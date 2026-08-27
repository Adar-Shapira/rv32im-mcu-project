#!/usr/bin/env python3
"""Generate the directed MCU-LEVEL USART test -- Phase 12B's verification.

WHY THIS EXISTS
    Phase 12A proved the USART as a LEAF: tb_uart.vhd loops TXD back into RXD
    at the real divider and measures the start bit, and tools/model_uart.py
    covers the register layer edge by edge with twelve mutations caught. What
    neither of those can see is the BUS: CS_UART and its three lanes, the three
    readers, MemRead_i reaching the peripheral so RXBUF's read side effect
    happens at all, and the two new interrupt-controller inputs that carry
    clearing rules b and c. That wiring is what this program exercises, on the
    real MCU, with the testbench doing nothing but tying UART_RXD_i to
    UART_TXD_o.

WHAT IT PROVES  (with tb_uart_mmio.vhd -- 22 scored stores, every value EXACT)
    Configuration and the read path
      [0x100]=0x08   UCTL written at 0x2018 (lane 0) and read back: BAUDRATE=1
                     selected, BUSY/OE/PE/FE all clear
    Round 1 -- one byte all the way around the loopback
      [0x104]=0x88   UCTL read the cycle AFTER writing TXBUF at 0x201A
                     (lane 2): BUSY is up because a byte is queued -- the
                     third BUSY term, the one a two-term BUSY would miss
      [0x108]=0x5A   the byte read back from RXBUF at 0x2019 (lane 1) after
                     going out on TXD and coming back in on RXD
      [0x10C]=0x00   IFG at 0x202D immediately after that read: RXIFG is gone
                     WITHOUT any W0C write -- clearing rule b, software half,
                     which only works if rx_clr_o reaches the controller
      [0x110]=0x08   UCTL idle again
    Round 2 -- the overrun, and what a read of RXBUF resets
      [0x114]=0x48   two bytes arrive with no read between them: OE set,
                     BUSY clear
      [0x118]=0x3C   RXBUF holds the NEWER byte
      [0x11C]=0x08   and that read cleared the receive-error bits too, exactly
                     as REQ p12 says ("reading RXBUF resets the receive-error
                     bits, and RXIFG")
    Round 3 -- clearing rule c, on TXIFG, still polled
      [0x120]=0x02   TXIE has been 0 for three transmits, so TXIFG sat in the
                     raw latch invisibly; enabling TXIE makes it appear --
                     A22's comeback, on a second flag
      [0x124]=0x00   and writing TXBUF clears it, again with no W0C: rule c
      [0x128]=0x71   TXBUF read-back (A28) while the frame is on the wire...
      [0x12C]=0x3C   ...and RXBUF still holds the PREVIOUS byte. This is the
                     one moment the two registers differ, and it is here on
                     purpose: with a loopback every other scored value is the
                     same byte in both, so swapping the two readers' lanes
                     would otherwise pass unnoticed
      [0x130]=0x02   after the frame, TXIFG is back -- the transmitter took it
      [0x134]=0x71   the loopback delivered it; this read drains RXIFG
      [0x138]=0x00
    Round 4 -- the interrupt, through the vector table
      [0x008]=ISR_RX the program's own vector word 2 (TYPE 08h = UART RX)
      [0x180]=0x00   IFG at ISR entry: RXIFG was auto-cleared at service --
                     rule b's HARDWARE half, observed from software
      [0x184]=0x44   the received byte, read inside the ISR
      [0x188]=0x00   TYPE at 0x202E (lane 2) reads idle for the same reason
      [0x200]=1      the ISR ran
      [0x13C]=1      gp after reti: GIE restored in hardware
      [0x140]=0x5D   end marker -- main resumed and finished

    One thing worth stating because it is easy to get wrong: the program sets
    IE = RXIE *before* it starts polling, with GIE still 0. It has to. What
    software reads from IFG is the MASKED view (irq AND ie, the falsified-A6
    correction), so a polled driver that leaves IE at 0 polls a register that
    can never change. This program is the executable statement of that.

WHAT IT DOES NOT PROVE, AND WHERE THAT IS PROVEN INSTEAD
    Two things were checked by mutating this generator and watching whether the
    cross-check noticed:
      * the same-cycle read-and-arrive case (is it an overrun? it is not) is
        NOT reachable from a program -- it needs a load to land exactly on the
        frame's last cycle. model_uart.py's phase P7e owns it, and a mutation
        that reports that overrun fails there.
      * the bit timing. tb_uart.vhd MEASURES the start bit against the real
        engine (176 cycles at 115200, 2080 at 9600). Nothing here depends on
        the frame length: every expectation is a value the program POLLS for.

THE SECOND DERIVATION -- the two vetted models composed on an emulated bus
    interpret() below runs the program against model_uart.UartPeriph and
    model_interrupt_ctrl.Intc, one edge each per instruction, with the Phase 9B
    entry protocol between them and the LOOPBACK emulated at the transaction
    level: when the register layer hands a byte to the transmitter, the frame
    occupies 10*16*div cycles, during which din_rdy is low and rx_busy is high,
    and on its last cycle dout_vld delivers the same byte back. Generation
    aborts if the resulting DTCM disagrees with the expectations above.

    That emulation is deliberately transaction-level, and the boundary is worth
    naming: it reproduces the VALUES and the ORDER, not the bit timing. The bit
    timing is proven where it can be -- tb_uart.vhd MEASURES the start bit
    (176 cycles at 115200, 2080 at 9600) against the real engine. Every
    expectation here is a value the program polls for, never a cycle count, so
    nothing in this file depends on the frame length being exactly right.

USAGE
    python3 tools/gen_uart_mmio_test.py
        writes SIM/RV32IMscMCU/uartmmio/{ITCM.hex,DTCM.hex,listing.txt}
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from gen_isa_test import enc, li32, ihex, M32               # noqa: E402
from model_uart import UartPeriph, divider                  # noqa: E402
from model_interrupt_ctrl import Intc                       # noqa: E402

RETI_WORD = 0x00020067

UCTL_A, RXBUF_A, TXBUF_A = 0x2018, 0x2019, 0x201A
IE_A, IFG_A, TYPE_A = 0x202C, 0x202D, 0x202E

CLK_HZ = 20_000_000          # SMCLK, F8/F11 -- the generic the top passes
BAUD_HIGH, BAUD_LOW = 115200, 9600

BYTE1 = 0x5A                 # round 1, read back normally
BYTE2 = 0xA5                 # round 2, deliberately left unread
BYTE3 = 0x3C                 # round 2, overruns BYTE2
BYTE4 = 0x71                 # round 3, in flight while RXBUF still holds BYTE3
BYTE5 = 0x44                 # round 4, arrives as an interrupt

MASK_BUSY = 0x80
MASK_OE = 0x40


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

    def score(reg):
        emit("sw", reg, 0, "s0")
        emit("addi", "s0", "s0", 4)

    def score_isr(reg):
        emit("sw", reg, 0, "s1")
        emit("addi", "s1", "s1", 4)

    def wait_idle():
        """poll UCTL until BUSY is low. Three instructions, so -8."""
        emit("lw", "t1", 0, "a0")
        emit("and", "t1", "t1", "t6")
        emit("bne", "t1", "zero", -8)

    def wait_ifg():
        """poll IFG until something pends. IE is RXIE only, so any non-zero
        value IS RXIFG and no mask is needed."""
        emit("lw", "t1", 0, "a4")
        emit("beq", "t1", "zero", -4)

    def wait_oe():
        """poll UCTL until OE is set -- the direct condition, so there is no
        race against the frame's last cycle."""
        emit("lw", "t1", 0, "a0")
        emit("and", "t1", "t1", "s5")
        emit("beq", "t1", "zero", -8)

    li("a0", UCTL_A)
    li("a1", RXBUF_A)
    li("a2", TXBUF_A)
    li("a3", IE_A)
    li("a4", IFG_A)
    li("a5", TYPE_A)
    emit("addi", "s0", "zero", 0x100)      # scratch pointer
    emit("addi", "s1", "zero", 0x180)      # ISR scratch pointer
    emit("addi", "s2", "zero", 0x200)      # ISR-ran flag
    emit("addi", "s3", "zero", 0x008)      # vector word 2 = TYPE 08h (UART RX)
    emit("addi", "t6", "zero", MASK_BUSY)
    emit("addi", "s5", "zero", MASK_OE)

    # ---- configure ---------------------------------------------------------
    emit("addi", "t0", "zero", 0x08)       # BAUDRATE=1 (115200), PENA=0, SWRST=0
    emit("sw",   "t0", 0, "a0")
    emit("sw",   "zero", 0, "a3")          # IE  = 0
    emit("sw",   "zero", 0, "a4")          # IFG = 0
    emit("lw",   "t1", 0, "a0")
    score("t1")                            # [0x100] = 0x08

    # RXIE, with GIE still 0: the IFG read-back is the MASKED view, so polled
    # operation needs the enable bit set even though no interrupt is wanted yet.
    emit("addi", "t0", "zero", 0x01)
    emit("sw",   "t0", 0, "a3")

    # ---- round 1: one byte around the loopback -----------------------------
    emit("addi", "t0", "zero", BYTE1)
    emit("sw",   "t0", 0, "a2")            # TXBUF (rule c: tx_clr pulses)
    emit("lw",   "t1", 0, "a0")
    score("t1")                            # [0x104] = 0x88, BUSY from the queue
    wait_ifg()
    emit("lw", "t3", 0, "a1")              # RXBUF (rule b: rx_clr pulses)
    score("t3")                            # [0x108] = BYTE1
    emit("lw", "t1", 0, "a4")
    score("t1")                            # [0x10C] = 0x00, no W0C anywhere
    wait_idle()
    emit("lw", "t1", 0, "a0")
    score("t1")                            # [0x110] = 0x08

    # ---- round 2: overrun, and what the RXBUF read resets ------------------
    emit("addi", "t0", "zero", BYTE2)
    emit("sw",   "t0", 0, "a2")
    wait_ifg()                             # BYTE2 has landed and is LEFT unread
    emit("addi", "t0", "zero", BYTE3)
    emit("sw",   "t0", 0, "a2")
    wait_oe()
    wait_idle()
    emit("lw", "t1", 0, "a0")
    score("t1")                            # [0x114] = 0x48
    emit("lw", "t3", 0, "a1")
    score("t3")                            # [0x118] = BYTE3, the newer byte
    emit("lw", "t1", 0, "a0")
    score("t1")                            # [0x11C] = 0x08, error bits reset

    # ---- round 3: clearing rule c, on TXIFG, still polled -------------------
    # TXIE has been 0 all along, so three transmits have latched TXIFG in the
    # RAW latch where software cannot see it. Enabling TXIE now makes it appear
    # -- assumption A22's comeback, demonstrated on a second flag -- and then
    # writing TXBUF has to clear it with no W0C anywhere (rule c).
    emit("addi", "t0", "zero", 0x02)       # IE = TXIE only
    emit("sw",   "t0", 0, "a3")
    emit("lw",   "t1", 0, "a4")
    score("t1")                            # [0x120] = 0x02, remembered request

    emit("addi", "t0", "zero", BYTE4)
    emit("sw",   "t0", 0, "a2")            # the write pulses tx_clr
    emit("lw",   "t1", 0, "a4")            # the VERY next cycle: before the
    score("t1")                            # transmitter can re-set it
    #                                        [0x124] = 0x00

    # TXBUF now holds BYTE4 while RXBUF still holds BYTE3 -- the frame is on
    # the wire. This is the only moment where the two registers differ, and it
    # is here on purpose: with a loopback every other scored value is the same
    # byte in both, so a swap of the two readers' lanes would pass unnoticed.
    emit("lw", "t3", 0, "a2")
    score("t3")                            # [0x128] = BYTE4, TXBUF read-back
    emit("lw", "t3", 0, "a1")
    score("t3")                            # [0x12C] = BYTE3, RXBUF unchanged

    wait_idle()                            # the frame completes
    emit("lw", "t1", 0, "a4")
    score("t1")                            # [0x130] = 0x02, TXIFG is back:
    #                                        the transmitter took the byte
    emit("addi", "t0", "zero", 0x01)       # IE = RXIE: mask TX, unmask RX
    emit("sw",   "t0", 0, "a3")
    emit("lw", "t3", 0, "a1")
    score("t3")                            # [0x134] = BYTE4, delivered by the
    #                                        loopback; the read drains RXIFG
    emit("lw", "t1", 0, "a4")
    score("t1")                            # [0x138] = 0x00

    # ---- round 4: the interrupt --------------------------------------------
    emit("addi", "t0", "zero", "ISR_RX")
    emit("sw",   "t0", 0, "s3")            # [0x008] = ISR_RX
    emit("addi", "gp", "zero", 1)          # EINT
    emit("addi", "t0", "zero", BYTE5)
    emit("sw",   "t0", 0, "a2")
    label("POLL_FLAG")
    emit("lw",  "t5", 0, "s2")
    emit("beq", "t5", "zero", -4)

    score("gp")                            # [0x13C] = 1, GIE restored by reti
    emit("addi", "t0", "zero", 0x5D)
    score("t0")                            # [0x140] = 0x5D
    emit("beq", "zero", "zero", 0)         # sentinel

    label("ISR_RX")
    emit("lw", "t3", 0, "a4")
    score_isr("t3")                        # [0x180] = 0x00, rule b at service
    emit("lw", "t3", 0, "a1")
    score_isr("t3")                        # [0x184] = BYTE4
    emit("lw", "t3", 0, "a5")
    score_isr("t3")                        # [0x188] = 0x00, TYPE idle
    emit("addi", "t5", "zero", 1)          # the flag main is polling
    emit("sw",   "t5", 0, "s2")            # [0x200] = 1
    emit("RAW", RETI_WORD)

    out = []
    for ins in prog:
        if ins[0] == "addi" and isinstance(ins[3], str):
            out.append(("addi", ins[1], ins[2], labels[ins[3]] * 4))
        else:
            out.append(ins)
    return out, {k: v * 4 for k, v in labels.items()}


# ── the second derivation: the vetted models on an emulated bus ──────────────
def interpret(prog, labels, trace=False):
    regs, dtcm = {}, {}
    uart, intc = UartPeriph(), Intc()

    # the loopback engine, transaction level. frame_left counts down the cycles
    # of the frame currently on the wire; while it is non-zero the transmitter
    # is not ready and the receiver is busy, and on its last cycle the byte
    # comes back in.
    eng = {"left": 0, "byte": 0}

    def eng_view():
        busy_frame = eng["left"] > 0
        return dict(din_rdy=0 if busy_frame else 1,
                    rx_busy=1 if busy_frame else 0,
                    dout_vld=1 if eng["left"] == 1 else 0,
                    dout=eng["byte"])

    def frame_cycles():
        baud = BAUD_HIGH if (uart.ctl >> 3) & 1 else BAUD_LOW
        return 10 * 16 * divider(CLK_HZ, baud)

    def rget(r):
        return regs.get(r, 0)

    def rset(r, v):
        if r != "zero":
            regs[r] = v & M32

    cyc = 0

    def tick(wr_u=None, rd_u=None, wr_i=None, inta=1):
        nonlocal cyc
        e = eng_view()
        u = uart.edge(wr=wr_u, rd=rd_u, dout_vld=e["dout_vld"], dout=e["dout"],
                      rx_busy=e["rx_busy"], din_rdy=e["din_rdy"])
        intc.edge(wr=wr_i, gie=rget("gp") & 1, inta=inta,
                  rx=u["rx_ev"], rxerr=u["rxerr_ev"], tx=u["tx_ev"],
                  rx_clr=u["rx_clr"], tx_clr=u["tx_clr"])
        if u["tx_ev"]:                          # the transmitter took the byte
            eng["left"] = frame_cycles()
            eng["byte"] = u["txbuf"]
        elif eng["left"] > 0:
            eng["left"] -= 1
        cyc += 1

    def mmio_read(a):
        """PRE-edge values, which is what a load in this cycle sees. BUSY is
        the model's own three-term expression evaluated against the current
        engine state -- the same formula, not a second definition of it."""
        e = eng_view()
        busy = 1 if (e["rx_busy"] or not e["din_rdy"] or uart.txbuf_vld) else 0
        if a == UCTL_A:  return uart.uctl_read(busy)
        if a == RXBUF_A: return uart.rxbuf
        if a == TXBUF_A: return uart.txbuf
        if a == IE_A:    return intc.ie
        if a == IFG_A:   return intc.view()
        if a == TYPE_A:  return intc.type_now()
        raise AssertionError(f"unexpected MMIO read {a:#x}")

    def mmio_wr(a, v):
        """returns (uart_write, intc_write) tuples for this edge"""
        if a == UCTL_A:  return ("uctl", v), None
        if a == TXBUF_A: return ("txbuf", v), None
        if a == IE_A:    return None, ("ie", v)
        if a == IFG_A:   return None, ("ifg", v)
        raise AssertionError(f"unexpected MMIO write {a:#x}")

    pc, steps = 0, 0
    while steps < 200_000:
        steps += 1

        # the Phase 9B entry, on the RTL's own condition (masked view AND GIE)
        if intc.view() != 0 and (rget("gp") & 1) == 1:
            tick(inta=0)                        # accept: capture + service clear
            tick()                              # Cycle 1 (TYPE push)
            tick()                              # Cycle 2 (vector fetch)
            rset("gp", rget("gp") & ~1)
            rset("tp", pc)
            pc = dtcm.get(intc.type_capt, 0)
            continue

        ins = prog[pc // 4]
        mn = ins[0]
        wr_u = wr_i = rd_u = None

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
            if a >= 0x2000:
                rset(rd, mmio_read(a))
                if a == RXBUF_A:
                    rd_u = "rxbuf"              # the READ SIDE EFFECT (REQ p12)
            else:
                rset(rd, dtcm.get(a, 0))
        elif mn == "sw":
            _, rs2, off, rs1 = ins
            assert off == 0
            a, v = rget(rs1), rget(rs2)
            if a >= 0x2000:
                wr_u, wr_i = mmio_wr(a, v)
            else:
                dtcm[a] = v
        elif mn in ("beq", "bne"):
            _, ra, rb, off = ins
            taken = (rget(ra) == rget(rb)) if mn == "beq" else \
                    (rget(ra) != rget(rb))
            if taken:
                if off == 0:
                    return dtcm, cyc
                pc += off
                tick(wr_u=wr_u, rd_u=rd_u, wr_i=wr_i)
                continue
        else:
            raise AssertionError(f"instruction outside the subset: {ins}")
        pc += 4
        tick(wr_u=wr_u, rd_u=rd_u, wr_i=wr_i)
    raise AssertionError("interpreter never reached the sentinel")


EXPECT = {
    0x008: None,                                  # filled from labels
    0x100: 0x08,
    0x104: 0x88,
    0x108: BYTE1,
    0x10C: 0x00,
    0x110: 0x08,
    0x114: 0x48,
    0x118: BYTE3,
    0x11C: 0x08,
    0x120: 0x02,
    0x124: 0x00,
    0x128: BYTE4,
    0x12C: BYTE3,
    0x130: 0x02,
    0x134: BYTE4,
    0x138: 0x00,
    0x13C: 1,
    0x140: 0x5D,
    0x180: 0x00,
    0x184: BYTE5,
    0x188: 0x00,
    0x200: 1,
}


def main():
    prog, labels = build()
    words = [ins[1] if ins[0] == "RAW" else enc(*ins) for ins in prog]

    EXPECT[0x008] = labels["ISR_RX"]

    dtcm, cycles = interpret(prog, labels)
    for a, v in sorted(EXPECT.items()):
        got = dtcm.get(a, 0)
        if got != v:
            sys.exit(f"CROSS-CHECK FAILED at [{a:#06x}]: the composed models "
                     f"produce {got:#x}, declared {v:#x}")
    extra = set(dtcm) - set(EXPECT)
    if extra:
        sys.exit(f"CROSS-CHECK FAILED: unexpected stores at "
                 f"{[hex(a) for a in sorted(extra)]}")

    div_hi = divider(CLK_HZ, BAUD_HIGH)
    frame = 10 * 16 * div_hi

    out = ROOT / "SIM" / "RV32IMscMCU" / "uartmmio"
    out.mkdir(parents=True, exist_ok=True)
    (out / "ITCM.hex").write_text(ihex(words))
    (out / "DTCM.hex").write_text(ihex([0] * 1024))

    lines = [
        "Directed MCU-level USART test -- tools/gen_uart_mmio_test.py",
        f"{len(prog)} instructions. Five bytes go out on TXD and come back on",
        "RXD; the testbench's only job is to tie the two pins together.",
        "",
        f"  UCTL  {UCTL_A:#06x} lane 0     IE   {IE_A:#06x} lane 0",
        f"  RXBUF {RXBUF_A:#06x} lane 1     IFG  {IFG_A:#06x} lane 1",
        f"  TXBUF {TXBUF_A:#06x} lane 2     TYPE {TYPE_A:#06x} lane 2",
        "",
        f"  BAUDRATE=1 -> divider {div_hi} at {CLK_HZ} Hz, so one 8N1 frame is",
        f"  10*16*{div_hi} = {frame} cycles. Five frames plus polling: the",
        f"  interpreter reaches the sentinel in {cycles} cycles.",
        "",
        f"  ISR_RX = {labels['ISR_RX']:#06x} -> DTCM word 2 (TYPE 08h, UART RX)",
        "",
        f"Expected DTCM after the sentinel -- {len(EXPECT)} stores, ALL EXACT:",
    ]
    for a in sorted(EXPECT):
        lines.append(f"  [{a:#06x}] = {EXPECT[a]:#04x}")
    lines += [
        "",
        "Derived twice: declared in gen_uart_mmio_test.py's EXPECT and",
        "reproduced by executing the program against model_uart.UartPeriph +",
        "model_interrupt_ctrl.Intc composed on an emulated bus, with the loop-",
        "back modelled at transaction level and the 9B entry protocol between",
        "them. Bit TIMING is not this file's claim -- tb_uart.vhd measures the",
        "start bit against the real engine.",
    ]
    (out / "listing.txt").write_text("\n".join(lines) + "\n")

    print(f"  {len(prog)} instructions, {len(EXPECT)} exact stores")
    print(f"  divider {div_hi}, frame {frame} cycles, sentinel at {cycles} cycles")
    print(f"  ISR_RX={labels['ISR_RX']:#x}")
    print(f"  wrote {out}/ITCM.hex, DTCM.hex, listing.txt")


if __name__ == "__main__":
    main()
