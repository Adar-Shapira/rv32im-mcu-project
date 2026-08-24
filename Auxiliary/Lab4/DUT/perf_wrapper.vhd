LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY perf_wrapper IS
  GENERIC (n : INTEGER := 8);
  PORT (
    clk      : IN STD_LOGIC;
    Y_i, X_i : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
    ALUFN_i  : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
    ALUout_o : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
    Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC
  );
END perf_wrapper;

ARCHITECTURE structural OF perf_wrapper IS
  -- Instantiate the combinational ALU from Lab 1
  COMPONENT top IS
    GENERIC (n : INTEGER := 8; k : integer := 3; m : integer := 4);
    PORT (
      Y_i,X_i  : IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
      ALUFN_i  : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
      ALUout_o : OUT STD_LOGIC_VECTOR(n-1 downto 0);
      Nflag_o, Cflag_o, Zflag_o, Vflag_o : OUT STD_LOGIC
    );
  END COMPONENT;

  -- Internal signals used as registers
  SIGNAL Y_reg, X_reg : STD_LOGIC_VECTOR (n-1 DOWNTO 0);
  SIGNAL ALUFN_reg    : STD_LOGIC_VECTOR (4 DOWNTO 0);
  SIGNAL ALUout_int   : STD_LOGIC_VECTOR (n-1 DOWNTO 0);
  SIGNAL N_int, C_int, Z_int, V_int : STD_LOGIC;

BEGIN
  -- Combinational logic mapping
  dut: top
    GENERIC MAP (n => n)
    PORT MAP (
      Y_i => Y_reg, 
      X_i => X_reg, 
      ALUFN_i => ALUFN_reg,
      ALUout_o => ALUout_int,
      Nflag_o => N_int, 
      Cflag_o => C_int, 
      Zflag_o => Z_int, 
      Vflag_o => V_int
    );

  -- Synchronous process for input and output registers
  PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      -- Sample inputs at the rising edge
      Y_reg <= Y_i;
      X_reg <= X_i;
      ALUFN_reg <= ALUFN_i;
      
      -- Sample outputs at the rising edge
      ALUout_o <= ALUout_int;
      Nflag_o <= N_int;
      Cflag_o <= C_int;
      Zflag_o <= Z_int;
      Vflag_o <= V_int;
    END IF;
  END PROCESS;
END structural;
