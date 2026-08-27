#!/usr/bin/env python3
"""Bit-exact model of DUT/RV32IMscMCU/UART_PERIPH.vhd -- the register layer.

WHERE THIS MODEL'S BOUNDARY IS, STATED FIRST BECAUSE IT MATTERS
    The UART is two pieces of code with two different risk profiles:

      the serial engine   jakubcabal's UART_TX / UART_RX / UART_DEBOUNCER,
                          MIT, v1.1, released 2018 and used in the field.
                          Adapted only for a runtime baud divider and one
                          added RX_BUSY port.
      the register layer  UCTL / RXBUF / TXBUF, the overrun and framing
                          flags, the read-clears, BUSY, SWRST, the four
                          interrupt-side strobes. ALL NEW WORK.

    Modelling his state machines state-by-state would be modelling proven
    code. So this file models the REGISTER LAYER exactly -- every process in
    UART_PERIPH.vhd, per clock edge -- and treats the engine as its interface
    contract: din_rdy / dout_vld / dout / frame_err / rx_busy are INPUTS to
    edge(), the same signals the RTL's processes see. The engine itself is
    verified where it can only be verified honestly: tb_uart.vhd loops TXD
    back into RXD and requires the byte to come back, at the real divider, in
    a real 8N1 frame. A wrong divider or a mangled frame cannot survive that,
    and no model of ours could have proved it.

WHY A MODEL AT ALL, then: every ordering question in the register layer is one
I got to decide, which means every one of them is a place to be wrong --
    - a read of RXBUF in the same cycle a new character lands: whose state
      survives, and is it an overrun? (It is not: the old byte WAS read.)
    - a write of TXBUF in the same cycle the transmitter accepts the previous
      byte: does the write survive? (It must, or the character vanishes.)
    - what SWRST clears, and what it must NOT clear (itself; the baud bit).
    - BUSY with a byte queued but the transmitter still idle.
  Those are the phases below, and the mutation runner beside this file kills a
  faithful mutant for each.

Sources -> bits, REQ p12:
  UCTL  [7] BUSY  [6] OE  [5] PE  [4] FE  [3] BAUDRATE  [2] PEV  [1] PENA  [0] SWRST
"""

import sys

# Rounded dividers, the same arithmetic as UART_CORE.vhd's constants.
def divider(clk_hz, baud):
    return (clk_hz + (16 * baud) // 2) // (16 * baud)


def baud_err_permille(clk_hz, baud, div):
    ref = baud * 16 * div
    return (abs(clk_hz - ref) * 1000) // ref


class UartPeriph:
    """Explicit pre-edge snapshot, then commit -- like every model_*.py here."""

    def __init__(self):
        self.ctl = 0          # bits 3..0 only: BAUDRATE, PEV, PENA, SWRST
        self.rxbuf = 0
        self.txbuf = 0
        self.txbuf_vld = 0
        self.full = 0
        self.fe = 0
        self.pe = 0          # Phase 12E: a real flag, not a constant 0
        self.oe = 0

    # ---- combinational views -------------------------------------------
    def swrst(self):
        return self.ctl & 1

    def uctl_read(self, busy):
        # Phase 12E: PE is stored and ANDed with PENA on the way out, because
        # REQ p12 says "when PENA = 0, PE is read as 0". The receiver also
        # cannot set it with parity disabled, so the bit reads 0 in 8N1 for two
        # independent reasons.
        pe_read = self.pe & (self.ctl >> 1) & 1
        return (busy << 7) | (self.oe << 6) | (pe_read << 5) | \
               (self.fe << 4) | self.ctl

    def edge(self, rst=0, wr=None, rd=None, dout_vld=0, dout=0,
             frame_err=0, parity_err=0, rx_busy=0, din_rdy=1):
        """wr = "uctl"|"txbuf" with value, as ("uctl", v); rd = "rxbuf" or None.
        The engine-side signals are inputs, per the boundary note above.
        Returns the pre-edge visible outputs and the event strobes."""
        # ---- pre-edge combinational ------------------------------------
        uctl_wr = wr is not None and wr[0] == "uctl"
        txbuf_wr = wr is not None and wr[0] == "txbuf"
        rxbuf_rd = 1 if rd == "rxbuf" else 0

        tx_accept = 1 if (self.txbuf_vld and din_rdy) else 0
        oe_set = 1 if (dout_vld and self.full and not rxbuf_rd) else 0
        busy = 1 if (rx_busy or (not din_rdy) or self.txbuf_vld) else 0

        out = dict(uctl=self.uctl_read(busy), rxbuf=self.rxbuf, txbuf=self.txbuf,
                   busy=busy, fe=self.fe, pe=self.pe, oe=self.oe, full=self.full,
                   rx_ev=dout_vld,
                   rxerr_ev=1 if (frame_err or parity_err or oe_set) else 0,
                   tx_ev=tx_accept, rx_clr=rxbuf_rd, tx_clr=1 if txbuf_wr else 0)

        # ---- commit ----------------------------------------------------
        if rst:
            self.ctl = 0
            self.rxbuf = 0
            self.txbuf = 0
            self.txbuf_vld = 0
            self.full = 0
            self.fe = 0
            self.pe = 0
            self.oe = 0
            return out

        sw = self.swrst()          # PRE-edge SWRST, like the RTL

        # UCTL: only bits 3..0, and reset/SWRST never touch it
        if uctl_wr:
            self.ctl = wr[1] & 0xF

        # TXBUF: a write WINS over a same-cycle accept
        if sw:
            self.txbuf_vld = 0
        elif txbuf_wr:
            self.txbuf = wr[1] & 0xFF
            self.txbuf_vld = 1
        elif tx_accept:
            self.txbuf_vld = 0

        # RXBUF + flags: read clears FIRST, then this cycle's arrivals set
        full_v, fe_v, pe_v, oe_v = self.full, self.fe, self.pe, self.oe
        if sw:
            full_v = fe_v = pe_v = oe_v = 0
        else:
            if rxbuf_rd:
                # REQ p12: "reading RXBUF resets the receive-error BITS" --
                # plural, so PE clears with FE and OE
                full_v = fe_v = pe_v = oe_v = 0
            if dout_vld:
                self.rxbuf = dout & 0xFF
                if full_v:
                    oe_v = 1
                full_v = 1
            if frame_err:
                fe_v = 1
            # Phase 12E. Deliberately NOT setting full_v and NOT writing
            # rxbuf: a parity-errored character is not delivered (the engine
            # holds dout_vld low for it -- A30), so PE and the error interrupt
            # are how software learns and RXBUF keeps what it held.
            if parity_err:
                pe_v = 1
        self.full, self.fe, self.pe, self.oe = full_v, fe_v, pe_v, oe_v

        return out


def main():
    CLK_HZ = 20_000_000
    fails = []

    def chk(ok, msg):
        if not ok:
            fails.append(msg)

    # ---- P0 the dividers, and the finding that motivated rounding ---------
    d96 = divider(CLK_HZ, 9600)
    d115 = divider(CLK_HZ, 115200)
    chk(d96 == 130, f"P0a 9600 divider {d96} != 130")
    chk(d115 == 11, f"P0b 115200 divider {d115} != 11")
    e96 = baud_err_permille(CLK_HZ, 9600, d96)
    e115 = baud_err_permille(CLK_HZ, 115200, d115)
    chk(e96 <= 30, f"P0c 9600 error {e96} per-mille above the 3% bound")
    chk(e115 <= 30, f"P0d 115200 error {e115} per-mille above the 3% bound")
    # the reference's truncating formula, for the record
    trunc = CLK_HZ // (16 * 115200)
    e_trunc = baud_err_permille(CLK_HZ, 115200, trunc)
    chk(trunc == 10 and e_trunc > 30,
        f"P0e the truncating formula was expected to FAIL the bound at 20 MHz "
        f"(divider {trunc}, error {e_trunc} per-mille) -- if it now passes, the "
        f"finding in UART_CORE.vhd's header note 2 needs re-deriving")
    bit_cycles_115 = 16 * d115
    bit_cycles_96 = 16 * d96
    chk(bit_cycles_115 == 176, "P0f 115200 bit period != 176 cycles")
    chk(bit_cycles_96 == 2080, "P0g 9600 bit period != 2080 cycles")

    u = UartPeriph()

    def step(n=1, **kw):
        last = None
        for _ in range(n):
            last = u.edge(**kw)
            kw["wr"] = None            # a bus access lasts one edge
            kw["rd"] = None
        return last

    # ---- P1 reset ---------------------------------------------------------
    step(3, rst=1)
    v = step()
    chk(v["uctl"] == 0x00, f"P1a UCTL after reset = {v['uctl']:#04x} != 0x00 "
        "(A25: SWRST = 0, the USART is operational out of reset)")
    chk(v["rxbuf"] == 0 and v["txbuf"] == 0, "P1b buffers not clear")
    chk(v["busy"] == 0, "P1c BUSY high with nothing happening")

    # ---- P2 UCTL: four writable bits, four read-only ----------------------
    step(wr=("uctl", 0xFF))
    v = step()
    chk(v["uctl"] & 0x0F == 0x0F, "P2a the four control bits did not store")
    chk(v["uctl"] & 0x70 == 0x00, f"P2b UCTL = {v['uctl']:#04x}: a write reached "
        "a read-only status bit (bits 6:4 are OE/PE/FE, hardware-owned)")
    # SWRST is set right now -- clear it and check BAUDRATE survives
    step(wr=("uctl", 0x08))            # BAUDRATE=1, SWRST=0
    v = step()
    chk(v["uctl"] & 0x0F == 0x08, f"P2c UCTL = {v['uctl']:#04x} != 0x08")

    # ---- P3 TXBUF: the queue, and the write that must win -----------------
    step(wr=("txbuf", 0xA5), din_rdy=1)
    v = step(din_rdy=0)               # engine busy: the byte stays queued
    chk(v["txbuf"] == 0xA5, "P3a TXBUF did not store")
    chk(v["busy"] == 1, "P3b BUSY low with a byte queued and the engine busy")
    # engine goes ready: the accept fires exactly once
    v = step(din_rdy=1)
    chk(v["tx_ev"] == 1, "P3c no tx_ev on the accept cycle (TXIFG: TXBUF free)")
    v = step(din_rdy=1)
    chk(v["tx_ev"] == 0, "P3d tx_ev fired twice for one byte")
    chk(v["busy"] == 0, "P3e BUSY still high after the byte was accepted")
    # A write in the SAME cycle as an accept must survive. Building that
    # collision needs care, and the first draft of this phase did not have it:
    # it wrote, let the accept happen on the next edge, and only then wrote
    # again -- two events one cycle apart, which is not a collision at all, and
    # mutant M3 walked straight through. A real collision needs the byte still
    # QUEUED (txbuf_vld = 1 pre-edge) AND the engine ready (din_rdy = 1) AND a
    # write, all at one edge -- so the queue is held with din_rdy low first.
    step(wr=("txbuf", 0x11), din_rdy=0)   # queued, engine busy: no accept
    v = step(din_rdy=0)
    chk(v["txbuf"] == 0x11 and v["busy"] == 1, "P3f setup: 0x11 is not queued")
    step(wr=("txbuf", 0x22), din_rdy=1)   # accept AND write, same edge
    v = step(din_rdy=0)
    chk(v["txbuf"] == 0x22, f"P3g TXBUF = {v['txbuf']:#04x}: a write that "
        "collided with the accept was dropped -- the character vanishes")
    chk(v["busy"] == 1, "P3h the colliding write left no byte queued")
    step(din_rdy=1)                   # drain
    step(din_rdy=1)

    # ---- P4 the TXBUF write is TXIFG's software clear (rule c) ------------
    v = step(wr=("txbuf", 0x33), din_rdy=1)
    chk(v["tx_clr"] == 1, "P4 tx_clr not raised by the TXBUF write (rule c)")
    step(2, din_rdy=1)

    # ---- P5 RXBUF: a character, then the read that clears -----------------
    v = step(dout_vld=1, dout=0x5A)
    chk(v["rx_ev"] == 1, "P5a no rx_ev on the arrival cycle")
    v = step()
    chk(v["rxbuf"] == 0x5A, f"P5b RXBUF = {v['rxbuf']:#04x} != 0x5A")
    chk(v["full"] == 1, "P5c the full flag did not set")
    v = step(rd="rxbuf")
    chk(v["rx_clr"] == 1, "P5d rx_clr not raised by the RXBUF read (rule b)")
    v = step()
    chk(v["full"] == 0, "P5e the read did not clear the full flag")
    chk(v["rxbuf"] == 0x5A, "P5f the read destroyed RXBUF's contents")

    # ---- P6 framing error, and its clear on read -------------------------
    v = step(frame_err=1)
    chk(v["rxerr_ev"] == 1, "P6a no rxerr_ev on a framing error")
    v = step()
    chk(v["uctl"] & 0x10 == 0x10, f"P6b UCTL = {v['uctl']:#04x}: FE (bit 4) "
        "did not set")
    step(rd="rxbuf")
    v = step()
    chk(v["uctl"] & 0x10 == 0x00, "P6c reading RXBUF did not reset FE "
        "(REQ p12: 'reading RXBUF resets the receive-error bits')")

    # ---- P6B parity: PE, and the "read as 0 when PENA = 0" rule ----------
    # Phase 12E. Everything about this phase is new: before it, PE was the
    # constant 0 and PENA/PEV were stored bits with no consumer.
    step(wr=("uctl", 0x00))               # parity disabled
    v = step(parity_err=1)                # (cannot happen with PENA=0, but the
    chk(v["rxerr_ev"] == 1, "P6Ba a parity error must raise rxerr_ev, "
        "because REQ p14 gives TYPE 04h to 'USART status error' and PE is one "
        "of the three status errors")
    v = step()
    chk(v["uctl"] & 0x20 == 0x00, f"P6Bb UCTL = {v['uctl']:#04x}: with "
        "PENA = 0, PE must read 0 -- REQ p12 says so outright, and the model "
        "must not report a flag the specification says is invisible")
    # ...and with PENA = 1 the same stored flag becomes visible
    step(wr=("uctl", 0x02))               # PENA = 1, odd parity
    v = step()
    chk(v["uctl"] & 0x20 == 0x20, f"P6Bc UCTL = {v['uctl']:#04x}: with "
        "PENA = 1 the stored PE must be visible")
    chk(v["uctl"] & 0x02 == 0x02, "P6Bd PENA did not read back")
    step(rd="rxbuf")
    v = step()
    chk(v["uctl"] & 0x20 == 0x00, "P6Be reading RXBUF did not reset PE "
        "(REQ p12: 'resets the receive-error bits', plural -- FE, PE and OE)")

    # a parity-errored character must NOT land in RXBUF and must NOT make the
    # buffer full, so it cannot cause a later overrun either (A30)
    step(wr=("uctl", 0x02))
    step(dout_vld=1, dout=0x77)           # a good character arrives, unread
    step(parity_err=1, dout=0x33)         # then a bad one, with a DIFFERENT
                                          # byte on the engine's output
    # NOTE the edge this is read on. edge() returns the PRE-edge view, so
    # asking on the same step as the parity error would still show 0x77 even if
    # the errored byte were being written -- the first draft did exactly that
    # and a mutant that overwrites RXBUF escaped. And `dout` has to differ from
    # the good byte, or the check cannot discriminate either: with dout at its
    # default of 0 an overwrite would show, but with dout = 0x77 nothing would.
    v = step()
    chk(v["rxbuf"] == 0x77, f"P6Bf RXBUF = {v['rxbuf']:#04x}: a parity-errored "
        "character must not overwrite the previous one -- it was never "
        "delivered (A30)")
    chk(v["uctl"] & 0x40 == 0x00, f"P6Bg UCTL = {v['uctl']:#04x}: OE must NOT "
        "be set by a parity-errored character -- nothing was overwritten, so "
        "nothing was lost to an overrun")
    chk(v["uctl"] & 0x20 == 0x20, "P6Bh PE did not set")
    step(rd="rxbuf")

    # ...and the same on an EMPTY buffer, which is the ordering that actually
    # discriminates. The pair above cannot: there, the buffer was already full
    # from the good character, so a mutant that ALSO marks it full on a parity
    # error changes nothing observable. Here the buffer starts empty, so if the
    # errored character wrongly marks it full, the next good character reports
    # an overrun that never happened -- and a driver would report data loss on
    # a clean line.
    v = step(parity_err=1)                # empty buffer, bad character
    chk(v["full"] == 0, "P6Bi a parity-errored character must not mark RXBUF "
        "full: nothing was delivered")
    v = step(dout_vld=1, dout=0x55)       # the next good one
    v = step()
    chk(v["uctl"] & 0x40 == 0x00, f"P6Bj UCTL = {v['uctl']:#04x}: OE set after "
        "a good character followed a parity-errored one into an EMPTY buffer. "
        "Nothing was overwritten, so nothing was lost")
    chk(v["rxbuf"] == 0x55, "P6Bk the good character did not land in RXBUF")
    step(rd="rxbuf")
    step(wr=("uctl", 0x00))

    # ---- P7 overrun -- and the case that is NOT one -----------------------
    step(dout_vld=1, dout=0x01)       # first character, left unread
    v = step(dout_vld=1, dout=0x02)   # second arrives: overrun
    chk(v["rxerr_ev"] == 1, "P7a no rxerr_ev when the overrun set")
    v = step()
    chk(v["uctl"] & 0x40 == 0x40, f"P7b UCTL = {v['uctl']:#04x}: OE (bit 6) "
        "did not set on an unread byte being overwritten")
    chk(v["rxbuf"] == 0x02, "P7c RXBUF kept the old byte instead of the new one")
    step(rd="rxbuf")
    v = step()
    chk(v["uctl"] & 0x40 == 0x00, "P7d the read did not clear OE")
    # THE CASE THAT IS NOT AN OVERRUN: arrival in the same cycle as the read
    step(dout_vld=1, dout=0x03)       # a byte sits unread
    v = step(dout_vld=1, dout=0x04, rd="rxbuf")   # read AND arrival collide
    chk(v["rxerr_ev"] == 0, "P7e an overrun was reported for a character that "
        "arrived in the same cycle its predecessor was READ -- nothing was lost")
    v = step()
    chk(v["uctl"] & 0x40 == 0x00, f"P7f UCTL = {v['uctl']:#04x}: OE set on the "
        "read-and-arrive collision")
    chk(v["rxbuf"] == 0x04, "P7g the colliding arrival was dropped")
    chk(v["full"] == 1, "P7h the colliding arrival left the buffer empty")
    step(rd="rxbuf")

    # ---- P8 BUSY's three terms, one at a time ----------------------------
    v = step()
    chk(v["busy"] == 0, "P8a BUSY high when idle")
    v = step(rx_busy=1)
    chk(v["busy"] == 1, "P8b BUSY low with the receiver mid-frame")
    v = step(din_rdy=0)
    chk(v["busy"] == 1, "P8c BUSY low with the transmitter mid-frame")
    step(wr=("txbuf", 0x77), din_rdy=0)
    v = step(din_rdy=1, rx_busy=0)
    chk(v["busy"] == 1, "P8d BUSY low with a byte queued in TXBUF -- a polling "
        "loop would send the next character on top of it")
    step(2, din_rdy=1)

    # ---- P9 SWRST: what it clears, and what it must NOT ------------------
    # din_rdy is held LOW through the whole setup on purpose. The first draft
    # left it at its default of 1, so the queued byte was accepted normally
    # before SWRST ever took effect -- there was nothing left for SWRST to
    # drop, and mutant M12 (SWRST leaving the byte queued, a silent hang)
    # escaped. The state SWRST clears has to still exist when it arrives.
    step(wr=("uctl", 0x0A), din_rdy=0)           # BAUDRATE = 1, PENA = 1 (12E:
                                                # so the PE set below is
                                                # VISIBLE and P9e can see it)
    step(dout_vld=1, dout=0x99, frame_err=1, parity_err=1, din_rdy=0)
    step(wr=("txbuf", 0x88), din_rdy=0)          # queued, and it stays queued
    v = step(din_rdy=0)
    chk(v["full"] == 1 and (v["uctl"] & 0x10) == 0x10,
        "P9a setup: no pending receive state to clear")
    chk(v["busy"] == 1, "P9a setup: the TX byte is not still queued")
    # SWRST is a REGISTERED bit -- swrst_w is ctl_q(0), not the write data --
    # so it takes effect the cycle AFTER the write lands, and what it clears is
    # visible the cycle after that. Two edges, not one; the first draft of this
    # phase checked one edge early and the model caught it.
    # 0x0B, not 0x09: UCTL is a plain register write and overwrites all four
    # stored bits, so the write that raises SWRST has to carry BAUDRATE and
    # PENA with it or SOFTWARE is what cleared them, not SWRST. The first
    # draft of this line wrote 0x09 and the model reported "SWRST cleared
    # PENA" -- which was true of the stimulus and false of the hardware.
    step(wr=("uctl", 0x0B), din_rdy=0)  # SWRST = 1, BAUDRATE and PENA stay
    step(din_rdy=0)                    # SWRST now high: this is the clearing edge
    v = step(din_rdy=0)
    chk(v["uctl"] & 0x08 == 0x08, f"P9b UCTL = {v['uctl']:#04x}: SWRST cleared "
        "BAUDRATE -- the link would silently drop to 9600")
    chk(v["uctl"] & 0x01 == 0x01, "P9c SWRST cleared itself -- unexitable")
    chk(v["full"] == 0, "P9d SWRST did not clear the receive state")
    chk(v["uctl"] & 0x70 == 0x00, "P9e SWRST did not clear FE/PE/OE -- all "
        "three error bits, 12E added PE to the mask")
    chk(v["uctl"] & 0x02 == 0x02, "P9e2 SWRST cleared PENA -- it must keep "
        "the frame format for the same reason it keeps BAUDRATE")
    chk(v["busy"] == 1, "P9f setup: din_rdy is still low so BUSY must hold")
    v = step(din_rdy=1)
    chk(v["busy"] == 0, "P9g SWRST left a byte queued in TXBUF -- it can never "
        "leave, because the engine is held in reset")
    # and it is exitable
    step(wr=("uctl", 0x0A))
    v = step(din_rdy=1)
    chk(v["uctl"] & 0x01 == 0x00, "P9h SWRST could not be cleared")

    print(f"checks failed: {len(fails)}")
    for m in fails:
        print("  FAIL", m)
    if fails:
        return 1
    print("PASS -- the register layer reproduces from UART_PERIPH.vhd's")
    print("semantics: the rounded dividers 130/11 (and the reference's")
    print("truncating 10 failing the 3% bound at 20 MHz), UCTL's four writable")
    print("bits, the TXBUF write that beats a colliding accept, the RXBUF read")
    print("that clears FE/OE, the overrun -- and the read-and-arrive collision")
    print("that is NOT one -- BUSY's three terms, and SWRST clearing the")
    print("engine state while keeping itself and BAUDRATE.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
