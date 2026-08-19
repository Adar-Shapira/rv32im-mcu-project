library ieee;
use ieee.std_logic_1164.all;
use work.aux_package.all;

entity top is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        ena            : in  std_logic;
        done           : out std_logic;
        
        TBactive       : in  std_logic;
        
        TB_ITCM_en     : in  std_logic;
        TB_ITCM_addr   : in  std_logic_vector(5 downto 0);
        TB_ITCM_din    : in  std_logic_vector(15 downto 0);
        
        TB_DTCM_en     : in  std_logic;
        TB_DTCM_wr     : in  std_logic;
        TB_DTCM_addr   : in  std_logic_vector(5 downto 0);
        TB_DTCM_din    : in  std_logic_vector(15 downto 0);
        TB_DTCM_dout   : out std_logic_vector(15 downto 0)
    );
end top;

architecture struct of top is

    signal sig_Cflag, sig_Zflag, sig_Nflag : std_logic;
    signal sig_IRin, sig_PCin              : std_logic;
    signal sig_PCsel                       : std_logic;
    signal sig_ALUFN                       : std_logic_vector(3 downto 0);
    signal sig_Imm1_in, sig_Imm2_in        : std_logic;
    signal sig_RFout, sig_RFin             : std_logic;
    signal sig_RFaddr_rd                   : std_logic_vector(1 downto 0);
    signal sig_RFaddr_wr                   : std_logic;
    signal sig_Ain, sig_Cin, sig_Cout      : std_logic;
    
    signal sig_DTCM_addr_in                : std_logic;
    signal sig_DTCM_out                    : std_logic;
    signal sig_DTCM_wr_ctrl                : std_logic;
    
    signal sig_Instruction_in : std_logic_vector(15 downto 0);
    signal sig_PC_out_addr    : std_logic_vector(15 downto 0);
    
    signal sig_DTCM_data_in   : std_logic_vector(15 downto 0);
    signal sig_DTCM_data_out  : std_logic_vector(15 downto 0);
    signal sig_DTCM_addr      : std_logic_vector(15 downto 0);

    signal actual_DTCM_addr   : std_logic_vector(5 downto 0);
    signal actual_DTCM_din    : std_logic_vector(15 downto 0);
    signal actual_DTCM_wr     : std_logic;
    
    signal sig_OPC            : std_logic_vector(3 downto 0); -- Connects IR OpCode

begin

    Control_inst: entity work.Control
        port map (
            clk          => clk,
            rst          => rst,
            ena          => ena,
            OPC          => sig_OPC, -- Wired to IR register
            Cflag        => sig_Cflag,
            Zflag        => sig_Zflag,
            Nflag        => sig_Nflag,
            PCin         => sig_PCin,
            IRin         => sig_IRin,
            PCsel        => sig_PCsel,
            Imm1_in      => sig_Imm1_in,
            Imm2_in      => sig_Imm2_in,
            RFout        => sig_RFout,
            RFin         => sig_RFin,
            RFaddr_rd    => sig_RFaddr_rd,
            RFaddr_wr    => sig_RFaddr_wr,
            Ain          => sig_Ain,
            Cin          => sig_Cin,
            Cout         => sig_Cout,
            ALUFN        => sig_ALUFN,
            DTCM_addr_in => sig_DTCM_addr_in,
            DTCM_out     => sig_DTCM_out,
            DTCM_wr      => sig_DTCM_wr_ctrl,
            done         => done
        );

    Datapath_inst: entity work.Datapath
        port map (
            clk            => clk,
            rst            => rst,
            IRin           => sig_IRin,
            PCin           => sig_PCin,
            PCsel          => sig_PCsel,
            Imm1_in        => sig_Imm1_in,
            Imm2_in        => sig_Imm2_in,
            RFout          => sig_RFout,
            RFin           => sig_RFin,
            RFaddr_rd      => sig_RFaddr_rd,
            RFaddr_wr      => sig_RFaddr_wr,
            Ain            => sig_Ain,
            Cin            => sig_Cin,
            Cout           => sig_Cout,
            ALUFN          => sig_ALUFN,
            DTCM_addr_in   => sig_DTCM_addr_in,
            DTCM_out       => sig_DTCM_out,
            OPC_out        => sig_OPC, -- Exports IR OpCode
            Cflag          => sig_Cflag,
            Zflag          => sig_Zflag,
            Nflag          => sig_Nflag,
            Instruction_in => sig_Instruction_in,
            PC_out_addr    => sig_PC_out_addr,
            DTCM_data_in   => sig_DTCM_data_in,
            DTCM_data_out  => sig_DTCM_data_out,
            DTCM_addr      => sig_DTCM_addr
        );

    ProgMem_inst: ProgMem
        generic map( Dwidth => 16, Awidth => 6, dept => 64 )
        port map (
            clk      => clk,
            memEn    => TB_ITCM_en,
            WmemData => TB_ITCM_din,
            WmemAddr => TB_ITCM_addr,
            RmemAddr => sig_PC_out_addr(5 downto 0),
            RmemData => sig_Instruction_in
        );

    actual_DTCM_addr <= TB_DTCM_addr when TBactive = '1' else sig_DTCM_addr(5 downto 0);
    actual_DTCM_din  <= TB_DTCM_din  when TBactive = '1' else sig_DTCM_data_out;
    actual_DTCM_wr   <= TB_DTCM_wr   when TBactive = '1' else sig_DTCM_wr_ctrl;

    dataMem_inst: dataMem
        generic map( Dwidth => 16, Awidth => 6, dept => 64 )
        port map (
            clk      => clk,
            memEn    => actual_DTCM_wr,
            WmemData => actual_DTCM_din,
            WmemAddr => actual_DTCM_addr,
            RmemAddr => actual_DTCM_addr,
            RmemData => sig_DTCM_data_in
        );

    TB_DTCM_dout <= sig_DTCM_data_in;

end struct;
