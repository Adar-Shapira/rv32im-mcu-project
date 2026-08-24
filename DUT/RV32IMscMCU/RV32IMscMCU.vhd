--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — RV32IM-based MCU, single-cycle
--
-- RV32IMscMCU — board-facing structural top level.
--
-- WHY THIS LEVEL EXISTS
--   Assignment definition §3: "The top level and the RV32IM core must be
--   structural" — two structural levels, not one. This is the outer one. The
--   MCU block of Figure 1 (p3) lives here: clock tree, RISC-V core, bus
--   interface logic and peripherals. The core itself stays a pure CPU.
--
--   Reference for the pattern: Auxilary/Lab4/DUT/fpga_hw_interface.vhd, the
--   board-level structural top of Lab 4, which conditions its KEY/SW inputs
--   and instantiates the PLL above the logic it drives.
--
-- WHY RESET POLARITY IS HANDLED HERE AND NOT IN THE CORE
--   KEY0 on the DE2-115 is active-low (idle='1', pressed='0') and §3 mandates
--   KEY0 as the system reset, so an inversion is needed somewhere. It belongs
--   at the board boundary, exactly as Lab 4 does it, for two reasons:
--     1. Everything below stays polarity-agnostic and matches the supplied
--        baseline Auxilary/DUT/RV32I_CORE.vhd, which wires rst_i straight to
--        every submodule.
--     2. It must not be tied to MODELSIM. MODELSIM selects PLL bypass; giving
--        it a second, unrelated job means forgetting to set it stops inverting
--        the clock source AND starts inverting the reset, and the core never
--        leaves reset. RST_ACTIVE_LOW below is an independent generic.
--
-- SCOPE, AS OF PHASE 5B
--   Phase 1 made this level deliberately thin: instantiate RV32IM_CORE, condition
--   reset, and be behaviourally transparent so the Lab 5 baseline cycle counts
--   (134 / 1514 / 2725 / 2735) reproduce through it unchanged.
--
--   Phase 5B adds the first real content: the BUS Interface Logic block of
--   Figure 1, which is the address decoder plus the read return path. The core
--   keeps its own PLL and its own DTCM — Figures 1 and 3 both draw the DTCM
--   inside the core — and what crosses this boundary is the request.
--
--   THE PHASE 1 CRITERION STILL HOLDS, and it was checked rather than assumed.
--   None of the four Lab 5 benchmarks can form a data address at or above 0x2000.
--   Derived from the shipped images under
--   Auxiliary/Lab 5 - as submitted/Auxilary/Benchmarks/test*/RV32IM/man_compiled/
--   bin/M9K-intel/ITCM.hex: none of the four contains a single lui, and their only
--   large-base instruction is auipc, whose immediate is 0 in all 31 occurrences
--   across the four. So every base is a PC value, the programs are 29 to 62
--   instructions long, and the largest displacement a load or store can add is
--   +2047:
--
--       test1  max base   44  ->  bound 2091
--       test2  max base   44  ->  bound 2091
--       test3  max base  160  ->  bound 2207   (the worst of the four, 0x89F)
--       test4  max base   68  ->  bound 2115
--
--   against an SFR page starting at 0x2000 = 8192. So dtcm_cs is '1' on every
--   access these programs make, the gated write enable equals the ungated one,
--   the load mux always selects the DTCM, and the cycle counts must be
--   bit-identical.
--
--   That is a bound from the address-formation instructions, not a full symbolic
--   execution: a long chain of addi on a pointer could in principle climb higher,
--   which it does not in 29 to 62 instructions. The definitive check is still
--   Adar's four cycle counts staying at 134 / 1514 / 2725 / 2735. If they move,
--   this phase broke something.
--
--   Still to attach here: the clock tree (mclk/smclk/accelclk, Figure 1) in
--   Phase 4B, and the GPIO / Basic Timer / interrupt controller / divider /
--   USART peripherals from Phase 6 onward, all onto sfr_cs_w.
--
-- SIGNAL-TAP PORTS
--   §7: "Location pins used for the validation phase (Signal-Tap) need to be
--   removed in the final step using a suitable parameter in the generate VHDL
--   statement." VHDL cannot conditionally declare a port, so the observation
--   ports always exist and the GEN_DEBUG_PORTS generate decides whether they
--   are driven from the core or tied off. Tied off, synthesis prunes the paths
--   and the .qsf carries no location assignment for them, which is what the
--   clause asks for.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.const_package.all;		-- Phase 5B: DATA_ADDR_WIDTH, SFR_CS_NUM, CS_*
USE work.aux_package.all;


ENTITY RV32IMscMCU IS
	generic(
		-- Board-boundary conditioning. TRUE  = rst_i comes from KEY0 (active-low).
		--                             FALSE = rst_i is already active-high, as the
		--                                     supplied testbench drives it.
		RST_ACTIVE_LOW		: boolean	:= TRUE;
		-- FALSE ties the observation ports off so no Signal-Tap pin is assigned (§7).
		GEN_DEBUG_PORTS		: boolean	:= TRUE;

		-- Passed through to the core unchanged.
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
		--=== Board pins ===
		clk_i				:IN		STD_LOGIC;		-- CLOCK_50, PIN_Y2
		rst_i				:IN		STD_LOGIC;		-- KEY0,     PIN_M23

		--=== GPIO board outputs — Phase 6A, Figure 5 (clause 5) ===
		-- Widths and roles from clause 5's table: PORT_LEDR drives LEDR7..LEDR0
		-- and each PORT_HEXn drives one 7-segment display. Port names take the
		-- _o extension per Auxiliary/hanan/Useful name extensions.md; the board
		-- pin names the .qsf assigns are LEDR[n] and HEX0[n]..HEX5[n].
		--
		-- LEDR9 and LEDR8 are deliberately absent. Clause 4 says the board has ten
		-- red LEDs, clause 5 maps only eight, and the map is what is implementable
		-- -- there is no register bit for the other two. Not an omission.
		LEDR_o				:OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);

		--=== Observation ports — Signal-Tap only, gated by GEN_DEBUG_PORTS ===
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

		-- Phase 5B (G-305). Two decoder outputs, observation only like the rest of
		-- this group and removed with it by GEN_DEBUG_PORTS. They are here because
		-- they are the two signals the aliasing test has to see, and because they
		-- are exactly what Signal-Tap wants when a store goes to the wrong region:
		-- dtcm_cs_o says which memory answered, unmapped_o says nobody did.
		dtcm_cs_o			:OUT	STD_LOGIC;
		unmapped_o			:OUT	STD_LOGIC;
		-- The DTCM's gated write enable. This is the one that matters: it is the
		-- Phase 5B fix itself, so it is what tb_mmio_alias asserts on. Watching
		-- dtcm_cs_o instead would prove only that the decode is right and would
		-- still pass with the gate removed.
		dtcm_wren_o			:OUT	STD_LOGIC;

		mclk_cnt_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0)
	);
END RV32IMscMCU;
--============================================================================
ARCHITECTURE structure OF RV32IMscMCU IS

	-- Internal active-high reset presented to everything below this level.
	SIGNAL rst_w				: STD_LOGIC;

	-- Core observation taps, exported or tied off by the GEN_DEBUG_PORTS generate.
	SIGNAL pc_w					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL RegWrite_ctrl_w		: STD_LOGIC;
	SIGNAL MemWrite_ctrl_w		: STD_LOGIC;
	SIGNAL Branch_ctrl_w		: STD_LOGIC;
	SIGNAL read_data1_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_w			: STD_LOGIC;
	SIGNAL dtcm_addr_w			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL mclk_cnt_w			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

	--=======================================================================
	-- BUS Interface Logic -- Phase 5B (G-305), the block Figure 1 draws between
	-- the RISC-V core and the peripherals
	--=======================================================================
	SIGNAL dbus_addr_w			: STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dbus_wdata_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dbus_MemRead_w		: STD_LOGIC;
	SIGNAL dbus_MemWrite_w		: STD_LOGIC;
	SIGNAL dbus_rdata_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_cs_w			: STD_LOGIC;
	SIGNAL unmapped_w			: STD_LOGIC;
	SIGNAL dtcm_wren_w			: STD_LOGIC;

	-- One bit per mapped SFR word, indexed by the CS_* constants in
	-- const_package. Phase 5B has no peripherals yet, so this has a driver and
	-- no load and synthesis will report it as unused -- that is expected, not a
	-- mistake. Phases 6 to 9 and 12 attach to it.
	SIGNAL sfr_cs_w				: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);

	--=======================================================================
	-- GPIO — Phase 6A
	--=======================================================================
	-- The clock every peripheral here must use: the core's mclk, not clk_i. At
	-- MODELSIM = 0 the core runs on its internal PLL and clk_i is still the raw
	-- board clock, so clocking a peripheral from clk_i would sample core signals
	-- at the wrong rate. Phase 4B moves the clock tree to this level and this
	-- becomes a CLKTREE output instead of a core output.
	SIGNAL mclk_w				: STD_LOGIC;

	-- Byte-lane qualification, the A0 term of Figure 5. lane0 selects the register
	-- at the word's base address, lane1 the one at base+1 -- which is how the
	-- figure separates PORT_HEX0 from PORT_HEX1 on a shared chip select.
	SIGNAL lane0_w				: STD_LOGIC;
	SIGNAL lane1_w				: STD_LOGIC;

	-- Each port's stored byte, and each display's seven segments. Local array
	-- types rather than one flat vector, so an index is a display number and not
	-- an arithmetic slice. A TYPE declaration needs no package body.
	type hex_byte_array_t is array (0 TO 5) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type hex_seg_array_t  is array (0 TO 5) of STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL ledr_q				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex_q				: hex_byte_array_t;		-- what the CPU stored
	SIGNAL hex_seg_w			: hex_seg_array_t;		-- what the display shows

BEGIN
	--=======================================
	-- Reset conditioning at the board boundary
	--=======================================
	-- Independent of MODELSIM by design. See the header.
	RSTCOND:
	if (RST_ACTIVE_LOW) generate
		rst_w	<= not rst_i;
	else generate
		rst_w	<= rst_i;
	end generate;

	--=======================================
	-- RV32IM core
	--=======================================
	-- Phase 1: the core still contains its own PLL and DTCM. The clock tree and
	-- the bus interface move up to this level in Phases 4 and 5, at which point
	-- clk_i feeds CLKTREE and the core receives mclk instead.
	CORE : RV32IM_CORE
	generic map(
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH
	)
	PORT MAP (
		--Inputs
		rst_i				=> rst_w,
		clk_i				=> clk_i,

		--Data bus (Phase 5B)
		dbus_addr_o			=> dbus_addr_w,
		dbus_wdata_o		=> dbus_wdata_w,
		dbus_MemRead_o		=> dbus_MemRead_w,
		dbus_MemWrite_o		=> dbus_MemWrite_w,
		dtcm_cs_i			=> dtcm_cs_w,
		dbus_rdata_i		=> dbus_rdata_w,

		--Outputs
		pc_o				=> pc_w,
		instruction_o		=> instruction_w,

		RegWrite_ctrl_o		=> RegWrite_ctrl_w,
		MemWrite_ctrl_o		=> MemWrite_ctrl_w,
		Branch_ctrl_o		=> Branch_ctrl_w,

		read_data1_o		=> read_data1_w,
		read_data2_o		=> read_data2_w,
		write_data_o		=> write_data_w,

		alu_res_o			=> alu_res_w,
		brTaken_o			=> brTaken_w,

		dtcm_addr_o			=> dtcm_addr_w,
		dtcm_data_wr_o		=> dtcm_data_wr_w,
		dtcm_data_rd_o		=> dtcm_data_rd_w,
		dtcm_wren_o			=> dtcm_wren_w,

		mclk_o				=> mclk_w,			-- Phase 6A: clocks the peripherals
		mclk_cnt_o			=> mclk_cnt_w
	);

	--=======================================
	-- BUS Interface Logic (Figure 1) — the address decoder
	--=======================================
	-- Figure 1 puts this block between the RISC-V core and the peripherals, and
	-- that is why it is instantiated here and not inside the core: the core stays
	-- a CPU, and every peripheral of Phases 6-9 and 12 attaches to one decoder
	-- rather than each re-deriving the map.
	DEC : addr_decoder
	PORT MAP (
		--Inputs
		addr_i				=> dbus_addr_w,

		--Outputs
		dtcm_cs_o			=> dtcm_cs_w,
		sfr_cs_o			=> sfr_cs_w,
		unmapped_o			=> unmapped_w
	);

	--=======================================
	-- Read return path
	--=======================================
	-- PHASE 5B PLACEHOLDER — REPLACED IN PHASE 6.
	--   No peripheral exists yet, so a load from the SFR page has nothing to
	--   answer it. Zero is the defined answer rather than 'X' or 'Z' for two
	--   reasons: it keeps the GPIO suites deterministic (test1 and test2 read
	--   PORT_SW and immediately mask the result, so they simply take the
	--   SW0 = '0' branch), and it does not poison the register file with
	--   metavalues that would then flood the transcript from the ALU.
	--
	--   It is NOT silent. The report below fires on the first SFR access of a
	--   run, so a test cannot pass by quietly reading zeros from a peripheral
	--   that was never built. Phase 6 replaces this constant with the
	--   peripherals' tri-state read bus (Figure 5, BidirPin with width => 32)
	--   and deletes the process.
	dbus_rdata_w <= (OTHERS => '0');

	SFRSTUB:
	if (MODELSIM = 1) generate
		sfr_read_notice : process(clk_i)
			variable told_v : boolean := FALSE;
		begin
			if rising_edge(clk_i) then
				if (dbus_MemRead_w = '1' or dbus_MemWrite_w = '1')
				   and dtcm_cs_w = '0' and not told_v then
					told_v := TRUE;
					report "RV32IMscMCU: an SFR access reached the bus interface, but " &
						   "Phase 5B has no peripherals -- reads return zero and writes " &
						   "are discarded. Expected at this phase. Reported once per run."
						severity note;
				end if;
			end if;
		end process sfr_read_notice;
	end generate;

	--=======================================
	-- GPIO output ports (Figure 5, clause 5) -- Phase 6A
	--=======================================
	-- Figure 5's structure, instantiated once per port rather than generated, so
	-- each block reads directly against the figure: which chip select, which A0
	-- term, and for the HEX ports which display.
	--
	-- The byte lane. Figure 5 gives PORT_LEDR's latch only "CS1 . MemWrite" with
	-- no A0 term, because in the GPIO-only subset it draws, nothing shares that
	-- word. Every port here is qualified by its exact lane anyway. That is the
	-- same full-decode choice ADDR_DECODER.vhd already made and for the same
	-- reason: otherwise a store to 0x2001 would be reported by unmapped_o AND
	-- still land in PORT_LEDR, and having the report disagree with the hardware
	-- is worse than being stricter than the figure. No supplied benchmark writes
	-- any of these addresses off-lane, so nothing observable changes.
	lane0_w <= (NOT dbus_addr_w(1)) AND (NOT dbus_addr_w(0));	-- word base + 0
	lane1_w <= (NOT dbus_addr_w(1)) AND      dbus_addr_w(0);	-- word base + 1

	-- PORT_LEDR, 0x2000 -> LEDR7..LEDR0
	P_LEDR : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i		=> mclk_w,
		rst_i		=> rst_w,
		cs_i		=> sfr_cs_w(CS_LEDR),
		MemWrite_i	=> dbus_MemWrite_w,
		lane_en_i	=> lane0_w,
		data_i		=> dbus_wdata_w(7 DOWNTO 0),
		q_o			=> ledr_q
	);
	LEDR_o <= ledr_q;

	-- The six 7-segment ports. PORT_HEX0/1 share CS_HEX01 and are separated by
	-- A0, and likewise for the other two pairs -- exactly Figure 5's pairing.
	P_HEX0 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(0)			-- 0x2004
	);
	P_HEX1 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(1)			-- 0x2005
	);
	P_HEX2 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(2)			-- 0x2008
	);
	P_HEX3 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(3)			-- 0x2009
	);
	P_HEX4 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(4)			-- 0x200C
	);
	P_HEX5 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => mclk_w, rst_i => rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => dbus_wdata_w(7 DOWNTO 0), q_o => hex_q(5)			-- 0x200D
	);

	-- The "7-segment encoder" of Figure 5, one per display. Low nibble only --
	-- the software shifts the digit down before storing, see HEX_DECODER.vhd.
	SEGGEN:
	for i in 0 to 5 generate
		SEG : hex_decoder
		PORT MAP (
			bin => hex_q(i)(3 DOWNTO 0),
			seg => hex_seg_w(i)
		);
	end generate;

	HEX0_o <= hex_seg_w(0);
	HEX1_o <= hex_seg_w(1);
	HEX2_o <= hex_seg_w(2);
	HEX3_o <= hex_seg_w(3);
	HEX4_o <= hex_seg_w(4);
	HEX5_o <= hex_seg_w(5);

	--=======================================
	-- Observation ports (§7)
	--=======================================
	DBGPORTS:
	if (GEN_DEBUG_PORTS) generate
		pc_o				<= pc_w;
		instruction_o		<= instruction_w;
		RegWrite_ctrl_o		<= RegWrite_ctrl_w;
		MemWrite_ctrl_o		<= MemWrite_ctrl_w;
		Branch_ctrl_o		<= Branch_ctrl_w;
		read_data1_o		<= read_data1_w;
		read_data2_o		<= read_data2_w;
		write_data_o		<= write_data_w;
		alu_res_o			<= alu_res_w;
		brTaken_o			<= brTaken_w;
		dtcm_addr_o			<= dtcm_addr_w;
		dtcm_data_wr_o		<= dtcm_data_wr_w;
		dtcm_data_rd_o		<= dtcm_data_rd_w;
		dtcm_cs_o			<= dtcm_cs_w;
		unmapped_o			<= unmapped_w;
		dtcm_wren_o			<= dtcm_wren_w;
		mclk_cnt_o			<= mclk_cnt_w;
	else generate
		pc_o				<= (others => '0');
		instruction_o		<= (others => '0');
		RegWrite_ctrl_o		<= '0';
		MemWrite_ctrl_o		<= '0';
		Branch_ctrl_o		<= '0';
		read_data1_o		<= (others => '0');
		read_data2_o		<= (others => '0');
		write_data_o		<= (others => '0');
		alu_res_o			<= (others => '0');
		brTaken_o			<= '0';
		dtcm_addr_o			<= (others => '0');
		dtcm_data_wr_o		<= (others => '0');
		dtcm_data_rd_o		<= (others => '0');
		dtcm_cs_o			<= '0';
		unmapped_o			<= '0';
		dtcm_wren_o			<= '0';
		mclk_cnt_o			<= (others => '0');
	end generate;

END structure;
