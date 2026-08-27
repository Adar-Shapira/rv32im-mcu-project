--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- G-408: the interrupt path end to end, PIPELINED MCU
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_intr_mmio.do -- it stages the SAME generated
--   images the single-cycle test uses (SIM/RV32IMscMCU/intrmmio/): the program
--   is core-agnostic, so there is one copy of it and not two to drift apart.
--
-- WHY THIS EXISTS SEPARATELY FROM THE SINGLE-CYCLE ONE
--   INTERRUPT_CTRL.vhd, KEYCOND and BASIC_TIMER are byte-identical in both DUT
--   trees (tools/check_peripheral_copies.py asserts it), so the controller
--   itself is already proven here by run_intc.do. What is NOT shared is the
--   core, and this test is precisely about the two of them WIRED TOGETHER: the
--   TYPE push is a real driver of the one shared bidirectional bus, and it has
--   to arrive in the cycle the CORE captures it.
--
--   The full stack with no testbench emulation left anywhere: a real KEY1
--   press on the raw active-low pin -> KEYCOND -> the controller's
--   release-edge latch -> INTR -> the pipelined two-cycle entry at a MEM
--   retirement boundary -> the vector the program itself wrote -> the ISR
--   reading and W0C-clearing IFG through the bus at its ODD address -> reti.
--   Then the Basic Timer does the same with no pin at all: 201 pclk ticks,
--   EQU0, bt_ifg_set_w, and rule a's auto-clear observed from software.
--
--   The checks are IDENTICAL to TB/RV32IMscMCU/tb_intr_mmio.vhd, so a
--   difference in the result is a difference in the core. Only the
--   instantiation changes: store observation from MemWrite_ctrl_o / alu_res_o
--   / read_data2_o, and the sentinel watched in the MEM stage
--   (MEMinstruction_o) because branches resolve there -- a decode-stage watch
--   would stop the run on a speculative fetch of the final self-jump.
--
-- WHY ALL 14 EXPECTATIONS STAY EXACT ON A PIPELINE
--   Because neither interrupt moment is pinned by BENCH timing. This bench
--   does exactly one thing: when the program stores its ready marker, it
--   presses KEY1 for a few cycles and releases. The program is sitting in a
--   poll loop by then and stays there until the ISR clears it, so it does not
--   matter how many cycles behind the single-cycle core this one is. Round 2
--   is pinned by a timer count, which runs off smclk and does not involve the
--   CPU at all. Every value below is something the program POLLED for or read
--   back, never a cycle count -- so there is nothing here to re-derive.
--
--   Program uses addi/slli/sw/lw@0/beq/and/reti (AND register form, not ANDI).
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_intr_mmio IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_intr_mmio;


ARCHITECTURE test OF tb_intr_mmio IS

	constant CLK_PERIOD	: time := 100 ns;
	-- ~400 cycles expected on the single-cycle core. Round 2 waits on a timer
	-- count that is independent of the CPU, so the pipeline adds only the fill,
	-- the poll loops' stalls and three flush cycles per taken branch. 4000 was
	-- already 10x headroom and stays unchanged.
	constant TIMEOUT	: natural := 4000;

	-- from the generator's listing
	constant ISR_KEY1_A	: natural := 16#124#;
	constant ISR_BT_A	: natural := 16#160#;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL key_pins	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "111";	-- raw, active-low

	SIGNAL instr	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	type mem_t is array (0 TO 191) of STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL scored	: mem_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nscored	: NATURAL := 0;

BEGIN
	--=======================================================================
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,		-- the stimulus below is active-high
		MODELSIM		=> MODELSIM
		-- KEY_ACTIVE_LOW keeps its TRUE default: key_pins above are the raw
		-- board-polarity pins, idle '1', pressed '0' -- so KEYCOND and the
		-- release-edge convention are exercised exactly as on the DE2-115
	)
	PORT MAP (
		clk_i				=> clk,
		rst_i				=> rst,
		KEY_i				=> key_pins,
		MEMinstruction_o	=> instr,	-- the RETIRING instruction
		MemWrite_ctrl_o		=> memw,
		alu_res_o			=> alu_res,	-- the full byte address, zero-extended
		read_data2_o		=> st_data	-- the store data
	);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	rst <= '1', '0' after 80 ns;

	--=======================================================================
	-- Scoreboard: every store whose byte address lands in the scratch/flag
	-- window, sampled at the falling edge. MMIO stores (0x2xxx) fall outside
	-- and are the peripherals' business.
	--=======================================================================
	scoreboard : process(clk)
		variable a : natural;
		variable n : natural := 0;
	begin
		if falling_edge(clk) then
			if memw = '1' and rst = '0' then
				a := to_integer(unsigned(alu_res(13 DOWNTO 0)));
				if a < 16#300# then
					scored(a / 4) <= st_data;
					n := n + 1;
					nscored <= n;
				end if;
			end if;
		end if;
	end process scoreboard;

	--=======================================================================
	verdict : process
		variable p, f : natural := 0;
		variable cyc  : natural := 0;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		procedure chkv(constant a : IN natural; constant v : IN natural;
					   constant msg : IN string) is
		begin
			chk(to_integer(unsigned(scored(a / 4))) = v, "[" &
				to_hstring(to_unsigned(a, 16)) & "] = 0x" &
				to_hstring(scored(a / 4)) & ", expected 0x" &
				to_hstring(to_unsigned(v, 32)) & " : " & msg);
		end procedure chkv;

	begin
		wait until rst = '0';

		-- ---- wait for the program's ready marker, then press KEY1 -----------
		cyc := 0;
		while scored(16#208#/4) /= x"00000001" and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the ready marker [0x208] never appeared. Check " &
			"the staged images (SIM/RV32IMscMCU/intrmmio/, NOT another set)");

		for i in 1 to 2 loop wait until falling_edge(clk); end loop;
		key_pins(1) <= '0';						-- press (active-low pin)
		for i in 1 to 6 loop wait until falling_edge(clk); end loop;
		key_pins(1) <= '1';						-- RELEASE: the request event

		-- ---- run to the sentinel with all 14 stores --------------------------
		cyc := 0;
		while not (instr = x"00000063" and nscored = 14) and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the program never finished (sentinel + 14 stores)." &
			" If [0x200] stayed 0 the KEY1 release never became an interrupt;" &
			" if [0x204] stayed 0 the timer's EQU0 never became one");
		chk(nscored = 14, "scored " & integer'image(nscored) &
			" store(s), expected exactly 14");

		-- the vector table the program built
		chkv(16#010#, ISR_BT_A,   "vector word 4 (BT handler)");
		chkv(16#014#, ISR_KEY1_A, "vector word 5 (KEY1 handler)");

		-- round 1: the KEY1 release, through every layer
		chkv(16#180#, 16#14#, "TYPE read at 0x202E (lane 2) inside the ISR " &
			"while KEY1IFG pends");
		chkv(16#184#, 16#08#, "IFG read at the ODD address 0x202D: KEY1IFG " &
			"visible (rule d: no auto-clear for KEYs)");
		chkv(16#188#, 16#00#, "IFG after the benchmark and-mask store: W0C " &
			"through the real bus");
		chkv(16#200#, 1, "flag1: the KEY1 ISR ran and stored");

		-- round 2: the timer, all by itself
		chkv(16#18C#, 16#00#, "IFG inside the BT ISR: BTIFG must be ALREADY " &
			"clear (rule a auto-clear at service, observed from software)");
		chkv(16#204#, 1, "flag2: the BT ISR ran");

		-- wrap-up
		chkv(16#100#, 16#00#, "IFG idle at the end");
		chkv(16#104#, 16#0C#, "IE reads back KEY1IE|BTIE");
		chkv(16#108#, 16#00#, "TYPE idle at the end");
		chkv(16#10C#, 1, "gp after both retis: GIE restored in HW");
		chkv(16#110#, 16#5D#, "end marker: main resumed and finished");

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "==== INTR MMIO, PIPELINED (G-408) SUMMARY ====" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - on the PIPELINED core, a pin release and a " &
				"timer compare each travelled pin/timer -> controller -> INTR -> " &
				"the two-cycle entry at a MEM retirement boundary -> TYPE over " &
				"the shared bus -> vector -> ISR -> bus RMW -> reti, with every " &
				"read-back exact." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
			report "  Run the single-cycle bench first (do run_intr_mmio.do in " &
				"SIM\\RV32IMscMCU). INTERRUPT_CTRL and KEYCOND are byte-identical " &
				"in both trees, so if that one passes the fault is in the core " &
				"or in the bus path, not in the controller." severity note;
		end if;
		report "==============================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
