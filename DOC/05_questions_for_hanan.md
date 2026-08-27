# Questions for Hanan — the current list

**Last updated 2026-08-25, after the forum answers and the recorded prep session
(`DOC/03` §"THE RECORDED PREP SESSION").**

This file is the short, sendable list: **only what is still open.** Each item has a one-sentence
**Ask** line meant to be sent as-is (translate to Hebrew if posting to the forum), followed by what we
already found and what we are doing meanwhile so that nothing is blocked while we wait.

The long analytical record — what was searched, which file said what, and the full transcription of
the forum answers — stays in `DOC/03_open_questions.md`. **Do not re-ask anything in section 6
below**; it is already answered.

| Section | Items | Nature |
| --- | --- | --- |
| 1. Blocking | 4 | a phase cannot be finished without the answer |
| 2. Proceeding under an assumption | 7 | built, but on an interpretation we chose |
| 3. Peripherals not yet built | 4 | needed before Phases 8, 9 and 12 |
| 4. Report and submission | 3 | needed before the ZIP |
| 5. Material we do not have | 1 | a request, not a question |
| 6. Already answered | — | **do not re-ask** |

---

## 1. Blocking — a phase cannot be finished without these

### B1 — Which FPGA board?

> **Ask:** Is the project to be built for the **DE2-115** or the **DE10-Standard**?

Clause 4 links figures for both, and both links are external and not in the document. Every Lab 5
file, both SDCs, the device line `EP4CE115F29C7` and our own hardware runs are **DE2-115**. All the
USART material is **DE10-Standard** (`JP1 connection.md` transcribes that board's Table 3-11). The
UART bonus menu names `LEDG`, which exists on the DE2-115 and not on the DE10-Standard.

**Why it matters beyond pin numbers:** `PIN_W15`, `PIN_AK2` and `PIN_AK3` are *valid* coordinates on
the F29 package as well, so a DE10-Standard assignment copied into a DE2-115 project compiles
cleanly and drives the wrong physical pins.

**Update 2026-08-25 (prep session):** demonstrating on a board, Hanan said the interface *"doesn't
matter — the same on both"*, and described six 7-segment modules, which is what the design drives.
So both boards are acceptable at the interface level; the question now decides **only the pin
table**, not the architecture.

**Meanwhile:** everything targets the DE2-115. Nothing is blocked except the pinned Quartus revision.

### B5 — test1 skips EINT on the SW0=0 path (added 2026-08-25, Phase 10A)

> **Ask:** In `Intrrupt-based IO/test1/asm-code/00_main.s`, the SW0=0 (short-delay) path executes
> `j STATE1` **before** the `ori gp,gp,0x01` EINT line, which sits after the `if_l:` label — so in
> the configuration the comments call "used for ModelSim based verification", GIE is never set and
> no KEY interrupt is ever taken. tests 2/3/4 all set EINT unconditionally at init. Is this
> intentional, or should the `j` land on the EINT?

Evidence: the shipped `bin/M9K-intel/ITCM.hex` word at byte `0xBC` is `0x01C0006F` — `jal x0`
targeting `0xD8` (STATE1), past the `ori gp,gp,1` at `0xC8`. **Meanwhile:** the original is
untouched; `SIM/RV32IMscMCU/bench_fixed/test1/` carries a one-word corrected copy (the jal
retargeted to the EINT itself, audited in `bench_fixed/PATCHES.md`), and Phase 10A's ModelSim run
uses it. On the board with SW0=1 the shipped image works as-is, so nothing hardware-facing blocks.

### B6 — test4's capture measurement cannot produce a nonzero runtime (added 2026-08-26, Phase 10B)

> **Ask:** In `Intrrupt-based IO/test4/asm-code/01_func.s`, `capture_init` writes
> `BTCTL1 = BTHOLD_BTCLR = 0x24` at the start of every measurement. That does two things to the
> measurement it is initializing: (a) it zeroes `BTINT`, which `bt_capture_config` had just set to
> 2, so the capture event does not raise `BTIFG` and `BT_ISR` never stores `BTCAPR`; and (b) it
> holds `BTHOLD = 1, BTCLR = 1` through the whole measured window — and no later write ever
> releases them — so `BTCNT` is pinned at 0 and a capture would latch 0 anyway. Together with the
> `CAPISEL` value that never changes (our earlier question on `capture` writing `0x07` twice),
> `runtime_div`/`runtime_rem` can never receive a nonzero value. Is a revised test4 planned, or
> should we validate capture with our own directed program and document test4's capture mode as
> configuration-only?

**Meanwhile:** the original is untouched; `bench_fixed/test4` carries only the audited one-word
`0x07 → 0x06` fix (which does make the capture *edge* real — our testbench counts it firing), and
`tb_bench_test4` asserts `runtime_div = runtime_rem = 0`, the only expectation the sources
support. Capture as a *mechanism* is already verified independently by `tb_basic_timer` (P6) and
`tb_timer_mmio` (S5–S7), so nothing is blocked.

### B2 — `SEC_PERIOD` and `BTSSEL` disagree by a factor of 8

> **Ask:** `test2` and `test3` set `BTCTL1 = 0x18` (`BTSSEL = 11`, ÷8) and then load
> `SEC_PERIOD = 0x01312D00` commented "1sec". At `SMCLK = 20 MHz` ÷ 8 that is **8 seconds**. Which is
> correct — the `BTSSEL` value, the constant, or the comment?

Three citations now stand behind this, and they conflict:

1. `Intrrupt-based IO/test{2,3}/asm-code/01_func.s:54-74` — `BTSSEL3 = 0x18`, bits[4:3] = `11`.
2. The same files' `io_map.s:45` — `SEC_PERIOD = 0x01312D00` = 20,000,000, *"in case of SMCLK=20MHz"*.
3. The added `Intrrupt-based IO/ReadMe.txt` — *"On every BT interrupt-interval of 1sec (value of
   0x01312D00 is for SMCLK=20MHz)"*.

Meanwhile `FREQ_5K = 500` at ÷8 gives **exactly** the 5 kHz that test4's PWM needs, so the ÷8 reading
of `BTSSEL` is right and it is `SEC_PERIOD` or its comment that is off by 8.

**Meanwhile:** Figure 7's divider table is implemented as drawn, and the discrepancy is reported
rather than silently "fixed". Registered as assumption **A5**.

### B3 — What frequency should `ACCELCLK` / `DIVCLK` be?

> **Ask:** The forum says the three clocks come from three separate PLL instances and that
> `MCLK = SMCLK` is acceptable for a single-cycle core. What should `ACCELCLK`/`DIVCLK` be — is the
> raw 50 MHz base acceptable, or is a specific ratio to `MCLK` expected?

The forum settled that `DIVCLK` "needs to be high" so the divider is genuinely an accelerator, and
that all three come from separate PLLs fed by the 50 MHz base. No number was given. It also said
`MCLK` must be an integer multiple of `SMCLK` — satisfied trivially at ×1.

**Update 2026-08-25 (prep session) — likely no longer worth asking.** Hanan: *"we bring it to the
maximum possible"*, *"theoretically ×5, 6, 7, 8"*, and decisively *"how fast the accelerator
finishes is up to you"*. So no specific frequency is mandated — the value is our design decision,
bounded by the divider's own Fmax. Plan: keep 50 MHz until Phase 14 measures `div_accel`'s Fmax,
then raise toward it and state the choice in the report.

**Meanwhile:** Phase 4B will use `MCLK = SMCLK = 20 MHz` and `ACCELCLK = 50 MHz`, and state the
choice in the report. A wrong guess costs one PLL parameter.

### B4 — `BTINT` is two bits but the text says three options

> **Ask:** `BTCTL1[1:0]` is `BTINT`, two bits, and page 8 says it selects the interrupt source "from
> three options", while Figure 7's `BTIFG` source mux has four positions fed by `EQU0`, `EQU1` and the
> capture event. Which code selects which source?

The forum clarified the *behaviour* — in compare mode the core interrupts per `BTINT` on comparison
with `BTCL0`/`BTCL1`, and the count always restarts at `BTCL0` — but not the **encoding**.

**Update 2026-08-25 — the benchmarks pin half the table, so this is no longer blind.** `io_map.s`
defines `BTINT2 = 0x02`, and test4 writes it **exactly when configuring input capture**, while every
compare test runs with `BTINT = 0`. So `00`→EQU0 and `10`→capture are benchmark facts; `01`→EQU1 is
the only source left; `11` reserved — which is precisely "three options" in two bits.

**Meanwhile:** Phase 8A is built on that table (assumption **A20** covers only the `01`/`11` half).
A different answer changes one selected-signal assignment in `BASIC_TIMER.vhd`.

---

## 2. Proceeding under an assumption — built, but on an interpretation we chose

Each of these is already implemented, each is behind a generic or a single constant, and each carries
what would falsify it. They are listed so that a "no" costs one line rather than a rebuild.

### A15 — Are the GPO ports readable?

> **Ask:** Clause 5's table gives `PORT_LEDR` and `PORT_HEX0`–`PORT_HEX5` a Direction of **GPO**, but
> Figure 5 draws a `MemRead`-enabled tri-state inside **each** output-port block, driving
> `Data<7..0>`. Should a load from `0x2000` return the byte last written there, or should an output
> port not respond to a read at all?

**Built as:** readable, behind `GEN_GPO_READBACK` (default `TRUE`). No supplied benchmark reads a GPO
port, so nothing observable depends on it. **A "no" is one word.**

**Update 2026-08-25 (prep session) — effectively answered, keep only as confirmation.** Hanan,
describing the type-1 GPO: *"there is a read from the tri-state, a read of the latch content... I
can write to the LEDs, read the value of the LEDs."* That is the read-back this generic implements.

### A16 — Does `PORT_PB` read `1` for a pressed key?

> **Ask:** You gave the bit order (`KEY1`→bit 0, `KEY2`→bit 1, `KEY3`→bit 2). Should `PORT_PB`
> present the **raw** active-low pin, or the pressed sense so that a pressed key reads `1`?

Nothing states the polarity, and `PORT_PB` is defined in every `io_map.s` but read by **no** supplied
program, so the material does not constrain it.

**Built as:** pressed reads `1`, behind `KEY_ACTIVE_LOW` (default `TRUE`), following
`Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:37-38` and this design's own treatment of KEY0.

### A11 — What do the upper 24 bits of a byte-wide MMIO read return?

> **Ask:** Figure 5 drives only `Data<7..0>` from a byte-resolution peripheral. On `lw` from
> `PORT_SW`, should bits 31..8 read zero?

**Built as:** zero — every bus driver is 32 bits wide and a byte register drives its value
zero-extended. All three MMIO reads in the benchmarks mask the result immediately, so nothing
observes it today.

### A12 — Does a Word-resolution register own all four byte lanes of its word?

> **Ask:** `BTCMPR0`, `BTCMPR1` and `BTCAPR` are marked "Word". Should `0x2021` be treated as part of
> `BTCMPR0`, or as unmapped?

**Built as:** all four lanes belong to the register.

### A13 — What does a GPO port hold after RESET?

> **Ask:** Figure 5 draws no reset on the output latches. Should the LEDs be off and the displays show
> `0` after KEY0, or should the displays be blank until first written?

**Built as:** zero, so the displays show `0`. "Blank until written" would need a separate
"not yet written" flag that nothing asks for.

### A17 — Are the Basic Timer's interface registers readable as well as writable?

> **Ask:** The forum answer on this was that the timer's interface registers are readable and
> writable **except `BTCTL2`**, which is read-only. Could you confirm that reading — we want to be
> sure we read it correctly, since `BTCTL2` is the capture-mode control register and the applications
> appear to write to it.

**This is one of two forum rows we could not transcribe with full confidence**, which is why it is
here rather than in section 6. Phase 8 is not started, so nothing is built on either reading.

### A19 — When `MCLK` and `SMCLK` are the same frequency, one PLL or two?

> **Ask:** You told us the three clocks come from three separate PLL instances, and separately that
> our values may be identical, i.e. `MCLK = SMCLK`. Taken together that gives two independent PLLs
> both producing 20 MHz — and the CPU drives address, write data and `MemWrite` on `MCLK` while the
> peripheral registers capture that bus on `SMCLK`. Two PLLs locked to the same reference are
> frequency-identical but their phase relationship is not specified, so that capture cannot be
> timing-analysed and no figure draws a synchroniser on the GPIO write path. Should `MCLK` and
> `SMCLK` be one shared net when they are the same frequency, or must they stay two separate PLL
> outputs?

**Built as:** one shared net, with the third PLL kept for `ACCELCLK` — generic
`SMCLK_SHARES_MCLK => TRUE` in `CLOCK_TREE.vhd`. The reading behind it: the three-instances answer
tells us *how to make three clocks* (don't try to get three outputs from one PLL) rather than
requiring two equal-frequency clocks to be distinct nets.

**If the answer is "two separate nets":** one word, `SMCLK_SHARES_MCLK => FALSE`, and the branch is
already written and tested. But then the MMIO write path needs synchronisation that Figure 5 does not
draw, so that answer also needs to say what should sit there.

---

## 3. Peripherals not yet built — needed before Phases 8, 9 and 12

### P1 — `HEU0`

> **Ask:** Figure 7 labels the latch-enable of the `BTCL0`/`BTCL1` shadow latches `HEU0`. What is it —
> what drives it and when do the shadow latches load?

Defined nowhere in the document.

### P2 — `RXIFG` serves two `TYPE` values

> **Ask:** `TYPE` `04h` (UART status error) and `08h` (UART RX) share one `RXIFG` flag. When both
> conditions are true, which `TYPE` should the controller present?

**Non-blocking in practice:** in all four benchmark DTCM images, `04h` and `08h` hold the **same**
handler address, so the two vector to one routine that distinguishes error from data by reading
`UCTL`. Verified in `DOC/02` §4.1.

### P3 — `UCTL` or `UTCL`?

> **Ask:** The page 6 memory map row reads `UTCL`; the register bit-field table on page 12 is titled
> `UCTL`; the benchmarks' `io_map.s` uses `UTCL`. Same register, three spellings — which is intended?

Cosmetic, but it goes in the report and in the RTL identifier.

### P4 — `UxBRx` and `UxMCTL`

> **Ask:** Figure 11 draws a "Prescaler/Divider `UxBRx`" and a "Modulator `UxMCTL`", but neither has an
> address, a bit-field table, or any prose. Is the baud rate controlled solely by `UCTL` bit 3, or is a
> separate baud register expected?

**Effectively answered by the specification itself — 2026-08-27, reading the p12 table for Phase
12A.** `UCTL` bit 3 is `BAUDRATE`, "0 = 9600, 1 = 115200", a `w` bit with its own detail rows. Two
rates, one bit, no address anywhere for `UxBRx` or `UxMCTL`, and neither appears in the p6 map.
Built that way. Worth one confirmation only because the figure draws blocks the register table does
not: **is there anything behind `UxBRx`/`UxMCTL` we are expected to implement?** We read them as
MSP430 heritage in the figure, not requirements.

Affects the UART bonus (Phase 12) only.

---

## 4. Report and submission

### R1 — Which report filename?

> **Ask:** The DOC table says `Final_report.pdf`; the clause 10 prose says `final.pdf`. Which?

### R2 — The menu names `LEDG`, and no register reaches it  *(rewritten 2026-08-27)*

> **Ask:** UART menu item 1 says "Count from `0x00` onto **LEDG**", but clause 5's GPIO table has
> exactly one LED register — `PORT_LEDR` at `0x2000`, driving `LEDR7-LEDR0` — and clause 4's output
> interface is "Board 10 red LEDs (LEDR9-LEDR0)". So software has no memory-mapped path to the green
> LEDs. Should item 1 count on `PORT_LEDR` (what we built), or should we add a `PORT_LEDG` register
> and its pins?

**This entry used to say LEDG does not exist on the DE2-115. That was wrong and is corrected.** The
course's own Terasic table — `Auxiliary/Lab4/Auxiliary/DE2_115_pin_assignments.csv` — lists **nine
green LEDs with pins**: `LEDG[0..8]` on `PIN_E21`, `PIN_E22`, `PIN_E25`, `PIN_E24`, `PIN_H21`,
`PIN_G20`, `PIN_G22`, `PIN_G21`, `PIN_F17`, all 2.5 V. (§1's own text already had this right; the two
statements contradicted each other.)

So the conflict is not about the board, it is about the register map. `LEDG` appears **once** in the
whole specification: in this menu line.

**Meanwhile:** Phase 12C's firmware counts up on `PORT_LEDR`, the same register item 2 counts down
on, and the transmitted menu text says `LEDR` so that what the operator reads matches what the board
does. Adding a `PORT_LEDG` register would mean inventing an address the specification does not
contain, which is the one thing the project rules forbid outright.

### R4 — Does the ZIP's `Quartus` folder include the `.qsf`/`.qpf`? (added 2026-08-27)

> **Ask:** Clause 10 Table 1 says the `Quartus` folder holds "a Signal-Tap file, an SDC file, and a
> SOF file" per design, and adds "do not place files that are not relevant for compilation". But the
> inspection protocol's חלק 0 has us compile the design in Quartus on the spot and burn it, which
> needs the project files and the pin assignments — i.e. the `.qsf` and `.qpf`. Should they be
> included?

**Meanwhile:** we include `.qsf` and `.qpf`. They are unambiguously "relevant for compilation", the
103 pin assignments live only there, and without them the on-the-spot build cannot drive the board.
Nothing else is added — no `db/`, no `output_files/`, no `.mpf`.

### R5 — Is the demo-day build the SignalTap-off build? (added 2026-08-27)

> **Ask:** חלק 0 of the inspection protocol says to compile **without the SignalTap file**, while
> clause 7 makes SignalTap validation mandatory and clause 10 asks for a `.stp` in the ZIP. We read
> that as: the `.stp` ships as the clause 7 deliverable, and the build performed in the room is a
> plain functional one with `ENABLE_SIGNALTAP OFF`. Correct?

**Meanwhile:** built that way — the `.stp` stays in the ZIP, and the SignalTap-off build is treated
as the one that must work on the board. See `DOC/04` §9.1.

### R3 — How should we present the ISA-conformance gap?

> **Ask:** Our directed ISA test checks full RV32IM conformance and therefore reports five permanent
> mismatches — two for `mul` being 16×16 and three for `mulh`/`mulhsu`/`mulhu`. Your answer is that a
> 16-bit `mul` only is what the project requires. Is it acceptable to present these in the report as
> "conformance beyond the project's scope, deliberately not implemented", rather than as defects?

We believe the answer is yes and are writing it that way; asking so the report is not surprising.

---

## 5. Material we do not have

### M1 — DE2-115 pin assignments

> **Ask:** Is there a DE2-115 pin-assignment file for the course, or should we take the pin numbers
> from Terasic's own `DE2_115.qsf`?

The design now has **61 board pins** — `LEDR[7..0]`, `HEX0`–`HEX5[6..0]`, `SW[7..0]`, `KEY[3..1]`,
plus `clk_i` and `rst_i` — and Phase 8 adds three more on the expansion header for `PWMout`,
`CAPIN1` and `CAPIN2`, which you have said we choose ourselves.

Checked: five `.qsf` files under `Auxiliary/` do contain `set_location_assignment` lines, but **none
of them, and no other supplied file, contains a single pin number for `LEDR` or any `HEX`**. The only
pin note is a 28-line student file covering `clk_i`, `rst_i` and `BPADDR_i[7..0]`.

**Meanwhile:** the performance Quartus revision is deliberately pinless, which is correct for the PPA
tables. Nothing can be tested on the board until this is resolved. Gap **G-504**.

---

## 6. Already answered — do not re-ask

The forum settled all of these. Wording and cross-checks are in `DOC/03_open_questions.md`, section
"ANSWERS FROM HANAN'S FORUM".

| Topic | Answer |
| --- | --- |
| Which core to start from | Lab 5 part 1, RV32IM single-cycle, **16-bit multiplier only** |
| `mulh` / `mulhsu` / `mulhu` | **Not required** — "`mul` only (as in Lab 5)" |
| Divider registers memory-mapped or core-internal | **Core-internal** |
| `Ain` / `Bin` | `Ain` = Dividend, `Bin` = Divisor |
| Divide by zero | Result is **all ones** |
| Divider subtractor | The `-` operator is allowed |
| Interrupt during `DIV`/`REM` | Finish the instruction — it completes when `BUSY` falls |
| One PLL or three | **Three separate PLL instances**, each from the 50 MHz base |
| May `MCLK = SMCLK`? | **Yes**, for a single-cycle core |
| `SMCLK` frequency | **20 MHz** (stated in the added `ReadMe.txt`) |
| `PORT_PB` bit order | `KEY1`→bit 0, `KEY2`→bit 1, `KEY3`→bit 2; KEY0 excluded |
| One HEX per value, or HEX pairs? | **Each HEX stands on its own** |
| GPIO registers: latch or DFF? | **DFF on `SMCLK`** is preferable |
| Key debounce in VHDL? | **No** — done in board hardware (74HC245) |
| Do buttons/switches need a synchroniser? | **No** — they are effectively static |
| Bidirectional data bus or separate paths? | **Bidirectional is mandatory** |
| Must `TYPE` be multiplied by 4? | **No** — it already holds multiples of 4 |
| Byte addresses in the peripheral space? | **Yes** — word alignment applies to the DTCM only |
| What does RESET clear in the Basic Timer? | **Only the interface registers** — `BTCNT` is not reset |
| Does `BTCNT` restart in compare mode? | **Yes, always at `BTCL0`** (on `EQU0`) |
| `IFG` raw or masked? | **Masked** — it depends on request **and** enable, and only rises when `IE = 1` |
| `PWMout` / `CAPIN1` / `CAPIN2` pins | **Choose three** on the expansion connector yourselves |
| Were the interrupt benchmarks updated? | **Yes** — and we verified our copies are the updated ones |
