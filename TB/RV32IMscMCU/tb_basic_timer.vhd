--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- self-checking testbench for BASIC_TIMER.vhd
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_timer.do        (zero setup -- a leaf test)
--
-- THE PROPERTIES, each with the exact number it must produce:
--   P0  RESET SEMANTICS ARE F16'S, BOTH HALVES. The five interface registers
--       clear -- and BTCNT does NOT. The second half is the sharp one: the
--       counter is run to a known value, reset is pulsed, and the counter
--       must come out NON-ZERO. A timer whose counter obeys rst_i passes
--       every other test here and fails this one.
--   P1  THE PRESCALER IS EXACT. With BTCL0 = 9 the EQU0 events arrive exactly
--       (9+1)*divider SMCLK cycles apart: 10 / 20 / 40 / 80 for BTSSEL
--       00 / 01 / 10 / 11. Measured between consecutive events.
--   P2  F17: BTCNT NEVER EXCEEDS BTCL0 -- a live monitor, armed whenever the
--       compare is configured, not a spot check.
--   P3  PWM DUTY, BOTH MODES, PHASE-INDEPENDENT. BTCL0=9, BTCL1=3: over any
--       20 consecutive cycles (two full periods) Mode0 is high for exactly
--       6 and Mode1 for exactly 14. Counting whole periods makes the check
--       immune to where the window starts, and the 3-in-10 duty is Lab 4
--       pwm.vhd's own update ordering -- so this doubles as proof the
--       adaptation preserved pwm.vhd's semantics.
--   P4  BTOUTEN=0 FREEZES PWMout -- page 8's "hold the PWMout signal value",
--       i.e. pwm.vhd's ena. Checked on every cycle across 25 cycles.
--   P5  BTHOLD FREEZES BTCNT; BTCLR ZEROES IT. Exact value compares.
--   P6  CAPTURE, five sub-cases, all with the counter HELD so BTCAPR must
--       equal the frozen BTCNT exactly -- no tolerance window:
--         a. test4's actual configuration, 0x07 (rising, source=GND): NO
--            capture -- the benchmark bug DOC/03 Q3 documents, reproduced;
--         b. 0x07 -> 0x06 (source to VCC): the edge test4 MEANT to make --
--            exactly ONE capture, BTCAPR = BTCNT exactly;
--         c. falling edge via VCC -> GND with CAPMD=10: one capture;
--         d. CAPMD=00: the source flips and NOTHING fires;
--         e. a real pin: CAPISEL=00, capin1_i driven 0->1: one capture.
--   P7  BTIFG SOURCE SELECT, per the benchmark-pinned codes: BTINT=11 (the
--       reserved code) produces ZERO pulses across eight wraps, then
--       BTINT=00 produces exactly 5 pulses in 25 cycles at period 5.
--   P8  THE FREQ_5K SCENARIO WITH THE REAL CONSTANT: BTCMPR0 = 500 (io_map.s
--       FREQ_5K), BTSSEL=3. F17-literal hardware gives (500+1)*8 = 4008
--       SMCLK cycles -- NOT the 4000 exact 5 kHz needs. The bench asserts
--       4008 and PRINTS the discrepancy: the hardware follows Hanan's F17,
--       the finding belongs to the benchmark constant (same class as B2).
--   P9  ANTI-VACUITY: events were really counted.
--
-- SAMPLING CONVENTION: value captures and comparisons happen after a FALLING
-- edge, mid-cycle, where every registered and combinational signal has
-- settled -- the same convention tb_isa_directed established and the reason
-- it cites. Pulse counting rides rising edges, where a one-cycle pulse is
-- seen exactly once.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_basic_timer IS
END tb_basic_timer;


ARCHITECTURE test OF tb_basic_timer IS

	constant CLK_PERIOD	: time := 10 ns;
	constant MAX_REPORTS: natural := 15;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL ctl_cs, cmpr0_cs, cmpr1_cs	: STD_LOGIC := '0';
	SIGNAL wr							: STD_LOGIC := '0';
	SIGNAL lane0, lane1					: STD_LOGIC := '0';
	SIGNAL wdata						: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL capin1, capin2				: STD_LOGIC := '0';

	SIGNAL pwm		: STD_LOGIC;
	SIGNAL ifg_set	: STD_LOGIC;
	SIGNAL btctl1_r	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL btctl2_r	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL cmpr0_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL cmpr1_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL capr_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL cnt_r	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- one driver each (the tb_sync rule)
	SIGNAL p_cnt, f_cnt		: NATURAL := 0;
	SIGNAL ifg_total		: NATURAL := 0;		-- cumulative BTIFG pulses
	SIGNAL wrap_guard_en	: BOOLEAN := FALSE;	-- arms the P2 monitor
	SIGNAL wrap_limit		: NATURAL := 0;
	SIGNAL mon_fail			: NATURAL := 0;

	constant Z32 : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

BEGIN
	--=======================================================================
	DUT : basic_timer
	generic map(DATA_WIDTH => 32)
	PORT MAP(clk_i => clk, rst_i => rst,
			 ctl_cs_i => ctl_cs, cmpr0_cs_i => cmpr0_cs, cmpr1_cs_i => cmpr1_cs,
			 MemWrite_i => wr, lane0_i => lane0, lane1_i => lane1, data_i => wdata,
			 capin1_i => capin1, capin2_i => capin2,
			 pwm_o => pwm, btifg_set_o => ifg_set,
			 btctl1_o => btctl1_r, btctl2_o => btctl2_r,
			 btcmpr0_o => cmpr0_r, btcmpr1_o => cmpr1_r,
			 btcapr_o => capr_r, btcnt_o => cnt_r);

	clk_gen : process
	begin
		while running loop
			clk <= '0'; wait for CLK_PERIOD/2;
			clk <= '1'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	--=======================================================================
	-- BTIFG pulse counter -- cumulative; the stimulus reads deltas mid-cycle.
	-- ifg_set is combinational off registered state, one tick wide, so each
	-- pulse is seen at exactly one rising edge.
	--=======================================================================
	ifg_count : process(clk)
		variable n : NATURAL := 0;
	begin
		if rising_edge(clk) then
			if ifg_set = '1' then
				n := n + 1;
				ifg_total <= n;
			end if;
		end if;
	end process ifg_count;

	--=======================================================================
	-- P2 monitor -- F17: while armed, BTCNT must never exceed the limit.
	--=======================================================================
	wrap_guard : process(clk)
		variable f : NATURAL := 0;
	begin
		if rising_edge(clk) then
			if wrap_guard_en and unsigned(cnt_r) > to_unsigned(wrap_limit, 32) then
				f := f + 1;
				mon_fail <= f;
				if f <= 3 then
					report "FAIL P2 wrap: BTCNT = " &
						integer'image(to_integer(unsigned(cnt_r))) &
						" exceeded BTCL0 = " & integer'image(wrap_limit) &
						". F17: the count restarts after reaching BTCL0."
						severity error;
				end if;
			end if;
		end if;
	end process wrap_guard;

	--=======================================================================
	stimulus : process
		variable p, f		: NATURAL := 0;
		variable nrep		: NATURAL := 0;
		variable t0			: NATURAL;
		variable base		: NATURAL;
		variable v_before	: NATURAL;
		variable hi			: NATURAL;
		variable mism		: NATURAL;
		variable frozen		: STD_LOGIC;

		procedure chk(constant ok : BOOLEAN; constant msg : STRING) is
		begin
			if ok then
				p := p + 1;
			else
				f := f + 1;
				if nrep < MAX_REPORTS then
					nrep := nrep + 1;
					report "FAIL " & msg severity error;
				end if;
			end if;
		end procedure chk;

		-- one bus write, exactly one rising edge wide, falling-edge aligned
		procedure bus_write(constant which : IN STRING;
							constant ln    : IN NATURAL;
							constant val   : IN STD_LOGIC_VECTOR(31 DOWNTO 0)) is
		begin
			wait until falling_edge(clk);
			if    which = "ctl"   then ctl_cs   <= '1';
			elsif which = "cmpr0" then cmpr0_cs <= '1';
			else                       cmpr1_cs <= '1';
			end if;
			if ln = 0 then lane0 <= '1'; else lane1 <= '1'; end if;
			wdata <= val;
			wr    <= '1';
			wait until falling_edge(clk);		-- one rising edge passed in between
			ctl_cs <= '0'; cmpr0_cs <= '0'; cmpr1_cs <= '0';
			lane0  <= '0'; lane1 <= '0'; wr <= '0';
		end procedure bus_write;

		procedure wr_ctl1(constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin
			bus_write("ctl", 0, x"000000" & v);
		end procedure wr_ctl1;

		procedure wr_ctl2(constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0)) is
		begin
			bus_write("ctl", 1, x"000000" & v);
		end procedure wr_ctl2;

		-- clock cycles between two consecutive BTIFG pulses
		procedure measure_period(variable cycles : OUT NATURAL) is
			variable n : NATURAL := 0;
		begin
			wait until rising_edge(clk) and ifg_set = '1';
			loop
				wait until rising_edge(clk);
				n := n + 1;
				exit when ifg_set = '1';
			end loop;
			cycles := n;
		end procedure measure_period;

	begin
		-- ================= P0a: reset clears the interface registers ========
		rst <= '1';
		wait for 5*CLK_PERIOD;
		wait until falling_edge(clk);
		rst <= '0';
		wait until falling_edge(clk);
		chk(btctl1_r = x"00" and btctl2_r = x"00" and cmpr0_r = Z32 and
			cmpr1_r = Z32 and capr_r = Z32,
			"P0a reset: an interface register did not clear (F16 first half)");

		-- ================= P1: prescaler exactness ==========================
		bus_write("cmpr0", 0, STD_LOGIC_VECTOR(to_unsigned(9, 32)));	-- BTCL0 = 9
		wrap_limit    <= 9;
		wrap_guard_en <= TRUE;											-- P2 armed
		wr_ctl1(x"00");			-- run: HOLD=0 CLR=0 SSEL=00 INT=00 (EQU0 -> IFG)

		measure_period(t0);
		chk(t0 = 10, "P1 BTSSEL=00: period " & integer'image(t0) & ", expected 10");
		wr_ctl1(x"08");			-- SSEL=01
		measure_period(t0); measure_period(t0);		-- the first spans the switch
		chk(t0 = 20, "P1 BTSSEL=01: period " & integer'image(t0) & ", expected 20");
		wr_ctl1(x"10");			-- SSEL=10
		measure_period(t0); measure_period(t0);
		chk(t0 = 40, "P1 BTSSEL=10: period " & integer'image(t0) & ", expected 40");
		wr_ctl1(x"18");			-- SSEL=11 -- the benchmarks' BTSSEL3
		measure_period(t0); measure_period(t0);
		chk(t0 = 80, "P1 BTSSEL=11: period " & integer'image(t0) & ", expected 80");

		-- ================= P3: PWM duty over whole periods ==================
		wr_ctl1(x"24");								-- HOLD=1 + CLR=1: park at zero
		bus_write("cmpr1", 0, STD_LOGIC_VECTOR(to_unsigned(3, 32)));	-- BTCL1 = 3
		wr_ctl1(x"40");								-- run, SSEL=00, OUTEN=1, MODE0
		wait until rising_edge(clk) and ifg_set = '1';	-- sync to a wrap tick
		hi := 0;
		for i in 1 to 20 loop						-- exactly two periods
			wait until rising_edge(clk);
			if pwm = '1' then hi := hi + 1; end if;
		end loop;
		chk(hi = 6, "P3 Mode0: high " & integer'image(hi) &
			" of 20 cycles, expected 6 (duty = BTCL1/(BTCL0+1) = 3/10)");

		wr_ctl1(x"C0");								-- MODE1, OUTEN=1, run
		-- TWO wrap waits, not one. The mode switch lands mid-period, and until
		-- a set-at-BTCL1 event has happened UNDER MODE1 the output still holds
		-- Mode0's leftover value -- so the first period after the switch is not
		-- steady state. One full period between the first and second wrap is.
		wait until rising_edge(clk) and ifg_set = '1';
		wait until rising_edge(clk) and ifg_set = '1';
		hi := 0;
		for i in 1 to 20 loop
			wait until rising_edge(clk);
			if pwm = '1' then hi := hi + 1; end if;
		end loop;
		chk(hi = 14, "P3 Mode1: high " & integer'image(hi) &
			" of 20 cycles, expected 14 (the Mode0 complement)");

		-- ================= P4: BTOUTEN=0 freezes PWMout =====================
		wr_ctl1(x"80");								-- MODE1 kept, OUTEN=0, still running
		wait until falling_edge(clk);
		frozen := pwm;
		mism := 0;
		for i in 1 to 25 loop						-- across 2.5 periods
			wait until falling_edge(clk);
			if pwm /= frozen then mism := mism + 1; end if;
		end loop;
		chk(mism = 0, "P4 BTOUTEN=0: PWMout moved " & integer'image(mism) &
			" time(s) while disabled; page 8 says it holds its value");

		-- ================= P5: BTHOLD freezes, BTCLR zeroes =================
		wr_ctl1(x"20");								-- BTHOLD=1
		wait until falling_edge(clk);
		v_before := to_integer(unsigned(cnt_r));
		for i in 1 to 20 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(to_integer(unsigned(cnt_r)) = v_before,
			"P5 BTHOLD: BTCNT moved from " & integer'image(v_before) &
			" to " & integer'image(to_integer(unsigned(cnt_r))));
		wr_ctl1(x"24");								-- BTHOLD=1 + BTCLR=1
		wait until falling_edge(clk);
		chk(cnt_r = Z32, "P5 BTCLR: BTCNT is not zero");

		-- ================= P0b: F16's second half -- BTCNT survives reset ===
		wrap_guard_en <= FALSE;						-- BTCL0 is about to reset to 0
		-- Give the counter a ceiling it cannot reach before the reset, so no
		-- wrap can land it back on zero at exactly the wrong moment -- a wrap
		-- coinciding with BTCL0 resetting to 0 would pin the counter at zero
		-- (EQU0 permanently true) and fail this check spuriously.
		bus_write("cmpr0", 0, STD_LOGIC_VECTOR(to_unsigned(1000000, 32)));
		wr_ctl1(x"00");								-- run (counter counts 0,1,2,...)
		for i in 1 to 6 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		rst <= '1';
		wait for 3*CLK_PERIOD;
		wait until falling_edge(clk);
		rst <= '0';
		wait until falling_edge(clk);
		chk(btctl1_r = x"00" and cmpr0_r = Z32,
			"P0b reset: interface registers did not clear on the second reset");
		chk(cnt_r /= Z32,
			"P0b F16: BTCNT came out of reset at ZERO. Hanan's F16 says reset " &
			"clears only the interface registers; the counter must survive.");

		-- ================= P6: capture, counter frozen for exact compares ===
		-- BTCL0 = 0 right now (it was just reset), and a counter AT zero with
		-- BTCL0 = 0 sees EQU0 permanently and cannot move -- so the compare
		-- register must be given a ceiling BEFORE the park-at-nonzero run.
		-- (The first draft of this test missed exactly that and would have
		-- "parked" at zero.)
		bus_write("cmpr0", 0, STD_LOGIC_VECTOR(to_unsigned(1000, 32)));
		wr_ctl1(x"02");								-- run, BTINT=10 (capture -> IFG)
		for i in 1 to 5 loop wait until rising_edge(clk); end loop;
		wr_ctl1(x"22");								-- BTHOLD=1, BTINT=10: freeze
		wait until falling_edge(clk);
		v_before := to_integer(unsigned(cnt_r));
		chk(v_before /= 0, "P6 setup: the counter failed to park at a non-zero value");

		-- a. test4's own value: CAPMD=01 (rising), CAPISEL=11 (GND) -- 0x07
		base := ifg_total;
		wr_ctl2(x"07");
		for i in 1 to 30 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(ifg_total = base and capr_r = Z32,
			"P6a: a capture fired with the source parked on GND. This is " &
			"test4's actual 0x07 configuration; it must produce NOTHING " &
			"(the benchmark bug DOC/03 Q3 documents).");

		-- b. the edge test4 meant: source to VCC -- one rising edge
		wr_ctl2(x"06");								-- CAPMD=01, CAPISEL=10 (VCC)
		for i in 1 to 10 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(ifg_total = base + 1,
			"P6b: expected exactly ONE capture on GND->VCC, saw " &
			integer'image(ifg_total - base));
		chk(to_integer(unsigned(capr_r)) = v_before,
			"P6b: BTCAPR = " & integer'image(to_integer(unsigned(capr_r))) &
			", expected the frozen BTCNT = " & integer'image(v_before));

		-- c. falling edge: CAPMD=10, source back to GND -- 0x0B
		base := ifg_total;
		wr_ctl2(x"0B");
		for i in 1 to 10 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(ifg_total = base + 1,
			"P6c: expected exactly ONE capture on the falling edge, saw " &
			integer'image(ifg_total - base));

		-- d. CAPMD=00: the source flips GND->VCC and nothing may fire
		base := ifg_total;
		wr_ctl2(x"02");								-- CAPMD=00, CAPISEL=10
		for i in 1 to 10 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(ifg_total = base,
			"P6d: CAPMD=00 must disable capture; " &
			integer'image(ifg_total - base) & " event(s) fired");

		-- e. a real pin: CAPISEL=00 selects capin1_i
		wr_ctl2(x"04");								-- CAPMD=01, CAPISEL=00
		for i in 1 to 5 loop wait until rising_edge(clk); end loop;	-- source settles low
		base := ifg_total;
		wait until falling_edge(clk);
		capin1 <= '1';
		for i in 1 to 10 loop wait until rising_edge(clk); end loop;
		wait until falling_edge(clk);
		chk(ifg_total = base + 1,
			"P6e: expected exactly ONE capture from the CAPIN1 pin, saw " &
			integer'image(ifg_total - base));

		-- ================= P7: the reserved BTINT code ======================
		wr_ctl1(x"24");								-- hold + clear
		bus_write("cmpr0", 0, STD_LOGIC_VECTOR(to_unsigned(4, 32)));	-- period 5
		wrap_limit <= 4; wrap_guard_en <= TRUE;
		base := ifg_total;
		wr_ctl1(x"03");								-- run, BTINT=11 (reserved)
		for i in 1 to 40 loop wait until rising_edge(clk); end loop;	-- ~8 wraps
		wait until falling_edge(clk);
		chk(ifg_total = base,
			"P7 BTINT=11: the reserved code produced " &
			integer'image(ifg_total - base) & " pulse(s); it must produce none");
		wr_ctl1(x"00");								-- BTINT=00 again
		wait until falling_edge(clk);
		base := ifg_total;
		for i in 1 to 25 loop wait until rising_edge(clk); end loop;	-- 5 whole periods
		wait until falling_edge(clk);
		chk(ifg_total = base + 5,
			"P7 BTINT=00: expected exactly 5 EQU0 pulses in 25 cycles at " &
			"period 5, saw " & integer'image(ifg_total - base));

		-- ================= P8: FREQ_5K with the real constant ===============
		wr_ctl1(x"24");								-- hold + clear
		bus_write("cmpr0", 0, STD_LOGIC_VECTOR(to_unsigned(500, 32)));	-- FREQ_5K
		wrap_limit <= 500;
		wr_ctl1(x"18");								-- run, BTSSEL=11, BTINT=00
		measure_period(t0); measure_period(t0);
		chk(t0 = 4008,
			"P8 FREQ_5K: interval " & integer'image(t0) & " cycles, expected 4008");
		report "P8 NOTE (a finding, not a failure): io_map.s comments FREQ_5K=500 " &
			"as 5 kHz at SMCLK=20MHz, but F17-literal hardware gives a period of " &
			"(500+1)*8 = 4008 SMCLK cycles = 4990 Hz. Exactly 5 kHz needs " &
			"BTCMPR0 = 499. Same class as B2's SEC_PERIOD factor-8 discrepancy."
			severity note;

		-- ================= P9 + verdict =====================================
		wrap_guard_en <= FALSE;
		chk(ifg_total > 10, "P9 anti-vacuity: almost no BTIFG events were counted");
		p_cnt <= p; f_cnt <= f;
		wait until rising_edge(clk);

		report "" severity note;
		report "========= BASIC_TIMER (Figure 7) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p_cnt) &
			", failed " & integer'image(f_cnt + mon_fail) &
			"  (BTIFG events counted: " & integer'image(ifg_total) & ")" severity note;
		if (f_cnt + mon_fail) = 0 then
			report "  VERDICT: PASS - prescaler exact, F16/F17 as Hanan stated, " &
				"Lab 4 PWM semantics preserved, capture edge-exact, and test4's " &
				"0x07 bug reproduced (no capture from a GND-parked source)."
				severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f_cnt + mon_fail) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "==================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stimulus;

END test;
