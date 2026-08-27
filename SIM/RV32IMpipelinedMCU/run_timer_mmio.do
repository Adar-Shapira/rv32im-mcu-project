# run_timer_mmio.do - the Basic Timer through the bus, on the PIPELINED MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\timer\{ITCM,DTCM}.hex                      #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate with:             #
# #     python3 tools/gen_timer_test.py                                #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   BASIC_TIMER.vhd is byte-identical in both DUT trees and
#   tools/check_peripheral_copies.py enforces it, so the timer core is already
#   proven here by run_timer.do (tb_basic_timer + model_basic_timer, eight
#   mutations caught). What is NOT shared is the CPU driving it. The same
#   113-instruction program configures the timer over the bus, reads all five
#   registers back (BTCTL2 written via its ODD byte address 0x201D), echoes
#   test4's capture bug at MCU level, forces the edge test4 meant, reads a
#   stable K back twice, and starts PWM - this time from the pipelined core.
#
#   The checks are IDENTICAL to the single-cycle testbench's. Only the
#   instantiation differs: store observation from MemWrite_ctrl_o / alu_res_o /
#   read_data2_o, and the sentinel watched in the MEM stage.
#
# THE TWO TIMING-DEPENDENT EXPECTATIONS SURVIVE UNCHANGED, FOR TWO REASONS
#   K, the captured count, is the number of cycles BTCNT ran between the
#   run-write and the hold-write, and everything between those two stores is
#   straight-line addi/slli/sw - no branch, no load, no divide, so no flush, no
#   load-use interlock and no divider hold. A pipeline retires straight-line
#   code at 1 IPC, so K does not move.
#   The PWM widths are produced by BASIC_TIMER off smclk with no CPU
#   involvement at all once the program has started it, so they cannot depend
#   on which core is driving.
#
# EXPECTED NUMBERS
#   VERDICT: PASS, failed 0, 7 scored stores, captured K in 1..60 (the
#   interpreter predicts 10 - see SIM/RV32IMscMCU/timer/listing.txt), and two
#   exact 10/31 PWM periods.

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/timer/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/timer/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench (tb_RV32IMpipelinedMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_timer_mmio.vhd

# -gMODELSIM=1: G_MODELSIM ships at 0 for Quartus, and this bench instantiates
# the whole MCU. Without the switch CLOCK_TREE builds the real altpll instead of
# the behavioural clocks - which would also break the PWM measurement below,
# since it is counted in testbench clocks against a timer running on smclk.
vsim -t ns -gMODELSIM=1 work.tb_timer_mmio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo ""
echo "FIRST THING TO DO ON A FAILURE: run the single-cycle bench,"
echo "  do run_timer_mmio.do  in SIM\\RV32IMscMCU"
echo "BASIC_TIMER is byte-identical in both trees, so if that one passes the"
echo "fault is in the bus path or the core, not in the timer."
echo ""
echo "If K is outside 1..60: the run-to-hold window took far longer here than"
echo "  the 1-IPC argument predicts - read the interval in the waveform before"
echo "  widening the range, because a much larger K means a stall nobody"
echo "  expected in straight-line code."
echo "If the PWM widths are wrong: that path does not involve the CPU, so"
echo "  suspect the clock configuration (-gMODELSIM=1) before the timer."
