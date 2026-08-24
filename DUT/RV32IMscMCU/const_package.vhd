---------------------------------------------------------------------------------------------
-- Copyright 2025 Hananya Ribo 
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
---------------------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;

package const_package is
--------------------------------------------------------------------
--	VECTOR EXTENTIONS constants
--------------------------------------------------------------------
	constant ZEROS_IMM12	:	STD_LOGIC_VECTOR(11 DOWNTO 0) := 12x"000";
	constant ZEROS_IMM20	:	STD_LOGIC_VECTOR(19 DOWNTO 0) := 20x"00000";
	constant ONES_IMM12		:	STD_LOGIC_VECTOR(11 DOWNTO 0) := 12x"FFF";
	constant ONES_IMM20		:	STD_LOGIC_VECTOR(19 DOWNTO 0) := 20x"FFFFF";
	
	constant ZEROS_DBUS2PCADDR	:	STD_LOGIC_VECTOR(DBUS_WIDTH-G_PC_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	
--------------------------------------------------------------------
--	IDECODE constants
--------------------------------------------------------------------
	constant RTYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110011";
	constant ITYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010011";
	constant STYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100011";
	constant SBTYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "1100011";
	constant UTYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010111" and "0110111";	--Upper immediate
	constant UJTYPE_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "1101111";
-- Three opcode constants the single-cycle const_package never declared. Values and names
-- taken verbatim from the pipelined core of the same LAB5 submission, which needs them for
-- the same three selected-assignment arms:
--   Auxiliary/Lab 5/DUT/RV32IM_pipeline/const_package.vhd:25,28,29
-- UTYPE_OPC above is kept because CONTROL.vhd:51 still uses it, where the bitwise AND
-- happens to give the correct answer for both lui and auipc; only IDECODE's exact-match
-- select was broken by it (defect 2).
	constant LOAD_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0000011";	--lb/lh/lw/lbu/lhu
	constant AUIPC_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010111";	--auipc
	constant LUI_OPC	:	STD_LOGIC_VECTOR(6 DOWNTO 0) := "0110111";	--lui
--------------------------------------------------------------------
--	Memory access width and signedness (Phase 3B, gap G-309)
--------------------------------------------------------------------
-- These are the RISC-V funct3 encodings of the load and store instructions,
-- not an encoding of ours: RV32I load funct3 is 000=lb 001=lh 010=lw 100=lbu
-- 101=lhu, and store funct3 is 000=sb 001=sh 010=sw. Source:
--   Auxiliary/Lab 5/Auxilary/RV32I - Instruction Formats.pdf
--   Auxiliary/Lab 5/Auxilary/RISC-V Instruction Set Manual (Unprivileged ISA).pdf
-- CONTROL builds the code from its own mask detectors rather than slicing
-- instruction(14 DOWNTO 12), so an encoding RV32I does not define (011/110/111,
-- and RV64's lwu) resolves to MEM_W instead of to an undefined width.
	constant MEM_B		:	STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";		--lb  / sb
	constant MEM_H		:	STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";		--lh  / sh
	constant MEM_W		:	STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";		--lw  / sw
	constant MEM_BU		:	STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";		--lbu
	constant MEM_HU		:	STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";		--lhu
--------------------------------------------------------------------
--	Memory-mapped I/O map (Phase 5, gap G-305)
--------------------------------------------------------------------
-- SOURCE OF EVERY VALUE BELOW
--   Auxiliary/Benchmark Apps/*/asm-code/io_map.s -- all four copies of that
--   file define the same twenty addresses; they differ only in the mask
--   constants appended after line 31, verified by diff. Cross-checked against
--   Auxiliary/Final Project 2026 definition.pdf p5 (§5, eight GPIO registers)
--   and p6 (§6, twelve interrupt-capable registers).
--
-- STRUCTURE THE ADDRESSES THEMSELVES REVEAL
--   The twenty registers occupy exactly twelve consecutive 32-bit words at the
--   bottom of the SFR page, and no register straddles a word boundary:
--
--     word  byte address(es)        register(s)                  mapped lanes
--     ----  ---------------------   --------------------------   ------------
--       0   0x2000                  PORT_LEDR                    0
--       1   0x2004 0x2005           PORT_HEX0  PORT_HEX1         0 1
--       2   0x2008 0x2009           PORT_HEX2  PORT_HEX3         0 1
--       3   0x200C 0x200D           PORT_HEX4  PORT_HEX5         0 1
--       4   0x2010                  PORT_SW                      0
--       5   0x2014                  PORT_PB                      0
--       6   0x2018 0x2019 0x201A    UTCL  RXBUF  TXBUF           0 1 2
--       7   0x201C 0x201D           BTCTL1  BTCTL2               0 1
--       8   0x2020                  BTCMPR0   (Word resolution)  0 1 2 3
--       9   0x2024                  BTCMPR1   (Word resolution)  0 1 2 3
--      10   0x2028                  BTCAPR    (Word resolution)  0 1 2 3
--      11   0x202C 0x202D 0x202E    IE  IFG  TYPE                0 1 2
--
--   That is precisely the structure Figure 5 (p5) draws: one chip select per
--   word, with A0 separating the two registers that share it -- PORT_HEX0 on
--   /A0 and PORT_HEX1 on A0, both on one CS. Two words carry three registers,
--   so A1 joins A0 as the lane selector there.
--
--   The useful consequence: the chip-select index IS the word offset inside the
--   SFR page, i.e. addr(5 DOWNTO 2). ADDR_DECODER.vhd needs no lookup table to
--   produce the one-hot -- see the header of that file.
--
--   The three Word-resolution registers claim all four lanes, because the whole
--   32-bit word belongs to them. The byte registers claim only the lanes their
--   own addresses name; the remaining lanes of those words are undefined and
--   ADDR_DECODER reports them as unmapped.
--
-- NAMING DEVIATION, STATED OPENLY
--   Figure 5 labels its chip selects CS1, CS6 and CS7 for PORT_LEDR, the
--   PORT_HEX0/PORT_HEX1 pair and PORT_SW respectively. Those three numbers fit
--   no arithmetic relation to the addresses that could be derived, so the
--   figure's numbering is treated as illustrative and the constants below are
--   named after the registers instead. The figure's *structure* is unchanged.
--
-- WHAT IS DELIBERATELY NOT HERE
--   Bit-field layouts (BTCTL1, BTCTL2, IE, IFG, TYPE, UCTL) are recorded in
--   DOC/02_requirements_traceability.md and belong to the phases that implement
--   those peripherals. This section is the address map only.
	constant DATA_ADDR_WIDTH	:	integer := 14;	-- §3: "the lowest 14-bit address 0...0 A13...A0"
	constant SFR_CS_NUM			:	integer := 12;	-- one chip select per mapped SFR word

-- Chip-select indices == the word offset inside the SFR page == addr(5 DOWNTO 2).
	constant CS_LEDR			:	integer := 0;	-- 0x2000
	constant CS_HEX01			:	integer := 1;	-- 0x2004 0x2005
	constant CS_HEX23			:	integer := 2;	-- 0x2008 0x2009
	constant CS_HEX45			:	integer := 3;	-- 0x200C 0x200D
	constant CS_SW				:	integer := 4;	-- 0x2010
	constant CS_PB				:	integer := 5;	-- 0x2014
	constant CS_UART			:	integer := 6;	-- 0x2018 0x2019 0x201A
	constant CS_BTCTL			:	integer := 7;	-- 0x201C 0x201D
	constant CS_BTCMPR0			:	integer := 8;	-- 0x2020
	constant CS_BTCMPR1			:	integer := 9;	-- 0x2024
	constant CS_BTCAPR			:	integer := 10;	-- 0x2028
	constant CS_INTC			:	integer := 11;	-- 0x202C 0x202D 0x202E

-- Which byte lanes of each SFR word carry a defined register: bit i of the mask
-- is lane i, i.e. byte address (word*4 + i). Indexed by addr(5 DOWNTO 2) over
-- its full 0..15 range, not 0..SFR_CS_NUM-1, so the upper quarter of the page
-- has an entry too and reads as "nothing defined" instead of being absent.
--
-- This array is the *specification* of the map, in one place. ADDR_DECODER.vhd
-- does not index it -- it writes the same twelve values out as a selected
-- assignment, to keep to_integer off the live address bus -- and
-- tb_addr_decoder.vhd builds its expected result from this array, so the two
-- are proved to agree on all 16384 addresses rather than trusted to.
--
-- A TYPE declaration needs no package body; only FUNCTION or PROCEDURE would
-- (Auxiliary/hanan/Package (sub-library).md).
	type sfr_lane_mask_t is array (0 TO 15) of STD_LOGIC_VECTOR(3 DOWNTO 0);

	constant SFR_LANE_MASK	:	sfr_lane_mask_t := (
		CS_LEDR		=> "0001",		-- 0x2000
		CS_HEX01	=> "0011",		-- 0x2004 0x2005
		CS_HEX23	=> "0011",		-- 0x2008 0x2009
		CS_HEX45	=> "0011",		-- 0x200C 0x200D
		CS_SW		=> "0001",		-- 0x2010
		CS_PB		=> "0001",		-- 0x2014
		CS_UART		=> "0111",		-- 0x2018 0x2019 0x201A
		CS_BTCTL	=> "0011",		-- 0x201C 0x201D
		CS_BTCMPR0	=> "1111",		-- 0x2020 -- Word resolution
		CS_BTCMPR1	=> "1111",		-- 0x2024 -- Word resolution
		CS_BTCAPR	=> "1111",		-- 0x2028 -- Word resolution
		CS_INTC		=> "0111",		-- 0x202C 0x202D 0x202E
		OTHERS		=> "0000"		-- 0x2030..0x203F -- no register defined
	);
--------------------------------------------------------------------
-- ALU Operations
--------------------------------------------------------------------
	constant ALU_NONE						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00000";
	constant ALU_SHIFTL						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00001";
	constant ALU_SHIFTR						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00010";
	constant ALU_SHIFTR_ARITH				:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00011";
	constant ALU_ADD						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00100";
	constant ALU_SUB						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00110";
	constant ALU_AND						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"00111";
	constant ALU_OR							:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"01000";
	constant ALU_XOR						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"01001";
	constant ALU_LESS_THAN_UNSIGNED			:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"01010";
	constant ALU_LESS_THAN_SIGNED			:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"01011";
	constant ALU_MUL						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"01100";
	
	constant ALU_BEQ						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10001";
	constant ALU_BNE						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10010";
	constant ALU_BLT						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10011";
	constant ALU_BGE						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10100";
	constant ALU_BLTU						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10101";
	constant ALU_BGEU						:	STD_LOGIC_VECTOR(4 DOWNTO 0) :=	"10110";

--------------------------------------------------------------------
-- Instructions Masks
--------------------------------------------------------------------	
-- andi
 constant INST_ANDI				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7013";
 constant INST_ANDI_MASK		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- addi
 constant INST_ADDI				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"13";
 constant INST_ADDI_MASK		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- slti
 constant INST_SLTI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2013";
 constant INST_SLTI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- sltiu
 constant INST_SLTIU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"3013";
 constant INST_SLTIU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- ori
 constant INST_ORI 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6013";
 constant INST_ORI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- xori
 constant INST_XORI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"4013";
 constant INST_XORI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- slli
 constant INST_SLLI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1013";
 constant INST_SLLI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fc00707f";

-- srli
 constant INST_SRLI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"5013";
 constant INST_SRLI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fc00707f";

-- srai
 constant INST_SRAI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"40005013";
 constant INST_SRAI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fc00707f";

-- lui
 constant INST_LUI 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"37";
 constant INST_LUI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7f";

-- auipc
 constant INST_AUIPC 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"17";
 constant INST_AUIPC_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7f";

-- add
 constant INST_ADD 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"33";
 constant INST_ADD_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- sub
 constant INST_SUB 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"40000033";
 constant INST_SUB_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- slt
 constant INST_SLT 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2033";
 constant INST_SLT_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- sltu
 constant INST_SLTU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"3033";
 constant INST_SLTU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- xor
 constant INST_XOR 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"4033";
 constant INST_XOR_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- or
 constant INST_OR 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6033";
 constant INST_OR_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- and
 constant INST_AND 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7033";
 constant INST_AND_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- sll
 constant INST_SLL 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1033";
 constant INST_SLL_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- srl
 constant INST_SRL 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"5033";
 constant INST_SRL_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- sra
 constant INST_SRA 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"40005033";
 constant INST_SRA_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- jal
 constant INST_JAL 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6f";
 constant INST_JAL_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7f";

-- jalr
 constant INST_JALR 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"67";
 constant INST_JALR_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- beq
 constant INST_BEQ 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"63";
 constant INST_BEQ_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- bne
 constant INST_BNE 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1063";
 constant INST_BNE_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- blt
 constant INST_BLT 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"4063";
 constant INST_BLT_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- bge
 constant INST_BGE 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"5063";
 constant INST_BGE_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- bltu
 constant INST_BLTU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6063";
 constant INST_BLTU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- bgeu
 constant INST_BGEU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7063";
 constant INST_BGEU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lb
 constant INST_LB 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"3";
 constant INST_LB_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lh
 constant INST_LH 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1003";
 constant INST_LH_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lw
 constant INST_LW 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2003";
 constant INST_LW_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lbu
 constant INST_LBU 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"4003";
 constant INST_LBU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lhu
 constant INST_LHU 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"5003";
 constant INST_LHU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- lwu
 constant INST_LWU 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6003";
 constant INST_LWU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- sb
 constant INST_SB 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"23";
 constant INST_SB_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- sh
 constant INST_SH 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1023";
 constant INST_SH_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- sw
 constant INST_SW 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2023";
 constant INST_SW_MASK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- ecall
 constant INST_ECALL 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"73";
 constant INST_ECALL_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"ffffffff";

-- ebreak
 constant INST_EBREAK 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"100073";
 constant INST_EBREAK_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"ffffffff";

-- eret
 constant INST_ERET 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"200073";
 constant INST_ERET_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"cfffffff";

-- csrrw
 constant INST_CSRRW 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"1073";
 constant INST_CSRRW_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- csrrs
 constant INST_CSRRS 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2073";
 constant INST_CSRRS_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- csrrc
 constant INST_CSRRC 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"3073";
 constant INST_CSRRC_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- csrrwi
 constant INST_CSRRWI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"5073";
 constant INST_CSRRWI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- csrrsi
 constant INST_CSRRSI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"6073";
 constant INST_CSRRSI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- csrrci
 constant INST_CSRRCI 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"7073";
 constant INST_CSRRCI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- mul
 constant INST_MUL 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2000033";
 constant INST_MUL_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- mulh
 constant INST_MULH 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2001033";
 constant INST_MULH_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- mulhsu
 constant INST_MULHSU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2002033";
 constant INST_MULHSU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- mulhu
 constant INST_MULHU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2003033";
 constant INST_MULHU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- div
 constant INST_DIV 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2004033";
 constant INST_DIV_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- divu
 constant INST_DIVU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2005033";
 constant INST_DIVU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- rem
 constant INST_REM 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2006033";
 constant INST_REM_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- remu
 constant INST_REMU 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"2007033";
 constant INST_REMU_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe00707f";

-- wfi
 constant INST_WFI 				:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"10500073";
 constant INST_WFI_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"ffff8fff";

-- fence
 constant INST_FENCE 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"f";
 constant INST_FENCE_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

-- sfence
 constant INST_SFENCE 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"12000073";
 constant INST_SFENCE_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"fe007fff";

-- fence.i
 constant INST_IFENCE 			:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"100f";
 constant INST_IFENCE_MASK 		:	STD_LOGIC_VECTOR(31 DOWNTO 0) := 32x"707f";

----------------------------------------------------------------------------------	
end const_package;

