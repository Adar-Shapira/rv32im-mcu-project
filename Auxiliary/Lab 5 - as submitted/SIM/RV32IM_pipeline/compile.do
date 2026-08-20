# compile.do - compile the RV32IM_pipeline design + testbench
vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IM_pipeline/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/const_package.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/aux_package.vhd

# multiplier, pipeline stages, hazard/forwarding units, top, testbench
vcom -2008 ../../DUT/RV32IM_pipeline/MUL16.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/CONTROL.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/IFETCH.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/IDECODE.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/HAZARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/FORWARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/PLL.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd
vcom -2008 ../../TB/RV32IM_pipeline/tb_RV32IM_pipeline.vhd