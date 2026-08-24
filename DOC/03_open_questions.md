# Deliverable C — Open Questions

> **If you only want the list to send Hanan, read `DOC/05_questions_for_hanan.md` instead.** That file
> holds only what is **still** open after the forum answers, with a one-sentence "Ask" line per item.
> This file is the long record: what was searched, which file said what, and the full transcription of
> the forum answers — including the ones that are now closed and must not be re-asked.

Points where the supplied material is ambiguous, incomplete, or self-contradicting. Each carries a
**provisional decision** so that no question blocks progress; if an answer arrives that differs, the
affected item is revisited and the decision line is updated.

Ordered by how much RTL behaviour depends on the answer.

---

# ANSWERS FROM HANAN'S FORUM — added 2026-08-24

Three screenshots of the course forum Q&A were supplied. They answer a large part of this document.
Recorded here **before** any of it is acted on, so that what changed and why is traceable.

**Transcription caveat.** The source is screenshots of Hebrew text, some of it small. Every row below
that drives a design decision was cross-checked against a file in the repo where that was possible,
and those cross-checks are named. Two rows are marked **[low confidence]** where the wording could not
be read with certainty; neither is acted on without confirming.

## A. Answers that close an open question

| # | Question | Hanan's answer | Closes |
| --- | --- | --- | --- |
| F1 | Which core do we start from, and does `mul` include `mulh*`? | Base on **Lab 5 part 1**: extend the supplied RV32I single-cycle to RV32IM, **"including support for a 16-bit multiplier only"**. And separately: **"`mul` only (as in Lab 5)"** | **Q14**, **G-326**, **G-308** |
| F2 | Are the divider's `DIVIDEND`/`DIVISOR`/`QUOTIENT`/`RESIDUE` memory-mapped or core-internal? | `DIVRST` initialises the divider's internal quotient shift register **"in parallel with writing the Dividend, Divisor values into the core's registers"** — *core* registers | **Q6**, confirms **A7** |
| F3 | Is `Ain` the dividend or the divisor? | **`Ain` = Dividend, `Bin` = Divisor** | new |
| F4 | What does divide-by-zero return? | Normally an exception status line; **"in your case there is no support for that and in practice the division result will be all ones"** | new |
| F5 | Must the divider's subtractor be built from full adders? | **"You may use the subtraction operator"** — just check what Quartus synthesises | new |
| F6 | Are `MCLK`, `ACCELCLK`, `SMCLK` produced by one PLL module? | **"No — on the basis of three different PLL instances"**, each fed by the 50 MHz base clock | **G-311**, and it **unblocks Phase 4B** |
| F7 | May all three clocks run at the same frequency? | The separation exists for timing/power independence, **but: "since you are working with a single-cycle base CPU (not a pipeline) running at a low frequency … your values may be identical, i.e. MCLK = SMCLK"** | **Q2** (largely), confirms **A2** |
| F8 | What is `SMCLK`? | Stated in writing in `Intrrupt-based IO/ReadMe.txt`: *"value of 0x01312D00 is for **SMCLK=20MHz**"* | confirms **A1** — no longer an assumption |
| F9 | What is `PORT_PB`'s bit layout? | **"The mapping is in the order KEY1–KEY3 to bits 0–2 respectively (KEY0 is not included, since it is the system RESET interface)"** | **unblocks Phase 6C** |
| F10 | Does each HEX stand alone, or do HEX0+HEX1 pair up for one value? | **"Each HEX stands on its own"** | confirms **A14** |
| F11 | Must the GPIO registers be latches, or may they be DFFs on a clock? | For them to be latches the bus data would have to be stable and not a combinational output; **"while the other modules' registers are DFF based on SMCLK, that is preferable for the GPIO register too"** | **validates the Phase 6A deviation** |
| F12 | Do we implement key debounce in VHDL? | **No — the board debounces in hardware** (a 74HC245 buffer, Figure 6); the signal entering the FPGA is clean | confirms the plan |
| F13 | An interrupt arrives while `DIV`/`REM` is still `BUSY` — finish the instruction first? | **"Correct."** The CPU finishes the current instruction, then drops `INTA` and runs the protocol; for `DIV`/`REM` the instruction only completes **when `BUSY` falls** | confirms the plan |
| F14 | Must `TYPE` be multiplied by 4 to index the vector table? | **"The `TYPE` register contains values that are multiples of 4"** — it is already a byte offset | confirms `DOC/02` §4.1 |
| F15 | `BTCTL2` sits at an odd address and the assembly stores to it — is that legal? | **"Word-multiple addressing is relevant for the DTCM address space only; in the peripherals' address space any address value can be relevant (byte addresses)"** | confirms the MMIO map |
| F16 | What exactly does RESET clear in the Basic Timer? | **"Only the timer's interface registers are reset: `BTCTL1`, `BTCTL2`, `BTCAPR`, `BTCMPR0`, `BTCMPR1`"** — so **`BTCNT` is not reset** | new, Phase 8 |
| F17 | In compare mode, does `BTCNT` keep counting past `BTCL1`? | The core raises an interrupt per `BTINT` on comparison with `BTCL0`/`BTCL1`, **but the count always restarts after reaching `BTCL0` (on the rise of `EQU0`)** | new, Phase 8 |
| F18 | Where do `PWMout`, `CAPIN1`, `CAPIN2` go? | **"Yes — you must choose three pins on the board's external interface connector"** for the three | narrows **G-504** |
| F19 | Were the interrupt benchmarks changed? | **"bin folders under test1, test2, test3 under Interrupt-based IO were updated … the content of the interrupt vector table was adjusted to ITCM start address of value zero."** Also: **test4 was added, plus a ReadMe describing test1–test4**, and all four now initialise `state=STATE0` | see B below |

**F19 checked against the repo, and we are current.** `Auxiliary/Benchmark Apps/Intrrupt-based IO/`
holds `test1`–`test4` **and** `ReadMe.txt`, and the vector tables read `0x200` / `0x11C` / `0x17C` /
`0x234` — ITCM-relative, no bias. The pre-update copy is preserved at
`_superseded/Interupt-based IO/` and reads `0x1FC`. **No re-import is needed.**

## B. What the added ReadMe gives us that no other file did

`Auxiliary/Benchmark Apps/Intrrupt-based IO/ReadMe.txt` is the per-application description the
forum asked for, and it is the **expected-behaviour contract** for Phase 10:

- **test1** — `KEY1`→ `arr1[i]` on HEX5,HEX4; `KEY2` → `arr2[i]` on HEX3,HEX2; `KEY3` → quotient on
  HEX1,HEX0 **and remainder on LEDR7-0**, then `i++`, then delay. `SW0` picks the delay length
  (short for simulation, long for the board). **Not timer-based.**
- **test2** — three FSM states printing `a0` to a HEX pair each; `a0++` on every **1 s** BT interrupt.
- **test3** — the same, but each key also changes the interval: 1 s → 0.5 s → 0.25 s → 0.125 s.
- **test4** — the application that covers everything: `KEY1` cycles the compare-mode interval,
  `KEY2` puts the timer in **output-compare mode with a 5 kHz PWM** and cycles the duty cycle through
  0.5 / 0.25 / 0.125 / 0.0625, `KEY3` uses **input-capture mode to time** an array division (even
  presses) or modulo (odd presses) loop.

## C. One thing the forum did NOT resolve — and it is now better evidenced

**Q3 / A5 stands.** `Intrrupt-based IO/test{2,3}/asm-code/01_func.s:54-74` programs
`BTCTL1 = BTSSEL3 = 0x18`, i.e. bits[4:3] = `11` → **÷8**, and then loads
`SEC_PERIOD = 0x01312D00 = 20,000,000` with the comment *"interrupt period of 1sec"*. At
`SMCLK = 20 MHz` divided by 8 that is **8 seconds**.

The forum's answers make this sharper rather than softer: F8 confirms `SMCLK = 20 MHz` in Hanan's own
words, and the ReadMe repeats "1sec" for the same constant. Meanwhile `FREQ_5K = 500` at ÷8 gives
exactly 5 kHz, which is what test4's PWM needs — so the ÷8 reading is right and it is the
`SEC_PERIOD` value or its comment that is off by 8. **Still the question to ask.**

## D. What these answers CONTRADICT in code already written

Recorded plainly, because three of them mean rework:

| Answer | What it contradicts | Action — **all three done 2026-08-24, before any new phase was started** |
| --- | --- | --- |
| **"No"** — buttons and switches need no two-DFF synchroniser, *"since their rate of change is many orders of magnitude slower than the system clock, so the signal is considered static"* | Phase 6B added exactly that on `SW_i`, justified by citing Hanan's **own** Figures 10a/10b material | ✔ **FIXED.** Now behind `GEN_INPUT_SYNC`, default `FALSE`, with the answer quoted at the generic. Kept available because it costs 16 flops and 2 cycles — nothing — and turning it on is how a marginal board would be diagnosed |
| **"It is mandatory to use a DATA BUS based on the bi-directional bus"** | Phase 6B built the **read** side as a real tri-state bus, but the write data still leaves the core on its own separate `dbus_wdata_w` path. That is not one bidirectional bus | ✔ **FIXED.** One shared `data_bus_w` with ten drivers — the CPU on `MemWrite`, the eight readable registers on `CS · MemRead · lane`, the terminator when neither — and **the peripherals now take their write data from the bus**, which is what makes it a bus. Every driver is 32 bits so A11 is expressed once and the bus always has a driver; `onehot_check` counts all ten and also asserts against *no* driver, the `'Z'` case |
| **F11**: the other modules' registers are DFFs based on **`SMCLK`** | Phase 6A clocks the seven GPO ports from **`mclk`**, via the transitional `mclk_o` export | ✔ **FIXED.** A named `pclk_w` now clocks every peripheral and nothing below the bus interface touches `mclk_w`. It is driven from `mclk_w` today, which is *correct* — F7 permits `MCLK = SMCLK` — and Phase 4B changes one line |
| **IFG is the masked value** — *"the flag accumulated as '1' in IFG depends on BOTH conditions, interrupt request AND interrupt enable; if either is zero the flag drops to zero"*, and IFG only rises when `IE = 1` | **Assumption A6 in `DOC/02` says the opposite**: that `IFG` holds the raw latched flag and `IE` masks only the path toward `INTR` | **A6 is falsified.** Phase 9 follows Hanan. Nothing is built yet, so this costs nothing — it would have cost a rebuild |

## E. Still open after the forum

Q1 (which board), Q3/A5 (above), Q4 (`RXIFG` serving two `TYPE` values), Q5 (`HEU0`),
Q9 (`BTINT`'s three-of-four encoding), Q11/Q12 (`UCTL` spelling, `UxBRx`/`UxMCTL`), and
**[low confidence]** two forum rows: whether *all* timer interface registers are read/write with
`BTCTL2` read-only, and the exact wording of the interrupt-request-in-the-control-unit answer.

---

## Blocking before hardware work

### Q1 — Which FPGA board?

**Found.** All Lab 5 material targets **DE2-115 / Cyclone IV E / EP4CE115F29C7**: the `.qsf` device
line, both SDC files, and the pin note. The students' own Lab 5 was compiled, programmed and
examined on a physical DE2-115. `Auxiliary/Lab4/DUT/hex_decoder.vhd:13` comments "DE2-115 7-segment
displays are active-low".

All USART material targets a **DE10-Standard / Cyclone V SoC**: `Auxiliary/USART Material/JP1
connection.md` is a transcription of the DE10-Standard User Manual Table 3-11 (`PIN_W15`,
`PIN_AK2`, `PIN_Y16` …).

The specification links figures for **both** (§4, p5: "Figure 4a — DE10-Standard", "Figure 4b —
DE2-115"), and both links are external Google Drive URLs, so neither figure is in the document.
§4's own I/O list — SW9-0, LEDR9-0, HEX5-0 — fits both boards. The UART bonus menu names `LEDG`,
which exists on the DE2-115 and **not** on the DE10-Standard.

**Why it matters beyond pin numbers.** `PIN_W15`, `PIN_AK2` and `PIN_AK3` are all *valid*
coordinates on the F29 package too. Copying DE10-Standard pin assignments into a DE2-115 `.qsf`
compiles with no error and silently mis-routes the UART.

**Also missing either way.** There is no DE2-115 expansion-header pin table anywhere in the
material. `Auxiliary/Lab 5/Auxilary/RV32I/QUARTUS/pinPlanner/DE2-115_pinLocation.txt` is a 28-line student note covering
only `clk_i`, `rst_i` and `BPADDR_i[7:0]` — no GPIO header, no HEX, no LEDR. We will need the
DE2-115 User Manual Table 3-x for the UART TX/RX/GND pins.

**Provisional decision.** DE2-115. Treat the DE10-Standard material as reference for the wrong
board. Interpret the menu's `LEDG` as `LEDR` and state that in the report.

---

### Q2 — What are `MCLK`, `SMCLK` and `ACCELCLK`?

**Found.** Figure 1 (p3) shows `baseclk50MHz → Clock Tree → mclk, accelclk, smclk`. Beyond the
string `baseclk50MHz` inside that image, **the document states no numeric frequency anywhere.**

Lab 5's PLL generics give 25 MHz (`G_PLL_DIV = 2`, `G_PLL_MUL = 1`) and both Lab 5 SDCs document
25 MHz. But the interrupt benchmarks annotate their timing constants `# in case of SMCLK=20MHz`, and
`FREQ_5K = 500` resolves to exactly 5 kHz only at SMCLK = 20 MHz with `BTSSEL = 3` (÷8).

**Question.** Is `SMCLK = 20 MHz`? Is `MCLK` the same, or a separate frequency? What should
`ACCELCLK` be — is 50 MHz (the undivided board clock) intended, given that §6.iii calls `DIVCLK` the
"fast clock"?

**Provisional decision.** `MCLK = SMCLK = 20 MHz`, `ACCELCLK = 50 MHz`. 20 MHz also buys needed
timing headroom: the single-cycle core closes at only 26.81 MHz before any peripheral is added, and
the new MMIO decoder lands directly in its critical path.

---

### Q3 — `BTSSEL = 3` with `SEC_PERIOD` gives 8 seconds, not 1

This is the sharpest contradiction we found, and it is arithmetic rather than interpretation.

**Found.** Figure 7 (p7) shows the `BTSSEL` mux as `00 → SMCLK`, `01 → SMCLK:2`, `10 → SMCLK:4`,
`11 → SMCLK:8`. The benchmark author's own comment at
`Intrrupt-based IO/test4/asm-code/01_func.s:158` confirms the `00` end: it annotates the value
`0x26` (whose `BTSSEL` bits are `00`) as `BTSSEL=SMCLK`.

test2, test3 and test4's compare mode all load `SEC_PERIOD = 20,000,000` into `BTCMPR0` and then
write `BTSSEL3 = 0x18`, i.e. `BTSSEL = 3` → ÷8. Their comments claim "interrupt period of 1sec".

At SMCLK = 20 MHz the timer clock is 2.5 MHz, so 20,000,000 counts is **8 seconds**. Meanwhile
test4's PWM mode loads `FREQ_5K = 500` at the same `BTSSEL = 3` and gets 2,500,000 ÷ 500 =
**5000 Hz exactly**, matching its comment.

So `FREQ_5K` is right and `SEC_PERIOD` is off by exactly 8× — at the same divider setting. For
`SEC_PERIOD` to mean one second, either SMCLK is 160 MHz (impossible from 50 MHz on this device) or
`BTSSEL` must be `0` for those tests.

**Question.** Should the tests be programming `BTSSEL = 0` for the one-second interval, or is
`SEC_PERIOD` intended to give 8 seconds and the comment is stale?

**Provisional decision.** Implement Figure 7's table exactly as drawn. Three independent pieces of
evidence support it — the mux labels, the author's `BTSSEL=SMCLK` annotation, and `FREQ_5K` resolving
exactly — against only the "1sec" prose comments. We will report the measured period as 8 s and note
that the benchmark comment disagrees, rather than bend the hardware to match a comment.

---

## Affect RTL structure

### Q4 — `BTINT` encoding

`BTCTL1[1:0]` is a two-bit field and p8 says only "BTINT: select the Interrupt Source from three
options". Figure 7's `BTIFG` source multiplexer has **four** positions, fed by `EQU0`, `EQU1` and the
capture event. Which code selects which source is stated nowhere.

The only value the benchmarks use is `BTINT = 2` (`BTINT2 = 0x02`, and `BTHOLD_BTCLR_BTINT2 = 0x26`),
in test4's capture mode. Everything else writes `BTINT = 0`.

**Provisional decision.** `0 → EQU0` (compare against `BTCL0`), `1 → EQU1` (compare against
`BTCL1`), `2 → capture event`, `3 → reserved, behaves as 0`. Derived solely from test4 using `2` for
capture and `0` everywhere else. Labelled an Assumption in Deliverable B.

---

### Q5 — `PORT_PB` bit layout

`0x2014` has an address (p6) and a device ("KEY[3-1]") but **no bit-field table**. Which bit is KEY1,
KEY2, KEY3? Do the buttons read active-low, as Figure 6's pull-up and 74HC245 schematic implies?

The `KEYnIFG` masks constrain the *`IFG`* bit positions (3, 4, 5) but say nothing about `PORT_PB`.

**Provisional decision.** Mirror the `IFG` layout: KEY1 → bit 0, KEY2 → bit 1, KEY3 → bit 2, upper
bits read `0`, and present the buttons **active-high** at the register (invert the pin) so software
reads `1` for pressed. **[REC]** This is the reading most consistent with the benchmarks, but it is
a guess — worth confirming because a benchmark that polls `PORT_PB` would break under the other
convention.

---

### Q6 — Are the divider registers memory-mapped?

`DIVIDEND`, `DIVISOR`, `QUOTIENT` and `RESIDUE` are given full 32-bit register diagrams on p9 but
appear in **neither** MMIO table (p5, p6). Figure 3 wires the divider's `Ain`/`Bin` to the ALU
operands and its `Quotient`/`Rem` into the write-back mux, not to the data bus.

**Question.** Core-internal, driven by decode of `div`/`divu`/`rem`/`remu`? Or SFR-addressable, in
which case what addresses?

**Provisional decision.** Core-internal, per Figure 3. `div`/`rem` decode triggers `DIVstart`, the
core stalls on `DIVbusy` via `PCHold`, and the result enters through the write-back mux.

---

### Q7 — `RXIFG` serves two TYPE values

`RXIFG` is the flag for **both** "UART status error" (TYPE `04h`, priority 1) and "UART RX"
(TYPE `08h`, priority 2). One flag, two vector slots.

**What we found.** In all four interrupt benchmarks, DTCM words 1 and 2 — the `04h` and `08h`
vectors — hold the **same handler address**. So both paths reach one routine, which presumably reads
`UCTL` to distinguish an error from valid data. The choice cannot change behaviour in any supplied
benchmark, which is why this is not in the blocking section.

**Question.** How should the controller choose which TYPE to present — is `04h` presented whenever
any of `FE`/`PE`/`OE` is set at the moment of service, and `08h` otherwise?

**Provisional decision.** Exactly that: if any UART error flag is set, present `04h`; otherwise
`08h`. This matches the priority ordering (error is higher) and the register semantics.

---

### Q8 — `HEU0` in Figure 7

The `BTCL0` and `BTCL1` shadow latches in Figure 7 are enabled by a signal drawn as `HEU0='1'`. That
name appears nowhere else in the document and matches no register field.

**Provisional decision.** Read it as the shadow-transfer enable, and implement the transfer
`BTCMPRx → BTCLx` while the timer is held or cleared (`BTHOLD` or `BTCLR`) and at each period
boundary. That is what the benchmarks do in practice — they write `BTCMPR0` while `BTHOLD = 1` and
then release. **[REC]** Likely a typo or an artefact of the figure; worth one line of confirmation.

---

## Documentation and naming

### Q9 — The ISA defects in the supplied baseline (six of seven, not four)

`lui` writes 0, every load addresses `rs1 + 0`, `sra` behaves as `srl`, and `sltu`/`sltiu`/`bltu`/
`bgeu` compare signed. All four are present **identically in `Auxiliary/Lab 5/Auxilary/DUT/`**, the
RV32I baseline distributed with LAB5:

| Defect | Baseline site |
| --- | --- |
| `lui` | `const_package.vhd:27` — `UTYPE_OPC := "0010111" and "0110111"` evaluates to `auipc` only |
| loads | `IDECODE.VHD:94-101` — the `with opc_w select` has no `0000011` arm |
| `sra` | `EXECUTE.VHD:179` — `brl_shr_pad_r <= 32x"FFFF"` is `0x0000FFFF`, so bit 31 is `'0'` |
| unsigned compares | `EXECUTE.VHD:9` — `USE IEEE.STD_LOGIC_SIGNED.ALL` makes line 78's `<` signed |

A fifth defect (`andi` writes 0, `ori` computes AND) is a student regression — the baseline's
`CONTROL.VHD:141` is correct.

**REVISED 2026-08-23: there are two more, and they are also the baseline's.**

| Defect | Baseline site |
| --- | --- |
| branch/`jal` displacement truncated one bit | `EXECUTE.VHD` — `sign_extend_i(PC_WIDTH-3 DOWNTO 0)` drops immediate bit 11, halving branch range to ±2 KiB inside an 8 KiB PC |
| `jalr` does not clear the target's bit 0 | `IFETCH.vhd` — the next-PC mux takes `alu_res_i` unmasked |

So the tally is **six of seven from the baseline**, one student regression. Both new ones are
control-flow defects that no supplied benchmark exercises, which is presumably why they survived.

**Question.** Is the RV32I baseline meant to be ISA-conformant, or are these deliberately left as
exercises? Either answer is fine; we need to know how to present them.

**Provisional decision — and it is now much better supported than when this was written.** Fix all
seven and present the six as supplied defects rather than as failures of our RTL. What changed is
that we are no longer *designing* the six repairs: the pipelined core in the same LAB5 submission
already fixes all seven and was hardware-validated that way, so each repair is a transcription with a
file:line citation. And defects 6 and 7 have an independent second confirmation in `Auxilary/Ori/`,
another student's pipeline, which fixes exactly those two with identical expressions.

The answer to this question now affects only the report's framing, not the work. **Downgraded from
blocking to informational.**

---

### Q10 — test4's capture input never changes

`capture_init` and `capture` in `Intrrupt-based IO/test4/asm-code/01_func.s` write the **same value**
to `BTCTL2`:

```asm
capture_init:
    li t0,CAPMD1_CAPISEL3   # "capture on rising-edge event, set the input signal to GND"
    sw t0,0(t6)             # BTCTL2 = 0x07
capture:
    li t0,CAPMD1_CAPISEL3   # "set the input signal to VCC"
    sw t0,0(t6)             # BTCTL2 = 0x07   <-- identical
```

`io_map.s:40` defines `CAPMD1_CAPISEL3 = 0x07`, i.e. `CAPMD = 1` (rising edge), `CAPISEL = 3` (GND).
`CAPISEL` therefore never leaves GND, no edge is ever generated, and `BTCAPR` is never written. The
comments describe the intent — GND then VCC, producing one rising edge — but the code does not
implement it. `CAPISEL = 2` (VCC) would be `0x06`.

Note that two other defects in the same file (an inverted loop guard and a missing loop back edge)
**were** fixed in the revision supplied on 2026-08-19; this one was not. The older revision is kept
at `Auxiliary/Benchmark Apps/_superseded/` with a full diff.

**Provisional decision.** Leave the supplied source untouched. Verify capture separately with a
clearly-marked corrected copy that writes `0x06` in `capture`, and report both.

---

### Q11 — `UCTL` or `UTCL`?

The p6 memory map row reads `UTCL`; the register bit-field table on p12 is titled `UCTL`. The
benchmarks' `io_map.s` uses `UTCL`. Same register at `0x2018`.

Related: the p6 map names the buffers `RXBF`/`TXBF` while the benchmarks and the p12-13 register
descriptions use `RXBUF`/`TXBUF`.

**Provisional decision.** Use `UTCL`, `RXBUF`, `TXBUF` — the names the executable `io_map.s`
contract uses — and note the spelling variants in the report.

---

### Q12 — Is a separate baud-rate register expected?

Figure 11 (p11) draws a `Prescaler/Divider UxBRx` block and a `Modulator UxMCTL` block, but neither
has a bit-field table, an address, or any prose. The only baud control defined anywhere is `UCTL`
bit 3 (`BAUDRATE`: 0 → 9600, 1 → 115200).

**Provisional decision.** No separate register. Baud is selected solely by `UCTL[3]`, and the
prescaler is internal. The supplied UART's divider is a compile-time constant
(`UART_FPGA_option1/rtl/uart.vhd:58`), so making it switchable at run time is new work either way.

---

### Q14 — Is a full 32×32 `mul` required, and are `mulh*` / `div*` in scope?

**This is the one open question that currently blocks work**, so it is worth sending first.

`MUL16.vhd` multiplies `rs1(15:0) × rs2(15:0)` unsigned — `EXECUTE.vhd:93-94` feeds it only the
lower half-words. So `mul` is correct only when both operands fit in 16 bits, and
`mulh`/`mulhsu`/`mulhu`/`div`/`divu`/`rem`/`remu` are not decoded at all despite their masks existing
in `const_package.vhd`.

`Auxiliary/Lab 5/PROJECT_EXPLANATION.md` §1 describes the submitted design, in its own
words, as "an RV32I-oriented teaching core extended with a tested 16-bit `mul` datapath", and it was
accepted that way. LAB5 calls the scope "MULDIV **partial**".

Three sub-questions:

1. **Does the final project need a conformant 32×32 `mul`?** No 32×32 multiplier exists anywhere in
   the material. Nine of the ten remaining ISA-suite mismatches sit behind this and the next item.
2. **Are `mulh`/`mulhsu`/`mulhu` in scope**, or does "MULDIV partial" mean `mul` only?
3. **Does `div` belong in the ALU at all?** §6.iii defines a **division accelerator** as a
   *peripheral* — Figure 9's `DIVIDEND`/`DIVISOR`/`QUOTIENT`/`RESIDUE` with
   `DIVCLK`/`DIVRST`/`DIVENA`/`DIVBUSY` — not as an instruction. If the accelerator is the intended
   answer, adding `div` decode to `EXECUTE` builds the wrong thing. This overlaps **Q6**, which asks
   whether those registers are memory-mapped or core-internal.

**Provisional decision: implement none of it yet.** Each option is a different piece of hardware and
picking one without an answer is exactly the invention the rules forbid. The directed ISA suite
already measures the gap precisely — 9 mismatches, named — so the cost of waiting is a number in a
report, not rework. Q6 and this question are the two that gate Phase 3C.

---

### Q13 — Five or six submission directories, and the report filename

p18 says the ZIP "will contain the next six subdirectories (only the exact next sub folders)" above
a table listing **five**: `DUT`, `TB`, `SIM`, `DOC`, `Quartus`.

`LAB5 task definition.pdf` §9.g uses the *identical* wording above the same five, and Lab 5 was
submitted with five and accepted.

Separately, p17 §10 calls the report `final.pdf` while Table 1 calls it `Final_report.pdf`.

**Provisional decision.** Five directories; report named `Final_report.pdf`. Both follow the more
specific of the two statements, and the directory count has direct precedent. Low risk, but a
submission-rule violation is disqualifying, so worth one line of confirmation.

---

## Summary

| # | Question | Blocks | Provisional decision |
| --- | --- | --- | --- |
| 1 | Board | pin planning, hardware | DE2-115 |
| 2 | Clock frequencies | timer verification, PLL | MCLK = SMCLK = 20 MHz, ACCELCLK = 50 MHz |
| 3 | `SEC_PERIOD` 8× discrepancy | timer verification | Follow Figure 7; report 8 s |
| 4 | `BTINT` encoding | timer RTL | 0→EQU0, 1→EQU1, 2→capture, 3→as 0 |
| 5 | `PORT_PB` layout | GPIO RTL | KEY1/2/3 → bits 0/1/2, active-high at the register |
| 6 | Divider registers mapped? | divider RTL | Core-internal |
| 7 | `RXIFG` two TYPEs | interrupt RTL | Error flags set → `04h`, else `08h` |
| 8 | `HEU0` | timer RTL | Shadow transfer on hold/clear and period boundary |
| 9 | Baseline decode defects | report framing only | Fix all five, cite each |
| 10 | test4 capture | verification only | Keep original; corrected copy marked separately |
| 11 | `UCTL`/`UTCL` naming | naming only | Follow `io_map.s` |
| 12 | Separate baud register? | UART RTL | No; `UCTL[3]` only |
| 13 | Five/six dirs, report name | submission | Five; `Final_report.pdf` |

Q1–Q3 should be asked first. Q4–Q8 are needed before their respective peripherals are verified
against real constants. Q9 and Q11–Q13 affect wording and packaging, not behaviour.

**Send first: Q6 and Q14.** Those two are the only ones now blocking implementation — together they decide what, if anything, happens to `mul` width, `mulh*` and `div*`, which is nine of the ten remaining ISA-suite mismatches. Q1–Q3 remain the next most valuable.
