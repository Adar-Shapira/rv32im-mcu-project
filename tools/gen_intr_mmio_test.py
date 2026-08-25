#!/usr/bin/env python3
"""Generate the directed MCU-LEVEL interrupt test -- Phase 9C's verification.

WHY THIS EXISTS
    Phase 9C wires the two separately-proven halves together: INTERRUPT_CTRL
    (9A, leaf) onto the bus at 0x202C/D/E, and the core's entry FSM (9B,
    core-level) onto the real INTR/INTA/TYPE-push. What remains unproven is
    exactly the WIRING: CS_INTC and the three lanes, the TYPE push as a real
    bus driver, bt_ifg_set_w and key_pressed_w as real sources, and gie/intr/
    inta between core and controller. The supplied interrupt benchmarks then
    run in Phase 10; this directed program isolates the wiring first, at
    either G_ISA_REPAIR setting, with EXACT expectations throughout.

WHAT IT PROVES (with tb_intr_mmio.vhd, which only presses KEY1 and watches)
      [0x010]=ISR_BT, [0x014]=ISR_KEY1   the program built its vector table
      [0x208]=1                          init done (the bench presses KEY1 now)
    Round 1 -- a REAL KEY1 press+release through the pin, PORT_PB's own
    key_pressed_w, the controller's release-edge latch, INTR, the entry:
      [0x180]=0x14   TYPE read at 0x202E (lane 2!) inside the ISR, while
                     KEY1IFG is still pending -- rule d end to end
      [0x184]=0x08   IFG read at the ODD address 0x202D: KEY1IFG visible
      [0x188]=0x00   IFG after the benchmark ISR idiom (and-mask, store):
                     W0C through the real bus
      [0x200]=1      flag1 -- the ISR ran and reti returned
    Round 2 -- the timer counts 201 pclk ticks and interrupts BY ITSELF
    (bt_ifg_set_w finally consumed):
      [0x18C]=0x00   IFG read inside the BT ISR: BTIFG was auto-cleared at
                     service (rule a) -- through the real bus
      [0x204]=1      flag2
    Wrap-up, all through the bus:
      [0x100]=0x00   IFG idle    [0x104]=0x0C  IE reads back KEY1IE|BTIE
      [0x108]=0x00   TYPE idle   [0x10C]=1     gp -- GIE restored by reti
      [0x110]=0x5D   end marker -- main resumed and finished
    14 scored stores, every value EXACT -- no ranges: the two interrupt
    moments are pinned by the program itself (a poll loop and a timer count).

THE SECOND DERIVATION -- the vetted models COMPOSED, not re-derived
    The interpreter below executes the program with model_interrupt_ctrl.Intc
    (twelve mutations caught) and model_basic_timer.Timer (eight) sitting on
    the bus, one edge each per instruction, and the 9B protocol emulated
    between them (3 cycles per entry). Generation aborts if the final DTCM
    disagrees with the declared expectations. Nothing about either peripheral
    is re-modelled here -- the standing check-the-labs/reuse rule applied to
    our own verified code.

USAGE
    python3 tools/gen_intr_mmio_test.py
        writes SIM/RV32IMscMCU/intrmmio/{ITCM.hex,DTCM.hex,listing.txt}
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import enc, li32, ihex, M32               # noqa: E402
from model_interrupt_ctrl import Intc                       # noqa: E402
from model_basic_timer import Timer                         # noqa: E402

RETI_WORD = 0x00020067

IE_A, IFG_A, TYPE_A = 0x202C, 0x202D, 0x202E
BTCTL1_A, BTCMPR0_A = 0x201C, 0x2020

BT_PERIOD = 200          # BTCMPR0: EQU0 every 201 pclk ticks


# ── the program ──────────────────────────────────────────────────────────────
def build():
    prog, labels = [], {}

    def emit(*ins):
        prog.append(tuple(ins))

    def label(name):
        labels[name] = len(prog)

    def li(reg, val):
        for ins in li32(reg, val):
            emit(*ins)

    # a0..a4 = the five MMIO addresses; s* = DTCM pointers; gp/tp = protocol's
    li("a0", IE_A)
    li("a1", IFG_A)
    li("a2", TYPE_A)
    li("a3", BTCTL1_A)
    li("a4", BTCMPR0_A)
    emit("addi", "s0", "zero", 0x100)     # wrap-up scratch
    emit("addi", "s1", "zero", 0x10)      # vector word 4 (BT)
    emit("addi", "s2", "zero", 0x14)      # vector word 5 (KEY1)
    emit("addi", "s3", "zero", 0x200)     # flag1
    emit("addi", "s4", "zero", 0x180)     # ISR scratch
    emit("addi", "s5", "zero", 0x204)     # flag2
    emit("addi", "s7", "zero", 0x208)     # ready marker

    # test1's exact init order: IE=0, IFG=0 while masked, THEN configure
    emit("sw", "zero", 0, "a0")
    emit("sw", "zero", 0, "a1")
    emit("addi", "t0", "zero", "ISR_BT")
    emit("sw",   "t0", 0, "s1")
    emit("addi", "t0", "zero", "ISR_KEY1")
    emit("sw",   "t0", 0, "s2")
    emit("addi", "t0", "zero", 0x08)      # KEY1IE only for round 1
    emit("sw",   "t0", 0, "a0")
    emit("addi", "gp", "zero", 1)         # EINT
    emit("addi", "t5", "zero", 1)
    label("READY")
    emit("sw",   "t5", 0, "s7")           # [0x208]=1: the bench presses KEY1 now

    label("POLL1")
    emit("lw",  "t5", 0, "s3")
    emit("beq", "t5", "zero", -4)

    # round 2: the timer interrupts by itself
    emit("addi", "t0", "zero", 0x24)      # BTCTL1: hold + clear
    emit("sw",   "t0", 0, "a3")
    emit("addi", "t0", "zero", BT_PERIOD)
    emit("sw",   "t0", 0, "a4")           # BTCMPR0
    emit("addi", "t0", "zero", 0x0C)      # IE = BTIE | KEY1IE
    emit("sw",   "t0", 0, "a0")
    emit("sw",   "zero", 0, "a3")         # BTCTL1 = 0: run, BTINT=00 (EQU0)

    label("POLL2")
    emit("lw",  "t5", 0, "s5")
    emit("beq", "t5", "zero", -4)

    # wrap-up: everything read back through the bus
    emit("lw", "t1", 0, "a1")
    emit("sw", "t1", 0, "s0")             # [0x100] IFG idle = 0
    emit("addi", "s0", "s0", 4)
    emit("lw", "t1", 0, "a0")
    emit("sw", "t1", 0, "s0")             # [0x104] IE = 0x0C
    emit("addi", "s0", "s0", 4)
    emit("lw", "t1", 0, "a2")
    emit("sw", "t1", 0, "s0")             # [0x108] TYPE idle = 0
    emit("addi", "s0", "s0", 4)
    emit("sw", "gp", 0, "s0")             # [0x10C] GIE restored = 1
    emit("addi", "s0", "s0", 4)
    emit("addi", "t0", "zero", 0x5D)
    emit("sw", "t0", 0, "s0")             # [0x110] end marker
    emit("beq", "zero", "zero", 0)        # sentinel

    label("ISR_KEY1")
    emit("lw", "t3", 0, "a2")
    emit("sw", "t3", 0, "s4")             # [0x180] TYPE while pending = 0x14
    emit("addi", "s4", "s4", 4)
    emit("lw", "t3", 0, "a1")             # the ODD address 0x202D (F15)
    emit("sw", "t3", 0, "s4")             # [0x184] IFG = 0x08 (KEY1IFG)
    emit("addi", "s4", "s4", 4)
    emit("addi", "t4", "zero", 0xF7)      # KEY1IFG_MASK's low byte
    emit("and",  "t3", "t3", "t4")        # the benchmark ISR idiom (and, NOT
    emit("sw",   "t3", 0, "a1")           # andi -- andi is defect 1)
    emit("lw", "t3", 0, "a1")
    emit("sw", "t3", 0, "s4")             # [0x188] IFG after W0C = 0
    emit("addi", "s4", "s4", 4)
    emit("addi", "t5", "zero", 1)
    emit("sw",   "t5", 0, "s3")           # flag1
    emit("RAW", RETI_WORD)

    label("ISR_BT")
    emit("addi", "t5", "zero", 0x20)      # BTCTL1: hold -- stop the timer first
    emit("sw",   "t5", 0, "a3")
    emit("lw", "t3", 0, "a1")
    emit("sw", "t3", 0, "s4")             # [0x18C] IFG = 0: rule a, end to end
    emit("addi", "s4", "s4", 4)
    emit("addi", "t5", "zero", 1)
    emit("sw",   "t5", 0, "s5")           # flag2
    emit("RAW", RETI_WORD)

    out = []
    for ins in prog:
        if ins[0] == "addi" and isinstance(ins[3], str):
            out.append(("addi", ins[1], ins[2], labels[ins[3]] * 4))
        else:
            out.append(ins)
    return out, {k: v * 4 for k, v in labels.items()}


# ── the second derivation: the two vetted models on the bus ──────────────────
def interpret(prog, labels):
    regs, dtcm = {}, {}
    intc, tmr = Intc(), Timer()

    def rget(r): return regs.get(r, 0)

    def rset(r, v):
        if r != "zero":
            regs[r] = v & M32

    key_on = [None, None]        # [start_cycle, end_cycle) once READY seen
    cyc = 0
    pc = 0
    steps = 0

    def keys_now():
        if key_on[0] is not None and key_on[0] <= cyc < key_on[1]:
            return (1, 0, 0)
        return (0, 0, 0)

    def tick(wr_t=None, wr_i=None, inta=1):
        """one pclk edge for both peripherals; returns nothing needed."""
        nonlocal cyc
        bt = tmr.edge(wr=wr_t)
        intc.edge(wr=wr_i, bt=bt, keys=keys_now(),
                  gie=rget("gp") & 1, inta=inta)
        cyc += 1

    def mmio_read(a):
        if a == IE_A:   return intc.ie
        if a == IFG_A:  return intc.view()
        if a == TYPE_A: return intc.type_now()
        raise AssertionError(f"unexpected MMIO read {a:#x}")

    def mmio_wr_tuples(a, v):
        if a == IE_A:      return None, ("ie", v)
        if a == IFG_A:     return None, ("ifg", v)
        if a == BTCTL1_A:  return ("ctl", 0, v), None
        if a == BTCMPR0_A: return ("cmpr0", 0, v), None
        raise AssertionError(f"unexpected MMIO write {a:#x}")

    while steps < 20000:
        steps += 1

        # the 9B entry, on the same condition the RTL uses (view AND gie)
        if intc.view() != 0 and (rget("gp") & 1) == 1:
            tick(inta=0)                          # accept: capture + svc-clear
            tick()                                # Cycle 1 (push)
            tick()                                # Cycle 2 (vector fetch)
            rset("gp", rget("gp") & ~1)
            rset("tp", pc)
            pc = dtcm.get(intc.type_capt, 0)
            continue

        ins = prog[pc // 4]
        mn = ins[0]
        wr_t = wr_i = None

        if mn == "RAW" and ins[1] == RETI_WORD:
            rset("gp", rget("gp") | 1)
            pc = rget("tp")
            tick()
            continue
        if mn == "addi":
            _, rd, rs, imm = ins
            rset(rd, rget(rs) + imm)
        elif mn == "slli":
            _, rd, rs, sh = ins
            rset(rd, rget(rs) << sh)
        elif mn == "and":
            _, rd, ra, rb = ins
            rset(rd, rget(ra) & rget(rb))
        elif mn == "lw":
            _, rd, off, rs = ins
            assert off == 0
            a = rget(rs)
            rset(rd, mmio_read(a) if a >= 0x2000 else dtcm.get(a, 0))
        elif mn == "sw":
            _, rs2, off, rs1 = ins
            assert off == 0
            a, v = rget(rs1), rget(rs2)
            if a >= 0x2000:
                wr_t, wr_i = mmio_wr_tuples(a, v)
            else:
                dtcm[a] = v
                if a == 0x208 and key_on[0] is None:
                    key_on[0], key_on[1] = cyc + 3, cyc + 8   # the bench's press
        elif mn == "beq":
            _, ra, rb, off = ins
            if rget(ra) == rget(rb):
                if off == 0:
                    return dtcm
                pc += off
                tick()
                continue
        else:
            raise AssertionError(f"instruction outside the subset: {ins}")
        pc += 4
        tick(wr_t=wr_t, wr_i=wr_i)
    raise AssertionError("interpreter never reached the sentinel")


EXPECT = {
    0x010: None, 0x014: None,            # filled from labels
    0x208: 1,
    0x180: 0x14, 0x184: 0x08, 0x188: 0x00, 0x200: 1,
    0x18C: 0x00, 0x204: 1,
    0x100: 0x00, 0x104: 0x0C, 0x108: 0x00, 0x10C: 1, 0x110: 0x5D,
}


def main():
    prog, labels = build()
    words = [ins[1] if ins[0] == "RAW" else enc(*ins) for ins in prog]

    EXPECT[0x010] = labels["ISR_BT"]
    EXPECT[0x014] = labels["ISR_KEY1"]

    dtcm = interpret(prog, labels)
    for a, v in EXPECT.items():
        got = dtcm.get(a, 0)
        if got != v:
            sys.exit(f"CROSS-CHECK FAILED at [{a:#06x}]: the composed models "
                     f"produce {got:#x}, declared {v:#x}")
    extra = set(dtcm) - set(EXPECT)
    if extra:
        sys.exit(f"CROSS-CHECK FAILED: unexpected stores at "
                 f"{[hex(a) for a in sorted(extra)]}")

    out = ROOT / "SIM" / "RV32IMscMCU" / "intrmmio"
    out.mkdir(parents=True, exist_ok=True)
    (out / "ITCM.hex").write_text(ihex(words))
    (out / "DTCM.hex").write_text(ihex([0] * 1024))

    lines = [
        "Directed MCU-level interrupt test -- tools/gen_intr_mmio_test.py",
        f"{len(prog)} instructions; a real KEY1 release and a real timer EQU0.",
        "",
        "The bench's one job: when [0x208]=1 is stored, press KEY1 for a few",
        "cycles and release. Everything else is the program and the hardware.",
        "",
        f"  READY marker address = 0x208   (store at instr {labels['READY']//4})",
        f"  ISR_KEY1 = {labels['ISR_KEY1']:#06x} -> DTCM word 5 (TYPE 0x14)",
        f"  ISR_BT   = {labels['ISR_BT']:#06x} -> DTCM word 4 (TYPE 0x10)",
        f"  BT period: BTCMPR0={BT_PERIOD} -> EQU0 every {BT_PERIOD+1} pclk",
        "",
        "Expected DTCM after the sentinel -- 14 stores, ALL EXACT:",
    ]
    for a in sorted(EXPECT):
        lines.append(f"  [{a:#06x}] = {EXPECT[a]:#04x}")
    lines += [
        "",
        "Derived twice: declared here, and reproduced by executing the program",
        "against model_interrupt_ctrl.Intc + model_basic_timer.Timer composed",
        "on the bus with the 9B entry protocol emulated between them.",
    ]
    (out / "listing.txt").write_text("\n".join(lines) + "\n")

    print(f"  {len(prog)} instructions, 14 exact stores")
    print(f"  ISR_KEY1={labels['ISR_KEY1']:#x} ISR_BT={labels['ISR_BT']:#x} "
          f"READY store idx={labels['READY']//4}")
    print(f"  wrote {out}/ITCM.hex, DTCM.hex, listing.txt")


if __name__ == "__main__":
    main()
