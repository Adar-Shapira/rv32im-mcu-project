LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY writeback IS
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
END writeback;


ARCHITECTURE struct OF writeback IS
	SIGNAL pc_plus4_extended_w : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
BEGIN

	-- Zero-extend PC+4 from PC_WIDTH up to the full 32-bit data bus width
	pc_plus4_extended_w <= ((DATA_BUS_WIDTH-PC_WIDTH-1) DOWNTO 0 => '0') & pc_plus4_i;

-----------------------------------------------------------------------------------------
-- Final Write-Back Data Multiplexer
-----------------------------------------------------------------------------------------
	write_data_o <= pc_plus4_extended_w 	WHEN RegDst_ctrl_i = '1' 	ELSE
					dtcm_data_rd_i 			WHEN MemtoReg_ctrl_i = '1' 	ELSE
					mul_res_i 				WHEN MULOp_ctrl_i = '1' 	ELSE
					alu_res_i;

END struct;