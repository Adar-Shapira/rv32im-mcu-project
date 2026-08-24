library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

PACKAGE sample_package is

component top is
	generic(
		FPGA_TARGET : boolean := TRUE
	);
	
	port (
		clk_i, ena_i	: in std_logic;	
		count_o				: out std_logic_vector (7 downto 0)
	);
end component;

end sample_package;
