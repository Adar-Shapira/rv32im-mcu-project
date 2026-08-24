library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all; 
 
entity counter is 
	generic(
		FPGA_TARGET : boolean := TRUE
	);
	
	port (
		clk_i, ena_i : in std_logic;	
		count_o      : out std_logic_vector (7 downto 0)
	); 
end counter;

architecture rtl of counter is
    signal count_q : std_logic_vector (31 downto 0):=x"00000000";
begin
    process (clk_i)
    begin
        if (rising_edge(clk_i)) then
           if ena_i = '1' then	   
		        count_q <= count_q + 1;
           end if;
	     end if;
    end process;
		
    planner: if FPGA_TARGET = TRUE generate
			count_o <= count_q(31 downto 24); -- Output the Most Sagnificant Byte
		else generate
			count_o <= count_q(7 downto 0); 	-- Output the Least Sagnificant Byte
		end generate planner; 
		
end rtl;



