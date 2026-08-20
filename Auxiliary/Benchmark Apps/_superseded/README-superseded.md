# Superseded benchmark revision

`Interupt-based IO/` here is the **older** revision of the interrupt-based-IO benchmark suite,
the one that was imported with the initial project on 2026-08-19 20:32.

It is superseded by `../Intrrupt-based IO/`, a newer revision supplied later on 2026-08-19.
Note the folder-name spelling differs between the two revisions — that is the course
material's own spelling in each case, not a rename by us.

Kept verbatim, unmodified, because the rules treat a supplied benchmark as a contract:
a defect claim about the old revision must remain checkable against the old files.

## Content differences between the two revisions

Only 9 files differ in content. The other 59 differ only by CRLF vs LF line endings.

### `test4/asm-code/01_func.s` — two defects fixed

| | old (here) | new (`../Intrrupt-based IO/`) |
| --- | --- | --- |
| loop guard, `for_l` and `for_l1` | `blt t4,a3,endfor_l` | `bge t4,a3,endfor_l` |
| loop back edge | *absent* | `j for_l` / `j for_l1` added |

In the old revision `blt` exits on the first iteration when `t4 < a3`, and there is no
back edge, so both the `div` and the `rem` array loops execute zero times. Fixed in the
new revision.

### `test1/asm-code/00_main.s` — one instruction added

`mv fp,zero  # goto idle state` inserted before `j END`.

This shifts all following code by one word, so `test1`'s interrupt vector table in
`bin/*/DTCM.*` was regenerated: every handler address moved +4.

### `test4/asm-code/00_main.s`

Whitespace only.

### Regenerated memory images

`test1/bin/{Hexadecimal-Text,M9K-intel}/{ITCM,DTCM}.*` and
`test4/bin/{Hexadecimal-Text,M9K-intel}/ITCM.*` were rebuilt to match the sources above.
`test4`'s DTCM images are unchanged, which is consistent — only `test4` code changed.

## Defect that survives into the new revision

`test4/asm-code/01_func.s` still never flips the capture input:

```asm
capture_init:
	li t0,CAPMD1_CAPISEL3   # capture on rising-edge event, set the input signal to GND
	sw t0,0(t6)             # BTCTL2 = 0x07
capture:
	li t0,CAPMD1_CAPISEL3   # set the input signal to VCC
	sw t0,0(t6)             # BTCTL2 = 0x07  <-- same value
```

`io_map.s:40` defines `CAPMD1_CAPISEL3 = 0x07`. Both writes store the same value, so the
selected capture source stays at whatever `CAPISEL = 3` means and no edge is ever produced.
Per the project definition, `CAPISEL` selects `{0: CAPIN1, 1: CAPIN2, 2: VCC, 3: GND}` and
`CAPMD` selects `{0,3: disabled, 1: rising, 2: falling}` — so the comments describe the
intent (GND then VCC, giving one rising edge) but the code does not implement it.

**Derived, not stated in the material:** if `CAPISEL` occupies bits [1:0] and `CAPMD`
bits [3:2], then `0x07 = 0b0111` is `CAPMD=1, CAPISEL=3` — matching the `capture_init`
comment exactly — and the value the `capture` comment intends would be `0x06`
(`CAPMD=1, CAPISEL=2` = VCC). The bit positions are not given anywhere in the supplied
material, so this layout is an inference from the two comments, not a specification fact.

Do not change the supplied source. Raise it with course staff, and if a corrected copy is
needed for verification, keep it separate and clearly marked.
