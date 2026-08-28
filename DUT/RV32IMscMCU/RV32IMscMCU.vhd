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
--   Reference for the pattern: Auxiliary/Lab4/DUT/fpga_hw_interface.vhd, the
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
-- SCOPE, AS OF PHASE 6A
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
--   Auxiliary/Lab 5/Auxilary/Benchmarks/test*/RV32IM/man_compiled/
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
--   Phase 6A then attached the first peripherals: the seven general-purpose
--   OUTPUT ports of Figure 5 -- PORT_LEDR and PORT_HEX0..PORT_HEX5 -- onto four of
--   sfr_cs_w's twelve bits.
--
--   Phases 6B, 6C and 6D then added the SFR read path (with the read-back
--   Figure 5 draws on each output port), PORT_PB, and the directed GPIO test.
--
--   PHASE 4C completed the clocking. clk_i -- the 50 MHz board oscillator --
--   now enters CLOCK_TREE at this level and nowhere else, exactly as Figure 1
--   draws it; the core RECEIVES mclk instead of generating it from an internal
--   PLL, its transitional mclk_o port is gone, the peripherals are on smclk, and
--   reset is held until the PLLs report lock. accelclk is generated and waits
--   for Phase 7B.
--
--   Still to attach here: the Basic Timer, the interrupt controller, the
--   division accelerator (built as a leaf in 7A, wired in 7B) and the USART.
--
-- SIGNAL-TAP / PPA PORTS
--   §7: "Location pins used for the validation phase (Signal-Tap) need to be
--   removed in the final step using a suitable parameter in the generate VHDL
--   statement." VHDL cannot conditionally declare a port, so this entity still
--   has the observation ports (ModelSim and SignalTap hierarchy). Quartus does
--   not compile this entity as the chip top: RV32IMscMCU_FPGA below is the
--   board-only wrapper (clause 5/6 I/O only). That is what makes Flow Summary
--   "Total virtual pins" = 0 — VIRTUAL_PIN ON on leftover ports is what was
--   producing the 274 virtual-pin row, and deleting those assignments without
--   removing the ports would just dump them onto unused FPGA balls.
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
		-- Phase 4C. TRUE holds the core and the peripherals in reset until the
		-- clock tree's PLLs report lock. Before lock a PLL output is not a valid
		-- clock -- it can be stopped, at the wrong frequency, or glitching -- so
		-- releasing reset into it is how a design comes up differently on
		-- different power-ons. Lab 4's board top captures pll_locked and then
		-- leaves it unused (PROJECT_EXPLANATION.md §9.3 records this), so this is
		-- a deliberate improvement over the reference and the report should say so.
		--
		-- It is a generic because holding reset longer moves WHEN the program
		-- starts, and none of this has run on real tooling yet: if the four
		-- benchmark counts move, FALSE isolates whether this is the cause in one
		-- run rather than by bisecting the phase. They should NOT move -- see the
		-- reasoning at the RSTLOCK generate below.
		GEN_RESET_ON_LOCK	: boolean	:= TRUE;
		-- Phase 6B. TRUE gives the seven GPO ports the read-back that Figure 5
		-- draws (a MemRead-enabled tri-state on each output-port block), so a load
		-- from 0x2000 returns the byte last written there.
		--
		-- It is a generic and not simply built in because clause 5's table gives all
		-- seven a Direction of "GPO", which contradicts the figure unless "GPO"
		-- names the device rather than forbidding a readable register. That is
		-- assumption A15 in DOC/02_requirements_traceability.md, and it is the one
		-- open question this phase rests on. If the answer comes back "output
		-- ports must not respond to a read", this is one word to change and the
		-- seven tri-states disappear.
		GEN_GPO_READBACK	: boolean	:= TRUE;
		-- Phase 6B built a two-stage synchroniser on SW_i, reasoning from Hanan's
		-- own Figures 10a/10b material. HIS FORUM ANSWER SAYS IT IS NOT WANTED:
		-- asked whether the asynchronous button and switch signals need a two-DFF
		-- synchroniser before use in synchronous logic, the answer is
		--   "No, since their rate of change is many orders of magnitude slower
		--    than the system clock, so the signal is considered static."
		-- So the default is FALSE and the switches are read combinationally. The
		-- generic remains because the chain costs sixteen flip-flops and two cycles
		-- of latency on a hand-operated switch, i.e. nothing, and because a marginal
		-- board would be diagnosed by turning it on.
		GEN_INPUT_SYNC		: boolean	:= FALSE;
		-- Phase 6C. TRUE = KEY1..KEY3 arrive from the board's pushbuttons, which
		-- are active-low, so PORT_PB reads '1' for a PRESSED key.
		--
		-- Hanan's forum gave the bit ORDER (see PORT_PB below) but nothing states
		-- the POLARITY, and no supplied program reads PORT_PB at all -- it is
		-- defined in every io_map.s and accessed by none, because the interrupt
		-- tests reach the keys through interrupts rather than by polling. So this
		-- is an Assumption (A16), and it is a generic for the same reason
		-- RST_ACTIVE_LOW is one: the same board fact, the same one-word fix.
		--
		-- Grounds for "pressed reads 1": the course's own board interface,
		-- Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:37-38, does exactly this --
		-- "Invert KEYs because DE2-115 pushbuttons are normally HIGH, LOW when
		-- pressed / key_pressed <= NOT KEY" -- and this design already does it for
		-- KEY0 through RST_ACTIVE_LOW.
		KEY_ACTIVE_LOW		: boolean	:= TRUE;

		-- PHASE 14 — the switch that makes row 1 of §6's three PPA tables
		-- buildable. FALSE = "MCU with GPIO": the eight §5 peripherals and
		-- nothing else. TRUE = "MCU with GPIO and Interrupt Capability", which
		-- is the real design.
		--
		-- What FALSE removes is exactly §6's twelve addresses, no more and no
		-- less: the interrupt controller, the Basic Timer, the USART, and
		-- PORT_PB. PORT_PB is in that list — it looks like a GPIO input port but
		-- §6 is where the specification puts it, because the KEYs are an
		-- interrupt source. §7's own wording endorses doing this with a
		-- generate parameter: SignalTap pins "need to be removed in the final
		-- step using a suitable parameter in the generate VHDL statement".
		--
		-- WHAT IT DOES NOT REMOVE, stated so the row-1 number is honest: the
		-- CPU core is untouched. Its interrupt entry FSM is still in
		-- RV32IM_CORE.vhd with intr_i tied to '0' below, so constant
		-- propagation collapses istate_q, intr_q, type_q and every mux they
		-- drive — but `reti` stays decoded in CONTROL and its GIE side door in
		-- IDECODE survives, which is one AND gate and one register-bit write
		-- path. Deliberate: adding a second generic inside the core would mean
		-- editing verified expressions in a passing design for the sake of a
		-- measurement. The divider accelerator also stays, in both rows — §6.iii
		-- makes it part of the CPU, and it has no MMIO address.
		GEN_INTERRUPT		: boolean	:= G_GEN_INTERRUPT;

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

		--=== GPIO board input — Phase 6B, Figure 5 (clause 5) ===
		-- Clause 4 lists SW9-SW0. PORT_SW at 0x2010 reads SW7..SW0 only
		-- (clause 5). SW9/SW8 are board pins, not MMIO bits.
		SW_i				:IN		STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');

		-- KEY3..KEY1 -- Phase 6C. Indexed 3 DOWNTO 1 so that KEY_i(n) is KEYn on
		-- the board and no off-by-one is possible at the pin assignment. KEY0 is
		-- absent because clause 3 makes it the system RESET, and it arrives on
		-- rst_i above.
		--
		-- Defaulted to all '1' -- with KEY_ACTIVE_LOW that is "no key pressed" --
		-- so the five testbenches written before this phase still elaborate and
		-- see released keys.
		KEY_i				:IN		STD_LOGIC_VECTOR(3 DOWNTO 1) := (OTHERS => '1');

		-- Phase 8B (F18: three pins on the expansion header). PWM is GPIO[9]
		-- as in Lab 4 / Figure 4b. CAPIN on GPIO[8] and GPIO[10]. The rest of
		-- J15 (GPIO[35:0], Terasic CSV) is brought out so clause 4's 2x20
		-- header is fully assigned; unused bits are high-Z.
		-- PWM_o / CAPIN1_i / CAPIN2_i stay for ModelSim; Quartus marks them
		-- VIRTUAL_PIN so they do not take a second ball.
		GPIO				:INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0) := (OTHERS => 'Z');
		CAPIN1_i			:IN		STD_LOGIC := '0';
		CAPIN2_i			:IN		STD_LOGIC := '0';
		PWM_o				:OUT	STD_LOGIC;

		--=== GPIO board outputs — Phase 6A, Figure 5 (clause 5) ===
		-- Widths from clause 5's table: PORT_LEDR drives LEDR7..LEDR0.
		-- Clause 4 lists LEDR9-LEDR0; LEDR9/LEDR8 are board pins held low
		-- (no register bits).
		LEDR_o				:OUT	STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);

		--=== USART — Phase 12B (bonus, clause 6.iv / clause 9) ===
		-- The two RS-232 pins of the DE2-115, named exactly as the course's own
		-- Terasic table names them so the pin assignment is checkable by eye:
		-- Auxiliary/Lab4/Auxiliary/DE2_115_pin_assignments.csv
		--     UART_RXD, Input,  PIN_G12, 3.3-V LVTTL
		--     UART_TXD, Output, PIN_G9,  3.3-V LVTTL
		-- (that file also lists UART_CTS/PIN_G14 and UART_RTS/PIN_J13 -- hardware
		-- flow control, which 8N1 without handshaking does not use, so they are
		-- left unassigned rather than tied to something invented.)
		--
		-- RXD is defaulted to '1' -- the idle line -- so that every testbench
		-- written before this phase still elaborates and sees a quiet receiver.
		UART_RXD_i			:IN		STD_LOGIC := '1';
		UART_TXD_o			:OUT	STD_LOGIC;

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
	-- rst_w conditioned by PLL lock -- Phase 4C. This is what the core and every
	-- peripheral actually use; rst_w alone still drives the clock tree's areset,
	-- because a PLL held in reset by its own lock signal would never lock.
	SIGNAL sys_rst_w			: STD_LOGIC;

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

	-- One bit per mapped SFR word, indexed by the CS_* constants in const_package.
	--
	-- UPDATED IN PHASE 6A. Bits CS_LEDR, CS_HEX01, CS_HEX23 and CS_HEX45 now have
	-- loads -- the seven GPO ports below. The other eight (CS_SW, CS_PB, CS_UART,
	-- CS_BTCTL, CS_BTCMPR0, CS_BTCMPR1, CS_BTCAPR, CS_INTC) are still driven and
	-- unread, so expect Quartus to report those EIGHT as unused, not the whole
	-- vector. That distinction matters: a report that the whole vector is unused
	-- would now mean the Phase 6A ports and their decode had been optimised away,
	-- which is a real failure and not the expected message it used to be.
	-- Phases 6B/6C, 8, 9 and 12 attach the rest.
	SIGNAL sfr_cs_w				: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);

	--=======================================================================
	-- GPIO — Phase 6A
	--=======================================================================
	-- PHASE 4C: THE THREE CLOCKS NOW COME FROM CLOCK_TREE AT THIS LEVEL, which is
	-- where Figure 1 draws them -- baseclk50MHz -> Clock Tree -> mclk, accelclk,
	-- smclk. Until 4C, mclk came out of the core's own internal PLL and was
	-- exported through a transitional mclk_o port; that port is gone and the core
	-- now RECEIVES mclk on its clk_i.
	SIGNAL mclk_w				: STD_LOGIC;	-- to the core
	SIGNAL smclk_w				: STD_LOGIC;	-- to the peripherals
	SIGNAL accelclk_w			: STD_LOGIC;	-- to the divider -- Phase 7B
	SIGNAL pll_locked_w			: STD_LOGIC;

	-- THE PERIPHERAL CLOCK. Hanan's forum: the other modules' registers "are DFF
	-- based on SMCLK, and that is preferable for the GPIO register too" -- so the
	-- peripherals belong on SMCLK, and as of 4C that is literally what they get.
	-- Every peripheral below is clocked from pclk_w, never mclk_w.
	--
	-- Note that with SMCLK_SHARES_MCLK => TRUE (the default, assumption A19) this
	-- is the SAME NET as mclk_w rather than a second 20 MHz clock. That is the
	-- point: the core drives a synchronous parallel bus into these registers, and
	-- two independent PLLs at one frequency would make that capture
	-- un-analysable. See CLOCK_TREE.vhd's header.
	SIGNAL pclk_w				: STD_LOGIC;

	-- Byte-lane qualification, the A0 term of Figure 5. lane0 selects the register
	-- at the word's base address, lane1 the one at base+1 -- which is how the
	-- figure separates PORT_HEX0 from PORT_HEX1 on a shared chip select.
	SIGNAL lane0_w				: STD_LOGIC;
	SIGNAL lane1_w				: STD_LOGIC;
	SIGNAL lane2_w				: STD_LOGIC;	-- Phase 9C: TYPE sits at word base + 2 (0x202E)

	-- '1' when the addressed SFR word has a peripheral behind it. Used only by the
	-- simulation-only stub notice below, which has to know which writes really are
	-- discarded now that four of the twelve words are implemented.
	SIGNAL gpo_cs_w				: STD_LOGIC;
	SIGNAL timer_cs_w			: STD_LOGIC;	-- Phase 8B: any of the timer's four words
	SIGNAL sfr_rd_impl_w		: STD_LOGIC;	-- this SFR word answers a read

	-- Phase 8B -- the Basic Timer's read-backs, and its event pulse.
	-- bt_ifg_set_w: CONSUMED SINCE PHASE 9C -- it is the INTC's bt_ifg_set_i,
	-- latched into IFG under the falsified-A6 rule, exactly what Phase 8B
	-- declared it was waiting for.
	SIGNAL btctl1_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL btctl2_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL btcmpr0_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL btcmpr1_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL btcapr_rd_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL bt_ifg_set_w			: STD_LOGIC;

	-- Phase 9C -- the Interrupt Controller's read-backs and the CPU handshake.
	-- intr_w arrives at the core ALREADY gated by GIE (the p13 AND lives in the
	-- controller); gie_w is the core's gp[0] tap closing that loop; inta_w is
	-- the core's one-cycle acknowledge; type_push_w/type_capt_w are REQ p15's
	-- TYPE-over-the-data-bus transfer, driven below as one more bus driver.
	SIGNAL intc_ie_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intc_ifg_rd_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intc_type_rd_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL type_push_w			: STD_LOGIC;
	SIGNAL type_capt_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL intr_w				: STD_LOGIC;
	SIGNAL inta_w				: STD_LOGIC;
	SIGNAL gie_w				: STD_LOGIC;
	SIGNAL intc_cs_w			: STD_LOGIC;	-- for the stub notices below

	-- Phase 12B -- the USART's read-backs, its three interrupt sources and the
	-- two software-side clears of rules b/c. rx_ev/tx_ev/rxerr_ev go to the
	-- interrupt controller's inputs, which have existed since 9A and were
	-- defaulted to '0' waiting for exactly this.
	SIGNAL uctl_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL rxbuf_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL txbuf_rd_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL uart_rx_ev_w			: STD_LOGIC;
	SIGNAL uart_rxerr_ev_w		: STD_LOGIC;
	SIGNAL uart_tx_ev_w			: STD_LOGIC;
	SIGNAL uart_rx_clr_w		: STD_LOGIC;
	SIGNAL uart_tx_clr_w		: STD_LOGIC;
	SIGNAL uart_txd_w			: STD_LOGIC := '1';	-- idle high
	SIGNAL uart_rxd_w			: STD_LOGIC;
	SIGNAL uart_cs_w			: STD_LOGIC;	-- for the stub notices below

	-- Phase 14: GEN_INTERRUPT as a signal, so the reader enables can be ANDed
	-- with it in one place each. Constant by construction, so with
	-- GEN_INTERRUPT => FALSE every path behind it propagates away.
	SIGNAL icap_w				: STD_LOGIC;

	-- Each port's stored byte, and each display's seven segments. Local array
	-- types rather than one flat vector, so an index is a display number and not
	-- an arithmetic slice. A TYPE declaration needs no package body.
	type hex_byte_array_t is array (0 TO 5) of STD_LOGIC_VECTOR(7 DOWNTO 0);
	type hex_seg_array_t  is array (0 TO 5) of STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL ledr_q				: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex_q				: hex_byte_array_t;		-- what the CPU stored
	SIGNAL hex_seg_w			: hex_seg_array_t;		-- what the display shows
	SIGNAL pwm_w				: STD_LOGIC;
	SIGNAL capin1_w				: STD_LOGIC;
	SIGNAL capin2_w				: STD_LOGIC;

	--=======================================================================
	-- SFR read path -- Phase 6B (Figure 5, and Figure 1's bidirectional-bus link)
	--=======================================================================
	-- One entry per readable byte register. The index order is arbitrary but fixed,
	-- and it is what ties an enable to its data and to its tri-state instance.
	CONSTANT RD_SW		: integer := 0;		-- 0x2010  PORT_SW
	CONSTANT RD_LEDR	: integer := 1;		-- 0x2000  PORT_LEDR   read-back
	CONSTANT RD_HEX0	: integer := 2;		-- 0x2004  PORT_HEX0   read-back
	CONSTANT RD_HEX1	: integer := 3;		-- 0x2005  PORT_HEX1   read-back
	CONSTANT RD_HEX2	: integer := 4;		-- 0x2008  PORT_HEX2   read-back
	CONSTANT RD_HEX3	: integer := 5;		-- 0x2009  PORT_HEX3   read-back
	CONSTANT RD_HEX4	: integer := 6;		-- 0x200C  PORT_HEX4   read-back
	CONSTANT RD_HEX5	: integer := 7;		-- 0x200D  PORT_HEX5   read-back
	CONSTANT RD_PB		: integer := 8;		-- 0x2014  PORT_PB     (Phase 6C)
	-- Phase 8B: the Basic Timer's five readable registers. The first two are
	-- BYTE registers (indices below NRD_BYTE, zero-extended by WEXT like every
	-- other byte register -- assumption A11); the last three are the map's only
	-- WORD-resolution registers and drive all 32 bits directly.
	CONSTANT RD_BTCTL1	: integer := 9;		-- 0x201C  byte, lane0
	CONSTANT RD_BTCTL2	: integer := 10;	-- 0x201D  byte, lane1
	-- Phase 9C: the Interrupt Controller's three byte registers (word 11,
	-- lanes 0/1/2 -- the map's first lane-2 register), plus the TYPE PUSH:
	-- REQ p15's transfer of TYPE to the CPU over the DATA bus during entry
	-- Cycle 1. The push is one more driver of the one shared bus -- Hanan's
	-- "mandatory ... bi-directional bus" answer applies to it like to every
	-- reader -- except its enable is the controller's push strobe, not a
	-- CS.MemRead term (the CPU cannot issue a load for it: it is the only
	-- bus master, which is the reason p15 routes TYPE this way at all).
	CONSTANT RD_IE			: integer := 11;	-- 0x202C  byte, lane0
	CONSTANT RD_IFG			: integer := 12;	-- 0x202D  byte, lane1
	CONSTANT RD_TYPE		: integer := 13;	-- 0x202E  byte, lane2, read-only
	CONSTANT RD_TYPEPUSH	: integer := 14;	-- entry Cycle 1, enable = type_push_w
	-- Phase 12B: the USART's three byte registers -- word 6, lanes 0/1/2, the
	-- second and last lane-2 word in the map. All three are Byte resolution
	-- (REQ p6), so they belong below NRD_BYTE with the rest. RXBUF's reader is
	-- the one register in this design whose READ HAS A SIDE EFFECT (REQ p12:
	-- reading it clears the error bits and RXIFG), which is why uart_periph
	-- takes MemRead_i and derives the strobe itself instead of reusing the
	-- enable below -- the two must be the same event, and it is cleaner to have
	-- one owner of it than two expressions that have to stay equal.
	CONSTANT RD_UCTL	: integer := 15;	-- 0x2018  byte, lane0
	CONSTANT RD_RXBUF	: integer := 16;	-- 0x2019  byte, lane1
	CONSTANT RD_TXBUF	: integer := 17;	-- 0x201A  byte, lane2
	CONSTANT NRD_BYTE	: integer := 18;	-- indices 0..17 are byte-wide
	CONSTANT RD_BTCMPR0	: integer := 18;	-- 0x2020  word
	CONSTANT RD_BTCMPR1	: integer := 19;	-- 0x2024  word
	CONSTANT RD_BTCAPR	: integer := 20;	-- 0x2028  word
	CONSTANT NRD		: integer := 21;

	type rd_byte_array_t is array (0 TO NRD_BYTE-1) of STD_LOGIC_VECTOR(7 DOWNTO 0);

	CONSTANT RD_NONE	: STD_LOGIC_VECTOR(NRD-1 DOWNTO 0) := (OTHERS => '0');

	type rd_word_array_t is array (0 TO NRD-1) of STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL rd_en_w				: STD_LOGIC_VECTOR(NRD-1 DOWNTO 0);
	SIGNAL rd_byte_w			: rd_byte_array_t;
	SIGNAL rd_word_w			: rd_word_array_t;	-- the byte, zero-extended to the bus
	SIGNAL term_en_w			: STD_LOGIC;		-- drives zeros when nothing else drives
	SIGNAL rdbk_w				: STD_LOGIC;		-- GEN_GPO_READBACK as a signal

	-- THE DATA BUS. One shared, bidirectional, resolved signal -- not a read path
	-- and a separate write path. Hanan's forum, asked whether the data bus may be
	-- implemented as separate read and write paths or whether BidirPin is
	-- required: "It is mandatory to use a DATA BUS based on the bi-directional
	-- bus." Phase 6B had built only the read half as a real bus; this is the
	-- correction.
	--
	-- Exactly one driver is active at any time, by construction:
	--   the CPU              when MemWrite
	--   one readable register when its own CS . MemRead ( . A0 )
	--   the terminator        when neither
	-- MemRead and MemWrite are never both asserted -- they are the load and store
	-- outputs of CONTROL -- so the first two cannot collide.
	SIGNAL data_bus_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	CONSTANT ZEROS_BUS			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

	-- SW7..SW0 after synchronisation. A switch is a mechanical contact with no
	-- clock at all, so its value can change arbitrarily close to a clock edge --
	-- the textbook case for the settling chain of Figures 10a/10b, which page 10
	-- states as a rule: "It's fundamental to have a flip-flop to synchronize every
	-- signal that is driven by combinational logic in domain A before sending it to
	-- domain B." Figure 5 draws no synchroniser on PORT_SW, so this is an addition,
	-- not something the figure asks for -- but it costs two flip-flops and Lab 4's
	-- own board interface registers its SW inputs too
	-- (Auxiliary/Lab4/DUT/fpga_hw_interface.vhd). Two cycles of latency on reading a
	-- hand-operated switch is not observable.
	SIGNAL sw_sync_w			: STD_LOGIC_VECTOR(7 DOWNTO 0);

	-- KEY3..KEY1 conditioned to "pressed = '1'", and the byte PORT_PB presents.
	SIGNAL key_pressed_w		: STD_LOGIC_VECTOR(3 DOWNTO 1);
	SIGNAL portpb_w				: STD_LOGIC_VECTOR(7 DOWNTO 0);

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
	-- Clock tree — Figure 1, Phase 4B/4C
	--=======================================
	-- clk_i (the 50 MHz board oscillator) enters here and nowhere else. The core
	-- receives mclk; the peripherals receive smclk; and as of Phase 7B2 the core
	-- passes accelclk on to its division accelerator, so all three have loads.
	--
	-- As of Phase 7B2 accelclk_w HAS a load: it goes into the core, which passes
	-- it to div_unit. So all three PLLs survive synthesis and the resource report
	-- should show THREE. Two would mean the divider is being optimised away, and
	-- the SDC's ACCELCLK clock-group constraint would then be matching nothing.
	CLKTREE : clock_tree
	generic map(
		MODELSIM			=> MODELSIM
	)
	PORT MAP(
		clk_i		=> clk_i,
		rst_i		=> rst_w,
		mclk_o		=> mclk_w,
		smclk_o		=> smclk_w,
		accelclk_o	=> accelclk_w,
		locked_o	=> pll_locked_w
	);

	--=======================================
	-- Reset release on PLL lock — Phase 4C
	--=======================================
	-- Precedent and the reason this is an improvement rather than a flourish:
	-- Auxiliary/Lab4/DUT/fpga_hw_interface.vhd captures pll_locked but
	-- PROJECT_EXPLANATION.md §9.3 records that the reference leaves it UNUSED,
	-- and that a production design would hold reset until the PLL has locked.
	-- Before lock, a PLL output is not a valid clock: it can be stopped, running
	-- at the wrong frequency, or glitching, and every register clocked by it is
	-- in an undefined state. Releasing reset into that is how a design comes up
	-- differently on different power-ons.
	--
	-- WHY IT IS A GENERIC. Holding reset longer moves WHEN the program starts,
	-- and nothing in this tree has been verified on real tooling yet. If the four
	-- benchmark counts move after this phase, setting GEN_RESET_ON_LOCK => FALSE
	-- isolates whether this is the cause in one run instead of by bisecting the
	-- whole phase.
	--
	-- WHY THE COUNTS SHOULD NOT MOVE ANYWAY, so that a change is a real finding
	-- and not an expected side effect: mclk_cnt_q is held at zero by reset and
	-- starts counting when reset releases, and the program starts executing at
	-- that same moment. Holding reset for longer shifts both together, so the
	-- count when the benchmark reaches its self-jump is the same number. What
	-- changes is only the wall-clock time at which the simulation ends.
	RSTLOCK:
	if (GEN_RESET_ON_LOCK) generate
		sys_rst_w <= rst_w OR (NOT pll_locked_w);
	else generate
		sys_rst_w <= rst_w;
	end generate RSTLOCK;

	--=======================================
	-- RV32IM core
	--=======================================
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
		rst_i				=> sys_rst_w,
		clk_i				=> mclk_w,			-- Phase 4C: from CLKTREE, not the raw pin
		-- Phase 7B2. This is what finally gives accelclk a load: until now the
		-- third PLL had no consumer and Quartus pruned it. Expect THREE clocks in
		-- the Timing Analyzer from this phase on, not two.
		divclk_i			=> accelclk_w,

		-- Phase 9C: the interrupt handshake, closing the loop the two halves
		-- were each verified for separately (9A leaf, 9B core-level).
		intr_i				=> intr_w,
		inta_o				=> inta_w,
		gie_o				=> gie_w,

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
	-- THE DATA BUS (Figure 1, Figure 5) — Phase 6B, corrected 2026-08-24
	--=======================================
	-- CORRECTION. Phase 6B built the read half as a genuine tri-state bus but left
	-- the write data on its own separate path out of the core, which is two
	-- unidirectional buses rather than one bidirectional one. Hanan's forum,
	-- asked exactly that question -- may the DATA BUS be implemented as separate
	-- read and write paths, or must BidirPin be used -- answers: "It is mandatory
	-- to use a DATA BUS based on the bi-directional bus." So there is now ONE
	-- shared bus, and the CPU is one of its drivers.
	--
	-- WHO DRIVES IT, AND WHY EXACTLY ONE ALWAYS DOES
	--   the CPU               when MemWrite            (BP_CPU below)
	--   one readable register when CS . MemRead ( . A0 ) (the RDGEN loop)
	--   the terminator        when neither              (BP_TERM)
	-- MemRead and MemWrite are the load and store outputs of CONTROL and are never
	-- both asserted, so the first two cannot collide. The terminator's enable is
	-- derived from the SAME signals that gate the other two rather than
	-- re-deriving the condition, so it cannot drift out of step -- a hand-written
	-- complement that lost a term would give 'X' (two drivers) or 'Z' (none), and
	-- neither is simulatable on this machine.
	--
	-- EVERY DRIVER IS 32 BITS WIDE, including the byte registers, which drive
	-- their value zero-extended. That is what implements assumption A11 (an MMIO
	-- read returns zero in the upper 24 bits) and it is also what guarantees the
	-- whole bus has a driver whenever any of them is on. When Phase 8 adds
	-- BTCMPR0/BTCMPR1/BTCAPR -- Word resolution -- they simply drive all 32 bits
	-- with real data instead of a zero extension, and nothing here changes shape.
	--
	-- THE PERIPHERALS TAKE THEIR WRITE DATA FROM THE BUS, not from a private wire,
	-- which is what makes it a bus rather than decoration. During a read the bus
	-- carries the read value and the GPO ports see it, but their enable requires
	-- MemWrite, so they do not capture it.
	--
	-- A note on the first cycles: before MemRead/MemWrite have settled out of 'U',
	-- no enable is definitely '1' and the bus reads 'Z'. Harmless -- the core only
	-- selects it when dtcm_cs is '0', and the reset PC addresses word 0, where
	-- dtcm_cs is '1'.
	BP_CPU : BidirPin
	generic map( width => DATA_BUS_WIDTH )
	PORT MAP (
		Dout	=> dbus_wdata_w,
		en		=> dbus_MemWrite_w,
		Din		=> open,
		IOpin	=> data_bus_w
	);

	dbus_rdata_w <= data_bus_w;

	RDBK:
	if (GEN_GPO_READBACK) generate
		rdbk_w <= '1';
	else generate
		rdbk_w <= '0';
	end generate;

	-- SW7..SW0. See GEN_INPUT_SYNC in the entity: Hanan's forum says a switch
	-- needs no synchroniser because its rate of change is many orders of magnitude
	-- slower than the clock, so the default is the direct connection.
	SWSYNC:
	if (GEN_INPUT_SYNC) generate
		SW_SYNC : sync
		generic map(
			DATA_WIDTH	=> 8,
			STAGES		=> 2,
			GEN_SRC_REG	=> FALSE		-- a switch is driven by no logic, so there
		)								-- is nothing for Figure 10a's launch
		PORT MAP (						-- register to register
			src_clk_i	=> pclk_w,
			dst_clk_i	=> pclk_w,
			rst_i		=> sys_rst_w,
			d_i			=> SW_i(7 DOWNTO 0),
			q_o			=> sw_sync_w
		);
	else generate
		sw_sync_w <= SW_i(7 DOWNTO 0);
	end generate;

	--=======================================
	-- PORT_PB, 0x2014 (clause 6) — Phase 6C
	--=======================================
	-- Board-boundary conditioning, exactly as RSTCOND does it for KEY0 and as
	-- Auxiliary/Lab4/DUT/fpga_hw_interface.vhd:38 does it for all four keys.
	KEYCOND:
	if (KEY_ACTIVE_LOW) generate
		key_pressed_w <= NOT KEY_i;
	else generate
		key_pressed_w <= KEY_i;
	end generate;

	-- THE BIT ORDER IS HANAN'S, NOT AN ASSUMPTION. Asked whether PORT_PB should
	-- return three bits with bit 0 unused, or the buttons packed into bits 0-2,
	-- his forum answer is: "the mapping is in the order KEY1-KEY3 to bits 0-2
	-- respectively (KEY0 is not included, since it is the system RESET interface)".
	-- Nothing in any supplied file states this, and no supplied program reads
	-- PORT_PB, so without that answer it could only have been guessed.
	--
	-- Bits 7..3 have no source. They read zero rather than being left undriven,
	-- for the same reason the bus has a terminator: an undriven bit reads 'Z',
	-- which arrives as 'X' in the register file.
	portpb_w(0) <= key_pressed_w(1);		-- KEY1
	portpb_w(1) <= key_pressed_w(2);		-- KEY2
	portpb_w(2) <= key_pressed_w(3);		-- KEY3
	portpb_w(7 DOWNTO 3) <= (OTHERS => '0');

	-- key_pressed_w is also what Phase 9's interrupt edge latches will observe.
	-- No edge detector is built here: clause 6.i puts the KEY interrupt sources in
	-- the interrupt controller, and Hanan's forum confirms the board debounces in
	-- hardware (a 74HC245, Figure 6), so what Phase 9 needs is edge detection on a
	-- clean signal, not debounce.

	-- One enable per readable register. PORT_SW is unconditional; the seven
	-- read-back paths are gated by rdbk_w so GEN_GPO_READBACK => FALSE removes
	-- them entirely.
	rd_en_w(RD_SW)   <= sfr_cs_w(CS_SW)    AND dbus_MemRead_w AND lane0_w;
	rd_en_w(RD_LEDR) <= sfr_cs_w(CS_LEDR)  AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX0) <= sfr_cs_w(CS_HEX01) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX1) <= sfr_cs_w(CS_HEX01) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_HEX2) <= sfr_cs_w(CS_HEX23) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX3) <= sfr_cs_w(CS_HEX23) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_HEX4) <= sfr_cs_w(CS_HEX45) AND dbus_MemRead_w AND lane0_w AND rdbk_w;
	rd_en_w(RD_HEX5) <= sfr_cs_w(CS_HEX45) AND dbus_MemRead_w AND lane1_w AND rdbk_w;
	rd_en_w(RD_PB)   <= sfr_cs_w(CS_PB)    AND dbus_MemRead_w AND lane0_w AND icap_w;
	-- Phase 8B. BTCTL1/BTCTL2 share word 7 and are split by A0, exactly like a
	-- HEX pair. The three Word registers own their whole word (A12), so no lane
	-- term. All five are readable -- assumption A17 for BTCTL2 (one forum row
	-- read it as read-only; the applications write it, so readable is built and
	-- the question stands in DOC/05).
	rd_en_w(RD_BTCTL1)  <= sfr_cs_w(CS_BTCTL)   AND dbus_MemRead_w AND lane0_w AND icap_w;
	rd_en_w(RD_BTCTL2)  <= sfr_cs_w(CS_BTCTL)   AND dbus_MemRead_w AND lane1_w AND icap_w;
	rd_en_w(RD_BTCMPR0) <= sfr_cs_w(CS_BTCMPR0) AND dbus_MemRead_w AND icap_w;
	rd_en_w(RD_BTCMPR1) <= sfr_cs_w(CS_BTCMPR1) AND dbus_MemRead_w AND icap_w;
	rd_en_w(RD_BTCAPR)  <= sfr_cs_w(CS_BTCAPR)  AND dbus_MemRead_w AND icap_w;
	-- Phase 9C. IE/IFG/TYPE share word 11, split by A1..A0 -- the map's first
	-- three-register word (F15's byte addressing again). TYPE is read-only in
	-- hardware (REQ p14): it has a reader and NO write path anywhere.
	-- RD_TYPEPUSH is the odd one out by design: enabled by the controller's
	-- push strobe during entry Cycle 1, when the core's annul keeps MemRead
	-- and MemWrite both low -- so it can never collide with the CPU or with
	-- any reader, and the onehot check below now watches that claim.
	rd_en_w(RD_IE)       <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane0_w AND icap_w;
	rd_en_w(RD_IFG)      <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane1_w AND icap_w;
	rd_en_w(RD_TYPE)     <= sfr_cs_w(CS_INTC) AND dbus_MemRead_w AND lane2_w AND icap_w;
	rd_en_w(RD_TYPEPUSH) <= type_push_w;
	-- Phase 12B. UCTL/RXBUF/TXBUF share word 6, split by A1..A0 like IE/IFG/TYPE.
	-- TXBUF is readable as well as writable: REQ p12 calls it the buffer holding
	-- "data waiting to be moved into the transmit shift register", and nothing in
	-- the table marks it write-only, so it reads back like every other register
	-- here (assumption A28). RXBUF's enable is ALSO the read-side-effect event --
	-- see the constant's comment above.
	rd_en_w(RD_UCTL)  <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane0_w AND icap_w;
	rd_en_w(RD_RXBUF) <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane1_w AND icap_w;
	rd_en_w(RD_TXBUF) <= sfr_cs_w(CS_UART) AND dbus_MemRead_w AND lane2_w AND icap_w;

	rd_byte_w(RD_SW)   <= sw_sync_w;
	rd_byte_w(RD_LEDR) <= ledr_q;
	rd_byte_w(RD_HEX0) <= hex_q(0);
	rd_byte_w(RD_HEX1) <= hex_q(1);
	rd_byte_w(RD_HEX2) <= hex_q(2);
	rd_byte_w(RD_HEX3) <= hex_q(3);
	rd_byte_w(RD_HEX4) <= hex_q(4);
	rd_byte_w(RD_HEX5) <= hex_q(5);
	rd_byte_w(RD_PB)   <= portpb_w;
	rd_byte_w(RD_BTCTL1) <= btctl1_rd_w;
	rd_byte_w(RD_BTCTL2) <= btctl2_rd_w;
	rd_byte_w(RD_IE)       <= intc_ie_rd_w;
	rd_byte_w(RD_IFG)      <= intc_ifg_rd_w;	-- the MASKED view (falsified A6)
	rd_byte_w(RD_TYPE)     <= intc_type_rd_w;
	rd_byte_w(RD_TYPEPUSH) <= type_capt_w;		-- frozen at the accept edge (9A)
	rd_byte_w(RD_UCTL)  <= uctl_rd_w;			-- BUSY/OE/PE/FE live, four bits stored
	rd_byte_w(RD_RXBUF) <= rxbuf_rd_w;
	rd_byte_w(RD_TXBUF) <= txbuf_rd_w;

	-- Zero-extend each byte register to the full bus width. This IS assumption
	-- A11, expressed once, in the only place it belongs. Phase 8B: the range is
	-- NRD_BYTE, not NRD -- the three Word-resolution registers below drive all
	-- 32 bits themselves, which is what "Address Resolution: Word" means.
	WEXT:
	for i in 0 to NRD_BYTE-1 generate
		rd_word_w(i) <= ZEROS_BUS(DATA_BUS_WIDTH-1 DOWNTO 8) & rd_byte_w(i);
	end generate;

	rd_word_w(RD_BTCMPR0) <= btcmpr0_rd_w;
	rd_word_w(RD_BTCMPR1) <= btcmpr1_rd_w;
	rd_word_w(RD_BTCAPR)  <= btcapr_rd_w;

	-- The exact complement of the other drivers, by construction: nobody reading
	-- AND the CPU not writing.
	term_en_w <= '1' WHEN (rd_en_w = RD_NONE and dbus_MemWrite_w = '0') ELSE '0';

	RDGEN:
	for i in 0 to NRD-1 generate
		BP : BidirPin
		generic map( width => DATA_BUS_WIDTH )
		PORT MAP (
			Dout	=> rd_word_w(i),
			en		=> rd_en_w(i),
			Din		=> open,
			IOpin	=> data_bus_w
		);
	end generate;

	BP_TERM : BidirPin
	generic map( width => DATA_BUS_WIDTH )
	PORT MAP (
		Dout	=> ZEROS_BUS,
		en		=> term_en_w,
		Din		=> open,
		IOpin	=> data_bus_w
	);

	-- Simulation-only. Two drivers on the same bus give 'X', which would show up
	-- far from its cause, so the at-most-one property is asserted where it lives.
	-- Severity is warning, not failure, so a metavalue during the first cycles
	-- after reset does not abort a run.
	-- Counts EVERY driver of data_bus_w, not just the readers: the CPU's driver
	-- and the terminator are on the same bus and a collision with either resolves
	-- to 'X' just as readily. Extended when the bus became bidirectional.
	onehot_check : process(all)
		variable hot_v : integer;
	begin
		hot_v := 0;
		for i in rd_en_w'range loop
			if rd_en_w(i) = '1' then
				hot_v := hot_v + 1;
			end if;
		end loop;
		if dbus_MemWrite_w = '1' then			-- BP_CPU
			hot_v := hot_v + 1;
		end if;
		if term_en_w = '1' then					-- BP_TERM
			hot_v := hot_v + 1;
		end if;

		assert hot_v <= 1
			report "RV32IMscMCU: " & integer'image(hot_v) & " drivers of data_bus_w " &
				   "are active at once, so the bus resolves to 'X'. The families " &
				   "are: the CPU (MemWrite), the readable registers " &
				   "(CS . MemRead . lane), the TYPE push (entry Cycle 1, when the " &
				   "core's annul keeps MemRead AND MemWrite low), and the " &
				   "terminator (none of the above). A count above one means a " &
				   "chip-select/lane term in rd_en_w, the terminator's complement " &
				   "in term_en_w, or a core annul gate that stopped holding during " &
				   "the push."
			severity warning;

		-- The other failure mode, and the one that produces 'Z' rather than 'X'.
		assert hot_v >= 1 or is_x(dbus_MemWrite_w) or is_x(dbus_MemRead_w)
			report "RV32IMscMCU: NO driver of data_bus_w is active, so the bus is " &
				   "floating at 'Z'. The terminator's enable has a gap. (Before the " &
				   "control signals settle out of 'U' this is normal and is not " &
				   "reported.)"
			severity warning;
	end process onehot_check;

	--=======================================
	-- Basic Timer -- Phase 8B (Figure 7 onto Figure 5's bus)
	--=======================================
	-- Clocked from pclk_w like every peripheral (F11: DFFs on SMCLK), reset by
	-- the lock-gated sys_rst_w, write data taken FROM the shared bidirectional
	-- bus exactly as the GPO ports take theirs. btcnt_o is left open: BTCNT has
	-- no MMIO address anywhere in the map -- software cannot poll it, and the
	-- observation belongs to SignalTap, not to a port bristling out of the top.
	-- Phase 14: absent in PPA row 1. The tie-offs are explicit rather than
	-- left to defaults so that an undriven read-back can never reach the bus
	-- as 'Z' -- the same reason the bus has a terminator.
	GEN_TIMER:
	if (GEN_INTERRUPT) generate
		TIMER : basic_timer
		generic map( DATA_WIDTH => DATA_BUS_WIDTH )
		PORT MAP (
			clk_i		=> pclk_w,
			rst_i		=> sys_rst_w,
			ctl_cs_i	=> sfr_cs_w(CS_BTCTL),
			cmpr0_cs_i	=> sfr_cs_w(CS_BTCMPR0),
			cmpr1_cs_i	=> sfr_cs_w(CS_BTCMPR1),
			MemWrite_i	=> dbus_MemWrite_w,
			lane0_i		=> lane0_w,
			lane1_i		=> lane1_w,
			data_i		=> data_bus_w,
			capin1_i	=> capin1_w,
			capin2_i	=> capin2_w,
			pwm_o		=> pwm_w,
			btifg_set_o	=> bt_ifg_set_w,
			btctl1_o	=> btctl1_rd_w,
			btctl2_o	=> btctl2_rd_w,
			btcmpr0_o	=> btcmpr0_rd_w,
			btcmpr1_o	=> btcmpr1_rd_w,
			btcapr_o	=> btcapr_rd_w,
			btcnt_o		=> open
		);
	else generate
		pwm_w        <= '0';
		bt_ifg_set_w <= '0';
		btctl1_rd_w  <= (OTHERS => '0');
		btctl2_rd_w  <= (OTHERS => '0');
		btcmpr0_rd_w <= (OTHERS => '0');
		btcmpr1_rd_w <= (OTHERS => '0');
		btcapr_rd_w  <= (OTHERS => '0');
	end generate GEN_TIMER;

	-- J15 expansion header (clause 4). PWM on GPIO[9] (Lab 4 / Figure 4b);
	-- CAPIN1/2 on GPIO[8]/[10]. Remaining bits high-Z so they are inputs.
	-- ModelSim still uses CAPIN1_i / CAPIN2_i / PWM_o (TBs already drive those).
	--
	-- USB-TTL on JP5 (3.3 V), not the DE2-115 RS-232 DB9: a TTL adapter must
	-- not sit on MAX232 levels. Adapter TX -> FPGA RX = GPIO[1]; adapter RX <-
	-- FPGA TX = GPIO[3]. UART_TXD_o still copies TX onto PIN_G9; PIN_G12 is
	-- unused on the FPGA build because RX is taken from GPIO[1].
	GPIO <= (9 => pwm_w, 3 => uart_txd_w, OTHERS => 'Z');
	PWM_o <= pwm_w;
	UART_TXD_o <= uart_txd_w;
	FPGA_CAPIN:
	if (MODELSIM = 0) generate
		capin1_w <= GPIO(8);
		capin2_w <= GPIO(10);
		uart_rxd_w <= GPIO(1);
	end generate FPGA_CAPIN;
	SIM_CAPIN:
	if (MODELSIM /= 0) generate
		capin1_w <= CAPIN1_i;
		capin2_w <= CAPIN2_i;
		uart_rxd_w <= UART_RXD_i;
	end generate SIM_CAPIN;

	--=======================================
	-- Interrupt Controller -- Phase 9C (REQ p13/p14 onto Figure 5's bus)
	--=======================================
	-- Clocked from pclk_w like every peripheral -- F11's own words: "the other
	-- modules' registers are DFF based on SMCLK". The INTR/INTA/TYPE handshake
	-- with the core is sound because pclk_w IS mclk_w today (A19, one 20 MHz
	-- net); if B3 ever splits them, the handshake AND bt_ifg_set_i need CDC --
	-- recorded in DOC/02 section 4.3.
	--   The p13 diagram draws CS and INTA active-low; this design's decoder
	-- produces active-high chip selects everywhere, and the controller was
	-- built (9A) and verified to that convention. INTA is active-low as drawn.
	--   Sources: bt_ifg_set_w is Phase 8B's event pulse, consumed at last;
	-- key_pressed_w is Phase 6C's normalized pressed level -- the controller
	-- fires on its FALLING edge, the release (DOC/03 section C). As of Phase 12B
	-- the three UART sources and the two rule-b/c clears are driven too, so
	-- every input of this controller now has a real source: all seven vector
	-- table entries of REQ p14 can fire.
	GEN_INTC:
	if (GEN_INTERRUPT) generate
		INTC : interrupt_ctrl
		generic map( DATA_WIDTH => DATA_BUS_WIDTH )
		PORT MAP (
			clk_i			=> pclk_w,
			rst_i			=> sys_rst_w,
			cs_i			=> sfr_cs_w(CS_INTC),
			MemWrite_i		=> dbus_MemWrite_w,
			lane0_i			=> lane0_w,
			lane1_i			=> lane1_w,
			data_i			=> data_bus_w,
			bt_ifg_set_i	=> bt_ifg_set_w,
			key_pressed_i	=> key_pressed_w,
			rxerr_ev_i		=> uart_rxerr_ev_w,
			rx_ev_i			=> uart_rx_ev_w,
			tx_ev_i			=> uart_tx_ev_w,
			rx_clr_i		=> uart_rx_clr_w,
			tx_clr_i		=> uart_tx_clr_w,
			gie_i			=> gie_w,
			inta_i			=> inta_w,
			intr_o			=> intr_w,
			type_push_o		=> type_push_w,
			type_capt_o		=> type_capt_w,
			ie_o			=> intc_ie_rd_w,
			ifg_o			=> intc_ifg_rd_w,
			type_o			=> intc_type_rd_w
		);
	else generate
		-- Phase 14: absent in PPA row 1. intr_w '0' is what collapses the
		-- core's entry FSM by constant propagation; see GEN_INTERRUPT's own
		-- comment for the small residue that survives and why.
		intr_w          <= '0';
		type_push_w     <= '0';
		type_capt_w     <= (OTHERS => '0');
		intc_ie_rd_w    <= (OTHERS => '0');
		intc_ifg_rd_w   <= (OTHERS => '0');
		intc_type_rd_w  <= (OTHERS => '0');
	end generate GEN_INTC;

	--=======================================
	-- USART -- Phase 12B (REQ p6/p12 onto Figure 5's bus; bonus, clause 6.iv)
	--=======================================
	-- The last of the twelve SFR words to be attached. Same conventions as every
	-- peripheral since 6A: pclk_w (F11), sys_rst_w, and the write data taken FROM
	-- the shared bidirectional bus rather than from a private path.
	--
	-- CLK_HZ is passed explicitly rather than left at the component's default,
	-- because UART_CORE turns it into the baud divider AT ELABORATION and asserts
	-- the resulting error: with SMCLK = 20 MHz (F8/F11) the divisors are 130 and
	-- 11, and a wrong CLK_HZ here is a compile error rather than a dead serial
	-- link on the bench. It is written as a literal for the same reason
	-- CLOCK_TREE states its frequencies three times -- one number, three
	-- independent statements of it, so a change that misses one is caught.
	--
	-- MemRead_i is what makes RXBUF's read side effect (REQ p12) possible; no
	-- other peripheral here needs the read strobe.
	GEN_UART:
	if (GEN_INTERRUPT) generate
		UART : uart_periph
		generic map(
			DATA_WIDTH	=> DATA_BUS_WIDTH,
			CLK_HZ		=> 20000000				-- SMCLK, F8/F11 -- see CLOCK_TREE.vhd
		)
		PORT MAP (
			clk_i		=> pclk_w,
			rst_i		=> sys_rst_w,
			cs_i		=> sfr_cs_w(CS_UART),
			MemWrite_i	=> dbus_MemWrite_w,
			MemRead_i	=> dbus_MemRead_w,
			lane0_i		=> lane0_w,				-- 0x2018 UCTL
			lane1_i		=> lane1_w,				-- 0x2019 RXBUF
			lane2_i		=> lane2_w,				-- 0x201A TXBUF
			data_i		=> data_bus_w,
			rxd_i		=> uart_rxd_w,			-- FPGA: GPIO[1]; sim: UART_RXD_i
			txd_o		=> uart_txd_w,			-- FPGA: GPIO[3] (and PIN_G9 copy)
			rx_ev_o		=> uart_rx_ev_w,
			rxerr_ev_o	=> uart_rxerr_ev_w,
			tx_ev_o		=> uart_tx_ev_w,
			rx_clr_o	=> uart_rx_clr_w,
			tx_clr_o	=> uart_tx_clr_w,
			uctl_o		=> uctl_rd_w,
			rxbuf_o		=> rxbuf_rd_w,
			txbuf_o		=> txbuf_rd_w
		);
	else generate
		-- Phase 14: absent in PPA row 1. TXD idles HIGH, which is the line's
		-- resting level and not merely a convenient constant: a board built
		-- this way must not look to a connected terminal like a permanent
		-- start bit.
		uart_txd_w        <= '1';
		uart_rx_ev_w      <= '0';
		uart_rxerr_ev_w   <= '0';
		uart_tx_ev_w      <= '0';
		uart_rx_clr_w     <= '0';
		uart_tx_clr_w     <= '0';
		uctl_rd_w         <= (OTHERS => '0');
		rxbuf_rd_w        <= (OTHERS => '0');
		txbuf_rd_w        <= (OTHERS => '0');
	end generate GEN_UART;

	-- Which SFR words actually have a peripheral behind them today. Phase 6A
	-- attached the four GPO words; Phase 8B the timer's four (a write to BTCAPR
	-- reaches the timer and is IGNORED there by design -- capture hardware owns
	-- that register -- which is different from a write falling into a stub).
	-- Phase 9C attached the interrupt controller and Phase 12B the USART, which
	-- was the last one: every mapped SFR word now has hardware behind it.
	gpo_cs_w <=	sfr_cs_w(CS_LEDR)  OR sfr_cs_w(CS_HEX01) OR
				sfr_cs_w(CS_HEX23) OR sfr_cs_w(CS_HEX45);

	-- Phase 14: in PPA row 1 these three words have no peripheral at all, so
	-- the terms drop and the stub notice below tells the truth about them.
	timer_cs_w <= (sfr_cs_w(CS_BTCTL)   OR sfr_cs_w(CS_BTCMPR0) OR
				   sfr_cs_w(CS_BTCMPR1) OR sfr_cs_w(CS_BTCAPR)) AND icap_w;

	intc_cs_w <= sfr_cs_w(CS_INTC) AND icap_w;	-- Phase 9C: word 11 has a peripheral now
	uart_cs_w <= sfr_cs_w(CS_UART) AND icap_w;	-- Phase 12B: word 6, the last one

	-- Which SFR words answer a READ today: PORT_SW and PORT_PB always, the four
	-- GPO words when read-back is enabled, the timer's four words, the interrupt
	-- controller's word (Phase 9C) and the USART's (Phase 12B). With
	-- GEN_GPO_READBACK => TRUE that is now EVERY mapped word, so the read notice
	-- below can only fire with read-back compiled out.
	sfr_rd_impl_w <= sfr_cs_w(CS_SW) OR (sfr_cs_w(CS_PB) AND icap_w)
					 OR (gpo_cs_w AND rdbk_w)
					 OR timer_cs_w OR intc_cs_w OR uart_cs_w;

	SFRSTUB:
	if (MODELSIM = 1) generate
		-- CORRECTED IN PHASE 6A. This process previously reported that *any* SFR
		-- access was discarded because no peripheral existed. After Phase 6A that
		-- was false for exactly the accesses the GPIO test makes: it fired on
		-- test0's store to PORT_LEDR -- a store PORT_LEDR now latches -- and said
		-- the write had been discarded, immediately before tb_gpio printed
		-- "all seven GPO ports held exactly what the program stored". A diagnostic
		-- that contradicts the test it runs alongside is worse than no diagnostic,
		-- so the condition is now precise about which half is still a stub.
		sfr_stub_notice : process(clk_i)
			variable told_rd_v : boolean := FALSE;
			variable told_wr_v : boolean := FALSE;
		begin
			if rising_edge(clk_i) then
				-- READS: implemented for PORT_SW and, when GEN_GPO_READBACK is set,
				-- for the seven GPO ports. Any other SFR word still reads as zero.
				-- Updated in Phase 6B, which built the read path.
				if dbus_MemRead_w = '1' and dtcm_cs_w = '0' and sfr_rd_impl_w = '0'
				   and not told_rd_v then
					told_rd_v := TRUE;
					report "RV32IMscMCU: an SFR READ reached a word with no readable " &
						   "register behind it and returned zero. Since Phase 12B EVERY " &
						   "mapped SFR word answers a read, so the only way to get here " &
						   "is GEN_GPO_READBACK => FALSE and a read of PORT_LEDR or a " &
						   "PORT_HEX, or a read of an address the decoder does not map " &
						   "at all, which unmapped_o reports separately. Once per run."
						   severity note;
				end if;

				-- WRITES: as of Phase 12B every SFR word that has writable
				-- hardware takes its write. What is left is the read-only ports,
				-- so this notice changed meaning: it no longer says "not built
				-- yet", it says "you wrote to something that cannot be written".
				if dbus_MemWrite_w = '1' and dtcm_cs_w = '0' and gpo_cs_w = '0'
				   and timer_cs_w = '0' and intc_cs_w = '0' and uart_cs_w = '0'
				   and not told_wr_v then
					told_wr_v := TRUE;
					report "RV32IMscMCU: an SFR WRITE reached a word with no writable " &
						   "register behind it and was discarded. Since Phase 12B this " &
						   "is no longer a missing peripheral: the seven GPO ports, " &
						   "the Basic Timer, the interrupt controller (IE/IFG) and the " &
						   "USART (UCTL/TXBUF) all take their writes. It means the " &
						   "target is READ-ONLY BY DESIGN, and the only two such " &
						   "words left are PORT_SW (0x2010) and PORT_PB (0x2014). " &
						   "A write to a read-only LANE of a word that does have " &
						   "hardware (TYPE at 0x202E, RXBUF at 0x2019) does not " &
						   "reach here: that word's chip select is claimed, and the " &
						   "peripheral drops the write itself. Once per run."
						severity note;
				end if;
			end if;
		end process sfr_stub_notice;
	end generate;

	-- Phase 4B replaces this with the SMCLK PLL instance's output.
	pclk_w <= smclk_w;					-- Phase 4C: the peripherals are on SMCLK

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
	lane2_w <=      dbus_addr_w(1)  AND (NOT dbus_addr_w(0));	-- word base + 2 (Phase 9C: TYPE)

	-- Phase 14: '1' in the real design, '0' in PPA row 1. Every reader and
	-- chip-select term belonging to §6's twelve addresses is ANDed with it.
	icap_w <= '1' WHEN GEN_INTERRUPT ELSE '0';

	-- PORT_LEDR, 0x2000 -> LEDR7..LEDR0
	P_LEDR : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i		=> pclk_w,
		rst_i		=> sys_rst_w,
		cs_i		=> sfr_cs_w(CS_LEDR),
		MemWrite_i	=> dbus_MemWrite_w,
		lane_en_i	=> lane0_w,
		data_i		=> data_bus_w(7 DOWNTO 0),
		q_o			=> ledr_q
	);
	LEDR_o(7 DOWNTO 0) <= ledr_q;
	LEDR_o(9 DOWNTO 8) <= "00";

	-- The six 7-segment ports. PORT_HEX0/1 share CS_HEX01 and are separated by
	-- A0, and likewise for the other two pairs -- exactly Figure 5's pairing.
	P_HEX0 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(0)			-- 0x2004
	);
	P_HEX1 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX01), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(1)			-- 0x2005
	);
	P_HEX2 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(2)			-- 0x2008
	);
	P_HEX3 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX23), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(3)			-- 0x2009
	);
	P_HEX4 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane0_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(4)			-- 0x200C
	);
	P_HEX5 : gpo_port
	generic map( DATA_WIDTH => 8 )
	PORT MAP (
		clk_i => pclk_w, rst_i => sys_rst_w,
		cs_i => sfr_cs_w(CS_HEX45), MemWrite_i => dbus_MemWrite_w, lane_en_i => lane1_w,
		data_i => data_bus_w(7 DOWNTO 0), q_o => hex_q(5)			-- 0x200D
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

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;

--============================================================================
-- RV32IMscMCU_FPGA — Quartus chip top. Board pins only.
--
-- Why a second entity in this file (not a new DUT file): clause 7 and the
-- Area table's I/O column want the fitted top to be MCU I/O and nothing else.
-- This entity is that top. RV32IMscMCU above stays the ModelSim / SignalTap
-- entity (testbenches map pc_o, PWM_o, …). Quartus/RV32IMscMCU.qsf sets
-- TOP_LEVEL_ENTITY to this name.
--
-- Ports here are exactly the 105 assigned balls: clk, KEY0, SW9-0, KEY3-1,
-- LEDR9-0, HEX5-0, GPIO[35:0], UART_RXD, UART_TXD. PWM and capture live on
-- GPIO[9]/[8]/[10] (F18); the PWM_o / CAPIN*_i ports are ModelSim copies
-- and are left open. Observation ports are open with GEN_DEBUG_PORTS FALSE
-- so they prune.
--============================================================================
ENTITY RV32IMscMCU_FPGA IS
	PORT(
		clk_i				:IN		STD_LOGIC;
		rst_i				:IN		STD_LOGIC;
		SW_i				:IN		STD_LOGIC_VECTOR(9 DOWNTO 0);
		KEY_i				:IN		STD_LOGIC_VECTOR(3 DOWNTO 1);
		GPIO				:INOUT	STD_LOGIC_VECTOR(35 DOWNTO 0);
		LEDR_o				:OUT	STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX2_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX3_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX4_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX5_o				:OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		UART_RXD_i			:IN		STD_LOGIC;
		UART_TXD_o			:OUT	STD_LOGIC
	);
END RV32IMscMCU_FPGA;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE work.cond_compilation_package.all;

ARCHITECTURE structure OF RV32IMscMCU_FPGA IS
BEGIN
	MCU : ENTITY work.RV32IMscMCU
		GENERIC MAP (
			GEN_DEBUG_PORTS	=> FALSE,
			GEN_INTERRUPT	=> G_GEN_INTERRUPT,
			MODELSIM		=> G_MODELSIM
		)
		PORT MAP (
			clk_i			=> clk_i,
			rst_i			=> rst_i,
			SW_i			=> SW_i,
			KEY_i			=> KEY_i,
			GPIO			=> GPIO,
			CAPIN1_i		=> '0',
			CAPIN2_i		=> '0',
			PWM_o			=> OPEN,
			LEDR_o			=> LEDR_o,
			HEX0_o			=> HEX0_o,
			HEX1_o			=> HEX1_o,
			HEX2_o			=> HEX2_o,
			HEX3_o			=> HEX3_o,
			HEX4_o			=> HEX4_o,
			HEX5_o			=> HEX5_o,
			UART_RXD_i		=> UART_RXD_i,
			UART_TXD_o		=> UART_TXD_o,
			pc_o			=> OPEN,
			instruction_o	=> OPEN,
			RegWrite_ctrl_o	=> OPEN,
			MemWrite_ctrl_o	=> OPEN,
			Branch_ctrl_o	=> OPEN,
			read_data1_o	=> OPEN,
			read_data2_o	=> OPEN,
			write_data_o	=> OPEN,
			alu_res_o		=> OPEN,
			brTaken_o		=> OPEN,
			dtcm_addr_o		=> OPEN,
			dtcm_data_wr_o	=> OPEN,
			dtcm_data_rd_o	=> OPEN,
			dtcm_cs_o		=> OPEN,
			unmapped_o		=> OPEN,
			dtcm_wren_o		=> OPEN,
			mclk_cnt_o		=> OPEN
		);
END structure;
