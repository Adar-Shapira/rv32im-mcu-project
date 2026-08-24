---------------------------------------------------------------------------------------------
-- Advanced CPU architecture and Hardware Accelerators Lab 361-1-4693 BGU
-- Final Project 2026 -- RV32IM-based MCU, single-cycle
--
-- BidirPin -- the tri-state buffer of Figure 5, and the block Figure 1 points at.
--
-- USED AS IS. Copied from the students' own Lab 3:
--     Auxiliary/Lab 5/Auxilary/Lab3/DUT/BidirPin.vhd
-- Everything below this header is BYTE-IDENTICAL to that file, md5
-- ab12d81dcdc85d91071b077359833bbd. Only this header was added and the filename
-- capitalised to match DUT/RV32IMscMCU's convention. Entity and port names are
-- unchanged, so they do not follow this project's _i/_o convention.
--
-- WHY THIS FILE AND NOT AN INLINE "WHEN en THEN ELSE Z"
--   Figure 1 (p3) carries a highlighted annotation, "Click Me: Bi-directional
--   Data BUS (reminder)", whose link target is this Lab 3 entity. Figure 5 (p5)
--   then draws exactly this element: a tri-state buffer driving Data<7..0>,
--   enabled by a chip select ANDed with MemRead. Using the supplied block keeps
--   the correspondence with the figures literal.
--
-- ONLY HALF OF IT IS USED HERE, AND THAT IS FINE
--   Lab 3 used this for a real bidirectional PACKAGE PIN, so it has both
--   directions: Dout/en drive IOpin, and Din reads it back. The SFR read bus needs
--   only the driving half, so every instantiation in RV32IMscMCU.vhd maps
--   Din => open. The unused half has no driver and synthesis removes it.
--
-- HOW IT IS USED, SO THE MULTI-DRIVER STRUCTURE IS NOT A SURPRISE
--   One instance per readable register, all of them associating IOpin with the
--   same slice of the shared read bus. That is a genuine multiply-driven resolved
--   signal -- which is what a tri-state bus IS -- and it is safe only because at
--   most one enable is ever high. RV32IMscMCU.vhd builds the terminator's enable
--   as the exact complement of the others by construction, and asserts the
--   at-most-one property in simulation.
---------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-----------------------------------------------------------------
entity BidirPin is
	generic( width: integer:=16 );
	port(   Dout: 	in 		std_logic_vector(width-1 downto 0);
			en:		in 		std_logic;
			Din:	out		std_logic_vector(width-1 downto 0);
			IOpin: 	inout 	std_logic_vector(width-1 downto 0)
	);
end BidirPin;

architecture comb of BidirPin is
begin 

	Din  <= IOpin;
	IOpin <= Dout when(en='1') else (others => 'Z');
	
end comb;

