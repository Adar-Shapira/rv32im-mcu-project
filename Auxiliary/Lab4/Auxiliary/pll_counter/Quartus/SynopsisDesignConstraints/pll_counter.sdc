# constraint for on board osc of name clk with period of 20ns targeted to the design pin of name clk

create_clock -name clk -period 20 [get_ports {clk_i}]
#---------------------------------------------------------------------------------------------------
#requires defifning PLL input 

#create_clock -period 20 [get_ports clk_i] derive_pll_clocks 
#or simply
derive_pll_clocks -create_base_clocks
