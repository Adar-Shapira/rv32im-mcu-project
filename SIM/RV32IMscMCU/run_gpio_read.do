# run_gpio_read.do - Phase 6B: the SFR read path
#
# Run compile.do first.
#
# ####################################################################
# # Needs GPIO **test1** images - test1, NOT test0.                   #
# ####################################################################
#
#   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test1\bin\M9K-intel\ITCM.hex" ^
#        C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
#   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test1\bin\M9K-intel\DTCM.hex" ^
#        C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
#
# M9K-intel, not Hexadecimal-Text. And remember to put test0's images back before
# re-running run_mmio.do or run_gpio.do.
#
# WHAT THIS TEST DOES, AND WHY IT IS THE STRONGEST ONE SO FAR
#   It does not assert on the value on the read bus. It drives the switches and
#   watches what the PROGRAM does, because test1 branches on what it reads:
#
#     SW = 0x01  ->  the counter on LEDR and the displays must count UP
#     SW = 0x02  ->  it must count DOWN
#     SW = 0x00  ->  neither branch is taken, print2all is never called, and
#                    NOTHING IS WRITTEN AT ALL
#
#   The third case is the sharp one. An undriven read bus reads 'Z', a
#   doubly-driven one reads 'X', and either sends a branch somewhere - which shows
#   up as writes appearing when there should be none. "Exactly zero writes" is
#   very hard to produce by accident.
#
#   The test runs three 300-cycle phases and ignores 60 cycles after each switch
#   change: when SW changes, the loop iteration already in flight has ALREADY read
#   the old value and completes with the old branch, so exactly one stale store
#   arrives in the new phase. Scoring it would fail a correct design.
#
#   SW_i is read combinationally by default. GEN_INPUT_SYNC defaults to FALSE
#   because Hanan's forum says a switch needs no synchroniser - "their rate of
#   change is many orders of magnitude slower than the system clock, so the signal
#   is considered static". Set it TRUE to diagnose a marginal board; it costs two
#   cycles and sixteen flip-flops.
#
# WHAT PASS MEANS
#   P1 up, P2 down, P3 quiet, P4 not-vacuous (at least two increments AND two
#   decrements actually observed), P5 the seven ports still hold what was stored -
#   the Phase 6A model carried forward, so 6B cannot silently break 6A.
#
#   Since 2026-08-24 this also exercises the CORRECTED data bus: one shared
#   bidirectional bus with the CPU as one of its drivers, which Hanan's forum makes
#   mandatory. The GPO ports now take their write data FROM the bus, so if the
#   CPU's driver or the terminator is wrong, the writes in phases 1 and 2 carry the
#   wrong value and P1/P2 fail.
#
# WHAT PASS DOES NOT MEAN
#   The seven GPO READ-BACK paths are not exercised. Figure 5 draws a
#   MemRead-enabled tri-state on each output-port block, and Phase 6B implements
#   them behind GEN_GPO_READBACK, but no supplied benchmark ever reads PORT_LEDR
#   or a PORT_HEXn - the only MMIO reads anywhere are three "lw ... PORT_SW". So
#   only PORT_SW's tri-state is proved here. Gap G-407.
#
#   Note also that read-back rests on assumption A15: clause 5's table calls all
#   seven ports "GPO", which contradicts the figure unless "GPO" names the device
#   rather than forbidding a readable register. If Hanan says output ports must not
#   answer a read, set GEN_GPO_READBACK => FALSE and nothing else changes.
#
# EXPECTED NUMBERS
#   One SW=0x01 iteration of test1 is 42 instructions, so a 300-cycle phase minus
#   the 60-cycle settle window is about 5 writes to PORT_LEDR and about 4 scored
#   increments. Phase 3 must show exactly 0 writes. "stores in settle windows"
#   should be about 1 per boundary.

onerror {quit -code 1}

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_gpio_read.vhd

vsim -t ns -gMODELSIM=1 work.tb_gpio_read
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0, phase 3"
echo "writes exactly 0, and >= 2 increments and >= 2 decrements observed."
echo ""
echo "If phase 3 shows writes: the read path is returning something non-zero when"
echo "it should return zero - check term_en_w and the rd_en_w terms in"
echo "RV32IMscMCU.vhd, and look for the one-hot warning from onehot_check."
echo "If P1 and P2 both fail but P3 passes: the bit order is wrong, or SW_i is not"
echo "reaching sw_sync_w. If only P5 fails, Phase 6A broke, not 6B."
