VHDL - Code Structure
Entity, Architecture, Configuration
©Hanan Ribo
1

.vhd File Structure
A standalone file of VHDL code is composed of at least three fundamental
sections:
• LIBRARY declarations: Contains a list of all libraries to be used in the
design. For example: ieee, std, work, etc.
• ENTITY: Specifies the I/O pins of the circuit.
• ARCHITECTURE: Contains the VHDL code proper, which describes how the
circuit should behave and function.
©Hanan Ribo 2

.vhd File Structure
©Hanan Ribo 3

Library Declarations
• To declare a LIBRARY (make it visible to the design) two lines of code are
needed, one containing the name of the library, and the other a use
clause, as shown before.
©Hanan Ribo 4

Entity
Entity defines the input and output of our design as a “black box” view.
entity NAME_OF_ENTITY is
generic (generic_declarations);
port (signal_names: mode type;
signal_names: mode type;
:
signal_names: mode type);
end NAME_OF_ENTITY ;
©Hanan Ribo 5

Entity - mode of the signals (PORTs)
mode: is one of the reserved words to indicate the signal direction:
• in – input signal
• out – output signal
• inout – usually used for bi-directional bus
• buffer - output signal and can be read
All are read by other entities
type: example of signal type.
• bit – Boolean 1 or 0
• bit_vector – Boolean vector
generic determine the architecture local constants.
:
generic (constant values of types: NATURAL, POSITIVE, INTEGER, STRING);
©Hanan Ribo 6

Entity - Examples
©Hanan Ribo 7

Architecture
• The ARCHITECTURE is a description of how the circuit should behave.
| • An ARCHITECTURE |     | must be associated to only single ENTITY. |     |                |     |
| ----------------- | --- | ----------------------------------------- | --- | -------------- | --- |
| architecture      |     | architecture_name                         |     | of entity_name | is  |
[ component declaration ]
[ signal declaration ]
begin
[ design logic - the code part]
| end | architecture_name |             | ;   |     |     |
| --- | ----------------- | ----------- | --- | --- | --- |
|     |                   | ©Hanan Ribo |     |     | 8   |

Architecture – Example1
©Hanan Ribo 9

Architecture – Example2
RS Latch
©Hanan Ribo 10

Architecture – Example3
©Hanan Ribo 11

Configuration – Simulation Environment
• Configuration is a simulation design unit which flexes the design
process.
• In order to associate one ARCHITECTURE from several options, we
use Configuration.
©Hanan Ribo 12