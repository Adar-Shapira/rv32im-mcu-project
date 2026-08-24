#!/usr/bin/env python3
"""Bit-exact model of DUT/RV32IMscMCU/BASIC_TIMER.vhd, run through the same
phases as TB/RV32IMscMCU/tb_basic_timer.vhd.

WHY (same reason as model_div_accel.py / model_div_unit.py): the toolchain is
Windows-only, so the RTL cannot be compiled here -- and every expected number in
the testbench (10/20/40/80 prescaler periods, 6-of-20 and 14-of-20 PWM duty,
exactly 5 pulses in 25 cycles, the 4008-cycle FREQ_5K interval) was derived by
hand, which is where off-by-ones live. This executes the RTL's semantics per
clock edge and checks every one of those numbers. It caught its keep during
development: the first draft of the P3 Mode1 window and the P6 park-at-nonzero
sequence were both wrong, found by tracing exactly what this file executes.

The model mirrors the VHDL processes one for one: all clocked processes sample
PRE-edge state simultaneously; combinational signals are functions of current
state. A bus write is active for exactly one edge, like the testbench's
falling-edge-aligned bus_write. Every check here is phase-robust (measured
between events or over whole periods), so the one thing the model cannot mirror
exactly -- the few alignment cycles the TB procedures consume -- cannot move a
result.
"""

import sys

M32 = 0xFFFFFFFF


class Timer:
    """The actual model used: explicit pre-edge snapshot, then commit."""

    def __init__(self):
        self.ctl1 = 0; self.ctl2 = 0
        self.cmpr0 = 0; self.cmpr1 = 0; self.capr = 0
        self.cl0 = 0; self.cl1 = 0
        self.cnt = 0; self.presc = 0
        self.pwm = 0
        self.s1 = self.s2 = self.d = 0

    def fields(self):
        c1 = self.ctl1
        return dict(outmd=(c1 >> 7) & 1, outen=(c1 >> 6) & 1,
                    hold=(c1 >> 5) & 1, ssel=(c1 >> 3) & 3,
                    clr=(c1 >> 2) & 1, intc=c1 & 3,
                    capmd=(self.ctl2 >> 2) & 3, capisel=self.ctl2 & 3)

    def edge(self, rst=0, wr=None, capin1=0, capin2=0):
        f = self.fields()                       # PRE-edge control fields
        tick = {0: 1, 1: self.presc & 1,
                2: 1 if (self.presc & 3) == 3 else 0,
                3: 1 if (self.presc & 7) == 7 else 0}[f["ssel"]]
        count_en = tick and not f["hold"] and not f["clr"]
        equ0 = 1 if self.cnt == self.cl0 else 0
        equ1 = 1 if self.cnt == self.cl1 else 0
        cap_src = {0: capin1, 1: capin2, 2: 1, 3: 0}[f["capisel"]]
        if f["capmd"] == 1:
            cap_ev = 1 if (self.s2 and not self.d) else 0
        elif f["capmd"] == 2:
            cap_ev = 1 if (not self.s2 and self.d) else 0
        else:
            cap_ev = 0
        equ0_ev = equ0 and count_en
        equ1_ev = equ1 and count_en
        ifg = [equ0_ev, equ1_ev, cap_ev, 0][f["intc"]]

        pre_cnt, pre_s1, pre_s2 = self.cnt, self.s1, self.s2

        # commit: regs
        if rst:
            self.ctl1 = self.ctl2 = self.cmpr0 = self.cmpr1 = 0
            self.capr = self.cl0 = self.cl1 = 0
        else:
            if wr is not None:
                which, lane, val = wr
                if which == "ctl" and lane == 0: self.ctl1 = val & 0xFF
                if which == "ctl" and lane == 1: self.ctl2 = val & 0xFF
                if which == "cmpr0": self.cmpr0 = val & M32; self.cl0 = val & M32
                if which == "cmpr1": self.cmpr1 = val & M32; self.cl1 = val & M32
            if cap_ev:
                self.capr = pre_cnt
        # presc / count (no reset arms; pre-edge fields)
        self.presc = 0 if f["clr"] else (self.presc + 1) & 7
        if f["clr"]:
            self.cnt = 0
        elif count_en:
            self.cnt = 0 if equ0 else (pre_cnt + 1) & M32
        # outunit (pwm.vhd semantics; reset arm kept)
        if rst:
            self.pwm = 0
        elif f["outen"]:
            if f["outmd"] == 0:
                if pre_cnt == 0:   self.pwm = 1
                elif equ1:         self.pwm = 0
            else:
                if pre_cnt == 0:   self.pwm = 0
                elif equ1:         self.pwm = 1
        # capture chain
        self.d = pre_s2
        self.s2 = pre_s1
        self.s1 = cap_src

        return ifg


def main():
    t = Timer()
    fails = []
    ifg_total = 0

    def step(n=1, rst=0, wr=None, cap1=0, cap2=0):
        nonlocal ifg_total
        got = 0
        for _ in range(n):
            got += t.edge(rst=rst, wr=wr, capin1=cap1, capin2=cap2)
            wr = None                      # a bus write lasts one edge
        ifg_total += got
        return got

    def wctl1(v): step(wr=("ctl", 0, v))
    def wctl2(v, cap1=0): step(wr=("ctl", 1, v), cap1=cap1)
    def wcmpr0(v): step(wr=("cmpr0", 0, v))
    def wcmpr1(v): step(wr=("cmpr1", 0, v))

    def chk(ok, msg):
        if not ok:
            fails.append(msg)

    def measure_period(cap1=0):
        # sync to a pulse, then count edges to the next one
        guard = 0
        while t.edge(capin1=cap1) == 0:
            guard += 1
            assert guard < 100000, "no first pulse"
        n = 0
        while True:
            n += 1
            if t.edge(capin1=cap1):
                return n

    # ---- P0a ---------------------------------------------------------------
    step(5, rst=1)
    chk(t.ctl1 == 0 and t.cmpr0 == 0 and t.capr == 0, "P0a iface regs not clear")

    # ---- P1 ----------------------------------------------------------------
    wcmpr0(9)
    wctl1(0x00)
    chk(measure_period() == 10, "P1 ssel=00 != 10")
    wctl1(0x08); measure_period()
    chk(measure_period() == 20, "P1 ssel=01 != 20")
    wctl1(0x10); measure_period()
    chk(measure_period() == 40, "P1 ssel=10 != 40")
    wctl1(0x18); measure_period()
    chk(measure_period() == 80, "P1 ssel=11 != 80")

    # ---- P2 (inline: run two periods at ssel=00, watch cnt <= 9) ------------
    wctl1(0x00)
    ok = True
    for _ in range(25):
        t.edge()
        ok = ok and t.cnt <= 9
    chk(ok, "P2 cnt exceeded BTCL0")

    # ---- P3 ----------------------------------------------------------------
    wctl1(0x24)
    wcmpr1(3)
    wctl1(0x40)
    while t.edge() == 0: pass                  # sync to wrap
    hi = 0
    for _ in range(20):
        hi += t.pwm                            # pre-edge sample...
        t.edge()
    chk(hi == 6, f"P3 mode0 hi={hi} != 6")
    wctl1(0xC0)
    while t.edge() == 0: pass                  # settle wrap
    while t.edge() == 0: pass                  # sync wrap
    hi = 0
    for _ in range(20):
        hi += t.pwm
        t.edge()
    chk(hi == 14, f"P3 mode1 hi={hi} != 14")

    # ---- P4 ----------------------------------------------------------------
    wctl1(0x80)
    frozen = t.pwm
    mism = 0
    for _ in range(25):
        t.edge()
        mism += 1 if t.pwm != frozen else 0
    chk(mism == 0, f"P4 pwm moved {mism} times with OUTEN=0")

    # ---- P5 ----------------------------------------------------------------
    wctl1(0x20)
    v = t.cnt
    step(20)
    chk(t.cnt == v, "P5 hold: cnt moved")
    wctl1(0x24); step(1)
    chk(t.cnt == 0, "P5 clr: cnt != 0")

    # ---- P0b ---------------------------------------------------------------
    wcmpr0(1000000)
    wctl1(0x00)
    step(6)
    step(3, rst=1)
    step(1)
    chk(t.ctl1 == 0 and t.cmpr0 == 0, "P0b iface regs not clear")
    chk(t.cnt != 0, "P0b F16: BTCNT was cleared by reset")

    # ---- P6 ----------------------------------------------------------------
    wcmpr0(1000)
    wctl1(0x02)
    step(5)
    wctl1(0x22)
    v = t.cnt
    chk(v != 0, "P6 setup: parked at zero")
    base = ifg_total
    wctl2(0x07); step(30)
    chk(ifg_total == base and t.capr == 0, "P6a captured from GND source")
    wctl2(0x06); step(10)
    chk(ifg_total == base + 1, f"P6b captures = {ifg_total-base} != 1")
    chk(t.capr == v, f"P6b capr={t.capr} != frozen cnt {v}")
    base = ifg_total
    wctl2(0x0B); step(10)
    chk(ifg_total == base + 1, f"P6c captures = {ifg_total-base} != 1")
    base = ifg_total
    wctl2(0x02); step(10)
    chk(ifg_total == base, f"P6d capmd=00 fired {ifg_total-base}")
    wctl2(0x04); step(5)
    base = ifg_total
    step(10, cap1=1)
    chk(ifg_total == base + 1, f"P6e pin capture = {ifg_total-base} != 1")

    # ---- P7 ----------------------------------------------------------------
    wctl1(0x24)
    wcmpr0(4)
    base = ifg_total
    wctl1(0x03)
    step(40)
    chk(ifg_total == base, f"P7 reserved code pulsed {ifg_total-base}")
    wctl1(0x00)
    base = ifg_total
    step(25)
    chk(ifg_total == base + 5, f"P7 int=00: {ifg_total-base} != 5 in 25")

    # ---- P8 ----------------------------------------------------------------
    wctl1(0x24)
    wcmpr0(500)
    wctl1(0x18)
    measure_period()
    n = measure_period()
    chk(n == 4008, f"P8 FREQ_5K interval {n} != 4008")

    print(f"checks failed: {len(fails)}   (BTIFG events counted: {ifg_total})")
    for m in fails:
        print("  FAIL", m)
    if fails:
        return 1
    print("PASS -- every expected number in tb_basic_timer.vhd reproduces from")
    print("the RTL semantics: 10/20/40/80, duty 6/20 and 14/20, capture counts")
    print("1/1/0/1 with BTCAPR exact, 0 and 5 pulses for BTINT=11/00, and the")
    print("FREQ_5K interval of 4008 cycles (= 4990 Hz, the F17-literal finding).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
