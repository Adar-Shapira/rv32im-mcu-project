LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY stall_unit IS
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
END stall_unit;

ARCHITECTURE logic OF stall_unit IS
	SIGNAL hazard_detected_w : STD_LOGIC;
BEGIN

-----------------------------------------------------------------------------------------
-- Load-Use Hazard Detection
-----------------------------------------------------------------------------------------
	hazard_detected_w <= '1' WHEN (id_ex_MemRead_i = '1') AND 
								  (id_ex_rd_i /= "00000") AND 
								  ((id_ex_rd_i = if_id_rs1_i) OR (id_ex_rd_i = if_id_rs2_i)) 
						ELSE '0';

-----------------------------------------------------------------------------------------
-- Output Routing
-----------------------------------------------------------------------------------------
	stall_IF_o <= hazard_detected_w;
	stall_ID_o <= hazard_detected_w;
	flush_EX_o <= hazard_detected_w;

END logic;