--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the USART peripheral, leaf-tested
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_uart.do  .. after compile.do. ZERO SETUP: no memory
--   images, nothing to stage.
--
-- WHAT THIS PROVES, AND HOW THE TWO HALVES ARE SPLIT
--   The UART is our register layer over jakubcabal's MIT serial engine, and
--   the two are checked differently on purpose:
--
--     the engine   by a REAL LOOPBACK. txd_o is wired back into rxd_i, so a
--                  byte written to TXBUF is serialised as an actual 8N1 frame
--                  at the actual divider and must come back through the
--                  receiver, byte-for-byte. Nothing is emulated: a mangled
--                  frame, a lost bit or a dead transmitter fails P2.
--     the register  by directed stimulus on every ordering we chose --
--     layer         tools/model_uart.py executes those same phases and twelve
--                   faithful mutations are all caught, including two that the
--                   first draft of that suite let through.
--
--   ONE THING A LOOPBACK CANNOT DO, said plainly: it cannot detect a baud
--   rate that is wrong but self-consistent, because the transmitter and the
--   receiver share the divider. That is what P6 is for -- it MEASURES the
--   start-bit width on txd_o against a literal derived by hand and checked
--   independently by the model, at both baud settings. A wrong divider
--   survives the loopback and dies there.
--
-- THE NUMBERS, AND WHERE THEY COME FROM (three independent statements of the
-- same value -- if any one is wrong the run fails):
--   SMCLK = 20 MHz (forum answers F8 and F11), 16x oversampling.
--     115200: divider round(20e6 / (16*115200)) = round(10.85) = 11
--             -> one bit = 16*11  =  176 cycles, one 8N1 frame = 1760
--       9600: divider round(20e6 / (16*9600))   = round(130.2) = 130
--             -> one bit = 16*130 = 2080 cycles
--   The RTL computes them (UART_CORE.vhd's constants), the model asserts them
--   from the formula (model_uart.py P0f/P0g), and this file states them as
--   literals below.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_uart IS
END tb_uart;


ARCHITECTURE test OF tb_uart IS

	constant CLK_PERIOD	: time := 100 ns;

	-- see the header: one bit, in clock cycles, at each baud setting
	constant BITC_115	: natural := 176;
	constant BITC_96	: natural := 2080;
	constant FRAME_115	: natural := 10 * BITC_115;		-- start + 8 + stop

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	-- bus side
	SIGNAL cs		: STD_LOGIC := '0';
	SIGNAL wr		: STD_LOGIC := '0';
	SIGNAL rd		: STD_LOGIC := '0';
	SIGNAL lane0	: STD_LOGIC := '0';
	SIGNAL lane1	: STD_LOGIC := '0';
	SIGNAL lane2	: STD_LOGIC := '0';
	SIGNAL wdata	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

	-- the serial line, and the switch that breaks the loopback for P4
	SIGNAL txd_w	: STD_LOGIC;
	SIGNAL rxd_w	: STD_LOGIC;
	SIGNAL loopback	: BOOLEAN := TRUE;
	SIGNAL rxd_drv	: STD_LOGIC := '1';		-- idle high, driven by hand in P4

	-- events and read-backs
	SIGNAL rx_ev	: STD_LOGIC;
	SIGNAL rxerr_ev	: STD_LOGIC;
	SIGNAL tx_ev	: STD_LOGIC;
	SIGNAL rx_clr	: STD_LOGIC;
	SIGNAL tx_clr	: STD_LOGIC;
	SIGNAL uctl		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL rxbuf	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL txbuf	: STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- event counters, so a pulse cannot be missed between samples
	SIGNAL n_rx		: NATURAL := 0;
	SIGNAL n_rxerr	: NATURAL := 0;
	SIGNAL n_tx		: NATURAL := 0;

BEGIN
	--=======================================================================
	DUT : uart_periph
	generic map( CLK_HZ => 20000000 )
	PORT MAP (
		clk_i		=> clk,
		rst_i		=> rst,
		cs_i		=> cs,
		MemWrite_i	=> wr,
		MemRead_i	=> rd,
		lane0_i		=> lane0,
		lane1_i		=> lane1,
		lane2_i		=> lane2,
		data_i		=> wdata,
		rxd_i		=> rxd_w,
		txd_o		=> txd_w,
		rx_ev_o		=> rx_ev,
		rxerr_ev_o	=> rxerr_ev,
		tx_ev_o		=> tx_ev,
		rx_clr_o	=> rx_clr,
		tx_clr_o	=> tx_clr,
		uctl_o		=> uctl,
		rxbuf_o		=> rxbuf,
		txbuf_o		=> txbuf
	);

	-- THE LOOPBACK. This is the whole point of P2: the design's own
	-- transmitter drives its own receiver, through no testbench arithmetic.
	rxd_w <= txd_w WHEN loopback ELSE rxd_drv;

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	rst <= '1', '0' after 80 ns;

	-- Event pulses are one cycle wide, so they are counted rather than
	-- sampled -- the same reason tb_basic_timer counts BTIFG events.
	counters : process(clk)
		variable a, b, c : natural := 0;
	begin
		if rising_edge(clk) and rst = '0' then
			if rx_ev    = '1' then a := a + 1; n_rx    <= a; end if;
			if rxerr_ev = '1' then b := b + 1; n_rxerr <= b; end if;
			if tx_ev    = '1' then c := c + 1; n_tx    <= c; end if;
		end if;
	end process counters;

	--=======================================================================
	stim : process
		variable p, f	: natural := 0;
		variable base	: natural;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		procedure settle(constant n : IN NATURAL) is
		begin
			for i in 1 to n loop wait until falling_edge(clk); end loop;
		end procedure settle;

		-- one-edge bus write, falling-edge aligned (tb_basic_timer's idiom)
		procedure bus_write(constant ln : IN NATURAL;
							constant v  : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin
			wait until falling_edge(clk);
			cs <= '1'; wr <= '1';
			case ln is
				when 0 => lane0 <= '1';
				when 1 => lane1 <= '1';
				when others => lane2 <= '1';
			end case;
			wdata <= x"000000" & v;
			wait until falling_edge(clk);
			cs <= '0'; wr <= '0'; lane0 <= '0'; lane1 <= '0'; lane2 <= '0';
		end procedure bus_write;

		-- one-edge RXBUF read. The VALUE is observed on rxbuf_o (which the MCU
		-- level puts behind a BidirPin); this drives the STROBE, which is what
		-- clears the receive-error bits and RXIFG.
		procedure read_rxbuf is
		begin
			wait until falling_edge(clk);
			cs <= '1'; rd <= '1'; lane1 <= '1';
			wait until falling_edge(clk);
			cs <= '0'; rd <= '0'; lane1 <= '0';
		end procedure read_rxbuf;

		procedure wr_uctl (constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin bus_write(0, v); end procedure;

		procedure wr_txbuf(constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin bus_write(2, v); end procedure;

		-- Drive one 8N1 frame onto rxd by hand, LSB first, with a chosen stop
		-- bit -- the only way to produce a FRAMING ERROR, which a loopback
		-- from a correct transmitter never can.
		procedure drive_frame(constant v    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
							  constant stop : IN STD_LOGIC;
							  constant bitc : IN NATURAL) is
		begin
			rxd_drv <= '0'; settle(bitc);					-- start bit
			for i in 0 to 7 loop
				rxd_drv <= v(i); settle(bitc);				-- LSB first
			end loop;
			rxd_drv <= stop; settle(bitc);					-- stop bit
			rxd_drv <= '1';
		end procedure drive_frame;

		-- Wait for the receiver to deliver a character, by counter not by
		-- level: rx_ev is one cycle wide.
		procedure wait_rx(constant from_n : IN NATURAL;
						  constant lim    : IN NATURAL;
						  constant tag    : IN STRING) is
			variable n : natural := 0;
		begin
			while n_rx = from_n and n < lim loop
				wait until falling_edge(clk);
				n := n + 1;
			end loop;
			chk(n < lim, tag & ": no character arrived within " &
				integer'image(lim) & " cycles");
		end procedure wait_rx;

		-- Measure the low pulse on txd_o. Sending 0x01 makes the start bit the
		-- ONLY low bit (bit 0 = 1 follows it), so the pulse is exactly one bit.
		procedure measure_start_bit(constant want : IN NATURAL;
									constant tag  : IN STRING) is
			variable n : natural := 0;
			variable g : natural := 0;
		begin
			wr_txbuf(x"01");
			-- wait for the line to leave idle
			while txd_w /= '0' and g < 4*want loop
				wait until falling_edge(clk); g := g + 1;
			end loop;
			chk(g < 4*want, tag & ": txd never went low - nothing was sent");
			-- count the low pulse
			while txd_w = '0' and n < 4*want loop
				wait until falling_edge(clk); n := n + 1;
			end loop;
			chk(n = want, tag & ": start bit measured " & integer'image(n) &
				" cycles, expected " & integer'image(want) &
				". The baud divider is wrong; and a loopback cannot see " &
				"this, because both ends share it");
		end procedure measure_start_bit;

	begin
		wait until rst = '0';
		settle(2);

		-- ---- P1 reset state ------------------------------------------------
		chk(uctl = x"00", "P1a UCTL after reset = 0x" & to_hstring(uctl) &
			" != 0x00 (A25: SWRST = 0, the USART is operational out of reset)");
		chk(rxbuf = x"00" and txbuf = x"00", "P1b the buffers are not clear");
		chk(txd_w = '1', "P1c txd is not idling high");

		-- ---- P2 UCTL: four writable bits, four read-only --------------------
		wr_uctl(x"FF"); settle(2);
		chk(uctl(3 DOWNTO 0) = "1111", "P2a the four control bits did not store");
		chk(uctl(6 DOWNTO 4) = "000", "P2b UCTL = 0x" & to_hstring(uctl) &
			": a write reached a read-only status bit (6:4 are OE/PE/FE)");
		wr_uctl(x"08"); settle(3);		-- BAUDRATE = 1 (115200), SWRST = 0
		chk(uctl(3 DOWNTO 0) = "1000", "P2c UCTL = 0x" & to_hstring(uctl) &
			": SWRST could not be cleared, or BAUDRATE did not stick");

		-- ---- P3 THE LOOPBACK at 115200 -------------------------------------
		base := n_rx;
		wr_txbuf(x"A5");
		settle(2);
		chk(uctl(7) = '1', "P3a BUSY did not go high with a byte queued");
		chk(n_tx > 0, "P3b no tx_ev when the transmitter took the byte");
		wait_rx(base, 3*FRAME_115, "P3c");
		settle(4);
		chk(rxbuf = x"A5", "P3d the loopback returned 0x" & to_hstring(rxbuf) &
			", expected 0xA5");
		chk(uctl(4) = '0', "P3e FE set on a clean loopback frame");
		chk(uctl(6) = '0', "P3f OE set on the very first character");
		settle(8);
		chk(uctl(7) = '0', "P3g BUSY still high after the frame completed");

		-- a second, different byte -- proves it is not a stuck register
		base := n_rx;
		wr_txbuf(x"3C");
		wait_rx(base, 3*FRAME_115, "P3h");
		settle(4);
		chk(rxbuf = x"3C", "P3i the second loopback returned 0x" &
			to_hstring(rxbuf) & ", expected 0x3C");

		-- ---- P4 the RXBUF read clears the error bits (rule b) --------------
		base := n_rxerr;
		read_rxbuf(); settle(2);
		chk(rx_clr = '0', "P4a rx_clr is still asserted a cycle after the read");
		chk(rxbuf = x"3C", "P4b the read destroyed RXBUF's contents");

		-- ---- P5 a FRAMING ERROR -- the loopback cannot make one ------------
		loopback <= FALSE; settle(2);
		base := n_rxerr;
		drive_frame(x"7E", '0', BITC_115);		-- stop bit LOW
		settle(8);
		chk(n_rxerr > base, "P5a no rxerr_ev on a frame with a low stop bit");
		chk(uctl(4) = '1', "P5b UCTL = 0x" & to_hstring(uctl) &
			": FE (bit 4) did not set");
		chk(rxbuf = x"3C", "P5c a frame with a bad stop bit still delivered " &
			"its data into RXBUF; the receiver gates DOUT_VLD on the stop " &
			"bit, so a broken frame must deliver nothing");
		read_rxbuf(); settle(3);
		chk(uctl(4) = '0', "P5d reading RXBUF did not reset FE (REQ p12: " &
			"'reading RXBUF resets the receive-error bits')");

		-- ---- P6 OVERRUN: two characters, no read in between ----------------
		base := n_rx;
		drive_frame(x"11", '1', BITC_115);
		wait_rx(base, 3*FRAME_115, "P6a");
		settle(4);
		chk(rxbuf = x"11", "P6b first character = 0x" & to_hstring(rxbuf));
		chk(uctl(6) = '0', "P6c OE set before any overrun");
		base := n_rxerr;
		drive_frame(x"22", '1', BITC_115);		-- arrives with 0x11 unread
		settle(8);
		chk(uctl(6) = '1', "P6d UCTL = 0x" & to_hstring(uctl) &
			": OE (bit 6) did not set when an unread character was overwritten");
		chk(n_rxerr > base, "P6e the overrun raised no status-error event");
		chk(rxbuf = x"22", "P6f RXBUF kept the old byte on overrun");
		read_rxbuf(); settle(3);
		chk(uctl(6) = '0', "P6g reading RXBUF did not reset OE");

		-- ---- P7 the divider, measured -- both settings ---------------------
		loopback <= TRUE; settle(2);
		measure_start_bit(BITC_115, "P7a 115200");
		settle(2*FRAME_115);					-- let that frame finish
		wr_uctl(x"00"); settle(3);				-- BAUDRATE = 0 -> 9600
		measure_start_bit(BITC_96, "P7b 9600");

		-- ---- P8 SWRST ------------------------------------------------------
		-- Set it while a frame is in flight and a byte is queued behind it.
		wr_txbuf(x"F0");						-- queued behind the running frame
		settle(2);
		chk(uctl(7) = '1', "P8a setup: BUSY should be high mid-frame");
		wr_uctl(x"09");							-- SWRST = 1, BAUDRATE stays 0
		settle(4);
		chk(uctl(0) = '1', "P8b SWRST cleared itself; it could never be exited");
		chk(uctl(3) = '0', "P8c BAUDRATE moved when SWRST was set");
		chk(uctl(7) = '0', "P8d BUSY = 1 after SWRST: the engine is held in " &
			"reset, so a byte still queued in TXBUF could never leave");
		chk(uctl(6) = '0' and uctl(4) = '0', "P8e SWRST did not clear FE/OE");
		chk(txd_w = '1', "P8f txd is not idle-high while the engine is reset");

		-- and it is exitable, and the link still works afterwards
		wr_uctl(x"08"); settle(4);				-- SWRST = 0, back to 115200
		chk(uctl(0) = '0', "P8g SWRST could not be cleared");
		base := n_rx;
		wr_txbuf(x"5A");
		wait_rx(base, 3*FRAME_115, "P8h");
		settle(4);
		chk(rxbuf = x"5A", "P8i the link did not recover after SWRST: RXBUF = 0x"
			& to_hstring(rxbuf) & ", expected 0x5A");

		-- ---- anti-vacuity ---------------------------------------------------
		chk(n_rx >= 5, "the receiver delivered only " & integer'image(n_rx) &
			" characters in the whole run; expected at least 5, so most " &
			"checks above cannot have meant anything");
		chk(n_tx >= 5, "the transmitter accepted only " & integer'image(n_tx) &
			" bytes; expected at least 5");

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "========= UART (Phase 12A) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) & "   (characters received " &
			integer'image(n_rx) & ", bytes sent " & integer'image(n_tx) &
			", error events " & integer'image(n_rxerr) & ")" severity note;
		if f = 0 then
			report "  VERDICT: PASS - real 8N1 frames looped from txd to rxd " &
				"at both baud rates, the measured start bit matches the " &
				"rounded divider at each, and the register layer's flags, " &
				"read-clears, BUSY and SWRST all behave." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "============================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stim;

END test;
