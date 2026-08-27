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
(`Auxiliary/Lab 5/Auxilary/Benchmarks/` abbreviated as `BM/` — the `Benchmarks/` level came with
Adar's `Auxiliary` restructure and this table lost it until 2026-08-26; all four paths verified
present):

| Destination | Source |
| --- | --- |
| `test1\bin\ITCM.hex` | `BM/test1/RV32IM/man_compiled/bin/M9K-intel/ITCM.hex` |
| `test1\bin\DTCM.hex` | `BM/test1/RV32IM/man_compiled/bin/M9K-intel/DTCM.hex` |
| `test1\RARS\DTCM.h` | `BM/test1/RV32IM/man_compiled/output/RARS/DTCM.h` |
| `test2\…` | `BM/test2/RV32IM/man_compiled/…` (same three files) |
| `test3\…` | `BM/test3/RV32IM/man_compiled/…` |
| `test4\…` | `BM/test4/RV32IM/man_compiled/…` |

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
    $src = "$aux\Benchmarks\test$n\RV32IM\man_compiled"
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
exit status) is moot on the reference side. On our side it is **closed for the single-cycle MCU**
since 2026-08-26: `SIM/RV32IMscMCU/regress.do` runs everything and exits non-zero on any failure
(see §9). Our pipeline copy at `SIM/RV32IMpipelinedMCU/batch_verify.do` still has the weakness and
gets the same treatment when Phase 11 lands.

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

This holds even though the seven ISA repairs are now compiled in unconditionally (the
`G_ISA_REPAIR` switch was removed on 2026-08-26 once the repaired core became the accepted
baseline): the repairs touch instructions these four benchmarks either already use correctly or
never use, which is exactly what the switch's before/after measurement established before it was
retired.

If a dump comes out **empty**, the hierarchical path in `mem_dump.do` is wrong. It must be
`/tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a` — the `MCU` level is the wrapper and
is easy to omit. An empty dump is not reported as an error by `mem save`.

Then repeat for `SIM\RV32IMpipelinedMCU`. Its `run_test.do` already prints `CLKCNT_o`, `STCNT_o` and
`FHCNT_o`; **record all three per test** — they are the input to the IPC check and are written down
nowhere (G-205). That folder was rebuilt on 2026-08-23 for the revised pipeline: new file list in
`compile.do`, `golden.do` added, and the stop condition moved from the retired `flush_o` port to
`MCU/CORE/flush_w`.

### 8.1a Eight tests that need nothing — run them first

No memory image, no `app_bin` staging. Run them straight after `compile.do`; if any fails, nothing
after it is meaningful. (Since the clause 10 rewrite `compile.do` compiles only the official
`tb_RV32IMscMCU`; every `run_*.do` script now compiles its own development testbench first, so
nothing extra is needed.)

| Script | Phase | Expect |
| --- | --- | --- |
| `do run_sync.do` | 4A — CDC synchronizer | `VERDICT: PASS`, zero failures in all three checkers |
| `do run_decode.do` | 5A — address decoder | `VERDICT: PASS`, failures 0, totals **8192 / 29 / 8163** |
| `do run_clock.do` | 4B — clock tree | `VERDICT: PASS`, failures 0, ~**110** accelclk edges, **10** distinct phases |
| `do run_div.do` | 7A — division accelerator | `VERDICT: PASS`, failures 0, **N=8 65536 ops**, **N=32 517 ops** |
| `do run_divunit.do` | 7B1 — division subsystem | `VERDICT: PASS`, failures 0, **57 operations** |
| `do run_timer.do` | 8A — Basic Timer | `VERDICT: PASS`, failures 0, plus the printed **FREQ_5K 4008-cycle** note |
| `do run_intc.do` | 9A — Interrupt Controller | `VERDICT: PASS`, failures 0. Watch P2b+P3 (the masked-latch pair) and P8a/P8b (release-edge) |
| `do run_uart.do` | 12A — USART (bonus) | `VERDICT: PASS`, failures 0, ≥5 characters looped. Watch P7a/P7b: the **measured** start bit must be 176 cycles at 115200 and 2080 at 9600 |
| `do run_uart_mmio.do` | 12B — USART on the bus | `VERDICT: PASS`, failures 0, **22 stores**, and a serial-line transition count well above 20. Stages its own `uartmmio\` images |
| `do run_ppa_row1.do` | 14 — PPA table row 1 | `VERDICT: PASS`, **identical to `run_gpio.do`'s summary**. Same testbench, same image, only `-gGEN_INTERRUPT=FALSE`. Proves the interrupt-free build is a working MCU before its area is reported |
| `do run_uart_menu.do` | 12C — clause 8 menu | `VERDICT: PASS`, failures 0, **423 characters decoded**. Stages `menusim\`, NOT `menu\`. **The slowest test after `run_div.do`** — about 75 ms simulated, because it transmits the real menu text twice at the real bit rate |

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

### 8.1b Phases 3A and 3B — the repaired core, now the only configuration

> **The `G_ISA_REPAIR` switch no longer exists.** It was removed on 2026-08-26 (Adar, commit
> `1d16fe2`), exactly as its own comment planned: "once the repaired core is the accepted baseline,
> TRUE becomes the only configuration exercised." The seven repairs are compiled in unconditionally.
> The before/after measurements below were taken while the switch existed and are the recorded
> baseline; nothing here needs a source edit any more.

1. `do repair_check.do` → **43 of 43 PASS.** (Historical: against the as-submitted expressions it
   reported exactly 25 failures — that "before" capture is the recorded baseline measurement.)
2. `do run_isa.do` → **exactly 5 mismatches.** Not zero. All five are mul-related (`mul` is 16-bit
   by Hanan's own answer — G-308/G-326), so 5 is the floor, not a to-do list. (Historical tallies:
   21 as-submitted / 5 repaired since Phase 7B2; 25/9 before the divider.)
3. Re-run the four benchmarks. **The four cycle counts must not move** (134 / 1514 / 2725 / 2735)
   and all four DTCM dumps must still match — the repairs touch instructions the benchmarks either
   already use correctly or never use. A count that *does* move is a finding worth stopping for.

### 8.1c Phases 5B and 6A — the GPIO benchmarks

**A finding for the report, from when the repairs were switchable:** on the as-submitted core `lui`
writes zero (defect 2), and every one of GPIO test0's stores is reached by
`lui t4,0x2 / addi t4,t4,offset / sw t0,0(t4)` — so with `lui` broken the stores landed on byte
addresses 0, 4, 5, 8, 9, 12, 13, inside the DTCM, **never reaching `0x2000`**. **The two defects
masked each other:** the missing region decode was invisible on the GPIO benchmarks precisely
because `lui` never formed an SFR address. Repairing `lui` is what exposed the aliasing.

**Nothing to stage** (since Phase 13 — §10): each script below copies its own images into `app_bin`,
so the order you run them in no longer matters and nothing has to be put back. The first two use
GPIO test0, `run_gpio_read.do` uses GPIO **test1**, and all three take the `M9K-intel` files — never
`Hexadecimal-Text`, which is a different program carrying a stale `−0x3000` `auipc` bias, and which
`tools/check_staging.py` now asserts no script can reach for.

A warning that `DTCM.hex` supplies 1024 words for a 2048-word memory is the shipped file's own
length, not a staging mistake.

| Script | Phase | Images | Expect |
| --- | --- | --- | --- |
| `do run_mmio.do` | 5B — MMIO aliasing | GPIO test0 | `VERDICT: PASS`; **`DTCM WRITES ACCEPTED: 0`**; ~126 MMIO stores; `DTCM stores seen 0` |
| `do run_gpio.do` | 6A — the seven GPO ports | GPIO test0 | `VERDICT: PASS`; ~**18 writes to each** of the seven ports; ≥ 3 distinct `LEDR` values |
| `do run_gpio_read.do` | 6B — the SFR read path | GPIO **test1** | `VERDICT: PASS`; **phase 3 writes exactly 0**; ≥ 2 increments and ≥ 2 decrements |

Phase 6B is the strongest evidence in this set: it does not assert on the value on the read bus, it
drives the switches and checks that the *program's own branches* follow what it read.

### 8.1d The directed GPIO test — the one that needs nothing from you

`run_gpio_directed.do` (Phase 6D) closes gaps G-406 and G-407. It is the only GPIO test that needs
**no benchmark image** — its images are generated and committed — so it can be run at any point.

It stages its own **generated** images from `SIM\RV32IMscMCU\gpio\` (regenerate with
`python3 tools/gen_gpio_test.py` only if the map or the cases change — the files are committed).

| Script | Closes | Expect |
| --- | --- | --- |
| `do run_gpio_directed.do` | G-406, G-407, and Phase 6C | `VERDICT: PASS`; **35 of 35** stores; **0** mismatches; ~332 cycles |

**Zero is the only passing number here**, unlike `run_isa.do`. The program uses only `addi`, `slli`,
`sw` and `lw`-at-offset-zero plus one `beq` sentinel, so it touches none of the seven
(since-repaired) Lab 5 ISA defects. That isolation is what makes a mismatch here a GPIO problem and
never an ISA one.

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

- the four SC cycle counts (the before/after pair per configuration existed while `G_ISA_REPAIR`
  did; since 2026-08-26 there is one configuration — the repaired core);
- the four pipeline `CLKCNT`/`STCNT`/`FHCNT` triples (G-205);
- `repair_check.do` passed/failed, and `run_isa.do` mismatches;
- compile error and warning counts;
- the memory-bit figure **and Fmax** from both perf revisions;
- `run_sync.do` and `run_decode.do` verdicts (Phases 4A and 5A) — and `run_decode.do`'s three totals;
- `run_div.do`'s verdict and **both operation counts** (Phase 7A) — **65536** at N=8 and **517** at
  N=32. If the verdict says `INCOMPLETE`, the exhaustive sweep was skipped and the run does not
  count. **Nothing is needed from Quartus for Phase 7A** — `div_accel` is not instantiated yet, so
  synthesis prunes it and it has no area row and no `DIVCLK` to report an Fmax on; an earlier version
  of the plan asked for those two numbers and was wrong to;
- **Phase 7B2 changed two expected numbers ON PURPOSE, and you should not read them as breakage.**
  `run_isa.do` expects **5** mismatches on the repaired core (21 on the as-submitted expressions,
  while the switch existed), where it used to say 9 (and 25). `div`, `divu`, `rem` and `remu` were
  four of the mismatches — they were not decoded at all and the core wrote zero — and they now go
  through the Figure 9 accelerator. The **5 that remain are all mul-related and all out of scope**
  by Hanan's own answer, so 5 is the floor. `repair_check.do` is unaffected — it does not touch the
  divider;
- **Phase 4C is the one that most needs your numbers.** It moved the clock tree from inside the core
  up to `RV32IMscMCU` per Figure 1, removed the core's `mclk_o`, put the peripherals on `smclk`, and
  now holds reset until the PLLs lock. That changed the clocking of **every** test at once. **Re-run
  Run 2 in full: the four counts must still be 134 / 1514 / 2725 / 2735.** They should be — in
  simulation the tree's `mclk_o` *is* `clk_i`, the same tie the core used to make itself, and the
  cycle counter starts when reset releases so holding reset longer shifts the start and the count
  together. If a count **does** move, set `GEN_RESET_ON_LOCK => FALSE` and re-run: that separates the
  reset change from the clock change in one run instead of bisecting the phase;
- `run_timer_mmio.do`'s verdict (Phase 8B) — it stages its own `SIM\RV32IMscMCU\timer\` images
  (committed; since Phase 13 a stale gpio set can no longer reach it). Report the captured K it prints —
  the generator's interpreter predicts 10, and a value that is stable-but-different is fine (range
  1..60), while S6 ≠ S7 is a real failure;
- `run_timer.do`'s verdict (Phase 8A) — and note its P8 line PRINTS a finding on purpose: FREQ_5K's
  interval is 4008 cycles (4990 Hz), because F17-literal hardware makes the period BTCL0+1. Do not
  "fix" the RTL to make it 4000; the constant is the suspect (same class as B2);
- `run_intc.do`'s verdict (Phase 9A) — zero setup. If anything fails, its footer maps each phase to
  the specific structural mistake it detects (raw-vs-masked, press-vs-release, W0C, the a-vs-d
  clearing split), so report WHICH phase, not just the count;
- `run_intr_core.do`'s verdict (Phase 9B) — stage `SIM\RV32IMscMCU\intr\` into `app_bin` first
  (NOT the gpio or timer images). Report the three printed numbers: tp1 (expect 44..48), tp3
  (expect 100..124) and the R3 deferral in cycles — the deferral is the F13 measurement, expect
  well above 12; a tiny value means interrupt entry did not wait for the divides;
- `run_intr_mmio.do`'s verdict (Phase 9C) — stage `SIM\RV32IMscMCU\intrmmio\` into `app_bin`. The
  full stack: a real KEY1 release and a real timer EQU0 through controller, entry, bus and reti.
  All 14 expected stores are exact; the run script's footer maps each possible failure to the
  specific wire it implicates. Also confirm the bus one-hot warning never fires during the run —
  the TYPE push is a new bus driver and silence is its collision proof;
- `run_uart_mmio.do`'s verdict (Phase 12B) — stages its own `uartmmio\` images. Twenty-two exact
  stores; the script's footer maps each possible failure to the specific wire. Two checks to watch
  because they exist only after a mutation run showed the first draft blind: `[0x124]` must be
  `0x00` (rule c — writing TXBUF clears TXIFG, i.e. `tx_clr_o` reaches the controller) and
  `[0x12C]` must be `0x3C` while `[0x128]` is `0x71` (RXBUF and TXBUF on the right lanes — under a
  loopback every other scored value is the same byte in both);
- `run_uart_menu.do`'s verdict (Phase 12C) — stages `menusim\`. **Report the character count: 423.**
  This is the clause 8 demo running against a bench that acts as the PC terminal, so its waveform
  and its decoded text are also *report material*: a screenshot of `UART_TXD_o` carrying the menu is
  the closest thing to the demo-day evidence that can be produced without the cable. If it times out
  having decoded nothing, run `run_uart.do` and `run_uart_mmio.do` first — a fault there explains it
  and this test does not;
- **the PIPELINE's two new runs** (Phase 12B/12C, added 2026-08-27): in
  `SIM\RV32IMpipelinedMCU`, `do compile.do` then `do run_uart_mmio.do` and
  `do run_uart_menu.do`. They stage the single-cycle tree's generated images, so
  there is nothing to set up. **What they test is the pipelined CORE, not the
  USART** — every peripheral is byte-identical in both trees and
  `check_peripheral_copies.py` enforces that, so if the single-cycle run of the
  same test passes and the pipelined one does not, the fault is in the core's
  interrupt entry. The menu firmware is the densest exercise of that entry in
  the project: three interrupt sources, any of which can land mid-character;
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

---

## 9. The demo-day protocol — Hanan's inspection guide (added 2026-08-25, **corrected against the PDF 2026-08-27**)

**Source:** `Auxiliary/מבנה הצגה ובדיקת פרויקט מסכם.pdf` — one page, the instructor-facing
protocol for the final-project presentation and inspection.

> **This section was rewritten on 2026-08-27.** It was first written from the `.md` extraction of
> the same document, which is garbled (Hebrew stored character-reversed, column order scrambled).
> The reconstruction was right in outline and **wrong in three details**: the parts are numbered
> **0–3**, not 1–4; the six levels *are* fully specified and are transcribed below (the old text
> said levels 2–5 were unrecoverable); and it missed the requirement that the design is compiled
> **without the SignalTap file**, which is a real technical constraint — see the consequences at
> the end. Total wall clock: **27 minutes**.

**חלק 0 — download and burn, in real time [5 min].** The students download, live, from **their own
personal VPL submission box** on Moodle **the content of the `DUT` folder**, extract every MCU
design file from it, load those into Quartus, and **compile — explicitly, and underlined in the
source — WITHOUT the SignalTap file** (*"ולקמפל ללא קובץ Signal Tap"*), then burn the design to the
FPGA. ModelSim and RARS are opened in parallel. The instructor's note gives the reason: *"the goal
is to verify that the code that was submitted is the one being tested."*

**חלק 1 — one application, per readiness level [7 min].** Also downloaded live: the binaries
(`ITCM.hex`, `DTCM.hex`) of **one** application from the list below, "which constitutes test code
of the project requirements". The students choose it **at this point, according to their system's
readiness level**.

> **Note, verbatim in the source:** the MCU design is burned to the FPGA **once only**; the
> applications must be loaded into the MCU **through the ISMCE interface**. *"It is very important
> to understand the separation between the MCU design and the applications running on the MCU."*

The six inspection levels, transcribed:

| רמה | What is inspected |
| --- | --- |
| **1** | The project requirements **in full** |
| 2 | **Including** the BT Timer module, **without** the DIVIDER hardware accelerator |
| 3 | **Not including** the BT Timer or the DIVIDER accelerator |
| 4 | The **GPIO part and the DIVIDER accelerator** — *without interrupt support* |
| 5 | The **GPIO part only** — without interrupt support and without the DIVIDER accelerator |
| 6 | The **DIVIDER accelerator part only** |

Levels 1–3 carry interrupt support; interrupts are what separates level 3 from level 4. **We
present level 1** — GPIO, Basic Timer, divider accelerator and interrupts are all built.

Per level tested, the instructor does two things: (i) a **detailed manual log** of the execution
description, following the applications' `ReadMe`; and (ii) **a screenshot of the ISMCE window
showing the DTCM memory content**, taken *after the application run finishes*, again per the
`ReadMe`. Our golden-model DTCM comparisons are that same check done in advance.

**חלק 2 — a personal question, each student separately [5 min each = 10 min].** A question on the
**HDL code describing a requested part of the system**, plus understanding built on the development
environments (Quartus, ModelSim, RARS) as the question requires and following the system's
development chain. The instructor picks the question **by the level chosen for presentation**, and
asks the student to **show the relevant part in the design code (VHDL), in the ModelSim wave
window, and so on.**

Consequence: **both of us must be able to open any module and justify it on the spot** — DOC/02's
traceability and each file's header citations are the preparation material for exactly this.

**חלק 3 — submission-folder inspection [5 min].** The instructor examines the Moodle submission
folder against the project requirements, and asks the students to open the ZIP holding the project
documentation and confirm the required sections are present.

### 9.1 What this changes for us — two live consequences

**1. The submission must compile with SignalTap OFF, and that is not how our revision ships.**
`Quartus/RV32IMscMCU/RV32IMscMCU.qsf` currently carries `ENABLE_SIGNALTAP ON` plus
`USE_SIGNALTAP_FILE`/`SIGNALTAP_FILE stp_pwm.stp` and the embedded `auto_signaltap_0` SLD block —
the right shape for the board bring-up it was built for (§1.7.e of the plan), and the wrong shape
for חלק 0. Three things follow, none of them urgent but all of them cheap:

- **The demo build is `ENABLE_SIGNALTAP OFF`.** With it off Quartus ignores the whole SLD section,
  so no edit beyond that one line is needed. Whether the *shipped* `.qsf` should default to OFF is
  a Phase 16 packaging decision and Adar's call — his board flow wants it ON.
- **One clean-room hazard is visible in BOTH projects**: the last SignalTap line is
  `set_global_assignment -name SLD_FILE db/stp_pwm_auto_stripped.stp` — `RV32IMscMCU.qsf` and
  `RV32IMpipelinedMCU.qsf` alike — and `db/` is a *generated* directory that does not exist in a
  fresh clone or in the ZIP. Harmless with SignalTap off (ignored) and normally regenerated with it
  on, but it is a `.qsf` line pointing into build output, which is exactly what a clean-room build
  punishes. Both projects also ship `ENABLE_SIGNALTAP ON`.
- **Both designs are safe under SignalTap-off by construction** — `LEDR`, the six `HEX` displays,
  `PWM` and `GPIO` are real pins driven through the peripherals, so nothing load-bearing can be
  optimised away.

  > **Corrected 2026-08-27, same day it was written.** This bullet first said the *pipeline* was
  > exposed, because at the time all fourteen of its wrapper outputs were observation ports — the
  > `GEN_DEBUG_PORTS => FALSE` exposure recorded in `5d540c0`. Adar's `beee0a7` closed it by
  > porting the whole peripheral set to the pipeline: `RV32IMpipelinedMCU.vhd` now brings out
  > `LEDR_o`, `HEX0..5_o`, `PWM_o` and `GPIO`, so real pins hold the design up there too. (The same
  > commit also removed the welded `rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i` from
  > `RV32IM_PIPE_CORE.vhd` — it is a plain `rst_w <= rst_i` now, with polarity handled once by the
  > wrapper's `RSTCOND`, which is the shape the single-cycle side already had.)

**2. Clause 10 wants a `.stp` in the ZIP; חלק 0 compiles without it.** Both are true and they do
not conflict: the `.stp` ships as the clause 7 SignalTap-validation deliverable and as evidence,
while the build performed in the room is a plain functional one. Worth knowing so nobody "fixes"
one against the other.

And it re-confirms two things already in place: Phase 16's clean-room gate is literally the first
five minutes of the grade, and `ENABLE_RUNTIME_MOD = YES` on the `ITCM`/`DTCM` instances (inherited
from Lab 5, carried through every phase) is load-bearing demo machinery — the ISMCE check in
section 7's record list is its guard.

---

## 10. The regression — one command, and it fails loudly (added 2026-08-26, Phase 13)

Everything in sections 8 and 8.1a–8.1d can be run in one shot, scored automatically, with a real
exit status. That last part is the point: gap **G-203** was that the old batch script only echoed,
so a failing regression looked exactly like a passing one to anything but a careful reader.

```
cd SIM\RV32IMscMCU
vsim -c -do regress.do
echo %ERRORLEVEL%        REM 0 = everything passed, 1 = something did not
```

It compiles once, then runs **all 18 self-checking tests** followed by **the four RV32IM
benchmarks**, and prints one summary table. Per-test transcripts go to `SIM\RV32IMscMCU\logs\`.
**The table is the summary; the log named in a failing row is the evidence** — read that, not the
table, when something fails.

**Nothing has to be staged by hand any more.** Every `run_*.do` now copies its own images into
`app_bin`, so a stale image set from the previous test cannot reach the next one. That was the
likeliest way to get a wrong-but-plausible result, and it is gone by construction. The seven
scripts that changed on 2026-08-26: `run_mmio`, `run_gpio`, `run_gpio_read`, `run_gpio_directed`,
`run_timer_mmio`, `run_intr_core`, `run_intr_mmio`.

**Scoring rule, uniform across every test.** A log containing `VERDICT: FAIL` or
`VERDICT: INCOMPLETE` failed; `VERDICT: PASS` passed; **no `VERDICT` line at all also fails**,
because a test that never reached its own summary has not passed — that is the failure a
grep-for-PASS regression silently swallows. Two tests carry one extra machine-checked fact each:
`run_bench_test4.do`'s capture-event count (must be 3), and the benchmarks below.

**Part B — the four benchmarks are actually compared, not just run.** `mclk_cnt_o` against
134 / 1514 / 2725 / 2735, **and** each DTCM dump diffed word by word against the reference's own
2048-word capture (`Auxiliary\Lab 5\SIM\RV32IM_sc\DTCM_testN_MS.mem`), reporting the first
differing word and both values. Part B needs the one-time `C:\TestPrograms\Quartus21_1\test1..4`
layout from section 3; without it the script **skips Part B, names the reason, and repeats the
warning in the summary** rather than reporting a partial pass as complete.

**The static half — run it on either machine, it needs no simulator:**

```
python3 tools/check_staging.py
```

It reads every `.do`, asserts each `app_bin` staging copy is an existing `.hex` M9K-intel or
generated image, and rejects any `Hexadecimal-Text` source — the two formats are different
programs (§3), and loading the wrong one produces a plausible wrong answer instead of an error. It
also catches path rot, which is not hypothetical: section 3's own staging table pointed at
`Auxilary\testN\…` for weeks after the `Auxiliary` restructure moved it to
`Auxilary\Benchmarks\testN\…`.

**Since 2026-08-27 it also asserts the `-gMODELSIM=1` switch**, because five scripts were missing
it. `G_MODELSIM` ships at `0` — the Quartus value, which `check_config_defaults.py` asserts and
which must *not* be edited to run a simulation — so a testbench that instantiates a whole MCU has
to be given the switch on its `vsim` line, or `CLOCK_TREE` takes its `CLK_FPGA` branch and
elaborates **two real ALTPLL megafunctions** fed by the bench's 100 ns clock. `mclk` then stops
being `clk_i`, every cycle-counted bound in the bench is measured against the wrong clock, and with
`GEN_RESET_ON_LOCK` the core does not leave reset until that PLL reports lock.

The five: `run_uart_mmio.do` and `run_uart_menu.do` in **both** trees (Phases 12B/12C/12D) and
`run_intr_mmio.do` in the single-cycle tree (Phase 9C). None had been run yet. The other 25
whole-MCU `vsim` lines all had the switch, which is exactly why nobody noticed — the habit was
right 25 times out of 30. Clean today: 70 staging copies and 30 whole-MCU `vsim` lines across 51
scripts.

**The pipeline now has the same one command — new 2026-08-27, Phase 11B:**

```
cd SIM\RV32IMpipelinedMCU
vsim -c -do regress.do
echo %ERRORLEVEL%
```

Until this existed the pipeline had `batch_verify.do` and nothing else, so its **ten** self-checking
testbenches were nine separate commands nobody scored together — a green run of one said nothing
about the other eight. `regress.do` compiles once, then runs and scores:

- **PART A** — the **thirteen** self-checking tests, by the same `VERDICT:` rule the single-cycle
  table uses: `run_isa.do` (§10.1), the three integration benches (§10.2), the GPIO trio, both USART
  tests, and the four interrupt benchmarks on their **corrected** images. Three of them carry one
  extra machine-checked fact each and it is folded into the row: test2 and test3 must see `BTCNT`
  tick, test4 must see **3** capture events.
- **PART B** — `batch_verify.do`, unchanged in what it does: the four **shipped** benchmarks, each
  final DTCM diffed word-by-word against the reference's own capture
  (`Auxiliary\Lab 5\SIM\RV32IM_pipeline\DTCM_testN_MS.mem`), failing a test whose program never
  reached its final `while(1)`. Different images and a different question from PART A, which is why
  both exist.

`batch_verify.do` still works standalone and still exits non-zero on its own; under `regress.do` it
hands its failure count up instead, and the driver owns the exit status. Its
`CLKCNT`/`STCNT`/`FHCNT` figures stay **reported, not asserted** — `PROJECT_EXPLANATION.md` §8.6's
numbers include the testbench drain, so they are a range, not a target — and they are exactly the
**G-205** evidence to copy into the plan file. `logs\batch_verify.log` is where they land.

Also note its `mem_dump.do` was widened from 1024 to 2048 words on 2026-08-26 (the last open half of
**G-204**); a 1024-word dump cannot be compared to the reference capture at all.

### 10.1 `run_isa.do` on the pipeline — what it is for

The four benchmarks compare a final DTCM image. That catches a gross error and says nothing about
`bgeu` on operands no benchmark forms, or `sra`'s sign fill, or a load's offset. **43 of the 56
stores** the directed suite scores are cases no benchmark executes, and the pipeline's CONTROL,
IDECODE, EXECUTE, IFETCH and DMEMORY are a *rewrite* — 212 changed lines in EXECUTE alone — so each
of the seven ISA repairs had to be present there independently. Until Phase 11B that was a claim
from reading the source.

```
cd SIM\RV32IMpipelinedMCU
do compile.do
do run_isa.do
```

**Expect `VERDICT: PASS` with exactly 5 mismatches.** That is the floor, not a to-do list: all five
are mul-related (**G-326** 2 cases, **G-308** 3 cases) and out of scope on *both* cores by Hanan's
forum answer, *"mul only (as in Lab 5), 16-bit multiplier only"*. `div`/`divu`/`rem`/`remu` are **not**
in that list any more — Phase 7B2 put them through the accelerator and they must PASS.

Any other number is a finding. Run the single-cycle suite (`do run_isa.do` in `SIM\RV32IMscMCU`)
and compare: a case that mismatches on the pipeline and passes on the single-cycle core is a defect
this core does not share, and the pipelined EXECUTE / IDECODE are where to look. The two runs score
**byte-identical** expectation packages — `tools/gen_isa_test.py` writes both and
`tools/check_peripheral_copies.py` asserts they never drift.

**Worth doing once, deliberately:** break something small, re-run either script, and confirm the
exit status is **1** and the table names the broken row. A regression nobody has seen fail is a
regression nobody should trust.

---

### 10.2 The three integration benches — new 2026-08-27, gap G-408

```
cd SIM\RV32IMpipelinedMCU
do run_intr_core.do      REM the entry protocol, cycle by cycle
do run_timer_mmio.do     REM the timer on the bus, + PWM at the pin
do run_intr_mmio.do      REM the whole path, real pin to reti
```

Every peripheral is byte-identical in both DUT trees, so a **leaf** test proven on the single-cycle
side is proven for the pipeline too — that is what `tools/check_peripheral_copies.py` protects.
These three are not leaf tests: their subject is the **core's interaction with a peripheral**, and
the cores are different designs, so their single-cycle results do not carry over. They score
byte-identical checks against the identical generated programs, staged from `SIM\RV32IMscMCU\`.

**Expect `VERDICT: PASS` from each.** On any failure, run the single-cycle bench of the same name
first. If that passes and the pipeline one does not, the fault is in the **core**, not in the
peripheral, the program or the expectations.

**One thing that looks wrong and is not:** `run_intr_core.do` is the only script in that directory
without `-gMODELSIM=1`. It instantiates the bare `RV32IM_PIPE_CORE`, not the MCU top, so there is no
`CLOCK_TREE` to send down its FPGA branch — it drives `clk` and `divclk` itself. `check_staging.py`
derives which testbenches instantiate an MCU top from the TB sources, so it does not flag this and
would still flag a real omission.

**What `run_intr_core.do` prints, and what to do with it.** `tp1`, `tp3` and the round-3 deferral
are reported in its summary. `tp1` must sit in 44..48, `tp3` in 100..124, and the deferral at or
above 12. That deferral floor is not a copied constant: `DIV_ACCEL` is 32 DIVCLK iterations,
`DIV_UNIT`/`DIV_ACCEL` are byte-identical in both trees, and the bench drives `divclk` at 21 ns —
so round 3's two back-to-back divides are 1344 ns, or 13.44 core cycles. A *small* deferral means
the accept gate stopped honouring `div_start`/`div_busy`, which is exactly what clause F13 forbids.

## 11. Phase 14 — the compile matrix (added 2026-08-27)

### 11.1 The requirement, read carefully, because it was misread until now

Clause 6 gives **three** tables — Area, Performance, Power — and each carries its own
*"Attaching the print screen of the Quartus … report is mandatory"*. Every one of them has the same
**three rows**:

| row | label in the document | what that is |
| --- | --- | --- |
| 1 | MCU with GPIO | the single-cycle MCU with **no interrupt capability at all** |
| 2 | MCU with GPIO and Interrupt Capability | the single-cycle MCU, complete |
| 3 | Pipelined MCU with GPIO and Interrupt Capability | the pipelined MCU, complete |

**The plan said "three perf revisions (A, B, C)" without ever saying what A, B and C were, and
nothing in this project recorded that row 1 is an interrupt-free build.** It could not have been
produced: there was no configuration for it. The point of the table is the delta between rows 1 and
2 — what interrupt capability costs in logic elements, registers, Fmax and power — so a missing row
1 is not a cosmetic hole.

**Which peripherals row 1 drops is not a judgement call.** §5 is titled "GPIO peripherals … *without*
interrupt capability" and lists eight: `PORT_LEDR`, `PORT_HEX0..5`, `PORT_SW`. §6 is titled
"Peripherals *with* interrupt capability" and lists twelve addresses: `PORT_PB`, the USART's three,
the Basic Timer's five, and `IE`/`IFG`/`TYPE`. So **`PORT_PB` belongs to the interrupt half** — easy
to get wrong, because it looks like a GPIO input port; §6 is where the specification puts it, because
the KEYs are an interrupt source.

Row 1 is now `GEN_INTERRUPT => FALSE` on `RV32IMscMCU`, which removes exactly those twelve
addresses' hardware. What it does **not** remove, so the number you report is honest: the CPU core is
untouched, with `intr_i` tied to `'0'`, so constant propagation collapses the entry FSM — but `reti`
stays decoded and its GIE side door survives, which is one AND gate and one register-bit write path.
Recorded rather than hidden. The divider accelerator also stays in both rows: §6.iii makes it part of
the CPU and it has no MMIO address.

### 11.2 Before you compile anything

```
python3 tools\check_config_defaults.py
```

It asserts `G_MODELSIM = 0` and `G_GEN_INTERRUPT = True`. Row 1 is the one build that needs a switch
flipped, and this is what stops a flipped tree from being committed afterwards. **Run it again after
you finish row 1.**

Also run, once, before believing any area number:

```
cd SIM\RV32IMscMCU
do compile.do
do run_ppa_row1.do
```

Same testbench, same benchmark image, same expectations as `run_gpio.do` — only
`-gGEN_INTERRUPT=FALSE`. Synthesis will happily report the area of a build that does not work; this
is what says it works. If `run_gpio.do` passes and this does not, the fault is in the row-1 gating,
not in the GPIO ports.

### 11.3 The builds

**Three compiles fill all three tables.** Each one produces its own Area, Fmax and Power report, so
there is no reason to compile more than once per row.

| # | For | Project | Configuration | SignalTap | Pins |
| --- | --- | --- | --- | --- | --- |
| 1 | tables, row 1 | `Quartus\RV32IMscMCU` | `G_GEN_INTERRUPT = False` | **OFF** | as shipped |
| 2 | tables, row 2 | `Quartus\RV32IMscMCU` | as shipped | **OFF** | as shipped |
| 3 | tables, row 3 | `Quartus\RV32IMpipelinedMCU` | as shipped | **OFF** | as shipped |
| 4 | the captures | `Quartus\RV32IMscMCU` | as shipped | **ON** (flip one line) | as shipped |
| 5 | the captures | `Quartus\RV32IMpipelinedMCU` | as shipped | **ON** (flip one line) | as shipped |

Builds 2 and 3 are **also the demo-day build** — pinned with SignalTap off is what the inspection
room compiles and burns (§9.1), and as of 2026-08-27 both `.qsf` files ship in exactly that state.
That was a deliberate change: the room's compile now works out of the box, and the captures are one
assignment away instead of the other way round.

**Note on the ideal-vs-shipped tension.** D-2's rule was that the PPA numbers must come from a
revision with *no pins* as well as no SignalTap, following Lab 4's `Lab4_Perf`/`Lab4_HW` pair. The
matrix above keeps the pins, for one reason: clause 10 wants **one** project per design in the ZIP
and the room compiles that project, so a second pinless revision is a file that exists only to be
measured. Pins cost I/O cells, not logic, and the Area table has its own **I/O pins** column — so
report the pinned numbers, note in the report that the three rows are measured pinned and
SignalTap-off, and the comparison between rows stays valid because all three are measured the same
way. If Hanan wants pinless numbers, add a revision then; nothing in the RTL changes.

### 11.4 What to record, per build

- **Area:** logic elements, registers, I/O pins, **embedded memory bits**, embedded 9-bit
  multipliers, PLLs. Memory bits must read **131,072** (= 2 × 2048 × 32) on builds 1–3. **483,328
  is the SignalTap-contamination signature** from Lab 5 commit `8a71ffb` — if you see it, SignalTap
  is on and the numbers belong in the bin.
- **Performance:** Fmax, `f_MCLK`, and the **critical path** — the table's own column asks "what is
  the slowest submodule and why does it cause the critical path", so a number alone does not answer
  it. Read the Timing Analyzer's worst-case path and name the module.
- **Power:** total, static, dynamic, I/O. Note whether `POWER_DEFAULT_TOGGLE_RATE 12.5%` is in the
  `.qsf` when you measure — it is, and it changes the answer, which is why the setting is part of the
  measurement (**G-208**).
- Sanity references, **not targets**: Lab 5's clean build gave single-cycle Fmax **26.81 MHz** and
  pipeline **41.84 MHz**, 4 multipliers, 1 PLL. Expect the wrapper to move Fmax a little. **Expect
  2 PLLs now**, not 1 — the clock tree instantiates `pll_gen` twice (F6), and `AUTO_MERGE_PLLS OFF`
  in the `.qsf` is what stops the Fitter merging them back into one.
- Three answers only Quartus can give, listed in `SIM\RV32IMscMCU\run_clock.do`'s header: whether a
  `pll_gen` instance fits, whether the inherited `intended_device_family => "Cyclone II"` is
  accepted on a Cyclone IV E part, and whether two instances may share one `CBX_MODULE_PREFIX`.
