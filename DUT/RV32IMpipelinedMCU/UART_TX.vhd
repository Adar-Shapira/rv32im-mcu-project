--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the UART peripheral (bonus, clause 6.iv)
--
-- THIRD-PARTY FILE, USED UNDER THE MIT LICENCE. The licence header below is
-- the author's own and must stay. Provenance:
--   Auxiliary/USART Material/UART_FPGA_option1/rtl/comp/uart_tx.vhd
--   jakubcabal/uart-for-fpga v1.1, MIT, Copyright (c) 2015 Jakub Cabal
--   original md5 b2fcd485105f909d318f9d218a05708f
--
-- Clause 6.iv: "You are given a VHDL design code that needs to be adapted" --
-- so adapting this code is what the requirement asks for, not a shortcut.
-- ONE SEMANTIC CHANGE, made in Phase 12E: PARITY IS RUNTIME, NOT COMPILE-TIME.
-- Everything else is byte-identical -- DIN/DIN_VLD/DIN_RDY is a plain
-- valid-ready handshake, and the data is latched by the SAME condition that
-- leaves the idle state (DIN_VLD='1' AND tx_ready='1'), so the register layer
-- can hold TXBUF stable until that accept and clear on it.
--
-- WHY THE CHANGE WAS NECESSARY
--   Upstream selects parity with a STRING GENERIC, so a build is 8N1 or 8E1 or
--   8O1 for ever. REQ p12 makes it a pair of WRITABLE REGISTER BITS -- UCTL[1]
--   PENA "Parity enabled. Parity bit is generated (TXD) and expected (RXD)"
--   and UCTL[2] PEV "0 Odd parity / 1 Even parity" -- and UCTL[5] PE is a
--   readable parity-error flag. A generic cannot implement a register field.
--   Phase 12A stored PENA/PEV and left them inert, reading PE as a constant 0,
--   and recorded that as assumption A26. That reading was the cheap one, not
--   the right one: a register software can write and that does nothing is a
--   stub, and PE is one of the three error flags §6.iv's own feature list
--   requires ("Status flags for error detection").
--
-- WHAT CHANGED, EXACTLY THREE PLACES
--   1. the PARITY_BIT generic is gone, replaced by two input ports,
--      PARITY_EN and PARITY_EVEN, both defaulted so an upstream-style
--      instantiation still means "none";
--   2. UART_PARITY is instantiated UNCONDITIONALLY with PARITY_TYPE => "even"
--      and the odd case is one inversion, because odd parity IS the inverse of
--      even parity -- so UART_PARITY.vhd itself stays byte-identical to
--      upstream and no second instance is spent on it;
--   3. the databits state tests PARITY_EN instead of the generic.
--   With PARITY_EN = '0' the paritybit state is unreachable exactly as before,
--   so the 8N1 path is bit-for-bit the path Phase 12A verified.
--============================================================================
--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  UART TRANSMITTER
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart-for-fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_TX is
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- PARITY CONTROL -- ADAPTED (BGU): runtime, from UCTL[2:1]. See the
        -- header. Defaulted so an unconnected instantiation means "none",
        -- which is what upstream's default generic meant.
        PARITY_EN   : in  std_logic := '0'; -- UCTL[1] PENA
        PARITY_EVEN : in  std_logic := '1'; -- UCTL[2] PEV: 1 = even, 0 = odd
        -- UART INTERFACE
        UART_CLK_EN : in  std_logic; -- oversampling (16x) UART clock enable
        UART_TXD    : out std_logic; -- serial transmit data
        -- USER DATA INPUT INTERFACE
        DIN         : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
        DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
        DIN_RDY     : out std_logic  -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
    );
end UART_TX;

architecture FULL of UART_TX is

    signal tx_clk_en         : std_logic;
    signal tx_clk_divider_en : std_logic;
    signal tx_ticks          : unsigned(3 downto 0);
    signal tx_data           : std_logic_vector(7 downto 0);
    signal tx_bit_count      : unsigned(2 downto 0);
    signal tx_bit_count_en   : std_logic;
    signal tx_ready          : std_logic;
    signal tx_parity_bit     : std_logic;
    signal tx_parity_even    : std_logic;   -- ADAPTED (BGU): see above
    signal tx_data_out_sel   : std_logic_vector(1 downto 0);

    type state is (idle, txsync, startbit, databits, paritybit, stopbit);
    signal tx_pstate : state;
    signal tx_nstate : state;

begin

    DIN_RDY <= tx_ready;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER CLOCK DIVIDER
    -- -------------------------------------------------------------------------

    uart_tx_clk_divider_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (tx_clk_divider_en = '1') then
                if (uart_clk_en = '1') then
                    if (tx_ticks = "1111") then
                        tx_ticks <= (others => '0');
                    else
                        tx_ticks <= tx_ticks + 1;
                    end if;
                else
                    tx_ticks <= tx_ticks;
                end if;
            else
                tx_ticks <= (others => '0');
            end if;
        end if;
    end process;

    uart_tx_clk_en_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_clk_en <= '0';
            elsif (uart_clk_en = '1' AND tx_ticks = "0001") then
                tx_clk_en <= '1';
            else
                tx_clk_en <= '0';
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER INPUT DATA REGISTER
    -- -------------------------------------------------------------------------

    uart_tx_input_data_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (DIN_VLD = '1' AND tx_ready = '1') then
                tx_data <= DIN;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER BIT COUNTER
    -- -------------------------------------------------------------------------

    uart_tx_bit_counter_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_bit_count <= (others => '0');
            elsif (tx_bit_count_en = '1' AND tx_clk_en = '1') then
                if (tx_bit_count = "111") then
                    tx_bit_count <= (others => '0');
                else
                    tx_bit_count <= tx_bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER PARITY GENERATOR
    -- -------------------------------------------------------------------------

    -- ADAPTED (BGU): unconditional, always "even", with odd taken as its
    -- inverse. Odd parity IS the inverse of even parity for any word, so one
    -- instance and one XNOR cover both -- and UART_PARITY.vhd stays exactly
    -- as its author wrote it. tx_parity_bit is only ever driven onto the wire
    -- in the paritybit state, which PARITY_EN = '0' makes unreachable, so no
    -- gating is needed here.
    uart_tx_parity_gen_i: entity work.UART_PARITY
    generic map (
        DATA_WIDTH  => 8,
        PARITY_TYPE => "even"
    )
    port map (
        DATA_IN     => tx_data,
        PARITY_OUT  => tx_parity_even
    );

    tx_parity_bit <= tx_parity_even WHEN PARITY_EVEN = '1' ELSE NOT tx_parity_even;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER OUTPUT DATA REGISTER
    -- -------------------------------------------------------------------------

    uart_tx_output_data_reg_p : process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                UART_TXD <= '1';
            else
                case tx_data_out_sel is
                    when "01" => -- START BIT
                        UART_TXD <= '0';
                    when "10" => -- DATA BITS
                        UART_TXD <= tx_data(to_integer(tx_bit_count));
                    when "11" => -- PARITY BIT
                        UART_TXD <= tx_parity_bit;
                    when others => -- STOP BIT OR IDLE
                        UART_TXD <= '1';
                end case;
            end if;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- UART TRANSMITTER FSM
    -- -------------------------------------------------------------------------

    -- PRESENT STATE REGISTER
    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (RST = '1') then
                tx_pstate <= idle;
            else
                tx_pstate <= tx_nstate;
            end if;
        end if;
    end process;

    -- NEXT STATE AND OUTPUTS LOGIC
    process (tx_pstate, DIN_VLD, tx_clk_en, tx_bit_count)
    begin

        case tx_pstate is

            when idle =>
                tx_ready <= '1';
                tx_data_out_sel <= "00";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '0';

                if (DIN_VLD = '1') then
                    tx_nstate <= txsync;
                else
                    tx_nstate <= idle;
                end if;

            when txsync =>
                tx_ready <= '0';
                tx_data_out_sel <= "00";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '1';

                if (tx_clk_en = '1') then
                    tx_nstate <= startbit;
                else
                    tx_nstate <= txsync;
                end if;

            when startbit =>
                tx_ready <= '0';
                tx_data_out_sel <= "01";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '1';

                if (tx_clk_en = '1') then
                    tx_nstate <= databits;
                else
                    tx_nstate <= startbit;
                end if;

            when databits =>
                tx_ready <= '0';
                tx_data_out_sel <= "10";
                tx_bit_count_en <= '1';
                tx_clk_divider_en <= '1';

                if ((tx_clk_en = '1') AND (tx_bit_count = "111")) then
                    if (PARITY_EN = '0') then        -- ADAPTED (BGU): runtime
                        tx_nstate <= stopbit;
                    else
                        tx_nstate <= paritybit;
                    end if ;
                else
                    tx_nstate <= databits;
                end if;

            when paritybit =>
                tx_ready <= '0';
                tx_data_out_sel <= "11";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '1';

                if (tx_clk_en = '1') then
                    tx_nstate <= stopbit;
                else
                    tx_nstate <= paritybit;
                end if;

            when stopbit =>
                tx_ready <= '1';
                tx_data_out_sel <= "00";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '1';

                if (DIN_VLD = '1') then
                    tx_nstate <= txsync;
                elsif (tx_clk_en = '1') then
                    tx_nstate <= idle;
                else
                    tx_nstate <= stopbit;
                end if;

            when others =>
                tx_ready <= '0';
                tx_data_out_sel <= "00";
                tx_bit_count_en <= '0';
                tx_clk_divider_en <= '0';
                tx_nstate <= idle;

        end case;
    end process;

end FULL;
