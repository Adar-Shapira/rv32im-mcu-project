# ============================================================
# SDC for the pipeline RV32IM core (top = RV32IM_PIPE_CORE)
# DE2-115, Cyclone IV E (EP4CE115F29C7)
# ============================================================

# On-board 50 MHz oscillator on clk_i feeding the PLL (period = 20 ns)
create_clock -name clk_i -period 20.000 [get_ports {clk_i}]

# Let the Timing Analyzer create the generated clock on the PLL c0 output
# (25 MHz core clock: 50 MHz * G_PLL_MUL / G_PLL_DIV = 50 * 1/2)
derive_pll_clocks

# Realistic clock uncertainty (jitter, etc.)
derive_clock_uncertainty