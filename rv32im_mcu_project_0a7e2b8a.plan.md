---
name: RV32IM MCU Project
overview: >
  Build the RV32IM-based MCU on the structural base established by commit cfc4b4f of
  Adar-Shapira/Lab5 — the revision that follows Hanan's supplied references most closely — rather
  than on the current HEAD, whose last commit introduced three deviations that must not be carried
  forward. Fix the five decode defects present in every revision, add the peripherals from the
  Figure 1 architecture, and verify against the supplied benchmarks with self-checking testbenches.
isProject: false
---

# RV32IM MCU — Project Plan (rev 2)

**Supersedes the previous roadmap.** That version was written before the reference material had been
surveyed and before the Lab 5 git history was read. It assumed components would be written from
scratch that already exist, under-scoped the ones that do not, and treated the current Lab 5 HEAD as
the base to build on. All three assumptions were wrong.

**Reference for the base:** `https://github.com/Adar-Shapira/Lab5`, commit **`cfc4b4f`**
(15 Jul 2026, "Initial commit"). Verified: it is the revision that follows Hanan's supplied
references most closely.

---

# 0. NEW — the Lab 5 reference was replaced on 2026-08-23

> `Auxiliary/Lab 5 - as submitted/` is no longer the tree this plan was written against. It was
> replaced with the **actual final Lab 5 submission**, and the change is large enough that several
> earlier conclusions in this file are now out of date. Read this section before anything else.

**What is in the folder now** — 341 files, including three things that were not there before:

| New | What it is |
| --- | --- |
| `209580208_211468582/` | The real submission staging directory, with the `.sof` files and the `.stp`. Byte-identical to the top-level `DUT/`, `TB/`, so it is a copy, not a variant. |
| `Auxilary/RV32I/`, `Auxilary/Benchmarks/`, `Auxilary/Ori/` | Hanan's distribution, restructured into proper subfolders — plus a folder called `Ori` that is new. See the provenance warning below. |
| `PROJECT_EXPLANATION.md`, `DOC/HANDOVER_Report_lab5.md` | 1,400 and 640 lines of prose describing the design, the measured numbers and the report rewrite. The most useful documents in the whole reference tree. |

## 0.a The single most important finding: the pipeline is the repaired core

**The pipelined core repairs all of the single-cycle core's ISA defects, and it was submitted and
hardware-validated that way.** That changes Phase 3 completely: the repairs no longer have to be
designed by us. Each one is a transcription from a sibling core in the same submission that passed
all four benchmarks against the RARS golden DTCM.

And there are **seven** defects, not five. Two were found in the revised reference and had never been
recorded here:

| # | Defect | Broken at (our tree) | Repaired at (reference pipeline) |
| --- | --- | --- | --- |
| 1 | `andi` decodes as OR; `ori` matches the AND arm first | `CONTROL.vhd:142` | `CONTROL.vhd:147` |
| 2 | `lui` immediate is 0 | `const_package.vhd:27`, `IDECODE.vhd:102` | `const_package.vhd:28-29`, `IDECODE.vhd:181-182` |
| 3 | every load addresses `rs1+0` | `IDECODE.vhd:97-104` | `IDECODE.vhd:178` |
| 4 | `sra` ≡ `srl` | `EXECUTE.vhd:200` | `brl_shr_pad_r <= (others => '1')` |
| 5 | `sltu`/`sltiu`/`bltu`/`bgeu` compare signed | `EXECUTE.vhd:10,81` | `EXECUTE.vhd:196-197` |
| **6 — new** | **branch/`jal` displacement truncated one bit** | `EXECUTE.vhd:66` | `EXECUTE.vhd:181` |
| **7 — new** | **`jalr` does not clear the target's bit 0** | `IFETCH.vhd:93` | `RV32IM_PIPE_CORE.vhd:190` |

Defect 6 in detail, because it is the one nobody would find by running the benchmarks: `IDECODE`
delivers the B/J-type immediate as `imm[12:1]`, so the adder must shift left by one. The
as-submitted slice is `sign_extend_i(PC_WIDTH-3 DOWNTO 0)` = bits 10..0, which **drops immediate bit
11** — byte-offset bit 12 — halving the reachable branch range to ±2 KiB inside a 13-bit, 8 KiB PC.
No supplied benchmark branches that far, so all four still match their golden DTCM. It is latent,
not benign. (The original `-- << 2` comment on that line is also wrong; the code shifts by one,
correctly.)

The reference even ships its own regression for these:
`Auxiliary/Lab 5 - as submitted/SIM/RV32IM_pipeline/directed_isa.do`. Our
`SIM/RV32IMscMCU/repair_check.do` is the single-cycle port of it.

## 0.b The pipeline was rewritten, and our copy was a revision behind

The revised pipeline is a different design from the one Phase 1 imported:

| Changed | From | To |
| --- | --- | --- |
| Multiplier | one `MUL16` in EX | **split**: `MULT_1` (EX, four 8×8 products) + `MULT_2` (MEM, combine) |
| Write-back mux | inside `IDECODE` | its own module, **`WRITEBACK.vhd`** |
| Signal-Tap trigger | `BPTRIGGER_o` | **`STRIGGER_o`** |
| `STCNT_o` / `FHCNT_o` | 8-bit | **16-bit** |
| Observation ports | one `pc_o`/`instruction_o` + datapath signals | **five** per-stage PC/instruction pairs (Figure 8) |
| `stall_o`, `flush_o` | top-level ports | **internal** (`stall_w`, `flush_w`) — observe in the wave window, not on a pin |
| `MUL16.vhd` | instantiated | present but **not instantiated**; removed from our tree |
| `STCNT` policy | every stall cycle | only `stall='1' and flush='0'` |

Our `DUT/RV32IMpipelinedMCU/` has been re-imported and the wrapper, testbench and `.do` scripts
rewritten to match. Details in Phase 3D.

## 0.c Measured numbers from the reference — use these, not the old ones

From `DOC/HANDOVER_Report_lab5.md` §3 and §6. The single-cycle row is unchanged; every pipeline
number moved.

| | Logic elements | Registers | I/O pins | Memory bits | 9-bit multipliers | Fmax | Total power |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Single-cycle | 3,120 | 1,279 | 270 | **131,072** | 4 | **26.81 MHz** | 275.98 mW |
| Pipeline | 3,538 | 1,877 | 284 | **131,072** | 4 | **51.7 MHz** | 292.21 mW |

The old pipeline figures (3,384 LE / 1,696 regs / 297 pins / 41.84 MHz / 299.10 mW) are **stale** —
`HANDOVER §4.6` lists them as the copy-paste tell. Memory bits stay 131,072 in both, which is still
the number that catches a stray SignalTap instance.

## 0.d Provenance warning — `Auxilary/Ori/`

`Auxilary/Ori/DUT/` is a **complete second pipeline implementation** matching the Figure 7 / Figure 8
structure (`FORWARD.vhd`, `STALL.vhd`, `MULT_1`, `MULT_2`, `WRITEBACK`, `RV32IM_CORE` with the exact
Figure 8 port list). What it is has **not** been established from the material:

- It is not mentioned in `DOC/readme.txt`, `PROJECT_EXPLANATION.md`, or `Auxilary/_lab5_extract.txt`.
- Only 2 of its 15 files carry a header, and those are Hanan's `cond_compilation_package.vhd` and
  `const_package.vhd`. Hanan's own files all carry headers; the other 13 have none.
- It differs from Hanan's `Auxilary/RV32I/DUT/` baseline in **every** file, including `PLL.vhd` —
  the one file that was previously md5-identical everywhere.
- It carries the same five original decode defects as the baseline, so it derives from the baseline
  but is not the repair source.
- It uses `STD_LOGIC_ARITH` / `std_logic_unsigned` throughout, a different style from our tree, and
  one comment reads `-- Inverted reset for DE-10 hardware` — **DE-10**, while our tree is DE2-115.

**ANSWERED 2026-08-23 (Yehonatan): it is another student's pipeline, and it may be used as a
reference.** So G-331 is closed, with three consequences that follow from *reference* being the
permission granted:

1. **Read it, cite it, do not ship it.** Under `CLAUDE.md` it ranks below Hanan's supplied code and
   below our own Lab 5, and `Auxiliary/` is reference-only by rule anyway. No line of it goes into
   `DUT/`, and nothing of ours is justified by "Ori does it this way" alone.
2. **It stays where it is, but labelled.** It sits inside a folder called `Auxilary`, which every
   reader will assume the lecturer supplied. This section is that label.
3. **Its real value is as a second opinion**, and it earned that immediately — below.

### What Ori is actually worth to us

**It independently repairs defects 6 and 7, with the identical expressions.** That was checked, not
assumed:

| Defect | Ori | Our pipeline reference |
| --- | --- | --- |
| 6 branch/`jal` displacement | `addr_gen_o <= pc_i(PC_WIDTH-1 DOWNTO 0) + (sign_extend_i(PC_WIDTH-2 DOWNTO 0) & '0');` — `EXECUTE.VHD:81` | identical, `EXECUTE.vhd:181` |
| 7 `jalr` bit 0 | `ex_mem_alu_res_r(PC_WIDTH-1 DOWNTO 1) & '0'` — `RV32IM_CORE.vhd:225` | identical, `RV32IM_PIPE_CORE.vhd:190` |

This matters more than it looks. Defects 6 and 7 are the two that came out of *reading* the RTL
rather than out of a failing test — no supplied benchmark exercises either, and the Phase-2 suite
does not reach them. Two independent implementations arriving at the same two fixes, and at the same
expressions, is real evidence that they are genuine defects and that the repairs are right.

It also tells us *why* those two: both are control-flow defects, and a pipeline exercises control
flow far harder than a single-cycle core does. Whoever wrote Ori almost certainly hit them.

**It still carries defects 2, 3 and 4** — `UTYPE_OPC := "0010111" and "0110111"`, no `LOAD_OPC` arm,
`brl_shr_pad_r <= 32x"FFFF"` — so it inherits the same baseline and confirms the provenance finding:
those are Hanan's, not ours.

**It does NOT implement sub-word access.** No `byteena`, no `MemOp`, nothing in `DEMEMORY.VHD`. With
Ori now permitted and checked, the Phase 3B claim stands with all three trees searched: **no
reference for byte enables exists in any material we have.**

**One place it is worse, worth keeping for the report.** Ori counts stalls unconditionally
(`IF stall_IF_w = '1' THEN st_cnt_r <= st_cnt_r + '1'`, `RV32IM_CORE.vhd:558`), where the revised
LAB5 pipeline counts only `stall AND NOT flush`. A stall coinciding with a MEM redirect is moot — the
flush already costs `depth = 3` in the IPC equation — so counting it double-charges. Ours is right;
this is a concrete example for the IPC discussion.

**Structurally it agrees with us on the things that matter:** branches resolve from the EX/MEM
register, i.e. in MEM, so flush depth is 3 — same equation, same penalty. Our structure is not
idiosyncratic.

## 0.e What else changed that affects the runbook

- **`run_test.do`, `mem_dump.do` and `batch_verify.do` no longer exist in the reference.** They were
  deleted; the reference now ships `compile.do`, `golden.do`, `wave.do` and (pipeline only)
  `directed_isa.do`. Our tree still has its own copies, which is what Phase 0 and Phase 1 use — but
  Phase 0's baseline procedure can no longer be run from the reference folder as written. See the
  note in Phase 0.
- **The single-cycle testbench lost its auto-stop process.** `std.env.stop` on the sentinel is gone,
  so a plain GUI *Run -All* never terminates. The `.do` script owns the stop condition again.
- **The single-cycle core now inverts reset internally**:
  `rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i`. This is decision **D-1** re-introduced. We keep
  polarity in the wrapper's `RST_ACTIVE_LOW` generic instead, and **our core does not invert** — so
  there is no double inversion. Verified.
- `DOC/readme.txt` still says `BPTRIGGER` in two places (lines 103, 211) where the port is now
  `STRIGGER_o`. Reference-internal inconsistency; the RTL is authoritative.

---

# 0. How the two of us work  ·  read this first

**Yehonatan — MacBook.** No simulator, no synthesiser. Writes and reviews VHDL, generates and
analyses memory images, maintains this plan and the `DOC/` documents. Cannot compile or run anything.

**Adar — Lenovo.** Has Quartus and ModelSim, and the board. Runs everything, records the numbers, and
reports back what actually happened.

So every phase splits in two: **prepared** on the Mac, **verified** on the Lenovo. A phase is not
done until Adar's numbers are in this file. Nothing here has ever been compiled.

## 0.1 Getting the code

```
git clone https://github.com/Adar-Shapira/rv32im-mcu-project.git
cd rv32im-mcu-project
git pull                     # before every session
```

> **Yehonatan: the Phase 1 and Phase 2 work is still uncommitted.** 51 files across `DUT/`, `TB/`,
> `SIM/`, `Quartus/`, `tools/` and `DOC/`. Commit and push before Adar starts, or he pulls an empty
> tree.

## 0.2 One-time setup on the Lenovo

| # | What | Detail |
| --- | --- | --- |
| 1 | **Quartus Prime 21.1.0 Lite** | Device support for Cyclone IV E. The projects target `EP4CE115F29C7`. |
| 2 | **ModelSim – Intel FPGA Starter Edition 20.1** | Expected at `C:\intelFPGA\20.1\modelsim_ase`. The version matters: `mem_dump.do` reaches into the precompiled `altsyncram` model's internals (`m_mem_data_a`), which is version-locked. A different ModelSim fails at the dump step, not at compile. |
| 3 | **Python 3** | Only needed to regenerate the ISA test (`tools/gen_isa_test.py`). The generated files are committed, so this is optional at first. |
| 4 | **Stage the benchmark images** | Run the PowerShell block in `DOC/04_baseline_runbook.md` §3 from the repo root. It builds `C:\TestPrograms\Quartus21_1\{app_bin, test1..4\bin, test1..4\RARS}` from files already in the repo. Nothing has to be downloaded. |

Why `C:\TestPrograms\Quartus21_1\` and not a path inside the repo: the RTL hardcodes
`init_file => "C:\TestPrograms\Quartus21_1\app_bin\{ITCM,DTCM}.hex"` at `IFETCH.vhd:64` and
`DMEMORY.vhd:50`. That is the convention Lab 5 already used and it is deliberately left alone until
the submission is staged — changing it now would mean the measured baseline no longer reproduces.

## 0.3 What Adar runs, in order

Two ModelSim sessions get us through everything that is currently prepared. **Stop at the first one
that does not match** and report the numbers — do not carry on.

### Run 1 — Baseline (Phase 0). Proves the tools, not our code.

Working directory: **`SIM\baseline_reference`** — in our tree, not in `Auxiliary`.

The reference folder no longer has scripts to run (§0.e): the replacement deleted `run_test.do`,
`mem_dump.do` and `batch_verify.do`, and there is no `compile.do` for the single-cycle core anywhere
in it — only the pipeline kept one. So `SIM/baseline_reference/` holds replacements that reach into
`Auxiliary/` **read-only**, which keeps the reference byte-for-byte as supplied and puts the `work`
library in our tree.

1. `do compile.do`. Expect **0 errors**, and three "Non-locally static OTHERS choice" warnings on
   `EXECUTE.vhd` — known and harmless.
2. For `N` = 1, 2, 3, 4: set `set N <n>` at the top of `run_test.do`, `do run_test.do`, then
   `do mem_dump.do`.

**No source edit anywhere, including in `Auxiliary`.** The old instruction to set `G_MODELSIM := 1`
by hand is superseded: `tb_RV32IM_sc` declares `MODELSIM` as a generic and forwards it to the core
(`TB/RV32IM_sc/tb_RV32IM_sc.vhd:19,61`), so `run_test.do` passes `-gMODELSIM=1`. That closes G-201 on
the reference side too. It is also now **mandatory**, not merely tidy — the revised reference core
inverts reset when `MODELSIM = 0`, so at the package default the testbench's active-high pulse holds
the core in reset forever, silently.

| Test | `mclk_cnt_o` | stops at | `pc_o` | dump vs `DTCM_testN_MS.mem` |
| --- | --- | --- | --- | --- |
| test1 | **134** | 13.4 µs | `0070` | identical, **2048** words |
| test2 | **1514** | 151.4 µs | `0070` | identical |
| test3 | **2725** | 272.5 µs | `00CC` | identical |
| test4 | **2735** | 273.5 µs | `004C` | identical |

The comparison target changed: diff against the reference's **own captures**,
`Auxiliary\Lab 5 - as submitted\SIM\RV32IM_sc\DTCM_testN_MS.mem`, which are now full 2048-word
dumps (2051 lines with the 3-line mti header) instead of the old 1024. `mem_dump.do` prints the exact
PowerShell command. That full range is what closes **G-204** on the single-cycle side. The RARS
`DTCM.h` goldens stay the architectural truth for Phase 10.

Both `mclk_cnt_o` figures are independently confirmed in writing by two documents inside the new
reference — `PROJECT_EXPLANATION.md` §7 and `DOC/HANDOVER_Report_lab5.md` §5.3 — which is better
evidence than the scripts that were deleted.

Then repeat in `SIM\RV32IM_pipeline` (which does still have its own `compile.do`) and **write down
`CLKCNT_o`, `STCNT_o`, `FHCNT_o` per test** — those three numbers exist nowhere and Phase 11's IPC
check needs them. Expect roughly 170 / 1,918 / 3,623 / 3,651 cycles with stalls 8 / 100 / 0 / 0 and
flushes 8 / 100 / 298 / 304 (`PROJECT_EXPLANATION.md` §8.6 — these include the testbench drain, so
treat them as a range, not a target).

*If the counts do not match:* the environment differs from the one that produced them. Do not start
Run 2. Report the ModelSim version and the transcript.

### Run 2 — Our tree (Phases 1 and 2).

Working directory: `SIM\RV32IMscMCU`

**No source edit.** `run_test.do` and `run_isa.do` both pass `-gMODELSIM=1`, which the testbench
forwards to the wrapper and the core. Quartus keeps the package default of `0` and also needs no
edit. If you ever find yourself editing `cond_compilation_package.vhd` in our tree, something is
wrong — say so.

1. Execute `compile.do`. Expect 0 errors and the same three warnings.
2. **Phase 1:** run `run_test.do` for `N` = 1..4. Expect the **same four counts as Run 1**
   (134 / 1514 / 2725 / 2735). The only change is that `RV32IMscMCU` now sits between the testbench
   and the core, so identical counts prove the new top level is transparent.
   - *An empty `DTCM.mem` means the hierarchical path in `mem_dump.do` is wrong.* It must be
     `/tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a` — the `MCU` level is the new
     wrapper. `mem save` does not report this as an error.
3. **Phase 2 — the "before" measurement.** Run `run_isa.do` with the tree exactly as cloned
   (`G_ISA_REPAIR = FALSE`). Expect **exactly 25 mismatches**, then a `SUMMARY` block.
   - **25 is the pass condition.** These are the known defects; the suite exists to measure them.
   - **0 mismatches means the test never ran** — `isa/ITCM.hex` did not reach `app_bin`.
   - **Any other number is a finding.** A mismatch on a case the listing does not mark `DEFECT` is a
     new bug; a `DEFECT` case that passes means the bug is not where we think. Either way, paste the
     whole `ISA TEST FAIL` list back.
   - Which 25, and the citation for each: `SIM\RV32IMscMCU\isa\listing.txt`.
   - The `SUMMARY` block now prints which configuration it was compiled against and how many
     mismatches that configuration should give, so there is no number to remember.
4. **Phase 3A + 3B — the "after" measurement.** One edit, then two runs.
   - In `DUT\RV32IMscMCU\cond_compilation_package.vhd`, set `G_ISA_REPAIR := TRUE`.
     **This is the one source edit the project asks for, and it is the switch's whole purpose.**
   - Re-run `compile.do` — a package change invalidates everything, so it is a full recompile.
   - `do repair_check.do` → expect **43 of 43 PASS**. Submodule-level proof that each repaired
     expression computes the right value. Against `FALSE` it reports exactly **25** failures and
     names the 18 control checks that must pass either way — so the script itself tells you which
     configuration you compiled.
   - `do run_isa.do` → expect **exactly 9 mismatches**. Not 0. The 9 that remain are the cases
     blocked on open questions, and `run_isa.do` prints the breakdown.
   - Then set it back to `FALSE` before committing, unless we have agreed to flip the default.
5. Repeat step 2 in `SIM\RV32IMpipelinedMCU`. Note this directory was rebuilt for the revised
   pipeline — new file list in `compile.do`, and `golden.do` is now the wave script to prefer.

### Run 3 — Quartus (still Phase 1).

Open `Quartus\RV32IMscMCU\RV32IMscMCU.qpf`, compile.

- The top entity must resolve to `RV32IMscMCU`.
- **The Fitter will warn about unassigned pins. That is correct.** This is the *performance* revision
  and deliberately carries no pin assignments, so the PPA numbers describe the design and not the
  board. The pinned revision comes later, in Phase 14.
- **The number that matters: embedded memory bits must be 131,072** (= 2 × 2048 × 32). If it reads
  **483,328**, a SignalTap instance has crept back in — that was the exact defect in Lab 5 commit
  `8a71ffb`, and avoiding it is why our tree was built from commit `cfc4b4f`.
- Sanity reference, not a target: single-cycle Fmax was **26.81 MHz** on
  `\G0:MCLK|altpll_component|pll|clk[0]`, Slow 1200 mV 85 °C. The wrapper adds a little
  combinational logic, so small movement is expected; a large jump is not.

Then the same for `Quartus\RV32IMpipelinedMCU\RV32IMpipelinedMCU.qpf`.

## 0.4 Where Adar writes the results

Straight into this file, in the phase's own table — Phase 0, Phase 1 and Phase 2 each have a
**"Adar's results"** block waiting. Screenshots go to `Screenshots\ModelSim\` and
`Screenshots\Quartus\`. Commit and push; the numbers are the deliverable, not a side note.

## 0.5 Ownership per phase

| Phase | Prepared by | Verified by | State |
| --- | --- | --- | --- |
| 0 Baseline | — (supplied material) | **Adar** | ready to run |
| 1 Clean structural base | Yehonatan ✔ | **Adar** | ready to run |
| 2 Directed ISA test | Yehonatan ✔ | **Adar** | ready to run |
| 3A Seven ISA repairs | Yehonatan ✔ | **Adar** | ready to run — flip `G_ISA_REPAIR` |
| 3B Byte enables / sub-word | Yehonatan ✔ | **Adar** | ready to run — same switch as 3A |
| 3C `mul` width, `mulh`, `div` | — | — | **blocked on Hanan** (Q6 + mul width) |
| 3D Pipeline re-import | Yehonatan ✔ | **Adar** | ready to run |
| 4 Clock tree / CDC | Yehonatan | Adar | waits on Q2 |
| 5 Bus interface + DTCM | Yehonatan | Adar | |
| 6 GPIO | Yehonatan | Adar | waits on Q5 |
| 7 Divider | Yehonatan | Adar | waits on Q6 |
| 8 Basic Timer | Yehonatan | Adar | waits on Q3, Q4, Q8 |
| 9 Interrupt controller | Yehonatan | Adar | waits on Q7 |
| 10 SC benchmarks | Yehonatan | Adar | |
| 11 Pipeline port | Yehonatan | Adar | needs Phase 0's pipeline counters |
| 12 UART | Yehonatan | Adar | waits on Q1, Q12 |
| 13 Regression | Yehonatan | Adar | |
| 14 Quartus PPA | Yehonatan | **Adar** | six revisions to compile |
| 15 Hardware validation | Yehonatan | **Adar only** | needs the board |
| 16 Report + ZIP | both | Adar checks the clean-room build | |

## 0.6 What Adar can also help with, off the critical path

- **Send Q1, Q2, Q3 to Hanan or the TA** (`DOC/03_open_questions.md`): which board, the three clock
  frequencies, and the 8× `SEC_PERIOD` discrepancy. Each already has a provisional decision so
  nothing is blocked, but answers take time — send early.
- **Answer G-207:** what is already inside the `finalProj` Quartus project on your machine? It exists
  in no local copy and its contents are unknown.
- **Answer G-208:** the two circled Quartus settings in the photos from 19 Aug — "Use smart
  compilation" and "Advanced Physical Optimization = Off". Were those staff instructions? Both change
  the PPA numbers, so if they are instructions they are requirements and not our choice.
- **Find the DE2-115 expansion-header pin table** (G-504). It is in the Terasic User Manual and in no
  file we have. Needed for the UART pins in Phase 12.

---

# 1. Why commit 1 is the base

The repository has three commits. Their contents were diffed file by file.

| | `cfc4b4f` — 15 Jul | `c1e9e64` — 18 Aug | `8a71ffb` — 19 Aug (HEAD) |
| --- | --- | --- | --- |
| Submodule RTL (`CONTROL`, `IDECODE`, `EXECUTE`, `IFETCH`, `DMEMORY`, `MUL16`, packages) | — | **md5-identical to commit 1** | **md5-identical to commit 1** |
| Reset handling in the core | `rst_i` straight through, as Hanan's `RV32I_CORE.vhd` | unchanged | **`RSTPOL` generate added, welded to `G_MODELSIM`** |
| Testbench | clock + reset only, as Hanan's `tb_RV32I.vhd` | **auto-stop via `std.env.stop` added** | unchanged |
| `.qsf` pin assignments | **none** | none | **added** |
| SignalTap | **none** | none | **`ENABLE_SIGNALTAP ON` + a 4782-line `.stp`, in the same and only revision** |
| ModelSim project files | not committed | **`.mpf` + `.cr.mti` committed** | unchanged |

So no CPU logic was ever changed after commit 1. Everything the later commits did was structural
packaging — and two of those three changes are the wrong shape for the final project.

## 1.1 What commit 3 broke

**D-1 — reset polarity welded into the core, tied to `G_MODELSIM`.**
`RV32IM_CORE.vhd` gained:

```vhdl
RSTPOL:
if (MODELSIM = 1) generate
    rst_w <= rst_i;
else generate
    rst_w <= not rst_i;
end generate;
```

The *intent* is right — KEY0 on the DE2-115 is active-low, and §3 mandates KEY0 as system reset. The
*placement* is wrong twice over. It overloads `G_MODELSIM`, whose job is PLL bypass, so forgetting
the toggle no longer just instantiates a PLL in simulation — it inverts the reset and the core never
leaves reset. And it puts board-level signal conditioning inside the CPU core, which the final
project explicitly forbids by requiring **two** structural levels (§3: "The top level and the RV32IM
core must be structural").

The correct placement already exists in their own earlier work:
`Auxilary/Lab4/DUT/fpga_hw_interface.vhd:38` inverts KEY at the board wrapper and leaves everything
below it polarity-agnostic. Commit 1's core matches Hanan's baseline exactly; keep it that way and
invert in the MCU top.

**D-2 — SignalTap merged into the only Quartus revision.**
Commit 3 set `ENABLE_SIGNALTAP ON`, added `USE_SIGNALTAP_FILE`, wired `acq_clk` to the PLL output and
`acq_trigger_in[0..7]` to `BPADDR_i`, and added the pin assignments — all into the single existing
project. So every subsequent compile measures an instrumented design. This is why the committed
report shows **483,328 embedded memory bits** where the true design uses **131,072**
(= 2 × 2048 × 32). Area, power and Fmax from that build are all contaminated.

§6's three PPA tables must be measured on the design itself, and §7 requires SignalTap pins to be
removable "using a suitable parameter in the generate VHDL statement". Again their own Lab 4 already
has the right pattern: two revisions, `Lab4_Perf` (top = `perf_wrapper`, no pins, SignalTap off,
constrained by `Lab4_perf.sdc`) and `Lab4_HW` (pinned, SignalTap on, `Lab4_hw.sdc`). Commit 1's
`.qsf` is already a clean performance revision — it has no pins and no SignalTap.

**D-3 — build artifacts committed.**
`RV32IM_sc_sim.mpf`, `RV32IM_pipeline_sim.mpf` and both `.cr.mti` files are ModelSim project state.
Commit 1's `.gitignore` did not cover them. §10 forbids "files that are not relevant for compilation
or a result of compilation" in the submission.

## 1.2 What commit 2 got right and we keep

The testbench auto-stop is worth keeping:

```vhdl
monitor_end_of_program : process
begin
    wait until instruction_o = X"00000063" or instruction_o = X"0000006F";
    report "Program finished (while(1) reached) - stopping simulation" severity note;
    std.env.stop;
end process;
```

It makes a run terminate without the Tcl `when` block, and it is the only assertion-shaped construct
anywhere in the students' Lab 5. It becomes the seed of the self-checking testbenches this project
needs.

## 1.3 What commit 1 does **not** fix

Commit 1 is a clean **structure**, not a correct **core**. All five decode defects are present in it,
byte-identical to HEAD — verified directly:

| Defect | Site in commit 1 | Also in Hanan's baseline? |
| --- | --- | --- |
| `andi` writes 0; `ori` computes AND | `CONTROL.vhd:142` — `ALU_AND WHEN and_w or ori_w ELSE` | **No** — baseline `Auxilary/DUT/CONTROL.VHD:141` has `andi_w`. Student regression. |
| `lui` writes 0 | `const_package.vhd:27` — `UTYPE_OPC := "0010111" and "0110111"` | **Yes**, identical |
| Every load addresses `rs1 + 0` | `IDECODE.vhd` — `with opc_w select` has no `0000011` arm | **Yes**, identical |
| `sra` ≡ `srl` | `EXECUTE.vhd:200` — `brl_shr_pad_r <= 32x"FFFF"` | **Yes**, identical |
| `sltu`/`sltiu`/`bltu`/`bgeu` signed | `EXECUTE.vhd:10` — `USE IEEE.STD_LOGIC_SIGNED.ALL` | **Yes**, identical |

Four of the five are in the code Hanan distributed. The baseline is a repair source for exactly one.

---

# 2. Reference hierarchy

Anchor every decision here, in this order. Never skip a level silently.

1. **`Auxiliary/Final Project 2026 definition.pdf`** — the specification. Register bit-field tables
   are raster images; read the PDF pages, never the `.md` extraction.
2. **`Auxiliary/Lab 5/Auxilary/LAB5 task definition.pdf`** — holds clause 6.iii.b, the IPC equation
   the final-project document references but does not contain.
3. **`Auxiliary/Lab 5/Auxilary/DUT/`** — Hanan's 12 supplied source files, single-cycle RV32I only.
4. **Commit `cfc4b4f`** — the structural base, equal to `Auxiliary/Lab 5 - as submitted/` for
   everything except the two testbenches.
5. **`Auxilary/Lab3/`, `Auxilary/Lab4/`** — their own completed earlier labs. The richest source of
   reusable leaf modules.
6. **`Auxiliary/Benchmark Apps/`** — `io_map.s` is the executable MMIO contract.
7. General RISC-V / FPGA knowledge — only after the above, and stated as such.

**Note on the local copies.** `Auxiliary/Lab 5/` is HEAD (has `RSTPOL`).
`Auxiliary/Lab 5 - as submitted/` is commit **`c1e9e64`**, not the final commit — its `RV32IM_CORE.vhd`
md5 matches commits 1 and 2, and it carries the `.mpf` files that commit 2 added. Its folder name
overstates what it is; it is the best local approximation of the clean base, and the one to run the
baseline against.

---

# 3. Target architecture

From Figure 1 (p3), Figure 5 (p5), and §3's two-level structural requirement.

```
RV32IMscMCU                                  ← TOP, structural, board-facing
│   pins: CLOCK_50, KEY0..3, SW7..0, LEDR7..0, HEX5..0, PWMout, CAPIN, UART TXD/RXD
│
├── CLKTREE            (ALTPLL, c0/c1/c2)     → mclk, smclk, accelclk
├── RSTSYNC                                   ← KEY0 inversion + PLL-lock release lives HERE, not in the core
│
├── RV32IM_CORE        structural, polarity-agnostic, active-high reset internally
│   ├── IFETCH (ITCM)   IDECODE (RF)   CONTROL   EXECUTE (ALU + MUL16)
│   └── DIVACCEL + SYNC                        ← accelclk domain, CDC per Figure 10
│
├── BUSIF                                      ← Figure 5: A13..A4,A3,A2 → CS_1..CS_n ; BidirPin for reads
│   └── DTCM (2048 × 32)                       ← 0x0000–0x1FFC
│
└── Peripherals                                ← 0x2000–0x3FFC
    ├── GPIO      LEDR, HEX0..5, SW, PB
    ├── BASICTIMER  BTCNT, BTSSEL mux, BTCL0/1, comparators, capture, Output Unit
    ├── INTCTRL     IE, IFG, TYPE, priority, INTR/INTA
    └── USART       UTCL, RXBUF, TXBUF          ← bonus
```

Three build configurations, selected by generics, no divergent source copies:

| Configuration | GPIO | Interrupts | UART | Core | Purpose |
| --- | --- | --- | --- | --- | --- |
| A | ✔ | — | — | single-cycle | PPA row 1 |
| B | ✔ | ✔ | — | single-cycle | PPA row 2 |
| C | ✔ | ✔ | — | pipeline | PPA row 3 |
| D | ✔ | ✔ | ✔ | either | UART bonus demo |

Each of A/B/C gets **two Quartus revisions**, following `Lab4_Perf` / `Lab4_HW`: a *perf* revision
with no pin assignments and SignalTap off, which produces the PPA numbers; and a *hw* revision with
pins and SignalTap on, which produces the `.sof` and the validation captures. The SignalTap-only
ports are gated by a generic inside a `generate`, satisfying §7 directly.

---

# 4. The plan

Every phase states its exit criterion. A phase is not done until its criterion is measured, not
argued.

## Phase 0 — Baseline  ·  **Adar: Run 1**

Prove the environment before changing anything.

- Run `DOC/04_baseline_runbook.md`, from `SIM/baseline_reference/`, against the unmodified
  `Auxiliary/Lab 5 - as submitted/`.
- **Exit:** `mclk_cnt_o` = 134 / 1514 / 2725 / 2735 for test1–4, and each dump identical to the
  reference's own capture `DTCM_testN_MS.mem` in all **2048** words.
- If the numbers do not reproduce, stop. Do not start Phase 1.

> **RESOLVED 2026-08-24.** The reference folder no longer contains `run_test.do`, `mem_dump.do` or
> `batch_verify.do`, and never had a single-cycle `compile.do` at all — the deleted scripts are
> replaced by **`SIM/baseline_reference/{compile,run_test,mem_dump}.do`**, which reach into
> `Auxiliary/` read-only so it stays byte-for-byte as supplied. The two workarounds described below
> are superseded; they are kept only because they explain *why* the scripts had to be written.
>
> Original note: the reference folder no longer contains
> `run_test.do`, `mem_dump.do` or `batch_verify.do` — they were deleted from the submission, which
> now ships only `golden.do`, `wave.do` and the pipeline's `compile.do` and `directed_isa.do`. So the
> runbook's "run `run_test.do` in the reference folder" step cannot be followed literally any more.
>
> Two ways to still get the baseline, and either is fine as long as you say which you used:
> 1. **Copy our own `SIM/RV32IMscMCU/{run_test.do,mem_dump.do}` into the reference SIM folder** and
>    fix the hierarchy paths — the reference has no `MCU` wrapper level, so drop `MCU/` from every
>    path. This keeps the measurement method identical to ours.
> 2. **Run it by hand:** `compile.do`, then `vsim -t ns -gMODELSIM=1 work.tb_rv32im_sc`, then
>    `do golden.do`, `run 300 us`, and read `mclk_cnt_o`. The testbench no longer stops itself
>    (§0.e), so a bounded `run` is required.
>
> The four expected counts are unchanged and are independently confirmed by
> `Auxiliary/Lab 5 - as submitted/DOC/HANDOVER_Report_lab5.md` §5.3 and
> `PROJECT_EXPLANATION.md` §7 — 134 / 1514 / 2725 / 2735, at terminal PCs
> `0x0070` / `0x0070` / `0x00CC` / `0x004C`. That is now two independent written sources for the
> baseline, which is worth more than the scripts we lost.

Gaps: **G-202**, G-201, G-206, G-332.

### ▸ Adar's results — Phase 0

Single-cycle, in `Auxiliary\Lab 5 - as submitted\SIM\RV32IM_sc`:

| Test | expected `mclk_cnt_o` | **measured** | `pc_o` | golden compare |
| --- | --- | --- | --- | --- |
| test1 | 134 | | | |
| test2 | 1514 | | | |
| test3 | 2725 | | | |
| test4 | 2735 | | | |

Pipeline, in `...\SIM\RV32IM_pipeline` — these three columns exist nowhere yet and Phase 11 needs
them (**G-205**):

| Test | `CLKCNT_o` | `STCNT_o` | `FHCNT_o` | computed IPC |
| --- | --- | --- | --- | --- |
| test1 | | | | |
| test2 | | | | |
| test3 | | | | |
| test4 | | | | |

IPC per LAB5 clause 6.iii.b: `(CLKCNT − (STCNT + 4 + 3·FHCNT)) / CLKCNT`, with depth = 3 because
branches resolve in stage 4.

- ModelSim version string: ______
- Compile: ____ errors, ____ warnings (3 expected on `EXECUTE.vhd`)
- Anything unexpected: ______

## Phase 1 — Clean structural base  ·  **built, awaiting verification**

Done on 2026-08-20. Every file is in place; nothing has been compiled, because that needs Windows.

| Done | What |
| --- | --- |
| ✔ | `DUT/RV32IMscMCU/` and `DUT/RV32IMpipelinedMCU/` populated from commit **`cfc4b4f`** — 24 files, cores without `RSTPOL` |
| ✔ | `RV32IMscMCU.vhd` and `RV32IMpipelinedMCU.vhd` written — the outer structural level §3 requires, with reset conditioning and the §7 `GEN_DEBUG_PORTS` gate |
| ✔ | `RST_ACTIVE_LOW` is an **independent** generic, not tied to `MODELSIM`. **D-1 reverted.** |
| ✔ | Both component declarations added to the two `aux_package.vhd` files |
| ✔ | `TB/RV32IMscMCU/tb_RV32IMscMCU.vhd` and `TB/RV32IMpipelinedMCU/tb_RV32IMpipelinedMCU.vhd` — the names §10 mandates. Clock, reset waveform and commit 2's auto-stop preserved byte-for-byte; the pipeline TB's external names retargeted through the new level. |
| ✔ | `SIM/*/{compile,run_test,mem_dump,wave,batch_verify}.do` retargeted. `mem_dump.do`'s hierarchical path gained the `MCU` level — getting this wrong yields an empty dump, not an error. |
| ✔ | `vsim -gMODELSIM=1` added to every `vsim` line. **G-201 closed** — and it needed no RTL change, because the testbench already exposed `MODELSIM` as a generic and forwarded it. |
| ✔ | Quartus projects renamed to `RV32IMscMCU.{qpf,qsf,sdc}` / `RV32IMpipelinedMCU.{qpf,qsf,sdc}`, top entity set to the wrapper, wrapper added to the file list. Taken from commit 1, so **no pin assignments and no SignalTap. D-2 reverted.** |
| ✔ | All six hand-written port maps cross-checked against their entities: 16/16 and 22/22, zero mismatches |

**Verified absent / present in the new tree:** `RSTPOL` 0 occurrences · `std.env.stop` 2 files ·
`signaltap` 0 in `.qsf` · `set_location_assignment` 0 · and the four defect sites still present and
untouched at `CONTROL.vhd:142`, `const_package.vhd:27`, `EXECUTE.vhd:10`, `EXECUTE.vhd:200`.

**Still to do in this phase:** the second Quartus revision per configuration (`*_hw` with pins and
SignalTap) — deferred until there are pins worth assigning, i.e. after Phase 6. The perf revision
exists now and is what the PPA tables need.

**Exit criterion, not yet met:** compile both wrappers in ModelSim and Quartus, and reproduce
134 / 1514 / 2725 / 2735 *through the wrapper*. Procedure in `DOC/04_baseline_runbook.md` §8.

### ▸ Adar's results — Phase 1  (Run 2 steps 1–2, and Run 3)

ModelSim, in `SIM\RV32IMscMCU`. **No source edit — `run_test.do` passes `-gMODELSIM=1`.**

| Test | expected | **measured** | same as Phase 0? |
| --- | --- | --- | --- |
| test1 | 134 | | |
| test2 | 1514 | | |
| test3 | 2725 | | |
| test4 | 2735 | | |

Identical counts are the whole point: they prove `RV32IMscMCU` is behaviourally transparent. A
difference means the wrapper changed something and must be fixed before Phase 3.

Then the same in `SIM\RV32IMpipelinedMCU`: ______

Quartus, `Quartus\RV32IMscMCU\RV32IMscMCU.qpf`:

| | expected | **measured** |
| --- | --- | --- |
| Top entity resolved | `RV32IMscMCU` | |
| **Embedded memory bits** | **131,072** | |
| Logic elements | ~3,384 was the pipeline reference; SC is smaller | |
| Registers | | |
| Fmax | 26.81 MHz was the pre-wrapper reference | |
| Errors / critical warnings | 0 | |

**131,072 is the load-bearing number.** 483,328 would mean SignalTap is instrumenting the build
again, which is the defect D-2 this whole tree exists to avoid.

Unassigned-pin warnings are expected and correct here — this is the pinless performance revision.

Then `Quartus\RV32IMpipelinedMCU\RV32IMpipelinedMCU.qpf`: ______

### Original phase description

Establish the tree from commit 1's shape, not HEAD's.

- Copy the nine submodule files + two cores into `DUT/RV32IMscMCU/` and `DUT/RV32IMpipelinedMCU/`.
  Take the **cores from commit `cfc4b4f`** (no `RSTPOL`); submodules are identical in every commit so
  the source does not matter.
- Rename the top entities to `RV32IMscMCU` / `RV32IMpipelinedMCU` as §10 requires, and introduce them
  as **new structural wrappers** around the existing `RV32IM_CORE` / `RV32IM_PIPE_CORE` rather than by
  renaming the cores. This is what gives us the second structural level §3 demands, and the place
  where reset inversion, the clock tree and the peripherals attach.
- Move KEY0 inversion into the top wrapper, patterned on
  `Auxilary/Lab4/DUT/fpga_hw_interface.vhd:38`. Delete `RSTPOL` from the core. **Fixes D-1.**
- Convert `G_MODELSIM` from a package constant to a generic the testbench overrides with `-g`.
  **Fixes G-201.** The package constant stays as the default so Quartus needs no edit.
- Carry commit 2's testbench auto-stop forward.
- Two Quartus revisions per configuration from the start, per `Lab4_{perf,hw}.sdc`. **Fixes D-2.**
- **Exit:** both wrappers compile in ModelSim and Quartus; the baseline numbers from Phase 0 still
  reproduce through the new wrapper; the perf revision reports 131,072 memory bits, not 483,328.

Gaps: G-311 (clock tree), D-1, D-2, D-3.

## Phase 2 — Directed ISA verification  ·  **built, awaiting verification**

Done on 2026-08-20. Written and self-validated here; the ModelSim run is on Windows.

| Done | What |
| --- | --- |
| ✔ | `tools/gen_isa_test.py` — generates the test program, the memory images, the expected-store package and a human listing, all from **one** table, so program and expectations cannot drift apart |
| ✔ | `TB/RV32IMscMCU/tb_isa_directed.vhd` — self-checking scoreboard, **46 declared cases**, 56 stores |
| ✔ | `TB/RV32IMscMCU/isa_expected_pkg.vhd` + `SIM/RV32IMscMCU/isa/{ITCM,DTCM}.hex` + `listing.txt` — generated |
| ✔ | `SIM/RV32IMscMCU/run_isa.do`, and the two new files added to `compile.do` |

**Three design problems and how each was solved**

*How does the testbench see results?* There is no register-file port. But
`MemWrite_ctrl_o`, `dtcm_addr_o` and `dtcm_data_wr_o` are declared outputs, so the scoreboard snoops
the store bus. No external names, no memory introspection, nothing tied to a precompiled Altera
model. The program publishes each case with `sw rX, slot*4(x0)`, so the store sequence *is* the
result sequence.

*When is a store valid?* `DMEMORY` drives its `altsyncram` with `wrclk_w <= NOT clk_i`, so the DTCM
commits on the **falling** edge of `clk_i`. The scoreboard samples there. Sampling the rising edge
would race the instruction fetch.

*What can the harness rely on?* Four of the five defects break exactly the instructions a harness
normally leans on — `lui` writes 0, loads ignore their offset, `sra` is `srl`, unsigned compares are
signed. So every case builds operands with `addi`/`slli` and publishes with `sw`. A 32-bit constant
is assembled a byte at a time (`li32`) because `lui` cannot be trusted.

**Self-validation that ran here, with no simulator**

- **Encoder self-test, 9/9.** Every encoding checked against a known word — including
  `addi s0,s0,160 = 0x0A040413` taken straight from the supplied `test1` ITCM image, and the two
  sentinels `0x00000063` / `0x0000006F`.
- **Reference RV32IM interpreter, 46/46.** A second, independent implementation written from the
  unprivileged ISA spec executes the generated program and produces the store sequence. Every
  declared expectation is cross-checked against it, so **a mismatch in ModelSim is a hardware
  finding, not a bad expectation.**
- **Structural check on all 8 hand-written VHDL files** — parens balanced, `process`/`component`
  blocks matched, no aggregate element missing a comma.
- **Image well-formedness** — 206 instruction records plus the EOF record, and the last instruction
  is the `0x00000063` sentinel.

**Two real bugs the self-validation caught before Windows ever saw the code**

1. The reference run reported **43 stores against 41 cases**: two cases perform scratch `sw`s while
   setting up, and those are real stores on the bus. Left unfixed the whole sequence would have been
   off by two and 19 cases would have mis-reported. Scratch data moved to words 200+ and the expected
   sequence is now derived from the reference run, so setup stores are accounted for explicitly.
2. `mulh` of `0x12345678 × 2` is **0** — which is also what an undecoded instruction writes, so all
   three high-multiply cases would have passed while testing nothing. Operands changed to
   `0x12345678 × 0x10000000`, whose high word is `0x01234567`.

### Two bugs found in this phase's own work on 2026-08-23 — read before running

**Bug 1: the suite would have miscounted by one, and cascaded.** The generator's reference
interpreter recorded only word stores in the expected sequence (`if f3 == 2`). Every store asserts
`MemWrite_ctrl_o`, so the scoreboard counts sub-word stores too — and the program contains one `sb`.
Measured on the generated image: **44 store instructions on the bus against 43 expected entries.**
The scoreboard advances its index on every store, so the missing entry shifted everything from store
#25 onward and would have produced roughly 19 spurious mismatches on top of the real ones. The
promised "20" was wrong. Fixed by recording every store, with the value the *bus* carries — which is
`read_data2_w`, the raw rs2 value, upstream of DMEMORY's lane replication.

**Bug 2: the one sub-word case could not fail.** `sb_then_lbu` stored `0x7F` and loaded it back
expecting `0x7F`. With no byte enables the `sb` writes the whole word as `0x0000007F`, and with no
extract mux the `lbu` returns that whole word — which *is* `0x7F`. Once the load offset was repaired
it would have passed while testing nothing at all. Exactly the failure mode caught earlier in the
`mulh` cases. Replaced with **six** cases that each need a surviving neighbour byte or a sign bit,
neither of which a full-word access can fake, and each of which re-establishes its own base word so
a failure localises to one instruction.

**Both numbers are now derived twice, independently.** `tools/gen_isa_test.py` computes the expected
mismatch count once by tagging each case with the gap it exercises, and once by executing the
generated program through `defect_run()` — a second interpreter that models this core's actual
defects rather than a conformant RV32IM. Generation **aborts** if the two disagree. Deriving the
number by bookkeeping is not the same as deriving it by execution, and only the second is evidence.

**The memory images changed, and that is the honest outcome.** Phase 2 called `isa/ITCM.hex` a frozen
contract, and it was — right up until the contract turned out to encode a program whose expectations
could not be met and one of whose cases could not fail. Freezing that would have been freezing a bug.
The image is now 268 words instead of 206 (`ITCM.hex` md5 `893b7c48…`; `DTCM.hex` is unchanged at
`e0c27360…`, still 1024 zero words). What the freeze was protecting — that the same suite measures
before and after — is intact, because both configurations run this same image. It is frozen again
from here.

**Exit criterion, not yet met:** run `run_isa.do`. The expected result is **exactly 25 mismatches** —
a generated constant (`EXPECTED_DEFECT_COUNT`) that the testbench compares its own tally against, so
it cannot drift. Zero would mean the images never reached `app_bin`. A count other than 25 is the
interesting outcome: a mismatch on a case not marked `DEFECT` is a new finding, and a `DEFECT` case
that passes means the defect is not where we think it is.

### ▸ Adar's results — Phase 2  (Run 2 step 3)

`SIM\RV32IMscMCU` → `run_isa.do`. Read the `SUMMARY` block it prints.

- Stores observed: ____ of 56
- **Mismatches: ____ ** (25 expected)
- Cycles: ____

Then tick each predicted case. A blank means it **passed**, which for these is itself a finding —
it would mean the defect is not where we think.

| # | case | mismatched? | # | case | mismatched? |
| --- | --- | --- | --- | --- | --- |
| 7 | `andi` | | 38 | `lh_sign_extends` | |
| 8 | `ori` | | 40 | `mul_wide` | |
| 12 | `sltiu` | | 41 | `mul_hi_low` | |
| 14 | `sltu` | | 42 | `mulh` | |
| 18 | `srai` | | 43 | `mulhu` | |
| 19 | `sra` | | 44 | `mulhsu` | |
| 20 | `lui` | | 45 | `div` | |
| 24 | `lw_offset` | | 46 | `divu` | |
| 27 | `sb_keeps_neighbours` | | 47 | `rem` | |
| 30 | `sh_keeps_neighbours` | | 48 | `remu` | |
| 32 | `lbu_selects_lane` | | 53 | `bltu_nottaken` | |
| 34 | `lb_sign_extends` | | 54 | `bgeu_taken` | |
| 36 | `lhu_selects_half` | | | | |

**Any case NOT in this table that mismatched — paste the full `ISA TEST FAIL` line here:**

```
```

That is the highest-value output of the whole phase: it is a defect nobody has found yet, and Phase 3
has to account for it.

### Original phase description

The first real test infrastructure. Authorable now, runnable on Windows.

- Write `TB/RV32IMscMCU/tb_isa_directed.vhd`: a self-checking testbench that loads a small ITCM
  image per instruction group and asserts expected register and memory state. Pattern the assertion
  style on `Auxilary/Lab3/TB/tb_top.vhd:86,110` — the only assertions anywhere in the material.
- Cover: arithmetic, logic, all shifts including `sra`, signed **and unsigned** compares, all
  branches, `jal`/`jalr`, `lui`/`auipc`, byte/half/word loads and stores with non-zero offsets, and
  every M-extension instruction.
- **Exit:** the suite runs and **fails** on exactly the five known defects plus the undecoded M
  instructions. A suite that passes against the unfixed core is not testing anything.

Gaps: **G-402**, G-401.

## Phase 3 — Repair and complete the core

Split into four parts because they have different owners and different blockers. **3A and 3D are
written; 3B is next on the Mac; 3C is deliberately not started.**

### Phase 3A — the seven ISA repairs  ·  **built, awaiting verification**

Done 2026-08-23. Every repair is a transcription from the reference pipeline (§0.a), so none of it is
our invention and each carries a file:line citation in the code itself.

| Done | What |
| --- | --- |
| ✔ | `G_ISA_REPAIR` switch added to `DUT/RV32IMscMCU/cond_compilation_package.vhd`, following the `G_MODELSIM` idiom that already lives in that file |
| ✔ | Defects 1–7 repaired in `CONTROL.vhd`, `IDECODE.vhd`, `EXECUTE.vhd`, `IFETCH.vhd`, `const_package.vhd` — each gated by the switch, each commented with the defect, the mechanism, and the reference line |
| ✔ | `LOAD_OPC`, `AUIPC_OPC`, `LUI_OPC` added to `const_package.vhd`, values taken verbatim from the pipeline's own package |
| ✔ | `SIM/RV32IMscMCU/repair_check.do` — directed checks ported from the reference's `directed_isa.do`, later extended to 43 to cover Phase 3B as well |
| ✔ | `tools/gen_isa_test.py` emits `EXPECTED_DEFECT_COUNT_REPAIRED`; `tb_isa_directed.vhd` picks the right count from `G_ISA_REPAIR`, so the suite predicts correctly in both configurations |

**Why a switch instead of just editing the code.** `CLAUDE.md` requires the failure to be measured
before the fix. The switch gets both measurements out of one build tree, in one sitting, with no
branch to juggle and no chance of the "before" and "after" runs disagreeing about anything except the
repair. `G_ISA_REPAIR = FALSE` reproduces the submitted core bit-for-bit — that was checked
expression by expression, not assumed.

**Which cases the switch closes, and which it does not.** The 25 Phase-2 mismatches were never all
decode defects:

| Gap | Cases | Closed by the switch? | Blocked on |
| --- | --- | --- | --- |
| G-321 `andi`/`ori` | 2 | ✔ 3A | — |
| G-325 signed compares | 4 | ✔ 3A | — |
| G-324 `sra` pad | 2 | ✔ 3A | — |
| G-322 `lui` | 1 | ✔ 3A | — |
| G-323 load offset | 1 | ✔ 3A | — |
| G-309 sub-word access | 6 | ✔ 3B | — |
| G-326 `MUL16` is 16×16 | 2 | ✘ | open question — mul width |
| G-308 `mulh`/`mulhu`/`mulhsu` | 3 | ✘ | open question — "MULDIV partial" |
| G-307 `div`/`divu`/`rem`/`remu` | 4 | ✘ | Phase 7, Q6 |

**25 → 9.** Defects 6 and 7 are not in that table because the Phase-2 suite does not reach them: its
only branch displacements are 0 and 8, and it executes no `jalr` at all — both verified by scanning
the generated image. That is what `repair_check.do` is for.

**What was validated here, with no simulator:**

- **Both mismatch counts derived twice, independently.** Once by tagging cases with gap IDs, once by
  executing the program through `defect_run()` — a model of this core's own defects, separate from
  the conformant reference model. They agree at 25 and at 9, and generation aborts if they ever
  do not.
- **The 9 survivors identified by name**, not just counted: `mul_wide`, `mul_hi_low`, `mulh`,
  `mulhu`, `mulhsu`, `div`, `divu`, `rem`, `remu`. Every one is a case blocked on a question. No
  regression hides in the count.
- **Parens and `if`/`end if` balance** in every edited file, checked against the pristine reference
  copies as a control — which is how the first balance metric was caught being wrong rather than the
  code.
- **Entity ≡ component ≡ instantiation** for `control` and `dmemory` after the port additions, and
  17 ports / 12 generics matched on the pipeline wrapper.
- **`G_ISA_REPAIR = FALSE` reproduces the submitted core** — checked expression by expression, not
  assumed, and confirmed by the defect model reproducing the same 25.

**Exit:** `repair_check.do` 43/43, and `run_isa.do` exactly 9.

#### ▸ Adar's results — Phase 3A  (Run 2 step 4)

- `repair_check.do` — passed: ____ of 43, failed: ____
- `run_isa.do` — mismatches: ____ (9 expected)

If `repair_check.do` reports exactly **25** failures, the design was compiled with
`G_ISA_REPAIR = FALSE`; set it to `TRUE`, re-run `compile.do`, and run again. Any count that is
neither 0 nor 25 is a real finding — a specific repair is wrong, or a control check broke, and a
broken control means a repair damaged behaviour that was already correct. Paste the failing lines:

```
```

Then re-run the four benchmarks with the repair on. **The four counts should not change**
(134 / 1514 / 2725 / 2735) and all four DTCM dumps should still match their RARS goldens — the
repairs touch instructions the benchmarks either use correctly already or never use. A count that
*does* move is a finding worth stopping for.

| Test | cycles, repair OFF | cycles, repair ON | DTCM matches golden? |
| --- | --- | --- | --- |
| 1 | 134 | | |
| 2 | 1514 | | |
| 3 | 2725 | | |
| 4 | 2735 | | |

### Phase 3B — byte enables and sub-word load/store  ·  **built, awaiting verification**

Done 2026-08-23. The one genuinely missing *feature* rather than defect, and mandatory: the
benchmarks address byte-resolution MMIO registers, `DMEMORY.vhd`'s `altsyncram` had **no
`byteena_a`**, and `CONTROL` detected `lb`/`lh`/`lbu`/`lhu`/`sb`/`sh` and then discarded the width.

**No direct course reference found.** Verified by grep: the tree has 10 `altsyncram`
instantiations and not one uses `byteena_a`, `byte_size` or `width_byteena_a`. The reference
pipeline does not implement sub-word access either — `PROJECT_EXPLANATION.md` §4.4 says so outright.
So this is our design. The three `altsyncram` identifiers come from Intel's megafunction interface,
which is **general knowledge, not course material**, and that is the one thing here I could not
verify locally.

| Done | What |
| --- | --- |
| ✔ | `const_package.vhd` — `MEM_B`/`MEM_H`/`MEM_W`/`MEM_BU`/`MEM_HU`. Not an encoding of ours: these are the ISA's own load/store funct3 values, cited to the instruction-format PDF |
| ✔ | `CONTROL.vhd` — new `MemOp_ctrl_o`, built from the mask detectors that already existed, so an undefined funct3 degrades to a full word rather than to an undefined width |
| ✔ | `DMEMORY.vhd` — `byteena_a` + `byte_size` + `width_byteena_a`; store-data lane replication; a byte/half extract mux and sign/zero extension on the read path; a static assert that the bus is 32 bits; a simulation-only misalignment warning |
| ✔ | `RV32IM_CORE.vhd` — routes `MemOp` and `alu_res_w(1 DOWNTO 0)`, the byte offset the word-address slice throws away |
| ✔ | `aux_package.vhd` — both component declarations updated; entity ≡ component ≡ instantiation verified for `control` and `dmemory` |
| ✔ | Folded under the same `G_ISA_REPAIR` switch. One switch, two configurations — two switches would mean four combinations to explain and to run |

**Why `byteena_a` and not read-modify-write.** The RAM output is `UNREGISTERED`, so `q_a` already
carries the addressed word and merging the new byte in looks tempting. It creates a combinational
path `q_a → data_a → RAM` — a loop through the memory — and same-address read-during-write on an M9K
is undefined in this configuration. `byteena_a` is the mechanism the hardware provides for exactly
this.

**Alignment is defined, not assumed.** RV32I traps on a misaligned access and this core has no trap
mechanism, so a half-word access uses `byte_sel_i(1)` only and aligns down. A simulation-only
`report … severity warning` fires if it ever happens, so a benchmark cannot depend on it silently.

**Timing risk, flagged for Phase 14.** The critical path is already ITCM → decode → ALU → DTCM with
the DTCM on the inverted clock: Fmax 26.81 MHz against a 25 MHz target, 1.81 MHz of margin. The
extract-and-extend mux lengthens exactly that path. **Expect Fmax to drop.** If it goes below
25 MHz the PLL ratio has to change, which is a Phase 4 decision — not a reason to undo this.

**Second risk: the memory-bit count.** Adding byte enables may change how Quartus configures the M9K
blocks. Embedded memory bits should still read **131,072**; if that number moves, say so before
drawing any conclusion from it.

Closes G-309. Takes the ISA suite from 25 mismatches to 9.

### Phase 3C — `mul` width, `mulh`, and `div`  ·  **deliberately not started**

Nine of the ten remaining mismatches are here, and **all of them are blocked on a question, not on
effort.** Implementing them now would be inventing requirements:

- `MUL16` multiplies only `rs1(15:0) × rs2(15:0)`. `PROJECT_EXPLANATION.md` §1 calls the submitted
  design "an RV32I-oriented teaching core extended with a tested 16-bit `mul` datapath" and it was
  accepted that way. Whether the final project needs a full 32×32 `mul` is unanswered.
- `mulh`/`mulhsu`/`mulhu` — masks exist in `const_package.vhd`, no ALU op consumes them. LAB5 calls
  the whole thing "MULDIV **partial**".
- `div`/`divu`/`rem`/`remu` — the Final Project defines a **division accelerator** as a peripheral
  (Figure 9: `DIVIDEND`/`DIVISOR`/`QUOTIENT`/`RESIDUE`, `DIVCLK`/`DIVRST`/`DIVENA`/`DIVBUSY`), not as
  an ISA instruction. Q6 asks whether those registers are memory-mapped or core-internal, and until
  that is answered, adding `div` to the ALU may well be building the wrong thing.

**Ask Hanan before writing any of this.** Q6 plus a new question on `mul` width.

### Phase 3D — re-import the revised pipeline  ·  **built, awaiting verification**

Forced by the reference update (§0.b), not a design choice. Our copy was an entire revision behind
and the wrapper was wired to a port list that no longer exists — it could not have compiled.

| Done | What |
| --- | --- |
| ✔ | 14 files re-imported from the revised reference; all md5-verified against it. `MUL16.vhd` deleted — present in the reference but not instantiated |
| ✔ | `RV32IMpipelinedMCU.vhd` rewritten for the Figure 8 interface. Port map cross-checked against the component declaration: 17 ports, 12 generics, none missing, none extra |
| ✔ | `aux_package.vhd` — the wrapper's component declaration re-added to the fresh copy |
| ✔ | `tb_RV32IMpipelinedMCU.vhd` rewritten, clock/reset/`BPADDR_i` stimulus copied from the reference testbench unchanged |
| ✔ | `compile.do` new file list; `golden.do` and `wave.do` retargeted from the reference; `run_test.do` and `batch_verify.do` stop condition moved from the retired `flush_o` port to `MCU/CORE/flush_w` |
| ✔ | Every hierarchical path in every pipeline `.do` file verified to exist in the revised RTL |

**Exit:** `compile.do` runs clean and the four benchmarks reproduce through the wrapper.

Gaps: G-321…G-327 (3A), G-309 (3B), G-307, G-308, G-326 (3C), G-330 (3D).

## Phase 4 — Clock tree, reset, CDC  ·  Yehonatan writes · Adar verifies

- Regenerate the ALTPLL with `c0`/`c1`/`c2` → `mclk`, `smclk`, `accelclk`. All three existing copies
  expose only `c0`. Worked non-trivial-ratio example: `Auxilary/Lab4/DUT/pll.vhd`, 50 → 2 MHz.
- Synchronise PLL lock into reset release, in the top wrapper.
- Build the two-flop synchroniser of Figures 10a/10b as a reusable entity. **Do not** mistake
  `IFETCH.vhd:73-82` for one — it is a single flop with an async preset.
- Constrain all three clocks and every crossing in the SDC. Start from
  `Auxilary/QUARTUS/SDC/RISCV_simple.sdc`.
- **Exit:** measured 20 MHz `smclk`, deterministic reset, no unconstrained cross-domain path.

Gaps: G-310, G-311. Blocked on **Q2**.

## Phase 5 — Bus interface and DTCM  ·  Yehonatan writes · Adar verifies

- Implement Figure 5's decoder: `A13..A4, A3, A2` → `CS_1..CS_n`, `A0` separating the HEX pairs.
- Split `0x0000–0x1FFF` → DTCM, `0x2000–0x3FFF` → MMIO, **before** narrowing to the RAM address.
  Today `RV32IM_CORE.vhd:215-220` does a bare bit-slice with no decode, so `0x2000` aliases onto
  DTCM word 0 — where the interrupt vector table lives.
- Use `Auxilary/Lab3/DUT/BidirPin.vhd` with `width => 32` for the read path. Figure 1 links to it
  explicitly as the bidirectional-bus reminder.
- Unmapped reads return a documented value; unmapped writes assert a simulation warning.
- **Watch the timing.** The single-cycle critical path is already ITCM address →
  `ID|Mux19` chain → DTCM address, with a **20 ns** relationship (the DTCM latches on the inverted
  clock) and 1.351 ns slack at 26.81 MHz. This decoder lands inside it.
- **Exit:** self-checking tests for DTCM boundaries, every access size, each adjacent MMIO address,
  and DTCM/MMIO non-aliasing.

Gaps: G-305, G-309.

## Phase 6 — GPIO  ·  Yehonatan writes · Adar verifies

- `hex_decoder.vhd` from `Auxilary/Lab4/DUT/` — **use as is**, active-low DE2-115, complete 0–F table.
- Latched LEDR7-0 and six HEX nibble registers per Figure 5; SW7-0 and KEY3-1 reads.
- KEY0 is reset only, in the top wrapper. KEY1-3 feed `PORT_PB` and the interrupt edge latches.
- **Exit:** GPIO test0, test1, test2 pass. **G-405**: these never write the DTCM, so verification is
  by MMIO assertion and waveform, not golden memory.

Gaps: G-306. Blocked on **Q5**.

## Phase 7 — Division accelerator  ·  Yehonatan writes · Adar verifies

- Figure 9 specifies it completely: dividend left-shift register, divisor register, subtractor
  `Result = Y − X` with non-negative feedback driving the quotient bit, quotient left-shift register;
  `DIVCLK`/`DIVRST`/`DIVENA` in, `DIVBUSY` out. **Writing `DIVISOR` starts it**; results ready after
  32 `DIVCLK` cycles.
- Subtractor candidate: `Auxilary/Lab4/DUT/AdderSub.vhd`, generic n-bit.
- Wrap signed `div`/`rem` around the unsigned engine. Stall via `PCHold` on `DIVbusy`, per Figure 3.
- Block interrupt entry until the divide retires, so the architectural boundary stays precise.
- **Exit:** exactly 32 accelerator cycles per operation; unit tests for latency, back-to-back,
  reset-while-busy, divide-by-zero, signed limits, quotient/remainder select.

Gaps: G-301. Blocked on **Q6**.

## Phase 8 — Basic Timer  ·  Yehonatan writes · Adar verifies

- 32-bit `BTCNT` up-counter, `BTSSEL` 4-to-1 clock mux (`00`→÷1 … `11`→÷8), `BTHOLD` enable,
  `BTCLR` clear.
- `BTCL0`/`BTCL1` shadow latches loaded from `BTCMPR0`/`BTCMPR1`.
- Output Unit adapted from `Auxilary/Lab4/DUT/pwm.vhd` — 16→32 bit, and re-map period `Y`→`BTCL0`,
  duty `X`→`BTCL1` to match Figure 8's Set/Reset and Reset/Set traces.
- Capture path: `CAPISEL` mux → `CAPMD` edge select → `BTCNT_CAPTURE` → `BTCAPR`.
- `BTINT` selects the `BTIFG` source from `EQU0`, `EQU1`, capture.
- **Exit:** self-checking compare, rate-change, PWM duty and capture tests. Then the real constants:
  `FREQ_5K = 500` at `BTSSEL=3` must give exactly 5 kHz.
- **Known contradiction:** `SEC_PERIOD = 20,000,000` at the same `BTSSEL=3` gives **8 seconds**, not
  the 1 second its comment claims. Implement Figure 7 as drawn and report the discrepancy — see Q3.

Gaps: G-302. Blocked on **Q3, Q4, Q8**.

## Phase 9 — Interrupt controller and CPU protocol  ·  Yehonatan writes · Adar verifies

- `IE`/`IFG`/`TYPE` per p14. Bit positions verified from two independent sources: the PDF tables and
  the benchmark masks (`BTIE = 0x04` → bit 2; `0x38` → bits 5,4,3; `0xFFF7`/`0xFFEF`/`0xFFDF` clear
  bits 3/4/5).
- Per-source flag = a D flop with `D` tied to `'1'`, **clocked by the source edge**, async-cleared —
  exactly the p13 diagram. No separate edge detector is drawn, but KEY1-3 still need synchronising
  into `mclk` first.
- `IFG` holds the raw latched flag; `IE` masks only the path toward `INTR`. `INTR = OR(irq AND eint)
  AND GIE`.
- Fixed priority, TYPE `04h`–`1Ch`.
- CPU entry FSM, two cycles, triggered by the **falling edge of `INTA`**: cycle 1 clears
  `GIE = gp[0]`, sets `INTA`, drives `TYPE` onto the data bus into a dedicated register; cycle 2
  clears the synchronous flag and emulates `load` + `jalr` to `Mem[TYPE]` with `R[tp]` = return
  address. Return: `jalr zero,0(tp)` sets `GIE`.
- **Exit:** cycle-accurate protocol assertions; simultaneous requests, priority, masking, nesting
  deferral while `GIE = 0`, manual and automatic clear, interrupts around loads, stores and divides.

Gaps: G-303, G-304. Blocked on **Q7**.

## Phase 10 — Single-cycle benchmark progression  ·  **Adar runs**

- Interrupt test1 with scripted KEY1/2/3 pulses; test2 one-second BT interrupts; test3 the four
  periods; test4 in compare, PWM and capture modes.
- Use `Auxiliary/Benchmark Apps/Intrrupt-based IO/` — the current revision. `_superseded/` holds the
  older one with two extra defects, kept for auditability.
- **test4's capture never fires**: `capture_init` and `capture` both write `0x07`, so `CAPISEL` stays
  at GND. Verify capture with a separately-marked corrected copy writing `0x06`. Q10.
- **Exit:** all mandatory checks pass with saved logs, memory diffs and report-ready waveforms.
  **G-204**: `mem_dump.do` exports 1024 of 2048 DTCM words — extend it or document the limit.

## Phase 11 — Pipeline port  ·  bonus 10%  ·  Yehonatan writes · Adar verifies

- Fork only after the single-cycle system is stable. Reuse the same bus interface, peripherals,
  divider and register maps.
- The pipeline is **a rewrite, not a derivative** of the baseline — changed-line counts against
  Hanan's files are `EXECUTE` 212, `DMEMORY` 106, `IFETCH` 78, `CONTROL` 29. Port each core fix
  deliberately; do not merge mechanically.
- Add divider and memory stalls to the existing `HAZARD_UNIT`/`FORWARD_UNIT`.
- Precise interrupts: pick a retirement boundary, kill younger instructions, preserve the resume PC,
  serialise the vector-table access.
- Preserve `CLKCNT_o`, `STCNT_o`, `FHCNT_o`, `BPADDR_i`, `BPTRIGGER_o`.
- **Exit:** architectural state matches the single-cycle reference for every test, and measured IPC
  equals clause 6.iii.b:
  `IPC = (CLKCNT_o − (STCNT_o + 4 + depth·FHCNT_o)) / CLKCNT_o`, with `depth` = 3 (branches resolve
  in stage 4). Capture the pipeline's own cycle counts — **G-205**, they are recorded nowhere.

## Phase 12 — UART  ·  bonus 20%  ·  Yehonatan writes · **Adar needs the cable and the board**

- Base: `UART_FPGA_option1` (jakubcabal, MIT). Keep the licence header.
- **Most of the register layer is new work** — neither supplied option has separate `RXBUF`/`TXBUF`,
  overrun logic, a parity-error output port, an aggregate `BUSY`, an `SWRST`, a runtime baud
  register, or any bus interface. Option 1 exports one of the three required error flags
  (`FRAME_ERROR <= NOT UART_RXD`, `rtl/comp/uart_rx.vhd:162`) and computes parity error at `:139`
  without exporting it.
- Adapt the compile-time divider (`rtl/uart.vhd:58`) to runtime `UCTL[3]` selection, switching only
  while idle.
- Do **not** use `example/uart_loopback_tb.vhd` — it port-maps `DIN_RDY` and `FRAME_ERR`, which the
  entity does not declare. Broken as shipped.
- Cross RX/TX events into the `mclk` MMIO domain with the Phase 4 synchroniser.
- Menu firmware: count up from `0x00`, count down from `0xFF`, clear, "I love my Negev" on KEY1,
  show menu. The document's `LEDG` is read as `LEDR` — Q1.
- **Exit:** ModelSim loopback and error suite passes; a terminal communicates at 115200 8N1 with no
  framing errors.

Gaps: G-313. Blocked on **Q12**, and **Q1/G-504** for the pins.

## Phase 13 — Regression and evidence  ·  **Adar runs**

- Scripts per core × configuration × benchmark: select images, run bounded stimuli, dump memory,
  compare, **return a non-zero exit status on mismatch**. `batch_verify.do` currently only echoes —
  **G-203**.
- Keep `bin/M9K-intel/*.hex` for ITCM and ISMCE, `bin/Hexadecimal-Text/*.h` as the DTCM golden text.
  Assert that `ITCM.h` is never loaded as an ITCM source — the two formats are **different
  programs**, `.hex` at text base 0 and `.h` retaining RARS's `0x3000`.
- Capture report-ready waveforms for interrupt tests 1–4.
- **Exit:** one regression summary covering every required test, with no manual source edits anywhere
  in the flow.

## Phase 14 — Quartus PPA  ·  **Adar only** — six revisions

- Three perf revisions (A, B, C), no pins, SignalTap off, consistent settings. These produce the
  three tables.
- Three hw revisions, pinned, SignalTap on, gated by the §7 generate generic. These produce the
  `.sof` files and the captures.
- Identify the **actual** critical path, not just Fmax. Reference numbers to beat: single-cycle
  Fmax 26.81 MHz, pipeline 41.84 MHz, 131,072 memory bits, 4 multipliers, 1 PLL — from the clean
  build screenshots in `Auxiliary/Lab 5 - as submitted/Screenshots/Quartus/`.
- **Settings are part of the measurement.** `POWER_DEFAULT_TOGGLE_RATE 12.5%` was added in commit 2
  and changes the power numbers; "Use smart compilation" and "Advanced Physical Optimization = Off"
  were circled in staff-supplied photos — **G-208**, confirm whether these are instructions.
- **Exit:** all six revisions fit and meet the chosen clock with clean constraints.

Gaps: G-206, G-208.

## Phase 15 — Hardware validation  ·  **Adar only** — needs the DE2-115

- Program each `.sof`; KEY0 reset; exercise GPIO, interrupt and UART scenarios on the DE2-115.
- SignalTap: at least one KEY ISR, one BT ISR, a divider stall and completion, a pipeline
  hazard/flush, and a UART transaction. Trigger per clause 6.iii.a:
  `SignalTap trigger = (IF_pc == BPADDR_i)`, `BPADDR_i` fed by SW7-SW0 at word granularity.
- Capacity check: `STdepth = (Embedded memory size − Design usage) / #ST channels`.
- ISMCE: load each benchmark's images, run, export DTCM, compare against the RARS `.hex`.
- **Exit:** signed hardware checklist with memory diffs, captures, terminal transcript and photos.

Blocked on **Q1**.

## Phase 16 — Report and submission  ·  both

- `Final_report.pdf`, structured on `Auxiliary/Lab 5 - as submitted/DOC/Report_lab5.pdf`. Figures and
  tables numbered, captions **below**.
- Must include: top-level block diagram, RTL Viewer, the three PPA tables with mandatory Quartus
  screenshots and critical-path analysis, a short description of every HDL file, waveforms for
  test4→test1, the IPC proof, and conclusions.
- Present the four baseline decode defects as **supplied** defects with their `Auxilary/DUT/`
  citations, and the benchmark defects likewise. Never as failures of our RTL.
- Attribute the MIT UART.
- ZIP: `209580208_211468582.zip`, uploaded by 209580208, containing exactly **five** folders —
  `DUT`, `TB`, `SIM`, `DOC`, `Quartus` — each with `RV32IMscMCU` and `RV32IMpipelinedMCU`
  subfolders. The document says "six" above a table listing five; LAB5 §9.g uses the identical
  wording and was accepted with five.
- **Exit:** unzip into a clean location and compile both ModelSim and Quartus projects from the
  packaged files alone, with zero missing files and no absolute-path dependency.

Gaps: G-501…G-505.

---

# 5. Gap register

`G-2xx` tooling · `G-3xx` design · `G-4xx` verification · `G-5xx` documentation.
`D-x` = deviations introduced by commit 3 that this plan reverts.

## Deviations to revert

| ID | What | Fix in |
| --- | --- | --- |
| **D-1** | `RSTPOL` inside the core, tied to `G_MODELSIM` | Phase 1 — move inversion to the MCU top, per `fpga_hw_interface.vhd:38` |
| **D-2** | SignalTap and pins merged into the only Quartus revision; PPA numbers contaminated (483,328 vs 131,072 memory bits) | Phase 1 — two revisions per configuration, per `Lab4_{perf,hw}.sdc` |
| **D-3** | `.mpf` and `.cr.mti` committed | Already handled by the project `.gitignore` |

## Tooling

| ID | Gap |
| --- | --- |
| **G-201** | `G_MODELSIM` is a manual source edit in both cores. Convert to a generic with `-g` override; keep the package constant as the Quartus default. |
| **G-202** | **Baseline never reproduced.** Runbook and all inputs are ready; nobody has run it. Gate on Phase 1. |
| **G-203** | `batch_verify.do` never returns a failing exit status. |
| **G-205** | Pipeline cycle counts recorded nowhere; needed for the IPC check. |
| **G-206** | Quartus never compiled from this repo. |
| **G-207** | `finalProj` Quartus project exists on the Windows machine and in no local copy. Contents unknown. |
| **G-208** | "Use smart compilation" and "Advanced Physical Optimization = Off" circled in staff photos; both change PPA numbers. Instruction or observation? |
| **G-332** | The reference folder no longer ships `run_test.do`, `mem_dump.do` or `batch_verify.do`, and never had a single-cycle `compile.do` (§0.e). **CLOSED 2026-08-24:** replacements written at `SIM/baseline_reference/`, reaching into `Auxiliary/` read-only; `DOC/04_baseline_runbook.md` rewritten around them. |
| **G-204** | `mem_dump.do` exported 1024 of 2048 DTCM words, leaving the upper half unchecked. **CLOSED on the single-cycle side 2026-08-24:** the reference's own captures are now full 2048-word dumps and `SIM/baseline_reference/mem_dump.do` exports the same range. `SIM/RV32IMscMCU/mem_dump.do` widened to 2047 in the same pass. Set it back to 1023 only to diff against a 1024-word RARS golden. |
| **G-333** | **NEW.** The reference single-cycle testbench lost its `std.env.stop` auto-stop process, so a plain GUI *Run -All* never terminates there. Our `tb_RV32IMscMCU.vhd` and `tb_isa_directed.vhd` are unaffected — the ISA testbench stops itself at the sentinel and has a watchdog. |

## Design — no supplied code exists

| ID | Component | Specified by |
| --- | --- | --- |
| **G-301** | Division accelerator, 32-cycle unsigned shift/subtract | Figure 9, p9 |
| **G-302** | Basic Timer core | Figure 7, p7 |
| **G-303** | Interrupt controller | p13–p14 |
| **G-304** | CPU interrupt entry FSM | p15 |
| **G-305** | MMIO address decoder | Figure 5, p5 |
| **G-306** | GPIO buffer registers | §5, §6 |
| **G-307** | `div`/`divu`/`rem`/`remu` decode — masks exist, hardware does not | §2 |
| **G-308** | `mulh`/`mulhsu`/`mulhu` — scope undecided | §2 |
| **G-309** | Byte enables and sub-word load/store. `altsyncram` had no `byteena_a`; `CONTROL` detected `lb`/`lh`/`sb`/`sh` then discarded the width. **Built in Phase 3B**, awaiting verification. | §2 |
| **G-310** | Two-flop CDC synchroniser | Figures 10a/10b |
| **G-311** | Multi-output clock tree; all three ALTPLL copies expose only `c0` | Figure 1 |
| **G-312** | Edge detector / one-shot for KEY1-3 | §6.i |
| **G-313** | UART register layer | §6.iv, p12 |

## Design — defects in supplied code

Status column added 2026-08-23. **"repaired"** means the fix is written and gated behind
`G_ISA_REPAIR`; it becomes *closed* when Adar's `repair_check.do` and `run_isa.do` numbers are in
Phase 3A above. Every repair is a transcription from the reference pipeline — see §0.a for the
before/after line pairs.

| ID | Defect | Origin | Status |
| --- | --- | --- | --- |
| **G-321** | `andi` writes 0; `ori` computes AND | student regression; baseline `CONTROL.VHD:141` is correct | repaired (3A) |
| **G-322** | `lui` writes 0 | **lecturer's baseline**, `const_package.vhd:27` | repaired (3A) |
| **G-323** | Loads address `rs1 + 0` | **lecturer's baseline**, `IDECODE.VHD:94-101` | repaired (3A) |
| **G-324** | `sra` ≡ `srl` | **lecturer's baseline**, `EXECUTE.VHD:179` | repaired (3A) |
| **G-325** | Unsigned compares are signed | **lecturer's baseline**, `EXECUTE.VHD:9` | repaired (3A) |
| **G-326** | `mul` is 16×16 unsigned, lower half-words only | `EXECUTE.vhd:93-94` | open — Phase 3C, needs a question answered |
| **G-327** | test4's capture input never changes; `CAPISEL` stays at GND | supplied benchmark, current revision | open |
| **G-328** | **NEW.** Branch/`jal` displacement truncated one bit: `EXECUTE.vhd:66` slices `(PC_WIDTH-3 DOWNTO 0)`, dropping immediate bit 11, so branch range is ±2 KiB instead of the full 8 KiB PC. No benchmark reaches that far, so it is latent and the golden DTCMs still match. | **lecturer's baseline**, `EXECUTE.VHD` | repaired (3A) |
| **G-329** | **NEW.** `jalr` does not clear the target's bit 0 (`IFETCH.vhd:93`). Masked today by the word-granular ITCM dropping bits 1..0, but `pc_o`, `pc_plus4` and every link address carry the odd value. | **lecturer's baseline**, `IFETCH.vhd` | repaired (3A) |
| **G-330** | **NEW.** Our `DUT/RV32IMpipelinedMCU/` was an entire revision behind the reference and its wrapper referenced retired ports (`BPTRIGGER_o`, `stall_o`, `flush_o`, 8-bit counters) — it could not have compiled. | our tree, from the 2026-08-23 reference update | re-imported (3D) |
| **G-331** | `Auxilary/Ori/` — another student's pipeline. **CLOSED 2026-08-23:** permitted as a reference, never as code. It independently confirms the defect 6 and defect 7 repairs with identical expressions, and confirms no byte-enable reference exists anywhere. See §0.d. | another student, via Yehonatan | closed |

## Verification

| ID | Gap |
| --- | --- |
| **G-401** | No self-checking testbench anywhere. The whole reference tree contains two assertions, both in `Auxilary/Lab3/TB/tb_top.vhd`, both used as a stop mechanism. |
| **G-402** | Directed ISA testbench — built in Phase 2, and two bugs in it found and fixed in Phase 3B (a one-off store-count shift, and a sub-word case that could not fail). Awaiting its first real run. |
| **G-204** | `mem_dump.do` exports 1024 of 2048 DTCM words; the upper half is never checked. |
| **G-403** | Per-component test plans not written. |
| **G-404** | `Benchmark Apps/RV32IM/test1/output/RARS/DTCM.hex` is a stale golden — 16 words disagree with `DTCM.h`. Would fail a correct CPU. |
| **G-405** | GPIO suite never writes the DTCM, so no golden-memory comparison is possible. |

## Documentation and submission

| ID | Gap |
| --- | --- |
| **G-501** | Q1–Q13 unanswered. `DOC/03_open_questions.md`. Send Q1–Q3 now. |
| **G-502** | Submission `DOC/Readme.txt` not written. Template: `Auxiliary/Lab 5 - as submitted/DOC/readme.txt`. |
| **G-503** | `Final_report.pdf` not started. Template: `.../DOC/Report_lab5.pdf`. |
| **G-504** | No DE2-115 expansion-header pin table anywhere in the material. UART pins need the User Manual. Do not copy the DE10-Standard pins — `PIN_W15`/`PIN_AK2`/`PIN_AK3` are valid on F29 too, so it compiles cleanly and mis-routes silently. |
| **G-505** | Ten assumptions recorded and unconfirmed. `DOC/02_requirements_traceability.md` §10. |

---

# 6. Documents

| File | Contents |
| --- | --- |
| `DOC/01_source_inventory.md` | Every component: supplied or not, exact path, provenance, reuse verdict |
| `DOC/02_requirements_traceability.md` | Every address, bit field, mode and clock with its source; four verification cross-checks; ten assumptions |
| `DOC/03_open_questions.md` | Q1–Q13, each with a provisional decision so nothing blocks |
| `DOC/04_baseline_runbook.md` | The Windows procedure, staging script, and exact expected numbers. **Rewritten 2026-08-24** for the replaced reference: sections 2, 4, 5.2, 6 and 8 all changed, and section 8.1b covers the Phase 3A/3B measurement |
| `SIM/baseline_reference/` | `compile.do`, `run_test.do`, `mem_dump.do` — replacements for the scripts the reference lost, reaching into `Auxiliary/` read-only |
| `Auxiliary/Lab 5 - as submitted/README-import.md` | What was imported and why the two Lab 5 copies differ |

---

# 7. Next actions

*Updated 2026-08-23, after the reference replacement (§0) and Phase 3A/3D.*

## Adar — Lenovo

1. **One-time setup**, §0.2. Quartus 21.1, ModelSim 20.1, then the PowerShell staging block from
   `DOC/04_baseline_runbook.md` §3.
2. **Run 1 — Phase 0 baseline.** ~30 min. Fill in the Phase 0 results table. **This gates
   everything**; if the four counts do not reproduce, stop and report.
3. **Run 2 — Phases 1, 2, 3A.** Four result tables to fill. Steps in §0.3; the only source edit in
   the whole sequence is flipping `G_ISA_REPAIR` between step 3 and step 4.
   - step 3, repair OFF → **25** mismatches (and `repair_check.do` reports 25 failures)
   - step 4, repair ON → **43/43** on `repair_check.do`, **9** mismatches on `run_isa.do`, and the
     four benchmark counts unchanged
4. **Run 3 — Quartus.** Confirm **131,072** memory bits. The reference's own numbers to compare
   against are now in §0.c — note the pipeline figures all changed.
5. **Send the questions** (§0.6). **Q6 and Q14 first** — those two are the only ones now blocking
   implementation, and together they decide nine of the ten remaining ISA-suite mismatches. Q14 is
   new: it asks whether a conformant 32×32 `mul` is required, whether `mulh*` is in scope, and
   whether `div` belongs in the ALU at all given that §6.iii defines a division *accelerator*. Then
   Q1, Q2, Q3.
6. **Answer G-207 and G-208** — what is in `finalProj`, and whether the two circled Quartus settings
   were instructions.
7. ~~Answer G-331~~ — done: `Auxilary/Ori/` is another student's pipeline, usable as a reference
   only. §0.d records what it is worth.

## Yehonatan — MacBook

1. **Commit and push.** Still not done, and it is still the only thing standing between Adar and any
   of the above. Now covers Phase 1, 2, 3A and 3D plus the replaced reference folder.
2. **Phase 4's clock tree**, as far as Q2 allows — the ALTPLL needs regenerating for `c0`/`c1`/`c2`
   and all three existing copies expose only `c0`. This is now the next real design work: 3B is done
   and 3C is blocked on Hanan.
3. **Update the `DOC/` documents for the new reference.** `01_source_inventory.md` and
   `02_requirements_traceability.md` both describe the old Lab 5 tree — in particular the
   defect-provenance table is now five rows where it should be seven, and
   `04_baseline_runbook.md` still tells Adar to run `run_test.do` from a reference folder that no
   longer contains it.
4. **Prepare Phase 4's clock tree** as far as Q2 allows: the ALTPLL needs regenerating for
   `c0`/`c1`/`c2` and all three existing copies expose only `c0`.

## The gate between us

**Phase 3A changed what the gate is.** It used to be "no repairs before the numbers arrive". The
switch replaced that: both measurements now come out of one build in one sitting, so nothing is
blocked on waiting.

What still gates:

- **Phase 3C is blocked on Hanan**, not on us. Nine of the ten remaining ISA mismatches are there,
  and every one of them needs a question answered before it can be written without inventing
  requirements.
- **Phase 4 onward is gated on Run 1.** If the Phase 0 baseline does not reproduce, nothing built on
  top of it means anything, and that is still true no matter how much is written on the Mac.
- **A partial `repair_check.do` failure stops everything.** All 15 failing means the wrong
  configuration was compiled. Some failing means a repair is wrong, and that has to be understood
  before any further component is built.
