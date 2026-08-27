--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12C: clause 8's menu on the PIPELINED MCU
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_uart_menu.do -- stages the SAME generated
--   images the single-cycle test uses (SIM/RV32IMscMCU/menusim/). NOTE
--   menusim, not menu: the two sets share a byte-identical ITCM and differ
--   only in the V_HALFSEC word, 9,999,999 for the board's 0.5 s and 1,999 so
--   a simulation finishes.
--
--   The checks below are IDENTICAL to TB/RV32IMscMCU/tb_uart_menu.vhd; only
--   the instantiation differs. What it adds is the CORE: this firmware is
--   interrupt-driven at three sources, so it is the densest exercise of the
--   pipelined entry protocol in the project -- an RX interrupt can land in
--   the middle of a character being pushed out, a timer tick in the middle of
--   the dispatch, and a KEY1 release during either.
--
-- WHAT THIS IS
--   The first test in this project where the testbench plays a THIRD PARTY
--   rather than watching. It is the PC of clause 8: it shifts characters onto
--   UART_RXD_i at the real bit time and it decodes UART_TXD_o back into
--   characters, mid-bit, exactly as a terminal would. Then it drives clause
--   8's menu the way a person would at a Tera-Term window:
--
--     1. collect the startup menu                    -> send '2'
--     2. four LED values counting down from 0xFF     -> send '1'
--     3. four LED values counting up from 0x00       -> send '3'
--     4. LEDs cleared and the counting has stopped   -> send '4'
--     5. press and RELEASE KEY1                      -> collect the message
--     6. send '5'                                    -> collect the menu again
--
--   Everything the MCU does in between is firmware and hardware: the RX
--   interrupt that delivers each command, the Basic Timer's EQU0 as the tick,
--   PORT_LEDR, KEY1 through the interrupt controller with its manual clear
--   (rule d), and one character per main-loop pass out of TXBUF.
--
-- WHY THE EXPECTED TEXT IS SAFE TO TRUST
--   MENU_TXT and NEGEV_TXT below are GENERATED. tools/gen_uart_menu.py writes
--   the same two strings into the DTCM image and then reads this file back and
--   fails if these two lines do not match it verbatim. Two copies of a string,
--   one edited, is the failure this project has already been bitten by once.
--
-- WHAT IT DOES NOT PROVE
--   The ~0.5 s wall-clock delay: the simulated image ticks every 2000 cycles.
--   The delay is one DTCM word and the board image carries 9,999,999, which is
--   10,000,000 SMCLK ticks -- cross-checked against the supplied benchmarks'
--   own SEC_PERIOD = 20,000,000 for one second at the same BTSSEL setting.
--   And not the PC end of clause 9: that is a real terminal on real hardware.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_uart_menu IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_uart_menu;


ARCHITECTURE test OF tb_uart_menu IS

	constant CLK_PERIOD	: time := 100 ns;

	-- One 8N1 bit is 16 oversampling steps of the runtime divider, and at
	-- CLK_HZ = 20 MHz with BAUDRATE = 1 that divider is 11: 16*11 = 176 cycles
	-- per bit, the same number tb_uart.vhd MEASURES out of the real engine.
	constant BITC		: natural := 176;
	constant BIT_TIME	: time := BITC * CLK_PERIOD;

	-- 423 characters at 1760 cycles each is the bulk of the run; the LED
	-- phases add a few tens of thousands. 200 ms is roughly 2.5x the expected
	-- 75 ms and keeps a hung run from sitting there for minutes.
	constant DEADLINE	: time := 200 ms;

	--=== GENERATED -- see tools/gen_uart_menu.py, which checks these lines ===
	constant MENU_TXT  : string := CR & LF & "Menu" & CR & LF & "1. Count from 0x00 onto LEDR with delay ~0.5sec" & CR & LF & "2. Count down from 0xFF onto LEDR with delay ~0.5sec" & CR & LF & "3. Clear all LEDs" & CR & LF & "4. On each KEY1 pressed, send the message I love my Negev" & CR & LF & "5. Show Menu" & CR & LF;
	constant NEGEV_TXT : string := "I love my Negev" & CR & LF;
	--=== end generated ======================================================

	constant CAPMAX		: natural := 1024;
	constant LEDMAX		: natural := 128;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL mcu_txd	: STD_LOGIC;					-- what the MCU transmits
	SIGNAL pc_txd	: STD_LOGIC := '1';				-- what the "PC" transmits
	SIGNAL key_pins	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "111";	-- raw, active-low
	SIGNAL ledr		: STD_LOGIC_VECTOR(9 DOWNTO 0);

	-- the decoded receive buffer, written only by the monitor process
	SIGNAL cap		: string(1 TO CAPMAX) := (OTHERS => ' ');
	SIGNAL ncap		: NATURAL := 0;

	-- every value PORT_LEDR took, written only by the LED watcher
	type led_arr_t is array (1 TO LEDMAX) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL led_seq	: led_arr_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nled		: NATURAL := 0;

BEGIN
	--=======================================================================
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,		-- the stimulus below is active-high
		MODELSIM		=> MODELSIM
		-- KEY_ACTIVE_LOW keeps its TRUE default: key_pins are the raw
		-- board-polarity pins, idle '1', pressed '0'
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		KEY_i			=> key_pins,
		UART_RXD_i		=> pc_txd,
		UART_TXD_o		=> mcu_txd,
		LEDR_o			=> ledr
	);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	rst <= '1', '0' after 80 ns;

	--=======================================================================
	-- The PC's receiver. Waits for a start bit, samples the eight data bits
	-- at their MIDPOINTS, LSB first, and appends the character. No knowledge
	-- of the transmitter beyond 8N1 and the bit time.
	--=======================================================================
	rx_monitor : process
		variable b  : STD_LOGIC_VECTOR(7 DOWNTO 0);
		variable nv : NATURAL := 0;
	begin
		wait until rst = '0';
		loop
			wait until falling_edge(mcu_txd);		-- the start bit
			wait for BIT_TIME + BIT_TIME/2;			-- the middle of bit 0
			for i in 0 TO 7 loop
				b(i) := mcu_txd;
				if i < 7 then
					wait for BIT_TIME;
				end if;
			end loop;
			wait for BIT_TIME;						-- into the stop bit
			nv := nv + 1;
			if nv <= CAPMAX then
				cap(nv) <= character'val(to_integer(unsigned(b)));
				ncap    <= nv;
			end if;
		end loop;
	end process rx_monitor;

	--=======================================================================
	-- Every value PORT_LEDR takes, in order. The firmware writes the byte
	-- once per timer tick, so this is the count sequence itself.
	--=======================================================================
	led_watch : process(ledr)
		variable nv : NATURAL := 0;
	begin
		if now > 100 ns and nv < LEDMAX then
			nv := nv + 1;
			led_seq(nv) <= ledr(7 DOWNTO 0);
			nled        <= nv;
		end if;
	end process led_watch;

	--=======================================================================
	verdict : process
		variable p, f : natural := 0;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		-- one character out of the PC, 8N1 at the real bit time
		procedure send_char(constant c : IN character) is
			variable v : STD_LOGIC_VECTOR(7 DOWNTO 0);
		begin
			v := STD_LOGIC_VECTOR(to_unsigned(character'pos(c), 8));
			pc_txd <= '0';							-- start
			wait for BIT_TIME;
			for i in 0 TO 7 loop					-- data, LSB first
				pc_txd <= v(i);
				wait for BIT_TIME;
			end loop;
			pc_txd <= '1';							-- stop, plus an idle bit
			wait for 2*BIT_TIME;
		end procedure send_char;

		-- wait until the monitor has decoded n characters in total
		procedure wait_bytes(constant n : IN natural; constant what : IN string) is
		begin
			while ncap < n and now < DEADLINE loop
				wait for BIT_TIME;
			end loop;
			chk(ncap >= n, "timed out waiting for " & what & ": " &
				integer'image(ncap) & " character(s) decoded, expected " &
				integer'image(n));
		end procedure wait_bytes;

		-- wait until the LED watcher has seen n values in total
		procedure wait_leds(constant n : IN natural; constant what : IN string) is
		begin
			while nled < n and now < DEADLINE loop
				wait for 20*CLK_PERIOD;
			end loop;
			chk(nled >= n, "timed out waiting for " & what & ": " &
				integer'image(nled) & " LED value(s) seen, expected " &
				integer'image(n));
		end procedure wait_leds;

		-- compare a decoded run against an expected string, naming the first
		-- character that differs rather than dumping both walls of text
		procedure chkstr(constant frm : IN natural; constant expect : IN string;
						 constant msg : IN string) is
			variable bad : natural := 0;
		begin
			for i in expect'range loop
				if bad = 0 and frm + i - 1 <= CAPMAX then
					if cap(frm + i - 1) /= expect(i) then
						bad := i;
					end if;
				end if;
			end loop;
			if bad = 0 then
				chk(TRUE, msg);
			else
				chk(FALSE, msg & ": character " & integer'image(bad) & " of " &
					integer'image(expect'length) & " decoded as 0x" &
					to_hstring(to_unsigned(character'pos(cap(frm + bad - 1)), 8)) &
					", expected 0x" &
					to_hstring(to_unsigned(character'pos(expect(bad)), 8)));
			end if;
		end procedure chkstr;

		-- find the first LED value equal to v, at or after index frm.
		-- IMPURE because it reads led_seq, a signal declared outside it.
		impure function led_find(constant v : STD_LOGIC_VECTOR(7 DOWNTO 0);
						  constant frm : natural; constant upto : natural)
			return natural is
		begin
			for i in frm TO upto loop
				if led_seq(i) = v then
					return i;
				end if;
			end loop;
			return 0;
		end function led_find;

		variable i0, i1 : natural;
		variable mark   : natural;

	begin
		wait until rst = '0';

		-- ---- 1. the startup menu -------------------------------------------
		wait_bytes(MENU_TXT'length, "the startup menu");
		chkstr(1, MENU_TXT, "the startup menu, transmitted MCU -> PC");

		-- ---- 2. item 2: count down from 0xFF -------------------------------
		mark := nled;
		send_char('2');
		wait_leds(mark + 1, "the first LED value after selecting item 2");
		i0 := led_find(x"FF", mark + 1, nled);
		chk(i0 /= 0, "PORT_LEDR never took 0xFF after item 2: the count-down " &
			"either did not start or did not start from 0xFF");
		if i0 /= 0 then
			wait_leds(i0 + 3, "four values of the count-down");
			chk(led_seq(i0 + 1) = x"FE", "count-down value 2 is 0x" &
				to_hstring(led_seq(i0 + 1)) & ", expected 0xFE");
			chk(led_seq(i0 + 2) = x"FD", "count-down value 3 is 0x" &
				to_hstring(led_seq(i0 + 2)) & ", expected 0xFD");
			chk(led_seq(i0 + 3) = x"FC", "count-down value 4 is 0x" &
				to_hstring(led_seq(i0 + 3)) & ", expected 0xFC");
		end if;

		-- ---- 3. item 1: count up from 0x00 ---------------------------------
		mark := nled;
		send_char('1');
		wait_leds(mark + 1, "the first LED value after selecting item 1");
		i1 := led_find(x"00", mark + 1, nled);
		chk(i1 /= 0, "PORT_LEDR never took 0x00 after item 1: the count-up " &
			"either did not start or did not start from 0x00");
		if i1 /= 0 then
			wait_leds(i1 + 3, "four values of the count-up");
			chk(led_seq(i1 + 1) = x"01", "count-up value 2 is 0x" &
				to_hstring(led_seq(i1 + 1)) & ", expected 0x01");
			chk(led_seq(i1 + 2) = x"02", "count-up value 3 is 0x" &
				to_hstring(led_seq(i1 + 2)) & ", expected 0x02");
			chk(led_seq(i1 + 3) = x"03", "count-up value 4 is 0x" &
				to_hstring(led_seq(i1 + 3)) & ", expected 0x03");
		end if;

		-- ---- 4. item 3: clear, and the counting must STOP ------------------
		send_char('3');
		wait for 40*BIT_TIME;					-- several ticks' worth
		chk(ledr(7 DOWNTO 0) = x"00", "PORT_LEDR reads 0x" &
			to_hstring(ledr(7 DOWNTO 0)) & " after item 3, expected 0x00");
		mark := nled;
		wait for 40*BIT_TIME;
		chk(nled = mark, "PORT_LEDR changed " & integer'image(nled - mark) &
			" more time(s) after item 3: clearing must also stop the count");

		-- ---- 5. item 4 + a KEY1 press --------------------------------------
		mark := ncap;
		send_char('4');
		wait for 20*BIT_TIME;					-- let the command be dispatched
		key_pins(1) <= '0';						-- press (active-low pin)
		wait for 20*CLK_PERIOD;
		key_pins(1) <= '1';						-- RELEASE: the request event
		wait_bytes(mark + NEGEV_TXT'length, "the KEY1 message");
		chkstr(mark + 1, NEGEV_TXT, "the message sent on the KEY1 release");

		-- ---- 6. item 5: show the menu again --------------------------------
		mark := ncap;
		send_char('5');
		wait_bytes(mark + MENU_TXT'length, "the menu after item 5");
		chkstr(mark + 1, MENU_TXT, "the menu re-transmitted for item 5");

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "========= UART MENU (Phase 12C) SUMMARY =========" severity note;
		report "  characters decoded from UART_TXD_o: " & integer'image(ncap)
			severity note;
		report "  PORT_LEDR values observed: " & integer'image(nled) severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - clause 8's menu ran end to end against a " &
				"bench acting as the PC terminal: the menu transmitted, all " &
				"five items exercised, the LED count up and down, the KEY1 " &
				"message on the release edge, and the menu re-shown."
				severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "=================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
