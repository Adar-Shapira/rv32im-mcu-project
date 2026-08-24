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

   **Then two tests that need nothing at all** — no images, no `app_bin`, and they do not care what
   `G_ISA_REPAIR` is set to. Run them first, because if either fails, nothing after it is meaningful:
   - `do run_sync.do` → **Phase 4A**, the CDC synchronizer. Expect `VERDICT: PASS`, zero failures in
     all three checkers.
   - `do run_decode.do` → **Phase 5A**, the address decoder, exhaustive over all 16,384 addresses.
     Expect `VERDICT: PASS`, failures 0, and the three totals **8192 / 29 / 8163**.

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
5. **Phases 5B and 6A — while `G_ISA_REPAIR` is still `TRUE`.** Do these *now*, before setting the
   switch back, so you do not pay for a second full recompile.

   **Both of them need `G_ISA_REPAIR = TRUE` and it is not arbitrary.** At `FALSE`, `lui` writes zero
   (defect 2), so GPIO test0's `lui t4,0x2 / addi / sw` sequences never form an address at or above
   `0x2000` — no MMIO store happens at all and there is nothing for either test to see. Both
   testbenches detect that and print `VERDICT: NOT APPLICABLE` rather than failing. Worth knowing for
   the report: **the two defects masked each other** — the missing region decode was invisible on the
   GPIO benchmarks precisely because `lui` was also broken.

   First stage GPIO test0's images. **The `M9K-intel` ones, not `Hexadecimal-Text`** — they are
   different programs and the `.h` copy carries a stale `−0x3000` `auipc` bias:

   ```
   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\ITCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\DTCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
   ```

   Expect a warning that `DTCM.hex` supplies 1024 words for a 2048-word memory. That is the shipped
   file's own length, not a staging mistake.

   - `do run_mmio.do` → **Phase 5B.** Expect `VERDICT: PASS`, and specifically
     **`DTCM WRITES ACCEPTED: 0`**. That one line is the fix: it says the DTCM refused every MMIO
     store. Also expect ~126 MMIO stores and `DTCM stores seen 0`.
   - `do run_gpio.do` → **Phase 6A.** Same images, nothing more to stage. Expect `VERDICT: PASS`,
     about **18 writes to each of the seven ports**, and ≥ 3 distinct `LEDR` values.
   - **Then restage for the last one — this is the only test that wants a different program.**
     Copy GPIO **`test1`**'s `M9K-intel` `ITCM.hex` and `DTCM.hex` over the same two `app_bin` files,
     and `do run_gpio_read.do` → **Phase 6B**. Expect `VERDICT: PASS`, and specifically **phase 3
     writes exactly 0** with ≥ 2 increments and ≥ 2 decrements. That test drives the switches and
     checks the *program's branches* follow what it read, which is why it is the strongest evidence
     in the set. **Put `test0`'s images back afterwards** or the two earlier tests will not reproduce.
   - **Notes from the wrapper — corrected 2026-08-24, the earlier wording was wrong.** Since Phase 6A
     the wrapper prints at most two notes, once each: an SFR **read** has no path yet and returns zero
     (that is Phase 6B), and an SFR **write** landed on one of the eight words that still have no
     peripheral. GPIO test0 writes only the four GPO words — which **do** take their writes — and
     reads nothing on the SFR page, so **on these two tests you should see neither note.** A write
     note here means a store went somewhere unexpected and is worth reading.
     *Why this changed:* the note used to say every SFR access was discarded. After Phase 6A that was
     false for exactly the accesses these tests make — it fired on test0's store to `PORT_LEDR`, a
     store `PORT_LEDR` now latches, and said the write was discarded immediately before `tb_gpio`
     printed that all seven ports held what was stored. Found by review.

6. **Now** set `G_ISA_REPAIR` back to `FALSE` before committing, unless we have agreed to flip the
   default.
7. Repeat step 2 in `SIM\RV32IMpipelinedMCU`. Note this directory was rebuilt for the revised
   pipeline — new file list in `compile.do`, and `golden.do` is now the wave script to prefer.

### Run 3 — Quartus (still Phase 1).

Open `Quartus\RV32IMscMCU\RV32IMscMCU.qpf`, compile.

- The top entity must resolve to `RV32IMscMCU`.
- **The Fitter will warn about unassigned pins. That is correct.** This is the *performance* revision
  and deliberately carries no pin assignments, so the PPA numbers describe the design and not the
  board. The pinned revision comes later, in Phase 14.
- **Four files were added to the project since the last Quartus run** — `ADDR_DECODER.vhd`,
  `SYNC.vhd`, `GPO_PORT.vhd`, `HEX_DECODER.vhd`. If Analysis & Synthesis reports an **unbound
  component**, the `.qsf` file list is the first place to look: there is no `SEARCH_PATH` in this
  project, so Quartus finds an entity only if the file is listed.
- **Pins are still not assigned, and now that matters more.** Phase 6A added 50 real board outputs
  (`LEDR_o[7..0]` plus six `HEX*_o[6..0]`). The Fitter will place them wherever it likes and the
  design still gives valid PPA numbers, which is what this revision is for. But **nothing can be
  tested on the board until they are assigned**, and the pin numbers are in no course file — see the
  block at the end of `RV32IMscMCU.qsf` and gap **G-504**.
- **The number that matters: embedded memory bits must be 131,072** (= 2 × 2048 × 32) — GPIO adds
  registers, not memory, so this figure must not move. If it reads
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
| 4A CDC synchronizer | Yehonatan ✔ | **Adar** | ready to run — frequency-independent |
| 4B Multi-output clock tree | — | **Adar needs Quartus** | blocked on Q2 *and* on the MegaWizard |
| 4C Reset-on-lock + SDC | Yehonatan | Adar | waits on 4B |
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
7. **`Auxiliary/hanan/` — Hanan's own lecture material for THIS lab.** Added 2026-08-24. 24 of the
   51 files carry his copyright and are authoritative for *method*: VHDL style, naming, verification
   technique, timing and power analysis. They are not a source of project requirements — the PDF in
   level 1 is — but where they state a rule, that rule binds our code.
8. **`Auxiliary/hanan/*_G.md` — Dr Guy Tel-Zur's material for course 361-1-4201.** A **different
   course**, and per the syllabus our **prerequisite**. 17 files: `The_Big_Picture`,
   `Single_Cycle_ Microarchitecture`, `Multi-Cycle`, `Pipelining_I`/`II`, `Branch_Prediction_I`/`II`,
   `Out-of-Order_Execution`, `Precise-Exceptions`, `ISA_Tradeoffs` ×3, `simd-architecture`,
   `DDCArv_Ch6`, `Admin`, `simulators`, `DatapathAndControlUnit`, `PipelineDesign`.
   **Legitimate as background, never as a requirement.** It is assumed knowledge for this lab, so
   citing it to explain *why* a design works is fine; citing it as "the course requires X" is not,
   because it is not this course.
9. General RISC-V / FPGA knowledge — only after the above, and stated as such.

## 2.1 What Hanan's own material settles

Read 2026-08-24. These are rules, not preferences, and the code has been checked against them.

| Rule | Source | Our state |
| --- | --- | --- |
| `_i`/`_o` ports; `_w` wire; `_q` **synchronous** register; `_r` **asynchronous/combinational** register; `_v` variable | `Useful name extensions.md` | Design files conform. **Testbench variables do not use `_v`** — a tidy-up, not a defect |
| **"Don't write Mixed PROCESS, is non synthesizable (ieee-1076.6 standard)."** A mixed process combines combinational and synchronous elements | `Sequential Code part7` | Conforms. `SYNC.vhd`'s two processes are pure synchronous; `DMEMORY.vhd`'s `misalign_check` is pure combinational and contains only a `report` |
| "Each Entity element in our design must be written in a separate `entity_name.vhd` file" | `Concurrent Code - Structural modeling` | Conforms |
| Assertions belong in one of three places: concurrent in the architecture, sequential in a process, or in the entity's passive part. Severities: note / warning / error / failure / fatal, and **failure is the default exit level** | `Advanced Design Verification.md` | Conforms — static asserts use `failure`, test failures use `error` |
| A PACKAGE needs a body **only** if it declares a FUNCTION or PROCEDURE | `Package (sub-library).md` | Conforms — all three packages declare only components/constants, so none has a body |
| `f_max` from the setup condition: `T_clk ≥ t_cq + max(t_pd(CL_i)) + t_su`. Hold: `t_cd(FF) + t_cd(CL) ≥ t_hold`. Positive clock skew *raises* `f_max`, negative lowers it | `Digital Logic Circuits - Timing Analysis.md` | The vocabulary and formulas for the Phase 14 PPA write-up. **"we strive in our design for balanced CL paths"** is the pipeline argument |
| `P_dynamic = f_CLK · N · C · V_DD²`, `P_static = I_leakage · V_DD` | `Digital Logic Circuits - Power Analysis.md` | Explains the reference's own numbers: +46.8% registers → +38.7% dynamic power |
| **`STD_LOGIC_ARITH` / `STD_LOGIC_SIGNED` / `STD_LOGIC_UNSIGNED` are "non-standard"**; VHDL-2008 provides `numeric_std_unsigned` / `numeric_std_signed` instead | `Enhancements in VHDL-2008.md` | Not a licence to change the reference's imports, but it *is* the explanation for defect 5 and belongs in the report |
| Local declarations inside a `generate` branch are explicitly legal and do not clash across branches | `Enhancements in VHDL-2008.md` | Validates `SYNC.vhd`'s per-branch `launch_q` |

**And one fact about the project itself, from the syllabus:** the summary project is worth **45% of
the course grade** (`CPUuarc_and_HWaccelerators_lab_syllabus_36114693_sem2026B.md`). Lecturer contact
`revoh@post.bgu.ac.il`. The VHDL conventions above trace to Pedroni, *Circuit Design with VHDL*,
which the syllabus lists as a course source.

## 2.2 ISMCE — the on-board validation loop, and a risk it creates

`Auxiliary/hanan/Validation using ISMCE.md` documents the hardware validation flow the assignment
requires (§8), and it changes the priority of something Phase 3B left as a footnote.

1. Load the `.sof` to the FPGA — **once per design cycle**.
2. Per application, recurring: import `ITCM.hex` and write it into the **physical** ITCM; same for
   `DTCM.hex`; **press KEY0 to run**; then export the physical DTCM to a `.hex`.
3. Run the same application in RARS to its endpoint, export a `DTCM.hex` from RARS, and compare the
   two files with **`TextDiff.exe`**.

**What makes that possible is `ENABLE_RUNTIME_MOD = YES` in the DTCM's `lpm_hint`** — and
`INSTANCE_NAME = DTCM` is the name ISMCE lists it under. Neither may be removed or renamed. Phase 3B
added `byteena_a` to that same `altsyncram`, and whether byte-enable mode and runtime modification
coexist cleanly is the one thing in 3B that could not be checked without the tool.

> **Adar, one check after the first Quartus compile of Phase 3B:** open ISMCE and confirm the `DTCM`
> instance still appears and can still be read and written. If it has gone, **say so before changing
> anything** — sub-word MMIO access and ISMCE validation are both mandatory, so a conflict between
> them is a question for Hanan, not something to work around quietly. Noted in
> `DUT/RV32IMscMCU/DMEMORY.vhd` at the `lpm_hint` line.

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

## Phase 4 — Clock tree, reset, CDC

Split, because only one part of it is unblocked. **4A is built; 4B and 4C wait on Q2.**

### Phase 4A — the CDC synchronizer  ·  **built, awaiting verification**

Done 2026-08-24. Closes **G-310**. Deliberately taken first: it is the only part of Phase 4 that is
**frequency-independent**, so Q2 cannot invalidate it.

| Done | What |
| --- | --- |
| ✔ | `DUT/RV32IMscMCU/SYNC.vhd` — Figures 10a/10b, generic width, generic stage count, and the mandatory domain-A launch register behind `GEN_SRC_REG` |
| ✔ | `TB/RV32IMscMCU/tb_sync.vhd` — self-checking, four properties, prints its own verdict and stops itself |
| ✔ | `SIM/RV32IMscMCU/run_sync.do`, and both files added to `compile.do` |
| ✔ | `aux_package.vhd` — component declared, so the divider, the KEY edge detectors and the UART all use one verified implementation instead of three inline copies |

**The figure was read, not assumed.** The plan said "two-flop synchroniser" and the traceability
document recorded the *rule* but never the structure. Reading page 10 of the PDF: **it is three
flip-flops, not two.**

| Domain | Contents | Clock |
| --- | --- | --- |
| A (slow) | `Comb logic` → one `D Q` | `MCLK` |
| B (fast) | `Din` → `D Q` → `Ds` → `D Q` → `Dout` "stable" | `DIVCLK`, both |

The page 10 prose makes the domain-A register mandatory: *"It's fundamental to have a flip-flop to
synchronize every signal that is driven by combinational logic (combo) in domain A before sending it
to domain B."* So it lives inside the entity, enabled by default — a launch register that is "the
caller's responsibility" is a launch register that gets forgotten.

Figure 10b draws the block as the divider uses it: a `Sync` box on `divclk` holding **two**
independent two-DFF chains, `Read data1 → Ain` and `Read data2 → Bin`. This entity is one chain;
Figure 10b's box is two instances. Splitting it that way is what makes it reusable for the
single-bit crossings later instead of being welded to two 32-bit operands.

**The one assumption, stated as such.** A two-stage synchronizer on a multi-bit **bus** is only sound
if the bus is stable across the crossing — individual bits can resolve on different destination
cycles, so a changing bus can present a value that never existed at the source. Figure 10b does it
to two 32-bit operands anyway, and for the divider that is fine: the CPU writes the operands, and
only *then* does the enable cross. Recorded in the RTL header and in
`DOC/02_requirements_traceability.md` §5. Any later crossing that cannot guarantee stability needs a
handshake, not this block.

**A side finding that strengthens Q6.** Figure 10b labels its inputs `Read data1` and `Read data2` —
this project's own register-file port names. So the divider's operands come from the register file,
not the data bus. That is now **two figures** pointing at "core-internal" for the divider registers
(Figure 3 wires `Ain`/`Bin` to the ALU operands) and none pointing the other way.

**What the test can and cannot prove.** It checks the latency from *both* sides — that the value is
**not** out after `STAGES-1` edges, and **is** out after `STAGES`. The first half is the one that
matters: it is what fails if the chain is ever shortened to a single register, which is how a
synchronizer quietly dies in a refactor. The clock ratio is 70 ns : 30 ns, coprime, so the source
edge lands at every phase relative to the destination edge. **It does not reproduce metastability —
no RTL simulator can.** That is a timing-analysis property and it belongs in the SDC (4C).

#### ▸ Adar's results — Phase 4A

`SIM\RV32IMscMCU` → `compile.do`, then `do run_sync.do`. No images, no `app_bin` staging.

- stimulus: passed ____ , failed ____
- monitor:  passed ____ , failed ____
- latency:  passed ____ , failed ____
- **VERDICT line:** ____________________

Expect PASS with zero failures everywhere. This one does **not** depend on `G_ISA_REPAIR`.

### Phase 4B — the multi-output clock tree  ·  **blocked, and not for the reason the plan said**

- **Blocked on Q2** for the ratios: the document states no numeric frequency anywhere except
  `baseclk50MHz` inside the Figure 1 image. `SMCLK = 20 MHz` is derived only from `FREQ_5K`
  arithmetic; `MCLK` and `ACCELCLK` are unstated.
- **And blocked on a tooling limit that was mis-scoped.** The plan said "regenerate the ALTPLL with
  `c1`/`c2`". Reading `PLL.vhd`: the wizard emitted `port_clk1`…`port_clk5` as strings, but the
  `altpll` **component declaration contains only `clk0_divide_by` / `clk0_multiply_by` /
  `clk0_duty_cycle` / `clk0_phase_shift`** — there are no `clk1_*` or `clk2_*` generics in the file.
  Adding them means asserting generics that are not written down anywhere we have, which is the same
  unverifiable-megafunction-parameter risk already outstanding from Phase 3B's `byteena_a`. One of
  those is acceptable; stacking two in a tree nobody has compiled is not.
- **Two ways forward, for Adar to decide with Quartus in front of him:**
  1. Run the MegaWizard on `PLL.vhd` and let it emit a real three-output instance. Correct, and
     trivial with the tool open. **Preferred.**
  2. Instantiate the existing, already-synthesised single-output `PLL` wrapper three times, one per
     clock. Costs 3 of the device's 4 PLLs (Lab 5 uses 1) and gives three independently-locking
     clocks with no defined phase relationship — acceptable here only *because* every crossing goes
     through 4A's synchronizer, but strictly worse than one PLL with three phase-related outputs.

  Either way the interface should be a `CLOCK_TREE` entity with `mclk_o`/`smclk_o`/`accelclk_o`, so
  the choice stays an implementation detail behind a stable boundary.

### Phase 4C — reset release on PLL lock, and the SDC  ·  **waits on 4B**

- Synchronise PLL `locked` into reset release in the top wrapper. Precedent:
  `Auxilary/Lab4/DUT/fpga_hw_interface.vhd` captures `pll_locked`. Note
  `PROJECT_EXPLANATION.md` §9.3 says the reference leaves `locked` **unused** and that a production
  design would hold reset until lock — so this is an improvement over the reference, and the report
  should say so.
- Constrain all three clocks and every crossing in the SDC, starting from
  `Auxilary/RV32I/QUARTUS/SDC/RISCV_simple.sdc`. Needs the frequencies, so it needs Q2.
- **Do not** mistake `IFETCH.vhd:73-82` for a synchroniser — verified again: it is
  `IF rst_i='1' THEN rst_q<='1' ELSIF rising_edge THEN rst_q<=rst_i`, a single flop with an async
  preset.
- **Exit:** measured 20 MHz `smclk`, deterministic reset, no unconstrained cross-domain path.

Gaps: **G-310 closed by 4A**; G-311 open. 4B/4C blocked on **Q2**.

## Phase 5 — Bus interface and DTCM  ·  Yehonatan writes · Adar verifies

Split in two, for the same reason 4A was taken before 4B: the decode function is provable on its
own, exhaustively, with no dependence on the core, on the peripherals, or on any open question.
Wiring it in is a separate, riskier step that changes the core's ports.

### Phase 5A — the address decoder  ·  **built, awaiting verification**

Done 2026-08-24. Closes the decode half of **G-305**.

| Done | What |
| --- | --- |
| ✔ | `DUT/RV32IMscMCU/ADDR_DECODER.vhd` — Figure 5's "Optimized Address Decoder": region split, SFR page qualifier, one-hot chip select per mapped SFR word, lane-accurate `unmapped_o` |
| ✔ | `const_package.vhd` — the MMIO map as data: `DATA_ADDR_WIDTH`, `SFR_CS_NUM`, twelve `CS_*` indices, and `SFR_LANE_MASK`, the lane-by-lane specification |
| ✔ | `TB/RV32IMscMCU/tb_addr_decoder.vhd` — **exhaustive over all 16384 addresses**, five properties, prints its own verdict and stops itself |
| ✔ | `SIM/RV32IMscMCU/run_decode.do`, and both files added to `compile.do` |
| ✔ | `aux_package.vhd` — component declared, so the Phase 6–9 and 12 peripherals all attach to one decoder |

**The structure came out of the addresses, not out of a guess.** The twenty registers of §5 and §6
occupy exactly **twelve consecutive 32-bit words**, and no register straddles a word boundary. So the
chip-select index *is* the word offset, `addr(5 DOWNTO 2)` — no lookup table. That is precisely what
Figure 5 draws: one CS per word, `A0` separating the two registers that share it.

**Two things the benchmark sources settle, and they change Phase 6.**
`Auxiliary/Benchmark Apps/GPIO/test0/asm-code/test0.s:21-28` is

```asm
li  t4,PORT_HEX1     # 0x2005
sw  t0,0(t4)         # write to PORT_HEX1
```

Every MMIO write in every supplied benchmark is a **word store to a byte address**, odd addresses
included — confirmed again at `Intrrupt-based IO/test1/asm-code/01_func.s:17-20`, where an `srli`
places the value in bits 7..0 before the `sw`.

1. On the I/O side `A1..A0` are the **register selector**, not an offset into the data. Figure 5
   wires the latch inputs `D0..D7` to `Data<7..0>` unconditionally.
2. So the MMIO write path must **not** reuse the lane replication and `byteena_a` added in Phase 3B.
   Those are right for the DTCM and wrong here. This is now in the RTL header so Phase 6 cannot
   forget it.

**The bug this closes, stated exactly.** `MA_WIDTH = 13`, so the core's DTCM address is
`alu_res_w(12 DOWNTO 2)` and bit 13 — the one bit that means "SFR, not DTCM" — is never read. The
twenty registers alias onto DTCM words 0..11, and words 0..7 are the whole vector table:

| MMIO register | aliases to | which holds |
| --- | --- | --- |
| `PORT_LEDR` `0x2000` | word 0 | the RESET vector |
| `PORT_HEX0/1` `0x2004` | word 1 | TYPE `04h`, UART error |
| `PORT_HEX2/3` `0x2008` | word 2 | TYPE `08h`, UART RX |
| `PORT_HEX4/5` `0x200C` | word 3 | TYPE `0Ch`, UART TX |
| `PORT_SW` `0x2010` | word 4 | TYPE `10h`, Basic Timer |
| `PORT_PB` `0x2014` | word 5 | TYPE `14h`, KEY1 |
| `UTCL`/`RXBUF`/`TXBUF` `0x2018` | word 6 | TYPE `18h`, KEY2 |
| `BTCTL1/2` `0x201C` | word 7 | TYPE `1Ch`, KEY3 |

Every one of the eight vectors is aliased by a register the benchmarks actually write, and the
interrupt suites write the HEX displays from inside their own handlers. Vector words verified
against all four benchmark DTCM images — `DOC/02_requirements_traceability.md` §4.1.

**Full decode, not partial.** `A12..A6 = 0` is checked too, so `0x2040` does not alias onto `0x2000`.
Figure 2 calls the SFR page "distributed among many I/O devices, **not all used**", so unused
addresses exist by design and must not land on used ones — and `unmapped_o` only means anything under
a full decode. Cost: a 7-input zero-compare. If Phase 14 finds this on the critical path, dropping
`A12..A6` is the cheapest thing to give up; **never drop `A13`**, that is the split itself.

**The map is derived twice, on purpose.** `CHECK 0` in the testbench holds `SFR_LANE_MASK` against an
address list transcribed independently from `io_map.s`, lane by lane over the whole page. So the run
proves *const_package agrees with the assembler* and *the RTL agrees with const_package*. A single
derivation only ever proves the RTL matches itself — the same discipline that caught two real bugs in
Phase 2's own work. Both derivations were also replayed outside VHDL before committing: they agree on
all 16384 addresses, and the totals are 8192 / 29 / 8163.

**Two things 5A deliberately does not do.** It is not instantiated — the Phase 1 exit criterion still
holds and the four cycle counts must be unchanged. And it takes no `MemRead`/`MemWrite`, because
Figure 5 qualifies with those *at the peripheral*, not at the decoder. Keeping it a pure function of
the address is what makes an exhaustive test meaningful.

**Naming deviation, stated openly.** Figure 5 labels its chip selects `CS1`, `CS6`, `CS7` for
`PORT_LEDR`, the HEX0/1 pair and `PORT_SW`. No arithmetic relation to the addresses reproduces those
three numbers, so the figure's numbering is treated as illustrative and the constants are named after
the registers. The figure's *structure* is unchanged.

#### ▸ Adar's results — Phase 5A

`SIM\RV32IMscMCU` → `compile.do`, then `do run_decode.do`. No images, no `app_bin` staging.

- addresses swept: ____ (expect 16384)
- DTCM bytes: ____ (expect **8192**) · mapped SFR bytes: ____ (expect **29**) · unmapped: ____ (expect **8163**)
- failures: ____
- **VERDICT line:** ____________________

Independent of `G_ISA_REPAIR`. If `CHECK 0` fails, the **specification** is wrong and the RTL may be
a faithful implementation of it — fix `const_package.vhd`, not the RTL.

### Phase 5B — wire it in  ·  **built, awaiting verification**

Done 2026-08-24. Closes the rest of **G-305**.

| Done | What |
| --- | --- |
| ✔ | `DMEMORY.vhd` — new `dtcm_cs_i`, and `wren_a` is now `MemWrite AND dtcm_cs_i`. One AND gate; that is the whole fix |
| ✔ | `RV32IM_CORE.vhd` — a functional data-bus port group, and the load region mux |
| ✔ | `RV32IMscMCU.vhd` — `ADDR_DECODER` instantiated where Figure 1 puts the `BUS Interface Logic`; read-return stub; `dtcm_cs_o` / `unmapped_o` added to the observation group |
| ✔ | `aux_package.vhd` — all three component declarations brought back in step |
| ✔ | `TB/RV32IMscMCU/tb_mmio_alias.vhd`, `SIM/RV32IMscMCU/run_mmio.do`, `compile.do` reordered so the decoder compiles before the top that instantiates it |

**Where each piece went, and why there.** The DTCM stays inside the core: Figures 1 and 3 both draw
it there. What crosses the boundary is the *request*. The decoder sits at the MCU level, because
Figure 1 puts the `BUS Interface Logic` box between the core and the peripherals — so the core stays
a CPU and every peripheral of Phases 6–9 and 12 attaches to one decoder instead of each re-deriving
the map.

**The port group is separate from the Signal-Tap ports, deliberately.** `alu_res_o`,
`dtcm_data_wr_o` and `MemWrite_ctrl_o` already carry the address, the write data and the write
strobe, and reusing them would have been less work. It would also have been a bug: §7 requires the
Signal-Tap pins to be removable through a generate, and a bus that depends on them cannot be
removed.

**`MemOp` is not on the bus.** A peripheral does not need the access width — Figure 5 wires every
latch input `D0..D7` to `Data<7..0>` unconditionally, and the benchmarks reach byte registers with a
word store. Width only matters to the DTCM, which is inside the core.

**A mux, not a tri-state, and this one is an Assumption.** Figure 1's "Bi-directional Data BUS
(reminder)" arrow points at the buses on the **peripheral** side of the `BUS Interface Logic`, and
Figure 5 draws the tri-state at the peripheral (`PORT_SW` on `CS7 · MemRead`). So the core-to-bus
link is not where the figures put the shared driver, and `BidirPin` moves to **Phase 6**, where it
will have a real second driver instead of being a one-driver bus with a keeper. Figure 3 does show a
buffer symbol below the DTCM whose connectivity **cannot be resolved at the resolution of the
supplied raster** — if it turns out to be a tri-state onto a shared core-internal bus, the load mux
in `RV32IM_CORE.vhd` is the single place that changes.

**The Phase 1 criterion still holds, and it was checked rather than assumed.** None of the four Lab 5
benchmarks can *form* a data address at or above `0x2000`. From the shipped `ITCM.hex` images: not
one of the four contains a single `lui`, and their only large-base instruction is `auipc`, whose
immediate is **0 in all 31 occurrences across the four**. Every base is therefore a PC value, the
programs are 29–62 instructions long, and the largest displacement a load or store can add is
`+2047`:

| Test | Max base | Bound | SFR page at 8192 |
| --- | --- | --- | --- |
| test1 | 44 | 2091 | no |
| test2 | 44 | 2091 | no |
| test3 | 160 | **2207** = `0x89F` | no |
| test4 | 68 | 2115 | no |

So `dtcm_cs` is `'1'` on every access those programs make, the gated write enable equals the ungated
one, and the four counts must be bit-identical. That is a bound from the address-formation
instructions, not a full symbolic execution — the definitive check is still Adar's numbers.

### ⚠ The finding that matters most in this phase: the two defects masked each other

`tb_mmio_alias` **requires `G_ISA_REPAIR = TRUE`**, and the reason is worth putting in the report.

Disassembling `Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex`, every one of test0's
seven stores is reached as:

```
lui  t4,0x2        -- ITCM word 4,  0x00002eb7
addi t4,t4,offset  -- ITCM word 5
sw   t0,0(t4)      -- ITCM word 6
```

At `G_ISA_REPAIR = FALSE`, `lui` writes **zero** — defect 2, `IDECODE.vhd:111` forces `lui_imm_w` to
all zeros in that configuration. So `t4 = 0 + offset`, and the seven stores land on byte addresses
**0, 4, 5, 8, 9, 12, 13** — all inside the DTCM, none of them ever reaching `0x2000`.

**So the missing region decode was invisible on the GPIO benchmarks precisely because `lui` was also
broken.** Repairing `lui` is what exposes the aliasing. Two defects, each hiding the other.

The testbench detects `G_ISA_REPAIR = FALSE` and reports **NOT APPLICABLE** with that explanation
rather than a FAIL, because a FAIL there would send someone hunting a decoder bug that is not present.

**Also verified from the same disassembly, rather than estimated:** `N` really is at DTCM word 0 —
the first record of the shipped `DTCM.hex` is `:0400000000000004f8`, and `short_delay = 4`. The loop
body is ITCM words 4–29, one iteration is **32 instructions** (23 body + 8 delay + 1 `j`), so
`RUN_CYCLES = 600` gives 18 full iterations and about 126 MMIO stores.

**Watch the timing.** The critical path is already ITCM address → `ID|Mux19` → DTCM address, with a
**20 ns** relationship (the DTCM latches on the inverted clock) and 1.351 ns slack at 26.81 MHz. The
decoder and the load mux both land inside it, on top of Phase 3B's extract-and-extend mux.

### What an adversarial review of this phase found, and changed

Phase 5B was written, then reviewed by five independent readers with distinct lenses (compilability,
behavioural equivalence, testbench soundness, interface consistency, spec fidelity), and every
finding was then given to a separate reader whose job was to **refute** it. Four survived. Three were
real and are fixed; one is recorded as G-334. This is worth writing down because two of them would
have cost a day each.

**1. BLOCKER — Quartus could not have compiled it.** `Quartus/RV32IMscMCU/RV32IMscMCU.qsf` lists
twelve `VHDL_FILE` assignments and `ADDR_DECODER.vhd` was not among them, while `RV32IMscMCU.vhd` —
the `TOP_LEVEL_ENTITY` — now instantiates it. There is no `SEARCH_PATH` in that project, so Quartus
resolves a component only from the file list: Analysis & Synthesis would have failed to bind
`addr_decoder`. `compile.do` had been updated; the `.qsf` had not. **Fixed**, and `SYNC.vhd` added at
the same time (uninstantiated, so synthesis prunes it and it costs nothing in the resource tables).

*The general lesson, worth carrying into every later phase: this project has **two** file lists, and
ModelSim passing says nothing about Quartus.*

**2. MAJOR — the test could not detect the absence of the fix.** As first written, P1 asserted on
`dtcm_cs_o`, the **decoder's** chip select. But the fix is the AND gate in `DMEMORY.vhd`
(`wren_w <= MemWrite_ctrl_i AND dtcm_cs_i`). Delete that gate and the decoder is still perfectly
correct: `dtcm_cs_o` still deasserts on every MMIO address, P2/P3/P4 all hold, and the testbench
prints **"VERDICT: PASS — every MMIO store was kept out of the DTCM"** while all ~126 stores land in
DTCM words 0–3. Nothing else in the repository would have caught it, because every other test avoids
`0x2000+` by construction.

**Fixed** by making the gate itself observable: `dtcm_wren_o` now comes out of `dmemory`, through the
core, into the MCU's observation group, and P1 asserts that **the DTCM accepted exactly zero writes
across the run** — the right number, because test0 never stores to the DTCM. Remove the gate and P1
fires ~126 times. The chip select proves the decode; only the enable proves the fix.

**3. CONFIRMED — the testbench sampled on the wrong clock edge.** It sampled `rising_edge(clk_i)`
and the comment cited `tb_isa_directed.vhd` as the authority for doing so. That file samples on the
**falling** edge and its header says why: `DMEMORY` drives its `altsyncram` with
`wrclk_w <= NOT clk_i`, so the DTCM latches when `clk_i` falls, and *"sampling on the rising edge
would race the instruction fetch."* **Fixed** — falling edge, with the real reasoning. This matters
more now than it did before: `dtcm_wren_o` is only meaningful at the edge the RAM actually uses.

**4. CONFIRMED — a documented rationale was provably false.** The header and `run_mmio.do` both
claimed that a decoder fed the wrong address slice would leave `dtcm_cs` asserted, *"P1 would never
fire, and only P2 would notice."* Wrong: P1 read `alu_res_o(13)` straight off the debug port, which a
mis-slice does not affect, so P1 **would** fire — and P1 firing strictly implied P2 firing, making
the "P1 alone" branch of the FAIL message name an unreachable outcome. **Fixed** in both files, and
the FAIL text now says how to actually read a failure.

**Refuted, correctly:** a claim that the `G_ISA_REPAIR = FALSE` case would fail confusingly (the
guard already handles it), and a claim that `run_decode.do`'s "not wired in" wording had gone stale
(it is phase-scoped and still true — `tb_addr_decoder` does instantiate the decoder standalone).

**Also verified independently, outside VHDL, before committing:** all eight touched files are
structurally balanced; every string literal is ASCII-only; all four entity/component pairs match port
for port **in order**; all three internal instantiations associate every port; and the two older
testbenches omit only the three new `OUT` ports, which is legal.

#### ▸ Adar's results — Phase 5B

`SIM\RV32IMscMCU` → `compile.do`. **Set `G_ISA_REPAIR := TRUE` first**, and stage GPIO test0's
`M9K-intel` images as `app_bin\ITCM.hex` / `app_bin\DTCM.hex`. Then `do run_mmio.do`.

- MMIO stores seen: ____ (expect ~126) · DTCM stores seen: ____ (expect **0**)
- **DTCM WRITES ACCEPTED: ____ (must be exactly 0 — this line is the fix)**
- least hits, any address: ____ (expect ~18, must be ≥ 2) · P2 cycles skipped: ____ (a handful)
- failures: ____
- **VERDICT line:** ____________________



Then re-run **Run 2** in full. The four benchmark counts and `run_isa.do` must be unchanged from what
you recorded before this phase — that, not `run_mmio.do`, is what proves the DTCM still works.

Gaps: G-305 (closed by 5A + 5B), G-309.

## Phase 6 — GPIO  ·  Yehonatan writes · Adar verifies

Split three ways, because only the output side is unblocked. The order matters: 6A needs no read
path, 6B builds the read path, 6C needs a question answered.

### Phase 6A — the seven GPO ports  ·  **built, awaiting verification**

Done 2026-08-24. Closes the output half of **G-306**.

| Done | What |
| --- | --- |
| ✔ | `DUT/RV32IMscMCU/GPO_PORT.vhd` — Figure 5's output-port interface, instantiated seven times |
| ✔ | `DUT/RV32IMscMCU/HEX_DECODER.vhd` — **used as is** from Lab 4, body byte-identical, md5 `56f2f16645e9bb4643c3a113c36e49c4` |
| ✔ | `RV32IMscMCU.vhd` — 7 × `gpo_port` + 6 × `hex_decoder`, and the board outputs `LEDR_o[7..0]`, `HEX0_o`…`HEX5_o[6..0]` |
| ✔ | `RV32IM_CORE.vhd` — exports `mclk_o`, transitionally; see below |
| ✔ | `TB/RV32IMscMCU/tb_gpio.vhd` + `SIM/RV32IMscMCU/run_gpio.do`, `compile.do` and the `.qsf` updated |

**"Use as is" is a checkable claim, not a courtesy.** `HEX_DECODER.vhd` is Lab 4's file with a
provenance header prepended and nothing else touched — the body's md5 matches the original exactly.
Its port names stay `bin`/`seg` rather than being renamed to the `_i`/`_o` convention, because
renaming would have made "unchanged" false.

**One deliberate deviation from Figure 5, with three reasons.** The figure draws a level-sensitive
`D-Latch ... En`. `gpo_port` is an edge-triggered register with an enable instead:

1. Hanan's own material is explicit about not writing what infers a latch
   (`Auxiliary/hanan/Sequential Code part7 - System Design Principles.md`), and a Cyclone IV has no
   latch primitive — a transparent latch becomes combinational feedback.
2. The course's **own** board-interface reference does it this way:
   `Auxilary/Lab4/DUT/fpga_hw_interface.vhd` registers its SW/KEY inputs as
   `IF rising_edge(clk_2MHz) THEN IF key_pressed(n) = '1' THEN` — an enabled register, exactly this
   structure.
3. Behaviour is identical here. Single-cycle: the address, the write data and `MemWrite` are stable
   for the whole store cycle, so a latch transparent for that cycle and a register capturing at its
   end settle to the same value.

**Which four bits the display shows — settled by the software, not guessed.**
`Intrrupt-based IO/test1/asm-code/01_func.s:17-20` does `andi s1,a0,0x000000F0` then `srli s1,s1,4`
then `sw` — the program shifts the digit into bits 3..0 before storing. So the encoder takes
`q_o(3 DOWNTO 0)`. Bits 7..4 are stored (Figure 5 draws D0..D7), have no load, and are pruned.

**Full lane decode, one step stricter than the figure.** Figure 5 gives `PORT_LEDR`'s latch only
`CS1 · MemWrite` with no `A0` term, because in the GPIO-only subset it draws nothing shares that word.
Every port here is qualified by its exact lane anyway — the same choice `ADDR_DECODER` already made,
for the same reason: otherwise a store to `0x2001` would be flagged by `unmapped_o` **and** still land
in `PORT_LEDR`, and having the report disagree with the hardware is worse than being stricter than the
figure. No supplied benchmark writes any of these addresses off-lane.

**The reset, and a correction to how this was first recorded.** `gpo_port` was written with a
*synchronous* reset and no initial value. The four testbenches that instantiate this design drive
reset high from 0 ns and low at 80 ns with the first rising clock edge at **100 ns**, so a
synchronous reset never sees an active edge at all — the register would have left reset holding `'U'`,
straight onto a board pin. Both were changed in one edit: the reset is asynchronous *and* `q_q`
carries an initial value, following `fpga_hw_interface.vhd`'s own `:= (OTHERS => '0')`.

**This was first written up as "a real bug found by tracing timing", and that overstated it.** With
the initial value present, a synchronous reset would leave `"0…0"`, not `'U'` — so the symptom
described cannot occur in the delivered code. The `'U'` hazard was real in the first draft and was
fixed twice over. The honest statement: the reset is asynchronous for **consistency** — every other
clocked element in this design resets asynchronously, and an asynchronous reset does not depend on a
power-up value being right — and the 80 ns/100 ns argument is a good reason not to use a synchronous
reset here, but not a live-bug argument. Caught by review; the corrected reasoning is in
`GPO_PORT.vhd`.

**`mclk_o` — transitional, and it is a correctness fix, not tidiness.** The core generates its own
`mclk` from its internal PLL, so at `MODELSIM = 0` the core runs at the PLL rate while `clk_i` is
still the 50 MHz board clock. A peripheral clocked from `clk_i` would sample a `MemWrite` pulse
belonging to a different clock rate and could capture twice or miss entirely. Exporting `mclk` is the
smallest correct fix available before Phase 4B moves the clock tree up to this level, at which point
the port disappears.

**Assumption — the reset value.** Nothing states what a GPO port holds after reset, and Figure 5
draws no reset on the latch at all. Zero is used: LEDs off, every display showing `0`. Recorded as
A13 in `DOC/02_requirements_traceability.md`.

**Why the test is a scoreboard and not a waveform.** `PORT_HEX0` and `PORT_HEX1` share one chip select
and are separated only by `A0`, so the natural bug is a store to one updating both. test0 writes the
**same value to all seven ports in the same iteration**, so on a waveform that bug is invisible —
every display would show the right digit anyway. Only a model that knows which port was addressed can
see it. The testbench also transcribes the 7-segment table **independently** of `hex_decoder.vhd`, so
comparing against it is a real check of the display path rather than a tautology.

#### ▸ Adar's results — Phase 6A

Part of **Run 2 step 5** — same staging as `run_mmio.do`, and needs `G_ISA_REPAIR = TRUE`. Then
`do run_gpio.do`.

- writes seen — LEDR: ____ · HEX0: ____ · HEX1: ____ · HEX2: ____ · HEX3: ____ · HEX4: ____ · HEX5: ____
  (expect about **18** each; **any zero fails P3**)
- distinct LEDR values: ____ (expect ~17, must be ≥ 3)
- failures: ____
- **VERDICT line:** ____________________

Reading a failure: one HEX of a pair failing while its partner is correct is **cross-talk on a shared
chip select** — look at `lane_en_i` on the two `P_HEXn` instances. All six failing together points at
the low-nibble wiring or `HEX_DECODER.vhd`. P3 alone means the program did not run.

### Phase 6B — the read path  ·  **built, awaiting verification**

Done 2026-08-24. Closes the rest of **G-306**.

| Done | What |
| --- | --- |
| ✔ | `DUT/RV32IMscMCU/BIDIRPIN.vhd` — **used as is** from Lab 3, body byte-identical, md5 `ab12d81dcdc85d91071b077359833bbd`. The block Figure 1's "Bi-directional Data BUS (reminder)" link points at |
| ✔ | `RV32IMscMCU.vhd` — `SW_i[7..0]`, the SW synchroniser, eight tri-state readers, a bus terminator, and the read half of the stub notice retired |
| ✔ | `GEN_GPO_READBACK` generic — the seven GPO read-back paths of Figure 5, behind a switch because they rest on assumption **A15** |
| ✔ | `TB/RV32IMscMCU/tb_gpio_read.vhd` + `SIM/RV32IMscMCU/run_gpio_read.do`, `compile.do` and the `.qsf` updated |

**The verification is the best in the project so far, and it is not an assertion on
the bus.** GPIO test1 *branches* on what it reads, so the program's own control flow
is the oracle. From the disassembled image, words 4–7 are
`lui x29,0x2 / lw x29,16(x29) / andi x7,x29,1 / bne x7,x0,+8` — read `PORT_SW`,
mask bit 0, branch. So:

| `SW_i` | test1 does | observable |
| --- | --- | --- |
| `0x01` | takes the SW0 branch, `addi x5,x5,1` | the counter **increases** |
| `0x02` | takes the SW1 branch, `addi x5,x5,-1` | the counter **decreases** |
| `0x00` | takes **neither** — `print2all` is never called | **nothing is written at all** |

The third row is the sharp one. An undriven read bus reads `'Z'`, a doubly-driven
one reads `'X'`, and either sends a branch somewhere — which shows up as writes
appearing when there should be none. *Exactly zero writes* is very hard to produce
by accident.

**A terminator whose enable cannot drift.** Inside an FPGA there is no bus keeper,
so with every tri-state off the bus would be `'Z'` and the core would mux that into
the register file. One extra driver supplies zeros when nothing else drives, and
its enable is `rd_en_w = RD_NONE` — derived from the *same vector* that gates the
readers, so the terminator and the readers cannot disagree. A hand-written
complement that drifted by one term would give `'X'` (two drivers) or `'Z'` (none),
and neither is simulatable here. A `process(all)` also asserts the at-most-one-hot
property, at `warning` severity so a startup metavalue does not abort a run.

**The switches are synchronised, which Figure 5 does not ask for.** A switch is a
mechanical contact with no clock, so its value can change arbitrarily close to an
edge — the textbook case for Figures 10a/10b, whose page 10 states the rule
outright. This is the **first real use of `SYNC.vhd`** from Phase 4A, with
`GEN_SRC_REG => FALSE` because there is no source domain to launch from. Two
flip-flops, and Lab 4's own board interface registers its SW inputs too. Two cycles
of latency on a hand-operated switch is not observable.

**A testbench bug I introduced and caught by tracing the boundary.** When `SW_i`
changes, the loop iteration already in flight has *already* read the old value and
completes with the old branch, so exactly one stale store lands in the new phase.
Scoring it fails a correct design — phase 3 would see "a write with both switches
clear", which is precisely what P3 exists to catch. Hence `SETTLE_CYCLES = 60`,
one full 42-instruction iteration plus the synchroniser's two.

**What this does not cover, and it is registered rather than left implicit.** The
seven GPO read-back tri-states are implemented and **exercised by nothing** — no
supplied benchmark reads `PORT_LEDR` or a `PORT_HEXn`; the only MMIO reads anywhere
are three `lw ... PORT_SW`. Gap **G-407**. Closing it needs a small program of ours
that stores a byte to a GPO port and loads it back — the same shape of gap as G-406.

#### ▸ Adar's results — Phase 6B

**Different staging from every other test: GPIO `test1`, not `test0`.** Then
`do run_gpio_read.do`. Put test0's images back before re-running `run_mmio.do` or
`run_gpio.do`.

- phase 1 `SW=0x01`: writes ____ , increments ____ (need ≥ 2)
- phase 2 `SW=0x02`: writes ____ , decrements ____ (need ≥ 2)
- phase 3 `SW=0x00`: writes ____ — **must be exactly 0**
- stores in settle windows: ____ (about 1 per boundary is normal)
- failures: ____ · **VERDICT line:** ____________________

Reading a failure: phase 3 showing writes means the read path returns something
non-zero when it should not — check `term_en_w` and look for the one-hot warning.
P1 and P2 both failing while P3 passes means the bit order or the synchroniser.
P5 alone means Phase 6A broke, not 6B.

### Phase 6B — original scope note

- **Scope widened by the Phase 6A review.** It is not just `PORT_SW`: Figure 5 draws a
  `MemRead`-enabled tri-state on **every** output-port block too, so a load from `0x2000` or `0x2004`
  should return the byte that port last stored. Phase 6A's ports are write-only. Nothing is blocked —
  no supplied benchmark reads a GPO port — but it is real specified behaviour and 6B is where the
  tri-state bus it needs gets built, so it belongs here rather than being left implicit.
  **Note the tension to resolve first:** clause 5's table gives all seven a Direction of `GPO`, which
  the figure's read-back contradicts unless "GPO" describes the *device* rather than forbidding a
  readable register. That is the ordinary MMIO reading and it matches the figure, but it is an
  interpretation — recorded in `DOC/02_requirements_traceability.md` §2.1 rather than assumed.
- `PORT_SW` at `0x2010`, and the tri-state read return this phase finally has a driver for:
  `Auxiliary/Lab 5/Auxilary/Lab3/DUT/BidirPin.vhd` with `width => 32`, which Figure 1 links to
  explicitly and Figure 5 draws as the buffer on `CS7 · MemRead`.
- Replaces the Phase 5B placeholder `dbus_rdata_w <= (OTHERS => '0')` and deletes the `SFRSTUB`
  notice process with it.
- **Not blocked.** §5 maps `SW7-SW0` and the benchmark masks confirm the bit order
  (`SW0_MASK 0x01`, `SW1_MASK 0x02` in `GPIO/test1/asm-code/test1.s`). Switches are not inverted on
  the DE2-115 — only the pushbuttons are.
- **Assumption A11** applies: the upper 24 bits of an MMIO read return zero. All three MMIO reads in
  the benchmarks `andi` the result immediately, so nothing observes them.
- **Exit:** GPIO test1 and test2 become runnable — both branch on `PORT_SW`, so neither can run
  before this lands. That is why test0 is the only GPIO benchmark Phase 6A could use.

### Phase 6C — `PORT_PB` and the KEY inputs  ·  **blocked**

- `PORT_PB` at `0x2014` reads KEY3-1. KEY0 is reset only, handled at the board boundary.
- KEY1-3 also feed the interrupt edge latches (Phase 9), and need synchronising into `mclk` first —
  `SYNC.vhd` from Phase 4A is the component for that.
- **Blocked:** `0x2014` has an address but **no bit-field table anywhere**. Which bit is KEY1, KEY2,
  KEY3, and do they read active-low as Figure 6's pull-up schematic implies? The `KEYnIFG` masks in
  `io_map.s` constrain the *interrupt* bits, not `PORT_PB`'s own layout. This is the open question to
  send Hanan.

Gaps: G-306 (output half closed by 6A). 6C blocked on the `PORT_PB` layout question.

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
| **G-305** | MMIO address decoder. **CLOSED 2026-08-24** (Phases 5A + 5B) — `ADDR_DECODER.vhd` with an exhaustive 16384-address testbench, the map as data in `const_package.vhd`, `dmemory`'s write enable gated by the chip select, and the decoder instantiated where Figure 1 puts the `BUS Interface Logic`. The twenty registers occupy exactly twelve consecutive words, so the chip-select index *is* `addr(5 DOWNTO 2)`. **The aliasing was hidden by defect 2**: at `G_ISA_REPAIR = FALSE`, `lui` writes zero, so the GPIO benchmarks never formed an SFR address at all. | Figure 5, p5 |
| **G-306** | GPIO buffer registers | §5, §6 |
| **G-307** | `div`/`divu`/`rem`/`remu` decode — masks exist, hardware does not | §2 |
| **G-308** | `mulh`/`mulhsu`/`mulhu` — scope undecided | §2 |
| **G-309** | Byte enables and sub-word load/store. `altsyncram` had no `byteena_a`; `CONTROL` detected `lb`/`lh`/`sb`/`sh` then discarded the width. **Built in Phase 3B**, awaiting verification. | §2 |
| **G-310** | CDC synchroniser. **CLOSED 2026-08-24** (Phase 4A) — `DUT/RV32IMscMCU/SYNC.vhd` plus a self-checking testbench. The figure specifies **three** flip-flops, not two: one launch register in the slow domain, two settling stages in the fast one. | Figures 10a/10b |
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
| **G-334** | **NEW, found by the Phase 5B review.** `aux_package.vhd`'s `RV32IM_CORE` **component** defaults `PC_WIDTH` and `MA_WIDTH` to `10`, while the **entity** defaults them to `G_PC_WIDTH`/`G_MA_WIDTH` = `13`. Every other generic in the same component forwards its `G_*` constant; only these two are hardcoded. Latent today — the sole instantiation associates both explicitly — but a component's default is what fills an unassociated generic, so any future bare-core instantiation would elaborate with `MA_WIDTH = 10` against `DTCM_ADDR_WIDTH = 11`, making `dtcm_addr_w` 8 bits wide against an 11-bit port. Inherited verbatim from `Auxiliary/Lab 5 - as submitted/DUT/RV32IM_sc/aux_package.vhd:21-22`, so **not changed unilaterally** — surfaced here per the no-blind-copy rule. Fix is two words when we decide to. | **lecturer's baseline** | open, latent |

## Verification

| ID | Gap |
| --- | --- |
| **G-401** | No self-checking testbench anywhere. The whole reference tree contains two assertions, both in `Auxilary/Lab3/TB/tb_top.vhd`, both used as a stop mechanism. |
| **G-402** | Directed ISA testbench — built in Phase 2, and two bugs in it found and fixed in Phase 3B (a one-off store-count shift, and a sub-word case that could not fail). Awaiting its first real run. |
| **G-204** | `mem_dump.do` exports 1024 of 2048 DTCM words; the upper half is never checked. |
| **G-403** | Per-component test plans not written. |
| **G-404** | `Benchmark Apps/RV32IM/test1/output/RARS/DTCM.hex` is a stale golden — 16 words disagree with `DTCM.h`. Would fail a correct CPU. |
| **G-407** | **NEW, from Phase 6B.** The seven GPO read-back tri-states of Figure 5 are implemented (behind `GEN_GPO_READBACK`) and exercised by nothing: no supplied benchmark reads `PORT_LEDR` or a `PORT_HEXn` — the only MMIO reads in any suite are three `lw ... PORT_SW`. So only `PORT_SW`'s tri-state is proved. Closing it needs a small program of ours that stores a byte to a GPO port and loads it back. Related: the paths also rest on assumption **A15**, so if Hanan says an output port must not answer a read, the right action is `GEN_GPO_READBACK => FALSE` rather than a test. |
| **G-406** | **NEW, from the Phase 6A review.** `tb_gpio`'s cross-talk check is one-sided. GPIO test0 writes the *same* value to all seven GPO ports in ascending address order, so a port that wrongly captures an **earlier** store fails, while a port that wrongly captures a **later** store of the same iteration re-captures a value it already holds and is invisible. Concretely: dropping `lane_en_i` on `P_HEX1` is caught, dropping it on `P_HEX0` is not. No supplied benchmark discriminates — test1 and test2 also write one value to all seven — so closing this needs a small program of ours that writes different values to the two ports of a pair. |
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
| `DOC/03_open_questions.md` | Q1–Q14, each with a provisional decision so nothing blocks |
| `DOC/04_baseline_runbook.md` | The Windows procedure, staging script, and exact expected numbers. **Rewritten 2026-08-24** for the replaced reference: sections 2, 4, 5.2, 6 and 8 all changed, and section 8.1b covers the Phase 3A/3B measurement |
| `SIM/baseline_reference/` | `compile.do`, `run_test.do`, `mem_dump.do` — replacements for the scripts the reference lost, reaching into `Auxiliary/` read-only |
| `Auxiliary/Lab 5 - as submitted/README-import.md` | What was imported and why the two Lab 5 copies differ |

---

# 7. Next actions

*Updated 2026-08-24, after Phase 4A and Phase 5A.*

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
4. **Run 3 — Quartus.** Confirm **131,072** memory bits. Phase 5B added two files to
   `Quartus/RV32IMscMCU/RV32IMscMCU.qsf` (`ADDR_DECODER.vhd` and `SYNC.vhd`); if Analysis & Synthesis
   still reports an unbound component, that file list is the first place to look. The reference's own numbers to compare
   against are now in §0.c — note the pipeline figures all changed.
   **Also, one check that only Quartus can answer:** open ISMCE and confirm the `DTCM` instance
   still appears and can be read and written. Phase 3B added `byteena_a` to the same `altsyncram`
   that carries `ENABLE_RUNTIME_MOD = YES`, and ISMCE is the mandatory §8 validation loop. If the
   instance is gone, **report it and change nothing** — sub-word access and ISMCE are both
   mandatory, so a conflict between them is a question for Hanan. Details in `DMEMORY.vhd`.
5. **Two leaf tests, no setup needed.** `do run_sync.do` (Phase 4A) and `do run_decode.do`
   (Phase 5A). Neither needs a memory image or `app_bin` staging, and neither depends on
   `G_ISA_REPAIR`, so they can be run any time — even before Run 1. Expected verdicts are in the
   Phase 4A and Phase 5A results blocks.
6. **`do run_mmio.do`** (Phase 5B). This one **does** need staging and **needs `G_ISA_REPAIR = TRUE`**
   — read the Phase 5B block above for why, it is not arbitrary. Then re-run Run 2 in full: the four
   benchmark counts must be unchanged.
7. **Send the questions** (§0.6). **Q6 and Q14 first** — those two are the only ones now blocking
   implementation, and together they decide nine of the ten remaining ISA-suite mismatches. Q14 is
   new: it asks whether a conformant 32×32 `mul` is required, whether `mulh*` is in scope, and
   whether `div` belongs in the ALU at all given that §6.iii defines a division *accelerator*. Then
   Q1, Q2, Q3.
8. **Answer G-207 and G-208** — what is in `finalProj`, and whether the two circled Quartus settings
   were instructions.
9. ~~Answer G-331~~ — done: `Auxilary/Ori/` is another student's pipeline, usable as a reference
   only. §0.d records what it is worth.

## Yehonatan — MacBook

1. ~~Commit and push~~ — done. ~~Update the `DOC/` documents for the new reference~~ — done in
   `82a1a11`. ~~Phase 5A~~ — done, see above.
2. ~~Phase 5B — wire the decoder in~~ — done. ~~Phase 6A — the seven GPO ports~~ — done.
3. **Phase 6B — the read path.** Next, and unblocked: `PORT_SW` plus the tri-state read return using
   `BidirPin.vhd` with `width => 32`, replacing the Phase 5B placeholder `dbus_rdata_w` and deleting
   the `SFRSTUB` notice with it. This is what makes **GPIO test1 and test2 runnable** — both branch on
   `PORT_SW` — so it roughly doubles the benchmark coverage Adar has.
4. **Then Phase 7 (divider) or Phase 8 (Basic Timer)**, whichever question comes back first. 6C, 7 and
   8 are all blocked on Hanan: `PORT_PB`'s bit layout, Q6/Q14 for the divider, Q3/Q4/Q8 for the timer.
5. **Prepare Phase 4's clock tree** as far as Q2 allows: the ALTPLL needs regenerating for
   `c0`/`c1`/`c2` and all three existing copies expose only `c0`. Note Phase 6A added a
   `mclk_o` port to the core that exists **only** until 4B moves the clock tree up — removing it is
   part of 4B, not a separate cleanup.

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
