library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;

entity tb_top is
	constant n : integer := 8;
	constant k : integer := 3;   
	constant m : integer := 4;   
	constant ROWmax : integer := 24; -- Extended to 24 tests
end tb_top;

architecture rtb of tb_top is
	type mem is array (0 to ROWmax) of std_logic_vector(4 downto 0);
	SIGNAL Y,X:  STD_LOGIC_VECTOR (n-1 DOWNTO 0);
	SIGNAL ALUFN :  STD_LOGIC_VECTOR (4 DOWNTO 0);
	SIGNAL ALUout:  STD_LOGIC_VECTOR(n-1 downto 0); 
	SIGNAL Nflag,Cflag,Zflag,Vflag: STD_LOGIC; 
	
    -- Added 5 custom edge-case test operations at the end
	SIGNAL Icache : mem := (
		"01000","01001","01010","01011","01100","01000","01001","01111","10000","10001",
		"10010","10000","10001","10010","11001","11010","11101","11110","11011","00100",
        "01000", -- Custom Test 1: Forced Addition Overflow
        "10000", -- Custom Test 2: Extreme Left Shift
        "11000", -- Custom Test 3: Bitwise NOT
        "01100", -- Custom Test 4: Y-2 Decrement
        "01010"  -- Custom Test 5: Negation of zero
	);
begin
	L0 : top generic map (n,k,m) port map(Y,X,ALUFN,ALUout,Nflag,Cflag,Zflag,Vflag);
    
    tb_x_y : process
    begin
        x <= (others => '1');
        y <= (others => '1');
        wait for 50 ns;
        for i in 0 to 45 loop -- Extended loop for new tests
            x <= x-10;
            y <= y-1;
            wait for 50 ns;
        end loop;
        wait;
    end process;

    tb_ALUFN : process
    begin
        ALUFN <= (others => '0');
        for i in 0 to ROWmax loop
            ALUFN <= Icache(i);
            wait for 100 ns;
        end loop;
        wait;
    end process;
end architecture rtb;