#!/usr/bin/env python3
"""Bit-exact model of DUT/RV32IMscMCU/INTERRUPT_CTRL.vhd, run through the same
phases as TB/RV32IMscMCU/tb_interrupt_ctrl.vhd.

WHY (same reason as every model_*.py here): the toolchain is Windows-only, so
the RTL cannot be compiled locally, and the controller's structure -- RAW
request latches with a MASKED read view (irq AND eint = IFGx, the p13 diagram
taken literally, the falsified-A6 correction), W0C software writes that clear
the RAW latch, three service auto-clears, and KEY events that fire on the
RELEASE (DOC/03 section C: the debounced KEY line rises 0->1 on release, and
every request event is a rising edge by Hanan's own rule) -- has enough moving
parts that every expected value in the testbench was derived by executing THIS
file, not by hand.

The model mirrors the VHDL one for one:
  - all clocked processes sample PRE-edge state simultaneously;
  - irq (raw) latches: set NOT gated by IE, cleared by W0C / service / reset;
  - the visible IFG, the TYPE encoder and the INTR OR-tree all read the
    MASKED view irq AND ie -- a masked request is invisible everywhere but
    REMEMBERED (assumption A22: it reappears when IE is re-enabled, and no
    benchmark can tell because they all clear IFG before enabling);
  - the KEY chain is sync stage1 -> stage2 -> history flop, and the event is
    the FALLING edge of the pressed level = the release: hist AND NOT s2;
  - the INTA handshake captures TYPE and applies the service clear at the edge
    that ends the INTA-low cycle, and pushes during the following cycle.

edge() returns the controller's VISIBLE outputs during the cycle being ended
(pre-edge view), then commits -- exactly what a falling-edge sample of the RTL
mid-cycle would see.

Sources -> bits (REQ p14, benchmark-cross-checked in DOC/02 section 3.1):
  [0] RX  [1] TX  [2] BT  [3] KEY1  [4] KEY2  [5] KEY3
TYPE codes by priority: 08 (A23), 0C, 10, 14, 18, 1C; 00 when idle.
"""

import sys

TYPES = [0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C]     # per bit 0..5
AUTOCLR = {0x08: 0, 0x0C: 1, 0x10: 2}            # rules b / c / a; KEYs excluded (rule d)


class Intc:
    """Explicit pre-edge snapshot, then commit -- like model_basic_timer.Timer."""

    def __init__(self):
        self.ie = 0
        self.irq = 0                 # the RAW request latches (p13 flops)
        self.key_s1 = [0, 0, 0]      # sync stage 1, keys 1..3 (pressed level)
        self.key_s2 = [0, 0, 0]      # sync stage 2 = key_sync_w
        self.key_h = [0, 0, 0]       # history flop
        self.type_capt = 0
        self.push = 0

    def view(self):
        return self.irq & self.ie    # the p13 AND gates: IFGx = irq AND eint

    def type_now(self):
        v = self.view()
        for i in range(6):
            if (v >> i) & 1:
                return TYPES[i]
        return 0

    def edge(self, rst=0, wr=None, bt=0, keys=(0, 0, 0), gie=0, inta=1,
             rx=0, rxerr=0, tx=0, rx_clr=0, tx_clr=0):
        """wr = ("ie"|"ifg", value) for a one-edge bus write, else None.
        keys are the PRESSED levels ('1' while held). rx_clr/tx_clr are the
        Phase 12B software-side halves of clearing rules b and c: uart_periph
        pulses them when RXBUF is READ and when TXBUF is WRITTEN (REQ p12).
        Returns the pre-edge visible outputs as a dict."""
        # ---- pre-edge combinational view --------------------------------
        set_w = [0] * 6
        set_w[0] = 1 if (rx or rxerr) else 0
        set_w[1] = tx
        set_w[2] = bt
        for k in range(3):           # the RELEASE: pressed level falls 1->0
            set_w[3 + k] = 1 if (self.key_h[k] and not self.key_s2[k]) else 0

        type_w = self.type_now()
        out = dict(ie=self.ie, ifg=self.view(), type=type_w,
                   intr=1 if (self.view() != 0 and gie) else 0,
                   push=self.push, type_capt=self.type_capt)

        wr_ie = wr is not None and wr[0] == "ie"
        wr_ifg = wr is not None and wr[0] == "ifg"

        clr_w = [0] * 6
        for i in range(6):
            if wr_ifg and ((wr[1] >> i) & 1) == 0:
                clr_w[i] = 1                     # software W0C, on the RAW latch
        if inta == 0 and type_w in AUTOCLR:
            clr_w[AUTOCLR[type_w]] = 1           # service auto-clear, a/b/c
        if rx_clr:
            clr_w[0] = 1                         # rule b: RXBUF was read
        if tx_clr:
            clr_w[1] = 1                         # rule c: TXBUF was written

        pre_s1, pre_s2 = list(self.key_s1), list(self.key_s2)

        # ---- commit ------------------------------------------------------
        if rst:
            self.ie = 0
            self.irq = 0
            self.key_s1 = [0, 0, 0]
            self.key_s2 = [0, 0, 0]
            self.key_h = [0, 0, 0]
            self.type_capt = 0
            self.push = 0
            return out

        if wr_ie:
            self.ie = wr[1] & 0x3F

        nxt = 0
        for i in range(6):
            b = set_w[i] or (((self.irq >> i) & 1) and not clr_w[i])
            nxt |= (1 if b else 0) << i
        self.irq = nxt

        for k in range(3):
            self.key_h[k] = pre_s2[k]
            self.key_s2[k] = pre_s1[k]
            self.key_s1[k] = 1 if keys[k] else 0

        if inta == 0:
            self.type_capt = type_w
            self.push = 1
        else:
            self.push = 0

        return out


def main():
    t = Intc()
    fails = []

    def chk(ok, msg):
        if not ok:
            fails.append(msg)

    def step(n=1, **kw):
        last = None
        for _ in range(n):
            last = t.edge(**kw)
            kw["wr"] = None              # a bus write lasts one edge
        return last

    def press_release(which=(1, 0, 0), hold=4, gap=4, **kw):
        step(hold, keys=which, **kw)
        step(gap, keys=(0, 0, 0), **kw)

    # ---- P0 reset ----------------------------------------------------------
    step(5, rst=1)
    v = step()
    chk(v["ie"] == 0 and v["ifg"] == 0 and v["type"] == 0 and v["intr"] == 0,
        "P0 not clear after reset")

    # ---- P1 IE write / read-back, bits 7:6 dropped ---------------------------
    step(wr=("ie", 0xFF))
    v = step()
    chk(v["ie"] == 0x3F, f"P1 IE={v['ie']:#04x} != 0x3F (bits 7:6 must drop)")
    step(wr=("ie", 0x38))
    v = step()
    chk(v["ie"] == 0x38, "P1 IE=0x38 readback")

    # ---- P2 raw latch, masked view -- the falsified-A6 correction ------------
    step(wr=("ie", 0x00))
    press_release()                      # full press+release with IE=0
    v = step()
    chk(v["ifg"] == 0, f"P2a IFG={v['ifg']:#04x}: reads the RAW latch; the "
        "falsified-A6 answer says the READ is the masked value")
    step(wr=("ie", 0x08))                # enable KEY1IE over the latched request
    v = step()
    chk(v["ifg"] == 0x08, f"P2b IFG={v['ifg']:#04x} != 0x08: the raw latch "
        "must REMEMBER the masked request (A22 comeback; p13 flop has no IE)")
    chk(v["intr"] == 0, "P2c INTR high with GIE=0")
    v = step(gie=1)
    chk(v["intr"] == 1, "P2d INTR low with flag pending and GIE=1")
    step(wr=("ifg", 0x00))

    # ---- P3 the benchmark init pattern kills masked requests ------------------
    step(wr=("ie", 0x00))
    press_release()                      # request latches invisibly again
    step(wr=("ifg", 0x00))               # test1's init: IFG=0 while IE=0
    step(wr=("ie", 0x08))                # ...and only then enable
    v = step(4)
    chk(v["ifg"] == 0, f"P3 IFG={v['ifg']:#04x}: the IFG=0 store while masked "
        "did not clear the RAW latch; test1's init order relies on it")

    # ---- P4 software W0C -------------------------------------------------------
    step(wr=("ie", 0x18))                # KEY1IE + KEY2IE
    press_release(which=(1, 1, 0))
    v = step()
    chk(v["ifg"] == 0x18, f"P4a IFG={v['ifg']:#04x} != 0x18 (both key releases)")
    step(wr=("ifg", 0xF7))               # the ISR idiom: KEY1IFG_MASK's low byte
    v = step()
    chk(v["ifg"] == 0x10, f"P4b IFG={v['ifg']:#04x} != 0x10 after KEY1IFG_MASK")
    step(wr=("ifg", 0xFF))
    v = step()
    chk(v["ifg"] == 0x10, f"P4c IFG={v['ifg']:#04x}: write-1 SET a flag (A24)")
    step(wr=("ifg", 0x00))

    # ---- P5 priority / TYPE, from the VIEW ---------------------------------------
    step(wr=("ie", 0x18))                # keys 1+2 enabled; BT NOT enabled
    step(bt=1)                           # BT request latches RAW, stays masked
    press_release(which=(0, 1, 0))       # KEY2 visible
    v = step()
    chk(v["ifg"] == 0x10, f"P5a IFG={v['ifg']:#04x} != 0x10 (KEY2 visible only)")
    chk(v["type"] == 0x18, f"P5a TYPE={v['type']:#04x} != 0x18: the MASKED BT "
        "request must not win priority (TYPE reads the view, not the raw latch)")
    step(wr=("ie", 0x1C))                # now enable BTIE too: BT reappears...
    v = step()
    chk(v["ifg"] == 0x14, f"P5b IFG={v['ifg']:#04x} != 0x14 (BT + KEY2)")
    chk(v["type"] == 0x10, f"P5b TYPE={v['type']:#04x} != 0x10 (BT outranks KEY2)")
    step(wr=("ifg", 0xFB))               # clear BT only
    v = step()
    chk(v["type"] == 0x18, f"P5c TYPE={v['type']:#04x} != 0x18 (KEY2 again)")
    step(wr=("ie", 0x3C))                # open KEY3IE too before the 3-key case
    press_release(which=(1, 0, 1))       # KEY1 + KEY3 join
    v = step()
    chk(v["ifg"] == 0x38, f"P5d IFG={v['ifg']:#04x} != 0x38 (all three keys)")
    chk(v["type"] == 0x14, f"P5d TYPE={v['type']:#04x} != 0x14 (KEY1 wins keys)")
    step(wr=("ifg", 0x00))

    # ---- P6 INTR gating: GIE, and the mask ----------------------------------------
    v = step()
    chk(v["ifg"] == 0 and v["intr"] == 0, "P6a not idle before the gating check")
    step(wr=("ie", 0x00))
    step(bt=1)                           # raw-pending, fully masked
    v = step(gie=1)
    chk(v["intr"] == 0, "P6b INTR high on a MASKED request (INTR must read the "
        "view -- the p13 OR tree sums the IFGx products, not the raw latches)")
    step(wr=("ie", 0x04))                # unmask: BT reappears
    v = step(gie=0)
    chk(v["intr"] == 0, "P6c INTR high with GIE=0")
    v = step(gie=1)
    chk(v["intr"] == 1, "P6d INTR low with BT visible and GIE=1")

    # ---- P7 the INTA handshake -------------------------------------------------------
    step(wr=("ie", 0x0C))                # BT (pending from P6) + KEY1
    press_release()
    v = step(gie=1)
    chk(v["ifg"] == 0x0C, f"P7a IFG={v['ifg']:#04x} != 0x0C (BT+KEY1)")
    step(inta=0)                         # the accept cycle
    v = step()                           # protocol Cycle 1
    chk(v["push"] == 1, "P7b no TYPE push the cycle after INTA")
    chk(v["type_capt"] == 0x10, f"P7b pushed {v['type_capt']:#04x} != 0x10")
    chk(v["ifg"] == 0x08, f"P7c IFG={v['ifg']:#04x} != 0x08 "
        "(BT must auto-clear at service -- rule a; KEY1 must survive)")
    v = step()
    chk(v["push"] == 0, "P7d push did not self-clear")
    step(inta=0)                         # service KEY1 now
    v = step()
    chk(v["type_capt"] == 0x14, f"P7e pushed {v['type_capt']:#04x} != 0x14 (KEY1)")
    chk(v["ifg"] == 0x08, "P7f KEY1IFG auto-cleared at service -- rule d says manual")
    step(wr=("ifg", 0xF7))               # the ISR's manual clear
    v = step(gie=1)
    chk(v["ifg"] == 0 and v["intr"] == 0, "P7g not idle after the manual clear")

    # ---- P7h capture is FROZEN at the accept edge ---------------------------------
    step(wr=("ie", 0x1C))
    press_release(which=(0, 1, 0))       # KEY2 pending
    v = step()
    chk(v["ifg"] == 0x10, "P7h setup: KEY2 not pending alone")
    step(inta=0, bt=1)                   # accept + simultaneous BT event
    v = step()
    chk(v["type_capt"] == 0x18, f"P7h pushed {v['type_capt']:#04x} != 0x18 "
        "(TYPE must freeze at the accept edge, not track the new BT flag)")
    chk(v["ifg"] == 0x14, f"P7h IFG={v['ifg']:#04x} != 0x14 (KEY2 auto-cleared? "
        "rule d -- or the simultaneous BT event was lost)")
    step(wr=("ifg", 0x00))

    # ---- P8 the event is the RELEASE, and it is an edge ----------------------------
    step(wr=("ie", 0x08))
    step(20, keys=(1, 0, 0))             # press and HOLD: no release yet
    v = step(keys=(1, 0, 0))
    chk(v["ifg"] == 0, f"P8a IFG={v['ifg']:#04x}: the flag set on the PRESS. "
        "DOC/03 section C: the request event is the RELEASE")
    step(6, keys=(0, 0, 0))              # release
    v = step()
    chk(v["ifg"] == 0x08, "P8b the release did not set the flag")
    step(wr=("ifg", 0x00))
    v = step(10)
    chk(v["ifg"] == 0, f"P8c IFG={v['ifg']:#04x}: re-set with no new event "
        "(the latch must be edge-set, not level-set)")
    press_release()                      # a full second press+release
    v = step()
    chk(v["ifg"] == 0x08, "P8d a second press+release did not set")
    step(wr=("ifg", 0x00))

    # ---- P9 the sync source: masked = invisible but remembered ----------------------
    step(wr=("ie", 0x00))
    step(bt=1)
    v = step()
    chk(v["ifg"] == 0, "P9a BTIFG visible with BTIE=0 (the masked view)")
    step(wr=("ie", 0x04))
    v = step()
    chk(v["ifg"] == 0x04, "P9b the masked BT request was not remembered (A22)")

    # ---- P10 rules b and c, the SOFTWARE halves -- Phase 12B -----------------
    # REQ p12: "reading RXBUF resets the receive-error bits, and RXIFG" and
    # "writing to the transmit data buffer clears TXIFG". These clear the RAW
    # latch, which is what makes POLLED operation possible: without them a
    # request latched while RXIE was 0 would fire the moment software enabled
    # RXIE, even though the character had already been consumed (A22's comeback
    # working against us).
    step(wr=("ie", 0x00))
    step(wr=("ifg", 0x00))
    step(wr=("ie", 0x03))                # RXIE | TXIE
    step(rx=1)                           # a character lands
    v = step()
    chk(v["ifg"] == 0x01, f"P10a RXIFG={v['ifg']:#04x} != 0x01 after rx")
    step(rx_clr=1)                       # software reads RXBUF
    v = step()
    chk(v["ifg"] == 0x00, f"P10b IFG={v['ifg']:#04x}: reading RXBUF must clear "
        "RXIFG with no W0C write anywhere (rule b, REQ p12)")

    step(tx=1)                           # the transmitter took a byte
    v = step()
    chk(v["ifg"] == 0x02, f"P10c TXIFG={v['ifg']:#04x} != 0x02 after tx")
    step(tx_clr=1)                       # software writes TXBUF
    v = step()
    chk(v["ifg"] == 0x00, f"P10d IFG={v['ifg']:#04x}: writing TXBUF must clear "
        "TXIFG (rule c, REQ p12)")

    # and the one ordering that matters: a character arriving in the SAME edge
    # as the read must survive -- set beats a same-edge clear, or a byte that
    # arrived while its predecessor was being consumed would be lost silently
    step(rx=1)
    v = step(rx=1, rx_clr=1)             # read and arrive together
    step()
    v = step()
    chk(v["ifg"] == 0x01, f"P10e IFG={v['ifg']:#04x}: a character arriving in "
        "the same edge as the RXBUF read must leave RXIFG SET -- the set term "
        "wins, or the new byte is announced to nobody")
    step(wr=("ifg", 0x00))
    step(rx_clr=1)

    # a clear with the flag MASKED still empties the raw latch, so enabling the
    # interrupt afterwards must stay quiet (the A22 comeback, deliberately
    # defeated by rule b -- this is the pair to P2b)
    step(wr=("ie", 0x00))
    step(rx=1)                           # latches invisibly
    step(rx_clr=1)                       # ...and is consumed while masked
    step(wr=("ie", 0x01))
    v = step()
    chk(v["ifg"] == 0x00, f"P10f IFG={v['ifg']:#04x}: a request already "
        "consumed through RXBUF must NOT come back when RXIE is enabled")

    print(f"checks failed: {len(fails)}")
    for m in fails:
        print("  FAIL", m)
    if fails:
        return 1
    print("PASS -- every expected value in tb_interrupt_ctrl.vhd reproduces from")
    print("the RTL semantics: raw latches with the masked view (falsified-A6),")
    print("A22 comeback, the test1 init pattern, W0C, view-based priority and")
    print("INTR, BT auto-clear vs KEY manual clear, frozen TYPE capture, and")
    print("KEY events on the RELEASE edge only.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
