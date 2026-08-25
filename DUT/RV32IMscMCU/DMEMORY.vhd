---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
--  Dmemory module (implements the DTCM data memory of the RISC-V core)
---------------------------------------------------------------------------------------------
-- PHASE 3B ADDITION (gap G-309): byte enables and sub-word load/store.
--
-- WHAT WAS MISSING
--   The supplied module writes the full 32-bit word on every store and returns
--   the full word on every load. CONTROL detects lb/lh/lbu/lhu/sb/sh and then
--   discards the width, so sb and sh corrupted the three (or two) neighbouring
--   bytes, and lb/lh/lbu/lhu returned the whole word with no lane selection and
--   no extension. The Final Project needs this: its benchmarks address
--   byte-resolution MMIO registers.
--
-- NO DIRECT COURSE REFERENCE FOUND
--   Nothing in the supplied material instantiates altsyncram with byte enables
--   -- verified by grep over every .vhd in the tree; there are 10 altsyncram
--   instantiations and not one uses byteena_a, byte_size or width_byteena_a.
--   The reference *pipeline* does not implement sub-word access either
--   (Auxiliary/Lab 5/PROJECT_EXPLANATION.md §4.4 states this
--   outright). So this is our design, and the three altsyncram identifiers
--   below come from Intel's altsyncram megafunction interface -- general
--   knowledge, NOT from anything supplied in the course.
--
--   >>> ADAR: if vcom or Quartus rejects byte_size / width_byteena_a /
--   >>> byteena_a, the fix is a rename, not a redesign -- open
--   >>> <quartus>/eda/sim_lib/altera_mf_components.vhd, find the altsyncram
--   >>> component declaration, and use the exact spelling it gives. Report what
--   >>> it was. Everything else in this file is plain VHDL.
--
-- WHY NOT READ-MODIFY-WRITE INSTEAD
--   The output is UNREGISTERED, so q_a already carries the addressed word and it
--   is tempting to merge in the new byte and write the whole word back. That
--   creates a combinational path q_a -> data_a -> RAM, i.e. a loop through the
--   memory, and same-address read-during-write on an M9K is undefined in this
--   configuration. byteena_a is the mechanism the hardware provides for exactly
--   this, so it is the one used.
--
-- TIMING RISK, FLAGGED FOR PHASE 14
--   The single-cycle critical path already runs ITCM -> decode -> ALU -> DTCM
--   with the DTCM on the inverted clock, giving Fmax 26.81 MHz against a 25 MHz
--   target -- 1.81 MHz of margin. The extract-and-extend mux below lengthens
--   exactly that path. Expect Fmax to drop; if it drops below 25 MHz the PLL
--   ratio has to change, and that is a Phase 4 decision, not a reason to undo
--   this.
--
-- ALIGNMENT
--   RV32I requires a trap on a misaligned access. This core has no trap
--   mechanism, so the behaviour is defined instead of left implicit: a
--   half-word access uses byte_sel_i(1) only and therefore aligns down. The
--   simulation-only check at the bottom of the architecture reports it, so a
--   benchmark that depends on misaligned access cannot pass quietly.
---------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;
USE work.const_package.all;					-- MEM_B / MEM_H / MEM_W / MEM_BU / MEM_HU

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY dmemory IS
	generic(
		DATA_BUS_WIDTH 	: integer := 32;
		DTCM_ADDR_WIDTH : integer := 8;
		WORDS_NUM 		: integer := 256
	);
	PORT(
		--Inputs
		clk_i			: IN 	STD_LOGIC;
		rst_i			: IN 	STD_LOGIC;
		dtcm_addr_i 	: IN 	STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
		dtcm_data_wr_i 	: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		MemRead_ctrl_i  : IN 	STD_LOGIC;
		MemWrite_ctrl_i : IN 	STD_LOGIC;
		-- Phase 3B (G-309). Defaulted so an instantiation that predates them
		-- still elaborates as a word-only memory.
		MemOp_ctrl_i	: IN 	STD_LOGIC_VECTOR(2 DOWNTO 0) := MEM_W;	-- access width/signedness
		byte_sel_i		: IN 	STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";	-- byte offset inside the word
		-- Phase 5B (G-305): this memory's chip select, from the address decoder.
		-- Defaults to '1' so an instantiation that predates the decoder still
		-- behaves exactly as before -- which is what keeps the Lab 5 baseline
		-- reproducible through a bare-core instantiation.
		dtcm_cs_i		: IN 	STD_LOGIC := '1';						-- address is in the DTCM region

		--Outputs
		dtcm_data_rd_o 	: OUT STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
		-- Phase 5B. The gated write enable, exported for observation only.
		--
		-- WHY A PORT EXISTS PURELY TO BE WATCHED
		--   The Phase 5B fix IS the AND gate below. A testbench that watches the
		--   decoder's chip select instead proves only that the decode is right,
		--   and would still pass if this gate were removed -- which is exactly the
		--   regression the phase exists to prevent. So the thing that has to be
		--   asserted on is the enable itself. It is also what Signal-Tap wants on
		--   the board when a store goes somewhere unexpected: "did the memory
		--   actually take this write".
		dtcm_wren_o		: OUT STD_LOGIC
	);
END dmemory;



ARCHITECTURE behavior OF dmemory IS
	CONSTANT NBYTES		: integer := DATA_BUS_WIDTH/8;		-- 4 lanes on a 32-bit bus

	SIGNAL wrclk_w		: STD_LOGIC;
	SIGNAL wren_w		: STD_LOGIC;									-- Phase 5B: gated write enable
	SIGNAL q_w			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);	-- raw RAM word

	-- store path
	SIGNAL store_sub_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL store_data_w	: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL byteena_sub_w: STD_LOGIC_VECTOR(NBYTES-1 DOWNTO 0);
	SIGNAL byteena_w	: STD_LOGIC_VECTOR(NBYTES-1 DOWNTO 0);

	-- load path
	SIGNAL byte_w		: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL half_w		: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL extend_w		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
	-- The lane literals below are written for a 32-bit bus. Stated as an
	-- assertion rather than a comment so a future width change fails loudly.
	assert DATA_BUS_WIDTH = 32
		report "DMEMORY: the sub-word logic assumes a 32-bit data bus (4 byte lanes)"
		severity failure;

	--=====================================================================
	-- STORE PATH
	--=====================================================================
	-- A sub-word store drives its data on the addressed lane, so the value is
	-- replicated across every lane and byteena decides which one lands. MEM_BU
	-- and MEM_HU are load-only encodings and fall through to the full word.
	with MemOp_ctrl_i select store_sub_w <=
		dtcm_data_wr_i( 7 DOWNTO 0) & dtcm_data_wr_i( 7 DOWNTO 0) &
		dtcm_data_wr_i( 7 DOWNTO 0) & dtcm_data_wr_i( 7 DOWNTO 0)	when MEM_B,
		dtcm_data_wr_i(15 DOWNTO 0) & dtcm_data_wr_i(15 DOWNTO 0)	when MEM_H,
		dtcm_data_wr_i												when others;

	-- One-hot for a byte, half-hot for a half-word, all lanes for a word.
	byteena_sub_w <=	"0001"	WHEN (MemOp_ctrl_i = MEM_B and byte_sel_i = "00")	ELSE
						"0010"	WHEN (MemOp_ctrl_i = MEM_B and byte_sel_i = "01")	ELSE
						"0100"	WHEN (MemOp_ctrl_i = MEM_B and byte_sel_i = "10")	ELSE
						"1000"	WHEN (MemOp_ctrl_i = MEM_B and byte_sel_i = "11")	ELSE
						"0011"	WHEN (MemOp_ctrl_i = MEM_H and byte_sel_i(1) = '0')	ELSE
						"1100"	WHEN (MemOp_ctrl_i = MEM_H and byte_sel_i(1) = '1')	ELSE
						(others => '1');

	--=====================================================================
	-- LOAD PATH
	--=====================================================================
	with byte_sel_i select byte_w <=
		q_w( 7 DOWNTO  0)	when "00",
		q_w(15 DOWNTO  8)	when "01",
		q_w(23 DOWNTO 16)	when "10",
		q_w(31 DOWNTO 24)	when others;

	half_w <= q_w(31 DOWNTO 16) WHEN byte_sel_i(1) = '1' ELSE q_w(15 DOWNTO 0);

	-- Sign- or zero-extend to the full bus. The aggregate-then-concatenate idiom
	-- is the one already used in this project at EXECUTE.vhd:73.
	with MemOp_ctrl_i select extend_w <=
		(23 DOWNTO 0 => byte_w(7))		& byte_w	when MEM_B,
		(23 DOWNTO 0 => '0')			& byte_w	when MEM_BU,
		(15 DOWNTO 0 => half_w(15))		& half_w	when MEM_H,
		(15 DOWNTO 0 => '0')			& half_w	when MEM_HU,
		q_w											when others;

	store_data_w	<= store_sub_w;
	byteena_w		<= byteena_sub_w;
	dtcm_data_rd_o	<= extend_w;

	--=====================================================================
	-- PHASE 5B (G-305): the write enable is gated by the chip select
	--=====================================================================
	-- This one AND gate is the whole fix for the aliasing bug. Without it the
	-- address decoder can be perfectly correct and still change nothing, because
	-- MemWrite reaches wren_a regardless of which region the address named.
	--
	-- The missing region decode is not an ISA defect from Lab 5 -- it is a Final
	-- Project requirement (clause 3 and Figure 2) that LAB5 had no reason to
	-- implement.
	--
	-- Nothing gates the READ side. An altsyncram read is unconditional and
	-- harmless: q_a always presents the addressed word, and RV32IM_CORE selects
	-- between it and the peripheral read data with the same chip select. Adding
	-- a read enable here would only add logic to the critical path.
	wren_w      <= MemWrite_ctrl_i AND dtcm_cs_i;
	dtcm_wren_o <= wren_w;

	--=====================================================================
	data_memory : altsyncram
	GENERIC MAP  (
		operation_mode			=> "SINGLE_PORT",
		width_a					=> DATA_BUS_WIDTH,
		widthad_a				=> DTCM_ADDR_WIDTH,
		numwords_a 				=> WORDS_NUM,
		byte_size				=> 8,			-- Phase 3B: one enable per 8 bits
		width_byteena_a			=> NBYTES,		-- Phase 3B: 4 lanes on a 32-bit word
		-- DO NOT REMOVE OR RENAME EITHER HALF OF THIS HINT.
		--   ENABLE_RUNTIME_MOD = YES is what exposes this memory to Quartus's
		--   In-System Memory Content Editor, and ISMCE is how the design is
		--   validated on the board: load the .sof once, then per application
		--   import ITCM.hex and DTCM.hex into the physical memories, press KEY0
		--   to run, export the physical DTCM, and TextDiff it against the RARS
		--   golden. Source: Auxiliary/hanan/Validation using ISMCE.md, and the
		--   assignment requires it (§8).
		--   INSTANCE_NAME = DTCM is the name the editor lists it under.
		--
		-- >>> ADAR, ONE CHECK AFTER THE FIRST QUARTUS COMPILE OF PHASE 3B:
		-- >>> open ISMCE and confirm the DTCM instance still appears and can
		-- >>> still be read and written. byteena_a was added to this same
		-- >>> instantiation, and whether byte-enable mode and runtime
		-- >>> modification coexist cleanly is the one thing here that could not
		-- >>> be verified without the tool. If ISMCE loses the instance, say so
		-- >>> before changing anything: sub-word MMIO access and ISMCE
		-- >>> validation are both mandatory, so a conflict between them is a
		-- >>> question for Hanan, not something to quietly work around.
		lpm_hint 				=> "ENABLE_RUNTIME_MOD = YES,INSTANCE_NAME = DTCM",
		lpm_type 				=> "altsyncram",
		outdata_reg_a 			=> "UNREGISTERED",
		init_file 				=> "C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex",
		intended_device_family 	=> "Cyclone"
	)
	PORT MAP (
		wren_a 					=> wren_w,			-- Phase 5B: MemWrite AND dtcm_cs_i
		clock0					=> wrclk_w,
		address_a				=> dtcm_addr_i,
		data_a					=> store_data_w,
		byteena_a				=> byteena_w,
		q_a						=> q_w
	);

	wrclk_w <= NOT clk_i;	-- Load memory address register with write clock

	--=====================================================================
	-- Simulation-only alignment check. Expected never to fire: every supplied
	-- benchmark is word-aligned, and the directed ISA suite addresses its
	-- half-words at offsets 0 and 2 on purpose.
	--=====================================================================
	-- Phase 5B added dtcm_cs_i to the condition: this memory should only comment
	-- on accesses actually aimed at it. An odd byte address in the SFR page is
	-- normal there -- PORT_HEX1 is at 0x2005 -- and is the peripheral's business.
	misalign_check : process(all)
	begin
		if dtcm_cs_i = '1'
		   and (MemRead_ctrl_i = '1' or MemWrite_ctrl_i = '1')
		   and (MemOp_ctrl_i = MEM_H or MemOp_ctrl_i = MEM_HU)
		   and byte_sel_i(0) = '1' then
			report "DMEMORY: misaligned half-word access at byte offset " &
				integer'image(CONV_INTEGER(byte_sel_i)) &
				" - aligned down to the even offset. RV32I would trap here."
				severity warning;
		end if;
	end process misalign_check;

END behavior;
