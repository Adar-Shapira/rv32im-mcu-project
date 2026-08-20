# Deliverable D — Baseline Runbook (Step 2)

Reproduce a known-good run of the **unchanged** Lab 5 cores before any RTL is touched, so that a
later failure can be attributed to our change rather than to the reference, the tool install, or the
environment.

**This runbook executes on the Windows machine.** Everything it needs is already in the repository;
nothing has to be recreated from scratch. Sections 1–3 are preparation, section 4 is the run,
section 5 is the pass/fail criterion.

Based on `Auxiliary/Lab 5 - as submitted/ModelSim_Testing_Guide.md`, which is the students' own
documented working procedure, and on the supplied `.do` scripts in the same tree.

---

## 0. What is being proven

| | |
| --- | --- |
| Design under test | `Auxiliary/Lab 5 - as submitted/DUT/RV32IM_sc/` — **unmodified** |
| Testbench | `Auxiliary/Lab 5 - as submitted/TB/RV32IM_sc/tb_RV32IM_sc.vhd` — unmodified |
| Scripts | `Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/{compile,run_test,mem_dump,wave}.do` — unmodified |
| Benchmarks | Lab 5's own test1–test4 (add / mul / xor programs), **not** the Final Project benchmarks |
| Pass criterion | four exact cycle counts, and `DTCM.mem` identical to the RARS golden in all 1024 words |

Do not substitute the Final Project benchmarks here. They exercise instructions the core gets wrong
(see `DOC/01_source_inventory.md` §2.2), so they would fail for reasons that have nothing to do with
the environment.

---

## 1. Tool environment

| Item | Value | Source |
| --- | --- | --- |
| Quartus | Prime 21.1.0 Lite | `Auxiliary/Lab 5/Quartus/*/*.qsf` |
| ModelSim | Intel FPGA Starter Edition **20.1**, `C:\intelFPGA\20.1\modelsim_ase` | `ModelSim_Testing_Guide.md` §A.1 |
| VHDL standard | **2008 — mandatory** | `EXECUTE.vhd` uses `process(all)`; the core top uses `if/else generate` |
| Device | `EP4CE115F29C7` (Cyclone IV E, DE2-115) | `.qsf` |

`mem_dump.do` addresses simulator internals
(`/tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a`), which version-locks it to ModelSim ASE
2020.1. A different ModelSim version will fail at the dump step, not at compile.

---

## 2. Set `G_MODELSIM = 1`

`Auxiliary/Lab 5 - as submitted/DUT/RV32IM_sc/cond_compilation_package.vhd:51` ships as:

```vhdl
constant G_MODELSIM : integer := 0;   -- options{1=MODELSIM,0=FPGA}
```

**Set it to `1` before simulating**, and back to `0` before any Quartus compile. Do the same in
`DUT/RV32IM_pipeline/cond_compilation_package.vhd`. This is the documented convention — see
`Auxiliary/Lab 5 - as submitted/DOC/readme.txt`.

At `0` the PLL is instantiated instead of bypassed, and — in the **project** copy of Lab 5, though
not in this submitted copy — the `RSTPOL` generate also inverts the reset, so the testbench's
active-high pulse holds the core in reset forever and nothing runs. Another reason to run the
baseline against `Auxiliary/Lab 5 - as submitted/` rather than `Auxiliary/Lab 5/`.

No `.do` file overrides this with `-g`. **Gap G-201** in the plan file tracks converting it to a
generic override so the manual edit disappears.

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
2. **File → Change Directory…** → `Auxiliary\Lab 5 - as submitted\SIM\RV32IM_sc`.
   The supplied `compile.do` uses `../../DUT/RV32IM_sc/…`, which resolves correctly from here —
   the imported tree is self-contained.
3. **Tools → Tcl → Execute Macro…** → `compile.do`.
   Expected: **0 errors**. Three warnings on `EXECUTE.vhd` ("Non-locally static OTHERS choice") are
   known and harmless.
4. Edit the first line of `run_test.do` to `set N 1`, save.
5. **Tools → Tcl → Execute Macro…** → `run_test.do`.
   It stages the images, loads the testbench, applies `wave.do`, runs until the program reaches its
   `while(1)` self-jump, and writes `DTCM.mem`.
6. Repeat step 4–5 for `N` = 2, 3, 4. Recompiling is **not** needed between tests — memories are
   read when the simulation loads.

Mechanics worth knowing:

- The testbench clock is **100 ns period = 10 MHz** (`tb_RV32IM_sc.vhd:102-109`). So simulated time
  and cycle count are related by exactly 0.1 µs per cycle, which is why test1's 134 cycles land at
  13.4 µs. This is a simulation-only clock; the PLL is bypassed at `G_MODELSIM = 1`.
- Reset is `rst_i <= '1', '0' after 80 ns` — active-high, released at 80 ns.
- The run stops on `instruction_o` reaching `0x00000063` (`beq x0,x0,0`) or `0x0000006F`
  (`jal x0,0`). Both `run_test.do`'s Tcl `when` block and the testbench's
  `monitor_end_of_program` process implement this, so it also stops under a plain GUI Run-All.
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

Compare `SIM\RV32IM_sc\DTCM.mem` against `C:\TestPrograms\Quartus21_1\testN\RARS\DTCM.h`. Expect
**all 1024 words identical**.

A pre-captured copy of each expected dump is committed at
`Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/DTCM_test1..4.mem`, so a reproduced run can be diffed
against those directly without touching the golden.

**`mem_dump.do` exports words 0–1023 only, while the DTCM is 2048 words.** The golden `DTCM.h` files
are also 1024 lines, so the comparison is self-consistent — but the upper half of the DTCM is never
checked by anything. Tracked as **Gap G-204**.

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

Repeat sections 2–5 against `Auxiliary/Lab 5 - as submitted/SIM/RV32IM_pipeline/`, whose
`compile.do` adds `HAZARD_UNIT.vhd` and `FORWARD_UNIT.vhd` and whose testbench is
`tb_RV32IM_pipeline`. That tree also contains `batch_verify.do`, which runs all four tests in
sequence — but it only *echoes* results and never returns a failing exit status, so its output must
be read by a human. Tracked as **Gap G-203**.

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
`0070` / `0070` / `00CC` / `004C` with `instruction_o = 00000063`, and `DTCM.mem` matching each
`RARS/DTCM.h` in all 1024 words.

If a dump comes out **empty**, the hierarchical path in `mem_dump.do` is wrong. It must be
`/tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a` — the `MCU` level is the wrapper and
is easy to omit. An empty dump is not reported as an error by `mem save`.

Then repeat for `SIM\RV32IMpipelinedMCU`. Its `run_test.do` already prints `CLKCNT_o`, `STCNT_o` and
`FHCNT_o`; **record all three per test** — they are the input to the IPC check and are written down
nowhere (G-205).

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

Compare the rest against the reference build for a sanity check, not as a target: single-cycle
Fmax 26.81 MHz on `\G0:MCLK|altpll_component|pll|clk[0]`, Slow 1200 mV 85 °C. The wrapper adds
combinational conditioning on reset and a gate on the debug ports, so small movements in logic
elements are expected; a large jump is not.

### 8.3 Record

Into the plan file's Phase 1 row: the four SC cycle counts, the four pipeline
`CLKCNT`/`STCNT`/`FHCNT` triples, the compile error and warning counts, and the memory-bit figure
from both perf revisions.
