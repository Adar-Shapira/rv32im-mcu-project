LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY pwm IS
    PORT (
        clk, rst, ena : IN STD_LOGIC;
        ALUFN         : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        X, Y          : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        PWMout        : OUT STD_LOGIC
    );
END pwm;

ARCHITECTURE rtl OF pwm IS
    SIGNAL timer   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pwm_reg : STD_LOGIC;
BEGIN
    PROCESS(clk, rst)
    BEGIN
        -- Asynchronous reset overrides everything
        IF rst = '1' THEN
            timer <= (OTHERS => '0');
            pwm_reg <= '0';
        ELSIF rising_edge(clk) THEN
            -- Check if module is enabled
            IF ena = '1' THEN
                -- Timer logic: increment until Y is reached, then reset
                IF timer >= Y - 1 THEN
                    timer <= (OTHERS => '0');
                ELSE
                    timer <= timer + 1;
                END IF;

                -- PWM output logic based on selected mode (ALUFN)
                IF ALUFN = "000" THEN      -- Mode 0: Set/Reset
                    IF timer = 0 THEN 
                        pwm_reg <= '1';
                    ELSIF timer = X THEN 
                        pwm_reg <= '0';
                    END IF;
                ELSIF ALUFN = "001" THEN   -- Mode 1: Reset/Set
                    IF timer = 0 THEN 
                        pwm_reg <= '0';
                    ELSIF timer = X THEN 
                        pwm_reg <= '1';
                    END IF;
                ELSIF ALUFN = "010" THEN   -- Mode 2: Toggle
                    IF timer = X THEN 
                        pwm_reg <= NOT pwm_reg;
                    END IF;
                ELSE
                    pwm_reg <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- Assign internal register state to the output port
    PWMout <= pwm_reg;
END rtl;