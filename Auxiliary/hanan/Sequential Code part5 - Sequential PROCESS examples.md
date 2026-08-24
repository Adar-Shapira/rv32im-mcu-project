VHDL - Sequential
PROCESS examples

©Hanan Ribo

1

4-stage shift register

We want to implement a Four Stages Shift-Register in different ways:

©Hanan Ribo

2

4-stage shift register (Behavioral approach)

Asynchronous part

Synchronous part

©Hanan Ribo

3

4-stage shift register (Structural approach)

©Hanan Ribo

4

4-stage shift register (solution 3 - unrecommended)

The way of using VARIABLES as memory
elements, different from their original purpose

©Hanan Ribo

5

Frequency divider (version 1)

Out1
combinational
logic

Out2
combinational
logic

Count1
combinational
logic

𝑓𝑐𝑙𝑘/8
𝑓𝑐𝑙𝑘/6

Simulation using ideal FFs

©Hanan Ribo

6

Frequency divider (version 1)

Out2
combinational
logic

Count1
combinational
logic

Out1
combinational
logic

©Hanan Ribo

7

Frequency divider (version 2)

𝑓𝑐𝑙𝑘/4

𝑓𝑐𝑙𝑘/8

©Hanan Ribo

8

Frequency divider (version 2)

𝑓𝑐𝑙𝑘/8
𝑓𝑐𝑙𝑘/4

©Hanan Ribo

9

