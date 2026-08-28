# ============================================================
# SDC for the pipeline RV32IM MCU -- top = RV32IMpipelinedMCU
# DE2-115, Cyclone IV E (EP4CE115F29C7)
#
# Clock tree is the same entity as the SC MCU (CLOCK_TREE.vhd).
# Constraints transcribed from Quartus/RV32IMscMCU/RV32IMscMCU.sdc.
# The previous pipeline SDC still described Lab 5's single 25 MHz PLL
# (G_PLL_MUL/DIV on the core). That is no longer the clocking.
# ============================================================

# The one real clock: the on-board 50 MHz oscillator (Figure 1 baseclk50MHz).
create_clock -name clk_i -period 20.000 [get_ports {clk_i}]

# What derive_pll_clocks will produce, from CLOCK_TREE.vhd's generics:
#   MCLK      50 MHz * 2/5 = 20 MHz   -- the core
#   SMCLK     the same net as MCLK by default (SMCLK_SHARES_MCLK)
#   ACCELCLK  50 MHz * 1/1 = 50 MHz   -- the divider
derive_pll_clocks
derive_clock_uncertainty

# ACCELCLK is a genuine second domain. Crossings go through SYNC.vhd
# (Figures 10a/10b); the analyser must not try to close setup on them.
set_clock_groups -asynchronous \
    -group [get_clocks {*P_MCLK*|altpll_component|*|clk[0]}] \
    -group [get_clocks {*P_ACCEL*|altpll_component|*|clk[0]}]
