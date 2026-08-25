--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 9B: the CPU side of the interrupt protocol
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_intr_core.do -- needs the GENERATED images staged
--   (SIM/RV32IMscMCU/intr/, committed), like the other staged tests.
--
-- WHAT THIS PROVES, AND WHAT IT DELIBERATELY DOES NOT
--   RV32IM_CORE alone. THIS TESTBENCH PLAYS THE INTERRUPT CONTROLLER: it
--   drives intr_i (only while gie_o is high -- the controller's own GIE
--   gate, p13), watches inta_o, and pushes TYPE onto dbus_rdata_i in the
--   cycle after the INTA pulse, exactly as INTERRUPT_CTRL.vhd does at the
--   MCU level. What is proven is REQ p15's protocol from the CPU's side:
--     - INTA: one-cycle active-low pulse, never asserted while GIE is low;
--     - entry: GIE (gp[0]) cleared IN HW; TYPE captured from the DATA bus;
--       the vector fetched from DTCM word TYPE/4 -- a table the program
--       itself wrote with two ordinary sw's; tp = the return address;
--     - return: reti (jalr zero,0(tp)) sets GIE back IN HW, and execution
--       really resumes where it left;
--     - F13: an interrupt raised the moment a div appears must WAIT --
--       through the div AND the adjacent rem AND the busy tail -- and
--       corrupt neither result (the deferral is measured in cycles);
--     - the annulled instruction at the return address retires exactly
--       once (every scored store lands once: the count is exact).
--   The wiring of INTERRUPT_CTRL onto the bus (CS_INTC, the TYPE-push
--   BidirPin, real sources) is Phase 9C and is not touched here.
--
--   The program (SIM/RV32IMscMCU/intr/listing.txt) runs three rounds:
--   KEY1 (TYPE 14h) into a poll loop, BT (TYPE 10h) to a different vector,
--   KEY1 again raised ON the div. 16 scored stores; the expected values
--   below are the generator's, cross-checked by its protocol-emulating
--   interpreter. tp values are RANGE-checked (where the interrupt lands
--   depends on this bench's timing) -- the ISR's copy and main's copy must
--   still be EQUAL, which is the protocol claim.
--
--   Runs at EITHER G_ISA_REPAIR setting: addi/sw/lw@0/beq/div/rem/reti
--   touch none of the seven defects.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_intr_core IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_intr_core;


ARCHITECTURE test OF tb_intr_core IS

	constant CLK_PERIOD	: time := 100 ns;
	constant DIV_PERIOD	: time := 21 ns;	-- coprime, as in tb_div_unit
	constant TIMEOUT	: natural := 4000;	-- cycles; three rounds need ~250

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

	SIGNAL instr	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- the scoreboard: last value stored per scored address, plus the count
	type mem_t is array (0 TO 191) of STD_LOGIC_VECTOR(31 DOWNTO 0);	-- words 0..0x2FC
	SIGNAL scored	: mem_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nscored	: NATURAL := 0;

BEGIN
	--=======================================================================
	CORE : RV32IM_CORE
	generic map(
		MODELSIM		=> MODELSIM,
		-- the component's PC/MA defaults are 10; the real configuration is
		-- G_PC_WIDTH/G_MA_WIDTH (13 for the 8 KiB TCMs) -- pass them the way
		-- RV32IMscMCU.vhd does
		PC_WIDTH		=> G_PC_WIDTH,
		MA_WIDTH		=> G_MA_WIDTH
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		divclk_i		=> divclk,
		intr_i			=> intr,
		inta_o			=> inta,
		gie_o			=> gie,
		dbus_addr_o		=> open,
		dbus_wdata_o	=> open,
		dbus_MemRead_o	=> open,
		dbus_MemWrite_o	=> open,
		-- dtcm_cs_i left at its '1' default: everything is DTCM here
		dbus_rdata_i	=> rdata,		-- the TYPE push arrives on this
		pc_o			=> open,
		instruction_o	=> instr,
		RegWrite_ctrl_o	=> open,
		MemWrite_ctrl_o	=> memw,
		Branch_ctrl_o	=> open,
		read_data1_o	=> open,
		read_data2_o	=> open,
		write_data_o	=> open,
		alu_res_o		=> alu_res,
		brTaken_o		=> open,
		dtcm_addr_o		=> open,
		dtcm_data_wr_o	=> st_data,
		dtcm_data_rd_o	=> open,
		dtcm_wren_o		=> open,
		mclk_cnt_o		=> open
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
	-- sampled at the falling edge. MemWrite_ctrl_o is the GATED strobe, so
	-- an annulled store that leaked past the annul would land here twice
	-- and break the exact count of 16.
	--=======================================================================
	scoreboard : process(clk)
		variable a : natural;
		variable n : natural := 0;
	begin
		if falling_edge(clk) then
			if memw = '1' and rst = '0' then
				a := to_integer(unsigned(alu_res(9 DOWNTO 0)));
				scored(a / 4) <= st_data;
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
		wait_gie('1', "R1 (the program's EINT)");	-- addi gp,zero,1 executed
		for i in 1 to 4 loop wait until falling_edge(clk); end loop;
		intr <= '1';
		handshake(x"14", "R1", defer1);
		wait_gie('1', "R1 reti (rule f)");			-- reti restored GIE in HW

		-- ---- round 2: BT, a different vector word ---------------------------
		for i in 1 to 10 loop wait until falling_edge(clk); end loop;
		intr <= '1';
		handshake(x"10", "R2", defer1);
		wait_gie('1', "R2 reti");

		-- ---- round 3: KEY1 raised ON the div -- F13's deferral --------------
		cyc := 0;
		loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
			exit when instr = DIV_WORD or cyc >= TIMEOUT;
		end loop;
		chk(cyc < TIMEOUT, "R3: the div never appeared on instruction_o");
		intr <= '1';
		handshake(x"14", "R3", defer3);
		chk(defer3 >= 12, "R3 F13: INTA fell after only " &
			integer'image(defer3) & " cycles - entry did not wait for the " &
			"div, the rem and the busy tail (expected >= 12)");
		wait_gie('1', "R3 reti");

		-- ---- run out: sentinel AND all 16 stores ----------------------------
		cyc := 0;
		while not (instr = x"00000063" and nscored = 16) and cyc < TIMEOUT loop
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
		report "========= INTR CORE (Phase 9B) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) & "  (tp1 = " & integer'image(tp1) &
			", tp3 = " & integer'image(tp3) & ", R3 deferral = " &
			integer'image(defer3) & " cycles)" severity note;
		if f = 0 then
			report "  VERDICT: PASS - two-cycle entry with GIE/tp/vector all " &
				"correct, three rounds through two different vectors, reti " &
				"restoring GIE in HW, and F13's deferral measured across a " &
				"div, a rem and the busy tail." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
