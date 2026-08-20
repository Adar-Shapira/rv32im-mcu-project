# Lab 5 — clean structural base (repo commit `c1e9e64`)

Imported from `~/Downloads/Lab5-main/` on 2026-08-20. Reference material only — nothing here is
part of the final project deliverable.

## The folder name overstates what this is

This tree is **commit `c1e9e64`** (18 Aug 2026), the *second* of three commits in
`https://github.com/Adar-Shapira/Lab5` — not the repository's final state. Identified by md5:
`DUT/RV32IM_sc/RV32IM_CORE.vhd` here hashes `f199df79…`, matching commits 1 and 2, while HEAD
hashes `bb404afa…`. It also carries the `.mpf` and `.cr.mti` files that commit 2 added and commit 1
did not have.

Which revision was handed in to the course is not recorded anywhere. What matters is that this is
the closest local copy to the **clean structural base**, commit `cfc4b4f`, and the one to run the
baseline against.

## How it differs from `Auxiliary/Lab 5/`

`Auxiliary/Lab 5/` is repository **HEAD** (`8a71ffb`, 19 Aug). Commit 3 added three things that this
tree does not have, and that the project plan deliberately reverts:

1. **`RSTPOL`** in `RV32IM_CORE.vhd` and `RV32IM_PIPE_CORE.vhd` —
   `rst_w <= rst_i when MODELSIM = 1 else not rst_i`. Here `rst_i` wires straight through,
   active-high, exactly as Hanan's `Auxilary/DUT/RV32I_CORE.vhd` does.
2. **DE2-115 pin assignments** in both `.qsf` files.
3. **`ENABLE_SIGNALTAP ON`** plus a 4782-line `RV32IM_pipeline.stp`, merged into the single existing
   Quartus revision — which is why HEAD's reports show 483,328 embedded memory bits instead of the
   true 131,072.

The **submodule RTL is md5-identical across all three commits** — `CONTROL`, `IDECODE`, `EXECUTE`,
`IFETCH`, `DMEMORY`, `MUL16` and all three packages. No CPU logic was ever changed after commit 1.
So **all five decode defects are present here too**, and in commit 1, and in HEAD.

Consequence for the baseline step: reproduce the measured numbers against **this** tree, not
against `Auxiliary/Lab 5/`. With `RSTPOL` present and `G_MODELSIM = 0`, the testbench's active-high
reset is inverted and the core is held in reset forever.

## One difference in the other direction

The two testbenches here **do** have commit 2's auto-stop process (`std.env.stop` on the `while(1)`
self-jump), which commit 1 lacks. That addition is worth keeping — see the plan's §1.2.

## What was imported

| Path | Contents |
| --- | --- |
| `DUT/RV32IM_sc/`, `DUT/RV32IM_pipeline/` | 24 VHDL files — the submitted cores |
| `TB/RV32IM_sc/tb_RV32IM_sc.vhd`, `TB/RV32IM_pipeline/tb_RV32IM_pipeline.vhd` | The two testbenches |
| `SIM/RV32IM_sc/`, `SIM/RV32IM_pipeline/` | `compile.do`, `run_test.do`, `mem_dump.do`, `batch_verify.do`, `wave.do`, `modelsim.ini`, `.mpf`, and **`DTCM_test1..4.mem` — the measured ModelSim outputs** |
| `Quartus/RV32IM_sc/`, `Quartus/RV32IM_pipeline/` | `.qpf`, `.qsf`, `.sdc` for both designs |
| `Screenshots/ModelSim/{SC,Pipeline}/` | Waveform captures for test1–test4 — templates for the report's mandatory "waveform for test4–test1" |
| `Screenshots/Quartus/{SC,Pipeline}/` | `area.png`, `fmax.png`, `power.png`, `critical_path.png` and the RTL Viewer captures — templates for the three mandatory PPA screenshots |
| `report_figs/` | Architecture diagrams: `arch_system`, `arch_sc_topentity`, `arch_sc_submodules`, `arch_sc_rv32i`, `arch_sc_rv32im`, `arch_pipe_rv32im`, `arch_pipe_topentity`, `task_ppa_tables_reference` |
| `DOC/readme.txt` | The students' per-file description of every DUT/TB/SIM/Quartus file |
| `DOC/Report_lab5.pdf` | The submitted Lab 5 report — the structural template for `Final_report.pdf` |
| `ModelSim_Testing_Guide.md` | The working ModelSim procedure, with the measured results below |

## What was deliberately left out

- `Auxilary/` — a duplicate of `Auxiliary/Lab 5/Auxilary/`, already in the project
- `Lab5.pdf`, `pre5.docx`, `Report_lab5.docx`, `Report_lab5.html`, `~$*.docx` — working documents
  and editor lock files
- `Screenshot 2026-08-19 at 16.15.51.png` — an untitled loose screenshot
- `*.bak` files inside `SIM/` — editor backups, removed on import

About 39 MB of the original 53 MB, almost all of it the duplicate `Auxilary/` tree.

## The baseline to reproduce

From `ModelSim_Testing_Guide.md`. Single-cycle core:

| Test | `mclk_cnt` | Sim time | `pc_o` |
| --- | --- | --- | --- |
| test1 | 134 | 13.4 µs | `0070` |
| test2 | 1514 | 151.4 µs | `0070` |
| test3 | 2725 | 272.5 µs | `00CC` |
| test4 | 2735 | 273.5 µs | `004C` |

All four halt at `instruction_o = 00000063`. Lab 5's own test1 is add / mul / xor — `res1` all
`0x09`, `res2` the products, `res3` the XORs — which is a different program from
`Auxiliary/Benchmark Apps/RV32IM/test1`.

`SIM/*/DTCM_test1..4.mem` hold the memory dumps those runs produced, so a reproduced run can be
diffed against them directly.

## Provenance

Authored by Adar Shapira (209580208) and Yehonatan Dadkha (211468582), except:

- `PLL.vhd` — Quartus ALTPLL MegaWizard output, third-party generated
- the files inherited from Hanan's baseline, which are catalogued in
  `DOC/01_source_inventory.md`
