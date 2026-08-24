-- Test Bench for counter.
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use WORK. sample_package.ALL;

entity test_counter is
end test_counter;

architecture stimulus of test_counter is
	signal	clk_i, ena_i : std_logic;	
	signal	count_o      : std_logic_vector (7 downto 0);
begin
        tester : top
					generic map(
						FPGA_TARGET => FALSE
					)
					
					port map(
						clk_i 		=>	clk_i,
						ena_i 		=> 	ena_i,
						count_o 	=> 	count_o
					);
        
        ena_sig : process
        begin
        -- test output respones to several inputs.
          ena_i<='0', '1' after 25 ns; 
          wait;
        end process ena_sig;
        
        clk_sig: process 
        begin
					clk_i <= '1';
					for i in 0 to 100000 loop 
						wait for 10 ns;
						clk_i <= not clk_i;			
					end loop;  
					wait;
        end process clk_sig;
				
end architecture stimulus;
