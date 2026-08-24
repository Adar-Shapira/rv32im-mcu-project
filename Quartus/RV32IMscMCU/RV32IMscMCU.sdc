# ============================================================
# SDC for the RV32IM MCU  --  top = RV32IMscMCU
# DE2-115, Cyclone IV E (EP4CE115F29C7)
# Phase 4C. Supersedes the Phase 1 file, which was wrong in two ways:
#   - it named RV32IM_CORE as the top, which stopped being true at Phase 1;
#   - it documented a single 25 MHz PLL output (50 * G_PLL_MUL / G_PLL_DIV),
#     which stopped being true at Phase 4B.
#
# Reference: Auxiliary/Lab 5/Auxilary/QUARTUS/SDC/RISCV_simple.sdc, which is
# exactly these three commands. What is added below is the part that file did
# not need: three generated clocks instead of one, and the cross-domain
# statements that go with them.
# ============================================================

# ------------------------------------------------------------
# The one real clock: the on-board 50 MHz oscillator.
# Figure 1 calls it baseclk50MHz. It reaches CLOCK_TREE and nothing else.
# ------------------------------------------------------------
create_clock -name clk_i -period 20.000 [get_ports {clk_i}]

# ------------------------------------------------------------
# Let the Timing Analyzer derive the PLL outputs rather than hand-writing
# create_generated_clock for each. This is what the reference SDC does, and it
# is the safer choice: a hand-written generated clock that disagrees with the
# megafunction's actual multiply/divide is a constraint that silently analyses
# the wrong frequency.
#
# What it will derive, from CLOCK_TREE.vhd's generics:
#   MCLK      50 MHz * 2/5 = 20 MHz   -- the core
#   SMCLK     the same net as MCLK by default (assumption A19 -- see below)
#   ACCELCLK  50 MHz * 1/1 = 50 MHz   -- the divider, Phase 7B
# ------------------------------------------------------------
derive_pll_clocks
derive_clock_uncertainty

# ------------------------------------------------------------
# MCLK and SMCLK
#
# With CLOCK_TREE's SMCLK_SHARES_MCLK = TRUE (the default), SMCLK IS MCLK --
# one PLL, one net -- so there is no MCLK/SMCLK crossing to constrain and
# nothing is needed here. That is the whole point of the default: the CPU drives
# a synchronous parallel bus into the peripheral registers, and Figure 5 draws no
# synchroniser on it.
#
# IF SMCLK_SHARES_MCLK IS EVER SET FALSE, this file MUST grow. Two independent
# PLLs at the same frequency have no specified phase relationship, so every
# path between the core and a peripheral becomes a genuine asynchronous
# crossing. Leaving this file unchanged in that case would let the Timing
# Analyzer report a clean design that is not one. The minimum would be:
#
#   set_clock_groups -asynchronous \
#       -group [get_clocks {*|altpll_component|*|clk[0]}] \
#       -group [get_clocks {*P_SMCLK*|altpll_component|*|clk[0]}]
#
# plus a real synchroniser in the RTL on every signal that crosses. Do not add
# the set_clock_groups line on its own: it silences the analysis without fixing
# the design, which is worse than the warning.
# ------------------------------------------------------------

# ------------------------------------------------------------
# ACCELCLK is a genuinely separate domain (Phase 7B)
#
# The divider runs on ACCELCLK while the core runs on MCLK, and the crossings
# between them go through DUT/RV32IMscMCU/SYNC.vhd -- the two-flop synchroniser
# of Figures 10a/10b. A synchroniser's input path is by construction not
# meant to meet setup/hold, so the analyser must be told not to try; otherwise
# it reports failures on paths that are correct by design.
#
# COMMENTED OUT UNTIL PHASE 7B, on purpose. Today accelclk has no load, so
# Quartus prunes the ACCELCLK PLL and these get_clocks patterns match nothing --
# and a set_clock_groups whose collections are empty is a constraint that looks
# applied and is not. Uncomment it in the same commit that instantiates
# div_accel, and check the Timing Analyzer's "Clocks" report shows three clocks
# before believing it.
#
# set_clock_groups -asynchronous \
#     -group [get_clocks {*P_MCLK*|altpll_component|*|clk[0]}] \
#     -group [get_clocks {*P_ACCEL*|altpll_component|*|clk[0]}]
# ------------------------------------------------------------

# ------------------------------------------------------------
# Board inputs and outputs
#
# SW, KEY, LEDR and the HEX displays are hand-operated or human-read and have no
# meaningful timing relationship to any clock. Left unconstrained deliberately:
# inventing an input delay for a switch would be a fabricated number, and clause
# 6 of the assignment asks for f_MCLK, not for I/O timing. Hanan's own reference
# SDC constrains nothing beyond the clock either.
#
# The one input that DOES matter is rst_i (KEY0), and it is handled in the RTL
# rather than here: it is conditioned at the board boundary (RST_ACTIVE_LOW) and
# then held until the PLLs lock (GEN_RESET_ON_LOCK), so its release is
# synchronous to a valid clock.
# ------------------------------------------------------------
