--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — RV32IM-based MCU, five-stage pipeline (bonus 10%)
--
-- RV32IMpipelinedMCU — board-facing structural top level.
--
-- Same rationale as RV32IMscMCU: Assignment definition §3 requires two
-- structural levels, board-level signal conditioning belongs at the boundary
-- and not inside the CPU, and §7 requires the Signal-Tap pins to be removable
-- through a generate parameter. See DUT/RV32IMscMCU/RV32IMscMCU.vhd for the
-- full reasoning; only the differences are noted here.
--
-- REWRITTEN 2026-08-23 FOR THE REVISED PIPELINE
--   The LAB5 pipeline was revised after this wrapper was first written, and the
--   core's interface changed with it. Reference:
--     Auxiliary/Lab 5 - as submitted/DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd
--     Auxiliary/Lab 5 - as submitted/DOC/HANDOVER_Report_lab5.md §4.3, §4.6
--   What changed, and why this file had to follow:
--     * BPTRIGGER_o          -> STRIGGER_o
--     * STCNT_o / FHCNT_o     8-bit -> 16-bit
--     * one pc_o/instruction_o pair -> five, one per stage (Figure 8):
--       IFpc_o/IFinstruction_o … WBpc_o/WBinstruction_o
--     * stall_o and flush_o are no longer top-level ports. They are internal
--       to the core (stall_w / flush_w) and must be observed through the wave
--       window or a Signal-Tap tap, not through a pin.
--     * the datapath observation ports the single-cycle core exposes
--       (RegWrite/MemWrite/Branch, read_data1/2, write_data, alu_res, brTaken,
--       dtcm_*) are NOT on the revised pipeline core at all. Figure 8 replaced
--       them with the five per-stage PC/instruction pairs, which is the more
--       useful view for a pipeline: those single signals each belonged to a
--       different stage and were easy to misread as one instruction.
--   Nothing here is invented. The port list below is exactly the core's, and
--   the wrapper adds only reset conditioning and the debug-port gate.
--
-- VALIDATION INSTRUMENTATION (LAB5 clause 6.iii)
--   BPADDR_i in, STRIGGER_o / CLKCNT_o / STCNT_o / FHCNT_o out. These feed the
--   Signal-Tap trigger and the IPC equation
--       IPC = (CLKCNT_o - (STCNT_o + 4 + depth*FHCNT_o)) / CLKCNT_o
--   with depth = 3, because branches and jumps resolve in stage 4 (MEM).
--
--   BPADDR_i is a board input (SW7-SW0) used only during validation, so
--   GEN_DEBUG_PORTS also gates it: tied to zero when the generic is FALSE,
--   driven from the port when it is TRUE.
--
--   ⚠ DO NOT SET GEN_DEBUG_PORTS => FALSE ON THIS WRAPPER. Corrected
--   2026-08-26; the sentence that used to stand here said to do exactly that in
--   a performance revision, and it would have produced a measurement of nothing.
--   Read the port list below: this entity has three inputs (clk_i, rst_i,
--   BPADDR_i) and FOURTEEN outputs, and every one of the fourteen is an
--   observation port. There is no GPIO, no LEDR, no HEX, no PWM here yet -- see
--   PHASE SCOPE. So the generate that ties the observation ports off at FALSE
--   leaves the five stages, both M9K TCMs and the PLL with no fan-out to any
--   pin, and synthesis deletes the whole design. The failure is silent and it
--   fails DOWNWARD: memory bits go to ~0, not to 483,328, and every acceptance
--   note in the runbook watches only for the high number. There would also be no
--   clock left for the Timing Analyzer to report an Fmax on.
--
--   What clause 7 actually requires is that the *location pins* used for
--   Signal-Tap be removed, and a performance revision does that by carrying no
--   set_location_assignment at all -- exactly as Auxiliary/Lab4/Quartus/
--   Lab4_Perf.qsf does. Keep the generic TRUE in both pipeline revisions. A
--   debug-free pipeline area figure only becomes meaningful once this wrapper
--   has real functional outputs, which is Phase 11's work, not a revision
--   setting. The single-cycle wrapper is a different case: it has 50+ real
--   board outputs, so FALSE there removes debug logic and leaves a design.
--
-- WHY RESET POLARITY LIVES HERE AND NOT IN THE CORE
--   The revised single-cycle core welds polarity to the simulation switch
--   (RV32IM_sc/RV32IM_CORE.vhd: rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i),
--   which makes "active-low reset" and "FPGA build" the same decision and blocks
--   an active-high board reset or an active-low simulation. Keeping the polarity
--   in the wrapper as its own generic separates the two, and matches what the
--   students' own Lab 4 already did (Auxilary/Lab4/DUT/fpga_hw_interface.vhd:38,
--   the RSTPOL generate). The pipeline core does not invert, so this wrapper is
--   the single owner of polarity — there is no double inversion.
--
--   That last sentence was FALSE until 2026-08-26 and the bug it hid was
--   FPGA-only. RV32IM_PIPE_CORE.vhd carried the same welded line as the
--   single-cycle reference, so at the committed defaults (RST_ACTIVE_LOW => TRUE,
--   G_MODELSIM := 0) the wrapper inverted and the core inverted again: the core's
--   internal reset was the raw KEY0 pin, which idles HIGH on the DE2-115, so the
--   board build would have held the design in reset unless KEY0 was pressed.
--   Simulation could not have shown it — tb_RV32IMpipelinedMCU passes
--   RST_ACTIVE_LOW => FALSE and every .do script passes -gMODELSIM=1, which
--   cancels both inversions. The core's line is now `rst_w <= rst_i`, matching
--   what the single-cycle core has always done, and the sentence above is true.
--
-- PHASE SCOPE
--   Thin, as on the single-cycle side. The core keeps its own PLL and DTCM; the
--   clock tree, bus interface and peripherals attach in later phases. The
--   wrapper must be behaviourally transparent so the pipeline baseline
--   reproduces through it unchanged.
--
--   The pipeline already includes the Lab 5 ISA repairs (it is the repair
--   reference the single-cycle side was transcribed from).
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY RV32IMpipelinedMCU IS
	generic(
		RST_ACTIVE_LOW		: boolean	:= TRUE;	-- TRUE = rst_i is KEY0 (active-low)
		GEN_DEBUG_PORTS		: boolean	:= TRUE;	-- FALSE ties off the Signal-Tap ports (§7)

		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		STCNT_WIDTH			: integer	:= 16;	-- 16 in the revised core, was 8
		FHCNT_WIDTH			: integer	:= 16;	-- 16 in the revised core, was 8
		BP_ADDR_WIDTH		: integer	:= 8
	);
	PORT(
		--=== Board pins ===
		clk_i				:IN		STD_LOGIC;		-- CLOCK_50, PIN_Y2
		rst_i				:IN		STD_LOGIC;		-- KEY0,     PIN_M23
		BPADDR_i			:IN		STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);	-- SW7-SW0, validation only

		--=== Figure 8 observation interface — gated by GEN_DEBUG_PORTS ===
		-- Five PC/instruction pairs, one per pipeline stage. They describe five
		-- DIFFERENT instructions in the same cycle; do not read them as one.
		IFpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IFinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		IDpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		IDinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		EXpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		EXinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		MEMpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		MEMinstruction_o	:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		WBpc_o				:OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		WBinstruction_o		:OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

		STRIGGER_o			:OUT	STD_LOGIC;	-- (IF PC word address = BPADDR_i)

		CLKCNT_o			:OUT	STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
		STCNT_o				:OUT	STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
		FHCNT_o				:OUT	STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0)
	);
END RV32IMpipelinedMCU;
--============================================================================
ARCHITECTURE structure OF RV32IMpipelinedMCU IS

	SIGNAL rst_w				: STD_LOGIC;	-- active-high internal reset
	SIGNAL bpaddr_w				: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);

	-- Core observation outputs, brought out here so the debug gate below can
	-- choose between driving the pins and tying them off.
	SIGNAL IFpc_w, IDpc_w, EXpc_w, MEMpc_w, WBpc_w
								: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL IFinst_w, IDinst_w, EXinst_w, MEMinst_w, WBinst_w
								: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL STRIGGER_w			: STD_LOGIC;
	SIGNAL CLKCNT_w				: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL STCNT_w				: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
	SIGNAL FHCNT_w				: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);

BEGIN
	--=======================================================================
	-- Reset conditioning. The only board-level signal shaping in this wrapper.
	--=======================================================================
	RSTCOND:
	if (RST_ACTIVE_LOW) generate
		rst_w <= not rst_i;
	else generate
		rst_w <= rst_i;
	end generate RSTCOND;

	--=======================================================================
	-- Breakpoint address. Real switches in a hardware revision; constant zero
	-- in a performance revision, so the fitter assigns no pins for it (§7).
	--=======================================================================
	BPIN:
	if (GEN_DEBUG_PORTS) generate
		bpaddr_w <= BPADDR_i;
	else generate
		bpaddr_w <= (others => '0');
	end generate BPIN;

	--=======================================================================
	-- The CPU core
	--=======================================================================
	CORE : RV32IM_PIPE_CORE
	generic map(
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH,
		STCNT_WIDTH			=> STCNT_WIDTH,
		FHCNT_WIDTH			=> FHCNT_WIDTH,
		BP_ADDR_WIDTH		=> BP_ADDR_WIDTH
	)
	PORT MAP(
		--Inputs
		rst_i				=> rst_w,
		clk_i				=> clk_i,
		BPADDR_i			=> bpaddr_w,

		--Outputs
		CLKCNT_o			=> CLKCNT_w,
		IFpc_o				=> IFpc_w,
		IFinstruction_o		=> IFinst_w,
		IDpc_o				=> IDpc_w,
		IDinstruction_o		=> IDinst_w,
		EXpc_o				=> EXpc_w,
		EXinstruction_o		=> EXinst_w,
		MEMpc_o				=> MEMpc_w,
		MEMinstruction_o	=> MEMinst_w,
		WBpc_o				=> WBpc_w,
		WBinstruction_o		=> WBinst_w,
		STRIGGER_o			=> STRIGGER_w,
		FHCNT_o				=> FHCNT_w,
		STCNT_o				=> STCNT_w
	);

	--=======================================================================
	-- Observation ports. Driven in a hardware revision; tied off in a
	-- performance revision so the fitter assigns no pins and the PPA area
	-- figure reflects the CPU rather than the debug harness. Assignment
	-- definition §7. Same pattern as the students' own Lab 4 two-revision
	-- split (Auxilary/Lab4/DUT/perf_wrapper.vhd).
	--=======================================================================
	DBGPORTS:
	if (GEN_DEBUG_PORTS) generate
		IFpc_o				<= IFpc_w;
		IFinstruction_o		<= IFinst_w;
		IDpc_o				<= IDpc_w;
		IDinstruction_o		<= IDinst_w;
		EXpc_o				<= EXpc_w;
		EXinstruction_o		<= EXinst_w;
		MEMpc_o				<= MEMpc_w;
		MEMinstruction_o	<= MEMinst_w;
		WBpc_o				<= WBpc_w;
		WBinstruction_o		<= WBinst_w;
		STRIGGER_o			<= STRIGGER_w;
		CLKCNT_o			<= CLKCNT_w;
		STCNT_o				<= STCNT_w;
		FHCNT_o				<= FHCNT_w;
	else generate
		IFpc_o				<= (others => '0');
		IFinstruction_o		<= (others => '0');
		IDpc_o				<= (others => '0');
		IDinstruction_o		<= (others => '0');
		EXpc_o				<= (others => '0');
		EXinstruction_o		<= (others => '0');
		MEMpc_o				<= (others => '0');
		MEMinstruction_o	<= (others => '0');
		WBpc_o				<= (others => '0');
		WBinstruction_o		<= (others => '0');
		STRIGGER_o			<= '0';
		CLKCNT_o			<= (others => '0');
		STCNT_o				<= (others => '0');
		FHCNT_o				<= (others => '0');
	end generate DBGPORTS;

END structure;
