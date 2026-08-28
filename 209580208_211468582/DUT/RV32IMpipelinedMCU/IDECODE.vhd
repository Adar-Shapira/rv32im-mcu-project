--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - ID stage
-- IDECODE holds the register file, instruction field extraction, immediate
-- generation + sign extension, and the ID/EX pipeline register. The WB mux
-- lives in WRITEBACK; IDECODE only consumes the selected write data.
-- Pipeline changes vs the single-cycle version:
--   * the RF write port is driven from the WB stage (wb_write_data_i from
--     WRITEBACK, wb_rd/wb_RegWrite from the MEM/WB register) while reads
--     still happen in ID
--   * RF read bypass: an instruction in WB writes the RF only at the clock
--     edge, so an ID-stage reader of the same register (distance 3, not
--     visible to the EX forwarding unit) takes the WB write data directly
--   * the ID/EX pipeline register carries data, immediate, rs1/rs2/rd
--     indices and all control bits; stall_i/flush_i inject a bubble
--     (control bits cleared) instead of the decoded instruction
--   * id_rs1_o/id_rs2_o expose the ID-stage source registers for the
--     load-use check in HAZARD_UNIT
--============================================================================ 
LIBRARY IEEE; 		
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.const_package.all;


ENTITY Idecode IS
	generic(
		PC_WIDTH 			: integer	:= 10;
		DATA_BUS_WIDTH		: integer := 32
	);
	PORT(
		--Inputs
		clk_i				: IN 	STD_LOGIC;
		rst_i				: IN 	STD_LOGIC;
		stall_i				: IN 	STD_LOGIC;										-- from HAZARD_UNIT: bubble into EX, ID instruction replayed
		hold_i				: IN 	STD_LOGIC := '0';								-- slice 3: freeze ID/EX (div in EX); do not bubble
		flush_i				: IN 	STD_LOGIC;										-- from top (MEM stage): kill the ID-stage instruction
		-- IF/ID inputs (ID-stage view produced by IFETCH)
		pc_i				: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_i			: IN	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- control inputs (CONTROL decodes the same ID-stage instruction)
		RegDst_ctrl_i 		: IN 	STD_LOGIC;
		RegWrite_ctrl_i 	: IN 	STD_LOGIC;
		MemtoReg_ctrl_i 	: IN 	STD_LOGIC;
		MemRead_ctrl_i 		: IN 	STD_LOGIC;
		MemWrite_ctrl_i 	: IN 	STD_LOGIC;
		MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
		DivStart_ctrl_i		: IN 	STD_LOGIC := '0';
		DivSigned_ctrl_i	: IN 	STD_LOGIC := '0';
		DivRem_ctrl_i		: IN 	STD_LOGIC := '0';
		Reti_ctrl_i			: IN 	STD_LOGIC := '0';
		Branch_ctrl_i 		: IN 	STD_LOGIC;
		Jal_ctrl_i 			: IN 	STD_LOGIC;
		Jalr_ctrl_i 		: IN 	STD_LOGIC;
		ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
		UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- WB-stage inputs (RF write port)
		wb_RegWrite_ctrl_i 	: IN 	STD_LOGIC;
		wb_rd_i				: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		wb_write_data_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- Slice 4. Transcribed from DUT/RV32IMscMCU/IDECODE.vhd:41-51, 62.
		-- Side doors fire in cycles where the normal WB port is idle (entry
		-- bubbles; reti's rd is x0). Defaulted so slice 3 instantiations hold.
		IntrGieWr_i			: IN	STD_LOGIC := '0';
		IntrGieVal_i		: IN	STD_LOGIC := '0';
		IntrTpWr_i			: IN	STD_LOGIC := '0';
		IntrTpVal_i			: IN	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
		
		--Outputs
		-- ID-stage (combinational) - for HAZARD_UNIT
		id_rs1_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		id_rs2_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- ID/EX pipeline register outputs (EX-stage view)
		ex_pc_o				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		ex_pc_plus4_o		: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		ex_instruction_o	: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		ex_read_data1_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		ex_read_data2_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		ex_sign_ext_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		ex_rs1_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ex_rs2_o			: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		ex_rd_o				: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- carried control bits: EX stage
		ex_ALUSrc_ctrl_o 	: OUT	STD_LOGIC;
		ex_UpperIm_ctrl_o	: OUT	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ex_ALUOp_ctrl_o	 	: OUT	STD_LOGIC_VECTOR(4 DOWNTO 0);
		-- carried control bits: MEM stage
		ex_Branch_ctrl_o 	: OUT	STD_LOGIC;
		ex_Jal_ctrl_o 		: OUT	STD_LOGIC;
		ex_Jalr_ctrl_o 		: OUT	STD_LOGIC;
		ex_MemRead_ctrl_o 	: OUT	STD_LOGIC;
		ex_MemWrite_ctrl_o 	: OUT	STD_LOGIC;
		ex_MemOp_ctrl_o		: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
		ex_DivStart_ctrl_o	: OUT	STD_LOGIC;
		ex_DivSigned_ctrl_o	: OUT	STD_LOGIC;
		ex_DivRem_ctrl_o	: OUT	STD_LOGIC;
		ex_Reti_ctrl_o		: OUT	STD_LOGIC;
		-- carried control bits: WB stage
		ex_RegDst_ctrl_o 	: OUT	STD_LOGIC;
		ex_RegWrite_ctrl_o 	: OUT	STD_LOGIC;
		ex_MemtoReg_ctrl_o 	: OUT	STD_LOGIC;
		gie_o				: OUT	STD_LOGIC
	);
END Idecode;


ARCHITECTURE behavior OF Idecode IS
TYPE register_file IS ARRAY (0 TO 31) OF STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	CONSTANT NOP_INSTRUCTION				: STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000013";

	SIGNAL RF_q							: register_file;
	SIGNAL wb_rf_write_w				: STD_LOGIC;
	SIGNAL read_data1_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL SignExt_w					: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL bubble_w						: STD_LOGIC;
	
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
	
	-- ID/EX pipeline register
	SIGNAL id_ex_pc_q					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_pc_plus4_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_instruction_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_read_data1_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_read_data2_q			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_sign_ext_q				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL id_ex_rs1_q					: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_rs2_q					: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_rd_q					: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_ALUSrc_q				: STD_LOGIC;
	SIGNAL id_ex_UpperIm_q				: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL id_ex_ALUOp_q				: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL id_ex_Branch_q				: STD_LOGIC;
	SIGNAL id_ex_Jal_q					: STD_LOGIC;
	SIGNAL id_ex_Jalr_q					: STD_LOGIC;
	SIGNAL id_ex_MemRead_q				: STD_LOGIC;
	SIGNAL id_ex_MemWrite_q				: STD_LOGIC;
	SIGNAL id_ex_MemOp_q				: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL id_ex_DivStart_q				: STD_LOGIC;
	SIGNAL id_ex_DivSigned_q			: STD_LOGIC;
	SIGNAL id_ex_DivRem_q				: STD_LOGIC;
	SIGNAL id_ex_Reti_q					: STD_LOGIC;
	SIGNAL id_ex_RegDst_q				: STD_LOGIC;
	SIGNAL id_ex_RegWrite_q				: STD_LOGIC;
	SIGNAL id_ex_MemtoReg_q				: STD_LOGIC;

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
	
	-- write enable of the WB-stage instruction (RF(0) hard-wired to zero)
	wb_rf_write_w	<=	'1' WHEN (wb_RegWrite_ctrl_i = '1' AND wb_rd_i /= 0) ELSE '0';
	
	-- Register-File read ports with WB bypass: the WB-stage value is written
	-- into the RF only at the next clock edge, so a same-cycle ID reader
	-- (3 instructions younger) must take the write data directly
	read_data1_w <= wb_write_data_i WHEN (wb_rf_write_w = '1' AND rs1_w = wb_rd_i) ELSE
					RF_q(CONV_INTEGER(rs1_w));
	
	read_data2_w <= wb_write_data_i WHEN (wb_rf_write_w = '1' AND rs2_w = wb_rd_i) ELSE
					RF_q(CONV_INTEGER(rs2_w));
	
	-- Sign Extend
  	SignExt_Iimm_w 	<=	ZEROS_IMM20 & Iimm_w 	WHEN	not Iimm_w(11) 	ELSE ONES_IMM20 & Iimm_w;
	SignExt_Simm_w 	<=	ZEROS_IMM20	& Simm_w 	WHEN 	not Simm_w(11)	ELSE ONES_IMM20 & Simm_w;
	SignExt_SBimm_w <=	ZEROS_IMM20	& SBimm_w 	WHEN 	not SBimm_w(11)	ELSE ONES_IMM20 & SBimm_w;
	SignExt_Uimm_w 	<=	ZEROS_IMM12 & Uimm_w 	WHEN 	not Uimm_w(19) 	ELSE ONES_IMM12 & Uimm_w;
	SignExt_UJimm_w	<=	ZEROS_IMM12 & UJimm_w 	WHEN 	not UJimm_w(19) ELSE ONES_IMM12 & UJimm_w;

	
	with	opc_w select
		SignExt_w 	<=	SignExt_Iimm_w				when ITYPE_OPC,
		SignExt_Iimm_w								when INST_JALR(6 DOWNTO 0),
						SignExt_Iimm_w								when LOAD_OPC,
		SignExt_Simm_w								when STYPE_OPC,
		SignExt_SBimm_w 							when SBTYPE_OPC,
						SignExt_Uimm_w(19 DOWNTO 0) & ZEROS_IMM12	when AUIPC_OPC,
						SignExt_Uimm_w(19 DOWNTO 0) & ZEROS_IMM12	when LUI_OPC,
		SignExt_UJimm_w								when UJTYPE_OPC,
		(others => '0')								when others;
	--==============================================================================
	--	Register-File(RF) structure - write port driven from the WB stage
	--==============================================================================
	process(clk_i,rst_i)
	begin
		if (rst_i='1') then
			FOR i IN 0 TO 31 LOOP
				RF_q(i) <= CONV_STD_LOGIC_VECTOR(0,32);
			END LOOP;
		elsif (clk_i'event and clk_i='1') then
			if (wb_rf_write_w = '1') then
				RF_q(CONV_INTEGER(wb_rd_i)) <= wb_write_data_i;
				-- index type is integer so we must use conv_integer for type casting
			end if;
			-- Slice 4: protocol side doors AFTER the normal write so they win
			-- if both ever named the same register -- which cannot happen
			-- (entry bubbles; reti's rd is x0). From SC IDECODE.vhd:154-165.
			if (IntrGieWr_i = '1') then
				RF_q(3)(0) <= IntrGieVal_i;
			end if;
			if (IntrTpWr_i = '1') then
				RF_q(4) <= IntrTpVal_i;
			end if;
		end if;
	end process;

	--==============================================================================
	--	ID/EX pipeline register
	--	flush -> bubble; hold (EX-stage divide) -> freeze (do not kill the div);
	--	stall (load-use) -> bubble so the load proceeds and the consumer replays.
	--==============================================================================
	bubble_w	<= flush_i or (stall_i and (not hold_i));
	
	process(clk_i,rst_i)
	begin
		if (rst_i='1') then
			id_ex_pc_q			<= (OTHERS => '0');
			id_ex_pc_plus4_q	<= (OTHERS => '0');
			id_ex_instruction_q	<= NOP_INSTRUCTION;
			id_ex_read_data1_q	<= (OTHERS => '0');
			id_ex_read_data2_q	<= (OTHERS => '0');
			id_ex_sign_ext_q	<= (OTHERS => '0');
			id_ex_rs1_q			<= (OTHERS => '0');
			id_ex_rs2_q			<= (OTHERS => '0');
			id_ex_rd_q			<= (OTHERS => '0');
			id_ex_ALUSrc_q		<= '0';
			id_ex_UpperIm_q		<= (OTHERS => '0');
			id_ex_ALUOp_q		<= ALU_NONE;
			id_ex_Branch_q		<= '0';
			id_ex_Jal_q			<= '0';
			id_ex_Jalr_q		<= '0';
			id_ex_MemRead_q		<= '0';
			id_ex_MemWrite_q	<= '0';
			id_ex_MemOp_q		<= MEM_W;
			id_ex_DivStart_q	<= '0';
			id_ex_DivSigned_q	<= '0';
			id_ex_DivRem_q		<= '0';
			id_ex_Reti_q		<= '0';
			id_ex_RegDst_q		<= '0';
			id_ex_RegWrite_q	<= '0';
			id_ex_MemtoReg_q	<= '0';
		elsif (clk_i'event and clk_i='1') then
			if (bubble_w = '1') then
				-- bubble: data fields and rs/rd indices cleared, all control
				-- bits deasserted so the NOP has no architectural effect
				id_ex_pc_q			<= (OTHERS => '0');
				id_ex_pc_plus4_q	<= (OTHERS => '0');
				id_ex_instruction_q	<= NOP_INSTRUCTION;
				id_ex_read_data1_q	<= (OTHERS => '0');
				id_ex_read_data2_q	<= (OTHERS => '0');
				id_ex_sign_ext_q	<= (OTHERS => '0');
				id_ex_rs1_q			<= (OTHERS => '0');
				id_ex_rs2_q			<= (OTHERS => '0');
				id_ex_rd_q			<= (OTHERS => '0');
				id_ex_ALUSrc_q		<= '0';
				id_ex_UpperIm_q		<= (OTHERS => '0');
				id_ex_ALUOp_q		<= ALU_NONE;
				id_ex_Branch_q		<= '0';
				id_ex_Jal_q			<= '0';
				id_ex_Jalr_q		<= '0';
				id_ex_MemRead_q		<= '0';
				id_ex_MemWrite_q	<= '0';
				id_ex_MemOp_q		<= MEM_W;
				id_ex_DivStart_q	<= '0';
				id_ex_DivSigned_q	<= '0';
				id_ex_DivRem_q		<= '0';
				id_ex_Reti_q		<= '0';
				id_ex_RegDst_q		<= '0';
				id_ex_RegWrite_q	<= '0';
				id_ex_MemtoReg_q	<= '0';
			elsif hold_i = '1' then
				null;	-- freeze ID/EX: the dividing instruction stays in EX
			else
				id_ex_pc_q			<= pc_i;
				id_ex_pc_plus4_q	<= pc_plus4_i;
				id_ex_instruction_q	<= instruction_i;
				id_ex_read_data1_q	<= read_data1_w;
				id_ex_read_data2_q	<= read_data2_w;
				id_ex_sign_ext_q	<= SignExt_w;
				id_ex_rs1_q			<= rs1_w;
				id_ex_rs2_q			<= rs2_w;
				id_ex_rd_q			<= rd_w;
				id_ex_ALUSrc_q		<= ALUSrc_ctrl_i;
				id_ex_UpperIm_q		<= UpperIm_ctrl_i;
				id_ex_ALUOp_q		<= ALUOp_ctrl_i;
				id_ex_Branch_q		<= Branch_ctrl_i;
				id_ex_Jal_q			<= Jal_ctrl_i;
				id_ex_Jalr_q		<= Jalr_ctrl_i;
				id_ex_MemRead_q		<= MemRead_ctrl_i;
				id_ex_MemWrite_q	<= MemWrite_ctrl_i;
				id_ex_MemOp_q		<= MemOp_ctrl_i;
				id_ex_DivStart_q	<= DivStart_ctrl_i;
				id_ex_DivSigned_q	<= DivSigned_ctrl_i;
				id_ex_DivRem_q		<= DivRem_ctrl_i;
				id_ex_Reti_q		<= Reti_ctrl_i;
				id_ex_RegDst_q		<= RegDst_ctrl_i;
				id_ex_RegWrite_q	<= RegWrite_ctrl_i;
				id_ex_MemtoReg_q	<= MemtoReg_ctrl_i;
			end if;
		end if;
	end process;

---------------------------------------------------------------------------------------
	-- ID-stage outputs (combinational)
	id_rs1_o			<= rs1_w;				-- HAZARD_UNIT load-use check
	id_rs2_o			<= rs2_w;
	
	-- ID/EX register outputs (EX-stage view)
	ex_pc_o				<= id_ex_pc_q;
	ex_pc_plus4_o		<= id_ex_pc_plus4_q;
	ex_instruction_o	<= id_ex_instruction_q;
	ex_read_data1_o		<= id_ex_read_data1_q;
	ex_read_data2_o		<= id_ex_read_data2_q;
	ex_sign_ext_o		<= id_ex_sign_ext_q;
	ex_rs1_o			<= id_ex_rs1_q;
	ex_rs2_o			<= id_ex_rs2_q;
	ex_rd_o				<= id_ex_rd_q;
	ex_ALUSrc_ctrl_o	<= id_ex_ALUSrc_q;
	ex_UpperIm_ctrl_o	<= id_ex_UpperIm_q;
	ex_ALUOp_ctrl_o		<= id_ex_ALUOp_q;
	ex_Branch_ctrl_o	<= id_ex_Branch_q;
	ex_Jal_ctrl_o		<= id_ex_Jal_q;
	ex_Jalr_ctrl_o		<= id_ex_Jalr_q;
	ex_MemRead_ctrl_o	<= id_ex_MemRead_q;
	ex_MemWrite_ctrl_o	<= id_ex_MemWrite_q;
	ex_MemOp_ctrl_o		<= id_ex_MemOp_q;
	ex_DivStart_ctrl_o	<= id_ex_DivStart_q;
	ex_DivSigned_ctrl_o	<= id_ex_DivSigned_q;
	ex_DivRem_ctrl_o	<= id_ex_DivRem_q;
	ex_Reti_ctrl_o		<= id_ex_Reti_q;
	ex_RegDst_ctrl_o	<= id_ex_RegDst_q;
	gie_o				<= RF_q(3)(0);
	ex_RegWrite_ctrl_o	<= id_ex_RegWrite_q;
	ex_MemtoReg_ctrl_o	<= id_ex_MemtoReg_q;
---------------------------------------------------------------------------------------
	
END behavior;
