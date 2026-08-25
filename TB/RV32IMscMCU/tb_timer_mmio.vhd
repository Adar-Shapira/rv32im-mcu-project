--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 8B: the Basic Timer through the MCU's own bus
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_timer_mmio.do  -- needs the GENERATED images staged
--   (SIM/RV32IMscMCU/timer/, committed), like the directed GPIO test.
--
-- WHAT THIS PROVES, AND WHAT IT DELIBERATELY DOES NOT
--   The timer CORE was proven cycle-exact by tb_basic_timer (with
--   model_basic_timer behind it, eight mutations caught). This testbench
--   proves the WIRING that Phase 8B added and nothing else: that a program
--   running on this CPU, through the decoder, the shared bidirectional bus
--   and the BidirPin readers, can configure the timer, read every register
--   back, trigger and read a capture, and drive PWM to a board pin.
--
--   The program (SIM/RV32IMscMCU/timer/listing.txt) makes 7 scored stores:
--     S1  [0x100] = 0x24  BTCTL1 read-back        (lane0 write)
--     S2  [0x104] = 0x07  BTCTL2 read-back        (write via ODD address
--                          0x201D -- F15's byte addressing at MCU level)
--     S3  [0x108] = 40    BTCMPR0 word read-back
--     S4  [0x10C] = 10    BTCMPR1 word read-back
--     S5  [0x110] = 0     BTCAPR with the capture source parked on GND --
--                          test4's actual 0x07 configuration, echoed: no
--                          edge, no capture, at MCU level
--     S6  [0x114] = K     BTCAPR after CAPISEL flips GND->VCC (the edge
--                          test4 MEANT); range-checked 1..60 -- see the
--                          generator's header for why not exact (the
--                          interpreter predicts K = 10)
--     S7  [0x118] = K     BTCAPR read AGAIN -- must EQUAL S6: a stable
--                          register behind the bus, not bus garbage
--   then starts PWM (mode0, BTCL0=40, BTCL1=10) and parks on the sentinel.
--   After the sentinel this bench measures PWM_o at the pin: two full
--   periods of high 10 / low 31 -- the Lab 4 pwm.vhd semantics arriving at
--   a board pin through every layer built since Phase 5A.
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
	constant TIMEOUT	: natural := 3000;		-- cycles; the program needs ~120

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
	MCU : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,		-- the stimulus below is active-high
		MODELSIM		=> MODELSIM
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		-- CAPIN1/CAPIN2 left at their '0' defaults: the program's capture uses
		-- the CAPISEL VCC/GND sources, exactly as test4 does.
		PWM_o			=> pwm_pin,
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
		dtcm_cs_o		=> open,
		unmapped_o		=> open,
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
		-- run to the sentinel
		while instr /= x"00000063" and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the program never reached its beq sentinel. " &
			"Check the staged images (SIM/RV32IMscMCU/timer/, NOT gpio/)");

		-- one settle cycle, then the seven stores
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
			integer'image(k6) & ", expected 1..60 (interpreter predicts 10)");
		chk(k7 = k6, "S7 second BTCAPR read = " & integer'image(k7) &
			" differs from S6 = " & integer'image(k6) &
			". The register behind the bus is not stable");

		-- ---- PWM at the pin: two full periods, widths exact ----------------
		-- sync into a low stretch, then to the rising edge
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
		report "========= TIMER MMIO (Phase 8B) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) & "  (captured K = " & integer'image(k6) & ")"
			severity note;
		if f = 0 then
			report "  VERDICT: PASS - the program configured the timer, read " &
				"all five registers back through the bus, captured and " &
				"re-read a stable BTCAPR, and Lab 4's PWM arrived at the pin " &
				"with the exact 10/31 widths." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "=================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
