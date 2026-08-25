--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — testbench for the single-cycle RV32IM MCU
--
-- Filename and entity name are mandated by the submission table (§10):
--   TB/RV32IMscMCU/tb_RV32IMscMCU.vhd
--
-- THE SPEC REQUIRES THIS ONE FILE. Clause 10 Table 1: "In folder RV32IMscMCU
-- insert the tb_RV32IMscMCU.vhd file". Same shape as Lab 5: one TB, clock +
-- reset, every observation port brought out for the wave window. GPIO / KEY /
-- PWM / HEX are added because this project has board I/O that Lab 5 did not.
--
-- REFERENCE
--   Auxiliary/Lab 5/TB/RV32IM_sc/tb_RV32IM_sc.vhd, itself based on Hanan's
--   Auxilary/TB/tb_RV32I.vhd.
--
-- HOW WE SIMULATE (course convention, not a .do-driven flow)
--   1. Set G_MODELSIM := 1 in cond_compilation_package.vhd, then compile.
--      Set it back to 0 before a Quartus compile.
--   2. Copy the chosen test's M9K-intel ITCM.hex and DTCM.hex into
--      C:\TestPrograms\Quartus21_1\app_bin\  (hardcoded init_file in IFETCH
--      and DMEMORY). Never use Hexadecimal-Text/*.h — those are a different
--      program.
--   3. Simulate work.tb_rv32imscmcu. Load SIM/RV32IMscMCU/golden.do (all
--      signals) or wave.do (compact daily set).
--   4. Force SW_i / KEY_i from the wave window for GPIO and interrupt apps.
--      KEY0 is rst_i. KEY1..3 are active-low; interrupt request is RELEASE.
--   5. There is no auto-stop. GPIO and interrupt apps loop forever. RV32IM
--      test1 ends in beq x0,x0,finish (0x00000063) — stop by hand, dump DTCM,
--      compare to that test's RARS DTCM.h (clause 8.c.i).
--
-- WHICH IMAGES GO WITH WHICH PART  (Auxiliary/Benchmark Apps/, not Lab 5)
--   RV32IM/test1          core: div / mul / rem arrays, then while(1)
--   GPIO/test0            GPO write path (LEDR + HEX0..5 count)
--   GPIO/test1            PORT_SW read: SW0 count up, SW1 count down, else idle
--   GPIO/test2            same switches, six-digit HEX number
--   Intrrupt-based IO/test1  KEY1/2/3 FSM + div/rem on KEY3
--   Intrrupt-based IO/test2  1 s Basic Timer + KEYs
--   Intrrupt-based IO/test3  four timer periods
--   Intrrupt-based IO/test4  compare / PWM / capture
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_RV32IMscMCU IS
	generic(
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
END tb_RV32IMscMCU;
--============================================================================
ARCHITECTURE struct OF tb_RV32IMscMCU IS
	--Inputs (Lab 5 shape: clock + reset)
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	-- Board I/O — Final Project clauses 4–6. Forced from the wave window
	-- for GPIO / interrupt apps; defaults are "switches down, keys released".
	SIGNAL SW_i					: STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
	SIGNAL KEY_i				: STD_LOGIC_VECTOR(3 DOWNTO 1) := (OTHERS => '1');	-- active-low, idle = 1
	SIGNAL GPIO					: STD_LOGIC_VECTOR(35 DOWNTO 0) := (OTHERS => 'Z');
	SIGNAL CAPIN1_i				: STD_LOGIC := '0';
	SIGNAL CAPIN2_i				: STD_LOGIC := '0';
	SIGNAL PWM_o				: STD_LOGIC;
	SIGNAL LEDR_o				: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL HEX0_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX1_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX2_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX3_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX4_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);
	SIGNAL HEX5_o				: STD_LOGIC_VECTOR(6 DOWNTO 0);

	-- Observation ports (Verification and Signal-Tap), same set as Lab 5
	SIGNAL pc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL RegWrite_ctrl_o		: STD_LOGIC;
	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL Branch_ctrl_o		: STD_LOGIC;

	SIGNAL read_data1_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_o			: STD_LOGIC;

	SIGNAL dtcm_addr_o			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

	SIGNAL dtcm_cs_o			: STD_LOGIC;
	SIGNAL unmapped_o			: STD_LOGIC;
	SIGNAL dtcm_wren_o			: STD_LOGIC;

	SIGNAL mclk_cnt_o			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

BEGIN
	MCU : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is already active-high, as Lab 5
		GEN_DEBUG_PORTS		=> TRUE,
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
		clk_i				=> clk_i,
		rst_i				=> rst_i,

		SW_i				=> SW_i,
		KEY_i				=> KEY_i,
		GPIO				=> GPIO,
		CAPIN1_i			=> CAPIN1_i,
		CAPIN2_i			=> CAPIN2_i,
		PWM_o				=> PWM_o,
		LEDR_o				=> LEDR_o,
		HEX0_o				=> HEX0_o,
		HEX1_o				=> HEX1_o,
		HEX2_o				=> HEX2_o,
		HEX3_o				=> HEX3_o,
		HEX4_o				=> HEX4_o,
		HEX5_o				=> HEX5_o,

		pc_o				=> pc_o,
		instruction_o		=> instruction_o,

		RegWrite_ctrl_o		=> RegWrite_ctrl_o,
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,
		Branch_ctrl_o		=> Branch_ctrl_o,

		read_data1_o		=> read_data1_o,
		read_data2_o		=> read_data2_o,
		write_data_o		=> write_data_o,

		alu_res_o			=> alu_res_o,
		brTaken_o			=> brTaken_o,

		dtcm_addr_o			=> dtcm_addr_o,
		dtcm_data_wr_o		=> dtcm_data_wr_o,
		dtcm_data_rd_o		=> dtcm_data_rd_o,

		dtcm_cs_o			=> dtcm_cs_o,
		unmapped_o			=> unmapped_o,
		dtcm_wren_o			=> dtcm_wren_o,

		mclk_cnt_o			=> mclk_cnt_o
	);
--------------------------------------------------------------------
	gen_clk : -- MCLK cycle = 100nsec = 0.1usec  (Lab 5 TB, unchanged)
	process
	begin
		clk_i <= '1';
		wait for 50 ns;
		clk_i <= not clk_i;
		wait for 50 ns;
	end process;

	gen_rst :
	process
	begin
		rst_i <='1','0' after 80 ns;
		wait;
	end process;
--------------------------------------------------------------------
END struct;
