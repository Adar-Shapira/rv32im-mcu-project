# run_intr_mmio.do - the interrupt path end to end, on the PIPELINED MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\intrmmio\{ITCM,DTCM}.hex                   #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate with:             #
# #     python3 tools/gen_intr_mmio_test.py                            #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   INTERRUPT_CTRL.vhd, KEYCOND and BASIC_TIMER are byte-identical in both DUT
#   trees and tools/check_peripheral_copies.py enforces it, so the controller
#   itself is already proven here by run_intc.do. This test is about the two
#   sides WIRED TOGETHER, and that half is not shared: the TYPE push is a real
#   driver of the one shared bidirectional bus and it has to arrive in the
#   cycle the CORE captures it. On this core the entry also happens at a MEM
#   retirement boundary with three younger stages killed.
#
#   No testbench emulation anywhere in the path: a real KEY1 release on the raw
#   active-low pin and a real Basic Timer EQU0 each travel pin/timer ->
#   INTERRUPT_CTRL -> INTR -> the pipelined two-cycle entry -> the TYPE push
#   over the bus -> the vector the program itself wrote -> the ISR reading and
#   W0C-clearing IFG through the bus -> reti. The bench does exactly one thing:
#   presses KEY1 when the program says it is ready.
#
# WHY ALL 14 EXPECTATIONS STAY EXACT - NO RANGES, EVEN ON A PIPELINE
#   Neither interrupt moment is pinned by BENCH timing. The program is sitting
#   in a poll loop when the key is pressed and stays there until the ISR clears
#   it, so it does not matter how many cycles behind the single-cycle core this
#   one is. Round 2 is pinned by a timer count that runs off smclk and does not
#   involve the CPU. Every value below is something the program POLLED for or
#   read back, never a cycle count.
#
# WHAT PASS MEANS
#   - CS_INTC and lanes 0/1/2 decode (IE at 0x202C, IFG at the ODD 0x202D,
#     TYPE at 0x202E - the map's first lane-2 register).
#   - The release edge of a real pin becomes an interrupt (DOC/03 C).
#   - TYPE reads 0x14 inside the KEY ISR while the flag pends (rule d), and the
#     benchmark and-mask store clears it (W0C) - all via the bus.
#   - bt_ifg_set_w raises an interrupt with no pin involved; the BT ISR reads
#     IFG = 0, i.e. rule a's auto-clear observed from software.
#   - IE reads back 0x0C; IFG/TYPE read 0 when idle; gp reads 1 after both
#     retis; the end marker lands - main resumed both times.
#
# WHAT PASS DOES NOT MEAN
#   Nothing new about the controller's corner cases (run_intc.do) or the entry
#   FSM's timing corners including F13 - that is run_intr_core.do, which on
#   this core raises its request off EXinstruction_o for reasons its own header
#   explains.

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/intrmmio/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/intrmmio/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench (tb_RV32IMpipelinedMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_intr_mmio.vhd

# -gMODELSIM=1: G_MODELSIM ships at 0 for Quartus, and this bench instantiates
# the whole MCU. Without the switch CLOCK_TREE builds the real altpll instead of
# the behavioural clocks. The single-cycle copy of this script was one of the
# five that were MISSING this until 2026-08-27; tools/check_staging.py now
# asserts it on every whole-MCU vsim line.
vsim -t ns -gMODELSIM=1 work.tb_intr_mmio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0,"
echo "14 scored stores, every value exact."
echo ""
echo "FIRST THING TO DO ON A FAILURE: run the single-cycle bench,"
echo "  do run_intr_mmio.do  in SIM\\RV32IMscMCU"
echo "INTERRUPT_CTRL and KEYCOND are byte-identical in both trees, so if that"
echo "one passes the fault is in the core or the bus path, not the controller."
echo ""
echo "If [0x200] stayed 0: the KEY1 RELEASE never became an interrupt."
echo "If [0x204] stayed 0: the timer's EQU0 never became one."
echo "If TYPE read 0x00 instead of 0x14 inside the ISR: the push did not drive"
echo "  the bus in the cycle the core captured it - the one thing this test"
echo "  exists to catch, and the one most likely to differ between the cores."
echo "If the run never finishes and [0x208] appeared: the entry never accepted."
echo "  On this core acceptance also needs a NON-BUBBLE instruction in MEM"
echo "  (mem_active_w), so check the poll loop is not all flush bubbles."
