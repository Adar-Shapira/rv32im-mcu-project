---------------------------------------------------------------------------------------------
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- RV32IM-based MCU, single-cycle
--
-- hex_decoder -- the "7-segment encoder" block of Figure 5 (p5).
--
-- USED AS IS. Copied from the students' own Lab 4:
--     Auxiliary/Lab 5/Auxilary/Lab4/DUT/hex_decoder.vhd
-- Everything below this header block is BYTE-IDENTICAL to that file. Only this
-- header was added, and the filename was capitalised to match the convention the
-- rest of DUT/RV32IMscMCU uses. The entity name is unchanged.
--
-- WHY IT NEEDED NO CHANGE
--   It is already exactly what Figure 5 asks for: four bits in, seven segments
--   out, active-low for the DE2-115 (its own line 13 says so), a complete 0..F
--   table, and an all-off OTHERS branch. Pure combinational, one CASE, no latch.
--
-- WHICH FOUR BITS IT SEES
--   A PORT_HEXn register is eight bits wide (Figure 5 draws D0..D7), but a
--   7-segment display shows one hex digit. The low nibble is the digit, and that
--   is settled by the software, not assumed: in
--   Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/asm-code/01_func.s:17-20 the
--   program masks and then shifts the digit down before storing --
--       andi s1,a0,0x000000F0 ; srli s1,s1,4 ; sw s1,0(s2)  # PORT_HEX1
--   so bits 3..0 of the stored byte are the digit to display. RV32IMscMCU.vhd
--   therefore wires q_o(3 DOWNTO 0) here; bits 7..4 are stored, have no load, and
--   are pruned by synthesis.
---------------------------------------------------------------------------------------------
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