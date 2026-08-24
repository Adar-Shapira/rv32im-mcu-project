project calculateorder

project compileall

vsim test_counter

add wave -r sim:/test_counter/tester/*

vcd file counter.vcd

#add all signals and nets within the current simulation
vcd add -r sim:/test_counter/tester/*
vcd add test_counter/tester/*

run 2000 us
run -all

#force the immediate writing of buffered Value Change Dump (VCD) data to the VCD file on disk
vcd flush

#Dump current state of all signals
vcd checkpoint 




vsim test_counter
vcd file counter.vcd
vcd add test_counter/*
run -all
vcd flush
