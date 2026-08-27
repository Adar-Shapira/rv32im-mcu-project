--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- G-408: the CPU-side interrupt protocol, PIPELINED core
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_intr_core.do -- it stages the SAME generated
--   images the single-cycle test uses (SIM/RV32IMscMCU/intr/): the program is
--   core-agnostic, so there is one copy of it and not two to drift apart.
--
-- WHY THIS EXISTS SEPARATELY FROM THE SINGLE-CYCLE ONE
--   This is the one testbench in the set whose subject IS the difference
--   between the two cores. The single-cycle entry is a three-state machine on
--   a core where every instruction retires in its own cycle. The pipelined
--   entry has to choose a RETIREMENT BOUNDARY (MEM), gate acceptance on
--   mem_active_w so a flush bubble is not mistaken for an instruction, kill
--   three younger stages, and recover a resume PC that may itself be a branch
--   redirect. The Phase 11 review pass checked all of that by READING
--   RV32IM_PIPE_CORE.vhd. Nothing executed it: before this file, the pipelined
--   entry protocol was exercised only indirectly, by Phase 12D's two USART
--   tests, and never cycle by cycle against REQ p15.
--
--   THIS BENCH PLAYS THE INTERRUPT CONTROLLER, exactly as the single-cycle one
--   does: it drives intr_i only while gie_o is high (the controller's own GIE
--   gate, p13), watches inta_o, and pushes TYPE onto dbus_rdata_i in the cycle
--   after the INTA pulse. That handshake needed NO adaptation, and that is
--   itself a finding worth stating: RV32IM_PIPE_CORE.vhd:274-303 drives
--   `inta_o <= NOT accept_w` and captures dbus_rdata_i(7 DOWNTO 0) in I_CYC1,
--   the same shape as DUT/RV32IMscMCU/RV32IM_CORE.vhd, which is what lets
--   INTERRUPT_CTRL be reused byte-identical between the trees.
--
-- WHAT CHANGES FROM TB/RV32IMscMCU/tb_intr_core.vhd
--   Every check, every expected value and every address is IDENTICAL, so a
--   difference in the result is a difference in the core. Three things change:
--
--   1. THE STORE OBSERVATION comes from the core's own bus-master ports,
--      dbus_MemWrite_o / dbus_addr_o / dbus_wdata_o, rather than the
--      single-cycle core's MemWrite_ctrl_o / alu_res_o / dtcm_data_wr_o. Same
--      three facts. dbus_MemWrite_o is `mem_MemWrite_w AND NOT annul_w`
--      (RV32IM_PIPE_CORE.vhd:555,760) -- the ANNUL-GATED strobe, which is what
--      makes the exact count of 16 meaningful: a store that leaked past the
--      annul would land twice.
--
--   2. THE SENTINEL is watched in MEM (MEMinstruction_o). Branches resolve
--      there, so a decode-stage watch would stop the run on a speculative
--      fetch of the final self-jump -- the trap batch_verify.do documents.
--
--   3. ROUND 3 RAISES THE REQUEST OFF EXinstruction_o, NOT MEMinstruction_o.
--      This is the one adaptation that is not cosmetic, and getting it wrong
--      would have made the F13 check VACUOUS rather than failing. Acceptance
--      is blocked by `ex_DivStart_w = '0' AND div_busy_w = '0'`
--      (RV32IM_PIPE_CORE.vhd:270-271) -- both EX-stage conditions. A divide
--      completes IN EX and only then advances, so by the time the div word
--      appears in MEM the divider is idle again and the request would be
--      accepted immediately: the bench would measure a deferral of ~0 and
--      report PASS having tested nothing. Watching EX raises the request while
--      the divide is actually in flight, which is the situation F13 is about.
--
-- THE DEFERRAL BOUND IS DERIVED, NOT COPIED
--   defer3 >= 12 is the single-cycle bench's number and it applies here for a
--   reason that does not depend on either core: DIV_ACCEL is N = 32 DIVCLK
--   iterations and DIV_UNIT/DIV_ACCEL are byte-identical in both DUT trees
--   (tools/check_peripheral_copies.py asserts it). This bench drives divclk
--   itself at DIV_PERIOD = 21 ns, so one divide is 32 * 21 = 672 ns and round
--   3 issues TWO of them back to back (div then rem) = 1344 ns. Against the
--   100 ns core clock that is 13.44 cycles, so at least 12 whole falling edges
--   must pass before INTA may fall. Anything less means entry did not wait for
--   the divider.
--
-- THE tp RANGES ARE UNCHANGED, AND THAT IS A CLAIM
--   tp1 must land in the poll loop [0x02C, 0x030] and tp3 in the post-div
--   block [0x064, 0x07C]. On this core the resume PC is the SUCCESSOR of the
--   completing MEM instruction -- pc+4, or the redirect target when that
--   instruction is itself a taken branch (RV32IM_PIPE_CORE.vhd:315). In the
--   poll loop MEM holds either the lw (resume = 0x030) or the taken beq
--   (resume = its target, 0x02C), so both endpoints of the single-cycle range
--   are reachable here for a DIFFERENT reason and the range still holds. The
--   load-bearing check is not the range: it is that main's copy of tp and the
--   ISR's copy are EQUAL, which is the protocol claim and is core-independent.
--
--   Program uses addi/sw/lw@0/beq/div/rem/reti.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;


ENTITY tb_intr_core IS
	generic(
		MODELSIM		: integer := G_MODELSIM;
		-- Passed through so the bench and the core cannot disagree about the
		-- width of the tie-off below. Value is the core's own default.
		BP_ADDR_WIDTH	: integer := 8
	);
END tb_intr_core;


ARCHITECTURE test OF tb_intr_core IS

	constant CLK_PERIOD	: time := 100 ns;
	constant DIV_PERIOD	: time := 21 ns;	-- coprime, as in tb_div_unit
	-- Three rounds need ~250 cycles on the single-cycle core. This core adds a
	-- fill, a stall per poll-loop iteration (lw then beq on the same register
	-- is a load-use hazard) and three flush cycles per taken branch, and the
	-- poll loops spin until an ISR clears them -- so the real figure is larger
	-- and not worth predicting. 4000 is the single-cycle bound unchanged and
	-- still leaves better than an order of magnitude.
	constant TIMEOUT	: natural := 4000;

	-- addresses from the generator's listing (BYTE addresses)
	constant POLL1_LO	: natural := 16#02C#;
	constant POLL1_HI	: natural := 16#030#;
	constant POSTDIV_LO	: natural := 16#064#;
	constant POSTDIV_HI	: natural := 16#07C#;	-- the sentinel itself
	constant ISR_KEY1_A	: natural := 16#080#;
	constant ISR_BT_A	: natural := 16#09C#;
	constant DIV_WORD	: STD_LOGIC_VECTOR(31 DOWNTO 0) := x"03184FB3";

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL divclk	: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL intr		: STD_LOGIC := '0';
	SIGNAL inta		: STD_LOGIC;
	SIGNAL gie		: STD_LOGIC;
	SIGNAL rdata	: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

	-- BPADDR_i is the only input on this core with no default, and SignalTap
	-- is not this bench's subject. A signal rather than an aggregate actual:
	-- an aggregate is legal for an `in` port but not every tool agrees, and a
	-- tie-off is not worth an elaboration argument.
	SIGNAL bpaddr	: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL mem_instr	: STD_LOGIC_VECTOR(31 DOWNTO 0);	-- the sentinel watch
	SIGNAL ex_instr		: STD_LOGIC_VECTOR(31 DOWNTO 0);	-- the div watch
	SIGNAL memw			: STD_LOGIC;
	SIGNAL baddr		: STD_LOGIC_VECTOR(DATA_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL st_data		: STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- the scoreboard: last value stored per scored address, plus the count
	type mem_t is array (0 TO 191) of STD_LOGIC_VECTOR(31 DOWNTO 0);	-- words 0..0x2FC
	SIGNAL scored	: mem_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nscored	: NATURAL := 0;

BEGIN
	--=======================================================================
	CORE : RV32IM_PIPE_CORE
	generic map(
		MODELSIM		=> MODELSIM,
		PC_WIDTH		=> G_PC_WIDTH,
		MA_WIDTH		=> G_MA_WIDTH,
		BP_ADDR_WIDTH	=> BP_ADDR_WIDTH
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		divclk_i		=> divclk,
		intr_i			=> intr,
		inta_o			=> inta,
		gie_o			=> gie,
		dbus_addr_o		=> baddr,		-- byte address of the store
		dbus_wdata_o	=> st_data,		-- the store data
		dbus_MemRead_o	=> open,
		dbus_MemWrite_o	=> memw,		-- ANNUL-GATED; see header note 1
		-- dtcm_cs_i left at its '1' default: everything is DTCM here
		dbus_rdata_i	=> rdata,		-- the TYPE push arrives on this
		dtcm_wren_o		=> open,
		BPADDR_i		=> bpaddr,		-- tied off; see the declaration
		CLKCNT_o		=> open,
		IFpc_o			=> open,
		IFinstruction_o	=> open,
		IDpc_o			=> open,
		IDinstruction_o	=> open,
		EXpc_o			=> open,
		EXinstruction_o	=> ex_instr,	-- round 3 raises the request off THIS
		MEMpc_o			=> open,
		MEMinstruction_o=> mem_instr,	-- the RETIRING instruction
		WBpc_o			=> open,
		WBinstruction_o	=> open,
		STRIGGER_o		=> open,
		FHCNT_o			=> open,
		STCNT_o			=> open
	);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	divclk_gen : process
	begin
		while running loop
			divclk <= '1'; wait for DIV_PERIOD/2;
			divclk <= '0'; wait for DIV_PERIOD/2;
		end loop;
		wait;
	end process divclk_gen;

	rst <= '1', '0' after 80 ns;

	--=======================================================================
	-- Scoreboard: every store, by full byte address (the tb_gpio lesson),
	-- sampled at the falling edge. dbus_MemWrite_o is the ANNUL-GATED strobe,
	-- so an annulled store that leaked past the annul would land here twice
	-- and break the exact count of 16.
	--
	-- The single-cycle bench slices alu_res to (9 DOWNTO 0), which folds any
	-- address above 0x3FF back into range. dbus_addr_o here is the bus's own
	-- 14-bit address, so the index is bounds-checked instead. Both are safe for
	-- THIS program (its highest store is 0x204); the difference is that an
	-- unexpected store would be silently mis-filed there and simply not filed
	-- here -- and either way the COUNT still moves, which is the check that
	-- would catch it.
	--=======================================================================
	scoreboard : process(clk)
		variable a : natural;
		variable n : natural := 0;
	begin
		if falling_edge(clk) then
			if memw = '1' and rst = '0' then
				a := to_integer(unsigned(baddr));
				if a / 4 <= 191 then
					scored(a / 4) <= st_data;
				end if;
				n := n + 1;
				nscored <= n;
			end if;
		end if;
	end process scoreboard;

	--=======================================================================
	verdict : process
		variable p, f		: natural := 0;
		variable cyc		: natural := 0;
		variable defer1		: natural;
		variable defer3		: natural;
		variable tp1, tp3	: natural;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		-- one full controller-side handshake: wait for the INTA pulse,
		-- verify its width, push TYPE in the following cycle (protocol
		-- Cycle 1), drop the request. Counts the falling edges between
		-- call and INTA fall into defer_o -- round 3's F13 measurement.
		--
		-- Byte-identical to the single-cycle bench's procedure. On this core
		-- acceptance additionally waits for a non-bubble instruction in MEM,
		-- so the count can be a few cycles larger in every round; only round
		-- 3's LOWER bound is asserted, and that bound comes from the divider.
		procedure handshake(constant typ     : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
							constant tag     : IN  STRING;
							variable defer_o : OUT natural) is
			variable n : natural := 0;
		begin
			loop
				wait until falling_edge(clk);
				exit when inta = '0';
				n := n + 1;
				if n >= 500 then
					chk(FALSE, tag & ": INTA never fell");
					defer_o := n;
					return;
				end if;
			end loop;
			defer_o := n;
			wait until falling_edge(clk);			-- mid protocol-Cycle 1
			chk(inta = '1', tag & ": INTA low for more than one cycle");
			rdata <= x"000000" & typ;				-- the TYPE push
			intr  <= '0';							-- request served
			wait until falling_edge(clk);			-- mid Cycle 2
			rdata <= (OTHERS => '0');
			chk(inta = '1', tag & ": INTA fell again inside the entry");
			-- GIE must have been cleared in HW by now (end of Cycle 1)
			chk(gie = '0', tag & ": GIE still high inside the entry (rule e)");
		end procedure handshake;

		procedure wait_gie(constant v : IN STD_LOGIC; constant tag : IN STRING) is
			variable n : natural := 0;
		begin
			while gie /= v loop
				wait until falling_edge(clk);
				n := n + 1;
				if n >= 500 then
					chk(FALSE, tag & ": GIE never reached the expected level");
					return;
				end if;
			end loop;
		end procedure wait_gie;

	begin
		wait until rst = '0';

		-- ---- round 1: KEY1 into the poll loop -------------------------------
		wait_gie('1', "R1 (the program's EINT)");	-- addi gp,zero,1 retired
		for i in 1 to 4 loop wait until falling_edge(clk); end loop;
		intr <= '1';
		handshake(x"14", "R1", defer1);
		wait_gie('1', "R1 reti (rule f)");			-- reti restored GIE in HW

		-- ---- round 2: BT, a different vector word ---------------------------
		for i in 1 to 10 loop wait until falling_edge(clk); end loop;
		intr <= '1';
		handshake(x"10", "R2", defer1);
		wait_gie('1', "R2 reti");

		-- ---- round 3: KEY1 raised while the div is IN EX -- F13's deferral --
		-- EX, not MEM. See header note 3: a divide finishes in EX before it
		-- advances, so a MEM watch would raise the request against an idle
		-- divider and measure nothing.
		cyc := 0;
		loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
			exit when ex_instr = DIV_WORD or cyc >= TIMEOUT;
		end loop;
		chk(cyc < TIMEOUT, "R3: the div never appeared on EXinstruction_o");
		intr <= '1';
		handshake(x"14", "R3", defer3);
		chk(defer3 >= 12, "R3 F13: INTA fell after only " &
			integer'image(defer3) & " cycles - entry did not wait for the " &
			"div, the rem and the busy tail (expected >= 12: two 32-iteration " &
			"divides at 21 ns is 1344 ns, or 13.44 core cycles)");
		wait_gie('1', "R3 reti");

		-- ---- run out: sentinel AND all 16 stores ----------------------------
		cyc := 0;
		while not (mem_instr = x"00000063" and nscored = 16) and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the program never finished (sentinel + 16 stores)." &
			" Check the staged images (SIM/RV32IMscMCU/intr/, NOT another set)");
		chk(nscored = 16, "scored " & integer'image(nscored) &
			" store(s), expected exactly 16 - an annulled store retired " &
			"twice, or one was lost");

		-- the vector table the program built
		chk(to_integer(unsigned(scored(16#10#/4))) = ISR_BT_A,
			"vector word 4 does not hold ISR_BT");
		chk(to_integer(unsigned(scored(16#14#/4))) = ISR_KEY1_A,
			"vector word 5 does not hold ISR_KEY1");

		-- round 1: rules e and f, tp coherence
		chk(scored(16#180#/4) = x"00000000", "[0x180] gp inside the ISR = 0x" &
			to_hstring(scored(16#180#/4)) & ", expected 0 (GIE cleared in HW)");
		chk(scored(16#100#/4) = x"00000001", "[0x100] gp after reti = 0x" &
			to_hstring(scored(16#100#/4)) & ", expected 1 (GIE set in HW)");
		tp1 := to_integer(unsigned(scored(16#184#/4)));
		chk(tp1 >= POLL1_LO and tp1 <= POLL1_HI, "tp1 = " & integer'image(tp1) &
			", expected inside the poll loop [44, 48]");
		chk(scored(16#104#/4) = scored(16#184#/4),
			"main's tp differs from the ISR's tp - tp did not survive");

		-- round 2: the other vector
		chk(scored(16#188#/4) = x"000000B7", "[0x188] = 0x" &
			to_hstring(scored(16#188#/4)) & ", expected 0xB7 - TYPE 10h did " &
			"not reach the BT handler");
		chk(scored(16#108#/4) = x"00000001", "[0x108] gp after round 2 != 1");

		-- round 3: the divides survived the pending interrupt
		chk(scored(16#10C#/4) = x"0000008E", "[0x10C] div 1000/7 = 0x" &
			to_hstring(scored(16#10C#/4)) & ", expected 0x8E (142)");
		chk(scored(16#110#/4) = x"00000006", "[0x110] rem 1000/7 = 0x" &
			to_hstring(scored(16#110#/4)) & ", expected 6");
		chk(scored(16#18C#/4) = x"00000000", "[0x18C] gp in ISR round 3 != 0");
		tp3 := to_integer(unsigned(scored(16#190#/4)));
		chk(tp3 >= POSTDIV_LO and tp3 <= POSTDIV_HI, "tp3 = " &
			integer'image(tp3) & ", expected in the post-div range [100, 124]");
		chk(scored(16#114#/4) = x"0000005D", "[0x114] end marker != 0x5D - " &
			"main did not resume and finish after round 3");

		-- the flags both ISRs raised
		chk(scored(16#200#/4) = x"00000001" and scored(16#204#/4) = x"00000001",
			"the ISR done-flags are not both 1");

		chk(gie = '1', "GIE not high at the end");

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "==== INTR CORE, PIPELINED (G-408) SUMMARY ====" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) & "  (tp1 = " & integer'image(tp1) &
			", tp3 = " & integer'image(tp3) & ", R3 deferral = " &
			integer'image(defer3) & " cycles)" severity note;
		if f = 0 then
			report "  VERDICT: PASS - the pipelined two-cycle entry is REQ p15: " &
				"GIE/tp/vector all correct at a MEM retirement boundary, three " &
				"rounds through two different vectors, reti restoring GIE in HW, " &
				"and F13's deferral measured across a div, a rem and the busy " &
				"tail with both results intact." severity note;
			report "  Compare tp1/tp3 and the deferral against the single-cycle " &
				"run: the VALUES should match, and they are reached by a " &
				"different mechanism (resume = the MEM instruction's successor, " &
				"or its redirect target)." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
			report "  Run the single-cycle bench first (do run_intr_core.do in " &
				"SIM\\RV32IMscMCU). If that passes and this does not, the fault " &
				"is in the PIPELINED entry, not in the program or the protocol." severity note;
		end if;
		report "==============================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
