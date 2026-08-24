library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all; 
 
entity top is

	generic(
		FPGA_TARGET : boolean := TRUE
	);
	
	port (
		clk_i, ena_i	: in std_logic;	
		count_o				: out std_logic_vector (7 downto 0)
	);
	
end top;

architecture rtl of top is

  component counter is
		generic(
			FPGA_TARGET : boolean := TRUE
		);
	
		port (
			clk_i, ena_i : in std_logic;	
			count_o          : out std_logic_vector (7 downto 0)
		); 
	end component;
	 
	component pll is
		port(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0				: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC );
		end component;
	 
  signal pll_w : std_logic ;
		
begin

    m0: counter
			generic map(
					FPGA_TARGET	=> FPGA_TARGET
			)
			port map(
				clk_i		=>	pll_w,
				ena_i		=>	ena_i,
				count_o	=>	count_o
			);
			
	  m1: pll 
			port map(
				inclk0 =>	clk_i,
				c0 		=>	pll_w
			);
		 
end rtl;


