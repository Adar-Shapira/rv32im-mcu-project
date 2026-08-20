--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026: drives RV32IMpipelinedMCU (the board-facing structural
-- top, §3) rather than the bare core. RST_ACTIVE_LOW => FALSE keeps the
-- supplied active-high reset stimulus valid. External names gained one level.
-- Testbench for the Pipelined RISC-V RV32IM Core (Part 2)
-- Same clock (100ns period) + reset generator as tb_RV32IM_sc, around the
-- RV32IM_PIPE_CORE top. In addition to the single-cycle observation points it
-- drives the BPADDR_i breakpoint address (emulating SW7-SW0 on the FPGA) and
-- exposes the pipeline debug outputs - stall_o, flush_o, BPTRIGGER_o and the
-- CLKCNT/STCNT/FHCNT counters - so the IPC equation
--   IPC = (CLKCNT - (STCNT + 4 + 3*FHCNT)) / CLKCNT
-- can be verified in simulation (run_test.do reads the counters at the end).
-- monitor_end_of_program (below) copies run_test.do's own stop condition
-- (MEM-stage redirect target == the flushing instruction's own PC+4) into
-- VHDL via std.env.stop, so the run halts by itself even without loading
-- run_test.do - e.g. from a plain GUI Run -All.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_RV32IMpipelinedMCU IS
	generic( 
		WORD_GRANULARITY 	: boolean 	:= G_WORD_GRANULARITY;
	  	MODELSIM 			: integer 	:= G_MODELSIM;
		DATA_BUS_WIDTH 		: integer 	:= 32;
		ITCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH 	: integer 	:= G_ADDRWIDTH;
		PC_WIDTH 			: integer 	:= G_PC_WIDTH;
		MA_WIDTH 			: integer 	:= G_MA_WIDTH;
		DATA_WORDS_NUM 		: integer 	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH 		: integer 	:= 16;
		-- STCNT/FHCNT are 8-bit registers on the FPGA (Figure 8); in simulation
		-- they are widened to 16 bits so the long gcc benchmarks (test3/test4,
		-- ~300 flushes) don't wrap around - the IPC equation check needs the
		-- true counts. The core generics default to 8 for the Quartus build.
		STCNT_WIDTH 		: integer 	:= 16;
		FHCNT_WIDTH 		: integer 	:= 16;
		BP_ADDR_WIDTH 		: integer 	:= 8
	);
END tb_RV32IMpipelinedMCU ;


ARCHITECTURE struct OF tb_RV32IMpipelinedMCU IS
	--Inputs
	SIGNAL rst_i		 			: STD_LOGIC;
	SIGNAL clk_i					: STD_LOGIC;
	SIGNAL BPADDR_i					: STD_LOGIC_VECTOR(BP_ADDR_WIDTH-1 DOWNTO 0);
	
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
	
	SIGNAL stall_o					: STD_LOGIC;
	SIGNAL flush_o					: STD_LOGIC;
	SIGNAL BPTRIGGER_o				: STD_LOGIC;
	
	SIGNAL CLKCNT_o					: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
	SIGNAL STCNT_o					: STD_LOGIC_VECTOR(STCNT_WIDTH-1 DOWNTO 0);
	SIGNAL FHCNT_o					: STD_LOGIC_VECTOR(FHCNT_WIDTH-1 DOWNTO 0);
   
BEGIN
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is active-high
		GEN_DEBUG_PORTS		=> TRUE,
		WORD_GRANULARITY 	=> WORD_GRANULARITY,
	  	MODELSIM 			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH,
		STCNT_WIDTH			=> STCNT_WIDTH,
		FHCNT_WIDTH			=> FHCNT_WIDTH,
		BP_ADDR_WIDTH		=> BP_ADDR_WIDTH
	)
	PORT MAP (
		--Inputs
		rst_i           	=> rst_i,
		clk_i           	=> clk_i,
		BPADDR_i			=> BPADDR_i,			-- breakpoint word address (SW7-SW0 on the FPGA)
		
		--Outputs
		pc_o				=> pc_o,				-- IFETCH output (IF-stage PC)
		instruction_o		=> instruction_o,		-- IFETCH output (IF/ID register, ID stage)
		
		RegWrite_ctrl_o		=> RegWrite_ctrl_o,		-- WB stage (RF write enable)
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,		-- MEM stage
		Branch_ctrl_o		=> Branch_ctrl_o,		-- MEM stage
		
		read_data1_o 		=> read_data1_o,		-- IDECODE output (ID/EX register)
		read_data2_o 		=> read_data2_o,		-- IDECODE output (ID/EX register)
		write_data_o		=> write_data_o,		-- IDECODE write-back mux (WB stage) 
		
		alu_res_o 			=> alu_res_o,			-- EXECUTE output (EX/MEM register)															
		brTaken_o			=> brTaken_o,			-- EXECUTE output (EX/MEM register) 
		
		dtcm_addr_o			=> dtcm_addr_o,			-- DMEMORY input
		dtcm_data_wr_o		=> dtcm_data_wr_o,		-- DMEMORY input
		dtcm_data_rd_o		=> dtcm_data_rd_o,		-- DMEMORY output
		
		stall_o				=> stall_o,				-- HAZARD_UNIT interlock
		flush_o				=> flush_o,				-- MEM-stage redirect
		BPTRIGGER_o			=> BPTRIGGER_o,			-- Signal-Tap trigger: IF PC == BPADDR_i
		
		CLKCNT_o			=> CLKCNT_o,			-- TOP output (clock counter)
		STCNT_o				=> STCNT_o,				-- TOP output (stall counter)
		FHCNT_o				=> FHCNT_o				-- TOP output (flush counter)
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

	-- breakpoint word address (emulates SW7-SW0): 0x04 = byte PC 0x10, the
	-- 5th instruction - BPTRIGGER_o must pulse once the IF PC reaches it
	BPADDR_i	<=	CONV_STD_LOGIC_VECTOR(4, BP_ADDR_WIDTH);
--------------------------------------------------------------------
	-- Auto-stop: every benchmark (test1..test4) ends in an unconditional self-jump
	-- that keeps re-flushing forever, so plain "flush_o='1'" would also fire on
	-- every ordinary taken branch/jump earlier in the program. The real
	-- end is identified the same way: the MEM-stage redirect target equals
	-- the flushing instruction's own PC+4 (a jump to itself). Requires
	-- G_MODELSIM=1 (mclk_w <= clk_i, no PLL) for clk_i to stand in for the
	-- core clock.
	monitor_end_of_program : process
		constant RETIRE_CYCLES	: natural := 5;	-- let EX/MEM/WB drain before stopping
	begin
		-- triggers directly on flush_o's own transition to '1', exactly like
		-- run_test.do's "when {flush_o == \"1\"}" - no clock-edge alignment
		-- assumption needed (avoids any clk_i vs. mclk_w delta-cycle skew).
		wait until flush_o = '1';
		if << signal .tb_rv32impipelinedmcu.MCU.CORE.mem_pc_plus4_w : std_logic_vector(PC_WIDTH-1 downto 0) >> =
		   << signal .tb_rv32impipelinedmcu.MCU.CORE.redirect_addr_w : std_logic_vector(PC_WIDTH-1 downto 0) >> + 4
		then
			report "Program finished (while(1) self-jump resolved in MEM) - stopping simulation" severity note;
			for i in 1 to RETIRE_CYCLES loop
				wait until rising_edge(clk_i);
			end loop;
			std.env.stop;
		end if;
	end process monitor_end_of_program;
--------------------------------------------------------------------
END struct;
