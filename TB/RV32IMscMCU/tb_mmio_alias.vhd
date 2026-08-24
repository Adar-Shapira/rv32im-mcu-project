--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — self-checking testbench for Phase 5B (gap G-305)
--
-- Proves that an MMIO access no longer reaches the DTCM.
--
-- WHY THIS TEST RUNS A SUPPLIED BENCHMARK AND NOT A PROGRAM OF OURS
--   Auxiliary/Benchmark Apps/GPIO/test0 is the shortest supplied program that
--   writes memory-mapped I/O, and it demonstrates the bug by itself:
--
--     .data
--     N: .word short_delay        -- lands in DTCM word 0
--     main:
--       la  t4,N
--       lw  t3,0(t4)              -- reads N once
--     Loop:
--       li  t4,PORT_LEDR          -- 0x2000
--       sw  t0,0(t4)              -- with no region decode: DTCM word 0 == N
--
--   Confirmed in the shipped image, not inferred: the first record of
--   Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/DTCM.hex is
--   :0400000000000004f8 — DTCM word 0 holds 0x00000004, which is
--   short_delay = 4. So the program's own loop variable sits exactly where
--   PORT_LEDR aliases to, and every one of the seven stores per iteration lands
--   on DTCM words 0..3 — where words 0..3 are the RESET, UART-error, UART-RX and
--   UART-TX interrupt vectors (p14, and DOC/02 section 4.1).
--
--   Using a supplied benchmark rather than a program we wrote means the property
--   is checked against the contract, not against our own idea of it.
--
-- WHAT IS CHECKED
--   P1  THE FIX ITSELF. dtcm_wren_o -- the DTCM's gated write enable, which is
--       DMEMORY.vhd's "wren_w <= MemWrite_ctrl_i AND dtcm_cs_i" -- must be '0'
--       for the whole run. test0 never stores to the DTCM, so the correct count
--       of DTCM writes across the run is exactly ZERO. Remove the AND gate and
--       this fires on all ~126 MMIO stores.
--
--       This deliberately watches the ENABLE, not the decoder's chip select. An
--       earlier draft of this file checked dtcm_cs_o instead, and that version
--       would have printed "VERDICT: PASS - every MMIO store was kept out of the
--       DTCM" on a design with the AND gate deleted: the decoder would still be
--       correct, dtcm_cs_o would still deassert, and every store would still
--       land in DTCM words 0..3. The chip select proves the decode; only the
--       enable proves the fix.
--   P2  THE WIRING. dtcm_cs_o must equal NOT alu_res_o(13) on every cycle. This
--       is what catches the decoder being fed the wrong address bits -- a
--       mis-slice would leave dtcm_cs asserted, which P1 would also catch, but
--       P2 says which of the two went wrong and does so on every cycle rather
--       than only on stores.
--   P3  NOT VACUOUS. The seven MMIO byte addresses of test0 must all have been
--       seen, at least twice round the loop. Without this the test passes
--       perfectly on a core that fetched nothing, and that is the failure mode a
--       "no bad thing happened" test always has.
--   P4  NOTHING UNMAPPED. unmapped_o must never be '1' during a store. Every
--       address test0 uses is in the map, so this firing means the decode or the
--       address routing is wrong.
--
-- WHAT THIS TEST DELIBERATELY DOES NOT CHECK
--   That the DTCM is still WRITABLE. test0 performs exactly one DTCM access (the
--   lw of N) and never stores to it, so a decoder stuck at dtcm_cs = '0' -- which
--   would break every DTCM store in the machine -- passes P1, P3 and P4 here and
--   is caught only by P2. The DTCM write path is covered elsewhere, and heavily:
--   tb_isa_directed.vhd scores 43 stores to DTCM scratch words, and the four Lab 5
--   benchmarks are almost entirely DTCM traffic and must still reproduce
--   134 / 1514 / 2725 / 2735 cycles. Read those results together with this one;
--   neither is sufficient alone.
--
-- THIS TEST REQUIRES G_ISA_REPAIR = TRUE, AND THE REASON IS INTERESTING
--   At G_ISA_REPAIR = FALSE the core reproduces the LAB5 submission, in which
--   lui writes zero (defect 2 -- IDECODE.vhd:111 forces lui_imm_w to all zeros
--   in that configuration). Disassembling the shipped image
--   Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex, every one of
--   test0's seven stores is reached as:
--
--       lui  t4,0x2        -- word 4, 0x00002eb7
--       addi t4,t4,offset  -- word 5
--       sw   t0,0(t4)      -- word 6
--
--   With lui broken, t4 = 0 + offset. The stores go to byte addresses
--   0, 4, 5, 8, 9, 12, 13 -- all inside the DTCM, none of them ever reaching
--   0x2000. So in that configuration this testbench measures nothing: P1 can
--   never fire and P3 fails because none of the seven MMIO addresses is seen.
--
--   That is worth stating plainly in the report, because it means THE TWO
--   DEFECTS MASKED EACH OTHER. The missing region decode was invisible on the
--   GPIO benchmarks precisely because lui never produced an SFR address in the
--   first place. Repairing lui is what exposes the aliasing.
--
--   Rather than fail confusingly, the checker below detects G_ISA_REPAIR = FALSE
--   and reports NOT APPLICABLE with this explanation.
--
-- STAGING
--   Needs GPIO test0's images as app_bin\ITCM.hex and app_bin\DTCM.hex, the same
--   mechanism every benchmark run uses (IFETCH.vhd and DMEMORY.vhd carry the
--   hardcoded init_file path). run_mmio.do says which files.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.const_package.all;
USE work.aux_package.all;


ENTITY tb_mmio_alias IS
	generic(
		WORD_GRANULARITY	: boolean	:= G_WORD_GRANULARITY;
		MODELSIM			: integer	:= G_MODELSIM;
		DATA_BUS_WIDTH		: integer	:= 32;
		ITCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		DTCM_ADDR_WIDTH		: integer	:= G_ADDRWIDTH;
		PC_WIDTH			: integer	:= G_PC_WIDTH;
		MA_WIDTH			: integer	:= G_MA_WIDTH;
		DATA_WORDS_NUM		: integer	:= G_DATA_WORDSNUM;
		CLK_CNT_WIDTH		: integer	:= 16;
		-- test0 loops forever, so the run is bounded here. Counted from the shipped
		-- ITCM image rather than estimated: the loop body is ITCM words 4..29, and
		-- one iteration executes 23 instructions of body + 8 in the delay loop
		-- (words 27-28 twice per count, N = 4) + 1 for the j = 32. The core is
		-- single-cycle, so after 4 setup instructions 600 cycles gives
		-- (600-4)/32 = 18 full iterations, well past the 2 that P3 requires.
		RUN_CYCLES			: integer	:= 600
	);
END tb_mmio_alias;
--============================================================================
ARCHITECTURE test OF tb_mmio_alias IS
	SIGNAL rst_i				: STD_LOGIC;
	SIGNAL clk_i				: STD_LOGIC;

	SIGNAL pc_o					: STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
	SIGNAL instruction_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL RegWrite_ctrl_o		: STD_LOGIC;
	SIGNAL MemWrite_ctrl_o		: STD_LOGIC;
	SIGNAL Branch_ctrl_o		: STD_LOGIC;
	SIGNAL read_data1_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL read_data2_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL write_data_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL alu_res_o			: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL brTaken_o			: STD_LOGIC;
	SIGNAL dtcm_addr_o			: STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_wr_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_data_rd_o		: STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
	SIGNAL dtcm_cs_o			: STD_LOGIC;
	SIGNAL unmapped_o			: STD_LOGIC;
	SIGNAL dtcm_wren_o			: STD_LOGIC;
	SIGNAL mclk_cnt_o			: STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

	-- The seven byte addresses test0 writes, in the order its source writes them.
	-- Transcribed from Auxiliary/Benchmark Apps/GPIO/test0/asm-code/test0.s:21-34
	-- via io_map.s.
	type addr_list_t is array (natural range <>) of integer;
	CONSTANT T0_STORES	: addr_list_t := (
		16#2000#,		-- PORT_LEDR
		16#2004#,		-- PORT_HEX0
		16#2005#,		-- PORT_HEX1
		16#2008#,		-- PORT_HEX2
		16#2009#,		-- PORT_HEX3
		16#200C#,		-- PORT_HEX4
		16#200D#		-- PORT_HEX5
	);
	CONSTANT MIN_ITERATIONS	: integer := 2;

	function addr_of(v : STD_LOGIC_VECTOR) return natural is
		variable n : natural := 0;
	begin
		for i in v'range loop
			n := n * 2;
			if v(i) = '1' then n := n + 1; end if;
		end loop;
		return n;
	end function;

	function bit_img(b : STD_LOGIC) return string is
	begin
		case b is
			when '0'	=> return "0";
			when '1'	=> return "1";
			when others	=> return "?";
		end case;
	end function;

BEGIN
	DUT : RV32IMscMCU
	generic map(
		RST_ACTIVE_LOW		=> FALSE,	-- stimulus below is active-high
		GEN_DEBUG_PORTS		=> TRUE,	-- dtcm_cs_o and unmapped_o must be driven
		WORD_GRANULARITY	=> WORD_GRANULARITY,
		MODELSIM			=> MODELSIM,
		DATA_BUS_WIDTH		=> DATA_BUS_WIDTH,
		ITCM_ADDR_WIDTH		=> ITCM_ADDR_WIDTH,
		DTCM_ADDR_WIDTH		=> DTCM_ADDR_WIDTH,
		PC_WIDTH			=> PC_WIDTH,
		MA_WIDTH			=> MA_WIDTH,
		DATA_WORDS_NUM		=> DATA_WORDS_NUM,
		CLK_CNT_WIDTH		=> CLK_CNT_WIDTH
	)
	PORT MAP (
		clk_i				=> clk_i,
		rst_i				=> rst_i,
		pc_o				=> pc_o,
		instruction_o		=> instruction_o,
		RegWrite_ctrl_o		=> RegWrite_ctrl_o,
		MemWrite_ctrl_o		=> MemWrite_ctrl_o,
		Branch_ctrl_o		=> Branch_ctrl_o,
		read_data1_o		=> read_data1_o,
		read_data2_o		=> read_data2_o,
		write_data_o		=> write_data_o,
		alu_res_o			=> alu_res_o,
		brTaken_o			=> brTaken_o,
		dtcm_addr_o			=> dtcm_addr_o,
		dtcm_data_wr_o		=> dtcm_data_wr_o,
		dtcm_data_rd_o		=> dtcm_data_rd_o,
		dtcm_cs_o			=> dtcm_cs_o,
		unmapped_o			=> unmapped_o,
		dtcm_wren_o			=> dtcm_wren_o,
		mclk_cnt_o			=> mclk_cnt_o
	);
--------------------------------------------------------------------
	-- Same 100 ns clock and 80 ns active-high reset as every other testbench in
	-- this project, so timing behaviour is directly comparable.
	-- std.env.stop ends the run, so this loop needs no termination of its own --
	-- the same shape tb_isa_directed.vhd uses.
	gen_clk : process
	begin
		clk_i <= '1';
		wait for 50 ns;
		clk_i <= '0';
		wait for 50 ns;
	end process;

	gen_rst : process
	begin
		rst_i <= '1', '0' after 80 ns;
		wait;
	end process;
--------------------------------------------------------------------
	-- One process, so ordinary variables carry every tally and no signal needs
	-- more than one driver. Variable names take Hanan's _v extension.
	--
	-- SAMPLING ON THE FALLING EDGE, and this is not a free choice.
	-- DMEMORY drives its altsyncram with wrclk_w <= NOT clk_i, so the DTCM latches
	-- a store when clk_i falls. The control and address outputs are combinational
	-- off the ITCM's registered instruction and are settled well before then, so
	-- falling_edge(clk_i) observes exactly what the memory commits -- and it is
	-- the only edge at which dtcm_wren_o can be read as the enable the RAM
	-- actually saw. Sampling on the rising edge would race the instruction fetch.
	-- Same convention, and the same reasoning, as the scoreboard in
	-- tb_isa_directed.vhd:182 ("WHY SAMPLING HAPPENS ON THE FALLING EDGE").
	checker : process(clk_i)
		variable fails_v		: integer := 0;
		variable cycles_v		: integer := 0;
		variable mmio_st_v		: integer := 0;		-- stores with A13 = '1'
		variable dtcm_acc_v		: integer := 0;		-- stores with A13 = '0'
		variable dtcm_wr_v		: integer := 0;		-- times the DTCM actually accepted a write
		variable seen_v			: STD_LOGIC_VECTOR(T0_STORES'length-1 DOWNTO 0) := (OTHERS => '0');
		variable min_hits_v		: integer := 0;		-- least times any one address was hit
		variable hits_v			: addr_list_t(T0_STORES'range) := (OTHERS => 0);
		variable a_v			: integer;
		variable known_v		: boolean;
		variable skipped_v		: integer := 0;		-- cycles where alu_res(13) was a metavalue
		variable reported_v		: integer := 0;

		procedure fail(msg : in string) is
		begin
			fails_v := fails_v + 1;
			if reported_v < 20 then
				reported_v := reported_v + 1;
				report msg severity error;
			end if;
		end procedure;
	begin
		if falling_edge(clk_i) and rst_i = '0' then
			--==========================================================
			-- Configuration guard. See the header: at G_ISA_REPAIR = FALSE the
			-- lui defect keeps every store below 0x2000, so there is nothing here
			-- to measure. Reported as NOT APPLICABLE rather than failed, because
			-- a FAIL here would send someone hunting a decoder bug that is not
			-- there.
			--==========================================================
			if not G_ISA_REPAIR then
				report "===== PHASE 5B MMIO ALIASING TEST (GPIO test0) =====" severity note;
				report "  VERDICT: NOT APPLICABLE - this build has G_ISA_REPAIR = FALSE." severity note;
				report "  In that configuration lui writes zero (defect 2), so test0's" severity note;
				report "  'lui t4,0x2 / addi / sw' sequences store to byte addresses 0, 4," severity note;
				report "  5, 8, 9, 12 and 13 - inside the DTCM, never reaching 0x2000. The" severity note;
				report "  aliasing this test looks for cannot occur, so a PASS would be" severity note;
				report "  meaningless and a FAIL would be misleading." severity note;
				report "  Set G_ISA_REPAIR := TRUE in cond_compilation_package.vhd, recompile," severity note;
				report "  and run again. Note for the report: the two defects masked each" severity note;
				report "  other - repairing lui is what exposes the missing region decode." severity note;
				report "====================================================" severity note;
				std.env.stop;
			end if;

			cycles_v := cycles_v + 1;

			--==========================================================
			-- P2 -- the wiring. Checked every cycle, access or not, because the
			-- decoder is combinational on the address bus and the invariant holds
			-- whether or not the cycle performs an access.
			--
			-- Metavalues are counted, not failed. alu_res carries 'U' before the
			-- register file has been written for the first time, and 'U' /= 'U' is
			-- false anyway, so failing on them would be arbitrary. If the skipped
			-- count is anything but a handful of startup cycles, that is itself
			-- the finding and the summary prints it.
			--==========================================================
			if alu_res_o(13) = '0' or alu_res_o(13) = '1' then
				if dtcm_cs_o /= (not alu_res_o(13)) then
					fail("FAIL P2 wiring at cycle " & integer'image(cycles_v) &
						 ": alu_res(13) = " & bit_img(alu_res_o(13)) &
						 " but dtcm_cs_o = " & bit_img(dtcm_cs_o) &
						 ". The decoder is not seeing the address bits it should - check " &
						 "dbus_addr_o's slice in RV32IM_CORE and the DEC port map.");
				end if;
			else
				skipped_v := skipped_v + 1;
			end if;

			--==========================================================
			-- P1 -- THE FIX ITSELF. dtcm_wren_o is DMEMORY's gated write enable.
			-- test0 never stores to the DTCM, so across the whole run this must
			-- be '0' on every falling edge: the correct DTCM write count is zero.
			-- Checked unconditionally, not only on stores, so a spurious enable
			-- from any cause is caught.
			--==========================================================
			if dtcm_wren_o = '1' then
				dtcm_wr_v := dtcm_wr_v + 1;
				a_v := addr_of(alu_res_o(DATA_ADDR_WIDTH-1 DOWNTO 0));
				fail("FAIL P1 the DTCM accepted a write, at cycle " &
					 integer'image(cycles_v) & ", byte address " & integer'image(a_v) &
					 " -> DTCM word " & integer'image((a_v mod 8192) / 4) &
					 ". GPIO test0 never stores to the DTCM, so dtcm_wren_o must stay " &
					 "'0' for the whole run. If the address is 0x2000 or above, the " &
					 "AND gate in DMEMORY.vhd (wren_w <= MemWrite_ctrl_i AND " &
					 "dtcm_cs_i) is not doing its job - that gate IS the Phase 5B fix.");
			end if;

			if MemWrite_ctrl_o = '1' then
				a_v := addr_of(alu_res_o(DATA_ADDR_WIDTH-1 DOWNTO 0));

				--======================================================
				-- P4 -- nothing test0 touches may be unmapped.
				--
				-- Only stores are visible here: the MCU exposes no MemRead port.
				-- Reads are covered by composition instead - P2 proves the decoder
				-- sees the right address bits, and tb_addr_decoder proves unmapped_o
				-- is exactly right as a function of the address, on all 16384 of them.
				--======================================================
				if unmapped_o = '1' then
					fail("FAIL P4 unmapped store at byte address " & integer'image(a_v) &
						 " (cycle " & integer'image(cycles_v) & "). Every address " &
						 "GPIO test0 uses is in the map, so either the decode or the " &
						 "address routing is wrong.");
				end if;

				if alu_res_o(13) = '1' then
					mmio_st_v := mmio_st_v + 1;

					-- P3 bookkeeping: which of test0's seven addresses was this?
					known_v := FALSE;
					for i in T0_STORES'range loop
						if T0_STORES(i) = a_v then
							known_v  := TRUE;
							seen_v(i) := '1';
							hits_v(i) := hits_v(i) + 1;
						end if;
					end loop;
					if not known_v then
						fail("FAIL P3 unexpected MMIO store to byte address " &
							 integer'image(a_v) & " at cycle " & integer'image(cycles_v) &
							 ". GPIO test0 writes only the seven GPO registers, so the " &
							 "effective address computation is wrong.");
					end if;
				else
					dtcm_acc_v := dtcm_acc_v + 1;
				end if;
			end if;

			--==========================================================
			-- End of the bounded run
			--==========================================================
			if cycles_v >= RUN_CYCLES then
				report "===== PHASE 5B MMIO ALIASING TEST (GPIO test0) =====" severity note;
				report "  cycles run          : " & integer'image(cycles_v) severity note;
				report "  MMIO stores seen    : " & integer'image(mmio_st_v) severity note;
				report "  DTCM stores seen    : " & integer'image(dtcm_acc_v) &
					   "  (expect 0 - test0 never stores to the DTCM)" severity note;
				report "  DTCM WRITES ACCEPTED: " & integer'image(dtcm_wr_v) &
					   "  (expect 0 - this is the Phase 5B fix)" severity note;
				report "  P2 cycles skipped   : " & integer'image(skipped_v) &
					   "  (metavalue on alu_res(13); a handful at startup is normal)" severity note;

				--======================================================
				-- P3 -- the anti-vacuity check
				--======================================================
				min_hits_v := integer'high;
				for i in T0_STORES'range loop
					if hits_v(i) < min_hits_v then
						min_hits_v := hits_v(i);
					end if;
					if seen_v(i) = '0' then
						fail("FAIL P3 coverage: byte address " &
							 integer'image(T0_STORES(i)) & " was never stored to. " &
							 "The program did not run as expected, so the absence of " &
							 "aliasing proves nothing.");
					end if;
				end loop;
				report "  least hits, any addr: " & integer'image(min_hits_v) &
					   "  (need >= " & integer'image(MIN_ITERATIONS) & ")" severity note;

				if min_hits_v < MIN_ITERATIONS then
					fail("FAIL P3 iterations: the least-hit MMIO address was written " &
						 integer'image(min_hits_v) & " time(s), fewer than the " &
						 integer'image(MIN_ITERATIONS) & " loop iterations this test " &
						 "requires. Raise RUN_CYCLES, or the core is not looping.");
				end if;

				report "  failures            : " & integer'image(fails_v) severity note;
				if fails_v = 0 then
					report "  VERDICT: PASS - the DTCM accepted zero writes across the run, " &
					   "every MMIO store was kept out of it, " &
						   "dtcm_cs_o tracked A13 on every cycle, all seven GPO registers " &
						   "were exercised at least " & integer'image(MIN_ITERATIONS) &
						   " times, and nothing unmapped was touched."
						severity note;
					report "  Read this together with tb_isa_directed and the four benchmark " &
						   "cycle counts: this test cannot prove the DTCM is still writable, " &
						   "and those can."
						severity note;
				else
					report "  VERDICT: FAIL - " & integer'image(fails_v) & " check(s) failed. " &
						   "How to read it: P1 with P2 passing means the decode is right and " &
						   "the AND gate in DMEMORY.vhd is not gating; P1 and P2 together " &
						   "mean the decoder is fed the wrong address bits; P2 alone means " &
						   "dtcm_cs is wrong in a direction no store exercised; P3 alone " &
						   "means the program did not run and nothing else here is meaningful."
						severity error;
				end if;
				report "====================================================" severity note;

				std.env.stop;
			end if;
		end if;
	end process checker;

END test;
