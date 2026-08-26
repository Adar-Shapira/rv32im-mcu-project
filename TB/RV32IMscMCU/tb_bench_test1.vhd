--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 10A: Interrupt benchmark test1, self-checking
--
-- HOW TO RUN
--   SIM/RV32IMscMCU/run_bench_test1.do -- needs the CORRECTED test1 images
--   staged (SIM/RV32IMscMCU/bench_fixed/test1/).
--
-- WHY THE CORRECTED IMAGE, AND WHAT WAS CORRECTED
--   The shipped test1 gates EINT on SW0: the SW0=0 short-delay path -- the
--   one its own comments call "used for ModelSim based verification" --
--   jumps PAST `ori gp,gp,1`, so GIE stays 0 and no KEY ever interrupts.
--   tests 2/3/4 all enable EINT unconditionally; test1 alone differs, so
--   this is a benchmark regression, documented in DOC/03. The original is
--   untouched; the copy under bench_fixed/ differs by ONE word (the jal's
--   target, audited in bench_fixed/PATCHES.md), and this bench runs the
--   copy at SW0=0. Staging the ORIGINAL instead makes every check after
--   reset fail with the displays frozen at 0 -- the documented dead state.
--
-- WHAT THIS PROVES
--   The supplied benchmark application -- the course contract -- running on
--   the full MCU: three KEY ISRs through the real controller and entry,
--   the state-machine kernel, div/rem on the divider accelerator, the
--   seven-segment and LED output path. Expected values below are derived
--   from the SHIPPED images, read word by word (not from our RTL):
--     arr1 = {100,98,97,96,95,94,93,92} at DTCM 0x24, arr2 = {8..1} at 0x44
--     KEY1 -> arr1[i] on HEX5:4;  KEY2 -> arr2[i] on HEX3:2
--     KEY3 -> a SWEEP: STATE3 leaves fp=3 on its increment path, so it
--       re-enters until t4 reaches SIZE: passes 1..8 divide arr1[k]/arr2[k]
--       and pass 9 divides MEM[0x44]=8 by MEM[0x64]=0 -- both words read
--       straight from the shipped DTCM.hex -- before the pointers reset and
--       fp clears. So the display AFTER a sweep is the divide-by-zero
--       tail: quotient all-ones (F4, and RISC-V's own rule) -> HEX1:0 =
--       "FF", remainder = the dividend -> LEDR = 0x08. One press per
--       sweep; with the FPGA's long delay this is the ~1s-per-step
--       animation the ReadMe describes.
--   Liveness is checked event-driven, not by timing: a SECOND KEY3 press
--   must drive LEDR through 0x04 (pass 1: 100 rem 8) before settling back
--   at 0x08 -- a changing observable, so a hung system cannot pass on
--   stale display contents.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_bench_test1 IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_bench_test1;


ARCHITECTURE test OF tb_bench_test1 IS

	constant CLK_PERIOD	: time := 100 ns;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL key_pins	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "111";	-- raw, active-low
	SIGNAL sw_pins	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');	-- SW0=0: short delay
	SIGNAL ledr		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex0, hex1, hex2, hex3, hex4, hex5 : STD_LOGIC_VECTOR(6 DOWNTO 0);

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
		SW_i(7 DOWNTO 0)	=> sw_pins,		-- SW0 = 0: the short-delay path
		SW_i(9 DOWNTO 8)	=> "00",
		KEY_i			=> key_pins,
		LEDR_o(7 DOWNTO 0)	=> ledr,
		HEX0_o			=> hex0,
		HEX1_o			=> hex1,
		HEX2_o			=> hex2,
		HEX3_o			=> hex3,
		HEX4_o			=> hex4,
		HEX5_o			=> hex5,
		PWM_o			=> open,
		pc_o			=> open,
		instruction_o	=> open,
		RegWrite_ctrl_o	=> open,
		MemWrite_ctrl_o	=> open,
		Branch_ctrl_o	=> open,
		read_data1_o	=> open,
		read_data2_o	=> open,
		write_data_o	=> open,
		alu_res_o		=> open,
		brTaken_o		=> open,
		dtcm_addr_o		=> open,
		dtcm_data_wr_o	=> open,
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

		-- event-driven wait: LEDR must REACH the value before the timeout
		procedure wait_ledr(constant v : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
							constant msg : IN string) is
			variable n : natural := 0;
		begin
			while ledr /= v and n < 6000 loop
				wait until falling_edge(clk);
				n := n + 1;
			end loop;
			chk(n < 6000, msg);
		end procedure wait_ledr;

	begin
		wait until rst = '0';
		settle(800);							-- init: EINT + display clear

		-- ---- the cleared state -----------------------------------------------
		chk_hex(hex5, 0, "init HEX5"); chk_hex(hex4, 0, "init HEX4");
		chk_hex(hex3, 0, "init HEX3"); chk_hex(hex2, 0, "init HEX2");
		chk_hex(hex1, 0, "init HEX1"); chk_hex(hex0, 0, "init HEX0");
		chk(ledr = x"00", "init LEDR not clear");

		-- ---- KEY1: arr1[0] = 100 = 0x64 on HEX5:4 -----------------------------
		press(1); settle(400);
		chk_hex(hex5, 6, "after KEY1, HEX5"); chk_hex(hex4, 4, "after KEY1, HEX4");
		chk_hex(hex3, 0, "after KEY1, HEX3 must not move");

		-- ---- KEY2: arr2[0] = 8 on HEX3:2 --------------------------------------
		press(2); settle(400);
		chk_hex(hex3, 0, "after KEY2, HEX3"); chk_hex(hex2, 8, "after KEY2, HEX2");
		chk_hex(hex5, 6, "after KEY2, HEX5 must not move");

		-- ---- KEY3: the sweep --------------------------------------------------
		press(3); settle(4000);				-- 9 passes at short delay
		chk_hex(hex1, 15, "after the sweep, HEX1");
		chk_hex(hex0, 15, "after the sweep, HEX0 (8/0: all-ones quotient, F4)");
		chk(ledr = x"08", "after the sweep, LEDR = 0x" & to_hstring(ledr) &
			", expected 0x08 (8 rem 0 = the dividend)");
		chk_hex(hex5, 6, "after the sweep, HEX5 held");
		chk_hex(hex4, 4, "after the sweep, HEX4 held");
		chk_hex(hex3, 0, "after the sweep, HEX3 held");
		chk_hex(hex2, 8, "after the sweep, HEX2 held");

		-- ---- liveness: a SECOND sweep, watched through a CHANGING value -------
		press(3);
		wait_ledr(x"04", "second sweep: LEDR never showed 0x04 (100 rem 8, " &
			"pass 1) - the system is not alive after the first sweep");
		wait_ledr(x"08", "second sweep: LEDR never settled back at 0x08");
		settle(400);
		chk_hex(hex1, 15, "after sweep 2, HEX1");
		chk_hex(hex0, 15, "after sweep 2, HEX0");

		-- ---- verdict ----------------------------------------------------------
		report "" severity note;
		report "========= BENCH TEST1 (Phase 10A) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - the supplied test1 application ran on the " &
				"full MCU: three KEY ISRs, the FSM kernel, eight divisions, " &
				"the divide-by-zero tail, and a live second sweep." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). If EVERYTHING after init failed with displays at " &
				"zero, the ORIGINAL image is staged - its SW0=0 path never " &
				"enables GIE. Stage bench_fixed/test1." severity error;
		end if;
		report "===================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stim;

END test;
