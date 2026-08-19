library ieee;
use ieee.std_logic_1164.all;

entity tb_control is
end tb_control;

architecture sim of tb_control is
    signal clk, rst, ena : std_logic := '0';
    signal OPC : std_logic_vector(3 downto 0) := "0000";
    signal Cflag, Zflag, Nflag : std_logic := '0';
    
    signal PCin, IRin, PCsel, Imm1_in, Imm2_in, RFout, RFin : std_logic;
    signal RFaddr_wr, Ain, Cin, Cout, DTCM_addr_in, DTCM_out, DTCM_wr, done : std_logic;
    signal RFaddr_rd : std_logic_vector(1 downto 0);
    signal ALUFN : std_logic_vector(3 downto 0);

begin
    uut: entity work.Control port map (
        clk => clk, rst => rst, ena => ena, OPC => OPC, Cflag => Cflag, Zflag => Zflag,
        Nflag => Nflag, PCin => PCin, IRin => IRin, PCsel => PCsel, Imm1_in => Imm1_in,
        Imm2_in => Imm2_in, RFout => RFout, RFin => RFin, RFaddr_rd => RFaddr_rd,
        RFaddr_wr => RFaddr_wr, Ain => Ain, Cin => Cin, Cout => Cout, ALUFN => ALUFN,
        DTCM_addr_in => DTCM_addr_in, DTCM_out => DTCM_out, DTCM_wr => DTCM_wr, done => done
    );

    clk <= not clk after 50 ns;

    process
    begin
        rst <= '1';
        ena <= '0';
        wait for 100 ns;
        rst <= '0';
        ena <= '1';
        
        OPC <= "0000"; 
        wait for 600 ns;
        
        OPC <= "1111"; -- DONE
        wait;
    end process;
end sim;
