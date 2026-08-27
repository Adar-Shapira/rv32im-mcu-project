--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Phase 12B: the USART on the bus, on the PIPELINED MCU
--
-- HOW TO RUN
--   SIM/RV32IMpipelinedMCU/run_uart_mmio.do -- stages the SAME generated
--   images the single-cycle test uses (SIM/RV32IMscMCU/uartmmio/): the program
--   is core-agnostic, so there is one copy of it and not two to drift apart.
--
-- WHY THIS EXISTS SEPARATELY FROM THE SINGLE-CYCLE ONE
--   Every peripheral is byte-identical between the two DUT trees
--   (tools/check_peripheral_copies.py enforces it), so the USART itself is
--   already proven here by the single-cycle run. What is NOT shared is the
--   core: the pipelined interrupt entry is a different design, with its own
--   retirement boundary, its own flush, and RXBUF's read side effect landing
--   in the MEM stage rather than in a single cycle. This file runs the same
--   22 exact expectations against that core.
--
--   The checks below are IDENTICAL to TB/RV32IMscMCU/tb_uart_mmio.vhd. Only
--   the instantiation differs: the pipelined top's store observation comes
--   from MemWrite_ctrl_o / alu_res_o / read_data2_o, and the sentinel is
--   watched in the MEM stage (MEMinstruction_o) because branches resolve
--   there -- watching a decode stage would stop the run on a speculative
--   fetch of the final self-jump, which is the trap batch_verify.do
--   documents.
--
-- WHAT THIS PROVES, AND WHAT IT DELIBERATELY DOES NOT
--   Phase 12A proved the USART as a leaf: tb_uart.vhd loops TXD back into RXD
--   at the real divider and MEASURES the start bit, and tools/model_uart.py
--   covers the register layer edge by edge. What neither could see is the BUS.
--   This bench closes that: a real program on the real MCU writes UCTL at
--   0x2018, TXBUF at 0x201A and reads RXBUF at 0x2019 -- three lanes of one
--   chip select -- watches IFG at 0x202D and TYPE at 0x202E, and takes a real
--   interrupt through the vector table it wrote itself.
--
--   THE BENCH DOES EXACTLY ONE THING: it ties UART_RXD_i to UART_TXD_o. Not a
--   procedure that shifts bits at a computed bit time, not a model of a frame
--   -- the two top-level pins, wired together, which is also what a loopback
--   plug on the DE2-115's DB9 does. Everything else is the program and the
--   hardware, and all 22 scored stores are EXACT because every expectation is
--   a value the program POLLED for, never a cycle count.
--
--   What it does not prove: the bit timing (tb_uart.vhd owns that -- both
--   ends here share one divider, so a wrong-but-consistent baud would still
--   loop back), and the same-cycle read-and-arrive overrun case, which is not
--   reachable from a program (model_uart.py phase P7e owns it).
--
--   Program uses addi/slli/sw/lw@0/and/beq/bne/reti.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use std.env.all;
USE work.cond_compilation_package.all;
USE work.aux_package.all;


ENTITY tb_uart_mmio IS
	generic(
		MODELSIM	: integer := G_MODELSIM
	);
END tb_uart_mmio;


ARCHITECTURE test OF tb_uart_mmio IS

	constant CLK_PERIOD	: time := 100 ns;
	-- The generator reports the interpreter reaching the sentinel in 8941
	-- cycles: five 8N1 frames of 10*16*11 = 1760 cycles each, plus the polling
	-- around them. 30000 leaves better than 3x headroom without letting a hung
	-- run sit there for a minute.
	constant TIMEOUT	: natural := 30000;

	-- from the generator's listing (SIM/RV32IMscMCU/uartmmio/listing.txt)
	constant ISR_RX_A	: natural := 16#218#;

	SIGNAL clk		: STD_LOGIC := '0';
	SIGNAL rst		: STD_LOGIC := '1';
	SIGNAL running	: BOOLEAN := TRUE;

	-- THE LOOPBACK. One signal: the MCU's TXD pin drives it, the MCU's RXD pin
	-- reads it. Initialised to the idle line level so the receiver does not see
	-- a start bit before the first transmit.
	SIGNAL serial	: STD_LOGIC := '1';

	SIGNAL instr	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL memw		: STD_LOGIC;
	SIGNAL alu_res	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL st_data	: STD_LOGIC_VECTOR(31 DOWNTO 0);

	type mem_t is array (0 TO 191) of STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL scored	: mem_t := (OTHERS => (OTHERS => '0'));
	SIGNAL nscored	: NATURAL := 0;

	-- Observation only, for the waveform and for the anti-vacuity check below:
	-- a run in which the line never moved cannot have proved anything.
	SIGNAL edges	: NATURAL := 0;

BEGIN
	--=======================================================================
	MCU : RV32IMpipelinedMCU
	generic map(
		RST_ACTIVE_LOW	=> FALSE,		-- the stimulus below is active-high
		MODELSIM		=> MODELSIM
	)
	PORT MAP (
		clk_i			=> clk,
		rst_i			=> rst,
		UART_RXD_i		=> serial,		-- ... and this reads it
		UART_TXD_o		=> serial,		-- the MCU drives the line ...
		MEMinstruction_o	=> instr,	-- the RETIRING instruction, see the header
		MemWrite_ctrl_o	=> memw,
		alu_res_o		=> alu_res,		-- the full byte address, zero-extended
		read_data2_o	=> st_data		-- the store data
	);

	clk_gen : process
	begin
		while running loop
			clk <= '1'; wait for CLK_PERIOD/2;
			clk <= '0'; wait for CLK_PERIOD/2;
		end loop;
		wait;
	end process clk_gen;

	rst <= '1', '0' after 80 ns;

	-- Count transitions on the serial line. Not a check in itself -- it is what
	-- makes the PASS non-vacuous: 22 exact values with a line that never
	-- toggled would mean the loopback was not the path they came through.
	line_watch : process(serial)
	begin
		if now > 100 ns then
			edges <= edges + 1;
		end if;
	end process line_watch;

	--=======================================================================
	-- Scoreboard: every store whose byte address lands in the scratch/flag
	-- window, sampled at the falling edge. MMIO stores (0x2xxx) fall outside
	-- and are the peripherals' business.
	--=======================================================================
	scoreboard : process(clk)
		variable a : natural;
		variable n : natural := 0;
	begin
		if falling_edge(clk) then
			if memw = '1' and rst = '0' then
				a := to_integer(unsigned(alu_res(13 DOWNTO 0)));
				if a < 16#300# then
					scored(a / 4) <= st_data;
					n := n + 1;
					nscored <= n;
				end if;
			end if;
		end if;
	end process scoreboard;

	--=======================================================================
	verdict : process
		variable p, f : natural := 0;
		variable cyc  : natural := 0;

		procedure chk(constant ok : boolean; constant msg : string) is
		begin
			if ok then p := p + 1;
			else
				f := f + 1;
				report "FAIL " & msg severity error;
			end if;
		end procedure chk;

		procedure chkv(constant a : IN natural; constant v : IN natural;
					   constant msg : IN string) is
		begin
			chk(to_integer(unsigned(scored(a / 4))) = v, "[" &
				to_hstring(to_unsigned(a, 16)) & "] = 0x" &
				to_hstring(scored(a / 4)) & ", expected 0x" &
				to_hstring(to_unsigned(v, 32)) & " : " & msg);
		end procedure chkv;

	begin
		wait until rst = '0';

		-- ---- run to the sentinel with all 22 stores -------------------------
		cyc := 0;
		while not (instr = x"00000063" and nscored = 22) and cyc < TIMEOUT loop
			wait until falling_edge(clk);
			cyc := cyc + 1;
		end loop;
		chk(cyc < TIMEOUT, "the program never finished (sentinel + 22 stores). " &
			"If it stalled early, find which poll loop it is in: no RXIFG means " &
			"nothing came back on RXD or IE was left at 0 (the IFG read-back is " &
			"the MASKED view); no OE means the second character did not overrun; " &
			"[0x200] still 0 means the RX interrupt never entered. Check the " &
			"staged images are SIM/RV32IMscMCU/uartmmio/, not another set");
		chk(nscored = 22, "scored " & integer'image(nscored) &
			" store(s), expected exactly 22");

		-- the line must actually have carried five frames
		chk(edges > 20, "the serial line made only " & integer'image(edges) &
			" transition(s): five 8N1 frames carrying 0x5A/0xA5/0x3C/0x71/0x44 " &
			"cannot look like that, so the values below did not travel over it");

		-- ---- configuration and the read path --------------------------------
		chkv(16#100#, 16#08#, "UCTL written at 0x2018 (lane 0) and read back: " &
			"BAUDRATE=1, BUSY/OE/PE/FE clear");

		-- ---- round 1: one byte around the loopback --------------------------
		chkv(16#104#, 16#88#, "UCTL one cycle after writing TXBUF: BUSY up " &
			"because a byte is QUEUED: the third BUSY term");
		chkv(16#108#, 16#5A#, "RXBUF at 0x2019 (lane 1) holds the byte that " &
			"went out on TXD and came back on RXD");
		chkv(16#10C#, 16#00#, "IFG right after that read: RXIFG cleared by the " &
			"READ, with no W0C write; rule b's software half, so rx_clr_o " &
			"reached the interrupt controller");
		chkv(16#110#, 16#08#, "UCTL idle again");

		-- ---- round 2: the overrun -------------------------------------------
		chkv(16#114#, 16#48#, "two characters with no read between them: OE " &
			"set, BUSY clear");
		chkv(16#118#, 16#3C#, "RXBUF holds the NEWER character");
		chkv(16#11C#, 16#08#, "and that read reset the receive-error bits too " &
			"(REQ p12), so OE is gone");

		-- ---- round 3: clearing rule c, on TXIFG -----------------------------
		chkv(16#120#, 16#02#, "TXIFG appears the moment TXIE is set: it had " &
			"been latching invisibly for three transmits (A22's comeback)");
		chkv(16#124#, 16#00#, "and writing TXBUF clears it with no W0C; " &
			"rule c's software half, so tx_clr_o reached the controller");
		chkv(16#128#, 16#71#, "TXBUF reads back the byte just written (A28), " &
			"while its frame is still on the wire");
		chkv(16#12C#, 16#3C#, "...and RXBUF still holds the PREVIOUS byte. " &
			"The two registers differ ONLY here, which is what makes a swap of " &
			"the RXBUF and TXBUF lanes fail instead of passing silently");
		chkv(16#130#, 16#02#, "after the frame, TXIFG is back: the transmitter " &
			"took the byte");
		chkv(16#134#, 16#71#, "the loopback delivered it to RXBUF");
		chkv(16#138#, 16#00#, "and that read drained RXIFG again");

		-- ---- round 4: the interrupt -----------------------------------------
		chkv(16#008#, ISR_RX_A, "vector word 2 (TYPE 08h = UART RX), written " &
			"by the program itself");
		chkv(16#180#, 16#00#, "IFG at ISR entry: RXIFG was auto-cleared AT " &
			"SERVICE; rule b's hardware half, observed from software");
		chkv(16#184#, 16#44#, "the received character, read inside the ISR");
		chkv(16#188#, 16#00#, "TYPE at 0x202E (lane 2) reads idle, for the " &
			"same reason: nothing pends any more");
		chkv(16#200#, 1, "the ISR ran and stored its flag");
		chkv(16#13C#, 1, "gp after reti: GIE restored in hardware");
		chkv(16#140#, 16#5D#, "end marker: main resumed and finished");

		-- ---- verdict --------------------------------------------------------
		report "" severity note;
		report "========= USART MMIO (Phase 12B) SUMMARY =========" severity note;
		report "  serial line transitions: " & integer'image(edges) severity note;
		report "  checks passed " & integer'image(p) & ", failed " &
			integer'image(f) severity note;
		if f = 0 then
			report "  VERDICT: PASS - five characters travelled CPU -> bus -> " &
				"UCTL/TXBUF -> transmitter -> the pin -> receiver -> RXBUF -> " &
				"bus -> CPU, with the overrun flag, both software clearing " &
				"rules and one real vectored RX interrupt, every read-back " &
				"exact." severity note;
		else
			report "  VERDICT: FAIL - " & integer'image(f) &
				" failure(s). Read the FAIL lines above." severity error;
		end if;
		report "==================================================" severity note;

		running <= FALSE;
		wait for 2*CLK_PERIOD;
		std.env.stop;
	end process verdict;

END test;
