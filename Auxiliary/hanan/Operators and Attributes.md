VHDL - Operators and
Attributes

©Hanan Ribo

1

VHDL Operators
• In order to write any code efficiently it’s important to be familiar with the

predefined Operators and Attributes.

• Pre-defined operators:

 Assignment operators
 Logical operators
 Arithmetic operators
 Relational (comparison) operators
 Shift operators
 Concatenation operators

©Hanan Ribo

2

Assignment Operators

• Operator <= Used to assign a value to a SIGNAL
• Operator := Used to assign a value to a VARIABLE, CONSTANT, or GENERIC

and also for establishing initial values.

• Operator => Used to assign values to individual vector elements or with

OTHERS.
• Examples:

©Hanan Ribo

3

Logical Operators

• Used to perform logical operations.
• The data must be of type BIT, STD_LOGIC, or STD_ULOGIC (or their

extensions, BIT_VECTOR, STD_LOGIC_VECTOR, or STD_ULOGIC_VECTOR).

• The logical operators are:

NOT, AND, OR, NAND, NOR, XOR, XNOR

• Example:

©Hanan Ribo

4

Arithmetic Operators

• Used to perform arithmetic operations.
• The data can be of type INTEGER, SIGNED, UNSIGNED, or REAL (for

simulation only).

• If the std_logic_signed or the std_logic_unsigned package of the ieee

library is used, then STD_LOGIC_VECTOR can also be employed directly in
addition and subtraction operations

©Hanan Ribo

5

Relational (comparison) operators

• Used for making comparisons.
• The data can be any of the types listed before.

©Hanan Ribo

6

Shift Operators

• Used for shifting data left or right.
• Syntax:

 <left operand> <shift operation> <right operand>
 the left operand must be of type BIT_VECTOR
 the right operand must be an INTEGER

• The shift operators are:

©Hanan Ribo

7

Operator summary table

©Hanan Ribo

8

Attributes
• Definition: A value, function, type, range, signal, or constant that may

be associated with one or more types, objects, subprograms, etc.

• Description: An attribute gives extra information about a specific part of

a VHDL description (pre-defined). Additionally, users can define new
attributes (user-defined).

• Improving code maintenance and generality.
• Each type or subtype T has a basic attribute called T'Base, which

indicates the base type for type T. It should be noted that this attribute
could be used only as a prefix for other attributes.

• Syntax:  object_name ‘ attribute_name[ ( expression ) ];

©Hanan Ribo

9

Data Attributes (pre-defined)

The pre-defined, synthesizable data attributes are the following:

• d’LOW - Returns lower array index
• d’HIGH - Returns upper array index
• d’LEFT - Returns leftmost array index
• d’RIGHT - Returns rightmost array index
• d’LENGTH - Returns vector size
• d’RANGE - Returns vector range
• d’REVERSE_RANGE - Returns vector range in reverse order

Example:
So the equivalents are:

©Hanan Ribo

10

SIGNAL Attributes (pre-defined)

The pre-defined, synthesizable Signal attributes are the following:

• s’EVENT - Returns true when an event occurs on s
• s’STABLE - Returns true if no event has occurred on s

Example:
All the next four lines are equal and synthesizable. The condition return TRUE
on rising clk event.

©Hanan Ribo

11

Simulation purpose Attributes

For simulation only, there are many more attributes.

• Scalar type attributes
• Attributes of discrete or physical types and subtypes
• Attributes of the array type or objects of the array type
• Signals attributes
• Attributes of named entities

For details see the next link:

Extended predefined attributes

©Hanan Ribo

12

User-Defined Attributes

• VHDL also allows the construction of user-defined attributes.
• A user-defined attribute can be declared anywhere, except in a PACKAGE

BODY (not recognized by the synthesis tool).

• Attribute declaration:
• Attribute specification:

 attribute_type is any data type (BIT, INTEGER, STD_LOGIC_VECTOR, etc.)
 class is any of TYPE, SIGNAL, FUNCTION, etc.
 value is any of ‘0’, 27, ‘‘00 11 10 01’’, etc.

• Example:

©Hanan Ribo

13

Operator Overloading (user-defined operators)
• The arithmetic operations are specified between data of certain types.
• For instance, the pre-defined ‘‘+’’ operator does not allow addition
between data of type BIT. We can use ‘‘+’’ to indicate a new kind of
addition, between values of type BIT_VECTOR. This technique is called
operator overloading.

• Example:

©Hanan Ribo

14

