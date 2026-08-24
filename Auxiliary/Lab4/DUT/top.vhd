LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.aux_package.all;
-------------------------------------
ENTITY top IS
  	GENERIC (n : INTEGER := 8;
		   k : integer := 3;   -- k=log2(n)
		   m : integer := 4	); -- m=2^(k-1)
  	PORT 
  	(  
		Y_i,X_i		: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		ALUFN_i 	: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		ALUout_o	: OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
		Nflag_o,Cflag_o,Zflag_o,Vflag_o: OUT STD_LOGIC
  	); -- Zflag,Cflag,Nflag,Vflag
END top;
-------------------------------------
ARCHITECTURE struct OF top IS 
	-- We will store X and Y for each of the components so that we change them only if needed
	signal X_AS, Y_AS, X_L, Y_L, X_S, Y_S : STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (others => '0');

	-- separate carry out for addersub and shifter (for logic always 0)
	signal cout_AS, cout_S 				: STD_LOGIC;

	-- result for each component
	signal res_AS, res_L, res_S 		: STD_LOGIC_VECTOR(n-1 DOWNTO 0);

	-- result for each component
	signal alufn_AS, alufn_L, alufn_S 	: STD_LOGIC_VECTOR(2 DOWNTO 0) := (others => '0');
	signal zero_vector 					: STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (  others => '0');
	signal ALUout_int 					: STD_LOGIC_VECTOR(n-1 DOWNTO 0);

BEGIN
	-- Here we store inputs according to ALUFN[4:3]---------------------
	X_AS 	<= X_i when (ALUFN_i(4 DOWNTO 3) = "01") else (others => '0');
	X_L 	<= X_i when (ALUFN_i(4 DOWNTO 3) = "11") else (others => '0');
	X_S 	<= X_i when (ALUFN_i(4 DOWNTO 3) = "10") else (others => '0');
	
	Y_AS 	<= Y_i when (ALUFN_i(4 DOWNTO 3) = "01") else (others => '0');
	Y_L 	<= Y_i when (ALUFN_i(4 DOWNTO 3) = "11") else (others => '0');
	Y_S 	<= Y_i when (ALUFN_i(4 DOWNTO 3) = "10") else (others => '0');
	
	alufn_AS <= ALUFN_i(2 DOWNTO 0) when (ALUFN_i(4 DOWNTO 3) = "01") else (others => '0');
	alufn_L <= ALUFN_i(2 DOWNTO 0) when (ALUFN_i(4 DOWNTO 3) = "11") else (others => '0');
	alufn_S <= ALUFN_i(2 DOWNTO 0) when (ALUFN_i(4 DOWNTO 3) = "10") else (others => '0');
	--------------------------------------------------------------------
	
	-- Here we port map each component----------------------------------
	hivut_AS :AdderSub
		
		generic map (n=>n)
		
		port map
		(
			x => X_AS,
			y => Y_AS,
			sub_cont => alufn_AS,
			cout => cout_AS,
			s => res_AS
		);
		
	hivut_L : LOGIC
	
		generic map (n=>n)

		port map
		(
			x => X_L,
			y => Y_L,
			alufn => alufn_L,
			aluout => res_L
		);
		
	hivut_S :Shifter 
	
		generic map (n=>n, k=>k)

		port map
		(
			x => X_S,
			y => Y_S,
			dir => alufn_S,
			cout => cout_S,
			res => res_S
		);
	---------------------------------------------------------------------
	
	-- Choose which result to take as an output according to ALUFN[4:3]
	ALUout_int <= res_AS WHEN (ALUFN_i(4 DOWNTO 3)= "01") else
				res_L WHEN (ALUFN_i(4 DOWNTO 3)= "11") else
				res_S WHEN (ALUFN_i(4 DOWNTO 3)= "10") else
				(others => '0');
				
	-----------------flags------------------
	Zflag_o <= '1' when (ALUout_int = zero_vector) else '0' ;
	Nflag_o <= '1' when (ALUout_int(n-1) ='1') else '0' ;

	-- Choose which carry out to take as an output according to ALUFN[4:3]
	WITH ALUFN_i(4 DOWNTO 3) select
		Cflag_o <= 	cout_AS	 	WHEN "01", 
					'0'  		WHEN "11",
					cout_S 		WHEN "10", 
					'0' 		WHEN OTHERS;
					
	-- V=1: add/sub use X_i and Y_i; inc/dec ignore X_i (X_AS is zero) — use Y_i vs result only
	Vflag_o <= '1' WHEN
				(ALUFN_i(4 DOWNTO 0) = "01000")
					and (X_i(n-1) = Y_i(n-1)) and (X_i(n-1) /= ALUout_int(n-1))
				else '1' WHEN
				(ALUFN_i(4 DOWNTO 0) = "01011")
					and (Y_i(n-1) = '0') and (ALUout_int(n-1) = '1')
				else '1' WHEN
				(ALUFN_i(4 DOWNTO 0) = "01001")
					and (X_i(n-1) /= Y_i(n-1)) and (X_i(n-1) = ALUout_int(n-1))
				else '1' WHEN
				(ALUFN_i(4 DOWNTO 0) = "01100")
					and (Y_i(n-1) = '1') and (ALUout_int(n-1) = '0')
				else '1' WHEN -- Neg of smallest negative (e.g. 10000000)
				(X_i(n-1) = '1') and (X_i(n-2 DOWNTO 0) = (n-2 DOWNTO 0 => '0')) and (ALUFN_i(4 DOWNTO 0) = "01010")
				else '0';
	
	ALUout_o <= ALUout_int;
	
END struct;