# run_bench_test4.do - Phase 11 slice 4: interrupt test4 on the pipeline MCU
#
# Run compile.do first.
# Stages ..\RV32IMscMCU\bench_fixed\test4 (shipped capture BTCTL2 never
# changes). ONE copy, in the tree whose generator maintains it -- see
# run_bench_test1.do for why the local duplicate was removed.

onerror {quit -code 1}

set ORIGINAL 0

if {$ORIGINAL} {
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test4/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test4/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
    echo "STAGED THE ORIGINAL (bugged) test4 images."
} else {
    file copy -force ../RV32IMscMCU/bench_fixed/test4/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force ../RV32IMscMCU/bench_fixed/test4/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex
}

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_bench_test4.vhd
vsim -t ns -gMODELSIM=1 work.tb_bench_test4

quietly set ::cap_events 0
when {/tb_bench_test4/MCU/TIMER/cap_ev_w == "1"} { quietly incr ::cap_events }

onbreak {resume}
run -all
nowhen *

echo ""
if {$::cap_events == 3} {
    echo "CAPTURE EVENTS SEEN: 3 of 3"
} else {
    echo "CAPTURE EVENTS SEEN: $::cap_events, expected 3 - THE CAPTURE EDGE CHECK FAILED."
    if {![info exists ::REGRESS]} { quit -code 1 }
}
echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0,"
echo "  plus CAPTURE EVENTS SEEN: 3 of 3."
echo ""
# quit -f, unless a regression driver is running us. regress.do sets ::REGRESS
# and needs the simulator to stay alive to score the next test; standalone this
# still exits so a batch `vsim -c -do run_bench_testN.do` returns. Same guard as
# SIM/RV32IMscMCU/repair_check.do:276.
if {![info exists ::REGRESS]} { quit -f }
