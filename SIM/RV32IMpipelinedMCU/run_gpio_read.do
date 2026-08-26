# run_gpio_read.do - Phase 11 slice 1: GPIO test1 on the pipelined MCU
#
# Run compile.do first.
#
# Port of SIM/RV32IMscMCU/run_gpio_read.do. DUT is RV32IMpipelinedMCU.
# Pipeline load/branch latency: SETTLE_CYCLES=120, PHASE_CYCLES=400.

onerror {quit -code 1}

file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test1/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test1/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_gpio_read.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio_read
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0,"
echo "phase 3 writes exactly 0, and >= 2 increments and >= 2 decrements."
echo ""
