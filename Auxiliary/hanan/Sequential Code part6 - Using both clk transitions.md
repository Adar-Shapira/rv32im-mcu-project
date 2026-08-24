VHDL
Using both clk transitions

©Hanan Ribo

1

Synchronous building block

We can use only one from the next two clk’s conditions per PROCESS:
 Positive edge trigger:

 Negative edge trigger:

©Hanan Ribo

2

Question:
How to design the given system ?

Design requirement: counter on both clk transitions.

©Hanan Ribo

3

Wrong solution No.1

The ModelSim simulation works well but the code is not synthesizable because:
 It contains signal assignments at both transitions of the reference clk signal (the target

technology contains only single edge FF).

©Hanan Ribo

4

Wrong solution No.2

The ModelSim simulation works well but the code is not synthesizable because :

The attribute EVENT must be related to a test condition (transition detector).
 if (clk'event and clk='1') – is correct , if (clk'event ) then – is incorrect

©Hanan Ribo

5

Wrong solution No.3

The ModelSim simulation doesn’t work well because, if a signal appears in the sensitivity
list but doesn’t appear in any of the PROCESS’s assignments the compiler ignores it (in
this case only clk signal appears in the sensitivity list and it is unused so the compiler
ignores the whole process).

©Hanan Ribo

6

Correct Solution - code

©Hanan Ribo

7

Correct Solution - synthesis

©Hanan Ribo

8

