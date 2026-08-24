--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Figure 7 multiplier stage 1 (EX): four 8x8 partial products.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY multiplier_1 IS
	PORT(
		a_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		b_i		: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p0_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p1_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p2_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p3_o	: OUT	STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END multiplier_1;

ARCHITECTURE dataflow OF multiplier_1 IS
	SIGNAL a_low_w, a_high_w	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL b_low_w, b_high_w	: STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
	a_low_w		<= a_i(7 DOWNTO 0);
	a_high_w	<= a_i(15 DOWNTO 8);
	b_low_w		<= b_i(7 DOWNTO 0);
	b_high_w	<= b_i(15 DOWNTO 8);

	p0_o <= a_low_w  * b_low_w;
	p1_o <= a_low_w  * b_high_w;
	p2_o <= a_high_w * b_low_w;
	p3_o <= a_high_w * b_high_w;
END dataflow;
