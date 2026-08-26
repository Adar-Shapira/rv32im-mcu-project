#!/usr/bin/env python3
"""Generate the directed Basic Timer MMIO test -- Phase 8B's verification.

WHY THIS EXISTS
    No supplied benchmark can exercise the timer's bus wiring on its own: every
    Interrupt-based IO test configures the timer and then waits for INTERRUPTS,
    which need Phase 9's controller -- without it they hang in their idle loop.
    So Phase 8B gets what Phase 6D got: a small directed program, generated so
    the program and its expectations cannot drift apart.

WHAT IT PROVES (the WIRING -- the timer core itself was proven cycle-exact by
tb_basic_timer + model_basic_timer, eight mutations caught; none of that is
re-proven here):
      S1  BTCTL1 write via lane0 lands, and reads back        = 0x24
      S2  BTCTL2 write via the ODD byte address 0x201D lands  = 0x07
          (F15's byte addressing, lane1, at MCU level)
      S3  BTCMPR0 word write lands and reads back             = 40
      S4  BTCMPR1 word write lands and reads back             = 10
      S5  BTCAPR reads ZERO before any capture -- and the configuration in
          force is test4's actual 0x07 (rising edge, source=GND), so this
          doubles as the MCU-level echo of the benchmark bug: no edge, no
          capture.
      S6  after running briefly, holding, and flipping CAPISEL GND->VCC
          (the edge test4 MEANT to make): BTCAPR reads the captured count.
      S7  a second read of BTCAPR returns the SAME value -- a real, stable
          register behind the bus, not bus garbage.
    Then BTCTL1 = 0x40 starts PWM (mode0, BTCL0=40, BTCL1=10) and the program
    parks on the beq sentinel; the testbench measures PWM_o at the pin:
    high 10 cycles, low 31, period 41.

WHY S6 IS RANGE-CHECKED, NOT EXACT
    The captured value K = the number of cycles the counter ran between the
    run-write and the hold-write. The interpreter below predicts it exactly
    under the 1-instruction-per-cycle model of the single-cycle core, and the
    listing prints that prediction -- but pinning the testbench to it would
    weld the test to an edge-level timing detail that is one honest off-by-one
    away from a false alarm on ModelSim. The wiring claim needs only:
    K is non-zero (the counter really ran and really captured), K is small
    (it really held), and both reads agree. Exactness for capture semantics
    already lives in tb_basic_timer's P6, where the counter is frozen.

WHY THE PROGRAM AVOIDS MOST OF THE ISA
    Same discipline as gen_gpio_test.py, from when the core still carried the
    seven Lab 5 defects (repaired unconditionally since): addresses and
    constants come from li32() (addi+slli only), every load has offset 0,
    stores have offset 0, and the only branch is the sentinel with offset 0.
    No other instruction class appears.

THE SECOND DERIVATION
    The expected values are not just the constants the program wrote: the
    interpreter below EXECUTES the program instruction by instruction with
    tools/model_basic_timer.Timer -- the model eight mutations already vetted --
    sitting on the bus, one timer edge per instruction. Generation aborts if
    the interpreter's store stream disagrees with the declared expectations.

USAGE
    python3 tools/gen_timer_test.py
        writes SIM/RV32IMscMCU/timer/{ITCM.hex,DTCM.hex,listing.txt}
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import enc, li32, ihex, M32              # noqa: E402
from model_basic_timer import Timer                        # noqa: E402

# ── the MMIO map (const_package.vhd / io_map.s -- same twenty addresses) ─────
BTCTL1  = 0x201C
BTCTL2  = 0x201D
BTCMPR0 = 0x2020
BTCMPR1 = 0x2024
BTCAPR  = 0x2028

SCRATCH = 0x0100        # DTCM byte address of the first scored store (word 64)

# ── the program ──────────────────────────────────────────────────────────────
def build():
    prog = []

    def emit(*ins):
        prog.append(tuple(ins))

    def li(reg, val):
        for ins in li32(reg, val):
            emit(*ins)

    # register plan: a0..a4 = the five timer addresses, s0 = scratch pointer,
    # t0 = write constant, t1 = read value, t2 = filler counter
    li("a0", BTCTL1)
    li("a1", BTCTL2)
    li("a2", BTCMPR0)
    li("a3", BTCMPR1)
    li("a4", BTCAPR)
    li("s0", SCRATCH)

    def wr(addr_reg, val):
        li("t0", val)
        emit("sw", "t0", 0, addr_reg)

    def rd_store(addr_reg):
        emit("lw", "t1", 0, addr_reg)
        emit("sw", "t1", 0, "s0")
        emit("addi", "s0", "s0", 4)

    # -- configure while held, then read everything back ---------------------
    wr("a0", 0x24)          # BTCTL1: BTHOLD + BTCLR -- parked at zero
    wr("a1", 0x07)          # BTCTL2 via ODD address: CAPMD=rising, CAPISEL=GND
    wr("a2", 40)            # BTCMPR0 (word)
    wr("a3", 10)            # BTCMPR1 (word)
    rd_store("a0")          # S1 = 0x24
    rd_store("a1")          # S2 = 0x07
    rd_store("a2")          # S3 = 40
    rd_store("a3")          # S4 = 10
    rd_store("a4")          # S5 = 0   (source parked on GND: test4's bug, echoed)

    # -- capture: run briefly, hold at a small non-zero count, force the edge -
    wr("a0", 0x02)          # run (HOLD=0, CLR=0, BTINT=capture)
    emit("addi", "t2", "zero", 0)
    emit("addi", "t2", "t2", 1)
    emit("addi", "t2", "t2", 1)
    emit("addi", "t2", "t2", 1)
    wr("a0", 0x22)          # hold: BTCNT frozen at K
    wr("a1", 0x06)          # CAPISEL GND->VCC: the rising edge test4 meant
    emit("addi", "t2", "t2", 1)    # let the 3-stage capture chain drain
    emit("addi", "t2", "t2", 1)
    emit("addi", "t2", "t2", 1)
    emit("addi", "t2", "t2", 1)
    rd_store("a4")          # S6 = K
    rd_store("a4")          # S7 = K again -- stable register, not bus noise

    # -- PWM at the pin, then park -------------------------------------------
    wr("a0", 0x40)          # run, BTOUTEN, Mode0; BTCL0=40, BTCL1=10
    emit("beq", "zero", "zero", 0)      # sentinel self-loop (0x00000063)

    return prog


# ── the second derivation: execute with the vetted timer model on the bus ────
REGN = {"zero": 0, "t0": 5, "t1": 6, "t2": 7,
        "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "s0": 8}
# (numbers only matter for the interpreter's register file; enc() has its own)


def interpret(prog):
    """One instruction per cycle -- the single-cycle core -- with one timer
    edge per instruction. Returns the store stream [(addr, value)] and the
    predicted captured count K."""
    t = Timer()
    regs = {}
    dtcm = {}
    stores = []

    def rget(r): return regs.get(r, 0)

    def timer_read(addr):
        return {BTCTL1: t.ctl1, BTCTL2: t.ctl2, BTCMPR0: t.cmpr0,
                BTCMPR1: t.cmpr1, BTCAPR: t.capr}[addr]

    for ins in prog:
        mn = ins[0]
        wr_tuple = None
        if mn == "addi":
            _, rd, rs, imm = ins
            regs[rd] = (rget(rs) + imm) & M32
        elif mn == "slli":
            _, rd, rs, sh = ins
            regs[rd] = (rget(rs) << sh) & M32
        elif mn == "lw":
            _, rd, off, rs = ins
            assert off == 0
            a = rget(rs)
            regs[rd] = timer_read(a) if a >= 0x2000 else dtcm.get(a, 0)
        elif mn == "sw":
            _, rs2, off, rs1 = ins
            assert off == 0
            a, v = rget(rs1), rget(rs2)
            stores.append((a, v))
            if a >= 0x2000:
                which = {BTCTL1: ("ctl", 0), BTCTL2: ("ctl", 1),
                         BTCMPR0: ("cmpr0", 0), BTCMPR1: ("cmpr1", 0),
                         BTCAPR: None}.get(a)
                if which:
                    wr_tuple = (which[0], which[1], v)
            else:
                dtcm[a] = v
        elif mn == "beq":
            break                      # the sentinel: stop interpreting
        else:
            raise AssertionError(f"instruction outside the safe subset: {mn}")
        if "zero" in regs:
            regs["zero"] = 0
        t.edge(wr=wr_tuple)            # every instruction is one pclk edge

    return stores, t


def main():
    prog = build()
    words = [enc(*ins) for ins in prog]

    stores, t = interpret(prog)
    dtcm_stores = [(a, v) for a, v in stores if a < 0x2000]
    k = dtcm_stores[5][1]              # S6's value = the predicted K

    # -- declared expectations, cross-checked against the interpreter --------
    expect = [
        (SCRATCH + 0x00, 0x24, "exact", "BTCTL1 read-back (lane0 write)"),
        (SCRATCH + 0x04, 0x07, "exact", "BTCTL2 read-back (ODD-address write)"),
        (SCRATCH + 0x08, 40,   "exact", "BTCMPR0 word read-back"),
        (SCRATCH + 0x0C, 10,   "exact", "BTCMPR1 word read-back"),
        (SCRATCH + 0x10, 0,    "exact", "BTCAPR before any edge (test4-bug echo)"),
        (SCRATCH + 0x14, k,    "range", "BTCAPR after the forced edge (K)"),
        (SCRATCH + 0x18, k,    "same",  "BTCAPR again -- must equal S6"),
    ]
    for (addr, val, kind, name), (ga, gv) in zip(expect, dtcm_stores):
        if ga != addr or (kind == "exact" and gv != val):
            sys.exit(f"CROSS-CHECK FAILED at {name}: interpreter stored "
                     f"({ga:#06x}, {gv}) vs declared ({addr:#06x}, {val})")
    if len(dtcm_stores) != len(expect):
        sys.exit(f"CROSS-CHECK FAILED: {len(dtcm_stores)} DTCM stores, "
                 f"expected {len(expect)}")
    if not (1 <= k <= 60):
        sys.exit(f"CROSS-CHECK FAILED: predicted K = {k} outside [1, 60]")
    if dtcm_stores[6][1] != k:
        sys.exit("CROSS-CHECK FAILED: S7 differs from S6 in the interpreter")

    # -- PWM state the testbench will measure --------------------------------
    assert t.ctl1 == 0x40 and t.cl0 == 40 and t.cl1 == 10, "end state wrong"

    out = ROOT / "SIM" / "RV32IMscMCU" / "timer"
    out.mkdir(parents=True, exist_ok=True)
    (out / "ITCM.hex").write_text(ihex(words))
    (out / "DTCM.hex").write_text(ihex([0] * 1024))

    lines = [
        "Directed Basic Timer MMIO test -- generated by tools/gen_timer_test.py",
        f"{len(prog)} instructions, 7 scored DTCM stores at 0x100..0x118.",
        "",
        "Expected stores (the testbench holds these):",
    ]
    for addr, val, kind, name in expect:
        tag = {"exact": f"= {val:#010x}",
               "range": f"in [1, 60]   (interpreter predicts {k})",
               "same":  "equal to the previous store"}[kind]
        lines.append(f"  [{addr:#06x}] {tag:<40} {name}")
    lines += [
        "",
        "Then BTCTL1 = 0x40 starts PWM: mode0, BTCL0=40, BTCL1=10 ->",
        "PWM_o high 10 pclk, low 31 pclk, period 41. Measured at the pin by",
        "tb_timer_mmio after the beq sentinel is reached.",
        "",
        f"Interpreter-predicted captured count K = {k} (one instruction per",
        "cycle, one timer edge per instruction, the vetted Timer model on the",
        "bus). The testbench checks range+equality, not K itself -- see the",
        "header of gen_timer_test.py for why.",
    ]
    (out / "listing.txt").write_text("\n".join(lines) + "\n")

    print(f"  {len(prog)} instructions, 7 scored stores, predicted K = {k}")
    print(f"  wrote {out}/ITCM.hex, DTCM.hex, listing.txt")


if __name__ == "__main__":
    main()
