--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- division subsystem: engine + crossings + signed wrapper
--
-- Phase 7B1. This is everything between the core and Figure 9's unsigned engine:
-- the two clock-domain crossings Figure 10b draws, the one it does NOT draw, the
-- signed div/rem wrapper, and the MCLK-side handshake. It presents a single
-- MCLK-domain interface so that Phase 7B2's job in the core is decode, a stall
-- term and a write-back mux -- and nothing about clock domains.
--
-- SCOPE: not instantiated yet. 7B2 wires it in. Same split as 7A before 7B,
-- 4A before 4B, 5A before 5B, 6A before 6B.
--============================================================================
-- STRUCTURE, and which figure each piece comes from
--
--   MCLK domain                          | DIVCLK domain
--   -------------------------------------|------------------------------------
--   |a|, |b| and the two signs           |
--   latched on accept                    |
--   ena level          --SYNC-->         | DIVENA
--   a_q                --SYNC-->         | dividend_i   (Figure 10b: Read data1 -> Ain)
--   b_q                --SYNC-->         | divisor_i    (Figure 10b: Read data2 -> Bin)
--                      <--SYNC--         | DIVBUSY      (drawn by NO figure -- ours)
--   quotient / residue read DIRECTLY     | Quotient / Residue
--   sign correction, zero-divisor rule   |
--
--   All four crossings are DUT/RV32IMscMCU/SYNC.vhd, the Figure 10a/10b block
--   built and tested in Phase 4A. This is its first real use.
--============================================================================
-- THE HANDSHAKE, WHICH IS THE WHOLE RISK IN THIS PHASE
--
--   THE CORE CANNOT STALL ON "DIVBUSY IS HIGH". DIVstart has to cross into
--   DIVCLK (two stages), the engine then raises DIVBUSY, and DIVBUSY has to
--   cross back into MCLK (two more). For several MCLK cycles after a div
--   issues, DIVBUSY still reads LOW -- so a stall written as "hold while busy"
--   does not hold at all and the core runs straight past its own divide,
--   writing back whatever the previous divide left behind.
--
--   So this unit exports done_o, not just busy_o, and 7B2's stall term is
--        PCHold <= DIVstart AND NOT done_o
--   which holds from the very first cycle (DIVstart is combinational decode, so
--   it is valid immediately) and releases exactly when the result is valid.
--   busy_o exists for observation and for the interrupt block of F13; it is not
--   what the stall is built on.
--
--   Internally the FSM does NOT trust a single look at the synchronised busy
--   either. It waits to see it HIGH and only then waits for it to fall
--   (WAIT_RISE -> WAIT_FALL). Sampling "is it low yet" straight after launching
--   would be true before the engine had even been told to start.
--
--   **CONSTRAINT THIS PLACES ON THE CLOCK RATIO, and it matters because the
--   ACCELCLK frequency is still open question B3.** WAIT_RISE only terminates if
--   DIVBUSY stays high long enough for the MCLK synchroniser to catch it.
--   DIVBUSY is high for N DIVCLK periods, and the synchroniser needs about two
--   MCLK periods, so the requirement is roughly
--        N / f_DIVCLK  >  2 / f_MCLK      i.e.   f_DIVCLK  <  16 x f_MCLK
--   At the planned 50 MHz DIVCLK against 20 MHz MCLK, DIVBUSY is high for 32 x
--   20 ns = 640 ns against an MCLK period of 50 ns -- twelve times the margin
--   needed. It is written down because the failure mode is a HANG, not a wrong
--   answer, and because a future "let us make DIVCLK much faster" would walk
--   into it. If B3 ever comes back with a DIVCLK far above MCLK, re-check this.
--
--   Is it an accelerator at all? 32 DIVCLK at 50 MHz = 640 ns, plus about four
--   MCLK cycles of crossing = roughly 840 ns, against 32 MCLK cycles at 20 MHz
--   = 1600 ns for the same work in the core's own domain. So yes, about 2x --
--   which is the entire justification for the separate clock and the crossings.
--============================================================================
-- WHY THE RESULT BUSES ARE **NOT** SYNCHRONISED, which looks like an omission
--
--   SYNC.vhd's header states the rule it must be used under: a two-stage
--   synchroniser on a MULTI-BIT bus is only sound when the bus is stable across
--   the crossing, because individual bits can resolve on different destination
--   cycles and a changing bus can present a value that never existed.
--
--   Running Quotient and Residue through synchronisers would therefore be worse
--   than useless -- it would be exactly the misuse that header warns about,
--   because those buses are still CHANGING while the engine iterates.
--
--   What makes reading them directly correct: the MCLK side only samples them
--   after it has seen DIVBUSY fall THROUGH a two-stage synchroniser. DIVBUSY
--   really fell at the same DIVCLK edge that produced the final result, and the
--   synchroniser adds about two MCLK periods on top -- so by the time this unit
--   captures, the engine has been idle and its outputs constant for at least two
--   MCLK cycles. Synchronise the CONTROL signal, hold the data stable, sample
--   the data once the control has arrived. That is the pattern SYNC.vhd
--   prescribes, applied.
--
-- WHY THE OPERANDS ARE REGISTERED BEFORE CROSSING -- a deliberate deviation
--   Figure 10b draws Read data1 and Read data2 going STRAIGHT into the Sync
--   block, i.e. live register-file outputs. This unit latches them first, on the
--   cycle it accepts the operation, and crosses the latched copies with
--   GEN_SRC_REG => FALSE.
--
--   Same reason as above: the crossing is only sound if the bus is stable for
--   its whole duration, and a live RF output is only stable while the div
--   instruction is the current instruction. That happens to be true here because
--   the core stalls -- but it is true by accident of the stall rather than by
--   construction, and a latched copy is stable by construction. 64 flip-flops
--   for a crossing that cannot be argued about later.
--============================================================================
-- SIGNED div / rem, and the ONE case that needs special hardware
--
--   RV32IM (and the benchmarks -- RV32IM/test1 and Interrupt-based IO test1 and
--   test4 use `div` and `rem`, the SIGNED opcodes, never divu/remu):
--     quotient truncates toward zero;  remainder takes the DIVIDEND's sign.
--   So: divide magnitudes, then negate the quotient if the signs differed and
--   the remainder if the dividend was negative.
--
--   THE OVERFLOW CASE NEEDS NOTHING. div(-2^31, -1) must give -2^31. Here:
--   |-2^31| is 0x80000000 (negating it gives itself), |-1| is 1, so the engine
--   returns quotient 0x80000000; the signs agree so no negation is applied; and
--   0x80000000 IS -2^31. The RISC-V overflow rule falls out of the arithmetic.
--
--   THE ZERO-DIVISOR CASE DOES NEED HARDWARE, and it is the one place the
--   obvious wrapper is wrong. RISC-V requires div(x, 0) = -1 for EVERY dividend,
--   and rem(x, 0) = x. The engine naturally returns quotient all-ones and
--   residue |x|. For a POSITIVE dividend the sign correction leaves all-ones,
--   which is -1: correct by luck. For a NEGATIVE dividend the signs differ, the
--   correction negates 0xFFFFFFFF, and the answer comes out as +1: wrong.
--   So divisor = 0 bypasses the sign correction entirely --
--        quotient  <= all ones      (= -1 signed, = 2^32-1 unsigned)
--        remainder <= the ORIGINAL dividend, sign and all
--   -- and that single rule is simultaneously correct for div, divu, rem and
--   remu, which is why there is one comparator here and not four cases.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.aux_package.all;


ENTITY div_unit IS
	generic(
		N	: integer := 32
	);
	PORT(
		--Inputs
		mclk_i		: IN	STD_LOGIC;						-- core clock
		divclk_i	: IN	STD_LOGIC;						-- accelclk, the fast clock
		rst_i		: IN	STD_LOGIC;						-- async, active high, MCLK domain

		start_i		: IN	STD_LOGIC;						-- Figure 3's DIVstart. A LEVEL: it stays
															-- asserted for the whole stall, because the
															-- Control Unit decodes it combinationally.
		signed_i	: IN	STD_LOGIC;						-- '1' = div/rem, '0' = divu/remu
		dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);	-- Figure 3's Ain
		divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);	-- Figure 3's Bin

		--Outputs
		busy_o		: OUT	STD_LOGIC;						-- observation, and F13's interrupt block
		done_o		: OUT	STD_LOGIC;						-- results valid -- BUILD THE STALL ON THIS
		quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);	-- Figure 3's Quotient
		remainder_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)	-- Figure 3's Rem
	);
END div_unit;

--============================================================================
ARCHITECTURE structure OF div_unit IS

	-- LAUNCH exists to give the operand crossings a head start over the enable
	-- crossing. See the note at the state itself -- it is a one-cycle state that
	-- fixes a real race, not padding.
	TYPE state_t IS (IDLE, LAUNCH, WAIT_RISE, WAIT_FALL, DONE);

	SIGNAL state_q		: state_t := IDLE;
	SIGNAL ena_q		: STD_LOGIC := '0';		-- level, crosses to DIVENA

	-- Latched operands and sign bookkeeping (MCLK)
	SIGNAL a_q			: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');	-- |dividend|
	SIGNAL b_q			: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');	-- |divisor|
	SIGNAL dvd_q		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');	-- the ORIGINAL dividend
	SIGNAL qneg_q		: STD_LOGIC := '0';		-- negate the quotient
	SIGNAL rneg_q		: STD_LOGIC := '0';		-- negate the remainder
	SIGNAL bzero_q		: STD_LOGIC := '0';		-- divisor was zero

	-- Captured raw results (MCLK)
	SIGNAL qraw_q		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL rraw_q		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');

	-- Combinational absolute value / sign extraction (MCLK)
	SIGNAL aneg_w		: STD_LOGIC;
	SIGNAL bneg_w		: STD_LOGIC;
	SIGNAL aabs_w		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL babs_w		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	-- Crossings
	SIGNAL ena_sync_w	: STD_LOGIC_VECTOR(0 DOWNTO 0);	-- MCLK -> DIVCLK
	SIGNAL a_sync_w		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL b_sync_w		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL busy_sync_w	: STD_LOGIC_VECTOR(0 DOWNTO 0);	-- DIVCLK -> MCLK
	SIGNAL ena_vec_w	: STD_LOGIC_VECTOR(0 DOWNTO 0);
	SIGNAL busy_vec_w	: STD_LOGIC_VECTOR(0 DOWNTO 0);

	-- Engine outputs (DIVCLK domain, read directly -- see the header)
	SIGNAL eng_busy_w	: STD_LOGIC;
	SIGNAL eng_quot_w	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL eng_res_w	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	CONSTANT ONES_N		: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '1');
	CONSTANT ZEROS_N	: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');

BEGIN
	--=======================================================================
	-- MCLK: magnitudes and signs, combinational
	--=======================================================================
	-- signed_i gates the sign bit, so at signed_i = '0' the operands pass
	-- through untouched and the whole wrapper collapses to divu/remu.
	aneg_w <= signed_i AND dividend_i(N-1);
	bneg_w <= signed_i AND divisor_i(N-1);

	aabs_w <= STD_LOGIC_VECTOR(0 - signed(dividend_i)) WHEN aneg_w = '1' ELSE dividend_i;
	babs_w <= STD_LOGIC_VECTOR(0 - signed(divisor_i))  WHEN bneg_w = '1' ELSE divisor_i;

	--=======================================================================
	-- MCLK-side control
	--=======================================================================
	fsm : PROCESS(mclk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			state_q	<= IDLE;
			ena_q	<= '0';
			a_q		<= (OTHERS => '0');
			b_q		<= (OTHERS => '0');
			dvd_q	<= (OTHERS => '0');
			qneg_q	<= '0';
			rneg_q	<= '0';
			bzero_q	<= '0';
			qraw_q	<= (OTHERS => '0');
			rraw_q	<= (OTHERS => '0');
		ELSIF rising_edge(mclk_i) THEN
			CASE state_q IS

				WHEN IDLE =>
					IF start_i = '1' THEN
						-- Latch everything the operation needs, so nothing that
						-- crosses a clock boundary can move underneath it.
						a_q		<= aabs_w;
						b_q		<= babs_w;
						dvd_q	<= dividend_i;
						qneg_q	<= aneg_w XOR bneg_w;
						rneg_q	<= aneg_w;
						IF divisor_i = ZEROS_N THEN
							bzero_q <= '1';
						ELSE
							bzero_q <= '0';
						END IF;
						state_q	<= LAUNCH;
					END IF;

				WHEN LAUNCH =>
					-- ONE CYCLE, AND IT FIXES A REAL RACE. The enable and the two
					-- operand buses all cross into DIVCLK through their own
					-- two-stage synchronisers. Launch them on the SAME MCLK edge
					-- and there is nothing that guarantees the operand bits
					-- resolve no later than the enable bit: each synchroniser
					-- settles independently, so DIVENA can legitimately arrive one
					-- DIVCLK edge before a bit of Ain or Bin has settled -- and the
					-- engine would then load a half-updated operand and return a
					-- confidently wrong answer.
					--
					-- Holding the enable back by one MCLK cycle gives the data a
					-- head start of a full MCLK period (2.5 DIVCLK periods at the
					-- planned 20/50 MHz) on top of its own two stages, so the
					-- operands are stable at the engine before DIVENA can be seen.
					-- This is the standard rule for crossing a bus alongside its
					-- control: launch the data first, the control after.
					ena_q	<= '1';
					state_q	<= WAIT_RISE;

				WHEN WAIT_RISE =>
					-- Wait to SEE the engine busy. Skipping this and testing for
					-- "not busy" would succeed immediately, before the enable had
					-- even crossed into the DIVCLK domain.
					IF busy_sync_w(0) = '1' THEN
						state_q <= WAIT_FALL;
					END IF;

				WHEN WAIT_FALL =>
					IF busy_sync_w(0) = '0' THEN
						-- Safe to sample the engine's outputs directly: they have
						-- been constant since before this falling edge crossed
						-- two synchroniser stages. See the header.
						qraw_q	<= eng_quot_w;
						rraw_q	<= eng_res_w;
						ena_q	<= '0';
						state_q	<= DONE;
					END IF;

				WHEN DONE =>
					-- Hold the result until the core has taken it, i.e. until the
					-- div instruction retires and DIVstart drops.
					IF start_i = '0' THEN
						state_q <= IDLE;
					END IF;

			END CASE;
		END IF;
	END PROCESS fsm;

	busy_o <= '1' WHEN state_q = LAUNCH OR state_q = WAIT_RISE OR
					   state_q = WAIT_FALL ELSE '0';
	done_o <= '1' WHEN state_q = DONE ELSE '0';

	--=======================================================================
	-- Crossings -- Figure 10b's Sync block, plus the return path no figure draws
	--
	-- GEN_SRC_REG => FALSE on every one of them, and that is not a shortcut:
	-- each source is ALREADY a register in its own domain (ena_q, a_q, b_q in
	-- MCLK; the engine's busy_q in DIVCLK), which is exactly the condition
	-- SYNC.vhd documents for switching the launch stage off. src_clk_i is unused
	-- in that branch and is tied off.
	--=======================================================================
	ena_vec_w(0) <= ena_q;

	S_ENA : sync
	generic map(DATA_WIDTH => 1, STAGES => 2, GEN_SRC_REG => FALSE)
	PORT MAP(src_clk_i => '0', dst_clk_i => divclk_i, rst_i => rst_i,
			 d_i => ena_vec_w, q_o => ena_sync_w);

	S_A : sync									-- Figure 10b: Read data1 -> Ain
	generic map(DATA_WIDTH => N, STAGES => 2, GEN_SRC_REG => FALSE)
	PORT MAP(src_clk_i => '0', dst_clk_i => divclk_i, rst_i => rst_i,
			 d_i => a_q, q_o => a_sync_w);

	S_B : sync									-- Figure 10b: Read data2 -> Bin
	generic map(DATA_WIDTH => N, STAGES => 2, GEN_SRC_REG => FALSE)
	PORT MAP(src_clk_i => '0', dst_clk_i => divclk_i, rst_i => rst_i,
			 d_i => b_q, q_o => b_sync_w);

	busy_vec_w(0) <= eng_busy_w;

	S_BUSY : sync								-- the direction no figure draws
	generic map(DATA_WIDTH => 1, STAGES => 2, GEN_SRC_REG => FALSE)
	PORT MAP(src_clk_i => '0', dst_clk_i => mclk_i, rst_i => rst_i,
			 d_i => busy_vec_w, q_o => busy_sync_w);

	--=======================================================================
	-- The engine -- Figure 9, unchanged and unsigned
	--=======================================================================
	-- DIVRST is tied to the system reset, and so is every synchroniser above.
	-- Both DIV_ACCEL.vhd and SYNC.vhd say their reset should be synchronised to
	-- the DESTINATION domain, and rst_i here is an MCLK-domain signal reaching
	-- DIVCLK-domain registers. That is a genuine simplification, taken knowingly
	-- rather than missed: reset is asserted while nothing is running and released
	-- long before any divide is issued, so its recovery window never overlaps an
	-- operation, and Phase 4C additionally holds it until the PLLs lock. What
	-- would break it is a design that resets MID-divide and expects a defined
	-- result on the next one -- nothing does, and the engine's own DIVRST test
	-- (7A property P5) covers abort-and-recover within one clock domain.
	ENGINE : div_accel
	generic map(N => N)
	PORT MAP(divclk_i	=> divclk_i,
			 divrst_i	=> rst_i,
			 divena_i	=> ena_sync_w(0),
			 dividend_i	=> a_sync_w,
			 divisor_i	=> b_sync_w,
			 divbusy_o	=> eng_busy_w,
			 quotient_o	=> eng_quot_w,
			 residue_o	=> eng_res_w);

	--=======================================================================
	-- Sign correction, and the zero-divisor rule that overrides it
	--=======================================================================
	quotient_o  <= ONES_N WHEN bzero_q = '1' ELSE
				   STD_LOGIC_VECTOR(0 - signed(qraw_q)) WHEN qneg_q = '1' ELSE
				   qraw_q;

	remainder_o <= dvd_q  WHEN bzero_q = '1' ELSE
				   STD_LOGIC_VECTOR(0 - signed(rraw_q)) WHEN rneg_q = '1' ELSE
				   rraw_q;

END structure;
