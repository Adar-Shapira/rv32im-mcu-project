--============================================================================
-- Copyright 2026 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Conditional Compilation Parameters
--============================================================================ 
library IEEE;
use ieee.std_logic_1164.all;


package cond_compilation_package is
-- Use Conditional Compilation to define 6-Parameters lines 51-56
------------------------------------------------------------------
-- M9K(and ModelSim) Memory configuration constants
------------------------------------------------------------------
	constant M9K_TCM1KiB_ADDRWIDTH 		: integer := 8;
	constant M9K_TCM2KiB_ADDRWIDTH 		: integer := 9;
	constant M9K_TCM4KiB_ADDRWIDTH 		: integer := 10;
	constant M9K_TCM8KiB_ADDRWIDTH 		: integer := 11;
	
	constant M9K_TCM1KiB_WORDSNUM 		: integer := 256;
	constant M9K_TCM2KiB_WORDSNUM 		: integer := 512;
	constant M9K_TCM4KiB_WORDSNUM 		: integer := 1024;
	constant M9K_TCM8KiB_WORDSNUM 		: integer := 2048;
-----------------------------------------------------------
-- M4K Memory configuration constants
-----------------------------------------------------------	
	constant M4K_TCM1KiB_ADDRWIDTH 		: integer := 10;
	constant M4K_TCM2KiB_ADDRWIDTH 		: integer := 11;
	constant M4K_TCM4KiB_ADDRWIDTH 		: integer := 12;
	constant M4K_TCM8KiB_ADDRWIDTH 		: integer := 13;
	
	constant M4K_TCM1KiB_WORDSNUM 		: integer := 1024;
	constant M4K_TCM2KiB_WORDSNUM 		: integer := 2048;
	constant M4K_TCM4KiB_WORDSNUM 		: integer := 4095;
	constant M4K_TCM8KiB_WORDSNUM 		: integer := 8190;
----------------------------------------------------------------------
-- PC_WIDTH and MA_WIDTH configuration constants for M9K_M4K_MODELSIM
----------------------------------------------------------------------		
	constant PC_WIDTH_TCM1KiB			: integer := 10;
	constant PC_WIDTH_TCM2KiB 			: integer := 11;
	constant PC_WIDTH_TCM4KiB 			: integer := 12;
	constant PC_WIDTH_TCM8KiB 			: integer := 13;
-----------------------------------------------------------------------	
	constant MA_WIDTH_TCM1KiB 			: integer := 10;
	constant MA_WIDTH_TCM2KiB 			: integer := 11;
	constant MA_WIDTH_TCM4KiB 			: integer := 12;
	constant MA_WIDTH_TCM8KiB 			: integer := 13;
--==================================================================================================================
-- 															Conditional Compilation defined by 8-Parameters
--==================================================================================================================
	constant G_MODELSIM					: integer	:= 0;					-- options{1=MODELSIM,0=FPGA} -- set to 0 before Quartus synthesis
	constant G_WORD_GRANULARITY 		: boolean := True;					-- options{True,False}
	constant G_ADDRWIDTH 				: integer := M9K_TCM8KiB_ADDRWIDTH;	-- options{M9K_MODELSIM_ADDRWIDTH,M4K_ADDRWIDTH} 
	constant G_DATA_WORDSNUM 			: integer := M9K_TCM8KiB_WORDSNUM;	-- options{M9K_MODELSIM_WORDSNUM,M4K_WORDSNUM}
	constant G_PC_WIDTH 				: integer := PC_WIDTH_TCM8KiB;		-- options{PC_WIDTH_TCM1KiB,PC_WIDTH_TCM2KiB,...}
	constant G_MA_WIDTH 				: integer := MA_WIDTH_TCM8KiB;		-- options{MA_WIDTH_TCM1KiB,MA_WIDTH_TCM2KiB,...}
	constant DBUS_WIDTH 				: integer	:= 32;
	constant G_PLL_DIV		 			: NATURAL	:= 2;					-- relavant only when G_MODELSIM=0
	constant G_PLL_MUL		 			: NATURAL	:= 1;					-- relavant only when G_MODELSIM=0

	-- PHASE 14. The default for RV32IMscMCU's GEN_INTERRUPT generic, which
	-- exists for ONE reason: row 1 of §6's three PPA tables.
	--
	-- Each of those tables -- Area, Performance, Power, all three with
	-- "Attaching the print screen ... is mandatory" -- has THREE rows:
	--     1. MCU with GPIO
	--     2. MCU with GPIO and Interrupt Capability
	--     3. Pipelined MCU with GPIO and Interrupt Capability
	-- Row 1 is a build with NO interrupt capability, and the whole point of the
	-- table is the delta between rows 1 and 2: what interrupt capability costs
	-- in logic elements, registers, Fmax and power. Until Phase 14 nothing in
	-- this project could produce row 1.
	--
	-- WHICH PERIPHERALS ROW 1 DROPS is not a judgement call: §5 is titled
	-- "GPIO peripherals ... WITHOUT interrupt capability" and lists eight
	-- (PORT_LEDR, PORT_HEX0..5, PORT_SW); §6 is titled "Peripherals WITH
	-- interrupt capability" and lists twelve addresses -- PORT_PB, the USART's
	-- three, the Basic Timer's five, and IE/IFG/TYPE. So PORT_PB belongs to the
	-- interrupt half, which is easy to get wrong: it is a GPIO-looking input
	-- port sitting in the interrupt clause because the KEYs are an interrupt
	-- source.
	--
	-- TRUE here is the real design and must stay TRUE in the committed tree;
	-- tools/check_config_defaults.py asserts it, so a build left flipped after
	-- a measurement cannot be committed by accident.
	constant G_GEN_INTERRUPT			: boolean	:= True;				-- options{True,False} -- False = PPA row 1
-- Explanation:
-----------------------------------------------------------
--	if G_MODELSIM=1 then 
--		IDE=Modelsim 
--  elsif G_MODELSIM=0 then
--    IDE=Quartus
--------------------------------------------------------
--  if G_WORD_GRANULARITY=True then 
--		Each WORD has a unike address
--	elsif G_WORD_GRANULARITY=False
-- 		Each BYTE has a unike address
--------------------------------------------------------
--  if G_ADDRWIDTH=M9K_MODELSIM_ADDRWIDTH then
--		ITCM_ADDR_WIDTH=DTCM_ADDR_WIDTH=M9K_TCM_ADDR_WIDTH
--	elsif  G_ADDRWIDTH=M4K_ADDRWIDTH then
--		ITCM_ADDR_WIDTH=DTCM_ADDR_WIDTH=M4K_TCM_ADDR_WIDTH
--------------------------------------------------------
--	if G_DATA_WORDSNUM=M9K_MODELSIM_ADDRWIDTH then
--		ITCM_WORDS_NUM=DTCM_WORDS_NUM=M9K_TCM_WORDSNUM
--	elsif  G_DATA_WORDSNUM=M4K_WORDSNUM then
--		ITCM_WORDS_NUM=DTCM_WORDS_NUM=M4K_TCM_WORDSNUM
--===================================================================================================================

end cond_compilation_package;
