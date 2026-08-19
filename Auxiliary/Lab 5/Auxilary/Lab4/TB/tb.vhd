-- ============================================================
-- Testbench for the OVERALL DUT: digital_system
-- Exercises:
--   * the combinational subpart (a few Arithmetic/Shift/Boolean ops), and
--   * the synchronous subpart (PWM modes 0/1/2) gated by ALUFN[4:3]="00".
-- Intended for waveform inspection in ModelSim.
-- ============================================================
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE work.aux_package.all;

ENTITY tb IS
END tb;

ARCHITECTURE sim OF tb IS
    CONSTANT n        : INTEGER := 8;
    CONSTANT clk_period : TIME := 20 ns;

    SIGNAL clk, rst, ena : STD_LOGIC := '0';
    SIGNAL Y_i, X_i      : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ALUFN_i       : STD_LOGIC_VECTOR(4 DOWNTO 0)  := (OTHERS => '0');
    SIGNAL ALUout_o      : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    SIGNAL Nflag_o, Cflag_o, Zflag_o, Vflag_o : STD_LOGIC;
    SIGNAL PWMout_o      : STD_LOGIC;

    SIGNAL sim_done : BOOLEAN := FALSE;
BEGIN

    dut : digital_system
        GENERIC MAP (n => n)
        PORT MAP (
            clk => clk, rst => rst, ena => ena,
            Y_i => Y_i, X_i => X_i, ALUFN_i => ALUFN_i,
            ALUout_o => ALUout_o,
            Nflag_o => Nflag_o, Cflag_o => Cflag_o,
            Zflag_o => Zflag_o, Vflag_o => Vflag_o,
            PWMout_o => PWMout_o
        );

    -- Clock generation
    clk_gen : PROCESS
    BEGIN
        WHILE NOT sim_done LOOP
            clk <= '0'; WAIT FOR clk_period/2;
            clk <= '1'; WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim : PROCESS
        -- Run the PWM long enough to see a few output periods.
        -- With Y (period) = 9 and X (compare) = 4 a full cycle is ~10 clocks.
        PROCEDURE run_pwm (mode : STD_LOGIC_VECTOR(2 DOWNTO 0)) IS
        BEGIN
            ALUFN_i <= "00" & mode;     -- PWM instruction class (ALUFN[4:3]="00")
            WAIT FOR 40 * clk_period;
        END PROCEDURE;
    BEGIN
        -- ---- reset ----
        rst <= '1'; ena <= '0';
        WAIT FOR 3 * clk_period;
        rst <= '0';

        -- =====================================================
        -- Combinational subpart (PWM disabled: ALUFN[4:3] /= "00")
        -- =====================================================
        Y_i <= x"000C"; X_i <= x"0005";   -- low byte 0x0C and 0x05

        ALUFN_i <= "01000"; WAIT FOR 2*clk_period;  -- Y + X      = 0x11
        ALUFN_i <= "01001"; WAIT FOR 2*clk_period;  -- Y - X      = 0x07
        ALUFN_i <= "01010"; WAIT FOR 2*clk_period;  -- neg(X)     = 0xFB
        ALUFN_i <= "01011"; WAIT FOR 2*clk_period;  -- Y + 2      = 0x0E
        ALUFN_i <= "01100"; WAIT FOR 2*clk_period;  -- Y - 2      = 0x0A
        ALUFN_i <= "10000"; WAIT FOR 2*clk_period;  -- SHL Y by X(k-1..0)
        ALUFN_i <= "10001"; WAIT FOR 2*clk_period;  -- SHR Y by X(k-1..0)
        ALUFN_i <= "11000"; WAIT FOR 2*clk_period;  -- NOT Y
        ALUFN_i <= "11001"; WAIT FOR 2*clk_period;  -- Y OR X
        ALUFN_i <= "11011"; WAIT FOR 2*clk_period;  -- Y XOR X

        -- =====================================================
        -- Synchronous subpart: PWM modes (ALUFN[4:3]="00")
        -- =====================================================
        Y_i <= x"0009";   -- PWM period
        X_i <= x"0004";   -- PWM compare value
        ena <= '1';

        run_pwm("000");   -- Mode 0: Set/Reset  (high 0..X, low X..Y)
        run_pwm("001");   -- Mode 1: Reset/Set  (low 0..X, high X..Y)
        run_pwm("010");   -- Mode 2: Toggle at X

        -- Show that PWM is held off when not selected (ena on, but ALU op)
        ALUFN_i <= "01000"; WAIT FOR 10 * clk_period;

        sim_done <= TRUE;
        WAIT;
    END PROCESS;

END sim;
