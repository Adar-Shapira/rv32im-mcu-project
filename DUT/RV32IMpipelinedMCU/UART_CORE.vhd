--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12A: the UART peripheral (bonus, clause 6.iv)
--
-- DERIVED FROM A THIRD-PARTY FILE, MIT LICENCE:
--   Auxiliary/USART Material/UART_FPGA_option1/rtl/uart.vhd
--   jakubcabal/uart-for-fpga v1.1, MIT, Copyright (c) 2015 Jakub Cabal
--   original md5 recorded in DOC/01; the licence text lives in
--   Auxiliary/USART Material/UART_FPGA_option1/LICENSE and is unmodified.
--
-- Clause 6.iv: "You are given a VHDL design code that needs to be adapted to
-- the following UART mode features." Adapting is the requirement; this file is
-- the adaptation of the original's top level. Its three children -- UART_TX,
-- UART_RX, UART_DEBOUNCER (and UART_PARITY beneath them) -- are the author's
-- files, copied with only the one RX_BUSY addition documented in UART_RX.vhd.
--
-- WHAT CHANGED, AND WHY EACH CHANGE EXISTS
--
-- 1. THE BAUD DIVIDER IS A RUNTIME CHOICE, NOT A GENERIC.
--    The original computes  DIVIDER_VALUE = CLK_FREQ/(16*BAUD_RATE)  as a
--    CONSTANT from generics, so the baud rate is frozen at compile time. REQ
--    p12 makes it software-selectable: UCTL bit 3, "Baud Rate value", 0 = 9600
--    and 1 = 115200. So both dividers are computed at elaboration and
--    baud_sel_i picks between them at runtime.
--
-- 2. THE DIVIDER IS ROUNDED, NOT TRUNCATED -- AND AT 20 MHz THAT IS THE
--    DIFFERENCE BETWEEN A WORKING LINK AND A DEAD ONE.
--    The original truncates. At this project's SMCLK = 20 MHz (forum answer
--    F8) and 115200 baud:
--        truncated: 20e6 / (16*115200) = 10.85 -> 10  ->  20e6/(16*10)
--                   = 125000 baud, an error of +8.5%
--        rounded  : 10.85 -> 11              ->  20e6/(16*11)
--                   = 113636 baud, an error of -1.36%
--    8N1 tolerates roughly +/-2-3% before the stop bit lands outside its
--    sampling window; +8.5% does not survive a ten-bit frame. The original's
--    own default of 50 MHz truncates to 27 and lands at +0.47%, which is why
--    the formula looks harmless in its home configuration. The elaboration
--    assert at the bottom of the declarations makes this a compile-time
--    failure rather than a bench-time mystery, for any CLK_HZ.
--        9600 at 20 MHz: divider 130 -> 9615 baud, +0.16%.
--
-- 3. THE CLOCK-ENABLE COMPARE IS '>=', NOT '='.
--    The original compares the counter against a constant, so equality is
--    safe. Here the maximum can CHANGE while the counter is above the new
--    value -- software writing UCTL[3] from 9600 (130) down to 115200 (11)
--    with the counter at, say, 90. On equality the counter would run to its
--    full width and the link would stall for hundreds of cycles; on '>=' the
--    next tick fires immediately and the divider re-locks. One character, and
--    it removes a hang. (Software should still switch baud only while idle --
--    a switch mid-character corrupts that character no matter what the
--    hardware does. Recorded as an assumption in DOC/02.)
--
-- 4. RX_BUSY IS BROUGHT OUT (see UART_RX.vhd) for UCTL bit 7.
--
-- 5. PARITY IS "none" -- 8N1. REQ p12's own feature list says "8-bit data
--    with non-parity", and its UCTL table says "when PENA = 0, PE is read as
--    0". The register layer above stores PENA/PEV and reads PE as 0, which
--    satisfies both statements for PENA = 0. Runtime parity would need the
--    RX and TX state machines to gain a runtime "is there a parity bit"
--    input, which is a real change to the author's FSMs; it is deliberately
--    NOT done here and is recorded as an assumption with what would falsify
--    it. See UART_PERIPH.vhd.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY uart_core IS
	generic(
		-- The clock this block is driven by. The peripherals run on SMCLK
		-- (forum answer F11), which is 20 MHz (F8). Passed rather than assumed
		-- so the elaboration check below is about the real clock.
		CLK_HZ			: natural := 20000000;
		BAUD_LOW		: natural := 9600;		-- UCTL[3] = 0  (REQ p12)
		BAUD_HIGH		: natural := 115200;	-- UCTL[3] = 1  (REQ p12)
		-- The largest baud error, in percent, this configuration may produce
		-- before elaboration fails. 3 is the usual 8N1 working bound.
		MAX_ERR_PCT		: natural := 3;
		-- The author's own RXD debouncer, LATENCY 4. Kept on: the RXD pin is
		-- an asynchronous board input and this is the author's intended use.
		USE_DEBOUNCER	: boolean := TRUE
	);
	PORT(
		--Inputs
		clk_i			: IN	STD_LOGIC;
		rst_i			: IN	STD_LOGIC;		-- high active, synchronous (the
												-- author's convention; SWRST
												-- reaches the core through it)
		baud_sel_i		: IN	STD_LOGIC;		-- UCTL[3]: 0 = BAUD_LOW, 1 = BAUD_HIGH
		rxd_i			: IN	STD_LOGIC := '1';	-- idle high

		-- transmit side, the author's valid/ready handshake
		din_i			: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
		din_vld_i		: IN	STD_LOGIC;

		--Outputs
		txd_o			: OUT	STD_LOGIC;
		din_rdy_o		: OUT	STD_LOGIC;		-- '1' = TX idle and will accept din_i
		dout_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		dout_vld_o		: OUT	STD_LOGIC;		-- one cycle per good character
		frame_err_o		: OUT	STD_LOGIC;		-- one cycle; stop bit was low
		rx_busy_o		: OUT	STD_LOGIC		-- a frame is in progress
	);
END uart_core;


ARCHITECTURE structure OF uart_core IS

	-- Rounded, not truncated: (x + y/2) / y. See note 2 in the header.
	CONSTANT DIV_LOW	: natural := (CLK_HZ + (16*BAUD_LOW)/2)  / (16*BAUD_LOW);
	CONSTANT DIV_HIGH	: natural := (CLK_HZ + (16*BAUD_HIGH)/2) / (16*BAUD_HIGH);

	-- BAUD_LOW is the slower rate, so its divider is the larger one and sizes
	-- the counter. Asserted below rather than assumed.
	CONSTANT DIV_MAX	: natural := DIV_LOW;

	-- Width without IEEE.MATH_REAL. The original uses ceil(log2(real(...))),
	-- which is legal and which Quartus accepts -- but this project has already
	-- been bitten once by Quartus 21.1's front end on a construct that
	-- simulates cleanly (plan section 1.7.b), and an integer loop cannot be
	-- misparsed. bits_for(130) = 8, bits_for(11) = 4.
	FUNCTION bits_for(n : natural) RETURN natural IS
		VARIABLE v_v : natural := n;
		VARIABLE b_v : natural := 1;
	BEGIN
		WHILE v_v > 1 LOOP
			v_v := v_v / 2;
			b_v := b_v + 1;
		END LOOP;
		RETURN b_v;
	END FUNCTION bits_for;

	CONSTANT CNT_W		: natural := bits_for(DIV_MAX);

	-- The actual baud each divider produces, and the error in per-mille. All
	-- integer, so the check below is exact rather than nearly right.
	--   actual = CLK_HZ / (16*DIV);  err_permille = |CLK_HZ - BAUD*16*DIV|
	--                                               * 1000 / (BAUD*16*DIV)
	CONSTANT REF_LOW	: natural := BAUD_LOW  * 16 * DIV_LOW;
	CONSTANT REF_HIGH	: natural := BAUD_HIGH * 16 * DIV_HIGH;
	CONSTANT ERR_LOW	: natural := (ABS(CLK_HZ - REF_LOW)  * 1000) / REF_LOW;
	CONSTANT ERR_HIGH	: natural := (ABS(CLK_HZ - REF_HIGH) * 1000) / REF_HIGH;

	SIGNAL cnt_q		: unsigned(CNT_W-1 DOWNTO 0);
	SIGNAL cnt_max_w	: unsigned(CNT_W-1 DOWNTO 0);
	SIGNAL clk_en_w		: STD_LOGIC;
	SIGNAL rxd_deb_w	: STD_LOGIC;

BEGIN
	--=======================================================================
	-- Elaboration checks. Same idiom as CLOCK_TREE.vhd: a wrong configuration
	-- must fail at compile time, in one line, naming the number.
	--=======================================================================
	ASSERT DIV_LOW >= 2 AND DIV_HIGH >= 2
		REPORT "uart_core: CLK_HZ is too low for these baud rates: a 16x " &
			   "oversampling divider needs at least 2. Dividers came out " &
			   integer'image(DIV_LOW) & " and " & integer'image(DIV_HIGH) & "."
		SEVERITY failure;

	ASSERT DIV_LOW >= DIV_HIGH
		REPORT "uart_core: BAUD_LOW must be the SLOWER rate: its divider " &
			   "sizes the counter. Got dividers " & integer'image(DIV_LOW) &
			   " and " & integer'image(DIV_HIGH) & "."
		SEVERITY failure;

	ASSERT ERR_LOW <= MAX_ERR_PCT*10
		REPORT "uart_core: at CLK_HZ = " & integer'image(CLK_HZ) & " the " &
			   integer'image(BAUD_LOW) & " baud divider is " &
			   integer'image(DIV_LOW) & ", an error of " &
			   integer'image(ERR_LOW) & " per-mille, above the " &
			   integer'image(MAX_ERR_PCT) & "% bound. Pick a clock whose " &
			   "16x multiple divides more evenly."
		SEVERITY failure;

	ASSERT ERR_HIGH <= MAX_ERR_PCT*10
		REPORT "uart_core: at CLK_HZ = " & integer'image(CLK_HZ) & " the " &
			   integer'image(BAUD_HIGH) & " baud divider is " &
			   integer'image(DIV_HIGH) & ", an error of " &
			   integer'image(ERR_HIGH) & " per-mille, above the " &
			   integer'image(MAX_ERR_PCT) & "% bound. NOTE the original's " &
			   "TRUNCATING formula would give " &
			   integer'image(CLK_HZ / (16*BAUD_HIGH)) & " here; this file " &
			   "rounds. See note 2 in the header."
		SEVERITY failure;

	--=======================================================================
	-- The 16x oversampling clock enable -- the original's counter, with the
	-- maximum made runtime (note 1) and the compare made '>=' (note 3).
	--=======================================================================
	cnt_max_w <= TO_UNSIGNED(DIV_HIGH, CNT_W) WHEN baud_sel_i = '1'
			ELSE TO_UNSIGNED(DIV_LOW,  CNT_W);

	clk_en_w <= '1' WHEN cnt_q >= (cnt_max_w - 1) ELSE '0';

	baud_cnt : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				cnt_q <= (OTHERS => '0');
			elsif clk_en_w = '1' then
				cnt_q <= (OTHERS => '0');
			else
				cnt_q <= cnt_q + 1;
			end if;
		end if;
	end process baud_cnt;

	--=======================================================================
	-- The author's three blocks, instantiated as his own top level does.
	--=======================================================================
	DEBG:
	if (USE_DEBOUNCER) generate
		DEB : entity work.UART_DEBOUNCER
		generic map( LATENCY => 4 )
		PORT MAP( CLK => clk_i, DEB_IN => rxd_i, DEB_OUT => rxd_deb_w );
	end generate DEBG;

	-- Two separate if-generates with no else, and no declarations inside a
	-- branch: plan section 1.7.b -- Quartus 21.1's front end internal-errors
	-- on if/else generate with an inner declarative region. Same netlist.
	NODEBG:
	if (NOT USE_DEBOUNCER) generate
		rxd_deb_w <= rxd_i;
	end generate NODEBG;

	TX : entity work.UART_TX
	generic map( PARITY_BIT => "none" )			-- note 5
	PORT MAP(
		CLK			=> clk_i,
		RST			=> rst_i,
		UART_CLK_EN	=> clk_en_w,
		UART_TXD	=> txd_o,
		DIN			=> din_i,
		DIN_VLD		=> din_vld_i,
		DIN_RDY		=> din_rdy_o
	);

	RX : entity work.UART_RX
	generic map( PARITY_BIT => "none" )			-- note 5
	PORT MAP(
		CLK			=> clk_i,
		RST			=> rst_i,
		UART_CLK_EN	=> clk_en_w,
		UART_RXD	=> rxd_deb_w,
		DOUT		=> dout_o,
		DOUT_VLD	=> dout_vld_o,
		FRAME_ERROR	=> frame_err_o,
		RX_BUSY		=> rx_busy_o				-- the one added port
	);

END structure;
