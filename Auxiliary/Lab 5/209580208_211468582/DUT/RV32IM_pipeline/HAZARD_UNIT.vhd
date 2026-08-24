--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - Hazard detection unit (combinational check)
-- Detects the single data hazard that full forwarding cannot cover: the
-- load-use hazard at distance 1. A load produces its data only at the end
-- of its MEM cycle, so an immediately following consumer cannot get the
-- value forwarded into its EX stage; it must be delayed by one cycle.
--
-- Check (purely combinational, no state):
--   the EX-stage instruction is a load (ex_MemRead from the ID/EX register)
--   AND its destination register matches rs1 or rs2 of the ID-stage
--   instruction (x0 excluded - it is hard-wired to zero and never forwarded).
--
-- On stall_o = '1' the top applies a one-cycle interlock:
--   * IFETCH freezes the PC and holds the IF/ID register (the ID-stage
--     instruction is replayed next cycle)
--   * IDECODE injects a bubble into the ID/EX register (the load itself
--     proceeds normally down the pipe)
--
-- One stall cycle is sufficient:
--   * after the stall the consumer is still in ID while the load is in MEM;
--     when the consumer finally reaches EX the load is in WB and its data
--     is forwarded by FORWARD_UNIT (select "01", WB write-back data)
--   * a consumer 2 instructions behind a load meets it the same way
--     (consumer in EX, load in WB) - no stall needed
--   * a consumer 3 instructions behind reads the RF in ID while the load
--     writes it in WB - covered by the RF read bypass inside IDECODE
--
-- The remaining hazard sources need no stall: ALU results are forwarded
-- from EX/MEM, and jal/jalr/taken-branch producers in MEM flush all 3
-- younger instructions, so their rd is never matched by an in-flight
-- consumer. A flush from MEM overrides a simultaneous stall in the top
-- (the redirecting instruction is older, so the stall is moot).
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY HAZARD_UNIT IS
	PORT(
		--Inputs
		-- ID-stage source registers (combinational, from IDECODE)
		id_rs1_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		id_rs2_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- EX-stage instruction info (from the ID/EX register in IDECODE)
		ex_MemRead_ctrl_i	: IN	STD_LOGIC;						-- EX-stage instruction is a load
		ex_rd_i				: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);	-- EX-stage destination register

		--Outputs
		stall_o				: OUT	STD_LOGIC						-- freeze PC + IF/ID, bubble into ID/EX
	);
END HAZARD_UNIT;


ARCHITECTURE behavior OF HAZARD_UNIT IS
	CONSTANT R0	: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";	-- x0, hard-wired to zero
BEGIN

	-- load-use interlock: load in EX, dependent consumer in ID
	stall_o	<=	'1'	WHEN (	ex_MemRead_ctrl_i = '1'	AND
							ex_rd_i /= R0			AND
							(ex_rd_i = id_rs1_i OR ex_rd_i = id_rs2_i))	ELSE
				'0';

END behavior;
