VHDL - Sequential
PROCESS Logic Synthesis

©Hanan Ribo

1

Introduction

• The next step after HDL code Simulation is HDL code Synthesis.
• Synthesis step contains the next:

✓ conversion of the high-level VHDL (or Verilog) language, which

describes the circuit at the Register Transfer Level (RTL), into a netlist at
the gate level.

✓ Optimization of the gate-level netlist for speed (minimize critical path)

and for area (minimize Logic function).

✓ Implementation of the optimized gate-level netlist based on

MUXs+LUTs, Latches, FFs (in case of FPGA as a target Hardware).
• The last step is a place and route (fitter), software will generate the

physical layout for a FPGA chip or will generate the masks for an ASIC
chip.

©Hanan Ribo

2

Synthesis coding approach
• Synthesis tools and Simulation tools translate PROCESS based HDL code in a

different way (concurrent code translated in the same way).

• Synthesis tools search for adjustment of VHDL code to one of the next three

template kinds (ieee-1076.6 standard):
Combinational Logic, Synchronous Logic, Latch based Logic.

• Our goal:

✓ writing of HDL code which will be translated in the same exact way by all

Synthesis and Simulation tools.

✓ Avoid of HDL code which synthesized with hardware errors in the required

design (avoid from Sick Hardware).

✓ Important rule: when you write HDL code, think Hardware!

©Hanan Ribo

3

Note: Unusual and Unsupported design approach
With a guarded BLOCK or with WHEN statements (using concurrent code)
even very simple sequential circuits can be constructed. This, however, is
Unusual and Unsupported design approach.
In conclusion: Synchronous design will be described using PROCESS only!

DFF implementation example

©Hanan Ribo

4

PROCESS Logic Synthesis
The way we write a PROCESS affects its synthesis and is associated with one of
the following two synthesis types:
• Combinatorial PROCESS (Combinational Logic Circuit):

✓ PROCESS that its sensitivity list contains all its internal input SIGNALS and the
PROCESS doesn’t contain IF-THEN statement which its condition on SIGNAL
event.

✓ This kind of PROCESS describes a combinational logic circuit.
✓  If we write a partial sensitivity list, the compiler completes it, differ from

simulation environment.

• Sequential PROCESS (Synchronous / Asynchronous Logic Circuit):

✓ PROCESS that its sensitivity list contains a input SIGNAL and the PROCESS

contains IF-THEN statement which its condition on SIGNAL event.

✓ This kind of PROCESS describes FFs based sequential logic circuit triggered by a

SIGNAL event.

©Hanan Ribo

5

Sequential PROCESS (A/Synchronous Circuit)
In order the compiler will synthesize the PROCESS as a Synchronous Logic Circuit
we must obey the next two rules (Synchronous Logic template):
Rule 1: Make sure that only the trigger input SIGNAL (mostly named clk) and its
Asynchronous SIGNAL (mostly named rst) in the required Synchronous circuit,
appear in the PROCESS sensitivity list.
Rule 2: Use a main IF-THEN statement (from the only next two patterns) which its
condition on SIGNAL event is a one of two forms (at the beginning, without using
of any ELSIF or at the end, at the last ELSIF), positive edge trigger  or negative edge
trigger.

Asynchronous part

Synchronous part

Combinational Logic

Combinational Logic

Synchronous part

©Hanan Ribo

6

Sequential PROCESS (Synchronous Circuit)

• Positive edge trigger condition:

• Negative edge trigger condition:

©Hanan Ribo

7

Three FFs (register) templates

Template No.1 (pure synchronous) – FF inferred version 1:

Synchronous part

Synchronous Combinational Logic

FF inferred version 1: A SIGNAL generates a flip-flop whenever an assignment
is made at the transition of another signal, that is, when a synchronous
assignment occurs.

8

©Hanan Ribo

Three FFs (register) templates

Template No.1 (including asynchronous logic) – FF inferred version 1:

Asynchronous Combinational Logic

Asynchronous part (setting of all circuit
outputs which are described by the PROCESS)

Synchronous Combinational Logic

Synchronous part

Note: if the asynchronous part was as the
next code, PRE input would been used.

Note: In case of a vector, you
must clear (or set) all vector
elements, otherwise the
result is mal synthesis.

©Hanan Ribo

9

Three FFs (register) templates

Template No.1 (including asynchronous logic) – FF inferred version 1:

Asynchronous Combinational Logic

Synchronous Combinational Logic

Synchronous part

©Hanan Ribo

10

Three FFs (register) templates

Template No.1 (including ENA logic) – FF inferred version 1:

Synchronous part

ENA logic, in case of IF-THEN nested
without ELSE/ELSIF

©Hanan Ribo

11

Three FFs (register) templates

Template No.1 (D input logic) – FF inferred version 1:

©Hanan Ribo

12

FF inferred version 1- examples

Two FFs inferred

Only one FFs inferred

©Hanan Ribo

13

FF inferred version 2
A VARIABLE, will not necessarily generate flip-flops if its value never leaves
the PROCESS (or FUNCTION, or PROCEDURE). However, if a value is assigned
to a variable at the transition of another signal, and such value is eventually
passed to a signal (which leaves the process), then flip-flops will be inferred.

©Hanan Ribo

14

FF inferred version 3
A VARIABLE also generates a register when it is used before a value has been
assigned to it. In this case a VARIABLE is used wrongly, instead of use
VARIABLE for intermediate calculations it is used as a memory element.
Remember: don’t read from VARIABLE before a value has been assigned to it.

©Hanan Ribo

15

Three FFs (register) templates

Template No.2:

Combinational Logic

Combinational Logic

©Hanan Ribo

16

Three FFs (register) templates

Template No.3:

©Hanan Ribo

17

DFF with q and qbar - example

Q: How do we implement the next DFF
A1: remember that the base FF is based on the form:

©Hanan Ribo

18

DFF with q and qbar - example

Q: How do we implement the next DFF
A2: remember that the base FF is based on the form:

©Hanan Ribo

19

