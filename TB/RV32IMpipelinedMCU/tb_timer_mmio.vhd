--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- G-408: the Basic Timer through the bus, PIPELINED MCU
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_timer_mmio.do -- it stages the SAME generated
--   images the single-cycle test uses (SIM/RV32IMscMCU/timer/): the program is
--   core-agnostic, so there is one copy of it and not two to drift apart.
--
-- WHY THIS EXISTS SEPARATELY FROM THE SINGLE-CYCLE ONE
--   BASIC_TIMER.vhd is byte-identical in both DUT trees
--   (tools/check_peripheral_copies.py asserts it), so the timer itself is
--   already proven here by tb_basic_timer and model_basic_timer. What is NOT
--   shared is the CPU driving it. This bench proves the same wiring claim
--   against the pipelined core: a program can configure the timer, read every
--   register back through the decoder and the shared bidirectional bus,
--   trigger and re-read a capture, and start PWM to a board pin.
--
--   The checks are IDENTICAL to TB/RV32IMscMCU/tb_timer_mmio.vhd. Only the
--   instantiation differs: store observation from MemWrite_ctrl_o / alu_res_o /
--   read_data2_o, and the sentinel watched in the MEM stage (MEMinstruction_o)
--   because branches resolve there -- a decode-stage watch would stop the run
--   on a speculative fetch of the final self-jump.
--
-- WHY THE TWO TIMING-DEPENDENT EXPECTATIONS SURVIVE UNCHANGED
--   Both looked like they might need re-deriving for a pipeline. Neither does,
--   and the reasons are different:
--
--   K, THE CAPTURED COUNT (S6/S7, range-checked 1..60, interpreter predicts
--   10). K is the number of cycles BTCNT ran between the run-write and the
--   hold-write. Everything the program executes between those two stores is
--   straight-line addi/slli/sw -- no branch, no load, no divide, so no flush,
--   no load-use interlock and no divider hold. A five-stage pipeline retires
--   straight-line code at one instruction per cycle, so the two stores reach
--   the timer the same number of cycles apart as on the single-cycle core and
--   K is essentially unchanged. The 1..60 window covers the rest.
--
--   THE PWM WIDTHS (high 10, low 31). Once the program has written BTCL0/BTCL1
--   and started the timer, PWM_o is produced by BASIC_TIMER off smclk with no
--   further CPU involvement, so the widths cannot depend on the core at all.
--   At MODELSIM = 1 with SMCLK_SHARES_MCLK, smclk IS the testbench clock
--   (CLOCK_TREE.vhd's CLK_SIM branch), so the counts are measured in the same
--   unit on both cores.
--
--   The program is addi/slli/sw/lw-at-offset-0 plus one beq.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_timer_mmio IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_timer_mmio;


ARCHITECTURE test OF tb_timer_mmio IS

	constant CLK_PERIOD	: time := 100 ns;		-- the MCU testbenches' convention
	-- The program needs ~120 cycles on the single-cycle core. This one adds a
	-- fill and a load-use stall per read-back pair (lw then sw of the loaded
	-- register), which is a small constant; 3000 was already 25x headroom.
	constant TIMEOUT	: natural := 3000;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL pwm_pin	: STD_LOGIC;
	SIGNAL instr	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- the scoreboard
	type score_t is array (0 TO 6) of STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL scored	: score_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nscored	: NATURAL := 0;

	constant SBASE	: unsigned(13 DOWNTO 0) := to_unsigned(16#0100#, 14);

BEGIN
	--=======================================================================
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,		-- the stimulus below is active-high
		MODELSIM		=> MODELSIM
	)
	PORT MAP (
		clk_i				=> clk,
		rst_i				=> rst,
		-- CAPIN1/CAPIN2 left at their '0' defaults: the program's capture uses
		-- the CAPISEL VCC/GND sources, exactly as test4 does.
		PWM_o				=> pwm_pin,
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
	-- Scoreboard: every store whose FULL BYTE ADDRESS (alu_res, not the DTCM
	-- word index -- the tb_gpio_directed lesson) lands in the scratch window.
	-- Sampled on the falling edge, mid-cycle, everything settled.
	--=======================================================================
	scoreboard : process(clk)
		variable idx : integer;
		variable n   : natural := 0;
	begin
		if falling_edge(clk) then
			if memw = '1' and rst = '0' then
				if unsigned(alu_res(13 DOWNTO 0)) >= SBASE and
				   unsigned(alu_res(13 DOWNTO 0)) <= SBASE + 24 then
					idx := to_integer(unsigned(alu_res(13 DOWNTO 0)) - SBASE) / 4;
					scored(idx) <= st_data;
					n := n + 1;
					nscored <= n;
				end if;
			end if;
		end if;
	end process scoreboard;

	--=======================================================================
	verdict : process
		variable p, f	: natural := 0;
		variable cyc	: natural := 0;
		variable k6, k7	: natural;
		variable hi, lo	: natural;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

	begin
		-- run to the sentinel, RETIRING in MEM
		while instr /= x"00000063" and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the program never reached its beq sentinel. " &
			"Check the staged images (SIM/RV32IMscMCU/timer/, NOT gpio/)");

		-- One settle cycle, then the seven stores. The sentinel retiring in MEM
		-- means every earlier instruction has already passed MEM, so all seven
		-- stores have committed by here -- the same guarantee the single-cycle
		-- bench gets from the sentinel simply executing.
		wait until falling_edge(clk);
		chk(nscored = 7, "scored " & integer'image(nscored) &
			" store(s) in the scratch window, expected exactly 7");
		chk(scored(0) = x"00000024", "S1 BTCTL1 read-back: got 0x" &
			to_hstring(scored(0)) & ", expected 0x00000024");
		chk(scored(1) = x"00000007", "S2 BTCTL2 (odd-address write): got 0x" &
			to_hstring(scored(1)) & ", expected 0x00000007");
		chk(scored(2) = x"00000028", "S3 BTCMPR0 word read-back: got 0x" &
			to_hstring(scored(2)) & ", expected 0x00000028 (40)");
		chk(scored(3) = x"0000000A", "S4 BTCMPR1 word read-back: got 0x" &
			to_hstring(scored(3)) & ", expected 0x0000000A (10)");
		chk(scored(4) = x"00000000", "S5 BTCAPR with source on GND: got 0x" &
			to_hstring(scored(4)) & ". A capture fired from test4's 0x07 " &
			"configuration, which must produce nothing");

		k6 := to_integer(unsigned(scored(5)));
		k7 := to_integer(unsigned(scored(6)));
		chk(k6 >= 1 and k6 <= 60, "S6 captured count K = " &
			integer'image(k6) & ", expected 1..60 (interpreter predicts 10; " &
			"the run-to-hold window is straight-line code, so a pipeline " &
			"retires it at 1 IPC and K should not move)");
		chk(k7 = k6, "S7 second BTCAPR read = " & integer'image(k7) &
			" differs from S6 = " & integer'image(k6) &
			". The register behind the bus is not stable");

		-- ---- PWM at the pin: two full periods, widths exact ----------------
		-- Produced by BASIC_TIMER off smclk with no CPU involvement, so these
		-- widths cannot depend on which core is driving. sync into a low
		-- stretch, then to the rising edge.
		cyc := 0;
		while pwm_pin /= '0' and cyc < 200 loop
			wait until falling_edge(clk); cyc := cyc + 1;
		end loop;
		while pwm_pin /= '1' and cyc < 200 loop
			wait until falling_edge(clk); cyc := cyc + 1;
		end loop;
		chk(cyc < 200, "PWM_o never pulsed after the sentinel");

		for rep in 1 to 2 loop
			hi := 0; lo := 0;
			while pwm_pin = '1' and hi < 100 loop
				wait until falling_edge(clk); hi := hi + 1;
			end loop;
			while pwm_pin = '0' and lo < 100 loop
				wait until falling_edge(clk); lo := lo + 1;
			end loop;
			chk(hi = 10, "PWM period " & integer'image(rep) & ": high " &
				integer'image(hi) & " cycles, expected 10 (= BTCL1)");
			chk(lo = 31, "PWM period " & integer'image(rep) & ": low " &
				integer'image(lo) & " cycles, expected 31 (= BTCL0+1-BTCL1)");
		end loop;

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "==== TIMER MMIO, PIPELINED (G-408) SUMMARY ====" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) & "  (captured K = " & integer'image(k6) & ")"
			severity note;
		if f = 0 then
			report "  VERDICT: PASS - a program on the PIPELINED core configured " &
				"the timer, read all five registers back through the bus, " &
				"captured and re-read a stable BTCAPR, and Lab 4's PWM arrived " &
				"at the pin with the exact 10/31 widths." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
			report "  Run the single-cycle bench first (do run_timer_mmio.do in " &
				"SIM\\RV32IMscMCU). BASIC_TIMER is byte-identical in both trees, " &
				"so if that one passes the fault is in the bus path or the core, " &
				"not in the timer." severity note;
		end if;
		report "===============================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
