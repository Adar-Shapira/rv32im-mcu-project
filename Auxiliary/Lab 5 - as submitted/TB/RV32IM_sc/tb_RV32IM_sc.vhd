--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Testbench for the Single-Cycle RISC-V RV32IM Core (Part 1)
-- Based on the given tb_RV32I: clock (100ns period) + reset generator around
-- the core; all core outputs are exposed for the wave window
-- monitor_end_of_program (below) copies run_test.do's own stop condition
-- (instruction_o reaches the final while(1) self-jump) into VHDL via
-- std.env.stop, so the run halts by itself even without loading run_test.do
-- - e.g. from a plain GUI Run -All.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_RV32IM_sc IS
	generic( 
		WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	  	MODELSIM 			: integer 	:= G_MODELSIM;
		DATA_BUS_WIDTH 		: integer 	:= 32;
		ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		PC_WIDTH 			: integer 	:= G_PC_WIDTH;
		MA_WIDTH 			: integer 	:= G_MA_WIDTH;
		DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH 		: integer 	:= 16
	);
END tb_RV32IM_sc ;


ARCHITECTURE struct OF tb_RV32IM_sc IS
	--Inputs
	SIGNAL rst_i		 			: STD_LOGIC;
	SIGNAL clk_i					: STD_LOGIC;
	
	--Outputs (used for Verification and FPGA Velidation(Signal-TAP))
	SIGNAL pc_o						: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	SIGNAL RegWrite_ctrl_o			: STD_LOGIC;
	SIGNAL MemWrite_ctrl_o			: STD_LOGIC;
	SIGNAL Branch_ctrl_o			: STD_LOGIC;
	
	SIGNAL read_data1_o 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o 			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_o				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	SIGNAL alu_res_o 				: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);															
	SIGNAL brTaken_o				: STD_LOGIC; 
	
	SIGNAL dtcm_addr_o				: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	
	SIGNAL mclk_cnt_o				: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
   
BEGIN
	CORE : RV32IM_CORE
	generic map(
		WORD_GRANULARITY 	=> WORD_GRANULARITY,
	  	MODELSIM 			=> MODELSIM,
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
		rst_i           	=> rst_i,
		clk_i           	=> clk_i,
		
		--Outputs
		pc_o				=> pc_o,				-- IFETCH output
		instruction_o		=> instruction_o,		-- IFETCH output
		
		RegWrite_ctrl_o		=> RegWrite_ctrl_o,		-- CONTROL output
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,		-- CONTROL output
		Branch_ctrl_o		=> Branch_ctrl_o,		-- CONTROL output
		
		read_data1_o 		=> read_data1_o,		-- IDECODE output
		read_data2_o 		=> read_data2_o,		-- IDECODE output
		write_data_o		=> write_data_o,		-- IDECODE input(Write-Back) 
		
		alu_res_o 			=> alu_res_o,			-- EXECUTE output															
		brTaken_o			=> brTaken_o,			-- EXECUTE output 
		
		dtcm_addr_o			=> dtcm_addr_o,			-- DMEMORY input
		dtcm_data_wr_o		=> dtcm_data_wr_o,		-- DMEMORY input
		dtcm_data_rd_o		=> dtcm_data_rd_o,		-- DMEMORY output
		
		mclk_cnt_o			=> mclk_cnt_o			-- TOP output
	);	
--------------------------------------------------------------------	
	gen_clk : -- MCLK cycle = 100nsec = 0.1usec
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
	-- Auto-stop: same condition as run_test.do's Tcl "when" block - every
	-- benchmark (test1..test4) ends in an unconditional self-jump - beq
	-- x0,x0,0 (0x00000063, man_compiled tests) or jal x0,0 (0x0000006F,
	-- gcc_compiled tests) - reached at instruction_o. Single-cycle
	-- write-back completes the same clock, so no retire delay is needed
	-- before stopping (unlike the pipeline testbench).
	monitor_end_of_program : process
	begin
		-- triggers directly on instruction_o's own transitions, exactly like
		-- run_test.do's "when {instruction_o == ... OR instruction_o == ...}"
		-- - no clock-edge alignment assumption needed.
		wait until instruction_o = X"00000063" or instruction_o = X"0000006F";
		report "Program finished (while(1) reached) - stopping simulation" severity note;
		std.env.stop;
	end process monitor_end_of_program;
--------------------------------------------------------------------
END struct;
