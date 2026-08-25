--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Top Level Structural Model for Single-Cycle RISC-V Core
-- Idecode module (register file, instruction field extraction, immediate
-- generation + sign extension, and the write-back mux)
-- RV32IM: copied unchanged from RV32I -- mul is R-type, so register reads,
--         rd write-back and immediates all work exactly as before
--============================================================================ 
LIBRARY IEEE; 		
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.const_package.all;
USE work.cond_compilation_package.all;	-- G_ISA_REPAIR (defect-repair switch)


ENTITY Idecode IS
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
		-- Phase 7B2. Figure 3 widens the write-back mux and selects it with
		-- WBSrc1/WBSrc0; these are that widening. div_result_i is already the
		-- quotient or the remainder -- RV32IM_CORE picks between them from the
		-- DivRem control bit, so this mux stays one bit wide. Both are defaulted,
		-- so an instantiation that predates the divider behaves exactly as before.
		DivSel_ctrl_i		: IN 	STD_LOGIC := '0';
		div_result_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

		-- Phase 9B. The interrupt protocol's two register-file side doors,
		-- REQ p15 + p13 rules e/f. GIE lives in gp[0] (= RF x3) and the return
		-- address goes to tp (= RF x4); both writes happen in cycles where the
		-- normal write port is provably idle -- entry cycles are annulled by the
		-- core, and reti is a jalr with rd = x0, which the RF guard below
		-- discards anyway. All defaulted so an instantiation that predates the
		-- interrupt protocol behaves exactly as before.
		IntrGieWr_i			: IN	STD_LOGIC := '0';	-- write gp[0] this edge...
		IntrGieVal_i		: IN	STD_LOGIC := '0';	-- ...with this value ('0' entry, '1' reti)
		IntrTpWr_i			: IN	STD_LOGIC := '0';	-- write tp this edge...
		IntrTpVal_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

		--Outputs
		read_data1_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o		: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		SignExt_o 			: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		-- Phase 9B. GIE = gp[0], tapped straight off the register file for the
		-- interrupt controller's INTR gate (the p13 AND with GIE). A dedicated
		-- tap, not a read port: both read ports are owned by the instruction's
		-- rs1/rs2 fields every cycle.
		gie_o				: OUT	STD_LOGIC
	);
END Idecode;


ARCHITECTURE behavior OF Idecode IS
TYPE register_file IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL RF_q							: register_file;
	SIGNAL write_data_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	SIGNAL opc_w						: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL rs1_w						: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL rs2_w						: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL rd_w							: STD_LOGIC_VECTOR(4 DOWNTO 0);
	
	SIGNAL Iimm_w						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Simm_w						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL SBimm_w						: STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL Uimm_w						: STD_LOGIC_VECTOR(19 DOWNTO 0);
	SIGNAL UJimm_w						: STD_LOGIC_VECTOR(19 DOWNTO 0);
	
	SIGNAL SignExt_Iimm_w				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL SignExt_Simm_w				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL SignExt_SBimm_w				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL SignExt_Uimm_w				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL SignExt_UJimm_w				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- G_ISA_REPAIR-gated immediates for defects 3 (loads) and 2 (lui)
	SIGNAL load_imm_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL lui_imm_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
	opc_w	<= instruction_i(6 DOWNTO 0); 
	
	rs1_w	<= instruction_i(19 DOWNTO 15);
  	rs2_w	<= instruction_i(24 DOWNTO 20);
  	rd_w	<= instruction_i(11 DOWNTO 7);
	
  	Iimm_w 	<= instruction_i(31 DOWNTO 20);
	Simm_w 	<= instruction_i(31 DOWNTO 25) & instruction_i(11 DOWNTO 7);
	SBimm_w <= instruction_i(31) & instruction_i(7) & instruction_i(30 DOWNTO 25) & instruction_i(11 DOWNTO 8);
	Uimm_w 	<= instruction_i(31 DOWNTO 12);
	UJimm_w <= instruction_i(31) & instruction_i(19 DOWNTO 12) & instruction_i(20) & instruction_i(30 DOWNTO 21);
	
	-- Read the Register 1 output of the Register-File
	read_data1_o <= RF_q(CONV_INTEGER(rs1_w));
	
	-- Read the Register 2 output of the Register-File		 
	read_data2_o <= RF_q(CONV_INTEGER(rs2_w));
	
	-- Mux to bypass data memory for Rformat instructions
	-- Phase 7B2: the divider arm sits ABOVE the ALU arm because a div is an
	-- R-type instruction, so MemtoReg is '0' for it and it would otherwise take
	-- the ALU result. It sits BELOW RegDst so jal/jalr are unaffected.
	write_data_w <= ZEROS_DBUS2PCADDR & pc_plus4_i			WHEN	RegDst_ctrl_i			ELSE
					div_result_i							WHEN	DivSel_ctrl_i = '1'		ELSE
					alu_res_i(DATA_BUS_WIDTH-1 DOWNTO 0) 	WHEN	not MemtoReg_ctrl_i 	ELSE 
					dtcm_data_rd_i;
	
	-- Sign Extend 16-bits to 32-bits
  	SignExt_Iimm_w 	<=	ZEROS_IMM20 & Iimm_w 	WHEN	not Iimm_w(11) 	ELSE ONES_IMM20 & Iimm_w;
	SignExt_Simm_w 	<=	ZEROS_IMM20	& Simm_w 	WHEN 	not Simm_w(11)	ELSE ONES_IMM20 & Simm_w;
	SignExt_SBimm_w <=	ZEROS_IMM20	& SBimm_w 	WHEN 	not SBimm_w(11)	ELSE ONES_IMM20 & SBimm_w;
	SignExt_Uimm_w 	<=	ZEROS_IMM12 & Uimm_w 	WHEN 	not Uimm_w(19) 	ELSE ONES_IMM12 & Uimm_w;
	SignExt_UJimm_w	<=	ZEROS_IMM12 & UJimm_w 	WHEN 	not UJimm_w(19) ELSE ONES_IMM12 & UJimm_w;

	
	-- Defect 3 (load offsets): the as-submitted select has no LOAD_OPC arm, so every
	-- lb/lh/lw/lbu/lhu falls through to (others => '0') and addresses rs1+0 regardless of
	-- its immediate. Defect 2 (lui): the UTYPE_OPC arm is an exact match against
	-- ("0010111" and "0110111") = "0010111" = auipc's opcode, so auipc matches and lui
	-- never does -- lui's immediate is 0, and since CONTROL forces ALU input A to zero for
	-- lui, lui writes 0. Repair reference, both defects:
	--   Auxiliary/Lab 5/DUT/RV32IM_pipeline/IDECODE.vhd:178,181,182
	-- which splits UTYPE_OPC into AUIPC_OPC/LUI_OPC and adds the LOAD_OPC arm.
	-- AUIPC_OPC = UTYPE_OPC's effective value, so the auipc path is unchanged either way.
	load_imm_w	<=	SignExt_Iimm_w								WHEN G_ISA_REPAIR ELSE (others => '0');
	lui_imm_w	<=	SignExt_Uimm_w(19 DOWNTO 0) & ZEROS_IMM12	WHEN G_ISA_REPAIR ELSE (others => '0');

	with	opc_w select
		SignExt_o 	<=	SignExt_Iimm_w				when ITYPE_OPC,
		SignExt_Iimm_w								when INST_JALR(6 DOWNTO 0),
		load_imm_w									when LOAD_OPC,
		SignExt_Simm_w								when STYPE_OPC,
		SignExt_SBimm_w 							when SBTYPE_OPC,
		SignExt_Uimm_w(19 DOWNTO 0) & ZEROS_IMM12	when AUIPC_OPC,
		lui_imm_w									when LUI_OPC,
		SignExt_UJimm_w								when UJTYPE_OPC,
		(others => '0')								when others;
	--==============================================================================
	--	Register-File(RF) structure
	--==============================================================================
	process(clk_i,rst_i)
	begin
		if (rst_i='1') then
			FOR i IN 0 TO 31 LOOP
				RF_q(i) <= CONV_STD_LOGIC_VECTOR(0,32);
			END LOOP;
		elsif (clk_i'event and clk_i='1') then
			if (RegWrite_ctrl_i = '1' AND rd_w /= 0) then	-- RF(0) hard-wired of value zero
				RF_q(CONV_INTEGER(rd_w)) <= write_data_w;
				-- index type is integer so we must use conv_integer for type casting
			end if;
			-- Phase 9B: the protocol's side doors, AFTER the normal write so they
			-- win if both ever named the same register in the same cycle -- which
			-- cannot happen (entry cycles are annulled; reti's rd is x0), but the
			-- ordering makes the priority explicit rather than accidental.
			--   GIE: only bit 0 moves; gp's other 31 bits are untouched, so a
			--   program using gp as a real global pointer keeps it intact.
			if (IntrGieWr_i = '1') then
				RF_q(3)(0) <= IntrGieVal_i;
			end if;
			if (IntrTpWr_i = '1') then
				RF_q(4) <= IntrTpVal_i;
			end if;
		end if;
	end process;

	-- Phase 9B: the GIE tap -- see the port comment.
	gie_o <= RF_q(3)(0);

END behavior;
