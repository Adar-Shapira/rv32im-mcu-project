--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- self-checking testbench for DIV_UNIT.vhd
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_divunit.do
--============================================================================
-- WHAT THIS TEST IS FOR, AND WHY IT IS NOT tb_div_accel AGAIN
--
--   tb_div_accel verified the ENGINE, in one clock domain, unsigned. This
--   verifies the things that only exist once the engine is wrapped:
--     - the four clock-domain crossings, with two genuinely different clocks;
--     - the MCLK-side handshake, which is where a divider usually goes wrong;
--     - the signed div/rem wrapper, including the two cases RISC-V calls out.
--
--   THE CLOCK RATIO IS DELIBERATELY COPRIME. The design will run at 20 MHz MCLK
--   against 50 MHz DIVCLK -- a 5:2 ratio, which holds the two clock edges in a
--   FIXED relationship. A crossing bug can hide behind a fixed relationship
--   indefinitely and then appear on a board when a PLL comes up at a different
--   phase. So this testbench uses 50 ns against 21 ns: coprime, so across a run
--   the DIVCLK edge lands at every phase of the MCLK period, including
--   arbitrarily close to it. Correctness must not depend on the ratio, and this
--   is what makes that claim testable rather than hoped for. Same argument as
--   tb_sync.vhd's 70/30 and CLOCK_TREE's simulation periods.
--
--   What no RTL simulator can do is reproduce metastability itself. What this
--   proves is the STRUCTURE: that the handshake completes at every phase, that
--   no operand is sampled mid-flight, and that the result is stable when read.
--
-- THE PROPERTIES
--   P0  RESET holds busy, done and both results at zero.
--   P1  HANDSHAKE. done_o is LOW for the whole operation and HIGH at the end,
--       while start_i is still asserted. This is the property the core's stall
--       is built on: PCHold <= DIVstart AND NOT done_o. If done_o were ever high
--       early, the core would retire the div before the result existed.
--   P2  BUSY. busy_o is high while the operation runs and low once done.
--   P3  QUOTIENT and P4 REMAINDER against an independent reference, for signed
--       and unsigned, including -2^31 / -1 and every divide-by-zero.
--   P5  LATENCY IS BOUNDED. Every operation completes inside a generous window.
--       A hang here is the failure mode the header of DIV_UNIT.vhd warns about
--       (WAIT_RISE never seeing DIVBUSY), so it is checked rather than assumed.
--   P6  BACK TO BACK. Operations issued one after another are all correct -- a
--       stale latched operand or an un-cleared sign flag fails here.
--   P7  ANTI-VACUITY: the run really executed the operations it claims, and
--       really produced non-zero quotients and non-zero remainders.
--   P8  ADJACENT DIVIDES, start_i NEVER DROPPING. Every other property here
--       lowers start between operations; the CORE does not, because two adjacent
--       div instructions keep DIVstart asserted continuously. This property was
--       added after exactly that case was found broken: a DONE state that waits
--       for start_i to fall leaves done_o high, and the second div retires
--       immediately carrying the FIRST one's result -- a silent wrong answer.
--
-- THE REFERENCE
--   IEEE.NUMERIC_STD's own "/" and "rem" on SIGNED and UNSIGNED, which share no
--   code with the restoring engine or with the wrapper. VHDL's "/" truncates
--   toward zero and "rem" takes the sign of the left operand -- exactly the
--   RV32IM definition -- so no adjustment is needed except for the two cases
--   where the ISA overrides ordinary arithmetic, which are written out below.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_div_unit IS
	generic(
		RANDOM_OPS	: integer := 40
	);
END tb_div_unit;


ARCHITECTURE test OF tb_div_unit IS

	constant N			: integer := 32;
	-- Coprime on purpose -- see the header.
	constant MCLK_HALF	: time := 25 ns;	-- 50 ns period
	constant DCLK_HALF	: time := 10500 ps;	-- 21 ns period
	constant MAX_REPORTS: natural := 15;
	-- 32 DIVCLK iterations plus four crossings, in MCLK cycles, with margin.
	constant MAX_WAIT	: natural := 120;

	SIGNAL mclk		: STD_LOGIC := '0';
	SIGNAL dclk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL start	: STD_LOGIC := '0';
	SIGNAL is_sgn	: STD_LOGIC := '1';
	SIGNAL dvd		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL dvs		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL busy		: STD_LOGIC;
	SIGNAL done		: STD_LOGIC;
	SIGNAL quot		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL remd		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	SIGNAL p_cnt, f_cnt	: NATURAL := 0;
	SIGNAL ops_cnt		: NATURAL := 0;
	SIGNAL nzq_cnt		: NATURAL := 0;
	SIGNAL nzr_cnt		: NATURAL := 0;

	constant ZV			: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
	constant ONES		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '1');
	-- The most negative value: '1' followed by zeros.
	constant MINNEG		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := '1' & ZV(N-2 DOWNTO 0);

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

	--=======================================================================
	-- The reference. Two ISA overrides are written out rather than left to the
	-- arithmetic, because in both cases ordinary arithmetic gives a different
	-- answer (or none at all):
	--
	--   DIVIDE BY ZERO. NUMERIC_STD's "/" is undefined for a zero divisor and
	--   simulators flag it. RISC-V instead defines the answer: quotient all
	--   ones, remainder the dividend -- for div, divu, rem and remu alike.
	--
	--   -2^31 / -1. The true quotient is +2^31, which is not representable in
	--   32-bit signed. RISC-V defines the result as -2^31 with remainder 0.
	--   NUMERIC_STD would have to wrap to produce that, and relying on a wrap is
	--   relying on undefined behaviour to be convenient.
	--=======================================================================
	function ref_quot(a, b : STD_LOGIC_VECTOR; sg : STD_LOGIC)
		return STD_LOGIC_VECTOR is
	begin
		if unsigned(b) = 0 then
			return ONES;
		end if;
		if sg = '1' then
			if a = MINNEG and b = ONES then		-- -2^31 / -1
				return MINNEG;
			end if;
			return STD_LOGIC_VECTOR(signed(a) / signed(b));
		else
			return STD_LOGIC_VECTOR(unsigned(a) / unsigned(b));
		end if;
	end function ref_quot;

	function ref_rem(a, b : STD_LOGIC_VECTOR; sg : STD_LOGIC)
		return STD_LOGIC_VECTOR is
	begin
		if unsigned(b) = 0 then
			return a;
		end if;
		if sg = '1' then
			if a = MINNEG and b = ONES then		-- -2^31 / -1
				return ZV;
			end if;
			return STD_LOGIC_VECTOR(signed(a) rem signed(b));
		else
			return STD_LOGIC_VECTOR(unsigned(a) rem unsigned(b));
		end if;
	end function ref_rem;

BEGIN
	--=======================================================================
	DUT : div_unit
	generic map(N => N)
	PORT MAP(mclk_i => mclk, divclk_i => dclk, rst_i => rst,
			 start_i => start, signed_i => is_sgn,
			 dividend_i => dvd, divisor_i => dvs,
			 busy_o => busy, done_o => done,
			 quotient_o => quot, remainder_o => remd);

	--=======================================================================
	mclk_gen : process
	begin
		while running loop
			mclk <= '0'; wait for MCLK_HALF;
			mclk <= '1'; wait for MCLK_HALF;
		end loop;
		wait;
	end process mclk_gen;

	dclk_gen : process
	begin
		while running loop
			dclk <= '0'; wait for DCLK_HALF;
			dclk <= '1'; wait for DCLK_HALF;
		end loop;
		wait;
	end process dclk_gen;

	--=======================================================================
	stimulus : process
		variable p, f	: NATURAL := 0;
		variable nrep	: NATURAL := 0;
		variable ops	: NATURAL := 0;
		variable nzq	: NATURAL := 0;
		variable nzr	: NATURAL := 0;
		variable waited	: NATURAL := 0;			-- P8
		variable lf		: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"2468ACE1";
		variable a, b	: STD_LOGIC_VECTOR(31 DOWNTO 0);

		procedure lfsr_step(variable s : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0)) is
			variable fb : STD_LOGIC;
		begin
			fb := s(31) XOR s(21) XOR s(1) XOR s(0);
			s  := s(30 DOWNTO 0) & fb;
		end procedure lfsr_step;

		-- One operation, with P1..P6 checked on it.
		procedure do_op(constant va, vb : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
						constant vs     : IN STD_LOGIC;
						constant tag    : IN STRING) is
			variable eq, er	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			variable waited	: NATURAL := 0;
		begin
			eq := ref_quot(va, vb, vs);
			er := ref_rem (va, vb, vs);

			-- P2: idle before we start
			if busy /= '0' or done /= '0' then
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL not_idle_before_start [" & tag & "]: busy=" &
						bit_img(busy) & " done=" & bit_img(done) severity error;
				end if;
			end if;

			dvd    <= va;
			dvs    <= vb;
			is_sgn <= vs;
			start  <= '1';

			-- P1: done must stay LOW until the result really exists. This is the
			-- property the core's stall rests on -- PCHold <= DIVstart AND NOT
			-- done_o -- so an early done_o retires the div before the divider has
			-- produced anything.
			waited := 0;
			loop
				wait until rising_edge(mclk);
				waited := waited + 1;
				exit when done = '1';
				if waited > MAX_WAIT then
					exit;
				end if;
			end loop;

			-- P5: bounded latency. A hang here is the WAIT_RISE failure mode
			-- DIV_UNIT.vhd's header warns about, so it is a checked property.
			if waited > MAX_WAIT then
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL latency_bound [" & tag & "]: done_o never rose " &
						"within " & integer'image(MAX_WAIT) & " MCLK cycles. The " &
						"handshake is stuck: most likely WAIT_RISE never saw " &
						"DIVBUSY, which is the clock-ratio constraint in " &
						"DIV_UNIT.vhd's header." severity error;
				end if;
			else
				p := p + 1;
			end if;

			-- P3 / P4: the numbers, sampled while done is high
			if quot = eq then
				p := p + 1;
			else
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL quotient [" & tag & "]: 0x" & to_hstring(va) &
						" / 0x" & to_hstring(vb) & " signed=" & bit_img(vs) &
						" gave 0x" & to_hstring(quot) & ", expected 0x" &
						to_hstring(eq) severity error;
				end if;
			end if;

			if remd = er then
				p := p + 1;
			else
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL remainder [" & tag & "]: 0x" & to_hstring(va) &
						" rem 0x" & to_hstring(vb) & " signed=" & bit_img(vs) &
						" gave 0x" & to_hstring(remd) & ", expected 0x" &
						to_hstring(er) severity error;
				end if;
			end if;

			-- P2: busy must be down once done is up
			if busy = '0' then
				p := p + 1;
			else
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL busy_still_high [" & tag & "]: done_o is high but " &
						"busy_o is too" severity error;
				end if;
			end if;

			if eq /= ZV then nzq := nzq + 1; end if;
			if er /= ZV then nzr := nzr + 1; end if;
			ops := ops + 1;

			-- Retire the instruction, exactly as the core would.
			start <= '0';
			wait until rising_edge(mclk);
			wait until rising_edge(mclk);
			p_cnt <= p; f_cnt <= f; ops_cnt <= ops; nzq_cnt <= nzq; nzr_cnt <= nzr;
		end procedure do_op;

	begin
		-- ---- P0 -------------------------------------------------------------
		rst <= '1';
		wait for 6 * MCLK_HALF;
		if busy = '0' and done = '0' and quot = ZV and remd = ZV then
			p := p + 1;
			report "PASS P0 reset holds outputs low" severity note;
		else
			f := f + 1;
			report "FAIL P0 reset: busy=" & bit_img(busy) & " done=" &
				bit_img(done) & " quot=0x" & to_hstring(quot) & " rem=0x" &
				to_hstring(remd) severity error;
		end if;
		p_cnt <= p; f_cnt <= f;
		wait until falling_edge(mclk);
		rst <= '0';
		wait until rising_edge(mclk);

		-- ---- directed corners, signed ---------------------------------------
		do_op(MINNEG,      ONES,        '1', "-2^31 / -1 overflow");
		do_op(MINNEG,      x"00000001", '1', "-2^31 / 1");
		do_op(x"FFFFFFFF", x"00000002", '1', "-1 / 2 truncation");
		do_op(x"00000007", x"FFFFFFFE", '1', "7 / -2 truncation");
		do_op(x"FFFFFFF9", x"00000002", '1', "-7 / 2 remainder sign");
		do_op(x"FFFFFFF9", x"FFFFFFFE", '1', "-7 / -2");
		do_op(x"00000064", x"00000007", '1', "100 / 7");
		-- the divide-by-zero column, including the case a naive wrapper fails
		do_op(x"00000000", x"00000000", '1', "0 / 0");
		do_op(x"00000001", x"00000000", '1', "1 / 0");
		do_op(x"FFFFFFFF", x"00000000", '1', "-1 / 0  <- naive wrapper gives +1");
		do_op(MINNEG,      x"00000000", '1', "-2^31 / 0");
		-- unsigned
		do_op(x"FFFFFFFF", x"FFFFFFFF", '0', "unsigned max / max");
		do_op(x"FFFFFFFF", x"80000000", '0', "unsigned divisor >= 2^31");
		do_op(x"FFFFFFFF", x"00000000", '0', "unsigned / 0");
		do_op(x"000003E8", x"00000007", '0', "unsigned 1000 / 7");
		report "directed corners done: " & integer'image(ops) & " operations, " &
			integer'image(f) & " failure(s) so far" severity note;

		-- ---- random, both signednesses --------------------------------------
		for i in 1 to RANDOM_OPS loop
			lfsr_step(lf); a := lf;
			lfsr_step(lf); b := lf;
			if (i mod 8) = 0 then
				b := b AND x"000000FF";
			elsif (i mod 16) = 3 then
				b := b OR x"80000000";
			end if;
			if (i mod 2) = 0 then
				do_op(a, b, '1', "random signed #" & integer'image(i));
			else
				do_op(a, b, '0', "random unsigned #" & integer'image(i));
			end if;
		end loop;

		-- ---- P8: ADJACENT DIVIDES, start_i NEVER DROPS ----------------------
		-- The property every other test in this file misses, because do_op always
		-- lowers start between operations. The CORE does not: two adjacent div
		-- instructions keep DIVstart asserted continuously, because the second one
		-- asserts it on the very cycle the first retires.
		--
		-- The bug this catches is silent, not loud: with a DONE state that waits
		-- for start_i to fall, the unit sits in DONE with done_o still high and the
		-- SECOND div retires immediately carrying the FIRST one's result.
		--
		-- 100/7 = 14 rem 2, then 1000/3 = 333 rem 1, with start held high across
		-- the change. If the second read gives 14, the bug is back.
		dvd    <= x"00000064";			-- 100
		dvs    <= x"00000007";			--   7
		is_sgn <= '1';
		start  <= '1';
		waited := 0;
		loop
			wait until rising_edge(mclk);
			waited := waited + 1;
			exit when done = '1' or waited > MAX_WAIT;
		end loop;
		if quot = x"0000000E" and remd = x"00000002" then
			p := p + 1;
		else
			f := f + 1;
			report "FAIL P8 setup: first of the adjacent pair gave 0x" &
				to_hstring(quot) & " rem 0x" & to_hstring(remd) &
				", expected 0x0000000E rem 0x00000002" severity error;
		end if;

		-- The second div arrives. Operands change; start_i does NOT fall.
		dvd <= x"000003E8";				-- 1000
		dvs <= x"00000003";				--    3
		waited := 0;
		loop							-- it must re-arm, i.e. drop done
			wait until rising_edge(mclk);
			waited := waited + 1;
			exit when done = '0' or waited > MAX_WAIT;
		end loop;
		if waited > MAX_WAIT then
			f := f + 1;
			report "FAIL P8 adjacent_divides: done_o never fell after the first " &
				"result, with start_i held high. The unit is stuck in DONE, so a " &
				"second back-to-back div would retire immediately carrying the " &
				"FIRST divide's result." severity error;
		end if;
		waited := 0;
		loop
			wait until rising_edge(mclk);
			waited := waited + 1;
			exit when done = '1' or waited > MAX_WAIT;
		end loop;
		if quot = x"0000014D" and remd = x"00000001" then
			p := p + 1;
			report "PASS P8 adjacent_divides: the second of a back-to-back pair " &
				"got its OWN result" severity note;
		else
			f := f + 1;
			report "FAIL P8 adjacent_divides: the second divide gave 0x" &
				to_hstring(quot) & " rem 0x" & to_hstring(remd) &
				", expected 0x0000014D rem 0x00000001. Getting 0x0000000E means " &
				"it retired with the FIRST divide's result." severity error;
		end if;
		start <= '0';
		wait until rising_edge(mclk);
		wait until rising_edge(mclk);
		ops := ops + 2;
		p_cnt <= p; f_cnt <= f; ops_cnt <= ops;

		-- ---- P7 --------------------------------------------------------------
		if ops = 17 + RANDOM_OPS then
			p := p + 1;
		else
			f := f + 1;
			report "FAIL P7 anti_vacuity: ran " & integer'image(ops) &
				" operations, expected " & integer'image(17 + RANDOM_OPS)
				severity error;
		end if;
		if nzq > 0 and nzr > 0 then
			p := p + 1;
		else
			f := f + 1;
			report "FAIL P7 anti_vacuity: no non-zero quotient or no non-zero " &
				"remainder was produced, so a unit stuck at zero would pass"
				severity error;
		end if;
		p_cnt <= p; f_cnt <= f; ops_cnt <= ops; nzq_cnt <= nzq; nzr_cnt <= nzr;
		wait until rising_edge(mclk);

		-- ---- verdict ---------------------------------------------------------
		report "" severity note;
		report "========= DIV_UNIT SUMMARY =========" severity note;
		report "  operations " & integer'image(ops_cnt) &
			", passed " & integer'image(p_cnt) &
			", failed " & integer'image(f_cnt) severity note;
		report "  non-zero quotients " & integer'image(nzq_cnt) &
			", non-zero remainders " & integer'image(nzr_cnt) severity note;
		if f_cnt = 0 then
			report "  VERDICT: PASS - signed and unsigned div/rem are correct " &
				"across a coprime clock crossing, and done_o never rose early."
				severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f_cnt) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "====================================" severity note;

		running <= FALSE;
		wait for 4 * MCLK_HALF;
		std.env.stop;
	end process stimulus;

END test;
