#!/usr/bin/env python3
"""
gen_isa_test.py — generate the directed ISA test for the RV32IM MCU.

Emits five files:
  SIM/RV32IMscMCU/isa/ITCM.hex          the test program, Intel HEX (word-addressed)
  SIM/RV32IMscMCU/isa/DTCM.hex          zero-filled data image
  SIM/RV32IMscMCU/isa/listing.txt       human-readable disassembly + expectations
  TB/RV32IMscMCU/isa_expected_pkg.vhd          the expected store sequence, as a
  TB/RV32IMpipelinedMCU/isa_expected_pkg.vhd   VHDL package -- ONE sequence, two
                                               byte-identical copies, because
                                               clause 10 gives each MCU its own
                                               TB folder (see main()).

  The program itself is generated ONCE and stays in SIM/RV32IMscMCU/isa/: it is
  core-agnostic, and the pipeline's run_isa.do stages that same copy rather than
  owning a second one that could drift.

WHY A GENERATOR
  The testbench must not depend on a hand-maintained pair of "program" and
  "expected values" that can drift apart. Both are derived here from one table.

HOW THE TESTBENCH OBSERVES RESULTS
  The core exposes MemWrite_ctrl_o, dtcm_addr_o and dtcm_data_wr_o. Every store
  is therefore visible on declared ports, so the testbench snoops the store bus
  and needs no memory introspection and no external names.

WHY THE PROGRAM ONLY USES addi AND sw FOR PLUMBING
  Four of the five known decode defects break exactly the instructions a test
  harness would normally lean on:
    - lui writes 0            -> cannot build addresses with it
    - loads ignore the offset -> cannot read back a value
    - sra behaves as srl
    - unsigned compares are signed
  So every test case sets its operands with addi (from x0 or another register)
  and publishes its result with `sw rX, imm(x0)`. S-type immediates are decoded
  correctly, and addi is exercised by every supplied benchmark, so both are safe
  to build on. A case that tests addi or sw itself is marked as such.

  Byte offsets stay within the ±2048 range of a single I/S immediate, which
  covers DTCM words 0..511 — far more than this suite needs.

INTEL HEX FORMAT
  Matched to the supplied images, e.g. Auxilary/test1/RV32IM/man_compiled/
  bin/M9K-intel/ITCM.hex:  ":04" + 4-hex word address + "00" + 8 hex data digits
  MSB-first + checksum. Verified against ':04001b00fc0414e3ea'.
"""

import pathlib
import sys

# ─────────────────────────────────────────────────────────────── encoder ──────

def _chk(b):
    return (-sum(b)) & 0xFF


def ihex(words):
    """Word-addressed Intel HEX, 4 data bytes per record, MSB-first."""
    out = []
    for a, w in enumerate(words):
        d = [(w >> 24) & 0xFF, (w >> 16) & 0xFF, (w >> 8) & 0xFF, w & 0xFF]
        rec = [0x04, (a >> 8) & 0xFF, a & 0xFF, 0x00] + d
        out.append(":" + "".join(f"{x:02x}" for x in rec) + f"{_chk(rec):02x}")
    out.append(":00000001FF")
    return "\n".join(out) + "\n"


R = {f"x{i}": i for i in range(32)}
R.update(zero=0, ra=1, sp=2, gp=3, tp=4, t0=5, t1=6, t2=7,
         s0=8, fp=8, s1=9, a0=10, a1=11, a2=12, a3=13, a4=14, a5=15,
         a6=16, a7=17, s2=18, s3=19, s4=20, s5=21, s6=22, s7=23,
         s8=24, s9=25, s10=26, s11=27, t3=28, t4=29, t5=30, t6=31)


def _r(x):
    return x if isinstance(x, int) else R[x]


def _u(v, bits):
    return v & ((1 << bits) - 1)


def r_type(f7, rs2, rs1, f3, rd, op):
    return (_u(f7, 7) << 25) | (_r(rs2) << 20) | (_r(rs1) << 15) | \
           (_u(f3, 3) << 12) | (_r(rd) << 7) | _u(op, 7)


def i_type(imm, rs1, f3, rd, op):
    return (_u(imm, 12) << 20) | (_r(rs1) << 15) | (_u(f3, 3) << 12) | \
           (_r(rd) << 7) | _u(op, 7)


def s_type(imm, rs2, rs1, f3, op):
    i = _u(imm, 12)
    return ((i >> 5) << 25) | (_r(rs2) << 20) | (_r(rs1) << 15) | \
           (_u(f3, 3) << 12) | ((i & 0x1F) << 7) | _u(op, 7)


def b_type(imm, rs2, rs1, f3, op):
    i = _u(imm, 13)
    return (((i >> 12) & 1) << 31) | (((i >> 5) & 0x3F) << 25) | \
           (_r(rs2) << 20) | (_r(rs1) << 15) | (_u(f3, 3) << 12) | \
           (((i >> 1) & 0xF) << 8) | (((i >> 11) & 1) << 7) | _u(op, 7)


def u_type(imm20, rd, op):
    return (_u(imm20, 20) << 12) | (_r(rd) << 7) | _u(op, 7)


def j_type(imm, rd, op):
    i = _u(imm, 21)
    return (((i >> 20) & 1) << 31) | (((i >> 1) & 0x3FF) << 21) | \
           (((i >> 11) & 1) << 20) | (((i >> 12) & 0xFF) << 12) | \
           (_r(rd) << 7) | _u(op, 7)


OP, OPI, LOAD, STORE, BR, LUI, AUIPC, JAL, JALR = \
    0x33, 0x13, 0x03, 0x23, 0x63, 0x37, 0x17, 0x6F, 0x67

I = {
    # R-type, base
    "add":  lambda d, a, b: r_type(0x00, b, a, 0, d, OP),
    "sub":  lambda d, a, b: r_type(0x20, b, a, 0, d, OP),
    "sll":  lambda d, a, b: r_type(0x00, b, a, 1, d, OP),
    "slt":  lambda d, a, b: r_type(0x00, b, a, 2, d, OP),
    "sltu": lambda d, a, b: r_type(0x00, b, a, 3, d, OP),
    "xor":  lambda d, a, b: r_type(0x00, b, a, 4, d, OP),
    "srl":  lambda d, a, b: r_type(0x00, b, a, 5, d, OP),
    "sra":  lambda d, a, b: r_type(0x20, b, a, 5, d, OP),
    "or":   lambda d, a, b: r_type(0x00, b, a, 6, d, OP),
    "and":  lambda d, a, b: r_type(0x00, b, a, 7, d, OP),
    # R-type, M extension
    "mul":    lambda d, a, b: r_type(0x01, b, a, 0, d, OP),
    "mulh":   lambda d, a, b: r_type(0x01, b, a, 1, d, OP),
    "mulhsu": lambda d, a, b: r_type(0x01, b, a, 2, d, OP),
    "mulhu":  lambda d, a, b: r_type(0x01, b, a, 3, d, OP),
    "div":    lambda d, a, b: r_type(0x01, b, a, 4, d, OP),
    "divu":   lambda d, a, b: r_type(0x01, b, a, 5, d, OP),
    "rem":    lambda d, a, b: r_type(0x01, b, a, 6, d, OP),
    "remu":   lambda d, a, b: r_type(0x01, b, a, 7, d, OP),
    # I-type
    "addi":  lambda d, a, i: i_type(i, a, 0, d, OPI),
    "slti":  lambda d, a, i: i_type(i, a, 2, d, OPI),
    "sltiu": lambda d, a, i: i_type(i, a, 3, d, OPI),
    "xori":  lambda d, a, i: i_type(i, a, 4, d, OPI),
    "ori":   lambda d, a, i: i_type(i, a, 6, d, OPI),
    "andi":  lambda d, a, i: i_type(i, a, 7, d, OPI),
    "slli":  lambda d, a, s: i_type(s & 0x1F, a, 1, d, OPI),
    "srli":  lambda d, a, s: i_type(s & 0x1F, a, 5, d, OPI),
    "srai":  lambda d, a, s: i_type(0x400 | (s & 0x1F), a, 5, d, OPI),
    # loads
    "lb":  lambda d, o, a: i_type(o, a, 0, d, LOAD),
    "lh":  lambda d, o, a: i_type(o, a, 1, d, LOAD),
    "lw":  lambda d, o, a: i_type(o, a, 2, d, LOAD),
    "lbu": lambda d, o, a: i_type(o, a, 4, d, LOAD),
    "lhu": lambda d, o, a: i_type(o, a, 5, d, LOAD),
    # stores
    "sb": lambda s, o, a: s_type(o, s, a, 0, STORE),
    "sh": lambda s, o, a: s_type(o, s, a, 1, STORE),
    "sw": lambda s, o, a: s_type(o, s, a, 2, STORE),
    # branches
    "beq":  lambda a, b, o: b_type(o, b, a, 0, BR),
    "bne":  lambda a, b, o: b_type(o, b, a, 1, BR),
    "blt":  lambda a, b, o: b_type(o, b, a, 4, BR),
    "bge":  lambda a, b, o: b_type(o, b, a, 5, BR),
    "bltu": lambda a, b, o: b_type(o, b, a, 6, BR),
    "bgeu": lambda a, b, o: b_type(o, b, a, 7, BR),
    # upper immediates and jumps
    "lui":   lambda d, u: u_type(u, d, LUI),
    "auipc": lambda d, u: u_type(u, d, AUIPC),
    "jal":   lambda d, o: j_type(o, d, JAL),
    "jalr":  lambda d, o, a: i_type(o, a, 0, d, JALR),
}


def enc(mn, *a):
    return I[mn](*a)


# ───────────────────────────────────────────────────── encoder self-test ─────
# Every value below was taken from a supplied image or hand-derived from the
# RISC-V spec, so a silent encoder bug cannot reach the generated program.
_SELFTEST = [
    ("addi s0,s0,160",  enc("addi", "s0", "s0", 160),   0x0A040413),  # test1 ITCM.h word 1
    ("beq x0,x0,0",     enc("beq", "zero", "zero", 0),  0x00000063),  # the auto-stop sentinel
    ("jal x0,0",        enc("jal", "zero", 0),          0x0000006F),  # the gcc sentinel
    ("ret / jalr x0,0(ra)", enc("jalr", "zero", 0, "ra"), 0x00008067),
    ("add t2,t0,t1",    enc("add", "t2", "t0", "t1"),   0x006283B3),
    ("sw t2,4(x0)",     enc("sw", "t2", 4, "zero"),     0x00702223),
    ("lui t2,0x12345",  enc("lui", "t2", 0x12345),      0x123453B7),
    ("srai t2,t0,4",    enc("srai", "t2", "t0", 4),     0x4042D393),
    ("mul t2,t0,t1",    enc("mul", "t2", "t0", "t1"),   0x026283B3),
]


def selftest():
    bad = 0
    for name, got, want in _SELFTEST:
        if got != want:
            print(f"  ENCODER FAIL  {name}: got {got:08x} want {want:08x}")
            bad += 1
    if bad:
        sys.exit(f"encoder self-test failed ({bad} of {len(_SELFTEST)})")
    print(f"  encoder self-test: {len(_SELFTEST)}/{len(_SELFTEST)} OK")


# ─────────────────────────────────────────────────────────── the test suite ──
# Each case: (name, note, [setup instructions], test instruction, expected 32-bit
# result). The generator appends `sw <result reg>, <slot*4>(x0)` after each case,
# so the store sequence is exactly the case order.
#
# Convention: t0/t1 hold operands, t2 holds the result.

M32 = 0xFFFFFFFF
DEFECT = "DEFECT"

# Byte offsets for scratch data, well clear of the case slots (words 0..N-1) so
# a scratch write can never be mistaken for a case result. Still inside addi's
# and the S-immediate's +/-2048 range.
SCRATCH_A = 200 * 4      # word 200
SCRATCH_B = 201 * 4      # word 201
SCRATCH_C = 210 * 4      # word 210
SCRATCH_D = 211 * 4      # word 211 — the sub-word test target (G-309)


def li32(reg, value):
    """Load a full 32-bit constant using only addi and slli.

    lui is broken on this core (G-322), so a constant cannot be built the normal
    way. Instead the value is assembled a byte at a time:
        r = b3 ; r = (r<<8)+b2 ; r = (r<<8)+b1 ; r = (r<<8)+b0
    Every added byte is <= 0xFF, well inside addi's 12-bit signed immediate, and
    every intermediate stays positive, so no sign-extension surprise.
    """
    v = value & M32
    b = [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF]
    seq = [("addi", reg, "zero", b[0])]
    for byte in b[1:]:
        seq.append(("slli", reg, reg, 8))
        if byte:
            seq.append(("addi", reg, reg, byte))
    return seq


def suite():
    C = []

    def case(name, setup, test, expect, note=""):
        # expect may be None, meaning "the generator patches it once the
        # instruction's own address is known" (auipc).
        C.append((name, note, setup, test,
                  None if expect is None else expect & M32))

    # ── plumbing first: prove addi and sw themselves ────────────────────────
    case("addi", [], ("addi", "t2", "zero", 0x2A), 0x2A,
         "plumbing: every later case depends on addi")
    case("addi_neg", [], ("addi", "t2", "zero", -1), M32,
         "plumbing: sign-extension of an I-immediate")

    # ── R-type arithmetic and logic ─────────────────────────────────────────
    case("add", [("addi", "t0", "zero", 5), ("addi", "t1", "zero", 3)],
         ("add", "t2", "t0", "t1"), 8)
    case("sub", [("addi", "t0", "zero", 5), ("addi", "t1", "zero", 3)],
         ("sub", "t2", "t0", "t1"), 2)
    case("and", [("addi", "t0", "zero", 0xF0), ("addi", "t1", "zero", 0x3C)],
         ("and", "t2", "t0", "t1"), 0x30)
    case("or", [("addi", "t0", "zero", 0xF0), ("addi", "t1", "zero", 0x3C)],
         ("or", "t2", "t0", "t1"), 0xFC)
    case("xor", [("addi", "t0", "zero", 0xF0), ("addi", "t1", "zero", 0x3C)],
         ("xor", "t2", "t0", "t1"), 0xCC)

    # ── I-type logic — DEFECT 1 lives here ──────────────────────────────────
    case("andi", [("addi", "t0", "zero", 0xFF)],
         ("andi", "t2", "t0", 0x0F), 0x0F,
         f"{DEFECT} G-321: CONTROL.vhd:142 selects ALU_AND on ori_w, not andi_w, "
         "so andi falls through to ALU_NONE and writes 0")
    case("ori", [("addi", "t0", "zero", 0xF0)],
         ("ori", "t2", "t0", 0x0F), 0xFF,
         f"{DEFECT} G-321: ori_w appears twice in the same chain; the earlier "
         "ALU_AND arm wins, so ori computes AND -> 0x00")
    case("xori", [("addi", "t0", "zero", 0xFF)],
         ("xori", "t2", "t0", 0x0F), 0xF0)

    # ── compares — DEFECT 5 lives here ──────────────────────────────────────
    case("slti", [("addi", "t0", "zero", 5)],
         ("slti", "t2", "t0", 7), 1)
    case("slti_neg", [("addi", "t0", "zero", -5)],
         ("slti", "t2", "t0", -1), 1, "signed compare, correct today")
    case("sltiu", [("addi", "t0", "zero", -1)],
         ("sltiu", "t2", "t0", 1), 0,
         f"{DEFECT} G-325: EXECUTE.vhd:10 imports STD_LOGIC_SIGNED, so 0xFFFFFFFF "
         "is treated as -1 and the result is 1 instead of 0")
    case("slt", [("addi", "t0", "zero", -1), ("addi", "t1", "zero", 1)],
         ("slt", "t2", "t0", "t1"), 1, "signed compare, correct today")
    case("sltu", [("addi", "t0", "zero", -1), ("addi", "t1", "zero", 1)],
         ("sltu", "t2", "t0", "t1"), 0,
         f"{DEFECT} G-325: same signed import; expect 1 instead of 0")

    # ── shifts — DEFECT 4 lives here ────────────────────────────────────────
    case("sll", [("addi", "t0", "zero", 1), ("addi", "t1", "zero", 4)],
         ("sll", "t2", "t0", "t1"), 0x10)
    case("slli", [("addi", "t0", "zero", 1)],
         ("slli", "t2", "t0", 4), 0x10)
    # 0x80000000 built without lui: -1 << 31
    neg1_shl31 = [("addi", "t0", "zero", -1), ("slli", "t0", "t0", 31)]
    case("srli", neg1_shl31, ("srli", "t2", "t0", 4), 0x08000000)
    case("srai", neg1_shl31, ("srai", "t2", "t0", 4), 0xF8000000,
         f"{DEFECT} G-324: EXECUTE.vhd:200 sets the sign pad to 32x\"FFFF\" = "
         "0x0000FFFF, so bit 31 is '0' and srai behaves as srli -> 0x08000000")
    case("sra", neg1_shl31 + [("addi", "t1", "zero", 4)],
         ("sra", "t2", "t0", "t1"), 0xF8000000,
         f"{DEFECT} G-324: same pad defect")

    # ── upper immediates — DEFECT 2 lives here ──────────────────────────────
    case("lui", [], ("lui", "t2", 0x12345), 0x12345000,
         f"{DEFECT} G-322: const_package.vhd:27 has "
         "UTYPE_OPC := \"0010111\" and \"0110111\", which evaluates to auipc's "
         "opcode only, so lui matches no arm of the immediate select -> 0")
    # auipc at a known program address; the generator fills the expectation in.
    case("auipc", [], ("auipc", "t2", 0), None,
         "expected value is the instruction's own PC, patched in by the generator")

    # ── loads with a non-zero offset — DEFECT 3 lives here ──────────────────
    # Plant two distinct markers, then read the far one back. The scratch words
    # live at 200+ so they cannot collide with a case slot; the generator picks
    # their expectations up automatically from the reference run.
    case("lw_offset",
         [("addi", "t0", "zero", 0x2AA), ("sw", "t0", SCRATCH_A, "zero"),
          ("addi", "t1", "zero", 0x155), ("sw", "t1", SCRATCH_B, "zero")],
         ("lw", "t2", SCRATCH_A, "zero"), 0x2AA,
         f"{DEFECT} G-323: IDECODE's immediate select has no LOAD arm, so the "
         f"offset becomes 0 and this reads word 0 instead of word "
         f"{SCRATCH_A // 4}")

    # ── sub-word access — G-309, no byte enables at all ──────────────────────
    #
    # REPLACED 2026-08-23. The single case that used to live here was
    #     addi t0,zero,0x7F ; sb t0,SCRATCH_C(zero) ; lbu t2,SCRATCH_C(zero)
    # expecting 0x7F — and it could not fail once the load offset was repaired.
    # With no byte enables the sb writes the whole word as 0x0000007F, and with
    # no extract mux the lbu returns that whole word, which IS 0x7F. It would
    # have reported a pass while testing nothing, exactly like the mulh cases
    # did before their operands were changed.
    #
    # Every case below is discriminating: it needs a *surviving* neighbour byte
    # or a sign bit, neither of which a full-word access can fake. Each one
    # re-establishes the base word itself rather than inheriting it from the
    # previous case, so a failure localises to one instruction.
    g309 = (f"{DEFECT} G-309: DMEMORY's altsyncram is instantiated without "
            "byteena_a and CONTROL discards the access width, so sub-word "
            "access is unimplemented")

    # sb must leave the other three bytes of the word alone. Without byteena the
    # whole word becomes 0x0000007F, so this reads 0x0000007F instead.
    case("sb_keeps_neighbours",
         li32("t0", 0xAABBCCDD) + [("sw", "t0", SCRATCH_D, "zero"),
                                   ("addi", "t1", "zero", 0x7F),
                                   ("sb", "t1", SCRATCH_D + 1, "zero")],
         ("lw", "t2", SCRATCH_D, "zero"), 0xAABB7FDD,
         g309 + " — byte 1 replaced, bytes 0/2/3 must survive")

    # sh must leave the other half alone.
    case("sh_keeps_neighbours",
         li32("t0", 0x11223344) + [("sw", "t0", SCRATCH_D, "zero")] +
         li32("t1", 0x5566) + [("sh", "t1", SCRATCH_D + 2, "zero")],
         ("lw", "t2", SCRATCH_D, "zero"), 0x55663344,
         g309 + " — upper half replaced, lower half must survive")

    # lbu must select the addressed lane and zero-extend it.
    case("lbu_selects_lane",
         li32("t0", 0xAABBCCDD) + [("sw", "t0", SCRATCH_D, "zero")],
         ("lbu", "t2", SCRATCH_D + 2, "zero"), 0x000000BB,
         g309 + " — byte 2 of 0xAABBCCDD, zero-extended")

    # lb must sign-extend. 0xF0 has bit 7 set, so a conformant core returns
    # 0xFFFFFFF0; anything that returns the raw word returns 0x000000F0.
    case("lb_sign_extends",
         li32("t0", 0x000000F0) + [("sw", "t0", SCRATCH_D, "zero")],
         ("lb", "t2", SCRATCH_D, "zero"), 0xFFFFFFF0,
         g309 + " — byte 0 = 0xF0, bit 7 set, must sign-extend")

    # lhu must select the addressed half and zero-extend it.
    case("lhu_selects_half",
         li32("t0", 0x89ABCDEF) + [("sw", "t0", SCRATCH_D, "zero")],
         ("lhu", "t2", SCRATCH_D + 2, "zero"), 0x000089AB,
         g309 + " — upper half of 0x89ABCDEF, zero-extended")

    # lh must sign-extend. 0xABCD has bit 15 set.
    case("lh_sign_extends",
         li32("t0", 0x0000ABCD) + [("sw", "t0", SCRATCH_D, "zero")],
         ("lh", "t2", SCRATCH_D, "zero"), 0xFFFFABCD,
         g309 + " — lower half = 0xABCD, bit 15 set, must sign-extend")

    # ── M extension ─────────────────────────────────────────────────────────
    case("mul_small", [("addi", "t0", "zero", 3), ("addi", "t1", "zero", 4)],
         ("mul", "t2", "t0", "t1"), 12, "works: both operands fit in 16 bits")
    big = li32("t0", 0x12345678)          # lui is broken, so build it bytewise
    case("mul_wide", big + [("addi", "t1", "zero", 2)],
         ("mul", "t2", "t0", "t1"), 0x2468ACF0,
         f"{DEFECT} G-326: EXECUTE.vhd:93-94 feeds MUL16 only the lower "
         "half-words, so this yields 0x5678*2 = 0x0000ACF0")
    # The high-multiply cases need a product that does NOT fit in 32 bits, or
    # the correct answer would be 0 — which is also what an undecoded
    # instruction writes, and the case would pass without testing anything.
    #   0x12345678 * 0x10000000 = 0x0123456780000000
    #   -> low 32 = 0x80000000, high 32 = 0x01234567
    wide_b = li32("t1", 0x10000000)
    case("mul_hi_low", big + wide_b, ("mul", "t2", "t0", "t1"), 0x80000000,
         f"{DEFECT} G-326: MUL16 sees only the lower half-words, "
         "0x5678 * 0x0000 = 0")
    for mn in ("mulh", "mulhu", "mulhsu"):
        case(mn, big + wide_b, (mn, "t2", "t0", "t1"), 0x01234567,
             f"{DEFECT} G-308: {mn} is not decoded at all — the instruction mask "
             "exists in const_package but no ALU op consumes it, so the core "
             "writes 0. Both operands are positive here, so all three high "
             "multiplies share the same correct answer.")
    # G-307 CLOSED BY PHASE 7B2. These four were DEFECT cases for as long as
    # div/divu/rem/remu went undecoded and the core wrote 0. Phase 7B2 decodes
    # them, stalls the pipeline on PCHold and writes back from the Figure 9
    # accelerator, so they are now expected to PASS -- and, unlike the G-321..325
    # repairs, they pass at EITHER setting of G_ISA_REPAIR, because the divider is
    # not behind that switch. Removing the DEFECT tag is what drops the expected
    # mismatch counts from 25/9 to 21/5.
    #   The five that remain are all mul-related and all OUT OF SCOPE by Hanan's
    #   own answer (DOC/03, F1: "mul only (as in Lab 5)", 16-bit) -- so 5 is the
    #   floor, not a to-do list. See DOC/05 item R3 for how the report says so.
    case("div", [("addi", "t0", "zero", 100), ("addi", "t1", "zero", 7)],
         ("div", "t2", "t0", "t1"), 14,
         "G-307 closed by Phase 7B2: div through the Figure 9 accelerator")
    case("divu", [("addi", "t0", "zero", 100), ("addi", "t1", "zero", 7)],
         ("divu", "t2", "t0", "t1"), 14, "G-307 closed by Phase 7B2")
    case("rem", [("addi", "t0", "zero", 100), ("addi", "t1", "zero", 7)],
         ("rem", "t2", "t0", "t1"), 2, "G-307 closed by Phase 7B2")
    case("remu", [("addi", "t0", "zero", 100), ("addi", "t1", "zero", 7)],
         ("remu", "t2", "t0", "t1"), 2, "G-307 closed by Phase 7B2")
    return C


# ───────────────────────────────────────────── branch cases (own encoding) ───
# Branches produce no result register, so each is expressed as: set t2 to a
# "not taken" marker, branch over the overwrite, store t2. Taken -> 0xA, not
# taken -> 0xB.
BRANCH_CASES = [
    ("beq_taken",   "beq",  0,  0, 0xA, ""),
    ("bne_taken",   "bne",  1,  0, 0xA, ""),
    ("blt_taken",   "blt", -1,  1, 0xA, "signed, correct today"),
    ("bge_taken",   "bge",  1, -1, 0xA, "signed, correct today"),
    ("bltu_nottaken", "bltu", -1, 1, 0xB,
     f"{DEFECT} G-325: unsigned 0xFFFFFFFF > 1 so this must NOT be taken; the "
     "signed import makes it taken -> 0xA"),
    ("bgeu_taken", "bgeu", -1, 1, 0xA,
     f"{DEFECT} G-325: unsigned 0xFFFFFFFF >= 1 so this MUST be taken; the "
     "signed import makes it not taken -> 0xB"),
]


# ──────────────────────────────────────────────────────────────── assembly ───

def build():
    prog = []          # list of (word, text)
    expect = []        # list of (slot, value, name, note)
    slot = 0

    def emit(mn, *a, text=None):
        prog.append((enc(mn, *a), text or (mn + " " + ",".join(map(str, a)))))

    for name, note, setup, test, want in suite():
        for s in setup:
            emit(*s)
        pc_here = len(prog) * 4
        emit(*test)
        if want is None:                 # auipc: expectation is its own PC
            want = pc_here
            note = note + f" (PC = 0x{pc_here:03X})"
        emit("sw", "t2", slot * 4, "zero")
        expect.append((slot, want & M32, name, note))
        slot += 1

    # branch cases
    for name, mn, a_val, b_val, want, note in BRANCH_CASES:
        emit("addi", "t0", "zero", a_val)
        emit("addi", "t1", "zero", b_val)
        emit("addi", "t2", "zero", 0xA)          # assume taken
        # branch over the "not taken" overwrite: +8 skips one instruction
        emit(mn, "t0", "t1", 8)
        emit("addi", "t2", "zero", 0xB)          # executed only if NOT taken
        emit("sw", "t2", slot * 4, "zero")
        expect.append((slot, want, name, note))
        slot += 1

    # jal / jalr: link register must hold the return address
    pc_jal = len(prog) * 4
    emit("jal", "t2", 8)                          # t2 <- pc+4, jump over next
    emit("addi", "t2", "zero", 0x5A5)             # skipped when jal works
                                                  # (0x5A5 fits addi's immediate)
    emit("sw", "t2", slot * 4, "zero")
    expect.append((slot, pc_jal + 4, "jal_link",
                   "t2 must hold PC+4 and the next instruction must be skipped"))
    slot += 1

    # sentinel: the auto-stop condition every supplied testbench already uses
    emit("beq", "zero", "zero", 0, text="beq x0,x0,0   # sentinel, auto-stop")

    return prog, expect


# ─────────────────────────────────────────────────────────────── emitters ────

# ---------------------------------------------------------------------------
# Which gaps the G_ISA_REPAIR switch actually closes.
#
# One switch, cond_compilation_package.G_ISA_REPAIR, selects between the core
# exactly as LAB5 submitted it and the core with all of our ISA conformance work
# applied. That work is two phases but one switch, deliberately: two switches
# would mean four configurations to explain and to run.
#   Phase 3A  the seven decode repairs, each transcribed from the pipelined core
#             of the same LAB5 submission     -> G-321, G-322, G-323, G-324, G-325
#   Phase 3B  byte enables and sub-word load/store, our own design  -> G-309
#
# What the switch does NOT close, and why each is blocked on a question rather
# than on effort:
#   G-326  MUL16 is 16x16, so a wide mul is wrong  -> open question, mul width
#   G-308  mulh / mulhu / mulhsu not decoded       -> open question, "MULDIV partial"
#   G-307  div / divu / rem / remu not decoded     -> Phase 7 divider, Q6
#
# Keeping the split here, next to the case table, is what stops the expected
# counts from drifting away from the program.
GAP_IDS = ("G-307", "G-308", "G-309", "G-321", "G-322",
           "G-323", "G-324", "G-325", "G-326")
def _div_ref(a, b, is_signed, want_rem):
    """RV32IM div/divu/rem/remu, from the definition. Mirrors DIV_UNIT.vhd and
    is checked far harder in tools/model_div_unit.py (131488 cases)."""
    from fractions import Fraction
    M = 0xFFFFFFFF
    if b == 0:                       # spec override, all four opcodes
        return (a & M) if want_rem else M
    q = int(Fraction(a, b))          # truncation toward zero
    r = a - q * b
    return (r & M) if want_rem else (q & M)


REPAIRED_BY_SWITCH = ("G-309",                                      # phase 3B
                      "G-321", "G-322", "G-323", "G-324", "G-325")  # phase 3A


def fixed_by_phase3a(note):
    """True if G_ISA_REPAIR = TRUE is expected to make this case pass."""
    return any(g in note for g in REPAIRED_BY_SWITCH)


def vhdl_pkg(seq):
    w = max(len(n) for _, _, _, n, _ in seq)
    rows = []
    last = len(seq) - 1
    for idx, addr, val, name, note in seq:
        tag = "DEFECT" if DEFECT in note else ("setup " if "setup store" in note else "      ")
        comma = "" if idx == last else ","
        # The comma must precede the trailing comment, or it lands inside it and
        # the aggregate does not parse.
        rows.append(f'\t\t({addr:4d}, x"{val:08X}", "{name:<{w}}"){comma}'
                    f'\t-- {idx:3d} {tag}')
    body = "\n".join(rows)
    n_def = sum(1 for _, _, _, _, note in seq if DEFECT in note)
    n_def_repaired = sum(1 for _, _, _, _, note in seq
                         if DEFECT in note and not fixed_by_phase3a(note))
    still = sorted({g for _, _, _, _, note in seq
                    if DEFECT in note and not fixed_by_phase3a(note)
                    for g in GAP_IDS if g in note})
    return f"""--============================================================================
-- isa_expected_pkg — GENERATED by tools/gen_isa_test.py. Do not edit by hand.
--
-- The complete expected store sequence of the directed ISA test, in bus order.
-- The testbench snoops MemWrite_ctrl_o / dtcm_addr_o / dtcm_data_wr_o and
-- compares each store against the next entry here, so both the value and the
-- ordering are checked.
--
-- Entries marked "setup" are scratch stores a case performs while preparing its
-- operands. They are real stores on the bus, so they must appear in the
-- sequence, but a mismatch on one of them points at the store path rather than
-- at the instruction under test.
--
-- Entries marked "DEFECT" are expected to FAIL on the unfixed core. That is the
-- point of the suite: {n_def} of {len(seq)} stores should mismatch today. See
-- SIM/RV32IMscMCU/isa/listing.txt for the reason attached to each one.
--
-- Cross-checked against a reference RV32IM interpreter in the generator, so the
-- values below are what a conformant core produces, not what this core does.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

package isa_expected_pkg is

\tconstant NAME_LEN : natural := {w};

\ttype expected_t is record
\t\taddr	: natural;										-- DTCM word index
\t\tdata	: STD_LOGIC_VECTOR(31 DOWNTO 0);
\t\tname	: string(1 to NAME_LEN);
\tend record;

\ttype expected_array_t is array (natural range <>) of expected_t;

\tconstant STORE_COUNT : natural := {len(seq)};

\t-- How many of the stores above are expected to MISMATCH on this core.
\t-- EXPECTED_DEFECT_COUNT is the Lab 5 as-submitted tally (historical).
\t-- EXPECTED_DEFECT_COUNT_REPAIRED is what the ISA-repaired core must produce;
\t-- leftovers are mul-related: {", ".join(still)}
\tconstant EXPECTED_DEFECT_COUNT : natural := {n_def};
\tconstant EXPECTED_DEFECT_COUNT_REPAIRED : natural := {n_def_repaired};

\tconstant EXPECTED : expected_array_t(0 to STORE_COUNT-1) := (
{body}
\t);

end package isa_expected_pkg;
"""


def listing(prog, seq):
    n_def = sum(1 for _, _, _, _, note in seq if DEFECT in note)
    L = ["Directed ISA test — generated listing",
         "GENERATED by tools/gen_isa_test.py. Do not edit by hand.",
         "=" * 78, "",
         f"{len(prog)} instructions, {len(seq)} stores, "
         f"{n_def} expected to fail on the unfixed core",
         "",
         "Expectations were cross-checked against a reference RV32IM interpreter,",
         "so a mismatch in ModelSim is a hardware finding, not a bad expectation.",
         "", "EXPECTED STORE SEQUENCE", "-" * 78]
    for idx, addr, val, name, note in seq:
        mark = "FAIL-EXPECTED" if DEFECT in note else ("setup" if "setup store" in note else "ok")
        L.append(f"  #{idx:3d}  word {addr:4d}  {name:<16} = 0x{val:08X}   [{mark}]")
        if note and "setup store" not in note:
            for line in note.splitlines():
                L.append(f"              {line.strip()}")
    L += ["", "PROGRAM", "-" * 78]
    for i, (w, t) in enumerate(prog):
        L.append(f"  {i*4:04X}  {w:08X}   {t}")
    return "\n".join(L) + "\n"


# ────────────────────────────────────────────── reference RV32IM interpreter ──
# The point of this is not to simulate hardware. It is to prove that the
# expectations in suite() are what a CONFORMANT RV32IM core would actually
# produce when it runs the generated program. Without it, a wrong expectation
# would look like a hardware defect and send us debugging the wrong thing.
#
# Implemented straight from the unprivileged ISA spec, deliberately without
# reusing any of the encoder above beyond the field positions.

def _s32(v):
    v &= M32
    return v - (1 << 32) if v & 0x80000000 else v


def reference_run(words, max_steps=100000):
    """Execute the program. Returns the ordered list of (word_addr, value)."""
    x = [0] * 32
    mem = bytearray(8 * 1024)
    stores = []
    pc = 0
    for _ in range(max_steps):
        if pc >> 2 >= len(words):
            raise RuntimeError(f"PC 0x{pc:X} left the program")
        w = words[pc >> 2]
        op = w & 0x7F
        rd = (w >> 7) & 0x1F
        f3 = (w >> 12) & 7
        rs1 = (w >> 15) & 0x1F
        rs2 = (w >> 20) & 0x1F
        f7 = (w >> 25) & 0x7F
        a, b = x[rs1], x[rs2]
        immI = _s32(((w >> 20) | (0xFFFFF000 if w & 0x80000000 else 0)))
        immS = _s32((((w >> 25) << 5) | ((w >> 7) & 0x1F))
                    | (0xFFFFF000 if w & 0x80000000 else 0))
        immB = _s32(((((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11)
                     | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1))
                    | (0xFFFFE000 if w & 0x80000000 else 0))
        immU = w & 0xFFFFF000
        immJ = _s32(((((w >> 31) & 1) << 20) | (((w >> 12) & 0xFF) << 12)
                     | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1))
                    | (0xFFE00000 if w & 0x80000000 else 0))
        nxt = pc + 4
        val = None

        if op == 0x33:                                    # R-type
            if f7 == 0x01:                                # M extension
                sa, sb = _s32(a), _s32(b)
                if f3 == 0: val = sa * sb
                elif f3 == 1: val = (sa * sb) >> 32
                elif f3 == 2: val = (sa * (b & M32)) >> 32
                elif f3 == 3: val = ((a & M32) * (b & M32)) >> 32
                elif f3 == 4: val = -1 if sb == 0 else (
                    sa if (sa == -(1 << 31) and sb == -1) else int(sa / sb) if sa * sb < 0 else sa // sb)
                elif f3 == 5: val = M32 if b == 0 else (a & M32) // (b & M32)
                elif f3 == 6: val = sa if sb == 0 else (
                    0 if (sa == -(1 << 31) and sb == -1) else sa - int(sa / sb) * sb if sa * sb < 0 else sa % sb)
                elif f3 == 7: val = a & M32 if b == 0 else (a & M32) % (b & M32)
            else:
                sh = b & 0x1F
                if f3 == 0: val = a - b if f7 == 0x20 else a + b
                elif f3 == 1: val = a << sh
                elif f3 == 2: val = 1 if _s32(a) < _s32(b) else 0
                elif f3 == 3: val = 1 if (a & M32) < (b & M32) else 0
                elif f3 == 4: val = a ^ b
                elif f3 == 5: val = (_s32(a) >> sh) if f7 == 0x20 else ((a & M32) >> sh)
                elif f3 == 6: val = a | b
                elif f3 == 7: val = a & b
        elif op == 0x13:                                  # I-type ALU
            sh = (w >> 20) & 0x1F
            if f3 == 0: val = a + immI
            elif f3 == 1: val = a << sh
            elif f3 == 2: val = 1 if _s32(a) < immI else 0
            elif f3 == 3: val = 1 if (a & M32) < (immI & M32) else 0
            elif f3 == 4: val = a ^ immI
            elif f3 == 5: val = (_s32(a) >> sh) if (w >> 30) & 1 else ((a & M32) >> sh)
            elif f3 == 6: val = a | immI
            elif f3 == 7: val = a & immI
        elif op == 0x03:                                  # loads
            ad = (a + immI) & M32
            if f3 == 0: val = _s32(mem[ad] | (0xFFFFFF00 if mem[ad] & 0x80 else 0))
            elif f3 == 4: val = mem[ad]
            elif f3 == 1:
                h = mem[ad] | (mem[ad + 1] << 8)
                val = _s32(h | (0xFFFF0000 if h & 0x8000 else 0))
            elif f3 == 5: val = mem[ad] | (mem[ad + 1] << 8)
            elif f3 == 2:
                val = int.from_bytes(mem[ad:ad + 4], "little")
        elif op == 0x23:                                  # stores
            ad = (a + immS) & M32
            n = {0: 1, 1: 2, 2: 4}[f3]
            mem[ad:ad + n] = (b & M32).to_bytes(4, "little")[:n]
            # BUG FIX 2026-08-23: this used to be "if f3 == 2", recording only
            # word stores. Every store asserts MemWrite_ctrl_o on the bus, so
            # the scoreboard counts sub-word stores too — and a missing entry
            # shifts the whole remaining sequence by one, turning a single
            # unmodelled sb into ~19 spurious mismatches. Verified against the
            # generated image: 44 store instructions, 43 expected entries.
            #
            # What the bus carries for a sub-word store, and why:
            #   dtcm_addr_o    is the WORD address (RV32IM_CORE.vhd:199 drops
            #                  bits 1..0), so ad >> 2.
            #   dtcm_data_wr_o is read_data2_w — the raw rs2 value, upstream of
            #                  any byte-lane replication inside DMEMORY — so
            #                  b & M32 regardless of the access width, and
            #                  regardless of G_ISA_REPAIR.
            stores.append((ad >> 2, b & M32))
        elif op == 0x63:                                  # branches
            take = {0: a == b, 1: a != b, 4: _s32(a) < _s32(b),
                    5: _s32(a) >= _s32(b), 6: (a & M32) < (b & M32),
                    7: (a & M32) >= (b & M32)}[f3]
            if take:
                if immB == 0:
                    return stores                          # the sentinel
                nxt = pc + immB
        elif op == 0x37: val = immU                        # lui
        elif op == 0x17: val = pc + immU                   # auipc
        elif op == 0x6F:                                   # jal
            val, nxt = pc + 4, pc + immJ
        elif op == 0x67:                                   # jalr
            val, nxt = pc + 4, (a + immI) & ~1
        else:
            raise RuntimeError(f"unhandled opcode 0x{op:02X} at 0x{pc:X}")

        if val is not None and rd != 0:
            x[rd] = val & M32
        pc = nxt & M32
    raise RuntimeError("step limit reached — program never hit the sentinel")


def resolve(words, declared):
    """Turn the declared cases into the full expected store sequence.

    The reference interpreter supplies the sequence — including the scratch
    stores a case's setup performs, which are real stores on the bus and would
    otherwise throw the ordering off. Every declared case is cross-checked
    against what the reference produced for its slot, so a wrong human
    expectation is caught here rather than looking like a hardware defect.
    """
    stores = reference_run(words)
    dmap = {slot: (val, name, note) for slot, val, name, note in declared}
    seq, bad, matched = [], 0, 0

    for idx, (addr, val) in enumerate(stores):
        if addr in dmap:
            dval, name, note = dmap[addr]
            if dval != val:
                print(f"  REFERENCE FAIL {name}: declared word {addr}="
                      f"0x{dval:08X}, a conformant core stores 0x{val:08X}")
                bad += 1
            matched += 1
            seq.append((idx, addr, val, name, note))
        else:
            seq.append((idx, addr, val, f"scratch{addr}",
                        "setup store, not a checked case"))

    if matched != len(declared):
        missing = sorted(set(dmap) - {a for _, a in stores})
        print(f"  REFERENCE FAIL: {len(declared)-matched} declared case(s) never "
              f"stored; slots {missing}")
        bad += 1
    if bad:
        sys.exit(f"reference cross-check failed ({bad} problems) — the "
                 f"expectations, not the hardware, are wrong")

    print(f"  reference cross-check: {matched}/{len(declared)} declared cases "
          f"agree with a conformant RV32IM")
    print(f"  store sequence : {len(seq)} total "
          f"({len(seq)-matched} setup stores interleaved)")
    return seq


# ─────────────────────────────────────────────────── defect model ────────────
# A SECOND, independent interpreter: this one models our RTL including its
# defects, and predicts what the scoreboard will actually observe. reference_run
# above models a conformant RV32IM and produces the expectations. Keeping the two
# apart is the whole point -- a single parameterised model would agree with
# itself by construction and prove nothing.
#
# It exists because the two expected-mismatch counts are promises made to whoever
# runs the simulation. Deriving them by tagging cases with gap IDs is bookkeeping;
# deriving them by executing the program is evidence.

def defect_run(words, repair, max_steps=200000):
    """Execute the program the way THIS core executes it.

    repair = False : the core exactly as LAB5 submitted it
    repair = True  : G_ISA_REPAIR = TRUE, i.e. phases 3A and 3B applied

    Returns the ordered list of (word_addr, bus_data) the DTCM write port sees,
    where bus_data is read_data2 -- the raw rs2 value, upstream of DMEMORY's
    byte-lane replication -- because that is the signal the scoreboard snoops.
    """
    PCM = 0x1FFF                      # 13-bit PC / MA_WIDTH
    x = [0] * 32
    mem = bytearray(8 * 1024)
    stores = []
    pc = 0

    def disp(imm):
        """addr_gen_o = pc + displacement, EXECUTE.vhd:66.

        IDECODE hands over imm[12:1] sign-extended, so the adder shifts left by
        one. Repaired it keeps 13 bits; as submitted it keeps 12, dropping
        imm[12] -- gap G-328.
        """
        half = (imm >> 1) & M32
        if repair:
            v = (half & 0xFFF) << 1                 # 13-bit operand
            return v - 0x2000 if v & 0x1000 else v
        v = (half & 0x7FF) << 1                     # 12-bit operand
        return v - 0x1000 if v & 0x800 else v

    for _ in range(max_steps):
        if (pc & PCM) >> 2 >= len(words):
            raise RuntimeError(f"defect model: PC 0x{pc:X} left the program")
        w = words[(pc & PCM) >> 2]
        op = w & 0x7F
        rd, f3 = (w >> 7) & 0x1F, (w >> 12) & 7
        rs1, rs2, f7 = (w >> 15) & 0x1F, (w >> 20) & 0x1F, (w >> 25) & 0x7F
        a, b = x[rs1], x[rs2]
        sa, sb = _s32(a), _s32(b)
        immI = _s32((w >> 20) | (0xFFFFF000 if w & 0x80000000 else 0))
        immS = _s32((((w >> 25) << 5) | ((w >> 7) & 0x1F))
                    | (0xFFFFF000 if w & 0x80000000 else 0))
        immB = _s32(((((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11)
                     | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1))
                    | (0xFFFFE000 if w & 0x80000000 else 0))
        immU = w & 0xFFFFF000
        immJ = _s32(((((w >> 31) & 1) << 20) | (((w >> 12) & 0xFF) << 12)
                     | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1))
                    | (0xFFE00000 if w & 0x80000000 else 0))
        nxt, val = pc + 4, None

        if op == 0x13:                                    # OP-IMM
            sh = rs2                                      # shamt is imm[4:0]
            if f3 == 0:   val = a + immI
            elif f3 == 1: val = a << sh
            elif f3 == 2: val = 1 if sa < immI else 0
            elif f3 == 3:                                 # sltiu -- G-325
                val = (1 if (a & M32) < (immI & M32) else 0) if repair \
                      else (1 if sa < immI else 0)
            elif f3 == 4: val = a ^ (immI & M32)
            elif f3 == 5:                                 # srli / srai -- G-324
                arith = bool(f7 & 0x20)
                val = ((sa >> sh) if (arith and repair) else ((a & M32) >> sh))
            elif f3 == 6:                                 # ori -- G-321
                val = (a | (immI & M32)) if repair else (a & (immI & M32))
            elif f3 == 7:                                 # andi -- G-321
                val = (a & (immI & M32)) if repair else 0
        elif op == 0x33:                                  # OP
            if f7 == 0x01:                                # M extension
                # mul is decoded but MUL16 sees the low half-words only (G-326),
                # and mulh/mulhsu/mulhu are still not decoded at all (G-308) --
                # those write zero.  BOTH ARE OUT OF SCOPE by Hanan's answer
                # (DOC/03, F1: "mul only (as in Lab 5)", 16-bit).
                #
                # G-307 CLOSED BY PHASE 7B2: div/divu/rem/remu now go to the
                # Figure 9 accelerator, so they produce real results here. The
                # semantics modelled are RISC-V's, which is what DIV_UNIT.vhd
                # implements -- truncation toward zero, remainder taking the
                # dividend's sign, divide-by-zero giving all-ones and the
                # dividend, and -2^31/-1 giving -2^31 remainder 0.
                if f3 == 0:                               # mul -- G-326
                    val = (a & 0xFFFF) * (b & 0xFFFF)
                elif f3 in (1, 2, 3):                     # mulh* -- G-308
                    val = 0
                elif f3 == 4:                             # div
                    val = _div_ref(sa, sb, True, False)
                elif f3 == 5:                             # divu
                    val = _div_ref(a & M32, b & M32, False, False)
                elif f3 == 6:                             # rem
                    val = _div_ref(sa, sb, True, True)
                else:                                     # remu
                    val = _div_ref(a & M32, b & M32, False, True)
            elif f3 == 0: val = (a - b) if (f7 & 0x20) else (a + b)
            elif f3 == 1: val = a << (b & 0x1F)
            elif f3 == 2: val = 1 if sa < sb else 0
            elif f3 == 3:                                 # sltu -- G-325
                val = (1 if (a & M32) < (b & M32) else 0) if repair \
                      else (1 if sa < sb else 0)
            elif f3 == 4: val = a ^ b
            elif f3 == 5:                                 # srl / sra -- G-324
                arith = bool(f7 & 0x20)
                val = ((sa >> (b & 0x1F)) if (arith and repair)
                       else ((a & M32) >> (b & 0x1F)))
            elif f3 == 6: val = a | b
            elif f3 == 7: val = a & b
        elif op == 0x03:                                  # loads
            # G-323: as submitted the immediate select has no LOAD arm, so the
            # offset is zero. G-309: and no extract-and-extend, so whatever the
            # RAM returns for the word is written to rd unchanged.
            ad = (a + (immI if repair else 0)) & PCM
            word = int.from_bytes(mem[ad & ~3:(ad & ~3) + 4], "little")
            if not repair:
                val = word
            else:
                off, hoff = ad & 3, ad & 2
                byte = mem[(ad & ~3) + off]
                half = int.from_bytes(mem[(ad & ~3) + hoff:(ad & ~3) + hoff + 2],
                                      "little")
                if f3 == 0:   val = byte - 0x100 if byte & 0x80 else byte
                elif f3 == 4: val = byte
                elif f3 == 1: val = half - 0x10000 if half & 0x8000 else half
                elif f3 == 5: val = half
                else:         val = word
        elif op == 0x23:                                  # stores
            ad = (a + immS) & PCM                         # the offset always worked
            stores.append((ad >> 2, b & M32))             # what the bus carries
            if not repair:
                # No byteena: every lane is written, so a sub-word store
                # clobbers the whole word with the raw register value (G-309).
                base, n = ad & ~3, 4
            elif f3 == 0: base, n = ad, 1
            elif f3 == 1: base, n = ad & ~1, 2            # halves align down
            else:         base, n = ad & ~3, 4
            mem[base:base + n] = (b & M32).to_bytes(4, "little")[:n]
        elif op == 0x63:                                  # branches
            if f3 in (0, 1, 4, 5):
                take = {0: a == b, 1: a != b, 4: sa < sb, 5: sa >= sb}[f3]
            else:                                         # bltu / bgeu -- G-325
                take = ({6: (a & M32) < (b & M32), 7: (a & M32) >= (b & M32)}[f3]
                        if repair else {6: sa < sb, 7: sa >= sb}[f3])
            if take:
                if immB == 0:
                    return stores                         # the sentinel
                nxt = pc + disp(immB)
        elif op == 0x37:                                  # lui -- G-322
            val = immU if repair else 0
        elif op == 0x17:                                  # auipc: always worked
            val = pc + immU
        elif op == 0x6F:                                  # jal
            val, nxt = pc + 4, pc + disp(immJ)
        elif op == 0x67:                                  # jalr -- G-329
            tgt = (a + immI) & M32
            val, nxt = pc + 4, (tgt & ~1) if repair else tgt
        else:
            raise RuntimeError(f"defect model: unhandled opcode 0x{op:02X}")

        if val is not None and rd != 0:
            x[rd] = val & M32
        pc = nxt & M32
    raise RuntimeError("defect model: step limit reached")


def score(stores, seq):
    """Replicate the VHDL scoreboard exactly.

    tb_isa_directed.vhd:188-218 -- per store compare the word address first, then
    the data; at most one failure per store; the index advances either way, so a
    missing or extra store shifts everything after it.
    """
    out = []
    for idx, (addr, data) in enumerate(stores):
        if idx >= len(seq):
            out.append((idx, "<beyond the sequence>", "extra store"))
            continue
        _, eaddr, edata, name, _ = seq[idx]
        if addr != eaddr:
            out.append((idx, name, f"address: expected word {eaddr}, got {addr}"))
        elif data != edata:
            out.append((idx, name, f"data: expected 0x{edata:08X}, got 0x{data:08X}"))
    if len(stores) < len(seq):
        out.append((len(stores), seq[len(stores)][3], "store never happened"))
    return out


def cross_check_counts(words, seq, n_def, n_def_repaired):
    """Execute both configurations and confirm the promised counts."""
    bad = 0
    for repair, promised, label in ((False, n_def, "G_ISA_REPAIR=FALSE"),
                                    (True, n_def_repaired, "G_ISA_REPAIR=TRUE ")):
        fails = score(defect_run(words, repair), seq)
        tag = "OK" if len(fails) == promised else "*** DISAGREES ***"
        print(f"  defect model {label}: {len(fails):2d} mismatches, "
              f"package promises {promised:2d}   {tag}")
        if len(fails) != promised:
            bad += 1
            for idx, name, why in fails[:60]:
                print(f"      #{idx:3d} {name:24s} {why}")
    if bad:
        sys.exit("defect model disagrees with the gap tagging — one of the two "
                 "is wrong, and the promised counts cannot be trusted until "
                 "they agree")


def main():
    root = pathlib.Path(__file__).resolve().parent.parent
    print("generating directed ISA test")
    selftest()

    prog, declared = build()
    words = [w for w, _ in prog]
    if len(words) > 2048:
        sys.exit(f"program is {len(words)} words, ITCM holds 2048")
    seq = resolve(words, declared)

    isa = root / "SIM" / "RV32IMscMCU" / "isa"
    isa.mkdir(parents=True, exist_ok=True)
    (isa / "ITCM.hex").write_text(ihex(words))
    (isa / "DTCM.hex").write_text(ihex([0] * 1024))
    (isa / "listing.txt").write_text(listing(prog, seq))

    # BOTH trees, from one generation. Clause 10 Table 1 gives each MCU its own
    # TB folder, so the expectation package genuinely exists twice and there is
    # no shared folder to point both at -- the same duplication clause 10 forces
    # on the peripherals. Writing one and copying the other by hand is how the
    # .qsf / compile.do pair drifted twice in this project (5d540c0, Phase 12B),
    # so the generator writes both and tools/check_peripheral_copies.py asserts
    # they are byte-identical. The PROGRAM is core-agnostic and lives once, in
    # SIM/RV32IMscMCU/isa/; the pipeline's run_isa.do stages that copy.
    pkg = vhdl_pkg(seq)
    pkg_paths = [root / "TB" / "RV32IMscMCU" / "isa_expected_pkg.vhd",
                 root / "TB" / "RV32IMpipelinedMCU" / "isa_expected_pkg.vhd"]
    for p in pkg_paths:
        p.write_text(pkg)

    defects = sum(1 for _, _, _, _, n in seq if DEFECT in n)
    repaired = sum(1 for _, _, _, _, n in seq
                   if DEFECT in n and not fixed_by_phase3a(n))
    print(f"  program        : {len(words)} words ({len(words)*4} bytes)")
    print(f"  declared cases : {len(declared)}")
    print(f"  stores expected to FAIL on the unfixed core: {defects}")
    cross_check_counts(words, seq, defects, repaired)
    print(f"  wrote {isa}/ITCM.hex, DTCM.hex, listing.txt")
    for p in pkg_paths:
        print(f"  wrote {p.relative_to(root)}")


if __name__ == "__main__":
    main()
