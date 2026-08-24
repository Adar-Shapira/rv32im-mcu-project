# run_sync.do - run the self-checking CDC synchronizer test (Phase 4A)
#
# Run compile.do first. This needs no benchmark images and no app_bin staging:
# SYNC.vhd is a leaf module with no memory, so nothing has to be on disk.
#
# The testbench stops itself and prints its own verdict, so there is no stop
# condition here and no waveform to read.
#
# WHAT PASS MEANS
#   All four properties of Figures 10a/10b hold: the two-stage latency (checked
#   from both sides - not out too early, and out on time), the value arriving
#   intact, no phantom value ever appearing on the output, and reset holding the
#   output low.
#
#   The "not out too early" half is the one that matters most. It is what fails
#   if the chain is ever shortened to a single register, which is the classic way
#   a synchronizer gets quietly broken during a later refactor.

onerror {quit -code 1}

vsim -t ns work.tb_sync
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, with zero failures"
echo "in all three checkers (stimulus, monitor, latency)."
echo ""
echo "This is a functional simulation, so it does NOT and cannot reproduce"
echo "metastability - no RTL simulator can. It proves the structure. The physical"
echo "property is a timing-analysis matter and belongs in the SDC, which is still"
echo "open pending Q2 (the actual clock frequencies)."
