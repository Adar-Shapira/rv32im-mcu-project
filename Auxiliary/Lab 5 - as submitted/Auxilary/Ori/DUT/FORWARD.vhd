LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY forwarding_unit IS
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
END forwarding_unit;


ARCHITECTURE logic OF forwarding_unit IS
BEGIN

-----------------------------------------------------------------------------------------
-- Forwarding A Logic (For rs1)
-----------------------------------------------------------------------------------------
	forward_A_o <= 
		-- 1. EX Hazard: Priority forward from Stage 4
		"10" WHEN (ex_mem_RegWrite_i = '1') AND 	-- Is the register updating?
				  (ex_mem_rd_i /= "00000") AND 		-- All the registers except x0
				  (ex_mem_rd_i = id_ex_rs1_i) 		-- Is the register that is updating the same as the input?
		ELSE  
		-- 2. MEM Hazard: Forward from Stage 5 
		-- (Ensures Stage 4 is NOT also trying to write to the exact same register)
		"01" WHEN (mem_wb_RegWrite_i = '1') AND 
				  (mem_wb_rd_i /= "00000") AND 
				  (NOT (ex_mem_RegWrite_i = '1' AND ex_mem_rd_i /= "00000" AND ex_mem_rd_i = id_ex_rs1_i)) AND
				  (mem_wb_rd_i = id_ex_rs1_i) 
		ELSE 
		-- 3. Default: Use raw register data
		"00";

-----------------------------------------------------------------------------------------
-- Forwarding B Logic (For rs2)
-----------------------------------------------------------------------------------------
	forward_B_o <= 
		-- 1. EX Hazard: Priority forward from Stage 4
		"10" WHEN (ex_mem_RegWrite_i = '1') AND  	
				  (ex_mem_rd_i /= "00000") AND 		
				  (ex_mem_rd_i = id_ex_rs2_i) 		
		ELSE  
		-- 2. MEM Hazard: Forward from Stage 5 
		-- (Ensures Stage 4 is NOT also trying to write to the exact same register)
		"01" WHEN (mem_wb_RegWrite_i = '1') AND 
				  (mem_wb_rd_i /= "00000") AND 
				  (NOT (ex_mem_RegWrite_i = '1' AND ex_mem_rd_i /= "00000" AND ex_mem_rd_i = id_ex_rs2_i)) AND
				  (mem_wb_rd_i = id_ex_rs2_i) 
		ELSE 
		-- 3. Default: Use raw register data
		"00";

END logic;