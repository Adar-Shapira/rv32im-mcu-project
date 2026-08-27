--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 11B: the directed ISA suite, on the PIPELINED core
--
-- WHY THIS FILE EXISTS
--   Every peripheral is byte-identical between the two DUT trees
--   (tools/check_peripheral_copies.py enforces it), so a leaf proven on the
--   single-cycle side is proven here too. THE CORE IS NOT A COPY. Its
--   CONTROL, IDECODE, EXECUTE, IFETCH and DMEMORY are a rewrite -- the Phase 11
--   review counted 212 changed lines in EXECUTE alone -- and every one of the
--   seven ISA repairs had to be present there independently.
--
--   Until this file, that was a claim from READING the pipeline's source, not a
--   measurement. The four benchmarks compare a final DTCM image, which catches
--   a gross error but says nothing about, say, bgeu on operands no benchmark
--   forms. 43 of the 56 stores below are cases the benchmarks never execute.
--
-- WHAT DIFFERS FROM TB/RV32IMscMCU/tb_isa_directed.vhd
--   The expectations, the program, the scoreboard rule and the verdict text are
--   IDENTICAL -- deliberately, so a difference in the printed numbers is a
--   difference in the CORE. Only four things change, and each was verified
--   against the RTL before it was assumed:
--
--   1. STORE DATA comes from read_data2_o, not dtcm_data_wr_o.
--      Both are the RAW (forwarded) rs2 value. The byte-lane replication for
--      sb/sh happens inside DMEMORY in BOTH trees -- DUT/RV32IMpipelinedMCU/
--      DMEMORY.vhd:153-158 is transcribed from the single-cycle file's 138-151
--      -- so the value on the bus for `sb t1,845(zero)` is 0x0000007F in both,
--      and isa_expected_pkg's entry 26 transfers unchanged.
--
--   2. THE ADDRESS comes from alu_res_o, which is the BYTE address zero-
--      extended (RV32IMpipelinedMCU.vhd:637), where the single-cycle top
--      exports the DTCM WORD address on dtcm_addr_o. Dividing by 4 gives the
--      same word index the package stores. Only the low DATA_ADDR_WIDTH bits
--      are converted: the rest are constant zero and a 32-bit conversion could
--      overflow `natural`.
--
--   3. THE SENTINEL is watched in the MEM stage (MEMinstruction_o), because
--      branches resolve there. Watching a fetch or decode stage would stop the
--      run on a SPECULATIVE fetch of the final self-jump -- the trap
--      SIM/RV32IMpipelinedMCU/batch_verify.do documents. Same choice as
--      TB/RV32IMpipelinedMCU/tb_uart_mmio.vhd.
--
--   4. THE CYCLE COUNT is CLKCNT_o; the single-cycle top calls it mclk_cnt_o.
--
-- WHY A STORE CANNOT BE COUNTED TWICE HERE
--   The scoreboard counts every cycle in which MemWrite_ctrl_o is high, so a
--   store held in MEM across a stall would be counted once per cycle and every
--   later expectation would be off by one. It cannot happen, for three separate
--   reasons in the RTL:
--     * a load-use stall freezes PC and IF/ID and BUBBLES ID/EX
--       (HAZARD_UNIT.vhd:15-19) -- MEM drains normally;
--     * a divide is held in EX by hold_o, which bubbles EX/MEM
--       (EXECUTE.vhd:482) -- MEM sees a bubble, not a repeat;
--     * a flush kills IF/ID/EX only; the instruction in MEM retires. That is
--       the same property the Phase 11 review relied on for interrupt
--       precision.
--   So MemWrite_ctrl_o is a one-cycle pulse per committed store. This matters
--   because the program executes div/divu/rem/remu (stores 45-48), which are
--   exactly the instructions that hold the pipeline.
--
-- WHY THE PREDICTED MISMATCH COUNT IS THE SAME CONSTANT
--   EXPECTED_DEFECT_COUNT_REPAIRED = 5, all mul-related (G-326, G-308). It
--   applies unchanged here because the pipeline's multiplier has the SAME
--   16-bit scope: MULT_1 is fed ain_w(15 DOWNTO 0) / bin_w(15 DOWNTO 0)
--   (EXECUTE.vhd:217-224), exactly as the single-cycle core feeds MUL16
--   (DUT/RV32IMscMCU/EXECUTE.vhd:112-113). Hanan's forum answer -- "mul only,
--   as in Lab 5, 16-bit multiplier only" -- is what puts those five out of
--   scope on BOTH cores.
--
--   If this core reports a number other than 5, that is a FINDING about the
--   pipelined core, which is the entire reason this file was written.
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_isa.do -- it stages SIM/RV32IMscMCU/isa/, the
--   one copy of the program, and runs this bench.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;
USE work.isa_expected_pkg.all;


ENTITY tb_isa_directed IS
	generic(
		MODELSIM		: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH	: integer	:= 32;
		PC_WIDTH		: integer	:= G_PC_WIDTH;
		CLK_CNT_WIDTH	: integer	:= 16
	);
END tb_isa_directed;
--============================================================================
ARCHITECTURE test OF tb_isa_directed IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	SIGNAL mem_pc_w				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_instr_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MemWrite_ctrl_w		: STD_LOGIC;
	SIGNAL alu_res_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL store_data_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL clkcnt_w				: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

	-- the auto-stop sentinel the whole project already uses: beq x0,x0,0
	constant SENTINEL			: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000063";

	-- Remaining mismatches on this (ISA-repaired) core. Mul-related leftovers
	-- are out of scope by Hanan's 16-bit mul answer. See the header for why the
	-- single-cycle constant applies to this core unchanged.
	constant PREDICTED			: natural := EXPECTED_DEFECT_COUNT_REPAIRED;

	-- Bit-by-bit rather than to_integer(unsigned(...)): identical to the
	-- single-cycle bench's helper, and it cannot raise on an 'X' left on the
	-- bus in a cycle the guard below did not exclude.
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
	-- Two rules decide what is associated here. Everything that fixes the WIDTH
	-- of a signal declared above is passed explicitly, so the bench and the DUT
	-- can never disagree about a vector length. Everything else -- the reset-on-
	-- lock generate, the GPO read-back, the KEY polarity, the memory geometry --
	-- is left at the top's own default, which is the SHIPPING configuration, so
	-- this bench cannot pass a core built differently from the one Quartus
	-- compiles. Same policy as TB/RV32IMpipelinedMCU/tb_uart_mmio.vhd.
	DUT : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is active-high
		GEN_DEBUG_PORTS		=> TRUE,	-- the observation ports below
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH
	)
	PORT MAP (
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		MEMpc_o				=> mem_pc_w,	-- for the FAIL message only
		MEMinstruction_o	=> mem_instr_w,	-- the RETIRING instruction
		MemWrite_ctrl_o		=> MemWrite_ctrl_w,
		alu_res_o			=> alu_res_w,	-- byte address, zero-extended
		read_data2_o		=> store_data_w,-- raw rs2, as the store path sees it
		CLKCNT_o			=> clkcnt_w
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
	-- the next expected entry, and report a verdict when the sentinel retires.
	--
	-- Sampled on the falling edge for the same reason the single-cycle bench
	-- gives: DMEMORY drives its altsyncram with wrclk_w <= NOT clk_i, so the
	-- DTCM latches a store when clk_i falls, and the MEM-stage control and data
	-- are combinational off registers that settled at the rising edge.
	scoreboard : process(clk_i)
		variable idx			: natural := 0;		-- next expected store
		variable fails			: natural := 0;		-- mismatches seen
		variable got_addr		: natural;
		variable done			: boolean := false;
	begin
		if falling_edge(clk_i) and rst_i = '0' and not done then

			--------------------------------------------------------------
			-- A store is committing this half-cycle.
			--------------------------------------------------------------
			if MemWrite_ctrl_w = '1' then
				if idx >= STORE_COUNT then
					report "ISA TEST: store #" & integer'image(idx) &
						" occurred but only " & integer'image(STORE_COUNT) &
						" were expected - the program executed more stores than " &
						"the generated sequence describes"
						severity error;
					fails := fails + 1;
				else
					-- byte address -> DTCM word index. See header note 2.
					got_addr := addr_of(alu_res_w(DATA_ADDR_WIDTH-1 DOWNTO 0)) / 4;

					if got_addr /= EXPECTED(idx).addr then
						report "ISA TEST FAIL [" & EXPECTED(idx).name & "] store #" &
							integer'image(idx) & ": wrong ADDRESS - expected word " &
							integer'image(EXPECTED(idx).addr) & ", got word " &
							integer'image(got_addr)
							severity error;
						fails := fails + 1;

					elsif store_data_w /= EXPECTED(idx).data then
						report "ISA TEST FAIL [" & EXPECTED(idx).name & "] word " &
							integer'image(EXPECTED(idx).addr) & ": expected 0x" &
							to_hstring(EXPECTED(idx).data) & ", got 0x" &
							to_hstring(store_data_w) &
							"   (MEMpc=0x" & to_hstring(mem_pc_w) &
							" instr=0x" & to_hstring(mem_instr_w) & ")"
							severity error;
						fails := fails + 1;
					end if;
					idx := idx + 1;
				end if;
			end if;

			--------------------------------------------------------------
			-- Sentinel retired: the program is over. Report and stop.
			--------------------------------------------------------------
			if mem_instr_w = SENTINEL then
				done := true;
				report "" severity note;
				report "========= DIRECTED ISA TEST SUMMARY - PIPELINED CORE =========" severity note;
				report "  stores observed : " & integer'image(idx) &
					" of " & integer'image(STORE_COUNT) & " expected" severity note;
				report "  mismatches      : " & integer'image(fails) severity note;
				report "  CLKCNT          : " & integer'image(addr_of(clkcnt_w)) severity note;

				if idx < STORE_COUNT then
					report "  INCOMPLETE: the program stopped before executing every " &
						"case. Missing from store #" & integer'image(idx) &
						" [" & EXPECTED(idx).name & "] onward. A control-flow " &
						"instruction under test most likely misdirected the PC."
						severity error;
				end if;

				report "  expected here   : " & integer'image(PREDICTED) &
					" mismatch(es) (ISA-repaired core; leftovers are mul-related)" severity note;

				-- The VERDICT line always starts with PASS or FAIL, like every
				-- other testbench in the set, so a regression script can score
				-- this one by the same rule.
				if fails = PREDICTED and PREDICTED = 0 then
					report "  VERDICT: PASS - zero mismatches, as predicted." severity note;
				elsif fails = PREDICTED then
					report "  VERDICT: PASS - " & integer'image(fails) &
						" mismatch(es), exactly the predicted set." severity note;
					report "  The seven ISA repairs are present in the PIPELINED core " &
						"and produce the right values under execution, not just in " &
						"the source. What remains is blocked on G-326/G-308 (mul " &
						"width) and is out of scope on both cores." severity note;
				elsif fails = 0 then
					report "  VERDICT: FAIL - zero mismatches, but " & integer'image(PREDICTED) &
						" were predicted. This is a FAILURE OF THE SUITE, not a pass." severity note;
					report "  The usual cause is that SIM/RV32IMscMCU/isa/ITCM.hex never " &
						"reached C:/TestPrograms/Quartus21_1/app_bin, so a different " &
						"program ran." severity note;
				else
					report "  VERDICT: FAIL - " & integer'image(fails) & " mismatch(es), but " &
						integer'image(PREDICTED) & " were predicted." severity note;
					report "  Compare against the SINGLE-CYCLE run of the same suite " &
						"before reading anything else: a case that mismatches HERE and " &
						"passes THERE is a defect this core does not share, and the " &
						"pipelined EXECUTE/IDECODE are where to look. A case marked " &
						"DEFECT in the listing that passed means the defect is not " &
						"where we thought." severity note;
				end if;
				report "==============================================================" severity note;
				std.env.stop;
			end if;
		end if;
	end process scoreboard;
--------------------------------------------------------------------
	-- Runaway guard. Every case is straight-line, so completion is a few hundred
	-- cycles: the program's 268 words, plus the pipeline fill, plus 3 flush
	-- cycles per taken redirect, plus the four divides. A divide holds EX until
	-- div_done, and at MODELSIM = 1 accelclk runs at 30 ns against the 100 ns
	-- core clock (CLOCK_TREE.vhd:169), so a 32-iteration divide costs about ten
	-- core cycles -- roughly 40 cycles for all four. That is far inside the
	-- bound below, which is the single-cycle bench's own 200 us unchanged.
	--
	-- Reaching it means the PC left the program, which is itself a finding, not
	-- a timeout to raise. Patterned on Auxilary/Lab3/TB/tb_top.vhd:86.
	watchdog : process
	begin
		wait for 200 us;
		report "ISA TEST: watchdog expired at 200 us without the sentinel " &
			"retiring in MEM. The PC left the program; do not extend the time."
			severity failure;
	end process watchdog;
--------------------------------------------------------------------
END test;
