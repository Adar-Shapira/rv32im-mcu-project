VHDL - Data Types,
User-defined Types
©Hanan Ribo
1

Topics
• Pre-Defined Data Types
• User-Defined Data Types
• Subtypes
• Arrays
• Port Array
• Records
• Signed and Unsigned Data Types
• Data Conversion
©Hanan Ribo 2

In order to write VHDL code efficiently
it is essential to know
• What data types are allowed.
• How to specify and use them.
• What data types are synthesizable.
• Data compatibility and data conversion
• Remember: operations between data of different types are not
allowed (unless using data conversion).
©Hanan Ribo 3

Architecture declarative objects
• In ARCHITECTURE declarative part, we can declare the two next objects:
CONSTANT and SIGNAL
• CONSTANT object:
 Serves to establish default values.
 Can be declared in a PACKAGE, ENTITY, or ARCHITECTURE.
 When declared in a package, it is truly global (for the entities that using the package).
 When declared in an entity (after PORT), it is global to all architectures that follow that top entity.
 when declared in an architecture (in its declarative part), it is local to that architecture’s code.
• Syntax:
CONSTANT name : data_type := value ;
©Hanan Ribo 4

Architecture declarative objects
• SIGNAL object:
 SIGNAL serves to pass values in and out the circuit, as well as between its internal
units (a signal represents circuit interconnects ).
 All PORTS of an ENTITY are signals by default (seen by its architecture only).
 When declared in an architecture (in its declarative part), it uses only as
interconnections between its internal units (seen by architecture only).
 Direct SIGNALs of different ENTITYs must not be wired (their internal and can be
seen by their architecture only), it’s possible using intermediate SIGNALs.
Syntax:
SIGNAL signal_name : type [:= initial_value];
©Hanan Ribo 5

Pre-Defined Data Types
BIT data type: two-level values logic ‘0’, ‘1’.
©Hanan Ribo 6

Pre-Defined Data Types
BOOLEAN data type: True, False.
• The Boolean type is used for conditional operations.
• The default value of any object of the Boolean type is false.
• Boolean values (false and true) are NOT identical to logical 0 and 1,
respectively.
©Hanan Ribo 7

Pre-Defined Data Types
INTEGER data type: 32-bit integers (from -2,147,483,647 to +2,147,483,647).
Integer Sub Types:
• NATURAL data type: Non-negative integers (from 0 to +2,147,483,647).
• POSITIVE data type: Non-negative integers (from 1 to +2,147,483,647).
©Hanan Ribo 8

Data Types - STD_LOGIC_1164 IEEE package
STD_LOGIC , STD_LOGIC_VECTOR data types:
•
A 9-value resolved logic type Std_logic is not a part of the VHDL Standard.
It is defined in IEEE Std 1164.
| 'U‘     | - Uninitialized                  |            |           |         |
| ------- | -------------------------------- | ---------- | --------- | ------- |
| ‘X’     | - Forcing Unknown (synthesizable |            | unknown)  |         |
| ‘0’     | - Forcing Low (synthesizable     | logic ‘1’) |           |         |
| ‘1’     | - Forcing High (synthesizable    | logic ‘0’) |           |         |
| ‘Z’     | - High impedance (synthesizable  |            | tri-state | buffer) |
| ‘W’     | - Weak unknown                   |            |           |         |
| ‘L’     | - Weak low                       |            |           |         |
| ‘H’     | - Weak high                      |            |           |         |
| ‘–’     | - Don’t care                     |            |           |         |
©Hanan Ribo
9

| STD_LOGIC | , STD_LOGIC_VECTOR - | examples |
| --------- | -------------------- | -------- |
©Hanan Ribo
10

STD_LOGIC - Resolved logic system
If multiple drivers are driving different values onto a signal of the std_logic
type, the signal value will be decided by the next resolution table (The type
has a built-in mechanism to determine what the signal value should be):
std_ulogic data type – is the unresolved type
©Hanan Ribo 11

User-Defined Data Types
• VHDL also allows the user to define his own data types of two categories
integer and enumerated.
• User defined data types are usually defined in the declarative part of the
architecture unit, or it is defined in the packet unit.
• Syntax:
©Hanan Ribo 12

User-defined integer types
• Definition: The integer type is a scalar whose set of values includes integer
numbers of the specified range.
• Syntax:
• Examples:
©Hanan Ribo 13

User-defined enumerate types
• Definition: The enumeration type is a type whose values are defined by listing
(enumerating) them explicitly.
• Note: The encoding of enumerated types is done sequentially and automatically
unless specified otherwise by a user-defined.
• Syntax:
• Examples:
©Hanan Ribo 14

Subtypes
• A SUBTYPE is a TYPE with a constraint.
• The main reason for using a subtype rather than specifying a new type is
that, though operations between data of different types are not allowed,
they are allowed between a subtype and its corresponding base type.
• Syntax:
• Examples:
©Hanan Ribo 15

Arrays
• Arrays are collections of objects of the same type.
• The allowed data types are: CONSTANT, SIGNAL, VARIABLE.
• They can be 1D, 2D, or 1Dx1D (higher dimensions, are not synthesizable).
• Syntax:
©Hanan Ribo 16

Arrays - Examples
©Hanan Ribo 17

Records
• Definition: Records are similar to arrays, with the only difference that they
contain objects of different types.
• Example:
©Hanan Ribo 18

Signed and Unsigned Data Types
• Signed and Unsigned Data Types defined in the std_logic_arith package of
the ieee library, their syntax is similar to that of STD_LOGIC_VECTOR.
• An UNSIGNED value is a number never lower than zero.
• An SIGNED value is a number in two’s complement format.
• Their intended mainly for arithmetic operations, that is, contrary to
STD_LOGIC_VECTOR (On the other hand, logical operations are not allowed).
• Examples:
©Hanan Ribo 19

packages std_logic_signed and std_logic_unsigned
• There is a simple way of allowing data of type STD_LOGIC_VECTOR to
participate directly in arithmetic operations.
• For that, the ieee library provides two packages, std_logic_signed and
std_logic_unsigned.
• Examples:
©Hanan Ribo 20

Data Conversion
• VHDL does not allow direct operations (arithmetic, logical, etc.) between
data of different types.
• It is often necessary to convert data from one type to another. for that, we
invoke a FUNCTION from a pre-defined PACKAGE which is capable of doing
it for us.
• Conversion functions:
• Overloading operators:
©Hanan Ribo 21

Data Conversion
• Example 1:
©Hanan Ribo 22

Data Conversion
• Example 2:
©Hanan Ribo 23

Synthesizable data types
©Hanan Ribo 24