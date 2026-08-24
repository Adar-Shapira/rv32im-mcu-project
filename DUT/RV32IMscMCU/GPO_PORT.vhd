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
-- WHAT FIGURE 5 SPECIFIES, AND THE ONE PLACE THIS DEVIATES
--   Specified and implemented: D0..D7 in, Q0..Q7 out, one enable formed as
--   CS_x . MemWrite (. A0 where a pair shares a chip select), a 7-segment
--   encoder after the register on the HEX ports.
--
--   DEVIATION: the figure draws a level-sensitive "D-Latch ... En". This entity
--   is an edge-triggered register with an enable instead. Three reasons, in
--   order of weight:
--     1. Hanan's own material is explicit that an inferred latch is not what to
--        write -- Auxiliary/hanan/Sequential Code part7 - System Design
--        Principles.md: "Don't write Mixed PROCESS, is non synthesizable
--        (ieee-1076.6 standard)", and the whole deck is about separating
--        combinational from synchronous. A transparent latch in an FPGA fabric
--        that has no latch primitive is built out of combinational feedback.
--     2. The course's own board-interface reference does it this way:
--        Auxiliary/Lab 5/Auxilary/Lab4/DUT/fpga_hw_interface.vhd registers its
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
		rst_i		: IN	STD_LOGIC;						-- active high, synchronous below
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
	-- Auxiliary/Lab 5/Auxilary/Lab4/DUT/fpga_hw_interface.vhd declares
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
	-- RESET IS ASYNCHRONOUS, and that is not a stylistic choice.
	--   Every clocked element in this design resets asynchronously --
	--   RV32IM_CORE.vhd's cycle counter and IFETCH's PC both test rst_i outside
	--   rising_edge -- and every testbench in the project drives reset the same
	--   way: high from 0 ns, low at 80 ns, with the first rising clock edge at
	--   100 ns. A SYNCHRONOUS reset would therefore never see an active edge:
	--   reset is already gone by the time the first edge arrives, so the register
	--   would leave reset holding whatever it powered up with. In simulation that
	--   is 'U' propagating straight to a board pin.
	--
	--   This was written synchronous first and the timing traced afterwards, which
	--   is how it was found. Noted so nobody "tidies" it back.
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
