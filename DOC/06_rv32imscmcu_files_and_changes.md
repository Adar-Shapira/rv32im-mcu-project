# RV32IMscMCU — file catalog and changes from the Lab 5 DUT

This document has two jobs:

1. Say what every file under `DUT/RV32IMscMCU/` does.
2. List every change relative to the Lab 5 single-cycle DUT, and why the change exists.

It is a description of the tree as it stands. It is not a specification. When a claim needs a source, the source is named.

---

## Reference used for the comparison

**Original DUT reference:** `Auxiliary/Lab 5/DUT/RV32IM_sc/` (11 VHDL files).

That folder is the Lab 5 single-cycle core as submitted: IF / ID / EX / MEM / WB in one cycle, Harvard ITCM+DTCM, 16×16 `mul`, no divider, no MMIO, no GPIO, no timer, no UART, no interrupt controller. The Lab 5 write-up states this plainly: `Auxiliary/Lab 5/PROJECT_EXPLANATION.md` §1 and §4.4.

**Official project definition:** `Auxiliary/Final Project 2026 definition.pdf` (Figures 1, 3, 5, 7–10; clauses 2–7).

**Sibling repair reference:** `Auxiliary/Lab 5/DUT/RV32IM_pipeline/` — used only for the seven ISA repairs transcribed into the single-cycle core. See `DOC/01_source_inventory.md` §2.2.

**Other course sources used by *new* files (not in the Lab 5 DUT):**

| Source | Used by |
| --- | --- |
| `Auxiliary/Lab4/DUT/hex_decoder.vhd` | `HEX_DECODER.vhd` (body byte-identical) |
| `Auxiliary/Lab4/DUT/pwm.vhd` | `BASIC_TIMER.vhd` (skeleton, widened 16→32) |
| `Auxiliary/Lab4/DUT/fpga_hw_interface.vhd` | board-level PLL / KEY inversion pattern for `RV32IMscMCU.vhd` and `CLOCK_TREE.vhd` |
| Lab 3 `BidirPin.vhd` (md5 `ab12d81dcdc85d91071b077359833bbd`) | `BIDIRPIN.vhd` (body byte-identical) |
| `Auxiliary/USART Material/UART_FPGA_option1/` (Jakub Cabal, MIT) | `UART_TX` / `UART_RX` / `UART_PARITY` / `UART_DEBOUNCER` / `UART_CORE` |
| `Auxiliary/Benchmark Apps/*/asm-code/io_map.s` | MMIO addresses in `const_package.vhd` |

The Lab 5 DUT has **no** address decoder, timer, interrupt controller, UART, GPIO port, clock tree, or divider. Those files are new work (or adapted from the sources above), not edits of Lab 5 files.

---

## Hierarchy (what sits where)

```
RV32IMscMCU                          board-facing MCU (new)
 ├── CLOCK_TREE                      Figure 1 clock tree (new)
 │    └── PLL_GEN × 1 or 2           parameterized ALTPLL (new; PLL.vhd unused)
 ├── RV32IM_CORE                     Lab 5 core, extended
 │    ├── IFETCH                     PC + ITCM
 │    ├── IDECODE                    RF + immediates + write-back
 │    ├── CONTROL                    instruction decode
 │    ├── EXECUTE                    ALU + MUL16 + branch adder
 │    │    └── MUL16                 16×16 unsigned multiplier (unchanged)
 │    ├── DMEMORY                    DTCM
 │    └── DIV_UNIT                   signed wrapper + CDC (new)
 │         ├── SYNC × 4              Figures 10a/10b (new)
 │         └── DIV_ACCEL             Figure 9 unsigned engine (new)
 ├── ADDR_DECODER                    Figure 5 (new)
 ├── GPO_PORT × 7 + HEX_DECODER × 6  Figure 5 GPIO outputs (new / Lab 4)
 ├── BIDIRPIN × N                    Figure 5 SFR read bus (Lab 3)
 ├── BASIC_TIMER                     Figure 7 (new; PWM from Lab 4)
 ├── INTERRUPT_CTRL                  p13/p14 (new)
 └── UART_PERIPH                     §6.iv register layer (new)
      └── UART_CORE                  adapted third-party top
           ├── UART_TX / UART_RX
           ├── UART_PARITY
           └── UART_DEBOUNCER
```

`PLL.vhd` is still in the folder, byte-identical to Lab 5, and is **not instantiated**. The clock tree uses `PLL_GEN` instead.

---

## Part 1 — What each file does

Files are grouped by role. Line counts are approximate (non-blank).

### 1.1 Packages

| File | Role |
| --- | --- |
| `cond_compilation_package.vhd` | Compile-time knobs shared by every entity's generic defaults: ModelSim vs FPGA (`G_MODELSIM`), word vs byte addressing, TCM size (`G_ADDRWIDTH`, `G_DATA_WORDSNUM`, `G_PC_WIDTH`, `G_MA_WIDTH`), leftover Lab 5 PLL ratio (`G_PLL_DIV` / `G_PLL_MUL`), and `G_GEN_INTERRUPT` (PPA table row 1 vs row 2). |
| `const_package.vhd` | Instruction opcode/mask constants, ALU opcodes, immediate pads. Extended with load/lui/auipc opcodes, sub-word `MEM_*` codes, the MMIO map (`DATA_ADDR_WIDTH`, `CS_*`, `SFR_LANE_MASK`), and `INST_RETI`. |
| `aux_package.vhd` | Component declarations only. No datapath. Grew from the Lab 5 core components to every MCU block so `RV32IMscMCU` / `RV32IM_CORE` can instantiate them structurally. |

### 1.2 CPU datapath (inherited from Lab 5, then extended)

| File | Role |
| --- | --- |
| `IFETCH.vhd` | Program counter, next-PC mux, and the ITCM (`altsyncram` ROM). Sequential fetch is PC+4. Taken branch / `jal` use `addr_gen_i`. `jalr` uses the ALU result with bit 0 cleared. Added: `PCHold_i` (divider stall and interrupt Cycle 1) and `IntrVec_ctrl_i` (interrupt Cycle 2 vector). |
| `IDECODE.vhd` | 32×32 register file, field extraction, I/S/SB/U/UJ immediate reconstruction, write-back mux. `x0` is hard-wired zero. Added: divider result arm, GIE tap on `x3[0]`, side-door writes to `gp[0]` and `tp` for interrupt entry/return. |
| `CONTROL.vhd` | Combinational decoder. Mask-compares the instruction against `INST_*` constants and drives RegWrite / MemRead / MemWrite / Branch / Jal / Jalr / ALUSrc / ALUOp / UpperIm. Added: `MemOp` (lb/lh/lw/lbu/lhu/sb/sh), `DivStart` / `DivSigned` / `DivRem`, and `Reti` (`jalr zero,0(tp)` exactly). |
| `EXECUTE.vhd` | ALU, 4-stage barrel shifter, six branch comparators, branch-target adder, and the `MUL16` instance on `ALU_MUL`. Port list is unchanged from Lab 5. Three ISA repairs live in the body (branch displacement, unsigned compare, `sra` pad). |
| `DMEMORY.vhd` | DTCM wrapper around `altsyncram`, still clocked on `not clk` so a store commits mid-cycle and a load is back before the next rising edge. Added: byte enables, sub-word extract/sign-extend, `dtcm_cs_i` so MMIO stores do not also write RAM. |
| `MUL16.vhd` | 16×16 → 32 unsigned multiplier from four 8×8 partial products (Quartus maps these onto the Cyclone IV 9-bit DSP blocks). Lab 5 `mul` datapath. **Byte-identical to the reference.** Does not implement `mulh` / `mulhsu` / `mulhu`. |
| `RV32IM_CORE.vhd` | Structural CPU: IF + ID + EX + MEM + CONTROL. Lab 5 version also owned the PLL and inverted KEY0 when `MODELSIM=0`. Those two jobs moved to the MCU. This file now receives `mclk` and `divclk`, masters the 14-bit data bus, instantiates `DIV_UNIT`, and runs the three-cycle interrupt entry FSM (accept / Cycle 1 / Cycle 2). |

### 1.3 MCU top and bus

| File | Role |
| --- | --- |
| `RV32IMscMCU.vhd` | Board-facing structural top required by definition §3 (“the top level **and** the RV32IM core must be structural”). Instantiates the clock tree, core, address decoder, GPIO, timer, interrupt controller, UART. Conditions KEY0 reset polarity (`RST_ACTIVE_LOW`). Gates SignalTap observation ports with `GEN_DEBUG_PORTS` (§7). `GEN_INTERRUPT` drops §6 peripherals for PPA table row 1. |
| `ADDR_DECODER.vhd` | Figure 5 “Optimized Address Decoder”. Splits the 14-bit data space on A13 into DTCM (`A13=0`) vs SFR page (`A13=1`), one-hot chip-select per mapped SFR word, `unmapped_o` for unused SFR bytes. Pure function of the address; MemRead/MemWrite qualify at the peripheral, as the figure draws. |

### 1.4 Clocking

| File | Role |
| --- | --- |
| `CLOCK_TREE.vhd` | Figure 1 block: `baseclk50MHz` → `mclk`, `accelclk`, `smclk`. FPGA mode: one or two `PLL_GEN` instances. ModelSim mode: behavioural clocks so `altpll` is not required. Default: MCLK = SMCLK = 20 MHz on **one shared net** (forum F7 + F8; sharing is a recorded design decision so the MMIO bus stays synchronously analysable). `accelclk` default 50 MHz (**Assumption A3** — no stated frequency in the definition). `locked_o` holds reset until the PLLs lock. |
| `PLL_GEN.vhd` | Same ALTPLL wrapper as `PLL.vhd`, but `clk0_divide_by` / `clk0_multiply_by` are generics so three frequencies are possible. Exists because three instances of Lab 5 `PLL` would all emit `50×G_PLL_MUL/G_PLL_DIV` (25 MHz). |
| `PLL.vhd` | Wizard-generated ALTPLL, 50 MHz in, `G_PLL_MUL/G_PLL_DIV` out. **Byte-identical to Lab 5 and to Hanan’s baseline.** Kept for provenance; nothing instantiates it after Phase 4C. |
| `SYNC.vhd` | Figures 10a/10b CDC chain: optional domain-A launch register plus a two-flop destination synchronizer. Generic width and stage count. Used by `DIV_UNIT` (operands, enable, busy) and by `INTERRUPT_CTRL` (KEY1–3). |

### 1.5 GPIO

| File | Role |
| --- | --- |
| `GPO_PORT.vhd` | One Figure 5 output-port register: 8-bit DFF enabled by `CS · MemWrite · lane`. Instantiated seven times (LEDR, HEX0–5). Edge-triggered rather than the figure’s latch (Lab 4 board interface does the same; a single-cycle store is indistinguishable). Reset value 0 is an assumption. Read-back is **not** inside this entity; the MCU places a `BidirPin` on `q_o` as Figure 5 draws. |
| `HEX_DECODER.vhd` | 4-bit binary → 7-segment, active-low for the DE2-115. Lab 4 `hex_decoder.vhd` body, byte-identical. Six instances, one per HEX display, wired to `q_o(3 DOWNTO 0)`. |
| `BIDIRPIN.vhd` | Lab 3 tri-state buffer. Figure 1’s “Bi-directional Data BUS (reminder)” target and Figure 5’s MemRead buffer. Every readable SFR drives the shared read bus through one instance; `Din` is left open. |

### 1.6 Timer, interrupts, divider

| File | Role |
| --- | --- |
| `BASIC_TIMER.vhd` | Figure 7 Basic Timer: 32-bit `BTCNT`, `BTSSEL` prescaler, `BTCL0/1` compare, PWM (`BTOUTMD`/`BTOUTEN`), input capture (`CAPMD`/`CAPISEL`), `BTIFG` pulse. Registers `BTCTL1/2`, `BTCMPR0/1`, `BTCAPR`. PWM modes 0/1 taken from Lab 4 `pwm.vhd`; Lab 4 toggle mode dropped because `BTOUTMD` is one bit (Figure 8). Forum F16: reset clears interface registers, **not** `BTCNT`. Forum F17: period is `BTCL0+1` ticks. |
| `INTERRUPT_CTRL.vhd` | p13/p14 controller: raw request latches, IE mask, IFG as the masked product (forum answer that falsified A6), TYPE encoder, INTR = OR(IFG) AND GIE, INTA handshake. KEY1–3 fire on **release** (prep-session transcript). BTIFG/RXIFG/TXIFG auto-clear on service; KEYiIFG is software W0C only. No Lab 3/4/5 VHDL reference. |
| `DIV_ACCEL.vhd` | Figure 9 unsigned restoring divider on `DIVCLK`. N cycles after Load, `DIVBUSY` falls. Divide-by-zero needs no extra logic: quotient all-ones, residue = dividend (forum F4 + RISC-V). |
| `DIV_UNIT.vhd` | Everything between the core and Figure 9: operand/enable/busy crossings (`SYNC`), signed `div`/`rem` wrapper, MCLK handshake. Exports `done_o`; the core stalls on `DIVstart AND NOT done`, not on `busy`, because busy is still low for several MCLK cycles after issue. Zero-divisor bypasses sign correction so `div(x,0) = -1` for a negative `x`. |

### 1.7 UART (bonus, §6.iv)

| File | Role |
| --- | --- |
| `UART_PERIPH.vhd` | **Ours.** MMIO register layer: `UCTL` / `RXBUF` / `TXBUF` at 0x2018–0x201A, overrun, aggregate `BUSY`, software baud select, RXBUF-read / TXBUF-write pulses that clear RXIFG/TXIFG. Neither supplied UART option has this. |
| `UART_CORE.vhd` | Adaptation of `uart.vhd`: runtime baud (9600 / 115200), **rounded** divider (truncation at 20 MHz / 115200 is +8.5% and will not frame), `>=` reload so a baud switch cannot hang the counter. |
| `UART_TX.vhd` | Cabal transmitter. Semantic change: `PARITY_EN` / `PARITY_EVEN` ports instead of a string generic, so UCTL[2:1] can select 8N1 / 8E1 / 8O1 at runtime. |
| `UART_RX.vhd` | Cabal receiver. Same parity ports, plus `RX_BUSY` (FSM not idle — needed for UCTL[7]) and `PARITY_ERROR`. |
| `UART_PARITY.vhd` | Cabal parity generator. **Body byte-identical** to the original. |
| `UART_DEBOUNCER.vhd` | Cabal RXD debouncer. **Body byte-identical** to the original. |

---

## Part 2 — Changes from `Auxiliary/Lab 5/DUT/RV32IM_sc`

Eleven files exist in both trees. Two are identical. Nine were changed. Eighteen files exist only in the MCU tree.

Comparison method: unified diff of each shared file, then a second pass with comments and blank lines stripped so comment-only edits are not counted as RTL changes.

### 2.1 Unchanged (byte-identical)

| File | md5 match | Why it was left alone |
| --- | --- | --- |
| `MUL16.vhd` | yes | Lab 5 already implements the 16×16 unsigned `mul` Figure 6 / clause 6.iii asks for. `mulh*` is not required by the supplied benchmarks and is not in this datapath. |
| `PLL.vhd` | yes | Wizard output; identical in Hanan’s baseline and both Lab 5 cores. Editing it would destroy the one file whose provenance needs no argument. The clock tree uses `PLL_GEN` instead. |

### 2.2 `cond_compilation_package.vhd`

**Code change:** one new constant.

```
constant G_GEN_INTERRUPT : boolean := True;
```

**Why.** Definition §6’s three PPA tables have a row “MCU with GPIO” (no interrupt capability) and a row “MCU with GPIO and Interrupt Capability”. `G_GEN_INTERRUPT` is the default for `RV32IMscMCU`’s `GEN_INTERRUPT` generic. `False` removes exactly the twelve §6 addresses (PORT_PB, UART, Basic Timer, IE/IFG/TYPE) so row 1 is a real build, not a hand-edit of the netlist. Default stays `True` (the real design). `tools/check_config_defaults.py` asserts that, so a measurement flip cannot be committed by accident.

Everything else — `G_MODELSIM`, TCM sizes, `G_PLL_*` — is the Lab 5 package unchanged. `G_PLL_DIV=2` / `G_PLL_MUL=1` still describe the **unused** `PLL.vhd`. Real MCLK/SMCLK/accelclk ratios live on `CLOCK_TREE` generics.

### 2.3 `const_package.vhd`

Lab 5 already contained the full RV32I mask set plus unused M-extension masks (`INST_DIV`, `INST_MULH`, …). Additions:

| Addition | Why |
| --- | --- |
| `LOAD_OPC`, `AUIPC_OPC`, `LUI_OPC` | Defect 2 and 3. Lab 5 `UTYPE_OPC := "0010111" and "0110111"` evaluates to `auipc` only, so `IDECODE`’s exact-match select dropped `lui`. Values taken from `Auxiliary/Lab 5/DUT/RV32IM_pipeline/const_package.vhd`. `UTYPE_OPC` is kept because `CONTROL` still uses the AND form, which happens to match both. |
| `MEM_B` / `MEM_H` / `MEM_W` / `MEM_BU` / `MEM_HU` | RISC-V funct3 encodings, from the course ISA PDF. `CONTROL` already detected lb/lh/… and discarded the width; these constants carry it to `DMEMORY`. |
| `DATA_ADDR_WIDTH`, `SFR_CS_NUM`, `CS_*`, `SFR_LANE_MASK` | MMIO map. Every address comes from `io_map.s` (all four copies agree), cross-checked against definition §5/§6. Lane masks follow which bytes of each SFR word are actually mapped. |
| `INST_RETI := 32x"20067"` | Exact encoding of `jalr zero,0(tp)` from `io_map.s`. Full 32-bit compare, no mask: any other `jalr` is not a return from interrupt. |

No Lab 5 mask constant was changed.

### 2.4 `CONTROL.vhd` — three functional additions, one ISA repair

**Repair (defect 1).** Lab 5 as-submitted:

```
ALU_AND WHEN and_w or ori_w ELSE
ALU_OR  WHEN or_w  or ori_w ELSE
```

`ori_w` appears twice; the earlier `ALU_AND` arm wins, so `andi` writes 0 and `ori` computes AND. Hanan’s own `Auxilary/DUT/CONTROL.VHD` is already `and_w or andi_w`. Repair transcribed from the Lab 5 pipeline `CONTROL.vhd:147`:

```
ALU_AND WHEN and_w or andi_w ELSE
ALU_OR  WHEN or_w  or ori_w  ELSE
```

**New ports (defaults not needed — the core always connects them):**

| Port | Why |
| --- | --- |
| `MemOp_ctrl_o` | Phase 3B. CONTROL already had `lb_w`…`sh_w` and threw them away. Byte-addressed MMIO in the final-project benchmarks (`sw` to 0x2005, etc.) needs the width at DTCM. |
| `DivStart_ctrl_o`, `DivSigned_ctrl_o`, `DivRem_ctrl_o` | Phase 7B2 / Figure 3 `DIVstart`. The four encodings were already in `const_package`; Lab 5 never decoded them. `DivStart` is a **level** (combinational decode stays asserted for the whole stall). Mask `0xFE00707F` includes funct7, so `div` (funct3=100) cannot alias `xor`. |
| `Reti_ctrl_o` | Phase 9B. Exact `instruction_i = INST_RETI`. The `jalr` still executes; this bit only tells the core to restore GIE in hardware (definition p13 rule f). |

`RegWrite` still fires for every R-type, including `div`. The core gates it during the stall so the RF is not written on every wait cycle.

### 2.5 `IDECODE.vhd`

| Change | Why |
| --- | --- |
| Immediate select gains `LOAD_OPC` | Defect 3. Lab 5 (and Hanan’s baseline) had no LOAD arm, so every load used `rs1+0`. Pipeline reference: `IDECODE.vhd:178`. |
| `UTYPE_OPC` split into `AUIPC_OPC` / `LUI_OPC` | Defect 2. Same pipeline file, two select arms. |
| Write-back mux arm `div_result_i when DivSel_ctrl_i` | Figure 3 WBSrc. The core already chose quotient vs remainder, so this mux stays one bit. Ports default `'0'` / zeros so a pre-divider instantiation is unchanged. |
| Side-door writes `RF_q(3)(0)` and `RF_q(4)` | Interrupt protocol: Cycle 1 clears `gp[0]` (GIE), Cycle 2 writes the return PC into `tp`, `reti` sets GIE. Normal write port is idle on those cycles (annulled / `rd=x0`). |
| `gie_o <= RF_q(3)(0)` | Dedicated tap for the controller’s INTR AND-gate. Both RF read ports are owned by `rs1`/`rs2` every cycle. |

Register file structure, `x0` write suppress, and I/S/SB/U/UJ immediate bit packing are Lab 5.

### 2.6 `EXECUTE.vhd` — three ISA repairs, no new ports

Port list identical to Lab 5. Body:

| Defect | Lab 5 | MCU | Why / source |
| --- | --- | --- | --- |
| 6 — branch/`jal` displacement truncated one bit | `sign_extend_i(PC_WIDTH-3 DOWNTO 0) & '0'` | `sign_extend_i(PC_WIDTH-2 DOWNTO 0) & '0'` | Immediate bit 11 was dropped; reachable range halved to ±2 KiB. Pipeline `EXECUTE.vhd:181`; independently Ori’s `EXECUTE.VHD:81`. |
| 5 — `sltu`/`bltu`/`bgeu` compared signed | `ain_w < bin_w` under `STD_LOGIC_SIGNED` | `('0' & ain_w) < ('0' & bin_w)` | Zero-extend to 33 bits so the signed package gives the unsigned answer without changing the library (which would disturb `slt`/`blt`/`bge`). Pipeline `EXECUTE.vhd:196-197`. |
| 4 — `sra` ≡ `srl` | `brl_shr_pad_r <= 32x"FFFF"` | `brl_shr_pad_r <= (OTHERS => '1')` | VHDL-2008 `32x"FFFF"` is `0x0000FFFF`, so bit 31 is `'0'` and arithmetic right shift never sign-fills. Pipeline uses `(others => '1')`. |

`MUL16` instantiation and the rest of the ALU case statement are Lab 5.

### 2.7 `IFETCH.vhd`

| Change | Why |
| --- | --- |
| `jalr_target_w <= alu_res_i(PC_WIDTH-1 DOWNTO 1) & '0'` | Defect 7. RV32I requires `pc ← (rs1+imm) & ~1`. Lab 5 took `alu_res_i` unmasked. Pipeline `RV32IM_PIPE_CORE.vhd:190`; Ori `RV32IM_CORE.vhd:225`. |
| `PCHold_i` (default `'0'`) | Figure 3 `PCHold`. During `div`/`rem` the PC must not advance, so the same instruction is re-fetched and `DIVstart` stays asserted. Also used for interrupt Cycle 1. |
| `IntrVec_ctrl_i` / `intr_vector_i` | Interrupt Cycle 2: next PC is `Mem[TYPE]` (definition p15 “emulate load + jalr”). Highest priority after reset in the next-PC mux, before hold / jalr / branch. |

ITCM `altsyncram` generics, word-granularity address slice, and the `rst_q` hold flop are Lab 5. The comment calling `rst_q` “synchronization” is inherited; it is a single flop with async preset, **not** a two-flop CDC (`SYNC.vhd` is the real synchronizer).

### 2.8 `DMEMORY.vhd`

Lab 5 wrote and returned the full 32-bit word on every access. `CONTROL` detected `lb`/`sb`/… and discarded the width. Final-project software addresses byte-resolution MMIO; without this, `sb`/`sh` corrupt neighbouring bytes and `lb`/`lh` return the whole word.

**No direct course reference** for `byteena_a`. Ten `altsyncram` instantiations in the supplied tree; none use `byteena_a` / `byte_size` / `width_byteena_a`. The identifiers come from Intel’s megafunction interface (general knowledge, not course material). Read-modify-write through the unregistered `q_a` was rejected: it is a combinational loop through the M9K, and same-address read-during-write is undefined.

| Addition | Why |
| --- | --- |
| `MemOp_ctrl_i`, `byte_sel_i` | Width and byte offset. Word address to the RAM still drops A1..A0; those bits select the lane here. |
| `dtcm_cs_i` (default `'1'`) | Phase 5B. Without it, every store to 0x2000 also writes DTCM word 0 (the RESET vector). See `ADDR_DECODER.vhd` header for the alias table. Default `'1'` keeps Lab 5 behaviour when the core is instantiated without a decoder. |
| Lane replication + `byteena_a` | Store only the addressed byte/half. |
| Extract + sign/zero extend | Load `lb`/`lbu`/`lh`/`lhu`. |
| Simulation-only misaligned-half warning | RV32I would trap; this core has no trap mechanism. Misaligned half-word aligns down. Reported so a benchmark that depends on it cannot pass quietly. |

### 2.9 `RV32IM_CORE.vhd` — largest inherited-file change

Lab 5 core (264 lines): PLL generate, KEY0 invert when `MODELSIM=0`, five submodules, clock-cycle counter, SignalTap copies.

MCU core (614 lines) keeps the five-submodule skeleton and the counter. Structural changes:

| Change | Why |
| --- | --- |
| **PLL generate removed.** `mclk_w <= clk_i`. | Figure 1 puts the Clock Tree at MCU level. The core is a consumer of `mclk`, not a producer. Internal PLL would make a second, untracked clock domain the peripherals could not share. |
| **Reset invert removed.** `rst_i` is already active-high. | Polarity is a board fact (`KEY0`). Lab 4 inverts at the board top. Tying invert to `MODELSIM` made “forgot to set the generic” both skip the PLL **and** invert reset, so the core never left reset. `RST_ACTIVE_LOW` on `RV32IMscMCU` is independent. |
| `divclk_i` (default `'0'`) | Figure 3 divider on its own clock. Default keeps pre-divider testbenches elaborating; the unit stays idle. |
| Data-bus master ports `dbus_addr_o` / `dbus_wdata_o` / `dbus_MemRead_o` / `dbus_MemWrite_o` | Figure 1: Control/Address/Data leave the CPU box. These are **functional**, not the SignalTap copies — those must be removable via `GEN_DEBUG_PORTS` without breaking the bus. Address is the **byte** address (A13 and A1..A0), not the word address the RAM uses. |
| `dtcm_cs_i`, `dbus_rdata_i` (defaults `'1'` / zeros) | Decoder tells the DTCM when it is selected; SFR loads come back on `dbus_rdata_i`. Defaults reproduce Lab 5 (every access is DTCM, read-back is zero). |
| Region mux `dtcm_data_rd_w <= dtcm_rd_w WHEN dtcm_cs_i ELSE dbus_rdata_i` | Load write-back from DTCM or MMIO. A mux, not a tri-state: Figure 5 draws the tri-state at the peripheral. |
| `DIV_UNIT` instance, `pc_hold_w`, gated RegWrite/MemWrite | Figure 3. Stall = `DIVstart AND NOT done`. Write enables gated so a 32-cycle divide does not write the RF 32 times. |
| Interrupt FSM `I_IDLE / I_CYC1 / I_CYC2` | Definition p15. Accept cycle: INTA low, current instruction completes, PC holds the return address. Cycle 1: GIE cleared, TYPE captured from the data bus, PC held, fetched instruction annulled. Cycle 2: DTCM address hijacked to `TYPE[7:2]`, that word becomes next PC, `tp` gets the return address. Accept blocked while `div_start` or `div_busy` (forum F13). |
| `dtcm_wren_o` | Observation of the gated RAM write enable. |

`MODELSIM` generic remains on the entity (ITCM/DTCM path behaviour and testbench overrides) but no longer selects a PLL.

### 2.10 `aux_package.vhd`

Lab 5 declared `RV32IM_CORE`, `Ifetch`, `Idecode`, `control`, `Execute`, `dmemory`, `PLL`, `MUL16`.

MCU adds declarations for every new entity (`RV32IMscMCU`, `clock_tree`, `pll_gen`, `sync`, `addr_decoder`, `gpo_port`, `hex_decoder`, `BidirPin`, `basic_timer`, `interrupt_ctrl`, `div_accel`, `div_unit`, UART set) and extends the inherited component ports to match the new signals (`MemOp`, `PCHold`, `DivStart`, `dtcm_cs`, `intr`/`inta`, …).

No behaviour lives here. A missing declaration is a compile error, not a functional bug.

---

## Part 3 — Files that do not exist in the Lab 5 DUT

These are not “changes to Lab 5 files”. They are new (or copied from another lab / third party) because the final project is an MCU, not a bare core.

| File | Provenance | Why it exists |
| --- | --- | --- |
| `RV32IMscMCU.vhd` | **New.** Pattern: Lab 4 `fpga_hw_interface.vhd` (board-level PLL, KEY invert, structural top). | Definition §3: two structural levels. Figure 1 MCU block. §7 SignalTap generate. |
| `ADDR_DECODER.vhd` | **New.** Structure from Figure 5; map from `io_map.s`. No decoder in any supplied VHDL. | Without A13, MMIO aliases onto DTCM words 0–11, which **are** the interrupt vector table. GPIO `test0.s` writes `PORT_LEDR` / `PORT_HEX1` every loop iteration. |
| `CLOCK_TREE.vhd` | **New.** Placement from Lab 4 board top; three clocks from Figure 1; ratios from forum F6/F7/F8. | Lab 5 had one clock. Figure 1 names three. |
| `PLL_GEN.vhd` | Lab 5 `PLL.vhd` with four wizard constants promoted to generics. | Three `PLL` instances would all be 25 MHz. |
| `SYNC.vhd` | **New.** Figures 10a/10b. Lab 5 `IFETCH` “rst sync” is not a synchronizer. | Divider operands/handshake and KEY CDC. |
| `GPO_PORT.vhd` | **New.** Figure 5 output-port block. Edge-triggered like Lab 4’s interface. | §5 PORT_LEDR / HEX0–5. |
| `HEX_DECODER.vhd` | Lab 4, body byte-identical. | Figure 5 “7-segment encoder”. |
| `BIDIRPIN.vhd` | Lab 3, body byte-identical. | Figure 1 reminder + Figure 5 MemRead buffer. |
| `BASIC_TIMER.vhd` | **New**, PWM skeleton from Lab 4 `pwm.vhd`. | §6.ii / Figures 7–8. No timer RTL in Labs 3–5. |
| `INTERRUPT_CTRL.vhd` | **New.** p13 diagram, p14 map, forum + prep-session. Zero interrupt VHDL in the labs. | §6.v. |
| `DIV_ACCEL.vhd` | **New.** Figure 9. Subtractor is VHDL `-` (forum F5), not Lab 4 `AdderSub`. | §6.iii unsigned engine. |
| `DIV_UNIT.vhd` | **New.** Wraps `DIV_ACCEL` + `SYNC`. | Figure 3/10b + signed `div`/`rem` + stall handshake. |
| `UART_PERIPH.vhd` | **New.** | §6.iv register map (UCTL/RXBUF/TXBUF). Supplied UART has no MMIO. |
| `UART_CORE.vhd` | Cabal `uart.vhd`, adapted (baud, rounding, `>=`). | Clause 6.iv: “code that needs to be adapted”. |
| `UART_TX.vhd` / `UART_RX.vhd` | Cabal, parity made runtime; RX also exports `RX_BUSY` / `PARITY_ERROR`. | Same clause; UCTL[2:1] and UCTL[7]/[5]. |
| `UART_PARITY.vhd` / `UART_DEBOUNCER.vhd` | Cabal, body byte-identical. | Children of the given UART design. |

---

## Part 4 — Behaviour the Lab 5 DUT still has, on purpose

Not every Lab 5 limitation was removed. These remain, and they are not accidents:

| Kept | Reason |
| --- | --- |
| 16×16 unsigned `mul` only (`MUL16`) | Matches Lab 5 Figure 6 / the supplied `mul` tests. `mulh*` encodings exist in `const_package` and are not executed — same as Lab 5 `PROJECT_EXPLANATION.md` §1. |
| Word-granularity TCMs, `G_ADDRWIDTH = 11` (8 KiB) | Lab 5 configuration that the four CPU benchmarks were built against. |
| DTCM on inverted clock | Lab 5 / Lab 3 pattern: `altsyncram` registers address/data, so it must be clocked after the ALU settles. |
| `STD_LOGIC_ARITH` / `STD_LOGIC_SIGNED` in inherited CPU files | Changing the library on `EXECUTE` would re-open defect 5. New files use `numeric_std`. |
| No trap on misaligned access | Core has no exception datapath. Align-down + simulation warning instead. |
| `PLL.vhd` still compiled | Provenance; unused. |

---

## Part 5 — How to verify a given change

| Change class | Test that owns it |
| --- | --- |
| ISA repairs 1–5 | `SIM/RV32IMscMCU/run_isa.do` (directed suite). Repairs 6–7: `repair_check.do` (no supplied benchmark reaches ±2 KiB or an odd `jalr`). |
| Lab 5 cycle counts still 134 / 1514 / 2725 / 2735 through the MCU wrapper | `run_test.do` on the four Lab 5 images. None of those programs form an address ≥ 0x2000, contain `div`, or take an interrupt — so decoder, divider stall, and ISR FSM are idle. |
| Sub-word memory | Directed ISA loads/stores; DMEMORY misalign warning is simulation-only. |
| Address decoder | `tb_addr_decoder.vhd` — exhaustive over all 16384 addresses. |
| GPIO | GPIO `test0` + `tb_mmio_alias`. |
| Timer / PWM / capture | Timer-directed TB + Interrupt-based IO benchmarks. |
| Divider | `tb_div_accel.vhd` exhaustive N=8 (65536 pairs); core-level `div`/`rem` in RV32IM test1 and interrupt tests. |
| Interrupts | Interrupt-based IO test1–test4. |
| UART | UART menu / USART-directed tests. |
| Clock tree / sync | `tb_clock_tree.vhd`, `tb_sync.vhd`. |

If a Lab 5 cycle count moves, the MCU wrapper is no longer transparent: stop and isolate (`GEN_RESET_ON_LOCK`, `dtcm_cs`, gated write enables) before adding more RTL.

---

## File list (complete)

```
DUT/RV32IMscMCU/
  ADDR_DECODER.vhd          NEW     Figure 5 decoder
  aux_package.vhd           CHANGED component declarations
  BASIC_TIMER.vhd           NEW     Figure 7
  BIDIRPIN.vhd              NEW     Lab 3 copy
  CLOCK_TREE.vhd            NEW     Figure 1
  cond_compilation_package  CHANGED +G_GEN_INTERRUPT
  const_package.vhd         CHANGED opcodes, MEM_*, MMIO map, INST_RETI
  CONTROL.vhd               CHANGED andi/ori repair; MemOp; div; reti
  DIV_ACCEL.vhd             NEW     Figure 9
  DIV_UNIT.vhd              NEW     CDC + signed wrapper
  DMEMORY.vhd               CHANGED byteena, sub-word, dtcm_cs
  EXECUTE.vhd               CHANGED defects 4, 5, 6
  GPO_PORT.vhd              NEW     Figure 5 GPO
  HEX_DECODER.vhd           NEW     Lab 4 copy
  IDECODE.vhd               CHANGED defects 2, 3; div WB; GIE/tp
  IFETCH.vhd                CHANGED defect 7; PCHold; vector
  INTERRUPT_CTRL.vhd        NEW     p13/p14
  MUL16.vhd                 IDENTICAL
  PLL.vhd                   IDENTICAL (unused)
  PLL_GEN.vhd               NEW     parameterized PLL
  RV32IM_CORE.vhd           CHANGED clock consumer, bus, div, ISR FSM
  RV32IMscMCU.vhd           NEW     MCU top
  SYNC.vhd                  NEW     Figures 10a/10b
  UART_CORE.vhd             NEW     adapted Cabal top
  UART_DEBOUNCER.vhd        NEW     Cabal copy
  UART_PARITY.vhd           NEW     Cabal copy
  UART_PERIPH.vhd           NEW     MMIO layer
  UART_RX.vhd               NEW     adapted Cabal RX
  UART_TX.vhd               NEW     adapted Cabal TX
```
