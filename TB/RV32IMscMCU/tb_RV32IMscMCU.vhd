--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — testbench for the single-cycle RV32IM MCU
--
-- Filename and entity name are mandated by the submission table (§10):
-- TB/RV32IMscMCU/tb_RV32IMscMCU.vhd.
--
-- REFERENCE
--   Auxiliary/Lab 5/TB/RV32IM_sc/tb_RV32IM_sc.vhd, itself based
--   on Hanan's Auxilary/TB/tb_RV32I.vhd.
--
-- CHANGES FROM THE REFERENCE, AND WHY EACH ONE IS NECESSARY
--   1. Drives RV32IMscMCU instead of RV32IM_CORE — the MCU top is what the
--      project delivers, and §3 requires that outer structural level.
--   2. RST_ACTIVE_LOW => FALSE. The MCU top defaults to TRUE because on the
--      board rst_i is KEY0, which is active-low. The supplied stimulus below
--      drives rst_i active-high ('1' then '0' after 80 ns) and is kept
--      byte-for-byte so the Lab 5 baseline reproduces; passing FALSE tells the
--      wrapper not to invert it. Nothing about the reset waveform changed.
--   3. GEN_DEBUG_PORTS => TRUE, so the observation ports carry real values in
--      simulation. Quartus performance revisions pass FALSE (§7).
--
--   Everything else — the 100 ns clock, the reset waveform, the generic list
--   and the auto-stop process — is unchanged from the reference. The Phase 1
--   exit criterion is that this testbench still yields mclk_cnt_o =
--   134 / 1514 / 2725 / 2735 for Lab 5 test1..test4.
--
-- NOTE ON MODELSIM
--   MODELSIM is a generic here, defaulting to the package constant. Override it
--   from the .do script with  vsim -gMODELSIM=1  — no source edit is ever
--   needed to switch between simulation and synthesis.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_RV32IMscMCU IS
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
END tb_RV32IMscMCU;
--============================================================================
ARCHITECTURE struct OF tb_RV32IMscMCU IS
	--Inputs
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	--Outputs (Verification and Signal-Tap validation)
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

BEGIN
	MCU : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is already active-high
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
		--Inputs
		clk_i				=> clk_i,
		rst_i				=> rst_i,

		--Outputs
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
--------------------------------------------------------------------
	-- Auto-stop, carried forward from repo commit c1e9e64. Every Lab 5
	-- benchmark ends in an unconditional self-jump - beq x0,x0,0 (0x00000063,
	-- man_compiled) or jal x0,0 (0x0000006F, gcc_compiled) - reached at
	-- instruction_o. Single-cycle write-back completes the same clock, so no
	-- retire delay is needed before stopping.
	monitor_end_of_program : process
	begin
		wait until instruction_o = X"00000063" or instruction_o = X"0000006F";
		report "Program finished (while(1) reached) - stopping simulation" severity note;
		std.env.stop;
	end process monitor_end_of_program;
--------------------------------------------------------------------
END struct;
