---------------------------------------------------------------------------------------------
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- RV32IM-based MCU, single-cycle
--
-- addr_decoder -- the "Optimized Address Decoder" of Figure 5 (p5).
--
-- Splits the 14-bit data address space of §3 into the DTCM and the SFR page,
-- and produces one chip select per memory-mapped I/O word.
---------------------------------------------------------------------------------------------
-- NO DIRECT COURSE REFERENCE FOUND for the code
--   Nothing in the supplied material contains an address decoder -- verified by
--   grep for "chip select", "_cs", "decoder" and "0x2000"/"2000" over every .vhd
--   in Auxiliary/. Neither Lab 5 core has one: RV32IM_CORE.vhd narrows the ALU
--   result straight to the RAM address with a bare bit-slice. So the code here
--   is ours. The *structure* is not: it is transcribed from Figure 5.
--
-- WHY IT IS NEEDED -- the concrete bug it closes
--   RV32IM_CORE.vhd (before Phase 5B) computes
--       dtcm_addr_w <= alu_res_w(MA_WIDTH-1 DOWNTO 2)
--   with MA_WIDTH = 13, so the DTCM word address is alu_res_w(12 DOWNTO 2) and
--   bit 13 -- the one bit that says "SFR, not DTCM" -- is never looked at. The
--   twenty MMIO registers therefore alias onto DTCM words 0..11, and DTCM words
--   0..7 are the interrupt vector table (p14, and confirmed word by word against
--   all four benchmark DTCM images in DOC/02_requirements_traceability.md §4.1):
--
--       MMIO register        aliases to   which holds
--       ------------------   ----------   -------------------------------
--       PORT_LEDR   0x2000   word  0      the RESET vector
--       PORT_HEX0/1 0x2004   word  1      TYPE 04h, UART error vector
--       PORT_HEX2/3 0x2008   word  2      TYPE 08h, UART RX vector
--       PORT_HEX4/5 0x200C   word  3      TYPE 0Ch, UART TX vector
--       PORT_SW     0x2010   word  4      TYPE 10h, Basic Timer vector
--       PORT_PB     0x2014   word  5      TYPE 14h, KEY1 vector
--       UTCL/RX/TX  0x2018   word  6      TYPE 18h, KEY2 vector
--       BTCTL1/2    0x201C   word  7      TYPE 1Ch, KEY3 vector
--       BTCMPR0..   0x2020+  words 8..11  application data
--
--   So it is not a corner case: every one of the eight vectors is aliased by a
--   register the benchmarks actually write, and the interrupt suites write the
--   HEX displays from inside their own handlers.
--
--   That this actually happens, and is not a theoretical worry, is settled by
--   the benchmark sources:
--       Auxiliary/Benchmark Apps/GPIO/test0/asm-code/test0.s:21-28
--           li  t4,PORT_LEDR
--           sw  t0,0(t4)          # write to PORT_LEDR[7-0]
--           ...
--           li  t4,PORT_HEX1      # 0x2005
--           sw  t0,0(t4)          # write to PORT_HEX1
--   Seven such stores per loop iteration, on every iteration.
--
-- TWO THINGS THOSE FOUR LINES ALSO SETTLE -- read before writing any peripheral
--   1. Every MMIO write in every supplied benchmark is a *word* store (sw) to a
--      *byte* address, odd addresses included. Confirmed a second time at
--      Auxiliary/Benchmark Apps/Intrrupt-based IO/test1/asm-code/01_func.s:17-20,
--      where an srli places the value in bits 7..0 and the sw then targets
--      0x2005. So on the I/O side A1..A0 are the *register selector*, not an
--      offset into the data being written, and Figure 5 wires the latch inputs
--      D0..D7 to Data<7..0> unconditionally.
--   2. Therefore the MMIO write path must NOT reuse the lane replication and
--      byteena_a built in Phase 3B (DMEMORY.vhd). Those are right for the DTCM
--      and wrong here. A peripheral takes Data<7..0>; a Word-resolution
--      peripheral takes Data<31..0>.
--   Both points are why this decoder outputs a chip select per *word* and leaves
--   A1..A0 on the address bus for each peripheral to qualify with, exactly as
--   Figure 5 draws it, rather than pre-selecting a byte lane here.
--
-- WHAT FIGURE 5 SPECIFIES, AND WHAT IT DOES NOT
--   Specified, and implemented below:
--     - one decoder driving CS_1..CS_n from the address bus;
--     - registers whose addresses differ only in A0 share one chip select and
--       are separated by A0 at the peripheral;
--     - the qualifier is the whole upper address, drawn as <A13..A4, A3, A2>.
--   Not specified, and therefore not invented here:
--     - the chip-select *numbering*. The figure labels PORT_LEDR CS1, the
--       PORT_HEX0/1 pair CS6 and PORT_SW CS7; no arithmetic relation to the
--       addresses reproduces those three numbers, so they are taken as
--       illustrative. The indices used here are the SFR word offset, which is
--       derivable, self-documenting and needs no lookup -- see const_package.
--
-- WHY THE DECODE IS FULL AND NOT PARTIAL
--   "Optimized" in the figure's label may well mean a partial decode -- ignore
--   the upper address bits and let 0x2040 alias onto 0x2000. This decoder
--   qualifies on A12..A6 = 0 as well, for two reasons:
--     - Figure 2 calls the SFR page "distributed among many I/O devices, NOT
--       ALL USED", so unused addresses exist by design and must not alias onto
--       used ones;
--     - unmapped_o only means something under a full decode, and it is what
--       lets the MCU level warn on a stray access instead of corrupting a
--       peripheral quietly.
--   Cost: a 7-input zero-compare, one or two LUT levels on a Cyclone IV. If
--   Phase 14 finds this decoder on the critical path, dropping A12..A6 from the
--   qualifier is the cheapest thing to give up -- and it costs exactly the
--   aliasing above. Do not drop A13: that is the DTCM/SFR split itself.
--
-- TIMING NOTE
--   This block sits inside the single-cycle critical path
--   ITCM -> decode -> ALU -> DTCM, which the Lab 5 reference measured at
--   Fmax 26.81 MHz against a 25 MHz target. It is combinational and shallow,
--   but it is not free. Flagged for Phase 14 together with the Phase 3B
--   extract-and-extend mux.
---------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
-- numeric_std, not STD_LOGIC_ARITH. Hanan's own VHDL-2008 material calls
-- STD_LOGIC_ARITH / STD_LOGIC_SIGNED / STD_LOGIC_UNSIGNED "non-standard" and
-- points at the numeric_std family instead; the supplied core's reliance on
-- STD_LOGIC_SIGNED is the direct cause of defect 5 (sltu/bltu comparing
-- signed). New files in this project use numeric_std.
USE IEEE.NUMERIC_STD.ALL;
USE work.cond_compilation_package.all;		-- G_DATA_WORDSNUM
USE work.const_package.all;					-- the MMIO map: SFR_CS_NUM, CS_*, SFR_LANE_MASK

ENTITY addr_decoder IS
	generic(
		-- §3: the data address space is the lowest 14 bits, 0...0 A13...A0.
		ADDR_WIDTH		: integer := DATA_ADDR_WIDTH;
		-- Only used by the elaboration-time check below, which proves the DTCM
		-- exactly fills the region that A13 = '0' selects.
		DTCM_WORDS_NUM	: integer := G_DATA_WORDSNUM
	);
	PORT(
		--Inputs
		-- A13..A0. Purely a function of the address: no MemRead/MemWrite here,
		-- because Figure 5 qualifies with those at the peripheral (En = CS.MemWrite
		-- on the latch, and the tri-state buffer on CS.MemRead), not at the decoder.
		-- Keeping this block a pure function of the address is also what makes an
		-- exhaustive testbench meaningful.
		addr_i			: IN	STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);

		--Outputs
		dtcm_cs_o		: OUT	STD_LOGIC;								-- DTCM selected
		sfr_cs_o		: OUT	STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);-- one-hot per SFR word
		unmapped_o		: OUT	STD_LOGIC								-- no register at this byte address
	);
END addr_decoder;


ARCHITECTURE dataflow OF addr_decoder IS
	-- The bits between the region select and the word-group select must all be
	-- zero for the address to be inside the SFR page. Declared as a constant
	-- rather than written as an aggregate on the right of "=", because an
	-- aggregate there depends on the context to supply its index constraint and
	-- tools differ on how they resolve it.
	CONSTANT SFR_PAGE_ZEROS	: STD_LOGIC_VECTOR(ADDR_WIDTH-2 DOWNTO 6) := (OTHERS => '0');

	SIGNAL sfr_page_w		: STD_LOGIC;						-- address is inside 0x2000..0x203F
	SIGNAL lane_mask_w		: STD_LOGIC_VECTOR(3 DOWNTO 0);		-- which lanes of this word are defined
	SIGNAL lane_bit_w		: STD_LOGIC;						-- the addressed lane's bit of that mask
	SIGNAL dtcm_cs_w		: STD_LOGIC;
	SIGNAL sfr_mapped_w		: STD_LOGIC;

BEGIN
	--=====================================================================
	-- Elaboration-time checks. Everything below hardcodes the shape of the
	-- address space, so a configuration change that invalidates it must fail
	-- loudly rather than decode silently wrong. Same approach as the
	-- DATA_BUS_WIDTH assertion in DMEMORY.vhd.
	--=====================================================================
	-- A13 is the region select, A12..A6 the page qualifier, A5..A2 the word
	-- group, A1..A0 the lane. That partition only exists at 14 bits.
	assert ADDR_WIDTH = 14
		report "addr_decoder: the bit partition assumes the 14-bit data address " &
			   "space of the assignment definition clause 3 (0...0 A13...A0)"
		severity failure;

	-- dtcm_cs_o below is just NOT A13, with no comparator against the DTCM size.
	-- That is only correct while the DTCM exactly fills the lower half of the
	-- address space: 2048 words x 4 bytes = 8192 = 2**13. A smaller DTCM would
	-- leave a hole that this decoder would still claim, so it must fail here
	-- instead. The alternative -- a 12-bit magnitude comparator in the
	-- single-cycle critical path -- costs real Fmax for a case the project does
	-- not have.
	assert DTCM_WORDS_NUM * 4 = 2**(ADDR_WIDTH-1)
		report "addr_decoder: the DTCM no longer exactly fills the region A13='0'. " &
			   "dtcm_cs_o is a bare NOT A13 and would claim addresses the DTCM " &
			   "does not implement. Add the size comparator before changing this."
		severity failure;

	--=====================================================================
	-- Region select -- Figure 2 (p4)
	--=====================================================================
	-- Word 0x000..0x7FF (byte 0x0000..0x1FFC) is the DTCM; word 0x800..0xFFF
	-- (byte 0x2000..0x3FFC) is the SFR page. One bit decides.
	dtcm_cs_w	<= NOT addr_i(ADDR_WIDTH-1);
	dtcm_cs_o	<= dtcm_cs_w;

	--=====================================================================
	-- SFR page qualifier -- the <A13..A4> half of Figure 5's decoder input
	--=====================================================================
	sfr_page_w	<= '1' WHEN (addr_i(ADDR_WIDTH-1) = '1' AND
							 addr_i(ADDR_WIDTH-2 DOWNTO 6) = SFR_PAGE_ZEROS)
					   ELSE '0';

	--=====================================================================
	-- Chip selects -- the <A3, A2> half, extended to A5..A2 to cover all
	-- twelve mapped words rather than only the eight GPIO ones the figure draws
	--=====================================================================
	-- One-hot. Groups 12..15 exist in the address space but hold no register, so
	-- they simply produce no chip select. to_unsigned is applied to the generate
	-- index, a compile-time constant, so nothing here converts the address.
	CSGEN:
	for i in 0 to SFR_CS_NUM-1 generate
		sfr_cs_o(i) <= '1' WHEN (sfr_page_w = '1' AND
								 addr_i(5 DOWNTO 2) = STD_LOGIC_VECTOR(to_unsigned(i, 4)))
						   ELSE '0';
	end generate;

	--=====================================================================
	-- Mapped / unmapped
	--=====================================================================
	-- The arms below are the contents of SFR_LANE_MASK in const_package, which
	-- is the specification of which byte lanes hold a register. They are written
	-- out as a selected assignment rather than as SFR_LANE_MASK(to_integer(...))
	-- deliberately: an integer index would put to_integer on the live address,
	-- and at simulation start the ALU result carries 'U', which makes
	-- numeric_std emit a metavalue warning on every delta and buries real
	-- failures in Adar's transcript.
	--
	-- The duplication is not left to trust. tb_addr_decoder.vhd builds its
	-- expected value from SFR_LANE_MASK itself, so if these arms and the package
	-- ever disagree the exhaustive sweep fails on the first address affected.
	with addr_i(5 DOWNTO 2) select lane_mask_w <=
		"0001"	when "0000",	-- CS_LEDR     0x2000
		"0011"	when "0001",	-- CS_HEX01    0x2004 0x2005
		"0011"	when "0010",	-- CS_HEX23    0x2008 0x2009
		"0011"	when "0011",	-- CS_HEX45    0x200C 0x200D
		"0001"	when "0100",	-- CS_SW       0x2010
		"0001"	when "0101",	-- CS_PB       0x2014
		"0111"	when "0110",	-- CS_UART     0x2018 0x2019 0x201A
		"0011"	when "0111",	-- CS_BTCTL    0x201C 0x201D
		"1111"	when "1000",	-- CS_BTCMPR0  0x2020  (Word resolution)
		"1111"	when "1001",	-- CS_BTCMPR1  0x2024  (Word resolution)
		"1111"	when "1010",	-- CS_BTCAPR   0x2028  (Word resolution)
		"0111"	when "1011",	-- CS_INTC     0x202C 0x202D 0x202E
		"0000"	when others;	--             0x2030..0x203F -- nothing defined

	-- Same idiom as the byte-lane select in DMEMORY.vhd:140.
	with addr_i(1 DOWNTO 0) select lane_bit_w <=
		lane_mask_w(0)	when "00",
		lane_mask_w(1)	when "01",
		lane_mask_w(2)	when "10",
		lane_mask_w(3)	when others;

	sfr_mapped_w	<= sfr_page_w AND lane_bit_w;

	-- Note that a chip select can be active while the byte address is unmapped:
	-- address 0x2001 selects the PORT_LEDR word but names a lane no register
	-- occupies. That is Figure 5's own structure -- the CS decodes the word and
	-- the peripheral qualifies the lane -- and it is why the unmapped report is
	-- lane-accurate rather than word-accurate.
	unmapped_o		<= NOT (dtcm_cs_w OR sfr_mapped_w);

END dataflow;
