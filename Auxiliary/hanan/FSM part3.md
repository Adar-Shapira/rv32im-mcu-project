FSM based Applicable
digital design

©Hanan Ribo

1

FSM based Applicable digital design
Applicable digital design are mostly based on FSM forms of Moore or Mealy
with stored output due to the next reasons:
Reason 1: Robustness from the influence of the parasitic logic feedback
surrounding the upper section (FSM combinational logic part) .

©Hanan Ribo

2

FSM based Applicable digital design
Applicable digital design are mostly based on FSM forms of Moore or Mealy
with stored output due to the next reasons:
Reason 2: Robustness from moving spikes / static 0-, 1-hazards / dynamic
hazards from Input to Output that happened between clk rising edges
(excluding spikes at the Output that created due to clk rising edge).

©Hanan Ribo

3

FSM based Applicable digital design
Applicable digital design are mostly based on FSM forms of Moore or Mealy
with stored output due to the next reasons:
Reason 3: Preventing from increasing the critical path which decreases the
system 𝑓𝑚𝑎𝑥

Mealy1

Mealy2

Mealy3

Critical path

©Hanan Ribo

4

FSM based Applicable digital design
Applicable digital design are mostly based on FSM forms of Moore or Mealy
with stored output due to the next reasons:
Reason 3: Preventing from increasing the critical path which decreases the
system 𝑓𝑚𝑎𝑥

Moore1

Moore2

Moore3

Critical path

©Hanan Ribo

5

FSM based Applicable digital design
Applicable digital design are mostly based on FSM forms of Moore or Mealy
with stored output due to the next reasons:
Reason 3: Preventing from increasing the critical path which decreases the
system 𝑓𝑚𝑎𝑥

Mealy1_StoredOutput

Mealy2_StoredOutput

Mealy3_StoredOutput

Critical path #1

Critical path #2

©Hanan Ribo

6

Encoding Style:
Binary, OneHot, TwoHot

©Hanan Ribo

7

Tradeoff:

#DFFs

vs.

FANin and FANout size

Explanation:

Depending the States

Encoding Allocation (Binary

Encoding or Direct Encoding)

and

The target HW (LUT based

with low FANin but DFFs

abundantly as in FPGA or the

opposite in ASIC).

Phase 4 – Implementation

ROM
or
Pure
Combinational
Logic

Present
State

DFFs
Array

Next
State

©Hanan Ribo

Encoding Style: Binary, OneHot, TwoHot

State encoding example of an 8-state FSM

©Hanan Ribo

9

Encoding Style: Binary, OneHot, TwoHot
• In order to encode the states of a FSM, we can select one among several available

styles (Binary, OneHot, TwoHot. Etc.).

• The default is binary:

 Advantage - requires the least number of flip-flops (n flip-flops (n bits), can encode up to 2n

states).

 Disadvantage - requires more logic and is slower than the others.
 Recommended in applications where Logic are abundant with high Fan-In, like in ASICs.

• OneHot encoding (extreme to binary):

One bit active per state.
 Advantage - requires the least amount of extra logic and is the fastest.
 Disadvantage - requires the largest number of flip-flops (uses one flip-flop per state - with n flip-

flops (n bits), only n states can be encoded).

 Recommended in applications where flip-flops are abundant, like in FPGAs.
• TwoHot encoding (inbetween binary and OneHot styles):

Two bits active per state. uses Two flip-flops per state - with n flip-flops (n bits),
only n(n -1)/2 states can be encoded).

©Hanan Ribo

10

States Encoding Allocation
• Approch1: Default allocation determined by the synthesis tool IDE (Quartus

of ALTEAR / SDK of XILINX) depends the target HW.

• Approch2: Using specific GUI / terminal commands in the synthesis tool IDE.
• Approch3: Using specific attributes in our HDL code which are acquainted by

the synthesis tool.

• Approch4: Using direct allocation in our HDL code (Generic approach,

independent on specific synthesis tool).

©Hanan Ribo

11

Direct allocation - independent on synthesis tool

• OneHot direct encoding:

• TwoHot direct encoding:

©Hanan Ribo

12

