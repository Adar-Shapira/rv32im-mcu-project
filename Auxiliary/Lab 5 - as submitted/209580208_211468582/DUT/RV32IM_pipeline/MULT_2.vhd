--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Figure 7 multiplier stage 2 (MEM): combine EX/MEM partial products.
-- RESULT = P0 + ((P1 + P2) << 8) + (P3 << 16)
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY multiplier_2 IS
	PORT(
		p0_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p1_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p2_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		p3_i	: IN	STD_LOGIC_VECTOR(15 DOWNTO 0);
		res_o	: OUT	STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END multiplier_2;

ARCHITECTURE dataflow OF multiplier_2 IS
	SIGNAL middle_w		: STD_LOGIC_VECTOR(16 DOWNTO 0);
	SIGNAL p0_ext_w		: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL middle_shift_w	: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL p3_shift_w		: STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN
	middle_w		<= ('0' & p1_i) + ('0' & p2_i);
	p0_ext_w		<= X"0000" & p0_i;
	middle_shift_w	<= "0000000" & middle_w & X"00";
	p3_shift_w		<= p3_i & X"0000";

	res_o <= p0_ext_w + middle_shift_w + p3_shift_w;
END dataflow;
