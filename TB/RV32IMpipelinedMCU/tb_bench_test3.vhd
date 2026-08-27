--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 11 slice 4: interrupt benchmark test3
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_bench_test3.do -- stages the shipped M9K-intel
--   images and passes MODELSIM=1.
--
-- WHAT THIS PROVES
--   Course app Intrrupt-based IO/test3: same KEY/state/HEX path as test2, plus
--   each KEY ISR rewrites BTCMPR0 (1 s >> 1/2/3) and the FSM kernel also
--   writes LEDR from a0. The shortened compare periods are still tens of
--   millions of pclk -- BT_ISR remains FPGA-only in this window. a0=0, so
--   HEX and LEDR stay 0 after each print.
--
-- HOW IT OBSERVES
--   Ordered store scoreboard (init + three KEY passes). BTCNT ticking is
--   the run-script Tcl watch, same as test2.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_bench_test3 IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_bench_test3;


ARCHITECTURE test OF tb_bench_test3 IS

	constant CLK_PERIOD	: time := 100 ns;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	SIGNAL key_pins	: STD_LOGIC_VECTOR(3 DOWNTO 1) := "111";
	SIGNAL ledr10	: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL ledr		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL hex0, hex1, hex2, hex3, hex4, hex5 : STD_LOGIC_VECTOR(6 DOWNTO 0);

	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	SIGNAL nstores	: natural := 0;
	SIGNAL sb_fails	: natural := 0;

	type exp_t is record
		addr : STD_LOGIC_VECTOR(15 DOWNTO 0);
		data : STD_LOGIC_VECTOR(31 DOWNTO 0);
	end record;
	type exp_array_t is array (natural range <>) of exp_t;

	-- SEC_PERIOD = 0x01312D00; KEY1 >>1, KEY2 >>2, KEY3 >>3 (00_main.s).
	constant EXP : exp_array_t(0 to 24) := (
		 0 => (x"201C", x"0000003C"),
		 1 => (x"202C", x"00000000"),
		 2 => (x"202D", x"00000000"),
		 3 => (x"2020", x"01312D00"),
		 4 => (x"202C", x"0000003C"),
		 5 => (x"201C", x"00000018"),
		 6 => (x"0020", x"00000000"),
		-- KEY1: state, BTCMPR0=0.5s, IFG, HEX10, LEDR
		 7 => (x"0020", x"00000001"),
		 8 => (x"2020", x"00989680"),
		 9 => (x"202D", x"00000000"),
		10 => (x"2004", x"00000000"),
		11 => (x"2005", x"00000000"),
		12 => (x"2000", x"00000000"),
		-- KEY2: 0.25 s
		13 => (x"0020", x"00000002"),
		14 => (x"2020", x"004C4B40"),
		15 => (x"202D", x"00000000"),
		16 => (x"2008", x"00000000"),
		17 => (x"2009", x"00000000"),
		18 => (x"2000", x"00000000"),
		-- KEY3: 0.125 s
		19 => (x"0020", x"00000003"),
		20 => (x"2020", x"002625A0"),
		21 => (x"202D", x"00000000"),
		22 => (x"200C", x"00000000"),
		23 => (x"200D", x"00000000"),
		24 => (x"2000", x"00000000")
	);

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
			when others => return "0001110";
		end case;
	end function seg7;

BEGIN
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,
		MODELSIM		=> MODELSIM
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		KEY_i			=> key_pins,
		LEDR_o			=> ledr10,
		HEX0_o			=> hex0,
		HEX1_o			=> hex1,
		HEX2_o			=> hex2,
		HEX3_o			=> hex3,
		HEX4_o			=> hex4,
		HEX5_o			=> hex5,
		PWM_o			=> open,
		MemWrite_ctrl_o	=> memw,
		alu_res_o		=> alu_res,
		read_data2_o	=> st_data
	);

	ledr <= ledr10(7 DOWNTO 0);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	rst <= '1', '0' after 80 ns;

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

	begin
		wait until rst = '0';

		wait_stores(7, 8000, "sys_init + state=0");
		settle(80);

		press(1);
		wait_stores(13, 8000, "KEY1 (0.5 s period + HEX10 + LEDR)");
		settle(50);
		chk_hex(hex1, 0, "KEY1 HEX1"); chk_hex(hex0, 0, "KEY1 HEX0");
		chk(ledr = x"00", "KEY1 LEDR");

		press(2);
		wait_stores(19, 8000, "KEY2 (0.25 s period + HEX32 + LEDR)");
		settle(50);
		chk_hex(hex3, 0, "KEY2 HEX3"); chk_hex(hex2, 0, "KEY2 HEX2");
		chk(ledr = x"00", "KEY2 LEDR");

		press(3);
		wait_stores(25, 8000, "KEY3 (0.125 s period + HEX54 + LEDR)");
		settle(50);
		chk_hex(hex5, 0, "KEY3 HEX5"); chk_hex(hex4, 0, "KEY3 HEX4");
		chk(ledr = x"00", "KEY3 LEDR");

		chk(nstores = 25, "final store count is " & integer'image(nstores) &
			", expected exactly 25");
		chk(sb_fails = 0, integer'image(sb_fails) &
			" scoreboard mismatch(es)");

		report "" severity note;
		report "========= BENCH TEST3 (Phase 11) SUMMARY =========" severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - KEY ISRs rewrote BTCMPR0 and the kernel " &
				"printed HEX+LEDR. The 0.125-1 s BT_ISR is FPGA-only."
				severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s)." severity error;
		end if;
		report "===================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process stim;

END test;
