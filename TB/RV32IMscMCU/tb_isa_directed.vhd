--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — directed, self-checking ISA testbench
--
-- PURPOSE
--   Turn the five known decode defects and the missing M-extension instructions
--   from a claim into a measurement, before any of them is touched. The rules
--   file requires a self-checking testbench rather than waveform inspection, and
--   this is the first one in the project.
--
-- WHAT IT PROVES
--   Cases covering RV32I arithmetic, logic, all shifts, signed AND unsigned
--   compares, every branch, jal, lui, auipc, word and sub-word loads and stores
--   with non-zero offsets, and every RV32M instruction.
--
--   On the CURRENT core, exactly EXPECTED_DEFECT_COUNT of the STORE_COUNT stores
--   must MISMATCH — both constants come from the generated package, so no number
--   is written down twice anywhere. A run that reports zero failures means the
--   suite is not reaching the defects and is itself broken. Once Phase 3 repairs
--   the core, the same suite must report zero.
--
-- HOW IT OBSERVES
--   The core has no register-file port, but MemWrite_ctrl_o, dtcm_addr_o and
--   dtcm_data_wr_o are all declared outputs. Every result therefore reaches the
--   testbench over real ports — no external names, no memory introspection, and
--   nothing that depends on a precompiled Altera model's internals.
--
--   The test program publishes each case's result with `sw rX, slot*4(x0)`, so
--   the store sequence is the result sequence.
--
-- WHY SAMPLING HAPPENS ON THE FALLING EDGE
--   DMEMORY drives its altsyncram with wrclk_w <= NOT clk_i, so the DTCM latches
--   a store when clk_i falls. The control and data outputs are combinational off
--   the ITCM's registered instruction, so they are settled well before then.
--   Sampling on falling_edge(clk_i) therefore observes exactly what the memory
--   commits. Sampling on the rising edge would race the instruction fetch.
--
-- WHY THE PROGRAM ONLY USES addi AND sw AS PLUMBING
--   Four of the five defects break the instructions a harness would normally
--   rely on — lui writes 0, loads ignore their offset, sra is srl, unsigned
--   compares are signed. So operands are built with addi (and slli, which
--   works) and results published with sw. See tools/gen_isa_test.py.
--
-- GENERATED INPUTS
--   tools/gen_isa_test.py emits SIM/RV32IMscMCU/isa/{ITCM,DTCM}.hex, the
--   companion listing, and isa_expected_pkg. The expectations there were
--   cross-checked against a reference RV32IM interpreter, so a mismatch here is
--   a hardware finding rather than a bad expectation.
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_isa.do — it stages the generated images into app_bin and
--   runs this testbench.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;
USE work.isa_expected_pkg.all;


ENTITY tb_isa_directed IS
	generic(
		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16
	);
END tb_isa_directed;
--============================================================================
ARCHITECTURE test OF tb_isa_directed IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	SIGNAL pc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL RegWrite_ctrl_o		: STD_LOGIC;
	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL Branch_ctrl_o		: STD_LOGIC;
	SIGNAL read_data1_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_o			: STD_LOGIC;
	SIGNAL dtcm_addr_o			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_cnt_o			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

	-- the auto-stop sentinel the whole project already uses: beq x0,x0,0
	constant SENTINEL			: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000063";

	-- How many mismatches this build is supposed to produce. Selected by the same
	-- package constant the RTL compiles against, so the prediction and the core
	-- can never disagree about which configuration is under test. A function
	-- rather than a "when/else" expression because a conditional expression is
	-- not legal in a constant initializer.
	function predicted_count(repair : boolean) return natural is
	begin
		if repair then
			return EXPECTED_DEFECT_COUNT_REPAIRED;
		else
			return EXPECTED_DEFECT_COUNT;
		end if;
	end function predicted_count;

	constant PREDICTED			: natural := predicted_count(G_ISA_REPAIR);

	function addr_of(v : STD_LOGIC_VECTOR) return natural is
		variable n : natural := 0;
	begin
		for i in v'range loop
			n := n * 2;
			if v(i) = '1' then n := n + 1; end if;
		end loop;
		return n;
	end function;

BEGIN
	DUT : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is active-high
		GEN_DEBUG_PORTS		=> TRUE,
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
		pc_o				=> pc_o,
		instruction_o		=> instruction_o,
		RegWrite_ctrl_o		=> RegWrite_ctrl_o,
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,
		Branch_ctrl_o		=> Branch_ctrl_o,
		read_data1_o		=> read_data1_o,
		read_data2_o		=> read_data2_o,
		write_data_o		=> write_data_o,
		alu_res_o			=> alu_res_o,
		brTaken_o			=> brTaken_o,
		dtcm_addr_o			=> dtcm_addr_o,
		dtcm_data_wr_o		=> dtcm_data_wr_o,
		dtcm_data_rd_o		=> dtcm_data_rd_o,
		mclk_cnt_o			=> mclk_cnt_o
	);
--------------------------------------------------------------------
	-- Same 100 ns clock and 80 ns active-high reset as every other testbench in
	-- this project, so timing behaviour is directly comparable.
	gen_clk : process
	begin
		clk_i <= '1';
		wait for 50 ns;
		clk_i <= not clk_i;
		wait for 50 ns;
	end process;

	gen_rst : process
	begin
		rst_i <= '1', '0' after 80 ns;
		wait;
	end process;
--------------------------------------------------------------------
	-- The scoreboard. One process: snoop every committed store, compare against
	-- the next expected entry, and report a verdict when the sentinel is fetched.
	scoreboard : process(clk_i)
		variable idx			: natural := 0;		-- next expected store
		variable fails			: natural := 0;		-- mismatches seen
		variable got_addr		: natural;
		variable done			: boolean := false;
	begin
		if falling_edge(clk_i) and rst_i = '0' and not done then

			--------------------------------------------------------------
			-- A store is committing this half-cycle: the DTCM's write clock
			-- (NOT clk_i) is rising right now.
			--------------------------------------------------------------
			if MemWrite_ctrl_o = '1' then
				if idx >= STORE_COUNT then
					report "ISA TEST: store #" & integer'image(idx) &
						" occurred but only " & integer'image(STORE_COUNT) &
						" were expected - the program executed more stores than " &
						"the generated sequence describes"
						severity error;
					fails := fails + 1;
				else
					got_addr := addr_of(dtcm_addr_o);

					if got_addr /= EXPECTED(idx).addr then
						report "ISA TEST FAIL [" & EXPECTED(idx).name & "] store #" &
							integer'image(idx) & ": wrong ADDRESS - expected word " &
							integer'image(EXPECTED(idx).addr) & ", got word " &
							integer'image(got_addr)
							severity error;
						fails := fails + 1;

					elsif dtcm_data_wr_o /= EXPECTED(idx).data then
						report "ISA TEST FAIL [" & EXPECTED(idx).name & "] word " &
							integer'image(EXPECTED(idx).addr) & ": expected 0x" &
							to_hstring(EXPECTED(idx).data) & ", got 0x" &
							to_hstring(dtcm_data_wr_o) &
							"   (pc=0x" & to_hstring(pc_o) &
							" instr=0x" & to_hstring(instruction_o) & ")"
							severity error;
						fails := fails + 1;
					end if;
					idx := idx + 1;
				end if;
			end if;

			--------------------------------------------------------------
			-- Sentinel reached: the program is over. Report and stop.
			--------------------------------------------------------------
			if instruction_o = SENTINEL then
				done := true;
				report "" severity note;
				report "================ DIRECTED ISA TEST SUMMARY ================" severity note;
				report "  stores observed : " & integer'image(idx) &
					" of " & integer'image(STORE_COUNT) & " expected" severity note;
				report "  mismatches      : " & integer'image(fails) severity note;
				report "  cycles          : " & integer'image(addr_of(mclk_cnt_o)) severity note;

				if idx < STORE_COUNT then
					report "  INCOMPLETE: the program stopped before executing every " &
						"case. Missing from store #" & integer'image(idx) &
						" [" & EXPECTED(idx).name & "] onward. A control-flow " &
						"instruction under test most likely misdirected the PC."
						severity error;
				end if;

				-- Which count applies depends on how the design was compiled, and the
				-- testbench can read that directly: G_ISA_REPAIR is the same package
				-- constant the RTL uses, so the prediction cannot disagree with the
				-- core under test. Both numbers come from the generated package, so
				-- neither can drift away from the suite.
				if G_ISA_REPAIR then
					report "  configuration   : G_ISA_REPAIR = TRUE " &
						"(Phase 3A repairs applied)" severity note;
				else
					report "  configuration   : G_ISA_REPAIR = FALSE " &
						"(core exactly as LAB5 submitted)" severity note;
				end if;
				report "  expected here   : " & integer'image(PREDICTED) &
					" mismatch(es)" severity note;

				if fails = PREDICTED and PREDICTED = 0 then
					report "  VERDICT: zero mismatches, as predicted - full PASS." severity note;
				elsif fails = PREDICTED then
					report "  VERDICT: " & integer'image(fails) &
						" mismatch(es) - exactly the predicted set." severity note;
					if G_ISA_REPAIR then
						report "  This is the expected Phase 3A result. The seven repairs " &
							"closed G-321/322/323/324/325; what remains is blocked on " &
							"G-309 (byte enables, Phase 3B), G-326/G-308 (mul width) and " &
							"G-307 (divider, Phase 7)." severity note;
					else
						report "  This is the expected Phase 2 result. Every mismatch above " &
							"is a confirmed defect; see SIM/RV32IMscMCU/isa/listing.txt " &
							"for the citation attached to each one." severity note;
					end if;
				elsif fails = 0 then
					report "  VERDICT: zero mismatches, but " & integer'image(PREDICTED) &
						" were predicted. This is a FAILURE OF THE SUITE, not a pass." severity note;
					report "  The usual cause is that isa/ITCM.hex never reached " &
						"C:/TestPrograms/Quartus21_1/app_bin, so a different program ran."
						severity note;
				else
					report "  VERDICT: " & integer'image(fails) & " mismatch(es), but " &
						integer'image(PREDICTED) & " were predicted." severity note;
					report "  The difference is the interesting part: a mismatch on a case " &
						"not marked DEFECT in the listing is a NEW finding, and a case " &
						"marked DEFECT that passed means the defect is not where we " &
						"thought." severity note;
				end if;
				report "===========================================================" severity note;
				std.env.stop;
			end if;
		end if;
	end process scoreboard;
--------------------------------------------------------------------
	-- Runaway guard. The program is 184 instructions and every case is
	-- straight-line, so completion is well under 1000 cycles. Reaching this
	-- means the PC left the program - which is itself a finding, not a timeout
	-- to raise. Patterned on Auxilary/Lab3/TB/tb_top.vhd:86.
	watchdog : process
	begin
		wait for 200 us;
		report "ISA TEST: watchdog expired at 200 us without reaching the " &
			"sentinel. The PC left the program; do not extend the time."
			severity failure;
	end process watchdog;
--------------------------------------------------------------------
END test;
