--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 9A: the Interrupt Controller (IE / IFG / TYPE)
--
-- WHERE THIS COMES FROM -- checked before it was written
--   No lab contains interrupt RTL. Searched Auxiliary/Lab 5, Lab4 and Lab3
--   for interrupt / INTR / INTA: the only hit is a student explanation
--   document, zero VHDL. So, per the project rules: No direct course RTL
--   reference found. Everything here is built from
--     (1) the controller diagram on p13 of Final Project 2026 definition.pdf
--         (per source: a D flip-flop with D='1' clocked by the interrupt
--         source, cleared by clr_irq / "interrupt done"; its output irq is
--         ANDed with the enable eint and THAT product is labelled IFGx;
--         the IFGx products feed an OR tree ANDed with GIE to make INTR;
--         CS and INTA are drawn active-low),
--     (2) the p14 register layouts and vector table (transcribed and
--         benchmark-cross-checked in DOC/02 sections 4 and 3.1),
--     (3) Hanan's forum answer that FALSIFIED assumption A6 (DOC/03):
--         "the flag accumulated as '1' in the IFG register depends on BOTH
--         conditions, interrupt request AND interrupt enable; if either is
--         zero the flag drops to zero" -- what the IFG register READS is
--         the MASKED product, never the raw latch, and
--     (4) the prep-session transcript in DOC/03 section C, which settles
--         the request polarity: every request event is a RISING 0->1 edge
--         ("we work only with a 0-to-1 event, deliberately"), and for the
--         pushbuttons that edge is the RELEASE -- the debounced KEY line
--         falls on press and rises on release, and he demonstrates the
--         request appearing at release. This transcript is the ONLY source
--         for KEY polarity; the PDF is silent.
--
-- THE STRUCTURE: RAW LATCH, MASKED VIEW -- the p13 diagram taken literally
--   Per source i:
--     irq_q(i)  -- the request latch. Set by the source's event edge,
--                  cleared by software (W0C), by the service auto-clear
--                  (rules a/b/c below) and by reset. NOT gated by IE:
--                  the p13 flop has D='1' and no enable anywhere near it.
--     ifg_w(i)  = irq_q(i) AND ie_q(i) -- the p13 AND gate, its output
--                  labelled IFGx in the diagram. THIS is what a software
--                  read returns, what the TYPE encoder sees, and what the
--                  INTR OR-tree sums. A masked request is invisible
--                  everywhere: it cannot read as pending, cannot win
--                  priority, cannot raise INTR.
--   Consequence, recorded as Assumption A22 in DOC/02: a request that
--   latched while its IE bit was 0 (or that was pending when IE dropped)
--   REAPPEARS when IE is set again -- the latch remembered it. No supplied
--   benchmark can see the difference: every one clears IFG (a store of 0,
--   which clears the RAW latches -- the W0C path below) while IE is still
--   0, and only then enables. Falsified by a benchmark that enables IE
--   over an uncleared request and expects silence.
--
-- SOFTWARE WRITES: W0C -- WRITE-0-CLEARS THE RAW LATCH, WRITE-1 LEAVES IT
--   The p13 flop has no software-set path. The only software access the
--   benchmarks make is the ISR idiom (test1/asm-code/00_main.s:139-144):
--       lw t3,(IFG); and t3,t3,KEYnIFG_MASK; sw t3,(IFG)
--   which writes 0 to the bit being cleared and each OTHER bit's own
--   current READ value back to it. W0C makes that exact: the 0 clears its
--   raw latch, the written-back 1s preserve theirs, and a flag that sets
--   between the lw and the sw survives (a set beats a same-edge clear).
--   Note the read is the MASKED view, so the idiom also silently clears
--   any masked-pending latch -- faithful to the diagram, and invisible to
--   every benchmark for the same clear-before-enable reason.
--   (Assumption A24: software cannot SET an IFG bit.)
--
-- BIT POSITIONS AND TYPE CODES -- REQ p14, benchmark-cross-checked
--   IE / IFG, bits 7:6 always read 0:
--     [5] KEY3   [4] KEY2   [3] KEY1   [2] BT   [1] TX   [0] RX
--   (io_map.s: BTIE=0x04 -> bit2; KEY3IE_KEY2IE_KEY1IE=0x38 -> bits 5:3;
--    KEYnIFG_MASK 0xFFF7/0xFFEF/0xFFDF -> clear bits 3/4/5.)
--   TYPE, priority 1 (highest) .. 7, from p14's own priority column:
--     x"04" UART err > x"08" UART RX > x"0C" UART TX > x"10" BT
--     > x"14" KEY1 > x"18" KEY2 > x"1C" KEY3;  x"00" when nothing pends.
--   RXIFG is ONE bit serving TWO TYPE codes (04h and 08h). This controller
--   presents x"08" for it (Assumption A23). DOC/02 section 4.1 proves the
--   choice cannot change behaviour in any supplied benchmark: words 1 and
--   2 of every benchmark vector table hold the SAME handler. Phase 12
--   (UART) revisits if Hanan answers open question 4.
--
-- CLEARING RULES a-f OF REQ p13, WHO IMPLEMENTS WHICH
--   a  BTIFG auto-clears when serviced          -> HERE, at the INTA edge
--   b  RXIFG auto-clears when serviced          -> HERE (svc_rx_w);
--        ... or when RXBUF is read              -> HERE since Phase 12B,
--        rx_clr_i, a one-cycle pulse from uart_periph's RXBUF read strobe
--   c  TXIFG auto-clears when serviced          -> HERE (svc_tx_w);
--        ... or when TXBUF is written           -> HERE since Phase 12B,
--        tx_clr_i, from uart_periph's TXBUF write strobe
--        REQ p12's own words for both halves: "reading RXBUF resets the
--        receive-error bits, and RXIFG" / "writing to the transmit data
--        buffer clears TXIFG". Both arrive on this clock (uart_periph is on
--        pclk_w too), and both clear the RAW latch, not the masked view --
--        so a read of RXBUF retires the request even while RXIE is 0, which
--        is what makes polled operation possible at all: without it a
--        masked-pending RXIFG would fire the instant software enabled RXIE.
--   d  KEYiIFG cleared manually by software     -> the W0C write path;
--        NO auto-clear at service for the KEYs, deliberately -- the
--        benchmark ISRs all do the manual clear, and it must find the
--        flag still set (that is what "manually with software" means)
--   e  GIE cleared in HW at entry               -> Phase 9B (CPU side)
--   f  GIE set in HW at return                  -> Phase 9B (CPU side)
--
-- THE INTA HANDSHAKE (REQ p15, reconstructed in DOC/02 section 4.2)
--   The CPU pulses inta_i low for exactly one cycle (the accept cycle).
--   At the edge that ends that cycle, this controller:
--     - latches TYPE into type_capt_q -- FROZEN, so a higher-priority
--       source arriving one cycle later cannot swap the vector under the
--       CPU's feet;
--     - applies the service auto-clear (rules a/b/c) to the captured
--       source's RAW latch, KEYs excluded (rule d).
--   During the FOLLOWING cycle (protocol Cycle 1), type_push_o is high
--   and type_capt_o carries the captured TYPE: the MCU level drives it
--   onto the shared data bus, because REQ p15 says the TYPE value travels
--   over the Data BUS -- the CPU is the only bus master, so the controller
--   pushes and the CPU captures. This block does not touch the bus
--   itself; like every peripheral read-back since Phase 6B, the tri-state
--   lives at the MCU level (BidirPin, Figure 5's convention).
--   A spurious INTA with nothing pending would push TYPE = x"00"; the
--   Phase 9B CPU FSM never asserts INTA without INTR, so the case is
--   unreachable rather than defended.
--
-- KEY EDGE CAPTURE -- REALIZATION DECISIONS, RECORDED
--   1. THE EVENT IS THE RELEASE (DOC/03 section C, the only polarity
--      source). This port takes the polarity-NORMALIZED pressed level
--      (the MCU's key_pressed_w, '1' while held) and detects its FALLING
--      edge -- which IS the release, on either board polarity. DOC/03
--      warns against key_pressed_w's RISING edge (the press: one event
--      early); the falling edge is the same signal at the right event.
--   2. Why not clock a flop from the raw KEY line, as p13 draws? Two
--      reasons. An asynchronous pin on an FPGA clock network gets no
--      timing analysis and puts a CDC hazard at every reader; implemented
--      instead as the synchronous equivalent -- the course's own Figure
--      10a two-flop synchronizer (SYNC.vhd, reused exactly as DIV_UNIT
--      reuses it) + one history flop + edge detect. And the raw line
--      idles HIGH, so reset-cleared synchronizer flops would fabricate
--      one spurious 0->1 "release" right after reset; the pressed level
--      idles LOW, matching the flops' reset state, so no spurious event.
--      GEN_SRC_REG => FALSE is sound for the single-bit reason: a 1-bit
--      signal cannot lose bus coherence, which is the only thing the
--      launch register protects (SYNC.vhd's own header).
--   bt_ifg_set_i needs none of this: basic_timer.btifg_set_o is a
--   one-cycle pulse already synchronous to this clock, and the pulse IS
--   a rising 0->1 event, exactly the prep-session rule (A19: MCLK and
--   SMCLK are today the same 20 MHz net; if B3 ever splits them, this
--   input needs a pulse CDC -- recorded in DOC/02 section 4.3).
--
-- WRITE SIDE -- the Phase 5 bus conventions, same as basic_timer:
--   one CS for the whole SFR word 11 (0x202C IE / 0x202D IFG / 0x202E
--   TYPE), lane0/lane1 from A1..A0 picking the register, and the value
--   taken from data_i(7:0) regardless of lane -- F15's byte addressing,
--   Figure 5 wiring every latch input D0..D7 to Data<7..0>. TYPE is
--   read-only (REQ p14), so a lane-2 write has no port here at all.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.aux_package.all;		-- the sync component (Figure 10a, Phase 7B1)


ENTITY interrupt_ctrl IS
	generic(
		DATA_WIDTH	: integer := 32
	);
	PORT(
		--Inputs
		clk_i			: IN	STD_LOGIC;		-- the CPU clock domain: INTR/INTA and the
												-- bus writes are CPU-side handshakes
		rst_i			: IN	STD_LOGIC;		-- active high

		-- write side, straight from the Phase 5 bus: one CS per SFR word
		cs_i			: IN	STD_LOGIC;		-- word 11: IE / IFG / TYPE
		MemWrite_i		: IN	STD_LOGIC;
		lane0_i			: IN	STD_LOGIC;		-- A1A0=00 -> IE
		lane1_i			: IN	STD_LOGIC;		-- A1A0=01 -> IFG
		data_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

		-- interrupt sources
		bt_ifg_set_i	: IN	STD_LOGIC := '0';					-- one-cycle pulse, same clock
		key_pressed_i	: IN	STD_LOGIC_VECTOR(3 DOWNTO 1) := "000";	-- '1' while held, asynchronous;
												-- the request event is the FALLING edge = the RELEASE
		rxerr_ev_i		: IN	STD_LOGIC := '0';	-- Phase 12B (UART): all five are
		rx_ev_i			: IN	STD_LOGIC := '0';	-- driven now. Still defaulted so
		tx_ev_i			: IN	STD_LOGIC := '0';	-- tb_interrupt_ctrl and every
													-- pre-12B instantiation elaborates
		-- Clearing rules b and c, software side (REQ p12). One-cycle pulses from
		-- uart_periph, same clock: rx_clr_i = RXBUF was read, tx_clr_i = TXBUF
		-- was written. They clear the RAW latch, exactly like the W0C path.
		rx_clr_i		: IN	STD_LOGIC := '0';
		tx_clr_i		: IN	STD_LOGIC := '0';

		-- CPU handshake (REQ p13 / p15; Phase 9B is the other end)
		gie_i			: IN	STD_LOGIC;			-- gp[0], tapped in IDECODE (Phase 9B)
		inta_i			: IN	STD_LOGIC := '1';	-- active low, one-cycle pulse

		--Outputs
		intr_o			: OUT	STD_LOGIC;
		type_push_o		: OUT	STD_LOGIC;			-- protocol Cycle 1: drive TYPE onto the bus
		type_capt_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);

		-- read-back (behind BidirPin at the MCU level, like every SFR read)
		ie_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		ifg_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		type_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END interrupt_ctrl;


ARCHITECTURE behavior OF interrupt_ctrl IS
	-- TYPE codes, REQ p14's vector table (priority 1..7 = the listing order)
	CONSTANT TYPE_NONE	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
	CONSTANT TYPE_RX	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"08";	-- A23: one RXIFG bit, code 08h
	CONSTANT TYPE_TX	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"0C";
	CONSTANT TYPE_BT	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10";
	CONSTANT TYPE_KEY1	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"14";
	CONSTANT TYPE_KEY2	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"18";
	CONSTANT TYPE_KEY3	: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"1C";

	SIGNAL ie_q			: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL irq_q		: STD_LOGIC_VECTOR(5 DOWNTO 0);	-- the RAW request latches (p13 flops)
	SIGNAL ifg_w		: STD_LOGIC_VECTOR(5 DOWNTO 0);	-- the MASKED view: irq AND eint = IFGx

	SIGNAL ie_wr_w		: STD_LOGIC;
	SIGNAL ifg_wr_w		: STD_LOGIC;

	SIGNAL key_sync_w	: STD_LOGIC_VECTOR(3 DOWNTO 1);	-- after the two-flop synchronizer
	SIGNAL key_hist_q	: STD_LOGIC_VECTOR(3 DOWNTO 1);	-- one more flop for the edge detect

	SIGNAL set_w		: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL clr_w		: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL svc_rx_w		: STD_LOGIC;	-- service auto-clears, rules b / c / a
	SIGNAL svc_tx_w		: STD_LOGIC;
	SIGNAL svc_bt_w		: STD_LOGIC;
	SIGNAL type_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL type_capt_q	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL push_q		: STD_LOGIC;

BEGIN
	--=======================================================================
	-- Bus write strobes -- basic_timer's exact idiom
	--=======================================================================
	ie_wr_w		<= cs_i AND MemWrite_i AND lane0_i;
	ifg_wr_w	<= cs_i AND MemWrite_i AND lane1_i;

	--=======================================================================
	-- KEY synchronizers + release-edge detect (realization decisions 1+2)
	--=======================================================================
	KEYSYNC: for k in 1 to 3 generate
		S_KEY : sync
		generic map(DATA_WIDTH => 1, STAGES => 2, GEN_SRC_REG => FALSE)
		PORT MAP(src_clk_i => '0', dst_clk_i => clk_i, rst_i => rst_i,
				 d_i => key_pressed_i(k DOWNTO k), q_o => key_sync_w(k DOWNTO k));
	end generate;

	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			key_hist_q <= (OTHERS => '0');
		elsif rising_edge(clk_i) then
			key_hist_q <= key_sync_w;
		end if;
	end process;

	--=======================================================================
	-- Set pulses, one per raw latch. The KEY event is the RELEASE: the
	-- pressed level falling 1->0 (DOC/03 section C -- the debounced KEY
	-- line's rising edge, seen through the pressed-polarity normalization).
	--=======================================================================
	set_w(0)	<= rx_ev_i OR rxerr_ev_i;	-- both UART sources share RXIFG (p14)
	set_w(1)	<= tx_ev_i;
	set_w(2)	<= bt_ifg_set_i;
	set_w(3)	<= key_hist_q(1) AND (NOT key_sync_w(1));
	set_w(4)	<= key_hist_q(2) AND (NOT key_sync_w(2));
	set_w(5)	<= key_hist_q(3) AND (NOT key_sync_w(3));

	--=======================================================================
	-- Clear terms on the RAW latches: software W0C, plus the service
	-- auto-clears (rules a/b/c). The service clear hits at the SAME edge
	-- that captures TYPE -- the edge ending the INTA-low cycle -- and only
	-- the source being serviced. KEY bits get no service term at all:
	-- rule d. A set beats a same-edge clear (the OR below), so a hardware
	-- event cannot be swallowed by a concurrent read-modify-write.
	--=======================================================================
	svc_rx_w	<= '1' WHEN (inta_i = '0' AND (type_w = TYPE_RX)) ELSE '0';
	svc_tx_w	<= '1' WHEN (inta_i = '0' AND (type_w = TYPE_TX)) ELSE '0';
	svc_bt_w	<= '1' WHEN (inta_i = '0' AND (type_w = TYPE_BT)) ELSE '0';

	clr_w(0)	<= (ifg_wr_w AND (NOT data_i(0))) OR svc_rx_w OR rx_clr_i;
	clr_w(1)	<= (ifg_wr_w AND (NOT data_i(1))) OR svc_tx_w OR tx_clr_i;
	clr_w(2)	<= (ifg_wr_w AND (NOT data_i(2))) OR svc_bt_w;
	clr_w(3)	<= ifg_wr_w AND (NOT data_i(3));
	clr_w(4)	<= ifg_wr_w AND (NOT data_i(4));
	clr_w(5)	<= ifg_wr_w AND (NOT data_i(5));

	--=======================================================================
	-- IE -- a plain byte register, reset-cleared, bits 7:6 not stored
	--=======================================================================
	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			ie_q <= (OTHERS => '0');
		elsif rising_edge(clk_i) then
			if ie_wr_w = '1' then
				ie_q <= data_i(5 DOWNTO 0);
			end if;
		end if;
	end process;

	--=======================================================================
	-- The RAW request latches -- the p13 flops, D='1', set by the event
	-- edge, NOT gated by IE. IE lives one AND gate downstream (ifg_w).
	--=======================================================================
	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			irq_q <= (OTHERS => '0');
		elsif rising_edge(clk_i) then
			for i in 0 to 5 loop
				irq_q(i) <= set_w(i) OR (irq_q(i) AND (NOT clr_w(i)));
			end loop;
		end if;
	end process;

	--=======================================================================
	-- The MASKED view -- the p13 AND gates, their outputs labelled IFGx.
	-- Everything downstream (read-back, TYPE, INTR) sees ONLY this.
	--=======================================================================
	ifg_w	<= irq_q AND ie_q;

	--=======================================================================
	-- TYPE -- the priority encoder, REQ p14's order, x"00" when idle
	--=======================================================================
	type_w	<=	TYPE_RX		WHEN ifg_w(0) = '1' ELSE
				TYPE_TX		WHEN ifg_w(1) = '1' ELSE
				TYPE_BT		WHEN ifg_w(2) = '1' ELSE
				TYPE_KEY1	WHEN ifg_w(3) = '1' ELSE
				TYPE_KEY2	WHEN ifg_w(4) = '1' ELSE
				TYPE_KEY3	WHEN ifg_w(5) = '1' ELSE
				TYPE_NONE;

	--=======================================================================
	-- INTR -- the p13 OR tree over the IFGx products, ANDed with GIE
	--=======================================================================
	intr_o	<= '1' WHEN (ifg_w /= "000000" AND gie_i = '1') ELSE '0';

	--=======================================================================
	-- The INTA handshake: freeze TYPE at the accept edge, push it the
	-- cycle after. push_q also self-clears, so a (protocol-violating)
	-- multi-cycle INTA low would just re-capture and keep pushing --
	-- benign, and unreachable from the Phase 9B FSM.
	--=======================================================================
	process(clk_i, rst_i)
	begin
		if rst_i = '1' then
			type_capt_q	<= (OTHERS => '0');
			push_q		<= '0';
		elsif rising_edge(clk_i) then
			if inta_i = '0' then
				type_capt_q	<= type_w;
				push_q		<= '1';
			else
				push_q		<= '0';
			end if;
		end if;
	end process;

	--=======================================================================
	-- Outputs
	--=======================================================================
	type_push_o	<= push_q;
	type_capt_o	<= type_capt_q;

	ie_o		<= "00" & ie_q;
	ifg_o		<= "00" & ifg_w;	-- the MASKED view -- the falsified-A6 correction
	type_o		<= type_w;			-- read-only, bits 7:6 zero by construction (p14)

END behavior;
