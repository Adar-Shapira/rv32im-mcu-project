# run_bench_test1.do - Phase 11 slice 4: interrupt test1 on the pipeline MCU
#
# Run compile.do first.
# Stages ..\RV32IMscMCU\bench_fixed\test1 (shipped test1 never enables GIE
# at SW0=0). ONE copy of the corrected images, in the tree whose generator
# maintains them (tools/patch_bench_images.py). The pipeline tree used to
# hold a hand-made second copy; it had already drifted (line endings) and
# nothing would have caught an ITCM drift, so it was removed 2026-08-27.

onerror {quit -code 1}

set ORIGINAL 0

if {$ORIGINAL} {
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
    echo "STAGED THE ORIGINAL (bugged) test1 images - this run documents B5."
} else {
    file copy -force ../RV32IMscMCU/bench_fixed/test1/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force ../RV32IMscMCU/bench_fixed/test1/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
}

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_bench_test1.vhd
vsim -t ns -gMODELSIM=1 work.tb_bench_test1
onbreak {resume}
run -all
echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo ""
# quit -f, unless a regression driver is running us. regress.do sets ::REGRESS
# and needs the simulator to stay alive to score the next test; standalone this
# still exits so a batch `vsim -c -do run_bench_testN.do` returns. Same guard as
# SIM/RV32IMscMCU/repair_check.do:276.
if {![info exists ::REGRESS]} { quit -f }
