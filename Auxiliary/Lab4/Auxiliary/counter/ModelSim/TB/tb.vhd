-- Test Bench for counter.
library IEEE;
library std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.env.all;
use WORK. sample_package.ALL;


entity test_counter is
	constant CYCLES : integer := 10000;
end test_counter;

architecture rtl of test_counter is
	signal	clk_i, ena_i : std_logic;	
	signal	count_o         : std_logic_vector (7 downto 0);
begin
        tester : counter
					generic map(
						FPGA_TARGET => FALSE
					)
					
					port map(
						clk_i 		=>	clk_i,
						ena_i 	=> 	ena_i,
						count_o 	=> 	count_o
					);
        
        testbench : process
        begin
        -- test output respones to several inputs.
          ena_i<='0', '1' after 5 ns; 
          wait;
        end process testbench;
        
        clock: process 
        begin
                clk_i <= '1';
                for i in 0 to CYCLES loop 
                        wait for 10 ns;
                        clk_i <= not clk_i;
												wait for 10 ns;
                        clk_i <= not clk_i;													
                end loop;  
                std.env.stop;	-- stop simulation;
        end process clock;
end architecture rtl;
