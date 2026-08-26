# run_gpio_directed.do - directed GPIO on the pipelined MCU (slice 2)
#
# Run compile.do first.
# Images: SIM/RV32IMpipelinedMCU/gpio/ (copied from the SC generated set).

onerror {quit -code 1}

file copy -force gpio/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force gpio/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/gpio_expected_pkg.vhd
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_gpio_directed.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio_directed
run -all

echo ""
echo "Expected: VERDICT: PASS, all stores matched."
echo ""
