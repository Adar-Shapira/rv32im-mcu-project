#!/usr/bin/env python3
"""Assemble UART/uart_menu.s into ITCM/DTCM instruction tuples.

`li` is expanded with `li32` (byte-at-a-time addi/slli), not `lui`,
because lui is broken on this core (G-322). uart_menu.c is the readable
C description of the same program; it is not lowered by this assembler.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import enc, li32, M32  # noqa: E402

RETI_WORD = 0x00020067
DTCM_WORDS = 1024

REGS = {
    "zero", "ra", "sp", "gp", "tp",
    "t0", "t1", "t2", "t3", "t4", "t5", "t6",
    "s0", "fp", "s1", "s2", "s3", "s4", "s5", "s6",
    "s7", "s8", "s9", "s10", "s11",
    "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7",
}
REGS.update(f"x{i}" for i in range(32))

I_TYPE = {"addi", "slli", "andi", "ori", "xori", "slti", "sltiu", "srli", "srai"}
R_TYPE = {"and", "or", "xor", "add", "sub", "sll", "srl", "sra", "slt", "sltu"}
B_TYPE = {"beq", "bne", "blt", "bge", "bltu", "bgeu"}


class AsmError(Exception):
    pass


def _strip_comment(line: str) -> str:
    in_str = False
    out = []
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == '"' and (i == 0 or line[i - 1] != "\\"):
            in_str = not in_str
            out.append(ch)
        elif ch == "#" and not in_str:
            break
        elif ch == "/" and not in_str and i + 1 < len(line) and line[i + 1] == "/":
            break
        elif ch == "/" and not in_str and i + 1 < len(line) and line[i + 1] == "*":
            i += 2
            while i + 1 < len(line) and not (line[i] == "*" and line[i + 1] == "/"):
                i += 1
            i += 2
            continue
        else:
            out.append(ch)
        i += 1
    return "".join(out).strip()


def _parse_int(tok: str, eqv: dict) -> int:
    tok = tok.strip()
    if tok in eqv:
        return eqv[tok]
    if re.fullmatch(r"'\\?.'", tok):
        return _parse_char(tok)
    if tok.startswith("0x") or tok.startswith("0X"):
        return int(tok, 16)
    return int(tok, 10)


def _parse_char(tok: str) -> int:
    inner = tok[1:-1]
    if inner == "\\n":
        return 10
    if inner == "\\r":
        return 13
    if inner == "\\t":
        return 9
    if inner == "\\\\":
        return 92
    if inner == "\\0":
        return 0
    if inner == "\\'":
        return 39
    if len(inner) == 1:
        return ord(inner)
    raise AsmError(f"bad character literal {tok}")


def _unescape_c_string(s: str) -> str:
    """s is the inside of a C/S assembler "..." with backslash escapes."""
    out = []
    i = 0
    while i < len(s):
        if s[i] != "\\":
            out.append(s[i])
            i += 1
            continue
        i += 1
        if i >= len(s):
            raise AsmError("dangling backslash in string")
        esc = s[i]
        i += 1
        mapping = {"n": "\n", "r": "\r", "t": "\t", "0": "\0",
                   "\\": "\\", '"': '"', "'": "'"}
        if esc in mapping:
            out.append(mapping[esc])
        else:
            raise AsmError(f"unknown string escape \\{esc}")
    return "".join(out)


def _split_args(blob: str) -> list[str]:
    args, cur, depth = [], [], 0
    for ch in blob:
        if ch == "(":
            depth += 1
            cur.append(ch)
        elif ch == ")":
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            args.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if cur or blob.endswith(","):
        args.append("".join(cur).strip())
    return [a for a in args if a != ""]


def _mem_ref(tok: str) -> tuple[str, str]:
    m = re.fullmatch(r"(-?[^()]+)\(([^()]+)\)", tok.strip())
    if not m:
        raise AsmError(f"expected off(rs) got {tok!r}")
    return m.group(1).strip(), m.group(2).strip()


def _preprocess_s(text: str, src_dir: pathlib.Path, defines: dict) -> str:
    lines = text.splitlines()
    out, i = [], 0
    n = len(lines)
    cond_stack = [True]  # currently emitting?

    def active() -> bool:
        return all(cond_stack)

    while i < n:
        raw = lines[i]
        line = _strip_comment(raw)
        i += 1
        if not line:
            if active():
                out.append("")
            continue
        parts = line.split(None, 1)
        d = parts[0].lower()
        rest = parts[1] if len(parts) > 1 else ""
        if d == ".include":
            if not active():
                continue
            name = rest.strip().strip('"').strip("'")
            path = (src_dir / name).resolve()
            if not path.exists():
                raise AsmError(f".include not found: {path}")
            out.append(_preprocess_s(path.read_text(encoding="utf-8"),
                                     path.parent, defines))
            continue
        if d == ".ifdef":
            cond_stack.append(active() and rest.strip() in defines)
            continue
        if d == ".ifndef":
            cond_stack.append(active() and rest.strip() not in defines)
            continue
        if d == ".else":
            if len(cond_stack) < 2:
                raise AsmError(".else without .ifdef")
            inner = cond_stack.pop()
            parent = active()
            cond_stack.append(parent and not inner)
            continue
        if d == ".endif":
            if len(cond_stack) < 2:
                raise AsmError(".endif without .ifdef")
            cond_stack.pop()
            continue
        if active():
            out.append(raw)
    if len(cond_stack) != 1:
        raise AsmError("unclosed .ifdef")
    return "\n".join(out) + "\n"


def assemble_text(text: str, src_dir: pathlib.Path, sim: bool = False):
    """Return (resolved_prog, byte_labels, dtcm_words, strings).

    strings is dict with MENU and NEGEV (without the terminating NUL word).
    """
    defines = {"UART_MENU_SIM": 1} if sim else {}
    text = _preprocess_s(text, src_dir, defines)

    eqv = {}
    prog = []
    labels = {}
    dtcm = [0] * DTCM_WORDS
    section = "text"
    data_addr = 0
    strings = {}
    string_at = {}  # addr -> name, filled when we see named .stringw? we name by addr

    def data_word_off() -> int:
        if data_addr % 4:
            raise AsmError(f".data address {data_addr:#x} is not word-aligned")
        return data_addr // 4

    def resolve_imm(tok: str, allow_label=False):
        tok = tok.strip()
        if tok in eqv:
            return eqv[tok]
        if allow_label and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", tok) and tok not in REGS:
            return ("L", tok)
        return _parse_int(tok, eqv)

    for lineno, raw in enumerate(text.splitlines(), 1):
        line = _strip_comment(raw)
        if not line:
            continue
        try:
            # .eqv NAME VALUE
            m = re.match(r"\.eqv\s+(\w+)\s+(.+)$", line, re.I)
            if m:
                eqv[m.group(1)] = _parse_int(m.group(2).strip(), eqv)
                continue
            low = line.lower()
            if low == ".text":
                section = "text"
                continue
            if low == ".data":
                section = "data"
                continue
            m = re.match(r"\.org\s+(.+)$", line, re.I)
            if m:
                data_addr = resolve_imm(m.group(1))
                if isinstance(data_addr, tuple):
                    raise AsmError(".org needs a numeric address")
                continue
            m = re.match(r"\.space\s+(.+)$", line, re.I)
            if m:
                if section != "data":
                    raise AsmError(".space only in .data")
                n = resolve_imm(m.group(1))
                if isinstance(n, tuple) or n < 0:
                    raise AsmError(".space needs a byte count")
                data_addr += n
                continue
            m = re.match(r"\.stringw\s+\"(.*)\"\s*$", line)
            if m:
                s = _unescape_c_string(m.group(1))
                string_at[data_addr] = s
                if section != "data":
                    raise AsmError(".stringw only in .data")
                for ch in s:
                    if data_word_off() >= DTCM_WORDS:
                        raise AsmError("DTCM overrun")
                    dtcm[data_word_off()] = ord(ch)
                    data_addr += 4
                if data_word_off() >= DTCM_WORDS:
                    raise AsmError("DTCM overrun")
                dtcm[data_word_off()] = 0
                data_addr += 4
                continue
            m = re.match(r"\.word\s+(.+)$", line, re.I)
            if m:
                if section != "data":
                    raise AsmError(".word only in .data")
                for tok in _split_args(m.group(1)):
                    val = resolve_imm(tok)
                    if isinstance(val, tuple):
                        raise AsmError(".word label not supported")
                    dtcm[data_word_off()] = val & M32
                    data_addr += 4
                continue

            # label, possibly followed by an instruction
            while True:
                lm = re.match(r"([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$", line)
                if not lm:
                    break
                name, rest = lm.group(1), lm.group(2)
                if section != "text":
                    raise AsmError(f"label {name} outside .text")
                if name in labels:
                    raise AsmError(f"duplicate label {name}")
                labels[name] = len(prog)
                line = rest.strip()
                if not line:
                    break
            if not line:
                continue

            # instruction
            if section != "text":
                raise AsmError(f"instruction in .data: {line}")
            parts = line.split(None, 1)
            mn = parts[0].lower()
            argblob = parts[1] if len(parts) > 1 else ""
            args = _split_args(argblob) if argblob else []

            if mn == "li":
                if len(args) != 2:
                    raise AsmError(f"li rd, imm: {line}")
                rd, imm = args[0], resolve_imm(args[1])
                if isinstance(imm, tuple):
                    raise AsmError("li of a label: use addi")
                for ins in li32(rd, imm):
                    prog.append(tuple(ins))
            elif mn in I_TYPE:
                if len(args) != 3:
                    raise AsmError(line)
                rd, rs, imm = args[0], args[1], resolve_imm(args[2], allow_label=True)
                prog.append((mn, rd, rs, imm))
            elif mn in R_TYPE:
                if len(args) != 3:
                    raise AsmError(line)
                prog.append((mn, args[0], args[1], args[2]))
            elif mn in ("lw", "lh", "lb", "lbu", "lhu"):
                if len(args) != 2:
                    raise AsmError(line)
                off, rs = _mem_ref(args[1])
                prog.append((mn, args[0], resolve_imm(off, allow_label=True), rs))
            elif mn in ("sw", "sh", "sb"):
                if len(args) != 2:
                    raise AsmError(line)
                off, rs = _mem_ref(args[1])
                prog.append((mn, args[0], resolve_imm(off, allow_label=True), rs))
            elif mn in B_TYPE:
                if len(args) != 3:
                    raise AsmError(line)
                prog.append((mn, args[0], args[1], ("L", args[2])))
            elif mn == "jalr":
                if len(args) != 2:
                    raise AsmError(line)
                off, rs = _mem_ref(args[1])
                prog.append((mn, args[0], resolve_imm(off), rs))
            elif mn in (".word",):
                raise AsmError("bare .word in .text not used")
            else:
                raise AsmError(f"unknown mnemonic {mn}")
        except AsmError:
            raise
        except Exception as e:
            raise AsmError(f"line {lineno}: {raw}\n  {e}") from e

    def cstr_at(addr):
        chars, i = [], addr // 4
        while i < DTCM_WORDS and dtcm[i]:
            chars.append(chr(dtcm[i] & 0xFF))
            i += 1
        return "".join(chars)

    sm = eqv.get("S_MENU", 0x40)
    sn = eqv.get("S_NEGEV", 0x400)
    strings["MENU"] = string_at.get(sm, cstr_at(sm))
    strings["NEGEV"] = string_at.get(sn, cstr_at(sn))

    byte_labels = {k: v * 4 for k, v in labels.items()}
    for name, addr in byte_labels.items():
        if addr >= 2048:
            raise AsmError(f"label {name} at {addr:#x} exceeds addi's 12-bit range")

    out = []
    for i, ins in enumerate(prog):
        mn = ins[0]
        if mn in I_TYPE and isinstance(ins[3], tuple) and ins[3][0] == "L":
            lab = ins[3][1]
            if lab not in byte_labels:
                raise AsmError(f"undefined label {lab}")
            out.append((mn, ins[1], ins[2], byte_labels[lab]))
        elif mn in ("lw", "sw", "lh", "lb", "lbu", "lhu", "sh", "sb") and isinstance(ins[2], tuple):
            lab = ins[2][1]
            out.append((mn, ins[1], byte_labels[lab], ins[3]))
        elif mn in B_TYPE and isinstance(ins[3], tuple) and ins[3][0] == "L":
            lab = ins[3][1]
            if lab not in labels:
                raise AsmError(f"undefined label {lab}")
            out.append((mn, ins[1], ins[2], (labels[lab] - i) * 4))
        else:
            out.append(ins)
    if sim:
        # uart_menu.s carries the board HALFSEC (RARS forbids a second .eqv).
        addr = eqv.get("V_HALFSEC_ADDR", 0x38)
        dtcm[addr // 4] = 1999
    return out, byte_labels, dtcm, strings


def assemble_file(path: pathlib.Path, sim: bool = False):
    path = pathlib.Path(path)
    return assemble_text(path.read_text(encoding="utf-8"), path.parent, sim=sim)


# ── C → assembly text ────────────────────────────────────────────────────────

_CALL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\((.*)\)\s*;\s*$")
_LABEL = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$")
_DEFINE = re.compile(r"^#define\s+(\w+)(?:\s+(.+?))?\s*$")
_INCLUDE = re.compile(r"^#include\s+\"([^\"]+)\"\s*$")
_IFNDEF = re.compile(r"^#ifndef\s+(\w+)\s*$")
_IFDEF = re.compile(r"^#ifdef\s+(\w+)\s*$")
_ARRAY = re.compile(
    r"(?:static\s+)?(?:const\s+)?char\s+(\w+)\s*\[\s*\]\s*=",
)


def _c_collect_string(text: str, start: int) -> tuple[str, int]:
    """From the '=' of an array init, collect concatenated "..." pieces."""
    i = start
    n = len(text)
    while i < n and text[i].isspace():
        i += 1
    pieces = []
    while i < n:
        while i < n and text[i].isspace():
            i += 1
        if i < n and text[i] == ";":
            return "".join(pieces), i + 1
        if i >= n or text[i] != '"':
            raise AsmError(f"expected string literal in array init at {i}")
        i += 1
        buf = []
        while i < n:
            if text[i] == "\\":
                buf.append(text[i:i+2])
                i += 2
                continue
            if text[i] == '"':
                i += 1
                break
            buf.append(text[i])
            i += 1
        pieces.append(_unescape_c_string("".join(buf)))
    raise AsmError("unterminated string array")


def _preprocess_c_lines(text: str, src_dir: pathlib.Path, defines: dict) -> list[str]:
    # very small preprocessor: #include, #define, #ifndef/#ifdef/#else/#endif
    raw_lines = text.splitlines()
    out, i = [], 0
    cond = [True]

    def active():
        return all(cond)

    while i < len(raw_lines):
        line = raw_lines[i].strip()
        i += 1
        if line.startswith("#"):
            # do not run _strip_comment: '#' starts the directive, not a comment
            code = re.sub(r"/\*.*?\*/", "", line)
            code = code.split("//")[0].strip()
        else:
            code = line
        if code.startswith("#include"):
            m = _INCLUDE.match(code)
            if not m:
                raise AsmError(f"bad #include: {line}")
            if not active():
                continue
            inc = (src_dir / m.group(1)).resolve()
            nested = _preprocess_c_lines(inc.read_text(encoding="utf-8"),
                                         inc.parent, defines)
            out.extend(nested)
            continue
        if code.startswith("#define"):
            m = _DEFINE.match(code)
            if not m:
                raise AsmError(f"bad #define: {line}")
            if active():
                val = (m.group(2) or "1").strip()
                if val.endswith("u") or val.endswith("U"):
                    val = val[:-1]
                defines[m.group(1)] = val
            continue
        if code.startswith("#ifndef"):
            m = _IFNDEF.match(code)
            cond.append(active() and m.group(1) not in defines)
            continue
        if code.startswith("#ifdef"):
            m = _IFDEF.match(code)
            cond.append(active() and m.group(1) in defines)
            continue
        if code.startswith("#else"):
            inner = cond.pop()
            parent = active()
            cond.append(parent and not inner)
            continue
        if code.startswith("#endif"):
            cond.pop()
            continue
        if code.startswith("#"):
            raise AsmError(f"unsupported directive: {line}")
        if active():
            out.append(raw_lines[i - 1])
    return out


def c_to_assembly(path: pathlib.Path, sim: bool = False) -> str:
    """Lower uart_menu.c to the assembler language uart_menu.s uses."""
    path = pathlib.Path(path)
    defines = {}
    if sim:
        defines["UART_MENU_SIM"] = "1"
    lines = _preprocess_c_lines(path.read_text(encoding="utf-8"),
                                path.parent, defines)

    # recover concatenated source for string extract
    blob = "\n".join(lines) + "\n"
    strings = {}
    for m in _ARRAY.finditer(blob):
        name = m.group(1)
        s, _ = _c_collect_string(blob, m.end())
        strings[name] = s

    eqv_lines = []
    skip_keys = {"UART_MENU_SIM", "UART_MENU_IO_MAP_H"}
    for k, v in defines.items():
        if k in skip_keys:
            continue
        eqv_lines.append(f".eqv {k} {v}")

    # find _start body
    body_lines = []
    in_start = False
    depth = 0
    for raw in lines:
        stripped = _strip_comment(raw)
        if not in_start:
            if re.search(r"\b_start\s*\(", stripped):
                in_start = True
                depth += stripped.count("{") - stripped.count("}")
            continue
        depth += raw.count("{") - raw.count("}")
        if depth <= 0:
            break
        body_lines.append(raw)

    asm_body = []
    for raw in body_lines:
        line = _strip_comment(raw)
        if not line or line in ("{", "}"):
            continue
        if line.startswith("unsigned ") or line.startswith("register "):
            continue
        if line.startswith("goto "):
            raise AsmError("use beq(zero, zero, L) not goto")
        lm = _LABEL.match(line)
        if lm:
            asm_body.append(f"{lm.group(1)}:")
            continue
        cm = _CALL.match(line)
        if not cm:
            raise AsmError(f"C line is not an instruction: {line}")
        mn, argblob = cm.group(1), cm.group(2)
        args = _split_args(argblob)
        mn_l = mn.lower()
        if mn_l in ("lw", "sw", "jalr") and len(args) == 3:
            asm_body.append(f"    {mn_l} {args[0]}, {args[1]}({args[2]})")
        else:
            asm_body.append(f"    {mn_l} " + ", ".join(args))

    menu = strings.get("MENU")
    negev = strings.get("NEGEV")
    if menu is None or negev is None:
        raise AsmError("C file must define MENU[] and NEGEV[]")

    # S_MENU / S_NEGEV / HALFSEC from defines
    def defn(name, default=None):
        if name not in defines:
            if default is None:
                raise AsmError(f"C is missing #define {name}")
            return default
        return defines[name]

    parts = [".include \"io_map.s\"", ""]
    parts.extend(eqv_lines)
    parts += ["", ".text", ""]
    parts.extend(asm_body)
    parts += [
        "",
        ".data",
        f".org {defn('V_HALFSEC_ADDR', '0x38')}",
        ".word HALFSEC",
        f".org {defn('S_MENU')}",
        ".stringw \"" + _escape_stringw(menu) + "\"",
        f".org {defn('S_NEGEV')}",
        ".stringw \"" + _escape_stringw(negev) + "\"",
        "",
    ]
    return "\n".join(parts) + "\n"


def _escape_stringw(s: str) -> str:
    out = []
    for ch in s:
        if ch == "\r":
            out.append("\\r")
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\t":
            out.append("\\t")
        elif ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        else:
            out.append(ch)
    return "".join(out)


def compile_c(path: pathlib.Path, sim: bool = False):
    asm = c_to_assembly(path, sim=sim)
    return assemble_text(asm, pathlib.Path(path).parent, sim=sim)


def encode_itcm(prog) -> list[int]:
    words = []
    for ins in prog:
        if ins[0] == "jalr" and ins[1] == "zero" and ins[2] == 0 and ins[3] == "tp":
            w = enc("jalr", "zero", 0, "tp")
            if w != RETI_WORD:
                raise AsmError(f"reti encoding {w:#010x} != {RETI_WORD:#010x}")
            words.append(w)
        else:
            words.append(enc(*ins))
    return words


def ir_equal(a, b) -> bool:
    return list(a) == list(b)
