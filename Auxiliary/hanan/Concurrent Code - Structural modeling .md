VHDL - Concurrent Code
Structural modeling

©Hanan Ribo

1

Introduction - Design Hierarchy

There are three types of digital design approach:
 Bottom-Up approach – Implemented using Structural modeling:

We first identify the building Entities that are available to us. We build bigger Entities,
using these building Entities. These Entities are then used for higher-level Entities
until we build the top-level Entity in the design.

 Top-Down approach – Implemented using Behavioral modeling:

We define the top-level Entity and identify the sub- Entities necessary to build the
top-level Entity. We further subdivide the sub- Entities until we come to leaf Entities,
which are the Entities that cannot further be divided.

 Mixed approach:

A combination of top-down and bottom-up flows (typically used).

©Hanan Ribo

2

Bottom-Up approach – Structural modeling

©Hanan Ribo

3

Top-Down approach – Behavioral modeling

©Hanan Ribo

4

Mixed approach – Chip design

• Typically, a combination of top-down and bottom-up flows is used.
• Design architects define the specifications of the top-level block.
• Logic designers decide how the design should be structured by breaking up

the functionality into blocks and sub-blocks (Top-Down).

• The Circuit designers are designing optimized circuits for leaf-level cells.

They build higher-level cells by using these leaf cells (Bottom-Up).

• The design flow meets at an intermediate point where the switch-level

circuit designers have created a library of leaf cells by using switches, and
the logic level designers have designed from top-down until all modules are
defined in terms of leaf cells.

©Hanan Ribo

5

Structural Architecture Modeling

• It is a construction of hierarchical design.
• Describes connection between existing components (entities).
• Components are declared before the architecture.
• Components are connected to each other using signals.

©Hanan Ribo

6

Structural Architecture Modeling

• The top level entity (called also main-code)

connects all its sub-entities using COMPONENTs.
• The depicted design contains three hierarchical

levels.

• Each Entity element in our design must be written

in a separate entity_name.vhd file

©Hanan Ribo

7

COMPONENT
• A COMPONENT is simply a piece of conventional code (LIBRARY declarations

+ENTITY +ARCHITECTURE).

• By declaring such code as being a COMPONENT, it can then be used within

another circuit, thus allowing the construction of hierarchical designs.
• A COMPONENT is also another way of partitioning a code and providing

code sharing and code reuse.
An example: commonly used circuits, like flip-flops, multiplexers, adders, basic gates,
etc., can be placed in a LIBRARY, so any project can make use of them without having to
explicitly rewrite such codes.

• To use (instantiate) a COMPONENT, it must first be declared.

©Hanan Ribo

8

COMPONENT declaration

COMPONENT declaration – two possible locations:
• In its immediate upper level ARCHITECTURE (inside the declarative part).
• In a Package
Syntax:
• The syntax is identical to ENTITY, except the key word COMPONENT.

©Hanan Ribo

9

COMPONENT instantiation

COMPONENT instantiation:
• After a COMPONENT declaration, in order to use it (instantiation) within its
immediate upper level ARCHITECTURE (after keyword BEGIN, in the body
section), we use PORT MAP statement.

• Using PORT MAP statements we interconnect between COMPONENTs in

the same hierarchical level.

• There are two methods for COMPONENT instantiation:

1) nominal mapping (decreasing syntax errors):

©Hanan Ribo

10

COMPONENT instantiation

2) positioning mapping (more convenient):

Note1: the current level port list must be in exact same order of the lower level ENTITY.

Example:

Note2: If we don’t need to connect some of the COMPONENT ports, we can use with
the keyword OPEN.

©Hanan Ribo

11

Structural Architecture example – MUX 2-1

©Hanan Ribo

12

Structural Architecture example – MUX 2-1

©Hanan Ribo

13

GENERIC MAP
• When we use COMPONENT which contains GENERIC statement, we can
pass the GENERIC parameters value through GENERIC MAP statement.

• Syntax:

• Example:

• Note:

If we don’t use GENERIC MAP the, the COMPONENT’s GENERIC parameters
will be as the defined default.

©Hanan Ribo

14

GENERIC MAP example – Ripple Adder

©Hanan Ribo

15

