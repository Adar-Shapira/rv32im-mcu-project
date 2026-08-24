--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Component declarations package
-- RV32IM: core renamed to RV32IM_CORE, MUL16 component added
--============================================================================
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;		-- MEM_W, used as the dmemory MemOp_ctrl_i default


package aux_package is

	-- Board-facing structural top level (Final Project §3). Declared first
	-- because it sits above RV32IM_CORE in the hierarchy.
	component RV32IMscMCU is
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
			CLK_CNT_WIDTH		: integer	:= 16
		);
		PORT(
			--Inputs
			clk_i				:IN		STD_LOGIC;
			rst_i				:IN		STD_LOGIC;

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

			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component RV32IM_CORE is
		generic( 
			WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	    	MODELSIM 			: integer 	:= G_MODELSIM;
			DATA_BUS_WIDTH 		: integer 	:= 32;
			ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			PC_WIDTH 			: integer 	:= 10;
			MA_WIDTH 			: integer 	:= 10;
			DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH 		: integer 	:= 16
		);
		PORT(	
			--Inputs
			rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC;
			
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
			dtcm_data_rd_o		:OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
		);		
	end component;
---------------------------------------------------------  
	component control is
		PORT( 
		--Inputs
		instruction_i 			: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
		
		--Outputs
		RegDst_ctrl_o 			: OUT 	STD_LOGIC;
		ALUSrc_ctrl_o 			: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 		: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 		: OUT 	STD_LOGIC;
		MemRead_ctrl_o 			: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 		: OUT 	STD_LOGIC;
		Branch_ctrl_o 			: OUT 	STD_LOGIC;
		Jal_ctrl_o 				: OUT 	STD_LOGIC;
		Jalr_ctrl_o 			: OUT 	STD_LOGIC;
		UpperIm_ctrl_o			: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUOp_ctrl_o	 		: OUT 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		MemOp_ctrl_o			: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0)	-- Phase 3B (G-309)
	);
	end component;
---------------------------------------------------------	
	-- Clock-domain-crossing synchronizer, Figures 10a/10b (gap G-310). Not yet
	-- instantiated by the core: it is a leaf for the divider (Phase 7), the KEY1-3
	-- edge detectors (Phase 6) and the UART status flags (Phase 12). Declared here
	-- so all three use one verified implementation instead of three inline copies.
	component sync is
		generic(
			DATA_WIDTH	: integer := 32;
			STAGES		: integer := 2;
			GEN_SRC_REG	: boolean := TRUE
		);
		PORT(
			--Inputs
			src_clk_i	: IN	STD_LOGIC;
			dst_clk_i	: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			d_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

			--Outputs
			q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------

	component dmemory is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			DTCM_ADDR_WIDTH 	: integer := 8;
			WORDS_NUM 			: integer := 256
		);
		PORT(	
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			-- Phase 3B (G-309). Defaults keep an older instantiation valid as a
			-- word-only memory; MEM_W comes from const_package.
			MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
			byte_sel_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";

			--Outputs
			dtcm_data_rd_o 		: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
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
			read_data1_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			read_data2_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			sign_extend_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
				
			--Outputs
			brTaken_o 			: OUT	STD_LOGIC;
			alu_res_o 			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_gen_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0)
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
	component Idecode is
		generic(
			PC_WIDTH 			: integer	:= 10;
			DATA_BUS_WIDTH		: integer := 32
		);
		PORT(
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			alu_res_i			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			
			--Outputs
			read_data1_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o		: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			SignExt_o 			: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)		 
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
			addr_gen_i 			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			Branch_ctrl_i		: IN 	STD_LOGIC;
			brTaken_i 			: IN 	STD_LOGIC;
			Jal_ctrl_i			: IN 	STD_LOGIC;
			Jalr_ctrl_i			: IN 	STD_LOGIC;
			alu_res_i 			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			--Outputs
			pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
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
