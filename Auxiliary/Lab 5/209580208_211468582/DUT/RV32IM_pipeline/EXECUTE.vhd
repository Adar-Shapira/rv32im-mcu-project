--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - EX stage
-- EXECUTE holds the ALU (with multiplier stage 1), the branch
-- comparison logic, the branch address adder, the two forwarding muxes and
-- the EX/MEM pipeline register. Pipeline changes vs the single-cycle version:
--   * forwarding muxes in front of both register operands, selected by
--     FORWARD_UNIT: "00" = ID/EX value, "10" = current MEM-stage result,
--     "01" = WB write-back data (wb_write_data_i)
--   * the forwarded rs2 value also feeds the store data path to MEM
--   * brTaken is computed here but the branch/jump redirect is issued only
--     in the MEM stage, so it is carried in the EX/MEM register together
--     with the branch target (addr_gen) and the jalr target (alu_res)
--   * flush_i (taken branch/jump resolved in MEM) bubbles the EX/MEM
--     register - the EX-stage instruction is the 3rd flushed instruction
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;


ENTITY  Execute IS
	generic(
		DATA_BUS_WIDTH 	: integer := 32;
		PC_WIDTH 		: integer := 10
	);
	PORT(	
		--Inputs
		clk_i 				: IN 	STD_LOGIC;
		rst_i 				: IN 	STD_LOGIC;
		flush_i				: IN 	STD_LOGIC;										-- from top (MEM stage): kill the EX-stage instruction
		-- ID/EX inputs (EX-stage view produced by IDECODE)
		pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_i			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data1_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		sign_extend_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- EX-stage control bits (from the ID/EX register)
		UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
		-- MEM/WB-stage control bits, carried through to the EX/MEM register
		Branch_ctrl_i 		: IN 	STD_LOGIC;
		Jal_ctrl_i 			: IN 	STD_LOGIC;
		Jalr_ctrl_i 		: IN 	STD_LOGIC;
		MemRead_ctrl_i 		: IN 	STD_LOGIC;
		MemWrite_ctrl_i 	: IN 	STD_LOGIC;
		RegDst_ctrl_i 		: IN 	STD_LOGIC;
		RegWrite_ctrl_i 	: IN 	STD_LOGIC;
		MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
		-- forwarding (FORWARD_UNIT selects, WB-stage write-back data)
		forward_a_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);					-- rs1 operand select
		forward_b_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);					-- rs2 operand select
		mem_forward_data_i	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- MEM ALU or stage-2 mul result
		wb_write_data_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- WB write-back mux output (WRITEBACK)
			
		--Outputs
		-- EX/MEM pipeline register outputs (MEM-stage view)
		mem_pc_o			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		mem_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- WB value for jal/jalr
		mem_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		mem_alu_res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- DTCM address / WB value / jalr target
		mem_write_data_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- store data (forwarded rs2 value)
		mem_addr_gen_o 		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- branch/jal target
		mem_brTaken_o 		: OUT	STD_LOGIC;
		mem_rd_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);					-- FORWARD_UNIT + WB
		-- Figure 7 multiplier stage-1 values, carried through EX/MEM
		mem_mul_p0_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		mem_mul_p1_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		mem_mul_p2_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		mem_mul_p3_o		: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		mem_Mul_ctrl_o		: OUT	STD_LOGIC;
		-- carried control bits: MEM stage
		mem_Branch_ctrl_o 	: OUT	STD_LOGIC;
		mem_Jal_ctrl_o 		: OUT	STD_LOGIC;
		mem_Jalr_ctrl_o 	: OUT	STD_LOGIC;
		mem_MemRead_ctrl_o 	: OUT	STD_LOGIC;
		mem_MemWrite_ctrl_o : OUT	STD_LOGIC;
		-- carried control bits: WB stage (mem_RegWrite also feeds FORWARD_UNIT)
		mem_RegDst_ctrl_o 	: OUT	STD_LOGIC;
		mem_RegWrite_ctrl_o : OUT	STD_LOGIC;
		mem_MemtoReg_ctrl_o : OUT	STD_LOGIC
	);
END Execute;


ARCHITECTURE struct OF Execute IS
	CONSTANT NOP_INSTRUCTION	: STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000013";
	COMPONENT multiplier_1 IS
		PORT(
			a_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			b_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p0_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p1_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p2_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
			p3_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;

	-- forwarding mux select encoding (FORWARD_UNIT must drive the same codes)
	CONSTANT FWD_NONE			: STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";	-- ID/EX register value
	CONSTANT FWD_WB				: STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";	-- WB write-back data (distance 2)
	CONSTANT FWD_MEM			: STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";	-- EX/MEM ALU result (distance 1)

	SIGNAL	fw_read_data1_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	fw_read_data2_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	addr_gen_w			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);

	SIGNAL 	ain_w 				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL 	bin_w 				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL 	sub_res_w 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL 	ltu_res_w 			: STD_LOGIC;
	SIGNAL 	eq_res_w			: STD_LOGIC;
	SIGNAL	msbneq_res_w		: STD_LOGIC;
	SIGNAL	alu_res_r 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brTaken_w 			: STD_LOGIC;
	SIGNAL	mul_p0_w, mul_p1_w	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	mul_p2_w, mul_p3_w	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	
	SIGNAL	brl_shl_s1_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shl_s2_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shl_s3_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shl_s4_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	SIGNAL	brl_shr_s1_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shr_s2_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shr_s3_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shr_s4_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	brl_shr_pad_r		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	-- EX/MEM pipeline register
	SIGNAL	ex_mem_pc_q			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_pc_plus4_q	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_instruction_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_alu_res_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_write_data_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_addr_gen_q	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL	ex_mem_brTaken_q	: STD_LOGIC;
	SIGNAL	ex_mem_rd_q			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL	ex_mem_mul_p0_q		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	ex_mem_mul_p1_q		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	ex_mem_mul_p2_q		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	ex_mem_mul_p3_q		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL	ex_mem_Mul_q		: STD_LOGIC;
	SIGNAL	ex_mem_Branch_q		: STD_LOGIC;
	SIGNAL	ex_mem_Jal_q		: STD_LOGIC;
	SIGNAL	ex_mem_Jalr_q		: STD_LOGIC;
	SIGNAL	ex_mem_MemRead_q	: STD_LOGIC;
	SIGNAL	ex_mem_MemWrite_q	: STD_LOGIC;
	SIGNAL	ex_mem_RegDst_q		: STD_LOGIC;
	SIGNAL	ex_mem_RegWrite_q	: STD_LOGIC;
	SIGNAL	ex_mem_MemtoReg_q	: STD_LOGIC;
	
		
BEGIN
--------------------------------------------------------------------------------------------------------
-- Forwarding muxes (in front of both register operands)
-- The MEM source selects the normal EX/MEM ALU result or multiplier stage-2
-- result in DMEMORY. Loads are covered by the HAZARD_UNIT load-use stall.
--------------------------------------------------------------------------------------------------------
WITH forward_a_i SELECT
	fw_read_data1_w <=	mem_forward_data_i	WHEN	FWD_MEM,
						wb_write_data_i		WHEN	FWD_WB,
						read_data1_i		WHEN	OTHERS;

WITH forward_b_i SELECT
	fw_read_data2_w <=	mem_forward_data_i	WHEN	FWD_MEM,
						wb_write_data_i		WHEN	FWD_WB,
						read_data2_i		WHEN	OTHERS;

--------------------------------------------------------------------------------------------------------
-- Branch Address Adder
-- Branch/JAL immediates already contain bits [12:1]/[20:1], so append one
-- zero bit to form the byte offset before adding it to the PC.
--------------------------------------------------------------------------------------------------------					  
addr_gen_w	<= pc_i(PC_WIDTH-1 DOWNTO 0) + (sign_extend_i(PC_WIDTH-2 DOWNTO 0) & '0');

--------------------------------------------------------------------------------------------------------
--ALU
--------------------------------------------------------------------------------------------------------
WITH UpperIm_ctrl_i SELECT
	ain_w <= 	fw_read_data1_w	WHEN	"00",
				((DATA_BUS_WIDTH-PC_WIDTH-1) DOWNTO 0 => '0') & pc_i	WHEN	"01",
				(others => '0')	WHEN	OTHERS;
	
bin_w <= 	fw_read_data2_w	WHEN not ALUSrc_ctrl_i ELSE	sign_extend_i(DATA_BUS_WIDTH-1 DOWNTO 0);


--Reused resuls 
sub_res_w			<= ain_w - bin_w;
-- Prefixing zero makes the signed-package comparison equivalent to RV32 unsigned.
ltu_res_w			<= '1' WHEN ('0' & ain_w) < ('0' & bin_w)	ELSE '0';
eq_res_w			<= '1' WHEN ain_w = bin_w 			ELSE '0'; 
msbneq_res_w		<= '1' WHEN ain_w(31) /= bin_w(31) 	ELSE '0';

--------------------------------------------------------------------------------------------------------
-- Figure 7 multiplier stage 1 (EX): four 8x8 partial products. The EX/MEM
-- register carries P0-P3 to multiplier stage 2 in DMEMORY.
--------------------------------------------------------------------------------------------------------
MUL1: multiplier_1
	port map(
		a_i 	=> ain_w(15 DOWNTO 0),
		b_i 	=> bin_w(15 DOWNTO 0),
		p0_o	=> mul_p0_w,
		p1_o	=> mul_p1_w,
		p2_o	=> mul_p2_w,
		p3_o	=> mul_p3_w
	);

	

PROCESS (all)
BEGIN
	-- default values
	alu_res_r 		<= (others => '0');
	brTaken_w 		<= '0';
	brl_shl_s1_r	<= (others => '0');
	brl_shl_s2_r	<= (others => '0');
	brl_shl_s3_r	<= (others => '0'); 
	brl_shl_s4_r	<= (others => '0');
	brl_shr_s1_r	<= (others => '0');
	brl_shr_s2_r	<= (others => '0');
	brl_shr_s3_r	<= (others => '0'); 
	brl_shr_s4_r	<= (others => '0');
	brl_shr_pad_r	<= (others => '0');
	
	
 	CASE ALUOp_ctrl_i IS	-- Select ALU operation
	------------------------------------------------------
    -- Arithmetic
    ------------------------------------------------------
		-- add, addi, auipc, jal, jalr
		WHEN ALU_ADD 	=>
			alu_res_r	<= ain_w + bin_w;
			brTaken_w	<= '0';
		
		-- sub
		WHEN ALU_SUB	=>
			alu_res_r	<= sub_res_w;		 
			brTaken_w	<= '0';
		
		-- mul result is completed in MEM by multiplier stage 2
		WHEN ALU_MUL	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= '0';
	------------------------------------------------------
    -- Logic
    ------------------------------------------------------
		-- and, andi	
    	WHEN	ALU_AND 	=>
			alu_res_r	<= ain_w and bin_w;
			brTaken_w	<= '0';
		
		-- or, ori		
	 	WHEN ALU_OR	=>
			alu_res_r	<= ain_w or bin_w;
			brTaken_w	<= '0';
		
		-- xor, xori
		WHEN ALU_XOR 	=>
			alu_res_r	<= ain_w xor bin_w;
			brTaken_w	<= '0';
				
	------------------------------------------------------
    -- Shift Left
    ------------------------------------------------------
		-- sll, slli
 	 	WHEN ALU_SHIFTL	=>
			-- Barrel-Shifter SHL stage 0
			if (bin_w(0) = '1') then
				brl_shl_s1_r <= (ain_w(30 DOWNTO 0) & '0');
			else
				brl_shl_s1_r <= ain_w;
			end if;
					
			-- Barrel-Shifter SHL stage 1
			if (bin_w(1) = '1') then
				brl_shl_s2_r <= (brl_shl_s1_r(29 DOWNTO 0) & "00");
			else
				brl_shl_s2_r <= brl_shl_s1_r;
			end if;
					
			-- Barrel-Shifter SHL stage 2
			if (bin_w(2) = '1')	then
				brl_shl_s3_r <= (brl_shl_s2_r(27 DOWNTO 0) & "0000");
			else
				brl_shl_s3_r <= brl_shl_s2_r;
			end if;
					
			-- Barrel-Shifter SHL stage 3
			if (bin_w(3) = '1')	then
				brl_shl_s4_r <= (brl_shl_s3_r(23 DOWNTO 0) & "00000000");
			else
				brl_shl_s4_r <= brl_shl_s3_r;
			end if;
					
			-- Barrel-Shifter SHL stage 4
			if (bin_w(4) = '1')	then
				alu_res_r <= (brl_shl_s4_r(15 DOWNTO 0) & "0000000000000000");
			else
				alu_res_r <= brl_shl_s4_r;
			end if;
				      
			brTaken_w	<= '0';
	------------------------------------------------------
    -- Shift Right
    ------------------------------------------------------		
		-- srl, srli, sra, srai	
 	 	WHEN ALU_SHIFTR | ALU_SHIFTR_ARITH 	=>
			--if sra? pad with 1's else pad with 0's 
			if (ain_w(31) = '1' and (ALUOp_ctrl_i = ALU_SHIFTR_ARITH)) then
				brl_shr_pad_r <= (others => '1');
			else
				brl_shr_pad_r <= (others => '0');
			end if;
			
			-- Barrel-Shifter SHR stage 0
			if (bin_w(0) = '1') then
				brl_shr_s1_r <= (brl_shr_pad_r(31) & ain_w(31 DOWNTO 1));
			else
				brl_shr_s1_r <= ain_w;
			end if;
			
			-- Barrel-Shifter SHR stage 1
			if (bin_w(1) = '1') then
				brl_shr_s2_r <= (brl_shr_pad_r(31 DOWNTO 30) & brl_shr_s1_r(31 DOWNTO 2));
			else
				brl_shr_s2_r <= brl_shr_s1_r;
			end if;
			
			-- Barrel-Shifter SHR stage 2
			if (bin_w(2) = '1') then
				brl_shr_s3_r <= (brl_shr_pad_r(31 DOWNTO 28) & brl_shr_s2_r(31 DOWNTO 4));
			else
				brl_shr_s3_r <= brl_shr_s2_r;
			end if;
			
			-- Barrel-Shifter SHR stage 3
			if (bin_w(3) = '1') then
				brl_shr_s4_r <= (brl_shr_pad_r(31 DOWNTO 24) & brl_shr_s3_r(31 DOWNTO 8));
			else
				brl_shr_s4_r <= brl_shr_s3_r;
			end if;
			
			-- Barrel-Shifter SHR stage 4
			if (bin_w(4) = '1')	then
				alu_res_r <= (brl_shr_pad_r(31 DOWNTO 16) & brl_shr_s4_r(31 DOWNTO 16));
			else
				alu_res_r <= brl_shr_s4_r;
			end if;
				   
			brTaken_w	<= '0';		 	 				
	------------------------------------------------------
    -- Comparision
    ------------------------------------------------------
		-- slt, slti
		WHEN ALU_LESS_THAN_SIGNED	=>
			brTaken_w	<= '0';
			IF msbneq_res_w THEN
				IF ain_w(31) THEN
					alu_res_r	<= (0 => '1', others => '0');	--32'h1
				ELSE
					alu_res_r	<= (others => '0');						--32'h0
				END IF;
			ELSE
				IF sub_res_w(31) THEN
					alu_res_r	<= (0 => '1', others => '0');	--32'h1	
				ELSE
					alu_res_r	<= (others => '0');						--32'h0
				END IF;
			END IF;
		
		-- sltu, sltiu 
		WHEN ALU_LESS_THAN_UNSIGNED	=>
			brTaken_w	<= '0';
			IF ltu_res_w THEN
				alu_res_r	<= (0 => '1', others => '0');		--32'h1
			ELSE
				alu_res_r	<= (others => '0');							--32'h0
			END IF;

	------------------------------------------------------
    -- Condional Branch 
    ------------------------------------------------------
		-- beq
		WHEN ALU_BEQ	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= eq_res_w;
		
		-- bne
		WHEN ALU_BNE	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= not eq_res_w;
		
		-- blt
		WHEN ALU_BLT	=>
			alu_res_r	<= (others => '0');
			IF msbneq_res_w THEN
				brTaken_w	<= ain_w(31);
			ELSE
				brTaken_w	<= sub_res_w(31);
			END IF;
		
		-- bge
		WHEN ALU_BGE	=>
			alu_res_r	<= (others => '0');
			IF msbneq_res_w THEN
				brTaken_w	<= bin_w(31);
			ELSE
				brTaken_w	<= not sub_res_w(31);
			END IF;
		
		-- bltu
		WHEN ALU_BLTU	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= ltu_res_w;
		
		-- bgeu
		WHEN ALU_BGEU	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= not ltu_res_w;
		
 	 	WHEN OTHERS	=>
			alu_res_r	<= (others => '0');
			brTaken_w	<= '0';
			
  END CASE;
		
END PROCESS;

--------------------------------------------------------------------------------------------------------
-- EX/MEM pipeline register
-- flush (taken branch/jump resolved in MEM) -> bubble: control bits cleared
-- so the killed EX-stage instruction has no architectural effect in MEM/WB.
-- There is no stall input: a hazard stall bubbles ID/EX (in IDECODE) while
-- the EX-stage instruction proceeds normally into MEM.
--------------------------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
BEGIN
	IF rst_i = '1' THEN
		ex_mem_pc_q			<= (OTHERS => '0');
		ex_mem_pc_plus4_q	<= (OTHERS => '0');
		ex_mem_instruction_q	<= NOP_INSTRUCTION;
		ex_mem_alu_res_q	<= (OTHERS => '0');
		ex_mem_write_data_q	<= (OTHERS => '0');
		ex_mem_addr_gen_q	<= (OTHERS => '0');
		ex_mem_brTaken_q	<= '0';
		ex_mem_rd_q			<= (OTHERS => '0');
		ex_mem_mul_p0_q		<= (OTHERS => '0');
		ex_mem_mul_p1_q		<= (OTHERS => '0');
		ex_mem_mul_p2_q		<= (OTHERS => '0');
		ex_mem_mul_p3_q		<= (OTHERS => '0');
		ex_mem_Mul_q		<= '0';
		ex_mem_Branch_q		<= '0';
		ex_mem_Jal_q		<= '0';
		ex_mem_Jalr_q		<= '0';
		ex_mem_MemRead_q	<= '0';
		ex_mem_MemWrite_q	<= '0';
		ex_mem_RegDst_q		<= '0';
		ex_mem_RegWrite_q	<= '0';
		ex_mem_MemtoReg_q	<= '0';
	ELSIF (clk_i'EVENT AND clk_i='1') THEN
		IF flush_i = '1' THEN
			ex_mem_pc_q			<= (OTHERS => '0');
			ex_mem_pc_plus4_q	<= (OTHERS => '0');
			ex_mem_instruction_q	<= NOP_INSTRUCTION;
			ex_mem_alu_res_q	<= (OTHERS => '0');
			ex_mem_write_data_q	<= (OTHERS => '0');
			ex_mem_addr_gen_q	<= (OTHERS => '0');
			ex_mem_brTaken_q	<= '0';
			ex_mem_rd_q			<= (OTHERS => '0');
			ex_mem_mul_p0_q		<= (OTHERS => '0');
			ex_mem_mul_p1_q		<= (OTHERS => '0');
			ex_mem_mul_p2_q		<= (OTHERS => '0');
			ex_mem_mul_p3_q		<= (OTHERS => '0');
			ex_mem_Mul_q		<= '0';
			ex_mem_Branch_q		<= '0';
			ex_mem_Jal_q		<= '0';
			ex_mem_Jalr_q		<= '0';
			ex_mem_MemRead_q	<= '0';
			ex_mem_MemWrite_q	<= '0';
			ex_mem_RegDst_q		<= '0';
			ex_mem_RegWrite_q	<= '0';
			ex_mem_MemtoReg_q	<= '0';
		ELSE
			ex_mem_pc_q			<= pc_i;
			ex_mem_pc_plus4_q	<= pc_plus4_i;
			ex_mem_instruction_q	<= instruction_i;
			ex_mem_alu_res_q	<= alu_res_r;
			ex_mem_write_data_q	<= fw_read_data2_w;
			ex_mem_addr_gen_q	<= addr_gen_w;
			ex_mem_brTaken_q	<= brTaken_w;
			ex_mem_rd_q			<= rd_i;
			ex_mem_mul_p0_q		<= mul_p0_w;
			ex_mem_mul_p1_q		<= mul_p1_w;
			ex_mem_mul_p2_q		<= mul_p2_w;
			ex_mem_mul_p3_q		<= mul_p3_w;
			IF ALUOp_ctrl_i = ALU_MUL THEN
				ex_mem_Mul_q	<= '1';
			ELSE
				ex_mem_Mul_q	<= '0';
			END IF;
			ex_mem_Branch_q		<= Branch_ctrl_i;
			ex_mem_Jal_q		<= Jal_ctrl_i;
			ex_mem_Jalr_q		<= Jalr_ctrl_i;
			ex_mem_MemRead_q	<= MemRead_ctrl_i;
			ex_mem_MemWrite_q	<= MemWrite_ctrl_i;
			ex_mem_RegDst_q		<= RegDst_ctrl_i;
			ex_mem_RegWrite_q	<= RegWrite_ctrl_i;
			ex_mem_MemtoReg_q	<= MemtoReg_ctrl_i;
		END IF;
	END IF;
END PROCESS;
	
--------------------------------------------------------------------------------------------------------
-- EX/MEM register outputs (MEM-stage view)
mem_pc_o				<= ex_mem_pc_q;
mem_pc_plus4_o		<= ex_mem_pc_plus4_q;
mem_instruction_o		<= ex_mem_instruction_q;
mem_alu_res_o		<= ex_mem_alu_res_q;
mem_write_data_o	<= ex_mem_write_data_q;
mem_addr_gen_o		<= ex_mem_addr_gen_q;
mem_brTaken_o		<= ex_mem_brTaken_q;
mem_rd_o			<= ex_mem_rd_q;
mem_mul_p0_o		<= ex_mem_mul_p0_q;
mem_mul_p1_o		<= ex_mem_mul_p1_q;
mem_mul_p2_o		<= ex_mem_mul_p2_q;
mem_mul_p3_o		<= ex_mem_mul_p3_q;
mem_Mul_ctrl_o		<= ex_mem_Mul_q;
mem_Branch_ctrl_o	<= ex_mem_Branch_q;
mem_Jal_ctrl_o		<= ex_mem_Jal_q;
mem_Jalr_ctrl_o		<= ex_mem_Jalr_q;
mem_MemRead_ctrl_o	<= ex_mem_MemRead_q;
mem_MemWrite_ctrl_o	<= ex_mem_MemWrite_q;
mem_RegDst_ctrl_o	<= ex_mem_RegDst_q;
mem_RegWrite_ctrl_o	<= ex_mem_RegWrite_q;
mem_MemtoReg_ctrl_o	<= ex_mem_MemtoReg_q;
 
END struct;
