# ModelSim Testing Guide — Single-Cycle RV32IM (Part 1)

Step-by-step procedure for verifying the design with benchmarks **test1–test4**,
using only ModelSim menus and buttons (no transcript window).

**The idea of every test:** the core runs a compiled C benchmark from the ITCM.
When the program reaches its final `while(1)` loop, the data memory (DTCM)
holds all computed results. We export the DTCM to `DTCM.mem` and compare it
word-for-word against the golden output produced by RARS (the official RISC-V
simulator) for the same program. A perfect match proves the core — including
the new `mul` instruction — executes the program correctly.

**File locations used by this guide** (already prepared):

```
C:\TestPrograms\Quartus21_1\
  app_bin\                      <- the core ALWAYS loads ITCM.hex + DTCM.hex from here
  test1\..test4\
    bin\ITCM.hex, DTCM.hex      <- input images of each benchmark
    RARS\DTCM.h                 <- golden result of each benchmark (plain hex text)
```

The design files load memory with an absolute path
(`init_file => "C:\TestPrograms\Quartus21_1\app_bin\..."` in `IFETCH.vhd` and
`DMEMORY.vhd`), so **whatever sits in `app_bin` when the simulation loads is the
program that runs**.

---

## Part A — One-time setup (do once)

### A.1 Set the working directory

1. Open ModelSim (20.1 / `modelsim_ase`).
2. **File → Change Directory...** → select `Lab5\SIM\RV32IM_sc`.
   All simulation products (`work` library, `wave.do`, `DTCM.mem`) live here.

### A.2 Create `compile.do`

1. **File → New → Source → Do** — an empty editor tab opens.
2. Type the following, then **File → Save As...** → `compile.do` (into `SIM\RV32IM_sc`):

```tcl
# compile.do - compile the RV32IM_sc design + testbench
vlib work
vmap work work

# packages first - everything depends on them
vcom -2008 ../../DUT/RV32IM_sc/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IM_sc/const_package.vhd
vcom -2008 ../../DUT/RV32IM_sc/aux_package.vhd

# multiplier, submodules, top, testbench
vcom -2008 ../../DUT/RV32IM_sc/MUL16.vhd
vcom -2008 ../../DUT/RV32IM_sc/CONTROL.vhd
vcom -2008 ../../DUT/RV32IM_sc/IFETCH.vhd
vcom -2008 ../../DUT/RV32IM_sc/IDECODE.vhd
vcom -2008 ../../DUT/RV32IM_sc/EXECUTE.vhd
vcom -2008 ../../DUT/RV32IM_sc/DMEMORY.vhd
vcom -2008 ../../DUT/RV32IM_sc/PLL.vhd
vcom -2008 ../../DUT/RV32IM_sc/RV32IM_CORE.vhd
vcom -2008 ../../TB/RV32IM_sc/tb_RV32IM_sc.vhd
```

Notes:
- `-2008` is mandatory: `EXECUTE.vhd` uses `process(all)` and the top uses
  `if/else generate` (VHDL-2008 features).
- Compile order matters — packages must be compiled before the files that use them.

### A.3 Create `mem_dump.do`

**File → New → Source → Do**, type, save as `mem_dump.do`:

```tcl
# mem_dump.do - export DTCM words 0..1023 to DTCM.mem,
# one bare hex word per line (same format as the RARS golden DTCM.h)
mem save -format mti -data hex -addr decimal -wordsperline 1 \
    -startaddress 0 -endaddress 1023 \
    -outfile DTCM_raw.mem /tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a

set fin  [open DTCM_raw.mem r]
set fout [open DTCM.mem w]
while {[gets $fin line] >= 0} {
    if {[string match "//*" $line] || [string trim $line] eq ""} { continue }
    puts $fout [string toupper [string trim [lindex [split $line ":"] end]]]
}
close $fin
close $fout
file delete DTCM_raw.mem
echo "DTCM.mem written"
```

(`mem save` is exactly what **File → Export → Memory Data...** does; the loop
only strips the header and address column so the file diffs cleanly against
the golden `DTCM.h`.)

### A.4 Create `run_test.do`

**File → New → Source → Do**, type, save as `run_test.do`:

```tcl
# run_test.do - edit N to choose the benchmark, then run this macro
set N 1

# load the benchmark images into app_bin (Tcl needs forward slashes)
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns work.tb_rv32im_sc
do wave.do

# stop automatically when the program reaches its final while(1) self-jump:
# beq x0,x0,0 (0x00000063, man_compiled tests) or jal x0,0 (0x0000006F, gcc).
# Values are written as 32-bit binary strings (that is how "when" compares a
# VHDL bus). The 5 ms bound only catches a runaway (bug) case.
onbreak {resume}
when {/tb_rv32im_sc/instruction_o == "00000000000000000000000001100011" OR /tb_rv32im_sc/instruction_o == "00000000000000000000000001101111"} {
    echo "Program finished (while(1) reached) at $now ns"
    stop
}
run 5 ms
do mem_dump.do
```

How the ending works: `when {...} {stop}` is a signal-value breakpoint — the
first time the fetched instruction equals the self-jump encoding (which only
happens when the program enters `while(1)`), the run stops **exactly at
completion**. `onbreak {resume}` lets the macro continue to `mem_dump.do`
after the stop. A bonus of stopping exactly on time: `mclk_cnt_o` shows the
true cycle count of the program, not inflated by idle spinning in the loop.

### A.5 Compile

1. **Tools → Tcl → Execute Macro...** → select `compile.do` → Open.
2. Expected: **0 errors**. Three warnings on `EXECUTE.vhd`
   ("Non-locally static OTHERS choice") are known and harmless.
3. Recompiling is only needed after editing VHDL files — switching benchmarks
   does **not** require recompiling (memories are read when the simulation loads).

### A.6 Create `wave.do` (ModelSim writes it from your clicks)

1. **Simulate → Start Simulation...** → expand `work` → select `tb_rv32im_sc`
   → **Resolution: ns** → OK.
   (If internal signals are missing later: in this dialog use
   **Optimization Options... → Apply full visibility to all modules**.)
2. In the **sim** (Structure) pane you see the hierarchy:
   `tb_rv32im_sc` → `CORE` → `IFE`, `ID`, `CTL`, `EXE` (contains `MUL`), `MEM`.
3. Click an instance; its signals appear in the **Objects** pane.
   Select signals (Ctrl-click) → **right-click → Add Wave**. Add:

   | From | Signals |
   |---|---|
   | `tb_rv32im_sc` | `clk_i`, `rst_i`, `mclk_cnt_o`, `pc_o`, `instruction_o`, `RegWrite_ctrl_o`, `MemWrite_ctrl_o`, `Branch_ctrl_o`, `read_data1_o`, `read_data2_o`, `write_data_o`, `alu_res_o`, `brTaken_o`, `dtcm_addr_o`, `dtcm_data_wr_o`, `dtcm_data_rd_o` |
   | `CORE/CTL` | `ALUOp_ctrl_o`, `mul_w`, `Jal_ctrl_o`, `Jalr_ctrl_o` |
   | `CORE/EXE/MUL` | `a_i`, `b_i`, `res_o` |
   | `CORE/ID` | `RF_q` (whole register file, expandable) |

4. Readability: select all in the Wave window (Ctrl+A) →
   **right-click → Radix → Hexadecimal**; set `mclk_cnt_o` to Unsigned and
   `pc_o` to Hexadecimal. Optionally **right-click → Group...** related signals
   (TOP / CONTROL / MUL16 / REGFILE).
5. With the Wave window active: **File → Save Format...** → save as `wave.do`
   in `SIM\RV32IM_sc`.
6. **Simulate → End Simulation** (we will reload per test).

---

## Part B — Per-test procedure (repeat for test1, test2, test3, test4)

### B.1 Run

1. Open `run_test.do` in the ModelSim editor (**File → Open...**),
   change the first line to the wanted test (`set N 1` ... `set N 4`), save.
2. **Tools → Tcl → Execute Macro...** → `run_test.do`.
   It copies the benchmark into `app_bin`, loads the testbench, applies your
   wave format, runs until the program reaches `while(1)` (auto-stop via the
   `when` breakpoint) and exports `DTCM.mem`.

### B.2 Confirm the program finished

1. Check the transcript's last lines show
   **"Program finished (while(1) reached) at ... ns"** — the auto-stop fired.
   (test1 stops at ~13.4 us; tests 2-4 take longer.)
2. In the Wave window click **zoom full** (magnifier icon / press `F`) and look
   at the end of the run: `pc_o` frozen and `instruction_o` stuck at the
   self-jump — **`00000063`** (`beq x0,x0,0`) for these man_compiled tests.
3. If instead the run ended at the full 5 ms with the PC still moving, the
   program never finished — that is a core bug to debug, not a time problem.
   (Worst case with `run -all`-style hangs: the **Break** button — red stop
   icon in the toolbar — halts a stuck simulation.)

### B.3 Compare against the golden model

1. Open both files in your editor (Cursor/VS Code):
   - `Lab5\SIM\RV32IM_sc\DTCM.mem` (your core's result)
   - `C:\TestPrograms\Quartus21_1\testN\RARS\DTCM.h` (golden, 1024 words)
2. Right-click the first file tab → **Select for Compare**, right-click the
   second → **Compare with Selected**.
3. Expected: **files identical** (every one of the 1024 words). Any diff means
   a core bug — note the address, find in the wave the store that wrote that
   word, and debug from there.

### B.4 Before the next test

Nothing to clean — just edit `N` in `run_test.do` and run the macro again.
It reloads the simulation (fresh memories) automatically.

---

## Part C — Which screenshots to take (with exact signal values to look for)

All times and values below were measured on this design with the
`man_compiled` benchmark images — your waves should show **exactly** these
numbers. Each probe time is the middle of the interesting cycle.

**How to navigate to a value or time in the Wave window:**
- *Jump to a time:* click the cursor's time field at the bottom-left of the
  Wave window, type the time (e.g. `1850 ns`), press Enter, then zoom in
  around the cursor (`i` / `o` keys or the zoom toolbar buttons).
- *Find a value:* click the signal name (e.g. `instruction_o`) →
  **Edit → Signal Search...** → choose **Search for Signal Value**, enter the
  value in the signal's radix (e.g. `03DE0F33`) → **Search Forward**.

General rule: every screenshot should include `clk_i`, `pc_o`,
`instruction_o`, plus the signals named for that shot, with the cursor placed
on the cycle so the value column shows the numbers.

### Screenshots for EVERY test (4 shots × 4 tests)

1. **Program start** — zoom on 0–1200 ns:
   `rst_i` drops at 80 ns, `pc_o` starts at `000` and increments by 4 every
   100 ns, `instruction_o` changes every cycle.
   *Proves: reset works; one instruction per clock (the CPI=1 "system timing"
   figure the report asks for).*
2. **Program end** — press zoom-full (`f`), look at the last cycles.
   Values to show (cursor on the final cycle):

   | Test | Run ends at | `pc_o` | `instruction_o` | `mclk_cnt_o` (unsigned) |
   |---|---|---|---|---|
   | test1 | 13.4 us | `0070` | `00000063` | **134** |
   | test2 | 151.4 us | `0070` | `00000063` | **1514** |
   | test3 | 272.5 us | `00CC` | `00000063` | **2725** |
   | test4 | 273.5 us | `004C` | `00000063` | **2735** |

   (`00000063` = `beq x0,x0,0`, the compiled `while(1)`.)
   *Proves: program ran to completion. Because the run auto-stops on reaching
   `while(1)`, `mclk_cnt_o` is the program's true cycle count — record it,
   you will compare against the pipelined core's counts in Part 2.*
3. **A `mul` instruction in flight** — search `instruction_o` for the mul
   word, or jump to the time below (first product of each test):

   | Test | Time | `pc_o` | `instruction_o` | MUL16 `a_i` | `b_i` | `res_o` |
   |---|---|---|---|---|---|---|
   | test1 | 1850 ns | `0044` | `03DE0F33` | `0001` | `0008` | `00000008` |
   | test2 | 1850 ns | `0044` | `03DE0F33` | `0001` | `0064` | `00000064` |
   | test3 | 92450 ns | `0080` | `03DE0F33` | `0001` | `0064` | `00000064` |
   | test4 | 183850 ns | `00E0` | `03498AB3` | `0001` | `0064` | `00000064` |

   Also show in the same shot: `mul_w = 1`, `ALUOp_ctrl_o` = the ALU_MUL code,
   and `alu_res_o` equal to `res_o` (1×8=8 for test1; 1×100=0x64 for the rest).
   For a more impressive value, step to a later product — e.g. test2's second
   mul at 3350 ns shows 2×99: `a_i=0002`, `b_i=0063`, `res_o=000000C6`.
   *Proves: CONTROL decodes mul → MUL16 multiplies → result reaches the ALU
   output. This is the entire Part-1 M-extension datapath in one picture.*
4. **Golden-model match** — screenshot of the file-compare window:
   `DTCM.mem` vs `C:\TestPrograms\Quartus21_1\testN\RARS\DTCM.h`,
   **zero differences** in all 1024 lines.
   *Proves: clause 8.c.i of the task PDF (RARS golden comparison) passed.*

### One extra test-specific screenshot each

**test1 — memory window with all three result vectors.**
After the run: **View → Memory List** → double-click
`/tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a` → capture words 0–39:

| Words (dec) | Content | Expected values (hex) |
|---|---|---|
| 0–7 | arr1 | `01 02 03 04 05 06 07 08` |
| 8–15 | arr2 | `08 07 06 05 04 03 02 01` |
| 16–23 | res1 = add | all `00000009` |
| 24–31 | res2 = **mul** | `08 0E 12 14 14 12 0E 08` |
| 32–39 | res3 = xor | `09 05 05 01 01 05 05 09` |

*Proves at a glance: add, mul and xor results all correct in memory.*

**test2 — a store cycle writing a result to the DTCM.**
Cursor at **1950 ns**: `MemWrite_ctrl_o = 1`, `instruction_o = 01E92023` (sw),
`dtcm_addr_o = 12D` (word 301 = `res2[0]`), `dtcm_data_wr_o = 00000064`
(the product 1×100 computed one cycle earlier).
Nearby for the same shot: the `res1[0]` store at 1750 ns
(`addr=0C9`, `data=00000065` = 101) and the `res3[0]` store at 2150 ns
(`addr=191`, `data=FFFFFF9D` = −99, showing signed results too).
*Proves: results reach the right DTCM addresses (res1 at word 201, res2 at
301, res3 at 401).*

**test3 — a taken branch redirecting the PC.**
Cursor at **2350 ns**: `instruction_o = FE0290E3` (bne back to loop start),
`Branch_ctrl_o = 1`, `brTaken_o = 1`, `pc_o = 0058` — and on the **next**
cycle `pc_o` is back at the loop body (not `005C` = PC+4).
For contrast, the same instruction at the loop's last iteration is not taken
and `pc_o` continues to PC+4 (visible right before the mul loop starts at
~92 us).
*Proves: branch resolution and PC redirect work.*

**test4 — a call/return pair (this test calls functions via `jalr`).**
Two cursors (**Add → Cursor** for the second one):
- Call: cursor at **1150 ns** — `instruction_o = 02C300E7` (`jalr` into
  `addMat`), `Jalr_ctrl_o = 1`, `alu_res_o = 00000050` (the function address);
  next cycle `pc_o = 0050`.
- Return: cursor at **91650 ns** — `instruction_o = 00008067` (`ret` =
  `jalr x0,0(ra)`), `pc_o = 0084`, `alu_res_o = 0000002C` (return address);
  next cycle `pc_o = 002C`, back in `main`, which immediately calls the next
  function (`subMat` call at 92050 ns, target `00000088`).
Expand `RF_q` in the same shot to show `x1` (ra) holding the return address
and `x2` (sp) holding the stack pointer.
*Proves: jalr-based calls, link register and returns work.*

---

## Quick reference — expected run behavior

The `when` breakpoint in `run_test.do` stops each run automatically at
completion, so no manual timing is needed. Measured behavior:

| Test | Program | Auto-stops at | `mclk_cnt_o` | muls | stores | taken branches | jalr |
|---|---|---|---|---|---|---|---|
| test1 | 8-element vectors | 13.4 us | 134 | 8 | 24 | 7 | 0 |
| test2 | 10×10, one loop | 151.4 us | 1514 | 100 | 300 | 99 | 0 |
| test3 | 10×10, three loops | 272.5 us | 2725 | 100 | 300 | 297 | 0 |
| test4 | 10×10, function calls | 273.5 us | 2735 | 100 | 300 | 297 | 6 |

(These counts are also useful sanity checks: 300 stores = 3 result matrices ×
100 elements; test4's 6 jalr = 3 calls + 3 returns.)

If a run hits the full 5 ms bound with the PC still moving, the program never
reached `while(1)` — debug the core, don't extend the time. (Extra cycles
spent inside `while(1)` would change nothing in the DTCM anyway.)
