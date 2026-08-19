LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY hex_decoder IS
    PORT (
        bin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END hex_decoder;

ARCHITECTURE behavior OF hex_decoder IS
BEGIN
    -- DE2-115 7-segment displays are active-low (0 turns the segment ON)
    PROCESS(bin)
    BEGIN
        CASE bin IS
            WHEN "0000" => seg <= "1000000"; -- 0
            WHEN "0001" => seg <= "1111001"; -- 1
            WHEN "0010" => seg <= "0100100"; -- 2
            WHEN "0011" => seg <= "0110000"; -- 3
            WHEN "0100" => seg <= "0011001"; -- 4
            WHEN "0101" => seg <= "0010010"; -- 5
            WHEN "0110" => seg <= "0000010"; -- 6
            WHEN "0111" => seg <= "1111000"; -- 7
            WHEN "1000" => seg <= "0000000"; -- 8
            WHEN "1001" => seg <= "0010000"; -- 9
            WHEN "1010" => seg <= "0001000"; -- A
            WHEN "1011" => seg <= "0000011"; -- b
            WHEN "1100" => seg <= "1000110"; -- C
            WHEN "1101" => seg <= "0100001"; -- d
            WHEN "1110" => seg <= "0000110"; -- E
            WHEN "1111" => seg <= "0001110"; -- F
            WHEN OTHERS => seg <= "1111111"; -- Off
        END CASE;
    END PROCESS;
END behavior;