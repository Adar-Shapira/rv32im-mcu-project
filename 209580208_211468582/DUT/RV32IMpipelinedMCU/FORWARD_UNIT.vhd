--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - Forwarding unit (full forwarding)
-- Purely combinational: compares the EX-stage source registers (rs1/rs2
-- from the ID/EX register) against the destination registers of the two
-- older instructions still in flight, and drives the select lines of the
-- two forwarding muxes in front of the ALU operands inside EXECUTE.
--
-- Forwarding sources (encoding shared with the muxes in EXECUTE):
--   "10" FWD_MEM  - EX/MEM ALU result, producer 1 instruction ahead
--   "01" FWD_WB   - WB write-back mux output (ALU result / load data /
--                   PC+4), producer 2 instructions ahead
--   "00" FWD_NONE - no match, the ID/EX register-file value is used
--
-- Match condition per source: RegWrite = '1' AND rd /= x0 AND rd = rs.
-- When both stages match the same rs, EX/MEM wins - it is the younger of
-- the two producers, i.e. the last writer of that register in program
-- order, exactly as in the classic MIPS forwarding unit.
--
-- Distance-3 producers (in WB while the consumer reads the RF in ID) are
-- covered by the read-port bypass inside IDECODE, not here.
--
-- Why the EX/MEM ALU result is always safe to forward:
--   * a load in MEM (data not in alu_res) can never have its consumer in
--     EX - the HAZARD_UNIT load-use stall keeps the consumer a cycle back,
--     so it meets the load from WB via FWD_WB
--   * jal/jalr in MEM (rd value is PC+4, not alu_res) redirect the PC and
--     flush the 3 younger instructions, so the consumer in EX is killed
--     before its result is used
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY FORWARD_UNIT IS
	PORT(
		--Inputs
		-- EX-stage source registers (from the ID/EX register in IDECODE)
		ex_rs1_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ex_rs2_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- MEM-stage producer (from the EX/MEM register in EXECUTE)
		mem_RegWrite_ctrl_i	: IN	STD_LOGIC;
		mem_rd_i			: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- WB-stage producer (from the MEM/WB register in DMEMORY)
		wb_RegWrite_ctrl_i	: IN	STD_LOGIC;
		wb_rd_i				: IN	STD_LOGIC_VECTOR(4 DOWNTO 0);

		--Outputs (select lines of the EXECUTE forwarding muxes)
		forward_a_o			: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);	-- rs1 (ALU A operand)
		forward_b_o			: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0)	-- rs2 (ALU B operand / store data)
	);
END FORWARD_UNIT;


ARCHITECTURE behavior OF FORWARD_UNIT IS
	CONSTANT R0			: STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";	-- x0, hard-wired to zero
	-- must match the mux encoding in EXECUTE
	CONSTANT FWD_NONE	: STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";		-- ID/EX register value
	CONSTANT FWD_WB		: STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";		-- WB write-back data (distance 2)
	CONSTANT FWD_MEM	: STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";		-- EX/MEM ALU result (distance 1)

	SIGNAL mem_fwd_en_w	: STD_LOGIC;
	SIGNAL wb_fwd_en_w	: STD_LOGIC;

BEGIN
	-- a stage can forward only if it actually writes a register (and not x0)
	mem_fwd_en_w	<= '1' WHEN (mem_RegWrite_ctrl_i = '1' AND mem_rd_i /= R0)	ELSE '0';
	wb_fwd_en_w		<= '1' WHEN (wb_RegWrite_ctrl_i  = '1' AND wb_rd_i  /= R0)	ELSE '0';

	-- rs1 (ALU A operand): EX/MEM has priority over MEM/WB (last writer wins)
	forward_a_o		<=	FWD_MEM		WHEN (mem_fwd_en_w = '1' AND mem_rd_i = ex_rs1_i)	ELSE
						FWD_WB		WHEN (wb_fwd_en_w  = '1' AND wb_rd_i  = ex_rs1_i)	ELSE
						FWD_NONE;

	-- rs2 (ALU B operand / store data): same check on the second source
	forward_b_o		<=	FWD_MEM		WHEN (mem_fwd_en_w = '1' AND mem_rd_i = ex_rs2_i)	ELSE
						FWD_WB		WHEN (wb_fwd_en_w  = '1' AND wb_rd_i  = ex_rs2_i)	ELSE
						FWD_NONE;

END behavior;
