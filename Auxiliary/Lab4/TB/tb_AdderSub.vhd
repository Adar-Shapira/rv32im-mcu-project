library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

entity tb_AdderSub is
end tb_AdderSub;

architecture test of tb_AdderSub is
    signal x, y, s : std_logic_vector(7 downto 0);
    signal sub_cont : std_logic_vector(2 downto 0);
    signal cout : std_logic;
begin
    DUT: AdderSub generic map(8) port map(x, y, sub_cont, cout, s);
    process begin
        x <= x"05"; y <= x"0A"; sub_cont <= "000"; wait for 100 ns; -- Add
        sub_cont <= "001"; wait for 100 ns; -- Sub
        sub_cont <= "011"; wait for 100 ns; -- Y+2
        wait;
    end process;
end test;