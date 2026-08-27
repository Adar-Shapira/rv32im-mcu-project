# run_uart_mmio.do - Phase 12B: the USART on the bus, end to end on the MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC: this script copies                           #
# # SIM\RV32IMscMCU\uartmmio\{ITCM,DTCM}.hex into app_bin itself, so   #
# # no other image set can reach this test.                            #
# # Regenerate with: python3 tools/gen_uart_mmio_test.py               #
# ######################################################################
#
# WHAT THIS IS
#   Phase 12A proved the USART as a LEAF (run_uart.do: a real txd->rxd
#   loopback with the start bit MEASURED, plus tools/model_uart.py on the
#   register layer). This is the same peripheral on the BUS: a real program
#   writes UCTL at 0x2018, TXBUF at 0x201A and reads RXBUF at 0x2019 -
#   three lanes of CS_UART - watches IFG at 0x202D, and takes a real
#   vectored RX interrupt. The bench does exactly ONE thing: it ties
#   UART_RXD_i to UART_TXD_o, which is what a loopback plug on the board's
#   DB9 does. All 22 expected stores are EXACT - no ranges.
#
# WHAT PASS MEANS
#   - CS_UART and lanes 0/1/2 decode: UCTL 0x2018, RXBUF 0x2019, TXBUF
#     0x201A, and the three readers return the right register. One scored
#     pair ([0x128]=0x71 while [0x12C]=0x3C) exists precisely so that a
#     swap of the RXBUF and TXBUF lanes FAILS - everywhere else a loopback
#     puts the same byte in both.
#   - MemRead_i reaches the peripheral, so RXBUF's read side effect happens
#     at all: [0x10C]=0 is RXIFG cleared BY THE READ, no W0C anywhere. That
#     is clearing rule b's software half, i.e. rx_clr_o -> interrupt_ctrl.
#   - [0x124]=0 is rule c's software half the same way: writing TXBUF
#     clears TXIFG, i.e. tx_clr_o -> interrupt_ctrl. Both inputs are new in
#     12B; before it they were tied to '0'.
#   - BUSY has its third term: [0x104]=0x88 is read one cycle after the
#     TXBUF write, while the byte is only QUEUED and neither shift register
#     has moved. A two-term BUSY reads 0x08 there and a polling driver
#     would overwrite an unsent character.
#   - The overrun path: [0x114]=0x48, and [0x11C]=0x08 because reading
#     RXBUF resets the receive-error bits too (REQ p12's own sentence).
#   - One RX interrupt, all the way: TYPE 08h -> the vector word the
#     program itself wrote -> the ISR -> reti with GIE restored.
#
# WHAT PASS DOES NOT MEAN
#   Not the bit timing: both ends of the loopback share one divider, so a
#   wrong-but-consistent baud rate would still come back. run_uart.do is
#   where the start bit is measured (176 cycles at 115200, 2080 at 9600).
#   Not the same-cycle read-and-arrive overrun case either - that needs a
#   load to land on the frame's last cycle and is not reachable from a
#   program; model_uart.py's phase P7e owns it.
#   And not the clause 8 menu firmware - that is Phase 12C, on this same
#   hardware.
#
# EXPECTED FIRST-RUN BEHAVIOUR
#   The program and its 22 expectations were derived twice: declared in
#   tools/gen_uart_mmio_test.py, and reproduced by executing the program
#   against model_uart.UartPeriph + model_interrupt_ctrl.Intc composed on
#   an emulated bus with the 9B entry protocol between them. The run is
#   about 9000 cycles - five 8N1 frames at 1760 cycles each plus polling -
#   so at 100 ns per cycle expect roughly 0.9 ms of simulated time.

onerror {quit -code 1}

# Staging, done here so the flow has no manual copy step (Phase 13).
# Images: generated: tools/gen_uart_mmio_test.py
file copy -force uartmmio/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force uartmmio/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_uart_mmio.vhd

# -gMODELSIM=1 is REQUIRED, and was missing until 2026-08-27.
#   G_MODELSIM ships at 0 (the Quartus value -- tools/check_config_defaults.py
#   asserts it), and this testbench instantiates the WHOLE MCU, so at the
#   package default CLOCK_TREE takes its CLK_FPGA branch and builds two real
#   altpll megafunctions fed by the bench's 100 ns clock instead of the
#   behavioural clocks. mclk would then be a PLL output at the 2/5 ratio rather
#   than clk_i itself, every cycle-counted bound in the bench would be measured
#   against the wrong clock, and with GEN_RESET_ON_LOCK the core does not leave
#   reset until that PLL reports lock. Every other whole-MCU script in this
#   project passes the switch; these four did not.
vsim -t ns -gMODELSIM=1 work.tb_uart_mmio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0, and a"
echo "transition count well above 20 - five 8N1 frames on the line."
echo ""
echo "If it timed out, the message names which poll loop to look at. In order:"
echo "  no RXIFG ever      -> nothing came back on RXD. Check UART_TXD_o and"
echo "                        UART_RXD_i are both port-mapped in the MCU, then"
echo "                        that run_uart.do (the leaf loopback) passes."
echo "  RXIFG never visible-> IE. What software reads from IFG is the MASKED"
echo "                        view (irq AND ie); with IE=0 it can never change."
echo "  OE never set       -> the second character did not overrun, so either"
echo "                        full_q or the oe_set term is wrong."
echo "  [0x200] stayed 0   -> the RX interrupt never entered. rx_ev_o -> the"
echo "                        controller's rx_ev_i is the suspect wire."
echo "If [0x10C] is 0x01: rx_clr_o is not reaching interrupt_ctrl (rule b)."
echo "If [0x124] is 0x02: tx_clr_o is not reaching it either (rule c)."
echo "If [0x12C] is 0x71: the RXBUF and TXBUF readers are on swapped lanes."
echo "If [0x104] is 0x08: BUSY lost its txbuf_vld term."
