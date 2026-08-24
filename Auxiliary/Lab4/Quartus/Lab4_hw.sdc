# ============================================================
# SDC for the HARDWARE revision (top = fpga_hw_interface)
# DE2-115, Cyclone IV E (EP4CE115F29C7)
# ============================================================

# On-board 50 MHz oscillator feeding the PLL (period = 20 ns)
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# Let the Timing Analyzer create the generated clock on the PLL output
# (the 2 MHz c0). The generated-clock name is the PLL output pin name.
derive_pll_clocks

# Realistic clock uncertainty (jitter, etc.)
derive_clock_uncertainty
