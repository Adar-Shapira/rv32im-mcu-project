LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY digital_system IS
    GENERIC (n : INTEGER := 8); 
    PORT (
        clk, rst, ena : IN STD_LOGIC;
        -- 16-bit inputs required for PWM compatibility
        Y_i, X_i      : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        ALUFN_i       : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
        ALUout_o      : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
        Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC;
        PWMout_o      : OUT STD_LOGIC
    );
END digital_system;

ARCHITECTURE structural OF digital_system IS
    -- Declare the Combinational ALU component from Lab 1
    COMPONENT top IS
        GENERIC (n : INTEGER := 8; k : integer := 3; m : integer := 4);
        PORT (
            Y_i, X_i  : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            ALUFN_i   : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            ALUout_o  : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Declare the Synchronous PWM unit component
    COMPONENT pwm IS
        PORT (
            clk, rst, ena : IN STD_LOGIC;
            ALUFN         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            X, Y          : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            PWMout        : OUT STD_LOGIC
        );
    END COMPONENT;

    -- PWM is selected only by the PWM Output instruction class (ALUFN[4:3]="00", Figure 4)
    SIGNAL pwm_sel       : STD_LOGIC;
    SIGNAL pwm_ena       : STD_LOGIC;
    SIGNAL pwm_X, pwm_Y  : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN
    -- Gate the synchronous subpart with the PWM instruction class (Figure 4)
    pwm_sel <= '1' WHEN ALUFN_i(4 DOWNTO 3) = "00" ELSE '0';
    pwm_ena <= ena AND pwm_sel;
    pwm_X   <= X_i WHEN pwm_sel = '1' ELSE (OTHERS => '0');
    pwm_Y   <= Y_i WHEN pwm_sel = '1' ELSE (OTHERS => '0');

    -- Map ALU instances (uses only the lower 8 bits of X and Y)
    alu_inst : top
        GENERIC MAP (n => 8, k => 3, m => 4)
        PORT MAP (
            Y_i => Y_i(7 DOWNTO 0),
            X_i => X_i(7 DOWNTO 0),
            ALUFN_i => ALUFN_i,
            ALUout_o => ALUout_o,
            Nflag_o => Nflag_o, 
            Cflag_o => Cflag_o, 
            Zflag_o => Zflag_o, 
            Vflag_o => Vflag_o
        );

    -- Map PWM instance (uses the full 16-bit vectors, gated by ALUFN[4:3]="00")
    pwm_inst : pwm
        PORT MAP (
            clk => clk,
            rst => rst,
            ena => pwm_ena,
            ALUFN => ALUFN_i(2 DOWNTO 0),
            X => pwm_X,
            Y => pwm_Y,
            PWMout => PWMout_o
        );
END structural;