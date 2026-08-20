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

## Phase 0 — Baseline  ·  blocked on Windows

Prove the environment before changing anything.

- Run `DOC/04_baseline_runbook.md` against `Auxiliary/Lab 5 - as submitted/`.
- **Exit:** `mclk_cnt_o` = 134 / 1514 / 2725 / 2735 for test1–4, and `DTCM.mem` identical to each
  `RARS/DTCM.h` in all 1024 words.
- If the numbers do not reproduce, stop. Do not start Phase 1.

Gaps: **G-202**, G-201, G-206.

## Phase 1 — Clean structural base

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

## Phase 2 — Directed ISA verification

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

- Fix the five defects. Cite each: one from Hanan's baseline `CONTROL.VHD:141`, four designed by us
  with the reasoning recorded.
- `sra`: candidate repair from `Auxilary/Lab4/DUT/Shifter.vhd`, a generic structural barrel shifter.
- Replace `USE IEEE.STD_LOGIC_SIGNED` with explicit `signed`/`unsigned` casts so both compare forms
  are correct.
- Add `div`, `divu`, `rem`, `remu` decode. Masks already exist at `const_package.vhd:243-273`.
- Decide `mulh`/`mulhsu`/`mulhu` scope — LAB5 calls it "MULDIV partial". Q on the list.
- Add byte enables and sub-word load/store: `byteena_a` on the `altsyncram`, a funct3-driven
  extract-and-extend mux, write-strobe generation. **Mandatory** — the benchmarks `sw` to byte
  addresses.
- **Exit:** the Phase 2 suite passes fully, and `Benchmark Apps/RV32IM/test1` (both `man_compiled`
  and `gcc_compiled`) matches its RARS golden. Note **G-404**: the `output/RARS/DTCM.hex` golden
  there is stale; use `DTCM.h`.

Gaps: G-321…G-327, G-307, G-308, G-309.

## Phase 4 — Clock tree, reset, CDC

- Regenerate the ALTPLL with `c0`/`c1`/`c2` → `mclk`, `smclk`, `accelclk`. All three existing copies
  expose only `c0`. Worked non-trivial-ratio example: `Auxilary/Lab4/DUT/pll.vhd`, 50 → 2 MHz.
- Synchronise PLL lock into reset release, in the top wrapper.
- Build the two-flop synchroniser of Figures 10a/10b as a reusable entity. **Do not** mistake
  `IFETCH.vhd:73-82` for one — it is a single flop with an async preset.
- Constrain all three clocks and every crossing in the SDC. Start from
  `Auxilary/QUARTUS/SDC/RISCV_simple.sdc`.
- **Exit:** measured 20 MHz `smclk`, deterministic reset, no unconstrained cross-domain path.

Gaps: G-310, G-311. Blocked on **Q2**.

## Phase 5 — Bus interface and DTCM

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

## Phase 6 — GPIO

- `hex_decoder.vhd` from `Auxilary/Lab4/DUT/` — **use as is**, active-low DE2-115, complete 0–F table.
- Latched LEDR7-0 and six HEX nibble registers per Figure 5; SW7-0 and KEY3-1 reads.
- KEY0 is reset only, in the top wrapper. KEY1-3 feed `PORT_PB` and the interrupt edge latches.
- **Exit:** GPIO test0, test1, test2 pass. **G-405**: these never write the DTCM, so verification is
  by MMIO assertion and waveform, not golden memory.

Gaps: G-306. Blocked on **Q5**.

## Phase 7 — Division accelerator

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

## Phase 8 — Basic Timer

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

## Phase 9 — Interrupt controller and CPU protocol

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

## Phase 10 — Single-cycle benchmark progression

- Interrupt test1 with scripted KEY1/2/3 pulses; test2 one-second BT interrupts; test3 the four
  periods; test4 in compare, PWM and capture modes.
- Use `Auxiliary/Benchmark Apps/Intrrupt-based IO/` — the current revision. `_superseded/` holds the
  older one with two extra defects, kept for auditability.
- **test4's capture never fires**: `capture_init` and `capture` both write `0x07`, so `CAPISEL` stays
  at GND. Verify capture with a separately-marked corrected copy writing `0x06`. Q10.
- **Exit:** all mandatory checks pass with saved logs, memory diffs and report-ready waveforms.
  **G-204**: `mem_dump.do` exports 1024 of 2048 DTCM words — extend it or document the limit.

## Phase 11 — Pipeline port  ·  bonus 10%

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

## Phase 12 — UART  ·  bonus 20%

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

## Phase 13 — Regression and evidence

- Scripts per core × configuration × benchmark: select images, run bounded stimuli, dump memory,
  compare, **return a non-zero exit status on mismatch**. `batch_verify.do` currently only echoes —
  **G-203**.
- Keep `bin/M9K-intel/*.hex` for ITCM and ISMCE, `bin/Hexadecimal-Text/*.h` as the DTCM golden text.
  Assert that `ITCM.h` is never loaded as an ITCM source — the two formats are **different
  programs**, `.hex` at text base 0 and `.h` retaining RARS's `0x3000`.
- Capture report-ready waveforms for interrupt tests 1–4.
- **Exit:** one regression summary covering every required test, with no manual source edits anywhere
  in the flow.

## Phase 14 — Quartus PPA

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

## Phase 15 — Hardware validation

- Program each `.sof`; KEY0 reset; exercise GPIO, interrupt and UART scenarios on the DE2-115.
- SignalTap: at least one KEY ISR, one BT ISR, a divider stall and completion, a pipeline
  hazard/flush, and a UART transaction. Trigger per clause 6.iii.a:
  `SignalTap trigger = (IF_pc == BPADDR_i)`, `BPADDR_i` fed by SW7-SW0 at word granularity.
- Capacity check: `STdepth = (Embedded memory size − Design usage) / #ST channels`.
- ISMCE: load each benchmark's images, run, export DTCM, compare against the RARS `.hex`.
- **Exit:** signed hardware checklist with memory diffs, captures, terminal transcript and photos.

Blocked on **Q1**.

## Phase 16 — Report and submission

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
| **G-309** | Byte enables and sub-word load/store. `altsyncram` has no `byteena_a`; `CONTROL` detects `lb`/`lh`/`sb`/`sh` then discards the width. **Mandatory.** | §2 |
| **G-310** | Two-flop CDC synchroniser | Figures 10a/10b |
| **G-311** | Multi-output clock tree; all three ALTPLL copies expose only `c0` | Figure 1 |
| **G-312** | Edge detector / one-shot for KEY1-3 | §6.i |
| **G-313** | UART register layer | §6.iv, p12 |

## Design — defects in supplied code

| ID | Defect | Origin |
| --- | --- | --- |
| **G-321** | `andi` writes 0; `ori` computes AND | student regression; baseline `CONTROL.VHD:141` is correct |
| **G-322** | `lui` writes 0 | **lecturer's baseline**, `const_package.vhd:27` |
| **G-323** | Loads address `rs1 + 0` | **lecturer's baseline**, `IDECODE.VHD:94-101` |
| **G-324** | `sra` ≡ `srl` | **lecturer's baseline**, `EXECUTE.VHD:179` |
| **G-325** | Unsigned compares are signed | **lecturer's baseline**, `EXECUTE.VHD:9` |
| **G-326** | `mul` is 16×16 unsigned, lower half-words only | `EXECUTE.vhd:93-94` |
| **G-327** | test4's capture input never changes; `CAPISEL` stays at GND | supplied benchmark, current revision |

## Verification

| ID | Gap |
| --- | --- |
| **G-401** | No self-checking testbench anywhere. The whole reference tree contains two assertions, both in `Auxilary/Lab3/TB/tb_top.vhd`, both used as a stop mechanism. |
| **G-402** | Directed ISA testbench does not exist. Highest-value item after G-202. |
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
| `DOC/04_baseline_runbook.md` | The Windows procedure, staging script, and exact expected numbers |
| `Auxiliary/Lab 5 - as submitted/README-import.md` | What was imported and why the two Lab 5 copies differ |

---

# 7. Next three actions

1. **Run `DOC/04_baseline_runbook.md` on Windows.** ~30 minutes. Closes G-202 and gates everything.
2. **Send Q1, Q2, Q3 to course staff** — board, clock frequencies, the 8× `SEC_PERIOD` discrepancy.
3. **Write the directed ISA testbench** (Phase 2 / G-402). Authorable without a simulator; it turns
   G-321…G-326 from a claim into a measurement.
