library IEEE;
use ieee.std_logic_1164.all;
USE work.aux_package.all;

entity tb_Shifter is
end tb_Shifter;

architecture test of tb_Shifter is
    signal x, y, res : std_logic_vector(7 downto 0);
    signal dir : std_logic_vector(2 downto 0);
    signal cout : std_logic;
begin
    DUT: Shifter generic map(8,3) port map(x, y, dir, cout, res);
    process begin
        y <= x"FF"; x <= x"03"; dir <= "000"; wait for 100 ns; -- SHL by 3
        dir <= "001"; wait for 100 ns; -- SHR by 3
        wait;
    end process;
end test;