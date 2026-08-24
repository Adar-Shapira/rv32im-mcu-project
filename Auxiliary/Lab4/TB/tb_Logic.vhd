library IEEE;
use ieee.std_logic_1164.all;
USE work.aux_package.all;

entity tb_Logic is
end tb_Logic;

architecture test of tb_Logic is
    signal x, y, aluout : std_logic_vector(7 downto 0);
    signal alufn : std_logic_vector(2 downto 0);
begin
    DUT: Logic generic map(8) port map(x, y, alufn, aluout);
    process begin
        x <= x"AA"; y <= x"F0"; alufn <= "010"; wait for 100 ns; -- AND
        alufn <= "011"; wait for 100 ns; -- XOR
        alufn <= "111"; wait for 100 ns; -- merge2bit(Y,X): expect 0xF2
        wait;
    end process;
end test;