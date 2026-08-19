library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.aux_package.all;

entity Datapath is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        
        -- Control signals input from Control Unit
        IRin           : in  std_logic;
        PCin           : in  std_logic;
        PCsel          : in  std_logic; 
        Imm1_in        : in  std_logic;
        Imm2_in        : in  std_logic;
        RFout          : in  std_logic;
        RFin           : in  std_logic;
        RFaddr_rd      : in  std_logic_vector(1 downto 0); 
        RFaddr_wr      : in  std_logic; 
        Ain            : in  std_logic;
        Cin            : in  std_logic;
        Cout           : in  std_logic;
        ALUFN          : in  std_logic_vector(3 downto 0);
        DTCM_addr_in   : in  std_logic;                    
        DTCM_out       : in  std_logic;                    
        
        -- Status signals output to Control Unit
        OPC_out        : out std_logic_vector(3 downto 0); -- Export IR opcode to Control
        Cflag          : out std_logic;
        Zflag          : out std_logic;
        Nflag          : out std_logic;
        
        -- External memory interfaces
        Instruction_in : in  std_logic_vector(15 downto 0);
        PC_out_addr    : out std_logic_vector(15 downto 0);
        DTCM_data_in   : in  std_logic_vector(15 downto 0);
        DTCM_data_out  : out std_logic_vector(15 downto 0);
        DTCM_addr      : out std_logic_vector(15 downto 0)
    );
end Datapath;

architecture rtl of Datapath is

    signal Main_BUS      : std_logic_vector(15 downto 0);
    signal PC_reg        : std_logic_vector(15 downto 0);
    signal IR_reg        : std_logic_vector(15 downto 0);
    signal A_reg         : std_logic_vector(15 downto 0);
    signal C_reg         : std_logic_vector(15 downto 0);
    signal DTCM_addr_reg : std_logic_vector(15 downto 0);
    
    signal Cflag_reg  : std_logic;
    signal Zflag_reg  : std_logic;
    signal Nflag_reg  : std_logic;

    signal RF_RregAddr : std_logic_vector(3 downto 0);
    signal RF_WregAddr : std_logic_vector(3 downto 0);
    signal RF_RregData : std_logic_vector(15 downto 0);
    
    signal ALU_out     : std_logic_vector(15 downto 0);
    signal ALU_Cout    : std_logic;

begin

    -----------------------------------------------------------------
    -- Register File (RF) instantiation
    -----------------------------------------------------------------
    RF_inst: RF 
        generic map( Dwidth => 16, Awidth => 4 )
        port map(
            clk      => clk,
            rst      => rst,
            WregEn   => RFin,
            WregData => Main_BUS, 
            WregAddr => RF_WregAddr,
            RregAddr => RF_RregAddr,
            RregData => RF_RregData 
        );

    -----------------------------------------------------------------
    -- Address routing for registers
    -----------------------------------------------------------------
    process(RFaddr_rd, IR_reg)
    begin
        if RFaddr_rd = "00" then
            RF_RregAddr <= IR_reg(7 downto 4);   
        elsif RFaddr_rd = "01" then
            RF_RregAddr <= IR_reg(3 downto 0);   
        else
            RF_RregAddr <= IR_reg(11 downto 8);  
        end if;
    end process;

    RF_WregAddr <= IR_reg(11 downto 8); 

    -----------------------------------------------------------------
    -- Main Data Bus management (Main BUS MUX)
    -----------------------------------------------------------------
    process(RFout, Cout, Imm1_in, Imm2_in, DTCM_out, RF_RregData, C_reg, IR_reg, DTCM_data_in)
    begin
        Main_BUS <= (others => '0'); 
        if (RFout = '1') then
            Main_BUS <= RF_RregData;
        elsif (Cout = '1') then
            Main_BUS <= C_reg;
        elsif (DTCM_out = '1') then
            Main_BUS <= DTCM_data_in; 
        elsif (Imm1_in = '1') then
            if IR_reg(7) = '1' then
                Main_BUS <= x"FF" & IR_reg(7 downto 0);
            else
                Main_BUS <= x"00" & IR_reg(7 downto 0);
            end if;
        elsif (Imm2_in = '1') then
            if IR_reg(3) = '1' then
                Main_BUS <= x"FFF" & IR_reg(3 downto 0);
            else
                Main_BUS <= x"000" & IR_reg(3 downto 0);
            end if;
        end if;
    end process;

    -----------------------------------------------------------------
    -- Synchronous registers (PC, IR, A, C)
    -----------------------------------------------------------------
    process(clk, rst)
        variable offset : std_logic_vector(15 downto 0);
    begin
        if rst = '1' then
            PC_reg        <= (others => '0');
            IR_reg        <= (others => '0');
            A_reg         <= (others => '0');
            C_reg         <= (others => '0');
            DTCM_addr_reg <= (others => '0');
            Cflag_reg     <= '0';
            Zflag_reg     <= '0';
            Nflag_reg     <= '0';
        elsif rising_edge(clk) then
            if IRin = '1' then
                IR_reg <= Instruction_in;
            end if;

            if PCin = '1' then
                if PCsel = '0' then
                    PC_reg <= PC_reg + 1;
                else
                    if IR_reg(7) = '1' then
                        offset := x"FF" & IR_reg(7 downto 0);
                    else
                        offset := x"00" & IR_reg(7 downto 0);
                    end if;
                    -- PC is already PC+1 from fetch state, so just add offset
                    PC_reg <= PC_reg + offset;
                end if;
            end if;

            if Ain = '1' then
                A_reg <= Main_BUS;
            end if;

            if Cin = '1' then
                C_reg <= ALU_out;
                Cflag_reg <= ALU_Cout;
                if ALU_out = x"0000" then Zflag_reg <= '1'; else Zflag_reg <= '0'; end if;
                Nflag_reg <= ALU_out(15);
            end if;
            
            if DTCM_addr_in = '1' then
                DTCM_addr_reg <= Main_BUS;
            end if;
        end if;
    end process;

    -----------------------------------------------------------------
    -- ALU unit
    -----------------------------------------------------------------
    process(A_reg, Main_BUS, ALUFN)
        variable temp_result : std_logic_vector(16 downto 0);
    begin
        ALU_out  <= (others => '0');
        ALU_Cout <= '0';
        temp_result := (others => '0');

        case ALUFN is
            when OPC_ADD =>
                temp_result := ('0' & A_reg) + ('0' & Main_BUS);
                ALU_out  <= temp_result(15 downto 0);
                ALU_Cout <= temp_result(16);
                
            when OPC_SUB =>
                temp_result := ('0' & A_reg) - ('0' & Main_BUS);
                ALU_out  <= temp_result(15 downto 0);
                ALU_Cout <= not temp_result(16); 
                
            when OPC_AND =>
                ALU_out <= A_reg and Main_BUS;
                
            when OPC_OR =>
                ALU_out <= A_reg or Main_BUS;
                
            when OPC_XOR =>
                ALU_out <= A_reg xor Main_BUS;
                
            when others =>
                ALU_out <= (others => '0');
        end case;
    end process;

    -- Output wiring
    OPC_out <= IR_reg(15 downto 12); -- OpCode exported to Control Unit
    Cflag <= Cflag_reg;
    Zflag <= Zflag_reg;
    Nflag <= Nflag_reg;
    PC_out_addr <= PC_reg;
    DTCM_data_out <= Main_BUS;
    DTCM_addr <= DTCM_addr_reg;

end rtl;