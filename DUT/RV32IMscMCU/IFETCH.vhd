--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Top Level Structural Model for Single-Cycle RISC-V Core
-- IFETCH module provides the PC and the ITCM of the RISC-V core)
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE work.cond_compilation_package.all;	-- G_ISA_REPAIR (defect-repair switch)
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


ENTITY Ifetch IS
	generic(
		WORD_GRANULARITY 	: boolean	:= False;
		DATA_BUS_WIDTH 		: integer	:= 32;
		PC_WIDTH 			: integer	:= 10;
		ITCM_ADDR_WIDTH 	: integer	:= 8;
		WORDS_NUM 			: integer	:= 256
	);
	PORT(
		--Inputs
		clk_i				: IN 	STD_LOGIC;
		rst_i 				: IN 	STD_LOGIC;
		addr_gen_i 			: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    	Branch_ctrl_i		: IN 	STD_LOGIC;
    	brTaken_i 			: IN 	STD_LOGIC;
		Jal_ctrl_i			: IN 	STD_LOGIC;
		Jalr_ctrl_i			: IN 	STD_LOGIC;
		alu_res_i 			: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- Phase 7B2. Figure 3 gives the Control Unit a PCHold input; this is the
		-- other end of it. While it is high the PC does not advance and the SAME
		-- instruction is re-fetched, which is what keeps DIVstart asserted for the
		-- whole divide. Defaulted to '0' so an instantiation that predates the
		-- divider behaves exactly as before.
		PCHold_i			: IN	STD_LOGIC := '0';
		
		--Outputs
		pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
		instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_q		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_r 		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w		: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL jalr_target_w	: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);	-- defect 7: jalr target, bit 0 gated
	SIGNAL brTaken_w  		: STD_LOGIC;
	SIGNAL rst_q  			: STD_LOGIC;
	
BEGIN
	--=======================================
	-- ITCM (ROM) connection
	--=======================================
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode			=> "ROM",
		width_a 				=> DATA_BUS_WIDTH,
		widthad_a 				=> ITCM_ADDR_WIDTH,
		numwords_a 				=> WORDS_NUM,
		lpm_hint 				=> "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type 				=> "altsyncram",
		outdata_reg_a 			=> "UNREGISTERED",
		init_file 				=> "C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex",
		intended_device_family	=> "Cyclone"
	)
	PORT MAP (
		clock0    	=> clk_i,
		address_a	=> itcm_addr_w, 
		q_a 	   	=> instruction_o 
	);
-------------------------------------------------------------------------------------
-- rst_i synchronization
-------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			rst_q <= '1';	-- preset
		ELSIF(clk_i'EVENT  AND clk_i='1') THEN
			rst_q <= rst_i;
		END IF;
END PROCESS;

-----------------------------------------------------------------------------------		
	-- Adder to execute PC+4
  	pc_plus4_r(PC_WIDTH-1 DOWNTO 0)	<= next_pc_w(PC_WIDTH-1 DOWNTO 0) + 4;
	
-----------------------------------------------------------------------------------
	-- Decision MUX for the next PC value
	brTaken_w 	<= 	Branch_ctrl_i AND brTaken_i;
	
	-- Defect 7 (jalr does not clear the target's low bit). RV32I requires
	-- pc <- (rs1 + imm) with bit 0 forced to zero. The as-submitted mux takes alu_res_i
	-- unmasked, so an odd jalr target misaligns the PC. Today it is masked by the
	-- word-granular ITCM (bits 1..0 are dropped on the way to the RAM address), so the
	-- fetch still lands on the right word -- but pc_o, pc_plus4 and every downstream link
	-- address carry the odd value. Repair reference:
	--   Auxiliary/Lab 5 - as submitted/DUT/RV32IM_pipeline/RV32IM_PIPE_CORE.vhd:190
	--     redirect_addr_w <= mem_alu_res_w(PC_WIDTH-1 DOWNTO 1) & '0' WHEN mem_Jalr_w = '1'
	jalr_target_w	<=	alu_res_i(PC_WIDTH-1 DOWNTO 1) & '0'	WHEN G_ISA_REPAIR ELSE
						alu_res_i(PC_WIDTH-1 DOWNTO 0);

	-- PHASE 7B2 -- THE STALL.
	--
	-- THIS IS NOT A NEW IDEA, AND IT IS NOT OURS. It is the same mechanism our
	-- own Lab 5 pipeline already uses for the load-use interlock:
	--   Auxiliary/Lab 5 - as submitted/DUT/RV32IM_pipeline/IFETCH.vhd:107
	--     pc_q(PC_WIDTH-1 DOWNTO 0)   WHEN  stall_i  ELSE  -- freeze PC (hazard stall)
	--   with the comment at lines 103-104 giving the same reason this needs:
	--     "On stall the PC recirculates, which also keeps the synchronous ITCM
	--      re-reading the same address so the IF-stage instruction is held."
	-- The only differences here are the name -- Figure 3 of the final-project
	-- definition calls the signal PCHold, so that is what the port is called --
	-- and the source: there it comes from HAZARD_UNIT's load-use check, here from
	-- a divide that has not finished. The pipeline's version also has to hold the
	-- IF/ID register (its line 149); a single-cycle core has no such register, so
	-- that half has no counterpart.
	--
	-- Why it works, restated because the consequence is easy to get wrong:
	--   itcm_addr_w is next_pc_w, so holding it at pc_q re-fetches the CURRENT
	--   instruction rather than the next one. Freezing only the pc register would
	--   NOT have done that -- next_pc_w would still have been pc_plus4_q, the ITCM
	--   would have fetched the following instruction, instruction_o would have
	--   changed underneath the stall, and DIVstart would have dropped mid-divide.
	--   pc_plus4_q needs no separate hold: it tracks next_pc_w + 4, so while the
	--   PC is held it sits at pc_q + 4, the right value to resume on.
	--
	-- ORDERING DIFFERS FROM THE PIPELINE, DELIBERATELY. There, flush has priority
	-- OVER stall, because the redirecting instruction is older than the stalled
	-- one. Here the hold sits ABOVE the jalr/branch arms instead: in a
	-- single-cycle core the stalled instruction IS the current instruction, there
	-- is nothing older in flight, and a redirect computed from a div that has not
	-- produced its result yet would be meaningless. Reset still wins over both.
	next_pc_w	<=	(others => '0') 					WHEN	rst_q 					ELSE
					pc_q								WHEN	PCHold_i = '1'			ELSE	-- Phase 7B2: hold
					jalr_target_w						WHEN	Jalr_ctrl_i				ELSE	-- case of jalr
					addr_gen_i(PC_WIDTH-1 DOWNTO 0)		WHEN	brTaken_w or Jal_ctrl_i ELSE	-- case of Branch Taken or jal 
					pc_plus4_q(PC_WIDTH-1 DOWNTO 0);											-- case of Branch Not-Taken 				
-----------------------------------------------------------------------------------
-- pc_plus4 register
-------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pc_plus4_q(PC_WIDTH-1 DOWNTO 0) <= (OTHERS => '0') ; 
		ELSIF(clk_i'EVENT  AND clk_i='1') THEN
			pc_plus4_q(PC_WIDTH-1 DOWNTO 0) <= pc_plus4_r;	
		END IF;
END PROCESS;

-----------------------------------------------------------------------------------
-- pc register
-------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pc_q(PC_WIDTH-1 DOWNTO 0) <= (OTHERS => '0') ; 
		ELSIF(clk_i'EVENT  AND clk_i='1') THEN
			pc_q(PC_WIDTH-1 DOWNTO 0) <= next_pc_w;	
		END IF;
END PROCESS;
-----------------------------------------------------------------------------------	
	-- send address to inst. memory address register
	G1: 
	if (WORD_GRANULARITY = True) generate 			-- i.e. each WORD has unike address
		itcm_addr_w <= next_pc_w(PC_WIDTH-1 DOWNTO 2);
	elsif (WORD_GRANULARITY = False) generate 	-- i.e. each BYTE has unike address
		itcm_addr_w <= next_pc_w;
	end generate;
---------------------------------------------------------------------------------------
	pc_o 		<= 	pc_q;
	pc_plus4_o	<= 	pc_plus4_q;	
---------------------------------------------------------------------------------------
	
END behavior;
