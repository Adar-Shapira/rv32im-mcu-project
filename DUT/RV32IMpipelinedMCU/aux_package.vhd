--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Component declarations package - pipelined RV32IM version
-- Every component matches its pipeline entity: the stage modules carry
-- stall/flush ports and their pipeline-register outputs, and the two new
-- units (HAZARD_UNIT, FORWARD_UNIT) plus the RV32IM_PIPE_CORE top with the
-- Figure 8 debug ports (CLKCNT/STCNT/FHCNT counters, BPADDR breakpoint) are
-- added. MUL16 and PLL are unchanged from the single-cycle version.
--============================================================================
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;


package aux_package is

	-- Board-facing structural top level (Final Project §3). Declared first
	-- because it sits above RV32IM_PIPE_CORE in the hierarchy.
	component RV32IMpipelinedMCU is
		generic(
			RST_ACTIVE_LOW		: boolean	:= TRUE;
			GEN_DEBUG_PORTS		: boolean	:= TRUE;
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
			--Inputs
			clk_i				:IN		STD_LOGIC;
			rst_i				:IN		STD_LOGIC;
			BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);

			--Outputs (Signal-Tap observation, gated by GEN_DEBUG_PORTS)
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
	end component;
---------------------------------------------------------
	component RV32IM_PIPE_CORE is
		generic( 
			WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	    	MODELSIM 			: integer 	:= G_MODELSIM;
			DATA_BUS_WIDTH 		: integer 	:= 32;
			ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			PC_WIDTH 			: integer 	:= 10;
			MA_WIDTH 			: integer 	:= 10;
			DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH 		: integer 	:= 16;
			STCNT_WIDTH 		: integer 	:= 8;
			FHCNT_WIDTH 		: integer 	:= 8;
			BP_ADDR_WIDTH 		: integer 	:= 8
		);
		PORT(	
			--Inputs
			rst_i		 		:IN		STD_LOGIC;
			clk_i				:IN		STD_LOGIC;
			BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);
			
			--Outputs (used also for Signal-Tap auxiliary pins)
			pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			RegWrite_ctrl_o		:OUT 	STD_LOGIC;
			MemWrite_ctrl_o		:OUT 	STD_LOGIC;
			Branch_ctrl_o		:OUT 	STD_LOGIC;
			
			read_data1_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			write_data_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			alu_res_o 			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);															
			brTaken_o			:OUT 	STD_LOGIC; 
			
			dtcm_addr_o			:OUT 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_o		:OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			stall_o				:OUT	STD_LOGIC;
			flush_o				:OUT	STD_LOGIC;
			BPTRIGGER_o			:OUT	STD_LOGIC;
			
			CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
			FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0)
		);		
	end component;
---------------------------------------------------------  
	component control is
		PORT( 
			--Inputs
			instruction_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			
			--Outputs
			RegDst_ctrl_o 		: OUT 	STD_LOGIC;
			ALUSrc_ctrl_o 		: OUT 	STD_LOGIC;
			MemtoReg_ctrl_o 	: OUT 	STD_LOGIC;
			RegWrite_ctrl_o 	: OUT 	STD_LOGIC;
			MemRead_ctrl_o 		: OUT 	STD_LOGIC;
			MemWrite_ctrl_o	 	: OUT 	STD_LOGIC;
			Branch_ctrl_o 		: OUT 	STD_LOGIC;
			Jal_ctrl_o 			: OUT 	STD_LOGIC;
			Jalr_ctrl_o 		: OUT 	STD_LOGIC;
			UpperIm_ctrl_o		: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(4 DOWNTO 0)
		);
	end component;
---------------------------------------------------------	
	component Ifetch is
		generic(
			WORD_GRANULARITY 	: boolean	:= False;
			DATA_BUS_WIDTH 		: integer	:= 32;
			PC_WIDTH 			: integer	:= 10;
			ITCM_ADDR_WIDTH 	: integer	:= 8;
			WORDS_NUM 			: integer	:= 256
		);
		PORT(
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i 				: IN 	STD_LOGIC;
			stall_i				: IN 	STD_LOGIC;
			flush_i				: IN 	STD_LOGIC;
			redirect_addr_i		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			
			--Outputs
			if_pc_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------		
	component Idecode is
		generic(
			PC_WIDTH 			: integer	:= 10;
			DATA_BUS_WIDTH		: integer := 32
		);
		PORT(
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			stall_i				: IN 	STD_LOGIC;
			flush_i				: IN 	STD_LOGIC;
			pc_i				: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			MemRead_ctrl_i 		: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			Branch_ctrl_i 		: IN 	STD_LOGIC;
			Jal_ctrl_i 			: IN 	STD_LOGIC;
			Jalr_ctrl_i 		: IN 	STD_LOGIC;
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_RegDst_ctrl_i 	: IN 	STD_LOGIC;
			wb_RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			wb_MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			wb_rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_pc_plus4_i		: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			wb_alu_res_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_dtcm_data_rd_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			--Outputs
			id_rs1_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			id_rs2_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_write_data_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ex_pc_o				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			ex_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			ex_read_data1_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ex_read_data2_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ex_sign_ext_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			ex_rs1_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_rs2_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_rd_o				: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_ALUSrc_ctrl_o 	: OUT	STD_LOGIC;
			ex_UpperIm_ctrl_o	: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ex_ALUOp_ctrl_o	 	: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_Branch_ctrl_o 	: OUT	STD_LOGIC;
			ex_Jal_ctrl_o 		: OUT	STD_LOGIC;
			ex_Jalr_ctrl_o 		: OUT	STD_LOGIC;
			ex_MemRead_ctrl_o 	: OUT	STD_LOGIC;
			ex_MemWrite_ctrl_o 	: OUT	STD_LOGIC;
			ex_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			ex_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
			ex_MemtoReg_ctrl_o 	: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			PC_WIDTH 			: integer := 10
		);
		PORT(	
			--Inputs
			clk_i 				: IN 	STD_LOGIC;
			rst_i 				: IN 	STD_LOGIC;
			flush_i				: IN 	STD_LOGIC;
			pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			read_data1_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			Branch_ctrl_i 		: IN 	STD_LOGIC;
			Jal_ctrl_i 			: IN 	STD_LOGIC;
			Jalr_ctrl_i 		: IN 	STD_LOGIC;
			MemRead_ctrl_i 		: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			forward_a_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			forward_b_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			wb_write_data_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
				
			--Outputs
			mem_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			mem_alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mem_write_data_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mem_addr_gen_o 		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			mem_brTaken_o 		: OUT	STD_LOGIC;
			mem_rd_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			mem_Branch_ctrl_o 	: OUT	STD_LOGIC;
			mem_Jal_ctrl_o 		: OUT	STD_LOGIC;
			mem_Jalr_ctrl_o 	: OUT	STD_LOGIC;
			mem_MemRead_ctrl_o 	: OUT	STD_LOGIC;
			mem_MemWrite_ctrl_o : OUT	STD_LOGIC;
			mem_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			mem_RegWrite_ctrl_o : OUT	STD_LOGIC;
			mem_MemtoReg_ctrl_o : OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------	
	component dmemory is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			DTCM_ADDR_WIDTH 	: integer := 8;
			WORDS_NUM 			: integer := 256;
			PC_WIDTH 			: integer := 10
		);
		PORT(	
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			alu_res_i			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			
			--Outputs
			dtcm_data_rd_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			wb_alu_res_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_dtcm_data_rd_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_rd_o				: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			wb_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
			wb_MemtoReg_ctrl_o 	: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------	
	component HAZARD_UNIT is
		PORT(
			--Inputs
			id_rs1_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			id_rs2_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_MemRead_ctrl_i	: IN	STD_LOGIC;
			ex_rd_i				: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			
			--Outputs
			stall_o				: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------	
	component FORWARD_UNIT is
		PORT(
			--Inputs
			ex_rs1_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_rs2_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			mem_RegWrite_ctrl_i	: IN	STD_LOGIC;
			mem_rd_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_RegWrite_ctrl_i	: IN	STD_LOGIC;
			wb_rd_i				: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
			
			--Outputs
			forward_a_o			: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);
			forward_b_o			: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------		
	component MUL16 is
		generic(
			DATA_BUS_WIDTH 	: integer := 32
		);
		PORT(
			--Inputs (lower half-words of rs1/rs2)
			a_i 				: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);
			b_i 				: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);

			--Output (full product)
			res_o 				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	COMPONENT PLL IS
		port(
			areset				: IN STD_LOGIC  := '0';
			inclk0				: IN STD_LOGIC  := '0';
			c0     				: OUT STD_LOGIC ;
			locked				: OUT STD_LOGIC 
		);
  END COMPONENT;
---------------------------------------------------------	

end aux_package;
