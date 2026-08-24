LAB5 - Scalar Pipelined RISC-V CPU uArchitecture
================================================
Adar Shapira      209580208
Yehonatan Dadkha  211468582

This file describes the content of each folder and subfolder in the
submission ZIP (id1_id2.zip, id1 < id2) for convenient navigation.
The ZIP contains the five directories required by LAB5 clause 9 / Table 1:
DUT, TB, SIM, DOC, Quartus.


Directory tree
--------------
209580208_211468582/
|-- DUT/                          VHDL design sources (no testbenches)
|   |-- RV32IM_sc/                Part 1: single-cycle RV32IM core
|   |-- RV32IM_pipeline/          Part 2: 5-stage pipelined RV32IM core
|-- TB/                           VHDL testbenches
|   |-- RV32IM_sc/
|   |-- RV32IM_pipeline/
|-- SIM/                          ModelSim *.do scripts
|   |-- RV32IM_sc/
|   |-- RV32IM_pipeline/
|-- DOC/                          Documentation (this file + full report)
|-- Quartus/                      Signal-Tap, SDC, and SOF files
    |-- RV32IM_sc/
    |-- RV32IM_pipeline/


========================================================================
DUT/   Design VHDL files only (excluding testbenches)
========================================================================

DUT/RV32IM_sc  -  Single-cycle RV32IM (MULDIV partial) core  [Part 1]
-----------------------------------------------------------------------
Top entity: RV32IM_CORE. Harvard ITCM/DTCM, 32x32 register file,
combinational ALU, and a 16x16->32 mul built from four 8-bit products
(Figure 6). One instruction completes every clock cycle.

  cond_compilation_package.vhd  Conditional-compilation parameters:
                                G_MODELSIM (1=ModelSim, 0=FPGA/Quartus),
                                TCM size (1-8 KiB), PC/MA widths,
                                PLL divide/multiply ratio.
  const_package.vhd             Opcode patterns / instruction masks used
                                by CONTROL, and the ALUOp encoding shared
                                by CONTROL and EXECUTE (ALU_MUL added for
                                the M-extension mul).
  aux_package.vhd               Component declarations for the whole
                                single-cycle design (includes MUL16;
                                core renamed RV32IM_CORE).
  RV32IM_CORE.vhd               Structural top. Wires the five datapath
                                submodules and exposes Signal-Tap debug
                                outputs (PC, instruction, control bits,
                                ALU result, DTCM buses, ...).
  IFETCH.vhd                    PC register, PC+4 adder, next-PC mux
                                (branch / jal / jalr), ITCM (altsyncram).
  IDECODE.vhd                   32x32 register file, instruction fields,
                                all five immediate formats + sign
                                extension, write-back mux.
  CONTROL.vhd                   Combinational decoder. Detects mul via
                                INST_MUL / INST_MUL_MASK and drives
                                ALUOp = ALU_MUL (mul is R-type, remaining
                                controls unchanged).
  EXECUTE.vhd                   ALU (add/sub/logic/barrel shifters/
                                compares) + branch logic. Instantiates
                                MUL16 and selects its result as alu_res
                                when ALUOp = ALU_MUL.
  MUL16.vhd                     16x16->32 multiplier of the lower
                                half-words of rs1/rs2, from four 8-bit
                                partial products:
                                RESULT = P0 + ((P1+P2)<<8) + (P3<<16).
                                Quartus maps this onto the FPGA embedded
                                9-bit multipliers.
  DMEMORY.vhd                   DTCM (altsyncram, written on the inverted
                                clock).
  PLL.vhd                       ALTPLL deriving the 25 MHz core clock
                                from the board 50 MHz oscillator
                                (instantiated only when G_MODELSIM = 0).


DUT/RV32IM_pipeline  -  5-stage pipelined RV32IM (MULDIV partial)  [Part 2]
-----------------------------------------------------------------------
Top entity: RV32IM_PIPE_CORE. IF / ID / EX / MEM / WB with combinational
hazard check (load-use stall), full forwarding, and branch/jump resolve
in MEM (Figure 7). The 16-bit mul is split across EX and MEM (MULT_1 /
MULT_2). Figure 8 debug ports: CLKCNT, STCNT, FHCNT, BPADDR.

  cond_compilation_package.vhd  Same role as in RV32IM_sc.
  const_package.vhd             Same role as in RV32IM_sc.
  aux_package.vhd               Component declarations for the pipeline
                                (stage modules with stall/flush and
                                pipeline-register ports; HAZARD_UNIT,
                                FORWARD_UNIT, WRITEBACK, MULT_1, MULT_2,
                                and RV32IM_PIPE_CORE with Figure 8 ports).
  RV32IM_PIPE_CORE.vhd          Structural top. Instantiates the five
                                stages plus hazard/forward units.
                                Branches/jumps resolve in MEM (taken
                                redirect flushes the 3 younger
                                instructions, depth = 3). Debug:
                                CLKCNT (clock counter), STCNT (stall
                                counter), FHCNT (flush counter), BPADDR
                                compared against the IF PC for the
                                Signal-Tap trigger BPTRIGGER.
  IFETCH.vhd                    IF stage + IF/ID pipeline register.
                                PC enable freezes on stall; flush injects
                                a bubble; next-PC mux takes the redirect
                                target from MEM.
  IDECODE.vhd                   ID stage + ID/EX pipeline register
                                (data, immediates, rs1/rs2/rd, control).
                                Register file is written from WB while
                                reads occur in ID (with a same-cycle
                                write-port bypass).
  CONTROL.vhd                   Same combinational decoder as part 1
                                (sits in ID); its outputs ride down the
                                pipe.
  EXECUTE.vhd                   EX stage + EX/MEM pipeline register.
                                Forwarding muxes on both ALU inputs
                                (ID/EX vs EX/MEM vs WB), driven by
                                FORWARD_UNIT. Instantiates MULT_1
                                (four 8x8 partial products).
  MULT_1.vhd                    Figure 7 mul stage 1 (EX): four 8x8
                                partial products P0..P3 of the lower
                                16 bits of the forwarded ALU operands.
  DMEMORY.vhd                   MEM stage (DTCM) + MEM/WB pipeline
                                register. Instantiates MULT_2 and muxes
                                the mul result onto the MEM ALU/result
                                path. Branch/jump taken is resolved here.
  MULT_2.vhd                    Figure 7 mul stage 2 (MEM): combines the
                                EX/MEM partial products
                                RESULT = P0 + ((P1+P2)<<8) + (P3<<16).
  WRITEBACK.vhd                 WB-stage write-back mux (Figure 7):
                                PC+4 (jal/jalr), ALU/mul result, or
                                DTCM load data. Feeds the RF write port,
                                the ID-stage RF bypass, and EX-stage WB
                                forwarding.
  HAZARD_UNIT.vhd               Combinational load-use interlock: EX-stage
                                load whose rd matches ID-stage rs1/rs2
                                (rd /= x0). stall_o freezes PC + IF/ID
                                and injects a bubble into ID/EX.
  FORWARD_UNIT.vhd              Compares EX-stage rs1/rs2 against EX/MEM
                                and MEM/WB destinations (RegWrite=1,
                                rd/=0) and drives the forwarding-mux
                                selects ("10"=MEM, "01"=WB, "00"=none).
  PLL.vhd                       Same role as in RV32IM_sc.


========================================================================
TB/   Design testbenches (one file per core)
========================================================================

TB/RV32IM_sc/
  tb_RV32IM_sc.vhd              Clock (100 ns period) + reset generator
                                around RV32IM_CORE. All core outputs are
                                brought out for the ModelSim wave window.

TB/RV32IM_pipeline/
  tb_RV32IM_pipeline.vhd        Same clock/reset around RV32IM_PIPE_CORE.
                                Drives BPADDR_i (emulating SW7-SW0) and
                                observes CLKCNT / STCNT / FHCNT for the
                                IPC check:
                                  IPC = (CLKCNT - (STCNT + 4 + 3*FHCNT))
                                        / CLKCNT


========================================================================
SIM/   ModelSim *.do scripts (one folder per core)
========================================================================

SIM/RV32IM_sc/
  golden.do                     Wave-window setup matching the golden
                                ModelSim view (top + submodule groups).

SIM/RV32IM_pipeline/
  golden.do                     Wave-window setup for the pipeline
                                (Figure 8 top ports, stall/flush,
                                forwarding, per-stage PC/instruction).


========================================================================
DOC/   Project documentation
========================================================================

  readme.txt                    This file: folder / subfolder map for
                                navigation (LAB5 clause 9.g).
  Report_lab5.pdf               Full LAB5 report (clause 9.a-f):
                                top-level block diagram, RTL Viewer,
                                PPA tables with Quartus screenshots,
                                short HDL file descriptions, numbered
                                figures/tables, and elaborated analysis
                                with waveforms for test1-test4.


========================================================================
Quartus/   Signal-Tap, SDC, and SOF (no compilation-result clutter)
========================================================================
Device: EP4CE115F29C7 (DE2-115, Cyclone IV E). VHDL-2008.
Constraint: 50 MHz on clk_i; derive_pll_clocks -> 25 MHz core clock.
Before synthesis set G_MODELSIM := 0 in cond_compilation_package.vhd
(both cores). Place benchmark ITCM.hex / DTCM.hex in
C:\TestPrograms\Quartus21_1\app_bin\. Set G_MODELSIM := 1 for ModelSim.

Quartus/RV32IM_sc/              Top = RV32IM_CORE
  RV32IM_sc.sdc                 Timing constraints (*.sdc).
  stp1.stp                      Signal-Tap instance (debug channels).
  RV32IM_CORE.sof               Programming file for the FPGA board.

Quartus/RV32IM_pipeline/        Top = RV32IM_PIPE_CORE
  RV32IM_pipeline.sdc           Timing constraints (*.sdc).
  RV32IM_pipeline.stp           Signal-Tap instance (Figure 8 signals:
                                per-stage PC/instruction, CLKCNT,
                                STCNT, FHCNT, BPTRIGGER = (IFPC==BPADDR)).
  RV32IM_PIPE_CORE.sof          Programming file for the FPGA board.


========================================================================
Notes
========================================================================
- KEY0 on the FPGA board is the core RESET (brings PC to the first
  instruction). SW7-SW0 feed BPADDR_i on the pipeline core.
- Golden-model check: at the end of each benchmark, compare the RARS
  DTCM.h / DTCM.hex against the ModelSim DTCM.mem / ISMCE DTCM.hex.
- IPC (pipeline, clause 6.iii.b):
    IPC = (CLKCNT_o - (STCNT_o + 4 + depth*FHCNT_o)) / CLKCNT_o
  with depth = 3 (flush kills the three younger instructions).
