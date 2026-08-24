#!/usr/bin/env python3
"""Bit-exact model of DUT/RV32IMscMCU/DIV_ACCEL.vhd, and its exhaustive check.

WHY THIS FILE EXISTS
    The whole toolchain is Windows-only (ModelSim ASE and Quartus both live on
    Adar's Lenovo), so RTL written here cannot be compiled here.  That is a bad
    reason to hand over a divider whose arithmetic has never been executed.
    This is a literal transcription of the VHDL -- the same shift, the same
    (N+1)-bit subtract, the same restore select, the same three-state FSM and the
    same counter -- run against Python's own // and %, which share nothing with
    it.  It cannot prove the VHDL compiles.  It does prove the algorithm and the
    cycle accounting, which is where the real risk was.

    tb_div_accel.vhd is the authority; this is what makes it likely to pass on
    the first run instead of the third.

    Companion to tools/gen_isa_test.py and tools/gen_gpio_test.py, which do the
    same job for the ISA and GPIO suites.
"""

import sys


class DivAccel:
    """One-for-one with DIV_ACCEL.vhd.  Each method maps to a named block there."""

    def __init__(self, n):
        self.n = n
        # the initial values on the signal declarations
        self.state = "IDLE"
        self.busy = 0
        self.sr = 0       # dividend left shift-register, 2N bits
        self.dvsr = 0     # divisor register, N bits
        self.qsr = 0      # quotient left shift-register, N bits
        self.cnt = 0

    # ---- the concurrent assignments: one restoring-division step ------------
    def _iter(self):
        n = self.n
        m2, mn = (1 << (2 * n)) - 1, (1 << n) - 1

        shifted = (self.sr << 1) & m2              # sr_q(2N-2 DOWNTO 0) & '0'
        y = (shifted >> n) & mn                    # shifted_w(2N-1 DOWNTO N)
        # unsigned('0' & y) - unsigned('0' & dvsr), N+1 bits, wraps mod 2**(N+1)
        diff = (y - self.dvsr) & ((1 << (n + 1)) - 1)
        nonneg = 0 if (diff >> n) & 1 else 1       # NOT diff_w(N)
        a_next = (diff & mn) if nonneg else y
        sr_next = ((a_next & mn) << n) | (shifted & mn)
        qsr_next = ((self.qsr << 1) & mn) | nonneg
        return sr_next, qsr_next

    # ---- the div_fsm process: one rising DIVCLK edge ------------------------
    def edge(self, divena, dividend=0, divisor=0, divrst=0):
        if divrst:                                  # asynchronous, wins outright
            self.state, self.busy = "IDLE", 0
            self.sr = self.dvsr = self.qsr = self.cnt = 0
            return

        if self.state == "IDLE":
            if divena:
                self.sr = dividend & ((1 << self.n) - 1)   # ZEROS_N & dividend_i
                self.dvsr = divisor & ((1 << self.n) - 1)
                self.qsr = 0
                self.cnt = self.n
                self.busy = 1
                self.state = "RUN"

        elif self.state == "RUN":
            sr_next, qsr_next = self._iter()
            if self.cnt == 1:                       # cnt_q reads its pre-edge value
                self.busy = 0
                self.state = "DONE"
            self.sr, self.qsr = sr_next, qsr_next
            self.cnt -= 1

        elif self.state == "DONE":
            if not divena:
                self.state = "IDLE"

    # ---- the output assignments --------------------------------------------
    @property
    def quotient(self):
        return self.qsr

    @property
    def residue(self):
        return self.sr >> self.n


def reference(dvd, dvs, n):
    """What the answer must be.  The zero-divisor row is the specification's, not
    Python's: quotient all ones, residue the dividend -- Hanan's forum answer
    (DOC/03, F4), and independently what RISC-V requires of divu/remu."""
    if dvs == 0:
        return (1 << n) - 1, dvd
    return dvd // dvs, dvd % dvs


def run_one(dut, dvd, dvs):
    """Mirrors tb_div_accel.vhd's do_div, including how it counts DIVBUSY cycles,
    so the latency number this prints is the number the testbench will assert on.

    Returns (quotient, residue, busy_cycles, busy_before_load, q_after_rearm,
    r_after_rearm).  The last three exist because an adversarial review of the
    testbench found that without them three real mutations of the RTL passed the
    whole suite:
      - DIVBUSY meaning "not DONE" rather than "running", i.e. permanently
        asserted between divides -- caught only by checking it is low BEFORE the
        load, since "high one cycle after the load" is also true of a signal that
        was already high;
      - DIVRST clearing only the FSM and not the shift registers -- caught only
        by aborting a divide whose partials are actually non-zero;
      - the engine wiping quotient and residue on the DONE -> IDLE re-arm --
        caught only by reading them again after DIVENA falls.
    """
    busy_before_load = dut.busy           # P1c: must be 0
    dut.edge(1, dvd, dvs)                 # the Load edge
    assert dut.state == "RUN", "the engine did not start"
    busy_cycles = 0
    guard = 4 * dut.n + 16
    while dut.busy and busy_cycles <= guard:
        dut.edge(1, dvd, dvs)
        busy_cycles += 1
    q, r = dut.quotient, dut.residue
    dut.edge(0)                           # DIVENA low: DONE -> IDLE
    # P3b: the result must still be there after the re-arm
    return q, r, busy_cycles, busy_before_load, dut.quotient, dut.residue


def main():
    fails = []
    checked = 0

    # ---- exhaustive at N = 8, every pair, zero divisor included -------------
    n = 8
    dut = DivAccel(n)
    for a in range(256):
        for b in range(256):
            q, r, cyc, b4, qa, ra = run_one(dut, a, b)
            eq, er = reference(a, b, n)
            checked += 1
            if (q, r) != (eq, er):
                fails.append(f"N=8 {a}/{b}: got q={q} r={r}, want q={eq} r={er}")
            if cyc != n:
                fails.append(f"N=8 {a}/{b}: DIVBUSY high {cyc} cycles, want {n}")
            if b4:
                fails.append(f"N=8 {a}/{b}: DIVBUSY was already high before the load")
            if (qa, ra) != (eq, er):
                fails.append(f"N=8 {a}/{b}: result lost on re-arm, "
                             f"q={qa} r={ra} after DIVENA fell")
    print(f"N=8  exhaustive : {checked} pairs (all 256x256), "
          f"{len(fails)} failure(s)")

    # ---- N = 32 ------------------------------------------------------------
    n = 32
    dut = DivAccel(n)
    before = len(fails)
    directed = [
        (0x00000000, 0x00000001), (0x00000001, 0x00000001),
        (0x00000007, 0x00000002), (0x00000064, 0x00000007),
        (0xFFFFFFFF, 0x00000001), (0xFFFFFFFF, 0xFFFFFFFF),
        # divisor at or above 2**31: the corner the N=8 sweep cannot reach, and
        # the only place the "an N-bit Y never overflows" argument could break
        (0xFFFFFFFF, 0x80000000), (0x80000000, 0x80000000),
        (0x80000000, 0x7FFFFFFF), (0x7FFFFFFF, 0x80000000),
        (0x7FFFFFFF, 0xFFFFFFFF), (0xFFFFFFFE, 0xFFFFFFFF),
        (0x00000000, 0x00000000), (0x00000001, 0x00000000),
        (0xDEADBEEF, 0x00000000), (0x80000000, 0xFFFFFFFF),
        (0x000003E8, 0x00000007),                 # the testbench's P7 case
    ]
    for a, b in directed:
        q, r, cyc, b4, qa, ra = run_one(dut, a, b)
        eq, er = reference(a, b, n)
        checked += 1
        if (q, r) != (eq, er):
            fails.append(f"N=32 0x{a:08X}/0x{b:08X}: got q=0x{q:08X} r=0x{r:08X}, "
                         f"want q=0x{eq:08X} r=0x{er:08X}")
        if cyc != n:
            fails.append(f"N=32 0x{a:08X}/0x{b:08X}: DIVBUSY {cyc} cycles, want {n}")
        if b4:
            fails.append(f"N=32 0x{a:08X}/0x{b:08X}: DIVBUSY already high pre-load")
        if (qa, ra) != (eq, er):
            fails.append(f"N=32 0x{a:08X}/0x{b:08X}: result lost on re-arm")
    print(f"N=32 directed   : {len(directed)} pairs, "
          f"{len(fails) - before} failure(s)")

    # ---- the same LFSR stream the testbench uses, so the two agree ---------
    before = len(fails)
    lf = 0x12345678

    def step(s):
        fb = ((s >> 31) ^ (s >> 21) ^ (s >> 1) ^ s) & 1
        return ((s << 1) | fb) & 0xFFFFFFFF

    ops = 500
    for i in range(1, ops + 1):
        lf = step(lf); a = lf
        lf = step(lf); b = lf
        if i % 8 == 0:
            b &= 0x000000FF
        elif i % 16 == 3:
            b |= 0x80000000
        q, r, cyc, b4, qa, ra = run_one(dut, a, b)
        eq, er = reference(a, b, n)
        checked += 1
        if (q, r) != (eq, er) or cyc != n or b4 or (qa, ra) != (eq, er):
            fails.append(f"N=32 random #{i} 0x{a:08X}/0x{b:08X}: "
                         f"got q=0x{q:08X} r=0x{r:08X} cyc={cyc} pre-busy={b4} "
                         f"rearm=(0x{qa:08X},0x{ra:08X}), "
                         f"want q=0x{eq:08X} r=0x{er:08X} cyc={n}")
    print(f"N=32 random     : {ops} pairs, {len(fails) - before} failure(s)")

    # ---- P5: DIVRST while busy, then the next divide must still be right ----
    before = len(fails)
    # 0xDEADBEEF/7 has BOTH partials non-zero from iteration 4 to 7, so the
    # clearing check below is not satisfied by the arithmetic.  The old operands
    # (0x0000FFFF/3) had sixteen leading zeros and both partials were provably
    # zero at the abort point, which made this test vacuous.  Same operands and
    # same abort point as tb_div_accel.vhd, so the two stay in step.
    DVD, DVS = 0xDEADBEEF, 0x00000007
    dut.edge(1, DVD, DVS)                 # load edge
    for _ in range(5):                    # five iterations
        dut.edge(1, DVD, DVS)
    if not dut.busy:
        fails.append("P5: the engine was not busy five iterations in")
    pre_q, pre_r = dut.quotient, dut.residue
    if pre_q == 0 or pre_r == 0:
        fails.append(f"P5 IS VACUOUS: partials at the abort point are "
                     f"q=0x{pre_q:X} r=0x{pre_r:X}; at least one is zero, so "
                     f"'DIVRST cleared it' cannot be told from 'never set'")
    dut.edge(1, DVD, DVS, divrst=1)
    if dut.busy or dut.quotient or dut.residue:
        fails.append("P5: DIVRST did not abort and clear")
    dut.edge(0)
    q, r, cyc, b4, qa, ra = run_one(dut, DVD, DVS)
    if (q, r, cyc) != (DVD // DVS, DVD % DVS, n) or b4 or (qa, ra) != (q, r):
        fails.append(f"P5: the divide after an abort gave q=0x{q:X} r=0x{r:X} "
                     f"cyc={cyc} pre-busy={b4}")
    print(f"P5 reset-while-busy : {len(fails) - before} failure(s)"
          f"   [partials at abort: q=0x{pre_q:X} r=0x{pre_r:X}]")

    # ---- P7: DIVENA held high past completion must not relaunch -------------
    before = len(fails)
    dut.edge(1, 1000, 7)
    while dut.busy:
        dut.edge(1, 1000, 7)
    hq, hr = dut.quotient, dut.residue
    if (hq, hr) != (142, 6):
        fails.append(f"P7 setup: 1000/7 gave q={hq} r={hr}, want q=142 r=6")
    for k in range(1, 21):
        dut.edge(1, 1000, 7)              # DIVENA still high
        if dut.busy:
            fails.append(f"P7: the engine RESTARTED {k} cycle(s) after finishing "
                         f"with DIVENA still high")
            break
        if (dut.quotient, dut.residue) != (hq, hr):
            fails.append(f"P7: the outputs moved after completion")
            break
    print(f"P7 divena-held-high : {len(fails) - before} failure(s)")

    print()
    print(f"total checked: {checked}")
    if fails:
        print(f"FAIL -- {len(fails)} failure(s):")
        for x in fails[:20]:
            print("   " + x)
        if len(fails) > 20:
            print(f"   ... and {len(fails) - 20} more")
        return 1
    print("PASS -- the algorithm is correct and DIVBUSY is high for exactly N "
          "DIVCLK cycles on every operation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
