# run_uart_menu.do - clause 8's menu, on the PIPELINED MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\menusim\{ITCM,DTCM}.hex                    #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate with:             #
# #     python3 tools/gen_uart_menu.py                                 #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   Every peripheral is byte-identical between the two DUT trees, and
#   tools/check_peripheral_copies.py enforces that, so the USART itself is
#   already proven by the single-cycle run. What is NOT shared is the core.
#   The pipelined interrupt entry is a different design - its own retirement
#   boundary, its own flush, RXBUF's read side effect landing in the MEM
#   stage. The same 423-character stream and the same two LED sequences are
#   expected of it.
#
#   The checks are IDENTICAL to the single-cycle testbench's. Only the
#   instantiation differs: store observation comes from MemWrite_ctrl_o /
#   alu_res_o / read_data2_o, and the sentinel is watched in the MEM stage,
#   because branches resolve there and a decode-stage watch would stop on a
#   speculative fetch of the final self-jump (the trap batch_verify.do
#   documents).

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/menusim/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/menusim/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_uart_menu.vhd

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
vsim -t ns -gMODELSIM=1 work.tb_uart_menu
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo "If the single-cycle run of the same test passes and this one does not,"
echo "the fault is in the PIPELINED CORE, not in the USART: the peripherals"
echo "are byte-identical in both trees and a checker asserts it."
