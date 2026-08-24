# Lab 5 — Single-Cycle and Pipelined RISC-V Processor

## 1. Project purpose

This project implements, simulates, synthesizes, and validates two versions of a small 32-bit RISC-V processor:

1. `DUT/RV32IM_sc`: a single-cycle processor.
2. `DUT/RV32IM_pipeline`: a five-stage pipelined processor with forwarding, load-use hazard detection, branch/jump flushing, performance counters, and a hardware breakpoint trigger.

Both processors execute machine-code programs stored in a local instruction memory (ITCM), read and write data in a separate data memory (DTCM), and expose internal datapath signals for ModelSim and SignalTap inspection. The four supplied benchmarks exercise vector arithmetic, matrix arithmetic, loops, branches, multiplication, loads/stores, and function calls.

The project has three verification levels:

1. **Functional simulation in ModelSim**: execute each benchmark, inspect waveforms, dump DTCM, and compare it with a golden RARS result.
2. **Synthesis and timing analysis in Quartus**: prove that the VHDL maps to the Cyclone IV FPGA, inspect the inferred RTL and resources, and determine the maximum clock frequency.
3. **On-board observation with SignalTap**: run the pipelined design on the DE2-115 and capture the PC, instruction, breakpoint, and performance counters using the FPGA's internal logic analyzer.

### Important accuracy note about the name “RV32IM”

The directories and top-level entities use the name `RV32IM`, but the implementation is not a complete implementation of the standard RV32M extension:

- `mul` is decoded and executed.
- `mulh`, `mulhsu`, `mulhu`, `div`, `divu`, `rem`, and `remu` are listed as constants but are not executed.
- The implemented `MUL16` multiplies only `rs1(15:0)` by `rs2(15:0)` as an unsigned 16-by-16-bit product. It is therefore correct for the supplied test values, which are small and non-negative, but it is not a general 32-by-32-bit RISC-V `mul`.

The technically precise description is therefore: **an RV32I-oriented teaching core extended with a tested 16-bit `mul` datapath**.

---

## 2. RISC-V background

### 2.1 What an ISA is

An instruction set architecture (ISA) is the contract between software and a processor. It defines:

- the machine instructions and their binary encodings;
- the programmer-visible registers;
- how memory is addressed;
- what each instruction must calculate;
- how branches, jumps, and function calls change control flow.

RISC-V is a modular ISA. In `RV32I`:

- `RV` means RISC-V;
- `32` means 32-bit integer registers and addresses;
- `I` means the base integer instruction set.

The standard `M` extension adds integer multiply and divide operations.

### 2.2 Registers

The processor contains 32 registers, `x0` through `x31`, each 32 bits wide.

- `x0` is permanently zero. Writes to `x0` are discarded.
- `x1` is conventionally `ra`, the return address.
- `x2` is conventionally `sp`, the stack pointer.
- The other registers hold operands, addresses, loop counters, temporary values, and function arguments/results.

The binary instruction contains register indexes:

- `rs1 = instruction(19 downto 15)`: first source register;
- `rs2 = instruction(24 downto 20)`: second source register;
- `rd = instruction(11 downto 7)`: destination register.

### 2.3 Program counter and instruction flow

The program counter (PC) is the byte address of an instruction. Every instruction is 32 bits, or four bytes, so sequential execution normally uses:

`next PC = current PC + 4`

A taken branch or jump replaces `PC + 4` with a target address.

### 2.4 Instruction formats and immediates

RISC-V places constant values, called immediates, in several instruction layouts:

- **R type**: two register operands and one destination, for example `add`, `sub`, `xor`, and `mul`.
- **I type**: one register and a 12-bit immediate, for example `addi`, loads, and `jalr`.
- **S type**: a split 12-bit immediate used by stores.
- **B/SB type**: a split signed branch displacement.
- **U type**: a 20-bit upper immediate used by `lui` and `auipc`.
- **J/UJ type**: a split signed jump displacement used by `jal`.

`IDECODE` reconstructs these fields and sign-extends them to 32 bits. Sign extension copies the immediate's sign bit into all higher bits, preserving negative two's-complement values.

### 2.5 The five conceptual processor operations

Nearly every instruction can be described using five operations:

1. **IF — instruction fetch**: use the PC to read an instruction from ITCM.
2. **ID — instruction decode/register read**: decode the instruction and read `rs1`/`rs2`.
3. **EX — execute**: perform arithmetic, comparison, address generation, or multiplication.
4. **MEM — memory access**: read or write DTCM for a load or store.
5. **WB — write back**: write the result into `rd`.

The single-cycle model performs all required operations for one instruction in one clock cycle. The pipeline overlaps these operations for several different instructions.

---

## 3. Repository organization

- `DUT/RV32IM_sc`: single-cycle VHDL source.
- `DUT/RV32IM_pipeline`: pipelined VHDL source.
- `TB/RV32IM_sc` and `TB/RV32IM_pipeline`: ModelSim testbenches.
- `SIM/RV32IM_sc` and `SIM/RV32IM_pipeline`: compile, run, wave, memory-dump, and batch scripts.
- `Auxilary/test1` through `Auxilary/test4`: C sources, assembly outputs, ITCM/DTCM images, and software verification versions.
- `Quartus/RV32IM_sc` and `Quartus/RV32IM_pipeline`: FPGA projects, constraints, and the pipeline SignalTap configuration.
- `Screenshots/ModelSim`: saved simulation waveforms.
- `Screenshots/Quartus`: RTL Viewer, timing, critical-path, and area screenshots.

---

## 4. Shared configuration and design assumptions

### 4.1 `cond_compilation_package.vhd`

This package selects the simulation/FPGA mode and memory sizes.

Current synthesis-oriented settings in both cores are:

- `G_MODELSIM = 0`: instantiate the PLL and invert the active-low board reset.
- `G_WORD_GRANULARITY = true`: ITCM and DTCM addresses select 32-bit words; byte addresses are converted by dropping address bits 1 and 0.
- `G_ADDRWIDTH = 11`: 2,048 addressable words.
- `G_DATA_WORDSNUM = 2048`: 2,048 words in each TCM.
- `G_PC_WIDTH = 13`: 13-bit byte PC, covering 8 KiB.
- `G_MA_WIDTH = 13`: 13-bit byte memory-address range.
- `G_PLL_DIV = 2`, `G_PLL_MUL = 1`: 50 MHz input divided to 25 MHz.

For normal ModelSim use, either set `G_MODELSIM = 1` before compilation or override the testbench `MODELSIM` generic with `-gMODELSIM=1`. In simulation mode, the testbench clock directly becomes the processor clock and reset remains active high.

### 4.2 `const_package.vhd`

This package contains:

- instruction opcode/mask constants used by `CONTROL`;
- the immediate-extension constants used by `IDECODE`;
- five-bit ALU operation codes shared by `CONTROL` and `EXECUTE`.

The ALU operation codes are:

| ALU code | Meaning |
|---|---|
| `ALU_NONE` | No operation; result is zero |
| `ALU_SHIFTL` | Logical left shift |
| `ALU_SHIFTR` | Logical right shift |
| `ALU_SHIFTR_ARITH` | Arithmetic right shift |
| `ALU_ADD` | Addition/address generation |
| `ALU_SUB` | Subtraction |
| `ALU_AND` | Bitwise AND |
| `ALU_OR` | Bitwise OR |
| `ALU_XOR` | Bitwise XOR |
| `ALU_LESS_THAN_UNSIGNED` | Unsigned set-less-than |
| `ALU_LESS_THAN_SIGNED` | Signed set-less-than |
| `ALU_MUL` | Implemented 16-by-16 multiplication |
| `ALU_BEQ` ... `ALU_BGEU` | Six branch comparisons |

### 4.3 `aux_package.vhd`

This is a structural declaration package. It declares the component interfaces so the top level and submodules can instantiate one another. It contains no active datapath behavior.

### 4.4 Memory architecture

The processor is Harvard-style: instructions and data use separate memories.

- **ITCM** is an `altsyncram` configured as ROM and initialized from `C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex`.
- **DTCM** is an `altsyncram` configured as single-port RAM and initialized from `C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex`.
- Both are 32 bits wide.
- With word granularity, byte address `A` selects word `A / 4`.
- DTCM uses an unregistered output.
- DTCM is clocked by `not mclk`, so a store commits on the processor clock's falling edge. A load value is then available before the next rising edge.

Although `CONTROL` recognizes byte and halfword load/store encodings, DTCM has no byte-enable or sign/zero-extension logic. The physically implemented and tested memory operations are therefore 32-bit word accesses (`lw` and `sw`).

---

## 5. Single-cycle processor

### 5.1 Meaning of “single cycle”

For each active clock period, one complete instruction travels through fetch, decode, execute, optional memory access, and write-back. The register file and PC update at the next rising edge.

Advantages:

- conceptually simple;
- no hazards between overlapping instructions;
- ideal CPI is exactly 1: one completed instruction per clock after reset.

Disadvantage:

- the clock period must accommodate the longest instruction path, typically fetch → register read → ALU/multiplier → memory → write-back;
- even a simple instruction must wait for that worst-case period.

### 5.2 Single-cycle top level: `RV32IM_CORE`

#### Generics

| Generic | Meaning |
|---|---|
| `WORD_GRANULARITY` | Select word-addressed TCM behavior |
| `MODELSIM` | `1`: direct simulation clock/reset; `0`: FPGA PLL and active-low key reset |
| `DATA_BUS_WIDTH` | Datapath width, 32 bits |
| `ITCM_ADDR_WIDTH` | ITCM word-address width |
| `DTCM_ADDR_WIDTH` | DTCM word-address width |
| `PC_WIDTH` | Program-counter width |
| `MA_WIDTH` | Memory byte-address width used before dropping low bits |
| `DATA_WORDS_NUM` | Number of words in each TCM |
| `CLK_CNT_WIDTH` | Width of the cycle counter |

#### Inputs

| Signal | Meaning |
|---|---|
| `clk_i` | External clock. On the board this is the 50 MHz oscillator; in ModelSim it is the testbench clock. |
| `rst_i` | Reset. Active high in simulation; connected to active-low `KEY0` and inverted internally in FPGA mode. |

#### Debug/verification outputs

| Signal | Meaning and use |
|---|---|
| `pc_o` | Registered byte-PC observation. It normally advances by four. Because this implementation addresses ITCM from `next_pc_w`, correlate `pc_o` and `instruction_o` against the saved waveform/disassembly rather than assuming they are an ordinary registered PC/instruction pair. |
| `instruction_o` | Current 32-bit word presented by the unregistered ITCM output. |
| `RegWrite_ctrl_o` | High when the current instruction writes `rd`. |
| `MemWrite_ctrl_o` | High for a store; enables DTCM write. |
| `Branch_ctrl_o` | High when the current instruction is a conditional branch. |
| `read_data1_o` | Value read from `rs1`. |
| `read_data2_o` | Value read from `rs2`; also store data. |
| `write_data_o` | Value selected for register write-back: PC+4, ALU result, or DTCM load data. |
| `alu_res_o` | Current ALU/multiplier result or computed data address. |
| `brTaken_o` | Result of the current branch comparison. |
| `dtcm_addr_o` | DTCM word address, derived from `alu_res_o`. |
| `dtcm_data_wr_o` | Word presented to DTCM on a store. |
| `dtcm_data_rd_o` | Word read from DTCM. |
| `mclk_cnt_o` | Number of processor rising edges since reset. |

### 5.3 Single-cycle data flow

For an ALU instruction such as `add x5,x6,x7`:

1. `IFETCH` reads the instruction at `pc`.
2. `CONTROL` recognizes `add` and drives register write plus `ALU_ADD`.
3. `IDECODE` reads `x6` and `x7`.
4. `EXECUTE` adds them.
5. `IDECODE`'s write-back mux selects the ALU result.
6. On the rising edge, `x5` receives the result and the PC advances.

For `lw x5,offset(x6)`:

1. `IDECODE` reads base register `x6` and sign-extends `offset`.
2. `EXECUTE` calculates `x6 + offset`.
3. That address selects DTCM.
4. `MemtoReg` selects DTCM data for write-back.
5. `x5` is updated on the rising edge.

For `sw x7,offset(x6)`:

1. `EXECUTE` calculates the address.
2. `read_data2` carries `x7`.
3. `MemWrite` causes DTCM to store the value on the falling edge.

For a branch:

1. `EXECUTE` compares `rs1` and `rs2`.
2. It also calculates `PC + signed branch displacement`.
3. `IFETCH` chooses the target only when `Branch` and `brTaken` are both high.

For `jal`:

- the next PC is `PC + jump displacement`;
- `PC + 4` is written to `rd` as the link address.

For `jalr`:

- the next PC comes from `rs1 + immediate`;
- `PC + 4` is written to `rd`;
- `jalr x0,0(x1)` implements the usual function return because no link is written and execution resumes at `x1`.

### 5.4 Single-cycle units and every entity port

#### `CONTROL`

`CONTROL` is combinational: changing `instruction_i` immediately changes its outputs.

| Port | Direction | Purpose |
|---|---|---|
| `instruction_i(31:0)` | In | Instruction to decode |
| `RegDst_ctrl_o` | Out | Select PC+4 as write-back for `jal`/`jalr` |
| `ALUSrc_ctrl_o` | Out | Select immediate instead of `rs2` for ALU input B |
| `MemtoReg_ctrl_o` | Out | Select DTCM data for a load |
| `RegWrite_ctrl_o` | Out | Enable destination-register write |
| `MemRead_ctrl_o` | Out | Mark a load; also used by pipeline hazard logic |
| `MemWrite_ctrl_o` | Out | Enable DTCM store |
| `Branch_ctrl_o` | Out | Mark a conditional branch |
| `Jal_ctrl_o` | Out | Mark `jal` |
| `Jalr_ctrl_o` | Out | Mark `jalr` |
| `UpperIm_ctrl_o(1:0)` | Out | `"01"` makes ALU A equal PC for `auipc`; `"10"` makes ALU A zero for `lui`; `"00"` uses `rs1` |
| `ALUOp_ctrl_o(4:0)` | Out | Select arithmetic, logic, comparison, branch, shift, or multiply operation |

Instruction recognition uses `(instruction AND mask) = pattern`, which checks opcode, `funct3`, and where needed `funct7`.

#### `IFETCH`

| Port | Direction | Purpose |
|---|---|---|
| `clk_i` | In | Processor clock |
| `rst_i` | In | Active-high internal reset |
| `addr_gen_i` | In | Branch/`jal` target calculated by `EXECUTE` |
| `Branch_ctrl_i` | In | Current instruction is a branch |
| `brTaken_i` | In | Branch comparison result |
| `Jal_ctrl_i` | In | Select direct jump target |
| `Jalr_ctrl_i` | In | Select ALU result as indirect jump target |
| `alu_res_i` | In | `jalr` target |
| `pc_o` | Out | Current PC |
| `pc_plus4_o` | Out | Sequential/link address |
| `instruction_o` | Out | ITCM instruction |

Its next-PC priority is reset → `jalr` → taken branch/`jal` → `PC+4`.

#### `IDECODE`

| Port | Direction | Purpose |
|---|---|---|
| `clk_i` | In | Register-file write clock |
| `rst_i` | In | Clears all 32 registers |
| `pc_plus4_i` | In | Link value for `jal`/`jalr` |
| `instruction_i` | In | Supplies opcode, `rs1`, `rs2`, `rd`, and immediate bits |
| `dtcm_data_rd_i` | In | Load write-back value |
| `alu_res_i` | In | ALU write-back value |
| `RegDst_ctrl_i` | In | Select PC+4 write-back |
| `RegWrite_ctrl_i` | In | Enable register-file write |
| `MemtoReg_ctrl_i` | In | Select memory rather than ALU write-back |
| `read_data1_o` | Out | `RF[rs1]` |
| `read_data2_o` | Out | `RF[rs2]` |
| `SignExt_o` | Out | Reconstructed and extended instruction immediate |

The write-back priority is PC+4 for jumps, otherwise ALU result for normal operations, otherwise DTCM for loads. Writes occur only when `RegWrite=1` and `rd != 0`.

#### `EXECUTE`

| Port | Direction | Purpose |
|---|---|---|
| `read_data1_i` | In | First register operand |
| `read_data2_i` | In | Second register operand |
| `sign_extend_i` | In | Extended immediate |
| `UpperIm_ctrl_i` | In | Select `rs1`, PC, or zero for ALU A |
| `ALUOp_ctrl_i` | In | Select operation |
| `ALUSrc_ctrl_i` | In | Select register or immediate for ALU B |
| `pc_i` | In | PC used for branch/`jal` target and `auipc` |
| `brTaken_o` | Out | Branch-condition result |
| `alu_res_o` | Out | ALU or `MUL16` result |
| `addr_gen_o` | Out | `PC + branch/jump displacement` |

`EXECUTE` includes:

- 32-bit add/subtract;
- bitwise AND/OR/XOR;
- five-level barrel shifters for shifts by 1, 2, 4, 8, and 16;
- signed and unsigned less-than logic;
- six branch comparisons;
- `MUL16`.

#### `DMEMORY`

| Port | Direction | Purpose |
|---|---|---|
| `clk_i` | In | Processor clock, inverted internally for RAM timing |
| `rst_i` | In | Present for interface consistency; RAM contents are not cleared by it |
| `dtcm_addr_i` | In | Word address |
| `dtcm_data_wr_i` | In | Store word |
| `MemRead_ctrl_i` | In | Load indication; the unregistered RAM output is physically always available |
| `MemWrite_ctrl_i` | In | RAM write enable |
| `dtcm_data_rd_o` | Out | Read word |

#### `MUL16`

| Port | Direction | Purpose |
|---|---|---|
| `a_i(15:0)` | In | Lower 16 bits of ALU operand A |
| `b_i(15:0)` | In | Lower 16 bits of ALU operand B |
| `res_o(31:0)` | Out | Unsigned 16-by-16 product |

#### `PLL`

| Port | Direction | Purpose |
|---|---|---|
| `areset` | In | Optional asynchronous PLL reset; defaults low and is not connected by the top |
| `inclk0` | In | 50 MHz board reference |
| `c0` | Out | 25 MHz processor clock with current divide/multiply constants |
| `locked` | Out | Indicates PLL frequency/phase lock; generated but not used by the top |

---

## 6. Five-stage pipelined processor

### 6.1 Why pipelining improves frequency

The single-cycle design puts nearly all processor logic between two clock edges. The pipelined design inserts registers between groups of logic:

`IF → IF/ID → ID → ID/EX → EX → EX/MEM → MEM → MEM/WB → WB`

Each stage has less combinational work, so it can usually run at a shorter period and higher frequency. Once full, the pipeline can ideally complete one instruction per cycle, even though one instruction still needs approximately five stages from fetch to write-back.

Pipeline registers improve clock frequency but introduce hazards:

- **data hazard**: a younger instruction needs a value not yet written;
- **control hazard**: instructions fetched after a branch may be on the wrong path;
- **structural hazard**: two operations need the same hardware simultaneously. Separate ITCM and DTCM avoid a fetch/data-memory structural conflict.

### 6.2 Stage-by-stage behavior

#### Stage 1 — IF

- Hold current PC.
- Read ITCM.
- Calculate `PC+4`.
- On a stall, hold the PC and IF/ID register.
- On a flush, redirect the PC and put `addi x0,x0,0` into IF/ID as a harmless NOP.

#### Stage 2 — ID

- Decode the IF/ID instruction.
- Read `rs1` and `rs2`.
- Generate its immediate.
- Detect a load-use hazard against the instruction in EX.
- Capture data, register indexes, PC values, and control bits into ID/EX.
- On stall or flush, clear ID/EX control bits to create a bubble.

#### Stage 3 — EX

- Forward the newest available values to both operands.
- Select register/immediate inputs.
- Execute ALU, branch comparison, target calculation, or multiplication.
- Capture the result, store data, `rd`, branch result, target, and later-stage controls into EX/MEM.

#### Stage 4 — MEM

- Read or write DTCM.
- Resolve control flow from EX/MEM:
  - taken conditional branch;
  - every `jal`;
  - every `jalr`.
- Generate `flush_w` and redirect the PC.
- Capture write-back values and controls into MEM/WB.

Because redirection waits until MEM, three younger instructions can be present in IF, ID, and EX. A redirect kills all three, so each flush has a three-cycle penalty.

#### Stage 5 — WB

The write-back mux is located in `IDECODE`, but its inputs come from MEM/WB:

- PC+4 for `jal`/`jalr`;
- DTCM data for `lw`;
- ALU/multiplier result otherwise.

The result is written to `rd`, forwarded to EX if needed, and bypassed directly to ID reads if WB and ID access the same register in the same cycle.

### 6.3 Pipelined top level: `RV32IM_PIPE_CORE`

The memory, PC, and datapath generics have the same meaning as the single-cycle core. Additional generics are:

| Generic | Meaning |
|---|---|
| `STCNT_WIDTH` | Stall-counter width; 8 on FPGA, widened to 16 in the testbench |
| `FHCNT_WIDTH` | Flush-counter width; 8 on FPGA, widened to 16 in the testbench |
| `BP_ADDR_WIDTH` | Breakpoint word-address width, 8 bits |

Inputs:

| Signal | Meaning |
|---|---|
| `clk_i` | 50 MHz board clock or direct ModelSim test clock |
| `rst_i` | Simulation reset or active-low board `KEY0` |
| `BPADDR_i(7:0)` | Breakpoint word address, connected to `SW7..SW0` on the board |

Outputs:

| Signal | Stage represented and meaning |
|---|---|
| `pc_o` | IF-stage byte PC |
| `instruction_o` | ID-stage instruction in IF/ID |
| `RegWrite_ctrl_o` | WB-stage register write enable |
| `MemWrite_ctrl_o` | MEM-stage store enable |
| `Branch_ctrl_o` | MEM-stage branch marker |
| `read_data1_o` | EX-stage unforwarded `rs1` value from ID/EX |
| `read_data2_o` | EX-stage unforwarded `rs2` value from ID/EX |
| `write_data_o` | WB-stage value selected for register write |
| `alu_res_o` | MEM-stage ALU result in EX/MEM |
| `brTaken_o` | MEM-stage branch comparison result |
| `dtcm_addr_o` | Current MEM-stage DTCM word address |
| `dtcm_data_wr_o` | Forwarded store value presented to DTCM |
| `dtcm_data_rd_o` | Current DTCM read value |
| `stall_o` | Load-use interlock request |
| `flush_o` | MEM-stage branch/jump redirect event |
| `BPTRIGGER_o` | High when IF PC word address equals the registered switch breakpoint |
| `CLKCNT_o` | Total processor clock cycles since reset |
| `STCNT_o` | Stall cycles, excluding a simultaneous higher-priority flush |
| `FHCNT_o` | Redirect/flush events |

The exposed signals intentionally represent different stages. They must not be interpreted as if they all describe `instruction_o` in the same cycle.

### 6.4 Forwarding

Without forwarding:

```text
add x5,x1,x2
sub x6,x5,x3
```

`sub` reaches EX before `add` has written `x5` in WB. Stalling until WB would waste cycles.

`FORWARD_UNIT` compares the EX instruction's `rs1` and `rs2` with older destination registers:

- `"10"`: use EX/MEM ALU result, one-instruction distance;
- `"01"`: use WB write-back result, two-instruction distance;
- `"00"`: use ID/EX register-file value.

EX/MEM has priority if both stages match because it is the newer producer. Register zero is excluded. The forwarded `rs2` value also becomes store data, so a just-produced value can be stored correctly.

`FORWARD_UNIT` ports:

| Port | Direction | Purpose |
|---|---|---|
| `ex_rs1_i`, `ex_rs2_i` | In | Source indexes of the EX instruction |
| `mem_RegWrite_ctrl_i` | In | MEM instruction will write a register |
| `mem_rd_i` | In | MEM destination |
| `wb_RegWrite_ctrl_i` | In | WB instruction will write a register |
| `wb_rd_i` | In | WB destination |
| `forward_a_o`, `forward_b_o` | Out | Two-bit selects for EX operand muxes |

### 6.5 Load-use hazard and stall

Forwarding cannot solve:

```text
lw  x5,0(x1)
add x6,x5,x2
```

The load data becomes available only near the end of the load's MEM cycle, too late for the following `add` EX calculation. `HAZARD_UNIT` detects:

`EX is a load AND EX.rd != x0 AND (EX.rd = ID.rs1 OR EX.rd = ID.rs2)`

It then:

1. freezes PC;
2. holds IF/ID so the consumer remains in ID;
3. injects a control-zero bubble into ID/EX;
4. allows the load to continue;
5. one cycle later forwards the load from WB to the consumer in EX.

`HAZARD_UNIT` ports:

| Port | Direction | Purpose |
|---|---|---|
| `id_rs1_i`, `id_rs2_i` | In | Current ID source indexes |
| `ex_MemRead_ctrl_i` | In | EX instruction is a load |
| `ex_rd_i` | In | EX destination |
| `stall_o` | Out | One-cycle interlock request |

### 6.6 Flush and control hazards

The top-level equation is:

`flush = (MEM.Branch AND MEM.brTaken) OR MEM.Jal OR MEM.Jalr`

On a flush:

- the PC takes the redirect target;
- IF/ID receives a NOP;
- ID/EX control bits are cleared;
- EX/MEM control bits for the younger EX instruction are cleared.

Flush has priority over stall because the MEM redirecting instruction is older, and all younger wrong-path instructions must be discarded.

### 6.7 Pipeline counters and IPC

- `CLKCNT`: every active processor cycle.
- `STCNT`: cycles with `stall=1` and `flush=0`.
- `FHCNT`: flush events.

The lab's estimate of useful retired instructions is:

`retired = CLKCNT - (STCNT + 4 + 3×FHCNT)`

The `4` is initial fill overhead for a five-stage pipeline. Each flush removes three younger instructions.

`IPC = retired / CLKCNT`

An ideal full pipeline approaches IPC = 1. Dependencies and redirects lower it. This equation is a performance accounting model, not an independent proof of functional correctness; the DTCM golden comparison remains the functional proof.

### 6.8 Pipeline unit ports

`CONTROL`, `MUL16`, and `PLL` use the same ports and behavior as in the single-cycle design.

#### Pipeline `IFETCH`

| Port | Direction | Purpose |
|---|---|---|
| `clk_i`, `rst_i` | In | Clock/reset |
| `stall_i` | In | Freeze PC and hold IF/ID |
| `flush_i` | In | Redirect and bubble IF/ID |
| `redirect_addr_i` | In | Target resolved in MEM |
| `if_pc_o` | Out | Current IF PC |
| `pc_o` | Out | ID PC held in IF/ID |
| `pc_plus4_o` | Out | ID PC+4 held in IF/ID |
| `instruction_o` | Out | ID instruction held in IF/ID |

#### Pipeline `IDECODE`

Inputs:

| Port group | Purpose |
|---|---|
| `clk_i`, `rst_i`, `stall_i`, `flush_i` | Clock, reset, and bubble controls |
| `pc_i`, `pc_plus4_i`, `instruction_i` | IF/ID values |
| `RegDst`, `RegWrite`, `MemtoReg`, `MemRead`, `MemWrite`, `Branch`, `Jal`, `Jalr`, `ALUSrc`, `UpperIm`, `ALUOp` | ID control outputs to capture in ID/EX |
| `wb_RegDst`, `wb_RegWrite`, `wb_MemtoReg`, `wb_rd`, `wb_pc_plus4`, `wb_alu_res`, `wb_dtcm_data_rd` | WB values and controls used by the write-back mux/register-file port |

Outputs:

| Port group | Purpose |
|---|---|
| `id_rs1_o`, `id_rs2_o` | ID source indexes for hazard detection |
| `wb_write_data_o` | Final WB value for RF write and WB forwarding |
| `ex_pc_o`, `ex_pc_plus4_o` | ID/EX PC values |
| `ex_read_data1_o`, `ex_read_data2_o`, `ex_sign_ext_o` | ID/EX operand/immediate values |
| `ex_rs1_o`, `ex_rs2_o`, `ex_rd_o` | ID/EX register indexes |
| `ex_ALUSrc`, `ex_UpperIm`, `ex_ALUOp` | EX controls |
| `ex_Branch`, `ex_Jal`, `ex_Jalr`, `ex_MemRead`, `ex_MemWrite` | Controls needed through MEM |
| `ex_RegDst`, `ex_RegWrite`, `ex_MemtoReg` | Controls needed through WB |

It also implements same-cycle WB-to-ID bypass on both register-file read ports.

#### Pipeline `EXECUTE`

Inputs:

| Port group | Purpose |
|---|---|
| `clk_i`, `rst_i`, `flush_i` | Clock/reset and EX/MEM bubble |
| `pc_i`, `pc_plus4_i`, `read_data1_i`, `read_data2_i`, `sign_extend_i`, `rd_i` | ID/EX data |
| `UpperIm`, `ALUOp`, `ALUSrc` | Current EX controls |
| `Branch`, `Jal`, `Jalr`, `MemRead`, `MemWrite`, `RegDst`, `RegWrite`, `MemtoReg` | Controls to carry into EX/MEM |
| `forward_a_i`, `forward_b_i` | Operand forwarding selections |
| `wb_write_data_i` | WB forwarding source |

Outputs:

| Port group | Purpose |
|---|---|
| `mem_pc_plus4_o` | Link value in EX/MEM |
| `mem_alu_res_o` | ALU result/address/`jalr` target in EX/MEM |
| `mem_write_data_o` | Forwarded store value in EX/MEM |
| `mem_addr_gen_o` | Branch/`jal` target in EX/MEM |
| `mem_brTaken_o`, `mem_rd_o` | Branch decision and destination in EX/MEM |
| `mem_Branch`, `mem_Jal`, `mem_Jalr`, `mem_MemRead`, `mem_MemWrite` | MEM controls |
| `mem_RegDst`, `mem_RegWrite`, `mem_MemtoReg` | WB controls |

#### Pipeline `DMEMORY`

Inputs:

| Port | Purpose |
|---|---|
| `clk_i`, `rst_i` | Clock/reset |
| `dtcm_addr_i`, `dtcm_data_wr_i` | DTCM word address and store data |
| `MemRead_ctrl_i`, `MemWrite_ctrl_i` | Load/store controls |
| `pc_plus4_i`, `alu_res_i`, `rd_i` | Values to capture in MEM/WB |
| `RegDst_ctrl_i`, `RegWrite_ctrl_i`, `MemtoReg_ctrl_i` | WB controls to capture |

Outputs:

| Port | Purpose |
|---|---|
| `dtcm_data_rd_o` | Current MEM read data |
| `wb_pc_plus4_o` | Link value in MEM/WB |
| `wb_alu_res_o` | ALU value in MEM/WB |
| `wb_dtcm_data_rd_o` | Load value in MEM/WB |
| `wb_rd_o` | WB destination |
| `wb_RegDst_ctrl_o`, `wb_RegWrite_ctrl_o`, `wb_MemtoReg_ctrl_o` | WB controls |

---

## 7. The four test programs

All programs end in `while(1)`, compiled as a self-branch or self-jump. This gives the testbench a recognizable completion point. The initial arrays/matrices and the expected final memory are produced independently, and RARS acts as the architectural golden model.

### 7.1 Test 1 — short vector arithmetic

Source: `Auxilary/test1/RV32IM/test1.c`

Inputs:

```text
arr1 = [1,2,3,4,5,6,7,8]
arr2 = [8,7,6,5,4,3,2,1]
```

For eight elements:

- `res1[i] = arr1[i] + arr2[i]`
- `res2[i] = arr1[i] * arr2[i]`
- `res3[i] = arr1[i] ^ arr2[i]`

Expected results:

```text
res1 = [9,9,9,9,9,9,9,9]
res2 = [8,14,18,20,20,18,14,8]
res3 = [9,5,5,1,1,5,5,9]
```

The hand-written assembly first loads `SIZE=8` and five array pointers. Its loop performs two loads, add/store, multiply/store, XOR/store, pointer increments, counter decrement, and `bne` back to the loop. The DTCM word map is:

| Word addresses | Contents |
|---|---|
| 0–7 | Original `arr1` |
| 8–15 | Original `arr2` |
| 16–23 | Eight addition results |
| 24–31 | Eight multiplication results |
| 32–39 | Eight XOR results |
| 40 | `SIZE = 8` |

What it tests:

- `lw` and `sw`;
- address incrementing;
- register arithmetic;
- bitwise XOR;
- `mul` decode and multiplier result;
- loop counter update;
- branch taken seven times and not taken at loop exit;
- correct placement of three result vectors in DTCM.

Measured single-cycle completion is 13.4 µs at the 100 ns simulation period, with `mclk_cnt_o = 134`, terminal PC observation `0x0070`, and terminal instruction `0x00000063`.

### 7.2 Test 2 — interleaved 10×10 matrix operations

Source: `Auxilary/test2/RV32IM/test2.c`

`mat1` contains 1 through 100. `mat2` contains 100 down to 1. A nested C loop was manually flattened/compiled into one element loop that calculates all three outputs together:

- `res1[k] = mat1[k] + mat2[k] = 101`
- `res2[k] = mat1[k] * mat2[k] = (k+1) × (100-k)`
- `res3[k] = mat1[k] - mat2[k] = 2(k+1) - 101`

What it tests:

- 100 multiply operations;
- 300 stores, one for every cell of three result matrices;
- repeated load-use dependencies;
- forwarding and one-cycle load-use stalls in the pipeline;
- negative two's-complement subtraction results;
- long-loop branch behavior;
- address regions for large arrays.

The first results are:

```text
res1[0] = 101       = 0x00000065
res2[0] = 1×100     = 0x00000064
res3[0] = 1-100     = 0xFFFFFF9D
```

The DTCM word layout is:

| Word addresses | Contents |
|---|---|
| 0 | `size = 100` (`0x64`) |
| 1–100 | `mat1 = 1..100` |
| 101–200 | `mat2 = 100..1` |
| 201–300 | `res1`, all `0x00000065` |
| 301–400 | `res2`, multiplication products |
| 401–500 | `res3`, signed subtraction results |

Representative stores are word 201=`0x65`, word 301=`0x64`, and word 401=`0xFFFFFF9D`. There are 100 multiplies, 300 stores, and 99 taken loop-back branches.

Measured single-cycle completion is 151.4 µs and 1,514 cycles, with terminal PC observation `0x0070`. A saved pipeline waveform shows the endpoint around 191.4 µs, `STCNT≈100`, and `FHCNT≈99` immediately around completion; the additional cycles are explained by load-use stalls and three-slot branch flushes.

### 7.3 Test 3 — three separate matrix loops

Source: `Auxilary/test3/RV32IM/test3.c`

Test 3 computes the same final matrices as test 2, but it uses three complete loops:

1. calculate every addition result;
2. calculate every multiplication result;
3. calculate every subtraction result.

Why this is different from test 2:

- memory accesses and arithmetic are grouped by operation;
- there are three independent loop-exit/control-flow phases;
- branch handling is exercised roughly three times as often;
- the pipeline schedule differs, so its stall/forward behavior differs even though the final DTCM is identical to test 2.

What it tests:

- long sequential sections;
- repeated loop-back branches and three loop exits;
- switching from add phase to multiply phase to subtract phase;
- preservation of earlier result arrays while later loops run;
- equivalence of two different program organizations that produce the same mathematical answer.

Measured single-cycle completion is 272.5 µs and 2,725 cycles.

The expected output memory is byte-for-byte identical to test 2 even though the instruction ordering is different. The three loops produce 100 multiplies, 300 stores, and `3×99=297` taken loop-back branches. The terminal single-cycle PC observation is `0x00CC`.

### 7.4 Test 4 — matrix functions and call/return control flow

Source: `Auxilary/test4/RV32IM/C-code/test4.c`

`main` calls:

1. `addMat(mat1, mat2, res1)`
2. `subMat(mat1, mat2, res2)`
3. `mulMat(mat1, mat2, res3)`

The numerical operations are the same as tests 2/3, but note the result order:

- test 4 `res1` is addition;
- test 4 `res2` is subtraction;
- test 4 `res3` is multiplication.

Its DTCM input regions are the same as tests 2/3, but output regions 301–400 and 401–500 are swapped by meaning:

| Word addresses | Test 4 contents |
|---|---|
| 201–300 | addition (`res1`) |
| 301–400 | subtraction (`res2`), beginning `0xFFFFFF9D` |
| 401–500 | multiplication (`res3`), beginning `0x00000064` |

What it tests:

- argument/address setup;
- stack-pointer and return-address conventions;
- `jalr`-based function calls;
- writing `PC+4` into `x1`/`ra`;
- `jalr x0,0(ra)` return;
- three calls and three returns;
- flushes caused by indirect control transfers;
- the same matrix datapath under modular function-oriented code.

Measured single-cycle completion is 273.5 µs and 2,735 cycles, with terminal PC observation `0x004C`. Test 4 has 297 taken loop branches plus six `jalr` redirects: three calls and three returns.

---

## 8. ModelSim verification

### 8.1 Testbench behavior

Both testbenches generate:

- 100 ns clock period: 50 ns high and 50 ns low;
- reset high initially and low after 80 ns.

This 10 MHz simulation clock is intentionally slow and has no relationship to Quartus Fmax. Functional RTL simulation does not model final FPGA propagation delays.

The single-cycle testbench stops when `instruction_o` becomes:

- `0x00000063`: `beq x0,x0,0`; or
- `0x0000006F`: `jal x0,0`.

The pipeline cannot safely stop merely when that instruction appears in ID because it may have been fetched speculatively and later flushed. It stops only when a flush in MEM has a redirect target equal to the redirecting instruction's own PC. It then waits several cycles to let older operations drain.

### 8.2 Build procedure

From the appropriate `SIM` directory:

1. Run `compile.do`.
2. Confirm every package, unit, top level, and testbench compiles with zero errors.
3. The three `Non-locally static OTHERS choice` warnings in `EXECUTE` are known VHDL-tool warnings and are not functional failures.
4. Ensure simulation mode is selected (`G_MODELSIM=1` or `-gMODELSIM=1`).

Compilation uses VHDL-2008 because of constructs including `process(all)`, generate forms, external names in the pipeline testbench, and `std.env.stop`.

### 8.3 Per-test procedure

`run_test.do`:

1. copies test `N`'s `ITCM.hex` and `DTCM.hex` into `C:\TestPrograms\Quartus21_1\app_bin`;
2. starts the correct testbench;
3. loads `wave.do`;
4. runs until the final self-loop or a 5 ms runaway limit;
5. records counters;
6. allows the pipeline to drain;
7. runs `mem_dump.do`.

The current scripts have `set N 4`; change `N` to 1, 2, 3, or 4 for an individual run.

### 8.4 Waveform checks

#### Reset and fetch

Confirm:

- reset is initially high;
- after reset, the PC begins at zero;
- normal PC steps are four bytes;
- instruction changes with PC;
- the cycle counter increments once per rising edge.

#### Decode and write-back

For a register-writing instruction:

- `RegWrite=1`;
- `read_data1`/`read_data2` match the indexed registers;
- `ALUOp` matches the instruction;
- `write_data` equals ALU, load, or PC+4 result;
- the destination register changes on the next active edge;
- `x0` never changes.

#### Multiplication

For instruction `0x03DE0F33` in test 1:

- `mul_w=1`;
- `ALUOp=ALU_MUL`;
- multiplier inputs show `1` and `8`;
- `MUL16.res_o=8`;
- `alu_res_o=8`;
- a later store writes 8 into the first multiplication-result element.

Testing only the instantaneous multiplier output is insufficient. Following the value through ALU result, store data, DTCM address, and final golden comparison proves end-to-end integration.

#### Loads and stores

For a store:

- `MemWrite=1`;
- ALU result gives the correct byte address;
- `dtcm_addr` equals byte address divided by four;
- `dtcm_data_wr` is the expected result;
- the DTCM word changes at the falling edge.

For a load:

- `MemRead=1`;
- address is correct;
- `dtcm_data_rd` matches memory;
- `MemtoReg=1`;
- the loaded word reaches write-back.

#### Branches and jumps

For a taken branch:

- `Branch=1`;
- comparator inputs are correct;
- `brTaken=1`;
- target equals PC plus signed branch displacement;
- single-cycle PC redirects on the next cycle;
- pipeline `flush=1`, wrong-path controls become zero, and IF PC redirects.

For a not-taken branch:

- `Branch=1`, `brTaken=0`;
- PC follows PC+4;
- pipeline does not flush.

For a function call/return:

- `Jalr=1`;
- ALU result is the target;
- PC redirects;
- call writes PC+4 into `ra`;
- return uses `ra` and does not modify a destination because `rd=x0`.

#### Pipeline forwarding

Confirm cases where:

- `forward_a` or `forward_b = 10`: newest result comes from EX/MEM;
- `forward_a` or `forward_b = 01`: value comes from WB;
- forwarded operand equals the producing instruction's result;
- dependent instruction's ALU result is correct without a stall;
- if the dependent value is store data, the forwarded value reaches `dtcm_data_wr`.

#### Pipeline load-use stall

At an immediate load consumer:

- load is in EX with `MemRead=1`;
- its `rd` matches ID `rs1` or `rs2`;
- `stall=1` for one cycle;
- PC and IF/ID hold;
- ID/EX control outputs become zero;
- load proceeds to MEM/WB;
- next cycle the consumer advances and receives WB forwarding;
- `STCNT` increments once.

#### Pipeline flush

At each taken branch/jump:

- MEM-stage condition generates `flush=1`;
- redirect address is correct;
- IF, ID, and EX younger operations are killed;
- no killed instruction writes a register or memory;
- `FHCNT` increments once.

### 8.5 Golden DTCM comparison: the decisive pass criterion

Waveforms demonstrate selected cycles; they do not prove every loop iteration. End-to-end verification is:

1. let the program finish;
2. export DTCM with `mem_dump.do`;
3. compare `SIM/.../DTCM.mem` against the RARS-generated golden DTCM for the same program;
4. require zero differing words.

The current dump script exports addresses 0 through 1023, i.e. the lower 1,024 words (4 KiB) of the configured 2,048-word DTCM. All benchmark data must lie in that checked range.

The repository preserves `DTCM_test1.mem` through `DTCM_test4.mem` for both cores. All eight saved simulation dumps match their corresponding 1,024-word RV32IM RARS golden `DTCM.h` files case-insensitively. This is the strongest stored evidence that both implementations completed all four programs correctly. There are no saved ModelSim transcripts or WLF databases, so exact run history must be regenerated when needed.

A pass requires all of the following:

- ModelSim compilation has zero errors;
- program reaches the final self-loop before 5 ms;
- no unknown `X/U` remains after reset in architecturally used values;
- selected waveform events have correct control/data relationships;
- DTCM dump is identical to RARS;
- pipeline stalls and flushes are explainable and do not alter final results.

### 8.6 Measured pipeline counter examples

Direct ModelSim runs with `MODELSIM=1` produced these post-drain observations:

| Test | Completion time reported | Final observed `CLKCNT` | `STCNT` | `FHCNT` |
|---|---:|---:|---:|---:|
| 1 | 16.6 µs | 170 | 8 | 8 |
| 2 | 191.4 µs | 1,918 | 100 | 100 |
| 3 | 361.9 µs | 3,623 | 0 | 298 |
| 4 | 364.7 µs | 3,651 | 0 | 304 |

These final values include the testbench's short drain interval and, depending on event-update timing, the terminal self-jump flush. For the lab IPC equation, use the counter snapshot taken by `run_test.do` at its specified completion event rather than mixing snapshots from different moments.

---

## 9. Quartus synthesis and FPGA implementation

### 9.1 Target hardware

Both Quartus projects target:

- board: Terasic DE2-115;
- FPGA: Intel/Altera Cyclone IV E;
- exact device: `EP4CE115F29C7`;
- Quartus Prime Lite 21.1;
- VHDL-2008.

Pin assignments:

- `clk_i` → `PIN_Y2`, board `CLOCK_50`;
- `rst_i` → `PIN_M23`, `KEY0`;
- pipeline `BPADDR_i(7:0)` → `SW7..SW0`.

### 9.2 What synthesis tests

Quartus Analysis & Synthesis checks that:

- the VHDL is synthesizable hardware, not simulation-only behavior;
- all entities connect with compatible widths and directions;
- logic can map to Cyclone IV lookup tables, registers, RAM blocks, PLLs, and multiplier resources;
- ITCM and DTCM infer embedded RAM;
- `MUL16` infers embedded multiplier hardware;
- pipeline registers, forwarding muxes, hazard comparator, and counters are real hardware;
- the complete design can be fitted into the selected device.

The RTL Viewer screenshots show the inferred hierarchy and connectivity:

- `rtl_ife`: PC, PC+4, ITCM, and pipeline IF/ID logic;
- `rtl_id`: register file, immediate paths, write-back mux, and ID/EX registers;
- `rtl_ctl`: mask-based instruction decoder;
- `rtl_exe`: ALU, shifters, comparisons, multiplier, forwarding, and EX/MEM;
- `rtl_mem`: DTCM and MEM/WB;
- `rtl_mul`: four partial multipliers and the adder/shift combination;
- pipeline `rtl_hzd` and `rtl_fwd`: hazard and forwarding comparators;
- pipeline `rtl_top*`: full stage interconnection, redirect, counters, and breakpoint.

### 9.3 PLL operation

The board provides a stable 50 MHz crystal oscillator:

`input period = 1 / 50 MHz = 20 ns`

The `ALTPLL` is configured at synthesis using:

- multiply by 1;
- divide by 2;
- 50% duty cycle;
- zero phase shift.

Therefore:

`fcore = 50 MHz × 1 / 2 = 25 MHz`

and:

`Tcore = 1 / 25 MHz = 40 ns`

A PLL uses a phase/frequency detector, feedback divider, voltage-controlled oscillator, and output divider to lock its generated clock to a reference. Once locked, the average phase and frequency relationship is controlled. It provides a dedicated low-skew FPGA clock network and allows frequency multiplication/division without implementing an unsafe clock divider in ordinary logic.

In FPGA mode, `mclk_w` comes from PLL `c0`. In ModelSim mode, the PLL is bypassed and `mclk_w=clk_i`, avoiding vendor PLL timing models during functional simulation.

The `locked` output exists but is not used to hold the core in reset. In a more robust production design, reset would normally remain asserted until PLL lock is stable and would be synchronously released.

The wizard “retrieval information” comments near the end of `PLL.vhd` still mention an older multiply-by-3 configuration and 75 MHz. They are stale metadata. The active VHDL generic map uses `G_PLL_MUL=1` and `G_PLL_DIV=2`, and the SDC also documents 25 MHz; those are the authoritative synthesis settings.

### 9.4 Embedded Multiplier 9-bit Elements

Cyclone IV devices contain dedicated arithmetic multiplier hardware. Quartus reports this resource in units called **Embedded Multiplier 9-bit Elements**. One such element can implement a multiplier up to roughly 9 by 9 bits; wider products consume several elements.

`MUL16` splits:

```text
A = AH·2^8 + AL
B = BH·2^8 + BL
```

Then computes:

```text
P0 = AL × BL
P1 = AL × BH
P2 = AH × BL
P3 = AH × BH

A × B = P0 + ((P1 + P2) << 8) + (P3 << 16)
```

Each partial product is 8×8, so it fits naturally in one embedded 9-bit multiplier element. Four partial products therefore use four elements. Quartus' pipeline area screenshot confirms:

- `Embedded Multiplier 9-bit elements = 4 / 532 (<1%)`.

Why use dedicated multiplier blocks:

- multiplication in lookup-table fabric would require many logic elements;
- dedicated blocks are smaller and usually faster;
- they reduce pressure on general routing and ALU logic;
- the explicit four-part structure makes resource mapping predictable.

The reported four elements prove that Quartus inferred dedicated hardware rather than constructing the whole multiplier from ordinary logic.

### 9.5 Pipeline resource result

The saved pipeline Fitter summary reports:

- logic elements: `3,384 / 114,480` (3%);
- registers: `1,696`;
- pins: `297 / 529` (56%);
- memory bits: `131,072 / 3,981,312` (3%);
- embedded 9-bit multiplier elements: `4 / 532` (<1%);
- PLLs: `1 / 4` (25%).

The high pin count is largely caused by exposing many debug buses as top-level outputs. This is useful for SignalTap/lab visibility but is not representative of a minimal packaged CPU interface.

The `131,072` memory bits equal 16 KiB:

`8 KiB ITCM + 8 KiB DTCM = 16 KiB = 131,072 bits`.

### 9.6 Fmax

`Fmax` is the highest clock frequency at which the fitted design satisfies register-to-register setup timing for the selected device, routing, voltage, temperature, and timing constraints:

`Fmax ≈ 1 / minimum safe clock period`

Saved slow-corner Timing Analyzer results:

- single-cycle PLL/core clock Fmax: **26.81 MHz**;
- pipelined PLL/core clock Fmax: **41.84 MHz**.

The separate `altera_reserved_tck` rows are JTAG/debug clocks and are not processor performance.

Interpretation:

- both designs are intended to run at 25 MHz;
- 25 MHz is below 26.81 MHz and 41.84 MHz, so both meet the intended core clock in the shown timing model;
- single-cycle margin is small: about 1.81 MHz;
- pipeline margin is much larger: about 16.84 MHz;
- pipeline Fmax improvement is approximately `41.84 / 26.81 ≈ 1.56`, or about 56%.

Fmax does not mean the application automatically runs 56% faster. Total performance depends on:

`instructions / second = clock frequency × IPC`

The pipeline has a higher clock ceiling but loses cycles to stalls and flushes. A fair comparison combines Fmax with the measured IPC and workload.

### 9.7 Critical path

A critical path is the slowest timing path limiting the clock period. It includes:

- source register clock-to-output delay;
- combinational logic delay;
- routing delay;
- destination register setup requirement;
- clock skew/uncertainty.

The saved pipeline timing screenshot shows representative high-delay paths from execute-stage registered logic toward DTCM/address-register logic. This is consistent with the MEM-address route: forwarded/registered execute result, address selection, and embedded RAM interface form a significant stage path.

Positive setup slack means arrival is earlier than required. Negative slack would mean the selected clock is too fast. The Fmax report summarizes the highest frequency before the worst setup slack reaches zero.

The screenshot displays a worst listed setup slack of `+12.849 ns` for a path from `Execute:EXE|ex_mem_alu_res_q[4]` to an M9K memory address register. It also displays a 20 ns relationship even though the documented derived core period is 40 ns. Since the textual Quartus timing reports are absent, this relationship cannot be resolved conclusively from the repository; use the Fmax screenshots as the preserved timing result and regenerate the reports before making a formal timing sign-off claim.

---

## 10. SignalTap hardware validation

### 10.1 What SignalTap is

SignalTap is an internal logic analyzer implemented inside the FPGA. It samples selected internal nodes on a hardware clock and stores them in on-chip RAM. After a trigger, Quartus reads the captured samples over JTAG.

Unlike ModelSim:

- SignalTap observes the real fitted FPGA;
- clock distribution, placement, routing, PLL, initialized RAM, and physical reset/switch inputs are active;
- only preselected nodes and a finite time window are visible.

### 10.2 Current pipeline SignalTap setup

`Quartus/RV32IM_pipeline/RV32IM_pipeline.stp` configures:

- acquisition clock: PLL output `clk[0]`, the 25 MHz processor clock;
- positive-edge sampling;
- sample depth: 4,096;
- circular/pre-trigger capture;
- observed buses: `BPADDR_i`, `BPTRIGGER_o`, `CLKCNT_o`, `STCNT_o`, `FHCNT_o`, `instruction_o`, and `pc_o`;
- advanced trigger based on `BPTRIGGER_o` and a nonzero clock-counter condition.

`BPADDR_i` is a word address from switches. The CPU stores it in `bpaddr_q`. The comparator uses:

`BPTRIGGER = 1 when IF_PC(PC_WIDTH-1 downto 2) = BPADDR`

Dropping PC bits 1 and 0 converts byte PC to word PC. Therefore, to trigger at byte PC `0x0040`, set switches to word address `0x10`.

### 10.3 Board procedure

1. Put the desired benchmark `ITCM.hex` and initial `DTCM.hex` in `app_bin`.
2. Keep `G_MODELSIM=0`.
3. Compile the pipeline Quartus project with SignalTap enabled.
4. Program `RV32IM_PIPE_CORE.sof` through USB-Blaster/JTAG.
5. Set `SW7..SW0` to the desired PC word address.
6. Press `KEY0` to reset; release it to run.
7. Arm SignalTap.
8. Wait for the core to fetch the selected PC and assert `BPTRIGGER`.
9. Inspect samples before and after the trigger.

### 10.4 What to test and exact pass conditions

#### A. PLL and reset

Check:

- samples occur on a stable 25 MHz acquisition clock;
- counters clear when `KEY0` is pressed;
- after release, `CLKCNT` increments monotonically.

Pass: reset reproducibly returns counters/PC to their initial state and execution restarts.

#### B. Breakpoint address conversion

Choose an instruction whose byte PC is known from assembly. Set switches to `PC/4`.

Pass:

- `BPADDR` equals switch value;
- `BPTRIGGER` rises when the IF PC's word address equals it;
- changing switches changes the trigger point correspondingly;
- the displayed instruction sequence around the event matches the program listing.

#### C. Sequential fetch

Away from redirects, inspect consecutive PC samples.

Pass:

- PC advances by four bytes per non-stalled cycle;
- instruction words correspond to ITCM at those addresses;
- when PC is held by a load-use stall, the counter still advances but the fetch point repeats.

#### D. Branch and jump behavior

Place a breakpoint near a loop branch or test 4 call/return.

Pass:

- the pre-trigger PC sequence reaches the branch/jump;
- after the pipeline's resolution delay, PC changes to the correct target;
- `FHCNT` increases by one per redirect;
- no unexplained target or missing redirect appears.

Because only top-level PC/instruction/counters are in the current `.stp`, the internal `flush_o` signal is inferred from the observed redirect and `FHCNT` increment. Add `flush_o` and `redirect_addr_w` as SignalTap nodes if direct proof is required.

#### E. Stall accounting

Use test 2, which has immediate load consumers.

Pass:

- repeated PC behavior appears where the interlock holds fetch;
- `STCNT` increments for each stall cycle;
- execution resumes at the correct instruction;
- the final counter agrees with ModelSim for the same binary and counter sampling point.

Add `stall_o`, ID/EX register indexes, and forwarding selects to the `.stp` if the presentation must show the exact hazard equation directly.

#### F. Performance counters and IPC

Trigger at or just before the final self-loop and read:

- `CLKCNT`;
- `STCNT`;
- `FHCNT`.

Compute:

`IPC = (CLKCNT - (STCNT + 4 + 3×FHCNT)) / CLKCNT`

Pass:

- counter values are stable/repeatable for identical reset and binary;
- they agree with ModelSim when measured at the same architectural event;
- test 2 shows stall cost;
- tests 3/4 show larger flush cost;
- test 4 has additional call/return redirects.

#### G. Functional result

The current SignalTap node list does not include DTCM address/data/write-enable, so it cannot by itself prove final matrix contents.

For stronger on-board proof, add:

- `MemWrite_ctrl_o`;
- `dtcm_addr_o`;
- `dtcm_data_wr_o`;
- optionally `alu_res_o`, `forward_a_w`, and `forward_b_w`.

Then trigger near representative stores and require the captured address/data pairs to match RARS. Full-memory functional proof remains most practical in ModelSim through the 1,024-word dump comparison.

### 10.5 Evidence boundary

The repository contains the pipeline `.stp` configuration and an SOF payload embedded inside it, which proves that a SignalTap-enabled image was prepared. It does not contain a standalone programming file or an exported SignalTap acquisition waveform. The `.stp` session header also names an EP3C120-compatible JTAG device while the Quartus project targets EP4CE115F29C7; this is likely stale session metadata and should be refreshed by rebuilding/reconnecting on the DE2-115. Therefore, the exact node/trigger configuration is supported, but a completed on-board capture should not be claimed without showing actual captured data.

---

## 11. Known limitations and presentation cautions

1. **Not full RV32M**: only the `mul` encoding is executed.
2. **Multiplier width**: only lower 16 bits of each operand are multiplied, unsigned.
3. **Memory access width**: datapath is effectively word-only despite decoding byte/halfword opcodes.
4. **No exceptions/CSRs**: constants exist for system instructions, but there is no trap/CSR subsystem.
5. **No cache or external bus**: programs and data reside entirely in local TCM.
6. **No dynamic branch prediction**: fetch proceeds sequentially until a MEM-stage redirect.
7. **Late branch resolution**: three younger instructions are flushed.
8. **Counter width on FPGA**: `STCNT` and `FHCNT` are 8 bits and can wrap above 255. The ModelSim testbench widens them to 16 bits for long tests. Tests 3/4 exceed 255 flushes, so raw 8-bit FPGA values must be interpreted modulo 256 unless the synthesized generics are widened.
9. **PLL lock is unused**: reset release is not conditioned on `locked`.
10. **Absolute memory paths**: simulation and synthesis depend on `C:\TestPrograms\Quartus21_1\app_bin`.
11. **Golden dump range**: `mem_dump.do` checks only the lower 1,024 of 2,048 configured DTCM words.
12. **Control decode errors**: `andi_w` is detected but never selected by the ALU mapping. The `ALU_AND` condition mistakenly contains `ori_w`, so `andi` falls through to `ALU_NONE` and `ori` selects AND before the later OR condition can match. This exists in both cores.
13. **Unknown R-type behavior**: format-level `RegWrite` can assert for an unsupported R-type encoding while `ALUOp=ALU_NONE`, potentially writing zero to `rd` instead of trapping.
14. **`jalr` alignment**: the standard requires clearing target bit 0; this datapath directly uses `rs1+immediate`, so software must provide an aligned target.
15. **Single-cycle PC/instruction observation**: ITCM uses `next_pc_w` while `pc_o` is registered, so waveform address correlation must follow the implementation rather than assuming a textbook registered pair.
16. **Top-level debug pins cost resources**: hundreds of output bits are exposed for observation, producing unusually high pin usage.

These limitations do not invalidate the lab demonstrations. They define exactly what has and has not been proven.

---

## 12. How to present the project

### 12.1 Opening summary

“We built two implementations of the same teaching RISC-V datapath. The single-cycle core completes one instruction per long clock period. The five-stage core overlaps five instructions, adds forwarding and a load-use interlock for data hazards, and flushes three younger instructions when a branch or jump resolves in MEM. Both use separate 8 KiB ITCM and DTCM memories and a custom 16-bit multiply datapath mapped onto four Cyclone IV embedded multiplier elements.”

### 12.2 Functional proof

“We run four independently generated machine-code benchmarks in ModelSim. We do not rely only on a few waveform screenshots. After the final self-loop, we export DTCM and compare every checked word with RARS. Waveforms explain reset, decode, multiplication, stores, branches, forwarding, stalls, and flushes; the memory comparison provides end-to-end correctness for each whole program.”

### 12.3 Performance proof

“The pipeline counts clock, stall, and flush events. The useful-instruction estimate subtracts initial fill, one cycle per stall, and three killed instructions per redirect. Quartus shows that stage registers increase the slow-corner Fmax from 26.81 to 41.84 MHz. Real throughput is frequency multiplied by IPC, so pipeline penalties must be considered alongside Fmax.”

### 12.4 Hardware proof

“Quartus maps the design to an EP4CE115F29C7 on the DE2-115. The PLL converts 50 MHz to a safe 25 MHz core clock. The memories consume exactly 16 KiB of embedded memory, and the four 8×8 partial products consume four embedded 9-bit multiplier elements. SignalTap samples the real 25 MHz domain and triggers when the IF PC word address matches the switch-selected breakpoint.”

### 12.5 Questions to be ready for

- Why is a pipeline faster if each instruction still uses five stages?
- Why can forwarding solve an ALU dependency but not an immediate load-use dependency?
- Why are three instructions flushed?
- Why does a function call need PC+4 and `ra`?
- Why does `SW=PC/4` for the breakpoint?
- Why are four embedded multipliers required for one 16×16 product?
- Why is Fmax not the same as application throughput?
- Why is RARS comparison stronger than a single waveform?
- Which parts of standard RV32IM are not implemented?

---

## 13. Final conclusion

The project demonstrates the complete engineering path from ISA-level software to FPGA hardware:

- decode 32-bit RISC-V instruction fields;
- move values through a register/ALU/memory datapath;
- control branches, jumps, loads, stores, and a custom multiply unit;
- transform a single-cycle processor into a five-stage pipeline;
- preserve correctness with forwarding, stalls, bypassing, and flushing;
- verify complete programs against an independent golden model;
- synthesize and fit to a Cyclone IV FPGA;
- analyze resource usage and maximum frequency;
- observe real hardware execution with a PC breakpoint and SignalTap counters.

The strongest technical claim supported by this repository is not “a fully compliant RV32IM CPU.” It is: **two functionally tested educational RISC-V cores, one single-cycle and one hazard-controlled five-stage pipeline, implementing the instruction subset required by four arithmetic benchmarks and a dedicated lower-16-bit multiply extension, with ModelSim, Quartus, timing, resource, and SignalTap infrastructure.**
