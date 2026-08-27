# compile.do - compile the RV32IMscMCU design + the official testbench
#
# Reference: Auxiliary/Lab 5/SIM/RV32IM_sc/compile.do
# Changes:   paths retargeted to DUT/RV32IMscMCU, wrapper + tb_RV32IMscMCU.vhd
#            added. Clause 10 Table 1 names exactly one TB file:
#            tb_RV32IMscMCU.vhd. Extra tb_*.vhd under TB/RV32IMscMCU/ are
#            development-only and are NOT compiled here and must NOT go in
#            the submission ZIP.
#
# -2008 is mandatory: EXECUTE.vhd uses process(all) and both structural tops
# use if/else generate.
# Compile order matters - packages before everything that uses them, leaf modules
# before the units that instantiate them, and RV32IM_CORE before the wrapper.
#
# Course flow: set G_MODELSIM := 1, compile (this file or the GUI), copy the
# chosen M9K-intel ITCM.hex+DTCM.hex into C:\TestPrograms\Quartus21_1\app_bin\,
# simulate work.tb_rv32imscmcu, then do golden.do (or wave.do).
#
# Run with the working directory set to SIM/RV32IMscMCU.

vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IMscMCU/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/aux_package.vhd

# leaf modules, in dependency order. ADDR_DECODER is here because RV32IMscMCU.vhd
# instantiates it (Phase 5B). SYNC is no longer an orphan either - Phase 7B1's
# DIV_UNIT instantiates it four times, which is its first real use.
vcom -2008 ../../DUT/RV32IMscMCU/MUL16.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CONTROL.vhd
vcom -2008 ../../DUT/RV32IMscMCU/IFETCH.vhd
vcom -2008 ../../DUT/RV32IMscMCU/IDECODE.vhd
vcom -2008 ../../DUT/RV32IMscMCU/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IMscMCU/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IMscMCU/PLL.vhd
# Phase 4B. PLL_GEN is PLL with the ratio as generics; CLOCK_TREE is Figure 1's
# block built from three of them. Both compile without altera_mf because at
# MODELSIM = 1 neither instantiates altpll - the same bypass the core already
# uses. PLL_GEN must come before CLOCK_TREE, which instantiates it.
vcom -2008 ../../DUT/RV32IMscMCU/PLL_GEN.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CLOCK_TREE.vhd
vcom -2008 ../../DUT/RV32IMscMCU/SYNC.vhd
# Phase 7A. Figure 9's division accelerator, now instantiated by DIV_UNIT below.
vcom -2008 ../../DUT/RV32IMscMCU/DIV_ACCEL.vhd
# Phase 7B1. DIV_UNIT instantiates DIV_ACCEL and SYNC, so both must precede it.
vcom -2008 ../../DUT/RV32IMscMCU/DIV_UNIT.vhd
vcom -2008 ../../DUT/RV32IMscMCU/ADDR_DECODER.vhd
# Phase 8A. The Basic Timer core -- skeleton from Auxiliary/Lab4/DUT/pwm.vhd.
# A leaf until Phase 8B wires it in; compiled so its testbench runs.
vcom -2008 ../../DUT/RV32IMscMCU/BASIC_TIMER.vhd
# Phase 9A. The Interrupt Controller -- no lab precedent exists (searched);
# built from REQ p13/p14 and the falsified-A6 forum answer. Instantiates SYNC
# for the KEY inputs, so SYNC must precede it. A leaf until Phase 9C wires it.
vcom -2008 ../../DUT/RV32IMscMCU/INTERRUPT_CTRL.vhd
# Phase 12A. The USART (bonus, REQ 6.iv). Four of these files are
# jakubcabal's MIT code (UART_FPGA_option1) -- UART_TX/PARITY/DEBOUNCER
# byte-identical, UART_RX plus one RX_BUSY port; UART_CORE is his top level
# adapted for a runtime, ROUNDED baud divider; UART_PERIPH is ours. Order
# matters: the leaves first, then the core that instantiates them by direct
# entity reference, then the register layer. A leaf until Phase 12B wires it.
vcom -2008 ../../DUT/RV32IMscMCU/UART_PARITY.vhd
vcom -2008 ../../DUT/RV32IMscMCU/UART_DEBOUNCER.vhd
vcom -2008 ../../DUT/RV32IMscMCU/UART_TX.vhd
vcom -2008 ../../DUT/RV32IMscMCU/UART_RX.vhd
vcom -2008 ../../DUT/RV32IMscMCU/UART_CORE.vhd
vcom -2008 ../../DUT/RV32IMscMCU/UART_PERIPH.vhd
# Phase 6A. HEX_DECODER.vhd is the students' Lab 4 file used as is - its body is
# byte-identical to Auxiliary/Lab4/DUT/hex_decoder.vhd, md5
# 56f2f16645e9bb4643c3a113c36e49c4. Only a provenance header was added.
vcom -2008 ../../DUT/RV32IMscMCU/HEX_DECODER.vhd
vcom -2008 ../../DUT/RV32IMscMCU/GPO_PORT.vhd
# Phase 6B. BIDIRPIN.vhd is the students' Lab 3 file used as is - its body is
# byte-identical to Auxiliary/Lab 5/Auxilary/Lab3/DUT/BidirPin.vhd (since deleted from the tree), md5
# ab12d81dcdc85d91071b077359833bbd. It is the block Figure 1's bidirectional-bus
# link points at, and Figure 5 draws it as the buffer on CS.MemRead.
vcom -2008 ../../DUT/RV32IMscMCU/BIDIRPIN.vhd

# core, then the MCU top that instantiates the core and the decoder
vcom -2008 ../../DUT/RV32IMscMCU/RV32IM_CORE.vhd
vcom -2008 ../../DUT/RV32IMscMCU/RV32IMscMCU.vhd

# Official testbench only — Final Project definition.pdf clause 10 Table 1.
vcom -2008 ../../TB/RV32IMscMCU/tb_RV32IMscMCU.vhd
