# run_uart.do - Phase 12A: the USART peripheral in UART mode (bonus, 6.iv)
#
# Run compile.do first (design only - since the clause 10 rewrite it compiles
# just the official tb_RV32IMscMCU; this script vcom's its own testbench).
#
# ####################################################################
# # ZERO SETUP. No memory images, nothing to stage. A leaf test, like #
# # run_sync/run_decode/run_clock/run_div/run_divunit/run_timer/      #
# # run_intc.                                                         #
# ####################################################################
#
# WHERE THIS UART COMES FROM
#   Clause 6.iv: "You are given a VHDL design code that needs to be adapted
#   to the following UART mode features." The given code is
#   Auxiliary/USART Material/UART_FPGA_option1 (jakubcabal/uart-for-fpga
#   v1.1, MIT, Copyright (c) 2015 Jakub Cabal) - option 1 rather than option
#   2 because it is the only one with a licence, and because its baud
#   divider is one isolated process, which is what makes REQ p12's runtime
#   rate selection tractable.
#
#   UART_TX / UART_PARITY / UART_DEBOUNCER are his files BYTE-IDENTICAL
#   (headers prepended, md5s recorded in each). UART_RX is his plus one
#   RX_BUSY output - the original exports nothing usable for UCTL bit 7, and
#   rx_receiving_data, which looks like the signal, is only high during the
#   data bits. UART_CORE is his top level adapted. UART_PERIPH is ours: the
#   whole register layer, because neither supplied option has RXBUF/TXBUF,
#   overrun logic, an aggregate BUSY, SWRST, a runtime baud rate, or any bus
#   interface at all.
#
# A FINDING WORTH READING BEFORE THE RUN
#   The original computes its divider as CLK_FREQ/(16*BAUD), TRUNCATING. At
#   this project's SMCLK = 20 MHz (forum answers F8/F11) and 115200 baud that
#   gives 10, i.e. 125000 baud - an error of +8.5%, which no 8N1 link
#   survives. Rounding gives 11 -> 113636 baud, -1.36%. At the original's own
#   default of 50 MHz truncation lands at +0.47%, which is why the formula
#   looks harmless in its home configuration. UART_CORE.vhd rounds, and
#   asserts the resulting error at ELABORATION for any CLK_HZ, so a wrong
#   clock is a compile error rather than a silent dead link.
#
# WHAT PASS MEANS
#   P1  reset: UCTL = 0x00 (A25 - SWRST = 0, the USART is operational out of
#       reset), buffers clear, txd idling high.
#   P2  UCTL's four control bits store and read back; a write cannot reach
#       bits 6:4, which are the hardware's OE/PE/FE.
#   P3  THE LOOPBACK. txd_o is wired to rxd_i, so two different bytes are
#       serialised as real 8N1 frames at the real divider and must come back
#       byte-for-byte, with BUSY rising and falling around each and no FE or
#       OE. Nothing here is emulated.
#   P4  the RXBUF read strobe pulses for one cycle and does not corrupt the
#       buffer.
#   P5  a FRAMING ERROR, which a correct loopback can never produce: the
#       loopback is broken and a frame with a LOW stop bit is driven onto rxd
#       by hand. FE must set, an error event must fire, and the data must NOT
#       reach RXBUF (the receiver gates DOUT_VLD on the stop bit). Reading
#       RXBUF must then clear FE - REQ p12, "reading RXBUF resets the
#       receive-error bits".
#   P6  OVERRUN: a second character arrives with the first unread. OE sets,
#       an error event fires, RXBUF holds the NEW byte, and a read clears OE.
#   P7  THE DIVIDER, MEASURED. A loopback cannot detect a baud rate that is
#       wrong but self-consistent - both ends share the divider - so the
#       start-bit width on txd_o is counted directly: 176 cycles at 115200
#       and 2080 at 9600, both derived in the testbench header and asserted
#       independently by tools/model_uart.py.
#   P8  SWRST holds the engine in reset, clears the receive flags and drops
#       the queued transmit byte (which could never leave), while NOT
#       clearing itself or BAUDRATE - either would be unrecoverable or
#       silently halve the link speed. Then it is cleared and the link works
#       again.
#   Plus anti-vacuity: at least five characters received and five sent, so a
#   run that quietly did nothing cannot report PASS.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the bus wiring at 0x2018/9/A - CS_UART and its three lanes
#   have been decoded and exhaustively tested since Phase 5A, but this UART
#   is not attached to them yet; that is Phase 12B, together with the two new
#   interrupt-controller inputs that consume rx_clr_o / tx_clr_o (rules b and
#   c). Nothing about parity: this build is 8N1, per REQ p12's own feature
#   list, with PENA/PEV stored and PE reading 0 - assumption A26. And nothing
#   about the board: clause 9's RS-232 link and clause 8's menu firmware need
#   the cable, the JP1 pins (F18/B1) and Phase 15.
#
# WHY THE FIRST RUN SHOULD PASS
#   tools/model_uart.py executes the register layer's semantics through these
#   same phases: 0 failures, and TWELVE faithful mutations all caught -
#   including the reference's truncating divider, an accept that beats a
#   colliding TXBUF write, a read that fails to clear FE/OE, the read-and-
#   arrive collision misreported as an overrun, and SWRST clearing its own
#   bit. Two of those twelve escaped the first draft of that phase suite and
#   the holes were closed; the notes are in the model at P3f and P9a.

onerror {quit -code 1}

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_uart.vhd

vsim -t ns work.tb_uart

# The testbench ends with std.env.stop, which is a BREAK; without this the
# macro halts there and the diagnostics below never print (run_test.do:25).
onbreak {resume}

run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0, with at"
echo "least 5 characters received and 5 sent."
echo ""
echo "If P3 fails with no character at all: the loopback produced nothing -"
echo "  check the transmitter first (P7a measures whether txd moves at all)."
echo "If P3 returns a WRONG byte: bit order or frame shape - the engine is"
echo "  jakubcabal's and LSB-first, so suspect UART_CORE's divider wiring."
echo "If P7a or P7b fails on the measured width: the baud divider is wrong."
echo "  That is the one thing the loopback cannot see, so trust this over P3."
echo "If P5c fails - data reached RXBUF from a bad frame - the receiver's"
echo "  DOUT_VLD gating was changed; it must be gated on the stop bit."
echo "If P6d fails: the overrun condition. Note the case that is NOT an"
echo "  overrun (arrival in the same cycle as the read) is checked by the"
echo "  model, at P7e/P7f there."
echo "If P8b or P8c fails: SWRST is clearing more than the engine state."
