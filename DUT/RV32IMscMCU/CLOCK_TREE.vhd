--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- the Clock Tree of Figure 1
--
-- Figure 1 (page 3) draws exactly this block by this name:
--     baseclk50MHz -> Clock Tree -> mclk, accelclk, smclk
-- so the entity name and all three output names come off the figure, not from
-- us. Phase 4B. Closes gap G-311.
--
-- SCOPE: built as a leaf in Phase 4B and WIRED IN by Phase 4C. RV32IMscMCU now
-- instantiates it, clk_i reaches it and nothing else, the core receives mclk,
-- the peripherals smclk, and the divider accelclk (Phase 7B2). Reset is held
-- until locked_o rises. The section "WHAT WIRING THIS IN MEANT" below is kept
-- because those consequences are live, not hypothetical.
--============================================================================
-- WHAT THE MATERIAL ACTUALLY SETTLES
--
--   [REQ p3, Figure 1]  Three clocks, named mclk / accelclk / smclk, from a
--   50 MHz base. mclk feeds the core, smclk the peripherals, accelclk the
--   accelerator.
--
--   WHAT LAB 5 AND LAB 4 ALREADY HAD, so the new part is only the new part:
--   the students' own Lab 4 board top,
--   Auxiliary/Lab 5/Auxilary/Lab4/DUT/fpga_hw_interface.vhd, already
--   instantiates a PLL at BOARD level (not inside the logic) and already
--   captures its locked output -- which is the structural pattern this entity
--   follows, and the precedent Phase 4C's reset-on-lock builds on.
--   What neither lab had is more than ONE clock: every ALTPLL copy in the whole
--   tree exposes c0 alone, and nothing anywhere generates a second or third
--   clock domain. Verified by searching every .vhd under Auxiliary/ for a clock
--   tree, a multi-output PLL or a second clock domain: there is none. So the
--   three-instance structure and the ratio generics are genuinely new work, and
--   the board-level placement is not.
--
--   [FORUM F6]  Asked whether the three come out of ONE PLL module, Hanan:
--   **"No -- on the basis of three different PLL instances"**, each fed from the
--   50 MHz base clock. This is what unblocked Phase 4B, and it retires the
--   roadmap's stated blocker: the ALTPLL does NOT have to be regenerated for
--   c1/c2. What was actually needed was a per-instance ratio, which is why
--   PLL_GEN.vhd exists.
--
--   [FORUM F7]  Asked whether all three may run at the same frequency: the
--   separation exists for timing and power independence, **"but since you are
--   working with a single-cycle base CPU (not a pipeline) running at a low
--   frequency ... your values may be identical, i.e. MCLK = SMCLK"**.
--
--   [FORUM F8]  SMCLK = 20 MHz, stated in writing in the course's own
--   `Intrrupt-based IO/ReadMe.txt`: "value of 0x01312D00 is for SMCLK=20MHz".
--   Not an assumption any more.
--
--   So: MCLK = SMCLK = 20 MHz from a 50 MHz base -- ratio 2/5, exactly. The
--   arithmetic is checked at elaboration below rather than trusted.
--
-- WHAT THE MATERIAL DOES NOT SETTLE: ACCELCLK
--   No frequency is stated for accelclk anywhere. Page 9 calls DIVCLK the "fast
--   clock", and the forum added only that it "needs to be high" so the divider is
--   genuinely an accelerator. **Assumption A3: ACCELCLK = 50 MHz**, the undivided
--   board clock, because it is the only faster clock available. Falsified by a
--   stated value or by timing closure failing at 50 MHz. This is open question
--   **B3** and it is one generic away from being changed.
--============================================================================
-- THE ONE REAL CONFLICT IN THIS PHASE, AND IT IS NOT RESOLVED QUIETLY
--
--   F6 says three PLL instances. F7 says MCLK and SMCLK may be the same value.
--   Do both, literally, and you get **two independent PLLs producing 20 MHz
--   each** -- and that is a design with a defect.
--
--   The core drives address, write data and MemWrite on MCLK. Every peripheral
--   register captures that bus on SMCLK: `gpo_port` does exactly this today, and
--   Hanan's own answer F11 says the peripheral registers should be DFFs on SMCLK.
--   That is a SYNCHRONOUS PARALLEL BUS crossing the MCLK/SMCLK boundary. Two
--   PLLs both locked to the same 50 MHz reference are frequency-identical, but
--   their output phase relationship is not specified by anything -- so the
--   setup/hold margin on that capture is whatever the fitter happens to produce,
--   Quartus has no basis on which to analyse it, and Figure 5 draws no
--   synchroniser anywhere on the GPIO write path. It would very likely work on
--   the bench and it cannot be shown to work. That is the failure mode that
--   turns up during a demo.
--
--   **Design decision, recorded as such: when MCLK and SMCLK are configured to
--   the same frequency they share one PLL and one net.** SMCLK_SHARES_MCLK
--   controls it, defaulting TRUE, and the elaboration check below refuses the
--   combination "share the net but ask for different frequencies".
--
--   The reading this rests on: F6 answers *how to produce three clocks* -- don't
--   try to make one PLL emit three, use separate instances -- rather than
--   mandating that two clocks of equal frequency be electrically distinct nets.
--   F7 permitting MCLK = SMCLK as *values* supports that: two independent PLLs
--   at one frequency buy nothing and cost analysability.
--
--   Set SMCLK_SHARES_MCLK => FALSE and you get the literal three-instance
--   structure, at which point the MMIO bus needs synchronisation that nothing in
--   the assignment draws. **Raised as a question rather than settled by us.**
--   Assumption A19.
--============================================================================
-- WHAT WIRING THIS IN MEANT -- live consequences, not warnings about the future
--
--   1. In simulation, MCLK IS clk_i -- the same tie the core used to make for
--      itself at MODELSIM = 1 before Phase 4C removed its internal PLL. That is
--      deliberate: it is what lets the tree be wired in without moving a single
--      benchmark cycle count. The four numbers 134 / 1514 / 2725 / 2735 must
--      still hold, and this is what makes that possible.
--
--   2. locked_o is LOW for SIM_LOCK_DELAY_NS at the start of every simulation,
--      and Phase 4C DOES gate reset release on it (GEN_RESET_ON_LOCK). Every
--      existing testbench releases reset at 80 ns, so the core now stays in reset
--      until 200 ns. The CYCLE COUNTS still must not move: mclk_cnt_q is held at
--      zero by reset and starts when reset releases, while the program starts
--      executing at that same moment, so a later release shifts both together.
--      Only the wall-clock end time changes. If a count does move,
--      GEN_RESET_ON_LOCK => FALSE isolates this from the clock change.
--
--   3. The simulation clock generators are FREE-RUNNING processes. A testbench
--      that instantiates this must terminate with `std.env.stop` (as tb_sync,
--      tb_addr_decoder and tb_div_accel all do) or with an explicit `run <time>`.
--      `run -all` on a design containing this block and no stop will not return.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY clock_tree IS
	generic(
		-- Hanan's own conditional-compilation idiom. At 0 the three PLLs are
		-- instantiated; at 1 they are replaced by behavioural clock sources,
		-- because altpll is a black box that needs the altera_mf library and the
		-- core already bypasses it the same way.
		MODELSIM			: integer := G_MODELSIM;

		-- The base clock, and the three targets. Frequencies in kHz so the
		-- elaboration check below is exact integer arithmetic with no rounding.
		IN_FREQ_KHZ			: natural := 50000;		-- Figure 1's baseclk50MHz
		IN_PERIOD_PS		: natural := 20000;		-- the same 50 MHz, in ps, for altpll

		MCLK_KHZ			: natural := 20000;		-- F7 + F8
		MCLK_MUL			: natural := 2;
		MCLK_DIV			: natural := 5;

		SMCLK_KHZ			: natural := 20000;		-- F8, stated in writing
		SMCLK_MUL			: natural := 2;
		SMCLK_DIV			: natural := 5;

		ACCELCLK_KHZ		: natural := 50000;		-- assumption A3, question B3
		ACCEL_MUL			: natural := 1;
		ACCEL_DIV			: natural := 1;

		-- See "THE ONE REAL CONFLICT" above. TRUE is the analysable choice.
		SMCLK_SHARES_MCLK	: boolean := TRUE;

		-- Simulation only. The accelclk half-period is chosen so that its ratio
		-- to the testbenches' 100 ns clock reduces to 10:3 -- COPRIME, on purpose.
		-- An integer ratio holds the two clock edges in a fixed relationship and
		-- can pass while hiding a real crossing bug; a coprime one walks the fast
		-- edge through every phase of the slow one. Same argument as
		-- TB/RV32IMscMCU/tb_sync.vhd's 70/30. It does NOT reproduce the real 5:2
		-- ratio, and is not trying to.
		--
		-- NOTE, because it looks like an inconsistency and is not: the three
		-- SIM_* periods are NOT derived from MCLK_KHZ / SMCLK_KHZ / ACCELCLK_KHZ,
		-- and are not meant to be. In simulation only the RATIOS between clocks
		-- matter, and deriving the periods from the real frequencies would make
		-- accelclk exactly 10x the testbench clock -- an integer ratio, which is
		-- the one thing to avoid. So do not expect a clock_tree configured for
		-- 10 MHz SMCLK to show a 100 ns period in a waveform; it shows 70 ns, on
		-- purpose. The real frequencies are what the elaboration checks above and
		-- the SDC (Phase 4C) are for.
		SIM_ACCEL_HALF_NS	: natural := 15;
		SIM_SMCLK_HALF_NS	: natural := 35;		-- only used when NOT sharing
		SIM_LOCK_DELAY_NS	: natural := 200		-- see note 2 above
	);
	PORT(
		--Inputs
		clk_i		: IN	STD_LOGIC;		-- Figure 1's baseclk50MHz, straight off the pin
		rst_i		: IN	STD_LOGIC;		-- active high; drives the PLLs' areset

		--Outputs
		mclk_o		: OUT	STD_LOGIC;		-- to the RISC-V core
		smclk_o		: OUT	STD_LOGIC;		-- to the peripherals and the Basic Timer
		accelclk_o	: OUT	STD_LOGIC;		-- to the division accelerator (DIVCLK)
		locked_o	: OUT	STD_LOGIC		-- all instantiated PLLs locked
	);
END clock_tree;

--============================================================================
ARCHITECTURE structure OF clock_tree IS

	SIGNAL mclk_w		: STD_LOGIC;
	SIGNAL smclk_w		: STD_LOGIC;
	SIGNAL accelclk_w	: STD_LOGIC;
	SIGNAL locked_w		: STD_LOGIC;

BEGIN
	--=======================================================================
	-- Elaboration-time checks. A wrong ratio is a silent frequency error that
	-- shows up as a benchmark that runs at the wrong speed, or as a Basic Timer
	-- whose 5 kHz is not 5 kHz -- both of which are extremely tedious to find on
	-- a board. Cross-multiplied so there is no integer division to round.
	--=======================================================================
	assert IN_FREQ_KHZ * MCLK_MUL = MCLK_KHZ * MCLK_DIV
		report "clock_tree: the MCLK ratio does not produce MCLK_KHZ. " &
			integer'image(IN_FREQ_KHZ) & " kHz * " & integer'image(MCLK_MUL) &
			" / " & integer'image(MCLK_DIV) & " is not " &
			integer'image(MCLK_KHZ) & " kHz."
		severity failure;

	assert IN_FREQ_KHZ * SMCLK_MUL = SMCLK_KHZ * SMCLK_DIV
		report "clock_tree: the SMCLK ratio does not produce SMCLK_KHZ. " &
			integer'image(IN_FREQ_KHZ) & " kHz * " & integer'image(SMCLK_MUL) &
			" / " & integer'image(SMCLK_DIV) & " is not " &
			integer'image(SMCLK_KHZ) & " kHz."
		severity failure;

	assert IN_FREQ_KHZ * ACCEL_MUL = ACCELCLK_KHZ * ACCEL_DIV
		report "clock_tree: the ACCELCLK ratio does not produce ACCELCLK_KHZ. " &
			integer'image(IN_FREQ_KHZ) & " kHz * " & integer'image(ACCEL_MUL) &
			" / " & integer'image(ACCEL_DIV) & " is not " &
			integer'image(ACCELCLK_KHZ) & " kHz."
		severity failure;

	-- The one that catches a genuinely dangerous combination: sharing the net
	-- while asking for two different frequencies would silently deliver MCLK's
	-- frequency on SMCLK, and every Basic Timer interval would be wrong.
	assert not (SMCLK_SHARES_MCLK and (SMCLK_KHZ /= MCLK_KHZ))
		report "clock_tree: SMCLK_SHARES_MCLK is TRUE but SMCLK_KHZ (" &
			integer'image(SMCLK_KHZ) & ") differs from MCLK_KHZ (" &
			integer'image(MCLK_KHZ) & "). Sharing one net cannot deliver two " &
			"frequencies. Either set the two equal, or set SMCLK_SHARES_MCLK " &
			"FALSE and read the conflict note in this file's header first."
		severity failure;

	-- Cheap sanity on the accelerator: a DIVCLK slower than MCLK is not an
	-- accelerator, and page 9 calls it the fast clock.
	assert ACCELCLK_KHZ >= MCLK_KHZ
		report "clock_tree: ACCELCLK (" & integer'image(ACCELCLK_KHZ) &
			" kHz) is slower than MCLK (" & integer'image(MCLK_KHZ) &
			" kHz). Page 9 calls DIVCLK the fast clock."
		severity warning;

	--=======================================================================
	-- Hardware: one pll_gen per clock, each fed from the same 50 MHz base, per
	-- forum answer F6.
	--=======================================================================
	CLKGEN:
	if (MODELSIM = 0) generate
		-- Declared inside the branch so they do not sit undriven at 'U' in the
		-- other one. Same pattern as SYNC.vhd's launch_q.
		SIGNAL lock_m_w	: STD_LOGIC;
		SIGNAL lock_s_w	: STD_LOGIC;
		SIGNAL lock_a_w	: STD_LOGIC;
	begin
		P_MCLK : pll_gen
		generic map(DIVIDE_BY => MCLK_DIV, MULTIPLY_BY => MCLK_MUL,
					IN_PERIOD_PS => IN_PERIOD_PS)
		PORT MAP(areset => rst_i, inclk0 => clk_i,
				 c0 => mclk_w, locked => lock_m_w);

		P_ACCEL : pll_gen
		generic map(DIVIDE_BY => ACCEL_DIV, MULTIPLY_BY => ACCEL_MUL,
					IN_PERIOD_PS => IN_PERIOD_PS)
		PORT MAP(areset => rst_i, inclk0 => clk_i,
				 c0 => accelclk_w, locked => lock_a_w);

		SHARE:
		if (SMCLK_SHARES_MCLK) generate
			-- One net. See the conflict note in the header: this is the choice
			-- that keeps the core-to-peripheral bus a single synchronous domain.
			smclk_w  <= mclk_w;
			lock_s_w <= '1';
		else generate
			P_SMCLK : pll_gen
			generic map(DIVIDE_BY => SMCLK_DIV, MULTIPLY_BY => SMCLK_MUL,
						IN_PERIOD_PS => IN_PERIOD_PS)
			PORT MAP(areset => rst_i, inclk0 => clk_i,
					 c0 => smclk_w, locked => lock_s_w);
		end generate SHARE;

		locked_w <= lock_m_w AND lock_s_w AND lock_a_w;

	else generate
		--===================================================================
		-- Simulation. altpll is a black box needing altera_mf, and the core
		-- already bypasses it exactly this way, so the clocks are produced
		-- behaviourally instead.
		--
		-- MCLK IS clk_i, not a generated clock. That is the whole reason Phase
		-- 4C can wire this in without moving a benchmark count -- see note 1 in
		-- the header.
		--===================================================================
		mclk_w <= clk_i;

		SIMSHARE:
		if (SMCLK_SHARES_MCLK) generate
			smclk_w <= clk_i;
		else generate
			-- Independent, so a design that assumes SMCLK = MCLK fails here
			-- rather than on the board.
			sim_smclk : process
			begin
				smclk_w <= '0';
				wait for SIM_SMCLK_HALF_NS * 1 ns;
				smclk_w <= '1';
				wait for SIM_SMCLK_HALF_NS * 1 ns;
			end process sim_smclk;
		end generate SIMSHARE;

		sim_accel : process
		begin
			accelclk_w <= '0';
			wait for SIM_ACCEL_HALF_NS * 1 ns;
			accelclk_w <= '1';
			wait for SIM_ACCEL_HALF_NS * 1 ns;
		end process sim_accel;

		-- A modelled lock delay. Not a model of PLL physics -- just enough for
		-- Phase 4C's reset-on-lock to have something to wait for.
		--
		-- LIMITATION, STATED SO NOBODY RELIES ON WHAT THIS DOES NOT DO: the
		-- modelled lock is ONE-SHOT and ignores rst_i. A real PLL drops lock when
		-- its areset is asserted and re-acquires it afterwards; this one goes high
		-- once, at SIM_LOCK_DELAY_NS from time zero, and stays there. So a
		-- testbench that asserts reset again mid-run will NOT see the core held
		-- off a second time, and a reset-recovery test written against this model
		-- would prove nothing. No current testbench does that -- all six drive
		-- reset once, high from 0 ns and low at 80 ns -- which is why the
		-- simplification is acceptable rather than merely convenient.
		sim_lock : process
		begin
			locked_w <= '0';
			wait for SIM_LOCK_DELAY_NS * 1 ns;
			locked_w <= '1';
			wait;
		end process sim_lock;

	end generate CLKGEN;

	--=======================================================================
	mclk_o		<= mclk_w;
	smclk_o		<= smclk_w;
	accelclk_o	<= accelclk_w;
	locked_o	<= locked_w;

END structure;
