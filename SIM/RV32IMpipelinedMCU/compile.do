# compile.do - compile the RV32IMpipelinedMCU design + testbench
#
# Reference: Auxiliary/Lab 5 - as submitted/SIM/RV32IM_pipeline/compile.do
# Changes:   paths retargeted to DUT/RV32IMpipelinedMCU, and two files added -
#            RV32IMpipelinedMCU.vhd (the board-facing structural top, Final
#            Project §3) and tb_RV32IMpipelinedMCU.vhd (the name the submission
#            table mandates).
#
# UPDATED 2026-08-23 for the revised pipeline:
#   - MUL16.vhd removed. It is not instantiated anywhere in the revised
#     pipeline; the Figure 7 multiplier is MULT_1 (EX) + MULT_2 (MEM).
#     Confirmed by Auxiliary/Lab 5 - as submitted/DOC/HANDOVER_Report_lab5.md §1.
#   - MULT_1.vhd, MULT_2.vhd and WRITEBACK.vhd added.
#
# -2008 is mandatory: EXECUTE.vhd uses process(all) and both structural tops
# use if/else generate.
# Compile order matters - packages before everything that uses them, and
# RV32IM_PIPE_CORE before the wrapper that instantiates it.
#
# Run with the working directory set to SIM/RV32IMpipelinedMCU.

vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IMpipelinedMCU/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/aux_package.vhd

# MCU leaves copied from RV32IMscMCU (Phase 11 slice 1)
vcom -2008 ../../DUT/RV32IMpipelinedMCU/PLL_GEN.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/CLOCK_TREE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/ADDR_DECODER.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/BIDIRPIN.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/GPO_PORT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/HEX_DECODER.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/SYNC.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/DIV_ACCEL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/DIV_UNIT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/BASIC_TIMER.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/INTERRUPT_CTRL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_PARITY.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_DEBOUNCER.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_TX.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_RX.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_CORE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/UART_PERIPH.vhd

# split multiplier, pipeline stages, hazard/forwarding units, top, testbench
vcom -2008 ../../DUT/RV32IMpipelinedMCU/MULT_1.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/MULT_2.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/PLL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/CONTROL.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/IFETCH.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/IDECODE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/WRITEBACK.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/HAZARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/FORWARD_UNIT.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/RV32IM_PIPE_CORE.vhd
vcom -2008 ../../DUT/RV32IMpipelinedMCU/RV32IMpipelinedMCU.vhd
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_RV32IMpipelinedMCU.vhd

echo "PASS: pipeline sources compiled"
