--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- unsigned multicycle division accelerator
--
-- Implements Figure 9 of `Auxiliary/Final Project 2026 definition.pdf` (page 9),
-- "Multicycle-based architecture of Unsigned Divisor accelerator". Figure 3
-- (page 4) labels the same block "Divider Accelerator 32-bit", which is where
-- this file's name comes from. Closes gap G-301.
--
-- SCOPE, STATED UP FRONT
--   This is the UNSIGNED engine only -- Phase 7A. It is not wired into the core
--   yet. The signed div/rem wrapper, the DIVstart/PCHold stall handshake, the
--   write-back mux and the two clock-domain crossings are Phase 7B, which needs
--   the DIVCLK that Phase 4B produces. Splitting it this way is the same reason
--   4A came before 4B and 5A before 5B: the arithmetic is provable on its own,
--   exhaustively, with no dependence on the core and no open question attached.
--============================================================================
-- WHAT FIGURE 9 ACTUALLY SHOWS, AND WHAT IT DOES NOT
--
--   LEGIBLE, and implemented exactly:
--     - a "Dividend left shift-register" drawn as TWO N-bit halves (the figure
--       prints "N-1 ... 0" twice, either side of a divider mark) with a '0'
--       shifted in at the far LSB, and a "Load" control on it;
--     - a "Divisor register" loaded from the external Divisor;
--     - a "Subtractor" computing "Result = Y - X" carrying a "Non-negative
--       Result" flag;
--     - a "Quotient left shift-register";
--     - outputs "Residue" and "Quotient", both N bits;
--     - control DIVCLK, DIVRST, DIVENA in and DIVBUSY out;
--     - the sentence under the figure: "The divider results are ready after N
--       DIVCLK cycles after loading a value to the second operand DIVISOR, i.e.,
--       32 DIVCLK cycles (fast clock) in our case of N=32."
--
--   NOT LEGIBLE, and therefore an explicit interpretation rather than a reading:
--     the exact bit-slice wiring. The figure is a raster image and at its
--     resolution the individual wires between the shift register, the subtractor
--     inputs and the residue output cannot be traced with confidence.
--
--   **Interpretation.** The blocks are connected as classical restoring
--   division: the upper half of the shift register is the running remainder A,
--   the lower half holds the not-yet-consumed dividend bits, each cycle shifts
--   the pair left by one, Y is the upper half after that shift, X is the divisor
--   register, and the non-negative flag both selects Y-X over Y and becomes the
--   next quotient bit. This is the only assignment of Figure 9's blocks that
--   makes them produce a correct quotient and residue, which is the argument for
--   it -- not that it was read off the page. It is verified EXHAUSTIVELY at N=8
--   (all 65536 operand pairs) in TB/RV32IMscMCU/tb_div_accel.vhd.
--   **Falsified by** course staff describing a different interconnection.
--============================================================================
-- TWO RESULTS THAT FALL OUT OF THE ALGORITHM, WORTH STATING BECAUSE THEY LOOK
-- LIKE THINGS THAT WOULD NEED EXTRA HARDWARE AND DO NOT
--
--   1. DIVIDE BY ZERO NEEDS NO SPECIAL CASE AT ALL.
--      With X = 0 the test Y >= X is true on every one of the N cycles, so every
--      quotient bit is 1 and every subtraction takes 0 away, which leaves A
--      collecting the dividend bits as they shift through. After N cycles:
--          QUOTIENT = all ones,  RESIDUE = the dividend.
--      Hanan, on the course forum: divide-by-zero would normally raise an
--      exception status, but "in your case there is no support for that and in
--      practice the division result will be all ones" (DOC/03, F4). The RISC-V
--      unprivileged spec independently requires exactly the same pair for divu
--      and remu. Three sources, one behaviour, zero exception logic. There is no
--      divide-by-zero branch below because none is needed -- if you go looking
--      for one, this is why it is absent.
--
--   2. Y IS N BITS WIDE AND THAT IS ENOUGH -- NOTHING OVERFLOWS.
--      The obvious worry is that 2*A + b needs N+1 bits, since A can be as large
--      as X-1. It cannot happen. After k steps A is exactly (the value of the top
--      k bits of the dividend) minus (partial quotient)*X, and the partial
--      quotient is non-negative, so A is at most the value of the top k bits,
--      which is strictly less than 2**k <= 2**N. The bit shifted out of the top
--      of the upper half is therefore always '0'. This is why Figure 9's 2N-bit
--      register with an N-bit subtractor is correct for every divisor, including
--      divisors at or above 2**31 -- the case that would break a naive width
--      argument. The exhaustive N=8 sweep covers every instance of it.
--============================================================================
-- THE SUBTRACTOR: WHY THE "-" OPERATOR AND NOT Lab4/AdderSub.vhd
--   Asked on the forum whether the subtractor must be built from full adders,
--   Hanan answered "You may use the subtraction operator" and to check what
--   Quartus synthesises (DOC/03, F5). Taken, because this unit sits on DIVCLK --
--   the FAST clock -- so its 32-bit carry path is the critical path of the whole
--   accelerator, and an inferred subtractor maps onto the Cyclone IV carry chain
--   while a hand-built ripple of discrete XOR/OR gates may not.
--
--   The structural alternative is a real one and is already in the material:
--   Auxiliary/Lab 5/Auxilary/Lab4/DUT/AdderSub.vhd, generic n-bit, built from
--   Lab4/DUT/FA.vhd. Its mapping onto this file is exact, which is worth writing
--   down so nobody has to re-derive it if the report wants that PPA row:
--          x => divisor,  y => the shifted upper half,  sub_cont => "001"
--          s => Y-X,      cout => the Non-negative Result flag
--   (for sub_cont = "001" it forms y + not(x) + 1, and its carry-out is exactly
--   "y >= x"). Swapping it in is a component instantiation in place of the two
--   concurrent assignments below. Deliberately NOT done here: it is a PPA
--   experiment, not a correctness question, and Phase 7A is the correctness step.
--============================================================================
-- THE CONTROL SEQUENCE, AND THE ONE PLACE IT IS NOT OBVIOUS
--
--   IDLE  -- DIVENA seen high on a rising DIVCLK edge: this is Figure 9's Load.
--            The shift register takes 0...0 & Dividend, the divisor register
--            takes Divisor, the quotient register clears, the counter takes N,
--            and DIVBUSY rises. Call this edge 0.
--   RUN   -- edges 1..N, one iteration each. On edge N the counter reaches its
--            last value and DIVBUSY falls, so DIVBUSY is high across exactly N
--            DIVCLK periods and the results are valid N cycles after the Load
--            edge -- which is the page 9 sentence, met literally.
--   DONE  -- results held. Returns to IDLE only once DIVENA is low again.
--
--   THAT LAST CLAUSE IS NOT DECORATION, IT IS THE WHOLE HANDSHAKE.
--   Figure 3 makes DIVstart an output of the Control Unit, and the Control Unit
--   is combinational decode of the current instruction. While the core is
--   stalled on a div, the div is still the current instruction, so DIVstart --
--   and therefore DIVENA -- stays asserted for the entire operation and beyond.
--   A start condition of "DIVENA is high" alone would relaunch the divide
--   immediately on the cycle after it finished, forever, and the core would
--   never see a result. So a start is armed once per assertion: the engine will
--   not reload until it has seen DIVENA low. Property P7 of the testbench holds
--   DIVENA high for twenty cycles past completion and checks that nothing
--   restarts and the outputs do not move.
--
--   And the same fact, from the other side, is Phase 7B's main design item, put
--   here so it is not rediscovered the hard way: THE CORE CANNOT STALL ON
--   "DIVBUSY IS HIGH". DIVstart has to cross into DIVCLK (two stages), the
--   engine then raises DIVBUSY, and DIVBUSY has to cross back into MCLK (two
--   stages). For several MCLK cycles after the div issues, DIVBUSY still reads
--   low, so a naive "stall while busy" stalls for nothing at all and the core
--   runs straight past its own divide. The stall must begin on the core's own
--   DIVstart and end on a seen-high-then-low DIVBUSY.
--
-- DIVRST
--   Hanan describes it as initialising the divider's internal quotient shift
--   register "in parallel with writing the Dividend, Divisor values into the
--   core's registers" (DOC/03, F2) -- so it is a functional initialise issued by
--   the core, not only a power-on reset. It is asynchronous and active high,
--   matching every other clocked element in this design (see GPO_PORT.vhd for
--   the same argument), and it clears the whole engine rather than just the
--   quotient register. Clearing more than Hanan named cannot change any result,
--   because everything it clears is reloaded by the next Load; what it buys is
--   that a read taken before the first divide returns zero instead of 'U'.
--
--   **It must arrive already synchronised to DIVCLK.** It originates in the MCLK
--   domain, and an asynchronous reset released in one domain against registers
--   clocked in another is a recovery/removal violation. That is not a gap: it is
--   what Figure 3's `Sync` block in front of this accelerator is for, and the
--   block exists -- DUT/RV32IMscMCU/SYNC.vhd, Phase 4A. Phase 7B wires it.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY div_accel IS
	generic(
		-- Figure 9 is drawn generically in N; the sentence under it fixes N = 32
		-- "in our case". Kept generic so the testbench can instantiate a narrow
		-- copy and sweep it exhaustively -- the algorithm is width-independent,
		-- so that sweep is worth far more than any sample at 32 bits.
		N	: integer := 32
	);
	PORT(
		--Inputs
		divclk_i	: IN	STD_LOGIC;								-- DIVCLK, the fast clock (accelclk)
		divrst_i	: IN	STD_LOGIC;								-- DIVRST, async active high, synchronised to DIVCLK by the caller
		divena_i	: IN	STD_LOGIC;								-- DIVENA, Figure 9's Load trigger
		dividend_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);			-- Figure 3's Ain
		divisor_i	: IN	STD_LOGIC_VECTOR(N-1 DOWNTO 0);			-- Figure 3's Bin

		--Outputs
		divbusy_o	: OUT	STD_LOGIC;								-- DIVBUSY
		quotient_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0);			-- Quotient
		residue_o	: OUT	STD_LOGIC_VECTOR(N-1 DOWNTO 0)			-- Residue
	);
END div_accel;

--============================================================================
ARCHITECTURE behavior OF div_accel IS

	TYPE state_t IS (IDLE, RUN, DONE);

	-- Initial values give the engine a defined power-up state before any reset
	-- has been seen, so a waveform opened at 0 ns shows zeros and not 'U'.
	-- Precedent: Auxiliary/Lab 5/Auxilary/Lab4/DUT/fpga_hw_interface.vhd, and
	-- GPO_PORT.vhd in this directory for the same reason.
	SIGNAL state_q	: state_t := IDLE;
	SIGNAL busy_q	: STD_LOGIC := '0';

	-- Figure 9's dividend left shift-register: 2N bits, upper half = the running
	-- remainder A, lower half = the dividend bits not yet consumed.
	SIGNAL sr_q		: STD_LOGIC_VECTOR(2*N-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL dvsr_q	: STD_LOGIC_VECTOR(N-1 DOWNTO 0)   := (OTHERS => '0');	-- Divisor register
	SIGNAL qsr_q	: STD_LOGIC_VECTOR(N-1 DOWNTO 0)   := (OTHERS => '0');	-- Quotient left shift-register
	SIGNAL cnt_q	: INTEGER RANGE 0 TO N := 0;

	-- One iteration, combinational. Named after the figure wherever the figure
	-- has a name for the thing.
	SIGNAL shifted_w	: STD_LOGIC_VECTOR(2*N-1 DOWNTO 0);
	SIGNAL y_w			: STD_LOGIC_VECTOR(N-1 DOWNTO 0);	-- Y, the subtractor's top input
	SIGNAL diff_w		: STD_LOGIC_VECTOR(N DOWNTO 0);		-- Y-X, one bit wider to expose the borrow
	SIGNAL nonneg_w		: STD_LOGIC;						-- "Non-negative Result"
	SIGNAL a_next_w		: STD_LOGIC_VECTOR(N-1 DOWNTO 0);
	SIGNAL sr_next_w	: STD_LOGIC_VECTOR(2*N-1 DOWNTO 0);
	SIGNAL qsr_next_w	: STD_LOGIC_VECTOR(N-1 DOWNTO 0);

	CONSTANT ZEROS_N	: STD_LOGIC_VECTOR(N-1 DOWNTO 0) := (OTHERS => '0');

BEGIN
	-- Elaboration-time, so a bad generic fails at compile rather than producing a
	-- quietly wrong divider. N=1 would make the quotient shift register's feedback
	-- slice a null range: legal VHDL, but not a divider anyone asked for.
	assert N >= 2
		report "div_accel: N must be at least 2. Figure 9's case is N = 32."
		severity failure;

	--=======================================================================
	-- One restoring-division step. Reads only registered state, so it is pure
	-- combinational logic with no process -- nothing here can be mistaken for a
	-- Mixed PROCESS, which Hanan's material rules out (Auxiliary/hanan/
	-- Sequential Code part7: "Don't write Mixed PROCESS, is non synthesizable").
	--=======================================================================
	-- Shift the whole 2N-bit register left by one, '0' into the LSB, exactly as
	-- the figure draws at its right edge.
	shifted_w	<= sr_q(2*N-2 DOWNTO 0) & '0';

	-- Y is the upper half AFTER the shift; X is the divisor register.
	y_w			<= shifted_w(2*N-1 DOWNTO N);

	-- Result = Y - X. Computed one bit wide to keep the borrow: with both
	-- operands zero-extended, bit N of the difference is the borrow, so it is
	-- '1' exactly when Y < X. Hence nonneg = not borrow, and it needs no separate
	-- comparator -- one subtractor, one bit of it read twice, which is what the
	-- figure draws.
	diff_w		<= STD_LOGIC_VECTOR(unsigned('0' & y_w) - unsigned('0' & dvsr_q));
	nonneg_w	<= NOT diff_w(N);

	-- The restore: keep the difference when it is non-negative, otherwise keep Y
	-- unchanged. This is the feedback arrow from the subtractor back into the
	-- shift register's upper half.
	a_next_w	<= diff_w(N-1 DOWNTO 0) WHEN nonneg_w = '1' ELSE y_w;
	sr_next_w	<= a_next_w & shifted_w(N-1 DOWNTO 0);

	-- The same flag is the quotient bit, shifted in at the quotient register's
	-- LSB. One wire, two jobs -- the figure's "Non-negative Result" line.
	qsr_next_w	<= qsr_q(N-2 DOWNTO 0) & nonneg_w;

	--=======================================================================
	-- Control. Pure synchronous: every signal it assigns is a register.
	--=======================================================================
	div_fsm : PROCESS(divclk_i, divrst_i)
	BEGIN
		IF divrst_i = '1' THEN
			state_q	<= IDLE;
			busy_q	<= '0';
			sr_q	<= (OTHERS => '0');
			dvsr_q	<= (OTHERS => '0');
			qsr_q	<= (OTHERS => '0');
			cnt_q	<= 0;
		ELSIF rising_edge(divclk_i) THEN
			CASE state_q IS

				WHEN IDLE =>
					-- Figure 9's Load. Both operand registers and the counter are
					-- taken on this one edge; the first iteration is the NEXT edge,
					-- which is what makes the results land exactly N cycles after
					-- the load rather than N+1.
					IF divena_i = '1' THEN
						sr_q	<= ZEROS_N & dividend_i;
						dvsr_q	<= divisor_i;
						qsr_q	<= (OTHERS => '0');
						cnt_q	<= N;
						busy_q	<= '1';
						state_q	<= RUN;
					END IF;

				WHEN RUN =>
					sr_q	<= sr_next_w;
					qsr_q	<= qsr_next_w;
					cnt_q	<= cnt_q - 1;
					-- cnt_q still reads its pre-edge value here, so cnt_q = 1 is
					-- the Nth and last iteration.
					IF cnt_q = 1 THEN
						busy_q	<= '0';
						state_q	<= DONE;
					END IF;

				WHEN DONE =>
					-- Results held. Re-arm only after DIVENA has gone low, or a
					-- level-held DIVstart would relaunch the divide forever -- see
					-- the handshake note in the header.
					IF divena_i = '0' THEN
						state_q	<= IDLE;
					END IF;

			END CASE;
		END IF;
	END PROCESS div_fsm;

	--=======================================================================
	-- Outputs
	--=======================================================================
	-- Straight off a flip-flop, not decoded from state_q. Figure 10a's prose is
	-- explicit that a signal driven by combinational logic must be registered
	-- before it crosses a clock boundary, and DIVBUSY's whole job is to cross
	-- back into MCLK. Registering it here means the crossing is correct even if a
	-- later caller forgets the launch stage.
	divbusy_o	<= busy_q;

	-- Ungated, as the figure draws them: during RUN they show the partial
	-- quotient and partial remainder. That is not a defect and it is not a
	-- hazard either -- the core only samples them once DIVBUSY has fallen. It is
	-- also what makes DIVRST meaningful, since clearing the quotient register is
	-- what stops a read before the first divide from returning stale bits.
	residue_o	<= sr_q(2*N-1 DOWNTO N);
	quotient_o	<= qsr_q;

END behavior;
