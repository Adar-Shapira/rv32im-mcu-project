VHDL - Combinatorial
PROCESS Logic Synthesis
©Hanan Ribo
1

Introduction
• The next step after HDL code Simulation is HDL code Synthesis.
• Synthesis contains the next three steps:
 conversion of the high-level VHDL (or Verilog) language, which
describes the circuit at the Register Transfer Level (RTL), into a netlist at
the gate level.
 Optimization of the gate-level netlist for speed (minimize critical path)
and for area (minimize Logic function).
 Implementation of the optimized gate-level netlist based on
MUXs+LUTs, Latches, FFs (in case of FPGA as a target Hardware).
• The last step is a place and route (fitter), software will generate the
physical layout for a FPGA chip or will generate the masks for an ASIC
chip.
©Hanan Ribo 2

Synthesis coding approach
• Synthesis tools and Simulation tools translate PROCESS based HDL code in a
different way (concurrent code translated in the same way).
• Synthesis tools search for adjustment of VHDL code to one of the next three
template kinds (ieee-1076.6 standard):
Combinational Logic, Synchronous Logic, Latch based Logic.
• Our goal:
 writing of HDL code which will be translated in the same exact way by all
Synthesis and Simulation tools.
 Avoid of HDL code which synthesized with hardware errors in the required
design (must avoid from Sick Hardware).
 Important rule: when you write HDL code, think Hardware!
©Hanan Ribo 3

Note: Unusual and Unsupported design approach
With a guarded BLOCK or with WHEN statements (using concurrent code)
even very simple sequential circuits can be constructed. This, however, is
Unusual and Unsupported design approach.
In conclusion: Synchronous design will be described using PROCESS only!
DFF implementation example using concurrent code
©Hanan Ribo 4

PROCESS Logic Synthesis
The way we write a PROCESS affects its synthesis and is associated with one of
the following two synthesis types:
• Combinatorial PROCESS (Combinational Logic Circuit):
 PROCESS that its sensitivity list contains all its internal input SIGNALS and the
PROCESS doesn’t contain IF-THEN statement which its condition on SIGNAL
event.
 This kind of PROCESS describes a combinational logic circuit.
 If we write a partial sensitivity list, the compiler completes it, differ from
simulation environment.
• Sequential PROCESS (Synchronous / Asynchronous Logic Circuit):
 PROCESS that its sensitivity list contains a input SIGNAL and the PROCESS
contains IF-THEN statement which its condition on SIGNAL event.
 This kind of PROCESS describes FFs based sequential logic circuit triggered by a
SIGNAL event.
©Hanan Ribo 5

Combinatorial PROCESS - Rules
In order the compiler will synthesize the a PROCESS as a Combinational Logic
Circuit we must obey the next three rules (Combinational Logic template):
Rule 1: Make sure that all the input SIGNALS of the required combinational
circuit appear in the PROCESS sensitivity list.
Rule 2: Don’t use IF-THEN statement which its condition on SIGNAL event
(SIGNAL transition).
Rule 3: PROCESS must cover all the permutations (full truth table
description) of the input and output SIGNALS of the combinational circuit.
 Use ELSE option in IF-THEN statement.
 For a complex Combinational Circuit description, use default SIGNALS
assignments (at the PROCESS beginning we write all the default output
SIGNALS assignment and later we use IF-THEN without covering all
permutations).
©Hanan Ribo 6

General rules for Combinational Logic Circuit
• General Rule 1: Use SIGNALS assignment without feedback (a SIGNAL must
appear only in one assignment side).
• General Rule 2: Avoid from multiple assignment to the same SIGNAL from
different PROCESSES (cause multiple driven).
©Hanan Ribo 7

Combinatorial PROCESS – MUX 3-1 example
• The PROCESS must cover all the permutations (full truth table description)
of the input and output SIGNALS of the combinational circuit.
• Attitude 1: use ELSE option in IF-THEN statement.
• Attitude 2: use default SIGNALS assignments
©Hanan Ribo 8

Combinatorial PROCESS – MUX 3-1 example
Synthesis result:
©Hanan Ribo 9
S
I2
I1
I0
[1
[2
[2
[2
..0
..0
..0
..0
]
]
]
]
2
2
' h
' h
1
0
--
--
E
A
B
E
A
B
q
[1
[1
q
[1
[1
u
..0
..0
u
..0
..0
a
]
]
a
]
]
l1
E Q
l0
E Q
U
U
A
A
L
L
O
O
U
U
T
T
O
D
D
~
A T
A T
[2
A A
A B
..0
S E
M U
]
L
X 2 1
O U T 0
O
D
D
~
A T
A T
[5
A A
A B
..3
S E
M U
]
L
X 2 1
O U T 0 O [2 ..0 ]

Wrong Combinatorial PROCESS (Sick HW)
• The next PROCESS doesn’t cover all the input S permutations of the
combinational circuit (permutation S=‘’11’’ is missing, in order to hold the
output O last value, tree Latches will be inferred) .
©Hanan Ribo 10

Wrong Combinatorial PROCESS (Sick HW)
Synthesis result (we meant for MUX 3-1, the result is a Sick HW):
E q u a l1
S [1 ..0 ]
A [1 ..0 ]
O U T
| 2 ' h 1  -- | B [1 ..0 ] |     |     |     |     |     |
| ----------- | ---------- | --- | --- | --- | --- | --- |
O [2 ]$ la tc h
0
|     |       |     |           | 0   | P R E  |     |
| --- | ----- | --- | --------- | --- | ------ | --- |
|     |       |     | 1         |     | D Q    |     |
|     | E Q U | A L |           | 1   |        |     |
|     |       |     | O [2 ]~ 4 |     | E N AC |     |
L R
|     | E q u a l0 |     |     | O [2 ]~ 6 |     |     |
| --- | ---------- | --- | --- | --------- | --- | --- |
O [1 ]$ la tc h
|             | A [1 ..0 ] |       | 0   |     |        |            |
| ----------- | ---------- | ----- | --- | --- | ------ | ---------- |
|             |            | O U T |     | 0   | P R E  |            |
| 2 ' h 0  -- | B [1 ..0 ] |       | 1   |     | D Q    | O [2 ..0 ] |
|             |            |       |     | 1   | E N AC |            |
O [1 ]~ 2
L R
O [1 ]~ 3
|     | E Q U      | A L |     |     |                 |     |
| --- | ---------- | --- | --- | --- | --------------- | --- |
|     | E q u a l2 |     |     |     | O [0 ]$ la tc h |     |
O [2 ]~ 7
|     |     |     |     | 0   | P R E |     |
| --- | --- | --- | --- | --- | ----- | --- |
D Q
|     |     |     |     | 1   | E N AC |     |
| --- | --- | --- | --- | --- | ------ | --- |
A [1 ..0 ]
|             |            | O U T |     |           | L R |     |
| ----------- | ---------- | ----- | --- | --------- | --- | --- |
| 2 ' h 2  -- | B [1 ..0 ] |       |     | O [0 ]~ 1 |     |     |
|             | E Q U      | A L   |     |           |     |     |
I2 [2 ..0 ] 0
I1 [2 ..0 ]
1
O [0 ]~ 0
I0 [2 ..0 ]
©Hanan Ribo
11

Simulation vs Synthesis
Combinatorial PROCESS: The
PROCESS covers all the
permutations (full truth table
case3 code
description) of the input and
simulation
output SIGNALS of the
doesn't
combinational circuit.
describe
AND gate Synthesis result:
Don’t use SIGNALS for
Intermediate calculations
©Hanan Ribo 12

Wrong Combinatorial PROCESS (Sick HW)
the specifications provided for y are incomplete,
as can be observed in the truth-table. Therefore,
a latch will be implemented, which renders the
previous y value.
©Hanan Ribo 13

Wrong Combinatorial PROCESS (Sick HW)
Synthesis result (we meant for selector, the result is a Sick HW):
©Hanan Ribo 14