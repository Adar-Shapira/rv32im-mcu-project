# Handover: rewrite LAB5 report (`Report_lab5`)

**Audience:** Claude (or any writer) producing a new `DOC/Report_lab5.docx` / `.pdf`  
**Authors:** Adar Shapira 209580208, Yehonatan Dadkha 211468582  
**Course:** מעבדת ארכיטקטורת מעבדים מתקדמת ומאיצי חומרה, 361.1.4693  
**Due:** 23.08.2026  
**Workspace:** `c:\Users\Adar\Documents\VHDL Lab\Lab5`

---

## 0. Mission

The existing report (`DOC/Report_lab5.docx` + `DOC/Report_lab5.pdf`) is a **good Hebrew academic draft of the OLD pipeline**. After that draft, the design was brought in line with lab Figures 7–8:

- Multiplier split across EX (`MULT_1`) and MEM (`MULT_2`)
- Separate `WRITEBACK` stage module
- Figure 8 top ports: per-stage PC/instruction, `STRIGGER_o`, 16-bit `STCNT`/`FHCNT`
- New ModelSim / SignalTap captures and new Quartus PPA for the pipeline

**Write a new report** that keeps the structure, Hebrew style, and Part-1 (single-cycle) content of the old report, but updates **every pipeline claim, table, caption, and screenshot** to the current design.

Do **not** invent waveforms or PPA numbers. Use only the files listed here. If a counter must be read off a screenshot, say so explicitly in the report (or read the PNG/JPEG yourself).

---

## 1. Sources of truth (read these)

| What | Path |
|---|---|
| Old report (style + SC content to reuse) | `DOC/Report_lab5.pdf` |
| Lab assignment extract | `Auxilary/_lab5_extract.txt` |
| Lab Figure 7 (5-stage uArch, split mul) | `Auxilary/_fig7_img_0.png` |
| Lab Figure 8 (top entity / debug ports) | `Auxilary/_fig8_img_0.png` |
| Folder map / HDL blurbs | `DOC/readme.txt` |
| Pipeline top | `DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd` |
| Pipeline stages | `IFETCH.vhd`, `IDECODE.vhd`, `CONTROL.vhd`, `EXECUTE.vhd`, `DMEMORY.vhd`, `WRITEBACK.vhd` |
| Split mul | `DUT/RV32IM_pipeline/MULT_1.vhd`, `MULT_2.vhd` |
| Hazard / forward | `HAZARD_UNIT.vhd`, `FORWARD_UNIT.vhd` |
| SC mul (unchanged) | `DUT/RV32IM_sc/MUL16.vhd` |
| Section 5 images (**use all 29**) | `Screenshots/pre/` |
| Pipeline RTL + new PPA | `Screenshots/Quartus/Pipeline/` |
| SC area (unchanged) | `Screenshots/Quartus/SC/area.png` |

**Leftover — do not document as part of the pipeline:**  
`DUT/RV32IM_pipeline/MUL16.vhd` exists but is **not instantiated**. Pipeline mul is only `MULT_1` + `MULT_2`.

---

## 2. Language and style

- Write the report in **Hebrew**, same academic tone as the old PDF (mixed Hebrew + English identifiers).
- Keep the old section outline (1 … 8). Do not invent a new chapter structure.
- Number **every** figure and table. Captions **below** the figure/table (assignment clause 9.e).
- Caption figures in Hebrew with English signal/file names in `monospace` or as in the old report (`CLKCNT_o`, `STRIGGER_o`, …).
- TOC with page numbers.
- Title page: same names, IDs, course, date 23.08.2026.
- Assignment clause 9 required items:
  - a. Top-level block diagrams (SC + pipeline Figure 8)
  - b. RTL Viewer results (both cores)
  - c. Three PPA tables of clause 7 + Quartus screenshots
  - d. Short HDL file descriptions
  - e. Numbered figures/tables, captions below
  - f. Elaborated analysis + waveforms for **test1–test4**

---

## 3. What stayed the same (reuse from old report)

**Part 1 / single-cycle is still valid.** Do not rewrite §3 architecture unless you are fixing wording.

- Top: `RV32IM_CORE`
- Five modules: `IFETCH`, `IDECODE`, `CONTROL`, `EXECUTE`, `DMEMORY`
- Mul: **`MUL16`** in EX, `RESULT = P0 + ((P1+P2)<<8) + (P3<<16)`
- DTCM written on `not(clk)` → half-cycle critical path
- `G_MODELSIM`, 8 KiB TCM, `G_WORD_GRANULARITY = True`, PLL 50×1/2 → **25 MHz** core clock
- Board: DE2-115, `EP4CE115F29C7`, Quartus 21.1.0 Lite, ModelSim TB period **100 ns**
- SC PPA (Fitter 15 Jul 2026) — **keep these numbers:**

| | SC |
|---|---|
| Logic elements | 3,120 |
| Registers | 1,279 |
| I/O pins | 270 |
| Embedded memory bits | 131,072 |
| Embedded 9-bit multipliers | 4 |
| PLLs | 1 |
| fmax | 26.81 MHz |
| Critical path | ITCM → IDECODE muxes → ALU → DTCM address reg; Latch Clock **INVERTED**; tpath 18.555 ns; `fmax = 1/(2·tpath) ≈ 26.8 MHz` |
| fMCLK | 25 MHz |
| Total / static / dynamic / I/O power | 275.98 / 102.39 / 22.93 / 150.67 mW |

There is **no new SC fmax/power PNG**. Keep old Figures 44, 46, 48 from the current docx if they are still in that file; otherwise say “same compilation as Table 10 SC row” and keep `Screenshots/Quartus/SC/area.png` for area.

Golden-model result (both cores, all four tests): DTCM identical to RARS and to each other, 1024 words. **Keep Table 9.**

IPC formula (unchanged):

```
STRIGGER = (IF_PC word-address == BPADDR_i)
IPC = [CLKCNT − (STCNT + 4 + depth·FHCNT)] / CLKCNT
depth = 3
```

Implementation of STRIGGER in VHDL (byte PC → word):

```vhdl
STRIGGER_o <= '1' WHEN (if_pc_w(PC_WIDTH-1 DOWNTO 2) = bpaddr_q) ELSE '0';
```

BPADDR from SW7–SW0, registered. KEY0 = reset.

---

## 4. What MUST change (old report is wrong here)

### 4.1 Pipeline multiplier (biggest architectural error in the old text)

Old text: one `MUL16` in EX, full 32-bit result in the EX cycle.

**Current (lab Figure 7):**

| Stage | File | Role |
|---|---|---|
| EX | `MULT_1.vhd` (`multiplier_1`, instance `MUL1`) | Four 8×8 products of the low 16 bits of the **forwarded** ALU operands → `p0_o..p3_o` (16-bit each) |
| EX/MEM | `EXECUTE.vhd` | Latches P0–P3 + `Mul` control |
| MEM | `MULT_2.vhd` (`multiplier_2`, instance `MUL2`) | `res_o = P0 + ((P1+P2)<<8) + (P3<<16)` |
| MEM | `DMEMORY.vhd` | `mem_result_w <= mul_res_w WHEN Mul_ctrl_i='1' ELSE alu_res_i` |
| Forward from MEM | `mem_forward_data_o <= mem_result_w` | So a `mul` consumer in the next instruction **does** get the result via FWD_MEM; no extra stall |
| WB | `wb_alu_res` already holds ALU **or** mul | `WRITEBACK` mux has **three** inputs only: PC+4 / alu-or-mul / DTCM load |

Quartus still reports **4** embedded 9-bit multipliers (the four 8×8 in `MULT_1`).

### 4.2 Write-back is its own module

Old Table 4: WB mux “inside `IDECODE.vhd`”.

**Current:** `WRITEBACK.vhd` is the Figure 7 WB mux. `IDECODE` still has the 32×32 RF, ID/EX register, and same-cycle RF read bypass from `wb_write_data_i`.

### 4.3 Figure 8 top ports (old `BPTRIGGER` / 8-bit counters / mixed debug)

Pipeline entity `RV32IM_PIPE_CORE` ports:

**Inputs:** `rst_i`, `clk_i`, `BPADDR_i[7:0]`

**Outputs:**

- `CLKCNT_o[15:0]`
- `IFpc_o`, `IFinstruction_o`
- `IDpc_o`, `IDinstruction_o`
- `EXpc_o`, `EXinstruction_o`
- `MEMpc_o`, `MEMinstruction_o`
- `WBpc_o`, `WBinstruction_o`
- `STRIGGER_o`  ← **not** `BPTRIGGER_o`
- `FHCNT_o[15:0]`, `STCNT_o[15:0]`  ← **16-bit**, not 8-bit

Pin count **284** = exactly these ports (`5×(13+32) + 16+16+16+8+1+1+1`). Old report’s 297 pins and the bullet “extra pins are stall_o/flush_o/BPTRIGGER” are wrong. `stall_w`/`flush_w` are **internal**.

### 4.4 STCNT policy

Old: STCNT increments every cycle with `stall='1'`.

**Current** (`RV32IM_PIPE_CORE.vhd`): increment only if `stall_w='1' and flush_w='0'`. A stall that coincides with a MEM redirect is not counted (flush already costs `depth=3` in the IPC equation). Flush still has priority in `IFETCH` next-PC mux.

### 4.5 Observation waves

Old §5.3 said: one `pc_o` is IF, `instruction_o` is ID, `alu_res_o` is MEM, …  
**Obsolete.** The pipeline TB/`golden.do` expose **five** PC/instruction pairs plus `STRIGGER_o`. ModelSim end-of-run shots also show `PIPE_CTRL` (`stall_w`, `flush_w`, `redirect_addr_w`, `forward_a/b`) and `MUL_STAGE1` / `MUL_STAGE2`.

### 4.6 Global string replacements

| Never write (pipeline) | Write |
|---|---|
| `BPTRIGGER_o` | `STRIGGER_o` |
| `MUL16` in EX of the pipeline | `MULT_1` (EX) + `MULT_2` (MEM) |
| WB mux in `IDECODE` | `WRITEBACK.vhd` |
| STCNT/FHCNT 8-bit | 16-bit |
| Pipeline fmax 41.84 MHz | **51.7 MHz** |
| Pipeline 3,384 LE / 1,696 regs / 297 pins | **3,538 / 1,877 / 284** |
| Pipeline power 299.10 mW | **292.21 mW** |

Keep `MUL16` **only** in §3 / Tables 2–3 (single-cycle).

---

## 5. Section-by-section writing plan

### §1 Aims — keep

Four bullets from the assignment (design RISC-V CPU; 5-stage pipe with full forwarding + combinational hazard check; CPU vs MCU; FPGA M9K memories). Harvard ITCM/DTCM.

### §2 System — keep, small edits

- Structural VHDL, not behavioral monolith.
- Table 1 tools: unchanged.
- `cond_compilation_package`: `G_MODELSIM`, 8 KiB, word granularity, PLL 2/1 → 25 MHz.

**Figure 1:** system = core + ITCM + DTCM. Reuse old Figure 1 if still accurate.

### §3 Single-cycle RV32IM — keep almost verbatim

Figures 2–12 (uArch, submodules, MUL16, SC RTL) can stay if they are still in the docx. No new SC RTL PNGs were captured.

Table 2 (I→IM changes) and Table 3 (SC HDL list) stay.

### §4 Pipelined RV32IM — rewrite the architecture pages

**Opening:** elevate the §3 core to a 5-stage scalar pipe. Clock is now the slowest **stage**, not the full SC path.

**Figure 13:** use lab Figure 7: `Auxilary/_fig7_img_0.png`  
Caption: מיקרו־ארכיטקטורת Pipelined RV32IM (MULDIV partial) בת חמישה שלבים. כופל 16 ביט מפוצל: שלב 1 ב-EX, שלב 2 ב-MEM.

#### Table 4 — replace with this map

| # | Stage | VHDL | In this stage | Pipe register at end |
|---|---|---|---|---|
| 1 | IF | `IFETCH.vhd` | PC, PC+4, redirect mux, ITCM | IF/ID |
| 2 | ID | `IDECODE.vhd` + `CONTROL.vhd` | Decode, RF read, immediates, RF bypass | ID/EX |
| 3 | EX | `EXECUTE.vhd` + `MULT_1.vhd` | Forwarding muxes, ALU, **four 8×8 products**, branch adder, `brTaken` | EX/MEM (incl. P0–P3, `Mul`) |
| 4 | MEM | `DMEMORY.vhd` + `MULT_2.vhd` | DTCM, **combine mul**, mux ALU/mul, resolve branch/jal/jalr | MEM/WB |
| 5 | WB | `WRITEBACK.vhd` | Mux PC+4 / ALU-or-mul / load data | — |

RF is read in ID, written in WB; bypass in `IDECODE` when WB `rd` matches ID `rs1`/`rs2`.

#### §4.2 Forwarding

`FORWARD_UNIT.vhd` compares EX `rs1`/`rs2` vs EX/MEM and MEM/WB destinations (`RegWrite=1`, `rd≠x0`). EX/MEM has priority (newer writer wins).

| Code | Name | Source | When |
|---|---|---|---|
| `00` | FWD_NONE | ID/EX RF value | no RAW |
| `10` | FWD_MEM | **`mem_forward_data_o`** (ALU **or** `MULT_2` result, combinational in MEM) | distance 1 |
| `01` | FWD_WB | `WRITEBACK.write_data_o` | distance 2 |

Do **not** say FWD_MEM is “always the ALU field of EX/MEM”. For `mul` the EX/MEM ALU field is not the product; the product is made in MEM.

#### §4.3 Load-use / HAZARD_UNIT

Unchanged equation:

```
stall = ex_MemRead AND (ex_rd ≠ x0) AND (ex_rd = id_rs1 OR ex_rd = id_rs2)
```

Effects: freeze PC+IF/ID; bubble ID/EX; load continues. One cycle is enough; then FWD_WB. Flush overrides stall.

#### §4.4 Control hazards

Unchanged: resolve in **MEM**, flush depth **3** (IF/ID, ID/EX, EX/MEM). Redirect = branch/jal adder or ALU (`jalr`). Flush beats stall.

#### §4.5 Debug / SignalTap

**Figure 17:** use lab Figure 8: `Auxilary/_fig8_img_0.png`

Table 6 — replace:

| Signal | Width | Role |
|---|---|---|
| `CLKCNT_o` | 16 | Cycles since reset; IPC denominator |
| `STCNT_o` | **16** | Stall cycles with `stall and not flush` |
| `FHCNT_o` | **16** | Flush/redirect events (one cycle each, depth 3) |
| `BPADDR_i` | 8 | Breakpoint **word** address from SW7–SW0 |
| `STRIGGER_o` | 1 | `IF_PC[PC_WIDTH-1:2] == bpaddr_q` |
| `IFpc_o` … `WBinstruction_o` | 13 + 32 each | Figure 8 observation |

IPC equation as in assignment clause 6.iii.b. Fill = 4 unused cycles; each flush kills 3 younger instructions.

ST depth formula unchanged. Design memory 131,072 / 3,981,312 bits.

#### Table 7 — pipeline HDL list (replace)

| File | Description |
|---|---|
| `cond_compilation_package.vhd`, `const_package.vhd`, `PLL.vhd` | Same role as Part 1. **No `MUL16` in the pipe.** |
| `IFETCH.vhd` | IF + IF/ID. `stall_i` freezes PC+IF/ID; `flush_i` redirects and inserts NOP `0x00000013`; `if_pc_o` for STRIGGER |
| `IDECODE.vhd` | ID + ID/EX. RF write from WB; combinational read bypass |
| `CONTROL.vhd` | Same combinational decoder as Part 1, sits in ID |
| `EXECUTE.vhd` | EX + EX/MEM. Forwarding muxes. Instantiates **`MULT_1`**. Carries P0–P3 and `Mul` ctrl |
| `MULT_1.vhd` | Figure 7 mul stage 1 |
| `DMEMORY.vhd` | MEM + MEM/WB. Instantiates **`MULT_2`**. Muxes mul onto MEM result/forward path |
| `MULT_2.vhd` | Figure 7 mul stage 2 |
| `WRITEBACK.vhd` | WB mux (PC+4 / ALU-or-mul / DTCM) |
| `HAZARD_UNIT.vhd` | Combinational load-use |
| `FORWARD_UNIT.vhd` | `00`/`10`/`01` selects |
| `RV32IM_PIPE_CORE.vhd` | Structural top, MEM resolve, flush depth 3, Figure 8 counters + STRIGGER |
| `aux_package.vhd` | Component declarations |

#### §4.7 RTL Viewer — **replace images** from `Screenshots/Quartus/Pipeline/`

Netlist of `RV32IM_PIPE_CORE` has **9** instances (old report said 8):  
`control:CTL`, `dmemory:MEM`, `Execute:EXE`, `FORWARD_UNIT:FWD`, `HAZARD_UNIT:HZD`, `Idecode:ID`, `Ifetch:IFE`, **`writeback:WB`**, `PLL:\G0:MCLK`.

Old report skipped Figure 20. Use that slot for WRITEBACK.

Suggested figure map (keep 13–18 as uArch / FWD / HZD / Figure 8 / debug; then RTL):

| Fig | File | Caption gist |
|---|---|---|
| 13 | `Auxilary/_fig7_img_0.png` | 5-stage uArch, split mul |
| 14 | `Screenshots/Quartus/Pipeline/rtl_fwd.png` | `FORWARD_UNIT:FWD` |
| 15 | (optional) zoom of FWD hooked to EXE — only if you still have the old fig; else drop and say Figure 24 shows the muxes | |
| 16 | `.../rtl_hzd.png` | `HAZARD_UNIT:HZD` → `stall_o` |
| 17 | `Auxilary/_fig8_img_0.png` | Top + Figure 8 ports |
| 18 | Re-capture of CLKCNT/STCNT/FHCNT/`STRIGGER` in RTL Viewer **if available**; else describe in text (logic is in `RV32IM_PIPE_CORE`, compare `if_pc_w(PC_WIDTH-1 DOWNTO 2)` to `bpaddr_q`) | |
| 19 | `.../rtl_top.png` | Top RTL, 9 instances |
| 20 | `.../rtl_wb.png` | `writeback:WB` |
| 21 | `.../rtl_if.png` | IF: stall/flush/redirect, `if_pc_o` |
| 22 | `.../rtl_id.png` | ID: RF + ID/EX, **no** WB mux |
| 23 | `.../rtl_ctl.png` | CONTROL |
| 24 | `.../rtl_exe.png` | EX: forwarding, ALU, **`mem_mul_p0..p3`**, `mem_Mul_ctrl_o` — **not MUL16** |
| 25 | `.../rtl_mem.png` | MEM: `mul_p*_i`, `Mul_ctrl_i`, `mem_forward_data_o` |
| 26 | `.../rtl_mul1.png` | `multiplier_1:MUL1` (EX) |
| 27 | `.../rtl_mul1_in.png` | **`multiplier_2:MUL2`** (MEM). Filename is misleading. |

### §5 Verification — **delete old Figures 27–41** and insert **all 29** files from `Screenshots/pre/`

#### Filename key (easy to get wrong)

| Pattern | What it actually is |
|---|---|
| `testN_sc_signaltap.jpeg` | **ModelSim** SC, start of run (`/tb_rv32im_sc/...`) |
| `testN_sc_signaltap_quartus.jpeg` | **FPGA SignalTap** SC (`log: Trig @ 2026/08/21 …`) |
| `testN_sc_end.jpeg` | ModelSim SC at `while(1)` = `beq x0,x0,0` = `00000063` |
| `testN_pipe_signaltap.jpeg` | **ModelSim** pipeline start (`/tb_rv32im_pipeline/...`) |
| `testN_pipe_signaltap_quartus.jpeg` | **FPGA SignalTap** pipeline (`log: Trig @ 2026/08/22 …`) |
| `testN_pipe_end.jpeg` | ModelSim pipeline at program end / self-jump |
| `testN_statistics.png` | RARS plugin “Instruction Counter” |
| `test_pipe_mul.jpeg` | ModelSim: `CORE/EXE/MUL1` then `CORE/MEM/mul_res_w` |

Do **not** caption `*_signaltap.jpeg` as SignalTap. It is ModelSim.

#### Table 8 — ModelSim scripts (update wave groups)

`compile.do`, `run_test.do`, `mem_dump.do`, `batch_verify.do` (pipe), `golden.do` / `wave.do`.

Pipeline wave groups in `SIM/RV32IM_pipeline/golden.do` / `wave.do`:

- TOP / STAGES: `IFpc_o` … `WBinstruction_o`, `STRIGGER_o`
- PIPE_CTRL: `stall_w`, `flush_w`, `redirect_addr_w`, `forward_a_w`, `forward_b_w`
- COUNTERS: `CLKCNT_o`, `STCNT_o`, `FHCNT_o` (unsigned)
- MUL_STAGE1: `CORE/EXE/MUL1/{a_i,b_i,p0_o..p3_o}`
- MUL_STAGE2: `CORE/MEM/mul_res_w`, `mem_result_w`
- REGFILE

Stop condition: **do not** halt on decode of the self-jump in the pipe (speculative fetch would fire too early). Halt on a MEM flush whose target equals the redirecting instruction (`target+4 == mem_pc_plus4`), i.e. a self-jump. SC can halt on the decoded `00000063`.

TB clock = **100 ns/cycle** (`13400 ns` ↔ `mclk_cnt=134`).

#### Table 9 — keep (all four tests, both cores, 1024 words, match RARS and each other)

#### §5.3 rewrite: do not cite old cycle windows

Throw away: test1 cycles 46–55 / 59; test2 17–26, 31–40, 38–47, CLKCNT=1914; test3 921–930, 1243–1252, ≈3617; test4 8–17, 913–922, 1834–1843, 2446–2455, ≈3644.

New captures are: **start of run**, **FPGA SignalTap**, **end at `00000063`**, plus RARS mix and one mul-pipeline shot.

**Read CLKCNT / STCNT / FHCNT off the four `*_pipe_end.jpeg` images yourself** and put the exact integers in §5 captions and Table 15. Approximate values seen in review (verify!):

| Test | SC `mclk_cnt` at end | Pipe `CLKCNT` (approx) | Notes |
|---|---|---|---|
| test1 | **134** (`pc=0070`) | ~167 | `flush` to `0070` |
| test2 | **1514** (`pc=0070`) | ~1915 | many stalls |
| test3 | **2725** (`pc=00CC`) | ~3620 | many flushes, STCNT≈0 |
| test4 | **2735** (`pc=004C`) | ~3644–3653 | STCNT=0, many flushes |

#### Suggested new figures 28+ (after RTL 13–27)

Renumber as needed; this is the required **image order**. Use **every** file under `Screenshots/pre/`.

**test1 — basic ops + mul**

| File | Caption / analysis |
|---|---|
| `test1_statistics.png` | RARS Instruction Counter: **133** retired (R 24 / I 71 / S 24 / B 8 / U 6). One less than SC `mclk_cnt=134` because RARS does not count the infinite self-jump. |
| `test1_sc_signaltap.jpeg` | ModelSim SC start: `pc` +4 every cycle, `IPC=1`. |
| `test1_sc_signaltap_quartus.jpeg` | FPGA SC SignalTap: same sequential stream (`0000…003C`). |
| `test1_sc_end.jpeg` | SC end: `pc=0070`, `instruction=00000063`, `Branch_ctrl=1`, `brTaken=1`, **`mclk_cnt_o=134`**. |
| `test1_pipe_signaltap.jpeg` | ModelSim pipe ~CLKCNT=14: five live instructions (`IFpc=0034` … `WBpc=0024`). |
| `test1_pipe_signaltap_quartus.jpeg` | FPGA pipe SignalTap: `STRIGGER_o` pulse at trigger; 5-stage slide. |
| `test1_pipe_end.jpeg` | Pipe end: redirect to `0070`, `flush_w=1`. Quote CLKCNT/STCNT/FHCNT from COUNTERS. |
| `test_pipe_mul.jpeg` | Split mul: EX `MUL1` `a_i=0140`, `b_i=0004`, `p0=0100`, `p2=0004`; **next cycle** MEM `mul_res_w=00000500` (= 0x140×4). This is the evidence that mul is two-stage. |

**test2 — load-use stalls**

| File | Caption / analysis |
|---|---|
| `test2_statistics.png` | RARS **1513** (R 300 / I 807 / S 300 / B 100). |
| `test2_sc_signaltap.jpeg` | ModelSim SC start; later `MemWrite`. |
| `test2_sc_signaltap_quartus.jpeg` | FPGA SC start. |
| `test2_sc_end.jpeg` | SC end: `pc=0070`, `00000063`, **`mclk_cnt=1514`**. |
| `test2_pipe_signaltap.jpeg` | ModelSim pipe start; `STCNT` begins to rise (~cycle 18) — load-use. |
| `test2_pipe_signaltap_quartus.jpeg` | FPGA: `BPADDR_i=0D`, `STRIGGER` at 0, `STCNT` 0→1. |
| `test2_pipe_end.jpeg` | ~191500 ns, CLKCNT≈1915. **This test is the stall-heavy one.** Read STCNT/FHCNT. Old report had STCNT=100, FHCNT=99 — confirm on the new shot. |

**test3 — taken branches / loops**

| File | Caption / analysis |
|---|---|
| `test3_statistics.png` | RARS **2724** (I 66%, B 11%). |
| `test3_sc_signaltap.jpeg` | ModelSim SC start. |
| `test3_sc_signaltap_quartus.jpeg` | FPGA SC start. |
| `test3_sc_end.jpeg` | SC end: `pc=00CC`, `00000063`, **`mclk_cnt=2725`**. |
| `test3_pipe_signaltap.jpeg` | ModelSim pipe start, 5-wide. |
| `test3_pipe_signaltap_quartus.jpeg` | FPGA: `BPADDR_i=0B`, `STRIGGER` at 0. |
| `test3_pipe_end.jpeg` | ~362000 ns, CLKCNT≈3620. Explain control-hazard cost: taken branch = 1 + 3 = 4 cycles vs 1 in SC. Quote FHCNT; STCNT should be ~0. |

**test4 — jalr / calls**

| File | Caption / analysis |
|---|---|
| `test4_statistics.png` | RARS **2734**. |
| `test4_sc_signaltap.jpeg` | ModelSim SC: **`pc` jumps `0028 → 0050`**, instruction `02C300E7` (`jalr`). |
| `test4_sc_signaltap_quartus.jpeg` | FPGA SC: same jump. |
| `test4_sc_end.jpeg` | SC end: `pc=004C`, `00000063`, **`mclk_cnt=2735`**. |
| `test4_pipe_signaltap.jpeg` | ModelSim pipe: IF at `0028`/`02C300E7`, then fetch `0050` after flush. |
| `test4_pipe_signaltap_quartus.jpeg` | FPGA: `BPADDR_i=0A`, `STRIGGER`, `FHCNT` 0→1, **`STCNT=0`**. |
| `test4_pipe_end.jpeg` | Loop `004C–0058`, STCNT=0, high FHCNT. Opposite of test2: flow-control heavy, no load-use. |

**Analysis points to keep (retargeted to new shots):**

- SC vs pipe reading: SC all signals = one instruction; pipe five instructions at once (now obvious from `IFpc`…`WBpc`).
- ModelSim start-of-run and FPGA SignalTap show the **same** instruction hex stream (validation).
- test2 unique large STCNT; test3/test4 unique large FHCNT and STCNT=0.
- End of every test: `00000063` / `brTaken` (SC) or periodic `flush_w` (pipe) for `while(1)`.

### §6 PPA — new pipeline numbers, keep SC

Constraint: 50 MHz on `clk_i`, `derive_pll_clocks`, `derive_clock_uncertainty`. Core clock 25 MHz (`G_PLL_DIV=2`, `G_PLL_MUL=1`).

#### Table 10 Area

| | LE | Registers | I/O | Mem bits | 9-bit mul | PLLs |
|---|---|---|---|---|---|---|
| SC | 3,120 | 1,279 | 270 | 131,072 | 4 | 1 |
| Pipe | **3,538** | **1,877** | **284** | 131,072 | 4 | 1 |

Screenshots:  
- SC area: `Screenshots/Quartus/SC/area.png`  
- Pipe area: `Screenshots/Quartus/Pipeline/area.png` (compiled Fri Aug 21 23:36:22 2026)

#### Table 11 Performance

| | fmax | Critical path | fMCLK |
|---|---|---|---|
| SC | 26.81 MHz | lw/sw path, half-cycle, 18.555 ns, inverted latch clock | 25 MHz |
| Pipe | **51.7 MHz** | **Re-identify from Timing Analyzer.** `critical_path.png` shows a DTCM path (launch INVERTED → `mem_wb_dtcm_data_q`) with slack **14.459 ns** at relationship 20 ns — that is **not** the 51.7 MHz limiter. Period of 51.7 MHz ≈ **19.34 ns**. Likely a full-cycle stage path (ID still the usual suspect: RF 32×32 + CONTROL + immediates + HAZARD into ID/EX). Do **not** copy the old “23.90 ns ID / 41.84 MHz” paragraph unchanged. |

Screenshots:  
- Pipe fmax: `Screenshots/Quartus/Pipeline/fmax.png` (51.7 MHz on `\G0:MCLK|altpll_component|pll|clk[0]`; ignore `altera_reserved_tck`)  
- Pipe timing: `Screenshots/Quartus/Pipeline/critical_path.png`  
- SC fmax/critical: keep old report images if still in the docx

**Theoretical:** `5 × 26.81 = 134.05 MHz`. Actual **51.7 / 134.05 ≈ 38.6%** (old report said 31% of theory and ×1.56 vs SC). New speedup vs SC: **51.7 / 26.81 ≈ ×1.93**.

Why not ×5 (keep the four structural reasons, retune numbers):

1. M9K access is an uncuttable floor in IF and MEM.
2. Inverted-clock DTCM still makes a half-cycle path; it is **no longer** the thing that caps ~42 MHz (51.7 is higher), but it still prevents 134 MHz.
3. Stages unbalanced; ID still heavy. EX is lighter than the old “ALU+full MUL16 in one stage” because combine moved to MEM — this is **why fmax rose 41.84 → 51.7**.
4. Clock-to-Q + setup + uncertainty per stage.

#### Table 12 Power

| | Total | Static | Dynamic | I/O |
|---|---|---|---|---|
| SC | 275.98 | 102.39 | 22.93 | 150.67 |
| Pipe | **292.21** | **102.49** | **31.81** | **157.91** |

Pipe screenshot: `Screenshots/Quartus/Pipeline/power.png`. Confidence: Low (no VCD). Relative comparison still valid.

#### Table 13 deltas (pipe vs SC)

| Metric | Delta |
|---|---|
| LE | +418 (+13.4%) |
| Registers | +598 (+46.8%) |
| I/O | +14 (+5.2%) |
| fmax | +92.8% (×1.93) |
| Total power | +16.23 mW (+5.9%) |
| Dynamic | +8.88 mW (+38.7%) |
| I/O power | +7.24 mW (+4.8%) |
| Static | +0.10 mW |

**Area analysis rewrite:**

- Register growth is the pipeline price (IF/ID, ID/EX, EX/MEM **including 4×16-bit mul products**, MEM/WB) + 16-bit STCNT/FHCNT + BPADDR.
- LE growth is forwarding, hazard, redirect, `WRITEBACK`, `MULT_2` adders — still much smaller % than registers.
- Memory bits identical (2×8 KiB).
- 4 embedded multipliers in **both** cores.
- Extra pins = Figure 8 observation ports (list them), **not** `stall_o`/`flush_o` as top outputs.

**Power analysis:** static ~identical (~3% LE of the chip). Dynamic up with extra registers. I/O still dominates because Figure 8 dumps five instruction buses off-chip; a production chip would not.

### §7 IPC

#### Independent instruction counts

| Test | RARS (statistics PNG) | SC `mclk_cnt` (IPC=1) |
|---|---|---|
| test1 | 133 | 134 |
| test2 | 1513 | 1514 |
| test3 | 2724 | 2725 |
| test4 | 2734 | 2735 |

Use SC as the assignment’s “instruction counter” for the IPC equation (one extra = the self-jump). Mention RARS as a cross-check.

#### Table 15

Fill CLKCNT, STCNT, FHCNT from the four `*_pipe_end.jpeg` files, then:

```
retired = CLKCNT − (STCNT + 4 + 3·FHCNT)
IPC = retired / CLKCNT
```

Expect retired ≈ SC count (off-by-one is OK if you sampled mid-flush). Old Table 15 (166/10/6, 1914/100/99, ≈3617/0/297, ≈3644/0/303) is **stale**.

Worked example style (update integers): for test2 the old identity was  
`1914 − (100 + 4 + 3·99) = 1513` vs 1514 SC. Repeat with the new counters.

#### Table 16 wall-clock at each core’s fmax

`Tclk_SC = 1/26.81e6 ≈ 37.30 ns`  
`Tclk_pipe = 1/51.7e6 ≈ 19.34 ns`  ← was 23.90 ns

Recompute `Texec = cycles × Tclk` after locking CLKCNT. Speedup will be about **×1.5**, not the old ×1.17–1.23, because fmax improved.

At **25 MHz both** (current PLL), the pipe is **slower** in wall time (more cycles). Recommendation: raise pipeline PLL toward fmax — with 51.7 MHz headroom you can use **`G_PLL_MUL=1`, `G_PLL_DIV=1` → 50 MHz**, not only the old 40 MHz (`MUL=4`,`DIV=5`) suggestion.

### §8 Conclusions — update numbers

Keep the story; replace quantities:

- Four benchmarks, DTCM = RARS = SC = pipe.
- Four embedded 9-bit multipliers as specified.
- IPC identity holds to ~1 instruction if counters are sampled at the self-jump.
- Pipeline buys time with **registers** (+46.8% vs +13.4% LE).
- Power +5.9% total vs **×1.93** fmax → better perf/W than the old draft claimed.
- Gap to 134 MHz: memory floor, inverted DTCM, unbalanced stages (ID), pipe overhead. Split mul **helped** (41.84 → 51.7).
- Improvements: (1) PLL to ~50 MHz; (2) resolve branches in EX/ID to cut depth 3→2/1; (3) split/balance ID; (4) don’t export Figure 8 buses in a production chip.

---

## 6. Absolute image checklist

Copy/insert these files. Paths relative to repo root.

### Architecture (assignment figures)

- `Auxilary/_fig7_img_0.png`
- `Auxilary/_fig8_img_0.png`

### Pipeline RTL + PPA

```
Screenshots/Quartus/Pipeline/rtl_top.png
Screenshots/Quartus/Pipeline/rtl_if.png
Screenshots/Quartus/Pipeline/rtl_id.png
Screenshots/Quartus/Pipeline/rtl_ctl.png
Screenshots/Quartus/Pipeline/rtl_exe.png
Screenshots/Quartus/Pipeline/rtl_mem.png
Screenshots/Quartus/Pipeline/rtl_wb.png
Screenshots/Quartus/Pipeline/rtl_fwd.png
Screenshots/Quartus/Pipeline/rtl_hzd.png
Screenshots/Quartus/Pipeline/rtl_mul1.png          # MUL1 (EX)
Screenshots/Quartus/Pipeline/rtl_mul1_in.png       # actually MUL2 (MEM)
Screenshots/Quartus/Pipeline/area.png
Screenshots/Quartus/Pipeline/fmax.png
Screenshots/Quartus/Pipeline/critical_path.png
Screenshots/Quartus/Pipeline/power.png
Screenshots/Quartus/SC/area.png
```

### Section 5 — all 29 under `Screenshots/pre/`

```
test1_statistics.png
test1_sc_signaltap.jpeg
test1_sc_signaltap_quartus.jpeg
test1_sc_end.jpeg
test1_pipe_signaltap.jpeg
test1_pipe_signaltap_quartus.jpeg
test1_pipe_end.jpeg
test_pipe_mul.jpeg

test2_statistics.png
test2_sc_signaltap.jpeg
test2_sc_signaltap_quartus.jpeg
test2_sc_end.jpeg
test2_pipe_signaltap.jpeg
test2_pipe_signaltap_quartus.jpeg
test2_pipe_end.jpeg

test3_statistics.png
test3_sc_signaltap.jpeg
test3_sc_signaltap_quartus.jpeg
test3_sc_end.jpeg
test3_pipe_signaltap.jpeg
test3_pipe_signaltap_quartus.jpeg
test3_pipe_end.jpeg

test4_statistics.png
test4_sc_signaltap.jpeg
test4_sc_signaltap_quartus.jpeg
test4_sc_end.jpeg
test4_pipe_signaltap.jpeg
test4_pipe_signaltap_quartus.jpeg
test4_pipe_end.jpeg
```

Reuse from the **old docx** only: SC uArch drawings (Figures 2–5), SC RTL (6–12) if still present, SC fmax/power/critical-path shots, and any SC block diagram you did not recapture.

---

## 7. Deliverable

- Output: `DOC/Report_lab5.docx` (and PDF if you can export).
- Match clause 9. Do not drop RTL Viewer, PPA tables, HDL file table, or test1–test4 waves.
- After inserting images, rebuild the figure number sequence from 1 with **no skipped numbers** (the old PDF jumped 19 → 21).
- Fix every cross-reference (old “Figures 36 and 41” in §7 pointed at test3/test4 pipe-end shots; point at the new pipe-end figures).

---

## 8. Quick “wrong if you copy-pasted the old PDF” test

If the new report still contains any of these, it is not updated:

- `BPTRIGGER`
- Pipeline `MUL16` as the EX module that produces `alu_res`
- “מרבב ה-write-back שבתוך IDECODE”
- Pipeline fmax **41.84 MHz**
- Pipeline LE **3,384** / regs **1,696** / pins **297**
- STCNT/FHCNT width **8**
- Wave analysis that cites SC cycles 46–55 or pipe CLKCNT=1914 as if they were the new screenshots
- Caption calling `rtl_mul1_in.png` “MUL1 internals”
- Caption calling `testN_sc_signaltap.jpeg` “Signal-Tap” (it is ModelSim)
