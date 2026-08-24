transcript on
onerror {quit -code 1}

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vcom -2008 ../../DUT/RV32IM_pipeline/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/const_package.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/aux_package.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/MULT_1.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/MULT_2.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/PLL.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/CONTROL.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/IFETCH.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/IDECODE.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/WRITEBACK.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/HAZARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/FORWARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd
vcom -2008 ../../TB/RV32IM_pipeline/tb_RV32IM_pipeline.vhd

echo "PASS: pipeline sources compiled"
