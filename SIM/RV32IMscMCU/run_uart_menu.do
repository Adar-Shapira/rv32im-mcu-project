# run_uart_menu.do - Phase 12C: clause 8's menu, bench acting as the PC
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC: this script copies                           #
# # SIM\RV32IMscMCU\menusim\{ITCM,DTCM}.hex into app_bin itself.       #
# # NOTE menusim, NOT menu. Both sets carry a BYTE-IDENTICAL ITCM and  #
# # differ in exactly one DTCM word, V_HALFSEC:                        #
# #     menu\     9,999,999 -> 0.5 s at SMCLK = 20 MHz  (the board)    #
# #     menusim\  1,999     -> a tick every 2000 cycles (simulation)   #
# # Regenerate both with: python3 tools/gen_uart_menu.py               #
# ######################################################################
#
# WHAT THIS IS
#   Clause 8's menu, running on the MCU, with the testbench playing the PC
#   terminal: it shifts characters onto UART_RXD_i at the real bit time
#   (176 cycles per bit) and decodes UART_TXD_o back into characters by
#   sampling mid-bit. It then works through the menu the way a person
#   would:
#       collect the startup menu          -> send '2'
#       four LED values down from 0xFF    -> send '1'
#       four LED values up from 0x00      -> send '3'
#       LEDs cleared and counting stopped -> send '4'
#       press and RELEASE KEY1            -> collect "I love my Negev"
#       send '5'                          -> collect the menu again
#
# WHAT PASS MEANS
#   - The firmware transmits clause 8's menu text, character-exact, out of
#     TXBUF one character per main-loop pass with BUSY respected.
#   - Every command arrives as a REAL RX INTERRUPT: TYPE 08h -> the vector
#     word the program wrote -> ISR_RX -> RXBUF -> reti.
#   - The ~0.5 s tick is the Basic Timer's EQU0 as an interrupt (TYPE 10h),
#     with rule a's auto-clear at service.
#   - Item 1 counts UP from 0x00 and item 2 DOWN from 0xFF on PORT_LEDR.
#     Item 1 says LEDG in the specification; see the note below.
#   - Item 3 clears the LEDs AND stops the count - the bench checks that
#     PORT_LEDR does not move again afterwards.
#   - KEY1 produces the message on its RELEASE edge (DOC/03 section C), and
#     the handler clears KEY1IFG with the supplied benchmarks' own and-mask
#     store, because rule d says the KEYs are cleared manually.
#   - Item 5 re-transmits the menu.
#
# ITEM 1 SAYS LEDG. THE BOARD HAS LEDG; THE SPECIFICATION HAS NO REGISTER.
#   Auxiliary\Lab4\Auxiliary\DE2_115_pin_assignments.csv lists nine green
#   LEDs with pins, so the earlier claim that the DE2-115 has none was
#   wrong. But clause 4's output interface is "Board 10 red LEDs
#   (LEDR9-LEDR0)" and clause 5's GPIO table has exactly one LED register,
#   PORT_LEDR at 0x2000. There is no memory-mapped path to LEDG anywhere in
#   the document, and LEDG appears in it exactly once - in this menu line.
#   So item 1 counts on PORT_LEDR and the transmitted text says LEDR, so
#   that what the operator reads matches what the LEDs do. Question R2.
#
# WHAT PASS DOES NOT MEAN
#   Not the ~0.5 s wall clock: this run ticks every 2000 cycles. The board
#   image carries 9,999,999 = 10,000,000 SMCLK ticks, cross-checked against
#   the supplied benchmarks' SEC_PERIOD = 20,000,000 for one second at the
#   same BTSSEL setting.
#   Not clause 9's PC end - a real terminal over the FTDI cable is Phase 15,
#   on the board, and needs the .sof and the cable.
#
# RUNTIME
#   The longest test after run_div.do: 423 characters at 1760 cycles each is
#   about 745,000 cycles, so roughly 75 ms of simulated time. That is the
#   price of transmitting the real menu text twice at the real bit rate
#   rather than a shortened stand-in.
#
# EXPECTED FIRST-RUN BEHAVIOUR
#   The transmitted stream and both LED sequences were derived twice:
#   produced by tools/gen_uart_menu.py's interpreter running this exact
#   program against model_uart.UartPeriph + model_interrupt_ctrl.Intc +
#   model_basic_timer.Timer with the same scripted PC, and checked here
#   against string constants THE GENERATOR VERIFIES it still agrees with.

onerror {quit -code 1}

# Staging, done here so the flow has no manual copy step (Phase 13).
# Images: generated: tools/gen_uart_menu.py
file copy -force menusim/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force menusim/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_uart_menu.vhd

vsim -t ns work.tb_uart_menu
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0, 423"
echo "characters decoded."
echo ""
echo "If nothing was decoded at all: the transmitter never moved. run_uart.do"
echo "  (the leaf loopback) and run_uart_mmio.do (the bus) come first - if"
echo "  either fails, fix that before reading anything here."
echo "If the menu is right but no command ever takes effect: the RX interrupt."
echo "  Check IE was written 0x0D, that vector word 2 holds ISR_RX, and that"
echo "  run_uart_mmio's [0x200] check passed."
echo "If the LEDs never move: the Basic Timer tick. BTCMPR0 comes from the"
echo "  V_HALFSEC DTCM word - if the menu\\ image was staged instead of"
echo "  menusim\\, the first tick is ten million cycles away and this test"
echo "  will time out looking like a dead timer."
echo "If the message never arrives after KEY1: either item 4 did not arm it,"
echo "  or the request is being taken on the PRESS instead of the RELEASE."
echo "If the count keeps going after item 3: V_MODE is not being cleared."
