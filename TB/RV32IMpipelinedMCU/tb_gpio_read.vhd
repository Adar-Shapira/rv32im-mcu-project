--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for Phase 6B (gap G-306)
--
-- Proves the SFR read path works, using the supplied GPIO test1 and its own
-- control flow as the oracle.
--
-- WHY test1 IS A BETTER TEST THAN ANY ASSERTION ON THE BUS
--   A read path can be checked two ways: watch the value on the bus, or watch
--   what the program DOES with it. The second is far stronger here, because
--   test1 branches on the value it reads. From the disassembled image
--   Auxiliary/Benchmark Apps/GPIO/test1/bin/M9K-intel/ITCM.hex:
--
--     word  4  lui   x29,0x2
--     word  5  lw    x29,16(x29)     -- reads 0x2010 = PORT_SW
--     word  6  andi  x7,x29,1        -- SW0_MASK
--     word  7  bne   x7,x0,+8        -- taken -> word 9
--     word  8  jal   x0,+28          -- not taken -> word 15
--     word  9  addi  x5,x5,1         -- SW0 set:   COUNT UP
--     word 15  andi  x7,x29,2        -- SW1_MASK
--     word 16  bne   x7,x0,+8        -- taken -> word 18
--     word 18  addi  x5,x5,-1        -- SW1 set:   COUNT DOWN
--
--   So the switch value chooses between three observable behaviours, and the
--   observable is the value that reaches PORT_LEDR and the six displays:
--
--     SW = 0x01  ->  the counter INCREASES
--     SW = 0x02  ->  the counter DECREASES
--     SW = 0x00  ->  neither branch is taken, so print2all is never called and
--                    NOTHING IS WRITTEN AT ALL
--
--   The third case is the sharpest. If the read path returned rubbish — 'Z' from
--   an undriven bus, 'X' from two drivers, or a stuck value — the branches would
--   go somewhere and writes would appear. "Exactly zero writes" is a very hard
--   thing to produce by accident.
--
-- WHAT IS CHECKED
--   P1  UP.    While SW = 0x01, every value written is the previous one plus 1.
--   P2  DOWN.  While SW = 0x02, every value written is the previous one minus 1.
--   P3  QUIET. While SW = 0x00, no store to any GPO port occurs at all.
--   P4  NOT VACUOUS. Phases 1 and 2 must each have produced writes, and the
--       counter must have moved in both directions. Without this, a core that
--       fetched nothing passes P3 and says nothing about P1 or P2.
--   P5  PORT CONTENT. The seven ports still hold what was last stored to them,
--       and each display still shows the right pattern — the Phase 6A model,
--       carried forward so 6B cannot silently break 6A.
--
-- WHAT THIS DOES NOT COVER, STATED PLAINLY
--   The GPO read-back paths (GEN_GPO_READBACK). No supplied benchmark ever reads
--   PORT_LEDR or a PORT_HEXn, so nothing here exercises those seven tri-states —
--   only PORT_SW's is proved. Recorded as gap G-407; closing it needs a small
--   program of ours that stores a byte to a GPO port and loads it back.
--
-- STAGING: GPIO **test1**'s M9K-intel images — note, test1, not test0.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;


ENTITY tb_gpio_read IS
	generic(
		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		-- One SW=0x01 iteration of test1 is 42 instructions (4 loop head + 1 addi
		-- + 2 call + 22 print2all + 2 call + 10 delay + 1 jal), counted from the
		-- disassembly. 300 cycles per phase is about 7 iterations, comfortably
		-- more than P4 needs. The SW=0x00 loop is only 9 instructions.
		PHASE_CYCLES		: integer	:= 400;
		-- Cycles to ignore after a switch change before scoring resumes. When SW
		-- changes, the iteration already in flight has ALREADY read the old value
		-- and will complete with the old branch, so exactly one stale store to
		-- PORT_LEDR arrives in the new phase. One full iteration is 42 cycles;
		-- 60 covers it with margin.
		--
		-- Without this, phase 3 fails: a stale increment landing just after the
		-- boundary looks like "a write happened with both switches clear", which is
		-- precisely what P3 is meant to catch, so it would be a false failure on a
		-- correct design.
		SETTLE_CYCLES		: integer	:= 120
	);
END tb_gpio_read;
--============================================================================
ARCHITECTURE test OF tb_gpio_read IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;
	SIGNAL SW_i					: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

	SIGNAL LEDR_o				: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL HEX0_o, HEX1_o		: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX2_o, HEX3_o		: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX4_o, HEX5_o		: STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	CONSTANT NPORT		: integer := 7;
	type int_array_t  is array (0 TO NPORT-1) of integer;
	type byte_array_t is array (0 TO NPORT-1) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type seg_table_t  is array (0 TO 15) of STD_LOGIC_VECTOR(6 DOWNTO 0);
	type seg6_array_t is array (0 TO 5)  of STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL hex_pins_w	: seg6_array_t;

	-- From io_map.s, as in tb_gpio.
	CONSTANT PORT_ADDR	: int_array_t := (
		16#2000#, 16#2004#, 16#2005#, 16#2008#, 16#2009#, 16#200C#, 16#200D#);

	-- Active-low DE2-115 patterns, derived from the segment shapes.
	CONSTANT SEG7		: seg_table_t := (
		"1000000","1111001","0100100","0110000","0011001","0010010","0000010","1111000",
		"0000000","0010000","0001000","0000011","1000110","0100001","0000110","0001110");

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

	function byte_val(b : STD_LOGIC_VECTOR) return integer is
		variable n : integer := 0;
	begin
		for i in 7 downto 0 loop
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
	DUT : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,
		GEN_DEBUG_PORTS		=> TRUE,
		GEN_GPO_READBACK	=> TRUE,
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
		PWM_o				=> open,
		SW_i(7 DOWNTO 0)	=> SW_i,
		SW_i(9 DOWNTO 8)	=> "00",
		LEDR_o				=> LEDR_o,
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
	-- Same falling-edge convention as every other testbench here, and the same
	-- one-cycle-delay model as tb_gpio: at each falling edge, commit the store
	-- recorded one edge earlier, then compare, then record this cycle's store.
	checker : process(clk_i)
		variable model_v	: byte_array_t := (OTHERS => (OTHERS => '0'));
		variable pend_idx_v	: integer := -1;
		variable pend_dat_v	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
		variable seg_v		: STD_LOGIC_VECTOR(6 DOWNTO 0);
		variable cycles_v	: integer := 0;
		variable fails_v	: integer := 0;
		variable reported_v	: integer := 0;
		variable a_v		: integer;
		variable phase_v	: integer := 1;			-- 1 = up, 2 = down, 3 = quiet
		variable phase_at_v	: integer := 0;			-- cycle the current phase began
		variable scoring_v	: boolean := FALSE;		-- past this phase's settle window
		variable skipped_v	: integer := 0;			-- stores ignored in a settle window
		variable wr_up_v	: integer := 0;
		variable wr_dn_v	: integer := 0;
		variable wr_quiet_v	: integer := 0;
		variable prev_v		: integer := -1;		-- previous value stored to LEDR
		variable have_prev_v: boolean := FALSE;
		variable ups_v		: integer := 0;
		variable downs_v	: integer := 0;

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

			-- Drive the switches. Changed at a phase boundary only. The program
			-- picks a change up on its next loop iteration, not immediately, which
			-- is what SETTLE_CYCLES below is for.
			--
			-- Note since 2026-08-24: SW_i is now read combinationally by default.
			-- GEN_INPUT_SYNC defaults to FALSE because Hanan's forum says a switch
			-- needs no synchroniser -- "their rate of change is many orders of
			-- magnitude slower than the system clock, so the signal is considered
			-- static". The settle window is unaffected either way: it exists for
			-- the loop iteration already in flight, not for the two flip-flops.
			if    cycles_v = 1              then
				SW_i <= x"01"; phase_v := 1; phase_at_v := cycles_v; have_prev_v := FALSE;
			elsif cycles_v = PHASE_CYCLES   then
				SW_i <= x"02"; phase_v := 2; phase_at_v := cycles_v; have_prev_v := FALSE;
			elsif cycles_v = 2*PHASE_CYCLES then
				SW_i <= x"00"; phase_v := 3; phase_at_v := cycles_v; have_prev_v := FALSE;
			end if;

			scoring_v := (cycles_v - phase_at_v) > SETTLE_CYCLES;

			--==========================================================
			-- 1. Commit the store recorded one edge ago.
			--==========================================================
			if pend_idx_v >= 0 then
				model_v(pend_idx_v) := pend_dat_v;

				-- P1 / P2 / P3 are all about stores to PORT_LEDR, which carries the
				-- counter. The other six get the same value, and P5 covers them.
				if pend_idx_v = 0 and not scoring_v then
					-- Inside a settle window: record the value so the next comparison
					-- has a baseline, but do not judge it.
					prev_v := byte_val(pend_dat_v);
					have_prev_v := TRUE;
					skipped_v := skipped_v + 1;
				elsif pend_idx_v = 0 then
					case phase_v is
						when 1 =>
							wr_up_v := wr_up_v + 1;
							if have_prev_v then
								if byte_val(pend_dat_v) = (prev_v + 1) mod 256 then
									ups_v := ups_v + 1;
								else
									fail("FAIL P1 up: SW=0x01 but PORT_LEDR went from " &
										 integer'image(prev_v) & " to " &
										 integer'image(byte_val(pend_dat_v)) & " at cycle " &
										 integer'image(cycles_v) & ". test1 takes the SW0 " &
										 "branch and increments, so the read of PORT_SW is " &
										 "not returning bit 0 set.");
								end if;
							end if;
						when 2 =>
							wr_dn_v := wr_dn_v + 1;
							if have_prev_v then
								if byte_val(pend_dat_v) = (prev_v + 255) mod 256 then
									downs_v := downs_v + 1;
								else
									fail("FAIL P2 down: SW=0x02 but PORT_LEDR went from " &
										 integer'image(prev_v) & " to " &
										 integer'image(byte_val(pend_dat_v)) & " at cycle " &
										 integer'image(cycles_v) & ". test1 should be taking " &
										 "the SW1 branch and decrementing.");
								end if;
							end if;
						when others =>
							wr_quiet_v := wr_quiet_v + 1;
							fail("FAIL P3 quiet: SW=0x00 but PORT_LEDR was written with " &
								 integer'image(byte_val(pend_dat_v)) & " at cycle " &
								 integer'image(cycles_v) & ". With neither switch set test1 " &
								 "takes neither branch and never calls print2all, so no store " &
								 "should happen at all. Something is making a branch go the " &
								 "wrong way - the read path is returning a non-zero value.");
					end case;
					prev_v := byte_val(pend_dat_v);
					have_prev_v := TRUE;
				end if;
			end if;

			--==========================================================
			-- P5 -- the Phase 6A port model, carried forward.
			--==========================================================
			if LEDR_o(7 DOWNTO 0) /= model_v(0) then
				fail("FAIL P5 " & pname(0) & " at cycle " & integer'image(cycles_v) &
					 ": pins " & to_bstr(LEDR_o(7 DOWNTO 0)) & ", expected " & to_bstr(model_v(0)));
			end if;
			for i in 1 to NPORT-1 loop
				seg_v := hex_pins_w(i-1);
				if seg_v /= SEG7(nib(model_v(i))) then
					fail("FAIL P5 " & pname(i) & " at cycle " & integer'image(cycles_v) &
						 ": segments " & to_bstr(seg_v) & ", expected " &
						 to_bstr(SEG7(nib(model_v(i)))) & " for digit " &
						 integer'image(nib(model_v(i))));
				end if;
			end loop;

			--==========================================================
			-- 2. Record this cycle's store.
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

			--==========================================================
			if cycles_v >= 3*PHASE_CYCLES then
				report "===== PHASE 6B SFR READ TEST (GPIO test1) =====" severity note;
				report "  cycles run              : " & integer'image(cycles_v) severity note;
				report "  phase 1  SW=0x01  writes: " & integer'image(wr_up_v) &
					   "   increments seen: " & integer'image(ups_v) severity note;
				report "  phase 2  SW=0x02  writes: " & integer'image(wr_dn_v) &
					   "   decrements seen: " & integer'image(downs_v) severity note;
				report "  phase 3  SW=0x00  writes: " & integer'image(wr_quiet_v) &
					   "   (must be 0)" severity note;
				report "  stores in settle windows: " & integer'image(skipped_v) &
					   "   (not scored; 1 per boundary is normal)" severity note;

				--======================================================
				-- P4 -- anti-vacuity
				--======================================================
				if ups_v < 2 then
					fail("FAIL P4: only " & integer'image(ups_v) & " increment(s) observed " &
						 "in phase 1. P1 proved nothing. Either the program did not run or " &
						 "PORT_SW never read as 0x01.");
				end if;
				if downs_v < 2 then
					fail("FAIL P4: only " & integer'image(downs_v) & " decrement(s) observed " &
						 "in phase 2. P2 proved nothing - the switch change is not reaching " &
						 "the program.");
				end if;

				report "  failures                : " & integer'image(fails_v) severity note;
				if fails_v = 0 then
					report "  VERDICT: PASS - the program counted UP while SW0 was set, DOWN " &
						   "while SW1 was set, and wrote nothing at all with both clear. Its " &
						   "branches followed the value read from PORT_SW, so the read path " &
						   "works. The seven ports also still hold what was stored."
						severity note;
					report "  NOT covered: the seven GPO read-back paths. No supplied " &
						   "benchmark reads PORT_LEDR or a PORT_HEXn, so only PORT_SW's " &
						   "tri-state is exercised here. Gap G-407."
						severity note;
				else
					report "  VERDICT: FAIL - " & integer'image(fails_v) & " check(s) failed. " &
						   "P3 failing (writes with both switches clear) points at the read " &
						   "returning garbage - an undriven bus reads 'Z' and a doubly-driven " &
						   "one reads 'X', and either makes a branch go the wrong way. P1 or " &
						   "P2 alone points at the bit order or the synchroniser. P5 alone " &
						   "means Phase 6A broke, not 6B."
						severity error;
				end if;
				report "===============================================" severity note;
				std.env.stop;
			end if;
		end if;
	end process checker;

END test;
