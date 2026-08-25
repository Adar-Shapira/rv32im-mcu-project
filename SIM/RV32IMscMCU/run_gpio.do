# run_gpio.do - Phase 6A: the seven GPO ports of Figure 5
#
# Run compile.do first.
#
# Needs GPIO test0's M9K-intel images staged.
#
# STAGING - identical to run_mmio.do, so if you have just run that, nothing to do:
#
#   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\ITCM.hex" ^
#        C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
#   copy "<repo>\Auxiliary\Benchmark Apps\GPIO\test0\bin\M9K-intel\DTCM.hex" ^
#        C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
#
# Use the M9K-intel .hex files, NOT the Hexadecimal-Text .h files - they are
# different programs, and the .h copy carries a stale -0x3000 auipc bias.
#
# WHAT PASS MEANS
#   P1  CONTENT       every one of the seven ports holds the byte the program
#                     last stored to its own byte address
#   P2  DISPLAY       each HEX shows the active-low pattern for the low nibble of
#                     its port, compared against a 7-segment table transcribed
#                     into the testbench independently of hex_decoder.vhd
#   P3  NOT VACUOUS   all seven ports were written, and LEDR showed at least
#                     three distinct values
#   P4  NO CROSS-TALK no port ever changed except on the edge after a store to
#                     its own address
#
#   P4 is the reason this is a scoreboard and not a waveform. PORT_HEX0 and
#   PORT_HEX1 share one chip select and are separated only by A0, so the natural
#   bug is a store to one updating both. test0 writes the SAME value to all seven
#   ports in the same iteration, so on a waveform that bug is invisible - every
#   display would show the right digit anyway. Only a model that knows which port
#   was addressed can see it.
#
#   BUT P4 IS ONE-SIDED, AND THAT IS WORTH KNOWING BEFORE YOU TRUST A PASS.
#   Because test0 writes the same value to every port in ascending address order,
#   a port that wrongly captures an EARLIER store fails (its pins move to a value
#   the model does not expect), while a port that wrongly captures a LATER store
#   of the same iteration re-captures the value it already holds and is invisible.
#   So a PASS here proves the lane decode in one direction only. Gap G-406 records
#   it; closing it needs a program that writes different values to the two ports
#   of a pair, which no supplied benchmark does.
#
# EXPECTED NUMBERS
#   test0's loop is 32 instructions and writes each of the seven ports once per
#   iteration, so in 600 cycles expect about 18 writes to each of the seven and
#   about 17 distinct LEDR values. Any port showing 0 writes fails P3.
#
# WHAT THIS DOES NOT COVER
#   PORT_SW and PORT_PB. Those are reads, and the read path is Phase 6B/6C -
#   Phase 6A is the output side only. GPIO test1 and test2 both branch on
#   PORT_SW, so they cannot be used until 6B lands; test0 is the only GPIO
#   benchmark that is purely output.
#
#   READ-BACK OF THE GPO PORTS ITSELF. Figure 5 draws a MemRead-enabled tri-state
#   on each output-port block, so a load from 0x2000 or 0x2004 should return the
#   byte the port last stored. Phase 6A's ports are write-only and such a load
#   returns zero. Nothing in any supplied benchmark reads a GPO port, so nothing
#   is blocked; it is scheduled with the rest of the read path in 6B and recorded
#   in DOC/02 because clause 5's table calls all seven "GPO", which is in tension
#   with the figure.
#
# NOTES YOU MAY SEE, AND WHAT THEY MEAN
#   RV32IMscMCU prints at most two notes per run, once each: an SFR READ has no
#   path yet and returns zero, and an SFR WRITE landed on one of the eight words
#   that still have no peripheral. GPIO test0 writes only the four GPO words and
#   reads nothing on the SFR page, so on this test you should see NEITHER. A write
#   note here means a store went somewhere unexpected - read it.
#
# ON THE BOARD, LATER
#   The pin assignments for LEDR and HEX0-HEX5 are NOT yet in
#   Quartus/RV32IMscMCU/RV32IMscMCU.qsf, and they are not derivable from any
#   course file - see the note in that .qsf and gap G-504. Until they are added,
#   this phase is simulation-only. That is a known, recorded gap, not an
#   oversight.

onerror {quit -code 1}

vsim -t ns -gMODELSIM=1 work.tb_gpio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0, about 18"
echo "writes to each of the seven ports, and >= 3 distinct LEDR values."
echo ""
echo "If exactly one HEX of a pair fails P2 while its partner is correct, that is"
echo "cross-talk on a shared chip select - look at lane_en_i on the two P_HEXn"
echo "instances in RV32IMscMCU.vhd. If all six fail together, look at the"
echo "low-nibble wiring into the SEGGEN generate, or at HEX_DECODER.vhd."
