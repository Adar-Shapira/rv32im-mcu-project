--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the USART register layer (bonus, §6.iv)
--
-- OURS. The serial engine below it is jakubcabal's MIT code, adapted in
-- UART_CORE.vhd; everything in THIS file is new work, because neither
-- supplied option has any of it: no separate RXBUF/TXBUF, no overrun logic,
-- no aggregate BUSY, no SWRST, no software-selectable baud rate, and no bus
-- interface at all.
--
-- THE REGISTERS -- REQ p6 (the map) and REQ p12 (the layout)
--   0x2018  UCTL   byte, lane 0   (the map on p6 spells it UTCL; the p12
--                                  bit-field table is titled UCTL. Same
--                                  register, two spellings -- open question
--                                  P3. This file uses the table's name.)
--   0x2019  RXBUF  byte, lane 1   read-only
--   0x201A  TXBUF  byte, lane 2
--   All three share SFR word 6, CS_UART, split by A1..A0 -- forum answer F15:
--   "in the peripherals' address space any address value can be relevant
--   (byte addresses)". The chip select and its three lanes have existed and
--   been exhaustively tested since Phase 5A; this is their first consumer.
--
--   UCTL, from the p12 table, exactly:
--     [7] BUSY (r)  [6] OE (r)  [5] PE (r)  [4] FE (r)
--     [3] BAUDRATE (w)  [2] PEV (w)  [1] PENA (w)  [0] SWRST (w)
--   so a write stores only bits 3..0 and a read returns the four status bits
--   above the four control bits. A write to bits 7..4 is discarded, by the
--   table's own r/w row -- not by omission.
--
-- THE TWO RULES THAT MAKE THIS MORE THAN A REGISTER FILE
--   REQ p12: "Reading RXBUF resets the receive-error bits, and RXIFG."
--   REQ p12: "Writing to the transmit data buffer clears TXIFG."
--   The first is why this entity takes MemRead_i at all -- no other
--   peripheral in this project has a read side effect. Both flags live in the
--   interrupt controller, so their second halves leave here as rx_clr_o and
--   tx_clr_o; Phase 12B gives the controller the two inputs to consume them
--   (it already has rx_ev_i / rxerr_ev_i / tx_ev_i sitting at '0'). The
--   "...or when the interrupt is serviced" halves are already built --
--   INTERRUPT_CTRL.vhd's svc_rx_w / svc_tx_w, rules b and c.
--
-- WHAT RAISES EACH EVENT, AND WHY
--   rx_ev_o     a good character reached RXBUF (the core's dout_vld). RXIFG.
--   rxerr_ev_o  a framing error, or an overrun being set. REQ p14 gives the
--               UART status error its own TYPE (04h) but the SAME flag bit as
--               UART RX -- one RXIFG serving two vector rows, which is
--               assumption A23; the controller presents 08h.
--   tx_ev_o     the transmitter took the byte OUT of TXBUF, so TXBUF is free
--               again. That is the MSP430 meaning of TXIFG and the only one
--               consistent with "writing TXBUF clears TXIFG": the flag says
--               "you may write", so it is raised by the buffer emptying and
--               cleared by the write that refills it.
--
-- BUSY is an OR of three things, not one: the receiver mid-frame (the
-- RX_BUSY port added to UART_RX), the transmitter mid-frame (the core's
-- din_rdy low), and a byte still queued in TXBUF waiting for the
-- transmitter. Leaving the third out would let BUSY read 0 with a character
-- still unsent, which is exactly what a polling loop must not see.
--
-- ASSUMPTIONS, EACH WITH WHAT WOULD FALSIFY IT (mirrored into DOC/02)
--   A25  UCTL resets to 0x00, so SWRST = 0 and the USART is operational out
--        of reset. The p12 table gives SWRST's two meanings but no reset
--        value; the MSP430 this peripheral is modelled on resets it to 1.
--        Every other peripheral in this project resets its interface
--        registers to zero (F16 for the timer), and firmware written either
--        way still works -- an MSP430-style driver clears SWRST first, which
--        is a no-op here. Falsified by a supplied firmware that depends on
--        the USART being held in reset until configured.
--   A26  Parity is not implemented: the frame is 8N1. REQ p12's own feature
--        list says "8-bit data with non-parity", and its UCTL table says
--        "when PENA = 0, PE is read as 0" -- so with PENA = 0, which is the
--        reset state, this build is conformant. PENA and PEV are stored and
--        read back so software sees a real register, and PE reads 0 always.
--        Falsified by a benchmark that sets PENA = 1 and expects a parity
--        bit on the wire; the cost then is a runtime "is there a parity bit"
--        input threaded into the author's RX and TX state machines.
--   A27  TXBUF is readable. The p12 text describes it as "user accessible"
--        and the MSP430's is readable; no supplied program reads it. Costs
--        one reader. Falsified by nothing that matters -- if it should be
--        write-only, delete the reader.
--   A28  Baud switching is a program-order responsibility: writing UCTL[3]
--        mid-character corrupts that character. No hardware interlock is
--        built, because none is specified and one would silently delay a
--        write. UART_CORE's '>=' compare guarantees the divider re-locks
--        immediately rather than stalling, which is the part that must not
--        be left to software.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.aux_package.all;


ENTITY uart_periph IS
	generic(
		DATA_WIDTH	: integer := 32;
		CLK_HZ		: natural := 20000000		-- SMCLK (F8/F11); sizes the dividers
	);
	PORT(
		--Inputs
		clk_i			: IN	STD_LOGIC;		-- SMCLK (pclk_w at the top level)
		rst_i			: IN	STD_LOGIC;		-- active high

		-- write/read side, straight from the Phase 5 bus: one CS per SFR word
		cs_i			: IN	STD_LOGIC;		-- word 6: UCTL / RXBUF / TXBUF
		MemWrite_i		: IN	STD_LOGIC;
		MemRead_i		: IN	STD_LOGIC;		-- RXBUF's read side effect needs this
		lane0_i			: IN	STD_LOGIC;		-- A1A0=00 -> UCTL
		lane1_i			: IN	STD_LOGIC;		-- A1A0=01 -> RXBUF
		lane2_i			: IN	STD_LOGIC;		-- A1A0=10 -> TXBUF
		data_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

		-- the serial pins (clause 9's RS-232 / FTDI link; JP1 per F18/B1)
		rxd_i			: IN	STD_LOGIC := '1';	-- idle high

		--Outputs
		txd_o			: OUT	STD_LOGIC;

		-- interrupt sources and the two software-side clears (rules b and c)
		rx_ev_o			: OUT	STD_LOGIC;
		rxerr_ev_o		: OUT	STD_LOGIC;
		tx_ev_o			: OUT	STD_LOGIC;
		rx_clr_o		: OUT	STD_LOGIC;		-- RXBUF was read
		tx_clr_o		: OUT	STD_LOGIC;		-- TXBUF was written

		-- read-back (behind BidirPin at the MCU level, like every SFR read)
		uctl_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		rxbuf_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		txbuf_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END uart_periph;


ARCHITECTURE behavior OF uart_periph IS

	-- UCTL's four writable bits, in the p12 table's own order
	SIGNAL ctl_q		: STD_LOGIC_VECTOR(3 DOWNTO 0);	-- 3=BAUDRATE 2=PEV 1=PENA 0=SWRST

	SIGNAL rxbuf_q		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL txbuf_q		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL txbuf_vld_q	: STD_LOGIC;	-- a byte is queued for the transmitter
	SIGNAL full_q		: STD_LOGIC;	-- RXBUF holds a character nobody has read
	SIGNAL fe_q			: STD_LOGIC;
	SIGNAL pe_q			: STD_LOGIC;	-- Phase 12E: UCTL[5], a real flag now
	SIGNAL oe_q			: STD_LOGIC;

	-- bus strobes
	SIGNAL uctl_wr_w	: STD_LOGIC;
	SIGNAL txbuf_wr_w	: STD_LOGIC;
	SIGNAL rxbuf_rd_w	: STD_LOGIC;

	-- the serial engine
	SIGNAL core_rst_w	: STD_LOGIC;
	SIGNAL din_rdy_w	: STD_LOGIC;
	SIGNAL dout_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL dout_vld_w	: STD_LOGIC;
	SIGNAL frame_err_w	: STD_LOGIC;
	SIGNAL parity_err_w	: STD_LOGIC;	-- Phase 12E, from the receiver
	SIGNAL pe_read_w	: STD_LOGIC;	-- what a read of UCTL[5] returns
	SIGNAL rx_busy_w	: STD_LOGIC;

	SIGNAL tx_accept_w	: STD_LOGIC;
	SIGNAL oe_set_w		: STD_LOGIC;
	SIGNAL busy_w		: STD_LOGIC;
	SIGNAL swrst_w		: STD_LOGIC;

BEGIN
	--=======================================================================
	-- Bus strobes -- basic_timer's idiom, plus the one read strobe
	--=======================================================================
	uctl_wr_w	<= cs_i AND MemWrite_i AND lane0_i;
	txbuf_wr_w	<= cs_i AND MemWrite_i AND lane2_i;
	rxbuf_rd_w	<= cs_i AND MemRead_i  AND lane1_i;
	-- A write to lane1 (RXBUF) has no path anywhere in this file: REQ p12
	-- describes RXBUF as receive data, so it is read-only BY THE TABLE, not
	-- by omission -- the same posture as PORT_PB.

	swrst_w		<= ctl_q(0);

	-- SWRST holds "the USART logic" in reset (REQ p12) -- the serial engine
	-- and the flags, NEVER UCTL itself: a reset that cleared its own SWRST bit
	-- could not be exited, and one that cleared BAUDRATE would silently drop
	-- back to 9600.
	core_rst_w	<= rst_i OR swrst_w;

	--=======================================================================
	-- The serial engine (jakubcabal, MIT -- adapted in UART_CORE.vhd)
	--=======================================================================
	CORE : uart_core
	generic map(
		CLK_HZ	=> CLK_HZ
	)
	PORT MAP(
		clk_i		=> clk_i,
		rst_i		=> core_rst_w,
		baud_sel_i	=> ctl_q(3),			-- UCTL[3]: 0 = 9600, 1 = 115200
		-- Phase 12E. These two used to have no consumer: PENA and PEV were
		-- stored and read back and changed nothing, which made them stubs.
		-- Now they reach the shift registers.
		--
		-- One thing worth naming: nothing interlocks a change of PENA against a
		-- character already on the wire, for the same reason nothing interlocks
		-- BAUDRATE (A28) -- an interlock would silently defer a software write,
		-- and the specification describes none. Changing the frame format
		-- mid-character corrupts that character, and that is program order's
		-- responsibility. BUSY is what software polls to know it is safe.
		parity_en_i	=> ctl_q(1),			-- UCTL[1] PENA
		parity_even_i	=> ctl_q(2),		-- UCTL[2] PEV: 1 = even, 0 = odd
		rxd_i		=> rxd_i,
		din_i		=> txbuf_q,
		din_vld_i	=> txbuf_vld_q,
		txd_o		=> txd_o,
		din_rdy_o	=> din_rdy_w,
		dout_o		=> dout_w,
		dout_vld_o	=> dout_vld_w,
		frame_err_o	=> frame_err_w,
		parity_err_o	=> parity_err_w,		-- Phase 12E
		rx_busy_o	=> rx_busy_w
	);

	--=======================================================================
	-- UCTL -- only bits 3..0 are stored; 7..4 are hardware status
	--=======================================================================
	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			ctl_q <= (OTHERS => '0');		-- A25: SWRST = 0, operational
		elsif rising_edge(clk_i) then
			if uctl_wr_w = '1' then
				ctl_q <= data_i(3 DOWNTO 0);
			end if;
		end if;
	end process;

	--=======================================================================
	-- TXBUF and its valid flag.
	--
	-- The accept condition is the author's own, taken from his file rather
	-- than guessed: UART_TX.vhd latches tx_data on (DIN_VLD = '1' AND
	-- tx_ready = '1') at line 94 of the original, which is the same edge the
	-- FSM leaves idle on. So holding txbuf_q stable until din_rdy_w is high
	-- and clearing on that cycle hands over exactly one byte.
	--
	-- A write WINS over the accept in the same cycle: the transmitter latches
	-- the pre-edge txbuf_q (the old byte, correctly) while txbuf_q takes the
	-- new one and stays valid. Ordering it the other way would drop the write.
	--=======================================================================
	tx_accept_w <= txbuf_vld_q AND din_rdy_w;

	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			txbuf_q		<= (OTHERS => '0');
			txbuf_vld_q	<= '0';
		elsif rising_edge(clk_i) then
			if swrst_w = '1' then
				-- the engine is in reset, so a queued byte can never leave;
				-- dropping it is the only state that is not a silent hang
				txbuf_vld_q <= '0';
			elsif txbuf_wr_w = '1' then
				txbuf_q		<= data_i(7 DOWNTO 0);
				txbuf_vld_q	<= '1';
			elsif tx_accept_w = '1' then
				txbuf_vld_q	<= '0';
			end if;
		end if;
	end process;

	--=======================================================================
	-- RXBUF, the full flag, and the two receive-error flags.
	--
	-- "Reading RXBUF resets the receive-error bits, and RXIFG" (REQ p12), so
	-- a read clears FE, OE and the full flag. A read that coincides with a
	-- new character must leave the NEW character's state, not the old one --
	-- which is why the clear and the set are sequenced through variables
	-- inside one process instead of racing as two arms of an if.
	--
	-- That sequencing also settles overrun correctly: a character arriving in
	-- the same cycle its predecessor is read is NOT an overrun, because the
	-- predecessor was read. oe_set_w below is that exact condition, and it is
	-- also the event the interrupt controller sees.
	--=======================================================================
	oe_set_w <= dout_vld_w AND full_q AND (NOT rxbuf_rd_w);

	process(clk_i, rst_i)
		variable full_v	: STD_LOGIC;
		variable fe_v	: STD_LOGIC;
		variable pe_v	: STD_LOGIC;
		variable oe_v	: STD_LOGIC;
	begin
		if rst_i = '1' then
			rxbuf_q	<= (OTHERS => '0');
			full_q	<= '0';
			fe_q	<= '0';
			pe_q	<= '0';
			oe_q	<= '0';
		elsif rising_edge(clk_i) then
			full_v := full_q;
			fe_v   := fe_q;
			pe_v   := pe_q;
			oe_v   := oe_q;

			if swrst_w = '1' then
				full_v := '0';
				fe_v   := '0';
				pe_v   := '0';
				oe_v   := '0';
			else
				-- 1. the software read clears first. REQ p12: "reading RXBUF
				-- resets the receive-error BITS, and RXIFG" -- plural, so PE
				-- clears here exactly like FE and OE. Phase 12E.
				if rxbuf_rd_w = '1' then
					full_v := '0';
					fe_v   := '0';
					pe_v   := '0';
					oe_v   := '0';
				end if;
				-- 2. then this cycle's arrivals set
				if dout_vld_w = '1' then
					rxbuf_q <= dout_w;
					if full_v = '1' then
						oe_v := '1';		-- overrun: unread byte overwritten
					end if;
					full_v := '1';
				end if;
				if frame_err_w = '1' then
					fe_v := '1';
				end if;
				-- Phase 12E. Note what is NOT here: no `full_v := '1'` and no
				-- rxbuf_q write. A parity-errored character is not delivered --
				-- the receiver holds DOUT_VLD low for it (upstream's own
				-- choice, kept: assumption A30) -- so PE plus the error
				-- interrupt is how software learns, and RXBUF keeps whatever it
				-- held. The alternative, delivering a byte known to be corrupt,
				-- would be inventing behaviour the specification does not
				-- describe.
				if parity_err_w = '1' then
					pe_v := '1';
				end if;
			end if;

			full_q	<= full_v;
			fe_q	<= fe_v;
			pe_q	<= pe_v;
			oe_q	<= oe_v;
		end if;
	end process;

	--=======================================================================
	-- Status, events and read-backs
	--=======================================================================
	-- Three terms, not one -- see the header.
	busy_w <= rx_busy_w OR (NOT din_rdy_w) OR txbuf_vld_q;

	rx_ev_o		<= dout_vld_w;
	-- Phase 12E adds the parity error. REQ p14 gives TYPE 04h to "USART status
	-- error" and all three of FE, PE and OE are status errors, so all three
	-- raise the same request.
	rxerr_ev_o	<= frame_err_w OR parity_err_w OR oe_set_w;
	tx_ev_o		<= tx_accept_w;
	rx_clr_o	<= rxbuf_rd_w;
	tx_clr_o	<= txbuf_wr_w;

	-- [7] BUSY  [6] OE  [5] PE  [4] FE  [3] BAUDRATE  [2] PEV  [1] PENA  [0] SWRST
	--
	-- PE, Phase 12E. REQ p12 says "when PENA = 0, PE is read as 0", so the
	-- stored flag is ANDed with PENA on the way out rather than being prevented
	-- from setting: the receiver already cannot set it with parity disabled
	-- (its check register is gated by PARITY_EN), so this AND is the second of
	-- two independent reasons the bit reads 0 in 8N1 -- belt and braces on a
	-- sentence the specification states outright.
	pe_read_w	<= pe_q AND ctl_q(1);
	uctl_o		<= busy_w & oe_q & pe_read_w & fe_q & ctl_q;
	rxbuf_o		<= rxbuf_q;
	txbuf_o		<= txbuf_q;		-- A27

END behavior;
