---------------------------------------------------------------------------------------------
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- RV32IM-based MCU, single-cycle
--
-- gpo_port -- one general-purpose OUTPUT port interface, per Figure 5 (p5).
--
-- Figure 5 draws the same block seven times: a register holding D0..D7, enabled
-- by the port's chip select ANDed with MemWrite, with the HEX pairs additionally
-- separated by A0. This is that block, instantiated once per port in
-- RV32IMscMCU.vhd. The 7-segment encoder that follows it on the HEX ports is a
-- separate entity (hex_decoder), exactly as the figure separates them.
---------------------------------------------------------------------------------------------
-- WHAT FIGURE 5 SPECIFIES, AND THE TWO PLACES THIS DEVIATES
--   Specified and implemented: D0..D7 in, Q0..Q7 out, one enable formed as
--   CS_x . MemWrite (. A0 where a pair shares a chip select), a 7-segment
--   encoder after the register on the HEX ports.
--
--   DEVIATION 2, AND IT IS A WHOLE PORT -- READ-BACK IS MISSING.
--   Look again at Figure 5 (p5): each of the three output-port interface blocks
--   it draws -- PORT_HEX1, PORT_HEX0 and PORT_LEDR -- carries a tri-state buffer
--   at the top, labelled with MemRead and the block's own chip select (and A0 /
--   /A0 for the pair), driving Data<7..0>. That is a read-back path: a load from
--   0x2000 or 0x2004 should return the byte the port last stored. This entity has
--   no such output, so all seven ports are write-only and a load from any of them
--   returns the Phase 5B placeholder zero.
--
--   Not implemented yet, and deliberately not invented either, because clause 5's
--   own table gives all seven a Direction of "GPO" -- output. The table and the
--   figure are in tension: "GPO" plausibly describes the device rather than
--   forbidding a readable register, which is the ordinary memory-mapped-I/O
--   reading and matches the figure. But that is an interpretation, so it is
--   recorded rather than assumed. See DOC/02_requirements_traceability.md.
--
--   Nothing is blocked: no supplied benchmark reads a GPO port -- the only MMIO
--   reads in any benchmark suite are three "lw ... PORT_SW". The read-back is
--   scheduled with the rest of the read path in Phase 6B, which is where the
--   tri-state bus it needs gets built.
--
--   DEVIATION 1: the figure draws a level-sensitive "D-Latch ... En". This entity
--   is an edge-triggered register with an enable instead. Three reasons, in
--   order of weight:
--     1. Hanan's own material is explicit that an inferred latch is not what to
--        write -- Auxiliary/hanan/Sequential Code part7 - System Design
--        Principles.md: "Don't write Mixed PROCESS, is non synthesizable
--        (ieee-1076.6 standard)", and the whole deck is about separating
--        combinational from synchronous. A transparent latch in an FPGA fabric
--        that has no latch primitive is built out of combinational feedback.
--     2. The course's own board-interface reference does it this way:
--        Auxiliary/Lab4/DUT/fpga_hw_interface.vhd registers its
--        SW/KEY inputs inside "IF rising_edge(clk_2MHz) THEN ... IF
--        key_pressed(n) = '1' THEN" -- an edge-triggered register with an enable,
--        which is precisely this structure.
--     3. Behaviour here is identical. This is a single-cycle machine: the
--        address, the write data and MemWrite are all stable for the whole store
--        cycle, so a latch transparent for that cycle and a register capturing at
--        its end settle to the same value. The only difference is when the pin
--        changes within the cycle, and nothing observes that.
--
-- WHY THE RISING EDGE AND NOT THE INVERTED CLOCK
--   The DTCM uses the falling edge (DMEMORY.vhd: wrclk_w <= NOT clk_i) because an
--   altsyncram REGISTERS its own address and data inputs, so it has to be clocked
--   after the ALU has settled, mid-cycle. This port has no internal input
--   register: its D inputs come straight off the data bus, so the rising edge that
--   ends the store cycle captures values that are already valid, and no inverted
--   clock is needed. Lab 4's interface uses the rising edge for the same reason.
--
--   Consequence, stated so it is not mistaken for a bug: the pin changes one
--   clock after the store instruction. Nothing in the assignment or the
--   benchmarks depends on the pin changing within the store cycle itself.
--
-- WHY THE THREE ENABLE TERMS ARE SEPARATE PORTS
--   cs_i, MemWrite_i and lane_en_i could have been ANDed by the caller and passed
--   as one enable. They are separate because Figure 5 draws the AND inside the
--   interface block, and because keeping them apart is what makes a wrong lane
--   visible in a waveform: with one combined enable, "this port took a write it
--   should not have" and "the decoder selected the wrong word" look the same.
--
-- ASSUMPTION -- THE RESET VALUE
--   Nothing in the assignment states what a GPO port holds after reset. Figure 5
--   draws no reset on the latch at all. Zero is used here, which means the LEDs
--   are off and every HEX display shows "0" after KEY0. The alternative reading
--   -- displays blank until first written -- would need a separate "not yet
--   written" flag that nothing asks for. Recorded in
--   DOC/02_requirements_traceability.md. Falsified by any statement that the
--   displays should be dark at reset.
---------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY gpo_port IS
	generic(
		-- Figure 5 draws D0..D7 / Q0..Q7, so eight bits is the port's own width.
		-- On a HEX port only bits 3..0 reach the encoder; the upper nibble has no
		-- load and synthesis prunes it, so following the figure costs nothing.
		DATA_WIDTH	: integer := 8
	);
	PORT(
		--Inputs
		clk_i		: IN	STD_LOGIC;
		rst_i		: IN	STD_LOGIC;						-- active high, ASYNCHRONOUS -- see below
		cs_i		: IN	STD_LOGIC;						-- CS_x from the address decoder
		MemWrite_i	: IN	STD_LOGIC;
		-- The A0 (and A1) qualification of Figure 5, for the ports that share a
		-- chip select. Defaulted to '1' for a port that owns its word alone, so
		-- those instantiations do not have to tie it off.
		lane_en_i	: IN	STD_LOGIC := '1';
		data_i		: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

		--Outputs
		q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
	);
END gpo_port;


ARCHITECTURE behavior OF gpo_port IS
	-- The initial value sets the register's POWER-UP state, before any reset has
	-- been seen. Precedent in the course material:
	-- Auxiliary/Lab4/DUT/fpga_hw_interface.vhd declares
	-- "SIGNAL Y_reg, X_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');"
	-- for the same purpose, and Quartus honours it on a Cyclone IV register.
	SIGNAL q_q		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL en_w		: STD_LOGIC;
BEGIN
	-- The three-input AND of Figure 5.
	en_w <= cs_i AND MemWrite_i AND lane_en_i;

	-- Pure synchronous. One clock, one enable, one reset -- no combinational
	-- element inside the process, so this is not a Mixed PROCESS.
	--
	-- RESET IS ASYNCHRONOUS. Two reasons, and the honest weight of each:
	--
	--   1. CONSISTENCY, which is the real reason. Every clocked element in this
	--      design resets asynchronously -- RV32IM_CORE.vhd's cycle counter and
	--      IFETCH's PC both test rst_i outside rising_edge -- and an asynchronous
	--      reset does not depend on a power-up value being right.
	--
	--   2. The four testbenches that instantiate this design drive reset high from
	--      0 ns and low at 80 ns, with the first rising clock edge at 100 ns
	--      (tb_RV32IMscMCU.vhd:136, tb_isa_directed.vhd:170,
	--      tb_mmio_alias.vhd:233, tb_gpio.vhd:240). A SYNCHRONOUS reset would
	--      therefore never see an active edge at all: reset is gone before the
	--      first edge arrives.
	--
	--   CORRECTION TO AN EARLIER VERSION OF THIS COMMENT, kept because the record
	--   matters more than looking right. It claimed that a synchronous reset would
	--   leave 'U' on a board pin. With the initial value on q_q above that is
	--   FALSE: the register reads "0...0" from 0 ns whether or not any reset edge
	--   ever arrives. The 'U' hazard was real in the first draft of this file,
	--   which had a synchronous reset and NO initial value; the two were fixed in
	--   the same edit and the note then described a state that no longer existed.
	--   So point 2 is a genuine argument against a synchronous reset here, but it
	--   is not a live-bug argument -- point 1 is why it stays asynchronous.
	reg : PROCESS(clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			q_q <= (OTHERS => '0');
		ELSIF rising_edge(clk_i) THEN
			IF en_w = '1' THEN
				q_q <= data_i;
			END IF;
		END IF;
	END PROCESS reg;

	q_o <= q_q;

END behavior;
