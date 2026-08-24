VHDL - Concurrent Code
Dataflow modeling
©Hanan Ribo
1

Introduction
• VHDL code can be concurrent (combinational logic) or sequential
(sequential logic).
• Combinational logic - definition:
The output is a pure function of the present input only (implemented by
Boolean circuits, using conventional logic gates only – no memory, no
feedback).
• Intuitively, the circuit information flows in parallel.
©Hanan Ribo 2

Introduction
• Sequential logic - definition:
The output does depend on present inputs and previous inputs
(implemented using storage, flip-flops elements, which are connected to
the combinational logic block through a feedback loop).
• Intuitively, the circuit information flows in serial triggered by clk signal.
©Hanan Ribo 3

Introduction
• Note: not any circuit that possesses storage elements is sequential.
• Example: RAM memory.
The storage elements appear in a forward path rather than in a feedback
loop. The memory-read operation depends only on the present address
vector input (with nothing to do with previous memory accesses).
©Hanan Ribo 4

Introduction
• There are four types of ARCHITECTURE Modeling styles:
 Dataflow modeling = Concurrent Code
 Structural modeling = Concurrent Code
 Behavioral modeling = Sequential Code
 Mixed modeling = Concurrent Code
©Hanan Ribo 5

Concurrent code - Dataflow
• Concurrent code dataflow approach is based on four kind of statements that
can only be used outside PROCESSES, FUNCTIONS, or PROCEDURES (Three
sequential code mechanism).
 Signal assignment using Operators (with no feedback)
 The WHEN statement (two kinds - WHEN/ELSE or WITH/SELECT/WHEN)
 The GENERATE statement
 The BLOCK statement
• The order of concurrent statements doesn’t matter, due to concurrent
execution.
• Notepad++ Download (highly recommended)
©Hanan Ribo 6

Signal assignment-using Operators
• Using Operators is the most basic way of creating concurrent code. Operators can
be used to implement any combinational circuit.
• Syntax:
• Note 1: Signal assignment with feedback causes buffer inferred, in order to save
the last signal value.
©Hanan Ribo 7

Signal assignment-using Operators
• Note 2: concurrent code must not use multiple driven assignments. Its
implementation shortcuts Vcc to gnd.
• Example 1:
©Hanan Ribo 8

Signal assignment-using Operators (Mux 4-1)
Example 2:
©Hanan Ribo 9

Conditional signal assignment
• Syntax:
Priority
Mux based
on 2-1 MUX
cascade
• Note: If ELSE is not required, this method should not be used.
• Example 1:
©Hanan Ribo 10

Conditional signal assignment (Mux 4-1)
• Example 2:
©Hanan Ribo 11

| unaffected | value using in WHEN | statement |
| ---------- | ------------------- | --------- |
©Hanan Ribo 12

Conditional signal assignment (tri-state)
• Example 3:
©Hanan Ribo 13

D latch using WHEN statement
©Hanan Ribo 14

Selected signal assignment (mux as a True Table)
• Syntax:
• Example 1:
©Hanan Ribo 15

Selected signal assignment (mux as a True Table)
Example 2:
©Hanan Ribo 16

| unaffected | value using in With-Select | statement |
| ---------- | -------------------------- | --------- |
©Hanan Ribo 17

Generate
• GENERATE is another concurrent statement. It allows a section of concurrent
code to be repeated a number of times, thus creating several instances of the
same assignments.
• GENERATE statement must be labeled.
• Formula 1 - FOR / GENERATE:
Notes:
 the identifier range must be static.
 Be aware of avoiding from overlap assignments (multiple driven), causes
compilation error.
©Hanan Ribo 18

FOR / GENERATE – multiple driven
• Example 1:
• Example 2:
©Hanan Ribo 19

Generate
• Formula 2 - IF / GENERATE :
• Formula 3 - IF / GENERATE and FOR / GENERATE can be combined:
©Hanan Ribo 20

GENERATE - Vector Shifter Example
-- Mux inferred (pure logic of Memory structure)
©Hanan Ribo 21

BLOCK
• There are two kinds of BLOCK statements:
Simple BLOCK and Guarded BLOCK.
• It allows a set of concurrent statements to be clustered into a BLOCK, with
the purpose of turning the overall code more readable and more
manageable (helpful when dealing with long codes).
• Only concurrent statements can be written within a BLOCK.
• A BLOCK statement must be labeled.
• Declarations inside a BLOCK are seen by the BLOCK only.
• A BLOCK statement is local to the ARCHITECTURE where it’s located.
• A BLOCK (simple or guarded) can be nested inside another BLOCK.
©Hanan Ribo 22

Simple BLOCK
• Syntax
:
©Hanan Ribo 23

Guarded BLOCK
• A guarded BLOCK is a special kind of BLOCK, which includes an additional
expression, called guard expression. A guarded statements in a guarded
BLOCK is executed only when the guard expression is TRUE (unguarded
statements will be executed anyway).
• Syntax:
©Hanan Ribo 24

Guarded BLOCK – D Latch example
©Hanan Ribo 25

| Guarded BLOCK – | DFF | example |
| --------------- | --- | ------- |
©Hanan Ribo
26