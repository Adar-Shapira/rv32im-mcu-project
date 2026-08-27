# run_gpio_test2.do - Phase 11 slice 1: GPIO test2 (nibble-split HEX)
#
# Same SW protocol as test1; HEX stores carry one nibble each.
# Reuses tb_gpio_read (port model + display check).

onerror {quit -code 1}

file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test2/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test2/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_gpio_read.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio_read
run -all

echo ""
echo "GPIO test2 via tb_gpio_read. Expected: VERDICT: PASS."
echo ""
