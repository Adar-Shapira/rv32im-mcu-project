--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — RV32IM-based MCU, single-cycle
--
-- RV32IMscMCU — board-facing structural top level.
--
-- WHY THIS LEVEL EXISTS
--   Assignment definition §3: "The top level and the RV32IM core must be
--   structural" — two structural levels, not one. This is the outer one. The
--   MCU block of Figure 1 (p3) lives here: clock tree, RISC-V core, bus
--   interface logic and peripherals. The core itself stays a pure CPU.
--
--   Reference for the pattern: Auxilary/Lab4/DUT/fpga_hw_interface.vhd, the
--   board-level structural top of Lab 4, which conditions its KEY/SW inputs
--   and instantiates the PLL above the logic it drives.
--
-- WHY RESET POLARITY IS HANDLED HERE AND NOT IN THE CORE
--   KEY0 on the DE2-115 is active-low (idle='1', pressed='0') and §3 mandates
--   KEY0 as the system reset, so an inversion is needed somewhere. It belongs
--   at the board boundary, exactly as Lab 4 does it, for two reasons:
--     1. Everything below stays polarity-agnostic and matches the supplied
--        baseline Auxilary/DUT/RV32I_CORE.vhd, which wires rst_i straight to
--        every submodule.
--     2. It must not be tied to MODELSIM. MODELSIM selects PLL bypass; giving
--        it a second, unrelated job means forgetting to set it stops inverting
--        the clock source AND starts inverting the reset, and the core never
--        leaves reset. RST_ACTIVE_LOW below is an independent generic.
--
-- PHASE 1 SCOPE
--   Deliberately thin. It instantiates the existing RV32IM_CORE and conditions
--   reset. The clock tree (mclk/smclk/accelclk per Figure 1), the bus interface
--   with the MMIO decoder (Figure 5), and the GPIO / Basic Timer / interrupt
--   controller / divider / USART peripherals attach here in later phases. Until
--   they do, the core keeps its own internal PLL and DTCM and this wrapper must
--   be behaviourally transparent — the Lab 5 baseline cycle counts
--   (134 / 1514 / 2725 / 2735) must reproduce through it unchanged. That is the
--   Phase 1 exit criterion.
--
-- SIGNAL-TAP PORTS
--   §7: "Location pins used for the validation phase (Signal-Tap) need to be
--   removed in the final step using a suitable parameter in the generate VHDL
--   statement." VHDL cannot conditionally declare a port, so the observation
--   ports always exist and the GEN_DEBUG_PORTS generate decides whether they
--   are driven from the core or tied off. Tied off, synthesis prunes the paths
--   and the .qsf carries no location assignment for them, which is what the
--   clause asks for.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY RV32IMscMCU IS
	generic(
		-- Board-boundary conditioning. TRUE  = rst_i comes from KEY0 (active-low).
		--                             FALSE = rst_i is already active-high, as the
		--                                     supplied testbench drives it.
		RST_ACTIVE_LOW		: boolean	:= TRUE;
		-- FALSE ties the observation ports off so no Signal-Tap pin is assigned (§7).
		GEN_DEBUG_PORTS		: boolean	:= TRUE;

		-- Passed through to the core unchanged.
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
	PORT(
		--=== Board pins ===
		clk_i				:IN		STD_LOGIC;		-- CLOCK_50, PIN_Y2
		rst_i				:IN		STD_LOGIC;		-- KEY0,     PIN_M23

		--=== Observation ports — Signal-Tap only, gated by GEN_DEBUG_PORTS ===
		pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		RegWrite_ctrl_o		:OUT	STD_LOGIC;
		MemWrite_ctrl_o		:OUT	STD_LOGIC;
		Branch_ctrl_o		:OUT	STD_LOGIC;

		read_data1_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		write_data_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		alu_res_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		brTaken_o			:OUT	STD_LOGIC;

		dtcm_addr_o			:OUT	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
		dtcm_data_wr_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		dtcm_data_rd_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
	);
END RV32IMscMCU;
--============================================================================
ARCHITECTURE structure OF RV32IMscMCU IS

	-- Internal active-high reset presented to everything below this level.
	SIGNAL rst_w				: STD_LOGIC;

	-- Core observation taps, exported or tied off by the GEN_DEBUG_PORTS generate.
	SIGNAL pc_w					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL RegWrite_ctrl_w		: STD_LOGIC;
	SIGNAL MemWrite_ctrl_w		: STD_LOGIC;
	SIGNAL Branch_ctrl_w		: STD_LOGIC;
	SIGNAL read_data1_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_w			: STD_LOGIC;
	SIGNAL dtcm_addr_w			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_cnt_w			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

BEGIN
	--=======================================
	-- Reset conditioning at the board boundary
	--=======================================
	-- Independent of MODELSIM by design. See the header.
	RSTCOND:
	if (RST_ACTIVE_LOW) generate
		rst_w	<= not rst_i;
	else generate
		rst_w	<= rst_i;
	end generate;

	--=======================================
	-- RV32IM core
	--=======================================
	-- Phase 1: the core still contains its own PLL and DTCM. The clock tree and
	-- the bus interface move up to this level in Phases 4 and 5, at which point
	-- clk_i feeds CLKTREE and the core receives mclk instead.
	CORE : RV32IM_CORE
	generic map(
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
		rst_i				=> rst_w,
		clk_i				=> clk_i,

		--Outputs
		pc_o				=> pc_w,
		instruction_o		=> instruction_w,

		RegWrite_ctrl_o		=> RegWrite_ctrl_w,
		MemWrite_ctrl_o		=> MemWrite_ctrl_w,
		Branch_ctrl_o		=> Branch_ctrl_w,

		read_data1_o		=> read_data1_w,
		read_data2_o		=> read_data2_w,
		write_data_o		=> write_data_w,

		alu_res_o			=> alu_res_w,
		brTaken_o			=> brTaken_w,

		dtcm_addr_o			=> dtcm_addr_w,
		dtcm_data_wr_o		=> dtcm_data_wr_w,
		dtcm_data_rd_o		=> dtcm_data_rd_w,

		mclk_cnt_o			=> mclk_cnt_w
	);

	--=======================================
	-- Observation ports (§7)
	--=======================================
	DBGPORTS:
	if (GEN_DEBUG_PORTS) generate
		pc_o				<= pc_w;
		instruction_o		<= instruction_w;
		RegWrite_ctrl_o		<= RegWrite_ctrl_w;
		MemWrite_ctrl_o		<= MemWrite_ctrl_w;
		Branch_ctrl_o		<= Branch_ctrl_w;
		read_data1_o		<= read_data1_w;
		read_data2_o		<= read_data2_w;
		write_data_o		<= write_data_w;
		alu_res_o			<= alu_res_w;
		brTaken_o			<= brTaken_w;
		dtcm_addr_o			<= dtcm_addr_w;
		dtcm_data_wr_o		<= dtcm_data_wr_w;
		dtcm_data_rd_o		<= dtcm_data_rd_w;
		mclk_cnt_o			<= mclk_cnt_w;
	else generate
		pc_o				<= (others => '0');
		instruction_o		<= (others => '0');
		RegWrite_ctrl_o		<= '0';
		MemWrite_ctrl_o		<= '0';
		Branch_ctrl_o		<= '0';
		read_data1_o		<= (others => '0');
		read_data2_o		<= (others => '0');
		write_data_o		<= (others => '0');
		alu_res_o			<= (others => '0');
		brTaken_o			<= '0';
		dtcm_addr_o			<= (others => '0');
		dtcm_data_wr_o		<= (others => '0');
		dtcm_data_rd_o		<= (others => '0');
		mclk_cnt_o			<= (others => '0');
	end generate;

END structure;
