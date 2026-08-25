--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Control-Unit module (RV32IM: adds mul decode -> ALU_MUL)
--============================================================================ 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;
USE work.cond_compilation_package.all;	-- G_ISA_REPAIR (defect-repair switch)


ENTITY control IS
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
		-- Phase 3B (G-309): the access width and signedness of a load or store.
		-- CONTROL already detected lb/lh/lw/lbu/lhu/sb/sh/sw and then threw the
		-- width away; this port is what carries it to DMEMORY.
		MemOp_ctrl_o		: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0);

		-- Phase 7B2. Figure 3 gives the Control Unit a DIVstart output; these are
		-- it plus the two qualifiers the division subsystem needs.
		--   DivStart : any of div / divu / rem / remu is the current instruction.
		--              A LEVEL, not a pulse -- this is combinational decode, so it
		--              stays asserted for the whole stall, which is exactly what
		--              DIV_UNIT's handshake is built to expect.
		--   DivSigned: div / rem  (as opposed to divu / remu).
		--   DivRem   : rem / remu (the remainder is wanted, not the quotient).
		DivStart_ctrl_o		: OUT	STD_LOGIC;
		DivSigned_ctrl_o	: OUT	STD_LOGIC;
		DivRem_ctrl_o		: OUT	STD_LOGIC;

		-- Phase 9B. reti = the exact encoding `jalr zero,0(tp)` (io_map.s's own
		-- .eqv; INST_RETI in const_package). The jalr executes normally -- this
		-- output only tells the core to set GIE = gp[0] in HW at the same edge,
		-- REQ p13 rule f. Full 32-bit compare, no mask: any other jalr (other
		-- rd, other rs1, nonzero imm) is NOT a return from interrupt.
		Reti_ctrl_o			: OUT	STD_LOGIC
	);
END control;


ARCHITECTURE behavior OF control IS

	SIGNAL	Rtype_w, Itype_w, Stype_w, SBtype_w, Utype_w, UJtype_w 								: STD_LOGIC;
	SIGNAL	lb_w, lh_w, lw_w, lbu_w, lhu_w, lwu_w, ld_w, sb_w, sh_w, sw_w, st_w					: STD_LOGIC;
	SIGNAL	beq_w, bne_w, blt_w, bge_w, bltu_w, bgeu_w, branch_w, jal_w, jalr_w 				: STD_LOGIC;
	SIGNAL	add_w, addi_w, and_w, andi_w, or_w, ori_w, sll_w, slli_w, sra_w, srai_w				: STD_LOGIC;
	SIGNAL	srl_w, srli_w, sub_w, xor_w, xori_w, auipc_w, lui_w, slt_w, slti_w, sltu_w, sltiu_w	: STD_LOGIC;
	SIGNAL	mul_w : STD_LOGIC;	-- M-extension: mul detector
	-- M-extension division, Phase 7B2. The four encodings were already in
	-- const_package.vhd and were simply never decoded; they are funct7 = 0000001
	-- with funct3 = 100/101/110/111 on the R-type opcode, and each mask is
	-- 0xFE00707F, so funct7 is part of the compare. That matters: div's funct3 of
	-- 100 is the same as xor's, and only the funct7 bit tells them apart -- with a
	-- narrower mask a div would decode as a xor and quietly compute one.
	SIGNAL	div_w, divu_w, rem_w, remu_w, divop_w : STD_LOGIC;
	SIGNAL  opc_w : STD_LOGIC_VECTOR(6 DOWNTO 0);
	-- Defect 1 (andi): the as-submitted ALUOp select tests ori_w on the ALU_AND arm, so
	-- andi never reaches ALU_AND (it falls through to ALU_OR, computing an OR) and the
	-- ALU_OR arm fires for both andi and ori. Repair reference:
	--   Auxiliary/Lab 5/DUT/RV32IM_pipeline/CONTROL.vhd:147
	--     ALU_AND WHEN and_w or andi_w ELSE
	SIGNAL	andi_sel_w : STD_LOGIC;

BEGIN
	opc_w 		<=	instruction_i(6 DOWNTO 0);
	andi_sel_w	<=	andi_w WHEN G_ISA_REPAIR ELSE ori_w;
	-- Code to generate control signals using opcode bits
	Rtype_w		<=  '1'	WHEN	opc_w = RTYPE_OPC  ELSE '0';
	Itype_w		<=  '1'	WHEN	(opc_w = ITYPE_OPC) or (ld_w = '1') or (jalr_w = '1') ELSE '0';
	Stype_w 	<=  '1'	WHEN	opc_w = STYPE_OPC  ELSE '0';
	SBtype_w 	<=  '1'	WHEN	opc_w = SBTYPE_OPC ELSE '0';
	Utype_w 	<=  '1'	WHEN	((opc_w and UTYPE_OPC) = UTYPE_OPC)  ELSE '0';
	UJtype_w 	<=  '1'	WHEN	opc_w = UJTYPE_OPC ELSE '0';

	lb_w		<=	'1'	WHEN	(instruction_i and INST_LB_MASK) = INST_LB				ELSE 	'0';	--lb		
	lh_w		<=	'1'	WHEN	(instruction_i and INST_LH_MASK) = INST_LH				ELSE 	'0';	--lh
	lw_w		<=	'1'	WHEN	(instruction_i and INST_LW_MASK) = INST_LW				ELSE 	'0';	--lw
	lbu_w		<=	'1'	WHEN	(instruction_i and INST_LBU_MASK) = INST_LBU			ELSE	'0';	--lbu
	lhu_w		<=	'1'	WHEN	(instruction_i and INST_LHU_MASK) = INST_LHU			ELSE	'0';	--lhu
	lwu_w		<=	'1'	WHEN	(instruction_i and INST_LWU_MASK) = INST_LWU			ELSE	'0';	--lwu
	
	ld_w 		<=	'1' WHEN 	 lb_w or lh_w or lw_w or lbu_w or lhu_w or lwu_w		ELSE	'0';	--Load      
													
	sb_w		<=	'1'	WHEN	(instruction_i and INST_SB_MASK) = INST_SB				ELSE	'0';	--sb
	sh_w		<=	'1'	WHEN	(instruction_i and INST_SH_MASK) = INST_SH				ELSE	'0';	--sh
	sw_w		<=	'1'	WHEN	(instruction_i and INST_SW_MASK) = INST_SW				ELSE	'0';	--sw																																						               
	
	st_w		<=	'1'	WHEN	sb_w or sh_w or sw_w									ELSE	'0';	--Store   	
													
	beq_w		<=	'1'	WHEN	(instruction_i and INST_BEQ_MASK) = INST_BEQ			ELSE	'0';	--beq												
	bne_w		<=	'1'	WHEN	(instruction_i and INST_BNE_MASK) = INST_BNE			ELSE	'0';	--bne
	blt_w		<=	'1'	WHEN	(instruction_i and INST_BLT_MASK) = INST_BLT			ELSE	'0';	--blt
	bge_w		<=	'1'	WHEN	(instruction_i and INST_BGE_MASK) = INST_BGE			ELSE	'0';	--bge
	bltu_w		<=	'1'	WHEN	(instruction_i and INST_BLTU_MASK) = INST_BLTU			ELSE	'0';	--bltu
	bgeu_w		<=	'1'	WHEN	(instruction_i and INST_BGEU_MASK) = INST_BGEU			ELSE	'0';	--bgeu
	
	branch_w	<=	'1'	WHEN	beq_w or bne_w or blt_w or bge_w or bltu_w or bgeu_w	ELSE	'0';	--Branch     	
																										
	jal_w		<=	'1'	WHEN	(instruction_i and INST_JAL_MASK) = INST_JAL			ELSE 	'0';	--jal	

	jalr_w		<=	'1'	WHEN	(instruction_i and INST_JALR_MASK) = INST_JALR			ELSE 	'0';
	
	add_w		<=	'1' WHEN	(instruction_i and INST_ADD_MASK) = INST_ADD			ELSE	'0';	--add	
	
	addi_w		<=	'1' WHEN	(instruction_i and INST_ADDI_MASK) = INST_ADDI			ELSE	'0';	--addi
	
	auipc_w		<=	'1' WHEN	(instruction_i and INST_AUIPC_MASK) = INST_AUIPC		ELSE	'0';	--auipc
	
	lui_w		<=	'1' WHEN	(instruction_i and INST_LUI_MASK) = INST_LUI			ELSE	'0';	--lui
	
	and_w		<=	'1' WHEN	(instruction_i and INST_AND_MASK) = INST_AND			ELSE	'0';	--and
	
	andi_w		<=	'1' WHEN	(instruction_i and INST_ANDI_MASK) = INST_ANDI			ELSE	'0';	--andi
	
	or_w		<=	'1' WHEN	(instruction_i and INST_OR_MASK) = INST_OR				ELSE	'0';	--or
	
	ori_w		<=	'1' WHEN	(instruction_i and INST_ORI_MASK) = INST_ORI			ELSE	'0';	--ori
	
	sll_w		<=	'1' WHEN	(instruction_i and INST_SLL_MASK) = INST_SLL			ELSE	'0';	--sll
	
	slli_w 		<=	'1' WHEN	(instruction_i and INST_SLLI_MASK) = INST_SLLI			ELSE	'0';	--slli
	
	sra_w 		<=	'1' WHEN	(instruction_i and INST_SRA_MASK) = INST_SRA			ELSE	'0';	-- sra
	
	srai_w 		<=	'1' WHEN	(instruction_i and INST_SRAI_MASK) = INST_SRAI			ELSE	'0';	-- srai
	
	srl_w 		<=	'1' WHEN	(instruction_i and INST_SRL_MASK) = INST_SRL			ELSE	'0';	-- srl
	
	srli_w 		<=	'1' WHEN	(instruction_i and INST_SRLI_MASK) = INST_SRLI			ELSE	'0';	-- srli
	
	sub_w 		<=	'1' WHEN	(instruction_i and INST_SUB_MASK) = INST_SUB			ELSE	'0';	-- sub
	
	xor_w 		<=	'1' WHEN	(instruction_i and INST_XOR_MASK) = INST_XOR			ELSE	'0';	-- xor
	
	xori_w 		<=	'1' WHEN	(instruction_i and INST_XORI_MASK) = INST_XORI			ELSE	'0';	-- xori
	
	slt_w 		<=	'1' WHEN	(instruction_i and INST_SLT_MASK) = INST_SLT			ELSE	'0';	-- slt
	
	slti_w 		<=	'1' WHEN	(instruction_i and INST_SLTI_MASK) = INST_SLTI			ELSE	'0';	-- slti
	
	sltu_w 		<=	'1' WHEN	(instruction_i and INST_SLTU_MASK) = INST_SLTU			ELSE	'0';	-- sltu
	
	sltiu_w 	<=	'1' WHEN	(instruction_i and INST_SLTIU_MASK) = INST_SLTIU		ELSE	'0';	-- sltiu
	
	mul_w 		<=	'1' WHEN	(instruction_i and INST_MUL_MASK) = INST_MUL			ELSE	'0';	-- mul (M-extension)

	div_w 		<=	'1' WHEN	(instruction_i and INST_DIV_MASK)  = INST_DIV			ELSE	'0';	-- div
	divu_w 		<=	'1' WHEN	(instruction_i and INST_DIVU_MASK) = INST_DIVU			ELSE	'0';	-- divu
	rem_w 		<=	'1' WHEN	(instruction_i and INST_REM_MASK)  = INST_REM			ELSE	'0';	-- rem
	remu_w 		<=	'1' WHEN	(instruction_i and INST_REMU_MASK) = INST_REMU			ELSE	'0';	-- remu
	divop_w		<=	div_w or divu_w or rem_w or remu_w;

	DivStart_ctrl_o		<=	divop_w;
	DivSigned_ctrl_o	<=	div_w  or rem_w;
	DivRem_ctrl_o		<=	rem_w  or remu_w;

	-- Phase 9B: reti recognition -- see the port comment. jalr_w above still
	-- fires for it too, which is correct: the PC redirect IS the jalr's.
	Reti_ctrl_o			<=	'1' WHEN instruction_i = INST_RETI ELSE '0';
	
	
	RegWrite_ctrl_o 	<=  Rtype_w or Itype_w or Utype_w or UJtype_w;
	MemtoReg_ctrl_o 	<=  ld_w;
	MemWrite_ctrl_o 	<=  st_w; 
	MemRead_ctrl_o 		<=  ld_w;
	Branch_ctrl_o     	<=	branch_w;
	Jal_ctrl_o			<=	jal_w; 
	Jalr_ctrl_o			<=	jalr_w;  
	RegDst_ctrl_o		<=	jal_w or jalr_w;
	ALUSrc_ctrl_o  		<=  Itype_w or Stype_w or Utype_w or UJtype_w;
	
	UpperIm_ctrl_o		<=	"01" WHEN auipc_w 	ELSE
							"10" WHEN	lui_w	ELSE
							"00";

	-- Phase 3B (G-309): access width / signedness, from the existing detectors.
	-- lb and sb share MEM_B and lh and sh share MEM_H because DMEMORY needs the
	-- width, and only a load needs the signedness. Everything else -- including
	-- lw, sw, lwu (RV64-only but detected above) and every non-memory
	-- instruction -- resolves to MEM_W, so an unrecognised funct3 degrades to a
	-- full-word access rather than to an undefined one.
	MemOp_ctrl_o		<=	MEM_B	WHEN (lb_w  or sb_w) = '1'	ELSE
							MEM_H	WHEN (lh_w  or sh_w) = '1'	ELSE
							MEM_BU	WHEN  lbu_w          = '1'	ELSE
							MEM_HU	WHEN  lhu_w          = '1'	ELSE
							MEM_W;
		  						      		
	ALUOp_ctrl_o		<=  ALU_ADD					WHEN	add_w	or 	addi_w or auipc_w or lui_w or jal_w or jalr_w or ld_w or st_w 	ELSE																																																				
							ALU_AND					WHEN	and_w 	or 	andi_sel_w	ELSE
							ALU_OR					WHEN	or_w 	or 	ori_w	ELSE
							ALU_SHIFTL				WHEN	sll_w 	or	slli_w	ELSE																					
							ALU_SHIFTR_ARITH		WHEN	sra_w 	or	srai_w	ELSE 																									
							ALU_SHIFTR				WHEN	srl_w 	or 	srli_w	ELSE																					
							ALU_SUB					WHEN	sub_w				ELSE	
							ALU_XOR					WHEN	xor_w 	or 	xori_w	ELSE 	
							ALU_LESS_THAN_SIGNED	WHEN	slt_w 	or 	slti_w 	ELSE
							ALU_LESS_THAN_UNSIGNED	WHEN	sltu_w 	or 	sltiu_w	ELSE																						
							ALU_MUL					WHEN	mul_w				ELSE
							ALU_BEQ					WHEN	beq_w				ELSE
							ALU_BNE					WHEN	bne_w				ELSE
							ALU_BLT					WHEN	blt_w				ELSE
							ALU_BGE					WHEN	bge_w				ELSE
							ALU_BLTU				WHEN	bltu_w				ELSE
							ALU_BGEU				WHEN	bgeu_w				ELSE
							ALU_NONE;

END behavior;
