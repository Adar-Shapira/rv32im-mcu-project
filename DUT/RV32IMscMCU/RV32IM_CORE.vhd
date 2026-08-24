--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Top Level Structural Model for Single-Cycle RISC-V RV32IM Core
-- RV32IM: renamed from RV32I_CORE; wiring unchanged (mul flows through the
-- existing ALU result path inside EXECUTE)
--============================================================================ 
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;		-- Phase 5B: DATA_ADDR_WIDTH (clause 3's 14-bit space)
USE work.aux_package.all;


ENTITY RV32IM_CORE IS
	generic( 
			WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	    	MODELSIM 			: integer 	:= G_MODELSIM;
			DATA_BUS_WIDTH 		: integer 	:= 32;
			ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			PC_WIDTH 			: integer 	:= G_PC_WIDTH;
			MA_WIDTH 			: integer 	:= G_MA_WIDTH;
			DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH 		: integer 	:= 16
	);
	PORT(
		--Inputs
		rst_i		 			:IN		STD_LOGIC;
		clk_i					:IN		STD_LOGIC;

		--======================================================================
		-- Data-bus master interface -- Phase 5B (G-305)
		--======================================================================
		-- Figure 1 (p3) draws the Control / Address / Data buses leaving the
		-- RISC-V core box and reaching the peripherals through a BUS Interface
		-- Logic block. This is that boundary. The DTCM stays inside the core,
		-- because Figures 1 and 3 both draw it there; what leaves is the request,
		-- so the decoder outside can say which region it names.
		--
		-- WHY THIS IS A SEPARATE PORT GROUP AND NOT THE SIGNAL-TAP PORTS
		--   alu_res_o, dtcm_data_wr_o and MemWrite_ctrl_o below already carry the
		--   address, the write data and the write strobe -- it is tempting to
		--   reuse them. That would be a bug: clause 7 requires the Signal-Tap
		--   pins to be removable through a generate, and a bus that depends on
		--   them cannot be removed. They are observation only. This group is
		--   functional.
		--
		-- WHY MemOp IS NOT HERE
		--   A peripheral does not need the access width. Figure 5 wires every
		--   latch input D0..D7 to Data<7..0> unconditionally, and the benchmarks
		--   reach byte registers with a word store (see ADDR_DECODER.vhd). Width
		--   only matters to the DTCM, which is inside.
		dbus_addr_o				:OUT	STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
		dbus_wdata_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		dbus_MemRead_o			:OUT	STD_LOGIC;
		dbus_MemWrite_o			:OUT	STD_LOGIC;

		-- Both defaulted, so this entity still elaborates and behaves exactly as
		-- it did before Phase 5B when instantiated without a bus interface --
		-- which is what keeps the LAB5 baseline reproducible.
		dtcm_cs_i				:IN		STD_LOGIC := '1';
		dbus_rdata_i			:IN		STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

		--Outputs (used also for Signal-Tap auxiliary pins)
		pc_o					:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		
		RegWrite_ctrl_o			:OUT 	STD_LOGIC;
		MemWrite_ctrl_o			:OUT 	STD_LOGIC;
		Branch_ctrl_o			:OUT 	STD_LOGIC;
		
		read_data1_o 			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		read_data2_o 			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		write_data_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		
		alu_res_o 				:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);															
		brTaken_o				:OUT 	STD_LOGIC; 
		
		dtcm_addr_o				:OUT 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
		dtcm_data_wr_o			:OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		dtcm_data_rd_o			:OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- Phase 5B: the DTCM's gated write enable. Observation only -- see the
		-- header of DMEMORY.vhd for why this is a port and not an internal signal.
		dtcm_wren_o				:OUT	STD_LOGIC;
		
		mclk_cnt_o				:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
	);		
END RV32IM_CORE;
--============================================================================
ARCHITECTURE structure OF RV32IM_CORE IS
	-- declare signals used to connect VHDL components
	SIGNAL pc_w 				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_w 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL read_data1_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL sign_extend_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL addr_gen_w 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_w 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_w 		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	-- Phase 5B: the DTCM's own output, before the region mux below chooses
	-- between it and the peripheral read data.
	SIGNAL dtcm_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_addr_w 			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL alu_src_w 			: STD_LOGIC;
	SIGNAL branch_w 			: STD_LOGIC;
	SIGNAL Jal_ctrl_w 			: STD_LOGIC;
	SIGNAL Jalr_ctrl_w 			: STD_LOGIC;
	SIGNAL reg_write_w 			: STD_LOGIC;
	SIGNAL reg_dst_w 			: STD_LOGIC;
	SIGNAL brTaken_w 			: STD_LOGIC;
	SIGNAL mem_write_w 			: STD_LOGIC;
	SIGNAL MemtoReg_w 			: STD_LOGIC;
	SIGNAL mem_read_w 			: STD_LOGIC;
	-- Phase 3B (G-309): sub-word access width, and the byte offset the word
	-- address drops on its way to the RAM.
	SIGNAL mem_op_w				: STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL byte_sel_w			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL upper_im_w			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL alu_op_w 			: STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_w 				: STD_LOGIC;
	SIGNAL mclk_cnt_q			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

BEGIN
	
	--=======================================
	-- PLL module connection
	--=======================================
	G0:
	if (MODELSIM = 0) generate
	  MCLK: PLL
		PORT MAP (
			inclk0 	=> clk_i,
			c0 		=> mclk_w
		);
	else generate
		mclk_w 	<= clk_i;
	end generate;
	--===========================================
	-- IFETCH (including ITCM) module connection
	--===========================================
	IFE : Ifetch
	generic map(
		WORD_GRANULARITY	=> 	WORD_GRANULARITY,
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH, 
		PC_WIDTH			=>	PC_WIDTH,
		ITCM_ADDR_WIDTH		=>	ITCM_ADDR_WIDTH,
		WORDS_NUM			=>	DATA_WORDS_NUM
	)
	PORT MAP (
		--Inputs
		clk_i 				=> mclk_w,  
		rst_i 				=> rst_i, 
		addr_gen_i 			=> addr_gen_w,
		Branch_ctrl_i 		=> branch_w,
		brTaken_i			=> brTaken_w,
		Jal_ctrl_i 			=> Jal_ctrl_w,
		Jalr_ctrl_i			=> Jalr_ctrl_w,
		alu_res_i			=> alu_res_w,
		
		--Outputs
		pc_o 				=> pc_w,
		pc_plus4_o	 		=> pc_plus4_w,
		instruction_o 		=> instruction_w    
	);
	--=======================================
	-- IDECODE module connection
	--=======================================
	ID : Idecode
  generic map(
		PC_WIDTH			=>	PC_WIDTH,
		DATA_BUS_WIDTH		=>  DATA_BUS_WIDTH
	)
	PORT MAP (	
		--Inputs
		clk_i 				=> mclk_w,  
		rst_i 				=> rst_i,
		pc_plus4_i	 		=> pc_plus4_w,
    	instruction_i 		=> instruction_w,
    	dtcm_data_rd_i 		=> dtcm_data_rd_w,
		alu_res_i 			=> alu_res_w,
		RegDst_ctrl_i		=> reg_dst_w,
		RegWrite_ctrl_i 	=> reg_write_w,
		MemtoReg_ctrl_i 	=> MemtoReg_w,
		
		--Outputs
		read_data1_o 		=> read_data1_w,
    	read_data2_o 		=> read_data2_w,
		SignExt_o 			=> sign_extend_w	 
	);
	--=======================================
	-- CONTROL module connection
	--=======================================
	CTL:   control
	PORT MAP ( 	
		--Inputs
		instruction_i 		=> instruction_w,
		
		--Outputs
		RegDst_ctrl_o		=> reg_dst_w,
		ALUSrc_ctrl_o 		=> alu_src_w,
		MemtoReg_ctrl_o 	=> MemtoReg_w,
		RegWrite_ctrl_o 	=> reg_write_w,
		MemRead_ctrl_o 		=> mem_read_w,
		MemWrite_ctrl_o 	=> mem_write_w,
		Branch_ctrl_o 		=> branch_w,
		Jal_ctrl_o 			=> Jal_ctrl_w,
		Jalr_ctrl_o			=> Jalr_ctrl_w,
		UpperIm_ctrl_o 		=> upper_im_w,
		ALUOp_ctrl_o 		=> alu_op_w,
		MemOp_ctrl_o		=> mem_op_w			-- Phase 3B (G-309): access width
	);
	--=======================================
	-- EXECUTE module connection
	--=======================================
	EXE:  Execute
  	generic map(
		DATA_BUS_WIDTH 		=> 	DATA_BUS_WIDTH,
		PC_WIDTH 			=>	PC_WIDTH
	)
	PORT MAP (	
		--Inputs
		read_data1_i 		=> read_data1_w,
    	read_data2_i 		=> read_data2_w,
		sign_extend_i 		=> sign_extend_w,
		UpperIm_ctrl_i 		=> upper_im_w,
		ALUOp_ctrl_i 		=> alu_op_w,
		ALUSrc_ctrl_i 		=> alu_src_w,
		pc_i				=> pc_w,
		
		--Outputs
		brTaken_o 			=> brTaken_w,
    	alu_res_o			=> alu_res_w,
		addr_gen_o 			=> addr_gen_w			
	);
	--=======================================
	-- DTCM module connection
	--=======================================
	G1: 
	if (WORD_GRANULARITY = True) generate -- i.e. each WORD has a unike address
		dtcm_addr_w	<= alu_res_w(MA_WIDTH-1 DOWNTO 2); -- increment memory address by 4;
	elsif (WORD_GRANULARITY = False) generate -- i.e. each BYTE has a unike address
		dtcm_addr_w	<= alu_res_w(MA_WIDTH-1 DOWNTO 0);
	end generate;
	
	-- Phase 3B (G-309): the two low bits of the byte address. G1 above narrows
	-- alu_res_w to the word address and drops exactly these bits, so they have
	-- to be carried to DMEMORY separately to select the byte lane.
	-- Under WORD_GRANULARITY = False the memory is byte-addressed and this
	-- signal is meaningless -- that configuration is not used by this project
	-- (the RAM is 32 bits wide, so it was never self-consistent) and is not
	-- exercised by any test.
	byte_sel_w <= alu_res_w(1 DOWNTO 0);

	MEM:  dmemory
	generic map(
		DATA_BUS_WIDTH		=> 	DATA_BUS_WIDTH,
		DTCM_ADDR_WIDTH		=> 	DTCM_ADDR_WIDTH,
		WORDS_NUM			=>	DATA_WORDS_NUM
	)
	PORT MAP (
		--Inputs
		clk_i 				=> mclk_w,
		rst_i 				=> rst_i,
		dtcm_addr_i 		=> dtcm_addr_w,
		dtcm_data_wr_i 		=> read_data2_w,
		MemRead_ctrl_i 		=> mem_read_w,
		MemWrite_ctrl_i 	=> mem_write_w,
		MemOp_ctrl_i		=> mem_op_w,
		byte_sel_i			=> byte_sel_w,
		dtcm_cs_i			=> dtcm_cs_i,		-- Phase 5B (G-305): gates wren_a

		--Outputs
		dtcm_data_rd_o 		=> dtcm_rd_w,
		dtcm_wren_o			=> dtcm_wren_o		-- Phase 5B: straight out for observation
	);

	--=======================================
	-- Load-data region mux -- Phase 5B (G-305)
	--=======================================
	-- The load value the register file writes back comes from the DTCM when the
	-- address named the DTCM, and from the bus interface otherwise. A plain mux,
	-- not a tri-state: Figure 1's "Bi-directional Data BUS (reminder)" arrow
	-- points at the buses on the PERIPHERAL side of the BUS Interface Logic, and
	-- Figure 5 draws the tri-state at the peripheral (PORT_SW on CS7.MemRead).
	-- The core-to-bus-interface link is not where the figures put the shared
	-- driver, so the tri-state belongs in Phase 6, where it will have a real
	-- second driver instead of being a one-driver bus with a keeper.
	--
	-- Assumption, recorded in DOC/02 section 2.1: Figure 3 shows a buffer symbol
	-- below the DTCM whose connectivity cannot be resolved at the resolution of
	-- the supplied raster. If it turns out to be a tri-state onto a shared
	-- core-internal data bus, this mux is the single place that changes.
	dtcm_data_rd_w <= dtcm_rd_w WHEN dtcm_cs_i = '1' ELSE dbus_rdata_i;

	--=======================================
	-- Data-bus master outputs -- Phase 5B (G-305)
	--=======================================
	-- The full byte address, NOT the narrowed word address: the decoder needs
	-- A13 for the region split and A1..A0 to separate the registers that share a
	-- chip select. G1 above drops exactly those bits on the way to the RAM.
	dbus_addr_o		<= alu_res_w(DATA_ADDR_WIDTH-1 DOWNTO 0);
	dbus_wdata_o	<= read_data2_w;	-- what a store presents, same source as the DTCM's
	dbus_MemRead_o	<= mem_read_w;
	dbus_MemWrite_o	<= mem_write_w;
	
	--=======================================
	-- MCLK counter register connection
	--=======================================									
	process (mclk_w , rst_i)
	begin
		if rst_i = '1' then
			mclk_cnt_q	<=	(others	=> '0');
		elsif rising_edge(mclk_w) then
			mclk_cnt_q	<=	mclk_cnt_q + '1';
		end if;
	end process;
---------------------------------------------------------------------------------------
-- Copying out important signals only for Verification and FPGA Velidation(Signal-TAP)
---------------------------------------------------------------------------------------
	pc_o					<=	pc_w;				-- IFETCH output								
  	instruction_o 			<= 	instruction_w;		-- IFETCH output
	
	RegWrite_ctrl_o 		<= 	reg_write_w;		-- CONTROL output
  	MemWrite_ctrl_o 			<= 	mem_write_w;	-- CONTROL output
	Branch_ctrl_o 			<= 	branch_w;			-- CONTROL output
	  
  	read_data1_o 			<= 	read_data1_w;		-- IDECODE output
  	read_data2_o 			<= 	read_data2_w;		-- IDECODE output
  	write_data_o  			<= 	dtcm_data_rd_w WHEN MemtoReg_w = '1' ELSE		-- IDECODE input(Write-Back) 
								alu_res_w;
												
  	alu_res_o 				<= 	alu_res_w;			-- EXECUTE output			
  	brTaken_o 				<= 	brTaken_w;			-- EXECUTE output
  
	dtcm_addr_o 			<= 	dtcm_addr_w;		-- DMEMORY input
	dtcm_data_wr_o 			<= 	read_data2_w;		-- DMEMORY input
	dtcm_data_rd_o			<=	dtcm_data_rd_w;		-- the load value written back.
													-- Phase 5B: this is now AFTER the
													-- region mux, so on an SFR load it
													-- shows the bus data, not the DTCM word.
	
	mclk_cnt_o				<=	mclk_cnt_q;			-- TOP output
	
---------------------------------------------------------------------------------------

END structure;
