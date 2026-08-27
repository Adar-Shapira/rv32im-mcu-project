# run_bench_test3.do - Phase 11 slice 4: interrupt test3 on the pipeline MCU
#
# Run compile.do first.
# Stages the shipped M9K-intel images. KEY ISRs shorten BTCMPR0; BT_ISR is
# still FPGA-only at 0.125 s. This script checks that BTCNT ticks.

onerror {quit -code 1}

file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test3/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/Intrrupt-based IO/test3/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_bench_test3.vhd
vsim -t ns -gMODELSIM=1 work.tb_bench_test3

quietly set ::btcnt_ticked 0
when {/tb_bench_test3/MCU/TIMER/btcnt_q'event} {
    if {[examine -unsigned /tb_bench_test3/MCU/TIMER/btcnt_q] > 0} {
        quietly set ::btcnt_ticked 1
    }
}

onbreak {resume}
run -all
nowhen *

echo ""
if {$::btcnt_ticked == 1} {
    echo "BTCNT TICKED: yes"
} else {
    echo "BTCNT TICKED: no - sys_init started the timer (BTCTL1=BTSSEL3) but BTCNT never left 0."
    if {![info exists ::REGRESS]} { quit -code 1 }
}
echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0,"
echo "  plus BTCNT TICKED: yes. The 0.125-1 s BT_ISR is FPGA-only."
echo ""
# quit -f, unless a regression driver is running us. regress.do sets ::REGRESS
# and needs the simulator to stay alive to score the next test; standalone this
# still exits so a batch `vsim -c -do run_bench_testN.do` returns. Same guard as
# SIM/RV32IMscMCU/repair_check.do:276.
if {![info exists ::REGRESS]} { quit -f }
