LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY logic IS
    GENERIC (n : INTEGER := 8);
    PORT 
    ( 	
        x,y     : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
        alufn   : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        aluout  : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
    );
END logic;

ARCHITECTURE la OF logic IS
	signal res_local : std_logic_vector(n-1 DOWNTO 0);
BEGIN
	-- Here we perform logic operators on the input y according to ALUFN[2:0] 
	the_logic_functions : for i in 0 to n-1 
    generate
        res_local(i) <= not y(i) when (alufn="000") else					-- not
                        x(i) or y(i) when (alufn="001") else				-- or
                        x(i) and y(i) when (alufn="010") else				-- and
                        x(i) xor y(i) when (alufn="011") else				-- xor
                        not (x(i) or y(i)) when (alufn="100") else		    -- nor
                        not (x(i) and y(i)) when (alufn="101") else		    -- nand
                        not (x(i) xor y(i)) when (alufn="110") else '0';    -- xnor
	end generate;

	-- then we make sure to save it to the output
	aluout <= res_local;
END la;