LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.aux_package.all;

-- AdderSub is capble of addition, substraction, neg, increment, decrement
ENTITY AdderSub IS
  GENERIC (n : INTEGER := 8);
  PORT (
		x,y  		: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		sub_cont 	: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        cout  		: OUT STD_LOGIC;
        s  			: OUT STD_LOGIC_VECTOR(n-1 downto 0));
		 
END AdderSub;
ARCHITECTURE dfl OF AdderSub IS
	SIGNAL reg : std_logic_vector(n-1 DOWNTO 0);
	SIGNAL x_new, y_new: std_logic_vector(n-1 DOWNTO 0);
	SIGNAL cin : std_logic;
BEGIN
	--if we do addition or increment then cout is 0
	--otherwise for subs, dec or neg cout is 1
	cin <= '1' when (sub_cont = "001" or sub_cont = "010") else '0';
 
	--Here we want to define the local x for calculation
	
	x_newD  : for i in 0 to n-1 generate

	x_new(i) <= '1' when (sub_cont = "011" and i = 1) else -- Y+2: x_new = 2 (00...010)
                '0' when (sub_cont = "011" and i /= 1) else
				'0' when (sub_cont = "100" and i = 0) else -- Y-2: x_new = -2 (11...110), cin=0 => Y+(-2)
                '1' when (sub_cont = "100" and i /= 0) else
				(x(i)) WHEN (sub_cont = "000") else -- for addition x_new = x
				(x(i) xor '1') WHEN (sub_cont = "010" or sub_cont="001") else -- for subs or neg we invert each bit and the with cin = 1 we get -x
				'Z' WHEN (sub_cont = "ZZZ")
				ELSE '0'; -- if sub_cont/ALUFN[2:0] is something else x_temp = 0
	end generate;

	y_new <= y WHEN (sub_cont = "000" or sub_cont = "001" or  sub_cont="011" 
		   	or  sub_cont="100") ELSE --for addition, subs, inc, dec y_new = y
			(OTHERS => 'Z') WHEN sub_cont = "ZZZ" ELSE
			(OTHERS => '0'); -- if neg or something else y_new = 0

	--Here we use full adders to form a ripple adder 
	first: FA port map(
	xi => x_new(0),
	yi => y_new(0),
	cin => cin,
	s => s(0),
	cout => reg(0)
	);
	
	rest : for i in 1 to n-1 generate
	chain : FA port map(
	xi => x_new(i),
	yi => y_new(i),
	cin => reg(i-1),
	s => s(i),
	cout => reg(i)
	);
	end generate;
	--Then we make sure to save the last carry out
	cout <= reg(n-1);

	END dfl;