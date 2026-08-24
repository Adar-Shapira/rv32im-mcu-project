Finite State
Machines modeling
in VHDL
©Hanan Ribo
1

Introduction
• Finite state machines (FSM) constitute a special modeling technique for
sequential logic circuits, as digital controllers and etc.
• Single-phase FSM (Mealy/Moore) diagram:
This upper section contains the combinational
logic. From a VHDL perspective this part, being
combinational (concurrent coding).
This lower section contains the sequential logic
(flip-flops). Since all flip-flops are in this part of the
system, clock and reset must be connected to it.
From a VHDL perspective this part, being sequential,
will require a PROCESS. When reset is asserted,
pr_state will be set to the system’s initial state.
©Hanan Ribo 2

Mealy vs. Moore Machines
Moore
Mealy
©Hanan Ribo 3

Mealy Machines
If the output of the machine depends on the present state and the current
input, then it is called Mealy machine.
©Hanan Ribo 4

Moore Machines
If the output of the machine depends only on the current state, it is called
Moore machine.
©Hanan Ribo 5

Moore Machines
©Hanan Ribo 6

Autonomous Moore Machine
If the output of the machine depends only on the current state, it is called a
Moore Autonomous machine.
©Hanan Ribo 7

Direct Moore Machine
If the output is the current state, it is called a Moore direct machine.
©Hanan Ribo 8

FSM approach - rule of thumb
• Sequential circuit can in principle be modeled as a state machine, this is not
always advantageous. The reason is that the code might become longer,
more complex, and more error prone than in a conventional approach (this is
often the case with simple registered circuits, like counters.
• As a simple rule of thumb, the FSM approach is advisable in systems whose
tasks constitute a well-structured list so all states can be easily enumerated.
• A typical state machine implementation is used with a user-defined
enumerated data type.
©Hanan Ribo 9

FSM Design Styles
Design Style No.1 Design Style No.2
pr_state nx_state pr_state nx_state
In many applications, the signals are required to be
In case of a Mealy Machine only pr_state
synchronous, so the output should be updated only
is stored, the output might change when
when the proper clock edge occurs (the output
the input changes depending on which
must be stored as well).
state the machine is in regardless of clk
(asynchronous output).
©Hanan Ribo 10

FSM Design Style No.1 – Sequential Part
In this design style the design of the lower section is completely separated from
that of the upper section. All states of the machine are always explicitly
declared using an enumerated data type.
Design of the Lower (Sequential) Section
In this approach the lower section is basically
standard. The number of flip-flops inferred from
this code section is 𝒍𝒐𝒈 𝒏 FFs
𝟐
©Hanan Ribo 11

FSM Design Style No.1 – Combinational Part
This code does two things: it assigns the output value and establishes the next state.
| The design of the Upper Section |     | is Concurrent. |     |
| ------------------------------- | --- | -------------- | --- |
In order to cover all pr_state signal permutations (Latch infer
avoiding) in case of complicated and big FSMs, we can write
| default assignments to all outputs (before            |                         | the CASE      | line).     |
| ----------------------------------------------------- | ----------------------- | ------------- | ---------- |
| In order to drain unplanned states we can use (before |                         |               | END CASE)  |
|                                                       | WHEN OTHERS => nx_state | <= idle_state | ;          |
©Hanan Ribo 12

Mealy Machine – Design Style No.1 Example
©Hanan Ribo 13

Mealy Machine – simple Example
©Hanan Ribo 14

Mealy Machine – simple Example
| 𝑌 ≜ 𝑁𝑆 |        |                  | ̅                   |
| ------ | ------ | ---------------- | ------------------- |
|        | 𝑠𝑡𝑎𝑡𝑒𝐴 | = ′0′ 𝑌          | = 𝑦𝑑 + 𝑦(cid:3364)𝑑 |
|        |        |   (cid:4682)     |                     |
| 𝑦 ≜ 𝑃𝑆 | 𝑠𝑡𝑎𝑡𝑒𝐵 | =(cid:4593) 1′ 𝑥 | = 𝑦𝑏 + 𝑦(cid:3364)𝑎 |
asynchronous output
© Hanan Ribo
15

Mealy Machine – simple Example
̅
| 𝑌 ≜ 𝑁𝑆 | 𝑠𝑡𝑎𝑡𝑒𝐴 | = ′0′ | 𝑌 = 𝑦𝑑       | + 𝑦(cid:3364)𝑑 |
| ------ | ------ | ----- | ------------ | -------------- |
|        |        |       |   (cid:3421) |                |
=(cid:4593)
| 𝑦 ≜ 𝑃𝑆 | 𝑠𝑡𝑎𝑡𝑒𝐵 | 1′  | 𝑥 = 𝑦𝑏 | + 𝑦(cid:3364)𝑎 |
| ------ | ------ | --- | ------ | -------------- |
© Hanan Ribo
16

Moore Machine Example – modulo five
• A counter is an example of Moore machine, for the output depends only on
the stored (present) state.
• As a simple registered circuit and as a sequencer, it can be easily
implemented in conventional approach or using FSM approach (when the
number of states is large it becomes cumbersome to enumerate them all).
©Hanan Ribo 17

Moore Machine Example – modulo five
©Hanan Ribo 18

Moore Machine Example – modulo five
©Hanan Ribo 19

Reminder - FSM Design Styles
Design Style No.1 Design Style No.2
pr_state nx_state pr_state nx_state
In many applications, the signals are required to be
In case of a Mealy Machine only pr_state
synchronous, so the output should be updated only
is stored, the output might change when
when the proper clock edge occurs (the output
the input changes depending on which
must be stored as well).
state the machine is in regardless of clk
(asynchronous output).
©Hanan Ribo 22

FSM Design Style No.2 (Stored Output)
©Hanan Ribo 23

Mealy Machine – Design Style No.2 Example
©Hanan Ribo 24

Mealy Machine – Design Style No.2 Example
©Hanan Ribo 25

Stored Output Mealy Machine – simple Example
synchronous output
© Hanan Ribo 26

Stored Output Mealy Machine – simple Example
̅
| 𝑌 ≜ 𝑁𝑆 | 𝑠𝑡𝑎𝑡𝑒𝐴 | = ′0′       | 𝑌 = 𝑦𝑑       | + 𝑦(cid:3364)𝑑 |
| ------ | ------ | ----------- | ------------ | -------------- |
|        |        |             |   (cid:3421) |                |
| 𝑦 ≜ 𝑃𝑆 |        | =(cid:4593) |              |                |
|        | 𝑠𝑡𝑎𝑡𝑒𝐵 | 1′          | 𝑥 = 𝑦𝑏       | + 𝑦(cid:3364)𝑎 |
©Hanan Ribo
27