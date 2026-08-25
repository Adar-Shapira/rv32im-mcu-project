#!/usr/bin/env python3
"""Generate the directed CORE-LEVEL interrupt-protocol test -- Phase 9B.

WHY THIS EXISTS
    Phase 9B adds the CPU side of the interrupt protocol (REQ p15): the entry
    FSM, GIE in gp[0], tp, the vector fetch, reti. No supplied benchmark can
    exercise it below the MCU level, and the MCU wiring (CS_INTC, the TYPE
    push reader) is Phase 9C -- so 9B gets a CORE-level test: the testbench
    plays the interrupt controller (drives intr_i, watches inta_o, pushes
    TYPE on dbus_rdata_i), and this program proves the protocol's register
    and control effects from the inside.

WHAT THE PROGRAM PROVES (with tb_intr_core.vhd)
    Round 1 -- KEY1 (TYPE 0x14) while main sits in a poll loop:
      [0x180] = 0      gp read INSIDE the ISR: GIE was cleared IN HW (rule e)
      [0x184] = tp1    the return address, range-checked to the poll loop
      [0x100] = 1      gp read by main AFTER reti: GIE restored IN HW (rule f)
      [0x104] = tp1    tp survived the ISR and equals what the ISR saw
    Round 2 -- BT (TYPE 0x10): a DIFFERENT vector word reaches a DIFFERENT
      handler:
      [0x188] = 0xB7   the BT handler's marker
      [0x108] = 1      GIE restored again
    Round 3 -- KEY1 raised the moment the div appears on instruction_o (F13):
      entry must WAIT for the divide; the testbench measures the deferral,
      and the program proves nothing was corrupted by it:
      [0x10C] = 142    div 1000/7 -- retired correctly despite the pending INTR
      [0x110] = 6      rem 1000/7 -- the adjacent-divide path, still correct
      [0x18C] = 0      the ISR ran (after the divides), GIE again cleared
      [0x190] = tp3    return address, range-checked to the post-div stores
      [0x114] = 0x5D   main resumed and finished
    The VECTOR TABLE IS BUILT BY THE PROGRAM ITSELF: two sw's write the two
    handler addresses into DTCM words 4 and 5 -- which also proves the fetch
    in entry Cycle 2 reads the same memory stores write (DTCM.hex is zeros).

WHY tp IS RANGE-CHECKED, NOT EXACT
    Where the interrupt lands depends on testbench timing (how many poll
    iterations run before intr_i rises, how long the divider's busy tail is).
    The protocol claim needs only: tp points INTO the region being executed
    at the time, the ISR's copy and main's copy AGREE, and execution resumes
    there. Same posture as the captured K in gen_timer_test.py.

WHY THIS RUNS AT EITHER G_ISA_REPAIR SETTING
    addi / sw / lw-at-offset-0 / beq / div / rem / jalr-at-offset-0-aligned:
    none touch the seven defects (div and rem are Phase 7B2 hardware,
    independent of the switch; jalr's defect 7 only bites ODD targets and tp
    is word-aligned).

THE SECOND DERIVATION
    interpret() below executes the program instruction by instruction and
    EMULATES the protocol -- entry (gp[0] cleared, tp = return address, PC =
    the DTCM word TYPE/4 names), the ISR, reti (gp[0] set, PC = tp) -- with
    the three interrupts injected at representative points. Generation aborts
    if the final DTCM disagrees with the declared expectations.

USAGE
    python3 tools/gen_intr_core_test.py
        writes SIM/RV32IMscMCU/intr/{ITCM.hex,DTCM.hex,listing.txt}
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import enc, ihex, M32                     # noqa: E402

RETI_WORD = 0x00020067          # jalr zero,0(tp) -- io_map.s's own .eqv

# ── the program ──────────────────────────────────────────────────────────────
# Two-pass: instruction lengths are fixed (no li32 needed -- every constant
# fits addi), so labels resolve after one layout pass.

def build():
    prog = []                   # (mnemonic tuple) or ("RAW", word)
    labels = {}

    def emit(*ins):
        prog.append(tuple(ins))

    def label(name):
        labels[name] = len(prog)

    # register plan: s0 = main scratch ptr, s1/s2 = vector word 4/5 addrs,
    # s3/s5 = flag addrs, s4 = ISR scratch ptr, t0/t5 = temporaries,
    # a6/a7 = div operands, t6/s6 = div results.
    # gp and tp belong to the PROTOCOL and are never used as data here.
    emit("addi", "s1", "zero", 0x10)      # vector word 4 (BT, TYPE 0x10)
    emit("addi", "s2", "zero", 0x14)      # vector word 5 (KEY1, TYPE 0x14)
    emit("addi", "s0", "zero", 0x100)     # main scratch
    emit("addi", "s4", "zero", 0x180)     # ISR scratch
    emit("addi", "s3", "zero", 0x200)     # flag1 (KEY1 ISR done)
    emit("addi", "s5", "zero", 0x204)     # flag2 (BT ISR done)
    emit("addi", "t0", "zero", "ISR_BT")  # build the vector table with plain
    emit("sw",   "t0", 0, "s1")           # stores: entry Cycle 2 must read
    emit("addi", "t0", "zero", "ISR_KEY1")  # back exactly what these wrote
    emit("sw",   "t0", 0, "s2")
    emit("addi", "gp", "zero", 1)         # EINT: GIE = gp[0] = 1

    label("POLL1")                        # round 1 lands in here
    emit("lw",  "t5", 0, "s3")
    emit("beq", "t5", "zero", -4)

    emit("sw",   "gp", 0, "s0")           # [0x100] = 1  (rule f held)
    emit("addi", "s0", "s0", 4)
    emit("sw",   "tp", 0, "s0")           # [0x104] = tp1
    emit("addi", "s0", "s0", 4)

    label("POLL2")                        # round 2 lands here or just before
    emit("lw",  "t5", 0, "s5")
    emit("beq", "t5", "zero", -4)
    emit("sw",   "gp", 0, "s0")           # [0x108] = 1
    emit("addi", "s0", "s0", 4)

    emit("addi", "a6", "zero", 1000)
    emit("addi", "a7", "zero", 7)
    label("DIVPH")
    emit("div", "t6", "a6", "a7")         # round 3 raised HERE (F13 deferral)
    emit("rem", "s6", "a6", "a7")
    label("POSTDIV")                      # ...and lands somewhere in here
    emit("sw",   "t6", 0, "s0")           # [0x10C] = 142
    emit("addi", "s0", "s0", 4)
    emit("sw",   "s6", 0, "s0")           # [0x110] = 6
    emit("addi", "s0", "s0", 4)
    emit("addi", "t0", "zero", 0x5D)
    emit("sw",   "t0", 0, "s0")           # [0x114] = 0x5D  (main finished)
    label("SENTINEL")
    emit("beq", "zero", "zero", 0)        # 0x00000063, the auto-stop

    label("ISR_KEY1")
    emit("sw",   "gp", 0, "s4")           # gp inside the ISR: MUST read 0
    emit("addi", "s4", "s4", 4)
    emit("sw",   "tp", 0, "s4")           # the return address
    emit("addi", "s4", "s4", 4)
    emit("addi", "t5", "zero", 1)
    emit("sw",   "t5", 0, "s3")           # flag1 = 1
    emit("RAW",  RETI_WORD)               # reti

    label("ISR_BT")
    emit("addi", "t5", "zero", 0xB7)
    emit("sw",   "t5", 0, "s4")           # the BT marker
    emit("addi", "s4", "s4", 4)
    emit("addi", "t5", "zero", 1)
    emit("sw",   "t5", 0, "s5")           # flag2 = 1
    emit("RAW",  RETI_WORD)               # reti

    # resolve label operands (only addi immediates carry them)
    out = []
    for ins in prog:
        if ins[0] == "addi" and isinstance(ins[3], str):
            out.append(("addi", ins[1], ins[2], labels[ins[3]] * 4))
        else:
            out.append(ins)
    return out, {k: v * 4 for k, v in labels.items()}


# ── the second derivation: interpret with the protocol emulated ──────────────
def interpret(prog, labels):
    """Sequential execution; three injected interrupts. Returns final DTCM."""
    regs = {}
    dtcm = {}

    def rget(r): return regs.get(r, 0)

    def rset(r, v):
        if r != "zero":
            regs[r] = v & M32

    # (when, type) -- injection points chosen at REPRESENTATIVE instructions:
    # round 1 in POLL1's lw, round 2 in POLL2's lw, round 3 right after the
    # rem retires (the F13 gate holds entry off until the divides finish).
    pending = [(labels["POLL1"] // 4, 0x14),
               (labels["POLL2"] // 4, 0x10),
               (labels["POSTDIV"] // 4, 0x14)]

    pc = 0
    steps = 0
    while steps < 5000:
        steps += 1
        idx = pc // 4

        # protocol emulation: an injected interrupt fires when GIE=1 and the
        # NEXT instruction to execute is its injection point (the accept
        # cycle's instruction has completed; pc here IS the return address).
        if pending and (rget("gp") & 1) == 1 and idx == pending[0][0]:
            _, typ = pending.pop(0)
            rset("gp", rget("gp") & ~1)          # Cycle 1: GIE cleared in HW
            rset("tp", pc)                       # Cycle 2: tp = return address
            pc = dtcm.get(typ, 0)                # Cycle 2: PC = Mem[TYPE]
            continue

        ins = prog[idx]
        mn = ins[0]
        if mn == "RAW" and ins[1] == RETI_WORD:  # reti
            rset("gp", rget("gp") | 1)           # GIE set in HW (rule f)
            pc = rget("tp")
            continue
        if mn == "addi":
            _, rd, rs, imm = ins
            rset(rd, rget(rs) + imm)
        elif mn == "lw":
            _, rd, off, rs = ins
            assert off == 0
            rset(rd, dtcm.get(rget(rs), 0))
        elif mn == "sw":
            _, rs2, off, rs1 = ins
            assert off == 0
            dtcm[rget(rs1)] = rget(rs2)
        elif mn == "div":
            _, rd, ra, rb = ins
            rset(rd, rget(ra) // rget(rb))       # positive operands only here
        elif mn == "rem":
            _, rd, ra, rb = ins
            rset(rd, rget(ra) % rget(rb))
        elif mn == "beq":
            _, ra, rb, off = ins
            if rget(ra) == rget(rb):
                if off == 0:                     # the sentinel
                    return dtcm
                pc = pc + off
                continue
        else:
            raise AssertionError(f"instruction outside the subset: {ins}")
        pc += 4
    raise AssertionError("interpreter never reached the sentinel")


def main():
    prog, labels = build()
    words = [ins[1] if ins[0] == "RAW" else enc(*ins) for ins in prog]

    dtcm = interpret(prog, labels)

    poll1, poll2 = labels["POLL1"], labels["POLL2"]
    postdiv, sentinel = labels["POSTDIV"], labels["SENTINEL"]

    # -- declared expectations, cross-checked against the interpreter --------
    exact = {
        0x100: 1, 0x108: 1, 0x10C: 142, 0x110: 6, 0x114: 0x5D,
        0x180: 0, 0x188: 0xB7, 0x18C: 0,
        0x200: 1, 0x204: 1,
        0x010: labels["ISR_BT"], 0x014: labels["ISR_KEY1"],
    }
    for a, v in exact.items():
        got = dtcm.get(a, 0)
        if got != v:
            sys.exit(f"CROSS-CHECK FAILED at [{a:#06x}]: interpreter has "
                     f"{got:#x}, declared {v:#x}")
    tp1_isr, tp1_main = dtcm.get(0x184, -1), dtcm.get(0x104, -1)
    if tp1_isr != tp1_main:
        sys.exit("CROSS-CHECK FAILED: ISR tp and main tp differ")
    if not (poll1 <= tp1_isr <= poll1 + 4):
        sys.exit(f"CROSS-CHECK FAILED: tp1 {tp1_isr:#x} outside POLL1")
    tp3 = dtcm.get(0x190, -1)
    if not (postdiv <= tp3 <= sentinel):
        sys.exit(f"CROSS-CHECK FAILED: tp3 {tp3:#x} outside the post-div range")

    out = ROOT / "SIM" / "RV32IMscMCU" / "intr"
    out.mkdir(parents=True, exist_ok=True)
    (out / "ITCM.hex").write_text(ihex(words))
    (out / "DTCM.hex").write_text(ihex([0] * 1024))

    div_word = enc("div", "t6", "a6", "a7")
    lines = [
        "Directed core-level interrupt-protocol test -- tools/gen_intr_core_test.py",
        f"{len(prog)} instructions; three interrupt rounds (KEY1, BT, KEY1-during-div).",
        "",
        "Addresses the testbench needs (BYTE addresses):",
        f"  POLL1    = {poll1:#06x}   (tp1 expected in [{poll1:#06x}, {poll1+4:#06x}])",
        f"  POLL2    = {poll2:#06x}",
        f"  DIVPH    = {labels['DIVPH']:#06x}   div word = 0x{div_word:08x}",
        f"  POSTDIV  = {postdiv:#06x}   (tp3 expected in [{postdiv:#06x}, {sentinel:#06x}])",
        f"  SENTINEL = {sentinel:#06x}",
        f"  ISR_KEY1 = {labels['ISR_KEY1']:#06x}  -> DTCM word 5 (TYPE 0x14)",
        f"  ISR_BT   = {labels['ISR_BT']:#06x}  -> DTCM word 4 (TYPE 0x10)",
        "",
        "Expected DTCM after the sentinel (the testbench holds these):",
    ]
    for a in sorted(exact):
        lines.append(f"  [{a:#06x}] = {exact[a]:#x}")
    lines += [
        f"  [0x0104] = [0x0184] = tp1 (range above)",
        f"  [0x0190] = tp3 (range above)",
        "",
        f"Interpreter (protocol emulated, 3 injections): tp1={tp1_isr:#x}, "
        f"tp3={tp3:#x} -- both landing where the ranges say.",
    ]
    (out / "listing.txt").write_text("\n".join(lines) + "\n")

    print(f"  {len(prog)} instructions; tp1={tp1_isr:#x} tp3={tp3:#x}")
    print(f"  POLL1={poll1:#x} POSTDIV={postdiv:#x} SENTINEL={sentinel:#x} "
          f"ISR_KEY1={labels['ISR_KEY1']:#x} ISR_BT={labels['ISR_BT']:#x}")
    print(f"  div word 0x{div_word:08x}")
    print(f"  wrote {out}/ITCM.hex, DTCM.hex, listing.txt")


if __name__ == "__main__":
    main()
