# run_clock.do - Phase 4B: the Clock Tree of Figure 1
#
# Run compile.do first.
#
# ####################################################################
# # ZERO SETUP. No memory images, no G_ISA_REPAIR setting, nothing to #
# # stage. A leaf test, like run_sync.do, run_decode.do and           #
# # run_div.do.                                                       #
# ####################################################################
#
# READ THIS FIRST: WHAT A PASS HERE DOES **NOT** MEAN
#   IT DOES NOT VERIFY THE PLLs, and it cannot. altpll is an Altera black box
#   that needs the altera_mf library, and this project's established idiom --
#   Hanan's own, in RV32IM_CORE.vhd -- is not to instantiate it in simulation at
#   all:
#       if (MODELSIM = 0) generate MCLK: PLL ... else mclk_w <= clk_i;
#   CLOCK_TREE follows that idiom, so at MODELSIM = 1 there is no PLL present.
#   Whether three pll_gen instances lock, at the right frequencies, on a
#   Cyclone IV E, is a QUARTUS question. It is on your list below, not answerable
#   in ModelSim by anyone.
#
# WHAT IT DOES VERIFY, AND WHY EACH IS WORTH HAVING
#   - The ratio arithmetic, at ELABORATION, exactly: 50 MHz * 2/5 = 20 MHz for
#     MCLK and SMCLK, * 1/1 = 50 MHz for ACCELCLK, cross-multiplied in integer
#     kHz so nothing rounds. A wrong ratio is otherwise a silent frequency error
#     that surfaces as a Basic Timer whose "5 kHz" is not 5 kHz -- very tedious
#     to find on a board. Checked for TWO configurations, not just the default:
#     DUT_B uses 25 MHz and 10 MHz, so arithmetic that happened to work only for
#     2/5 would be caught.
#   - That MCLK in simulation **is** clk_i. This is the single property that lets
#     Phase 4C wire the tree in without moving a benchmark cycle count. The four
#     numbers 134 / 1514 / 2725 / 2735 must survive 4C unchanged.
#   - That ACCELCLK is genuinely independent of MCLK and walks through many
#     distinct phases of it -- measured, not asserted. Phase 7B's clock-domain
#     crossing is only exercised if the two clocks actually slide against each
#     other; an integer ratio holds the edges in a fixed relationship and can pass
#     while hiding a real crossing bug. Same argument as tb_sync.vhd's 70/30.
#   - That locked_o starts low and rises, so Phase 4C's reset-on-lock has
#     something real to wait for.
#   - That BOTH branches of every generate actually compile. DUT_B runs with
#     SMCLK_SHARES_MCLK => FALSE for exactly that reason: a generate branch
#     nothing instantiates is a branch nobody compiles, and it breaks the first
#     time someone flips the generic.
#
# THE ONE REAL CONFLICT IN THIS PHASE -- worth knowing before you read the code
#   Forum answer F6 says the three clocks come from three separate PLL instances.
#   F7 says MCLK and SMCLK may be the same value. Do both literally and you get
#   two independent PLLs each producing 20 MHz -- and that is a design with a
#   defect, because the core drives address, write data and MemWrite on MCLK
#   while every peripheral register captures that bus on SMCLK (F11 says the
#   peripheral registers should be DFFs on SMCLK, and gpo_port does exactly
#   that). Two PLLs locked to the same reference are frequency-identical but
#   their phase relationship is specified by nothing, so that capture's
#   setup/hold margin is whatever the fitter happens to produce and Quartus has
#   no basis on which to analyse it -- and Figure 5 draws no synchroniser
#   anywhere on the GPIO write path.
#
#   So SMCLK_SHARES_MCLK defaults TRUE: when the two are configured to the same
#   frequency they share one PLL and one net. That is a DESIGN DECISION, recorded
#   as assumption A19 and raised as a question, not something the material
#   settles. Set it FALSE for the literal three-instance structure.
#
# EXPECTED NUMBERS
#   VERDICT: PASS, zero failures in all four checkers. Roughly 110 accelclk
#   edges, 32 mclk edges, 47 SMCLK edges on DUT_B, and 10 distinct phases.
#   Runtime is trivial -- about 3.3 us of simulated time.
#
# YOUR QUARTUS-ONLY ITEMS FOR THIS PHASE (nothing here can answer them)
#   1. Does a pll_gen instance compile and fit at all? PLL_GEN.vhd promotes four
#      constants to generics; every one already existed in PLL.vhd's own altpll
#      component declaration and was already being passed, so nothing new is
#      asserted about the megafunction -- but that is an argument, not a run.
#   2. The family string says "Cyclone II" and the board is Cyclone IV E. That
#      mismatch is inherited from PLL.vhd and Lab 5 compiled and ran with it, so
#      it is left at the known-working value. If Quartus rejects a PLL parameter,
#      pass DEVICE_FAMILY => "Cyclone IV E" and say which way it went.
#   3. Three instances with different parameters share one CBX_MODULE_PREFIX. If
#      Quartus reports colliding megafunction parameters, give each its own
#      LPM_HINT_STR -- that is the whole fix, and it is why the hint is a generic.
#   Report whatever happens; none of it blocks this simulation.

onerror {quit -code 1}

vsim -t ns work.tb_clock_tree
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS and failed 0 in all"
echo "four checkers, with about 110 accelclk edges and 10 distinct phases."
echo ""
echo "If elaboration ABORTS with a clock_tree report: a ratio generic and its"
echo "target frequency disagree. The message names which clock and prints the"
echo "arithmetic. That assert is doing its job - fix the generics, not the check."
echo "If P1 fails: MCLK is no longer clk_i in simulation, and wiring the tree in"
echo "at Phase 4C WILL move every benchmark cycle count."
echo "If P4 fails: the sim accelclk ratio stopped being coprime with the 100 ns"
echo "testbench clock, so Phase 7B's crossing would be tested at one fixed phase."
echo "If P5 fails: the SMCLK_SHARES_MCLK => FALSE branch is not producing an"
echo "independent clock."
