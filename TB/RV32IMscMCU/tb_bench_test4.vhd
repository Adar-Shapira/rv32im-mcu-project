--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 10B: Interrupt benchmark test4, self-checking
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_bench_test4.do -- it stages the CORRECTED images
--   (SIM/RV32IMscMCU/bench_fixed/test4/) itself and passes MODELSIM=1;
--   do not run this at MODELSIM=0.
--
-- WHY THE CORRECTED IMAGE, AND WHAT WAS CORRECTED
--   Shipped test4 writes BTCTL2 = 0x07 both before AND after the measured
--   division loop (01_func.s:181-183 and :192-194) -- its own comments say
--   "set the input signal to GND" then "set the input signal to VCC", but the
--   identical value is stored twice, so no edge is ever produced (question
--   Q10 / gap G-327, and Hanan's prep-session walkthrough of the intended
--   GND->VCC event). The copy under bench_fixed/test4 changes exactly ONE
--   word (ITCM word 265, byte 0x424: the `capture` routine's 0x07 -> 0x06 =
--   CAPMD=01 rising + CAPISEL=10 VCC; audited in bench_fixed/PATCHES.md).
--
-- WHAT THE ONE-WORD FIX DOES **NOT** REPAIR -- two further shipped defects,
-- found while building this bench (recorded in the plan, Phase 10B):
--   1. `capture_init` (01_func.s:177-179) writes BTCTL1 = 0x24, which sets
--      BTINT back to "00" -- so when the (now real) capture event fires,
--      btifg_set_o is still routed from EQU0, and NO BT interrupt is raised.
--      BT_ISR's state-3 arm (00_main.s:187-192, MEM[a6] = BTCAPR) therefore
--      never executes, and runtime_div/runtime_rem (DTCM 0xC4/0xC8) keep
--      their .data zeros.
--   2. The same 0x24 (and the 0x26 before it) holds BTHOLD=1 AND BTCLR=1
--      through the whole measured window, so BTCNT is pinned at zero and the
--      captured value is 0 regardless.
--   This bench asserts exactly that behavior -- the only expectations the
--   sources support. The capture EDGE itself is observed by the run script
--   (a Tcl watch on /tb_bench_test4/MCU/TIMER/cap_ev_w -- same hierarchical-
--   reach precedent as mem_dump.do), expected once per KEY3 press.
--
-- WHAT THIS PROVES
--   The supplied benchmark application -- the course contract -- running on
--   the full MCU: three KEY ISRs through the real controller and entry, the
--   FSM kernel, twenty div/rem operations on the divider accelerator, the
--   Basic Timer programmed in all three of its modes by the program itself,
--   and the PWM pin carrying the programmed frequency and duty. Expected
--   values are derived from the SHIPPED sources, word by word (not from our
--   RTL): arr1 = {81..90} at DTCM 0x24, arr2 = {11..20} at 0x4C, so
--   divarr = {7,6,6,6,5,5,5,4,4,4} and remarr = {4,10,5,0,10,6,2,16,13,10};
--   FREQ_5K = 500 with BTSSEL=3 gives a (500+1)*8 = 4008-pclk PWM period
--   (the tb_basic_timer P8 finding), high = BTCMPR1 ticks (Mode0).
--
-- HOW IT OBSERVES
--   An EXACT, ORDERED store scoreboard on the debug taps (MemWrite_ctrl_o,
--   alu_res_o = full byte address -- the tb_gpio_directed lesson -- and
--   dtcm_data_wr_o), the tb_intr_mmio pattern hardened to a full sequence
--   match: all 83 stores the program makes, in order, with exact data. Plus
--   the PWM pin measured with tb_timer_mmio's own loop, and the HEX/LEDR
--   ports checked idle (BT_ISR never runs, so nothing may reach a display).
--
-- PRESS CHOREOGRAPHY -- deliberate, and load-bearing:
--   KEY3, KEY3, KEY1, KEY3, KEY2, KEY2.
--   * KEY2 (PWM) runs LAST and only ever starts from a parked-and-cleared
--     BTCNT (0x58 has BTCLR=0, and EQU0 is an equality compare -- starting
--     with BTCNT > BTCMPR0 would strand the PWM until 32-bit wraparound).
--     The preceding KEY3 pass parks AND clears BTCNT (BTCTL1=0x24).
--   * No mode ever leaves a latched raw BTIFG behind before a later IE write
--     re-enables BTIE (mode 1's EQU0 needs 20M pclk to fire; mode 3 keeps
--     count_en=0) -- so the masked-pending-latch reappearance (INTC A22)
--     and a nested BT entry inside a KEY ISR are structurally avoided.
--   * a7 is shared by all three ISRs and pre/post-increment timing differs
--     per mode (KEY2's config reads a7 BEFORE its ISR increments; STATE1 and
--     STATE3 read AFTER) -- the expected values below track it press by
--     press: parities 1,2,(3),4 give rem,div,(t4=3),div; KEY2 reads 4 then 5
--     giving BTCMPR1 = 250 then 125.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_bench_test4 IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_bench_test4;


ARCHITECTURE test OF tb_bench_test4 IS

	constant CLK_PERIOD	: time := 100 ns;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL key_pins	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "111";	-- raw, active-low
	SIGNAL ledr		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex0, hex1, hex2, hex3, hex4, hex5 : STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL pwm		: STD_LOGIC;

	-- debug taps for the scoreboard
	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	-- scoreboard state (each signal has exactly one driving process)
	SIGNAL nstores	: natural := 0;
	SIGNAL sb_fails	: natural := 0;
	SIGNAL pwm_seen	: BOOLEAN := FALSE;

	--=======================================================================
	-- The complete expected store trace: every sw test4 executes, in program
	-- order, with exact data. Derived instruction by instruction from
	-- 00_main.s / 01_func.s / io_map.s (asm-code of the shipped benchmark)
	-- for the press sequence KEY3,KEY3,KEY1,KEY3,KEY2,KEY2 -- the derivation
	-- is spelled out in the plan file, Phase 10B. Addresses are full byte
	-- addresses as alu_res_o carries them.
	--=======================================================================
	type exp_t is record
		addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
		data : STD_LOGIC_VECTOR(31 DOWNTO 0);
	end record;
	type exp_array_t is array (natural range <>) of exp_t;

	constant EXP : exp_array_t(0 to 82) := (
		-- ---- init: intr_config (01_func.s:72-88), state=0, HEX clear ------
		 0 => (x"201C", x"00000024"),	-- BTCTL1 = BTHOLD|BTCLR
		 1 => (x"202C", x"00000000"),	-- IE  = 0
		 2 => (x"202D", x"00000000"),	-- IFG = 0
		 3 => (x"202C", x"00000038"),	-- IE  = KEY3|KEY2|KEY1
		 4 => (x"0020", x"00000000"),	-- state = STATE0
		 5 => (x"2004", x"00000000"),	-- HEX0 = 0   (print2HEXsArr, a0=0)
		 6 => (x"2005", x"00000000"),	-- HEX1
		 7 => (x"2008", x"00000000"),	-- HEX2
		 8 => (x"2009", x"00000000"),	-- HEX3
		 9 => (x"200C", x"00000000"),	-- HEX4
		10 => (x"200D", x"00000000"),	-- HEX5
		-- ---- KEY3 #1: a7 0->1, parity 1 -> rem_arrays -> remarr ----------
		11 => (x"0020", x"00000003"),	-- state = 3
		12 => (x"201C", x"00000026"),	-- BTCTL1 = HOLD|CLR|BTINT2
		13 => (x"2020", x"FFFFFFFF"),	-- BTCMPR0 full scale
		14 => (x"202C", x"0000003C"),	-- IE += BTIE
		15 => (x"202D", x"00000000"),	-- IFG rmw: (masked 0x20) & 0xFFDF
		16 => (x"201C", x"00000024"),	-- capture_init: HOLD|CLR (BTINT lost)
		17 => (x"201D", x"00000007"),	-- BTCTL2: rising + GND
		18 => (x"009C", x"00000004"),	-- remarr[0] = 81 rem 11
		19 => (x"00A0", x"0000000A"),	-- remarr[1] = 82 rem 12
		20 => (x"00A4", x"00000005"),	-- remarr[2] = 83 rem 13
		21 => (x"00A8", x"00000000"),	-- remarr[3] = 84 rem 14
		22 => (x"00AC", x"0000000A"),	-- remarr[4] = 85 rem 15
		23 => (x"00B0", x"00000006"),	-- remarr[5] = 86 rem 16
		24 => (x"00B4", x"00000002"),	-- remarr[6] = 87 rem 17
		25 => (x"00B8", x"00000010"),	-- remarr[7] = 88 rem 18
		26 => (x"00BC", x"0000000D"),	-- remarr[8] = 89 rem 19
		27 => (x"00C0", x"0000000A"),	-- remarr[9] = 90 rem 20
		28 => (x"201D", x"00000006"),	-- capture: rising + VCC  ** THE FIX **
		-- ---- KEY3 #2: a7 1->2, parity 0 -> div_arrays -> divarr ----------
		29 => (x"0020", x"00000003"),
		30 => (x"201C", x"00000026"),
		31 => (x"2020", x"FFFFFFFF"),
		32 => (x"202C", x"0000003C"),
		33 => (x"202D", x"00000000"),
		34 => (x"201C", x"00000024"),
		35 => (x"201D", x"00000007"),	-- VCC->GND falls; CAPMD=01 ignores it
		36 => (x"0074", x"00000007"),	-- divarr[0] = 81/11
		37 => (x"0078", x"00000006"),	-- divarr[1] = 82/12
		38 => (x"007C", x"00000006"),	-- divarr[2] = 83/13
		39 => (x"0080", x"00000006"),	-- divarr[3] = 84/14
		40 => (x"0084", x"00000005"),	-- divarr[4] = 85/15
		41 => (x"0088", x"00000005"),	-- divarr[5] = 86/16
		42 => (x"008C", x"00000005"),	-- divarr[6] = 87/17
		43 => (x"0090", x"00000004"),	-- divarr[7] = 88/18
		44 => (x"0094", x"00000004"),	-- divarr[8] = 89/19
		45 => (x"0098", x"00000004"),	-- divarr[9] = 90/20
		46 => (x"201D", x"00000006"),	-- GND->VCC: capture event #2
		-- ---- KEY1: a7 2->3, STATE1 reads a7&3 = 3 -> the 0.125 s arm ------
		47 => (x"0020", x"00000001"),	-- state = 1
		48 => (x"2020", x"01312D00"),	-- BTCMPR0 = SEC_PERIOD (ISR default)
		49 => (x"201C", x"00000018"),	-- BTCTL1 = BTSSEL3: timer RUNS
		50 => (x"202C", x"0000003C"),	-- IE += BTIE (raw BTIFG is 0 here)
		51 => (x"202D", x"00000000"),	-- IFG rmw: (masked 0x08) & 0xFFF7
		52 => (x"2020", x"002625A0"),	-- STATE1: SEC_PERIOD>>3 ("0.125sec")
		-- ---- KEY3 #3: a7 3->4, parity 0 -> divarr again; parks BTCNT -----
		53 => (x"0020", x"00000003"),
		54 => (x"201C", x"00000026"),	-- also ends mode 1's free-running count
		55 => (x"2020", x"FFFFFFFF"),
		56 => (x"202C", x"0000003C"),
		57 => (x"202D", x"00000000"),
		58 => (x"201C", x"00000024"),
		59 => (x"201D", x"00000007"),
		60 => (x"0074", x"00000007"),
		61 => (x"0078", x"00000006"),
		62 => (x"007C", x"00000006"),
		63 => (x"0080", x"00000006"),
		64 => (x"0084", x"00000005"),
		65 => (x"0088", x"00000005"),
		66 => (x"008C", x"00000005"),
		67 => (x"0090", x"00000004"),
		68 => (x"0094", x"00000004"),
		69 => (x"0098", x"00000004"),
		70 => (x"201D", x"00000006"),	-- capture event #3
		-- ---- KEY2 #1: config reads a7=4 -> t4=0 -> BTCMPR1 = 500>>1 = 250 -
		71 => (x"0020", x"00000002"),	-- state = 2
		72 => (x"202C", x"00000038"),	-- IE: BTIE off ("doesn't need interrupt")
		73 => (x"2020", x"000001F4"),	-- BTCMPR0 = FREQ_5K = 500
		74 => (x"2024", x"000000FA"),	-- BTCMPR1 = 250 (duty 0.5)
		75 => (x"201C", x"00000058"),	-- BTOUTEN|BTSSEL3: PWM starts, BTCNT=0
		76 => (x"202D", x"00000000"),	-- IFG rmw: (masked 0x10) & 0xFFEF
		-- ---- KEY2 #2: config reads a7=5 -> t4=1 -> BTCMPR1 = 500>>2 = 125 -
		77 => (x"0020", x"00000002"),
		78 => (x"202C", x"00000038"),
		79 => (x"2020", x"000001F4"),
		80 => (x"2024", x"0000007D"),	-- BTCMPR1 = 125 (duty 0.25)
		81 => (x"201C", x"00000058"),
		82 => (x"202D", x"00000000")
	);

	-- the DE2-115 active-low digit table -- HEX_DECODER.vhd's own case, as a
	-- function, so an expected DIGIT can be named instead of a segment mask
	function seg7(constant d : natural) return STD_LOGIC_VECTOR is
	begin
		case d is
			when 0  => return "1000000";
			when 1  => return "1111001";
			when 2  => return "0100100";
			when 3  => return "0110000";
			when 4  => return "0011001";
			when 5  => return "0010010";
			when 6  => return "0000010";
			when 7  => return "1111000";
			when 8  => return "0000000";
			when 9  => return "0010000";
			when 10 => return "0001000";
			when 11 => return "0000011";
			when 12 => return "1000110";
			when 13 => return "0100001";
			when 14 => return "0000110";
			when others => return "0001110";	-- F
		end case;
	end function seg7;

BEGIN
	--=======================================================================
	MCU : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,
		MODELSIM		=> MODELSIM
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		KEY_i			=> key_pins,
		LEDR_o(7 DOWNTO 0)	=> ledr,
		HEX0_o			=> hex0,
		HEX1_o			=> hex1,
		HEX2_o			=> hex2,
		HEX3_o			=> hex3,
		HEX4_o			=> hex4,
		HEX5_o			=> hex5,
		PWM_o			=> pwm,
		pc_o			=> open,
		instruction_o	=> open,
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
	-- Scoreboard: EVERY store, matched in order against EXP. alu_res is the
	-- full byte address (an MMIO store and a DTCM store can share dtcm_addr_o
	-- -- the tb_gpio_directed lesson), st_data the stored word.
	--=======================================================================
	scoreboard : process(clk)
	begin
		if falling_edge(clk) and rst = '0' then
			if memw = '1' then
				if nstores <= EXP'high then
					if alu_res(31 DOWNTO 16) /= x"0000"
					   or alu_res(15 DOWNTO 0) /= EXP(nstores).addr
					   or st_data /= EXP(nstores).data then
						report "SCOREBOARD MISMATCH at store #" &
							integer'image(nstores) &
							": got [" & to_hstring(alu_res(15 DOWNTO 0)) &
							"] = "    & to_hstring(st_data) &
							", expected [" & to_hstring(EXP(nstores).addr) &
							"] = "    & to_hstring(EXP(nstores).data)
							severity error;
						sb_fails <= sb_fails + 1;
					end if;
				else
					report "UNEXPECTED EXTRA STORE #" & integer'image(nstores) &
						": [" & to_hstring(alu_res(15 DOWNTO 0)) & "] = " &
						to_hstring(st_data) severity error;
					sb_fails <= sb_fails + 1;
				end if;
				nstores <= nstores + 1;
			end if;
		end if;
	end process scoreboard;

	-- PWM must stay silent until the program itself enables BTOUTEN (KEY2)
	pwm_watch : process(clk)
	begin
		if falling_edge(clk) and rst = '0' then
			if pwm = '1' then
				pwm_seen <= TRUE;
			end if;
		end if;
	end process pwm_watch;

	--=======================================================================
	stim : process
		variable p, f : natural := 0;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		procedure settle(constant n : IN NATURAL) is
		begin
			for i in 1 to n loop wait until falling_edge(clk); end loop;
		end procedure settle;

		-- a full press-and-release; the ISR fires on the RELEASE
		procedure press(constant k : IN NATURAL) is
		begin
			wait until falling_edge(clk);
			key_pins(k) <= '0';
			settle(6);
			key_pins(k) <= '1';
		end procedure press;

		procedure chk_hex(signal   h : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
						  constant d : IN NATURAL; constant msg : IN string) is
		begin
			chk(h = seg7(d), msg & " (expected digit " & integer'image(d) & ")");
		end procedure chk_hex;

		-- event-driven wait: the store COUNT must reach the phase boundary
		procedure wait_stores(constant n   : IN NATURAL;
							  constant tmo : IN NATURAL;
							  constant msg : IN string) is
			variable c : natural := 0;
		begin
			while nstores < n and c < tmo loop
				wait until falling_edge(clk);
				c := c + 1;
			end loop;
			chk(nstores = n, msg & ": store count " & integer'image(nstores) &
				", expected " & integer'image(n));
		end procedure wait_stores;

		-- tb_timer_mmio's own PWM loop, at ticks*8 pclk (BTSSEL=3). Skips one
		-- full period first: the enable/duty-change period starts off-phase
		-- (BTCNT=0 stretch before the first prescaler tick).
		procedure measure_pwm(constant exp_hi : IN NATURAL;
							  constant exp_lo : IN NATURAL;
							  constant tag    : IN string) is
			variable c, hi, lo : natural;
		begin
			c := 0;
			while pwm /= '0' and c < 12000 loop
				wait until falling_edge(clk); c := c + 1;
			end loop;
			while pwm /= '1' and c < 12000 loop
				wait until falling_edge(clk); c := c + 1;
			end loop;
			chk(c < 12000, tag & ": PWM_o never reached a rising edge");
			-- skip one full period
			c := 0;
			while pwm = '1' and c < 12000 loop
				wait until falling_edge(clk); c := c + 1;
			end loop;
			while pwm = '0' and c < 12000 loop
				wait until falling_edge(clk); c := c + 1;
			end loop;
			chk(c < 12000, tag & ": PWM_o stuck during the skipped period");
			for rep in 1 to 2 loop
				hi := 0; lo := 0;
				while pwm = '1' and hi < 6000 loop
					wait until falling_edge(clk); hi := hi + 1;
				end loop;
				while pwm = '0' and lo < 6000 loop
					wait until falling_edge(clk); lo := lo + 1;
				end loop;
				chk(hi = exp_hi, tag & " period " & integer'image(rep) &
					": high " & integer'image(hi) & " pclk, expected " &
					integer'image(exp_hi) & " (= BTCMPR1 ticks x 8)");
				chk(lo = exp_lo, tag & " period " & integer'image(rep) &
					": low "  & integer'image(lo) & " pclk, expected " &
					integer'image(exp_lo) & " (= (501 - BTCMPR1) ticks x 8)");
			end loop;
		end procedure measure_pwm;

	begin
		wait until rst = '0';

		-- ---- init: 11 stores, displays cleared, PWM silent -------------------
		wait_stores(11, 3000, "init sequence");
		settle(50);
		chk_hex(hex5, 0, "init HEX5"); chk_hex(hex4, 0, "init HEX4");
		chk_hex(hex3, 0, "init HEX3"); chk_hex(hex2, 0, "init HEX2");
		chk_hex(hex1, 0, "init HEX1"); chk_hex(hex0, 0, "init HEX0");
		chk(ledr = x"00", "init LEDR not clear");

		-- ---- KEY3 #1: remarr through the divider accelerator -----------------
		press(3);
		wait_stores(29, 20000, "KEY3 #1 (rem pass)");
		settle(50);

		-- ---- KEY3 #2: divarr --------------------------------------------------
		press(3);
		wait_stores(47, 20000, "KEY3 #2 (div pass)");
		settle(50);

		-- ---- KEY1: compare-mode configuration (the 1-second cadence itself ----
		-- ---- is 20M pclk away -- FPGA material, like tests 2/3) ---------------
		press(1);
		wait_stores(53, 3000, "KEY1 (compare-mode config)");
		settle(50);
		chk(not pwm_seen, "PWM_o pulsed before any KEY2 press");

		-- ---- KEY3 #3: divarr again, and parks+clears BTCNT for the PWM --------
		press(3);
		wait_stores(71, 20000, "KEY3 #3 (div pass, parks BTCNT)");
		settle(50);

		-- ---- KEY2 #1: PWM, duty 0.5: high 250 ticks, low 251, period 4008 -----
		press(2);
		wait_stores(77, 3000, "KEY2 #1 (PWM duty 0.5)");
		measure_pwm(2000, 2008, "PWM duty 0.5");

		-- ---- KEY2 #2: duty 0.25: high 125 ticks = 1000 pclk --------------------
		press(2);
		wait_stores(83, 3000, "KEY2 #2 (PWM duty 0.25)");
		measure_pwm(1000, 3008, "PWM duty 0.25");

		-- ---- the N1 consequence: BT_ISR never ran, displays still dark --------
		settle(200);
		chk(nstores = 83, "final store count is " & integer'image(nstores) &
			", expected exactly 83");
		chk(sb_fails = 0, integer'image(sb_fails) &
			" scoreboard mismatch(es) -- see the SCOREBOARD MISMATCH lines");
		chk_hex(hex5, 0, "final HEX5"); chk_hex(hex4, 0, "final HEX4");
		chk_hex(hex3, 0, "final HEX3"); chk_hex(hex2, 0, "final HEX2");
		chk_hex(hex1, 0, "final HEX1"); chk_hex(hex0, 0, "final HEX0");
		chk(ledr = x"00", "final LEDR not clear (test4 never writes it)");

		-- ---- verdict ----------------------------------------------------------
		report "" severity note;
		report "========= BENCH TEST4 (Phase 10B) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - the supplied test4 application ran on the " &
				"full MCU: three KEY ISRs, all three timer modes programmed, " &
				"twenty divisions, exact 83-store trace, and the PWM pin at " &
				"4008 pclk with both programmed duties." severity note;
			report "  Now read the CAPTURE EVENTS line the run script prints: " &
				"3 is the pass condition there." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). If the FIRST scoreboard mismatch is store #28 " &
				"expecting 201D=00000006 but got 00000007, the ORIGINAL image " &
				"is staged - its capture routine never changes BTCTL2. Stage " &
				"bench_fixed/test4." severity error;
		end if;
		report "===================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stim;

END test;
