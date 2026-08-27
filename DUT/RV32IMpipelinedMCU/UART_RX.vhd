--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the UART peripheral (bonus, clause 6.iv)
--
-- THIRD-PARTY FILE, USED UNDER THE MIT LICENCE. The licence header below is
-- the author's own and must stay. Provenance:
--   Auxiliary/USART Material/UART_FPGA_option1/rtl/comp/uart_rx.vhd
--   jakubcabal/uart-for-fpga v1.1, MIT, Copyright (c) 2015 Jakub Cabal
--   original md5 2a856823864aace1198b8c464a08b3c6
--
-- ADAPTED -- TWO semantic changes, everything else byte-identical (verify with:
-- diff the original against this file from its first '-----' line onward; the
-- diff must show only these).
--
-- CHANGE 1 (Phase 12A) -- a BUSY source, in three places:
--   a. line 27 gains a ';' so the port list can continue;
--   b. a new output port RX_BUSY;
--   c. one concurrent assignment driving it, with its comment.
--
-- CHANGE 2 (Phase 12E) -- PARITY IS RUNTIME, NOT COMPILE-TIME, and PE is
-- exported. Upstream selects parity with a STRING GENERIC, so a build is 8N1
-- or 8E1 or 8O1 for ever. REQ p12 makes it a pair of WRITABLE REGISTER BITS --
-- UCTL[1] PENA "Parity enabled. Parity bit is generated (TXD) and expected
-- (RXD)", UCTL[2] PEV "0 Odd parity / 1 Even parity" -- and UCTL[5] PE is a
-- readable parity-error flag. A generic cannot implement a register field.
-- Phase 12A stored PENA/PEV and left them inert with PE a constant 0, recorded
-- as assumption A26; that was the cheap reading, not the right one. A register
-- software can write and that does nothing is a stub, and PE is one of the
-- three error flags §6.iv's own feature list requires.
--   a. the PARITY_BIT generic is gone, replaced by PARITY_EN and PARITY_EVEN
--      input ports, both defaulted so an upstream-style instantiation still
--      means "none";
--   b. UART_PARITY is instantiated UNCONDITIONALLY with PARITY_TYPE => "even"
--      and odd is one inversion of it, because odd parity IS the inverse of
--      even parity -- so UART_PARITY.vhd stays byte-identical to upstream and
--      no second instance is spent;
--   c. the parity-error register gains `AND PARITY_EN`, which is load-bearing
--      -- see its own comment: it samples on every rx_clk_en, not only in the
--      paritybit state, so without the gate an 8N1 frame would latch a
--      meaningless comparison and valid characters would be dropped;
--   d. a new output port PARITY_ERROR, driven with the same one-cycle shape as
--      FRAME_ERROR;
--   e. the databits state tests PARITY_EN instead of the generic.
-- With PARITY_EN = '0' the paritybit state is unreachable and the register is
-- pinned at '0', so the 8N1 path is bit-for-bit the path Phase 12A verified.
--
-- WHY THAT PORT. UCTL bit 7 is BUSY -- "this bit indicates if a transmit or
-- receive operation is in progress" (REQ p12). The transmit half is free:
-- DIN_RDY already means "TX idle". The receive half has no output at all in
-- the original. rx_receiving_data looked like the signal, and is NOT: the FSM
-- drives it '1' only in the databits state (line 216 of the original), so it
-- reads '0' during the start bit, the parity bit and the stop bit -- a BUSY
-- built on it would blink mid-character. The honest signal is the FSM state
-- itself, rx_pstate /= idle, which is what this port exports.
--
-- Clause 6.iv: "You are given a VHDL design code that needs to be adapted" --
-- so adapting this code is what the requirement asks for, not a shortcut.
--============================================================================
--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART RECEIVER
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_RX is
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- PARITY CONTROL -- ADAPTED (BGU): runtime, from UCTL[2:1]. See the
        -- header. Defaulted so an unconnected instantiation means "none".
        PARITY_EN   : in  std_logic := '0'; -- UCTL[1] PENA
        PARITY_EVEN : in  std_logic := '1'; -- UCTL[2] PEV: 1 = even, 0 = odd
        -- UART INTERFACE
        UART_CLK_EN : in  std_logic; -- oversampling (16x) UART clock enable
        UART_RXD    : in  std_logic; -- serial receive data
        -- USER DATA OUTPUT INTERFACE
        DOUT        : out std_logic_vector(7 downto 0); -- output data received via UART
        DOUT_VLD    : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
        FRAME_ERROR : out std_logic; -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
        PARITY_ERROR: out std_logic; -- ADAPTED (BGU): one-cycle pulse, same shape as FRAME_ERROR -- UCTL bit 5 PE
        RX_BUSY     : out std_logic  -- ADAPTED (BGU): high for the whole frame, i.e. rx_pstate /= idle -- UCTL bit 7
    );
end UART_RX;

architecture FULL of UART_RX is

    signal rx_clk_en          : std_logic;
    signal rx_ticks           : unsigned(3 downto 0);
    signal rx_clk_divider_en  : std_logic;
    signal rx_data            : std_logic_vector(7 downto 0);
    signal rx_bit_count       : unsigned(2 downto 0);
    signal rx_receiving_data  : std_logic;
    signal rx_parity_bit      : std_logic;
    signal rx_parity_even     : std_logic;   -- ADAPTED (BGU): see above
    signal rx_parity_error    : std_logic;
    signal rx_parity_check_en : std_logic;
    signal rx_output_reg_en   : std_logic;

    type state is (idle, startbit, databits, paritybit, stopbit);
    signal rx_pstate : state;
    signal rx_nstate : state;

begin

    -- ADAPTED (BGU): the receive half of UCTL bit 7 BUSY. See the header.
    RX_BUSY <= '0' when (rx_pstate = idle) else '1';

    -- -------------------------------------------------------------------------
    -- UART RECEIVER CLOCK DIVIDER AND CLOCK ENABLE FLAG
    -- -------------------------------------------------------------------------

    uart_rx_clk_divider_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_clk_divider_en = '1') then
                if (UART_CLK_EN = '1') then
                    if (rx_ticks = "1111") then
                        rx_ticks <= (others => '0');
                    else
                        rx_ticks <= rx_ticks + 1;
                    end if;
                else
                    rx_ticks <= rx_ticks;
                end if;
            else
                rx_ticks <= (others => '0');
            end if;
        end if;
    end process;

    uart_rx_clk_en_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_clk_en <= '0';
            elsif (UART_CLK_EN = '1' AND rx_ticks = "0111") then
                rx_clk_en <= '1';
            else
                rx_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER BIT COUNTER
    -- -------------------------------------------------------------------------

    uart_rx_bit_counter_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_bit_count <= (others => '0');
            elsif (rx_clk_en = '1' AND rx_receiving_data = '1') then
                if (rx_bit_count = "111") then
                    rx_bit_count <= (others => '0');
                else
                    rx_bit_count <= rx_bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER DATA SHIFT REGISTER
    -- -------------------------------------------------------------------------

    uart_rx_data_shift_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_clk_en = '1' AND rx_receiving_data = '1') then
                rx_data <= UART_RXD & rx_data(7 downto 1);
            end if;
        end if;
    end process;

    DOUT <= rx_data;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER PARITY GENERATOR AND CHECK
    -- -------------------------------------------------------------------------

    -- ADAPTED (BGU): unconditional, always "even", with odd as its inverse --
    -- see the header. UART_PARITY.vhd stays exactly as its author wrote it.
    uart_rx_parity_gen_i: entity work.UART_PARITY
    generic map (
        DATA_WIDTH  => 8,
        PARITY_TYPE => "even"
    )
    port map (
        DATA_IN     => rx_data,
        PARITY_OUT  => rx_parity_even
    );

    rx_parity_bit <= rx_parity_even WHEN PARITY_EVEN = '1' ELSE NOT rx_parity_even;

    -- AND PARITY_EN IS LOAD-BEARING, and it is the one hazard that making this
    -- runtime introduces. Upstream could leave this register ungated because
    -- the whole process only existed in a parity build. Here it exists always,
    -- and it samples on EVERY rx_clk_en -- data bits and stop bit included, not
    -- just the parity bit. Without the AND, an 8N1 frame would latch a
    -- meaningless comparison and DOUT_VLD below (NOT rx_parity_error AND
    -- UART_RXD) would suppress perfectly good characters about half the time.
    -- With it, PARITY_EN = '0' pins the register at '0' -- exactly what the
    -- deleted uart_rx_noparity_g branch did.
    uart_rx_parity_check_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (rx_clk_en = '1') then
                rx_parity_error <= (rx_parity_bit XOR UART_RXD) AND PARITY_EN;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER OUTPUT REGISTER
    -- -------------------------------------------------------------------------

    uart_rx_output_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                DOUT_VLD <= '0';
                FRAME_ERROR <= '0';
                PARITY_ERROR <= '0';    -- ADAPTED (BGU)
            else
                if (rx_clk_en = '1' AND rx_output_reg_en = '1') then
                    DOUT_VLD <= NOT rx_parity_error AND UART_RXD;
                    FRAME_ERROR <= NOT UART_RXD;
                    -- ADAPTED (BGU): the same one-cycle shape as FRAME_ERROR,
                    -- announced at the same instant -- the end of the stop bit,
                    -- which is when this receiver decides the frame's fate.
                    -- Note what the line above already does with it, and that
                    -- it is UPSTREAM's choice, not ours: a parity-errored
                    -- character is NOT delivered (DOUT_VLD stays low), so
                    -- software learns of it through PE and the error interrupt
                    -- rather than through a corrupt byte in RXBUF.
                    -- Recorded as assumption A30.
                    PARITY_ERROR <= rx_parity_error;
                else
                    DOUT_VLD <= '0';
                    FRAME_ERROR <= '0';
                    PARITY_ERROR <= '0';
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART RECEIVER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                rx_pstate <= idle;
            else
                rx_pstate <= rx_nstate;
            end if;
        end if;
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (rx_pstate, UART_RXD, rx_clk_en, rx_bit_count)
    begin
        case rx_pstate is

            when idle =>
                rx_output_reg_en  <= '0';
                rx_receiving_data <= '0';
                rx_clk_divider_en <= '0';

                if (UART_RXD = '0') then
                    rx_nstate <= startbit;
                else
                    rx_nstate <= idle;
                end if;

            when startbit =>
                rx_output_reg_en  <= '0';
                rx_receiving_data <= '0';
                rx_clk_divider_en <= '1';

                if (rx_clk_en = '1') then
                    rx_nstate <= databits;
                else
                    rx_nstate <= startbit;
                end if;

            when databits =>
                rx_output_reg_en  <= '0';
                rx_receiving_data <= '1';
                rx_clk_divider_en <= '1';

                if ((rx_clk_en = '1') AND (rx_bit_count = "111")) then
                    if (PARITY_EN = '0') then        -- ADAPTED (BGU): runtime
                        rx_nstate <= stopbit;
                    else
                        rx_nstate <= paritybit;
                    end if ;
                else
                    rx_nstate <= databits;
                end if;

            when paritybit =>
                rx_output_reg_en  <= '0';
                rx_receiving_data <= '0';
                rx_clk_divider_en <= '1';

                if (rx_clk_en = '1') then
                    rx_nstate <= stopbit;
                else
                    rx_nstate <= paritybit;
                end if;

            when stopbit =>
                rx_output_reg_en  <= '1';
                rx_receiving_data <= '0';
                rx_clk_divider_en <= '1';

                if (rx_clk_en = '1') then
                    rx_nstate <= idle;
                else
                    rx_nstate <= stopbit;
                end if;

            when others =>
                rx_output_reg_en  <= '0';
                rx_receiving_data <= '0';
                rx_clk_divider_en <= '0';
                rx_nstate         <= idle;

        end case;
    end process;

end FULL;
