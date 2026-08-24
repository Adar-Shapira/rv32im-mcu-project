# Deliverable B — Requirements Traceability

Every address, bit field, interrupt source, timer mode, divider signal and clock, with the source it
came from. Where the material is ambiguous, the interpretation is labelled **Assumption** and what
would falsify it is stated.

Category tags, never mixed:

| Tag | Meaning |
| --- | --- |
| **[REQ]** | Official requirement, cited to a page of `Auxiliary/Final Project 2026 definition.pdf` |
| **[REQ-L5]** | Official requirement from `Auxiliary/Lab 5/Auxilary/LAB5 task definition.pdf` |
| **[CODE]** | Behaviour of code Hanan supplied |
| **[BENCH]** | Conclusion derived from a supplied benchmark |
| **[DEC]** | Our design decision |
| **[REC]** | Engineering recommendation, not binding |

All register bit-field tables in the specification are **raster images**, so no text extractor can
recover them and `Final Project 2026 definition.md` is missing or mangling every one. Everything
below was read from the PDF pages directly.

---

## 1. Data address space

**[REQ p3]** The data address space addresses DTCM and memory-mapped I/O at the lowest 14-bit
address `0…0 A13…A0`.

**[REQ p4, Figure 2]** Word-addressed layout, marked "32-bit Word":

| Word address | Byte address | Region |
| --- | --- | --- |
| `0x000` – `0x7FF` | `0x0000` – `0x1FFC` | DTCM, physical data memory — 2048 words |
| `0x800` – `0xFFF` | `0x2000` – `0x3FFC` | SFR (Special Function Registers), "distributed among many I/O devices, not all used" |

**[REQ p3, Figure 1]** Both memories are labelled `ITCM / L1-ICACHE 8kB size` and
`DTCM / L1-DCACHE 8kB size`.

**[CODE]** `cond_compilation_package.vhd:53-56` sets `G_ADDRWIDTH = 11` and
`G_DATA_WORDSNUM = 2048` — 2048 × 32 bits = 8 KiB. Consistent.

**[CODE]** `RV32IM_CORE.vhd:215-220` currently does `dtcm_addr_w <= alu_res_w(MA_WIDTH-1 DOWNTO 2)`
with `MA_WIDTH = 13`, and there is **no I/O decode at all**. Address `0x2000` therefore aliases onto
DTCM word 0 — where the interrupt vector table lives. This is the single most important gap in the
supplied core.

---

## 2. MMIO map

**[REQ p5, §5]** GPIO without interrupt capability:

| Register | Address | Resolution | Direction | Note |
| --- | --- | --- | --- | --- |
| `PORT_LEDR` | `0x2000` | Byte | GPO | LEDR7–LEDR0 |
| `PORT_HEX0` | `0x2004` | Byte | GPO | |
| `PORT_HEX1` | `0x2005` | Byte | GPO | |
| `PORT_HEX2` | `0x2008` | Byte | GPO | |
| `PORT_HEX3` | `0x2009` | Byte | GPO | |
| `PORT_HEX4` | `0x200C` | Byte | GPO | |
| `PORT_HEX5` | `0x200D` | Byte | GPO | |
| `PORT_SW` | `0x2010` | Byte | GPI | SW7–SW0 |

**[REQ p6, §6]** Peripherals with interrupt capability:

| Register | Address | Resolution | Device |
| --- | --- | --- | --- |
| `PORT_PB` | `0x2014` | Byte | KEY[3-1] |
| `UTCL` | `0x2018` | Byte | USART |
| `RXBF` | `0x2019` | Byte | USART |
| `TXBF` | `0x201A` | Byte | USART |
| `BTCTL1` | `0x201C` | Byte | Basic Timer |
| `BTCTL2` | `0x201D` | Byte | Basic Timer |
| `BTCMPR0` | `0x2020` | Word | Basic Timer |
| `BTCMPR1` | `0x2024` | Word | Basic Timer |
| `BTCAPR` | `0x2028` | Word | Basic Timer |
| `IE` | `0x202C` | Byte | Interrupt Controller |
| `IFG` | `0x202D` | Byte | Interrupt Controller |
| `TYPE` | `0x202E` | Byte | Interrupt Controller |

**[REQ p5, §4] vs [REQ p5, §5]** §4 lists ten switches and ten red LEDs; §5 maps only SW7–SW0 and
LEDR7–LEDR0. Only eight of each are memory-mapped. Benign — the map is authoritative.

**[REQ p5, Figure 5]** The decoder structure. An `Optimized Address Decoder` takes
`Address<A13..A4, A3, A2>` and produces `CS_1 … CS_n`. HEX registers are paired on one chip select
and separated by `A0`: HEX0 (`0x2004`) on `Ā0` and HEX1 (`0x2005`) on `A0`, both on `CS6`. Each
output port is a `D-Latch D0..D7 / Q0..Q7` enabled by `CS_x · MemWrite`, followed by a
`7-segment encoder` for the HEX ports. `PORT_LEDR` is a latch on `CS1 · MemWrite`. `PORT_SW` drives
`Data<7..0>` through a tri-state buffer on `CS7 · MemRead` — which is why the data bus is
bidirectional, and why Figure 1 links to a bidirectional-bus reminder.

**[BENCH]** Every `io_map.s` in every benchmark suite defines exactly these twenty addresses with
exactly these values, including the GPIO suites, which never use the timer or interrupt registers.
Two naming differences: the spec writes `RXBF`/`TXBF`, the benchmarks write `RXBUF`/`TXBUF`; and
`UTCL` on p6 is titled `UCTL` in the register table on p12. Same registers.

**[BENCH]** `Intrrupt-based IO/test1/asm-code/01_func.s:17-20` performs `sw` to `0x2005`, a
non-word-aligned byte address. Sub-word MMIO stores are therefore mandatory, not optional.

### 2.1 What the twenty addresses imply about the decoder — Phase 5A

**[BENCH]** Grouped by word — the addresses being those of §5 and §6 above — the map has no ragged edges: the twenty registers occupy exactly
**twelve consecutive 32-bit words** and **no register straddles a word boundary**.

| SFR word | Byte address(es) | Register(s) | Mapped lanes |
| --- | --- | --- | --- |
| 0 | `0x2000` | `PORT_LEDR` | 0 |
| 1 | `0x2004` `0x2005` | `PORT_HEX0` `PORT_HEX1` | 0 1 |
| 2 | `0x2008` `0x2009` | `PORT_HEX2` `PORT_HEX3` | 0 1 |
| 3 | `0x200C` `0x200D` | `PORT_HEX4` `PORT_HEX5` | 0 1 |
| 4 | `0x2010` | `PORT_SW` | 0 |
| 5 | `0x2014` | `PORT_PB` | 0 |
| 6 | `0x2018` `0x2019` `0x201A` | `UTCL` `RXBUF` `TXBUF` | 0 1 2 |
| 7 | `0x201C` `0x201D` | `BTCTL1` `BTCTL2` | 0 1 |
| 8 | `0x2020` | `BTCMPR0` — Word | 0 1 2 3 |
| 9 | `0x2024` | `BTCMPR1` — Word | 0 1 2 3 |
| 10 | `0x2028` | `BTCAPR` — Word | 0 1 2 3 |
| 11 | `0x202C` `0x202D` `0x202E` | `IE` `IFG` `TYPE` | 0 1 2 |

**[DEC]** The chip-select index is therefore `addr(5 DOWNTO 2)` — the word offset itself — and no
lookup table is needed to produce the one-hot. This is exactly Figure 5's structure: one CS per word,
`A0` separating the pair that shares it. Two words carry three registers, so `A1` joins `A0` there.
Implemented in `DUT/RV32IMscMCU/ADDR_DECODER.vhd`; the map is data in `const_package.vhd`
(`SFR_LANE_MASK`).

**[DEC]** Totals, exhaustively checked by `TB/RV32IMscMCU/tb_addr_decoder.vhd`: **8192** DTCM
bytes, **29** mapped SFR bytes (17 byte registers + 3 word registers × 4 lanes), **8163** unmapped.

**[BENCH] The write path is not the DTCM's write path.** `GPIO/test0/asm-code/test0.s:21-28` is
`li t4,PORT_HEX1` then `sw t0,0(t4)` — a **word** store to byte address `0x2005`. Every MMIO write in
every supplied benchmark has this shape, odd addresses included, and
`Intrrupt-based IO/test1/asm-code/01_func.s:17-20` uses an `srli` to place the value in bits 7..0
before the `sw`. Two consequences:

1. On the I/O side `A1..A0` are the **register selector**, not an offset into the data being
   written. Figure 5 wires the latch inputs `D0..D7` to `Data<7..0>` unconditionally.
2. The MMIO write path must **not** reuse the lane replication and `byteena_a` of Phase 3B
   (`DMEMORY.vhd`). Those are correct for the DTCM and wrong for a peripheral. A byte-resolution
   peripheral takes `Data<7..0>`; a Word-resolution one takes `Data<31..0>`.

**[BENCH] The read path only needs eight bits.** All three MMIO reads in the benchmarks are
`lw` from `PORT_SW`, and each is immediately followed by `andi` against a mask
(`GPIO/test1/asm-code/test1.s:24-25` and `test2.s:24-25`). Figure 5 drives only `Data<7..0>` from the
`PORT_SW` tri-state. **Assumption:** the upper 24 bits read as zero. Harmless either way in every
supplied benchmark, because the mask discards them. **Falsified by** a program that uses the upper
bits of an MMIO read.

**[DEC] Full decode, not partial.** `A12..A6 = 0` is part of the qualifier, so `0x2040` does not
alias onto `0x2000`. Figure 2 calls the SFR page "distributed among many I/O devices, **not all
used**", so unused addresses exist by design and must not land on used ones; and an unmapped-access
report is only meaningful under a full decode. Cost is a 7-input zero-compare. If Phase 14 finds the
decoder on the critical path, dropping `A12..A6` is the cheapest concession — `A13` must never be
dropped, as that is the DTCM/SFR split itself.

**[REQ p5] vs [REQ p5, Figure 5] — the GPO ports: output-only, or readable?** Clause 5's table gives
`PORT_LEDR` and `PORT_HEX0`…`PORT_HEX5` a Direction of **GPO**. Figure 5, however, draws inside *each*
of the three output-port interface blocks it shows a tri-state buffer labelled with `MemRead` and that
block's chip select (plus `A0` / `Ā0` for the pair), driving `Data<7..0>` — i.e. a **read-back** path,
so a load from `0x2000` or `0x2004` should return the byte the port last stored.

**Assumption (A15):** the two are reconcilable — "GPO" describes the *device* (an output device)
rather than forbidding a readable register, and a read-back register is the ordinary
memory-mapped-I/O arrangement. Read-back is therefore treated as required and scheduled with the rest
of the read path in Phase 6B. **Nothing is blocked either way:** no supplied benchmark reads a GPO
port — the only MMIO reads anywhere in the benchmark suites are three `lw` from `PORT_SW`.
**Falsified by** course staff saying the seven output ports must not respond to a read at all, in
which case Phase 6B omits the read-back and `unmapped_o`'s meaning there needs deciding.

**Phase 6A implements the write side only**, and records that omission as the second of its two
deviations from Figure 5 — see the header of `DUT/RV32IMscMCU/GPO_PORT.vhd`. It was found by an
adversarial review of the phase, not by design.

**[DEC] Naming deviation, recorded.** Figure 5 labels its chip selects `CS1`, `CS6` and `CS7` for
`PORT_LEDR`, the `PORT_HEX0`/`PORT_HEX1` pair and `PORT_SW`. No arithmetic relation to the addresses
reproduces those three numbers, so the figure's numbering is treated as **illustrative** and the
constants are named after the registers instead. The figure's structure is implemented unchanged.

---

## 3. Basic Timer

**[REQ p7, Figure 7]** `BTCTL1` — 8-bit, byte address `0x201C`:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Field | BTOUTMD | BTOUTEN | BTHOLD | BTSSEL | BTSSEL | BTCLR | BTINT | BTINT |
| Access | rw | rw | rw | rw | rw | rw | rw | rw |

**[REQ p7, Figure 7]** The `BTSSEL` encoding, from the 4-to-1 clock multiplexer in Figure 7:

| `BTSSEL` | Timer clock |
| --- | --- |
| `00` | SMCLK |
| `01` | SMCLK ÷ 2 |
| `10` | SMCLK ÷ 4 |
| `11` | SMCLK ÷ 8 |

**[REQ p7, Figure 7]** `BTCTL2` — 8-bit, byte address `0x201D`:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Field | 0 | 0 | 0 | 0 | CAPMD | CAPMD | CAPISEL | CAPISEL |
| Access | r | r | r | r | rw | rw | rw | rw |

**[REQ p8]** `CAPISEL` selects `{0: CAPIN1 pin, 1: CAPIN2 pin, 2: VCC('1'), 3: GND('0')}`.
`CAPMD` selects `{0,3: capture disabled, 1: Rising edge, 2: Falling edge}`.

**[REQ p7]** `BTCMPR0` (`0x2020`), `BTCMPR1` (`0x2024`), `BTCAPR` (`0x2028`) are all 32-bit
word-addressed, bits 31..0, `rw`.

**[REQ p8]** `BTCCRx` and `BTCMPRx` are the same registers under two names. "BTCCR" appears only in
the p8 prose and never in any address table; the addressed names are authoritative.

**[REQ p7, Figure 7]** Datapath, top to bottom:
`BTCMPR0` and `BTCMPR1` each feed a `Latch BTCL0` / `Latch BTCL1` enabled by a signal drawn as
`HEU0='1'`. `BTCNT` is a **32-bit up-mode** counter with `EN` from `BTHOLD`, `CLK` from the `BTSSEL`
mux, reset from `BTCLR`, and a comparator output `EQU0`. `BTCL0`/`BTCL1` and `EQU0`/`EQU1` feed an
`Output Unit` gated by `BTOUTMD` and `BTOUTEN`, producing `PWMout`. The capture path is
`CAPISEL` mux (CAPIN1 / CAPIN2 / VCC / GND) → `Capture Mode` block → edge detector →
`BTCNT_CAPTURE on event register` → `BTCAPR`. A 4-position mux selected by `BTINT` chooses the
`BTIFG` source from `EQU0`, `EQU1` and the capture event.

**[REQ p8]** Modes. *Compare*: `BTCNT` compared to `BTCCR0`/`BTCCR1` for periodic interrupt
intervals. *Output Compare*: compared to `BTCMPR0` and `BTCMPR1` for PWM. *Input Capture*: `BTCNT`
captured on event into `BTCAPR`.

**[REQ p8, Figure 8]** Reference lines top to bottom are `BTR(max)`, `BTCL0`, `BTCL1`, `0h`. The
sawtooth rises to `BTCL0` and resets. Two output traces: `Output Mode0: Set/Reset` and
`Output Mode1: Reset/Set`, which are complements of each other. So **`BTCL0` is the period and
`BTCL1` is the duty threshold**, and `BTOUTMD` selects which polarity.

### 3.1 Verification 1 — every timer constant decodes. **PASS, 13/13.**

Each `.eqv` from every `io_map.s`, decoded against the layouts above.

| Constant | Value | Binary | Decodes to | Name says | |
| --- | --- | --- | --- | --- | --- |
| `BTHOLD_BTCLR` | `0x24` | `0010_0100` | BTHOLD=1, BTSSEL=00, BTCLR=1, BTINT=00 | BTHOLD + BTCLR | ✔ |
| `BTHOLD_BTSSEL3_BTCLR` | `0x3C` | `0011_1100` | BTHOLD=1, BTSSEL=11, BTCLR=1 | BTHOLD + BTSSEL3 + BTCLR | ✔ |
| `BTSSEL3` | `0x18` | `0001_1000` | BTSSEL=11, everything else 0 | BTSSEL3 | ✔ |
| `BTOUTEN_BTSSEL3` | `0x58` | `0101_1000` | BTOUTEN=1, BTHOLD=0, BTSSEL=11 | BTOUTEN + BTSSEL3 | ✔ |
| `BTINT2` | `0x02` | `0000_0010` | BTINT=10 = 2 | BTINT2 | ✔ |
| `BTHOLD_BTCLR_BTINT2` | `0x26` | `0010_0110` | BTHOLD=1, BTSSEL=00, BTCLR=1, BTINT=10 | BTHOLD + BTCLR + BTINT2 | ✔ |
| `CAPMD1_CAPISEL3` | `0x07` | `0000_0111` | CAPMD=01 (rising), CAPISEL=11 (GND) | CAPMD1 + CAPISEL3 | ✔ |
| `BTIE` | `0x04` | `0000_0100` | IE bit 2 | BTIE | ✔ |
| `KEY3IE_KEY2IE_KEY1IE` | `0x38` | `0011_1000` | IE bits 5,4,3 | KEY1/2/3 IE | ✔ |
| `KEY3IE_KEY2IE_KEY1IE_BTIE` | `0x3C` | `0011_1100` | IE bits 5,4,3,2 | + BTIE | ✔ |
| `KEY1IFG_MASK` | `0xFFF7` | `…1111_0111` | AND-clears IFG bit 3 | KEY1IFG | ✔ |
| `KEY2IFG_MASK` | `0xFFEF` | `…1110_1111` | AND-clears IFG bit 4 | KEY2IFG | ✔ |
| `KEY3IFG_MASK` | `0xFFDF` | `…1101_1111` | AND-clears IFG bit 5 | KEY3IFG | ✔ |

**Independently corroborated by the benchmark authors' own comments**, which spell out the field
assignments:

| Source | Comment |
| --- | --- |
| `test4/01_func.s:76` | `# BTCTL1=(BTHOLD=1,BTCLR=1)` for `0x24` |
| `test2/01_func.s:56` | `# BTCTL1=(BTHOLD=1,BTSSEL=3,BTCLR=1)` for `0x3C` |
| `test4/01_func.s:101` | `# BTCTL1=(BTHOLD=0,BTCLR=0,BTSSEL=3,BTINT=0)` for `0x18` |
| `test4/01_func.s:147` | `# BTCTL1=(BTOUTEN=1,BTHOLD=0,BTCLR=0,BTSSEL=3)` for `0x58` |
| `test4/01_func.s:158` | `# BTCTL1=(BTHOLD=1,BTCLR=1,BTSSEL=SMCLK,BTINT=2)` for `0x26` |

That last comment is decisive: `0x26` has `BTSSEL = 00`, and the author annotates it
`BTSSEL=SMCLK`. So `00` is SMCLK undivided, exactly as Figure 7's mux shows.

**Caution:** `0x3C` means two different things depending on the destination register —
`BTHOLD_BTSSEL3_BTCLR` when written to `BTCTL1`, `KEY3IE_KEY2IE_KEY1IE_BTIE` when written to `IE`.

### 3.2 Verification 2 — the frequency arithmetic. **FAIL. A real contradiction.**

**[BENCH]** The two timing constants, with the benchmarks' own annotations:

```
.eqv SEC_PERIOD  0x01312D00   # = 20,000,000   # in case of SMCLK=20MHz
.eqv FREQ_5K     0x000001F4   # = 500          # in case of SMCLK=20MHz
```

**[BENCH]** Which `BTSSEL` each is used with, read from the sources rather than assumed:

| Test | Sequence | `BTSSEL` | Constant | Claimed |
| --- | --- | --- | --- | --- |
| test2 | `01_func.s:54` writes `0x3C`, `:64` loads `SEC_PERIOD` → `BTCMPR0`, `:72` writes `0x18` | **3 (÷8)** | `SEC_PERIOD` | "interrupt period of 1sec" |
| test3 | identical to test2 | **3 (÷8)** | `SEC_PERIOD` | "interrupt period of 1sec" |
| test4 compare | `01_func.s:74` writes `0x24`, `:95` loads `SEC_PERIOD`, `:99` writes `0x18` | **3 (÷8)** | `SEC_PERIOD` | "interrupt period of 1sec" |
| test4 PWM | `:120` loads `FREQ_5K` → `BTCMPR0`, `:145` writes `0x58` | **3 (÷8)** | `FREQ_5K` | "PWM frequency=5KHz (for SMCLK=20MHz)" |

Both constants are used at the **same** `BTSSEL = 3`, so ÷8 applies to both. Working the arithmetic
at SMCLK = 20 MHz, timer clock = 2.5 MHz:

- `FREQ_5K`: 2,500,000 ÷ 500 = **5000 Hz exactly** ✔ matches its comment.
- `SEC_PERIOD`: 20,000,000 ÷ 2,500,000 = **8 seconds**, not 1 ✘ off by exactly 8×.

For `SEC_PERIOD` to give one second at `BTSSEL = 3`, SMCLK would have to be 160 MHz, which is not
achievable from a 50 MHz input on this device and contradicts the constant's own annotation. For it
to give one second, `BTSSEL` would have to be `0`.

So exactly one of these holds, and the material does not say which:

1. SMCLK = 20 MHz, the `BTSSEL` table is as Figure 7 draws it, and the benchmarks' "1sec" comments
   are simply wrong — the real period is 8 s. `FREQ_5K` stays correct.
2. The `BTSSEL` encoding is reversed (`11` → ÷1), making `SEC_PERIOD` correct and `FREQ_5K` wrong
   by 8× (40 kHz instead of 5 kHz).

**[DEC]** We implement reading 1: Figure 7's table as drawn, `00` → ÷1 through `11` → ÷8. Three
independent things support it — the Figure 7 mux labels, the author's own `BTSSEL=SMCLK` comment on
value `00`, and `FREQ_5K` resolving exactly. Only the "1sec" prose comments contradict it, and
comments are the weakest evidence in the set.

**Assumption:** SMCLK = 20 MHz. Nothing in the specification states any frequency (see §6).
This is derived solely from `FREQ_5K` resolving exactly at ÷8, and from the benchmarks' own
`# in case of SMCLK=20MHz` annotations. **Falsified by** course staff stating a different SMCLK, in
which case `FREQ_5K` stops being 5 kHz and the whole derivation must be redone.

Raised as open question 2. It does not block: the timer implements the specified table, behaviour is
deterministic, and the 8× discrepancy is a property of the supplied benchmark rather than of our
RTL.

---

## 4. Interrupt controller

**[REQ p14]** `IE`, Interrupt Enable Register — byte address `0x202C`:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Field | 0 | 0 | KEY3IE | KEY2IE | KEY1IE | BTIE | TXIE | RXIE |
| Access | r-0 | rw | rw | rw | rw | rw | rw | rw |

`IEx`: 0 = interrupt not enabled, 1 = interrupt enabled.

**[REQ p14]** `IFG`, Interrupt Flag Register — byte address `0x202D`:

| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Field | 0 | 0 | KEY3IFG | KEY2IFG | KEY1IFG | BTIFG | TXIFG | RXIFG |
| Access | r-0 | rw | rw | rw | rw | rw | rw | rw |

`IFGx`: 0 = no interrupt pending, 1 = interrupt pending.

**[REQ p14]** `TYPE`, Interrupt Type Register — byte address `0x202E`. Bits 7:6 are `0`, read-only;
bits 5:0 are `TYPEx`, read-only.

**Cross-check:** these layouts were derived independently from the benchmark masks in §3.1 before
the PDF pages were read, and the two agree bit for bit. `BTIE = 0x04` → bit 2; `0x38` → bits 5,4,3;
`0xFFF7`/`0xFFEF`/`0xFFDF` → clear bits 3/4/5.

**[REQ p14]** Interrupt vector table:

| Source | Flag | TYPE | System interrupt | Priority |
| --- | --- | --- | --- | --- |
| RESET | — | `00h` | NMI | 0, highest |
| UART status error | RXIFG | `04h` | maskable | 1 |
| UART RX | RXIFG | `08h` | maskable | 2 |
| UART TX | TXIFG | `0Ch` | maskable | 3 |
| Basic Timer | BTIFG | `10h` | maskable | 4 |
| Pushbutton 1 | KEY1 | `14h` | maskable | 5 |
| Pushbutton 2 | KEY2 | `18h` | maskable | 6 |
| Pushbutton 3 | KEY3 | `1Ch` | maskable | 7, lowest |

**[REQ p13]** Clearing rules, verbatim:

- a. `BTIFG` is reset automatically when the interrupt is serviced.
- b. `RXIFG` is automatically reset if the pending interrupt is served or when `RXBUF` is read.
- c. `TXIFG` is automatically reset if the interrupt request is serviced or if a character is
  written to `TXBUF`.
- d. `KEYiIFG` is reset manually with software (`BTIFG`, `RXIFG`, `TXIFG` as well).
- e. As part of the CPU servicing an interrupt, `GIE` is cleared *in HW* — DINT of other interrupts.
- f. Symmetrically, as part of the CPU returning from interrupt, `GIE` is set *in HW* — EINT, back
  to the original state.

**[REQ p13, diagram]** Structure. The controller sits on the Control / Address / Data buses with a
`CS` input and interrupt-source inputs `IS0 … ISn`, drives `INTR` to the CPU and receives `INTA`
from it — both `CS` and `INTA` drawn active-low.

Per source: a D flip-flop with `D` tied to `"1"`, **clocked by the interrupt source `IS`** and
asynchronously cleared by `clr_irq`, with an "interrupt done" feedback path into that clear. So each
flag is a set-only latch triggered by the source's edge — this is exactly the KEY edge-latch
behaviour, and no separate edge detector is drawn.

Per the multi-source diagram, the flop outputs form the **IFG register** directly, and each
`irq_n AND eint_n` product feeds an OR tree whose output is ANDed with `GIE` to produce `INTR`.

**Assumption:** `IFG` holds the **raw latched** flag and `IE` masks only the path toward `INTR`.
The single-source diagram labels the `irq AND eint` output `IFGx`, which would instead make `IFG`
the masked value; the multi-source diagram contradicts it by bracketing the flop outputs as "the IFG
Register". We follow the multi-source reading because the benchmarks read and clear `IFG` bits
independently of `IE`. **Falsified by** a benchmark that reads `IFG` and expects a masked value.

### 4.1 Verification 4 — every TYPE value has a vector. **PASS.**

`TYPE` is a byte offset into the DTCM vector table, so `TYPE / 4` is the word index. Words 0–7 of
each benchmark's DTCM image:

| TYPE | Word | test1 | test2 | test3 | test4 |
| --- | --- | --- | --- | --- | --- |
| `00h` RESET | 0 | `00000000` | `00000000` | `00000000` | `00000000` |
| `04h` UART error | 1 | `00000200` | `0000011c` | `0000017c` | `00000234` |
| `08h` UART RX | 2 | `00000200` | `0000011c` | `0000017c` | `00000234` |
| `0Ch` UART TX | 3 | `00000204` | `00000120` | `00000180` | `00000238` |
| `10h` Basic Timer | 4 | `000001fc` | `00000104` | `00000164` | `000001f8` |
| `14h` KEY1 | 5 | `00000160` | `00000068` | `00000080` | `00000138` |
| `18h` KEY2 | 6 | `00000194` | `0000009c` | `000000cc` | `00000178` |
| `1Ch` KEY3 | 7 | `000001c8` | `000000d0` | `00000118` | `000001b8` |

Every entry is word-aligned and inside the ITCM extent. The RESET vector is `0` in all four,
consistent with **[REQ p3]** "KEY0 as a System RESET (brings the PC to the first program
instruction)".

**This resolves the `RXIFG` ambiguity in practice.** TYPE `04h` and `08h` hold the *same* handler
address in all four benchmarks, so the two UART sources vector to one routine that distinguishes
error from data by reading `UCTL`. The hardware still has to pick which TYPE value to present, but
the choice cannot change program behaviour in any supplied benchmark. Open question 4 is therefore
non-blocking.

### 4.2 The service protocol

**[REQ p15]** At the next clock cycle after `INTR` is set to `'1'` by the controller, the CPU sets
`INTA` to `'0'`. At that point, before the service process starts, the next PC address is the
**interrupt return address**.

Entry — latency **two cycles**, triggered by the **falling edge of `INTA`**:

*Cycle 1*
- Clear `GIE` (bit `gp[0] = 0`)
- Set `INTA` (`INTA = '1'`)
- Write the content of register `TYPE` onto the Data BUS and capture it in a dedicated register.
  **[REQ p15]** notes it cannot go on the Address BUS, because the CPU is the only bus master.

*Cycle 2*
- If the pending `TYPE` interrupt is a synchronous source, clear its flag (like `BTIFG`)
- Emulate execution of `load` (of the `TYPE` content) and `jalr` (to `Mem[TYPE]` content), with
  `R[tp]` = interrupt return address

Return — latency **one cycle**: as part of executing `jalr zero, 0(tp)` (`reti`), set `GIE`
(bit `gp[0] = 1`).

**[BENCH]** The software side of the contract:
`Intrrupt-based IO/*/asm-code/io_map.s` defines `.eqv reti  jalr zero,0(tp)`, and
`test1/asm-code/00_main.s:77` is `ori gp,gp,0x01   # EINT, GIE=gp[0]=1`.

So `INTA` is idle-high, pulses low for exactly one cycle as the trigger, and is driven high again in
Cycle 1.

---

## 5. Division accelerator

**[REQ p9, Figure 9]** Datapath: a `Dividend left shift-register` loaded via `Load` and shifting
`'0'` in at the LSB; a `Divisor register`; a `Subtractor` computing `Result = Y − X` with a
`Non-negative Result` feedback that also drives the quotient bit; and a
`Quotient left shift-register`. Outputs are `Residue` and `Quotient`.

Control signals: `DIVCLK`, `DIVRST`, `DIVENA` in; `DIVBUSY` out.

**[REQ p9]** Operand and result registers `DIVIDEND`, `DIVISOR`, `QUOTIENT`, `RESIDUE`, all 32-bit,
bits 31..0.

**[REQ p9]** "The divider results are ready after N DIVCLK cycles after loading a value to the
second operand DIVISOR, i.e., 32 DIVCLK cycles (**fast clock**) in our case of N=32."

So **writing `DIVISOR` starts the operation**, and the count is 32 cycles of the fast clock.

**[REQ p4, Figure 3]** The integration. `Control Unit` gains `PCHold` and `DIVbusy` as inputs and
`DIVstart` as an output; a `Divider Accelerator 32-bit` block takes `Ain`/`Bin` and produces
`Quotient`/`Rem`, clocked by `divclk`, preceded by a `Sync` block also on `divclk`; and the
write-back mux is widened, selected by `WBSrc1`/`WBSrc0`.

**Assumption:** `DIVIDEND`, `DIVISOR`, `QUOTIENT` and `RESIDUE` are **core-internal**, not
memory-mapped. They are given register diagrams on p9 but appear in neither MMIO table, and
Figure 3 wires them to the ALU operands rather than to the data bus. **Falsified by** course staff
assigning them SFR addresses. Raised as open question 6.

**Third piece of evidence for the same reading, added 2026-08-24.** Figure 10b labels the two
synchroniser inputs `Read data1` and `Read data2` — which are this project's own register-file read
port names (`read_data1_o` / `read_data2_o` in `IDECODE.vhd`). So the operands enter the divider
domain straight from the register file, not from the data bus. Together with Figure 3 wiring
`Ain`/`Bin` to the ALU operands, that is two figures pointing the same way and none pointing the
other. Q6 still wants a confirmation, but the provisional answer is now well supported.

**[REQ p10, Figures 10a/10b]** The CDC rule and its exact structure, read off the figures rather
than inferred from the prose. **Three flip-flops, not two.**

Figure 10a draws the complete crossing:

| Domain | Contents | Clock |
| --- | --- | --- |
| A (slow) | `Comb logic` → one `D Q` | `MCLK` |
| B (fast) | `Din` → `D Q` → `Ds` → `D Q` → `Dout` "stable" | `DIVCLK`, both stages |

The accompanying waveform names the interval between `Din` and `Ds` the **"Metastable phase"** and
the point after `Dout` settles **"Stable Output"**.

The page 10 prose makes the domain-A register mandatory, not optional: *"It's fundamental to have a
flip-flop to synchronize every signal that is driven by combinational logic (combo) in domain A
before sending it to domain B through the synchronizer. In domain B, we must register the input to
avoid metastability caused by violating the fast clock-domain B regime."*

Figure 10b then draws the block as the divider instantiates it — a `Sync` box clocked by `divclk`,
containing **two independent two-DFF chains**:

```
Read data1 -> [DFF] -Ds-> [DFF] -> Ain
Read data2 -> [DFF] -Ds-> [DFF] -> Bin
```

**Assumption, and it is a real one.** A two-stage synchroniser on a *multi-bit bus* is only sound
when the bus is stable across the crossing: individual bits can resolve on different destination
cycles, so a bus that changes mid-sample can present a value that never existed on the source side.
Figure 10b applies it to two 32-bit operands regardless. For the divider that is sound, because the
CPU writes `DIVIDEND` and `DIVISOR` and only then does the enable cross — the operands are
quasi-static by the time they matter. **Falsified by** any later use where the data can change while
being sampled; such a crossing needs a handshake or a gray code, not this block.
**Implemented and tested:** `DUT/RV32IMscMCU/SYNC.vhd`, `TB/RV32IMscMCU/tb_sync.vhd`. Gap G-310.

Neither figure draws a reset. One is added anyway — a synchroniser chain starting at `'U'` propagates
unknowns into the divider for two cycles — and it is sampled in the **destination** domain, since a
reset released in the source domain would itself be an unsynchronised crossing.

---

## 6. Clocks

**[REQ p3, Figure 1]** `baseclk50MHz → Clock Tree → mclk, accelclk, smclk`. Three named clocks:
`mclk` to the RISC-V core, `smclk` to the peripherals, `accelclk` to the accelerator.

**[REQ p16]** The PPA performance table's third column is `f_MCLK (= f_sysclk)`, so `mclk` is the
system clock the tables report.

**[REQ p7, Figure 7]** The Basic Timer's `BTSSEL` mux input is `SMCLK`.

**[REQ p9]** The divider's `DIVCLK` is "fast clock" — corresponding to `accelclk`.

**No numeric frequency is stated anywhere in the specification** except the string `baseclk50MHz`
inside the Figure 1 image. Verified by searching the whole document.

**[CODE]** `cond_compilation_package.vhd:58-59` sets `G_PLL_DIV = 2`, `G_PLL_MUL = 1`, giving
50 ÷ 2 = **25 MHz**, and both Lab 5 SDC files document 25 MHz.

**[CODE]** `Auxilary/QUARTUS/SDC/RISCV_simple.sdc` constrains the *input port* at 50 MHz —
`create_clock -name clk -period 20 [get_ports {clk_i}]` — and then `derive_pll_clocks
-create_base_clocks`, letting the tool derive the PLL outputs.

**[BENCH]** `SEC_PERIOD` and `FREQ_5K` are both annotated `# in case of SMCLK=20MHz`, and `FREQ_5K`
resolves exactly at 20 MHz ÷ 8 (see §3.2).

**[CODE]** All three ALTPLL copies in the material expose only `c0`. A three-output clock tree
requires regenerating the megafunction.

**[DEC]** Target `SMCLK = 20 MHz`. **Assumption:** `MCLK = SMCLK = 20 MHz` unless course staff say
otherwise. **[REC]** 20 MHz also buys timing headroom the design needs: the single-cycle core closes
at only 26.81 MHz *before* any peripheral is added, and the MMIO decoder lands in its critical path.
**Falsified by** course staff specifying `MCLK ≠ SMCLK`, or by a required `f_MCLK` above 20 MHz.

**Assumption:** `ACCELCLK = 50 MHz`, the undivided board clock, since §6.iii calls `DIVCLK` the fast
clock and 50 MHz is the only faster clock available. **Falsified by** timing closure failing at
50 MHz for the divider, or by a stated value.

---

## 7. IPC and validation instrumentation

**[REQ-L5 p8, clause 6.iii.b]** The IPC equation the final-project document references but does not
contain:

```
IPC = ( CLKCNT_o − ( STCNT_o + 4 + depth · FHCNT_o ) ) / CLKCNT_o
    = InstructionCounter / CLKCNT_o                        where IPC = 1/CPI
```

**[REQ-L5 p8, clause 6.iii.a]** `SignalTap trigger = ( IF_pc == BPADDR_i )`

**[REQ-L5 p8]** SignalTap capacity:
`STdepth = ( Embedded memory size − Design usage memory size ) / #ST channels`

**[REQ-L5 p8]** `STCNT_o` is an 8-bit stall counter, cleared on reset, counting on the rising edge
when a stall occurs. `FHCNT_o` is an 8-bit flush counter, same conditions. `BPADDR_i` is an 8-bit
breakpoint address of **word granularity**, cleared on reset, fed by SW7–SW0.

> **The submitted design deliberately exceeds this width, and it had to.** The revised pipeline
> declares `STCNT_WIDTH` and `FHCNT_WIDTH` as **16**
> (`Auxiliary/Lab 5 - as submitted/DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd`), because test3 and
> test4 produce roughly 298 and 304 flushes — an 8-bit counter wraps at 255 and the IPC equation
> would then be computed from a wrapped value. `DOC/HANDOVER_Report_lab5.md` §4.3 records the change.
>
> This is a **design decision, not a requirement**, and the report must say so rather than presenting
> 16 bits as what p8 asked for. Our wrapper follows the implementation at 16 bits.
>
> A related change in the same revision: `STCNT` now increments only when `stall = '1' AND
> flush = '0'` (§4.4). A stall coinciding with a MEM redirect is moot — the flush already costs
> `depth = 3` in the IPC equation — so counting it would double-charge. `Auxilary/Ori/` counts
> unconditionally (`RV32IM_CORE.vhd:558`) and is the counter-example.

**[REQ-L5 p7]** Conditional branches and unconditional jumps are resolved in **pipeline stage 4**.

**[REQ p17, §8.c.iii and §8.e.iii]** Both reference "clause 6.iii.b". **That clause does not exist
in the final-project document** — its §6.iii is the divider diagram and has no lettered sub-items.
The equation is in the LAB5 PDF. Recorded so nobody hunts for it again.

**[REQ p17, §8.c.i]** ModelSim golden comparison: RARS `DTCM.h` against ModelSim `DTCM.mem`.
**[REQ p17, §8.e.i]** ISMCE golden comparison: RARS `DTCM.hex` against ISMCE `DTCM.hex`.

**[BENCH]** This is why the two image formats differ and must not be interchanged. `bin/M9K-intel/*.hex`
uses `auipc imm = 0x00000` (text base 0) and is the ITCM source; `bin/Hexadecimal-Text/ITCM.h`
retains RARS's `0x3000` base and is **not** loadable. The `.h` files are the DTCM golden text, which
is exactly what §8.c.i asks for.

---

## 8. Verification 3 — the MMIO map is bijective. **PASS.**

- Every one of the twenty addresses in §5 and §6 appears in every `io_map.s`, with the same value.
- Every address any `io_map.s` defines appears in §5 or §6. No extras.
- The GPIO suites define the timer and interrupt-controller addresses too, even though they never
  use them — so all seven `io_map.s` files carry the identical canonical map.

Only naming differs: `RXBF`/`TXBF` (spec) vs `RXBUF`/`TXBUF` (benchmarks), and `UTCL` (p6 map) vs
`UCTL` (p12 register table).

---

## 9. Submission

**[REQ p18, §10.8]** `id1_id2.zip` with `id1 < id2`, uploaded to Moodle only by the student with
`id1`. Any violation disqualifies the submission. Here: `209580208_211468582.zip`, uploaded by
209580208.

**[REQ p18, Table 1]** The ZIP contains "the next six subdirectories (only the exact next sub
folders)" — above a table listing **five**: `DUT`, `TB`, `SIM`, `DOC`, `Quartus`.

**[REQ-L5 p10, §9.g]** The LAB5 document uses the *identical* wording — "the next six
subdirectories" — above a table listing the same five. Lab 5 was submitted with five and accepted.

**[DEC]** Five directories. The word "six" is an inherited typo, and the precedent is direct.

**[REQ p18]** Subfolder names for this project are `RV32IMscMCU` and `RV32IMpipelinedMCU` — *not*
Lab 5's `RV32IM_sc` / `RV32IM_pipeline`. Testbench filenames `tb_RV32IMscMCU.vhd` and
`tb_RV32IMpipelinedMCU.vhd`. `DOC` holds `Readme.txt` and `Final_report.pdf`. `Quartus` holds a
SignalTap file, an SDC file and a SOF file per design, and "Do not place files that are not relevant
for compilation or a result of compilation!"

**[REQ p17, §10]** The prose says the report is `final.pdf`; Table 1 says `Final_report.pdf`.
**[DEC]** `Final_report.pdf`, matching the table, which is the more specific statement. Open
question 7.

---

## 10. Assumption register

Everything in this document that is not cited to a source.

| # | Assumption | Basis | Falsified by |
| --- | --- | --- | --- |
| A1 | `SMCLK = 20 MHz` | `FREQ_5K` resolves exactly at ÷8; benchmark annotations | A stated SMCLK |
| A2 | `MCLK = SMCLK` | No statement to the contrary; simplest tree | A stated `f_MCLK` |
| A3 | `ACCELCLK = 50 MHz` | §6.iii calls DIVCLK the fast clock; 50 MHz is the only faster clock | Timing closure failure, or a stated value |
| A4 | `BTSSEL` is `00`→÷1 … `11`→÷8 as Figure 7 draws it | Figure 7 mux labels; the `BTSSEL=SMCLK` author comment on `0x26`; `FREQ_5K` resolving exactly | Course staff reversing it — but then `FREQ_5K` breaks |
| A5 | The benchmarks' "1sec" comments are wrong, not the `BTSSEL` table | Three-to-one evidence, §3.2 | Course staff confirming a 1 s period at `BTSSEL=3` |
| A6 | `IFG` holds the raw latched flag; `IE` masks only toward `INTR` | The multi-source diagram brackets the flop outputs as the IFG register; benchmarks clear `IFG` independently of `IE` | A benchmark reading a masked `IFG` |
| A7 | Divider operand/result registers are core-internal | Absent from both MMIO tables; Figure 3 wires them to ALU operands | An assigned SFR address |
| A8 | Five submission directories, not six | LAB5 uses identical wording and was accepted with five | Course staff naming a sixth |
| A9 | `Final_report.pdf` | Table 1 is more specific than the prose | Course staff preferring `final.pdf` |
| A10 | Board is DE2-115 | All Lab 5 material and the students' own hardware runs target it | Course staff naming DE10-Standard |
| A11 | The upper 24 bits of an MMIO read return zero | Figure 5 drives only `Data<7..0>` from the `PORT_SW` tri-state; all three MMIO reads in the benchmarks `andi` the result immediately | A program that uses the upper bits of an MMIO read |
| A12 | A Word-resolution register owns all four lanes of its word | §6's table gives `BTCMPR0`/`BTCMPR1`/`BTCAPR` Address Resolution "Word", and `io_map.s` marks them "define a Word address" | A byte-resolution use of any of those three |
| A13 | A GPO port holds zero after reset — LEDs off, every HEX showing `0` | Nothing states a reset value and Figure 5 draws no reset on the latch at all; zero needs no extra state, whereas "blank until first written" needs a flag nothing asks for | Any statement that the displays should be dark after KEY0 |
| A15 | The seven GPO ports are readable (Figure 5's `MemRead` tri-state), despite clause 5's Direction column saying `GPO` | Figure 5 draws the buffer inside every output-port block; a read-back register is the ordinary MMIO arrangement, and "GPO" plausibly describes the device | Course staff saying an output port must not respond to a read |
| A14 | A `PORT_HEXn` register is 8 bits wide and the display decodes bits 3..0 | Figure 5 draws `D0..D7` into the latch and a 7-segment encoder after it; `Intrrupt-based IO/test1/asm-code/01_func.s:17-20` masks and `srli`s the digit into bits 3..0 before storing | A program that expects the upper nibble to affect the display |

Fifteen assumptions. None blocks Step 2. A1, A2, A4 and A5 must be settled before the Basic Timer
(roadmap Step 9) is verified against real constants; A10 before pin planning. A11 and A12 came out of
Phase 5A and are both exercised by `TB/RV32IMscMCU/tb_addr_decoder.vhd`, so if either is wrong the
change is one line in `const_package.vhd` and the exhaustive sweep re-proves the whole map. A13 and
A14 came out of Phase 6A; both are one line in `GPO_PORT.vhd` or in the `SEGGEN` generate of
`RV32IMscMCU.vhd`, and `tb_gpio.vhd` re-proves the display path either way. **A15 is the one to send
Hanan** — it is a genuine contradiction between clause 5's table and Figure 5, not an ambiguity, and
it decides whether Phase 6B builds seven read-back paths or none.
