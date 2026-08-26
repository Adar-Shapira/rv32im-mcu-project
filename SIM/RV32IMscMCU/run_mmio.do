# run_mmio.do - Phase 5B: prove an MMIO access no longer reaches the DTCM
#
# Run compile.do first.
#
# STAGING IS AUTOMATIC (since Phase 13): this script copies GPIO test0's
#   M9K-intel images into app_bin itself, so there is nothing to do by hand and
#   nothing left over from a previous test.
#
#   Unlike run_sync.do and run_decode.do, this test runs a real program, so the
#   two init files have to be on disk where IFETCH.vhd and DMEMORY.vhd look for
#   them. The M9K-intel .hex files are used, NOT the Hexadecimal-Text .h files:
#   they are different programs, and the .h copy carries a stale -0x3000 auipc
#   bias. Same rule DOC/04_baseline_runbook.md states for every benchmark run.
#
#   Expect a warning that DTCM.hex supplies 1024 words for a 2048-word memory.
#   That is the shipped file's own length, not a staging mistake; the upper half
#   initialises to zero and this program never reaches it.
#
# WHAT PASS MEANS
#   Four properties, on the supplied GPIO test0 program:
#     P1  dtcm_wren_o stayed '0' for the whole run - the DTCM accepted ZERO
#         writes. test0 never stores to the DTCM, so zero is the right number.
#     P2  dtcm_cs_o tracked NOT alu_res(13) on every cycle
#     P3  all seven GPO registers were written, at least twice round the loop
#     P4  no store hit an unmapped address
#
#   P1 watches the ENABLE, not the decoder's chip select, and that distinction is
#   the point. The fix is one AND gate in DMEMORY.vhd:
#       wren_w <= MemWrite_ctrl_i AND dtcm_cs_i;
#   Delete it and the decoder is still perfectly correct: dtcm_cs_o still
#   deasserts on every MMIO address, so a test that watched the chip select would
#   print PASS while all ~126 stores still landed in DTCM words 0..3. Watching
#   dtcm_wren_o is what makes the test able to fail for the right reason.
#
#   P3 is the one that stops this test being worthless. P1 and P4 are both "a bad
#   thing did not happen", and a core that fetched nothing satisfies them
#   perfectly. P3 requires the program to have actually run.
#
#   P2 separates the two ways P1 can fail: with P2 passing, the decode is right
#   and the gate is not gating; with P2 failing too, the decoder is being fed the
#   wrong address bits.
#
# WHAT PASS DOES NOT MEAN
#   It does not mean the DTCM still works. test0 never stores to the DTCM, so a
#   decoder stuck at dtcm_cs = '0' passes everything here except P2. Read this
#   result together with:
#     - run_isa.do          43 scored stores to DTCM scratch words
#     - the four benchmarks  134 / 1514 / 2725 / 2735 cycles, unchanged
#   Those two are what prove the memory is still writable. This test proves the
#   I/O page is kept out of it. Neither is sufficient alone.
#
# WHY A CYCLE COUNT IS NOT THE PASS CRITERION HERE
#   test0 ends with "j Loop" and never terminates, so there is no sentinel to
#   stop on and no reference cycle count to compare against. The testbench bounds
#   the run itself with RUN_CYCLES and stops.

onerror {quit -code 1}

# Staging, done here so the flow has no manual copy step (Phase 13).
# Images: GPIO test0 (benchmark)
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_mmio_alias.vhd

vsim -t ns -gMODELSIM=1 work.tb_mmio_alias
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0."
echo "Sanity numbers, counted from the shipped ITCM image rather than estimated:"
echo "one loop iteration is 32 instructions, so 600 cycles is 18 iterations ->"
echo "about 126 MMIO stores, 'least hits any addr' about 18 (must be >= 2), and"
echo "DTCM stores seen 0 and DTCM WRITES ACCEPTED 0 - test0 loads N once and"
echo "never stores to memory, so both counts must be exactly zero."
echo ""
echo "Notes from RV32IMscMCU are EXPECTED and are not failures. Since Phase 6A the"
echo "wrapper reports at most two, once each: an SFR READ has no path yet and"
echo "returns zero (Phase 6B), and an SFR WRITE to one of the eight words that"
echo "still have no peripheral was discarded. GPIO test0 writes only the four GPO"
echo "words, which DO take their writes, so on this test you should see NEITHER"
echo "note. Seeing the write note here would mean a store went somewhere"
echo "unexpected - that is worth reading, not ignoring."
