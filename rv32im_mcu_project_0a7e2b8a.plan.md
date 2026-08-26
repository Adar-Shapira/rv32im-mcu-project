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
| 3 | **Python 3** | Only needed to regenerate the ISA and GPIO tests (`tools/gen_isa_test.py`, `tools/gen_gpio_test.py`). The generated files are committed, so this is optional at first. `tools/model_div_accel.py` is also Python but is a check we already ran, not something you need to run. |
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
wrong — say so. *(Since 2026-08-26 there is also nothing else in that package to flip:
`G_ISA_REPAIR` was retired — §1.7.)*

1. Execute `compile.do`. Expect 0 errors and the same three warnings. Since the clause 10 rewrite
   it compiles **only the official `tb_RV32IMscMCU`**; every `run_*.do` script compiles its own
   development testbench first, so nothing extra is needed.

   **Then seven tests that need nothing at all** — no images, no `app_bin`. Run them first, because
   if any fails, nothing after it is meaningful:
   - `do run_sync.do` → **Phase 4A**, the CDC synchronizer. Expect `VERDICT: PASS`, zero failures in
     all three checkers.
   - `do run_decode.do` → **Phase 5A**, the address decoder, exhaustive over all 16,384 addresses.
     Expect `VERDICT: PASS`, failures 0, and the three totals **8192 / 29 / 8163**.
   - `do run_clock.do` → **Phase 4B**, the clock tree. Expect `VERDICT: PASS`, failures 0, about
     110 accelclk edges and 10 distinct phases. Quick. It does **not** verify the PLLs — `altpll` is
     not instantiated at `MODELSIM = 1` — and its header lists three Quartus-only items for you.
   - `do run_divunit.do` → **Phase 7B1**, the division subsystem. Expect `VERDICT: PASS`, failures
     0, operations 57.
   - `do run_timer.do` → **Phase 8A**, the Basic Timer. Expect `VERDICT: PASS`, failures 0, and the
     printed FREQ_5K note (4008 cycles = 4990 Hz — a finding, not a bug).
   - `do run_intc.do` → **Phase 9A**, the Interrupt Controller. Expect `VERDICT: PASS`, failures 0.
     Quick — a few microseconds of simulated time.
   - `do run_div.do` → **Phase 7A**, the division accelerator. Expect `VERDICT: PASS`, failures 0,
     **65536** operations at N=8 and **517** at N=32. This is the long one — tens of seconds, because
     it sweeps every one of the 65536 operand pairs; it prints a progress line every 16 dividends so
     you can see it advancing. If you are in a hurry, `vsim -t ns -gEXHAUSTIVE=0 work.tb_div_accel`
     skips the sweep and then honestly says `INCOMPLETE` instead of `PASS`.

2. **Phase 1:** run `run_test.do` for `N` = 1..4. Expect the **same four counts as Run 1**
   (134 / 1514 / 2725 / 2735). The only change is that `RV32IMscMCU` now sits between the testbench
   and the core, so identical counts prove the new top level is transparent.
   - *An empty `DTCM.mem` means the hierarchical path in `mem_dump.do` is wrong.* It must be
     `/tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a` — the `MCU` level is the new
     wrapper. `mem save` does not report this as an error.
3. **Phases 2 + 3A + 3B — the ISA suite on the repaired core.** *(Rewritten 2026-08-26: the
   `G_ISA_REPAIR` switch is gone — §1.7. The before/after choreography this step used to describe
   was carried out and its numbers recorded; the repaired core is now the only configuration.)*
   - `do repair_check.do` → expect **43 of 43 PASS**. Submodule-level proof that each repaired
     expression computes the right value.
   - `do run_isa.do` → expect **exactly 5 mismatches**, then a `SUMMARY` block. All five are
     mul-related and out of scope by Hanan's own answer (16-bit `mul` — G-308/G-326); 5 is the
     floor, not a to-do list.
   - **0 mismatches means the test never ran** — `isa/ITCM.hex` did not reach `app_bin`.
   - **Any other number is a finding.** Paste the whole `ISA TEST FAIL` list back.
   - The citation for each case: `SIM\RV32IMscMCU\isa\listing.txt`.
4. **Phases 5B and 6A — the GPIO benchmarks.**

   Worth knowing for the report, from when the repairs were switchable: **the `lui` defect and the
   missing region decode masked each other** — on the as-submitted core GPIO test0's
   `lui t4,0x2 / addi / sw` sequences never formed an address at or above `0x2000`, so the missing
   MMIO decode was invisible on the GPIO benchmarks precisely because `lui` was also broken.

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
   - **`do run_gpio_directed.do`** → **Phase 6D**, the directed GPIO test. Stage the *generated*
     images from `SIM\RV32IMscMCU\gpio\` instead of a benchmark — it needs nothing else, so it can
     also be run outside this step entirely. Expect **35 of 35** stores
     and **zero** mismatches — there is no expected-failure count here. It also carries Phase 6C's two
     `PORT_PB` cases.
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

5. Repeat step 2 in `SIM\RV32IMpipelinedMCU`. Note this directory was rebuilt for the revised
   pipeline — new file list in `compile.do`, and `golden.do` is now the wave script to prefer.

### Run 3 — Quartus (still Phase 1).

Open `Quartus\RV32IMscMCU\RV32IMscMCU.qpf`, compile.

> **Rewritten 2026-08-26 — the revision changed character (§1.7.e).** Adar assigned the full board
> pinout (103 `set_location_assignment` lines: clk/KEY0 from Lab 5, SW/KEY/LEDR/HEX/GPIO from
> Lab4_HW / the Terasic CSV — closing **G-504** for the DE2-115) and added SignalTap
> (`stp_pwm.stp`) to this, still the only, revision. So the current `.qsf` is the **board/HW
> revision**: it is what FPGA testing runs on, and its area/power numbers are instrumented and NOT
> the report's PPA numbers.

- The top entity must resolve to `RV32IMscMCU`.
- If Analysis & Synthesis reports an **unbound component**, the `.qsf` file list is the first place
  to look: there is no `SEARCH_PATH` in this project, so Quartus finds an entity only if the file
  is listed.
- **`AUTO_MERGE_PLLS OFF` must stay in the `.qsf`.** With it on (the Quartus default) the Fitter
  merges the two `pll_gen` instances into one physical PLL — exactly the one-module clock tree
  forum answer F6 forbids. The `CBX_MODULE_PREFIX` hints in `CLOCK_TREE.vhd` keep them separate at
  synthesis; the `.qsf` line keeps them separate at fit.
- **For the report's PPA tables (Phase 14) a clean performance revision must be created** — no
  pins, SignalTap off, as D-2 and Lab 4's `Lab4_Perf`/`Lab4_HW` pattern prescribe. In THAT
  revision, embedded memory bits must read **131,072** (= 2 × 2048 × 32); **483,328** is the
  SignalTap-contamination signature from Lab 5 commit `8a71ffb`. On the current instrumented
  revision the inflated figure is expected, not a defect.
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
| 1 Clean structural base | Yehonatan ✔ | **Adar ✔** | **run 2026-08-25/26 (§1.7): RV32IM tests pass in ModelSim.** Numbers/screenshots still to be recorded |
| 2 Directed ISA test | Yehonatan ✔ | **Adar ✔** | **run 2026-08-25/26 (§1.7)** — expects 5 mismatches since the switch retired |
| 3A Seven ISA repairs | Yehonatan ✔ | **Adar ✔** | **run 2026-08-25/26 (§1.7): ISA suite passes in ModelSim; switch retired, repairs now unconditional.** Numbers/screenshots still to be recorded |
| 3B Byte enables / sub-word | Yehonatan ✔ | **Adar ✔** | **run with 3A (§1.7)** — same caveat on numbers |
| 3C `mul` width, `mulh`, `div` | — | — | **ANSWERED 2026-08-24** — `mul` only, 16-bit, as in Lab 5. Mostly nothing to do |
| 3D Pipeline re-import | Yehonatan ✔ | **Adar** | ready to run |
| 4A CDC synchronizer | Yehonatan ✔ | **Adar** | ready to run — frequency-independent |
| **4B Clock tree** | **Yehonatan ✔** | **Adar** | **ready to run — `do run_clock.do`.** Three Quartus items too; only `ACCELCLK`'s value is open (**B3**) |
| **4C Wire in + reset-on-lock + SDC** | **Yehonatan ✔** | **Adar** | **ready — re-run Run 2; the four counts must not move** |
| 5A/5B Bus interface + DTCM | Yehonatan ✔ | **Adar** | ready to run |
| 6A–6D GPIO | Yehonatan ✔ | **Adar ✔** | **run 2026-08-25/26 (§1.7): GPIO tests pass in ModelSim.** Numbers/screenshots still to be recorded |
| **7A Divider engine** | **Yehonatan ✔** | **Adar** | **ready to run — `do run_div.do`, needs nothing staged** |
| **7B1 Divider subsystem** | **Yehonatan ✔** | **Adar** | **ready to run — `do run_divunit.do`** |
| **7B2 Divider into the core** | **Yehonatan ✔** | **Adar** | **ready — re-run Run 2 AND `run_isa.do`; the ISA counts change to 21/5 on purpose** |
| **8A Basic Timer core** | **Yehonatan ✔** | **Adar** | **ready to run — `do run_timer.do`.** B4 mostly settled from the benchmarks; B2 still open for `SEC_PERIOD` |
| **8B Timer onto the bus** | **Yehonatan ✔** | **Adar** | **ready — stage `timer/` images, `do run_timer_mmio.do`** |
| **9A Interrupt Controller** | **Yehonatan ✔** | **Adar** | **ready to run — `do run_intc.do`, needs nothing staged.** Built on the falsified-A6 structure (raw latch, masked view) and the KEY-fires-on-RELEASE fact; **P2** (`RXIFG`/two TYPEs) affects only which of two equal-handler codes is pushed (A23) |
| **9B CPU-side protocol** | **Yehonatan ✔** | **Adar** | **ready — stage `intr/` images, `do run_intr_core.do`.** Report tp1/tp3 and the R3 deferral (the F13 number) |
| **9C Controller onto the bus** | **Yehonatan ✔** | **Adar** | **ready — stage `intrmmio/` images, `do run_intr_mmio.do`.** All 14 expected stores exact; the bus one-hot warning must stay silent (the TYPE push is a new driver) |
| **10A test1 harness + corrected copies** | **Yehonatan ✔** | **Adar** | **ready — `do run_bench_test1.do` (stages itself, passes `-gMODELSIM=1`; both fixed 2026-08-26)**. Found+fixed (one word, audited): shipped test1 never enables GIE at SW0=0 — question **B5** |
| **10B test4 harness; tests 2/3 = FPGA** | **Yehonatan ✔** | **Adar** | **ready — `do run_bench_test4.do` (stages itself).** Expect PASS + `CAPTURE EVENTS: 3 of 3`. **Two NEW findings (B6):** the shipped capture flow zeroes BTINT and holds+clears BTCNT, so the measured runtime is structurally 0 even with the G-327 fix. test2/3 stay FPGA material (B2) |
| 11 Pipeline port | Yehonatan | Adar | needs Phase 0's pipeline counters |
| 12 UART | Yehonatan | Adar | waits on Q1, Q12 |
| **13 Regression** | **Yehonatan ✔** | **Adar** | **ready — `python3 tools/check_staging.py` (clean today), then `vsim -c -do regress.do` and check the exit status.** G-203 closed for the SC side; every script stages its own images now |
| 14 Quartus PPA | Yehonatan | **Adar** | six revisions to compile |
| 15 Hardware validation | Yehonatan | **Adar only** | needs the board |
| 16 Report + ZIP | both | Adar checks the clean-room build | |

## 0.6 What Adar can also help with, off the critical path

- **Send section 1 of `DOC/05_questions_for_hanan.md`** — B1 the board, B2 the 8× `SEC_PERIOD`
  discrepancy, B3 `ACCELCLK`, B4 `BTINT`. *(This item used to say "send Q1, Q2, Q3 from `DOC/03`";
  Q2 was largely answered by the forum on 2026-08-24 and `DOC/03` has since become the long working
  record rather than the sendable list. `DOC/05` is the sendable one.)* Each item already has a
  provisional decision so nothing is blocked, but answers take time — send early.
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
`Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:38` inverts KEY at the board wrapper and leaves everything
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

# 1.5 NEW — Hanan's forum answers, 2026-08-24

Three screenshots of the course forum Q&A arrived. They are **the most valuable material we have
received since the reference replacement**, because they turn five assumptions into facts, unblock
three phases, and — importantly — contradict three things already written.

The full transcription, with the wording of every answer and the cross-checks against the repo, is in
`DOC/03_open_questions.md` under "ANSWERS FROM HANAN'S FORUM". This section is the consequences.

## 1.5.a Three phases unblocked

| Phase | Was blocked on | The answer |
| --- | --- | --- |
| **3C** | whether `mul` must be 32×32, whether `mulh*` is in scope, and Q6 | **Nothing to build.** 16-bit `mul` *is* the requirement; `mulh*` is not required; the divider's registers are core-internal. The phase collapses into Phase 7 |
| **4B** | Q2, and the belief that ALTPLL had to be regenerated for `c1`/`c2` | **"No — on the basis of three different PLL instances."** The existing single-output `PLL.vhd` is instantiated **three times**. Nothing to regenerate. And `MCLK = SMCLK` is permitted for a single-cycle core |
| **6C** | `PORT_PB`'s bit layout, which appears in no file | **`KEY1`→bit 0, `KEY2`→bit 1, `KEY3`→bit 2**; `KEY0` excluded because it is the RESET interface |

## 1.5.b Five assumptions settled

`A1` (`SMCLK = 20 MHz`) — **confirmed in writing** in the added `ReadMe.txt`.
`A2` (`MCLK = SMCLK`) — **confirmed**, explicitly permitted for a single-cycle core.
`A7` (divider registers core-internal) — **confirmed**.
`A14` (a HEX shows the low nibble) — **confirmed**: *"each HEX stands on its own"*.
`A6` (`IFG` holds the raw flag) — **FALSIFIED.** `IFG` is the **masked** value; it only rises when
`IE = 1`. Nothing is built on it yet, so this cost nothing — it would have cost a Phase 9 rebuild.

## 1.5.c Three things already written that the answers contradict — **ALL THREE FIXED 2026-08-24**

Recorded here and not buried, because two of them were real rework. All three are now done, before
any new phase was started.

1. ✔ **The `SW_i` synchroniser (Phase 6B) is not wanted.** Hanan: buttons and switches need no
   two-DFF synchroniser, *"since their rate of change is many orders of magnitude slower than the
   system clock, so the signal is considered static"*. It was added citing his **own** Figures 10a/10b
   material — exactly the reasoning-from-analogy the project rules warn about.
   → **Now behind `GEN_INPUT_SYNC`, defaulting to `FALSE`**, with his answer quoted at the generic.
   The chain is kept available because it costs sixteen flip-flops and two cycles on a hand-operated
   switch, i.e. nothing, and because turning it on is how a marginal board would be diagnosed.

2. ✔ **The bidirectional data bus is mandatory, and ours was half-built.** *"It is mandatory to use a
   DATA BUS based on the bi-directional bus."* Phase 6B built the **read** side as a genuine tri-state
   bus, but write data still left the core on a separate `dbus_wdata_w` path — two unidirectional
   buses, not one bidirectional one.
   → **Now one shared `data_bus_w`** with **ten drivers**: the CPU through `BP_CPU` on `MemWrite`,
   the eight readable registers on `CS · MemRead · lane`, and the terminator when neither. And the
   crucial part — **the peripherals now take their write data *from the bus*** rather than from a
   private wire, which is what makes it a bus rather than decoration.

   Two details that make it safe without a simulator. **Every driver is 32 bits wide**, including the
   byte registers, which drive their value zero-extended — that is assumption **A11** expressed once,
   in the only place it belongs, and it also guarantees the whole bus has a driver whenever any one
   is on. And `onehot_check` was extended to count **all ten** drivers, not just the readers, with a
   second assertion for the opposite failure: **no** driver active, which gives `'Z'` rather than
   `'X'` and would otherwise surface far from its cause.

   Exclusivity is by construction: `MemRead` and `MemWrite` are the load and store outputs of
   `CONTROL` and are never both asserted, the decoder is one-hot (proved exhaustively in Phase 5A),
   and the lanes are complementary.

3. ✔ **The peripherals belong on `SMCLK`, not `MCLK`.** Phase 6A clocked the seven GPO ports from the
   core's `mclk_o`.
   → **A named `pclk_w` now clocks every peripheral**, and nothing below the bus interface touches
   `mclk_w` any more. It is currently driven from `mclk_w`, which is *correct* rather than a shortcut
   — the same forum answer permits `MCLK = SMCLK` for a single-cycle core. Phase 4B changes the one
   line `pclk_w <= mclk_w;` to the SMCLK PLL instance's output and nothing else.

## 1.5.d What the added ReadMe is worth on its own

`Auxiliary/Benchmark Apps/Intrrupt-based IO/ReadMe.txt` — which the forum says was added in response
to exactly the question we had — is **the expected-behaviour contract for Phase 10**, per application,
in English, including test4's three modes (compare / output-compare PWM at 5 kHz with four duty
cycles / input-capture timing of a division loop). Until now Phase 10 had cycle counts and golden
memories but no statement of what the interrupt applications were supposed to *do*.

**And we are already current.** The forum says the interrupt `bin` folders were updated so the vector
table is ITCM-relative; our copies read `0x200`/`0x11C`/`0x17C`/`0x234`, `test4` and `ReadMe.txt` are
present, and the pre-update copy is preserved under `_superseded/`. No re-import.

## 1.5.e The one question the forum did not settle — now better evidenced

**`SEC_PERIOD` versus `BTSSEL`.** `Intrrupt-based IO/test{2,3}/asm-code/01_func.s:54-74` programs
`BTCTL1 = 0x18` → `BTSSEL = 11` → **÷8**, then loads `SEC_PERIOD = 0x01312D00 = 20,000,000`, commented
*"interrupt period of 1sec"*. At 20 MHz ÷ 8 that is **8 seconds**.

The answers make this *sharper*: `SMCLK = 20 MHz` is now Hanan's own statement, and the new ReadMe
repeats "1sec" for the same constant. Meanwhile `FREQ_5K = 500` at ÷8 gives exactly the 5 kHz test4's
PWM needs — so ÷8 is right and it is `SEC_PERIOD` or its comment that is off by a factor of 8.
**Still the question to ask, and now with three independent citations behind it.**

---

# 1.6 NEW — the recorded prep session, transcript received 2026-08-25

Hanan's recorded preparation meeting for the final project. The raw speaker-tagged transcript
(Hebrew ASR; **our copy cuts off mid-way through the closing bonus discussion**) arrived on
2026-08-25. The full digest with verbatim quotes is in `DOC/03_open_questions.md` §"THE RECORDED
PREP SESSION"; this section is the consequences.

**Evidentiary rank:** the lecturer's own words about this project — same tier as the forum answers.
Oral, so the PDF wins any conflict; every checkable claim was cross-checked against pp. 13–15 of
the definition PDF and against the built tree, and **no conflict was found**.

## 1.6.a The bottom line: it is overwhelmingly corroboration, and zero code changed

The session walks through exactly the architecture this plan already implements — the bit-13 region
split, the one-CS-per-word decoder with `A0` splitting the HEX pairs, the in-hardware 7-segment
encoder, the load-only GPI, the vector table at DTCM 0 with TYPE as the vector **byte address**
(timer → `0x10`), the masked `IFG`, `GIE = gp[0]` / return address in `tp`, the 2-cycle entry +
1-cycle `reti` protocol inside the control unit, the 32-cycle unsigned divider whose `busy` holds
the PC with write-back in the release cycle, the slow→fast CDC, the timer's three modes, and
`SHORT_DELAY = 4`. Full table in DOC/03 §A. The one default the transcript could have flipped —
`GEN_GPO_READBACK` — was **already `TRUE`**, so no RTL edit came out of the session.

Sharpest single corroboration: his capture walkthrough — *"initialise the select to 3, then set it
to 2, and I have created a rising event"* — is bit-for-bit the `BASIC_TIMER.vhd:331-335` CAPISEL
mux (2 = VCC, 3 = GND). The BTCTL2 raster reading now has independent oral confirmation.

## 1.6.b Four things it upgrades

| Item | Was | Now |
| --- | --- | --- |
| **A15** GPO read-back | our interpretation of Figure 5's tri-state | **his own description**: *"I can write to the LEDs, read the value of the LEDs"* — a load returns the latch content. `GEN_GPO_READBACK => TRUE` stands; the ask in `DOC/05` is now confirmation-only |
| **B3** ACCELCLK | "what frequency is expected?" | **no number is mandated — it is our design decision**: *"we bring it to the maximum possible"*, *"theoretically ×5, 6, 7, 8"*, and decisively *"how fast the accelerator finishes is up to you"*. Keep 50 MHz until Phase 14 measures `div_accel`'s real Fmax, then raise toward it |
| **B1** the board | either/or unknown | **both boards are equivalent at the interface level** — *"it doesn't matter, the same on both"* (he demonstrates with six 7-segment modules, which is what we drive). Only the pin table still needs the answer |
| **Q10/G-327** test4's capture | our reading of the `0x07`/`0x06` constants | the corrected copy's GND→VCC sequence is **the sequence he himself describes**; the shipped test4 never performs the second write |

## 1.6.c The one genuinely new hardware fact — for Phase 9

**Every interrupt request event is a rising 0→1 edge, deliberately** (*"I deliberately simplify
it... all the request signals go from zero to one"*) — **and for the pushbuttons that means the
request fires on RELEASE**: the debounced KEY line falls on press, rises on release, and his demo
places the request at the release. Consequence, recorded before the wrong edge gets built: clock
the p13 IS flop from the **debounced KEY line itself**, not from `key_pressed_w` — that signal is
inverted (`KEY_ACTIVE_LOW`), so its rising edge is the *press* and would fire every KEY interrupt
one event early. The PDF is silent on KEY polarity; the transcript is currently the only source.
Details and quotes: DOC/03 §C.

## 1.6.d Bonus logistics

Both bonuses require **finishing the base first and registering with Hanan by a date he will
announce**. Pipeline bonus: a dedicated ~half-hour lecture for registrants. UART bonus (20%):
registrants **receive ready HDL from Hanan** to adapt and integrate as a bus peripheral —
presumably the already-shipped `USART Material/UART_FPGA_option{1,2}`, **to be confirmed at
registration** before Phase 12's register layer is built on option 1.

---

# 1.7 NEW — Adar's verification session, 2026-08-25/26

Three commits (`1d16fe2`, `7bc9dc0`, `7225893`) plus a verbal report. This is the first time the
tree has been compiled — in ModelSim **and** in Quartus **and** on the board — so everything in it
outranks any prediction written earlier in this file. Where Adar's changes contradicted something
here, his version stands and the text has been updated (§0.3 steps 3–4, Run 3, the phase table).

## 1.7.a `G_ISA_REPAIR` is retired — the repaired core is the only core

Removed from `cond_compilation_package.vhd` and from every RTL site that tested it (`CONTROL`,
`IDECODE`, `EXECUTE`, `IFETCH`, `DMEMORY`), exactly as the switch's own comment planned: *"once the
repaired core is the accepted baseline, TRUE becomes the only configuration exercised."* The
before/after measurements the switch existed for were taken; the seven repairs are now
unconditional. Every committed testbench, `.do` script and `gen_isa_test.py` was updated by Adar in
the same commit. Completed on the Mac side 2026-08-26: `gen_gpio_test.py` (whose emitted text would
have reverted his edit on regeneration — verified byte-identical now), the three other generators'
docstrings, the Phase 10A harness (below), and `DOC/01/02/04`.

**Consequences for the suite:** `run_isa.do` expects **5** mismatches, `repair_check.do` expects
**43/43** with no alternate signature, and the GPIO benchmarks need no precondition. The
NOT-APPLICABLE guards are gone from `tb_gpio`/`tb_gpio_read`/`tb_mmio_alias`.

## 1.7.b Quartus 21.1 could not compile our generate style — CLOCK_TREE and SYNC rewritten

Quartus 21.1 Lite's Verific front end **internal-errors** (`vhdltreenode.cpp` PushScope) on
if/else generate with an inner declarative region — the exact idiom Phases 4A/4B used to keep
branch-local signals out of the other branch. Adar's fix, same netlist either way when the generate
condition is a compile-time constant: **two separate if-generates** (no else), with the branch-local
signals **hoisted** to the architecture (`lock_m/s/a_w` in `CLOCK_TREE.vhd`, `launch_q` in
`SYNC.vhd`). Rule for all future RTL: **no if/else generate with declarations inside a branch.**

Two more findings from the same fight, both real hardware facts:

- **The Fitter silently merges PLLs.** Distinct `CBX_MODULE_PREFIX` hints (`PLL_MCLK`/`PLL_ACCEL`)
  keep the two `pll_gen` megafunctions separate at synthesis, but the Fitter still folded them into
  one physical PLL (`fit.rpt` Info 176132, "Auto Merge PLLs = On" — the Quartus default), which is
  exactly the one-module clock tree forum answer F6 forbids. **`AUTO_MERGE_PLLS OFF`** is now in the
  `.qsf` and must stay there.
- `RV32IMpipelinedMCU.vhd` needed the same generate treatment (6 lines).

## 1.7.c `compile.do` compiles the official testbench only

Clause 10 Table 1 names exactly one TB file: `tb_RV32IMscMCU.vhd`. Adar restricted `compile.do` to
it and rewrote the official TB to the course convention — board I/O signals brought out and forced
from the wave window, **no auto-stop**, `golden.do` (all signals) and `wave.do` (compact set) as
the wave scripts. The other `tb_*.vhd` under `TB/RV32IMscMCU/` are **development-only and must NOT
go into the submission ZIP** (his header says so explicitly).

Completed on the Mac side 2026-08-26, so the scripted flow still works from a clean clone: **every
`run_*.do` now `vcom`s its own testbench** (plus its expected-package where one exists) before
`vsim` — the pattern `run_bench_test1.do` already used. Adar's own flow through `RV32IM_SC.mpf`
is unaffected; the `.mpf` stays out of the ZIP per D-3.

## 1.7.d The board interface widened to the full DE2-115

`SW_i` is now `9 DOWNTO 0` (PORT_SW still reads bits 7..0 — SW9/8 are board pins, not MMIO bits),
`LEDR_o` is `9 DOWNTO 0` with bits 9:8 driven `"00"`, and a new `GPIO : INOUT (35 DOWNTO 0)` brings
out the whole J15 expansion header per clause 4: **PWM on `GPIO[9]`** (Lab 4 / Figure 4b),
**CAPIN1/2 on `GPIO[8]`/`GPIO[10]`**, unused bits high-Z. `PWM_o`/`CAPIN1_i`/`CAPIN2_i` remain for
ModelSim (the existing TBs drive them) and are `VIRTUAL_PIN` in Quartus so they take no ball.
Testbenches that instantiate the MCU now use partial association — `SW_i(7 DOWNTO 0) => ...,
SW_i(9 DOWNTO 8) => "00"`, `LEDR_o(7 DOWNTO 0) => ...` — Adar's pattern in `tb_gpio`, followed by
the updated `tb_bench_test1`.

## 1.7.e The `.qsf` is now the pinned board revision — and Phase 14 changed accordingly

103 `set_location_assignment` lines (clk/KEY0 from Lab 5; SW, KEY, LEDR, HEX, GPIO from Lab4_HW /
the Terasic CSV — **G-504 closed** for the DE2-115) plus SignalTap (`stp_pwm.stp`, a PWM-focused
`.stp`) in the same, still only, revision. That is the right shape for the board bring-up he was
doing, and it means:

1. **FPGA testing is unblocked** — this is what his board session ran on.
2. **The report's PPA numbers cannot come from this revision** (SignalTap inflates memory bits —
   the 483,328 signature). Phase 14 must add the clean performance revision (D-2's
   `Lab4_Perf`/`Lab4_HW` pattern). This was always the plan; it is now concrete work against a
   pinned base instead of prevention.

## 1.7.f Adar's reported results (verbal, 2026-08-26) — and the three asks

**Reported:** the RV32IM and GPIO suites pass in ModelSim; all FPGA checks work **except one item**
his tooling attributes to the test rather than the design; single-cycle is close to done.
Screenshots deferred until things settle.

**Not yet in this file, and needed before Single Cycle is marked done:**

1. **Which check is the failing one, and its exact failure text.** "The tool says it is a test
   problem" is a hypothesis, not a finding — per the Benchmarks-are-a-Contract rule it needs the
   same treatment as every failure: name the test, paste the output, and only then decide whether
   the test or the RTL is wrong. If it is a test of ours, we fix it; if it is a shipped benchmark,
   we document it like B5/test4.
2. **The numbers** for the results tables — the four SC counts, `run_isa.do`'s tally,
   `repair_check.do`, the leaf-test verdicts, and the pipeline `CLKCNT`/`STCNT`/`FHCNT` triples
   (G-205) if the pipeline was run.
3. **The screenshots**, once stable, to `Screenshots\ModelSim\` and `Screenshots\Quartus\`.

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
5. **`Auxilary/Lab3/`, `Auxiliary/Lab4/`** — their own completed earlier labs. The richest source of
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
> `Auxiliary/Lab 5/DOC/HANDOVER_Report_lab5.md` §5.3 and
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
  `Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:38`. Delete `RSTPOL` from the core. **Fixes D-1.**
- Convert `G_MODELSIM` from a package constant to a generic the testbench overrides with `-g`.
  **Fixes G-201.** The package constant stays as the default so Quartus needs no edit.
- Carry commit 2's testbench auto-stop forward.
- Two Quartus revisions per configuration from the start, per `Lab4_{perf,hw}.sdc`. **Fixes D-2.**
- **Exit:** both wrappers compile in ModelSim and Quartus; the baseline numbers from Phase 0 still
  reproduce through the new wrapper; the perf revision reports 131,072 memory bits, not 483,328.

Gaps: ~~G-311 (clock tree)~~ **closed by Phase 4B**; D-1, D-2, D-3.

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

**Exit criterion, not yet met:** run `run_isa.do`. The expected result is **exactly 21 mismatches** —
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

### Phase 3A — the seven ISA repairs  ·  **verified in ModelSim 2026-08-25/26 (§1.7); numbers pending**

Done 2026-08-23. Every repair is a transcription from the reference pipeline (§0.a), so none of it is
our invention and each carries a file:line citation in the code itself.

> **2026-08-26: the switch described below has since been retired** (§1.7.a) — the before/after
> measurements were taken and the repairs are now unconditional. This block is the record of how
> they were built and measured; the checklists' present tense is that of 2026-08-23.

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
| G-326 `MUL16` is 16×16 | 2 | ✘ | **ANSWERED — not a defect.** 16-bit `mul` is the requirement |
| G-308 `mulh`/`mulhu`/`mulhsu` | 3 | ✘ | **ANSWERED — not required.** `mul` only |
| G-307 `div`/`divu`/`rem`/`remu` | 4 | ✘ | Phase 7 — **now unblocked**, registers are core-internal |

**25 → 9, and after Hanan's forum answers the 9 read differently.** Five of them —
the two `mul` width cases and the three `mulh*` cases — are **not defects at all**: Hanan's forum says
the required core is Lab 5's RV32IM *"including support for a 16-bit multiplier only"* and *"`mul`
only (as in Lab 5)"*. So the directed suite is measuring conformance the project does not ask for.
Those five stay as documented, deliberately-failing evidence in the report rather than work items.
The remaining four are `div`/`divu`/`rem`/`remu`, and those are Phase 7, which is now unblocked.

Defects 6 and 7 are not in that table because the Phase-2 suite does not reach them: its
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
- `run_isa.do` — mismatches: ____ (5 expected since Phase 7B2; was 9 when this block was written)

*(2026-08-26: the "exactly 25 failures = wrong configuration" signature is gone with the retired
switch — §1.7.a.)* Any non-zero `repair_check.do` count is a real finding — a specific repair is
wrong, or a control check broke, and a broken control means a repair damaged behaviour that was
already correct. Paste the failing lines:

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

Closes G-309. Takes the ISA suite from 21 mismatches to 5. *(Those were 25 and 9 until Phase 7B2 closed G-307.)*

### Phase 3C — `mul` width, `mulh`, and `div`  ·  **ANSWERED 2026-08-24 — mostly nothing to do**

This phase was held back because implementing it would have meant inventing requirements. Hanan's
forum answers settle all three parts, and **two of them turn out to need no work at all**:

- **`MUL16` being 16×16 is the requirement, not a defect.** The base task is to *"extend the RV32I
  single-cycle to the RV32IM single-cycle you were given, **including support for a 16-bit multiplier
  only**"*. Nothing to widen. **G-326 closed.**
- **`mulh`/`mulhsu`/`mulhu` are not required.** *"`mul` only (as in Lab 5)."* The masks in
  `const_package.vhd` stay unused. **G-308 closed.**
- **`div`/`divu`/`rem`/`remu` belong to the accelerator, and its registers are core-internal.**
  `DIVRST` initialises the divider's internal quotient shift register *"in parallel with writing the
  Dividend, Divisor values into the **core's** registers"* — so they are not memory-mapped, which was
  Q6. **That moves the remaining four cases into Phase 7, which is now unblocked.**

So the only thing that was ever really in this phase is the divider, and it has moved to where it
belongs. **The five `mul`/`mulh*` mismatches in the directed ISA suite stay**, as documented evidence
that the suite tests full RV32IM conformance while the project asks for a subset — which is worth a
paragraph in the report, not a code change.

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

Expect PASS with zero failures everywhere, in any build of the tree.

### Phase 4B — the clock tree  ·  **built, awaiting verification**

**Files:** `DUT/RV32IMscMCU/CLOCK_TREE.vhd` (new), `DUT/RV32IMscMCU/PLL_GEN.vhd` (new),
`TB/RV32IMscMCU/tb_clock_tree.vhd` (new), `SIM/RV32IMscMCU/run_clock.do` (new); `aux_package.vhd`,
`compile.do` and the `.qsf` updated. The leaf only — wiring it in is 4C.

**The blocker this phase was recorded as having was the wrong blocker.** The plan said the ALTPLL had
to be regenerated for `c1`/`c2`. Forum answer **F6** removed that outright: the three clocks come
from **three separate PLL instances**, not one multi-output PLL. What actually stood in the way was
smaller and had not been noticed: **`PLL.vhd`'s entity takes no generics at all.** Its ratio comes
from `G_PLL_DIV`/`G_PLL_MUL` in `cond_compilation_package.vhd`, so three instances of it would have
produced three copies of *one* frequency (25 MHz).

- `PLL_GEN.vhd` is `PLL.vhd` with four constants promoted to generics — divide, multiply, input
  period, device family, plus the `lpm_hint` string. **Every one already appears in `PLL.vhd`'s own
  `altpll` component declaration and is already passed by it**, so nothing new is asserted about the
  megafunction. That is the distinction that matters: `clk1_*`/`clk2_*` generics appear in no file we
  have, and adding *those* would have been the unverifiable-parameter risk this plan warned about.
- `PLL.vhd` is left **byte-identical** (md5 `a12064f2…`, the same in all four places it exists) and
  the core still instantiates it. The price is ~60 duplicated lines of `altpll` boilerplate, taken
  knowingly rather than risk the Phase 0/1 baseline for a feature the baseline does not use.
- Ratios: `MCLK = SMCLK = 20 MHz` (F7 permits equal, F8 states 20 MHz **in writing**),
  `ACCELCLK = 50 MHz` (assumption A3, question B3). Checked **at elaboration**, cross-multiplied in
  integer kHz so nothing rounds — a wrong ratio is otherwise a silent frequency error that surfaces
  as a Basic Timer whose "5 kHz" is not 5 kHz.

**The one real conflict, resolved as a decision and not as a reading — assumption A19.**
F6 says three separate PLL instances; F7 says `MCLK` and `SMCLK` may be equal. Do both literally and
you get **two independent PLLs each producing 20 MHz** — and the core drives address, write data and
`MemWrite` on `MCLK` while every peripheral register captures that bus on `SMCLK` (F11, and
`gpo_port` does exactly this). Two PLLs on one reference are frequency-identical but their phase
relationship is specified by nothing, so that capture cannot be timing-analysed, and Figure 5 draws
no synchroniser anywhere on the GPIO write path. It would probably work on the bench and could not be
shown to work. **`SMCLK_SHARES_MCLK` defaults `TRUE`: equal frequency means one net.** Sent as a
question; `FALSE` gives the literal structure and that branch is written and tested.

**What the testbench does not do, stated plainly: it does not verify the PLLs.** `altpll` needs
`altera_mf` and the course's own idiom — Hanan's, in `RV32IM_CORE.vhd` — is not to instantiate it in
simulation. What is verified: the ratio arithmetic for **two** different configurations, that MCLK in
simulation **is** `clk_i`, that ACCELCLK is independent of MCLK and walks 10 distinct phases of it,
that `locked` starts low and rises, and that **both** branches of every generate compile.

**Adar's results — Phase 4B**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_clock.do` | `VERDICT: PASS`, failures 0 | |
| accelclk edges / distinct phases | ~110 / 10 | |
| Quartus: does a `pll_gen` instance compile and fit? | yes | |
| Quartus: is `intended_device_family => "Cyclone II"` accepted on the Cyclone IV E part? | inherited from `PLL.vhd`, and Lab 5 ran with it — if rejected, pass `"Cyclone IV E"` | |
| Quartus: may three instances share one `CBX_MODULE_PREFIX`? | if not, give each its own `LPM_HINT_STR` | |

Gaps: **G-311 closed.** New assumption **A19**. `ACCELCLK`'s value is still **B3**.

### Phase 4C — wire the tree in, reset on lock, and the SDC  ·  **built, awaiting verification**

**Files:** `RV32IMscMCU.vhd`, `RV32IM_CORE.vhd`, `aux_package.vhd`,
`Quartus/RV32IMscMCU/RV32IMscMCU.sdc` — all changed, none new.

- **`clk_i` now enters `CLOCK_TREE` and nowhere else**, exactly as Figure 1 draws it. The core
  RECEIVES `mclk` on its `clk_i`; its internal PLL generate is gone and the transitional `mclk_o`
  port added by Phase 6A is **removed**. The peripherals move from `mclk_w` to `smclk_w` — which,
  under A19's default, is the same net. `accelclk_w` is generated and waits for 7B.
- **`PLL.vhd` is now instantiated by nothing.** It stays compiled and byte-identical; `PLL_GEN` is
  what the tree uses. Do not delete it — its provenance is worth more than the file list is tidy.
- **Reset is held until the PLLs report lock**, behind `GEN_RESET_ON_LOCK` (default `TRUE`).
  Precedent `Auxiliary/Lab4/DUT/fpga_hw_interface.vhd` captures `pll_locked`; `PROJECT_EXPLANATION.md`
  §9.3 records that the reference then leaves it **unused** and that a production design would hold
  reset until lock. So this is a deliberate improvement over the reference and **the report should
  say so.** Note the clock tree's own `areset` keeps the unconditioned `rst_w` — a PLL held in reset
  by its own lock signal would never lock.
- **SDC rewritten.** The old one named `RV32IM_CORE` as the top (untrue since Phase 1) and documented
  a single 25 MHz PLL output (untrue since 4B). It now constrains the one real clock and lets
  `derive_pll_clocks` produce the rest, and it carries two written-out conditionals: what must be
  added if `SMCLK_SHARES_MCLK` is ever set `FALSE`, and the ACCELCLK clock-group statement, which is
  **commented out on purpose** until 7B — today `accelclk` has no load, Quartus prunes that PLL, and
  a `set_clock_groups` whose collections match nothing is a constraint that looks applied and is not.
- **Do not** mistake `IFETCH.vhd:73-82` for a synchroniser — verified again: it is
  `IF rst_i='1' THEN rst_q<='1' ELSIF rising_edge THEN rst_q<=rst_i`, a single flop with an async
  preset.

**THE ONE THING THAT MATTERS IN VERIFYING THIS PHASE.** 4C changes the clocking of every existing
test at once, and nothing in this tree has run on real tooling yet. **Re-run Run 2 in full. The four
counts must still be 134 / 1514 / 2725 / 2735.**

They *should* be, and here is why, so that a change is a real finding rather than an expected side
effect: in simulation `CLOCK_TREE`'s `mclk_o` **is** `clk_i`, the same tie the core used to make
itself at `MODELSIM = 1`, so the clock is bit-identical. And `mclk_cnt_q` is held at zero by reset and
starts counting when reset releases, while the program starts executing at that same moment —
so holding reset until the modelled 200 ns lock shifts both together and the count at the
benchmark's self-jump is the same number. What changes is only the wall-clock time at which the
simulation ends.

**If a count does move**, set `GEN_RESET_ON_LOCK => FALSE` and re-run. That isolates the reset change
from the clock change in one run instead of bisecting the whole phase.

**Adar's results — Phase 4C**

| Check | Expect | Result |
| --- | --- | --- |
| Run 2 four counts | 134 / 1514 / 2725 / 2735 — **unchanged** | |
| `run_isa.do` mismatches | unchanged from before 4C | |
| `run_mmio.do`, `run_gpio*.do` | unchanged | |
| Quartus: three clocks in the Timing Analyzer? | **two** today — `accelclk` has no load until 7B, so its PLL is pruned | |
| Quartus: `f_MCLK` after the fitter | a number — this is the PPA table's `f_sysclk` | |

Gaps: **G-310 closed by 4A, G-311 by 4B.** `ACCELCLK`'s value is still question **B3**, and the
`MCLK`/`SMCLK` net question is **A19**.

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

If `CHECK 0` fails, the **specification** is wrong and the RTL may be
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

`tb_mmio_alias` **required the repaired core** (a `G_ISA_REPAIR = TRUE` guard, until the switch was
retired — §1.7.a), and the reason is worth putting in the report.

Disassembling `Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex`, every one of test0's
seven stores is reached as:

```
lui  t4,0x2        -- ITCM word 4,  0x00002eb7
addi t4,t4,offset  -- ITCM word 5
sw   t0,0(t4)      -- ITCM word 6
```

On the as-submitted core, `lui` writes **zero** — defect 2. So `t4 = 0 + offset`, and the seven
stores land on byte addresses
**0, 4, 5, 8, 9, 12, 13** — all inside the DTCM, none of them ever reaching `0x2000`.

**So the missing region decode was invisible on the GPIO benchmarks precisely because `lui` was also
broken.** Repairing `lui` is what exposes the aliasing. Two defects, each hiding the other.

*(While the switch existed the testbench detected the `FALSE` build and reported NOT APPLICABLE
rather than a FAIL; the guard went with the switch — §1.7.a.)*

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

`SIM\RV32IMscMCU` → `compile.do`. Stage GPIO test0's
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
   `Auxiliary/Lab4/DUT/fpga_hw_interface.vhd` registers its SW/KEY inputs as
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

Part of **Run 2 step 4** — same staging as `run_mmio.do`. Then
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

**Corrected 2026-08-24 after Hanan's forum answers** — see §1.5.c. The read path described below is
now one **bidirectional** bus with the CPU as a driver, not a read-only tri-state bus beside a
separate write path; the peripherals take their write data from it; and the `SW_i` synchroniser is
behind `GEN_INPUT_SYNC`, default `FALSE`.

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
  `Auxiliary/Lab 5/Auxilary/Lab3/DUT/BidirPin.vhd (since deleted from the tree)` with `width => 32`, which Figure 1 links to
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

### Phase 6D — the directed GPIO test  ·  **built, awaiting verification**

Done 2026-08-24. **Closes G-406 and G-407** — the two verification gaps Phases 6A
and 6B each registered against their own tests. Not a new feature: it is the
evidence the previous two phases were missing.

| Done | What |
| --- | --- |
| ✔ | `tools/gen_gpio_test.py` — 304 instructions, 32 scored stores, an independent GPIO model, and a second derivation that must agree |
| ✔ | `SIM/RV32IMscMCU/gpio/{ITCM.hex,DTCM.hex,listing.txt}` — generated, committed |
| ✔ | `TB/RV32IMscMCU/gpio_expected_pkg.vhd` + `tb_gpio_directed.vhd` + `run_gpio_directed.do` |

**The two gaps close each other, which is why one program does both.** Read-back
(G-407) is what makes a port's *content* observable; once content is observable
the lane decode is discriminable in **both** directions (G-406). So the program
writes different values to the two halves of each shared chip select, in both
orders, and reads both back:

| Store | Case | Catches |
| --- | --- | --- |
| 3 | `hex01_ascending:rd` PORT_HEX0 must be `A5`, not `5A` | `PORT_HEX0` also capturing the `0x2005` store — **the direction GPIO test0 cannot see** |
| 8 | `hex01_descending:rd` PORT_HEX1 must be `B7`, not `7B` | `PORT_HEX1` also capturing the later `0x2004` store |

**It is the one GPIO test that needs no benchmark image at all.**
The program builds every address with `addi`/`slli` (`li32`, no `lui`), loads at
offset zero throughout, and has no compares, no `sra`, no `jalr` and one `beq`
sentinel at offset 0 — so it touched **none of the seven (since-repaired) ISA
defects**, checked one by one in the generator's header. That isolation is what
makes a mismatch here a GPIO problem and never an ISA
one. **Zero is the only passing number**, unlike the ISA suite.

**Five more things the 32 stores cover, beyond the two gaps:**

- **Assumption A11.** Write `0xFF` to `PORT_LEDR`, read it back: must be
  `0x000000FF`. A sign-extending or floating read path gives `0xFFFFFFFF` or `X`.
- **`PORT_SW` through the synchroniser**, value `0x5C` — deliberately not
  bit-symmetric, so a reversed bit order cannot pass.
- **The bus terminator.** An unmapped SFR read at `0x2030` must return `0`. A
  floating bus would give `'Z'`, which arrives as `'X'` in the register file.
- **An unmapped SFR write** at `0x2034` must be discarded and must not disturb
  `PORT_LEDR`.
- **The Phase 5B property at *program* level.** A marker `0xDEADBEEF` is planted
  in **DTCM word 0** — the word `PORT_LEDR` aliased onto before Phase 5B, and
  where the interrupt vector table lives — and read back at the end after
  fourteen MMIO stores. Until now that property was only checked at the mechanism
  level, by watching `dtcm_wren_o`.

**Addresses are compared as full byte addresses**, from `alu_res_o`, not as DTCM
word indices. That is not cosmetic: an MMIO store to `0x2004` and a DTCM store to
word 1 produce the *same* `dtcm_addr_o`, because the core drops bit 13 on the way
to the RAM. Comparing `dtcm_addr_o` would leave this suite unable to tell an MMIO
store from the DTCM store it used to alias onto — one of the things being tested.

**Derived twice, as the ISA suite is.** The generator computes the expected
sequence once while *emitting* the code and once by *executing* it on an
interpreter with an independent model of the GPIO block, and aborts if the two
disagree. They agree on all 32. That discipline is what caught two real bugs in
the Phase 2 generator, which is why it is repeated here.

#### ▸ Adar's results — Phase 6D

Stage the **generated** images, not a benchmark:
`SIM\RV32IMscMCU\gpio\ITCM.hex` and `DTCM.hex` → `app_bin`. Then
`do run_gpio_directed.do`.

- stores seen: ____ of 32 · cycles: ____ (expect ~305)
- mismatches: ____ — **zero is the only pass**
- **VERDICT line:** ____________________

Every mismatch names its case; look it up in `SIM\RV32IMscMCU\gpio\listing.txt`,
which says in words what that case is for.

### Phase 6C — `PORT_PB` and the KEY inputs  ·  **built, awaiting verification**

Done 2026-08-24, unblocked by Hanan's forum. **Closes G-306 entirely.**

| Done | What |
| --- | --- |
| ✔ | `KEY_i[3..1]` board input, `KEY_ACTIVE_LOW` generic, `key_pressed_w` conditioning |
| ✔ | `PORT_PB` at `0x2014` assembled and attached to the read bus as its ninth reader |
| ✔ | `tools/gen_gpio_test.py` extended with two cases; the suite is now **35 stores** |
| ✔ | `tb_gpio_directed.vhd` drives `KEY_i`; `aux_package`, `run_gpio_directed.do`, the `.qsf` updated |

**The bit order is Hanan's, and it could only have been guessed otherwise.** Asked whether `PORT_PB`
returns three bits with bit 0 unused or the buttons packed into bits 0–2: *"the mapping is in the
order KEY1–KEY3 to bits 0–2 respectively (KEY0 is not included, since it is the system RESET
interface)"*. **No supplied file states this**, and — checked — `PORT_PB` is defined in every
`io_map.s` and **read by no supplied program**: the interrupt tests reach the keys through interrupts,
not by polling.

**The polarity is not his, so it is an Assumption with a generic.** Nothing states whether `PORT_PB`
presents the raw active-low pin or the pressed sense. `KEY_ACTIVE_LOW` defaults to `TRUE` — pressed
reads `'1'` — because `Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:37-38` does exactly that for all four
keys (*"Invert KEYs because DE2-115 pushbuttons are normally HIGH, LOW when pressed"*) and this design
already does it for KEY0 through `RST_ACTIVE_LOW`. Registered as **A16**; one word to flip.

**`KEY_i` is indexed `3 DOWNTO 1`**, so `KEY_i(n)` is `KEYn` on the board and no off-by-one is
possible at pin assignment. KEY0 is absent because clause 3 makes it the system RESET, and it arrives
on `rst_i`. Bits 7..3 of `PORT_PB` read zero rather than being left undriven — same reason the bus has
a terminator.

**Two new directed cases, and the value was chosen to discriminate.** `KEY3` and `KEY2` pressed,
`KEY1` released → `PORT_PB` must read **`0x06`**. That is **not symmetric under bit reversal**, so a
wrong order gives `0x03` and fails. And a store to `PORT_PB` — a GPI — must be discarded and must not
disturb what it presents, which the second case checks by writing `0x00` and reading `0x06` back.

**No edge detector is built here.** Clause 6.i puts the KEY interrupt sources in the interrupt
controller, and Hanan's forum confirms the board debounces in hardware (a 74HC245, Figure 6), so what
Phase 9 needs is edge detection on an already-clean signal. `key_pressed_w` is what it will observe.

#### ▸ Adar's results — Phase 6C

Part of `run_gpio_directed.do` — same staging.

- stores seen: ____ of **35** · mismatches: ____ (**zero is the only pass**)
- **VERDICT line:** ____________________

A `port_pb:rd` mismatch reading `0x03` instead of `0x06` is a reversed bit order; reading `0x01`
instead of `0x06` is inverted polarity, i.e. `KEY_ACTIVE_LOW` is wrong for this board.

### Phase 6C — original scope note

- `PORT_PB` at `0x2014` reads KEY3-1. KEY0 is reset only, handled at the board boundary.
- KEY1-3 also feed the interrupt edge latches (Phase 9), and need synchronising into `mclk` first —
  `SYNC.vhd` from Phase 4A is the component for that.
- **Blocked:** `0x2014` has an address but **no bit-field table anywhere**. Which bit is KEY1, KEY2,
  KEY3, and do they read active-low as Figure 6's pull-up schematic implies? The `KEYnIFG` masks in
  `io_map.s` constrain the *interrupt* bits, not `PORT_PB`'s own layout. This is the open question to
  send Hanan.

Gaps: **G-306 CLOSED** by 6A (outputs), 6B (read path) and 6C (`PORT_PB`).

## Phase 7 — Division accelerator  ·  Yehonatan writes · Adar verifies

Split for the same reason 4A came before 4B and 5A before 5B: the arithmetic is provable on its own,
exhaustively, with no dependence on the core and **no open question attached** — the forum answered
every one that touched it. Wiring it into the core is a separate, riskier step that also needs a
clock we do not have yet.

### Phase 7A — the unsigned engine  ·  **built, awaiting verification**

**Files:** `DUT/RV32IMscMCU/DIV_ACCEL.vhd` (new), `TB/RV32IMscMCU/tb_div_accel.vhd` (new),
`SIM/RV32IMscMCU/run_div.do` (new), `tools/model_div_accel.py` (new); `aux_package.vhd`,
`compile.do` and the `.qsf` updated.

- Figure 9's block set and every signal name implemented exactly: 2N-bit dividend left-shift
  register with `'0'` entering at the LSB, divisor register, `Result = Y − X` subtractor whose
  non-negative flag both drives the restore and becomes the quotient bit, quotient left-shift
  register, `Residue` and `Quotient` out, `DIVCLK`/`DIVRST`/`DIVENA` in and `DIVBUSY` out.
- **Page 9's timing met literally.** One Load edge, then N iteration edges; `DIVBUSY` rises on the
  Load edge and falls on the Nth, so it is high across exactly N `DIVCLK` periods and the results are
  valid N cycles after the load. Measured on every one of 66,000+ operations, not spot-checked.
- **Verification:** all **65536** operand pairs at N=8 (the divide-by-zero column included) against
  `IEEE.NUMERIC_STD`'s own `/` and `rem`, plus 16 directed corners and 500 pseudo-random pairs at
  N=32, plus reset-while-busy and `DIVENA`-held-high. Eight properties, P0–P8.

**Three things worth carrying forward, each of which changes something:**

1. **Divide by zero needs no hardware.** Run the algorithm with `X = 0` and `Y ≥ X` holds every
   cycle, so every quotient bit is `'1'` and the remainder ends up holding the dividend. Result: all
   ones and the dividend — which is simultaneously Hanan's forum answer (F4) and the RISC-V
   requirement for `divu`/`remu`. **No exception logic is needed and none was written.**
2. **An N-bit `Y` never overflows**, so Figure 9's 2N-bit register is correct even for divisors above
   `2^31`. Proof in `DOC/02` §5.1. It is also the one claim an N=8 sweep cannot test, which is why
   the N=32 list aims at it directly.
3. **The start must be armed once per `DIVENA` assertion, not level-triggered.** Figure 3 makes
   `DIVstart` a combinational Control Unit output, so it stays high for the whole stall; a
   level-triggered engine relaunches forever and the core never sees a result. Verified to be a real
   trap: the Python model was mutated to start on a level and **P7 was the only failing property.**

**Why the first ModelSim run should pass.** The toolchain is Windows-only, so this RTL could not be
compiled where it was written. `tools/model_div_accel.py` transcribes it line for line into Python
and runs the same 66,053 cases against Python's `//` and `%` — 0 failures — and eight deliberate
mutations of that model were all caught. A failure in ModelSim therefore points at the VHDL
translation or the simulator setup rather than the arithmetic, and `run_div.do`'s footer says which
property failing means which.

**Adar's results — Phase 7A**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_div.do` | `VERDICT: PASS`, failures 0 | |
| N=8 operations | 65536 | |
| N=32 operations | 517 | |
| Runtime | tens of seconds, ~13 ms simulated | |

**Nothing to do in Quartus for this phase, and a retracted claim about why.** An earlier version of
this block asked Adar for `div_accel`'s area and `DIVCLK` Fmax and said that was the number question
B3 needs. **That was wrong.** `TOP_LEVEL_ENTITY` is `RV32IMscMCU`, nothing instantiates `div_accel`
yet, and nothing drives `divclk_i` — so Analysis & Synthesis elaborates the block and drops it: no
row in the resource table, and no `DIVCLK` for the Timing Analyzer to report an Fmax on. Adar would
have gone looking for two numbers that cannot exist, and might have recorded 0 LEs as the area. The
`.qsf` comment asserting otherwise contradicted the `SYNC.vhd` comment nine lines above it in the
same file, which had it right; both are now corrected. Getting those numbers needs Phase 7B's
instantiation, or a dedicated revision with `TOP_LEVEL_ENTITY div_accel` and a `create_clock` on
`divclk_i` — a **Phase 14** item.

Gaps: G-301 closed for the engine. New assumption **A18** (Figure 9's bit-level wiring is not legible
in the raster figure; restoring division is the only interconnection of its blocks that works).

### Phase 7B1 — the division subsystem  ·  **built, awaiting verification**

**Files:** `DUT/RV32IMscMCU/DIV_UNIT.vhd` (new), `TB/RV32IMscMCU/tb_div_unit.vhd` (new),
`SIM/RV32IMscMCU/run_divunit.do` (new), `tools/model_div_unit.py` (new); `aux_package.vhd`,
`compile.do` and the `.qsf` updated.

Everything between the core and Figure 9's engine, behind one MCLK-domain interface — so 7B2's job
in the core is decode, a stall term and a mux, and nothing about clock domains. **This is `SYNC.vhd`'s
first real use**, four times over.

- **The stall is built on `done_o`, not `busy_o`**, and that is the whole reason this unit exists.
  `DIVstart` takes two synchroniser stages to reach the engine and `DIVBUSY` two more to come back,
  so for several MCLK cycles after a div issues **`busy` still reads low** — a stall written as "hold
  while busy" does not hold at all. 7B2's term is `PCHold <= DIVstart AND NOT done_o`.
- **A real race, found and fixed before the code ever ran.** The enable and the two operand buses
  each cross through their own two-stage synchroniser. Launched on the same MCLK edge, nothing
  guarantees the operand bits resolve no later than the enable bit — so `DIVENA` could arrive one
  DIVCLK edge before a bit of `Ain`/`Bin` had settled, and the engine would load a half-updated
  operand and return a confidently wrong answer. The `LAUNCH` state holds the enable back one MCLK
  cycle. Data first, control after.
- **The result buses are deliberately NOT synchronised.** `SYNC.vhd`'s own header forbids putting a
  *changing* multi-bit bus through a two-flop synchroniser, and `Quotient`/`Residue` change on every
  iteration. They are read directly, only after `DIVBUSY` has been seen to fall through two stages —
  by which point the engine has been idle and its outputs constant for at least two MCLK cycles.
- **Signed `div`/`rem`.** `-2^31 / -1` needs no special case: `|-2^31|` is `0x80000000`, the signs
  agree, nothing is negated, and `0x80000000` *is* `-2^31`. **Divide-by-zero does** need one: RISC-V
  requires `-1` for every dividend, but for a *negative* dividend the sign correction would negate
  `0xFFFFFFFF` into `+1`. Verified that this is real, not defensive — removing the override from the
  Python model produces **155 failures**.
- **A clock-ratio constraint, written down because B3 is still open.** `WAIT_RISE` only terminates if
  `DIVBUSY` stays high long enough for the MCLK synchroniser to catch it: roughly
  `f_DIVCLK < 16 x f_MCLK`. At 50 MHz against 20 MHz there is twelve times the margin needed. The
  failure mode is a **hang**, not a wrong answer, which is why it is a checked property (P5) and not
  a comment.

**Verification:** `tools/model_div_unit.py` checks the wrapper against `fractions.Fraction` — which
truncates toward zero exactly and shares no step with the magnitude algorithm — over **all 65536
pairs signed and all 65536 unsigned** at N=8, plus 32-bit corners and random cases: **131,488 cases,
0 failures**, and **seven** deliberate mutations all caught. The testbench then does what the model
cannot: two **coprime** clocks (50 ns against 21 ns), so the DIVCLK edge lands at every phase of the
MCLK period rather than the fixed 5:2 relationship the real design will have.

**A bug found after this phase was committed, and fixed.** `DONE` waited for `start_i` to fall —
which two **adjacent** `div` instructions never allow, because the second asserts `DIVstart` on the
very cycle the first retires. The unit sat in `DONE` with `done_o` still high and the second div
retired immediately **carrying the first one's result**: a silent wrong answer, not a hang. `DONE`
now lasts exactly one cycle, which is safe because the retire and that transition happen on the same
edge. **Neither the model nor the testbench covered it** — `do_op` always lowered `start` between
operations, and the model does not simulate the FSM at all. New property **P8** drives the case the
core actually produces.

**Adar's results — Phase 7B1**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_divunit.do` | `VERDICT: PASS`, failures 0 | |
| operations | **57** (15 directed + 40 random + P8's adjacent pair) | |
| Runtime | about 60 us simulated, quick | |

### Phase 7B2 — wire it into the core  ·  **built, awaiting verification**

All the clock-domain work is done and tested in 7B1. What is left is core-side and single-domain:

- `div`/`rem`/`divu`/`remu` decode in `CONTROL.vhd`, producing Figure 3's `DIVstart` and the
  `signed_i` qualifier. **The benchmarks use the signed opcodes** — `div`/`rem` in `RV32IM/test1` and
  in `Intrrupt-based IO` test1 and test4, four occurrences each — and never `divu`/`remu`, though all
  four are supported because the wrapper makes the unsigned pair nearly free.
- The stall: `PCHold <= DIVstart AND NOT done_o`, and `PCHold` into `IFETCH` so the PC holds.
- Write-back mux widened, selected by `WBSrc1`/`WBSrc0` per Figure 3, with `Quotient` and `Rem` as
  two of its inputs.
- Instantiate `div_unit` in `RV32IMscMCU` on `accelclk_w`, which Phase 4C already generates and
  leaves waiting. **This is also what stops Quartus pruning the third PLL.**
- Block interrupt entry until the divide retires — Hanan confirmed this reading (F13): for
  `DIV`/`REM` the instruction completes only when `BUSY` falls. That lands in Phase 9.
- **Exit:** the RV32IM benchmark's `div`/`rem` arrays produce the right values through the core, and
  the four Lab 5 cycle counts still hold for the benchmarks that contain no `div`.

**Files changed:** `CONTROL.vhd`, `IFETCH.vhd`, `IDECODE.vhd`, `RV32IM_CORE.vhd`, `RV32IMscMCU.vhd`,
`aux_package.vhd`, `RV32IMscMCU.sdc`, `tools/gen_isa_test.py`, `isa_expected_pkg.vhd`. No new files.

**Three things worth reading before verifying:**

1. **The ISA suite's expected numbers CHANGED, and that is the phase working.**
   `run_isa.do` now expects **21 / 5**, not 25 / 9. `div`, `divu`, `rem` and `remu` were four of the
   mismatches — undecoded, core wrote zero — and they now pass **at either setting of
   `G_ISA_REPAIR`**, because the divider is not behind that switch. The generator's **two independent
   derivations caught this by themselves**: the gap tagging said one thing and the defect model still
   said "div writes 0", and generation refused to promise a count until both agreed.
   **The 5 that remain are all mul-related and all out of scope** by Hanan's own answer (F1: "mul only
   (as in Lab 5)", 16-bit). 5 is the floor, not a to-do list.
   The ITCM/DTCM images are **byte-identical** (`893b7c48…` / `e0c27360…`) — the program did not
   change, only which stores are expected to fail.
2. **The four Lab 5 cycle counts must NOT move, and this is checkable rather than hopeful.** Every new
   control term is gated by `pc_hold_w`, which can only rise on a div — and **none of the four Lab 5
   benchmarks contains one.** Their ITCM images decode to exactly **one `mul` each and zero
   div/rem** (29 / 29 / 52 / 62 words; the decoder was validated by checking the first word of test1
   is `auipc x8,0` = `0x00000417`). So `pc_hold_w ≡ '0'`, the RegWrite/MemWrite gating is a no-op, and
   the write-back mux's new arm is never selected.
3. **Expect THREE clocks in Quartus now, not two.** The divider finally gives `accelclk` a load, so
   the third PLL stops being pruned — and the ACCELCLK `set_clock_groups` in the SDC, deliberately
   commented out since 4C, is now **enabled**. If the Timing Analyzer still lists two clocks, that
   constraint is silently matching nothing and is hiding every violation on the crossing.

**How the stall works, in one line each:** `CONTROL` decodes the four opcodes into `DIVstart` plus a
signed and a remainder qualifier; `pc_hold_w <= DIVstart AND NOT done_o`; `IFETCH` feeds `pc_q` back
as the next PC, which re-fetches the **same** instruction and so keeps `DIVstart` asserted; `IDECODE`
gains a divider arm above the ALU arm in its write-back mux; and `RegWrite`/`MemWrite` are gated off
for the duration so the register file is not written on every stall cycle.

**Adar's results — Phase 7B2**

| Check | Expect | Result |
| --- | --- | --- |
| Run 2 four counts | 134 / 1514 / 2725 / 2735 — **unchanged** | |
| `run_isa.do` | **5** mismatches (was 9), all mul-related. *(The 21-at-`FALSE` row retired with the switch — §1.7.a)* | |
| `repair_check.do` | unchanged — it does not touch the divider | |
| Quartus: clocks in the Timing Analyzer | **three** | |
| Quartus: `f_MCLK` with the divider in | a number — the PPA table's `f_sysclk` | |

Touches `CONTROL`/`IFETCH`/`IDECODE`/`RV32IM_CORE`/`RV32IMscMCU`, which is why it is separate from
7B1. **G-307 closed.**

## Phase 8 — Basic Timer  ·  Yehonatan writes · Adar verifies

### Phase 8A — the timer core  ·  **built, awaiting verification**

**Files:** `DUT/RV32IMscMCU/BASIC_TIMER.vhd` (new), `TB/RV32IMscMCU/tb_basic_timer.vhd` (new),
`SIM/RV32IMscMCU/run_timer.do` (new), `tools/model_basic_timer.py` (new); `aux_package.vhd`,
`compile.do` and the `.qsf` updated. The leaf only — the MMIO wiring and the read path are 8B, and
`btifg_set_o` waits for Phase 9's IFG.

**Most of the skeleton is Lab 4's, taken on the standing check-the-labs-first rule.**
`Auxiliary/Lab4/DUT/pwm.vhd` was read in full before a line was written, and maps almost one to one:
its wrap-at-`Y` counter is `BTCNT` with the wrap point moved to F17's `BTCL0`; its `ena` is
`BTOUTEN` — and page 8's own wording, *"hold the PWMout signal value"*, is exactly what an
update-enable does when low; its Mode 0 Set/Reset and Mode 1 Reset/Set are `BTOUTMD`'s two values
with `X` renamed `BTCL1`; its Mode 2 (Toggle) is dropped because `BTOUTMD` is one bit and Figure 8
draws exactly two traces. The full line-by-line mapping is in `BASIC_TIMER.vhd`'s header. No other
timer/counter/capture precedent exists in Labs 3, 4 or 5 — searched.

**B4 is now mostly answered from the benchmarks, not guessed.** `io_map.s` defines `BTINT2 = 0x02`,
and `test4/01_func.s:156-158` writes `BTCTL1=(BTHOLD,BTCLR,BTINT=2)` precisely when configuring
**input capture**, while every compare-interrupt test runs with `BTINT=0`. So `00`→EQU0 and
`10`→capture are **benchmark facts**; `01`→EQU1 is the only source left; `11` is reserved — "three
options" in two bits, exactly as page 8 says. Only the `01`/`11` half is still assumption (**A20**).

**Forum answers built in literally:** **F16** — reset clears only the five interface registers, so
`BTCNT` lives in a process with **no reset arm** (only `BTCLR` clears it); **F17** — the count
restarts after reaching `BTCL0`, so `EQU0 = (BTCNT = BTCL0)` and **the period is `BTCL0`+1 ticks**.

**A NEW FINDING FALLS OUT OF F17-LITERAL HARDWARE:** `FREQ_5K = 500` at ÷8 gives a period of
(500+1)×8 = **4008** SMCLK cycles = **4990 Hz, not 5000**. Exactly 5 kHz needs `BTCMPR0 = 499`.
Same class as B2's `SEC_PERIOD` factor-8: the constant and the definition disagree, the hardware
follows Hanan's stated definition, and the testbench asserts 4008 and **prints** the discrepancy.

**A21:** the `BTCL0`/`BTCL1` shadow latches load on the bus write (Figure 7's `HEU0` label is
defined nowhere — open question P1). Indistinguishable in every supplied benchmark; one enable term
to change.

**Verification:** `tools/model_basic_timer.py` executes the RTL's per-edge semantics through the
same phases as the testbench — 0 failures, and **eight faithful mutations all caught**, including a
counter that obeys reset (P0b names the F16 violation), a wrap one count early, swapped PWM modes,
and the reserved `BTINT` code firing. The testbench itself went through three self-caught bug fixes
before it ever saw a simulator: a park-at-nonzero sequence that could not move (BTCL0 was still 0), a
phase-sensitive PWM window, and a Mode1 window measured before steady state.

**Adar's results — Phase 8A**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_timer.do` | `VERDICT: PASS`, failures 0 | |
| P1 periods | 10 / 20 / 40 / 80 | |
| P8 FREQ_5K interval | **4008** cycles, plus the printed 4990 Hz note | |
| BTIFG events counted | ≥ 10 (P9 anti-vacuity) | |

Gaps: **G-302 closed for the core.** `BTINT` codes `01`/`11` are **A20**; shadow-latch timing is
**A21**; `SEC_PERIOD` remains **B2**.

### Phase 8B — wire it in  ·  **built, awaiting verification**

**Files:** `RV32IMscMCU.vhd` and `aux_package.vhd` changed; `tools/gen_timer_test.py`,
`SIM/RV32IMscMCU/timer/{ITCM,DTCM}.hex + listing.txt`, `TB/RV32IMscMCU/tb_timer_mmio.vhd`,
`SIM/RV32IMscMCU/run_timer_mmio.do` new.

- The timer sits on `pclk_w` / `sys_rst_w`, takes write data **from the shared bidirectional bus**
  like every peripheral, and its five registers are readable through five new BidirPin readers
  (`NRD` 9 → **14**). The three Word-resolution registers are the map's first, so `WEXT`'s
  zero-extension now covers indices 0..10 only and **the word registers drive all 32 bits
  directly** — that is what "Address Resolution: Word" means, and a wrong wiring here is exactly
  what the S3/S4 checks catch.
- **Three new top-level pins:** `PWM_o`, `CAPIN1_i`, `CAPIN2_i` (F18; locations wait on B1).
- `bt_ifg_set_w` is generated and deliberately unconsumed until Phase 9 — same posture as
  `div_busy_w`.
- The SFR stub notices updated: the timer's four words now take writes and answer reads (a write to
  `BTCAPR` reaches the timer and is ignored **there**, by design — different from falling into a
  stub).

**Verification — a directed program, because no supplied benchmark can do it:** every
Interrupt-based IO test configures the timer and then waits for *interrupts*, which need Phase 9 —
without it they hang in their idle loop. So `tools/gen_timer_test.py` generates a 113-instruction
program (addi/slli/sw/lw-at-0 + one beq — an ISA footprint clear of all seven since-repaired
defects), and derives its
expectations a second way by **executing it against `model_basic_timer.Timer`** — the model eight
mutations already vetted — one timer edge per instruction. Generation aborts on disagreement.

The program: configures while held, reads all five registers back (`BTCTL2` written via its **odd**
address `0x201D`), echoes **test4's capture bug at MCU level** (S5: source parked on GND captures
nothing), forces the edge test4 meant (`CAPISEL` GND→VCC), reads a stable K twice, then starts PWM —
and the bench measures **10/31-cycle widths at the pin**. K is range-checked (1..60, predicted 10),
not exact — pinning it would weld the test to an edge-level timing detail; exactness lives in
`tb_basic_timer` P6 where the counter is frozen.

**Adar's results — Phase 8B**

| Check | Expect | Result |
| --- | --- | --- |
| stage `SIM\RV32IMscMCU\timer\*.hex` → `app_bin`, `do run_timer_mmio.do` | `VERDICT: PASS`, failed 0 | |
| scored stores / captured K | 7 / K in 1..60 (predicted 10) | |
| PWM widths at the pin | exactly 10 and 31 | |
| Quartus: `PWM_o`/`CAPIN1_i`/`CAPIN2_i` appear as pins | yes — locations still unassigned (B1) | |

**Exit for Phase 8 as a whole** stays: the interrupt benchmarks' timer flows on the MCU — that is
Phase 9's integration test, since they need IFG/IE/TYPE to advance.

## Phase 9 — Interrupt controller and CPU protocol  ·  Yehonatan writes · Adar verifies

- `IE`/`IFG`/`TYPE` per p14. Bit positions verified from two independent sources: the PDF tables and
  the benchmark masks (`BTIE = 0x04` → bit 2; `0x38` → bits 5,4,3; `0xFFF7`/`0xFFEF`/`0xFFDF` clear
  bits 3/4/5).
- Per-source flag = a D flop with `D` tied to `'1'`, **clocked by the source edge**, async-cleared —
  exactly the p13 diagram. No separate edge detector is drawn, but KEY1-3 still need synchronising
  into `mclk` first.
- **Request events are rising 0→1 edges for every source, and the KEY request fires on RELEASE** —
  the prep session (§1.6.c): the debounced KEY line falls on press, rises on release, and the
  release edge is the request. So the IS flop clocks from the **debounced KEY line itself**, never
  from `key_pressed_w` — that signal is inverted, its rising edge is the press, and using it fires
  every KEY interrupt one event early. The PDF is polarity-silent; the transcript is the only
  source, so this is the first thing to confirm if a KEY ISR ever fires at the "wrong" moment.
- **`IFG` reads the MASKED value** — `IFGx = irq AND eint`, the p13 AND gate, confirmed by the
  forum (the answer that falsified A6) and again by the prep session. The flop output `irq` is the
  raw latch; what the register exposes is the AND. `INTR = OR(IFGx) AND GIE`.
- Flag clearing per p13's notes: `BTIFG` auto-clears when serviced; `RXIFG` when serviced or
  `RXBUF` read; `TXIFG` when serviced or `TXBUF` written; `KEYiIFG` **only by software** (the
  other three may also be cleared by software).
- Fixed priority, TYPE `04h`–`1Ch`; RESET is TYPE `00h`, **NMI — no local and no global mask**
  (p14 table + prep session).
- CPU entry FSM, two cycles, **multicycle unit inside the control unit** (p15): `INTA` idles high
  and falls on the cycle **after** `INTR` rises; the FSM triggers on that falling edge. Cycle 1
  clears `GIE = gp[0]`, restores `INTA` to `'1'`, drives `TYPE` onto the **data** bus into a
  dedicated register (the address bus cannot carry it — the CPU is the only bus master, p15's red
  note); cycle 2 clears the synchronous flag and emulates `load` + `jalr` to `Mem[TYPE]` with
  `R[tp]` = return address. Return: `jalr zero,0(tp)` sets `GIE`, one cycle.
- **Exit:** cycle-accurate protocol assertions; simultaneous requests, priority, masking, nesting
  deferral while `GIE = 0`, manual and automatic clear, interrupts around loads, stores and divides.

Gaps: G-303, G-304. Blocked on **Q7** — which affects only the two UART rows of the vector table;
the KEY/timer half of the controller is fully specified and buildable now.

### Phase 9A — the controller  ·  **built, awaiting verification**

**Files:** `DUT/RV32IMscMCU/INTERRUPT_CTRL.vhd` (new), `TB/RV32IMscMCU/tb_interrupt_ctrl.vhd` (new),
`SIM/RV32IMscMCU/run_intc.do` (new), `tools/model_interrupt_ctrl.py` (new); `aux_package.vhd`,
`compile.do` and the `.qsf` updated. The leaf only — the CPU-side protocol is 9B, the bus wiring is
9C; sources and the INTA handshake are testbench-driven here.

**No lab precedent — searched and recorded.** The only interrupt hit in Labs 3/4/5 is a student
explanation document, zero RTL. Built from four sources: the **p13 diagram taken literally** — raw
request latches (D='1' flops) behind AND gates whose outputs the diagram itself labels `IFGx`; the
**p14 layouts and vector table** (already benchmark-cross-checked in DOC/02 §3.1); the
**falsified-A6 forum answer** — what `IFG` *reads* is the masked product `irq AND eint`, never the
raw latch; and the **prep session** (DOC/03 §C) — every request event is a rising 0→1 edge, so the
KEY request fires on **RELEASE**. The only reused RTL is `SYNC.vhd` (Figure 10a), two-flop per KEY,
exactly as `DIV_UNIT` reuses it.

**The mid-build correction the process caught:** the first draft gated the *set* path by IE and
killed pending flags on IE-drop — plausible from the forum answer's wording alone, but the p13
diagram and the prep session both say raw-latch-plus-masked-view. The plan's own Phase 9 bullets
pointed back at the sources before anything was committed; the draft was rebuilt to the sourced
structure, and the wrong structure now lives on as **mutant M1**, killed by the A22 comeback check
(P2b). Same for the KEY edge: press-edge detection is **mutant M8**, killed by P8a — DOC/03's exact
warned-against bug, now permanently fenced.

**What is deliberately visible in the semantics:** a masked request is invisible everywhere (read,
TYPE, INTR) but **remembered** — it reappears when IE is enabled (**A22**; no benchmark can tell,
they all clear IFG before enabling, and P3 proves that exact init pattern kills the memory).
Software writes are **W0C** (**A24** — the p13 flop has no software-set path; the ISR
read-modify-write idiom works exactly). `RXIFG` presents TYPE `08h` for its two codes (**A23** —
DOC/02 §4.1: both vector-table words hold the same handler in all four benchmarks). BT auto-clears
at service, KEYs never do (rules a and d). TYPE freezes at the INTA accept edge and is pushed one
cycle later for the MCU level to drive onto the data bus (REQ p15: the CPU is the only bus master).

**Verification:** `tools/model_interrupt_ctrl.py` — 0 failures through the same ten phases, and
**twelve faithful mutations all caught**, each by the phase built for it: set-gated-by-IE, raw
readback, write-1-sets, inverted priority, INTR ignoring GIE, auto-clear hitting KEYs, no BT
auto-clear, press-edge, live TYPE during push, level-set key latch, INTR from raw, TYPE from raw.
The model also caught one cross-check bug in the phase suite itself before commit (P5d demanded a
KEY3 flag while KEY3IE was still 0).

**Adar's results — Phase 9A**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_intc.do` | `VERDICT: PASS`, failures 0 | |
| P2b (A22 comeback) and P3 (init pattern) both pass | yes — they check opposite directions of the same latch | |
| P8a/P8b | no flag on press-and-hold, flag on release | |

Gaps: **G-303 closed for the controller leaf.** The `RXIFG` dual-TYPE choice is **A23**; the
masked-request memory is **A22**; G-304 (CPU-side FSM) is Phase 9B.

### Phase 9B — the CPU side  ·  **built, awaiting verification**

**Files:** `RV32IM_CORE.vhd` (entry FSM + hijacks), `CONTROL.vhd` (+`Reti_ctrl_o`), `IDECODE.vhd`
(+GIE tap and the two register-file side doors), `IFETCH.vhd` (+the vector arm),
`const_package.vhd` (+`INST_RETI`), `aux_package.vhd` (all four components) changed;
`tools/gen_intr_core_test.py`, `SIM/RV32IMscMCU/intr/{ITCM,DTCM}.hex + listing.txt`,
`TB/RV32IMscMCU/tb_intr_core.vhd`, `SIM/RV32IMscMCU/run_intr_core.do` new.

**The protocol, placed exactly where DOC/02 §4.2 reconstructed it:** a three-state FSM whose accept
cycle is combinational (`INTA = NOT accept_w`, a one-cycle low pulse the cycle after `INTR` rises —
`intr_q` is the "next clock cycle" of REQ p15). Cycle 1: PC held by the same mechanism as the
divider stall, GIE = `gp[0]` cleared through a side door that touches **only bit 0** (a program
using gp as a real global pointer keeps it), TYPE captured from the **raw** `dbus_rdata_i`.
Cycle 2: DTCM address hijacked to `type_q(7:2)` with `MemOp` forced to `MEM_W` (the extract mux
would otherwise slice the vector), the word into IFETCH's new top-priority arm, `tp` = return
address. `reti` = the exact word `jalr zero,0(tp)` recognized in CONTROL; its only added effect is
the GIE-set at the same edge.

**F13 is the accept gate, literally:** blocked while `div_start_w` (raw decode — so an accept cycle
can never be a div issue cycle and no divide is ever annulled mid-flight) or `div_busy_w` (the
synchroniser tail — the consumer that signal was declared for in 7B2) is high.

**The annul is load-bearing on the bus:** during Cycle 1 the controller drives TYPE on the shared
data bus, so the core suppresses its own MemRead — plus RegWrite/MemWrite/DivStart, and the
DTCM-side MemRead gate that silences the half-word misalignment `severity failure` an annulled
`lh` would otherwise raise.

**Verification — the testbench plays the controller** (INTERRUPT_CTRL's exact push timing, itself
leaf-proven by 9A): a generated 45-instruction program builds its own vector table with two plain
stores, then takes three interrupts — KEY1 into a poll loop, BT to a different vector, and KEY1
raised **the moment the div appears on `instruction_o`**. Checks: gp reads 0 inside every ISR and
1 after every reti (rules e/f in HW), tp equal in ISR and main and range-checked, 0xB7 from the BT
vector, div/rem = 142/6 **after** the deferral, the measured deferral ≥ 12 cycles, exactly 16
scored stores (an annul leak would break the count), one-cycle INTA pulses. The generator's
interpreter emulates the full protocol as the second derivation and aborts on disagreement.

**Adar's results — Phase 9B**

| Check | Expect | Result |
| --- | --- | --- |
| stage `SIM\RV32IMscMCU\intr\*.hex` → `app_bin`, `do run_intr_core.do` | `VERDICT: PASS`, failed 0 | |
| printed tp1 / tp3 | 44..48 / 100..124 | |
| printed R3 deferral | ≥ 12 cycles (expect ~25+) | |
| re-run Run 2 | the four benchmark counts unchanged — no benchmark contains an interrupt request, and every new arm is gated by the FSM idling | |

Gaps: **G-304 closed at the core level.** Phase 9C wires the two proven halves together on the bus
(CS_INTC, lanes 0/1/2, the TYPE-push BidirPin, `bt_ifg_set_w`, `key_pressed_w`, `gie_o`/`intr`/
`inta` between core and controller) — after that the Interrupt-based IO benchmarks finally run.

### Phase 9C — the two halves onto the bus  ·  **built, awaiting verification**

**Files:** `RV32IMscMCU.vhd` only (plus one stale comment in `RV32IM_CORE.vhd`);
`tools/gen_intr_mmio_test.py`, `SIM/RV32IMscMCU/intrmmio/{ITCM,DTCM}.hex + listing.txt`,
`TB/RV32IMscMCU/tb_intr_mmio.vhd`, `SIM/RV32IMscMCU/run_intr_mmio.do` new. **Nothing rewritten:**
the controller is 9A's, the FSM is 9B's, the readers extend Phase 6B's structure, and the sources
are the wires 6C and 8B left waiting.

- `IE`/`IFG`/`TYPE` = readers 11/12/13 on `CS_INTC`, lanes 0/1/**2** (`lane2_w` new — TYPE is the
  map's first base+2 register). TYPE is read-only in hardware: a reader, no write path.
- **The TYPE push is bus driver 14** — a real `BidirPin` on the one shared bus, per Hanan's
  "mandatory … bi-directional bus" answer, enabled by the push strobe. It cannot collide because
  the core's annul holds MemRead and MemWrite low in Cycle 1, and `onehot_check` now watches
  exactly that claim (its message text names the new family).
- **Two small hidden-remark corrections while wiring:** the controller sits on `pclk_w` — F11's
  own words ("the other modules' registers are DFF based on SMCLK") supersede 9A's CPU-clock
  phrasing, sound under A19 with the B3-split caveat now covering the whole handshake; and the two
  Phase-8B/7B2 "deliberately unconsumed" comments (`bt_ifg_set_w`, `div_busy_w`) were retired —
  both signals now have their intended consumers.

**Verification — the first test with no emulation anywhere in the path:** the bench presses KEY1
once when the program stores its ready marker, and everything else is hardware: pin → KEYCOND →
release-edge latch → INTR → entry → TYPE over the bus → the program's own vector table → ISR bus
RMW (`and`-mask, never `andi` — defect 1) → reti; then the timer repeats it with no pin at all —
`bt_ifg_set_w` consumed, and rule a's auto-clear observed from software (the BT ISR reads IFG = 0).
**All 14 expected stores are exact — no ranges** — because both interrupt moments are pinned by the
program, not by bench timing. Second derivation: the program executed against
`model_interrupt_ctrl.Intc` + `model_basic_timer.Timer` **composed** on one emulated bus with the
9B protocol between them — the vetted models reused, not re-derived. Agreed on the first run.

**Adar's results — Phase 9C**

| Check | Expect | Result |
| --- | --- | --- |
| stage `SIM\RV32IMscMCU\intrmmio\*.hex` → `app_bin`, `do run_intr_mmio.do` | `VERDICT: PASS`, failed 0 | |
| the bus one-hot warning | **never fires** — the TYPE push's collision proof | |
| re-run Run 2 | four counts unchanged (no old benchmark raises INTR; the reti word appears only in the interrupt suite — scanned) | |

Gaps: **Phase 9 complete as built.** The mandatory-path phases left are 10 (the Interrupt-based IO
benchmarks on exactly this hardware — Adar), then 13-16. P2/Q4 (`RXIFG`'s two TYPE codes) remains
A23 until Hanan answers; A17 (BTCTL2 read-only?) unchanged.

## Phase 10 — Single-cycle benchmark progression  ·  **Adar runs**

- Interrupt test1 with scripted KEY1/2/3 pulses; test2 one-second BT interrupts; test3 the four
  periods; test4 in compare, PWM and capture modes.
- Use `Auxiliary/Benchmark Apps/Intrrupt-based IO/` — the current revision. `_superseded/` holds the
  older one with two extra defects, kept for auditability.
- **test4's capture never fires**: `capture_init` and `capture` both write `0x07`, so `CAPISEL` stays
  at GND. Verify capture with a separately-marked corrected copy writing `0x06`. Q10.
  **Strengthened by the prep session (§1.6.b):** Hanan's own capture walkthrough is "initialise the
  select to 3, then set it to 2" — the exact GND→VCC rising event the corrected copy performs and
  the shipped benchmark never does. The corrected copy is now his described intent, not our guess.

### Phase 10A — test1, self-checking, plus the corrected copies  ·  **built, awaiting verification**

**Files:** `tools/patch_bench_images.py`, `SIM/RV32IMscMCU/bench_fixed/{test1,test4}/` (+
`PATCHES.md`), `TB/RV32IMscMCU/tb_bench_test1.vhd`, `SIM/RV32IMscMCU/run_bench_test1.do` new;
`compile.do` untouched — the run script `vcom`s its own testbench (§1.7.c). Originals under
`Auxiliary/` untouched. Harness updated 2026-08-26 for the retired `G_ISA_REPAIR` and the 10-bit
`SW_i`/`LEDR_o` ports (§1.7.a/§1.7.d).

**A THIRD benchmark bug found, same class as test4's (question B5):** shipped test1 gates EINT on
SW0 — the SW0=0 short-delay path (its own comments: "used for ModelSim based verification") jumps
past `ori gp,gp,1`, so GIE never sets and the application is dead. tests 2/3/4 enable EINT
unconditionally; test1 alone differs. Both corrected copies are **one audited word each**, derived
from the originals at build time by `patch_bench_images.py` (aborts if the original ever changes):
test1's `jal` retargeted to land ON the EINT (no instruction moves — the vector table stays
valid); test4's `capture` writes `0x06` (its own comment says "set to VCC" while the code writes
GND — the fix implements the comment, and Hanan's prep-session walkthrough).

**The harness:** `tb_bench_test1` runs the supplied application as the contract it is — expected
values read from the shipped images word by word, not from our RTL. KEY1 → `0x64` on HEX5:4;
KEY2 → `8` on HEX3:2; KEY3 → the full STATE3 **sweep** (fp stays 3 on the increment path — one
press animates all eight divisions, which is the ReadMe's ~1s-per-step behaviour under the FPGA's
long delay), ending on the sweep's own tail: pass 9 divides `MEM[0x44]=8` by `MEM[0x64]=0`, so the
final display is the divide-by-zero contract — HEX1:0 = `FF` (all-ones quotient, F4) and LEDR =
`0x08` (remainder = dividend). Liveness is event-driven: a second sweep must drive LEDR *through*
`0x04` before settling at `0x08` — a hung system cannot pass on stale displays.

**tests 2/3 in ModelSim — a decision, recorded:** their interrupt interval is `SEC_PERIOD` =
20,000,000 SMCLK ticks (×8 under the programmed ÷8 — question B2 either way), which no simulation
can sit through as shipped. They are **FPGA material**; if ModelSim coverage is ever wanted, the
route is another separately-marked one-word copy (a short `BTCMPR0`), not a quiet edit. test4's
harness (compare / PWM / capture with the corrected copy) is 10B.

**Adar's results — Phase 10A**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_bench_test1.do` (it stages `bench_fixed\test1` itself) | `VERDICT: PASS`, failed 0 | |
| once, for the report: `set ORIGINAL 1` at the top of the script, re-run | everything after init fails, displays frozen at 0 — the B5 bug reproduced | |

*(2026-08-26: `run_bench_test1.do`'s `vsim` line was missing `-gMODELSIM=1` — at the committed
package default the clock tree instantiates real `pll_gen` megafunctions. Fixed before the script
was ever run; found by the Phase 10B source review.)*

### Phase 10B — test4, self-checking, on the corrected copy  ·  **built 2026-08-26, awaiting verification**

**Goal.** Run the supplied test4 application — the ReadMe's compare / output-compare-PWM /
input-capture contract — on the full MCU in ModelSim, self-checking, using the one-word corrected
copy `bench_fixed/test4` (the G-327 CAPISEL fix, Phase 10A's audit).

**Relevant requirements.** Clause 8's benchmark validation; the ReadMe.txt test4 contract
(§1.5.d); the Benchmarks-are-a-Contract rule (originals untouched, corrected copies separate and
marked).

**Existing references found.** `test4/asm-code/{00_main.s,01_func.s,io_map.s}` +
`Intrrupt-based IO/ReadMe.txt:102–135` (the program and its intent comments);
`bin/M9K-intel/*.hex` and `bench_fixed/test4` (images — re-verified word-identical except ITCM
word 265); `BASIC_TIMER.vhd`/`INTERRUPT_CTRL.vhd`/`RV32IMscMCU.vhd` (the RTL the program lands
on); `tb_bench_test1.vhd` (the 10A harness pattern), `tb_intr_mmio.vhd` (the exact-store
scoreboard), `tb_timer_mmio.vhd` (the PWM pin-measurement loop, copied verbatim);
`mem_dump.do` (the hierarchical-reach precedent the capture spy uses).

**What was reused.** The 10A entity/procedures/verdict shape; tb_intr_mmio's debug-tap scoreboard
hardened to a full ordered 83-store trace; tb_timer_mmio's PWM measurement; the staging and
script conventions.

**What was developed.** `TB/RV32IMscMCU/tb_bench_test4.vhd` (the harness),
`SIM/RV32IMscMCU/run_bench_test4.do` (staging, own `vcom`, `-gMODELSIM=1`, and a Tcl `when`
counter on `/tb_bench_test4/MCU/TIMER/cap_ev_w` — expected exactly 3, one per KEY3 press). The
83-entry expected-store trace was derived instruction by instruction from the shipped sources for
the press sequence **KEY3, KEY3, KEY1, KEY3, KEY2, KEY2** — chosen so that (a) the PWM only ever
starts from a parked-and-cleared BTCNT (EQU0 is an equality compare; starting above BTCMPR0
strands the PWM until 32-bit wrap), and (b) no latched raw BTIFG ever precedes an IE write that
re-enables BTIE, so the A22 masked-pending reappearance and a nested BT entry inside a KEY ISR
are structurally avoided. a7's per-mode read phase (KEY2's config reads it *before* its ISR
increments; STATE1/STATE3 read *after*) is tracked press by press: parities 1,2,4 → rem, div,
div; KEY1 sees `a7&3 = 3` → the 0.125 s arm; KEY2 sees 4 then 5 → BTCMPR1 = 250 then 125.

**⚠ TWO NEW BENCHMARK FINDINGS — test4's runtime measurement is structurally zero, beyond G-327
(question B6).** Found while deriving the expected values; verified in both the sources and the
RTL, and nowhere previously recorded:

1. **`capture_init` clobbers BTINT.** `bt_capture_config` arms BTINT=2 (`BTCTL1←0x26`,
   `01_func.s:156–158`) but `capture_init` then writes `BTCTL1←0x24` (`01_func.s:177–179`) —
   BTINT="00", so `btifg_set_o` is routed from EQU0 (`BASIC_TIMER.vhd:355–359`), and the capture
   event the one-word fix creates **raises no BT interrupt**. `BT_ISR`'s state-3 arm
   (`00_main.s:187–192`, `MEM[a6]←BTCAPR`) never executes.
2. **BTCNT is pinned at zero through the measured window.** Both capture-flow BTCTL1 values
   (0x26, 0x24) keep BTHOLD=1 **and** BTCLR=1; BTCLR zeroes BTCNT every edge
   (`BASIC_TIMER.vhd:287–288`), so BTCAPR latches **0** even when the edge fires. A "runtime"
   measured with the counter held and cleared is 0 by construction.

   So even the CORRECTED copy leaves `runtime_div`/`runtime_rem` at their `.data` zeros — the
   only expectation the sources support, and what the harness asserts. The capture EDGE itself
   (what the one-word fix exists to create) is proven by the run script's `cap_ev_w` counter.
   Per the Benchmarks-are-a-Contract rule the copy stays at ONE audited word; making the
   measurement actually work needs `capture_init` to preserve BTINT and release the counter —
   a different program, not a patch we invent silently. Asked as **B6** in `DOC/05`.

**Open questions.** B6 (above); B2 unchanged (affects only mode 1's real-time meaning — every
mode-1 interval is ≥ 2.5M ticks, so the compare-mode *cadence* is FPGA material exactly like
tests 2/3, and the harness proves the mode-1 configuration path only).

**A verification nugget worth keeping (found by the adversarial review of the 83-entry trace,
2026-08-26):** between reset and `intr_config`, the timer's reset state (BTCTL1 = 0x00 → counting
enabled, BTCNT = BTCL0 = 0) makes `equ0_ev` fire **every cycle**, silently latching raw BTIFG.
It is invisible (IE = 0, GIE = 0) and the shipped program happens to clean it up in its own first
three stores — `BTCTL1←0x24` stops the set-pulse and `IFG←0` W0C-clears the residue. The
harness's expected IFG-read values (all zero) depend on exactly that; a program that skipped
`intr_config`'s IFG clear would take a phantom BT interrupt the moment it set BTIE. Worth a
sentence in the report's interrupt chapter.

**Verification plan / files.** Below; `compile.do` untouched.

**Adar's results — Phase 10B**

| Check | Expect | Result |
| --- | --- | --- |
| `do run_bench_test4.do` (it stages `bench_fixed\test4` itself) | `VERDICT: PASS`, failed 0, **and** `CAPTURE EVENTS SEEN: 3 of 3` | |
| once, for the report: `set ORIGINAL 1` at the top of the script, re-run | first scoreboard mismatch at store #28 (`201D` = 06 expected, 07 got) and `CAPTURE EVENTS SEEN: 0` — G-327 reproduced | |

- **Exit:** all mandatory checks pass with saved logs, memory diffs and report-ready waveforms.
  **G-204**: `mem_dump.do` exports 1024 of 2048 DTCM words — extend it or document the limit.

## Phase 11 — Pipeline port  ·  bonus 10%  ·  Yehonatan writes · Adar verifies

- **Process precondition from the prep session (§1.6.d):** the bonus is conditional on finishing
  the base project and **registering with Hanan by a date he will announce**; registrants get a
  dedicated ~half-hour lecture on moving the core, the accelerator and the peripherals to
  pipeline. Register as soon as the base is done — the lecture is reference material this phase
  currently does not have.
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

- **Process precondition from the prep session (§1.6.d):** same registration gate as Phase 11, and
  registrants **receive ready HDL from Hanan** to adapt and integrate as a bus peripheral. That is
  presumably the already-shipped `USART Material/UART_FPGA_option{1,2}` — **confirm at
  registration whether a further handout supersedes them** before building the register layer on
  option 1.
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

## Phase 13 — Regression and evidence  ·  **built 2026-08-26 · Adar runs**

**Goal.** One command that runs the whole single-cycle suite, scores it, and **fails loudly** —
closing **G-203**, which was that `batch_verify.do` only ever echoed, so a failing regression
looked exactly like a passing one to anything but a careful human reader.

**Existing references found.** `SIM/RV32IMpipelinedMCU/batch_verify.do` (the loop-and-examine
shape, and its own missing exit status); `SIM/RV32IMscMCU/run_test.do` (the `when` stop condition
and the staging idiom); `mem_dump.do` (the 2048-word dump); `Auxiliary/Lab 5/SIM/RV32IM_sc/
DTCM_test{1,2,3,4}_MS.mem` (the reference's own full-range captures — all four present, 2051 lines
each); the 18 existing `run_*.do` scripts and their testbenches' `VERDICT` lines.

**What was built — `SIM/RV32IMscMCU/regress.do`.** Headless: `vsim -c -do regress.do`, then read
the exit status (0 / 1). It compiles once, then:

- **Part A — all 18 self-checking tests**, scored by one uniform rule that needs no per-test
  knowledge: a log containing `VERDICT: FAIL` or `VERDICT: INCOMPLETE` failed, `VERDICT: PASS`
  passed, and **no `VERDICT` line at all also fails** ("never reached its summary" — the failure
  mode a grep-for-PASS regression misses). Per-test transcripts go to `logs\<name>.log`; the table
  is the summary, the log is the evidence. Two extra machine-checkable facts are folded in:
  test4's capture-event count (must be 3) and Part B below.
- **Part B — the four RV32IM benchmarks, actually compared.** `mclk_cnt_o` against
  134 / 1514 / 2725 / 2735, **and** the DTCM dump diffed word by word against the reference's own
  2048-word capture, reporting the first differing word and its two values. If the one-time
  `C:\TestPrograms\Quartus21_1\test1..4` layout is absent it **skips Part B with a named reason**
  and says so again in the summary — it never silently reports a partial pass as complete.

**Two supporting changes so the flow has no manual step** (Phase 13's own exit criterion):

- **Seven scripts now stage their own images** — `run_mmio`, `run_gpio`, `run_gpio_read`,
  `run_gpio_directed`, `run_timer_mmio`, `run_intr_core`, `run_intr_mmio`. They used to instruct
  the operator to copy files by hand, which is the likeliest way to get a wrong-but-plausible
  result (a stale image set from the previous test). `run_isa.do` already did this; all 18 now do.
- **`repair_check.do` no longer takes the tool down** when sourced (`quit` guarded by `::REGRESS`),
  and its verdict line gained the `PASS`/`FAIL` keyword the uniform rule needs — as did
  `tb_isa_directed.vhd`, the one testbench whose verdict did not start with either.

**`tools/check_staging.py` — the static half.** Phase 13 also asks to *assert* that `ITCM.h` is
never loaded as an ITCM source. This lint reads every `.do`, checks every `app_bin` staging copy
is an existing `.hex`, and rejects `Hexadecimal-Text` sources. It runs on the Mac in a second,
**passes clean today (34 copies across 33 scripts)**, and was self-tested against three
deliberately bad lines to prove it can fail. It also catches path rot — which is not
hypothetical: it is exactly the class of bug found the same day in `DOC/04` §3, whose staging
table still pointed at `Auxilary/testN/…` after Adar's restructure moved it to
`Auxilary/Benchmarks/testN/…` (fixed; all four paths verified present).

**Still to do here.** Report-ready waveform captures for interrupt tests 1–4 (needs a run), and
the pipeline's own regression once Phase 11 lands — `batch_verify.do` has the same missing exit
status and can take the same treatment.

**Adar's results — Phase 13**

| Check | Expect | Result |
| --- | --- | --- |
| `python3 tools/check_staging.py` (either machine) | `clean`, exit 0 | |
| `vsim -c -do regress.do` in `SIM\RV32IMscMCU`, then `echo %ERRORLEVEL%` | the summary table all `passed`, and **exit status 0** | |
| deliberately, once: break one thing and re-run | exit status **1**, and the table names the broken row — proves G-203 is really closed | |

- **Exit:** one regression summary covering every required test, with no manual source edits
  anywhere in the flow.

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

- `Final_report.pdf`, structured on `Auxiliary/Lab 5/DOC/Report_lab5.pdf`. Figures and
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
| **G-203** | ~~`batch_verify.do` never returns a failing exit status.~~ **CLOSED for the single-cycle side 2026-08-26 (Phase 13)** — `SIM/RV32IMscMCU/regress.do` scores all 18 tests plus the four benchmarks and `quit -code 1`s on any failure, and `tools/check_staging.py` is the static half. The **pipeline's** `batch_verify.do` still only echoes; same treatment when Phase 11 lands. |
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
| ~~G-306~~ | GPIO buffer registers. **CLOSED 2026-08-24** across 6A (the seven output ports and the 7-segment path), 6B (the read path, one bidirectional bus) and 6C (`PORT_PB`). Verified by a 35-store directed suite that needs no benchmark and no switch flip, plus `tb_gpio` and `tb_gpio_read` on the supplied GPIO test0 and test1. | §5, §6 |
| **G-307** | `div`/`divu`/`rem`/`remu` decode — masks exist, hardware does not | §2 |
| ~~G-308~~ | `mulh`/`mulhsu`/`mulhu` — **CLOSED 2026-08-24, NOT REQUIRED.** Hanan's forum: *"`mul` only (as in Lab 5)"*, and the base task is *"extend the RV32I single-cycle to RV32IM … including support for a 16-bit multiplier only"*. Nothing to build. | §2 |
| **G-309** | Byte enables and sub-word load/store. `altsyncram` had no `byteena_a`; `CONTROL` detected `lb`/`lh`/`sb`/`sh` then discarded the width. **Built in Phase 3B**, awaiting verification. | §2 |
| **G-310** | CDC synchroniser. **CLOSED 2026-08-24** (Phase 4A) — `DUT/RV32IMscMCU/SYNC.vhd` plus a self-checking testbench. The figure specifies **three** flip-flops, not two: one launch register in the slow domain, two settling stages in the fast one. | Figures 10a/10b |
| **G-311** | Multi-output clock tree. **RESHAPED 2026-08-24 and no longer blocked on the megafunction.** Hanan's forum, asked whether `MCLK`/`ACCELCLK`/`SMCLK` come from one PLL module: *"No — on the basis of three different PLL instances"*, each fed by the 50 MHz base. So the existing single-output `PLL.vhd` is instantiated **three times** with different multiply/divide ratios — nothing has to be regenerated for `c1`/`c2`, which was the whole Phase 4B blocker. And `MCLK = SMCLK` is permitted for a single-cycle core. | Figure 1 |
| **G-312** | Edge detector / one-shot for KEY1-3 | §6.i |
| **G-313** | UART register layer | §6.iv, p12 |

## Design — defects in supplied code

Status column added 2026-08-23. **"repaired"** means the fix is written and compiled in
(unconditionally since 2026-08-26 — §1.7.a); it becomes *closed* when Adar's `repair_check.do` and
`run_isa.do` numbers are in Phase 3A above. Every repair is a transcription from the reference
pipeline — see §0.a for the before/after line pairs.

| ID | Defect | Origin | Status |
| --- | --- | --- | --- |
| **G-321** | `andi` writes 0; `ori` computes AND | student regression; baseline `CONTROL.VHD:141` is correct | repaired (3A) |
| **G-322** | `lui` writes 0 | **lecturer's baseline**, `const_package.vhd:27` | repaired (3A) |
| **G-323** | Loads address `rs1 + 0` | **lecturer's baseline**, `IDECODE.VHD:94-101` | repaired (3A) |
| **G-324** | `sra` ≡ `srl` | **lecturer's baseline**, `EXECUTE.VHD:179` | repaired (3A) |
| **G-325** | Unsigned compares are signed | **lecturer's baseline**, `EXECUTE.VHD:9` | repaired (3A) |
| ~~G-326~~ | `mul` is 16×16 unsigned, lower half-words only — **NOT A DEFECT. CLOSED 2026-08-24.** Hanan's forum says the required core is the Lab 5 RV32IM *"including support for a 16-bit multiplier only"*. The supplied behaviour **is** the specification, so the four `mul_*` mismatches in the ISA suite are the suite measuring conformance the project does not ask for, not bugs. | `EXECUTE.vhd:93-94` | closed — not a defect |
| **G-327** | test4's capture input never changes; `CAPISEL` stays at GND | supplied benchmark, current revision | open |
| **G-328** | **NEW.** Branch/`jal` displacement truncated one bit: `EXECUTE.vhd:66` slices `(PC_WIDTH-3 DOWNTO 0)`, dropping immediate bit 11, so branch range is ±2 KiB instead of the full 8 KiB PC. No benchmark reaches that far, so it is latent and the golden DTCMs still match. | **lecturer's baseline**, `EXECUTE.VHD` | repaired (3A) |
| **G-329** | **NEW.** `jalr` does not clear the target's bit 0 (`IFETCH.vhd:93`). Masked today by the word-granular ITCM dropping bits 1..0, but `pc_o`, `pc_plus4` and every link address carry the odd value. | **lecturer's baseline**, `IFETCH.vhd` | repaired (3A) |
| **G-330** | **NEW.** Our `DUT/RV32IMpipelinedMCU/` was an entire revision behind the reference and its wrapper referenced retired ports (`BPTRIGGER_o`, `stall_o`, `flush_o`, 8-bit counters) — it could not have compiled. | our tree, from the 2026-08-23 reference update | re-imported (3D) |
| **G-331** | `Auxilary/Ori/` — another student's pipeline. **CLOSED 2026-08-23:** permitted as a reference, never as code. It independently confirms the defect 6 and defect 7 repairs with identical expressions, and confirms no byte-enable reference exists anywhere. See §0.d. | another student, via Yehonatan | closed |
| **G-334** | **NEW, found by the Phase 5B review.** `aux_package.vhd`'s `RV32IM_CORE` **component** defaults `PC_WIDTH` and `MA_WIDTH` to `10`, while the **entity** defaults them to `G_PC_WIDTH`/`G_MA_WIDTH` = `13`. Every other generic in the same component forwards its `G_*` constant; only these two are hardcoded. Latent today — the sole instantiation associates both explicitly — but a component's default is what fills an unassociated generic, so any future bare-core instantiation would elaborate with `MA_WIDTH = 10` against `DTCM_ADDR_WIDTH = 11`, making `dtcm_addr_w` 8 bits wide against an 11-bit port. Inherited verbatim from `Auxiliary/Lab 5/DUT/RV32IM_sc/aux_package.vhd:21-22`, so **not changed unilaterally** — surfaced here per the no-blind-copy rule. Fix is two words when we decide to. | **lecturer's baseline** | open, latent |

## Verification

| ID | Gap |
| --- | --- |
| **G-401** | No self-checking testbench anywhere. The whole reference tree contains two assertions, both in `Auxilary/Lab3/TB/tb_top.vhd`, both used as a stop mechanism. |
| **G-402** | Directed ISA testbench — built in Phase 2, and two bugs in it found and fixed in Phase 3B (a one-off store-count shift, and a sub-word case that could not fail). Awaiting its first real run. |
| **G-204** | `mem_dump.do` exports 1024 of 2048 DTCM words; the upper half is never checked. |
| **G-403** | Per-component test plans not written. |
| **G-404** | `Benchmark Apps/RV32IM/test1/output/RARS/DTCM.hex` is a stale golden — 16 words disagree with `DTCM.h`. Would fail a correct CPU. |
| **G-407** | The seven GPO read-back tri-states of Figure 5 were exercised by nothing — no supplied benchmark reads `PORT_LEDR` or a `PORT_HEXn`. **CLOSED 2026-08-24** by the directed GPIO test, which reads all seven back. Read-back is also what closed G-406, since it is what makes a port's content observable. The paths still rest on assumption **A15**; if Hanan says an output port must not answer a read, the action is `GEN_GPO_READBACK => FALSE` and this suite's read-back cases go with it. |
| **G-406** | `tb_gpio`'s cross-talk check is one-sided — GPIO test0 writes the *same* value to all seven GPO ports in ascending address order, so a port wrongly capturing a **later** store re-captures a value it already holds and is invisible. **CLOSED 2026-08-24** by the directed GPIO test: `tools/gen_gpio_test.py` writes **different** values to the two halves of each shared chip select in **both** orders and reads both back, so store 3 catches an extra capture by `PORT_HEX0` and store 8 catches one by `PORT_HEX1`. |
| **G-405** | GPIO suite never writes the DTCM, so no golden-memory comparison is possible. |

## Documentation and submission

| ID | Gap |
| --- | --- |
| **G-501** | Q1–Q13 unanswered. `DOC/03_open_questions.md`. Send Q1–Q3 now. |
| **G-502** | Submission `DOC/Readme.txt` not written. Template: `Auxiliary/Lab 5/DOC/readme.txt`. |
| **G-503** | `Final_report.pdf` not started. Template: `.../DOC/Report_lab5.pdf`. |
| **G-504** | No DE2-115 expansion-header pin table anywhere in the material. UART pins need the User Manual. Do not copy the DE10-Standard pins — `PIN_W15`/`PIN_AK2`/`PIN_AK3` are valid on F29 too, so it compiles cleanly and mis-routes silently. |
| **G-505** | Ten assumptions recorded and unconfirmed. `DOC/02_requirements_traceability.md` §10. |

---

# 6. Documents

| File | Contents |
| --- | --- |
| `DOC/01_source_inventory.md` | Every component: supplied or not, exact path, provenance, reuse verdict |
| `DOC/02_requirements_traceability.md` | Every address, bit field, mode and clock with its source; four verification cross-checks; ten assumptions |
| `DOC/03_open_questions.md` | The long record: Q1–Q14 with a provisional decision each, **plus the full transcription of Hanan's forum answers** and what each closes or falsifies, **plus the digest of the recorded prep session** (received 2026-08-25) with its verbatim quotes |
| `DOC/05_questions_for_hanan.md` | **The sendable list** — only what is still open after the forum. 18 items, one "Ask" line each, grouped by what they block, plus a 23-row "do not re-ask" table |
| `DOC/04_baseline_runbook.md` | The Windows procedure, staging script, and exact expected numbers. **Rewritten 2026-08-24** for the replaced reference: sections 2, 4, 5.2, 6 and 8 all changed, and section 8.1b covers the Phase 3A/3B measurement |
| `SIM/baseline_reference/` | `compile.do`, `run_test.do`, `mem_dump.do` — replacements for the scripts the reference lost, reaching into `Auxiliary/` read-only |
| ``README-import.md` (removed by the 2026-08-25 Auxiliary restructure)` | What was imported and why the two Lab 5 copies differ |

---

# 7. Next actions

*Updated 2026-08-24, after Phase 4A and Phase 5A.*

## Adar — Lenovo

1. **One-time setup**, §0.2. Quartus 21.1, ModelSim 20.1, then the PowerShell staging block from
   `DOC/04_baseline_runbook.md` §3.
2. **Run 1 — Phase 0 baseline.** ~30 min. Fill in the Phase 0 results table. **This gates
   everything**; if the four counts do not reproduce, stop and report.
3. **Run 2 — Phases 1, 2, 3A.** Four result tables to fill. Steps in §0.3. **No source edit
   anywhere** — since 2026-08-26 the repairs are compiled in unconditionally (§1.7.a):
   - `repair_check.do` → **43/43**, `run_isa.do` → **5** mismatches (all mul-related), and the
     four benchmark counts unchanged (134 / 1514 / 2725 / 2735)
4. **Run 3 — Quartus.** Confirm **131,072** memory bits. Phase 5B added two files to
   `Quartus/RV32IMscMCU/RV32IMscMCU.qsf` (`ADDR_DECODER.vhd` and `SYNC.vhd`); if Analysis & Synthesis
   still reports an unbound component, that file list is the first place to look. The reference's own numbers to compare
   against are now in §0.c — note the pipeline figures all changed.
   **Also, one check that only Quartus can answer:** open ISMCE and confirm the `DTCM` instance
   still appears and can be read and written. Phase 3B added `byteena_a` to the same `altsyncram`
   that carries `ENABLE_RUNTIME_MOD = YES`, and ISMCE is the mandatory §8 validation loop. If the
   instance is gone, **report it and change nothing** — sub-word access and ISMCE are both
   mandatory, so a conflict between them is a question for Hanan. Details in `DMEMORY.vhd`.
5. **Four leaf tests, no setup needed.** `do run_sync.do` (4A), `do run_decode.do` (5A),
   `do run_clock.do` (4B) and `do run_div.do` (7A). None needs a memory image or `app_bin` staging,
   so they can be run any time — even before Run 1. Expected
   verdicts are in the 4A, 5A, 4B and 7A results blocks. `run_div.do` is the slow one: it sweeps all
   65536 operand pairs at N=8, so budget tens of seconds and watch for its progress lines.
   `run_clock.do` also carries **three Quartus-only questions** in its header — whether `pll_gen`
   fits, the inherited `"Cyclone II"` family string, and the shared `CBX_MODULE_PREFIX`.
6. **`do run_mmio.do`** (Phase 5B). This one **does** need staging (GPIO test0's `M9K-intel`
   images). Then re-run Run 2 in full: the four benchmark counts must be unchanged.
7. **Send the questions — `DOC/05_questions_for_hanan.md`.** Rewritten 2026-08-24 after the forum
   answers, and far shorter than it was: **Q6 and Q14 are answered**, and so are fifteen others.
   Eighteen items remain, each with a one-sentence "Ask" line ready to send as-is.
   **Send section 1 first** — four items, and they are the only ones that block a phase:
   - **B1** which board, DE2-115 or DE10-Standard — blocks every pin assignment
   - **B2** `SEC_PERIOD` versus `BTSSEL`, the factor of 8 — blocks Phase 8's timing
   - **B3** what `ACCELCLK`/`DIVCLK` should be — blocks Phase 4B's third PLL ratio
   - **B4** `BTINT`'s encoding, two bits for "three options" — blocks Phase 8

   Section 6 of that file is a **do-not-re-ask** table of the 23 things the forum settled, so no
   forum post is spent on an answered question.
8. **Answer G-207 and G-208** — what is in `finalProj`, and whether the two circled Quartus settings
   were instructions.
9. ~~Answer G-331~~ — done: `Auxilary/Ori/` is another student's pipeline, usable as a reference
   only. §0.d records what it is worth.

## Yehonatan — MacBook

1. ~~Commit and push~~ — done. ~~Update the `DOC/` documents for the new reference~~ — done in
   `82a1a11`. ~~Phase 5A~~ — done, see above.
2. ~~Phase 5B — wire the decoder in~~ — done. ~~Phase 6A — the seven GPO ports~~ — done.
3. ~~Phase 6B — the read path~~ — **done**, and 6C (`PORT_PB`) and 6D (the directed GPIO test) with
   it. The `SFRSTUB` placeholder is gone, the bus is one shared bidirectional bus with ten drivers,
   and GPIO test1 is runnable.
4. ~~Phase 7A — the divider engine~~ — **done**, `run_div.do`. The four forum answers F2–F5 unblocked
   it entirely (`Ain`=Dividend, registers core-internal, divide-by-zero all-ones, `-` operator
   allowed), so it was not blocked on anything.
5. ~~Phase 4B — the clock tree~~ — **done**, `run_clock.do`. *(This item used to say "the ALTPLL needs regenerating for
   `c0`/`c1`/`c2`". The forum answer F6 removed that work — Hanan: the three clocks come from
   **three separate PLL instances**, each fed by the 50 MHz base, not one multi-output PLL. The plan's
   own G-311 row already says "nothing has to be regenerated"; this item was the last place still
   saying the opposite.)* `MCLK = SMCLK = 20 MHz` is permitted (F7); only `ACCELCLK` is open, and that
   is **B3**. 4B also removes the transitional `mclk_o` port Phase 6A added to the core — that removal
   is part of 4B, not a separate cleanup.
6. ~~Phase 4C~~ — **done**: the tree is wired in, `clk_i` reaches `CLOCK_TREE` and nowhere else, the
   core's `mclk_o` is gone, the peripherals are on `smclk`, reset is held until lock, and the SDC is
   rewritten. **This is the phase that most needs Adar's numbers**, because it changed the clocking of
   every existing test at once.
7. **Next: Phase 7B** (the divider into the core — 4B now provides `DIVCLK`, and `accelclk_w` is
   already generated and waiting at the top level) **or Phase 8** (Basic Timer, still blocked on
   **B2** and **B4**). 7B is the better next step: it is unblocked, and it is what gives `accelclk`
   a load so the third PLL stops being pruned.

## The gate between us

**Phase 3A changed what the gate is.** It used to be "no repairs before the numbers arrive". The
switch replaced that: both measurements now come out of one build in one sitting, so nothing is
blocked on waiting.

What still gates:

- ~~**Phase 3C is blocked on Hanan**~~ — **no longer true, answered 2026-08-24.** Hanan: base on Lab 5
  part 1 and extend to RV32IM *"including support for a 16-bit multiplier only"*, and *"`mul` only (as
  in Lab 5)"*. So `mulh`/`mulhsu`/`mulhu` are **out of scope**, the 16-bit `mul` **is** the
  requirement, and `div`/`rem` are served by the Phase 7 accelerator rather than by an ALU operation.
  The remaining ISA-suite mismatches therefore stop being defects to fix and become
  conformance gaps beyond the project's scope — which is item R3 of `DOC/05`, a reporting question,
  not a build one.
- **Phase 4 onward is gated on Run 1.** If the Phase 0 baseline does not reproduce, nothing built on
  top of it means anything, and that is still true no matter how much is written on the Mac.
- **A partial `repair_check.do` failure stops everything.** All 15 failing means the wrong
  configuration was compiled. Some failing means a repair is wrong, and that has to be understood
  before any further component is built.
