--============================================================================
-- Copyright 2026 Hananya Ribo
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - WB stage
-- WRITEBACK is the Figure 7 write-back mux. Mul vs ALU is already selected
-- in MEM (mem_result_w latched as wb_alu_res), so this mux has three inputs:
--   * PC+4 for jal/jalr (RegDst)
--   * ALU/mul result when MemtoReg is 0
--   * DTCM load data when MemtoReg is 1
-- The result feeds the register-file write port in IDECODE, ID-stage RF
-- bypass, and EX-stage WB forwarding.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.const_package.all;

ENTITY writeback IS
	generic(
		DATA_BUS_WIDTH 	: integer := 32;
		PC_WIDTH 		: integer := 10
	);
	PORT(
		-- MEM/WB pipeline-register values
		alu_res_i		: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		dtcm_data_rd_i	: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		pc_plus4_i		: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		MemtoReg_ctrl_i	: IN	STD_LOGIC;
		RegDst_ctrl_i	: IN	STD_LOGIC;

		-- RF write data / forwarding source
		write_data_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END writeback;

ARCHITECTURE struct OF writeback IS
BEGIN
	write_data_o <=	ZEROS_DBUS2PCADDR & pc_plus4_i			WHEN	RegDst_ctrl_i		ELSE
					alu_res_i(DATA_BUS_WIDTH-1 DOWNTO 0)	WHEN	not MemtoReg_ctrl_i	ELSE
					dtcm_data_rd_i;
END struct;
