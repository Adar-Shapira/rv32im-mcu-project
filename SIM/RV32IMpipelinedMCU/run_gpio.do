# run_gpio.do - Phase 11 slice 1: GPIO test0 on the pipelined MCU
#
# Run compile.do first.
#
# Port of SIM/RV32IMscMCU/run_gpio.do. DUT is RV32IMpipelinedMCU.
# Stores commit in MEM, so tb_gpio.vhd uses RUN_CYCLES=900 (vs SC 600).

onerror {quit -code 1}

file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_gpio.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0."
echo ""
