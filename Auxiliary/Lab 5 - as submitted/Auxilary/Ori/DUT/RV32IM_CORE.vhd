LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;

ENTITY RV32IM_CORE IS
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
		CNT_WIDTH			: integer	:= 8
	);
	PORT(
		-- Inputs
		rst_i				: in 	std_logic;
		clk_i				: in 	std_logic;
		BPADDR_i			: in 	std_logic_vector(7 downto 0);
		
		-- PC Outputs
		IFpc_o				: out	std_logic_vector(PC_WIDTH-1 downto 0);
		IDpc_o				: out	std_logic_vector(PC_WIDTH-1 downto 0);
		EXpc_o				: out	std_logic_vector(PC_WIDTH-1 downto 0);
		MEMpc_o				: out	std_logic_vector(PC_WIDTH-1 downto 0);
		WBpc_o				: out	std_logic_vector(PC_WIDTH-1 downto 0);
		
		-- Instruction Outputs
		IFinstruction_o		: out	std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
		IDinstruction_o		: out	std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
		EXinstruction_o		: out	std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
		MEMinstruction_o	: out	std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
		WBinstruction_o		: out	std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
		
		-- Counter Outputs
		CLKCNT_o			: out	std_logic_vector(CLK_CNT_WIDTH-1 downto 0);
		FHCNT_o				: out	std_logic_vector(CNT_WIDTH-1 downto 0);	--flush counter
		STCNT_o				: out	std_logic_vector(CNT_WIDTH-1 downto 0); --stall counter
		
		-- SignalTap Trigger 
		STRIGGER_o			: out	std_logic
	);
END RV32IM_CORE;

--------------------------------------------------------------------------------------
architecture structure of RV32IM_CORE is

	--===================================================
	-- SYSTEM & HAZARD SIGNALS
	--===================================================
	SIGNAL rst_w 			: STD_LOGIC; -- Inverted reset for DE-10 hardware
	SIGNAL mclk_w 			: STD_LOGIC;
	
	-- Hazard Unit Wires
	SIGNAL stall_IF_w 		: STD_LOGIC;
	SIGNAL stall_ID_w 		: STD_LOGIC;
	SIGNAL flush_EX_w 		: STD_LOGIC;
	
	-- Forwarding Unit Wires
	SIGNAL forward_A_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL forward_B_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	
	-- Branch Resolution
	SIGNAL flush_branch_w 	: STD_LOGIC;
	SIGNAL fetch_branch_target_w : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);

	-- Counters
	SIGNAL clk_cnt_r		: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL fh_cnt_r			: STD_LOGIC_VECTOR(CNT_WIDTH-1 DOWNTO 0);
	SIGNAL st_cnt_r			: STD_LOGIC_VECTOR(CNT_WIDTH-1 DOWNTO 0);

	--===================================================
	-- STAGE 1: FETCH WIRES
	--===================================================
	SIGNAL if_pc_w			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_pc_plus4_w	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_inst_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	--===================================================
	-- PIPELINE REGISTER 1: IF/ID
	--===================================================
	SIGNAL if_id_pc_r		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_id_pc_plus4_r	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_id_inst_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	--===================================================
	-- STAGE 2: DECODE WIRES
	--===================================================
	SIGNAL id_raw_read_data1_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_raw_read_data2_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_read_data1_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_read_data2_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_SignExt_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_rs1_w			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_rs2_w			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_rd_w			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	
	-- Control Wires
	SIGNAL id_RegDst_w		: STD_LOGIC;
	SIGNAL id_ALUSrc_w		: STD_LOGIC;
	SIGNAL id_MemtoReg_w	: STD_LOGIC;
	SIGNAL id_RegWrite_w	: STD_LOGIC;
	SIGNAL id_MemRead_w		: STD_LOGIC;
	SIGNAL id_MemWrite_w	: STD_LOGIC;
	SIGNAL id_Branch_w		: STD_LOGIC;
	SIGNAL id_Jal_w			: STD_LOGIC;
	SIGNAL id_Jalr_w		: STD_LOGIC;
	SIGNAL id_UpperIm_w		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL id_ALUOp_w		: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_MULOp_w		: STD_LOGIC;

	--===================================================
	-- PIPELINE REGISTER 2: ID/EX
	--===================================================
	SIGNAL id_ex_pc_r			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_pc_plus4_r		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_inst_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_read_data1_r	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_read_data2_r	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_SignExt_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_rs1_r			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_rs2_r			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_rd_r			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	
	-- ID/EX Control
	SIGNAL id_ex_RegDst_r		: STD_LOGIC;
	SIGNAL id_ex_ALUSrc_r		: STD_LOGIC;
	SIGNAL id_ex_MemtoReg_r		: STD_LOGIC;
	SIGNAL id_ex_RegWrite_r		: STD_LOGIC;
	SIGNAL id_ex_MemRead_r		: STD_LOGIC;
	SIGNAL id_ex_MemWrite_r		: STD_LOGIC;
	SIGNAL id_ex_Branch_r		: STD_LOGIC;
	SIGNAL id_ex_Jal_r			: STD_LOGIC;
	SIGNAL id_ex_Jalr_r			: STD_LOGIC;
	SIGNAL id_ex_UpperIm_r		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL id_ex_ALUOp_r		: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_MULOp_r		: STD_LOGIC;

	--===================================================
	-- STAGE 3: EXECUTE WIRES
	--===================================================
	SIGNAL ex_brTaken_w			: STD_LOGIC;
	SIGNAL ex_alu_res_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_addr_gen_w		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_rs2_forwarded_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_P0_w				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_P1_w				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_P2_w				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_P3_w				: STD_LOGIC_VECTOR(15 DOWNTO 0);

	--===================================================
	-- PIPELINE REGISTER 3: EX/MEM
	--===================================================
	SIGNAL ex_mem_pc_r				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_pc_plus4_r		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_inst_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_brTaken_r			: STD_LOGIC;
	SIGNAL ex_mem_alu_res_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_addr_gen_r		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_rs2_forwarded_r	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_rd_r				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ex_mem_P0_r				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_mem_P1_r				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_mem_P2_r				: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL ex_mem_P3_r				: STD_LOGIC_VECTOR(15 DOWNTO 0);

	-- EX/MEM Control
	SIGNAL ex_mem_RegDst_r			: STD_LOGIC;
	SIGNAL ex_mem_MemtoReg_r		: STD_LOGIC;
	SIGNAL ex_mem_RegWrite_r		: STD_LOGIC;
	SIGNAL ex_mem_MemRead_r			: STD_LOGIC;
	SIGNAL ex_mem_MemWrite_r		: STD_LOGIC;
	SIGNAL ex_mem_Branch_r			: STD_LOGIC;
	SIGNAL ex_mem_Jal_r				: STD_LOGIC;
	SIGNAL ex_mem_Jalr_r			: STD_LOGIC;
	SIGNAL ex_mem_MULOp_r			: STD_LOGIC;

	--===================================================
	-- STAGE 4: MEMORY WIRES
	--===================================================
	SIGNAL mem_dtcm_data_rd_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_mul_res_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_dtcm_addr_w		: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL ex_mem_forward_data_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	--===================================================
	-- PIPELINE REGISTER 4: MEM/WB
	--===================================================
	SIGNAL mem_wb_pc_r				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_pc_plus4_r		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_inst_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_alu_res_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_dtcm_data_rd_r	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_mul_res_r			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_rd_r				: STD_LOGIC_VECTOR(4 DOWNTO 0);

	-- MEM/WB Control
	SIGNAL mem_wb_RegDst_r			: STD_LOGIC;
	SIGNAL mem_wb_MemtoReg_r		: STD_LOGIC;
	SIGNAL mem_wb_RegWrite_r		: STD_LOGIC;
	SIGNAL mem_wb_MULOp_r			: STD_LOGIC;

	--===================================================
	-- STAGE 5: WRITEBACK WIRES
	--===================================================
	SIGNAL wb_write_data_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

begin

	--====================================================================================
	-- 0. SYSTEM & PLL CONFIGURATION
	--====================================================================================
	-- Invert active-low KEY0 to active-high for internal core logic
	rst_w <= NOT rst_i;

	-- Stage 4 Branch/Jump resolution: Triggers a pipeline flush if taken
	flush_branch_w <= ex_mem_Jal_r OR ex_mem_Jalr_r OR (ex_mem_Branch_r AND ex_mem_brTaken_r);
	-- JALR MUX
	fetch_branch_target_w <= (ex_mem_alu_res_r(PC_WIDTH-1 DOWNTO 1) & '0') WHEN ex_mem_Jalr_r = '1' ELSE ex_mem_addr_gen_r;
	-- PLL if we use FPGA 
	G0:
	if (MODELSIM = 0) generate
	  MCLK: PLL
		PORT MAP (
			inclk0 	=> clk_i,
			c0 		=> mclk_w
		);
	else generate
		mclk_w <= clk_i;
	end generate;

	--====================================================================================
	-- 1. STAGE INSTANTIATIONS
	--====================================================================================
	
	IFE: Ifetch
	generic map(
		WORD_GRANULARITY 	=> WORD_GRANULARITY, 
		DATA_BUS_WIDTH 		=> DATA_BUS_WIDTH, 
		PC_WIDTH 			=> PC_WIDTH, 
		ITCM_ADDR_WIDTH 	=> ITCM_ADDR_WIDTH, 
		WORDS_NUM 			=> DATA_WORDS_NUM
	)
	PORT MAP (
		clk_i 			=> mclk_w,  
		rst_i 			=> rst_w, 
		ena_i			=> (not stall_IF_w) or flush_branch_w, 
		pc_sel_i		=> flush_branch_w,		
		branch_target_i	=> fetch_branch_target_w,  -- Uses JALR MUX
		
		pc_o 			=> if_pc_w,
		pc_plus4_o	 	=> if_pc_plus4_w,
		instruction_o 	=> if_inst_w    
	);

	ID: Idecode
	generic map(
		PC_WIDTH 		=> PC_WIDTH, 
		DATA_BUS_WIDTH 	=> DATA_BUS_WIDTH
	)
	PORT MAP (	
		clk_i 			=> mclk_w,  
		rst_i 			=> rst_w,
		instruction_i 	=> if_id_inst_r,
		rd_i			=> mem_wb_rd_r,
		write_data_i	=> wb_write_data_w,
		RegWrite_ctrl_i	=> mem_wb_RegWrite_r,
		
		read_data1_o 	=> id_raw_read_data1_w,
		read_data2_o 	=> id_raw_read_data2_w,
		SignExt_o 		=> id_SignExt_w,
		rs1_o			=> id_rs1_w,
		rs2_o			=> id_rs2_w,
		rd_o			=> id_rd_w
	);
	-- Internal Forwarding: Bypass RF to read fresh data if WB writes to the same register
	id_read_data1_w <= wb_write_data_w WHEN (mem_wb_RegWrite_r = '1' AND mem_wb_rd_r /= "00000" AND mem_wb_rd_r = id_rs1_w) ELSE id_raw_read_data1_w;
	id_read_data2_w <= wb_write_data_w WHEN (mem_wb_RegWrite_r = '1' AND mem_wb_rd_r /= "00000" AND mem_wb_rd_r = id_rs2_w) ELSE id_raw_read_data2_w;
	

	CTL: control
	PORT MAP ( 	
		instruction_i 	=> if_id_inst_r,
		
		RegDst_ctrl_o	=> id_RegDst_w,
		ALUSrc_ctrl_o 	=> id_ALUSrc_w,
		MemtoReg_ctrl_o => id_MemtoReg_w,
		RegWrite_ctrl_o => id_RegWrite_w,
		MemRead_ctrl_o 	=> id_MemRead_w,
		MemWrite_ctrl_o => id_MemWrite_w,
		Branch_ctrl_o 	=> id_Branch_w,
		Jal_ctrl_o 		=> id_Jal_w,
		Jalr_ctrl_o		=> id_Jalr_w,
		UpperIm_ctrl_o 	=> id_UpperIm_w,
		ALUOp_ctrl_o 	=> id_ALUOp_w,
		MULOp_ctrl_o	=> id_MULOp_w
	);
	
	HAZARD_UNIT: stall_unit
	PORT MAP (
		id_ex_MemRead_i	=> id_ex_MemRead_r,
		id_ex_rd_i		=> id_ex_rd_r,
		if_id_rs1_i		=> id_rs1_w, 
		if_id_rs2_i		=> id_rs2_w,
		
		stall_IF_o		=> stall_IF_w,
		stall_ID_o		=> stall_ID_w,
		flush_EX_o		=> flush_EX_w
	);

	FWD_UNIT: forwarding_unit
	PORT MAP (
		id_ex_rs1_i			=> id_ex_rs1_r,
		id_ex_rs2_i			=> id_ex_rs2_r,
		
		ex_mem_rd_i			=> ex_mem_rd_r,
		ex_mem_RegWrite_i	=> ex_mem_RegWrite_r,
		
		mem_wb_rd_i			=> mem_wb_rd_r,
		mem_wb_RegWrite_i	=> mem_wb_RegWrite_r,
		
		forward_A_o			=> forward_A_w,
		forward_B_o			=> forward_B_w
	);
	-- Forwarding MUX: Select multiplier result for MUL instructions, else ALU result
	ex_mem_forward_data_w <= mem_mul_res_w WHEN ex_mem_MULOp_r = '1' ELSE ex_mem_alu_res_r;

	EXE: Execute
	generic map(
		DATA_BUS_WIDTH 	=> DATA_BUS_WIDTH, 
		PC_WIDTH 		=> PC_WIDTH
	)
	PORT MAP (	
		read_data1_i 		=> id_ex_read_data1_r,
		read_data2_i 		=> id_ex_read_data2_r,
		sign_extend_i 		=> id_ex_SignExt_r,
		UpperIm_ctrl_i 		=> id_ex_UpperIm_r,
		ALUOp_ctrl_i 		=> id_ex_ALUOp_r,
		ALUSrc_ctrl_i 		=> id_ex_ALUSrc_r,
		pc_i				=> id_ex_pc_r,
		MULOp_ctrl_i		=> id_ex_MULOp_r,
		
		-- Forwarding Control and Data Wires
		forward_A_ctrl_i	=> forward_A_w,
		forward_B_ctrl_i	=> forward_B_w,
		mem_forward_data_i	=> ex_mem_forward_data_w, 
		wb_forward_data_i	=> wb_write_data_w,
		
		brTaken_o 			=> ex_brTaken_w,
		alu_res_o			=> ex_alu_res_w,
		addr_gen_o 			=> ex_addr_gen_w,
		rs2_forwarded_o		=> ex_rs2_forwarded_w,
		
		P0_o 				=> ex_P0_w,
		P1_o 				=> ex_P1_w,
		P2_o 				=> ex_P2_w,
		P3_o 				=> ex_P3_w
	);

	-- Memory Address calculation based on granularity
	G1: if (WORD_GRANULARITY = True) generate
		mem_dtcm_addr_w	<= ex_mem_alu_res_r(MA_WIDTH-1 DOWNTO 2);
	elsif (WORD_GRANULARITY = False) generate 
		mem_dtcm_addr_w	<= ex_mem_alu_res_r(MA_WIDTH-1 DOWNTO 0);
	end generate;
	
	MEM: dmemory
	generic map(
		DATA_BUS_WIDTH => DATA_BUS_WIDTH, 
		DTCM_ADDR_WIDTH => DTCM_ADDR_WIDTH, 
		WORDS_NUM => DATA_WORDS_NUM
	)
	PORT MAP (	
		clk_i 			=> mclk_w,  
		rst_i 			=> rst_w,
		dtcm_addr_i 	=> mem_dtcm_addr_w,
		dtcm_data_wr_i 	=> ex_mem_rs2_forwarded_r,
		MemRead_ctrl_i 	=> ex_mem_MemRead_r, 
		MemWrite_ctrl_i => ex_mem_MemWrite_r,
		
		P0_i			=> ex_mem_P0_r,
		P1_i			=> ex_mem_P1_r,
		P2_i			=> ex_mem_P2_r,
		P3_i			=> ex_mem_P3_r,
				
		dtcm_data_rd_o 	=> mem_dtcm_data_rd_w,
		mul_res_o		=> mem_mul_res_w
	);

	WB: writeback
	generic map(
		DATA_BUS_WIDTH => DATA_BUS_WIDTH, 
		PC_WIDTH => PC_WIDTH
	)
	PORT MAP (
		alu_res_i 		=> mem_wb_alu_res_r,
		dtcm_data_rd_i 	=> mem_wb_dtcm_data_rd_r,
		mul_res_i 		=> mem_wb_mul_res_r,
		pc_plus4_i 		=> mem_wb_pc_plus4_r,
		
		MemtoReg_ctrl_i => mem_wb_MemtoReg_r,
		RegDst_ctrl_i 	=> mem_wb_RegDst_r,
		MULOp_ctrl_i 	=> mem_wb_MULOp_r,
		
		write_data_o 	=> wb_write_data_w
	);

	--====================================================================================
	-- 2. PIPELINE REGISTERS (Synchronous Processes)
	--====================================================================================

	-- Pipeline Register 1: IF/ID
	PROCESS (mclk_w)
	BEGIN
		IF rising_edge(mclk_w) THEN
			IF (rst_w = '1' OR flush_branch_w = '1') THEN
				if_id_pc_r			<= (others => '0');
				if_id_pc_plus4_r	<= (others => '0');
				if_id_inst_r		<= (others => '0');
			ELSIF (stall_ID_w = '0') THEN
				if_id_pc_r			<= if_pc_w;
				if_id_pc_plus4_r	<= if_pc_plus4_w;
				if_id_inst_r		<= if_inst_w;
			END IF;
		END IF;
	END PROCESS;

	-- Pipeline Register 2: ID/EX
	PROCESS (mclk_w)
	BEGIN
		IF rising_edge(mclk_w) THEN
			IF (rst_w = '1' OR flush_branch_w = '1' OR flush_EX_w = '1') THEN
				-- Clear Control Signals to prevent structural writes
				id_ex_RegWrite_r 	<= '0';
				id_ex_MemWrite_r 	<= '0';
				id_ex_MemRead_r		<= '0';
				id_ex_Branch_r	 	<= '0';
				id_ex_Jal_r			<= '0';
				id_ex_Jalr_r		<= '0';
				id_ex_MULOp_r		<= '0';
				id_ex_inst_r		<= (others => '0');
				id_ex_rs1_r         <= "00000";
				id_ex_rs2_r         <= "00000";
				id_ex_rd_r          <= "00000";
			ELSE
				-- Pass Controls
				id_ex_RegDst_r		<= id_RegDst_w;
				id_ex_ALUSrc_r		<= id_ALUSrc_w;
				id_ex_MemtoReg_r	<= id_MemtoReg_w;
				id_ex_RegWrite_r	<= id_RegWrite_w;
				id_ex_MemRead_r		<= id_MemRead_w;
				id_ex_MemWrite_r	<= id_MemWrite_w;
				id_ex_Branch_r		<= id_Branch_w;
				id_ex_Jal_r			<= id_Jal_w;
				id_ex_Jalr_r		<= id_Jalr_w;
				id_ex_UpperIm_r		<= id_UpperIm_w;
				id_ex_ALUOp_r		<= id_ALUOp_w;
				id_ex_MULOp_r		<= id_MULOp_w;
				-- Pass Data
				id_ex_pc_r			<= if_id_pc_r;
				id_ex_pc_plus4_r	<= if_id_pc_plus4_r;
				id_ex_inst_r		<= if_id_inst_r;
				id_ex_read_data1_r	<= id_read_data1_w;
				id_ex_read_data2_r	<= id_read_data2_w;
				id_ex_SignExt_r		<= id_SignExt_w;
				id_ex_rs1_r			<= id_rs1_w;
				id_ex_rs2_r			<= id_rs2_w;
				id_ex_rd_r			<= id_rd_w;
			END IF;
		END IF;
	END PROCESS;

	-- Pipeline Register 3: EX/MEM
	PROCESS (mclk_w)
	BEGIN
		IF rising_edge(mclk_w) THEN
			IF (rst_w = '1' or flush_branch_w = '1') THEN
				ex_mem_RegWrite_r 	<= '0';
				ex_mem_MemWrite_r 	<= '0';
				ex_mem_Branch_r	 	<= '0';
				ex_mem_Jal_r		<= '0';
				ex_mem_Jalr_r		<= '0';
				ex_mem_MULOp_r		<= '0';
				ex_mem_brTaken_r	<= '0';
				ex_mem_inst_r		<= (others => '0');
			ELSE
				-- Pass Controls
				ex_mem_RegDst_r		<= id_ex_RegDst_r;
				ex_mem_MemtoReg_r	<= id_ex_MemtoReg_r;
				ex_mem_RegWrite_r	<= id_ex_RegWrite_r;
				ex_mem_MemRead_r	<= id_ex_MemRead_r;
				ex_mem_MemWrite_r	<= id_ex_MemWrite_r;
				ex_mem_Branch_r		<= id_ex_Branch_r;
				ex_mem_Jal_r		<= id_ex_Jal_r;
				ex_mem_Jalr_r		<= id_ex_Jalr_r;
				ex_mem_MULOp_r		<= id_ex_MULOp_r;
				-- Pass Data
				ex_mem_pc_r				<= id_ex_pc_r;
				ex_mem_pc_plus4_r		<= id_ex_pc_plus4_r;
				ex_mem_inst_r			<= id_ex_inst_r;
				ex_mem_brTaken_r		<= ex_brTaken_w;
				ex_mem_alu_res_r		<= ex_alu_res_w;
				ex_mem_addr_gen_r		<= ex_addr_gen_w;
				ex_mem_rs2_forwarded_r	<= ex_rs2_forwarded_w;
				ex_mem_rd_r				<= id_ex_rd_r;
				ex_mem_P0_r				<= ex_P0_w;
				ex_mem_P1_r				<= ex_P1_w;
				ex_mem_P2_r				<= ex_P2_w;
				ex_mem_P3_r				<= ex_P3_w;
			END IF;
		END IF;
	END PROCESS;

	-- Pipeline Register 4: MEM/WB
	PROCESS (mclk_w)
	BEGIN
		IF rising_edge(mclk_w) THEN
			IF (rst_w = '1') THEN
				mem_wb_RegWrite_r 	<= '0';
				mem_wb_inst_r		<= (others => '0');
			ELSE
				-- Pass Controls
				mem_wb_RegDst_r			<= ex_mem_RegDst_r;
				mem_wb_MemtoReg_r		<= ex_mem_MemtoReg_r;
				mem_wb_RegWrite_r		<= ex_mem_RegWrite_r;
				mem_wb_MULOp_r			<= ex_mem_MULOp_r;
				-- Pass Data
				mem_wb_pc_r				<= ex_mem_pc_r;
				mem_wb_pc_plus4_r		<= ex_mem_pc_plus4_r;
				mem_wb_inst_r			<= ex_mem_inst_r;
				mem_wb_alu_res_r		<= ex_mem_alu_res_r;
				mem_wb_dtcm_data_rd_r	<= mem_dtcm_data_rd_w;
				mem_wb_mul_res_r		<= mem_mul_res_w;
				mem_wb_rd_r				<= ex_mem_rd_r;
			END IF;
		END IF;
	END PROCESS;

	--====================================================================================
	-- 3. DIAGNOSTICS & SYSTEM COUNTERS
	--====================================================================================
	PROCESS (mclk_w)
	BEGIN
		IF rising_edge(mclk_w) THEN
			IF rst_w = '1' THEN
				clk_cnt_r	<= (others => '0');
				fh_cnt_r	<= (others => '0');
				st_cnt_r	<= (others => '0');
			ELSE
				clk_cnt_r	<= clk_cnt_r + '1';
				IF flush_branch_w = '1' THEN fh_cnt_r <= fh_cnt_r + '1'; END IF;
				IF stall_IF_w = '1' THEN st_cnt_r <= st_cnt_r + '1'; END IF;
			END IF;
		END IF;
	END PROCESS;

	-- Pipeline Instruction & PC Tracers
	IFpc_o				<= if_pc_w;
	IDpc_o				<= if_id_pc_r;
	EXpc_o				<= id_ex_pc_r;
	MEMpc_o				<= ex_mem_pc_r;
	WBpc_o				<= mem_wb_pc_r;
	
	IFinstruction_o		<= if_inst_w;
	IDinstruction_o		<= if_id_inst_r;
	EXinstruction_o		<= id_ex_inst_r;
	MEMinstruction_o	<= ex_mem_inst_r;
	WBinstruction_o		<= mem_wb_inst_r;

	-- Counter mapping
	CLKCNT_o			<= clk_cnt_r;
	FHCNT_o				<= fh_cnt_r;
	STCNT_o				<= st_cnt_r;

	-- SignalTap Trigger (Checks if Fetch PC matches word-aligned BPADDR)
	STRIGGER_o			<= '1' WHEN if_pc_w(9 DOWNTO 2) = BPADDR_i ELSE '0';
	--=========================================================
	-- 	The second instruction for example is:
	--	addr: 0x4 ~ 00000100 
	-- 	If we ignore the first two bits, the address will be 1,
	--	meaning that the break point is 00000001
	--=========================================================
END structure;