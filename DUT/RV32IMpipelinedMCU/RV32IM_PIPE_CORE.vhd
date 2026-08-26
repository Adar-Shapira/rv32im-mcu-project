--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Top Level Structural Model for Pipelined RISC-V RV32IM Core (Figure 8)
-- Instantiates the 5 pipeline stages (IF | ID | EX | MEM | WB) plus
-- HAZARD_UNIT and FORWARD_UNIT, and generates
-- the two global pipeline-control signals:
--   * stall_w - from HAZARD_UNIT (load-use interlock): freezes PC + IF/ID
--     and bubbles ID/EX
--   * flush_w - taken branch / jal / jalr resolved in the MEM stage
--     (EX/MEM register outputs): redirects the PC and kills the 3 younger
--     instructions (IF/ID, ID/EX and EX/MEM get bubbles) => depth = 3
-- The redirect target is the branch address adder result (branch/jal) or
-- the ALU result (jalr), both carried in the EX/MEM register.
-- Debug additions per Figure 8 (vs the single-cycle top): CLKCNT_o clock
-- counter, STCNT_o stall counter, FHCNT_o flush counter, and the BPADDR_i
-- breakpoint register compared against the IF-stage PC (word granularity)
-- to produce the SignalTap trigger STRIGGER_o.
--============================================================================ 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY RV32IM_PIPE_CORE IS
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
	PORT(	
		--Inputs
		rst_i		 			:IN		STD_LOGIC;
		clk_i					:IN		STD_LOGIC;
		BPADDR_i				:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);	-- breakpoint word address (SW7-SW0)
		
		-- Figure 8 SignalTap observation interface
		CLKCNT_o				:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
		IFpc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IFinstruction_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		IDpc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IDinstruction_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		EXpc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		EXinstruction_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		MEMpc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		MEMinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		WBpc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		WBinstruction_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		STRIGGER_o				:OUT	STD_LOGIC;
		FHCNT_o					:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);
		STCNT_o					:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0)
	);		
END RV32IM_PIPE_CORE;
--============================================================================
ARCHITECTURE structure OF RV32IM_PIPE_CORE IS
	-- clock
	SIGNAL mclk_w 				: STD_LOGIC;
	SIGNAL rst_w					: STD_LOGIC;
	-- global pipeline control
	SIGNAL stall_w 				: STD_LOGIC;
	SIGNAL flush_w 				: STD_LOGIC;
	SIGNAL redirect_addr_w		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	-- IF stage / IF-ID register outputs
	SIGNAL if_pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- CONTROL outputs (ID stage, captured by the ID/EX register in IDECODE)
	SIGNAL reg_dst_w 			: STD_LOGIC;
	SIGNAL reg_write_w 			: STD_LOGIC;
	SIGNAL MemtoReg_w 			: STD_LOGIC;
	SIGNAL mem_read_w 			: STD_LOGIC;
	SIGNAL mem_write_w 			: STD_LOGIC;
	SIGNAL branch_w 			: STD_LOGIC;
	SIGNAL Jal_ctrl_w 			: STD_LOGIC;
	SIGNAL Jalr_ctrl_w 			: STD_LOGIC;
	SIGNAL alu_src_w 			: STD_LOGIC;
	SIGNAL upper_im_w			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL alu_op_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	-- IDECODE outputs: ID stage (hazard check) + WB write-back data
	SIGNAL id_rs1_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_rs2_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL wb_write_data_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- ID/EX register outputs (EX-stage view)
	SIGNAL ex_pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL ex_instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_read_data1_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_read_data2_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_sign_ext_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL ex_rs1_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ex_rs2_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ex_rd_w 				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ex_ALUSrc_w 			: STD_LOGIC;
	SIGNAL ex_UpperIm_w 		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL ex_ALUOp_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL ex_Branch_w 			: STD_LOGIC;
	SIGNAL ex_Jal_w 			: STD_LOGIC;
	SIGNAL ex_Jalr_w 			: STD_LOGIC;
	SIGNAL ex_MemRead_w 		: STD_LOGIC;
	SIGNAL ex_MemWrite_w 		: STD_LOGIC;
	SIGNAL ex_RegDst_w 			: STD_LOGIC;
	SIGNAL ex_RegWrite_w 		: STD_LOGIC;
	SIGNAL ex_MemtoReg_w 		: STD_LOGIC;
	-- EX/MEM register outputs (MEM-stage view)
	SIGNAL mem_pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_instruction_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_alu_res_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_write_data_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_addr_gen_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_brTaken_w 		: STD_LOGIC;
	SIGNAL mem_rd_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL mem_mul_p0_w			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL mem_mul_p1_w			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL mem_mul_p2_w			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL mem_mul_p3_w			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL mem_Mul_w			: STD_LOGIC;
	SIGNAL mem_Branch_w 		: STD_LOGIC;
	SIGNAL mem_Jal_w 			: STD_LOGIC;
	SIGNAL mem_Jalr_w 			: STD_LOGIC;
	SIGNAL mem_MemRead_w 		: STD_LOGIC;
	SIGNAL mem_MemWrite_w 		: STD_LOGIC;
	SIGNAL mem_RegDst_w 		: STD_LOGIC;
	SIGNAL mem_RegWrite_w 		: STD_LOGIC;
	SIGNAL mem_MemtoReg_w 		: STD_LOGIC;
	-- MEM stage
	SIGNAL dtcm_addr_w 			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL mem_forward_data_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- MEM/WB register outputs (WB-stage view)
	SIGNAL wb_pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL wb_pc_plus4_w 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL wb_instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL wb_alu_res_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL wb_dtcm_data_rd_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL wb_rd_w 				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL wb_RegDst_w 			: STD_LOGIC;
	SIGNAL wb_RegWrite_w 		: STD_LOGIC;
	SIGNAL wb_MemtoReg_w 		: STD_LOGIC;
	-- forwarding mux selects
	SIGNAL forward_a_w 			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL forward_b_w 			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	-- debug registers (Figure 8)
	SIGNAL mclk_cnt_q			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);	-- CLKCNT
	SIGNAL stcnt_q				: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);		-- STCNT
	SIGNAL fhcnt_q				: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);		-- FHCNT
	SIGNAL bpaddr_q				: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);	-- BPADDR breakpoint register

BEGIN
	-- RESET POLARITY IS THE WRAPPER'S JOB, NOT THIS FILE'S -- corrected 2026-08-26.
	--
	-- The as-supplied line here was
	--     rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i;
	-- which is deviation D-1: it welds board-level signal conditioning to the
	-- simulation switch, inside the core. RV32IMpipelinedMCU already conditions
	-- KEY0 in its own RSTCOND generate (RV32IMpipelinedMCU.vhd:136-141) under the
	-- RST_ACTIVE_LOW generic, and its header states it is "the single owner of
	-- polarity -- there is no double inversion".
	--
	-- That statement was FALSE while this line stood. At the committed defaults
	-- (RST_ACTIVE_LOW => TRUE, G_MODELSIM := 0) the wrapper inverted and this
	-- line inverted again, so the core's internal reset was the raw KEY0 pin --
	-- which idles HIGH on the DE2-115. The FPGA build would have sat in
	-- permanent reset unless KEY0 was held down, and simulation would not have
	-- shown it: tb_RV32IMpipelinedMCU passes RST_ACTIVE_LOW => FALSE and the .do
	-- scripts pass -gMODELSIM=1, so both inversions vanish there.
	--
	-- The single-cycle core has no inversion at all for exactly this reason
	-- (RV32IM_CORE.vhd uses rst_i directly; polarity lives in RV32IMscMCU's own
	-- RSTCOND at RV32IMscMCU.vhd:465). This is the same de-welding, applied to
	-- the copy that the Phase 3D re-import brought in unchanged.
	rst_w <= rst_i;
	
	--=======================================
	-- PLL module connection
	--=======================================
	G0:
	if (MODELSIM = 0) generate
	  MCLK: PLL
		PORT MAP (
			inclk0 	=> clk_i,
			c0 		=> mclk_w
		);
	else generate
		mclk_w 	<= clk_i;
	end generate;
	
	--=================================================
	-- Global pipeline control: flush / redirect (MEM)
	--=================================================
	-- branches and jumps are resolved in stage 4 (MEM): a taken branch or
	-- any jal/jalr redirects the PC and flushes the 3 younger instructions
	flush_w			<=	(mem_Branch_w AND mem_brTaken_w) OR mem_Jal_w OR mem_Jalr_w;
	
	-- redirect target: jalr jumps to rs1+imm (ALU result), branch/jal to
	-- PC+offset (branch address adder), both from the EX/MEM register
	redirect_addr_w	<=	mem_alu_res_w(PC_WIDTH-1 DOWNTO 1) & '0'	WHEN mem_Jalr_w = '1' ELSE
						mem_addr_gen_w;
	
	--===========================================
	-- IFETCH (including ITCM) module connection
	--===========================================
	IFE : Ifetch
	generic map(
		WORD_GRANULARITY	=> 	WORD_GRANULARITY,
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		PC_WIDTH			=>	PC_WIDTH,
		ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
		WORDS_NUM			=>	DATA_WORDS_NUM
	)
	PORT MAP (
		--Inputs
		clk_i 				=> mclk_w,  
		rst_i 				=> rst_w,
		stall_i 			=> stall_w,
		flush_i 			=> flush_w,
		redirect_addr_i		=> redirect_addr_w,
		
		--Outputs
		if_pc_o 			=> if_pc_w,
		if_instruction_o	=> if_instruction_w,
		pc_o 				=> id_pc_w,
		pc_plus4_o	 		=> id_pc_plus4_w,
		instruction_o 		=> id_instruction_w    
	);
	--=======================================
	-- CONTROL module connection (ID stage)
	--=======================================
	CTL:   control
	PORT MAP ( 	
		--Inputs
		instruction_i 		=> id_instruction_w,
		
		--Outputs
		RegDst_ctrl_o		=> reg_dst_w,
		ALUSrc_ctrl_o 		=> alu_src_w,
		MemtoReg_ctrl_o 	=> MemtoReg_w,
		RegWrite_ctrl_o 	=> reg_write_w,
		MemRead_ctrl_o 		=> mem_read_w,
		MemWrite_ctrl_o 	=> mem_write_w,
		Branch_ctrl_o 		=> branch_w,
		Jal_ctrl_o 			=> Jal_ctrl_w,
		Jalr_ctrl_o			=> Jalr_ctrl_w,
		UpperIm_ctrl_o 		=> upper_im_w,
		ALUOp_ctrl_o 		=> alu_op_w
	);
	--==================================================
	-- IDECODE module connection (ID stage + RF + ID/EX)
	--==================================================
	ID : Idecode
	generic map(
		PC_WIDTH			=>	PC_WIDTH,
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
		--Inputs
		clk_i 				=> mclk_w,  
		rst_i 				=> rst_w,
		stall_i 			=> stall_w,
		flush_i 			=> flush_w,
		pc_i				=> id_pc_w,
		pc_plus4_i	 		=> id_pc_plus4_w,
    	instruction_i 		=> id_instruction_w,
		RegDst_ctrl_i		=> reg_dst_w,
		RegWrite_ctrl_i 	=> reg_write_w,
		MemtoReg_ctrl_i 	=> MemtoReg_w,
		MemRead_ctrl_i 		=> mem_read_w,
		MemWrite_ctrl_i 	=> mem_write_w,
		Branch_ctrl_i 		=> branch_w,
		Jal_ctrl_i 			=> Jal_ctrl_w,
		Jalr_ctrl_i 		=> Jalr_ctrl_w,
		ALUSrc_ctrl_i 		=> alu_src_w,
		UpperIm_ctrl_i 		=> upper_im_w,
		ALUOp_ctrl_i 		=> alu_op_w,
		wb_RegWrite_ctrl_i 	=> wb_RegWrite_w,
		wb_rd_i 			=> wb_rd_w,
		wb_write_data_i 	=> wb_write_data_w,
		
		--Outputs
		id_rs1_o 			=> id_rs1_w,
		id_rs2_o 			=> id_rs2_w,
		ex_pc_o 			=> ex_pc_w,
		ex_pc_plus4_o 		=> ex_pc_plus4_w,
		ex_instruction_o	=> ex_instruction_w,
		ex_read_data1_o 	=> ex_read_data1_w,
    	ex_read_data2_o 	=> ex_read_data2_w,
		ex_sign_ext_o 		=> ex_sign_ext_w,
		ex_rs1_o 			=> ex_rs1_w,
		ex_rs2_o 			=> ex_rs2_w,
		ex_rd_o 			=> ex_rd_w,
		ex_ALUSrc_ctrl_o 	=> ex_ALUSrc_w,
		ex_UpperIm_ctrl_o 	=> ex_UpperIm_w,
		ex_ALUOp_ctrl_o 	=> ex_ALUOp_w,
		ex_Branch_ctrl_o 	=> ex_Branch_w,
		ex_Jal_ctrl_o 		=> ex_Jal_w,
		ex_Jalr_ctrl_o 		=> ex_Jalr_w,
		ex_MemRead_ctrl_o 	=> ex_MemRead_w,
		ex_MemWrite_ctrl_o 	=> ex_MemWrite_w,
		ex_RegDst_ctrl_o 	=> ex_RegDst_w,
		ex_RegWrite_ctrl_o 	=> ex_RegWrite_w,
		ex_MemtoReg_ctrl_o 	=> ex_MemtoReg_w
	);
	--=================================================
	-- EXECUTE module connection (EX stage + EX/MEM)
	--=================================================
	EXE:  Execute
  	generic map(
		DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
		PC_WIDTH 			=>	PC_WIDTH
	)
	PORT MAP (	
		--Inputs
		clk_i 				=> mclk_w,
		rst_i 				=> rst_w,
		flush_i 			=> flush_w,
		pc_i				=> ex_pc_w,
		pc_plus4_i 			=> ex_pc_plus4_w,
		instruction_i		=> ex_instruction_w,
		read_data1_i 		=> ex_read_data1_w,
    	read_data2_i 		=> ex_read_data2_w,
		sign_extend_i 		=> ex_sign_ext_w,
		rd_i 				=> ex_rd_w,
		UpperIm_ctrl_i 		=> ex_UpperIm_w,
		ALUOp_ctrl_i 		=> ex_ALUOp_w,
		ALUSrc_ctrl_i 		=> ex_ALUSrc_w,
		Branch_ctrl_i 		=> ex_Branch_w,
		Jal_ctrl_i 			=> ex_Jal_w,
		Jalr_ctrl_i 		=> ex_Jalr_w,
		MemRead_ctrl_i 		=> ex_MemRead_w,
		MemWrite_ctrl_i 	=> ex_MemWrite_w,
		RegDst_ctrl_i 		=> ex_RegDst_w,
		RegWrite_ctrl_i 	=> ex_RegWrite_w,
		MemtoReg_ctrl_i 	=> ex_MemtoReg_w,
		forward_a_i 		=> forward_a_w,
		forward_b_i 		=> forward_b_w,
		mem_forward_data_i	=> mem_forward_data_w,
		wb_write_data_i 	=> wb_write_data_w,
		
		--Outputs
		mem_pc_o 			=> mem_pc_w,
		mem_pc_plus4_o 		=> mem_pc_plus4_w,
		mem_instruction_o	=> mem_instruction_w,
		mem_alu_res_o 		=> mem_alu_res_w,
		mem_write_data_o 	=> mem_write_data_w,
		mem_addr_gen_o 		=> mem_addr_gen_w,
		mem_brTaken_o 		=> mem_brTaken_w,
		mem_rd_o 			=> mem_rd_w,
		mem_mul_p0_o		=> mem_mul_p0_w,
		mem_mul_p1_o		=> mem_mul_p1_w,
		mem_mul_p2_o		=> mem_mul_p2_w,
		mem_mul_p3_o		=> mem_mul_p3_w,
		mem_Mul_ctrl_o		=> mem_Mul_w,
		mem_Branch_ctrl_o 	=> mem_Branch_w,
		mem_Jal_ctrl_o 		=> mem_Jal_w,
		mem_Jalr_ctrl_o 	=> mem_Jalr_w,
		mem_MemRead_ctrl_o 	=> mem_MemRead_w,
		mem_MemWrite_ctrl_o => mem_MemWrite_w,
		mem_RegDst_ctrl_o 	=> mem_RegDst_w,
		mem_RegWrite_ctrl_o => mem_RegWrite_w,
		mem_MemtoReg_ctrl_o => mem_MemtoReg_w
	);
	--=================================================
	-- DTCM module connection (MEM stage + MEM/WB)
	--=================================================
	G1: 
	if (WORD_GRANULARITY = True) generate -- i.e. each WORD has a unike address
		dtcm_addr_w	<= mem_alu_res_w(MA_WIDTH-1 DOWNTO 2); -- increment memory address by 4;
	elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address
		dtcm_addr_w	<= mem_alu_res_w(MA_WIDTH-1 DOWNTO 0);
	end generate;
	
	MEM:  dmemory
	generic map(
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
		WORDS_NUM			=>	DATA_WORDS_NUM,
		PC_WIDTH 			=>	PC_WIDTH
	)
	PORT MAP (	
		--Inputs
		clk_i 				=> mclk_w,  
		rst_i 				=> rst_w,
		dtcm_addr_i 		=> dtcm_addr_w,
		dtcm_data_wr_i 		=> mem_write_data_w,
		MemRead_ctrl_i 		=> mem_MemRead_w, 
		MemWrite_ctrl_i 	=> mem_MemWrite_w,
		pc_i 				=> mem_pc_w,
		pc_plus4_i 			=> mem_pc_plus4_w,
		instruction_i		=> mem_instruction_w,
		alu_res_i 			=> mem_alu_res_w,
		rd_i 				=> mem_rd_w,
		mul_p0_i			=> mem_mul_p0_w,
		mul_p1_i			=> mem_mul_p1_w,
		mul_p2_i			=> mem_mul_p2_w,
		mul_p3_i			=> mem_mul_p3_w,
		Mul_ctrl_i			=> mem_Mul_w,
		RegDst_ctrl_i 		=> mem_RegDst_w,
		RegWrite_ctrl_i 	=> mem_RegWrite_w,
		MemtoReg_ctrl_i 	=> mem_MemtoReg_w,
				
		--Outputs
		dtcm_data_rd_o 		=> OPEN,
		mem_forward_data_o	=> mem_forward_data_w,
		wb_pc_o 			=> wb_pc_w,
		wb_pc_plus4_o 		=> wb_pc_plus4_w,
		wb_instruction_o	=> wb_instruction_w,
		wb_alu_res_o 		=> wb_alu_res_w,
		wb_dtcm_data_rd_o 	=> wb_dtcm_data_rd_w,
		wb_rd_o 			=> wb_rd_w,
		wb_RegDst_ctrl_o 	=> wb_RegDst_w,
		wb_RegWrite_ctrl_o 	=> wb_RegWrite_w,
		wb_MemtoReg_ctrl_o 	=> wb_MemtoReg_w
	);
	--=================================================
	-- WRITEBACK mux (WB stage)
	--=================================================
	WB: writeback
	generic map(
		DATA_BUS_WIDTH		=>	DATA_BUS_WIDTH,
		PC_WIDTH			=>	PC_WIDTH
	)
	PORT MAP (
		alu_res_i			=> wb_alu_res_w,
		dtcm_data_rd_i		=> wb_dtcm_data_rd_w,
		pc_plus4_i			=> wb_pc_plus4_w,
		MemtoReg_ctrl_i		=> wb_MemtoReg_w,
		RegDst_ctrl_i		=> wb_RegDst_w,
		write_data_o		=> wb_write_data_w
	);
	--=======================================
	-- HAZARD_UNIT connection (interlock)
	--=======================================
	HZD: HAZARD_UNIT
	PORT MAP (
		--Inputs
		id_rs1_i 			=> id_rs1_w,
		id_rs2_i 			=> id_rs2_w,
		ex_MemRead_ctrl_i 	=> ex_MemRead_w,
		ex_rd_i 			=> ex_rd_w,
		
		--Outputs
		stall_o 			=> stall_w
	);
	--=======================================
	-- FORWARD_UNIT connection (full forwarding)
	--=======================================
	FWD: FORWARD_UNIT
	PORT MAP (
		--Inputs
		ex_rs1_i 			=> ex_rs1_w,
		ex_rs2_i 			=> ex_rs2_w,
		mem_RegWrite_ctrl_i => mem_RegWrite_w,
		mem_rd_i 			=> mem_rd_w,
		wb_RegWrite_ctrl_i 	=> wb_RegWrite_w,
		wb_rd_i 			=> wb_rd_w,
		
		--Outputs
		forward_a_o 		=> forward_a_w,
		forward_b_o 		=> forward_b_w
	);
	
	--==========================================================
	-- Debug registers (Figure 8): CLKCNT / STCNT / FHCNT
	--==========================================================
	-- CLKCNT: free-running clock counter (cleared on reset)
	process (mclk_w , rst_w)
	begin
		if rst_w = '1' then
			mclk_cnt_q	<=	(others	=> '0');
		elsif rising_edge(mclk_w) then
			mclk_cnt_q	<=	mclk_cnt_q + '1';
		end if;
	end process;
	
	-- STCNT: counts stall cycles (cleared on reset). A stall that coincides
	-- with a flush is not counted - the redirect from MEM cancels the
	-- interlock (flush has priority in IFETCH), and that cycle is already
	-- accounted for by the flush penalty in the IPC equation
	-- IPC = (CLKCNT - (STCNT + 4 + 3*FHCNT)) / CLKCNT.
	process (mclk_w , rst_w)
	begin
		if rst_w = '1' then
			stcnt_q	<=	(others	=> '0');
		elsif rising_edge(mclk_w) then
			if (stall_w = '1' and flush_w = '0') then
				stcnt_q	<=	stcnt_q + '1';
			end if;
		end if;
	end process;
	
	-- FHCNT: counts flush events (cleared on reset). flush_w is high for
	-- exactly one cycle per taken branch/jal/jalr (the EX/MEM register is
	-- bubbled right after), so one count = one redirect = 3 killed
	-- instructions (depth = 3 in the IPC equation).
	process (mclk_w , rst_w)
	begin
		if rst_w = '1' then
			fhcnt_q	<=	(others	=> '0');
		elsif rising_edge(mclk_w) then
			if flush_w = '1' then
				fhcnt_q	<=	fhcnt_q + '1';
			end if;
		end if;
	end process;
	
	--==========================================================
	-- BPADDR breakpoint register + Signal-Tap trigger
	--==========================================================
	-- BPADDR_i (word-granularity address from SW7-SW0) is sampled into the
	-- breakpoint register (cleared on reset)
	process (mclk_w , rst_w)
	begin
		if rst_w = '1' then
			bpaddr_q	<=	(others	=> '0');
		elsif rising_edge(mclk_w) then
			bpaddr_q	<=	BPADDR_i;
		end if;
	end process;
	
	-- SignalTap_trigger = (IF_PC == BPADDR_i): the byte-addressed IF-stage
	-- PC is converted to a word address (drop the 2 LSBs); the unsigned
	-- compare zero-extends the shorter operand
	
---------------------------------------------------------------------------------------
-- Figure 8 verification and FPGA SignalTap outputs
---------------------------------------------------------------------------------------
	CLKCNT_o				<=	mclk_cnt_q;
	IFpc_o					<=	if_pc_w;
	IFinstruction_o		<=	if_instruction_w;
	IDpc_o					<=	id_pc_w;
	IDinstruction_o		<=	id_instruction_w;
	EXpc_o					<=	ex_pc_w;
	EXinstruction_o		<=	ex_instruction_w;
	MEMpc_o					<=	mem_pc_w;
	MEMinstruction_o		<=	mem_instruction_w;
	WBpc_o					<=	wb_pc_w;
	WBinstruction_o			<=	wb_instruction_w;
	STRIGGER_o				<=	'1' WHEN (if_pc_w(PC_WIDTH-1 DOWNTO 2) = bpaddr_q) ELSE '0';
	FHCNT_o					<=	fhcnt_q;
	STCNT_o					<=	stcnt_q;
	
---------------------------------------------------------------------------------------

END structure;
