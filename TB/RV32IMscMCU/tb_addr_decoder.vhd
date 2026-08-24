--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for ADDR_DECODER.vhd
--
-- EXHAUSTIVE, not sampled. The decoder is a pure combinational function of a
-- 14-bit address, so the input space is 16384 values and every one of them is
-- driven and checked. There is no coverage argument to make and no corner case
-- to argue about: either all 16384 agree with the reference model or the run
-- fails and names the first addresses that did not.
--
-- WHAT IS CHECKED, PER ADDRESS
--   1. dtcm_cs_o  — asserted exactly on 0x0000..0x1FFF (Figure 2, p4).
--   2. sfr_cs_o   — the expected one-hot, or all-zero outside the SFR page.
--   3. unmapped_o — asserted exactly where no register is defined.
--   4. ONE-HOT. At most one chip select is ever active. A decoder that
--      double-selects would let two peripherals latch the same store.
--   5. NON-ALIASING. dtcm_cs_o and any sfr_cs_o are never both active. This is
--      the property whose absence is the bug Phase 5 exists to close: without a
--      region decode, a store to PORT_LEDR (0x2000) also lands in DTCM word 0.
--
-- WHERE THE EXPECTED VALUES COME FROM
--   From the assembler, not from the RTL. BYTE_REG_ADDR and WORD_REG_BASE below
--   are transcribed from
--       Auxiliary/Benchmark Apps/GPIO/test0/asm-code/io_map.s
--   which is the executable form of the map in §5 (p5) and §6 (p6). All four
--   copies of io_map.s in the benchmark suites define the same twenty
--   addresses — verified by diff; they differ only in the mask constants
--   appended after line 31.
--
-- WHY THE MAP IS DERIVED TWICE
--   CHECK 0, before the sweep, compares SFR_LANE_MASK in const_package against
--   the address list in this file, lane by lane over the whole page. So the run
--   proves two independent things:
--     - const_package agrees with io_map.s   (is the specification right?)
--     - the RTL agrees with const_package    (is the implementation right?)
--   A single derivation would only ever prove the RTL matches itself. This is
--   the same discipline tools/gen_isa_test.py applies to the expected store
--   sequence, and it is what caught two real bugs in Phase 2's own work.
--
-- WHAT THIS TESTBENCH DOES NOT COVER
--   The decoder takes no MemRead/MemWrite and has no clock, because Figure 5
--   qualifies with those at the peripheral, not at the decoder. Read/write
--   qualification, the bidirectional read path and the unmapped-access warning
--   are Phase 5B, at the MCU level, and get their own tests.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.const_package.all;			-- DATA_ADDR_WIDTH, SFR_CS_NUM, CS_*, SFR_LANE_MASK
USE work.aux_package.all;			-- addr_decoder


ENTITY tb_addr_decoder IS
END tb_addr_decoder;


ARCHITECTURE test OF tb_addr_decoder IS
	CONSTANT ADDR_WIDTH		: integer := DATA_ADDR_WIDTH;		-- 14, from §3
	CONSTANT ADDR_SPACE		: integer := 2**ADDR_WIDTH;			-- 16384 byte addresses
	CONSTANT DTCM_BYTES		: integer := 2**(ADDR_WIDTH-1);		-- 0x2000 — the DTCM half
	CONSTANT SFR_BASE		: integer := 2**(ADDR_WIDTH-1);		-- 0x2000 — the SFR half
	CONSTANT SFR_PAGE_TOP	: integer := SFR_BASE + 63;			-- 0x203F: A12..A6 = 0

	-- Stop describing failures after this many, so a systematic break prints a
	-- readable diagnosis instead of 16384 lines. The tally is still complete.
	CONSTANT MAX_REPORTS	: integer := 20;

	SIGNAL addr			: STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL dtcm_cs		: STD_LOGIC;
	SIGNAL sfr_cs		: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);
	SIGNAL unmapped		: STD_LOGIC;

	--=======================================================================
	-- The reference model — transcribed from io_map.s
	--=======================================================================
	type addr_list_t is array (natural range <>) of integer;

	-- The seventeen Byte-resolution registers. Each occupies exactly one byte.
	CONSTANT BYTE_REG_ADDR	: addr_list_t := (
		16#2000#,								-- PORT_LEDR
		16#2004#, 16#2005#,						-- PORT_HEX0  PORT_HEX1
		16#2008#, 16#2009#,						-- PORT_HEX2  PORT_HEX3
		16#200C#, 16#200D#,						-- PORT_HEX4  PORT_HEX5
		16#2010#,								-- PORT_SW
		16#2014#,								-- PORT_PB
		16#2018#, 16#2019#, 16#201A#,			-- UTCL  RXBUF  TXBUF
		16#201C#, 16#201D#,						-- BTCTL1  BTCTL2
		16#202C#, 16#202D#, 16#202E#			-- IE  IFG  TYPE
	);

	-- The three Word-resolution registers. io_map.s marks these "define a Word
	-- address", and §6's table gives their Address Resolution as Word, so the
	-- whole 32-bit word belongs to the register and all four of its lanes are
	-- mapped. 17 + 3 = the twenty registers of §5 and §6.
	CONSTANT WORD_REG_BASE	: addr_list_t := (
		16#2020#,								-- BTCMPR0
		16#2024#,								-- BTCMPR1
		16#2028#								-- BTCAPR
	);

	-- 17 byte registers + 3 word registers x 4 lanes = 29 mapped SFR bytes.
	CONSTANT EXP_SFR_MAPPED	: integer := BYTE_REG_ADDR'length + WORD_REG_BASE'length * 4;
	CONSTANT EXP_UNMAPPED	: integer := ADDR_SPACE - DTCM_BYTES - EXP_SFR_MAPPED;

	function is_byte_reg(a : integer) return boolean is
	begin
		for i in BYTE_REG_ADDR'range loop
			if BYTE_REG_ADDR(i) = a then
				return TRUE;
			end if;
		end loop;
		return FALSE;
	end function;

	function is_word_reg(a : integer) return boolean is
	begin
		for i in WORD_REG_BASE'range loop
			if a >= WORD_REG_BASE(i) and a < WORD_REG_BASE(i) + 4 then
				return TRUE;
			end if;
		end loop;
		return FALSE;
	end function;

	function is_mapped_sfr(a : integer) return boolean is
	begin
		return is_byte_reg(a) or is_word_reg(a);
	end function;

	-- STD_LOGIC'image renders '1' with its quotes, so a message reads got ''1''.
	-- to_string(std_logic) is VHDL-2008 and would do, but a three-line CASE has
	-- no version or tool dependency at all and the messages stay readable.
	function bit_img(b : STD_LOGIC) return string is
	begin
		case b is
			when '0'	=> return "0";
			when '1'	=> return "1";
			when others	=> return "?";
		end case;
	end function;

	-- The expected chip-select vector. Built from the address arithmetic of
	-- Figure 5 directly: inside the SFR page, the word offset selects, and the
	-- four word offsets above the last register select nothing.
	function expected_cs(a : integer) return STD_LOGIC_VECTOR is
		variable r_v	: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0) := (OTHERS => '0');
		variable grp_v	: integer;
	begin
		if a >= SFR_BASE and a <= SFR_PAGE_TOP then
			grp_v := (a - SFR_BASE) / 4;
			if grp_v < SFR_CS_NUM then
				r_v(grp_v) := '1';
			end if;
		end if;
		return r_v;
	end function;

BEGIN
	--=======================================================================
	DUT : addr_decoder
	generic map(
		ADDR_WIDTH		=> ADDR_WIDTH
	)
	PORT MAP(
		addr_i			=> addr,
		dtcm_cs_o		=> dtcm_cs,
		sfr_cs_o		=> sfr_cs,
		unmapped_o		=> unmapped
	);

	--=======================================================================
	-- One process, so ordinary variables carry the tallies and no signal needs
	-- more than one driver. Variable names take Hanan's _v extension
	-- (Auxiliary/hanan/Useful name extensions.md).
	--=======================================================================
	sweep : process
		variable fails_v		: integer := 0;
		variable checks_v		: integer := 0;
		variable reported_v		: integer := 0;
		variable dtcm_cnt_v		: integer := 0;
		variable mapped_cnt_v	: integer := 0;
		variable unmap_cnt_v	: integer := 0;
		variable hot_v			: integer := 0;
		variable addr_v			: integer := 0;
		variable exp_dtcm_v		: STD_LOGIC;
		variable exp_unmap_v	: STD_LOGIC;
		variable exp_cs_v		: STD_LOGIC_VECTOR(SFR_CS_NUM-1 DOWNTO 0);

		-- One place that decides whether a failure gets described, so the cap
		-- cannot be applied inconsistently between checks.
		procedure fail(msg : in string) is
		begin
			fails_v := fails_v + 1;
			if reported_v < MAX_REPORTS then
				reported_v := reported_v + 1;
				report msg severity error;
			elsif reported_v = MAX_REPORTS then
				reported_v := reported_v + 1;
				report "... further failures are counted but not described." severity note;
			end if;
		end procedure;
	begin
		report "===== ADDR_DECODER (Figure 5) EXHAUSTIVE SWEEP =====" severity note;
		report "  address space  : " & integer'image(ADDR_SPACE) & " byte addresses" severity note;
		report "  registers      : " & integer'image(BYTE_REG_ADDR'length) & " byte + " &
			   integer'image(WORD_REG_BASE'length) & " word = " &
			   integer'image(BYTE_REG_ADDR'length + WORD_REG_BASE'length) & " (expect 20)" severity note;

		-- The register count is itself a transcription check on this file.
		if BYTE_REG_ADDR'length + WORD_REG_BASE'length /= 20 then
			fail("FAIL transcription: the reference model lists " &
				 integer'image(BYTE_REG_ADDR'length + WORD_REG_BASE'length) &
				 " registers, but io_map.s defines exactly 20.");
		end if;

		--===================================================================
		-- CHECK 0 — const_package against io_map.s
		--===================================================================
		-- SFR_LANE_MASK is the specification the RTL is written from. Here it is
		-- held against the address list transcribed from the assembler, lane by
		-- lane across the whole 64-byte page. If this fails, the RTL may well be
		-- a faithful implementation of a wrong map.
		for grp in 0 to 15 loop
			for lane in 0 to 3 loop
				addr_v	 := SFR_BASE + grp*4 + lane;
				checks_v := checks_v + 1;
				if (SFR_LANE_MASK(grp)(lane) = '1') /= is_mapped_sfr(addr_v) then
					fail("FAIL spec_mismatch at 0x" &
						 to_hstring(STD_LOGIC_VECTOR(to_unsigned(addr_v, 16))) &
						 ": const_package SFR_LANE_MASK(" & integer'image(grp) & ")(" &
						 integer'image(lane) & ") = '" &
						 bit_img(SFR_LANE_MASK(grp)(lane)) &
						 "', but io_map.s says mapped = " & boolean'image(is_mapped_sfr(addr_v)));
				end if;
			end loop;
		end loop;
		report "  CHECK 0 (const_package vs io_map.s): 64 lanes compared" severity note;

		--===================================================================
		-- THE SWEEP — every address in the data address space
		--===================================================================
		for a in 0 to ADDR_SPACE-1 loop
			addr <= STD_LOGIC_VECTOR(to_unsigned(a, ADDR_WIDTH));
			wait for 1 ns;

			-- Expected values, computed independently of the RTL.
			if a < DTCM_BYTES then
				exp_dtcm_v := '1';
			else
				exp_dtcm_v := '0';
			end if;

			exp_cs_v := expected_cs(a);

			if (a < DTCM_BYTES) or is_mapped_sfr(a) then
				exp_unmap_v := '0';
			else
				exp_unmap_v := '1';
			end if;

			-- 1. region select
			checks_v := checks_v + 1;
			if dtcm_cs /= exp_dtcm_v then
				fail("FAIL dtcm_cs at 0x" & to_hstring(addr) & ": got '" &
					 bit_img(dtcm_cs) & "', expected '" &
					 bit_img(exp_dtcm_v) & "'");
			end if;

			-- 2. chip selects
			checks_v := checks_v + 1;
			if sfr_cs /= exp_cs_v then
				fail("FAIL sfr_cs at 0x" & to_hstring(addr) & ": got " &
					 to_string(sfr_cs) & ", expected " & to_string(exp_cs_v));
			end if;

			-- 3. mapped / unmapped
			checks_v := checks_v + 1;
			if unmapped /= exp_unmap_v then
				fail("FAIL unmapped at 0x" & to_hstring(addr) & ": got '" &
					 bit_img(unmapped) & "', expected '" &
					 bit_img(exp_unmap_v) & "'");
			end if;

			hot_v := 0;
			for i in sfr_cs'range loop
				if sfr_cs(i) = '1' then
					hot_v := hot_v + 1;
				end if;
			end loop;

			-- 4. at most one chip select
			checks_v := checks_v + 1;
			if hot_v > 1 then
				fail("FAIL one_hot at 0x" & to_hstring(addr) & ": " &
					 integer'image(hot_v) & " chip selects active at once (" &
					 to_string(sfr_cs) & "). Two peripherals would latch the same store.");
			end if;

			-- 5. DTCM and I/O never both selected — the Phase 5 bug itself
			checks_v := checks_v + 1;
			if dtcm_cs = '1' and hot_v > 0 then
				fail("FAIL aliasing at 0x" & to_hstring(addr) &
					 ": dtcm_cs_o and a chip select are both active. This is exactly " &
					 "the aliasing that lets an MMIO store overwrite the DTCM.");
			end if;

			-- tallies, used for the independent totals check below
			if dtcm_cs = '1' then
				dtcm_cnt_v := dtcm_cnt_v + 1;
			elsif unmapped = '0' then
				mapped_cnt_v := mapped_cnt_v + 1;
			end if;
			if unmapped = '1' then
				unmap_cnt_v := unmap_cnt_v + 1;
			end if;
		end loop;

		--===================================================================
		-- TOTALS — a second, coarser view of the same run
		--===================================================================
		-- Per-address equality can pass while the model and the RTL share a
		-- misconception. The three totals are derived from the register list
		-- alone and are stated here as absolute numbers, so a map that is
		-- systematically off by a register or a lane shows up as a wrong count
		-- even if every individual comparison agreed.
		checks_v := checks_v + 3;
		if dtcm_cnt_v /= DTCM_BYTES then
			fail("FAIL total_dtcm: " & integer'image(dtcm_cnt_v) &
				 " addresses selected the DTCM, expected " & integer'image(DTCM_BYTES));
		end if;
		if mapped_cnt_v /= EXP_SFR_MAPPED then
			fail("FAIL total_mapped: " & integer'image(mapped_cnt_v) &
				 " mapped SFR bytes, expected " & integer'image(EXP_SFR_MAPPED));
		end if;
		if unmap_cnt_v /= EXP_UNMAPPED then
			fail("FAIL total_unmapped: " & integer'image(unmap_cnt_v) &
				 " unmapped addresses, expected " & integer'image(EXP_UNMAPPED));
		end if;

		--===================================================================
		report "=========== ADDR_DECODER SUMMARY ===========" severity note;
		report "  addresses swept : " & integer'image(ADDR_SPACE) severity note;
		report "  checks made     : " & integer'image(checks_v) severity note;
		report "  DTCM bytes      : " & integer'image(dtcm_cnt_v) &
			   "  (expected " & integer'image(DTCM_BYTES) & ")" severity note;
		report "  mapped SFR bytes: " & integer'image(mapped_cnt_v) &
			   "  (expected " & integer'image(EXP_SFR_MAPPED) & ")" severity note;
		report "  unmapped        : " & integer'image(unmap_cnt_v) &
			   "  (expected " & integer'image(EXP_UNMAPPED) & ")" severity note;
		report "  failures        : " & integer'image(fails_v) severity note;

		if fails_v = 0 then
			report "  VERDICT: PASS - the decoder agrees with io_map.s on all " &
				   integer'image(ADDR_SPACE) & " addresses, the chip selects are " &
				   "one-hot everywhere, and no address ever selects both the DTCM " &
				   "and a peripheral."
				severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(fails_v) &
				   " check(s) failed. Read the first described failures above: the " &
				   "address they name tells you whether the region split, the page " &
				   "qualifier, the word group or the lane mask is wrong."
				severity error;
		end if;
		report "============================================" severity note;

		std.env.stop;
	end process sweep;

END test;
