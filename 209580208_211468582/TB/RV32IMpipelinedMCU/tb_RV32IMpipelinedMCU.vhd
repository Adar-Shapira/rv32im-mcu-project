--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — testbench for RV32IMpipelinedMCU
--
-- REFERENCE
--   Auxiliary/Lab 5 - as submitted/TB/RV32IM_pipeline/tb_RV32IM_pipeline.vhd
--   The clock generator, the reset generator and the BPADDR_i constant below are
--   copied from it unchanged, so the pipeline baseline reproduces through this
--   testbench exactly as it does through the reference one. Only the DUT differs:
--   the MCU wrapper instead of the bare core.
--
-- REWRITTEN 2026-08-23
--   The previous version of this file was written against the older pipeline
--   core, which exposed stall_o, flush_o, BPTRIGGER_o, 8-bit counters and a
--   single pc_o/instruction_o pair. The revised core replaced all of that with
--   the Figure 8 interface. See DUT/RV32IMpipelinedMCU/RV32IMpipelinedMCU.vhd
--   for the full list of what changed.
--
-- THREE GENERIC OVERRIDES, AND WHY
--   1. RST_ACTIVE_LOW => FALSE. The MCU top defaults to TRUE because on the
--      DE2-115 the reset pin is KEY0, which is active-low. The reference reset
--      stimulus (rst_i <= '1','0' after 80 ns) is already active-high, and it is
--      preserved verbatim above, so the wrapper must not invert it.
--   2. GEN_DEBUG_PORTS => TRUE, so the observation ports carry real values in
--      the wave window rather than the tied-off zeros a performance revision
--      would show.
--   3. STCNT_WIDTH / FHCNT_WIDTH => 16. These are 16 bits in the revised core
--      too, so this is no longer an override that changes anything — it is kept
--      explicit because test3 and test4 exceed 255 flushes and a reader needs to
--      see that the width is deliberate.
--
-- NOTE ON MODELSIM
--   MODELSIM is a generic here, defaulting to the package constant. Override it
--   from the .do script with  vsim -gMODELSIM=1  — no source edit is ever
--   needed to move between simulation and synthesis.
--
-- NO AUTO-STOP PROCESS
--   The reference testbench has none, and a pipeline must not halt merely
--   because the self-jump appears in a decode stage: it may have been fetched
--   speculatively and then flushed. The correct stop condition is a MEM-stage
--   flush whose redirect target is the redirecting instruction's own PC, which
--   is a property of internal signals and belongs in the .do script that can
--   watch them. See SIM/RV32IMpipelinedMCU/run_test.do.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_RV32IMpipelinedMCU IS
	generic(
		WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
		MODELSIM 			: integer 	:= G_MODELSIM;
		DATA_BUS_WIDTH 		: integer 	:= 32;
		ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		PC_WIDTH 			: integer 	:= G_PC_WIDTH;
		MA_WIDTH 			: integer 	:= G_MA_WIDTH;
		DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH 		: integer 	:= 16;
		STCNT_WIDTH 		: integer 	:= 16;
		FHCNT_WIDTH 		: integer 	:= 16;
		BP_ADDR_WIDTH 		: integer 	:= 8
	);
END tb_RV32IMpipelinedMCU;


ARCHITECTURE struct OF tb_RV32IMpipelinedMCU IS
	--Inputs
	SIGNAL rst_i		 			: STD_LOGIC;
	SIGNAL clk_i					: STD_LOGIC;
	SIGNAL BPADDR_i					: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);

	-- Figure 8 outputs. The five PC/instruction pairs describe five DIFFERENT
	-- instructions in the same cycle — that is the point of them.
	SIGNAL CLKCNT_o					: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL IFpc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL IFinstruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL IDpc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL IDinstruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL EXpc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL EXinstruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL MEMpc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL MEMinstruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL WBpc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL WBinstruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL STRIGGER_o				: STD_LOGIC;
	SIGNAL FHCNT_o					: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);
	SIGNAL STCNT_o					: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);

BEGIN
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is already active-high
		GEN_DEBUG_PORTS		=> TRUE,
		WORD_GRANULARITY 	=> WORD_GRANULARITY,
		MODELSIM 			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH,
		STCNT_WIDTH			=> STCNT_WIDTH,
		FHCNT_WIDTH			=> FHCNT_WIDTH,
		BP_ADDR_WIDTH		=> BP_ADDR_WIDTH
	)
	PORT MAP (
		--Inputs
		clk_i           	=> clk_i,
		rst_i           	=> rst_i,
		BPADDR_i			=> BPADDR_i,			-- breakpoint word address (SW7-SW0 on the FPGA)

		-- Figure 8 outputs
		IFpc_o				=> IFpc_o,
		IFinstruction_o		=> IFinstruction_o,
		IDpc_o				=> IDpc_o,
		IDinstruction_o		=> IDinstruction_o,
		EXpc_o				=> EXpc_o,
		EXinstruction_o		=> EXinstruction_o,
		MEMpc_o				=> MEMpc_o,
		MEMinstruction_o	=> MEMinstruction_o,
		WBpc_o				=> WBpc_o,
		WBinstruction_o		=> WBinstruction_o,
		STRIGGER_o			=> STRIGGER_o,
		CLKCNT_o			=> CLKCNT_o,
		STCNT_o				=> STCNT_o,
		FHCNT_o				=> FHCNT_o
	);
--------------------------------------------------------------------
	gen_clk : -- MCLK cycle = 100nsec = 0.1usec
	process
  begin
		clk_i <= '1';
		wait for 50 ns;
		clk_i <= not clk_i;
		wait for 50 ns;
  end process;

	gen_rst :
	process
  begin
		rst_i <='1','0' after 80 ns;
		wait;
  end process;

	-- breakpoint word address (emulates SW7-SW0): 0x04 = byte PC 0x10, the
	-- 5th instruction - STRIGGER_o must pulse once the IF PC reaches it
	BPADDR_i	<=	CONV_STD_LOGIC_VECTOR(4, BP_ADDR_WIDTH);
--------------------------------------------------------------------
END struct;
