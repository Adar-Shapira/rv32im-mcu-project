# compile.do - compile the RV32IM_sc design + testbench
vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IM_sc/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IM_sc/const_package.vhd
vcom -2008 ../../DUT/RV32IM_sc/aux_package.vhd

# multiplier, submodules, top, testbench
vcom -2008 ../../DUT/RV32IM_sc/MUL16.vhd
vcom -2008 ../../DUT/RV32IM_sc/CONTROL.vhd
vcom -2008 ../../DUT/RV32IM_sc/IFETCH.vhd
vcom -2008 ../../DUT/RV32IM_sc/IDECODE.vhd
vcom -2008 ../../DUT/RV32IM_sc/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IM_sc/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IM_sc/PLL.vhd
vcom -2008 ../../DUT/RV32IM_sc/RV32IM_CORE.vhd
vcom -2008 ../../TB/RV32IM_sc/tb_RV32IM_sc.vhd