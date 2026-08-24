--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- self-checking testbench for DIV_ACCEL.vhd
--
-- Proves that the Figure 9 accelerator divides correctly and that its timing is
-- the one page 9 states. Self-checking: it prints a pass/fail tally and stops
-- itself, so it needs no waveform reading and no stop condition in the .do
-- script, and it needs no memory images -- it is a leaf test like tb_sync and
-- tb_addr_decoder, runnable the moment compile.do finishes.
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_div.do
--============================================================================
-- THE TWO INSTANCES, AND WHY THE SMALL ONE IS THE IMPORTANT ONE
--
--   DUT8  is N = 8 and is swept EXHAUSTIVELY: all 256 dividends against all 256
--         divisors, 65536 operations, divide-by-zero column included. Every
--         quotient and every residue is compared against IEEE.NUMERIC_STD's own
--         "/" and "rem", which share no line of code with the restoring
--         datapath under test.
--
--   DUT32 is N = 32, the case page 9 fixes, and gets directed corners plus 500
--         pseudo-random pairs.
--
--   The exhaustive sweep is at 8 bits and the design ships at 32, so state the
--   gap rather than let the word "exhaustive" paper over it: 65536 cases at N=8
--   is NOT a proof for N=32. What makes it worth far more than a sample at 32
--   bits is that the datapath is width-independent -- the same shift, the same
--   subtract, the same select, N times -- so a wiring error, an off-by-one in
--   the slice boundaries or a wrong restore condition is a bug at every width
--   and the sweep finds it. What the sweep cannot find is a bug that exists ONLY
--   at 32 bits, and there is exactly one candidate for that: the claim in
--   DIV_ACCEL.vhd's header that an N-bit Y never overflows. So the directed list
--   at N=32 aims straight at it -- divisors at and above 2**31, dividends at
--   0xFFFFFFFF, and the pseudo-random stream deliberately forces a divisor with
--   bit 31 set every sixteenth case.
--
-- THE PROPERTIES
--   P0  RESET. While DIVRST is high, busy, quotient and residue are all zero.
--   P1c DIVBUSY IS LOW BEFORE THE LOAD, on every operation. Added after review,
--       and it is the property that gives P1 its meaning: "DIVBUSY is high one
--       cycle after the load" is also true of a DIVBUSY that was ALREADY high,
--       so without a baseline an engine whose DIVBUSY means "not DONE" -- i.e.
--       permanently asserted between divides -- passes everything else.
--   P1  LATENCY. Page 9: "results are ready after N DIVCLK cycles after loading".
--       Measured on every single operation, both widths: DIVBUSY must rise on
--       the load edge and fall exactly N DIVCLK periods later. Not once as a
--       spot check -- 66000+ times, so a data-dependent early exit cannot hide.
--   P2  QUOTIENT and P3 RESIDUE against the independent reference model.
--   P3b THE RESULT SURVIVES THE RE-ARM. Also added after review. Every other
--       check samples the outputs at the one falling edge where DIVBUSY first
--       reads low and never looks again, so an engine that wipes the quotient
--       and residue on the DONE -> IDLE transition passed the whole suite -- and
--       in Phase 7B that would destroy every result the core tries to write back.
--   P4  DIVIDE BY ZERO. Quotient all ones, residue = dividend, per Hanan's forum
--       answer (DOC/03, F4) and the RISC-V spec for divu/remu. Covered 256 times
--       by the N=8 sweep and directly at N=32.
--   P5  RESET WHILE BUSY. DIVRST mid-operation drops DIVBUSY and clears the
--       outputs, and the NEXT divide is still correct -- an abort must not leave
--       the engine wedged. It aborts 0xDEADBEEF / 7, whose partial quotient AND
--       partial residue are both non-zero from iteration 4 to 7, and it CHECKS
--       that before aborting: an earlier version used operands with sixteen
--       leading zeros, so both partials were provably zero at the abort point and
--       "DIVRST cleared them" could not be told from "they were never set".
--   P6  BACK TO BACK. The directed and random loops issue operations one after
--       another with a single idle cycle between; every one of them is checked,
--       so a stale divisor register or an uncleared quotient register fails.
--   P7  DIVENA HELD HIGH. The one that matters most, because it is the one a
--       plausible design gets wrong. Figure 3 makes DIVstart a combinational
--       Control Unit output, so it stays asserted for the whole stall: after the
--       result is ready, DIVENA is held high for twenty more cycles and DIVBUSY
--       must stay low and the outputs must not move. An engine that restarts on
--       a level fails here and passes everything else.
--   P8  ANTI-VACUITY. The operation counts must match what was intended, and the
--       run must have produced at least one non-zero quotient and at least one
--       non-zero residue. Without this a testbench that ran nothing at all would
--       print PASS.
--
-- WHY EACH CHECKER OWNS ITS OWN COUNTERS
--   Same reason as tb_sync.vhd: NATURAL is unresolved, so two processes cannot
--   share one counter signal. Each stimulus drives its own pair and the verdict
--   process reads both.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_div_accel IS
	generic(
		-- 1 = run the full 65536-pair sweep at N=8 (the default, and what a
		-- verification run must use). 0 = skip it, for a quick smoke test while
		-- editing the RTL. The .do script prints which mode it ran in.
		EXHAUSTIVE	: integer := 1;
		-- How many pseudo-random pairs to run at N=32.
		RANDOM_OPS	: integer := 500
	);
END tb_div_accel;


ARCHITECTURE test OF tb_div_accel IS

	constant CLK_PERIOD	: time := 20 ns;
	constant N32		: integer := 32;
	constant N8			: integer := 8;

	-- A wrong divider is wrong thousands of times, and 65536 FAIL lines is not a
	-- transcript anyone reads. After this many, failures are still counted but no
	-- longer printed.
	constant MAX_REPORTS	: natural := 20;

	-- STD_LOGIC'image renders '1' complete with its quote marks, so a report
	-- concatenating it reads "busy=''1''". One CASE fixes it; the same helper is
	-- in the other testbenches of this project for the same reason.
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

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL running	: BOOLEAN := TRUE;

	-- N = 32 instance
	SIGNAL rst32	: STD_LOGIC := '1';
	SIGNAL ena32	: STD_LOGIC := '0';
	SIGNAL dvd32	: STD_LOGIC_VECTOR(N32-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL dvs32	: STD_LOGIC_VECTOR(N32-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL busy32	: STD_LOGIC;
	SIGNAL quo32	: STD_LOGIC_VECTOR(N32-1 DOWNTO 0);
	SIGNAL res32	: STD_LOGIC_VECTOR(N32-1 DOWNTO 0);

	-- N = 8 instance
	SIGNAL rst8		: STD_LOGIC := '1';
	SIGNAL ena8		: STD_LOGIC := '0';
	SIGNAL dvd8		: STD_LOGIC_VECTOR(N8-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL dvs8		: STD_LOGIC_VECTOR(N8-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL busy8	: STD_LOGIC;
	SIGNAL quo8		: STD_LOGIC_VECTOR(N8-1 DOWNTO 0);
	SIGNAL res8		: STD_LOGIC_VECTOR(N8-1 DOWNTO 0);

	-- one driver each
	SIGNAL p32, f32	: NATURAL := 0;
	SIGNAL p8,  f8	: NATURAL := 0;
	SIGNAL ops32	: NATURAL := 0;
	SIGNAL ops8		: NATURAL := 0;
	SIGNAL nz_quo	: NATURAL := 0;		-- P8: operations that produced a non-zero quotient
	SIGNAL nz_res	: NATURAL := 0;		-- P8: ... and a non-zero residue
	SIGNAL done32	: BOOLEAN := FALSE;
	SIGNAL done8	: BOOLEAN := FALSE;

	constant Z32	: STD_LOGIC_VECTOR(N32-1 DOWNTO 0) := (OTHERS => '0');
	constant Z8		: STD_LOGIC_VECTOR(N8-1 DOWNTO 0)  := (OTHERS => '0');

	--=======================================================================
	-- The N=32 directed list. Every entry is here because it can fail on its
	-- own:
	--   0-3    the ordinary cases, so an obviously broken engine dies fast
	--   4-5    the widest dividend
	--   6-9    DIVISOR AT OR ABOVE 2**31 -- the one corner the N=8 sweep cannot
	--          reach, and the only place DIV_ACCEL.vhd's "an N-bit Y never
	--          overflows" argument could be wrong
	--   10-11  quotient must come out zero (dividend < divisor)
	--   12-14  the divide-by-zero column, P4
	--   15     the RV32I signed extremes read as unsigned, which is what Phase
	--          7B's signed wrapper will hand this engine
	--
	-- Declared at architecture level, not inside the stimulus, so the verdict
	-- process can size its own expected operation count from 'LENGTH. Adding a
	-- row here must not silently break the anti-vacuity check, and with a
	-- hard-coded 16 in the verdict it would have.
	--=======================================================================
	type vec_array is array (natural range <>) of STD_LOGIC_VECTOR(N32-1 DOWNTO 0);

	constant DVD_LIST : vec_array := (
		x"00000000", x"00000001", x"00000007", x"00000064",
		x"FFFFFFFF", x"FFFFFFFF",
		x"FFFFFFFF", x"80000000", x"80000000", x"7FFFFFFF",
		x"7FFFFFFF", x"FFFFFFFE",
		x"00000000", x"00000001", x"DEADBEEF",
		x"80000000");

	constant DVS_LIST : vec_array := (
		x"00000001", x"00000001", x"00000002", x"00000007",
		x"00000001", x"FFFFFFFF",
		x"80000000", x"80000000", x"7FFFFFFF", x"80000000",
		x"FFFFFFFF", x"FFFFFFFF",
		x"00000000", x"00000000", x"00000000",
		x"FFFFFFFF");

	--=======================================================================
	-- The reference model. Deliberately built out of IEEE.NUMERIC_STD's own
	-- operators, which are a different algorithm entirely from the restoring
	-- datapath under test -- a model that reimplemented the same shift-and-
	-- subtract would agree with the DUT precisely when both were wrong.
	--
	-- The zero-divisor guard is not a convenience: NUMERIC_STD's "/" and "rem"
	-- are undefined for a zero right operand and simulators flag it, so the
	-- expected values for that column come from the specification instead --
	-- quotient all ones, residue the dividend, exactly as Hanan stated and as
	-- RISC-V requires. That is the ONE place the model is told the answer rather
	-- than computing it, which is why it is written where it cannot be missed.
	--=======================================================================
	function ref_quot(dvd, dvs : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
		constant ONES : STD_LOGIC_VECTOR(dvd'range) := (OTHERS => '1');
	begin
		if unsigned(dvs) = 0 then
			return ONES;
		else
			return STD_LOGIC_VECTOR(unsigned(dvd) / unsigned(dvs));
		end if;
	end function ref_quot;

	function ref_res(dvd, dvs : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
	begin
		if unsigned(dvs) = 0 then
			return dvd;
		else
			return STD_LOGIC_VECTOR(unsigned(dvd) rem unsigned(dvs));
		end if;
	end function ref_res;

	--=======================================================================
	-- Run one division and check P1, P2, P3 on it.
	--
	-- Written once and used by both instances, which is why the vectors are
	-- unconstrained: the same procedure drives the 8-bit sweep and the 32-bit
	-- directed list, so the two cannot drift apart and quietly check different
	-- things.
	--
	-- Sampling is on the FALLING edge throughout. Reading a signal at the rising
	-- edge that produces it yields its pre-edge value, and every off-by-one in a
	-- latency measurement traces back to that; mid-cycle everything has settled
	-- and there is nothing to get wrong.
	--=======================================================================
	procedure do_div(
		signal   clk_s	: IN	STD_LOGIC;
		signal   ena_s	: OUT	STD_LOGIC;
		signal   dvd_s	: OUT	STD_LOGIC_VECTOR;
		signal   dvs_s	: OUT	STD_LOGIC_VECTOR;
		signal   busy_s	: IN	STD_LOGIC;
		signal   quo_s	: IN	STD_LOGIC_VECTOR;
		signal   res_s	: IN	STD_LOGIC_VECTOR;
		constant dvd	: IN	STD_LOGIC_VECTOR;
		constant dvs	: IN	STD_LOGIC_VECTOR;
		constant nn		: IN	INTEGER;
		constant tag	: IN	STRING;
		variable pass	: INOUT	NATURAL;
		variable fail	: INOUT	NATURAL;
		variable nrep	: INOUT	NATURAL;
		variable nzq	: INOUT	NATURAL;
		variable nzr	: INOUT	NATURAL
	) is
		variable cycles	: NATURAL := 0;
		variable eq		: STD_LOGIC_VECTOR(dvd'range);
		variable er		: STD_LOGIC_VECTOR(dvd'range);
		constant ZV		: STD_LOGIC_VECTOR(dvd'range) := (OTHERS => '0');
	begin
		eq := ref_quot(dvd, dvs);
		er := ref_res(dvd, dvs);

		-- ---- P1c: the engine must be IDLE before we start --------------------
		-- Added after review, and it is not a formality. Without it, P1a below
		-- only asks "is DIVBUSY high one cycle after the load", which a DIVBUSY
		-- that was ALREADY high satisfies. Hoisting `busy_q <= '1'` out of the
		-- `IF divena_i = '1'` in the RTL's IDLE branch turns DIVBUSY into
		-- "not DONE" -- permanently asserted between divides, which in the real
		-- MCU means the core's stall ends on the PREVIOUS divide's busy -- and
		-- that mutation passed every other property in this file with
		-- byte-identical counters. Establishing the baseline is what ties
		-- DIVBUSY's assertion to the load edge.
		if busy_s /= '0' then
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL busy_not_low_before_load [" & tag & "]: DIVBUSY is " &
					bit_img(busy_s) & " while the engine should be idle. DIVBUSY " &
					"must mean 'this operation is running', not 'not finished'."
					severity error;
			end if;
		else
			pass := pass + 1;
		end if;

		dvd_s <= dvd;
		dvs_s <= dvs;
		ena_s <= '1';

		wait until rising_edge(clk_s);		-- Figure 9's Load edge
		wait until falling_edge(clk_s);		-- everything settled

		-- ---- P1a: busy must be up straight after the load -------------------
		if busy_s /= '1' then
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL busy_did_not_rise [" & tag & "]: DIVBUSY is " &
					bit_img(busy_s) & " on the cycle after the load edge"
					severity error;
			end if;
		else
			pass := pass + 1;
		end if;

		-- ---- P1b: and must fall exactly nn cycles later ----------------------
		cycles := 0;
		while busy_s = '1' and cycles <= 2*nn + 8 loop
			wait until falling_edge(clk_s);
			cycles := cycles + 1;
		end loop;

		if cycles = nn then
			pass := pass + 1;
		else
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL latency [" & tag & "]: DIVBUSY was high for " &
					integer'image(cycles) & " DIVCLK cycles, page 9 requires " &
					integer'image(nn) & ". A count of 0 means it never rose; a " &
					"count of " & integer'image(2*nn + 8) & " means it never fell."
					severity error;
			end if;
		end if;

		-- ---- P2 / P3: the numbers -------------------------------------------
		if quo_s = eq then
			pass := pass + 1;
		else
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL quotient [" & tag & "]: 0x" & to_hstring(dvd) &
					" / 0x" & to_hstring(dvs) & " gave 0x" & to_hstring(quo_s) &
					", expected 0x" & to_hstring(eq) severity error;
			end if;
		end if;

		if res_s = er then
			pass := pass + 1;
		else
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL residue [" & tag & "]: 0x" & to_hstring(dvd) &
					" rem 0x" & to_hstring(dvs) & " gave 0x" & to_hstring(res_s) &
					", expected 0x" & to_hstring(er) severity error;
			end if;
		end if;

		-- P8 material: record that this run actually produced something.
		if eq /= ZV then nzq := nzq + 1; end if;
		if er /= ZV then nzr := nzr + 1; end if;

		-- Drop DIVENA and give the engine the one edge it needs to re-arm, so
		-- the next call finds it in IDLE. See the handshake note in DIV_ACCEL.vhd.
		ena_s <= '0';
		wait until rising_edge(clk_s);
		wait until falling_edge(clk_s);

		-- ---- P3b: the result must SURVIVE the re-arm -------------------------
		-- Also added after review. Every check above samples the outputs at the
		-- one falling edge where DIVBUSY first reads low, and then never looks
		-- again -- so an engine that clears the quotient and residue on the
		-- DONE -> IDLE transition passed the entire suite. That is not a
		-- theoretical bug: it is a plausible misreading of "DIVRST initialises
		-- the quotient shift register", and in Phase 7B it would destroy every
		-- result. The core sees DIVBUSY fall through a two-flop synchronizer and
		-- writes back at least one MCLK edge later, while DIVENA drops in that
		-- same MCLK cycle and reaches the accelerator a couple of DIVCLK edges
		-- later -- and DIVCLK is the FAST clock, so the engine would re-arm and
		-- wipe both registers before the core ever latched them.
		if quo_s = eq and res_s = er then
			pass := pass + 1;
		else
			fail := fail + 1;
			if nrep < MAX_REPORTS then
				nrep := nrep + 1;
				report "FAIL result_lost_on_rearm [" & tag & "]: after DIVENA " &
					"fell and the engine re-armed, quotient is 0x" &
					to_hstring(quo_s) & " and residue 0x" & to_hstring(res_s) &
					", expected 0x" & to_hstring(eq) & " and 0x" & to_hstring(er) &
					". The results must hold until the next Load."
					severity error;
			end if;
		end if;
	end procedure do_div;

	-- Deterministic pseudo-random operands: a 32-bit maximal-length LFSR. Not a
	-- statistical generator and not meant to be -- what matters is that the
	-- stream is the same on every run, so a failure Adar sees is a failure that
	-- reproduces here, with no seed to write down.
	procedure lfsr_step(variable s : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0)) is
		variable fb : STD_LOGIC;
	begin
		fb := s(31) XOR s(21) XOR s(1) XOR s(0);
		s  := s(30 DOWNTO 0) & fb;
	end procedure lfsr_step;

BEGIN
	-- Elaboration-time. A directed row added to one list and not the other would
	-- otherwise raise an index error 500 operations into the run, or worse, pair
	-- the wrong dividend with the wrong divisor and look like an RTL bug.
	assert DVD_LIST'length = DVS_LIST'length
		report "tb_div_accel: DVD_LIST and DVS_LIST must be the same length"
		severity failure;

	--=======================================================================
	DUT32 : div_accel
	generic map(N => N32)
	PORT MAP(divclk_i => clk, divrst_i => rst32, divena_i => ena32,
			 dividend_i => dvd32, divisor_i => dvs32,
			 divbusy_o => busy32, quotient_o => quo32, residue_o => res32);

	DUT8 : div_accel
	generic map(N => N8)
	PORT MAP(divclk_i => clk, divrst_i => rst8, divena_i => ena8,
			 dividend_i => dvd8, divisor_i => dvs8,
			 divbusy_o => busy8, quotient_o => quo8, residue_o => res8);

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
	-- N = 32: P0, the directed corners, the random stream, then P5 and P7.
	--=======================================================================
	stim32 : process
		variable p, f	: NATURAL := 0;
		variable nrep	: NATURAL := 0;
		variable nzq	: NATURAL := 0;
		variable nzr	: NATURAL := 0;
		variable ops	: NATURAL := 0;
		variable lf		: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"12345678";
		variable a, b	: STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable hold_q	: STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable hold_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable p7_ok	: BOOLEAN;
		variable pre_q	: STD_LOGIC_VECTOR(31 DOWNTO 0);
		variable pre_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	begin
		-- ---- P0: reset holds everything at zero ------------------------------
		rst32 <= '1';
		ena32 <= '0';
		wait for 4*CLK_PERIOD;
		if busy32 = '0' and quo32 = Z32 and res32 = Z32 then
			p := p + 1;
			report "PASS P0 reset_holds_outputs_low (N=32)" severity note;
		else
			f := f + 1;
			report "FAIL P0 reset_holds_outputs_low (N=32): busy=" &
				bit_img(busy32) & " quo=0x" & to_hstring(quo32) &
				" res=0x" & to_hstring(res32) severity error;
		end if;
		p32 <= p; f32 <= f;
		wait until falling_edge(clk);
		rst32 <= '0';

		-- ---- the directed corners --------------------------------------------
		for i in DVD_LIST'range loop
			do_div(clk, ena32, dvd32, dvs32, busy32, quo32, res32,
				   DVD_LIST(i), DVS_LIST(i), N32,
				   "N32 directed #" & integer'image(i),
				   p, f, nrep, nzq, nzr);
			ops := ops + 1;
			p32 <= p; f32 <= f; ops32 <= ops;
		end loop;
		report "N=32 directed corners done: " & integer'image(ops) &
			" operations, " & integer'image(f) & " failure(s) so far" severity note;

		-- ---- the pseudo-random stream ----------------------------------------
		for i in 1 to RANDOM_OPS loop
			lfsr_step(lf); a := lf;
			lfsr_step(lf); b := lf;
			-- Bias the divisor on purpose. An unbiased 32-bit divisor is almost
			-- always huge, which makes almost every quotient 0 or 1 and leaves the
			-- interesting part of the datapath untested.
			if (i mod 8) = 0 then
				b := b AND x"000000FF";		-- small divisor -> a long quotient
			elsif (i mod 16) = 3 then
				b := b OR  x"80000000";		-- divisor >= 2**31, the width corner
			end if;
			do_div(clk, ena32, dvd32, dvs32, busy32, quo32, res32,
				   a, b, N32, "N32 random #" & integer'image(i),
				   p, f, nrep, nzq, nzr);
			ops := ops + 1;
			p32 <= p; f32 <= f; ops32 <= ops;
		end loop;
		report "N=32 random stream done: " & integer'image(RANDOM_OPS) &
			" operations" severity note;

		-- ---- P5: DIVRST while the engine is busy ------------------------------
		-- THE OPERANDS ARE CHOSEN, NOT ARBITRARY, and an earlier version of this
		-- test was vacuous because they were not. It aborted 0x0000FFFF / 3 --
		-- but that dividend has sixteen leading zeros, so for the first sixteen
		-- iterations the shift register's upper half is still zero, Y = 0 < 3
		-- every time, and BOTH partials are exactly zero at the abort point. The
		-- "DIVRST cleared them" check was therefore satisfied by the arithmetic
		-- rather than by DIVRST, and deleting the sr_q/qsr_q clears from the
		-- RTL's DIVRST branch passed the whole suite.
		--
		-- 0xDEADBEEF / 7 has both partials non-zero continuously from iteration 4
		-- through iteration 7 (q = 1,3,7,F with r = 6 throughout), so the window
		-- is wide enough that an off-by-one in either direction is still a real
		-- test. Five iterations in, the partials are q = 0x3 and r = 0x6.
		--
		-- And it no longer TRUSTS that: the guard below samples the partials just
		-- before the abort and fails if either is zero, so if this test ever
		-- becomes vacuous again it says so instead of passing.
		dvd32 <= x"DEADBEEF";
		dvs32 <= x"00000007";
		ena32 <= '1';
		wait until rising_edge(clk);			-- load edge
		for k in 1 to 6 loop					-- five iterations completed
			wait until falling_edge(clk);
		end loop;
		if busy32 /= '1' then
			f := f + 1;
			report "FAIL P5 setup: the engine was not busy five iterations into a divide"
				severity error;
		end if;
		pre_q := quo32;
		pre_r := res32;
		if pre_q = Z32 or pre_r = Z32 then
			f := f + 1;
			report "FAIL P5 IS VACUOUS: at the abort point the partial quotient is 0x" &
				to_hstring(pre_q) & " and the partial residue 0x" & to_hstring(pre_r) &
				". At least one is zero, so 'DIVRST cleared it' cannot be told apart " &
				"from 'it was never set'. Change the operands or the abort point: " &
				"0xDEADBEEF/7 has both non-zero from iteration 4 to 7."
				severity error;
		else
			p := p + 1;
			report "PASS P5 is not vacuous: partials at the abort point are q=0x" &
				to_hstring(pre_q) & " r=0x" & to_hstring(pre_r) severity note;
		end if;
		rst32 <= '1';
		wait until falling_edge(clk);
		wait until falling_edge(clk);
		if busy32 = '0' and quo32 = Z32 and res32 = Z32 then
			p := p + 1;
			report "PASS P5 reset_while_busy aborts and clears" severity note;
		else
			f := f + 1;
			report "FAIL P5 reset_while_busy: busy=" & bit_img(busy32) &
				" quo=0x" & to_hstring(quo32) & " res=0x" & to_hstring(res32) &
				". DIVRST did not abort the operation" severity error;
		end if;
		rst32 <= '0';
		ena32 <= '0';
		wait until falling_edge(clk);
		wait until rising_edge(clk);
		-- and the engine must still work afterwards, which is the half of P5 that
		-- an abort-but-wedge bug fails
		do_div(clk, ena32, dvd32, dvs32, busy32, quo32, res32,
			   x"0000FFFF", x"00000003", N32, "N32 after-abort",
			   p, f, nrep, nzq, nzr);
		ops := ops + 1;
		p32 <= p; f32 <= f; ops32 <= ops;

		-- ---- P7: DIVENA held high past completion -----------------------------
		-- This is the one that catches a level-triggered start. Note it is run
		-- WITHOUT do_div, because do_div drops DIVENA at the end and that is
		-- exactly the behaviour under test here.
		dvd32 <= x"000003E8";					-- 1000
		dvs32 <= x"00000007";					--    7  -> 142 remainder 6
		ena32 <= '1';
		wait until rising_edge(clk);			-- load
		wait until falling_edge(clk);
		while busy32 = '1' loop
			wait until falling_edge(clk);
		end loop;
		hold_q := quo32;
		hold_r := res32;
		if hold_q = x"0000008E" and hold_r = x"00000006" then
			p := p + 1;
		else
			f := f + 1;
			report "FAIL P7 setup: 1000/7 gave 0x" & to_hstring(hold_q) &
				" rem 0x" & to_hstring(hold_r) & ", expected 0x0000008E rem 0x00000006"
				severity error;
		end if;
		-- DIVENA is still high. Twenty cycles of it.
		-- p7_ok is a local flag rather than a test on the global failure count: by
		-- this point f may already be non-zero from an earlier property, and
		-- "f = 0" would then report P7 as failed when P7 itself passed -- or, with
		-- the condition written the other way round, report a pass it did not earn.
		p7_ok := TRUE;
		for k in 1 to 20 loop
			wait until falling_edge(clk);
			if busy32 /= '0' then
				f := f + 1;
				p7_ok := FALSE;
				report "FAIL P7 divena_held_high: the engine RESTARTED " &
					integer'image(k) & " cycle(s) after finishing, with DIVENA " &
					"still high. Figure 3's DIVstart is a combinational Control " &
					"Unit output and stays asserted for the whole stall, so a " &
					"level-triggered start relaunches the divide forever and the " &
					"core never sees a result." severity error;
				exit;
			end if;
			if quo32 /= hold_q or res32 /= hold_r then
				f := f + 1;
				p7_ok := FALSE;
				report "FAIL P7 divena_held_high: the outputs moved after " &
					"completion: quo 0x" & to_hstring(quo32) & " res 0x" &
					to_hstring(res32) severity error;
				exit;
			end if;
		end loop;
		if p7_ok then
			p := p + 1;
			report "PASS P7 divena_held_high: no restart, outputs stable for 20 cycles"
				severity note;
		end if;
		ena32 <= '0';
		wait until rising_edge(clk);

		p32 <= p; f32 <= f; ops32 <= ops;
		nz_quo <= nzq; nz_res <= nzr;
		done32 <= TRUE;
		wait;
	end process stim32;

	--=======================================================================
	-- N = 8: every dividend against every divisor. 65536 operations.
	--=======================================================================
	stim8 : process
		variable p, f	: NATURAL := 0;
		variable nrep	: NATURAL := 0;
		variable nzq	: NATURAL := 0;
		variable nzr	: NATURAL := 0;
		variable ops	: NATURAL := 0;
	begin
		rst8 <= '1';
		ena8 <= '0';
		wait for 4*CLK_PERIOD;
		if busy8 = '0' and quo8 = Z8 and res8 = Z8 then
			p := p + 1;
			report "PASS P0 reset_holds_outputs_low (N=8)" severity note;
		else
			f := f + 1;
			report "FAIL P0 reset_holds_outputs_low (N=8)" severity error;
		end if;
		p8 <= p; f8 <= f;
		wait until falling_edge(clk);
		rst8 <= '0';

		if EXHAUSTIVE /= 0 then
			for a in 0 to 255 loop
				for b in 0 to 255 loop
					do_div(clk, ena8, dvd8, dvs8, busy8, quo8, res8,
						   STD_LOGIC_VECTOR(to_unsigned(a, N8)),
						   STD_LOGIC_VECTOR(to_unsigned(b, N8)),
						   N8, "N8 " & integer'image(a) & "/" & integer'image(b),
						   p, f, nrep, nzq, nzr);
					ops := ops + 1;
				end loop;
				p8 <= p; f8 <= f; ops8 <= ops;
				-- One line every 16 dividends, so a long run visibly progresses
				-- instead of looking hung.
				if (a mod 16) = 15 then
					report "  N=8 sweep: dividends 0.." & integer'image(a) &
						" done (" & integer'image(ops) & " operations, " &
						integer'image(f) & " failure(s))" severity note;
				end if;
			end loop;
		else
			report "  N=8 exhaustive sweep SKIPPED (EXHAUSTIVE = 0). This run does " &
				"NOT verify the divider." severity warning;
		end if;

		p8 <= p; f8 <= f; ops8 <= ops;
		done8 <= TRUE;
		wait;
	end process stim8;

	--=======================================================================
	-- Verdict, including P8.
	--=======================================================================
	verdict : process
		variable extra_fail	: NATURAL := 0;
		variable want8		: NATURAL;
		variable want32		: NATURAL;
	begin
		wait until done32 and done8;
		wait for CLK_PERIOD;

		if EXHAUSTIVE /= 0 then want8 := 65536; else want8 := 0; end if;
		-- directed + random + the one divide issued after the P5 abort
		want32 := DVD_LIST'length + RANDOM_OPS + 1;

		-- ---- P8 -------------------------------------------------------------
		if ops8 /= want8 then
			extra_fail := extra_fail + 1;
			report "FAIL P8 anti_vacuity: the N=8 sweep ran " & integer'image(ops8) &
				" operations, expected " & integer'image(want8) severity error;
		end if;
		if ops32 /= want32 then
			extra_fail := extra_fail + 1;
			report "FAIL P8 anti_vacuity: the N=32 list ran " & integer'image(ops32) &
				" operations, expected " & integer'image(want32) severity error;
		end if;
		if nz_quo = 0 or nz_res = 0 then
			extra_fail := extra_fail + 1;
			report "FAIL P8 anti_vacuity: no operation produced a non-zero quotient " &
				"or no operation produced a non-zero residue, so an engine stuck at " &
				"zero would have passed" severity error;
		end if;

		report "" severity note;
		report "========= DIV_ACCEL (Figure 9) SUMMARY =========" severity note;
		report "  N=32 directed+random : " & integer'image(ops32) &
			" operations, passed " & integer'image(p32) &
			", failed " & integer'image(f32) severity note;
		if EXHAUSTIVE /= 0 then
			report "  N=8  EXHAUSTIVE      : " & integer'image(ops8) &
				" operations (all 256x256 pairs), passed " & integer'image(p8) &
				", failed " & integer'image(f8) severity note;
		else
			report "  N=8  EXHAUSTIVE      : SKIPPED - this run does not verify " &
				"the divider" severity warning;
		end if;
		report "  non-zero quotients " & integer'image(nz_quo) &
			", non-zero residues " & integer'image(nz_res) &
			" (P8 anti-vacuity)" severity note;

		if (f32 + f8 + extra_fail) = 0 and EXHAUSTIVE /= 0 then
			report "  VERDICT: PASS - the accelerator divides correctly and DIVBUSY " &
				"is high for exactly N DIVCLK cycles, as page 9 states." severity note;
		elsif (f32 + f8 + extra_fail) = 0 then
			report "  VERDICT: INCOMPLETE - nothing failed, but the exhaustive sweep " &
				"was skipped. Re-run without -gEXHAUSTIVE=0 before believing it."
				severity warning;
		else
			report "  VERDICT: FAIL - " & integer'image(f32 + f8 + extra_fail) &
				" failure(s). Read the FAIL lines above; only the first " &
				integer'image(MAX_REPORTS) & " per stimulus are printed."
				severity error;
		end if;
		report "================================================" severity note;

		running <= FALSE;
		wait for CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
