--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for the directed GPIO test
--
-- Closes gaps G-406 and G-407, which Phases 6A and 6B each registered against
-- their own verification:
--
--   G-406  tb_gpio's cross-talk check is ONE-SIDED. GPIO test0 writes the same
--          value to all seven ports in ascending address order, so a port that
--          wrongly captures an EARLIER store fails, while one that wrongly
--          captures a LATER store re-captures a value it already holds and is
--          invisible.
--   G-407  The seven GPO read-back tri-states of Figure 5 are implemented and
--          exercised by nothing. No supplied benchmark reads PORT_LEDR or a
--          PORT_HEXn — the only MMIO reads anywhere are three lw from PORT_SW.
--
-- THEY CLOSE EACH OTHER, which is why one program does both. Read-back makes a
-- port's CONTENT observable; once content is observable the lane decode is
-- discriminable in both directions. The program writes different values to the
-- two halves of each shared chip select, in BOTH orders, and reads both back.
--
-- PHASE 6C ADDED TWO CASES
--   PORT_PB is read with KEY3 and KEY2 pressed and KEY1 released, which must give
--   0x06 — a value that is NOT symmetric under bit reversal, so a wrong bit order
--   gives 0x03 and fails. The order itself (KEY1→bit 0, KEY2→bit 1, KEY3→bit 2)
--   is Hanan's forum answer; the polarity is assumption A16. And a store to
--   PORT_PB, which is a GPI, must be discarded and must not disturb what it
--   presents.
--
-- HOW IT WORKS
--   The same scoreboard shape as tb_isa_directed.vhd: snoop every committed
--   store and compare it against the next entry of a generated expected
--   sequence, so both the values and the ORDER are checked. The program
--   publishes each result with "sw rX, slot*4(zero)" to a DTCM scratch word, and
--   the MMIO stores appear in the sequence too.
--
--   ADDRESSES ARE COMPARED AS FULL BYTE ADDRESSES, from alu_res_o, not as DTCM
--   word indices. That is not a style choice: an MMIO store to 0x2004 and a DTCM
--   store to word 1 produce the same dtcm_addr_o, because the core narrows the
--   address by dropping bit 13. Comparing dtcm_addr_o would make this suite
--   unable to tell an MMIO store from the DTCM store it used to alias onto —
--   which is one of the things being tested.
--
--   This program builds addresses with addi and slli only, uses lw at offset
--   zero throughout, and has no compares, no sra, no jalr and one beq sentinel
--   at offset 0. tools/gen_gpio_test.py carries the defect-by-defect check.
--
--   That makes this the one GPIO test that can be run without editing
--   cond_compilation_package.vhd, and it means a mismatch here is a GPIO
--   problem, never an ISA one.
--
-- STAGING: SIM/RV32IMscMCU/gpio/{ITCM.hex,DTCM.hex} — generated, not a benchmark.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;
USE work.gpio_expected_pkg.all;


ENTITY tb_gpio_directed IS
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
		-- The program is 331 instructions of straight-line code plus the
		-- sentinel, and the core is single-cycle, so it retires in ~332 cycles.
		-- The cap is a backstop for a core that never reaches the sentinel.
		MAX_CYCLES			: integer	:= 1000
	);
END tb_gpio_directed;
--============================================================================
ARCHITECTURE test OF tb_gpio_directed IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	SIGNAL instruction_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_cnt_o			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

	-- The auto-stop sentinel the whole project uses: beq x0,x0,0.
	CONSTANT SENTINEL			: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000063";

	function addr_of(v : STD_LOGIC_VECTOR) return natural is
		variable n : natural := 0;
	begin
		for i in v'range loop
			n := n * 2;
			if v(i) = '1' then n := n + 1; end if;
		end loop;
		return n;
	end function;

	function hex4(n : natural) return string is
		CONSTANT D : string(1 TO 16) := "0123456789ABCDEF";
		variable s : string(1 TO 4);
		variable v : natural := n;
	begin
		for i in 4 downto 1 loop
			s(i) := D(v mod 16 + 1);
			v := v / 16;
		end loop;
		return s;
	end function;

BEGIN
	DUT : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,
		GEN_DEBUG_PORTS		=> TRUE,
		GEN_GPO_READBACK	=> TRUE,		-- the whole point of this suite
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
		SW_i				=> SW_VALUE,		-- both from the generated package
		KEY_i				=> KEY_VALUE,		-- raw active-low pins, KEY3..KEY1
		instruction_o		=> instruction_o,
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,
		alu_res_o			=> alu_res_o,
		dtcm_data_wr_o		=> dtcm_data_wr_o,
		mclk_cnt_o			=> mclk_cnt_o
	);
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
	-- Falling edge, the same convention and for the same reason as every other
	-- testbench here: DMEMORY clocks its altsyncram on NOT clk_i, so a store
	-- commits when clk falls, and the control and address outputs are settled
	-- well before then. Sampling on the rising edge would race the fetch.
	scoreboard : process(clk_i)
		variable idx		: natural := 0;			-- next expected store
		variable fails		: natural := 0;
		variable cycles		: natural := 0;
		variable got_addr	: natural;
		variable done		: boolean := FALSE;
	begin
		if falling_edge(clk_i) and rst_i = '0' and not done then
			cycles := cycles + 1;

			if MemWrite_ctrl_o = '1' then
				got_addr := addr_of(alu_res_o(DATA_ADDR_WIDTH-1 DOWNTO 0));

				if idx >= STORE_COUNT then
					fails := fails + 1;
					report "GPIO TEST FAIL: store number " & integer'image(idx) &
						   " to 0x" & hex4(got_addr) & " is BEYOND the expected " &
						   "sequence of " & integer'image(STORE_COUNT) & ". The " &
						   "program executed more stores than it contains, so " &
						   "control flow went somewhere it should not have."
						severity error;
				else
					if got_addr /= EXPECTED(idx).addr then
						fails := fails + 1;
						report "GPIO TEST FAIL [" & EXPECTED(idx).name & "]: store " &
							   integer'image(idx) & " went to 0x" & hex4(got_addr) &
							   ", expected 0x" & hex4(EXPECTED(idx).addr) &
							   ". A wrong ADDRESS means the effective-address " &
							   "computation or the store path, not the GPIO block."
							severity error;
					elsif dtcm_data_wr_o /= EXPECTED(idx).data then
						fails := fails + 1;
						report "GPIO TEST FAIL [" & EXPECTED(idx).name & "]: store " &
							   integer'image(idx) & " at 0x" & hex4(got_addr) &
							   " carried 0x" & to_hstring(dtcm_data_wr_o) &
							   ", expected 0x" & to_hstring(EXPECTED(idx).data) &
							   ".  Reason this case exists: " &
							   "see SIM/RV32IMscMCU/gpio/listing.txt entry " &
							   integer'image(idx) & "."
							severity error;
					end if;
					idx := idx + 1;
				end if;
			end if;

			--==========================================================
			-- Stop on the sentinel, or on the cycle cap.
			--==========================================================
			if instruction_o = SENTINEL or cycles >= MAX_CYCLES then
				done := TRUE;
				report "===== DIRECTED GPIO TEST (G-406, G-407) =====" severity note;
				report "  cycles           : " & integer'image(cycles) &
					   "   (mclk_cnt_o = " & integer'image(addr_of(mclk_cnt_o)) & ")"
					severity note;
				report "  stores seen      : " & integer'image(idx) &
					   " of " & integer'image(STORE_COUNT) severity note;
				report "  mismatches       : " & integer'image(fails) severity note;

				if instruction_o /= SENTINEL then
					fails := fails + 1;
					report "GPIO TEST FAIL: the cycle cap of " &
						   integer'image(MAX_CYCLES) & " was reached without fetching " &
						   "the sentinel. The program did not run to completion."
						severity error;
				end if;

				if idx < STORE_COUNT then
					fails := fails + 1;
					report "GPIO TEST FAIL: only " & integer'image(idx) & " of " &
						   integer'image(STORE_COUNT) & " expected stores were seen. " &
						   "The next one missing is [" & EXPECTED(idx).name &
						   "] at 0x" & hex4(EXPECTED(idx).addr) & ". A short " &
						   "sequence means the program stopped early, not that a " &
						   "value was wrong."
						severity error;
				end if;

				if fails = 0 then
					report "  VERDICT: PASS - all " & integer'image(STORE_COUNT) &
						   " stores matched, in order. G-406 and G-407 are closed: " &
						   "each shared chip select was exercised in BOTH write " &
						   "orders with different values, all seven GPO ports were " &
						   "read back, PORT_SW read 0x" & to_hstring(SW_VALUE) &
						   ", PORT_PB read the pressed keys in Hanan's bit order and " &
						   "ignored a write, an unmapped read returned " &
						   "zero, an unmapped write was discarded, and DTCM word 0 " &
						   "still held its marker after fourteen MMIO stores."
						severity note;
				else
					report "  VERDICT: FAIL - " & integer'image(fails) & " problem(s). " &
						   "Unlike the ISA suite, ZERO is the only passing number here: " &
						   "this program avoids the Lab 5 ISA defects, so nothing is " &
						   "expected to fail. " &
						   "Read the first failure's case name and look it up in " &
						   "SIM/RV32IMscMCU/gpio/listing.txt, which says what that " &
						   "case is for."
						severity error;
				end if;
				report "=============================================" severity note;
				std.env.stop;
			end if;
		end if;
	end process scoreboard;

END test;
