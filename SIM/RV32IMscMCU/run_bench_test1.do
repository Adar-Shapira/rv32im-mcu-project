# run_bench_test1.do - Phase 10A: Interrupt benchmark test1 on the full MCU
#
# Run compile.do first (design only - since the clause 10 rewrite it compiles
# just the official tb_RV32IMscMCU; this script vcom's its own testbench).
#
# ######################################################################
# # STAGING IS AUTOMATIC: this script copies the CORRECTED images from  #
# # bench_fixed\test1 into app_bin itself (run_test.do's own idiom).    #
# # To reproduce the shipped B5 bug ONCE for the report, set            #
# # `set ORIGINAL 1` below and re-run - it stages the untouched         #
# # Auxiliary originals instead.                                        #
# ######################################################################
#
# WHY THE CORRECTED IMAGE - A DOCUMENTED BENCHMARK BUG (DOC/03)
#   Shipped test1 gates EINT on SW0: the SW0=0 short-delay path - the one
#   its own comments call "used for ModelSim based verification" - jumps
#   past `ori gp,gp,1`, so GIE stays 0 and no KEY ever interrupts. tests
#   2/3/4 enable EINT unconditionally; test1 alone differs. The original
#   stays untouched under Auxiliary/; the copy under bench_fixed/ changes
#   exactly ONE word (the jal target - audited in bench_fixed/PATCHES.md)
#   and is what this run stages. If you stage the ORIGINAL instead, every
#   check after init fails with all displays frozen at zero - which is
#   itself the reproduction of the bug, worth doing ONCE for the report.
#
# WHAT PASS MEANS
#   The supplied application - the course contract - runs on the full MCU:
#   KEY1 puts arr1[0]=0x64 on HEX5:4, KEY2 puts arr2[0]=8 on HEX3:2, KEY3
#   runs the whole STATE3 sweep (fp stays 3 on the increment path): eight
#   real divisions on the divider accelerator and then the sweep's tail,
#   MEM[0x44]/MEM[0x64] = 8/0 - both words read from the shipped DTCM.hex
#   - so the final display is the divide-by-zero contract: HEX1:0 = FF
#   (all-ones quotient, forum answer F4) and LEDR = 0x08 (remainder = the
#   dividend). A SECOND sweep is then watched event-driven: LEDR must pass
#   through 0x04 (100 rem 8) and settle at 0x08 - a changing observable,
#   so a hung system cannot pass on stale displays.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about tests 2/3 in ModelSim - their SEC_PERIOD interrupt
#   interval is 20,000,000 SMCLK ticks (8 s at the programmed divide-by-8;
#   question B2), which is not simulatable as shipped; they are FPGA
#   material, or need a separately-marked short-period copy if ModelSim
#   coverage is ever wanted. test4 has its own corrected copy
#   (bench_fixed/test4, the 0x06 capture fix) and its own phase.

onerror {quit -code 1}

# 0 = the corrected copy (the normal run); 1 = the shipped originals, which
# reproduces B5: everything after init fails with the displays frozen at 0.
set ORIGINAL 0

if {$ORIGINAL} {
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
    echo "STAGED THE ORIGINAL (bugged) test1 images - this run documents B5."
} else {
    file copy -force bench_fixed/test1/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force bench_fixed/test1/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
}

# Development-only testbench: compile.do stopped compiling dev TBs when it was
# restricted to the clause 10 official testbench, so it is compiled here.
vcom -2008 ../../TB/RV32IMscMCU/tb_bench_test1.vhd

# MODELSIM=1 is mandatory: at the committed package default (G_MODELSIM=0)
# the clock tree instantiates real pll_gen megafunctions and the behavioral
# clocks never exist. Found in Phase 10B review; run_timer_mmio.do's form.
vsim -t ns -gMODELSIM=1 work.tb_bench_test1

# The testbench ends with std.env.stop, which is a BREAK; without this the
# macro halts there and the diagnostics below never print (run_test.do:25).
onbreak {resume}

run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo ""
echo "If EVERYTHING after init failed and displays stayed at digit 0: the"
echo "  ORIGINAL image is staged; its SW0=0 path never executes EINT. Stage"
echo "  bench_fixed\\test1. (Seeing that dead state once is the bug's repro.)"
echo "If the sweep checks fail with HEX1:0 not FF: either the divider's"
echo "  divide-by-zero contract broke (run_div.do P-cases) or the sweep did"
echo "  not run to its tail (interrupt entry or state kernel)."
echo "If the second sweep's LEDR=0x04 wait times out: the system hung after"
echo "  the first sweep - suspect IFG clearing in the ISR (W0C path)."
