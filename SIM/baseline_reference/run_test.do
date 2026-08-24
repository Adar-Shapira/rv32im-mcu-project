# run_test.do - run one Lab 5 benchmark against the UNMODIFIED reference core
#
# Edit N below, then:  do run_test.do
# Run compile.do first, once.
#
# WHAT THIS PROVES
#   The four cycle counts and the four DTCM images. If they reproduce, the tool
#   install, the staged benchmark images and the reference RTL are all sound, and
#   any later failure belongs to a change of ours. That is the whole point of
#   Phase 0, and nothing built on top of it means anything until it passes.
#
# THE EXPECTED NUMBERS, AND WHERE THEY COME FROM
#   Two independent written sources in the reference itself, which is better
#   evidence than the scripts that were deleted:
#     Auxiliary/Lab 5/PROJECT_EXPLANATION.md      §7.1-7.4
#     Auxiliary/Lab 5/DOC/HANDOVER_Report_lab5.md §5.3
#
#     test1  mclk_cnt_o = 134   at  13.4 us   terminal pc_o = 0x0070
#     test2  mclk_cnt_o = 1514  at 151.4 us   terminal pc_o = 0x0070
#     test3  mclk_cnt_o = 2725  at 272.5 us   terminal pc_o = 0x00CC
#     test4  mclk_cnt_o = 2735  at 273.5 us   terminal pc_o = 0x004C
#
#   The 100 ns testbench clock makes simulated time and cycle count the same
#   number to within a factor of 0.1 us, which is why 134 cycles lands at 13.4 us.
#   This clock is simulation-only; the PLL is bypassed at MODELSIM = 1.

set N 1

onerror {quit -code 1}

# ---------------------------------------------------------------------------
# Stage the benchmark. The ITCM/DTCM init_file paths are hardcoded inside
# IFETCH.vhd and DMEMORY.vhd, so the images have to be copied to that exact
# location rather than pointed at. Tcl needs forward slashes.
# ---------------------------------------------------------------------------
set SRC C:/TestPrograms/Quartus21_1/test$N/bin
set DST C:/TestPrograms/Quartus21_1/app_bin
if {![file isdirectory $SRC]} {
    echo "FAIL: $SRC does not exist. Run the staging script in"
    echo "      DOC/04_baseline_runbook.md section 3 first."
    quit -code 1
}
file copy -force $SRC/ITCM.hex $DST/ITCM.hex
file copy -force $SRC/DTCM.hex $DST/DTCM.hex

# ---------------------------------------------------------------------------
# -gMODELSIM=1 bypasses the PLL and stops the core inverting reset. No source
# edit anywhere: see the note in compile.do.
# ---------------------------------------------------------------------------
vsim -t ns -gMODELSIM=1 work.tb_rv32im_sc
do {../../Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/golden.do}

# ---------------------------------------------------------------------------
# Stop at the program's final while(1) self-jump: beq x0,x0,0 for the
# man_compiled tests, jal x0,0 for the gcc_compiled ones.
#
# The revised reference testbench no longer stops itself -- its
# monitor_end_of_program process with std.env.stop was removed -- so the stop
# condition lives here. A plain GUI Run -All would never terminate.
# ---------------------------------------------------------------------------
onbreak {resume}
when {/tb_rv32im_sc/instruction_o == 32'h00000063 || /tb_rv32im_sc/instruction_o == 32'h0000006F} {
    echo "Program finished (while(1) reached) at $now ns"
    stop
}
run 5 ms
nowhen *

# ---------------------------------------------------------------------------
set cyc [examine -unsigned /tb_rv32im_sc/mclk_cnt_o]
set pc  [examine -radix hexadecimal /tb_rv32im_sc/pc_o]
set ins [examine -radix hexadecimal /tb_rv32im_sc/instruction_o]
set want [lindex {0 134 1514 2725 2735} $N]

echo ""
echo "=============== PHASE 0 BASELINE - test$N ==============="
echo "  mclk_cnt_o    : $cyc      (expected $want)"
echo "  terminal pc_o : $pc"
echo "  instruction_o : $ins"
if {$cyc == $want} {
    echo "  CYCLE COUNT: matches."
} else {
    echo "  CYCLE COUNT: DOES NOT MATCH. Stop here and report the ModelSim"
    echo "  version and this transcript - the environment differs from the one"
    echo "  that produced the reference numbers, and Phase 1 must not start."
}
echo "  Now run mem_dump.do and diff against the committed golden."
echo "========================================================="
