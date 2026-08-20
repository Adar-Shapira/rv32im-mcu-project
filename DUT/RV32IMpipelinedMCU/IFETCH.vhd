--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Pipelined RISC-V RV32IM Core - IF stage
-- IFETCH provides the PC and the ITCM, plus the IF/ID pipeline register.
-- Pipeline changes vs the single-cycle version:
--   * branch/jal/jalr are resolved in the MEM stage, so the local next-PC
--     mux inputs are replaced by flush_i + redirect_addr_i from the top
--   * stall_i freezes the PC (recirculation) and holds the IF/ID register
--   * flush_i redirects the PC and injects a NOP bubble into IF/ID
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
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
		stall_i				: IN 	STD_LOGIC;										-- from HAZARD_UNIT: freeze PC + IF/ID
		flush_i				: IN 	STD_LOGIC;										-- from top (MEM stage): taken branch/jal/jalr
		redirect_addr_i		: IN 	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- redirect target resolved in MEM

		--Outputs
		if_pc_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- IF-stage PC (breakpoint/Signal-Tap)
		pc_o 				: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- IF/ID: PC of the ID-stage instruction
		pc_plus4_o 			: OUT	STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);			-- IF/ID: PC+4 of the ID-stage instruction
		instruction_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)	-- IF/ID: ID-stage instruction
	);
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	-- NOP = addi x0,x0,0 ; injected into IF/ID on flush (bubble)
	CONSTANT NOP_INSTRUCTION	: STD_LOGIC_VECTOR(31 DOWNTO 0) := X"00000013";

	SIGNAL pc_q					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_q			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL pc_plus4_r 			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w			: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_data_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL rst_q  				: STD_LOGIC;
	-- IF/ID pipeline register
	SIGNAL if_id_pc_q			: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_id_pc_plus4_q		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL if_id_instruction_q	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

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
		q_a 	   	=> itcm_data_w 
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
	-- flush (redirect from MEM) has priority over stall: the redirecting
	-- instruction is older than the stalled one, so the stall is cancelled.
	-- On stall the PC recirculates, which also keeps the synchronous ITCM
	-- re-reading the same address so the IF-stage instruction is held.
	next_pc_w	<=	(others => '0') 					WHEN	rst_q 		ELSE
					redirect_addr_i						WHEN	flush_i		ELSE	-- taken branch/jal/jalr resolved in MEM
					pc_q(PC_WIDTH-1 DOWNTO 0)			WHEN	stall_i		ELSE	-- freeze PC (hazard stall)
					pc_plus4_q(PC_WIDTH-1 DOWNTO 0);								-- sequential fetch
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
-- IF/ID pipeline register
-- flush -> NOP bubble (kills the IF-stage instruction on a taken branch/jump)
-- stall -> hold (the ID-stage instruction is replayed)
-------------------------------------------------------------------------------------
PROCESS (clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			if_id_pc_q			<= (OTHERS => '0');
			if_id_pc_plus4_q	<= (OTHERS => '0');
			if_id_instruction_q	<= NOP_INSTRUCTION;
		ELSIF(clk_i'EVENT  AND clk_i='1') THEN
			IF flush_i = '1' THEN
				if_id_pc_q			<= (OTHERS => '0');
				if_id_pc_plus4_q	<= (OTHERS => '0');
				if_id_instruction_q	<= NOP_INSTRUCTION;
			ELSIF stall_i = '0' THEN
				if_id_pc_q			<= pc_q;
				if_id_pc_plus4_q	<= pc_plus4_q;
				if_id_instruction_q	<= itcm_data_w;
			END IF;
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
	if_pc_o		<=	pc_q;					-- IF-stage PC (breakpoint compare)
	pc_o 		<= 	if_id_pc_q;				-- ID-stage view
	pc_plus4_o	<= 	if_id_pc_plus4_q;
	instruction_o	<=	if_id_instruction_q;
---------------------------------------------------------------------------------------
	
END behavior;
