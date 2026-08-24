# constraint for on board osc of name clk with period of 20ns targeted to the design pin of name clk

create_clock -name clk -period 20 [get_ports {clk_i}]
#---------------------------------------------------------------------------------------------------
# Automatically apply a generate clock on the output of phase-locked loops (PLLs)
# This command can be safely left in the SDC even if no PLLs exist in the design
# The clock names for the generated clocks will be the names of the PLL output pins

derive_pll_clocks -create_base_clocks
#---------------------------------------------------------------------------------------------------
# Adds 100ps of uncertainty to the clk_i source for setup checks

set_clock_uncertainty -setup -to clk_i 0.100
#---------------------------------------------------------------------------------------------------
# Adds 50ps of uncertainty for hold checks

set_clock_uncertainty -hold -to clk_i 0.050
