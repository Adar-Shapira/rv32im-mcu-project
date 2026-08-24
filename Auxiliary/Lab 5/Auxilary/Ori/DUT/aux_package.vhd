library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;


package aux_package is
-------------------------------------------------------------------------------------
	component RV32IM_CORE IS
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
			FHCNT_o				: out	std_logic_vector(CNT_WIDTH-1 downto 0);	
			STCNT_o				: out	std_logic_vector(CNT_WIDTH-1 downto 0);
			
			-- SignalTap Trigger 
			STRIGGER_o			: out	std_logic
		);
	END component;
-------------------------------------------------------------------------------------
	component Ifetch IS
		generic(
			WORD_GRANULARITY 	: boolean	:= False;
			DATA_BUS_WIDTH 		: integer	:= 32;
			PC_WIDTH 			: integer	:= 10;
			ITCM_ADDR_WIDTH 	: integer	:= 8;
			WORDS_NUM 			: integer	:= 256
		);
		PORT(
			--Inputs
			clk_i           : IN  STD_LOGIC;
			rst_i           : IN  STD_LOGIC;
			ena_i           : IN  STD_LOGIC; 								-- Freezes PC during a pipeline stall
			pc_sel_i        : IN  STD_LOGIC; 								-- '1' when a branch or jump is taken in Stage 4
			branch_target_i : IN  STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0); 	-- Resolved target from Stage 4
			
			--Outputs
			pc_o            : OUT STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_o      : OUT STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o   : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component Idecode IS
		generic(
			PC_WIDTH 		: integer := 10;
			DATA_BUS_WIDTH	: integer := 32
		);
		PORT(
			--Inputs from IF/ID Pipeline Register
			clk_i           : IN  STD_LOGIC;
			rst_i           : IN  STD_LOGIC;
			instruction_i   : IN  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			-- Inputs from MEM/WB Pipeline Register (Stage 5)
			rd_i            : IN  STD_LOGIC_VECTOR(4 DOWNTO 0); -- Destination register to write to
			write_data_i    : IN  STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); -- Data to write
			RegWrite_ctrl_i : IN  STD_LOGIC; -- Write enable signal
			
			--Outputs to ID/EX Pipeline Register
			read_data1_o    : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o    : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			SignExt_o       : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			-- Extracted register addresses for the pipeline
			rs1_o 			: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			rs2_o 			: OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
			rd_o  			: OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component control IS
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
			MULOp_ctrl_o     	: OUT	STD_LOGIC   -- New control output
		);
	END component;
-------------------------------------------------------------------------------------	
	component Execute IS
		generic(
			DATA_BUS_WIDTH 	: integer := 32;
			PC_WIDTH 		: integer := 10
		);
		PORT(	
			--Inputs
			read_data1_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			sign_extend_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			MULOp_ctrl_i		: IN 	STD_LOGIC;		
			pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			
			-- Forwarding Inputs
			forward_A_ctrl_i   	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			forward_B_ctrl_i   	: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			mem_forward_data_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); -- From EX/MEM
			wb_forward_data_i  	: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0); -- From MEM/WB
				
			-- Standard Outputs to EX/MEM
			brTaken_o 			: OUT	STD_LOGIC;
			alu_res_o 			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_gen_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			rs2_forwarded_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			-- Multiplier Stage 1 Outputs to EX/MEM
			P0_o				: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P1_o				: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P2_o				: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P3_o				: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component dmemory IS
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			DTCM_ADDR_WIDTH 	: integer := 8;
			WORDS_NUM 			: integer := 256
		);
		PORT(	
			-- Standard Memory Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			
			-- Multiplier Stage 2 Inputs (From EX/MEM)
			P0_i 				: IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P1_i 				: IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P2_i 				: IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
			P3_i 				: IN 	STD_LOGIC_VECTOR(15 DOWNTO 0);
			
			-- Outputs to MEM/WB
			dtcm_data_rd_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mul_res_o 		: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component writeback IS
		generic(
			DATA_BUS_WIDTH 	: integer := 32;
			PC_WIDTH 		: integer := 10
		);
		PORT(	
			-- Data Inputs from MEM/WB Pipeline Register
			alu_res_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			mul_res_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			pc_plus4_i 		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			
			-- Control Inputs from MEM/WB Pipeline Register
			MemtoReg_ctrl_i : IN 	STD_LOGIC;
			RegDst_ctrl_i 	: IN 	STD_LOGIC; -- Selects PC+4 for JAL/JALR
			MULOp_ctrl_i 	: IN 	STD_LOGIC;
			
			-- Output to Register File and Forwarding Unit
			write_data_o 	: OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component stall_unit IS
		PORT(
			-- Inputs from ID/EX Pipeline Register (Stage 3)
			id_ex_MemRead_i	: IN STD_LOGIC;                      -- Is the instruction in Execute a Load?
			id_ex_rd_i		: IN STD_LOGIC_VECTOR(4 DOWNTO 0);   -- The destination register of the Load
			
			-- Inputs from IDECODE Module (Stage 2)
			if_id_rs1_i		: IN STD_LOGIC_VECTOR(4 DOWNTO 0);   -- Source register 1 of the decoded instruction
			if_id_rs2_i		: IN STD_LOGIC_VECTOR(4 DOWNTO 0);   -- Source register 2 of the decoded instruction
			
			-- Outputs to Pipeline Registers and Fetch
			stall_IF_o		: OUT STD_LOGIC;                     -- Freezes the Program Counter
			stall_ID_o		: OUT STD_LOGIC;                     -- Freezes the IF/ID Register
			flush_EX_o		: OUT STD_LOGIC                      -- Zeroes the ID/EX Register controls
		);
	END component;
-------------------------------------------------------------------------------------
	component forwarding_unit IS
		PORT(
			-- Source Registers from Execute Stage (Stage 3)
			id_ex_rs1_i			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			id_ex_rs2_i			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			
			-- Destination Register & Control from Memory Stage (Stage 4)
			ex_mem_rd_i			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			ex_mem_RegWrite_i	: IN STD_LOGIC;
			
			-- Destination Register & Control from Write-Back Stage (Stage 5)
			mem_wb_rd_i			: IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			mem_wb_RegWrite_i	: IN STD_LOGIC;
			
			-- Forwarding Multiplexer Controls to Execute Stage
			forward_A_o			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			forward_B_o			: OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
		);
	END component;
-------------------------------------------------------------------------------------
	component multiplier_1 is
		port(
			Ain 	: in std_logic_vector(15 downto 0);
			Bin 	: in std_logic_vector(15 downto 0);
			
			-- Multiplier Stage 1 Outputs
			P0_o 	: out std_logic_vector(15 downto 0);
			P1_o 	: out std_logic_vector(15 downto 0);
			P2_o 	: out std_logic_vector(15 downto 0);
			P3_o 	: out std_logic_vector(15 downto 0)
		);
	end component;
-------------------------------------------------------------------------------------
	component multiplier_2 is
		port(
			P0_i 	: in std_logic_vector(15 downto 0);
			P1_i 	: in std_logic_vector(15 downto 0);
			P2_i 	: in std_logic_vector(15 downto 0);
			P3_i 	: in std_logic_vector(15 downto 0);
			
			Res 	: out std_logic_vector(31 downto 0)
		);
	end component;
-------------------------------------------------------------------------------------
	component PLL IS
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC ;
			locked		: OUT STD_LOGIC 
		);
	END component;
end aux_package;