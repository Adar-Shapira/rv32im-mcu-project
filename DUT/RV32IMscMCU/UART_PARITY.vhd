--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the UART peripheral (bonus, clause 6.iv)
--
-- THIRD-PARTY FILE, USED UNDER THE MIT LICENCE. The licence header below is
-- the author's own and must stay. Provenance:
--   Auxiliary/USART Material/UART_FPGA_option1/rtl/comp/uart_parity.vhd
--   jakubcabal/uart-for-fpga v1.1, MIT, Copyright (c) 2015 Jakub Cabal
--   original md5 530bb3ff74e1109e5e19e3ea1e4a73a6
--
-- Clause 6.iv: "You are given a VHDL design code that needs to be adapted" --
-- so adapting this code is what the requirement asks for, not a shortcut.
-- BODY BYTE-IDENTICAL to the original -- only this header is prepended.
--============================================================================
--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART PARITY BIT GENERATOR
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_PARITY is
    Generic (
        DATA_WIDTH  : integer := 8;
        PARITY_TYPE : string  := "none" -- legal values: "none", "even", "odd", "mark", "space"
    );
    Port (
        DATA_IN     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        PARITY_OUT  : out std_logic
    );
end UART_PARITY;

architecture FULL of UART_PARITY is

begin

    -- -------------------------------------------------------------------------
    -- PARITY BIT GENERATOR
    -- -------------------------------------------------------------------------

    even_parity_g : if (PARITY_TYPE = "even") generate

        process (DATA_IN)
        	variable parity_temp : std_logic;
        begin
            parity_temp := '0';
            for i in DATA_IN'range loop
                parity_temp := parity_temp XOR DATA_IN(i);
            end loop;
            PARITY_OUT <= parity_temp;
        end process;

    end generate;

    odd_parity_g : if (PARITY_TYPE = "odd") generate

        process (DATA_IN)
        	variable parity_temp : std_logic;
        begin
            parity_temp := '1';
            for i in DATA_IN'range loop
                parity_temp := parity_temp XOR DATA_IN(i);
            end loop;
            PARITY_OUT <= parity_temp;
        end process;

    end generate;

    mark_parity_g : if (PARITY_TYPE = "mark") generate

        PARITY_OUT <= '1';

    end generate;

    space_parity_g : if (PARITY_TYPE = "space") generate

        PARITY_OUT <= '0';

    end generate;

end FULL;
