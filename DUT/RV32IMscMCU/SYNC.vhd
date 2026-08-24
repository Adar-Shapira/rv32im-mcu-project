--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 — clock-domain-crossing synchronizer
--
-- Implements Figures 10a and 10b of `Auxiliary/Final Project 2026 definition.pdf`
-- (page 10). Closes gap G-310.
--
-- WHAT THE FIGURES ACTUALLY SPECIFY
--   Figure 10a draws the complete crossing, and it is three flip-flops, not two:
--
--     clock domain A (slow)          |  clock domain B (fast)
--     comb logic -> [D Q]            |  Din -> [D Q] -Ds-> [D Q] -> Dout stable
--                    ^ MCLK          |          ^ DIVCLK  ^ DIVCLK
--
--   The page 10 prose is explicit about why the first one is not optional:
--     "It's fundamental to have a flip-flop to synchronize every signal that is
--      driven by combinational logic (combo) in domain A before sending it to
--      domain B through the synchronizer. In domain B, we must register the
--      input to avoid metastability caused by violating the fast clock-domain B
--      regime."
--
--   So domain A owns a launch register whose job is to present a clean, glitch-
--   free edge at the boundary, and domain B owns the two-stage synchronizer that
--   lets a metastable sample settle. Figure 10a's waveform labels the interval
--   between Din and Ds "Metastable phase" and the interval after Dout "Stable
--   Output".
--
--   Figure 10b then draws the block as instantiated for the divider:
--     Sync(divclk): Read data1 -> [DFF] -Ds-> [DFF] -> Ain
--                   Read data2 -> [DFF] -Ds-> [DFF] -> Bin
--   i.e. one two-stage chain per operand. This entity is ONE chain, generic in
--   width; Figure 10b's `Sync` block is two instances of it. Splitting it that
--   way is what makes it reusable for the single-bit crossings later — the KEY1-3
--   edge detectors and the UART status flags — instead of being welded to the
--   divider's two 32-bit operands.
--
-- GEN_SRC_REG — why the launch register is inside this entity
--   The prose calls the domain-A flop fundamental, and a synchronizer whose
--   launch register is "the caller's responsibility" is a synchronizer whose
--   launch register gets forgotten. So it lives here, enabled by default, and is
--   switched off only when the source is already registered in domain A — in
--   which case src_clk_i is unused and may be tied to '0'.
--
-- THE ONE ASSUMPTION, STATED AS SUCH
--   **Assumption.** A two-stage synchronizer on a multi-bit bus is only safe when
--   the bus is stable across the crossing. Individual bits can resolve on
--   different destination cycles, so a bus that changes while being sampled can
--   present a value that never existed on the source side. Figure 10b applies it
--   to two 32-bit operands anyway, and for the divider that is sound: the CPU
--   writes DIVIDEND and DIVISOR, and only then does the enable cross, so the
--   operands are quasi-static by the time they matter.
--
--   What this means for every later use: synchronize the CONTROL signal through
--   this entity and hold the data stable, or use a handshake. Do not synchronize
--   a bus that is changing. If a future crossing cannot guarantee stability, this
--   entity is the wrong tool and the design needs a handshake or a gray code.
--
-- NOTHING IN THE COURSE MATERIAL IS A PRECEDENT FOR THIS -- CHECKED
--   Searched every .vhd under Auxiliary/ for an existing synchronizer before
--   writing one. The only hits are IFETCH.vhd's "rst_i synchronization" comment
--   -- in the Lab 5 single-cycle core, the pipeline, and Ori's copy -- and that
--   is NOT a synchronizer: it is
--       IF rst_i='1' THEN rst_q<='1' ELSIF rising_edge(clk) THEN rst_q<=rst_i
--   a single flip-flop with an asynchronous preset. One flop cannot let a
--   metastable sample settle; that is the whole point of the second stage.
--   Do not mistake the two for each other, and do not "reuse" that code here.
--   (The supplied UART, Auxiliary/USART Material/UART_FPGA_option2/VHDL/DUT/
--   UART_RX.vhd, does mention synchronization -- relevant to Phase 12, not to
--   this entity, and it is third-party code rather than course material.)
--
-- RESET
--   Neither figure draws one. Simulation needs one anyway, or the chain starts at
--   'U' and propagates unknowns into the divider for two cycles. It is an
--   asynchronous, active-high reset matching the rest of this core, and it is
--   sampled in the DESTINATION domain — a synchronizer reset released in the
--   source domain would itself be a crossing.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY sync IS
	generic(
		DATA_WIDTH	: integer := 32;		-- 32 for the divider operands, 1 for a flag
		STAGES		: integer := 2;			-- Figure 10b draws two; 3 for a very high ratio
		GEN_SRC_REG	: boolean := TRUE		-- Figure 10a's domain-A launch register
	);
	PORT(
		--Inputs
		src_clk_i	: IN	STD_LOGIC;		-- domain A, the SLOW clock (MCLK in Figure 10a)
		dst_clk_i	: IN	STD_LOGIC;		-- domain B, the FAST clock (DIVCLK in Figure 10a)
		rst_i		: IN	STD_LOGIC;		-- asynchronous, active high, destination domain
		d_i			: IN	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

		--Outputs
		q_o			: OUT	STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)	-- Dout, stable in domain B
	);
END sync;

--============================================================================
ARCHITECTURE structure OF sync IS

	TYPE stage_array IS ARRAY (0 TO STAGES-1) OF
		STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

	SIGNAL boundary_w	: STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);	-- Din in Figure 10a
	SIGNAL sync_q		: stage_array;								-- Ds .. Dout

BEGIN
	-- Two stages is the specified minimum and the point of the whole entity.
	-- One stage is not a synchronizer, it is just a register.
	assert STAGES >= 2
		report "SYNC: STAGES must be at least 2 (Figure 10b draws two). " &
			"A single stage does not let a metastable sample settle."
		severity failure;

	--=======================================================================
	-- Clock domain A — the launch register (Figure 10a, left half)
	--=======================================================================
	SRCREG:
	if (GEN_SRC_REG) generate
		-- Declared inside the generate so it does not exist at all in the other
		-- branch. An architecture-level signal would sit there undriven at 'U',
		-- which is exactly the kind of thing that looks like a bug in a waveform.
		SIGNAL launch_q : STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
	begin
		process (src_clk_i, rst_i)
		begin
			if rst_i = '1' then
				launch_q <= (others => '0');
			elsif rising_edge(src_clk_i) then
				launch_q <= d_i;
			end if;
		end process;
		boundary_w <= launch_q;
	else generate
		-- The source is already registered in domain A, so adding a second flop
		-- here would only add latency. src_clk_i is unused in this branch.
		boundary_w <= d_i;
	end generate SRCREG;

	--=======================================================================
	-- Clock domain B — the synchronizer chain (Figure 10a, right half)
	-- sync_q(0) is Figure 10a's Ds, the stage that may be metastable.
	-- sync_q(STAGES-1) is Dout, the stable output.
	--=======================================================================
	process (dst_clk_i, rst_i)
	begin
		if rst_i = '1' then
			for i in 0 to STAGES-1 loop
				sync_q(i) <= (others => '0');
			end loop;
		elsif rising_edge(dst_clk_i) then
			sync_q(0) <= boundary_w;
			for i in 1 to STAGES-1 loop
				sync_q(i) <= sync_q(i-1);
			end loop;
		end if;
	end process;

	q_o <= sync_q(STAGES-1);

END structure;
