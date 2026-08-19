--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - MEM stage
-- DMEMORY holds the DTCM (altsyncram, written on the inverted clock exactly
-- as in the single-cycle version) and the MEM/WB pipeline register.
-- Pipeline changes vs the single-cycle version:
--   * the MEM/WB pipeline register is added around the DTCM: it carries the
--     load data, the ALU result, PC+4, the destination register and the
--     WB-stage control bits (RegDst/RegWrite/MemtoReg) to the write-back
--     mux in IDECODE; wb_rd_o/wb_RegWrite_ctrl_o also feed FORWARD_UNIT
--   * no stall/flush port: branches and jumps are resolved in the MEM
--     stage, so the MEM-stage instruction is always older than any
--     redirect/stall and always proceeds to WB
-- DTCM timing within the MEM cycle: the address register is loaded at the
-- falling edge (inverted clock) and the output is unregistered, so the read
-- data is valid in the second half of the cycle and is latched into the
-- MEM/WB register at the next rising edge; a store is likewise committed at
-- the falling edge of its MEM cycle.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	generic(
		DATA_BUS_WIDTH 	: integer := 32;
		DTCM_ADDR_WIDTH : integer := 8;
		WORDS_NUM 		: integer := 256;
		PC_WIDTH 		: integer := 10
	);
	PORT(	
		--Inputs
		clk_i				: IN 	STD_LOGIC;
		rst_i				: IN 	STD_LOGIC;
		-- EX/MEM inputs (MEM-stage view produced by EXECUTE)
		dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);	-- sliced from mem_alu_res in the top
		dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- store data (forwarded rs2 value)
		MemRead_ctrl_i  	: IN 	STD_LOGIC;
		MemWrite_ctrl_i 	: IN 	STD_LOGIC;
		-- MEM-stage values carried through to the MEM/WB register
		pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- WB value for jal/jalr
		alu_res_i			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- WB value for ALU instructions
		rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- WB-stage control bits (from the EX/MEM register)
		RegDst_ctrl_i 		: IN 	STD_LOGIC;
		RegWrite_ctrl_i 	: IN 	STD_LOGIC;
		MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
		
		--Outputs
		-- MEM-stage (combinational) - debug/Signal-Tap
		dtcm_data_rd_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- MEM/WB pipeline register outputs (WB-stage view, to IDECODE + FORWARD_UNIT)
		wb_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		wb_alu_res_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		wb_dtcm_data_rd_o 	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- WB value for loads
		wb_rd_o				: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);					-- FORWARD_UNIT + RF write port
		-- carried control bits: WB stage (wb_RegWrite also feeds FORWARD_UNIT)
		wb_RegDst_ctrl_o 	: OUT	STD_LOGIC;
		wb_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
		wb_MemtoReg_ctrl_o 	: OUT	STD_LOGIC
	);
END dmemory;


ARCHITECTURE behavior OF dmemory IS
	SIGNAL wrclk_w 				: STD_LOGIC;
	SIGNAL dtcm_data_rd_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- MEM/WB pipeline register
	SIGNAL mem_wb_pc_plus4_q	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_alu_res_q		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_dtcm_data_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mem_wb_rd_q			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL mem_wb_RegDst_q		: STD_LOGIC;
	SIGNAL mem_wb_RegWrite_q	: STD_LOGIC;
	SIGNAL mem_wb_MemtoReg_q	: STD_LOGIC;
	
BEGIN
	--=======================================
	-- DTCM (RAM) connection - unchanged
	--=======================================
	data_memory : altsyncram
	GENERIC MAP  (
		operation_mode			=> "SINGLE_PORT",
		width_a					=> DATA_BUS_WIDTH,
		widthad_a				=> DTCM_ADDR_WIDTH,
		numwords_a 				=> WORDS_NUM,
		lpm_hint 				=> "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = DTCM",
		lpm_type 				=> "altsyncram",
		outdata_reg_a 			=> "UNREGISTERED",
		init_file 				=> "C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex",
		intended_device_family 	=> "Cyclone"
	)
	PORT MAP (
		wren_a 					=> MemWrite_ctrl_i,
		clock0					=> wrclk_w,
		address_a				=> dtcm_addr_i,
		data_a					=> dtcm_data_wr_i,
		q_a						=> dtcm_data_rd_w	
	);

	wrclk_w <= NOT clk_i;	-- Load memory address register with write clock

--------------------------------------------------------------------------------------------------------
-- MEM/WB pipeline register
-- The MEM-stage instruction is never stalled or flushed (redirects originate
-- here), so the register loads unconditionally every rising edge.
--------------------------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
BEGIN
	IF rst_i = '1' THEN
		mem_wb_pc_plus4_q	<= (OTHERS => '0');
		mem_wb_alu_res_q	<= (OTHERS => '0');
		mem_wb_dtcm_data_q	<= (OTHERS => '0');
		mem_wb_rd_q			<= (OTHERS => '0');
		mem_wb_RegDst_q		<= '0';
		mem_wb_RegWrite_q	<= '0';
		mem_wb_MemtoReg_q	<= '0';
	ELSIF (clk_i'EVENT AND clk_i='1') THEN
		mem_wb_pc_plus4_q	<= pc_plus4_i;
		mem_wb_alu_res_q	<= alu_res_i;
		mem_wb_dtcm_data_q	<= dtcm_data_rd_w;
		mem_wb_rd_q			<= rd_i;
		mem_wb_RegDst_q		<= RegDst_ctrl_i;
		mem_wb_RegWrite_q	<= RegWrite_ctrl_i;
		mem_wb_MemtoReg_q	<= MemtoReg_ctrl_i;
	END IF;
END PROCESS;

--------------------------------------------------------------------------------------------------------
	-- MEM-stage output (combinational)
	dtcm_data_rd_o		<= dtcm_data_rd_w;
	
	-- MEM/WB register outputs (WB-stage view)
	wb_pc_plus4_o		<= mem_wb_pc_plus4_q;
	wb_alu_res_o		<= mem_wb_alu_res_q;
	wb_dtcm_data_rd_o	<= mem_wb_dtcm_data_q;
	wb_rd_o				<= mem_wb_rd_q;
	wb_RegDst_ctrl_o	<= mem_wb_RegDst_q;
	wb_RegWrite_ctrl_o	<= mem_wb_RegWrite_q;
	wb_MemtoReg_ctrl_o	<= mem_wb_MemtoReg_q;
--------------------------------------------------------------------------------------------------------
	
END behavior;
