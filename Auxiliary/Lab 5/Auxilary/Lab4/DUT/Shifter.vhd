LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.aux_package.all;
-- Barrel Shifter:
-- The input is X,Y (n-bit vectors) and the output is Y (as the shifterd vector)
-- and carry out bit. X is the number of shiftes to be performed.
-- dir = ALUFN[2:0]. If dir = '001' then SHR,  if dir = '000' then SHL
-- otherwise the output is zero. 

ENTITY Shifter IS
  GENERIC (	n	: INTEGER := 8; -- Input size
			k	: INTEGER := 3); -- Number of steps Log(n)
  PORT ( X,Y	: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
		 dir	: IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- direction: left or right
         res	: OUT STD_LOGIC_VECTOR(n-1 downto 0); -- shifted vector as the output
		 cout	: OUT STD_LOGIC
	    );
END Shifter;

ARCHITECTURE dfl OF Shifter IS
	SUBTYPE vector IS std_logic_vector (n-1 DOWNTO 0);
	TYPE stepMatrix IS ARRAY (k DOWNTO 0) OF vector; -- type of a stepMatrix with size (k,n)
	SIGNAL stepMat		: stepMatrix; -- We will use this stepMatrix to store the vector each step of the shifting
	SIGNAL carry : std_logic_vector(k-1 DOWNTO 0);
BEGIN

	-- here we initialize the first row of the stepMatrix: 
	-- if we shift left then stepMat(0) = Y, if we shift right then stepMat(0) is reversed Y
	firstStep : for i in 0 to n-1 generate
		stepMat(0)(i) <= Y(i) 	WHEN dir = "000" ELSE
					 Y(n-1-i)	WHEN dir = "001";
	end generate;

	shiftingY: for step in 1 to k generate
		-- We add zeros to the start of the shifted vector according to X
		stepMat(step)(2**(step-1) - 1 DOWNTO 0) <= (OTHERS => '0') 							WHEN X(step-1)='1' ELSE
											    stepMat(step-1)(2**(step-1) - 1 DOWNTO 0)	WHEN X(step-1)='0';
										    					 			
		-- Shift Y according to X
		stepMat(step)(n-1 DOWNTO 2**(step-1)) <= stepMat(step-1)(n-1-2**(step-1) DOWNTO 0)	WHEN X(step-1)='1' ELSE
											 stepMat(step-1)(n-1 DOWNTO 2**(step-1))	WHEN X(step-1)='0';
	end generate;
	
	-- If we're shifting right we want to reverse again the shifted vector again otherwise unaffected
	inversingY	: for i in 0 to n-1 generate
		res(i) <= stepMat(k)(i)	 	WHEN dir = "000" ELSE
				  stepMat(k)(n-1-i) WHEN dir = "001" ELSE
				  '0';
	end generate;
	
	
	--We Want to save the Carry out
	--so each step we can save the last carry out
	carry(0) <= stepMat(0)(n-1) WHEN X(0) = '1' ELSE
				'0' 			WHEN X(0) = '0';
	--if there was a shift we save the new carry out else we just take the carry out from the previous step
	carry_out : for step in 1 to k-1 generate
		carry(step) <= carry(step-1) 				WHEN X(step) = '0' ELSE
					   stepMat(step)(n-2**step)	WHEN X(step) = '1';
	end generate;
	
	cout <= carry(k-1) WHEN (dir = "001" or dir = "000") ELSE
			'0';
	
END dfl;