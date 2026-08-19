library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_datapath is
end tb_datapath;

architecture sim of tb_datapath is
    signal clk, rst : std_logic := '0';
    
    -- Inputs to Datapath
    signal IRin, PCin, PCsel, Imm1_in, Imm2_in : std_logic := '0';
    signal RFout, RFin, RFaddr_wr, Ain, Cin, Cout : std_logic := '0';
    signal DTCM_addr_in, DTCM_out : std_logic := '0';
    signal RFaddr_rd : std_logic_vector(1 downto 0) := "00";
    signal ALUFN : std_logic_vector(3 downto 0) := "0000";
    signal Instruction_in : std_logic_vector(15 downto 0) := x"0000";
    signal DTCM_data_in : std_logic_vector(15 downto 0) := x"0000";
    
    -- Outputs from Datapath
    signal Cflag, Zflag, Nflag : std_logic;
    signal PC_out_addr, DTCM_data_out, DTCM_addr : std_logic_vector(15 downto 0);

begin
    uut: entity work.Datapath port map (
        clk => clk, rst => rst, IRin => IRin, PCin => PCin, PCsel => PCsel,
        Imm1_in => Imm1_in, Imm2_in => Imm2_in, RFout => RFout, RFin => RFin,
        RFaddr_rd => RFaddr_rd, RFaddr_wr => RFaddr_wr, Ain => Ain, Cin => Cin,
        Cout => Cout, ALUFN => ALUFN, DTCM_addr_in => DTCM_addr_in, DTCM_out => DTCM_out,
        Cflag => Cflag, Zflag => Zflag, Nflag => Nflag, Instruction_in => Instruction_in,
        PC_out_addr => PC_out_addr, DTCM_data_in => DTCM_data_in, DTCM_data_out => DTCM_data_out,
        DTCM_addr => DTCM_addr
    );

    clk <= not clk after 50 ns;

    -- Stimulus process
    process
    begin
        -- 1. Reset
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;
        
        -- 2. Load Immediate (0x000A) to R2
        Instruction_in <= x"020A"; -- ra=2, data=0A
        Imm1_in <= '1';
        RFin <= '1';
        wait for 100 ns;
        Imm1_in <= '0';
        RFin <= '0';
        
        -- 3. Load Immediate (0x0005) to R3
        Instruction_in <= x"0305"; -- ra=3, data=05
        Imm1_in <= '1';
        RFin <= '1';
        wait for 100 ns;
        Imm1_in <= '0';
        RFin <= '0';
        
        -- 4. Execute ADD R1, R2, R3
        Instruction_in <= x"0123"; -- ra=1, rb=2, rc=3
        
        -- Step 4a: Read Rb (R2) to A register
        RFaddr_rd <= "00"; -- Select Rb field
        RFout <= '1';
        Ain <= '1';
        wait for 100 ns;
        Ain <= '0';
        RFout <= '0';
        
        -- Step 4b: Read Rc (R3) to ALU, Compute ADD, Save to C
        RFaddr_rd <= "01"; -- Select Rc field
        RFout <= '1';
        ALUFN <= "0000"; -- ALU ADD function
        Cin <= '1';
        wait for 100 ns;
        Cin <= '0';
        RFout <= '0';
        
        -- Step 4c: Write C back to Ra (R1)
        Cout <= '1';
        RFaddr_wr <= '0'; -- Select Ra field
        RFin <= '1';
        wait for 100 ns;
        Cout <= '0';
        RFin <= '0';
        
        -- End of test
        wait;
    end process;
end sim;
