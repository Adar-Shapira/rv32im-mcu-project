--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Component declarations package - pipelined RV32IM version
-- Every component matches its pipeline entity: the stage modules carry
-- stall/flush ports and their pipeline-register outputs, and the two new
-- units (HAZARD_UNIT, FORWARD_UNIT, WRITEBACK) plus the RV32IM_PIPE_CORE top
-- with the Figure 8 debug ports (CLKCNT/STCNT/FHCNT counters, BPADDR
-- breakpoint) are added. The Figure 7 multiplier is split across MULT_1 (EX)
-- and MULT_2 (MEM).
--============================================================================
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;


package aux_package is

	-- Board-facing structural top level (Final Project §3). Declared first
	-- because it sits above RV32IM_PIPE_CORE in the hierarchy. This is the only
	-- addition to the LAB5 aux_package; the port list mirrors
	-- DUT/RV32IMpipelinedMCU/RV32IMpipelinedMCU.vhd exactly, which in turn
	-- mirrors the revised core's Figure 8 interface.
	component RV32IMpipelinedMCU is
		generic(
			RST_ACTIVE_LOW		: boolean	:= TRUE;
			GEN_DEBUG_PORTS		: boolean	:= TRUE;
			GEN_RESET_ON_LOCK	: boolean	:= TRUE;
			GEN_GPO_READBACK	: boolean	:= TRUE;
			GEN_INPUT_SYNC		: boolean	:= FALSE;
			KEY_ACTIVE_LOW		: boolean	:= TRUE;
			WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
			MODELSIM			: integer	:= G_MODELSIM;
			DATA_BUS_WIDTH		: integer	:= 32;
			ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
			PC_WIDTH			: integer	:= G_PC_WIDTH;
			MA_WIDTH			: integer	:= G_MA_WIDTH;
			DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH		: integer	:= 16;
			STCNT_WIDTH			: integer	:= 16;
			FHCNT_WIDTH			: integer	:= 16;
			BP_ADDR_WIDTH		: integer	:= 8
		);
		PORT(
			clk_i				:IN		STD_LOGIC;
			rst_i				:IN		STD_LOGIC;
			BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

			SW_i				:IN		STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
			KEY_i				:IN		STD_LOGIC_VECTOR(3 DOWNTO 1) := (OTHERS => '1');
			GPIO				:INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0) := (OTHERS => 'Z');
			CAPIN1_i			:IN		STD_LOGIC := '0';
			CAPIN2_i			:IN		STD_LOGIC := '0';
			PWM_o				:OUT	STD_LOGIC;
			LEDR_o				:OUT	STD_LOGIC_VECTOR(9 DOWNTO 0);
			HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);

			IFpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			IFinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			IDpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			IDinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			EXpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			EXinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MEMpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			MEMinstruction_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			WBpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			WBinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			STRIGGER_o			:OUT	STD_LOGIC;
			CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
			FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);

			-- Observation used by GPIO TBs (MEM-stage store request)
			MemWrite_ctrl_o		:OUT	STD_LOGIC;
			alu_res_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_cs_o			:OUT	STD_LOGIC;
			unmapped_o			:OUT	STD_LOGIC;
			dtcm_wren_o			:OUT	STD_LOGIC
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
			PC_WIDTH 			: integer 	:= G_PC_WIDTH;
			MA_WIDTH 			: integer 	:= G_MA_WIDTH;
			DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH 		: integer 	:= 16;
			STCNT_WIDTH 		: integer 	:= 16;
			FHCNT_WIDTH 		: integer 	:= 16;
			BP_ADDR_WIDTH 		: integer 	:= 8
		);
		PORT(	
			rst_i		 		:IN		STD_LOGIC;
			clk_i				:IN		STD_LOGIC;
			divclk_i			:IN		STD_LOGIC := '0';
			intr_i				:IN		STD_LOGIC := '0';
			inta_o				:OUT	STD_LOGIC;
			gie_o				:OUT	STD_LOGIC;
			dbus_addr_o			:OUT	STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
			dbus_wdata_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dbus_MemRead_o		:OUT	STD_LOGIC;
			dbus_MemWrite_o		:OUT	STD_LOGIC;
			dtcm_cs_i			:IN		STD_LOGIC := '1';
			dbus_rdata_i		:IN		STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			dtcm_wren_o			:OUT	STD_LOGIC;
			BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);
			
			-- Figure 8 SignalTap observation interface
			CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
			IFpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			IFinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			IDpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			IDinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			EXpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			EXinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MEMpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			MEMinstruction_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			WBpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			WBinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			STRIGGER_o			:OUT	STD_LOGIC;
			FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);
			STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0)
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
			ALUOp_ctrl_o	 	: OUT 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			MemOp_ctrl_o		: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0);
			DivStart_ctrl_o		: OUT	STD_LOGIC;
			DivSigned_ctrl_o	: OUT	STD_LOGIC;
			DivRem_ctrl_o		: OUT	STD_LOGIC;
			Reti_ctrl_o			: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------	
	component Ifetch is
		generic(
			WORD_GRANULARITY 	: boolean	:= False;
			DATA_BUS_WIDTH 		: integer	:= 32;
			PC_WIDTH 			: integer	:= G_PC_WIDTH;
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
			IntrVec_ctrl_i		: IN	STD_LOGIC := '0';
			intr_vector_i		: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			
			--Outputs
			if_pc_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			if_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------		
	component Idecode is
		generic(
			PC_WIDTH 			: integer	:= G_PC_WIDTH;
			DATA_BUS_WIDTH		: integer := 32
		);
		PORT(
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			stall_i				: IN 	STD_LOGIC;
			hold_i				: IN 	STD_LOGIC := '0';
			flush_i				: IN 	STD_LOGIC;
			pc_i				: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			MemRead_ctrl_i 		: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
			DivStart_ctrl_i		: IN 	STD_LOGIC := '0';
			DivSigned_ctrl_i	: IN 	STD_LOGIC := '0';
			DivRem_ctrl_i		: IN 	STD_LOGIC := '0';
			Reti_ctrl_i			: IN 	STD_LOGIC := '0';
			Branch_ctrl_i 		: IN 	STD_LOGIC;
			Jal_ctrl_i 			: IN 	STD_LOGIC;
			Jalr_ctrl_i 		: IN 	STD_LOGIC;
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			wb_rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_write_data_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			IntrGieWr_i			: IN	STD_LOGIC := '0';
			IntrGieVal_i		: IN	STD_LOGIC := '0';
			IntrTpWr_i			: IN	STD_LOGIC := '0';
			IntrTpVal_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			
			--Outputs
			id_rs1_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			id_rs2_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_pc_o				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			ex_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			ex_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
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
			ex_MemOp_ctrl_o		: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			ex_DivStart_ctrl_o	: OUT	STD_LOGIC;
			ex_DivSigned_ctrl_o	: OUT	STD_LOGIC;
			ex_DivRem_ctrl_o	: OUT	STD_LOGIC;
			ex_Reti_ctrl_o		: OUT	STD_LOGIC;
			ex_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			ex_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
			ex_MemtoReg_ctrl_o 	: OUT	STD_LOGIC;
			gie_o				: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			PC_WIDTH 			: integer := G_PC_WIDTH
		);
		PORT(	
			--Inputs
			clk_i 				: IN 	STD_LOGIC;
			rst_i 				: IN 	STD_LOGIC;
			flush_i				: IN 	STD_LOGIC;
			hold_i				: IN 	STD_LOGIC := '0';
			pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
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
			MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
			DivStart_ctrl_i		: IN 	STD_LOGIC := '0';
			div_result_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			Reti_ctrl_i			: IN 	STD_LOGIC := '0';
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			forward_a_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			forward_b_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			mem_forward_data_i	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_write_data_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
				
			--Outputs
			mem_pc_o			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			mem_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			mem_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mem_alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mem_write_data_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mem_addr_gen_o 		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			mem_brTaken_o 		: OUT	STD_LOGIC;
			mem_rd_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			mem_mul_p0_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mem_mul_p1_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mem_mul_p2_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mem_mul_p3_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mem_Mul_ctrl_o		: OUT	STD_LOGIC;
			mem_Branch_ctrl_o 	: OUT	STD_LOGIC;
			mem_Jal_ctrl_o 		: OUT	STD_LOGIC;
			mem_Jalr_ctrl_o 	: OUT	STD_LOGIC;
			mem_Reti_ctrl_o		: OUT	STD_LOGIC;
			mem_MemRead_ctrl_o 	: OUT	STD_LOGIC;
			mem_MemWrite_ctrl_o : OUT	STD_LOGIC;
			mem_MemOp_ctrl_o	: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			mem_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			mem_RegWrite_ctrl_o : OUT	STD_LOGIC;
			mem_MemtoReg_ctrl_o : OUT	STD_LOGIC;
			fw_rs1_o			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			fw_rs2_o			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------	
	component dmemory is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			DTCM_ADDR_WIDTH 	: integer := 8;
			WORDS_NUM 			: integer := 256;
			PC_WIDTH 			: integer := G_PC_WIDTH
		);
		PORT(	
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
			byte_sel_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
			dtcm_cs_i			: IN 	STD_LOGIC := '1';
			dbus_rdata_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			vec_fetch_i			: IN	STD_LOGIC := '0';
			pc_i				: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			alu_res_i			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			mul_p0_i			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mul_p1_i			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mul_p2_i			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			mul_p3_i			: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			Mul_ctrl_i			: IN	STD_LOGIC;
			RegDst_ctrl_i 		: IN 	STD_LOGIC;
			RegWrite_ctrl_i 	: IN 	STD_LOGIC;
			MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
			
			--Outputs
			dtcm_data_rd_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_wren_o			: OUT	STD_LOGIC;
			mem_forward_data_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_pc_o				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			wb_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			wb_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_alu_res_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_dtcm_data_rd_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			wb_rd_o				: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
			wb_RegDst_ctrl_o 	: OUT	STD_LOGIC;
			wb_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
			wb_MemtoReg_ctrl_o 	: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	component writeback is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			PC_WIDTH 			: integer := G_PC_WIDTH
		);
		PORT(
			alu_res_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_i		: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			MemtoReg_ctrl_i		: IN	STD_LOGIC;
			RegDst_ctrl_i		: IN	STD_LOGIC;
			write_data_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
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
			ex_DivStart_ctrl_i	: IN	STD_LOGIC := '0';
			div_done_i			: IN	STD_LOGIC := '1';
			
			--Outputs
			stall_o				: OUT	STD_LOGIC;
			hold_o				: OUT	STD_LOGIC
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
	component multiplier_1 is
		PORT(
			a_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			b_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p0_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p1_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p2_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p3_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component multiplier_2 is
		PORT(
			p0_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p1_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p2_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p3_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			res_o	: OUT	STD_LOGIC_VECTOR(31 DOWNTO 0)
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
	component pll_gen is
		generic(
			DIVIDE_BY		: NATURAL := G_PLL_DIV;
			MULTIPLY_BY		: NATURAL := G_PLL_MUL;
			IN_PERIOD_PS	: NATURAL := 20000;
			DEVICE_FAMILY	: STRING  := "Cyclone II";
			LPM_HINT_STR	: STRING  := "CBX_MODULE_PREFIX=PLL_GEN"
		);
		PORT(
			areset			: IN	STD_LOGIC := '0';
			inclk0			: IN	STD_LOGIC := '0';
			c0				: OUT	STD_LOGIC;
			locked			: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	component clock_tree is
		generic(
			MODELSIM			: integer := G_MODELSIM;
			IN_FREQ_KHZ			: natural := 50000;
			IN_PERIOD_PS		: natural := 20000;
			MCLK_KHZ			: natural := 20000;
			MCLK_MUL			: natural := 2;
			MCLK_DIV			: natural := 5;
			SMCLK_KHZ			: natural := 20000;
			SMCLK_MUL			: natural := 2;
			SMCLK_DIV			: natural := 5;
			ACCELCLK_KHZ		: natural := 50000;
			ACCEL_MUL			: natural := 1;
			ACCEL_DIV			: natural := 1;
			SMCLK_SHARES_MCLK	: boolean := TRUE;
			SIM_ACCEL_HALF_NS	: natural := 15;
			SIM_SMCLK_HALF_NS	: natural := 35;
			SIM_LOCK_DELAY_NS	: natural := 200
		);
		PORT(
			clk_i		: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			mclk_o		: OUT	STD_LOGIC;
			smclk_o		: OUT	STD_LOGIC;
			accelclk_o	: OUT	STD_LOGIC;
			locked_o	: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	component addr_decoder is
		generic(
			ADDR_WIDTH		: integer := DATA_ADDR_WIDTH;
			DTCM_WORDS_NUM	: integer := G_DATA_WORDSNUM
		);
		PORT(
			addr_i			: IN	STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
			dtcm_cs_o		: OUT	STD_LOGIC;
			sfr_cs_o		: OUT	STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);
			unmapped_o		: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	component BidirPin is
		generic( width : integer := 16 );
		PORT(
			Dout	: IN	STD_LOGIC_VECTOR(width-1 DOWNTO 0);
			en		: IN	STD_LOGIC;
			Din		: OUT	STD_LOGIC_VECTOR(width-1 DOWNTO 0);
			IOpin	: INOUT	STD_LOGIC_VECTOR(width-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component gpo_port is
		generic(
			DATA_WIDTH	: integer := 8
		);
		PORT(
			clk_i		: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			cs_i		: IN	STD_LOGIC;
			MemWrite_i	: IN	STD_LOGIC;
			lane_en_i	: IN	STD_LOGIC := '1';
			data_i		: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component hex_decoder is
		PORT(
			bin : IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			seg : OUT	STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component sync is
		generic(
			DATA_WIDTH	: integer := 32;
			STAGES		: integer := 2;
			GEN_SRC_REG	: boolean := TRUE
		);
		PORT(
			src_clk_i	: IN	STD_LOGIC;
			dst_clk_i	: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			d_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component div_accel is
		generic(
			N	: integer := 32
		);
		PORT(
			divclk_i	: IN	STD_LOGIC;
			divrst_i	: IN	STD_LOGIC;
			divena_i	: IN	STD_LOGIC;
			dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			divbusy_o	: OUT	STD_LOGIC;
			quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			residue_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component div_unit is
		generic(
			N	: integer := 32
		);
		PORT(
			mclk_i		: IN	STD_LOGIC;
			divclk_i	: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			start_i		: IN	STD_LOGIC;
			signed_i	: IN	STD_LOGIC;
			dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			busy_o		: OUT	STD_LOGIC;
			done_o		: OUT	STD_LOGIC;
			quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			remainder_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component basic_timer is
		generic(
			DATA_WIDTH	: integer := 32
		);
		PORT(
			clk_i			: IN	STD_LOGIC;
			rst_i			: IN	STD_LOGIC;
			ctl_cs_i		: IN	STD_LOGIC;
			cmpr0_cs_i		: IN	STD_LOGIC;
			cmpr1_cs_i		: IN	STD_LOGIC;
			MemWrite_i		: IN	STD_LOGIC;
			lane0_i			: IN	STD_LOGIC;
			lane1_i			: IN	STD_LOGIC;
			data_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			capin1_i		: IN	STD_LOGIC := '0';
			capin2_i		: IN	STD_LOGIC := '0';
			pwm_o			: OUT	STD_LOGIC;
			btifg_set_o		: OUT	STD_LOGIC;
			btctl1_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			btctl2_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			btcmpr0_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			btcmpr1_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			btcapr_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			btcnt_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component interrupt_ctrl is
		generic(
			DATA_WIDTH	: integer := 32
		);
		PORT(
			clk_i			: IN	STD_LOGIC;
			rst_i			: IN	STD_LOGIC;
			cs_i			: IN	STD_LOGIC;
			MemWrite_i		: IN	STD_LOGIC;
			lane0_i			: IN	STD_LOGIC;
			lane1_i			: IN	STD_LOGIC;
			data_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
			bt_ifg_set_i	: IN	STD_LOGIC := '0';
			key_pressed_i	: IN	STD_LOGIC_VECTOR(3 DOWNTO 1) := "000";
			rxerr_ev_i		: IN	STD_LOGIC := '0';
			rx_ev_i			: IN	STD_LOGIC := '0';
			tx_ev_i			: IN	STD_LOGIC := '0';
			gie_i			: IN	STD_LOGIC;
			inta_i			: IN	STD_LOGIC := '1';
			intr_o			: OUT	STD_LOGIC;
			type_push_o		: OUT	STD_LOGIC;
			type_capt_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			ie_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			ifg_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			type_o			: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	end component;
---------------------------------------------------------

end aux_package;
