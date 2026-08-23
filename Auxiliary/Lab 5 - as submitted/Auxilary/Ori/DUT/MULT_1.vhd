LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity multiplier_1 is
	port(
		Ain 	: in std_logic_vector(15 downto 0);
		Bin 	: in std_logic_vector(15 downto 0);
		
		-- Multiplier Stage 1 Outputs
		P0_o 	: out std_logic_vector(15 downto 0);
		P1_o 	: out std_logic_vector(15 downto 0);
		P2_o 	: out std_logic_vector(15 downto 0);
		P3_o 	: out std_logic_vector(15 downto 0)
	);
end multiplier_1;

architecture mult_1 of multiplier_1 is

	signal A_low, A_high 	: std_logic_vector(7 downto 0);
	signal B_low, B_high 	: std_logic_vector(7 downto 0);
	
begin
	
	-- Extract the high and low 8-bit chunks from the 16-bit inputs
    A_low  <= Ain(7 downto 0);
    A_high <= Ain(15 downto 8);
    B_low  <= Bin(7 downto 0);
    B_high <= Bin(15 downto 8);

	P0_o <= A_low * B_low;
    P1_o <= A_low * B_high;
    P2_o <= A_high * B_low;
    P3_o <= A_high * B_high;

end mult_1;

