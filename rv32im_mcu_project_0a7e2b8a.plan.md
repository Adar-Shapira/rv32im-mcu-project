---
name: RV32IM MCU Project
overview: Build the mandatory DE2-115 single-cycle RV32IM MCU first, then reuse the verified memory/peripheral subsystem for the pipelined (+10%) and UART (+20%) variants. Verification will progress from ISA and peripheral unit tests through all supplied benchmarks, Quartus PPA, SignalTap/ISMCE hardware validation, and an exact submission-package audit.
todos:
  - id: requirements
    content: Freeze requirements, MMIO/register map, benchmark defects, and submission interpretations
    status: pending
  - id: baseline
    content: Create reproducible ModelSim/Quartus baseline from Lab 5 without generated artifacts
    status: pending
  - id: single-cycle
    content: Complete and verify the single-cycle RV32IM core, memory bus, GPIO, divider, timer, and interrupts
    status: pending
  - id: benchmarks
    content: Pass all supplied single-cycle benchmarks with golden-memory and waveform evidence
    status: pending
  - id: pipeline
    content: Port the verified subsystem to the pipeline core and prove hazards, interrupts, and IPC
    status: pending
  - id: uart
    content: Integrate UART option 1, implement the MMIO/interrupt wrapper and menu demo
    status: pending
  - id: quartus-hardware
    content: Build PPA configurations and validate with DE2-115, SignalTap, and ISMCE
    status: pending
  - id: submission
    content: Finish the report and clean-room audit the exact final ZIP layout
    status: pending
isProject: false
---

# RV32IM MCU Final Project Plan

## Project outcome and acceptance criteria
- Deliver a structural RV32IM Harvard MCU for the DE2-115 with 8 KiB ITCM, 8 KiB DTCM, memory-mapped GPIO, KEY interrupts, Basic Timer compare/PWM/capture modes, a 32-cycle divider accelerator, and the specified interrupt protocol.
- Also deliver the selected bonuses: a pipelined MCU using the same verified peripherals and an 8N1 UART with programmable 9600/115200 baud, RX/TX buffering, error status, interrupts, and the required PC menu demo.
- Pass the supplied GPIO tests 0–2 and interrupt tests 1–4 in ModelSim and on hardware, validate memory against RARS where applicable, prove IPC accounting, and collect the required Quartus area/fmax/power evidence.
- Treat [Final Project 2026 definition.pdf](Auxiliary/Final%20Project%202026%20definition.pdf) as the primary specification and the assembly `io_map.s` files as the executable MMIO contract.

## Important decisions from the supplied material
- Start from the single-cycle sources in [Lab 5/DUT/RV32IM_sc](Auxiliary/Lab%205/DUT/RV32IM_sc), then port the finished subsystem to [Lab 5/DUT/RV32IM_pipeline](Auxiliary/Lab%205/DUT/RV32IM_pipeline). Do not start from the older RV32I/Lab 3 cores.
- Reuse the Lab 5 testbench, ModelSim scripts, Quartus project, SDC, SignalTap, M9K ITCM/DTCM, and DE2-115 pin references as templates. Do not copy generated `db`, `incremental_db`, `output_files`, ModelSim `work`, transcripts, or old absolute paths.
- Keep full 32-bit byte addresses through the data-bus decoder. DTCM uses `address(12 downto 2)` for 2048 words; MMIO decodes exact byte addresses including `0x2005`, `0x2009`, and `0x200D`. Do not globally switch the existing RAM to byte granularity, which would conflict with its 2048-word depth.
- Generate a 20 MHz MCU/SMCLK from `CLOCK_50` so `SEC_PERIOD = 0x01312D00` is one second. Use the 50 MHz board clock for the fast divider and UART, with explicit CDC handshakes.
- Use [UART option 1](Auxiliary/USART%20Material/UART_FPGA_option1) as the MIT-licensed UART base; retain its license and attribution. Adapt its static divider to the `UTCL.BAUDRATE` runtime selection.
- Preserve Auxiliary as reference-only. Build a clean development tree, then stage a separate exact final ZIP tree so build caches and helper files cannot leak into submission.

## Step 1 — Freeze requirements and resolve specification defects
- Create a requirements traceability checklist covering every address, register bit, interrupt source/priority, timer mode, divider rule, UART bit, benchmark, report item, and final ZIP artifact.
- Record the authoritative MMIO map: DTCM `0x0000–0x1FFC`; LEDR `0x2000`; HEX0–5 `0x2004/05/08/09/0C/0D`; SW `0x2010`; PB `0x2014`; UART `0x2018–1A`; timer `0x201C/1D/20/24/28`; interrupt controller `0x202C–2E`.
- Record ambiguities and chosen interpretations before coding: `Final_report.pdf` filename; five listed top-level submission folders despite “six”; byte-addressed registers accessed by `sw`; BTCCR/BTCMPR naming; automatic versus software IFG clearing; and LEDG in the UART menu as a likely LEDR typo.
- Flag supplied test4 source defects for explicit handling rather than silently changing them: `blt t4,a3,endfor` appears to skip the div/rem loops, and `capture` writes the same `CAPMD1_CAPISEL3` value as initialization despite its VCC comment. Compare source against the supplied ITCM image and ask course staff which artifact is authoritative; retain originals and keep any corrected test copy clearly separate.
- Exit criterion: signed-off traceability list with no unresolved choice that changes RTL behavior.

## Step 2 — Create the clean project and reproducible tool flow
- Establish development folders for shared RTL, single-cycle RTL, pipeline RTL, unit/system testbenches, ModelSim scripts, benchmark images, Quartus projects, evidence, and documentation.
- Base the tools on the supplied Quartus 21.1/Lab 5 flow and DE2-115 device `EP4CE115F29C7`; verify installed ModelSim/Questa compatibility before modifying RTL.
- Replace hardcoded `C:\TestPrograms\Quartus21_1\...` memory paths with controlled relative paths or memory-file generics. Let the testbench override `MODELSIM => 1` while Quartus uses the hardware default, avoiding manual source toggles.
- Add repeatable compile scripts with explicit VHDL compile order and benchmark selection; regenerate all simulator and Quartus outputs locally.
- Exit criterion: unchanged Lab 5 single-cycle and pipeline baselines compile and run one known Lab 5 test, proving the environment before functional changes.

## Step 3 — Define the structural architecture and interfaces
- Keep both the FPGA MCU top and CPU core structural: only component instances, generics, and wiring in those levels; put behavior in leaf modules.
- Define a stable CPU data-master interface: full address, write data, read data, read/write strobes, access size/sign, and completion/stall. This interface will feed a structural memory subsystem containing DTCM and peripheral decode.
- Define shared peripheral interfaces for GPIO, timer, interrupt controller, UART, PWM/capture pins, and debug observations so the same subsystem can attach to either CPU.
- Add build generics for interrupt capability, UART, pipeline/debug exports, and SignalTap-only ports. These generics must support the three required PPA configurations without maintaining divergent source copies.
- Produce the top-level block diagram now and keep it synchronized for the final report.
- Exit criterion: interface specification and compileable structural skeleton for both MCU variants.

## Step 4 — Audit and complete the single-cycle RV32IM core
- First fix existing decode/ISA defects discovered by directed tests; for example, [CONTROL.vhd](Auxiliary/Lab%205/DUT/RV32IM_sc/CONTROL.vhd) currently selects `ALU_AND` with `ori_w` rather than `andi_w`, while the benchmarks use `andi` heavily.
- Build a self-checking ISA testbench for RV32I arithmetic, logic, shifts, comparisons, branches, jumps, immediates, and byte/half/word loads/stores.
- Complete RV32M semantics, not only the small positive benchmark cases: `MUL`, high multiply variants if required for ISA compatibility, `DIV/DIVU`, and `REM/REMU`, including divide-by-zero and signed overflow rules.
- Replace or extend the 16-bit multiply path where needed to guarantee correct 32-bit RV32M results.
- Run the pure RV32IM benchmark in [Benchmark Apps/RV32IM/test1](Auxiliary/Benchmark%20Apps/RV32IM/test1), first hand-written and then GCC-generated, and compare DTCM words 16–39 to the supplied RARS/GDB golden output.
- Exit criterion: directed ISA suite and both RV32IM test images pass before MMIO or interrupts are introduced.

## Step 5 — Implement the clock, reset, and CDC foundation
- Regenerate the PLL for Cyclone IV/DE2-115 rather than hand-editing stale wizard metadata: 50 MHz input, 20 MHz MCU/SMCLK output, lock output, and correct reset behavior.
- Synchronize PLL lock into reset release; KEY0 remains active-low external reset and resets PC, memories/peripheral state as specified.
- Run the divider accelerator and UART at 50 MHz. Use request/acknowledge toggles or equivalent handshakes; hold multi-bit operands/results stable while crossing domains and use two-flop synchronizers for control/status.
- Synchronize KEY1–3 and external capture/UART inputs. Use one-shot edge detection; only add configurable debounce if board behavior requires it because the board keys are already described as debounced.
- Constrain all clocks and CDC paths in the SDC and add CDC-focused simulations.
- Exit criterion: measured 20 MHz MCU clock, deterministic reset, and no unconstrained cross-domain control paths.

## Step 6 — Build the DTCM and MMIO memory subsystem
- Refactor [DMEMORY.vhd](Auxiliary/Lab%205/DUT/RV32IM_sc/DMEMORY.vhd) into a DTCM leaf behind a memory subsystem; retain 2048×32 M9K storage, runtime modification instance name `DTCM`, and ITCM instance name `ITCM` for ISMCE.
- Decode `0x0000–0x1FFF` to DTCM and `0x2000–0x3FFF` to MMIO before narrowing the RAM address.
- Implement byte enables and correct sign/zero extension for RV32I loads/stores. For the supplied nonstandard `sw` operations to byte-resolution MMIO addresses, decode the exact address and consume/return the low byte without aliasing adjacent HEX registers.
- Return deterministic zero or a documented value for unmapped reads; ignore unmapped writes and assert a simulation warning.
- Add unit tests for DTCM boundaries, access sizes, exact adjacent MMIO addresses, and DTCM/MMIO non-aliasing.
- Exit criterion: all memory tests pass and every MMIO address selects exactly one peripheral/register.

## Step 7 — Implement and verify GPIO
- Implement registered LEDR7–0 and six HEX nibble registers, SW7–0 and KEY3–1 reads, and active-low seven-segment decoding using the Lab 4 decoder/pin wrapper only as a pattern.
- Map KEY0 exclusively to reset. Map KEY1–3 consistently into `PORT_PB` and into interrupt-source edge detectors.
- Extend the single-cycle testbench to drive switch/key stimuli and check logical HEX register values separately from active-low segment outputs.
- Run GPIO test0, test1, then test2. Check count-up, SW0 increment priority, SW1 decrement, hold behavior, LED output, and independent six-digit HEX writes.
- Exit criterion: all GPIO tests pass deterministic ModelSim observation windows and work interactively on the DE2-115.

## Step 8 — Implement the 32-cycle division accelerator
- Implement the Figure 9 unsigned 32-step shift/subtract engine in the 50 MHz domain with start, busy, quotient, and residue; wrap signed `DIV/REM` behavior around unsigned magnitude operations.
- Launch on decode of a divide/remainder instruction, stall PC and all architectural writes while busy, and write the selected result exactly once when completion returns to the 20 MHz core domain.
- Preserve operands across the operation and block interrupt entry until the current divide instruction retires, ensuring a precise architectural boundary.
- Unit-test latency, back-to-back operations, reset while busy, zero divisors, signed limits, and quotient/remainder selection.
- Exit criterion: exactly 32 accelerator cycles per normal operation and all RV32M directed/golden tests pass.

## Step 9 — Implement the Basic Timer
- Implement `BTCTL1`, `BTCTL2`, `BTCMPR0`, `BTCMPR1`, `BTCAPR`, 32-bit `BTCNT`, SMCLK `/1,/2,/4,/8`, hold/clear, compare flags, output compare/PWM, and input capture according to Figure 7 and the benchmark masks.
- Use shadow/active compare registers so updates are glitch-free; define transfer on held/clear initialization and safe period boundaries, matching benchmark writes performed while held.
- Implement compare mode periodic reset/interrupt, PWM period/duty behavior for both output modes, and capture of `BTCNT` on the selected CAPIN/VCC/GND edge. Verify the corrected VCC/GND software sequence separately because supplied test4 appears inconsistent.
- Use shortened compare constants in unit tests, then verify real constants at 20 MHz: one-second `0x01312D00` and 5 kHz period `0x1F4`.
- Exit criterion: self-checking compare, rate-change, PWM duty, and capture tests pass before connection to interrupts.

## Step 10 — Implement the interrupt controller and two-cycle CPU protocol
- Implement byte registers `IE`, `IFG`, and read-only `TYPE`; map RX, TX, BT, KEY1, KEY2, KEY3 to bits 0–5 and enforce the documented fixed priority and TYPE offsets `0x04–0x1C`.
- Latch key edges; auto-clear BT/RX/TX on service as specified while also supporting documented software clearing; preserve unrelated IFG bits during the benchmark read-modify-write masks. Treat UART error as the higher-priority interpretation of RXIFG when an error is latched.
- Extend the register file/core with controlled access to `gp[0]` as GIE and `tp` as the return register. Detect exactly `jalr zero,0(tp)` as `reti` for GIE restoration.
- Add a dedicated interrupt-service FSM: finish the current instruction, save its next PC to `tp`, clear GIE, perform the INTA/TYPE capture cycle, use the following cycle to read `DTCM[TYPE/4]`, auto-clear the serviced synchronous flag, and redirect to the handler. Stall normal memory ownership during the vector-table read.
- Test simultaneous requests, priority, masking, nested-request deferral while GIE=0, manual/automatic flag clear, return address correctness, and interrupts around loads/stores/division.
- Exit criterion: cycle-accurate protocol assertions pass and handlers return to the exact interrupted flow.

## Step 11 — Run the complete single-cycle benchmark progression
- Run interrupt test1 with scripted KEY1/2/3 pulses; verify ISR/FSM state, displayed arrays, quotient/remainder, IFG clearing, and `reti`.
- Run test2; verify one-second BT interrupts and `a0` display snapshots.
- Run test3; verify 1, 1/2, 1/4, and 1/8 second periods and correct concurrent KEY/BT arbitration.
- Run test4 in compare, PWM, and capture modes. Validate actual supplied binary behavior, then separately validate corrected div/rem-loop and capture stimulus if course staff confirms the source defects.
- Dump all 2048 DTCM words after a deterministic stop/stimulus point. Compare against RARS `DTCM.h` where meaningful; for interactive/infinite-loop tests, compare deterministic memory regions and verify MMIO/timing with assertions and waveforms rather than claiming a nonexistent natural program end.
- Exit criterion: all mandatory single-cycle benchmark checks pass with saved logs, memory diffs, and report-ready waveforms.

## Step 12 — Port the verified system to the pipeline bonus core
- Fork the supplied pipeline only after the single-cycle architecture is stable. Reuse the same memory subsystem, peripherals, divider, UART wrapper, register maps, and benchmark images.
- Integrate access-size controls through pipeline registers and add divider/memory stalls to the existing hazard/forward units without losing instructions or double-committing writes.
- Make interrupts precise: select a retirement boundary, kill younger instructions, preserve the correct resume PC, serialize vector-table access, and restart fetch at the handler. Test requests coincident with branch flush, load-use stall, store, and divider completion.
- Preserve `CLKCNT`, `STCNT`, `FHCNT`, breakpoint, and SignalTap observability. Count every non-branch lost cycle consistently so the supplied IPC equation remains valid; add an independent retired-instruction count in simulation to cross-check it.
- Re-run the complete ISA and benchmark matrix on the pipeline core.
- Exit criterion: pipeline architectural state matches the single-cycle reference for every test, and measured IPC equals the counter equation within exact integer accounting.

## Step 13 — Integrate and verify the UART bonus
- Import the five option-1 UART RTL files and MIT license. Wrap them with `UTCL`, `RXBUF`, and `TXBUF` at `0x2018–0x201A`.
- Implement `UTCL` status/control bits: BUSY, overrun, parity/frame errors, baud select, parity controls if retained, and software reset. Required operation is 1 start, 8 data LSB-first, no parity, 1 stop.
- Adapt the 50 MHz 16× baud tick to switch safely between 9600 and 115200 while idle. Buffer one RX byte and one TX byte; define overrun and ready/full semantics explicitly.
- Cross RX/TX status/data events to the 20 MHz MMIO domain with handshakes. Generate independent RX/TX interrupt flags and apply the specified clear-on-read/write/service behavior.
- Build self-checking UART unit and MMIO tests: TX frame timing, RX bytes, loopback, both baud rates, bad stop bit, overrun, status clearing, and interrupts.
- Assign UART TX/RX/GND to documented free DE2-115 GPIO-header pins. Use a current working driver for the actual PL-2303/FTDI cable; the bundled 2009 PL-2303 installer may be incompatible with modern Windows.
- Exit criterion: ModelSim loopback/error suite passes and a terminal communicates at 115200 8N1 without framing errors.

## Step 14 — Create the UART menu firmware and hardware demo
- Write a dedicated RISC-V menu application using only the implemented MMIO contract.
- Implement menu commands: delayed count up from `0x00` on the available red LEDs, delayed count down from `0xFF`, clear LEDs, send `I love my Negev` on each KEY1 event, and redisplay the menu.
- Resolve the document’s nonexistent DE2-115 `LEDG` reference as LEDR and state that interpretation in the report.
- Test commands through a bit-level UART testbench, then through PuTTY/Tera Term with 115200 8N1 and no flow control.
- Exit criterion: all five commands and RX/TX interrupts work repeatedly without disturbing timer/GPIO behavior.

## Step 15 — Automate regression and evidence capture
- Provide compile/run scripts for unit suites and each core × benchmark combination; scripts select images, run bounded deterministic stimuli, dump memory, compare expected data, and return failure status.
- Keep Intel/M9K `.hex` for Quartus/ISMCE and one-word-per-line `.h/.mem` for golden comparisons; add a converter/checker that proves both image formats contain identical words.
- Capture report-ready waveforms for interrupt tests 1–4, including PC/instruction, MMIO address/data/strobes, IE/IFG/TYPE, INTR/INTA, gp GIE, tp return address, timer count/match/PWM/capture, and divider busy/result. Add pipeline stall/flush/IPC and UART frames for bonus evidence.
- Exit criterion: one clean regression summary shows every required test and artifact, with no hidden manual source edits.

## Step 16 — Build the three required Quartus/PPA configurations
- Create clean Quartus projects and SDCs for: single-cycle MCU with GPIO; single-cycle MCU with GPIO plus interrupts; pipelined MCU with GPIO plus interrupts. Keep UART disabled for the mandated apples-to-apples three-row PPA tables and report its cost separately if useful.
- Assign only real MCU I/O pins in the DE2-115 QSF: `CLOCK_50`, KEY0–3, SW0–7, LEDR0–7, HEX0–5, PWM/capture, and UART pins. Gate exported validation pins with a generate generic and disable them for final SOFs.
- Run full compile, Timing Analyzer, and Power Analyzer under consistent settings/activity assumptions. Identify the actual critical path rather than only reporting fmax.
- Save screenshots and numeric results for logic elements, registers, pins, embedded memory bits, multipliers, PLLs, fmax/critical path, total/static/dynamic/I/O power.
- Exit criterion: all projects fit and meet the chosen 20 MHz system clock with clean required constraints and reproducible reports.

## Step 17 — Perform mandatory DE2-115 validation
- Program each `.sof`; use KEY0 reset and exercise GPIO/interrupt/UART scenarios on the physical board.
- Adapt the Lab 5 SignalTap file to capture core and peripheral internals without temporary physical debug pins. Capture at least one KEY ISR, BT ISR, divider stall/completion, pipeline hazard/flush, and UART transaction.
- Use ISMCE to load each benchmark’s ITCM/DTCM image, reset, run the prescribed stimulus, export DTCM, and compare with the expected/RARS image where applicable.
- Verify timing-dependent behavior with instruments or SignalTap: 20 MHz SMCLK basis, one-second timer, 5 kHz PWM and duty cycles, UART baud, and capture values.
- Exit criterion: signed hardware checklist with memory diffs, SignalTap captures, terminal transcript, and photos/screenshots needed for the report.

## Step 18 — Write the final report
- Produce `Final_report.pdf` with numbered pages, figures, tables, and captions below each figure/table.
- Include requirements and assumptions; structural block diagram; design decisions; RTL Viewer; short description of every HDL file; ISA/MMIO/interrupt/timer/divider/UART details; benchmark methodology; waveforms for tests 4 through 1; IPC proof; three PPA tables with mandatory Quartus screenshots and critical-path analysis; hardware validation; limitations/ambiguities; and conclusions.
- Explicitly document third-party UART attribution and any corrected benchmark copy without presenting supplied defects as RTL failures.
- Exit criterion: every report item on pages 18–19 of the definition maps to a page/figure/table in a final compliance checklist.

## Step 19 — Stage and audit the exact submission ZIP
- Create `id1_id2.zip` with `id1 < id2`, uploaded only by student `id1`.
- Include exactly the five listed top-level folders despite the PDF’s “six” typo:
  - `DUT/RV32IMscMCU` and `DUT/RV32IMpipelinedMCU`: design VHDL only, with all dependencies needed to compile independently.
  - `TB/RV32IMscMCU` and `TB/RV32IMpipelinedMCU`: correctly named MCU testbenches.
  - `SIM/...`: ModelSim `.do` files and only required simulation inputs.
  - `DOC`: `Readme.txt` navigation guide and `Final_report.pdf`.
  - `Quartus/...`: required SignalTap `.stp`, SDC, and final SOF for each design.
- Exclude testbench files from DUT, generated caches/reports not requested, transcripts, temporary memory dumps, absolute-path dependencies, and unrelated Auxiliary material.
- Unzip into a clean temporary location and independently compile both ModelSim and Quartus projects from the packaged files; verify hashes/openability of PDF, STP, SDC, SOF, and memory assets.
- Exit criterion: clean-room package compilation succeeds with zero missing files or path assumptions, and a final tree comparison matches the required layout exactly.