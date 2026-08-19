library ieee;
use ieee.std_logic_1164.all;

package aux_package is

    -----------------------------------------------------------------
    -- Constants for OpCodes (Based on Table 2)
    -----------------------------------------------------------------
    constant OPC_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant OPC_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant OPC_AND  : std_logic_vector(3 downto 0) := "0010";
    constant OPC_OR   : std_logic_vector(3 downto 0) := "0011";
    constant OPC_XOR  : std_logic_vector(3 downto 0) := "0100";
    --constant OPC_RT   : std_logic_vector(3 downto 0) := "0101";
    --constant OPC_RT   : std_logic_vector(3 downto 0) := "0110";
    constant OPC_JMP  : std_logic_vector(3 downto 0) := "0111";
    constant OPC_JC   : std_logic_vector(3 downto 0) := "1000";
    constant OPC_JNC  : std_logic_vector(3 downto 0) := "1001";
    --constant OPC_RT   : std_logic_vector(3 downto 0) := "1010";
    --constant OPC_RT   : std_logic_vector(3 downto 0) := "1011";
    constant OPC_MOV  : std_logic_vector(3 downto 0) := "1100";
    constant OPC_LD   : std_logic_vector(3 downto 0) := "1101";
    constant OPC_ST   : std_logic_vector(3 downto 0) := "1110";
    constant OPC_DONE : std_logic_vector(3 downto 0) := "1111";

    -----------------------------------------------------------------
    -- Components Declarations
    -----------------------------------------------------------------
    component RF is
        generic( Dwidth: integer:=16;
                 Awidth: integer:=4);
        port(    clk,rst,WregEn: in std_logic;    
                 WregData:    in std_logic_vector(Dwidth-1 downto 0);
                 WregAddr,RregAddr: in std_logic_vector(Awidth-1 downto 0);
                 RregData:     out std_logic_vector(Dwidth-1 downto 0)
        );
    end component;

    component dataMem is
        generic( Dwidth: integer:=16;
                 Awidth: integer:=6;
                 dept:   integer:=64);
        port(    clk,memEn: in std_logic;    
                 WmemData:    in std_logic_vector(Dwidth-1 downto 0);
                 WmemAddr,RmemAddr: in std_logic_vector(Awidth-1 downto 0);
                 RmemData:     out std_logic_vector(Dwidth-1 downto 0)
        );
    end component;

    component ProgMem is
        generic( Dwidth: integer:=16;
                 Awidth: integer:=6;
                 dept:   integer:=64);
        port(    clk,memEn: in std_logic;    
                 WmemData:    in std_logic_vector(Dwidth-1 downto 0);
                 WmemAddr,RmemAddr: in std_logic_vector(Awidth-1 downto 0);
                 RmemData:     out std_logic_vector(Dwidth-1 downto 0)
        );
    end component;

    component BidirPin is
        generic( width: integer:=16 );
        port(   Dout:   in      std_logic_vector(width-1 downto 0);
                en:     in      std_logic;
                Din:    out     std_logic_vector(width-1 downto 0);
                IOpin:  inout   std_logic_vector(width-1 downto 0)
        );
    end component;

end aux_package;
