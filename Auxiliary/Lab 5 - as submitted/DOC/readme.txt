Lab 5: Single-Cycle and Pipelined RV32IM CPU
Adar Shapira 209580208
Yehonatan Dadkha 211468582

DUT/RV32IM_sc - single-cycle RV32IM core (part 1)
-------------------------------------------------
* cond_compilation_package.vhd : Conditional-compilation parameters: ModelSim/FPGA switch (G_MODELSIM),
                                 TCM size (1-8 KiB), PC/MA widths, PLL divide/multiply ratio.
* const_package.vhd            : Opcode patterns and instruction masks used by CONTROL, and the ALUOp
                                 encoding shared by CONTROL and EXECUTE (ALU_MUL added for the M-extension).
* MUL16.vhd                    : 16x16->32 multiplier of the lower half-words of rs1/rs2, built from four
                                 8-bit partial products: RESULT = P0 + ((P1+P2)<<8) + (P3<<16), so Quartus
                                 maps it onto the FPGA's embedded 9-bit multipliers.
* CONTROL.vhd                  : Combinational decoder; detects mul via INST_MUL/INST_MUL_MASK and drives
                                 ALUOp = ALU_MUL (mul is R-type, so the remaining controls are unchanged).
* EXECUTE.vhd                  : ALU (add/sub/logic/barrel shifters/compares) + branch logic; instantiates
                                 MUL16 and selects its result as alu_res on ALU_MUL.
* IFETCH.vhd                   : PC register, PC+4 adder, next-PC mux (branch/jal/jalr), ITCM (altsyncram).
* IDECODE.vhd                  : 32x32 register file, instruction fields, all 5 immediate formats + sign
                                 extension, write-back mux.
* DMEMORY.vhd                  : DTCM (altsyncram, written on the inverted clock).
* aux_package.vhd              : Component declarations for the whole design (MUL16 added, core renamed).
* PLL.vhd                      : ALTPLL deriving the 25 MHz core clock from the board's 50 MHz oscillator
                                 (instantiated only when G_MODELSIM = 0).
* RV32IM_CORE.vhd              : Structural top; wires the 5 submodules and exposes the Signal-Tap debug
                                 outputs (pc, instruction, control bits, ALU result, DTCM buses, ...).

DUT/RV32IM_pipeline - 5-stage pipelined RV32IM core (part 2)
------------------------------------------------------------
* cond_compilation_package.vhd, const_package.vhd, MUL16.vhd, PLL.vhd : same roles as in part 1.
* IFETCH.vhd                   : IF stage + IF/ID pipeline register; PC gets an enable (freeze on stall),
                                 flush injects a bubble, next-PC mux takes the redirect target from MEM.
* IDECODE.vhd                  : ID stage + ID/EX pipeline register (data, immediates, rs1/rs2/rd, control
                                 bits); the register file is written from the WB stage while reads are in ID.
* CONTROL.vhd                  : Same combinational decoder (sits in ID); its outputs ride down the pipe.
* EXECUTE.vhd                  : EX stage + EX/MEM pipeline register; forwarding muxes on both ALU inputs
                                 (ID/EX vs EX/MEM vs WB data), driven by FORWARD_UNIT.
* DMEMORY.vhd                  : MEM stage (DTCM) + MEM/WB pipeline register.
* HAZARD_UNIT.vhd              : Combinational load-use interlock: compares ID-stage rs1/rs2 against
                                 destinations in flight and stalls (freeze PC + IF/ID, bubble into EX).
* FORWARD_UNIT.vhd             : Compares EX-stage rs1/rs2 against EX/MEM and MEM/WB destinations
                                 (RegWrite=1, rd/=0) and drives the forwarding-mux selects.
* RV32IM_PIPE_CORE.vhd         : Structural top; branches/jumps resolve in MEM (taken branch flushes the
                                 3 younger instructions => depth 3). Debug additions: CLKCNT (clock counter),
                                 STCNT (stall counter), FHCNT (flush counter) and the BPADDR breakpoint
                                 register compared against the IF PC for the Signal-Tap trigger BPTRIGGER.

TB
--
* TB/RV32IM_sc/tb_RV32IM_sc.vhd             : Clock (100 ns period) + reset generator around the
                                              single-cycle core; all core outputs exposed for the wave window.
* TB/RV32IM_pipeline/tb_RV32IM_pipeline.vhd : Same for the pipeline; also drives BPADDR_i and observes
                                              CLKCNT/STCNT/FHCNT for the IPC check:
                                              IPC = (CLKCNT - (STCNT + 4 + 3*FHCNT)) / CLKCNT.

SIM (ModelSim scripts, one folder per core)
-------------------------------------------
* compile.do      : Creates the work library and compiles packages, DUT and TB in dependency order (-2008).
* run_test.do     : Loads benchmark testN images into app_bin, starts the simulation with wave.do, runs
                    until the program's final while(1) self-jump, then dumps the DTCM.
* wave.do         : Wave-window signal setup.
* mem_dump.do     : Exports the DTCM to DTCM.mem (one bare hex word per line, same format as the RARS
                    golden DTCM.h) for comparison against the golden output.
* batch_verify.do : (pipeline) headless run of test1..test4: reports CLKCNT/STCNT/FHCNT + IPC per test and
                    writes DTCM_testN.mem. DTCM_testN.mem files are the dumps from the verified runs.

Quartus
-------
* Quartus/RV32IM_sc       : project with top = RV32IM_CORE, constrained by RV32IM_sc.sdc
                            (50 MHz on clk_i, derive_pll_clocks -> 25 MHz core clock).
* Quartus/RV32IM_pipeline : project with top = RV32IM_PIPE_CORE, constrained by RV32IM_pipeline.sdc.
* Both projects: device EP4CE115F29C7 (DE2-115, Cyclone IV E), VHDL-2008 input.

DOC
---
* readme.txt      : This file.
* Report_lab5.pdf : Lab report (block diagrams, RTL viewer, PPA tables, waveforms, IPC results).

Note: before Quartus synthesis set G_MODELSIM := 0 in cond_compilation_package.vhd (both cores) and place
the benchmark ITCM.hex/DTCM.hex in C:\TestPrograms\Quartus21_1\app_bin\; set it back to 1 for ModelSim.
