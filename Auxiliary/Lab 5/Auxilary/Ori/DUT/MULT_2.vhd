LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity multiplier_2 is
	port(
		P0_i 	: in std_logic_vector(15 downto 0);
		P1_i 	: in std_logic_vector(15 downto 0);
		P2_i 	: in std_logic_vector(15 downto 0);
		P3_i 	: in std_logic_vector(15 downto 0);
		
		Res 	: out std_logic_vector(31 downto 0)
	);
end multiplier_2;

architecture mult_2 of multiplier_2 is

	signal M 				: std_logic_vector(16 downto 0);
	
	signal P0_ext			: std_logic_vector(31 downto 0);
	signal M_shifted		: std_logic_vector(31 downto 0);
	signal P3_shifted		: std_logic_vector(31 downto 0);
	
begin

	M <= ("0" & P1_i) + ("0" & P2_i);
	
	P0_ext 		<= x"0000" & P0_i; 				-- P0 zero extended to 32 bits
	M_shifted 	<= "0000000" & M & x"00";		-- M shifted left by 8
	P3_shifted 	<= P3_i & x"0000";				-- P3 shifted left by 16
	
	Res <= P0_ext + M_shifted + P3_shifted;

end mult_2;

