LIBRARY IEEE;
USE ieee.std_logic_1164.all;

PACKAGE aux_package IS
--------------------------------------------------------
    COMPONENT top IS
        GENERIC (n : INTEGER := 8; k : integer := 3; m : integer := 4);
        PORT (  
            Y_i, X_i : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            ALUFN_i  : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
            ALUout_o : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC 
        );
    END COMPONENT;

    COMPONENT FA IS
        PORT (
            xi, yi, cin: IN std_logic;
            s, cout: OUT std_logic
        );
    END COMPONENT;

    COMPONENT AdderSub IS
        GENERIC (n : INTEGER := 8);
        PORT (
            x, y     : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            sub_cont : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            cout     : OUT STD_LOGIC;
            s        : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Logic IS 
        GENERIC (n : INTEGER := 8);
        PORT (
            x, y   : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            alufn  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            aluout : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Shifter IS
        GENERIC (n : INTEGER := 8; k : INTEGER := 3);
        PORT (
             x, y : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
             dir  : IN STD_LOGIC_VECTOR (2 DOWNTO 0); 
             cout : OUT STD_LOGIC;
             res  : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0)
        );
    END COMPONENT;

    -- ==================================================
    -- NEW COMPONENTS FOR LAB 4
    -- ==================================================
    
    COMPONENT pwm IS
        PORT (
            clk, rst, ena : IN STD_LOGIC;
            ALUFN         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            X, Y          : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            PWMout        : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT digital_system IS
        GENERIC (n : INTEGER := 8); 
        PORT (
            clk, rst, ena : IN STD_LOGIC;
            Y_i, X_i      : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
            ALUFN_i       : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
            ALUout_o      : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
            Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC;
            PWMout_o      : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT hex_decoder IS
        PORT (
            bin : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    -- ALTPLL: derives the 2 MHz system clock from the 50 MHz oscillator
    COMPONENT pll IS
        PORT (
            areset : IN  STD_LOGIC := '0';
            inclk0 : IN  STD_LOGIC := '0';
            c0     : OUT STD_LOGIC;
            locked : OUT STD_LOGIC
        );
    END COMPONENT;

END aux_package;