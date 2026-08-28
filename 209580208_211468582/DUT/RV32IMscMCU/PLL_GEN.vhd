--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- ALTPLL wrapper whose ratio is a GENERIC
--
-- Phase 4B. This is DUT/RV32IMscMCU/PLL.vhd with four wizard constants promoted
-- to generics and nothing else changed.
--============================================================================
-- WHY THIS FILE EXISTS AT ALL, AND WHY PLL.vhd WAS NOT SIMPLY EDITED
--
--   Figure 1 needs three clocks. Hanan's forum answer settles how to make them:
--   asked whether MCLK, ACCELCLK and SMCLK come out of one PLL module, he said
--   **"No -- on the basis of three different PLL instances"**, each fed from the
--   50 MHz base clock (DOC/03, F6). That answer is what unblocked Phase 4B.
--
--   But three instances at three frequencies need a per-instance ratio, and
--   PLL.vhd has none: its entity takes no generics at all, and its ratio comes
--   from package constants --
--       clk0_divide_by => G_PLL_DIV, clk0_multiply_by => G_PLL_MUL
--   -- so three instances of PLL would produce three copies of ONE frequency
--   (50 x 1/2 = 25 MHz at the current G_PLL_MUL = 1, G_PLL_DIV = 2). That is the
--   real obstacle, and it is not the one the roadmap predicted: the roadmap said
--   the megafunction would have to be regenerated for c1/c2. It does not. It has
--   to be given generics.
--
--   PLL.vhd is left BYTE-IDENTICAL instead of edited, deliberately. Its md5 is
--   a12064f21cedbb715db75713499dc998 in all four places it exists -- our DUT
--   copy, Auxiliary/Lab 5/DUT/RV32IM_sc, .../RV32IM_pipeline and Hanan's own
--   Auxilary/DUT -- which makes it the one file in the whole tree whose
--   provenance needs no argument. Editing it would end that for the sake of
--   avoiding a copy, and would put the Phase 0/1 baseline at risk for a change
--   whose only purpose is a feature the baseline does not use. So the boilerplate
--   is duplicated here on purpose, and the core keeps instantiating the original.
--
--   THE PRICE, STATED PLAINLY: two files now contain the same ~60-line altpll
--   component declaration. If Altera's parameter list ever has to change, it has
--   to change in both. That is the trade accepted above.
--
-- WHAT IS PARAMETERISED, AND WHY EACH ONE IS SAFE TO PARAMETERISE
--   Every generic below is a parameter that ALREADY appears in PLL.vhd's own
--   altpll component declaration and is ALREADY passed by PLL.vhd. Nothing new
--   is asserted about the megafunction. This matters because the roadmap flagged
--   "asserting generics that are not written down anywhere we have" as a real
--   risk -- the same risk still outstanding from Phase 3B's byteena_a -- and this
--   file deliberately does not take it. Adding clk1_* / clk2_* generics, which
--   appear nowhere in any file we have, WOULD have taken it.
--
-- DEFAULTS REPRODUCE PLL.vhd EXACTLY
--   With no generic map, pll_gen is PLL: G_PLL_DIV / G_PLL_MUL from the package,
--   50 MHz in, Cyclone II, the same lock multipliers. So the two can be compared
--   directly if anything ever looks wrong.
--
-- TWO THINGS ONLY QUARTUS CAN CONFIRM -- for Adar, not blockers
--   1. THE FAMILY STRING SAYS "Cyclone II" AND THE BOARD IS Cyclone IV E.
--      That mismatch is inherited: PLL.vhd says Cyclone II, the .qsf says
--      FAMILY "Cyclone IV E" / DEVICE EP4CE115F29C7, and Lab 5 compiled and ran
--      on the board anyway -- so the string is evidently tolerated. It is left at
--      "Cyclone II" because that is the configuration KNOWN to work, not because
--      it is right. If Quartus rejects a PLL parameter, pass
--      DEVICE_FAMILY => "Cyclone IV E" and report which way it went.
--   2. THREE INSTANCES WITH DIFFERENT PARAMETERS SHARE ONE CBX PREFIX.
--      lpm_hint carries CBX_MODULE_PREFIX, and normally one module reused three
--      times is exactly right. If Quartus complains about colliding megafunction
--      parameters, give each instance its own string via LPM_HINT_STR -- that is
--      the whole fix, and it is why the hint is a generic rather than a literal.
--============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.cond_compilation_package.all;

LIBRARY altera_mf;
USE altera_mf.all;

ENTITY pll_gen IS
	GENERIC (
		-- The ratio. Output frequency = inclk0 * MULTIPLY_BY / DIVIDE_BY.
		DIVIDE_BY		: NATURAL := G_PLL_DIV;
		MULTIPLY_BY		: NATURAL := G_PLL_MUL;
		-- Input period in PICOSECONDS. 20000 ps = 20 ns = 50 MHz, the DE2-115
		-- board clock, and the value PLL.vhd hardcodes.
		IN_PERIOD_PS	: NATURAL := 20000;
		-- See note 1 in the header before changing this.
		DEVICE_FAMILY	: STRING  := "Cyclone II";
		-- See note 2 in the header. One string, so no concatenation is handed to
		-- the megafunction.
		LPM_HINT_STR	: STRING  := "CBX_MODULE_PREFIX=PLL_GEN"
	);
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0			: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC
	);
END pll_gen;


ARCHITECTURE SYN OF pll_gen IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (5 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC ;
	SIGNAL sub_wire3	: STD_LOGIC ;
	SIGNAL sub_wire4	: STD_LOGIC_VECTOR (1 DOWNTO 0);
	SIGNAL sub_wire5_bv	: BIT_VECTOR (0 DOWNTO 0);
	SIGNAL sub_wire5	: STD_LOGIC_VECTOR (0 DOWNTO 0);

	-- Copied verbatim from PLL.vhd. Do not trim it to the parameters actually
	-- used: a component declaration for a megafunction has to match the library
	-- entity, not the subset this wrapper happens to set.
	COMPONENT altpll
	GENERIC (
		clk0_divide_by		: NATURAL;
		clk0_duty_cycle		: NATURAL;
		clk0_multiply_by		: NATURAL;
		clk0_phase_shift		: STRING;
		compensate_clock		: STRING;
		gate_lock_signal		: STRING;
		inclk0_input_frequency		: NATURAL;
		intended_device_family		: STRING;
		invalid_lock_multiplier		: NATURAL;
		lpm_hint		: STRING;
		lpm_type		: STRING;
		operation_mode		: STRING;
		port_activeclock		: STRING;
		port_areset		: STRING;
		port_clkbad0		: STRING;
		port_clkbad1		: STRING;
		port_clkloss		: STRING;
		port_clkswitch		: STRING;
		port_configupdate		: STRING;
		port_fbin		: STRING;
		port_inclk0		: STRING;
		port_inclk1		: STRING;
		port_locked		: STRING;
		port_pfdena		: STRING;
		port_phasecounterselect		: STRING;
		port_phasedone		: STRING;
		port_phasestep		: STRING;
		port_phaseupdown		: STRING;
		port_pllena		: STRING;
		port_scanaclr		: STRING;
		port_scanclk		: STRING;
		port_scanclkena		: STRING;
		port_scandata		: STRING;
		port_scandataout		: STRING;
		port_scandone		: STRING;
		port_scanread		: STRING;
		port_scanwrite		: STRING;
		port_clk0		: STRING;
		port_clk1		: STRING;
		port_clk2		: STRING;
		port_clk3		: STRING;
		port_clk4		: STRING;
		port_clk5		: STRING;
		port_clkena0		: STRING;
		port_clkena1		: STRING;
		port_clkena2		: STRING;
		port_clkena3		: STRING;
		port_clkena4		: STRING;
		port_clkena5		: STRING;
		port_extclk0		: STRING;
		port_extclk1		: STRING;
		port_extclk2		: STRING;
		port_extclk3		: STRING;
		valid_lock_multiplier		: NATURAL
	);
	PORT (
			areset	: IN STD_LOGIC ;
			clk	: OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
			inclk	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
			locked	: OUT STD_LOGIC
	);
	END COMPONENT;

BEGIN
	-- A PLL that multiplies or divides by zero is a typo, and it would otherwise
	-- reach the fitter as a megafunction parameter error with no hint of where it
	-- came from.
	assert DIVIDE_BY > 0 and MULTIPLY_BY > 0
		report "pll_gen: DIVIDE_BY and MULTIPLY_BY must both be at least 1."
		severity failure;

	sub_wire5_bv(0 DOWNTO 0) <= "0";
	sub_wire5    <= To_stdlogicvector(sub_wire5_bv);
	locked    <= sub_wire0;
	sub_wire2    <= sub_wire1(0);
	c0    <= sub_wire2;
	sub_wire3    <= inclk0;
	sub_wire4    <= sub_wire5(0 DOWNTO 0) & sub_wire3;

	altpll_component : altpll
	GENERIC MAP (
		clk0_divide_by => DIVIDE_BY,				-- was G_PLL_DIV
		clk0_duty_cycle => 50,
		clk0_multiply_by => MULTIPLY_BY,			-- was G_PLL_MUL
		clk0_phase_shift => "0",
		compensate_clock => "CLK0",
		gate_lock_signal => "NO",
		inclk0_input_frequency => IN_PERIOD_PS,		-- was the literal 20000
		intended_device_family => DEVICE_FAMILY,	-- was the literal "Cyclone II"
		invalid_lock_multiplier => 5,
		lpm_hint => LPM_HINT_STR,					-- was "CBX_MODULE_PREFIX=PLL"
		lpm_type => "altpll",
		operation_mode => "NORMAL",
		port_activeclock => "PORT_UNUSED",
		port_areset => "PORT_USED",
		port_clkbad0 => "PORT_UNUSED",
		port_clkbad1 => "PORT_UNUSED",
		port_clkloss => "PORT_UNUSED",
		port_clkswitch => "PORT_UNUSED",
		port_configupdate => "PORT_UNUSED",
		port_fbin => "PORT_UNUSED",
		port_inclk0 => "PORT_USED",
		port_inclk1 => "PORT_UNUSED",
		port_locked => "PORT_USED",
		port_pfdena => "PORT_UNUSED",
		port_phasecounterselect => "PORT_UNUSED",
		port_phasedone => "PORT_UNUSED",
		port_phasestep => "PORT_UNUSED",
		port_phaseupdown => "PORT_UNUSED",
		port_pllena => "PORT_UNUSED",
		port_scanaclr => "PORT_UNUSED",
		port_scanclk => "PORT_UNUSED",
		port_scanclkena => "PORT_UNUSED",
		port_scandata => "PORT_UNUSED",
		port_scandataout => "PORT_UNUSED",
		port_scandone => "PORT_UNUSED",
		port_scanread => "PORT_UNUSED",
		port_scanwrite => "PORT_UNUSED",
		port_clk0 => "PORT_USED",
		port_clk1 => "PORT_UNUSED",
		port_clk2 => "PORT_UNUSED",
		port_clk3 => "PORT_UNUSED",
		port_clk4 => "PORT_UNUSED",
		port_clk5 => "PORT_UNUSED",
		port_clkena0 => "PORT_UNUSED",
		port_clkena1 => "PORT_UNUSED",
		port_clkena2 => "PORT_UNUSED",
		port_clkena3 => "PORT_UNUSED",
		port_clkena4 => "PORT_UNUSED",
		port_clkena5 => "PORT_UNUSED",
		port_extclk0 => "PORT_UNUSED",
		port_extclk1 => "PORT_UNUSED",
		port_extclk2 => "PORT_UNUSED",
		port_extclk3 => "PORT_UNUSED",
		valid_lock_multiplier => 1
	)
	PORT MAP (
		areset => areset,
		inclk => sub_wire4,
		locked => sub_wire0,
		clk => sub_wire1
	);

END SYN;
