--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Component declarations package
-- RV32IM: core renamed to RV32IM_CORE, MUL16 component added
--============================================================================
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;		-- MEM_W, used as the dmemory MemOp_ctrl_i default


package aux_package is

	-- Board-facing structural top level (Final Project §3). Declared first
	-- because it sits above RV32IM_CORE in the hierarchy.
	component RV32IMscMCU is
		generic(
			RST_ACTIVE_LOW		: boolean	:= TRUE;
			GEN_DEBUG_PORTS		: boolean	:= TRUE;
			GEN_RESET_ON_LOCK	: boolean	:= TRUE;	-- Phase 4C, hold reset until the PLLs lock
			GEN_GPO_READBACK	: boolean	:= TRUE;	-- Phase 6B, assumption A15
			GEN_INPUT_SYNC		: boolean	:= FALSE;	-- Hanan: switches need no synchroniser
			KEY_ACTIVE_LOW		: boolean	:= TRUE;	-- Phase 6C, assumption A16
			WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
			MODELSIM			: integer	:= G_MODELSIM;
			DATA_BUS_WIDTH		: integer	:= 32;
			ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
			PC_WIDTH			: integer	:= G_PC_WIDTH;
			MA_WIDTH			: integer	:= G_MA_WIDTH;
			DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH		: integer	:= 16
		);
		PORT(
			--Inputs
			clk_i				:IN		STD_LOGIC;
			rst_i				:IN		STD_LOGIC;

			--GPIO board input (Phase 6B). Defaulted so the four earlier testbenches,
			--which do not associate it, still elaborate.
			SW_i				:IN		STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
			KEY_i				:IN		STD_LOGIC_VECTOR(3 DOWNTO 1) := (OTHERS => '1');

			--GPIO board outputs (Phase 6A, Figure 5)
			LEDR_o				:OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
			HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);

			--Outputs (Signal-Tap observation, gated by GEN_DEBUG_PORTS)
			pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			RegWrite_ctrl_o		:OUT	STD_LOGIC;
			MemWrite_ctrl_o		:OUT	STD_LOGIC;
			Branch_ctrl_o		:OUT	STD_LOGIC;

			read_data1_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			write_data_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			alu_res_o			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			brTaken_o			:OUT	STD_LOGIC;

			dtcm_addr_o			:OUT	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

			-- Phase 5B (G-305): decoder observation, gated by GEN_DEBUG_PORTS.
			-- dtcm_wren_o is the gated write enable -- the fix itself, and what
			-- tb_mmio_alias asserts on.
			dtcm_cs_o			:OUT	STD_LOGIC;
			unmapped_o			:OUT	STD_LOGIC;
			dtcm_wren_o			:OUT	STD_LOGIC;

			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	component RV32IM_CORE is
		generic( 
			WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	    	MODELSIM 			: integer 	:= G_MODELSIM;
			DATA_BUS_WIDTH 		: integer 	:= 32;
			ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
			PC_WIDTH 			: integer 	:= 10;
			MA_WIDTH 			: integer 	:= 10;
			DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
			CLK_CNT_WIDTH 		: integer 	:= 16
		);
		PORT(	
			--Inputs
			rst_i		 		:IN	STD_LOGIC;
			clk_i				:IN	STD_LOGIC;
			divclk_i			:IN	STD_LOGIC := '0';	-- Phase 7B2, Figure 3's divclk

			--Data-bus master interface -- Phase 5B (G-305). Figure 1's boundary
			--between the RISC-V core and the BUS Interface Logic. Kept separate
			--from the Signal-Tap ports below, which clause 7 requires to be
			--removable and which therefore cannot carry a functional bus.
			dbus_addr_o			:OUT	STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
			dbus_wdata_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dbus_MemRead_o		:OUT	STD_LOGIC;
			dbus_MemWrite_o		:OUT	STD_LOGIC;
			dtcm_cs_i			:IN		STD_LOGIC := '1';
			dbus_rdata_i		:IN		STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

			--Outputs (used also for Signal-Tap auxiliary pins)
			pc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			RegWrite_ctrl_o		:OUT 	STD_LOGIC;
			MemWrite_ctrl_o		:OUT 	STD_LOGIC;
			Branch_ctrl_o		:OUT 	STD_LOGIC;
			
			read_data1_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o 		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			write_data_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			
			alu_res_o 			:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);															
			brTaken_o			:OUT 	STD_LOGIC; 
			
			dtcm_addr_o			:OUT 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_o		:OUT 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_data_rd_o		:OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			dtcm_wren_o			:OUT	STD_LOGIC;		-- Phase 5B, observation
			-- mclk_o REMOVED by Phase 4C: the clock tree moved up to RV32IMscMCU
			-- per Figure 1, so the core receives mclk on clk_i instead of making
			-- and exporting it.

			mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
		);		
	end component;
---------------------------------------------------------  
	component control is
		PORT( 
		--Inputs
		instruction_i 			: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
		
		--Outputs
		RegDst_ctrl_o 			: OUT 	STD_LOGIC;
		ALUSrc_ctrl_o 			: OUT 	STD_LOGIC;
		MemtoReg_ctrl_o 		: OUT 	STD_LOGIC;
		RegWrite_ctrl_o 		: OUT 	STD_LOGIC;
		MemRead_ctrl_o 			: OUT 	STD_LOGIC;
		MemWrite_ctrl_o	 		: OUT 	STD_LOGIC;
		Branch_ctrl_o 			: OUT 	STD_LOGIC;
		Jal_ctrl_o 				: OUT 	STD_LOGIC;
		Jalr_ctrl_o 			: OUT 	STD_LOGIC;
		UpperIm_ctrl_o			: OUT 	STD_LOGIC_VECTOR(1 DOWNTO 0);
		ALUOp_ctrl_o	 		: OUT 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		MemOp_ctrl_o			: OUT 	STD_LOGIC_VECTOR(2 DOWNTO 0);	-- Phase 3B (G-309)
		-- Phase 7B2: Figure 3's DIVstart, plus the two qualifiers.
		DivStart_ctrl_o			: OUT	STD_LOGIC;
		DivSigned_ctrl_o		: OUT	STD_LOGIC;
		DivRem_ctrl_o			: OUT	STD_LOGIC
	);
	end component;
---------------------------------------------------------	
	-- Clock-domain-crossing synchronizer, Figures 10a/10b (gap G-310). Not yet
	-- instantiated by the core: it is a leaf for the divider (Phase 7), the KEY1-3
	-- edge detectors (Phase 6) and the UART status flags (Phase 12). Declared here
	-- so all three use one verified implementation instead of three inline copies.
	component sync is
		generic(
			DATA_WIDTH	: integer := 32;
			STAGES		: integer := 2;
			GEN_SRC_REG	: boolean := TRUE
		);
		PORT(
			--Inputs
			src_clk_i	: IN	STD_LOGIC;
			dst_clk_i	: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			d_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

			--Outputs
			q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	-- The unsigned multicycle division accelerator of Figure 9 (gap G-301),
	-- labelled "Divider Accelerator 32-bit" in Figure 3. Phase 7A built and
	-- verified it standalone; Phase 7B instantiates it, feeds Ain/Bin through two
	-- `sync` instances per Figure 10b, and brings DIVBUSY back the other way.
	-- Generic in N only so its testbench can sweep a narrow copy exhaustively --
	-- the design instantiates it at the N = 32 of page 9.
	component div_accel is
		generic(
			N	: integer := 32
		);
		PORT(
			--Inputs
			divclk_i	: IN	STD_LOGIC;
			divrst_i	: IN	STD_LOGIC;
			divena_i	: IN	STD_LOGIC;
			dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);

			--Outputs
			divbusy_o	: OUT	STD_LOGIC;
			quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			residue_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	-- Phase 7B1. The division SUBSYSTEM: Figure 9's engine plus the four clock-
	-- domain crossings, the MCLK-side handshake and the signed div/rem wrapper.
	-- It presents an MCLK-domain interface so that Phase 7B2's work in the core is
	-- decode, a stall term and a write-back mux -- and nothing about clock domains.
	--
	-- BUILD THE STALL ON done_o, NOT ON busy_o. DIVstart takes two synchroniser
	-- stages to reach the engine and DIVBUSY two more to come back, so busy_o
	-- still reads LOW for several MCLK cycles after a div issues. The stall term
	-- is  PCHold <= DIVstart AND NOT done_o.
	component div_unit is
		generic(
			N	: integer := 32
		);
		PORT(
			--Inputs
			mclk_i		: IN	STD_LOGIC;
			divclk_i	: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			start_i		: IN	STD_LOGIC;
			signed_i	: IN	STD_LOGIC;
			dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);

			--Outputs
			busy_o		: OUT	STD_LOGIC;
			done_o		: OUT	STD_LOGIC;
			quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			remainder_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	-- The "Optimized Address Decoder" of Figure 5 (gap G-305). Splits the 14-bit
	-- data address space of §3 into DTCM and SFR, and produces one chip select
	-- per mapped SFR word. Phase 5A built it with an exhaustive testbench; Phase
	-- 5B instantiates it in RV32IMscMCU, where Figure 1 puts the BUS Interface
	-- Logic. The peripherals of Phases 6-9 and 12 attach to sfr_cs_o.
	component addr_decoder is
		generic(
			ADDR_WIDTH		: integer := DATA_ADDR_WIDTH;
			DTCM_WORDS_NUM	: integer := G_DATA_WORDSNUM
		);
		PORT(
			--Inputs
			addr_i			: IN	STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);

			--Outputs
			dtcm_cs_o		: OUT	STD_LOGIC;
			sfr_cs_o		: OUT	STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);
			unmapped_o		: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	-- The tri-state buffer of Figure 5, and the block Figure 1's
	-- "Bi-directional Data BUS (reminder)" link points at (gap G-306). USED AS IS
	-- from the students' Lab 3 -- the body of DUT/RV32IMscMCU/BIDIRPIN.vhd is
	-- byte-identical to Auxiliary/Lab 5/Auxilary/Lab3/DUT/BidirPin.vhd (since deleted from the tree), md5
	-- ab12d81dcdc85d91071b077359833bbd, so the port names are that file's.
	-- Instantiated once per readable SFR register plus one bus terminator.
	component BidirPin is
		generic( width : integer := 16 );
		PORT(
			Dout	: IN	STD_LOGIC_VECTOR(width-1 DOWNTO 0);
			en		: IN	STD_LOGIC;
			Din		: OUT	STD_LOGIC_VECTOR(width-1 DOWNTO 0);
			IOpin	: INOUT	STD_LOGIC_VECTOR(width-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	-- One general-purpose OUTPUT port interface of Figure 5 (gap G-306): a
	-- register holding D0..D7, enabled by CS . MemWrite (. A0 for the ports that
	-- share a chip select). Instantiated seven times in RV32IMscMCU.
	component gpo_port is
		generic(
			DATA_WIDTH	: integer := 8
		);
		PORT(
			--Inputs
			clk_i		: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;
			cs_i		: IN	STD_LOGIC;
			MemWrite_i	: IN	STD_LOGIC;
			lane_en_i	: IN	STD_LOGIC := '1';
			data_i		: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

			--Outputs
			q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	-- The "7-segment encoder" of Figure 5. USED AS IS from the students' Lab 4 --
	-- the body of DUT/RV32IMscMCU/HEX_DECODER.vhd is byte-identical to
	-- Auxiliary/Lab4/DUT/hex_decoder.vhd (md5 56f2f166...), so the
	-- port names here are that file's, not this project's _i/_o convention.
	component hex_decoder is
		PORT(
			bin : IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			seg : OUT	STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	end component;
---------------------------------------------------------

	component dmemory is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			DTCM_ADDR_WIDTH 	: integer := 8;
			WORDS_NUM 			: integer := 256
		);
		PORT(	
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i				: IN 	STD_LOGIC;
			dtcm_addr_i 		: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
			dtcm_data_wr_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			MemRead_ctrl_i  	: IN 	STD_LOGIC;
			MemWrite_ctrl_i 	: IN 	STD_LOGIC;
			-- Phase 3B (G-309). Defaults keep an older instantiation valid as a
			-- word-only memory; MEM_W comes from const_package.
			MemOp_ctrl_i		: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;
			byte_sel_i			: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
			-- Phase 5B (G-305). Defaulted to '1' so a pre-decoder instantiation
			-- behaves exactly as before.
			dtcm_cs_i			: IN 	STD_LOGIC := '1';

			--Outputs
			dtcm_data_rd_o 		: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			-- Phase 5B: the gated write enable, for observation. See DMEMORY.vhd.
			dtcm_wren_o			: OUT STD_LOGIC
		);
	end component;
---------------------------------------------------------		
	component Execute is
		generic(
			DATA_BUS_WIDTH 		: integer := 32;
			PC_WIDTH 			: integer := 10
		);
		PORT(	
			--Inputs
			read_data1_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			read_data2_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			sign_extend_i 		: IN 	STD_LOGIC_VECTOR(31 DOWNTO 0);
			UpperIm_ctrl_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0);
			ALUOp_ctrl_i	 	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
			ALUSrc_ctrl_i 		: IN 	STD_LOGIC;
			pc_i				: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
				
			--Outputs
			brTaken_o 			: OUT	STD_LOGIC;
			alu_res_o 			: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			addr_gen_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------		
	component MUL16 is
		generic(
			DATA_BUS_WIDTH 	: integer := 32
		);
		PORT(
			--Inputs (lower half-words of rs1/rs2)
			a_i 				: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);
			b_i 				: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);

			--Output (full product)
			res_o 				: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------		
	component Idecode is
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
			-- Phase 7B2: Figure 3's widened write-back mux.
			DivSel_ctrl_i		: IN 	STD_LOGIC := '0';
			div_result_i		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
			
			--Outputs
			read_data1_o		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			read_data2_o		: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			SignExt_o 			: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)		 
		);
	end component;
---------------------------------------------------------		
	component Ifetch is
		generic(
			WORD_GRANULARITY 	: boolean	:= False;
			DATA_BUS_WIDTH 		: integer	:= 32;
			PC_WIDTH 			: integer	:= 10;
			ITCM_ADDR_WIDTH 	: integer	:= 8;
			WORDS_NUM 			: integer	:= 256
		);
		PORT(
			--Inputs
			clk_i				: IN 	STD_LOGIC;
			rst_i 				: IN 	STD_LOGIC;
			addr_gen_i 			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			Branch_ctrl_i		: IN 	STD_LOGIC;
			brTaken_i 			: IN 	STD_LOGIC;
			Jal_ctrl_i			: IN 	STD_LOGIC;
			Jalr_ctrl_i			: IN 	STD_LOGIC;
			alu_res_i 			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
			PCHold_i			: IN	STD_LOGIC := '0';	-- Phase 7B2, Figure 3
			
			--Outputs
			pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
			instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
		);
	end component;
---------------------------------------------------------
	COMPONENT PLL IS
		port(
			areset				: IN STD_LOGIC  := '0';
			inclk0				: IN STD_LOGIC  := '0';
			c0     				: OUT STD_LOGIC ;
			locked				: OUT STD_LOGIC
		);
  END COMPONENT;
---------------------------------------------------------
	-- Phase 4B. PLL.vhd with four wizard constants promoted to generics, so that
	-- three instances can run at three ratios -- PLL.vhd's entity takes no
	-- generics at all, which is the real reason a plain three-instance clock tree
	-- was not possible before. PLL.vhd itself is left byte-identical (md5
	-- a12064f2...) and the core still instantiates it; see PLL_GEN.vhd's header
	-- for why the boilerplate is duplicated rather than the original edited.
	component pll_gen is
		generic(
			DIVIDE_BY		: NATURAL := G_PLL_DIV;
			MULTIPLY_BY		: NATURAL := G_PLL_MUL;
			IN_PERIOD_PS	: NATURAL := 20000;
			DEVICE_FAMILY	: STRING  := "Cyclone II";
			LPM_HINT_STR	: STRING  := "CBX_MODULE_PREFIX=PLL_GEN"
		);
		PORT(
			areset			: IN	STD_LOGIC := '0';
			inclk0			: IN	STD_LOGIC := '0';
			c0				: OUT	STD_LOGIC;
			locked			: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------
	-- The "Clock Tree" of Figure 1 (gap G-311): baseclk50MHz in, mclk / smclk /
	-- accelclk out, built from three pll_gen instances per Hanan's forum answer
	-- F6. Phase 4B built and verified it standalone; Phase 4C instantiates it in
	-- RV32IMscMCU, releases reset on lock, and constrains all three in the SDC.
	-- Read CLOCK_TREE.vhd's header before wiring it in: the lock delay and the
	-- free-running simulation clocks both have consequences for existing tests.
	component clock_tree is
		generic(
			MODELSIM			: integer := G_MODELSIM;
			IN_FREQ_KHZ			: natural := 50000;
			IN_PERIOD_PS		: natural := 20000;
			MCLK_KHZ			: natural := 20000;
			MCLK_MUL			: natural := 2;
			MCLK_DIV			: natural := 5;
			SMCLK_KHZ			: natural := 20000;
			SMCLK_MUL			: natural := 2;
			SMCLK_DIV			: natural := 5;
			ACCELCLK_KHZ		: natural := 50000;
			ACCEL_MUL			: natural := 1;
			ACCEL_DIV			: natural := 1;
			SMCLK_SHARES_MCLK	: boolean := TRUE;
			SIM_ACCEL_HALF_NS	: natural := 15;
			SIM_SMCLK_HALF_NS	: natural := 35;
			SIM_LOCK_DELAY_NS	: natural := 200
		);
		PORT(
			--Inputs
			clk_i		: IN	STD_LOGIC;
			rst_i		: IN	STD_LOGIC;

			--Outputs
			mclk_o		: OUT	STD_LOGIC;
			smclk_o		: OUT	STD_LOGIC;
			accelclk_o	: OUT	STD_LOGIC;
			locked_o	: OUT	STD_LOGIC
		);
	end component;
---------------------------------------------------------

end aux_package;
