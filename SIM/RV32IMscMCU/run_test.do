# run_test.do - edit N to choose the benchmark, then run this macro
#
# Reference: Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/run_test.do
# Changes:
#   1. Top is now tb_rv32imscmcu (the MCU wrapper, not the bare core).
#   2. vsim passes -gMODELSIM=1. The testbench exposes MODELSIM as a generic
#      and forwards it to the wrapper and the core, so simulation no longer
#      requires editing cond_compilation_package.vhd by hand. Quartus keeps the
#      package default of 0 and needs no edit either. This closes the manual
#      toggle that could otherwise leave the design mis-configured.

set N 1

# load the benchmark images into app_bin (Tcl needs forward slashes)
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns -gMODELSIM=1 work.tb_rv32imscmcu
do wave.do

# stop automatically when the program reaches its final while(1) self-jump:
# beq x0,x0,0 (0x00000063, man_compiled tests) or jal x0,0 (0x0000006F, gcc).
# Values are written as 32-bit binary strings (that is how "when" compares a
# VHDL bus). The 5 ms bound only catches a runaway (bug) case.
onbreak {resume}
when {/tb_rv32imscmcu/instruction_o == "00000000000000000000000001100011" OR /tb_rv32imscmcu/instruction_o == "00000000000000000000000001101111"} {
    echo "Program finished (while(1) reached) at $now ns"
    stop
}
run 5 ms
do mem_dump.do
