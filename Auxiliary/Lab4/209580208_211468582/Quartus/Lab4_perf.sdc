# ============================================================
# SDC for the PERFORMANCE revision (top = perf_wrapper)
# Pure combinational ALU confined between input/output registers
# (Figure 1). No pins, no PLL, no SignalTap.
# ============================================================

# Single source clock on the perf_wrapper 'clk' port.
# The period below is only a reference constraint; the combinational
# subpart f_max is read from the Slow-model "Report Fmax Summary"
# in the Timing Analyzer regardless of this value.
create_clock -name clk -period 20.000 [get_ports {clk}]

derive_clock_uncertainty
