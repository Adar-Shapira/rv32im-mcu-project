# run_bench_test4.do - Phase 10B: Interrupt benchmark test4 on the full MCU
#
# Run compile.do first (design only - since the clause 10 rewrite it compiles
# just the official tb_RV32IMscMCU; this script vcom's its own testbench).
#
# ######################################################################
# # STAGING IS AUTOMATIC: this script copies the CORRECTED images from  #
# # bench_fixed\test4 into app_bin itself (run_test.do's own idiom).    #
# # To reproduce the shipped G-327 bug ONCE for the report, set         #
# # `set ORIGINAL 1` below and re-run - it stages the untouched         #
# # Auxiliary originals instead.                                        #
# ######################################################################
#
# WHY THE CORRECTED IMAGE - A DOCUMENTED BENCHMARK BUG (Q10 / G-327)
#   Shipped test4 writes BTCTL2 = 0x07 both before and after the measured
#   loop; its own comments say "GND" then "VCC" but the value never changes,
#   so no capture edge exists. The copy under bench_fixed/test4 changes
#   exactly ONE word (ITCM word 265, byte 0x424: capture's 0x07 -> 0x06 =
#   rising + CAPISEL VCC - audited in bench_fixed/PATCHES.md, and it is the
#   GND->VCC event Hanan's prep session walks through).
#
# WHAT THE ONE-WORD FIX DOES NOT REPAIR - found in Phase 10B, recorded in
# the plan and DOC/03 (question B6):
#   capture_init then writes BTCTL1=0x24, which (a) zeroes BTINT, so the
#   capture event sets no BTIFG and BT_ISR never runs, and (b) keeps
#   BTHOLD=1,BTCLR=1 through the measured window, so BTCNT is pinned at 0
#   and BTCAPR latches 0. So runtime_div/runtime_rem MUST stay 0 - the
#   testbench asserts exactly that, and the capture EDGE is proven here,
#   below, by counting /tb_bench_test4/MCU/TIMER/cap_ev_w pulses (the same
#   hierarchical reach mem_dump.do already uses). Expected: exactly 3,
#   one per KEY3 press.
#
# WHAT PASS MEANS
#   The supplied application - the course contract - runs on the full MCU:
#   KEY3 twice fills remarr {4,10,5,0,10,6,2,16,13,10} then divarr
#   {7,6,6,6,5,5,5,4,4,4} through the divider accelerator; KEY1 programs
#   compare mode (BTCMPR0=SEC_PERIOD>>3, BTCTL1=0x18, IE=0x3C); a third
#   KEY3 refills divarr and parks BTCNT; KEY2 twice runs the PWM at
#   period 4008 pclk with high 2000 then 1000 pclk (duty 0.5 then 0.25,
#   README's ladder for a7=4,5). All 83 stores exact, in order.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the 1-second compare-mode cadence - BTCMPR0 is >= 2.5M
#   ticks in every mode-1 arm (SEC_PERIOD, question B2), so the BT compare
#   interrupt itself is FPGA material, exactly like tests 2/3. The KEY1
#   press here proves the configuration path and the KEY1 ISR only.

onerror {quit -code 1}

# 0 = the corrected copy (the normal run); 1 = the shipped originals, which
# reproduces G-327: first scoreboard mismatch at store #28 and 0 cap events.
set ORIGINAL 0

if {$ORIGINAL} {
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test4/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test4/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
    echo "STAGED THE ORIGINAL (bugged) test4 images - this run documents G-327."
} else {
    file copy -force bench_fixed/test4/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force bench_fixed/test4/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
}

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench, so it is compiled here.
vcom -2008 ../../TB/RV32IMscMCU/tb_bench_test4.vhd

# MODELSIM=1 is mandatory: at 0 the clock tree instantiates real pll_gen
# megafunctions (run_timer_mmio.do's form, not a package edit).
vsim -t ns -gMODELSIM=1 work.tb_bench_test4

# Count capture events inside the timer - the direct observation of what the
# one-word fix exists to create. cap_ev_w is one clean clk-wide pulse per
# CAPMD-selected edge (BASIC_TIMER.vhd's capsync/cap_ev_w).
quietly set ::cap_events 0
when {/tb_bench_test4/MCU/TIMER/cap_ev_w == "1"} { quietly incr ::cap_events }

# The testbench ends with std.env.stop, which is a BREAK; without this the
# macro halts there and the CAPTURE EVENTS verdict below never prints
# (run_test.do:25 is the project precedent).
onbreak {resume}

run -all

# Deregister the watch so it cannot keep counting into a later test when this
# script is sourced from regress.do.
nowhen *

echo ""
if {$::cap_events == 3} {
    echo "CAPTURE EVENTS SEEN: 3 of 3 - the patched BTCTL2 write (0x07->0x06,"
    echo "  GND->VCC) produced exactly one rising capture event per KEY3 press."
} else {
    echo "CAPTURE EVENTS SEEN: $::cap_events, expected 3 - THE CAPTURE EDGE CHECK FAILED."
    echo "  0 with everything else passing usually means the ORIGINAL image is"
    echo "  staged (its BTCTL2 never changes value). Any other number: look at"
    echo "  BTCTL2 stores in the wave and at BASIC_TIMER's capsync chain."
}
echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0,"
echo "  plus CAPTURE EVENTS SEEN: 3 of 3 just printed."
echo ""
echo "If the FIRST scoreboard mismatch is store #28 (201D = 06 vs 07): the"
echo "  ORIGINAL test4 image is staged; stage bench_fixed\\test4. (Seeing that"
echo "  once is the G-327 bug's repro, worth doing ONCE for the report.)"
echo "If divarr/remarr values mismatch: the divider path broke - run"
echo "  run_div.do and run_divunit.do before touching anything here."
echo "If PWM widths are off by a factor of 8: BTSSEL divide chain - run_timer.do."
echo "If store counts stall at a phase boundary: that press's ISR never ran -"
echo "  interrupt entry; run_intc.do and run_intr_mmio.do isolate it."
