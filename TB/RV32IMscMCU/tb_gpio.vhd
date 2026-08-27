--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for Phase 6A (gap G-306)
--
-- Runs the supplied GPIO test0 and checks that the seven GPO ports of Figure 5
-- hold, and display, exactly what the program stored.
--
-- WHY THIS NEEDS A SCOREBOARD AND NOT AN EYEBALL
--   G-405 in the plan says these benchmarks never write the DTCM, so there is no
--   golden memory image to diff and the obvious fallback is "look at the
--   waveform". A waveform cannot show the property that actually matters here,
--   which is not "does LEDR change" but "does LEDR change ONLY when LEDR was
--   addressed". The classic decode bug in a design like this is cross-talk — a
--   store to PORT_HEX0 also updating PORT_HEX1, because the two share a chip
--   select and are separated only by A0. That is invisible in test0, where every
--   port is written the same value in the same iteration, and it is exactly what
--   P4 below catches.
--
-- THE MODEL
--   Independent of the RTL: it is built from the byte addresses in io_map.s and
--   from Figure 5's rule (a port captures when its own byte address is stored
--   to). It does not call hex_decoder — the expected segment patterns below are
--   transcribed separately from the DE2-115 active-low truth table, so the
--   display path is genuinely checked rather than compared against itself.
--
-- TIMING, AND WHY THE MODEL LAGS BY ONE CYCLE
--   gpo_port captures on rising_edge(mclk) with en = cs.MemWrite.lane, so a store
--   executing in cycle N appears on the pins after the rising edge that ENDS
--   cycle N, i.e. during cycle N+1. Sampling happens on the falling edge, which
--   is mid-cycle and where the store request of the current cycle and the port
--   contents from the previous one are both stable. So at each falling edge the
--   checker first commits the request it recorded one edge earlier, then compares,
--   then records this cycle's request. Same sampling edge, and the same reason, as
--   tb_isa_directed.vhd:182 and tb_mmio_alias.vhd.
--
-- WHAT IS CHECKED
--   P1  CONTENT.   Every one of the seven ports holds the byte the program last
--                  stored to its own address.
--   P2  DISPLAY.   Each HEX display shows the active-low 7-segment pattern for
--                  the low nibble of its port, from an independent table.
--   P3  NOT VACUOUS. All seven ports must have been written, and the value must
--                  have advanced through at least three distinct values — test0
--                  increments t0 once per iteration, so a stuck core fails here.
--   P4  NO CROSS-TALK. A port may change only on the edge following a store to
--                  its own byte address. This is the one a waveform cannot show.
--
--   P4's LIMIT, STATED RATHER THAN LEFT TO BE DISCOVERED. test0 writes the SAME
--   value to all seven ports in a fixed ascending order, so P4 catches cross-talk
--   in one direction only: a port capturing an EARLIER store than its own moves
--   its pins to a value the model does not expect and fails. A port capturing a
--   LATER store of the same iteration re-captures a value it already holds, its
--   pins never move, and nothing here can see it. Concretely: dropping
--   lane_en_i on P_HEX1 (which would make it take 0x2004's store) IS caught;
--   dropping it on P_HEX0 (which would make it also take 0x2005's store) is NOT.
--   Discriminating that direction needs a program that writes DIFFERENT values to
--   the two ports of a pair, which no supplied benchmark does -- GPIO test1 and
--   test2 also write one value to all seven. Recorded as gap G-406.
--
-- STAGING
--   GPIO test0's M9K-intel images as app_bin\ITCM.hex and app_bin\DTCM.hex.
--   run_gpio.do gives the exact copy commands.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;


ENTITY tb_gpio IS
	generic(
		-- PHASE 14. Overridable from the command line so PPA row 1 -- "MCU with
		-- GPIO", the interrupt-free configuration -- can be SIMULATED and not
		-- merely synthesized:
		--     vsim -t ns -gGEN_INTERRUPT=FALSE work.tb_gpio
		-- This suite is the right one for that: it touches the seven GPO ports
		-- and nothing in clause 6, so every check below must still pass with the
		-- interrupt capability compiled out. (tb_gpio_directed would NOT do --
		-- it reads PORT_PB, which clause 6 owns, so it is expected to fail in
		-- row 1 rather than prove anything about it.)
		GEN_INTERRUPT		: boolean	:= G_GEN_INTERRUPT;
		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		-- 32 instructions per test0 iteration (counted from the shipped ITCM
		-- image, see tb_mmio_alias.vhd), so 600 cycles is 18 iterations.
		RUN_CYCLES			: integer	:= 600
	);
END tb_gpio;
--============================================================================
ARCHITECTURE test OF tb_gpio IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	SIGNAL LEDR_o				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL HEX0_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX1_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX2_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX3_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX4_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX5_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	--=======================================================================
	-- The model
	--=======================================================================
	-- Port index 0 is PORT_LEDR, 1..6 are PORT_HEX0..PORT_HEX5. Byte addresses
	-- transcribed from Auxiliary/Benchmark Apps/GPIO/test0/asm-code/io_map.s.
	CONSTANT NPORT		: integer := 7;
	type int_array_t  is array (0 TO NPORT-1) of integer;
	type byte_array_t is array (0 TO NPORT-1) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type seg_table_t  is array (0 TO 15) of STD_LOGIC_VECTOR(6 DOWNTO 0);
	type seg6_array_t is array (0 TO 5)  of STD_LOGIC_VECTOR(6 DOWNTO 0);

	-- The six displays gathered into one indexable signal. This exists so the
	-- checker can loop over them; an impure function reading the six port signals
	-- would do the same job but puts signal reads inside a subprogram, which is
	-- legal and still worth avoiding when a plain wire does it.
	SIGNAL hex_pins_w	: seg6_array_t;

	CONSTANT PORT_ADDR	: int_array_t := (
		16#2000#,		-- 0  PORT_LEDR
		16#2004#,		-- 1  PORT_HEX0
		16#2005#,		-- 2  PORT_HEX1
		16#2008#,		-- 3  PORT_HEX2
		16#2009#,		-- 4  PORT_HEX3
		16#200C#,		-- 5  PORT_HEX4
		16#200D#		-- 6  PORT_HEX5
	);

	-- Active-low DE2-115 7-segment patterns, bit 6 = segment g .. bit 0 = a.
	-- Transcribed INDEPENDENTLY of hex_decoder.vhd so that comparing against it
	-- is a real check of the display path and not a tautology.
	CONSTANT SEG7		: seg_table_t := (
		"1000000",	-- 0
		"1111001",	-- 1
		"0100100",	-- 2
		"0110000",	-- 3
		"0011001",	-- 4
		"0010010",	-- 5
		"0000010",	-- 6
		"1111000",	-- 7
		"0000000",	-- 8
		"0010000",	-- 9
		"0001000",	-- A
		"0000011",	-- b
		"1000110",	-- C
		"0100001",	-- d
		"0000110",	-- E
		"0001110"	-- F
	);

	function addr_of(v : STD_LOGIC_VECTOR) return natural is
		variable n : natural := 0;
	begin
		for i in v'range loop
			n := n * 2;
			if v(i) = '1' then n := n + 1; end if;
		end loop;
		return n;
	end function;

	function nib(b : STD_LOGIC_VECTOR) return integer is
		variable n : integer := 0;
	begin
		for i in 3 downto 0 loop
			n := n * 2;
			if b(i) = '1' then n := n + 1; end if;
		end loop;
		return n;
	end function;

	function pname(i : integer) return string is
	begin
		case i is
			when 0 => return "PORT_LEDR";
			when 1 => return "PORT_HEX0";
			when 2 => return "PORT_HEX1";
			when 3 => return "PORT_HEX2";
			when 4 => return "PORT_HEX3";
			when 5 => return "PORT_HEX4";
			when others => return "PORT_HEX5";
		end case;
	end function;

	function to_bstr(v : STD_LOGIC_VECTOR) return string is
		variable s : string(1 TO v'length);
		variable k : integer := 1;
	begin
		for i in v'range loop
			case v(i) is
				when '0' => s(k) := '0';
				when '1' => s(k) := '1';
				when others => s(k) := '?';
			end case;
			k := k + 1;
		end loop;
		return s;
	end function;

BEGIN
	DUT : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,
		GEN_DEBUG_PORTS		=> TRUE,	-- MemWrite_ctrl_o and alu_res_o must be driven
		GEN_INTERRUPT		=> GEN_INTERRUPT,
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH
	)
	PORT MAP (
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		LEDR_o(7 DOWNTO 0)	=> LEDR_o,
		HEX0_o				=> HEX0_o,
		HEX1_o				=> HEX1_o,
		HEX2_o				=> HEX2_o,
		HEX3_o				=> HEX3_o,
		HEX4_o				=> HEX4_o,
		HEX5_o				=> HEX5_o,
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,
		read_data2_o		=> read_data2_o,
		alu_res_o			=> alu_res_o
	);
--------------------------------------------------------------------
	hex_pins_w(0) <= HEX0_o;
	hex_pins_w(1) <= HEX1_o;
	hex_pins_w(2) <= HEX2_o;
	hex_pins_w(3) <= HEX3_o;
	hex_pins_w(4) <= HEX4_o;
	hex_pins_w(5) <= HEX5_o;
--------------------------------------------------------------------
	gen_clk : process
	begin
		clk_i <= '1';
		wait for 50 ns;
		clk_i <= '0';
		wait for 50 ns;
	end process;

	gen_rst : process
	begin
		rst_i <= '1', '0' after 80 ns;
		wait;
	end process;
--------------------------------------------------------------------
	checker : process(clk_i)
		variable model_v	: byte_array_t := (OTHERS => (OTHERS => '0'));
		variable writes_v	: int_array_t  := (OTHERS => 0);
		variable pend_idx_v	: integer := -1;				-- port written in the previous cycle
		variable pend_dat_v	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
		variable act_v		: STD_LOGIC_VECTOR(7 DOWNTO 0);
		variable seg_v		: STD_LOGIC_VECTOR(6 DOWNTO 0);
		variable cycles_v	: integer := 0;
		variable fails_v	: integer := 0;
		variable reported_v	: integer := 0;
		variable a_v		: integer;
		variable distinct_v	: integer := 0;
		variable last_led_v	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

		procedure fail(msg : in string) is
		begin
			fails_v := fails_v + 1;
			if reported_v < 20 then
				reported_v := reported_v + 1;
				report msg severity error;
			end if;
		end procedure;
	begin
		if falling_edge(clk_i) and rst_i = '0' then

			cycles_v := cycles_v + 1;

			--==========================================================
			-- 1. Commit the write recorded one edge ago. It took effect at the
			--    rising edge between then and now.
			--==========================================================
			if pend_idx_v >= 0 then
				model_v(pend_idx_v) := pend_dat_v;
				writes_v(pend_idx_v) := writes_v(pend_idx_v) + 1;
			end if;

			--==========================================================
			-- P1 CONTENT and P2 DISPLAY, and P4 NO CROSS-TALK.
			--
			-- P4 needs no separate comparison: the model only ever changes for
			-- the port the previous cycle addressed, so if any OTHER port moved,
			-- its comparison here is what fails. That is the whole point of
			-- modelling the content rather than watching for edges.
			--==========================================================
			-- PORT_LEDR: all eight bits are observable directly.
			if LEDR_o /= model_v(0) then
				fail("FAIL P1/P4 " & pname(0) & " at cycle " & integer'image(cycles_v) &
					 ": pins show " & to_bstr(LEDR_o) & ", expected " & to_bstr(model_v(0)) &
					 ". If another port was stored to in the previous cycle, this is " &
					 "cross-talk - check the lane_en_i term on P_LEDR.");
			end if;

			-- The six displays: compare segments against the independent table.
			for i in 1 to NPORT-1 loop
				seg_v := hex_pins_w(i-1);
				if seg_v /= SEG7(nib(model_v(i))) then
					fail("FAIL P2 " & pname(i) & " at cycle " & integer'image(cycles_v) &
						 ": segments " & to_bstr(seg_v) & ", expected " &
						 to_bstr(SEG7(nib(model_v(i)))) & " for digit " &
						 integer'image(nib(model_v(i))) &
						 ". Either the port took a write it should not have (cross-talk " &
						 "on a shared chip select), or the 7-segment path is wrong.");
				end if;
			end loop;

			--==========================================================
			-- 2. Record this cycle's store, if it targets a GPO port.
			--==========================================================
			pend_idx_v := -1;
			if MemWrite_ctrl_o = '1' then
				a_v := addr_of(alu_res_o(DATA_ADDR_WIDTH-1 DOWNTO 0));
				for i in 0 to NPORT-1 loop
					if PORT_ADDR(i) = a_v then
						pend_idx_v := i;
						pend_dat_v := read_data2_o(7 DOWNTO 0);
					end if;
				end loop;
			end if;

			-- P3 bookkeeping: count how many distinct values LEDR has shown.
			if model_v(0) /= last_led_v then
				distinct_v := distinct_v + 1;
				last_led_v := model_v(0);
			end if;

			--==========================================================
			if cycles_v >= RUN_CYCLES then
				report "===== PHASE 6A GPIO TEST (GPIO test0) =====" severity note;
				report "  cycles run        : " & integer'image(cycles_v) severity note;
				for i in 0 to NPORT-1 loop
					report "  " & pname(i) & " writes : " & integer'image(writes_v(i)) severity note;
				end loop;
				report "  distinct LEDR vals: " & integer'image(distinct_v) &
					   "  (need >= 3)" severity note;

				--======================================================
				-- P3 -- the anti-vacuity check
				--======================================================
				for i in 0 to NPORT-1 loop
					if writes_v(i) = 0 then
						fail("FAIL P3 coverage: " & pname(i) & " (byte address " &
							 integer'image(PORT_ADDR(i)) & ") was never written, so " &
							 "the fact that it holds the right value proves nothing.");
					end if;
				end loop;
				if distinct_v < 3 then
					fail("FAIL P3 progress: LEDR showed only " & integer'image(distinct_v) &
						 " distinct value(s). test0 increments its counter once per loop, " &
						 "so the core is not looping - raise RUN_CYCLES or look at the core.");
				end if;

				report "  failures          : " & integer'image(fails_v) severity note;
				if fails_v = 0 then
					report "  VERDICT: PASS - all seven GPO ports held exactly what the " &
						   "program stored, every display showed the right active-low " &
						   "pattern for its low nibble, no port ever moved without being " &
						   "addressed, and the counter advanced."
						severity note;
				else
					report "  VERDICT: FAIL - " & integer'image(fails_v) & " check(s) failed. " &
						   "A P2 failure on one HEX of a pair with the other correct is " &
						   "cross-talk on a shared chip select: check lane_en_i. All six " &
						   "HEX failing together points at the 7-segment path or the " &
						   "low-nibble wiring. P3 alone means the program did not run."
						severity error;
				end if;
				report "===========================================" severity note;
				std.env.stop;
			end if;
		end if;
	end process checker;

END test;
