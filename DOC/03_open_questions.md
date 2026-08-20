# Deliverable C — Open Questions

Points where the supplied material is ambiguous, incomplete, or self-contradicting. Each carries a
**provisional decision** so that no question blocks progress; if an answer arrives that differs, the
affected item is revisited and the decision line is updated.

Ordered by how much RTL behaviour depends on the answer.

---

## Blocking before hardware work

### Q1 — Which FPGA board?

**Found.** All Lab 5 material targets **DE2-115 / Cyclone IV E / EP4CE115F29C7**: the `.qsf` device
line, both SDC files, and the pin note. The students' own Lab 5 was compiled, programmed and
examined on a physical DE2-115. `Auxilary/Lab4/DUT/hex_decoder.vhd:13` comments "DE2-115 7-segment
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
material. `Auxilary/QUARTUS/pinPlanner/DE2-115_pinLocation.txt` is a 28-line student note covering
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

### Q9 — The four decode defects in the supplied baseline

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

**Question.** Is the RV32I baseline meant to be ISA-conformant, or are these deliberately left as
exercises? Either answer is fine; we need to know how to present them.

**Provisional decision.** Fix all five, document each with its baseline citation, and present the
four as supplied defects rather than as failures of our RTL — the same treatment the rules require
for benchmark defects.

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
against real constants. Q9–Q13 affect wording and packaging, not behaviour.
