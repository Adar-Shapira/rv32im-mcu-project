--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — RV32IM-based MCU, five-stage pipeline (bonus 10%)
--
-- RV32IMpipelinedMCU — board-facing structural top level.
--
-- Same rationale as RV32IMscMCU: Assignment definition §3 requires two
-- structural levels, board-level signal conditioning belongs at the boundary
-- and not inside the CPU, and §7 requires the Signal-Tap pins to be removable
-- through a generate parameter. See DUT/RV32IMscMCU/RV32IMscMCU.vhd for the
-- full reasoning; only the differences are noted here.
--
-- DIFFERENCES FROM THE SINGLE-CYCLE WRAPPER
--   The pipeline core carries the LAB5 clause 6.iii validation instrumentation:
--   BPADDR_i in, and BPTRIGGER_o / CLKCNT_o / STCNT_o / FHCNT_o out. These feed
--   the Signal-Tap trigger and the IPC equation
--       IPC = (CLKCNT_o - (STCNT_o + 4 + depth*FHCNT_o)) / CLKCNT_o
--   with depth = 3, because branches and jumps resolve in stage 4.
--
--   BPADDR_i is a board input (SW7-SW0) used only during validation, so
--   GEN_DEBUG_PORTS also gates it: tied to zero in a performance revision so no
--   pin is assigned, driven from the port in a hardware revision.
--
-- PHASE 1 SCOPE
--   Thin, as on the single-cycle side. The core keeps its own PLL and DTCM; the
--   clock tree, bus interface and peripherals attach in later phases. The
--   wrapper must be behaviourally transparent so the pipeline baseline
--   reproduces through it unchanged.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY RV32IMpipelinedMCU IS
	generic(
		RST_ACTIVE_LOW		: boolean	:= TRUE;	-- TRUE = rst_i is KEY0 (active-low)
		GEN_DEBUG_PORTS		: boolean	:= TRUE;	-- FALSE ties off the Signal-Tap ports (§7)

		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		STCNT_WIDTH			: integer	:= 8;
		FHCNT_WIDTH			: integer	:= 8;
		BP_ADDR_WIDTH		: integer	:= 8
	);
	PORT(
		--=== Board pins ===
		clk_i				:IN		STD_LOGIC;		-- CLOCK_50, PIN_Y2
		rst_i				:IN		STD_LOGIC;		-- KEY0,     PIN_M23
		BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);	-- SW7-SW0, validation only

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

		stall_o				:OUT	STD_LOGIC;
		flush_o				:OUT	STD_LOGIC;
		BPTRIGGER_o			:OUT	STD_LOGIC;

		CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
		STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
		FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0)
	);
END RV32IMpipelinedMCU;
--============================================================================
ARCHITECTURE structure OF RV32IMpipelinedMCU IS

	SIGNAL rst_w				: STD_LOGIC;
	SIGNAL bpaddr_w				: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);

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
	SIGNAL stall_w				: STD_LOGIC;
	SIGNAL flush_w				: STD_LOGIC;
	SIGNAL BPTRIGGER_w			: STD_LOGIC;
	SIGNAL CLKCNT_w				: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL STCNT_w				: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
	SIGNAL FHCNT_w				: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);

BEGIN
	--=======================================
	-- Reset conditioning at the board boundary
	--=======================================
	RSTCOND:
	if (RST_ACTIVE_LOW) generate
		rst_w	<= not rst_i;
	else generate
		rst_w	<= rst_i;
	end generate;

	--=======================================
	-- Breakpoint address — validation only
	--=======================================
	BPIN:
	if (GEN_DEBUG_PORTS) generate
		bpaddr_w	<= BPADDR_i;
	else generate
		bpaddr_w	<= (others => '0');
	end generate;

	--=======================================
	-- RV32IM pipelined core
	--=======================================
	CORE : RV32IM_PIPE_CORE
	generic map(
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
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
		rst_i				=> rst_w,
		clk_i				=> clk_i,
		BPADDR_i			=> bpaddr_w,

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

		stall_o				=> stall_w,
		flush_o				=> flush_w,
		BPTRIGGER_o			=> BPTRIGGER_w,

		CLKCNT_o			=> CLKCNT_w,
		STCNT_o				=> STCNT_w,
		FHCNT_o				=> FHCNT_w
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
		stall_o				<= stall_w;
		flush_o				<= flush_w;
		BPTRIGGER_o			<= BPTRIGGER_w;
		CLKCNT_o			<= CLKCNT_w;
		STCNT_o				<= STCNT_w;
		FHCNT_o				<= FHCNT_w;
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
		stall_o				<= '0';
		flush_o				<= '0';
		BPTRIGGER_o			<= '0';
		CLKCNT_o			<= (others => '0');
		STCNT_o				<= (others => '0');
		FHCNT_o				<= (others => '0');
	end generate;

END structure;
