--============================================================================
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- MUL16 module - 16x16 -> 32 bit unsigned multiplier built from four
-- 8x8 partial products (mapped by Quartus onto the embedded 9-bit multipliers)
--
--   A = AH & AL,  B = BH & BL   (8-bit half-words of the 16-bit operands)
--   P0 = AL*BL, P1 = AL*BH, P2 = AH*BL, P3 = AH*BH
--   M  = P1 + P2
--   RESULT = P0 + (M << 8) + (P3 << 16)
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MUL16 IS
	generic(
		DATA_BUS_WIDTH 	: integer := 32
	);
	PORT(
		--Inputs (lower half-words of rs1/rs2)
		a_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);
		b_i 		: IN 	STD_LOGIC_VECTOR(DATA_BUS_WIDTH/2-1 DOWNTO 0);

		--Output (full product)
		res_o 		: OUT	STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0)
	);
END MUL16;


ARCHITECTURE dataflow OF MUL16 IS
	constant HALF_WIDTH			: integer := DATA_BUS_WIDTH/2;	-- 16
	constant QUARTER_WIDTH		: integer := DATA_BUS_WIDTH/4;	-- 8

	constant ZEROS_HALF			: UNSIGNED(HALF_WIDTH-1 DOWNTO 0) 		:= (others => '0');
	constant ZEROS_QUARTER		: UNSIGNED(QUARTER_WIDTH-1 DOWNTO 0)	:= (others => '0');

	-- Operand half-words
	SIGNAL	al_w, ah_w			: UNSIGNED(QUARTER_WIDTH-1 DOWNTO 0);
	SIGNAL	bl_w, bh_w			: UNSIGNED(QUARTER_WIDTH-1 DOWNTO 0);

	-- 8x8 -> 16 partial products
	SIGNAL	p0_w				: UNSIGNED(HALF_WIDTH-1 DOWNTO 0);	-- AL*BL
	SIGNAL	p1_w				: UNSIGNED(HALF_WIDTH-1 DOWNTO 0);	-- AL*BH
	SIGNAL	p2_w				: UNSIGNED(HALF_WIDTH-1 DOWNTO 0);	-- AH*BL
	SIGNAL	p3_w				: UNSIGNED(HALF_WIDTH-1 DOWNTO 0);	-- AH*BH

	-- Middle sum M = P1 + P2 (one extra bit for the carry)
	SIGNAL	mid_w				: UNSIGNED(HALF_WIDTH DOWNTO 0);

	-- Aligned 32-bit terms of the final sum
	SIGNAL	term0_w				: UNSIGNED(DATA_BUS_WIDTH-1 DOWNTO 0);	-- P0
	SIGNAL	term1_w				: UNSIGNED(DATA_BUS_WIDTH-1 DOWNTO 0);	-- M  << 8
	SIGNAL	term2_w				: UNSIGNED(DATA_BUS_WIDTH-1 DOWNTO 0);	-- P3 << 16

	SIGNAL	res_w				: UNSIGNED(DATA_BUS_WIDTH-1 DOWNTO 0);

BEGIN
--------------------------------------------------------------------------------------------------------
-- Split each operand into high and low half-words
--------------------------------------------------------------------------------------------------------
al_w	<= UNSIGNED(a_i(QUARTER_WIDTH-1 DOWNTO 0));
ah_w	<= UNSIGNED(a_i(HALF_WIDTH-1 DOWNTO QUARTER_WIDTH));
bl_w	<= UNSIGNED(b_i(QUARTER_WIDTH-1 DOWNTO 0));
bh_w	<= UNSIGNED(b_i(HALF_WIDTH-1 DOWNTO QUARTER_WIDTH));

--------------------------------------------------------------------------------------------------------
-- Four 8x8 partial products
--------------------------------------------------------------------------------------------------------
p0_w	<= al_w * bl_w;
p1_w	<= al_w * bh_w;
p2_w	<= ah_w * bl_w;
p3_w	<= ah_w * bh_w;

--------------------------------------------------------------------------------------------------------
-- Combine: RESULT = P0 + ((P1 + P2) << 8) + (P3 << 16)
--------------------------------------------------------------------------------------------------------
mid_w	<= ('0' & p1_w) + ('0' & p2_w);

term0_w	<= ZEROS_HALF & p0_w;
term1_w	<= ZEROS_QUARTER(QUARTER_WIDTH-2 DOWNTO 0) & mid_w & ZEROS_QUARTER;
term2_w	<= p3_w & ZEROS_HALF;

res_w	<= term0_w + term1_w + term2_w;
res_o	<= STD_LOGIC_VECTOR(res_w);

END dataflow;
