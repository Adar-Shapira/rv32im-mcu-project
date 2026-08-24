--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- self-checking testbench for CLOCK_TREE.vhd
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_clock.do
--============================================================================
-- WHAT THIS TEST CANNOT DO, SAID FIRST BECAUSE IT MATTERS MOST
--
--   IT DOES NOT VERIFY THE PLLs. It cannot. `altpll` is an Altera black box that
--   needs the altera_mf library, and this project's established idiom -- Hanan's
--   own, in RV32IM_CORE.vhd -- is to not instantiate it in simulation at all:
--       if (MODELSIM = 0) generate MCLK: PLL ... else mclk_w <= clk_i;
--   CLOCK_TREE follows that idiom, so at MODELSIM = 1 there is no PLL present to
--   test. Whether three pll_gen instances actually lock, at the right
--   frequencies, on a Cyclone IV E, is a QUARTUS question and it is on Adar's
--   list, not answerable here by anyone.
--
--   So do not read a PASS here as "the clock tree works". Read it as: the ratio
--   arithmetic is right, the simulation behaviour every later phase depends on is
--   right, and both generate branches actually compile.
--
--   What IS verified, and each of these is worth having:
--     - the ratio arithmetic, at elaboration, exactly (integer, cross-multiplied,
--       no rounding) -- and for TWO different configurations, not just the
--       default, because a check that only ever sees one set of numbers is not
--       much of a check;
--     - that MCLK in simulation is clk_i itself, which is the single property
--       that lets Phase 4C wire this in without moving a benchmark cycle count;
--     - that ACCELCLK is genuinely independent of MCLK and walks through many
--       distinct phases relative to it, which is what makes it useful for
--       exercising Phase 7B's clock-domain crossing;
--     - that locked_o starts low and rises -- so 4C's reset-on-lock has something
--       real to wait for;
--     - that the SMCLK_SHARES_MCLK = FALSE branch compiles and produces a
--       genuinely different clock. Both branches of every generate are
--       instantiated somewhere in this file ON PURPOSE: a generate branch that
--       nothing instantiates is a branch that is never compiled, and it will
--       break the first time someone flips the generic.
--
--   The elaboration asserts' FAILURE path is deliberately not tested. They are
--   `severity failure`, so exercising one aborts the simulation -- that is their
--   job. Their arithmetic is checked independently in the run_clock.do header.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_clock_tree IS
END tb_clock_tree;


ARCHITECTURE test OF tb_clock_tree IS

	-- 100 ns, matching tb_RV32IMscMCU.vhd's "MCLK cycle = 100nsec". The
	-- coprimality claim below is about the real configuration, so it has to be
	-- measured against the clock the real testbenches use.
	constant CLK_PERIOD		: time := 100 ns;
	constant ACCEL_HALF		: natural := 15;	-- CLOCK_TREE's default
	constant LOCK_DELAY		: natural := 200;	-- CLOCK_TREE's default
	constant RUN_NS			: natural := 3000;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	-- A: the default configuration -- MCLK = SMCLK = 20 MHz sharing one net
	SIGNAL mclk_a, smclk_a, accel_a, lock_a : STD_LOGIC;
	-- B: the other branch of every generate, and a SECOND valid ratio set
	SIGNAL mclk_b, smclk_b, accel_b, lock_b : STD_LOGIC;

	-- one driver each, per the note in tb_sync.vhd
	SIGNAL p_lock, f_lock	: NATURAL := 0;
	SIGNAL p_mclk, f_mclk	: NATURAL := 0;
	SIGNAL p_per,  f_per	: NATURAL := 0;
	SIGNAL p_fin,  f_fin	: NATURAL := 0;

	SIGNAL accel_edges		: NATURAL := 0;		-- anti-vacuity
	SIGNAL mclk_edges		: NATURAL := 0;
	SIGNAL smclk_b_edges	: NATURAL := 0;		-- P5
	SIGNAL phase_count		: NATURAL := 0;		-- distinct ACCELCLK/MCLK phases seen
	SIGNAL last_mclk_ns		: NATURAL := 0;

	function bit_img(b : STD_LOGIC) return STRING is
	begin
		case b is
			when '0' => return "0";
			when '1' => return "1";
			when 'U' => return "U";
			when 'X' => return "X";
			when 'Z' => return "Z";
			when others => return "?";
		end case;
	end function bit_img;

BEGIN
	--=======================================================================
	-- A -- everything defaulted. This is the configuration the design ships in.
	--=======================================================================
	DUT_A : clock_tree
	generic map(MODELSIM => 1)
	PORT MAP(clk_i => clk, rst_i => rst,
			 mclk_o => mclk_a, smclk_o => smclk_a,
			 accelclk_o => accel_a, locked_o => lock_a);

	--=======================================================================
	-- B -- SMCLK on its own net, and a completely different (but still exact)
	-- set of ratios: MCLK 25 MHz = 50 * 1/2, SMCLK 10 MHz = 50 * 1/5. If the
	-- elaboration arithmetic were wrong in a way that happened to work for
	-- 2/5, this instance would catch it.
	--=======================================================================
	DUT_B : clock_tree
	generic map(MODELSIM => 1,
				MCLK_KHZ => 25000, MCLK_MUL => 1, MCLK_DIV => 2,
				SMCLK_KHZ => 10000, SMCLK_MUL => 1, SMCLK_DIV => 5,
				SMCLK_SHARES_MCLK => FALSE)
	PORT MAP(clk_i => clk, rst_i => rst,
			 mclk_o => mclk_b, smclk_o => smclk_b,
			 accelclk_o => accel_b, locked_o => lock_b);

	--=======================================================================
	clk_gen : process
	begin
		while running loop
			clk <= '0'; wait for CLK_PERIOD/2;
			clk <= '1'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	--=======================================================================
	-- P0 -- locked_o starts low and rises at the modelled delay.
	--=======================================================================
	lock_check : process
		variable p, f : NATURAL := 0;
	begin
		-- Just before the delay expires it must still be low. Sampled 10 ns
		-- early rather than exactly on the boundary, so the check does not turn
		-- on a delta-cycle race with the assignment itself.
		wait for (LOCK_DELAY - 10) * 1 ns;
		if lock_a = '0' and lock_b = '0' then
			p := p + 1;
			report "PASS P0a locked starts low" severity note;
		else
			f := f + 1;
			report "FAIL P0a locked is not low before the modelled lock delay: " &
				"A=" & bit_img(lock_a) & " B=" & bit_img(lock_b) &
				". Phase 4C's reset-on-lock would release reset immediately."
				severity error;
		end if;

		wait for 20 ns;
		if lock_a = '1' and lock_b = '1' then
			p := p + 1;
			report "PASS P0b locked rises" severity note;
		else
			f := f + 1;
			report "FAIL P0b locked never rose: A=" & bit_img(lock_a) &
				" B=" & bit_img(lock_b) & ". Phase 4C would hold reset forever."
				severity error;
		end if;
		p_lock <= p; f_lock <= f;
		wait;
	end process lock_check;

	--=======================================================================
	-- P1 / P2 -- in simulation MCLK **is** clk_i, and SMCLK follows it when the
	-- two share a net. This is the property Phase 4C depends on: wire the tree
	-- in and the four benchmark counts must not move.
	--
	-- Sampled 1 ns after each clk_i edge, not at it. mclk_o reaches the port
	-- through two delta cycles (clk_i -> mclk_w -> mclk_o), so a comparison made
	-- at the instant clk_i changes sees a transient mismatch that means nothing.
	--=======================================================================
	mclk_check : process
		variable p, f : NATURAL := 0;
		variable n    : NATURAL := 0;
	begin
		while running loop
			wait until rising_edge(clk) or not running;
			exit when not running;
			wait for 1 ns;
			n := n + 1;
			if mclk_a = '1' and smclk_a = '1' and mclk_b = '1' then
				p := p + 1;
			else
				f := f + 1;
				if f <= 5 then
					report "FAIL P1 mclk does not follow clk_i high: mclk_a=" &
						bit_img(mclk_a) & " smclk_a=" & bit_img(smclk_a) &
						" mclk_b=" & bit_img(mclk_b) severity error;
				end if;
			end if;

			wait until falling_edge(clk) or not running;
			exit when not running;
			wait for 1 ns;
			if mclk_a = '0' and smclk_a = '0' and mclk_b = '0' then
				p := p + 1;
			else
				f := f + 1;
				if f <= 5 then
					report "FAIL P1 mclk does not follow clk_i low: mclk_a=" &
						bit_img(mclk_a) & " smclk_a=" & bit_img(smclk_a) &
						" mclk_b=" & bit_img(mclk_b) severity error;
				end if;
			end if;
			mclk_edges <= n;
			p_mclk <= p; f_mclk <= f;
		end loop;
		wait;
	end process mclk_check;

	--=======================================================================
	-- Timestamp of the last MCLK rising edge, for the phase measurement below.
	-- Its own process because a signal may have only one driver.
	--=======================================================================
	mclk_stamp : process
	begin
		while running loop
			wait until rising_edge(mclk_a) or not running;
			exit when not running;
			last_mclk_ns <= (now / 1 ns);
		end loop;
		wait;
	end process mclk_stamp;

	--=======================================================================
	-- P5's evidence: how many rising edges DUT_B's independent SMCLK produced.
	-- Its own process for the one-driver-per-signal rule.
	--=======================================================================
	smclk_b_count : process
		variable n : NATURAL := 0;
	begin
		while running loop
			wait until rising_edge(smclk_b) or not running;
			exit when not running;
			n := n + 1;
			smclk_b_edges <= n;
		end loop;
		wait;
	end process smclk_b_count;

	--=======================================================================
	-- P3 -- ACCELCLK's period is what the generic asks for.
	-- P4 -- and it is genuinely independent of MCLK: its edges land at many
	--       distinct offsets within the MCLK period. CLOCK_TREE's header claims
	--       the ratio is deliberately coprime so the fast edge walks through
	--       every phase of the slow one; this is that claim, measured.
	--=======================================================================
	accel_check : process
		variable p, f		: NATURAL := 0;
		variable prev_ns	: INTEGER := -1;
		variable this_ns	: NATURAL;
		variable n			: NATURAL := 0;
		variable offset		: NATURAL;
		type seen_t is array (0 TO 99) of BOOLEAN;
		variable seen		: seen_t := (others => FALSE);
		variable distinct	: NATURAL := 0;
	begin
		while running loop
			wait until rising_edge(accel_a) or not running;
			exit when not running;
			this_ns := (now / 1 ns);
			n := n + 1;

			if prev_ns >= 0 then
				if (this_ns - prev_ns) = 2 * ACCEL_HALF then
					p := p + 1;
				else
					f := f + 1;
					if f <= 5 then
						report "FAIL P3 accelclk period is " &
							integer'image(this_ns - prev_ns) & " ns, expected " &
							integer'image(2 * ACCEL_HALF) severity error;
					end if;
				end if;
			end if;
			prev_ns := this_ns;

			-- offset of this accel edge within the MCLK period
			offset := (this_ns - last_mclk_ns) mod (CLK_PERIOD / 1 ns);
			if not seen(offset) then
				seen(offset) := TRUE;
				distinct := distinct + 1;
				phase_count <= distinct;
			end if;

			accel_edges <= n;
			p_per <= p; f_per <= f;
		end loop;
		wait;
	end process accel_check;

	--=======================================================================
	-- Stimulus, then the verdict.
	--=======================================================================
	stimulus : process
		variable p, f : NATURAL := 0;
	begin
		rst <= '1';
		wait for 3 * CLK_PERIOD;
		rst <= '0';

		wait for RUN_NS * 1 ns;

		-- ---- P5: B's SMCLK really is a different clock --------------------
		-- The whole point of the FALSE branch. If someone "simplifies" it to
		-- smclk_w <= clk_i, this is what notices.
		--
		-- COUNTED, not sampled. An earlier version of this check compared the two
		-- levels at two instants half an MCLK period apart and called them
		-- distinct if they ever differed -- which fails a CORRECT design: at
		-- 70 ns against 100 ns the two clocks genuinely agree at both of those
		-- points more than once per run. Counting edges over the whole run cannot
		-- do that: a 70 ns clock must produce strictly more rising edges than a
		-- 100 ns one, and a "simplified" SMCLK tied to clk_i produces exactly the
		-- same number.
		if smclk_b_edges > mclk_edges then
			p := p + 1;
			report "PASS P5 the non-sharing branch produces a distinct SMCLK: " &
				integer'image(smclk_b_edges) & " SMCLK edges against " &
				integer'image(mclk_edges) & " MCLK edges" severity note;
		else
			f := f + 1;
			report "FAIL P5 with SMCLK_SHARES_MCLK => FALSE, SMCLK produced " &
				integer'image(smclk_b_edges) & " rising edges against MCLK's " &
				integer'image(mclk_edges) & ". A genuinely independent 70 ns " &
				"clock must produce strictly more than a 100 ns one; equal counts " &
				"mean the FALSE branch is just following clk_i." severity error;
		end if;

		-- ---- P6: anti-vacuity ---------------------------------------------
		if accel_edges >= 50 and mclk_edges >= 20 then
			p := p + 1;
		else
			f := f + 1;
			report "FAIL P6 anti_vacuity: only " & integer'image(accel_edges) &
				" accelclk edges and " & integer'image(mclk_edges) &
				" mclk edges were observed, so the checks above ran on almost " &
				"nothing" severity error;
		end if;

		if phase_count >= 5 then
			p := p + 1;
			report "PASS P4 accelclk walks " & integer'image(phase_count) &
				" distinct phases of the mclk period" severity note;
		else
			f := f + 1;
			report "FAIL P4 accelclk landed at only " & integer'image(phase_count) &
				" distinct offsets within the mclk period. The sim ratio is not " &
				"coprime, so a Phase 7B crossing bug could hide behind a fixed " &
				"edge relationship." severity error;
		end if;
		p_fin <= p; f_fin <= f;
		wait for 1 ns;

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "======= CLOCK_TREE (Figure 1) SUMMARY =======" severity note;
		report "  lock      passed " & integer'image(p_lock) &
			", failed " & integer'image(f_lock) severity note;
		report "  mclk=clk  passed " & integer'image(p_mclk) &
			", failed " & integer'image(f_mclk) severity note;
		report "  accel per passed " & integer'image(p_per) &
			", failed " & integer'image(f_per) severity note;
		report "  final     passed " & integer'image(p_fin) &
			", failed " & integer'image(f_fin) severity note;
		report "  observed: " & integer'image(accel_edges) & " accelclk edges, " &
			integer'image(mclk_edges) & " mclk edges, " &
			integer'image(phase_count) & " distinct phases" severity note;
		if (f_lock + f_mclk + f_per + f_fin) = 0 then
			report "  VERDICT: PASS - the ratios elaborate, MCLK is clk_i in " &
				"simulation, and ACCELCLK is independent of it." severity note;
			report "  NOTE: this does NOT verify the PLLs. altpll is not " &
				"instantiated at MODELSIM=1. That check is Quartus-only." severity note;
		else
			report "  VERDICT: FAIL - " &
				integer'image(f_lock + f_mclk + f_per + f_fin) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "=============================================" severity note;

		running <= FALSE;
		wait for 2 * CLK_PERIOD;
		std.env.stop;
	end process stimulus;

END test;
