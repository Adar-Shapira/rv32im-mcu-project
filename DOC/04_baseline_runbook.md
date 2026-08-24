# Deliverable D — Baseline Runbook (Step 2)

Reproduce a known-good run of the **unchanged** Lab 5 cores before any RTL is touched, so that a
later failure can be attributed to our change rather than to the reference, the tool install, or the
environment.

**This runbook executes on the Windows machine.** Everything it needs is already in the repository;
nothing has to be recreated from scratch. Sections 1–3 are preparation, section 4 is the run,
section 5 is the pass/fail criterion.

Based on `Auxiliary/Lab 5/ModelSim_Testing_Guide.md`, which is the students' own
documented working procedure, and on the supplied `.do` scripts in the same tree.

---

> ## ⚠ REVISED 2026-08-24 — the reference lost its scripts
>
> `Auxiliary/Lab 5 - as submitted/` was replaced with the real final Lab 5 submission, and the
> replacement **deleted `run_test.do`, `mem_dump.do` and `batch_verify.do`**. There is no `compile.do`
> for the single-cycle core anywhere in the reference tree either — only the pipeline has one. What
> remains in `SIM/RV32IM_sc/` is `golden.do`, `wave.do`, four captured DTCM dumps and the `.mpf`.
>
> **So this runbook's original section 4 cannot be followed literally.** Replacement scripts now live
> in **`SIM/baseline_reference/`** — `compile.do`, `run_test.do`, `mem_dump.do` — which reach into
> `Auxiliary/` read-only and leave it byte-for-byte as supplied. Section 4 below has been rewritten
> around them.
>
> Three other things changed that this document had wrong:
>
> 1. **No source edit is needed, anywhere.** `tb_RV32IM_sc` exposes `MODELSIM` as a generic and
>    forwards it to the core, so `-gMODELSIM=1` does the job. Section 2 used to tell you to edit the
>    reference's `cond_compilation_package.vhd` by hand — do not.
> 2. **The reference core now inverts reset itself** when `MODELSIM = 0`. Section 2 used to say the
>    submitted copy did not. It does now, which makes `-gMODELSIM=1` mandatory rather than merely
>    convenient.
> 3. **The captured dumps cover all 2048 DTCM words**, not 1024. Gap G-204 is effectively closed by
>    the new reference, and section 5.2 has been corrected.

---

## 0. What is being proven

| | |
| --- | --- |
| Design under test | `Auxiliary/Lab 5/DUT/RV32IM_sc/` — **unmodified** |
| Testbench | `Auxiliary/Lab 5/TB/RV32IM_sc/tb_RV32IM_sc.vhd` — unmodified |
| Scripts | `SIM/baseline_reference/{compile,run_test,mem_dump}.do` — ours, because the reference's were deleted. Wave view from `Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/golden.do`, unmodified |
| Benchmarks | Lab 5's own test1–test4 (add / mul / xor programs), **not** the Final Project benchmarks |
| Pass criterion | four exact cycle counts, and the DTCM dump identical to the reference's own capture in all **2048** words |

Do not substitute the Final Project benchmarks here. They exercise instructions the core gets wrong
(see `DOC/01_source_inventory.md` §2.2 — **seven** defects, not the five recorded there before
2026-08-23), so they would fail for reasons that have nothing to do with the environment.

---

## 1. Tool environment

| Item | Value | Source |
| --- | --- | --- |
| Quartus | Prime 21.1.0 Lite | `Auxiliary/Lab 5/Quartus/*/*.qsf` |
| ModelSim | Intel FPGA Starter Edition **20.1**, `C:\intelFPGA\20.1\modelsim_ase` | `ModelSim_Testing_Guide.md` §A.1 |
| VHDL standard | **2008 — mandatory** | `EXECUTE.vhd` uses `process(all)`; the core top uses `if/else generate` |
| Device | `EP4CE115F29C7` (Cyclone IV E, DE2-115) | `.qsf` |

`SIM/baseline_reference/mem_dump.do` addresses simulator internals
(`/tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a`), which version-locks it to ModelSim ASE
2020.1. A different ModelSim version will fail at the dump step, not at compile. Note the path has
**no wrapper level** — this is the bare reference core. Our own tree needs
`/tb_rv32imscmcu/MCU/CORE/...`, and that one extra level is the commonest cause of an empty dump,
which `mem save` does not report as an error.

---

## 2. Simulation mode — **do not edit anything**

`Auxiliary/Lab 5/DUT/RV32IM_sc/cond_compilation_package.vhd:51` ships as:

```vhdl
constant G_MODELSIM : integer := 0;   -- options{1=MODELSIM,0=FPGA}
```

The earlier version of this runbook told you to set it to `1` by hand and back to `0` before Quartus.
**Don't.** `tb_RV32IM_sc` declares `MODELSIM` as a generic
(`TB/RV32IM_sc/tb_RV32IM_sc.vhd:19`) and forwards it to the core (line 61), so

```
vsim -t ns -gMODELSIM=1 work.tb_rv32im_sc
```

does the job with the package default left alone — which is what Quartus wants anyway. This is what
closes **gap G-201**, and `SIM/baseline_reference/run_test.do` already does it.

Getting this wrong is not subtle. The revised reference core inverts reset when `MODELSIM = 0`:

```vhdl
rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i;   -- DUT/RV32IM_sc/RV32IM_CORE.vhd
```

Compiled at the default, the testbench's active-high `rst_i <= '1','0' after 80 ns` is inverted into
a permanent reset assertion: the core sits at PC 0 forever, the transcript shows no errors, and
nothing runs. The older copy at `Auxiliary/Lab 5/` did not do this — the submitted one does.

**Keep `Auxiliary/` untouched.** It is reference-only by rule, and with `-gMODELSIM=1` there is now no
reason to modify a single byte of it.

---

## 3. Stage the benchmark images

The RTL hardcodes its memory init path at two sites —
`IFETCH.vhd:64` and `DMEMORY.vhd:50`, both
`init_file => "C:\TestPrograms\Quartus21_1\app_bin\{ITCM,DTCM}.hex"` — so whatever sits in
`app_bin` when the simulation loads is the program that runs. Leave those lines alone for the
baseline; they are the documented convention, and changing them changes what we are trying to
reproduce.

Create this layout on the Windows machine:

```
C:\TestPrograms\Quartus21_1\
  app_bin\                  <- run_test.do copies the selected test in here
  test1\bin\ITCM.hex  DTCM.hex
  test1\RARS\DTCM.h
  test2\bin\...   test2\RARS\...
  test3\bin\...   test3\RARS\...
  test4\bin\...   test4\RARS\...
```

Every file comes from the repository. Source paths, relative to the repo root
(`Auxiliary/Lab 5/Auxilary/` abbreviated as `AUX/`):

| Destination | Source |
| --- | --- |
| `test1\bin\ITCM.hex` | `AUX/test1/RV32IM/man_compiled/bin/M9K-intel/ITCM.hex` |
| `test1\bin\DTCM.hex` | `AUX/test1/RV32IM/man_compiled/bin/M9K-intel/DTCM.hex` |
| `test1\RARS\DTCM.h` | `AUX/test1/RV32IM/man_compiled/output/RARS/DTCM.h` |
| `test2\…` | `AUX/test2/RV32IM/man_compiled/…` (same three files) |
| `test3\…` | `AUX/test3/RV32IM/man_compiled/…` |
| `test4\…` | `AUX/test4/RV32IM/man_compiled/…` |

Use the **`RV32IM/man_compiled`** variant, not `RV32I` and not `gcc_compiled`. The guide's expected
values assume it (`res2` holds products, so the program must contain `mul`), and `gcc_compiled`
images do not exist for test2–test4 — only their `.s` sources do.

Use **`bin/M9K-intel/*.hex`**, never `bin/Hexadecimal-Text/ITCM.h`. The two are different programs:
the `.hex` images are assembled for text base 0, the `.h` images retain RARS's `0x3000` base and are
not loadable. See `DOC/02_requirements_traceability.md` §7.

PowerShell to do it, run from the repo root:

```powershell
$aux = "Auxiliary\Lab 5\Auxilary"
$dst = "C:\TestPrograms\Quartus21_1"
New-Item -ItemType Directory -Force -Path "$dst\app_bin" | Out-Null
foreach ($n in 1..4) {
    New-Item -ItemType Directory -Force -Path "$dst\test$n\bin","$dst\test$n\RARS" | Out-Null
    $src = "$aux\test$n\RV32IM\man_compiled"
    Copy-Item "$src\bin\M9K-intel\ITCM.hex"  "$dst\test$n\bin\ITCM.hex"  -Force
    Copy-Item "$src\bin\M9K-intel\DTCM.hex"  "$dst\test$n\bin\DTCM.hex"  -Force
    Copy-Item "$src\output\RARS\DTCM.h"      "$dst\test$n\RARS\DTCM.h"   -Force
}
Write-Host "staged"
```

---

## 4. Run

1. Open ModelSim 20.1.
2. **File → Change Directory…** → `SIM\baseline_reference` (in our tree, **not** in `Auxiliary`).
   The scripts there reach into the reference read-only, and the `work` library is created here so
   the reference folder stays clean.
3. **Tools → Tcl → Execute Macro…** → `compile.do`.
   Expected: **0 errors**. Three warnings on `EXECUTE.vhd` ("Non-locally static OTHERS choice") are
   known and harmless.
4. Edit `set N 1` at the top of `run_test.do`, save.
5. **Tools → Tcl → Execute Macro…** → `run_test.do`.
   It stages the images, loads the testbench with `-gMODELSIM=1`, applies the reference's own
   `golden.do` wave view, runs to the `while(1)` self-jump, and prints the cycle count next to the
   expected one.
6. **Execute Macro…** → `mem_dump.do`, which writes `DTCM_testN_run.mem` and prints the
   PowerShell one-liner to diff it against the reference's own capture.
7. Repeat 4–6 for `N` = 2, 3, 4. Recompiling is **not** needed between tests — the memories are read
   when the simulation loads.

Mechanics worth knowing:

- The testbench clock is **100 ns period = 10 MHz** (`tb_RV32IM_sc.vhd:102-109`). So simulated time
  and cycle count are related by exactly 0.1 µs per cycle, which is why test1's 134 cycles land at
  13.4 µs. This is a simulation-only clock; the PLL is bypassed at `G_MODELSIM = 1`.
- Reset is `rst_i <= '1', '0' after 80 ns` — active-high, released at 80 ns.
- The run stops on `instruction_o` reaching `0x00000063` (`beq x0,x0,0`) or `0x0000006F`
  (`jal x0,0`), via the Tcl `when` block in `run_test.do`. **The reference testbench no longer stops
  itself** — its `monitor_end_of_program` process with `std.env.stop` was removed in the 2026-08-23
  replacement, so a plain GUI *Run -All* there never terminates. Gap **G-333**.
- The 5 ms bound only catches a runaway. If a run hits it with the PC still moving, the program
  never finished — that is a core or environment fault, not a time limit to raise.

---

## 5. Pass criterion

### 5.1 Cycle counts — must match exactly

| Test | `mclk_cnt_o` | Stops at | `pc_o` | `instruction_o` |
| --- | --- | --- | --- | --- |
| test1 | **134** | 13.4 µs | `0070` | `00000063` |
| test2 | **1514** | 151.4 µs | `0070` | `00000063` |
| test3 | **2725** | 272.5 µs | `00CC` | `00000063` |
| test4 | **2735** | 273.5 µs | `004C` | `00000063` |

### 5.2 Golden comparison — zero differences

`mem_dump.do` writes `DTCM_testN_run.mem` in the working directory. Diff it against the reference's
own capture at

```
Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/DTCM_testN_MS.mem
```

skipping the 3 header lines, and expect **all 2048 words identical**. `mem_dump.do` prints the exact
PowerShell command.

**The range changed on 2026-08-23, in our favour.** The old captures were 1024 words and the old
`mem_dump.do` exported 1024, so the upper half of the DTCM was never checked by anything — gap
**G-204**. The new captures are 2051 lines: 3 header lines plus **2048 data words**, i.e. the whole
memory. `SIM/baseline_reference/mem_dump.do` exports the same 2048-word range so the diff is
byte-for-byte, and G-204 is closed on the single-cycle side.

The reference captures are the better comparison target here — they are what this exact RTL produced
on hardware-validated runs. The RARS `DTCM.h` goldens remain the *architectural* truth and are what
Phase 10 compares against once the core is repaired; note **G-404**, that
`Benchmark Apps/RV32IM/test1/output/RARS/DTCM.hex` is stale and `DTCM.h` is the one to use.

### 5.3 Spot check on test1

`View → Memory List` → `/tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a`, words 0–39:

| Words | Contents | Expected |
| --- | --- | --- |
| 0–7 | `arr1` | `01 02 03 04 05 06 07 08` |
| 8–15 | `arr2` | `08 07 06 05 04 03 02 01` |
| 16–23 | `res1` = add | all `00000009` |
| 24–31 | `res2` = **mul** | `08 0E 12 14 14 12 0E 08` |
| 32–39 | `res3` = xor | `09 05 05 01 01 05 05 09` |

If `res2` is right, the `mul` datapath and `MUL16` are working — which is the one piece of the M
extension the baseline actually implements.

---

## 6. Pipeline baseline

Repeat sections 2–5 against `Auxiliary/Lab 5 - as submitted/SIM/RV32IM_pipeline/`. That folder **does**
still have its own `compile.do`, and it is the one place the reference kept one — it now lists
`MULT_1.vhd`, `MULT_2.vhd` and `WRITEBACK.vhd` alongside `HAZARD_UNIT.vhd` and `FORWARD_UNIT.vhd`,
and no longer lists `MUL16.vhd`, which is present in the folder but not instantiated. The testbench
is `tb_RV32IM_pipeline`.

`batch_verify.do` was **deleted** in the replacement, so gap **G-203** (it never returned a failing
exit status) is moot on the reference side; our own copy at `SIM/RV32IMpipelinedMCU/batch_verify.do`
still has that weakness.

What the reference gained instead is more useful: **`SIM/RV32IM_pipeline/directed_isa.do`**, its own
directed regression for the ISA repairs. `SIM/RV32IMscMCU/repair_check.do` is the single-cycle port
of it — see the plan file §0.a.

**The pipeline stop condition is different and it matters.** Do not halt when the `while(1)`
self-jump appears in a decode stage: branches resolve in MEM, so speculative fetch brings it into ID
during the first loop iteration, where it is flushed. Halt on a MEM flush whose redirect target is
the redirecting instruction's own PC. Our `SIM/RV32IMpipelinedMCU/run_test.do` implements exactly
that, watching `MCU/CORE/flush_w`.

Expected pipeline counters, from `PROJECT_EXPLANATION.md` §8.6 — note these include the testbench's
drain interval, so treat them as a sanity range and not an exact target:

| Test | `CLKCNT` | `STCNT` | `FHCNT` |
| --- | ---: | ---: | ---: |
| 1 | ~170 | 8 | 8 |
| 2 | ~1,918 | 100 | 100 |
| 3 | ~3,623 | 0 | 298 |
| 4 | ~3,651 | 0 | 304 |

The pipeline's own cycle counts are not recorded in the guide and must be captured during this run;
they are the input to the IPC check in roadmap Step 12. Tracked as **Gap G-205**.

Reference PPA figures for the submitted pipeline build, for cross-checking a Quartus compile later:
3,384 logic elements, 1,696 registers, 297 pins, 131,072 memory bits, 4 multipliers, 1 PLL, and
**Fmax 41.84 MHz**. Single-cycle **Fmax 26.81 MHz** on `\G0:MCLK|altpll_component|pll|clk[0]`,
Slow 1200 mV 85 °C model — verified from
`Auxiliary/Lab 5 - as submitted/Screenshots/Quartus/SC/fmax.png`.

---

## 7. What to record

Write the outcome into the plan file's status table, and save under `Screenshots/ModelSim/`:

- the four cycle counts as measured
- the four compare results
- the transcript of the compile, showing 0 errors and the three known warnings
- ModelSim version string, so a later environment change is detectable

If any of the four cycle counts differs from section 5.1, **stop**. Do not start Step 3. A baseline
that does not reproduce means the environment differs from the one that produced these numbers, and
every later result would be uninterpretable.

---

## 8. Phase 1 verification — the same numbers through the new wrapper

Section 4–5 prove the *reference*. This section proves that our new structural top level is
behaviourally transparent, which is the Phase 1 exit criterion.

Nothing about the CPU changed between the two runs. The only difference is that
`RV32IMscMCU` now sits between the testbench and `RV32IM_CORE`, conditioning reset and gating the
observation ports. If the cycle counts move, the wrapper is not transparent and must be fixed before
any further work.

### 8.1 ModelSim

1. **File → Change Directory…** → `SIM\RV32IMscMCU` (the project tree, not `Auxiliary`).
2. Execute `compile.do`. Expected: **0 errors**, and the same three known
   "Non-locally static OTHERS choice" warnings on `EXECUTE.vhd`.
3. Edit `set N` in `run_test.do`, execute it, for N = 1..4.

**No source edit is needed to switch to simulation.** `run_test.do` passes `-gMODELSIM=1`, which the
testbench forwards to the wrapper and the core. `cond_compilation_package.vhd` keeps its shipped
default of `0` so Quartus needs no edit either.

**Expected: identical to section 5.1** — `mclk_cnt_o` = 134 / 1514 / 2725 / 2735, halting at `pc_o` =
`0070` / `0070` / `00CC` / `004C` with `instruction_o = 00000063`, and the DTCM dump matching the
reference capture word for word.

This holds because the tree ships with `G_ISA_REPAIR = FALSE`, which reproduces the submitted core
expression by expression. **Leave it alone for this section** — Phase 1 is about the wrapper being
transparent, and changing two things at once would tell you nothing about either.

If a dump comes out **empty**, the hierarchical path in `mem_dump.do` is wrong. It must be
`/tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a` — the `MCU` level is the wrapper and
is easy to omit. An empty dump is not reported as an error by `mem save`.

Then repeat for `SIM\RV32IMpipelinedMCU`. Its `run_test.do` already prints `CLKCNT_o`, `STCNT_o` and
`FHCNT_o`; **record all three per test** — they are the input to the IPC check and are written down
nowhere (G-205). That folder was rebuilt on 2026-08-23 for the revised pipeline: new file list in
`compile.do`, `golden.do` added, and the stop condition moved from the retired `flush_o` port to
`MCU/CORE/flush_w`.

### 8.1a Five tests that need nothing — run them first

No memory image, no `app_bin` staging, and they do not care what `G_ISA_REPAIR` is set to. Run them
straight after `compile.do`; if any fails, nothing after it is meaningful.

| Script | Phase | Expect |
| --- | --- | --- |
| `do run_sync.do` | 4A — CDC synchronizer | `VERDICT: PASS`, zero failures in all three checkers |
| `do run_decode.do` | 5A — address decoder | `VERDICT: PASS`, failures 0, totals **8192 / 29 / 8163** |
| `do run_clock.do` | 4B — clock tree | `VERDICT: PASS`, failures 0, ~**110** accelclk edges, **10** distinct phases |
| `do run_div.do` | 7A — division accelerator | `VERDICT: PASS`, failures 0, **N=8 65536 ops**, **N=32 517 ops** |
| `do run_divunit.do` | 7B1 — division subsystem | `VERDICT: PASS`, failures 0, **55 operations** |

`run_clock.do` is quick (about 3.3 µs simulated) but read its header before believing it: **it does
not verify the PLLs, and it cannot.** `altpll` is an Altera black box needing `altera_mf`, and the
course's own idiom — Hanan's, in `RV32IM_CORE.vhd` — is not to instantiate it in simulation at all.
What it does prove is the ratio arithmetic (at elaboration, exactly, for two different
configurations), that MCLK in simulation *is* `clk_i` (the property that lets Phase 4C wire the tree
in without moving a benchmark count), that ACCELCLK is genuinely independent of MCLK, and that both
branches of every generate compile. **Three items for you in Quartus** are listed in that script's
header — whether `pll_gen` fits at all, the inherited `"Cyclone II"` family string against the
board's Cyclone IV E, and whether three instances may share one `CBX_MODULE_PREFIX`. None of them
blocks the simulation; report whatever happens.

`run_decode.do` is exhaustive over all 16,384 addresses of the 14-bit data address space, so it is a
proof rather than a sample. It also runs `CHECK 0` first, which holds `const_package.vhd`'s map
against an address list transcribed separately from `io_map.s` — **if CHECK 0 fails, the
specification is wrong and the RTL may be a faithful implementation of it: fix `const_package.vhd`,
not the RTL.**

`run_div.do` is the longest of the three — about 13 ms of simulated time, tens of seconds of wall
clock — because it sweeps **all 65536 operand pairs** through an N=8 copy of the divider, and on
every single operation it also measures how long `DIVBUSY` stays high. It prints a progress line
every 16 dividends, sixteen lines in all, so a long run visibly advances instead of looking hung.
While editing the RTL you can use `vsim -t ns -gEXHAUSTIVE=0 work.tb_div_accel` to skip the sweep —
it then reports `VERDICT: INCOMPLETE` rather than `PASS`, on purpose, because a run without the
sweep has not verified the divider.

**This one should pass first time, and if it does not, say which half broke.** The toolchain is on
your machine, not ours, so the RTL was written where it could not be compiled. Instead
`tools/model_div_accel.py` transcribes it line for line into Python and runs the same 66,053 cases
against Python's own `//` and `%`: 0 failures, and eight deliberate mutations of it (inverted
non-negative flag, off-by-one counter, wrong `Y` slice, no restore, no quotient shift, level-
triggered start, right shift instead of left, divisor register never loaded) were **all** caught. So
a failure here points at the VHDL translation or the simulator setup rather than at the arithmetic —
and `run_div.do`'s footer lists which property failing means which. That distinction is the whole
reason both exist.

Note what this does **not** cover: it is the unsigned engine alone. Signed `div`/`rem`, the two clock
crossings, the stall and the write-back mux are Phase 7B, and 7B needs the `DIVCLK` that Phase 4B
produces.

### 8.1b Phases 3A and 3B — the "after" measurement

Only once 8.1 has reproduced the baseline. **One edit, then two runs.**

1. In `DUT\RV32IMscMCU\cond_compilation_package.vhd`, set `G_ISA_REPAIR := TRUE`.
   This is the one source edit the project asks for, and it is the switch's whole purpose: both the
   before and the after measurement come out of one build tree, so they cannot disagree about
   anything except the repair.
2. Re-run `compile.do` — a package change invalidates everything, so it is a full recompile.
3. `do repair_check.do` → **43 of 43 PASS**. Against `FALSE` it reports exactly **25** failures and
   names the 18 control checks that must pass either way, so the script itself tells you which
   configuration you compiled.
4. `do run_isa.do` → **exactly 9 mismatches.** Not zero. The 9 that remain are `mul_wide`,
   `mul_hi_low`, `mulh`, `mulhu`, `mulhsu`, `div`, `divu`, `rem`, `remu` — every one blocked on a
   question for Hanan rather than on effort, which is why none is implemented.
5. Re-run the four benchmarks with the repair on. **The four cycle counts should not move**, and all
   four DTCM dumps should still match. The repairs touch instructions the benchmarks either already
   use correctly or never use. A count that *does* move is a finding worth stopping for.

### 8.1c Phases 5B and 6A — while `G_ISA_REPAIR` is still `TRUE`

Do these **before** setting the switch back, so there is no second full recompile.

**Both need `G_ISA_REPAIR = TRUE`, and the reason is worth knowing.** At `FALSE` the core reproduces
the LAB5 submission, in which `lui` writes zero (defect 2). Every one of GPIO test0's stores is
reached by `lui t4,0x2 / addi t4,t4,offset / sw t0,0(t4)`, so with `lui` broken `t4 = offset` and the
stores land on byte addresses 0, 4, 5, 8, 9, 12, 13 — inside the DTCM, **never reaching `0x2000`**.
Neither test can measure anything, and both print `VERDICT: NOT APPLICABLE` instead of failing.

That is a finding for the report in its own right: **the two defects masked each other.** The missing
region decode was invisible on the GPIO benchmarks precisely because `lui` never formed an SFR
address. Repairing `lui` is what exposes the aliasing.

**Stage GPIO test0's images.** The `M9K-intel` files, **not** `Hexadecimal-Text` — they are different
programs and the `.h` copy carries a stale `−0x3000` `auipc` bias:

```
copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\ITCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\DTCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
```

A warning that `DTCM.hex` supplies 1024 words for a 2048-word memory is the shipped file's own
length, not a staging mistake.

| Script | Phase | Expect |
| --- | --- | --- |
| `do run_mmio.do` | 5B — MMIO aliasing | `VERDICT: PASS`; **`DTCM WRITES ACCEPTED: 0`**; ~126 MMIO stores; `DTCM stores seen 0` |
| `do run_gpio.do` | 6A — the seven GPO ports | `VERDICT: PASS`; ~**18 writes to each** of the seven ports; ≥ 3 distinct `LEDR` values |

**Then one more, with different images.** `run_gpio_read.do` (Phase 6B) runs GPIO **`test1`**, not
`test0`. Restage:

```
copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test1\bin\M9K-intel\ITCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test1\bin\M9K-intel\DTCM.hex"  C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
```

| Script | Phase | Expect |
| --- | --- | --- |
| `do run_gpio_read.do` | 6B — the SFR read path | `VERDICT: PASS`; **phase 3 writes exactly 0**; ≥ 2 increments and ≥ 2 decrements |

**Put `test0`'s images back afterwards**, or `run_mmio.do` and `run_gpio.do` will not reproduce.

### 8.1d The directed GPIO test — the one that needs nothing from you

`run_gpio_directed.do` (Phase 6D) closes gaps G-406 and G-407. It is the only GPIO test that needs
**neither a benchmark image nor `G_ISA_REPAIR = TRUE`**, so it can be run at any point, in whatever
configuration you happen to have compiled.

Stage the **generated** images, not a benchmark:

```
copy <repo>\SIM\RV32IMscMCU\gpio\ITCM.hex  C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
copy <repo>\SIM\RV32IMscMCU\gpio\DTCM.hex  C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
```

| Script | Closes | Expect |
| --- | --- | --- |
| `do run_gpio_directed.do` | G-406, G-407, and Phase 6C | `VERDICT: PASS`; **35 of 35** stores; **0** mismatches; ~332 cycles |

**Zero is the only passing number here**, unlike `run_isa.do`. The program uses only `addi`, `slli`,
`sw` and `lw`-at-offset-zero plus one `beq` sentinel, so it touches none of the seven ISA defects and
nothing is expected to fail in either configuration. A mismatch here is a GPIO problem, never an ISA
one.

**Every mismatch names its case.** Look the case up in `SIM\RV32IMscMCU\gpio\listing.txt`, which
says in words what that case is for and what its failure means. Quick reading:

- two stores of one pair swapped → the `lane_en_i` term on those two `P_HEXn` instances
- every `:rd` entry reading zero → read-back is off; check `GEN_GPO_READBACK` and `rdbk_w`
- the unmapped read non-zero → the bus terminator's enable
- DTCM word 0 having lost its `0xDEADBEEF` marker → the Phase 5B write gating in `DMEMORY.vhd`
- `port_pb:rd` reading `0x03` instead of `0x06` → the KEY bit order is reversed
- `port_pb:rd` reading `0x01` instead of `0x06` → the polarity is inverted, i.e. `KEY_ACTIVE_LOW` is
  wrong for this board (assumption A16)

The images are committed, so they do not need regenerating. If the map or the cases ever change,
`python3 tools/gen_gpio_test.py` rebuilds them and refuses to write anything if its two independent
derivations of the expected sequence disagree.

**Why this is the strongest test in the set.** It does not assert on the read bus; it drives the
switches and watches what the *program* does, because test1 branches on what it reads. `SW=0x01` must
make the counter go up, `SW=0x02` down, and `SW=0x00` must produce **no writes at all** — with
neither switch set, test1 takes neither branch and never calls `print2all`. An undriven read bus reads
`'Z'`, a doubly-driven one reads `'X'`, and either sends a branch somewhere, which shows up as writes
appearing where there should be none.

**What it does not prove:** the seven GPO read-back paths. Figure 5 draws a `MemRead` tri-state on
each output-port block and Phase 6B implements them, but no supplied benchmark reads `PORT_LEDR` or a
`PORT_HEXn`, so only `PORT_SW`'s is exercised. Gap **G-407**.

**`DTCM WRITES ACCEPTED: 0` is the single line that matters in `run_mmio.do`.** It says the DTCM
refused every MMIO store, which is the whole point of Phase 5B. The earlier draft of that test
watched the address decoder's chip select instead and would have printed PASS with the fix deleted.

**Notes from the wrapper — this guidance was corrected on 2026-08-24; the earlier version was
wrong.** Since Phase 6A the wrapper prints at most two notes, once each: an SFR **read** has no path
yet and returns zero (Phase 6B), and an SFR **write** landed on one of the eight words that still
have no peripheral behind it. GPIO test0 writes only the four GPO words — which **do** take their
writes — and reads nothing on the SFR page, so **on these two tests you should see neither note.** If
the write note appears, a store went somewhere unexpected: read it, do not dismiss it.

*Why it changed, because it is a useful lesson:* the note used to say that every SFR access was
discarded. Phase 6A made that false for exactly the accesses these tests make — it fired on test0's
store to `PORT_LEDR`, a store `PORT_LEDR` now latches, and announced that the write had been
discarded immediately before `tb_gpio` printed that all seven ports held what the program stored. A
diagnostic that contradicts the test running alongside it is worse than no diagnostic.

**Reading a `run_gpio.do` failure:** one HEX of a pair failing while its partner is correct is
cross-talk on a shared chip select — `PORT_HEX0` and `PORT_HEX1` share one, separated only by `A0` —
so look at `lane_en_i` on the two `P_HEXn` instances. All six failing together points at the
low-nibble wiring or `HEX_DECODER.vhd`. A P3 failure alone means the program did not run.

**And know what a `run_gpio.do` PASS does not prove.** test0 writes the *same* value to all seven
ports in ascending address order, so the cross-talk check is one-sided: a port that wrongly captures
an **earlier** store fails, but a port that wrongly captures a **later** store of the same iteration
re-captures the value it already holds and is invisible. Closing that needs a program writing
different values to the two ports of a pair, which no supplied benchmark does — GPIO test1 and test2
also write one value to all seven. Recorded as gap **G-406**.

**GPIO test1 and test2 cannot be run yet.** Both branch on `PORT_SW`, and the read path is Phase 6B.
test0 is the only GPIO benchmark that is purely output.

Before Phase 2's run, note that two bugs were found in the ISA suite's own generator on 2026-08-23
and fixed — a store-count shift and a case that could not fail. The counts in the plan file before
that date (20 / 10) are wrong; the correct ones are **25** and **9**, and both are now derived twice
independently, with generation aborting if the two derivations disagree.

### 8.2 Quartus

Open `Quartus\RV32IMscMCU\RV32IMscMCU.qpf` and compile.

- Top entity must resolve to `RV32IMscMCU`.
- `G_MODELSIM` stays `0` — no edit.
- **The Fitter will report unassigned pins.** That is correct and expected: this is the
  *performance* revision, deliberately carrying no pin assignments so the PPA numbers describe the
  design rather than the board. Pins arrive in the separate `_hw` revision later.

**The number that matters:** the Fitter's area report must show **131,072 embedded memory bits**
(= 2 × 2048 × 32). If it shows 483,328, a SignalTap instance has crept back in — that was exactly
the defect in repo commit `8a71ffb`, and reverting it is why this revision came from commit
`cfc4b4f`.

**Four files were added to the project since the last Quartus run** — `ADDR_DECODER.vhd`,
`SYNC.vhd`, `GPO_PORT.vhd`, `HEX_DECODER.vhd`. If Analysis & Synthesis reports an **unbound
component**, the `.qsf` file list is the first place to look: this project has no `SEARCH_PATH`, so
Quartus finds an entity only if its file is listed. (This exact omission was caught in review before
Phase 5B was committed — `compile.do` had been updated and the `.qsf` had not.)

**Phase 6A added 50 real board pins** — `LEDR_o[7..0]` and six `HEX*_o[6..0]` — and they are still
**unassigned on purpose**. The Fitter placing them anywhere is fine for PPA, but nothing can be tested
on the DE2-115 until they have locations, and **the pin numbers are in no course file**: the only
pin-location material in `Auxiliary/` is a 28-line student note covering `clk_i`, `rst_i` and
`BPADDR_i` only. That is gap **G-504**. The block at the end of `RV32IMscMCU.qsf` says where the
numbers have to come from and asks for them in a commit that touches nothing else.

**Two new risks from Phase 3B, both to watch here.** Byte enables were added to the DTCM
(`byteena_a`, `byte_size`, `width_byteena_a`), and:

- the memory-bit figure may move, because byte-enable mode can change how Quartus configures the M9K
  blocks. It *should* stay 131,072. If it does not, report the number before drawing any conclusion
  from it;
- **Fmax will probably drop.** The extract-and-extend mux sits on the critical path, which already
  had only 1.81 MHz of margin (26.81 MHz measured against a 25 MHz target). If it falls below
  25 MHz the PLL ratio has to change — a Phase 4 decision, not a reason to undo Phase 3B.

Compare the rest against the reference build for a sanity check, not as a target: single-cycle
Fmax 26.81 MHz on `\G0:MCLK|altpll_component|pll|clk[0]`, Slow 1200 mV 85 °C. The wrapper adds
combinational conditioning on reset and a gate on the debug ports, so small movements in logic
elements are expected; a large jump is not.

### 8.3 Record

Into the plan file's own results blocks — Phase 0, Phase 1, Phase 2 and Phase 3A each have one
waiting:

- the four SC cycle counts, at `G_ISA_REPAIR = FALSE` **and** at `TRUE`;
- the four pipeline `CLKCNT`/`STCNT`/`FHCNT` triples (G-205);
- `repair_check.do` passed/failed, and `run_isa.do` mismatches, in both configurations;
- compile error and warning counts;
- the memory-bit figure **and Fmax** from both perf revisions;
- `run_sync.do` and `run_decode.do` verdicts (Phases 4A and 5A) — and `run_decode.do`'s three totals;
- `run_div.do`'s verdict and **both operation counts** (Phase 7A) — **65536** at N=8 and **517** at
  N=32. If the verdict says `INCOMPLETE`, the exhaustive sweep was skipped and the run does not
  count. **Nothing is needed from Quartus for Phase 7A** — `div_accel` is not instantiated yet, so
  synthesis prunes it and it has no area row and no `DIVCLK` to report an Fmax on; an earlier version
  of the plan asked for those two numbers and was wrong to;
- **Phase 7B2 changed two expected numbers ON PURPOSE, and you should not read them as breakage.**
  `run_isa.do` now expects **21** mismatches at `G_ISA_REPAIR = FALSE` and **5** at `TRUE`, where it
  used to say 25 and 9. `div`, `divu`, `rem` and `remu` were four of the mismatches — they were not
  decoded at all and the core wrote zero — and they now go through the Figure 9 accelerator. They
  pass at **either** setting, because the divider is not behind that switch. The **5 that remain are
  all mul-related and all out of scope** by Hanan's own answer, so 5 is the floor. `repair_check.do`
  is unaffected — it does not touch the divider, and its own "25 failures" signature is a different
  test's number that happens to share the digits;
- **Phase 4C is the one that most needs your numbers.** It moved the clock tree from inside the core
  up to `RV32IMscMCU` per Figure 1, removed the core's `mclk_o`, put the peripherals on `smclk`, and
  now holds reset until the PLLs lock. That changed the clocking of **every** test at once. **Re-run
  Run 2 in full: the four counts must still be 134 / 1514 / 2725 / 2735.** They should be — in
  simulation the tree's `mclk_o` *is* `clk_i`, the same tie the core used to make itself, and the
  cycle counter starts when reset releases so holding reset longer shifts the start and the count
  together. If a count **does** move, set `GEN_RESET_ON_LOCK => FALSE` and re-run: that separates the
  reset change from the clock change in one run instead of bisecting the phase;
- `run_divunit.do`'s verdict and operation count (Phase 7B1). This is the one that exercises the
  clock-domain crossings, so a failure here is worth reporting in detail: **which** property failed
  tells us which half broke. `P5 latency_bound` means the handshake HUNG, not that it was slow —
  the likely cause is the clock-ratio constraint in `DIV_UNIT.vhd`'s header. A wrong remainder on
  negative dividends means the remainder sign is following the quotient instead of the dividend.
  `-1/0` giving `+1` means the divide-by-zero override is missing;
- `run_clock.do`'s verdict and its edge counts (Phase 4B) — and, separately, **three Quartus answers
  nobody else can give**: does a `pll_gen` instance compile and fit at all; does Quartus accept the
  inherited `intended_device_family => "Cyclone II"` on a Cyclone IV E part, or must it become
  `"Cyclone IV E"`; and does it accept three instances with different parameters sharing one
  `CBX_MODULE_PREFIX`, or does each need its own `LPM_HINT_STR`. Each has a one-word fix already
  written into `PLL_GEN.vhd`'s generics — the point is to find out which, before Phase 4C wires the
  tree into the top level;
- `run_mmio.do`'s **`DTCM WRITES ACCEPTED`** figure and `run_gpio.do`'s seven write counts
  (Phases 5B and 6A);
- `run_gpio_read.do`'s three phase counts (Phase 6B) — phase 3 must be **0**;
- `run_gpio_directed.do`'s store count and mismatch count (Phases 6C and 6D) — **35 of 35, zero
  mismatches**;
- **one Quartus-only answer nobody else can give:** open the In-System Memory Content Editor and
  confirm the `DTCM` instance still appears and can be read and written. Phase 3B added `byteena_a`
  to the same `altsyncram` that carries `ENABLE_RUNTIME_MOD = YES`, and ISMCE is the mandatory §8
  validation loop. If the instance is gone, **report it and change nothing** — sub-word access and
  ISMCE are both required, so a conflict between them is a question for Hanan.
