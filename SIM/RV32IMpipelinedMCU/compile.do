# compile.do - compile the RV32IMpipelinedMCU design + testbench
vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IMpipelinedMCU/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/aux_package.vhd

# multiplier, pipeline stages, hazard/forwarding units, top, testbench
vcom -2008 ../../DUT/RV32IMpipelinedMCU/MUL16.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/CONTROL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/IFETCH.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/IDECODE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/HAZARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/FORWARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/PLL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/RV32IM_PIPE_CORE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/RV32IMpipelinedMCU.vhd
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_RV32IMpipelinedMCU.vhd