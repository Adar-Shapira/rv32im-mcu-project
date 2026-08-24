VHDL
System Design Principles

©Hanan Ribo

1

High Level System Description
• The most common mistake is to start HDL coding before describing the

required digital system in high level of RTL form.

• In RTL system description it becomes clear what are the system’s

combinational and synchronous subunits.

• Any digital logic system can be disassembled to logic blocks chained to FFs

(registers) .

©Hanan Ribo

2

System separation to combinational and
synchronous subunits
There are four building blocks of combinational and synchronous subunits:
1. Pure logic
2. Pure synchronous (single or multiple chained)
3. Logic through Synchronous
4. Logic through Synchronous feedback

©Hanan Ribo

3

Example of Digital System Disassembly

Sequential code

Sequential code

Concurrent code

Sequential code

Concurrent code

Sequential code

Sequential code

©Hanan Ribo

Sequential code

4

Mixed Process

• Mixed PROCESS is a PROCESS which combines combinatorial and

synchronous elements inside it (even Latch elements).

• Don’t write Mixed PROCESS, is non synthesizable (ieee-1076.6 standard).
• When you write a PROCESS, ask yourself if it describes combinatorial logic

or synchronous circuit. If you're not sure, you are writing a Mixed
PROCESS.

• Synchronous derivator example – circuit implementation:

Note: without
dismantle it into two
parts, you write a Mixed
PROCESS

Concurrent code

Sequential code

©Hanan Ribo

5

Mixed Process – Synchronous derivator

The PROCESS combines
combinatorial and synchronous
elements inside it

©Hanan Ribo

6

Synchronous derivator – correct approach

Sequential code

Concurrent code

©Hanan Ribo

7

Question:
How to implement the given circuit ?

Option No.1

Option No.2

Correct but
contains
redundancy

Correct: Pure
synchronous
(multiple
chained)

©Hanan Ribo

8

Pure synchronous (multiple chained) PROCESS

Sequential code

©Hanan Ribo

9

