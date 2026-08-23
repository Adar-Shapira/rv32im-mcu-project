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
    clk_i           : IN  STD_LOGIC;
    rst_i           : IN  STD_LOGIC;
    ena_i           : IN  STD_LOGIC; 								-- Freezes PC during a pipeline stall
    pc_sel_i        : IN  STD_LOGIC; 								-- '1' when a branch or jump is taken in Stage 4
    branch_target_i : IN  STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0); 	-- Resolved target from Stage 4
    
    --Outputs
    pc_o            : OUT STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    pc_plus4_o      : OUT STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    instruction_o   : OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END Ifetch;


ARCHITECTURE behavior OF Ifetch IS
	SIGNAL pc_q				: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL itcm_addr_w		: STD_LOGIC_VECTOR(ITCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL next_pc_w  		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL rst_q  			: STD_LOGIC;
	SIGNAL pc_plus4_w  		: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	
BEGIN
	--=======================================
	-- ITCM (ROM) connection
	--=======================================
	inst_memory: altsyncram
	GENERIC MAP (
		operation_mode					=> "ROM",
		width_a 						=> DATA_BUS_WIDTH,
		widthad_a 						=> ITCM_ADDR_WIDTH,
		numwords_a 						=> WORDS_NUM,
		lpm_hint 						=> "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = ITCM",
		lpm_type 						=> "altsyncram",
		outdata_reg_a 					=> "UNREGISTERED",
		init_file 						=> "C:\Users\oripa\Documents\Benchmark_Apps\test3\RV32IM\bin\M9K-intel\ITCM.hex",  -- Change path for input file
		intended_device_family			=> "Cyclone"
	)
	PORT MAP (
		clock0    	=> clk_i,
		address_a	=> itcm_addr_w, 
		q_a 	   	=> instruction_o 
	);
-------------------------------------------------------------------------------------
-- rst_i synchronization
-------------------------------------------------------------------------------------
	PROCESS (clk_i)
		BEGIN
			IF(clk_i'EVENT  AND clk_i='1') THEN
				IF rst_i = '1' THEN
					rst_q <= '1';	-- preset
				ELSE
					rst_q <= rst_i;
				END IF;
			END IF;
	END PROCESS;
	
-----------------------------------------------------------------------------------
-- Decision MUX for the next PC value
-----------------------------------------------------------------------------------
	pc_plus4_w <= pc_q + 4;
	next_pc_w <= 	(others => '0')                  		WHEN	rst_q = '1' 	ELSE
					branch_target_i(PC_WIDTH-1 DOWNTO 0) 	WHEN	pc_sel_i = '1' 	ELSE
					pc_plus4_w;
																			
-----------------------------------------------------------------------------------
-- pc register
-------------------------------------------------------------------------------------
	PROCESS (clk_i)
		BEGIN
			IF(clk_i'EVENT AND clk_i='1') THEN
				IF rst_i = '1' THEN
					pc_q(PC_WIDTH-1 DOWNTO 0) <= (OTHERS => '0') ;
				ELSIF ena_i = '1' THEN 
					-- Only update the PC only if ena is '1'
					pc_q(PC_WIDTH-1 DOWNTO 0) <= next_pc_w;
				END IF;
			END IF;
	END PROCESS;
-----------------------------------------------------------------------------------	
	-- send address to inst. memory address register
	-- During a stall (ena_i = '0'), pc_q doesn't update but we must keep feeding pc_q to altsyncram
	-- so it fetches the stalled instruction again. Otherwise next_pc_w advances altsyncram to the next instruction
	-- and the current one is lost when the stall ends.
	G1: 
	if (WORD_GRANULARITY = True) generate 			-- i.e. each WORD has unique address
		itcm_addr_w <= next_pc_w(PC_WIDTH-1 DOWNTO 2) WHEN ena_i = '1' ELSE pc_q(PC_WIDTH-1 DOWNTO 2);
	elsif (WORD_GRANULARITY = False) generate 		-- i.e. each BYTE has unique address
		itcm_addr_w <= next_pc_w WHEN ena_i = '1' ELSE pc_q;
	end generate;
---------------------------------------------------------------------------------------
	pc_o 		<= 	pc_q;
	pc_plus4_o	<= 	pc_plus4_w;	
---------------------------------------------------------------------------------------
	
END behavior;


