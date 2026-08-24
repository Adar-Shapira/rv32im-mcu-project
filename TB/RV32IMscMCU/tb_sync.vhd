--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for SYNC.vhd
--
-- Proves the four properties that make the synchronizer of Figures 10a/10b
-- correct. Self-checking: it prints a pass/fail tally and stops itself, so it
-- needs no waveform reading and no stop condition in the .do script.
--
--   1. LATENCY. Figure 10a shows Din -> Ds -> Dout: two destination edges from
--      the domain boundary to the stable output.
--   2. IT ARRIVES INTACT. Every driven value reaches q_o unchanged.
--   3. NO PHANTOM VALUE. q_o only ever holds a value that was really driven —
--      never a mixture of an old and a new one. This is the property that breaks
--      if a stage is shared or mis-clocked.
--   4. RESET. q_o is zero while rst_i is asserted.
--
-- TWO INSTANCES, ON PURPOSE
--   DUT_A has GEN_SRC_REG => TRUE: the complete Figure 10a path, launch register
--   included. It carries properties 2, 3 and 4.
--   DUT_B has GEN_SRC_REG => FALSE and is fed the same d, so for it the domain
--   boundary IS d. That makes the latency of the chain itself measurable without
--   reaching into the DUT's internals with an external name — and it exercises
--   the GEN_SRC_REG = FALSE branch, which would otherwise never be compiled.
--
-- WHY THE CLOCK RATIO IS DELIBERATELY NOT AN INTEGER
--   Source 70 ns, destination 30 ns. 7:3 is coprime, so across the run the source
--   edge lands at every phase relative to the destination edge, including
--   arbitrarily close to it. An integer ratio holds the two edges in a fixed
--   relationship and can pass while hiding a real crossing bug.
--
--   This is a functional simulation, so it cannot reproduce metastability — no
--   RTL simulator can. What it proves is the structure: that a settling stage
--   exists, that the latency is what the figure specifies, and that no value is
--   corrupted in transit. Metastability itself is a timing-analysis and
--   physical-design property, addressed in the SDC.
--
-- WHY EACH CHECKER OWNS ITS OWN COUNTERS
--   VHDL allows only one driver per signal of an unresolved type, and NATURAL is
--   unresolved. Three processes therefore cannot share one `fails` counter. Each
--   drives its own pair and the stimulus reads all of them for the verdict —
--   reading is unrestricted, only driving is not.
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_sync.do
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.aux_package.all;


ENTITY tb_sync IS
	generic(
		DATA_WIDTH	: integer := 8;		-- 8 keeps the phantom-value table at 256 entries
		STAGES		: integer := 2		-- Figure 10b draws two
	);
END tb_sync;


ARCHITECTURE test OF tb_sync IS

	constant SRC_PERIOD	: time := 70 ns;	-- domain A, slow
	constant DST_PERIOD	: time := 30 ns;	-- domain B, fast
	constant N_VALUES		: natural := 24;

	SIGNAL src_clk	: STD_LOGIC := '0';
	SIGNAL dst_clk	: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL d			: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL q_a		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);	-- with launch register
	SIGNAL q_b		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);	-- without

	SIGNAL running	: BOOLEAN := TRUE;

	-- one driver each, per the note above
	SIGNAL stim_pass, stim_fail	: NATURAL := 0;
	SIGNAL mon_pass,  mon_fail	: NATURAL := 0;
	SIGNAL lat_pass,  lat_fail	: NATURAL := 0;

	-- Every value the stimulus has driven, so the monitor can tell a legitimate
	-- value from a corrupted mixture of two.
	TYPE seen_array IS ARRAY (0 TO 255) OF BOOLEAN;
	SIGNAL was_driven	: seen_array := (others => FALSE);

	-- An explicit constant rather than comparing against an aggregate. An
	-- aggregate on the right of a relational operator relies on the context to
	-- supply the index constraint, which tools handle inconsistently.
	constant ZEROS	: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (others => '0');

BEGIN
	assert DATA_WIDTH = 8
		report "tb_sync: the phantom-value table is sized for DATA_WIDTH = 8"
		severity failure;

	--=======================================================================
	DUT_A : sync								-- the full Figure 10a path
	generic map(DATA_WIDTH => DATA_WIDTH, STAGES => STAGES, GEN_SRC_REG => TRUE)
	PORT MAP(src_clk_i => src_clk, dst_clk_i => dst_clk, rst_i => rst,
			 d_i => d, q_o => q_a);

	DUT_B : sync								-- chain only, boundary = d
	generic map(DATA_WIDTH => DATA_WIDTH, STAGES => STAGES, GEN_SRC_REG => FALSE)
	PORT MAP(src_clk_i => '0', dst_clk_i => dst_clk, rst_i => rst,
			 d_i => d, q_o => q_b);

	--=======================================================================
	src_gen : process
	begin
		while running loop
			src_clk <= '0'; wait for SRC_PERIOD/2;
			src_clk <= '1'; wait for SRC_PERIOD/2;
		end loop;
		wait;
	end process;

	dst_gen : process
	begin
		while running loop
			dst_clk <= '0'; wait for DST_PERIOD/2;
			dst_clk <= '1'; wait for DST_PERIOD/2;
		end loop;
		wait;
	end process;

	--=======================================================================
	-- Property 4, then the stimulus, then the verdict.
	--=======================================================================
	stimulus : process
		variable v	: NATURAL;
		variable p	: NATURAL := 0;
		variable f	: NATURAL := 0;
	begin
		-- ---- reset held -------------------------------------------------
		rst <= '1';
		d   <= (others => '0');
		wait for 4*SRC_PERIOD;
		if q_a = ZEROS and q_b = ZEROS then
			p := p + 1;
			report "PASS reset_holds_output_low" severity note;
		else
			f := f + 1;
			report "FAIL reset_holds_output_low: an output is not zero during reset"
				severity error;
		end if;
		stim_pass <= p; stim_fail <= f;
		wait until rising_edge(dst_clk);
		rst <= '0';

		-- ---- drive distinct values on the source clock ------------------
		for i in 1 to N_VALUES loop
			v := (i * 11) mod 256;				-- 11 coprime with 256: no repeats
			wait until rising_edge(src_clk);
			was_driven(v) <= TRUE;
			d <= std_logic_vector(to_unsigned(v, DATA_WIDTH));
			wait for 3*DST_PERIOD;				-- settle before the next change
		end loop;

		-- ---- property 2: the last value arrived intact through both -----
		wait for 4*SRC_PERIOD;
		if q_a = d and q_b = d then
			p := p + 1;
			report "PASS value_arrives_intact" severity note;
		else
			f := f + 1;
			report "FAIL value_arrives_intact: d = 0x" & to_hstring(d) &
				", q_a = 0x" & to_hstring(q_a) & ", q_b = 0x" & to_hstring(q_b)
				severity error;
		end if;
		stim_pass <= p; stim_fail <= f;
		wait for DST_PERIOD;

		-- ---- verdict ----------------------------------------------------
		report "" severity note;
		report "========= SYNC (Figures 10a/10b) SUMMARY =========" severity note;
		report "  stimulus  passed " & integer'image(stim_pass) &
			", failed " & integer'image(stim_fail) severity note;
		report "  monitor   passed " & integer'image(mon_pass) &
			", failed " & integer'image(mon_fail) severity note;
		report "  latency   passed " & integer'image(lat_pass) &
			", failed " & integer'image(lat_fail) severity note;
		if (stim_fail + mon_fail + lat_fail) = 0 then
			report "  VERDICT: PASS - the synchronizer behaves as Figures 10a/10b " &
				"specify." severity note;
		else
			report "  VERDICT: FAIL - " &
				integer'image(stim_fail + mon_fail + lat_fail) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "==================================================" severity note;
		running <= FALSE;
		wait for DST_PERIOD;
		std.env.stop;
	end process stimulus;

	--=======================================================================
	-- Property 3: no phantom value on either output.
	--=======================================================================
	monitor : process(dst_clk)
		variable f	: NATURAL := 0;
	begin
		if rising_edge(dst_clk) and rst = '0' then
			if q_a /= ZEROS
			   and not was_driven(to_integer(unsigned(q_a))) then
				report "FAIL no_phantom_value on q_a: 0x" & to_hstring(q_a) &
					" was never driven on d_i" severity error;
				f := f + 1;
			end if;
			if q_b /= ZEROS
			   and not was_driven(to_integer(unsigned(q_b))) then
				report "FAIL no_phantom_value on q_b: 0x" & to_hstring(q_b) &
					" was never driven on d_i" severity error;
				f := f + 1;
			end if;
			mon_fail <= f;
			if f = 0 then
				mon_pass <= 1;		-- one standing pass while nothing has gone wrong
			end if;
		end if;
	end process monitor;

	--=======================================================================
	-- Property 1: exactly STAGES destination edges from the boundary to q_o.
	-- Measured on DUT_B, whose boundary is d itself.
	--=======================================================================
	-- Both halves of the property are checked, because only the first one proves
	-- that two stages exist:
	--   TOO EARLY — with STAGES-1 edges elapsed the new value must NOT be out yet.
	--               A one-stage chain fails here, which is the whole point.
	--   ARRIVED   — with STAGES edges elapsed it must be out.
	-- Reading a signal at a clock edge yields its pre-edge value, so the counts
	-- below are edges-since-the-boundary-changed, inclusive of the detecting edge.
	latency : process(dst_clk)
		variable prev		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (others => '0');
		variable elapsed		: INTEGER := -1;
		variable want		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (others => '0');
		variable p, f		: NATURAL := 0;
	begin
		if rising_edge(dst_clk) and rst = '0' then
			if d /= prev then					-- a new value at the boundary
				prev    := d;
				want    := d;
				elapsed := 0;
			elsif elapsed >= 0 then
				elapsed := elapsed + 1;

				if elapsed = STAGES-1 then
					if q_b /= want then
						p := p + 1;			-- correctly not out yet
					else
						report "FAIL latency_too_early: q_b already reads 0x" &
							to_hstring(q_b) & " after only " &
							integer'image(STAGES-1) & " destination edge(s). " &
							"The chain is shorter than " & integer'image(STAGES) &
							" stages, so nothing is given time to settle."
							severity error;
						f := f + 1;
					end if;
				elsif elapsed = STAGES then
					if q_b = want then
						p := p + 1;
					else
						report "FAIL latency_not_arrived: " & integer'image(STAGES) &
							" destination edges after the boundary changed, q_b = 0x" &
							to_hstring(q_b) & ", expected 0x" & to_hstring(want)
							severity error;
						f := f + 1;
					end if;
					elapsed := -1;				-- done with this value
				end if;
				lat_pass <= p; lat_fail <= f;
			end if;
		end if;
	end process latency;

END test;
