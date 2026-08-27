# run_gpio_directed.do - directed GPIO on the pipelined MCU (slice 2)
#
# Run compile.do first.
# Images: SIM/RV32IMscMCU/gpio/ -- the ONE generated set, staged straight
# from the tree tools/gen_gpio_test.py writes. The local copy this script
# used to read was a hand-made duplicate and was removed 2026-08-27.

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/gpio/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/gpio/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/gpio_expected_pkg.vhd
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_gpio_directed.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio_directed
run -all

echo ""
echo "Expected: VERDICT: PASS, all stores matched."
echo ""
