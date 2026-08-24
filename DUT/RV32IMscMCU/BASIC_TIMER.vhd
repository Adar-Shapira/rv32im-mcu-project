--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- Basic Timer core (Figure 7, clause 6.ii)
--
-- Phase 8A. The timer as a leaf: counter, prescaler, compare, PWM output unit
-- and input capture, with the five interface registers. Wiring it onto the
-- MMIO bus and into the interrupt controller is Phase 8B. Same split as every
-- phase before it: the leaf is provable alone, the wiring is a separate risk.
--============================================================================
-- WHAT ALREADY EXISTED, AND WAS TAKEN -- checked before writing, per the
-- standing rule: this project continues Lab 5, and Labs 3/4 are in the repo.
--
--   Auxiliary/Lab4/DUT/pwm.vhd IS MOST OF THIS TIMER'S SKELETON, and was read
--   in full first. The mapping, line by line:
--
--     pwm.vhd                              this file
--     ------------------------------------ ----------------------------------
--     timer, 16-bit, wraps at Y            btcnt_q, 32-bit, wraps at BTCL0
--       "IF timer >= Y-1 THEN timer<=0"      (the wrap condition changes to
--                                             F17's "restarts after reaching
--                                             BTCL0" -- see below)
--     ena  (gates updates)                 BTOUTEN gates the OUTPUT register
--                                          BTHOLD  gates the COUNTER
--                                          (pwm.vhd has one enable for both;
--                                           Figure 7 splits them, so each half
--                                           keeps its own)
--     ALUFN "000" Mode 0: Set/Reset        BTOUTMD = '0'  Output Mode0
--       set at timer=0, clear at timer=X     set at btcnt=0, clear at BTCL1
--     ALUFN "001" Mode 1: Reset/Set        BTOUTMD = '1'  Output Mode1
--       clear at timer=0, set at timer=X     clear at btcnt=0, set at BTCL1
--     ALUFN "010" Mode 2: Toggle           DROPPED -- BTOUTMD is one bit and
--                                          Figure 8 draws exactly two traces
--     X (duty compare)                     BTCL1
--     Y (period)                           BTCL0
--     registered PWMout (pwm_reg)          identical, kept registered
--
--   Searched for any OTHER timer/counter/capture precedent in Labs 3, 4, 5:
--   none. (RV32IM_PIPE_CORE's CLKCNT/STCNT are event counters with no compare,
--   no prescaler and no output -- not a precedent for this.)
--
-- WHAT THE SPECIFICATION FIXES (recovered from the PDF rasters -- DOC/02 s3):
--   BTCTL1 (0x201C):  [7] BTOUTMD  [6] BTOUTEN  [5] BTHOLD  [4:3] BTSSEL
--                     [2] BTCLR    [1:0] BTINT
--   BTCTL2 (0x201D):  [3:2] CAPMD  {0,3: disabled, 1: rising, 2: falling}
--                     [1:0] CAPISEL {0: CAPIN1 pin, 1: CAPIN2 pin,
--                                    2: VCC('1'),   3: GND('0')}
--   BTSSEL: 00 -> SMCLK   01 -> SMCLK/2   10 -> SMCLK/4   11 -> SMCLK/8
--   BTCMPR0/BTCMPR1 (Word): compare values, auto-transferred to the BTCL0/
--   BTCL1 shadow latches. BTCAPR (Word): BTCNT captured on the input event.
--
-- FORUM ANSWERS BUILT IN, EXACTLY AS GIVEN:
--   F16  RESET clears ONLY the interface registers -- BTCTL1, BTCTL2, BTCAPR,
--        BTCMPR0, BTCMPR1. **BTCNT is NOT reset.** That is why the counter
--        lives in a process with no reset arm (it has a power-up initial value
--        for simulation, cleared only by BTCLR).
--   F17  "the count always restarts after reaching BTCL0 (on the rise of
--        EQU0)". Implemented literally: EQU0 = (BTCNT = BTCL0), and the next
--        counting tick loads zero. The counter therefore shows BTCL0 for one
--        tick, so THE PERIOD IS BTCL0+1 TICKS, not BTCL0.
--
--        CONSEQUENCE, REPORTED RATHER THAN SILENTLY FIXED: FREQ_5K = 500 at
--        BTSSEL=3 then gives 20 MHz / 8 / 501 = 4990 Hz, not 5000. Exactly
--        5 kHz needs BTCMPR0 = 499. Same class as the SEC_PERIOD factor-8
--        discrepancy (question B2): the benchmark constants and the hardware
--        definition disagree slightly, the hardware follows the definition,
--        and the discrepancy is a finding. Recorded in DOC/02.
--
-- BTINT -- NO LONGER A BLIND GUESS. Question B4 asked which two-bit code
--   selects which BTIFG source ("three options", four mux positions). The
--   BENCHMARKS pin two of the four codes:
--     io_map.s:  .eqv BTINT2 0x02  -- and test4/01_func.s:156-158 writes
--     BTCTL1=(BTHOLD=1,BTCLR=1,BTINT=2) precisely when configuring INPUT
--     CAPTURE; every compare-interrupt test runs with BTINT=0.
--   So:  00 -> EQU0   (benchmark-pinned)      10 -> capture (benchmark-pinned)
--        01 -> EQU1   (the only source left)  11 -> none    (reserved)
--   -- which is exactly "three options" in two bits. 01 and 11 are assumption
--   A20; a different answer to B4 changes one selected-signal-assignment.
--
-- THE SHADOW LATCHES (assumption A21): Figure 7 draws BTCL0/BTCL1 loaded from
--   BTCMPR0/BTCMPR1 through latches enabled by "HEU0" -- a label defined
--   nowhere (open question P1). Implemented as immediate transfer on the bus
--   write, which is indistinguishable from any deferred-update scheme in every
--   supplied benchmark (they all configure the compare registers while the
--   timer is held). Falsified by HEU0 turning out to mean update-on-EQU0; the
--   change is one enable term on the shadow assignment.
--
-- BUS-SIDE CONVENTIONS -- the ones Phase 5A established and F15 confirmed:
--   byte registers take data_i(7 DOWNTO 0) whatever the byte address (A1..A0
--   only SELECT the register; BTCTL2 at odd 0x201D is legal); Word registers
--   take all 32 bits. Writes to BTCAPR are ignored -- it is capture hardware's.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY basic_timer IS
	generic(
		DATA_WIDTH	: integer := 32
	);
	PORT(
		--Inputs
		clk_i			: IN	STD_LOGIC;		-- SMCLK (pclk_w at the top level)
		rst_i			: IN	STD_LOGIC;		-- active high -- clears ONLY the interface registers (F16)

		-- write side, straight from the Phase 5 bus: one CS per SFR word
		ctl_cs_i		: IN	STD_LOGIC;		-- word 7: BTCTL1 / BTCTL2
		cmpr0_cs_i		: IN	STD_LOGIC;		-- word 8: BTCMPR0
		cmpr1_cs_i		: IN	STD_LOGIC;		-- word 9: BTCMPR1
		MemWrite_i		: IN	STD_LOGIC;
		lane0_i			: IN	STD_LOGIC;		-- A1A0=00 -> BTCTL1
		lane1_i			: IN	STD_LOGIC;		-- A1A0=01 -> BTCTL2
		data_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

		-- capture pins (F18: three pins on the expansion header; B1 pins them)
		capin1_i		: IN	STD_LOGIC := '0';
		capin2_i		: IN	STD_LOGIC := '0';

		--Outputs
		pwm_o			: OUT	STD_LOGIC;		-- PWMout, to the third header pin
		btifg_set_o		: OUT	STD_LOGIC;		-- one tick-wide event pulse, per BTINT (Phase 9 latches it)

		-- read-back (Phase 8B puts these behind BidirPin, like every SFR read)
		btctl1_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		btctl2_o		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		btcmpr0_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
		btcmpr1_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
		btcapr_o		: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
		btcnt_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)		-- observation / SignalTap
	);
END basic_timer;

--============================================================================
ARCHITECTURE behavior OF basic_timer IS

	-- Interface registers -- the five F16 names. Reset clears them; power-up
	-- initial values keep a waveform readable before the first reset.
	SIGNAL btctl1_q		: STD_LOGIC_VECTOR(7 DOWNTO 0)  := (OTHERS => '0');
	SIGNAL btctl2_q		: STD_LOGIC_VECTOR(7 DOWNTO 0)  := (OTHERS => '0');
	SIGNAL btcmpr0_q	: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL btcmpr1_q	: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL btcapr_q		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	-- The Figure 7 shadow latches. "Zero on RESET" per page 8.
	SIGNAL btcl0_q		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL btcl1_q		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

	-- NOT an interface register (F16): no reset arm anywhere below, only BTCLR.
	SIGNAL btcnt_q		: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL presc_q		: UNSIGNED(2 DOWNTO 0) := (OTHERS => '0');

	-- pwm.vhd's pwm_reg, kept registered exactly as Lab 4 has it.
	SIGNAL pwm_q		: STD_LOGIC := '0';

	-- capture path: two synchroniser stages plus one edge-delay stage. The
	-- pins are asynchronous board inputs, and an edge detector must compare
	-- two SETTLED samples -- comparing against the first flop would use a
	-- possibly-metastable value (the SYNC.vhd rule, applied inline because
	-- the edge detector needs the intermediate taps a sync instance hides).
	SIGNAL cap_s1_q		: STD_LOGIC := '0';
	SIGNAL cap_s2_q		: STD_LOGIC := '0';
	SIGNAL cap_d_q		: STD_LOGIC := '0';

	-- decoded fields
	SIGNAL btoutmd_w	: STD_LOGIC;
	SIGNAL btouten_w	: STD_LOGIC;
	SIGNAL bthold_w		: STD_LOGIC;
	SIGNAL btssel_w		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL btclr_w		: STD_LOGIC;
	SIGNAL btint_w		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL capmd_w		: STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL capisel_w	: STD_LOGIC_VECTOR(1 DOWNTO 0);

	SIGNAL tick_w		: STD_LOGIC;			-- one pulse per BTSSEL-divided period
	SIGNAL count_en_w	: STD_LOGIC;			-- tick, minus hold and clear
	SIGNAL equ0_w		: STD_LOGIC;
	SIGNAL equ1_w		: STD_LOGIC;
	SIGNAL equ0_ev_w	: STD_LOGIC;			-- the wrap tick itself
	SIGNAL equ1_ev_w	: STD_LOGIC;
	SIGNAL cap_src_w	: STD_LOGIC;
	SIGNAL cap_ev_w		: STD_LOGIC;

	CONSTANT ZEROS_C	: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0) := (OTHERS => '0');

BEGIN
	--=======================================================================
	-- Field decode (Figure 7's register layouts, DOC/02 s3)
	--=======================================================================
	btoutmd_w	<= btctl1_q(7);
	btouten_w	<= btctl1_q(6);
	bthold_w	<= btctl1_q(5);
	btssel_w	<= btctl1_q(4 DOWNTO 3);
	btclr_w		<= btctl1_q(2);
	btint_w		<= btctl1_q(1 DOWNTO 0);
	capmd_w		<= btctl2_q(3 DOWNTO 2);
	capisel_w	<= btctl2_q(1 DOWNTO 0);

	--=======================================================================
	-- Interface registers -- the ONLY things rst_i touches (F16)
	--=======================================================================
	regs : PROCESS(clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			btctl1_q	<= (OTHERS => '0');
			btctl2_q	<= (OTHERS => '0');
			btcmpr0_q	<= (OTHERS => '0');
			btcmpr1_q	<= (OTHERS => '0');
			btcapr_q	<= (OTHERS => '0');
			btcl0_q		<= (OTHERS => '0');
			btcl1_q		<= (OTHERS => '0');
		ELSIF rising_edge(clk_i) THEN
			IF MemWrite_i = '1' THEN
				-- Byte registers: the value is in data_i(7..0) whatever the
				-- byte address -- Phase 5A's benchmark-derived convention, and
				-- F15's byte-addressing answer. Same shape as gpo_port.
				IF ctl_cs_i = '1' AND lane0_i = '1' THEN
					btctl1_q <= data_i(7 DOWNTO 0);
				END IF;
				IF ctl_cs_i = '1' AND lane1_i = '1' THEN
					btctl2_q <= data_i(7 DOWNTO 0);
				END IF;
				-- Word registers own all four lanes (A12). The shadow latch
				-- takes the same value on the same edge -- assumption A21.
				IF cmpr0_cs_i = '1' THEN
					btcmpr0_q	<= data_i;
					btcl0_q		<= data_i;
				END IF;
				IF cmpr1_cs_i = '1' THEN
					btcmpr1_q	<= data_i;
					btcl1_q		<= data_i;
				END IF;
				-- No BTCAPR write arm: capture hardware owns it.
			END IF;
			-- Capture wins over nothing -- BTCAPR has no bus write to race.
			IF cap_ev_w = '1' THEN
				btcapr_q <= btcnt_q;
			END IF;
		END IF;
	END PROCESS regs;

	--=======================================================================
	-- Prescaler and tick -- Figure 7's BTSSEL mux, as a clock ENABLE rather
	-- than a divided clock net: a gated clock on an FPGA is a design smell
	-- (skew, no timing model), an enable is the standard fabric idiom, and
	-- nothing observable differs at the register boundary.
	--=======================================================================
	presc : PROCESS(clk_i)
	BEGIN
		IF rising_edge(clk_i) THEN
			-- free-running; BTCLR realigns it so a cleared timer starts its
			-- first divided period whole
			IF btclr_w = '1' THEN
				presc_q <= (OTHERS => '0');
			ELSE
				presc_q <= presc_q + 1;
			END IF;
		END IF;
	END PROCESS presc;

	WITH btssel_w SELECT tick_w <=
		'1'											WHEN "00",	-- SMCLK
		presc_q(0)									WHEN "01",	-- /2
		presc_q(1) AND presc_q(0)					WHEN "10",	-- /4
		presc_q(2) AND presc_q(1) AND presc_q(0)	WHEN "11",	-- /8
		'0'											WHEN OTHERS;

	count_en_w <= tick_w AND (NOT bthold_w) AND (NOT btclr_w);

	--=======================================================================
	-- BTCNT -- pwm.vhd's timer process, 16->32, with three deliberate changes:
	--   * wrap at BTCL0 exactly (F17: "restarts after reaching BTCL0"), not
	--     pwm.vhd's ">= Y-1" -- the compare EQU0 must actually fire, and
	--     pwm.vhd's wrap would stop the counter one short of it;
	--   * NO reset arm -- F16 says RESET does not clear BTCNT;
	--   * hold/clear come from BTCTL1 instead of one ena pin.
	--=======================================================================
	equ0_w <= '1' WHEN btcnt_q = btcl0_q ELSE '0';
	equ1_w <= '1' WHEN btcnt_q = btcl1_q ELSE '0';

	count : PROCESS(clk_i)
	BEGIN
		IF rising_edge(clk_i) THEN
			IF btclr_w = '1' THEN
				btcnt_q <= (OTHERS => '0');
			ELSIF count_en_w = '1' THEN
				IF equ0_w = '1' THEN
					btcnt_q <= (OTHERS => '0');		-- F17's restart
				ELSE
					btcnt_q <= STD_LOGIC_VECTOR(UNSIGNED(btcnt_q) + 1);
				END IF;
			END IF;
		END IF;
	END PROCESS count;

	-- Events fire on the counting tick that LEAVES the compare value -- the
	-- same ordering pwm.vhd uses ("IF timer = X" acts as the register leaves
	-- X). One pulse per period each, exactly tick-wide.
	equ0_ev_w <= equ0_w AND count_en_w;
	equ1_ev_w <= equ1_w AND count_en_w;

	--=======================================================================
	-- Output unit -- pwm.vhd lines 35-46 with the renames from the header.
	-- BTOUTEN is pwm.vhd's ena, and page 8's own wording -- "hold the PWMout
	-- signal value" -- says exactly what an update-enable does when low.
	--=======================================================================
	outunit : PROCESS(clk_i, rst_i)
	BEGIN
		IF rst_i = '1' THEN
			pwm_q <= '0';								-- pwm.vhd resets pwm_reg too
		ELSIF rising_edge(clk_i) THEN
			IF btouten_w = '1' THEN
				IF btoutmd_w = '0' THEN					-- Output Mode0: Set/Reset
					IF btcnt_q = ZEROS_C THEN
						pwm_q <= '1';
					ELSIF equ1_w = '1' THEN
						pwm_q <= '0';
					END IF;
				ELSE									-- Output Mode1: Reset/Set
					IF btcnt_q = ZEROS_C THEN
						pwm_q <= '0';
					ELSIF equ1_w = '1' THEN
						pwm_q <= '1';
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS outunit;

	--=======================================================================
	-- Input capture -- CAPISEL source mux, CAPMD edge select, BTCNT snapshot
	--=======================================================================
	WITH capisel_w SELECT cap_src_w <=
		capin1_i	WHEN "00",
		capin2_i	WHEN "01",
		'1'			WHEN "10",		-- VCC -- how test4 MEANT to force an edge
		'0'			WHEN OTHERS;	-- GND -- where test4's 0x07 actually leaves it

	capsync : PROCESS(clk_i)
	BEGIN
		IF rising_edge(clk_i) THEN
			cap_s1_q	<= cap_src_w;	-- may go metastable -- never compared
			cap_s2_q	<= cap_s1_q;	-- settled
			cap_d_q		<= cap_s2_q;	-- edge-detect delay
		END IF;
	END PROCESS capsync;

	cap_ev_w <=	(cap_s2_q AND (NOT cap_d_q))	WHEN capmd_w = "01" ELSE	-- rising
				((NOT cap_s2_q) AND cap_d_q)	WHEN capmd_w = "10" ELSE	-- falling
				'0';														-- 00 / 11 disabled

	--=======================================================================
	-- BTIFG source select -- the codes as the benchmarks pin them (header)
	--=======================================================================
	WITH btint_w SELECT btifg_set_o <=
		equ0_ev_w	WHEN "00",		-- benchmark-pinned (every compare test)
		equ1_ev_w	WHEN "01",		-- A20: the only source left
		cap_ev_w	WHEN "10",		-- benchmark-pinned (test4's BTINT2 in capture)
		'0'			WHEN OTHERS;	-- reserved -- "three options" in two bits

	--=======================================================================
	pwm_o		<= pwm_q;
	btctl1_o	<= btctl1_q;
	btctl2_o	<= btctl2_q;
	btcmpr0_o	<= btcmpr0_q;
	btcmpr1_o	<= btcmpr1_q;
	btcapr_o	<= btcapr_q;
	btcnt_o		<= btcnt_q;

END behavior;
