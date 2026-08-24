361-1-4201/381-1-0107
Computer Architecture
Intro to Microarchitecture: Single-Cycle
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015, 1/26/2015
With Dr. Danny Seidner modifications

Agenda for Today & Next Few Lectures
 Start Microarchitecture
Lectures 4-5
 Single-cycle Microarchitectures
 Multi-cycle Microarchitectures
Lecture 6
 Microprogrammed Microarchitectures
 Pipelining
Lect 7
 Issues in Pipelining: Control & Data Dependence Handling, State Maintenance and
Recovery, …
2

Recap of the Last Lectures
 Computer Architecture Today and Basics – Lec #1
 Fundamental Concepts – Lec #1
 Computer Arch = ISA (the definition) + uArch (the implementation)
 ISA basics and tradeoffs – Lec #2
 Instruction length
 Uniform vs. non-uniform decode
 Number of registers
 Addressing modes
 Aligned vs. unaligned access
 RISC vs. CISC properties
 MIPS ISA – Lec #3
 MIPS ISA Overview
 Datapath & Microarchitecture – Lec #4
3

הבשחמל רמוח
 As you learn the MIPS ISA, think about what tradeoffs the designers have made
 in terms of the ISA properties we talked about
 And, think about the pros and cons of design choices
 In comparison to ARM, Alpha
 In comparison to x86, VAX
 And, think about the potential mistakes
 Branch delay slot? (stall in the pipeline – ונדמל םרט)
 Load delay slot? (בוכיע אלל עצבתת האבה הארוההש חיטבהל)
 No FP, no multiply, MIPS (initial)
4

Food for Thought for You הבשחמל רמוח דוע
 How would you design a new ISA?
 Where would you place it?
 What design choices would you make in terms of ISA properties?
 What would be the first question you ask in this process?
 “What is my design point?”
 The 1st question to ask what is the Design Point / Use Case
ןימזמה תא לואשל וצרתש הנושארה הלאשה המ?
Look Forward & Up
5

Review: Other Example ISA-level Tradeoffs
 Condition codes vs. not – ךשמהב דמלי
 VLIW vs. single instruction – ךשמהב דמלי
 SIMD (single instruction multiple data) vs. SISD – ןילפ לש הימונוסקטה
 Precise vs. imprecise exceptions – ךשמהב דמלי
MIPS MIPS X86
 Virtual memory vs. not
 Unaligned access vs. not
 Hardware interlocks vs. software-guaranteed interlocking
 Software vs. hardware managed page fault handling
 Cache coherence (hardware vs. software)
 … Think Programmer vs. (Micro)architect
?הסמעמה תא םקמל ןכיה
6

Review: A Note on RISC vs. CISC
 RISC
– Simple instructions
– Fixed length
– Uniform decode
– Few addressing modes
 CISC
– Complex instructions
– Variable length
– Non-uniform decode
– Many addressing modes
7

Now That We Have an ISA
 How do we implement it?
 i.e., how do we design a system that obeys the hardware/software interface?
 Aside: “System” can be solely hardware or a combination of hardware and software
 Remember “Translation of ISAs”
 A virtual ISA can be converted by “software” into an implementation ISA
 We will assume “hardware” for most lectures
8

Implementing the ISA:
Microarchitecture Basics
9

How Does a Machine Process Instructions?
 What does processing an instruction mean?
 Remember the von Neumann model
AS = Architectural (programmer visible) state before an instruction is processed
Process instruction
AS’ = Architectural (programmer visible) state after an instruction is processed
 Processing an instruction: Transforming AS to AS’ according to the ISA specification of the
instruction
10

Remember: Programmer Visible (Architectural) State
?AS תרדגה
M[0]
M[1]
M[2]
M[3]
Registers
M[4]
- given special names in the ISA
(as opposed to addresses)
- general vs. special purpose
M[N-1]
Program Counter
Memory
memory address
array of storage locations
of the current instruction
indexed by an address
Instructions (and programs) specify how to transform
the values of programmer visible state
11

The “Process instruction” Step
 ISA specifies abstractly what AS’ should be, given an instruction and AS
 It defines an abstract finite state machine where
Finite State Machine
 State = programmer-visible state
 Next-state logic = instruction execution specification
 From ISA point of view, there are no “intermediate states” between AS and AS’ during instruction execution
 One state transition per instruction
 Microarchitecture implements how AS is transformed to AS’
 There are many choices in implementation
 We can have programmer-invisible state to optimize the speed of instruction execution: multiple state
transitions per instruction
 Choice 1: AS  AS’ (transform AS to AS’ in a single clock cycle)
 Choice 2: AS  AS+MS1  AS+MS2  AS+MS3  AS’ (take multiple clock cycles to
transform AS to AS’)
AS = Architecture State
MS=Mictoarchitecture State 12

A Very Basic Instruction Processing Engine
 Each instruction takes a single clock cycle to execute
 Only combinational logic is used to implement instruction execution
 No intermediate, programmer-invisible state updates
AS = Architectural (programmer visible) state
at the beginning of a clock cycle
Process instruction in one clock cycle
AS’ = Architectural (programmer visible) state
at the end of a clock cycle
13

A Very Basic Instruction Processing Engine
 Single-cycle machine
AS’
AS
Sequential
Combinational
Logic
Logic
(State)
 What is the clock cycle time determined by? ?תונעל הצור והשימ
 What is the critical path of the combinational logic determined by?
14

Single-cycle vs. Multi-cycle Machines
 Single-cycle machines
 Each instruction takes a single clock cycle
 All state updates made at the end of an instruction’s execution
 Big disadvantage: The slowest instruction determines cycle time  long clock cycle time
 Multi-cycle machines
 Instruction processing broken into multiple cycles (or stages)
 State updates can be made during an instruction’s execution
 Architectural state(*) updates made only at the end of an instruction’s execution
Slowest
 Advantage over single-cycle: The slowest “stage” determines cycle time
combinational logic
 Both single-cycle and multi-cycle machines literally follow the von Neumann model at the microarchitecture
level
םדוקה ףקשב רדגוהש יפכ "בצמ" )*(
16

Instruction Processing “Cycle”
 Instructions are processed under the direction of a “control unit” step by step.
 Instruction cycle: Sequence of steps to process an instruction
 Fundamentally, there are six phases (steps):
 Fetch
 IF - Fetch
 Decode
 ID - Decode
 Evaluate Address
 EX - Execute/Evaluate Address
 Fetch Operands
 MEM - Fetch Operands
 Execute
 WB - Store Result
 Store Result
We will later change to 5 stages
 Not all instructions
require all six stages
!ןועש לש רוזחמ ןיבל הארוה לש רוזחמ ןיב ןיחבהל שי
17

Instruction Processing “Cycle” vs. Machine Clock Cycle
 Single-cycle machine:
 All six phases of the instruction processing cycle take a single machine clock cycle to
complete
 Multi-cycle machine:
 All six phases of the instruction processing cycle can take multiple machine clock cycles to
complete
 In fact, each phase can take multiple clock cycles to complete
…ןועש ירוזחמ 5 חקי FETCH עוציבש ןכתי לשמל
...תלכסתמ היווח איה single cycle גוסמ בשחמב ןורכזל דבעמה ןיב היצקארטניאה 
18

Instruction Processing Viewed Another Way
 Instructions transform Data (AS) to Data’ (AS’)
 This transformation is done by functional units
Data vs. Control
 Units that “operate” on data
separation
 These units need to be told what to do to the data
 An instruction processing engine consists of two components
 Datapath: Consists of hardware elements that deal with and transform data signals
 functional units that operate on data
 hardware structures (e.g. wires and muxes) that enable the flow of data into the functional units and
registers
 storage units that store data (e.g., registers)
 Control logic: Consists of hardware elements that determine control signals, i.e., signals that specify what the
datapath elements should do to the data
19

Single-cycle vs. Multi-cycle: Control & Data
 Single-cycle machine:
 Control signals are generated in the same clock cycle as the one during which data signals are
operated on
 Everything related to an instruction happens in one clock cycle (serialized processing)
 Multi-cycle machine:
 Control signals needed in the next cycle can be generated in the current cycle
 Latency of control processing can be overlapped with latency of datapath operation (more
parallelism)
 We will see the difference clearly in microprogrammed multi-cycle microarchitectures
20

Many Ways of Datapath and Control Design
 There are many ways of designing the data path and control logic
 Single-cycle, multi-cycle, pipelined datapath and control
 Single-bus vs. multi-bus datapaths
 Hardwired/combinational vs. microcoded/microprogrammed control
 Control signals generated by combinational logic versus
 Control signals stored in a memory structure
 Control signals and structure depend on the datapath design
21

Flash-Forward: Performance Analysis
 Execution time of an instruction
CPI=1/IPC
 {CPI} x {clock cycle time}
 Execution time of a program
We have
 Sum over all instructions [{CPI} x {clock cycle time}]
one degree of freedom
 {# of instructions} x {Average CPI} x {clock cycle time}
to optimize
 Single cycle microarchitecture performance
 CPI = 1
 Clock cycle time = long
Now, we have
 Multi-cycle microarchitecture performance two degrees of freedom
to optimize independently
 CPI = different for each instruction
 Average CPI  hopefully small
:םילדג 2 םע "קחשל" ןתינ
 Clock cycle time = short
clock cycle time -ו CPI 22

A Single-Cycle Microarchitecture
A Closer Look
23

Remember…
 Single-cycle machine
AS’
AS
Sequential
Combinational
Logic
Logic
(State)
24

Let’s Start with the State Elements
 Data and control inputs
ALU control
|     |     |     | 5   |     |     |     |     | 3   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Read
register 1
Read
| Instruction |     |          | 5    |     | data 1 |     |     |     |
| ----------- | --- | -------- | ---- | --- | ------ | --- | --- | --- |
|             |     | Register | Read |     |        |     |     |     |
address
|     |     | numbers | register 2 |     |     |     |     | Zero |
| --- | --- | ------- | ---------- | --- | --- | --- | --- | ---- |
אוהש המ לכ םע ליחתנ
|     |     |     |     | Registers |     | Data |     | ALU ALU |
| --- | --- | --- | --- | --------- | --- | ---- | --- | ------- |
PC 5
|                                      |     |     | W         | r i t e |     |     |     | result |
| ------------------------------------ | --- | --- | --------- | ------- | --- | --- | --- | ------ |
| programmIensr tvruiscitbiolne state  |     |     | A dd reSg | u ms    |     |     |     |        |
i ter
Read
| Instruction |     |     |     |     | data 2 |     |     |     |
| ----------- | --- | --- | --- | --- | ------ | --- | --- | --- |
Write
Data
| memory |     |     | data |     |     |     |     |     |
| ------ | --- | --- | ---- | --- | --- | --- | --- | --- |
RegWrite
| a. Instruction memory | b. Program counter |     | c. Adder |              |     |     |     |        |
| --------------------- | ------------------ | --- | -------- | ------------ | --- | --- | --- | ------ |
|                       |                    |     |          | a. Registers |     |     |     | b. ALU |
MemWrite
Instruction
address
|     |     |     |     | Address | Read |     |     |     |
| --- | --- | --- | --- | ------- | ---- | --- | --- | --- |
|     |     |     |     | PC      | data |     | 16  | 32  |
Sign
Instruction Add Sum
extend
Data
Write
Instruction
|     |     |     |     | data | memory |     |     |     |
| --- | --- | --- | --- | ---- | ------ | --- | --- | --- |
memory
MemRead
|     | a. Instruction memory |     | b. Program counter |     |     | c. Adder |     |     |
| --- | --------------------- | --- | ------------------ | --- | --- | -------- | --- | --- |
b. Sig2n5-extension unit
a. Data memory unit
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

For Now, We Will Assume
 “Magic” memory and register file
 Combinational read
 output of the read data port is a combinational function of the register file contents and the
corresponding read select port
 Synchronous write
 the selected register is updated on the positive edge clock transition when write enable is
asserted
 Cannot affect read output in between clock edges
 Single-cycle, synchronous memory – תוטשפה םשל החנה יהוז
 Contrast this with memory that tells when the data is ready
 i.e., Ready bit: indicating the read or write is done
26

FIGURE 4.3 Combinational logic, state elements, and the clock are closely related. In a synchronous digital
system, the clock determines when elements with state will write values into internal storage. Any inputs to a
state element must reach a stable value (that is, have reached a value from which they will not change until
after the clock edge) before the active clock edge causes the state to be updated. All state elements in this
chapter, including memory, are assumed to be positive edge-triggered; that is, they change on the rising clock
edge.
Copyright © 2014 Elsevier Inc. All rights reserved.

Instruction Processing
 5 generic steps (P&H book) –
םיפקש 10 ינפל בתכנש המ תמועל לק יונישו גוזימ השענ ןאכ ךא םיבלש 6 לע ונרביד םנמא
 Instruction fetch (IF)
 Instruction decode and register operand fetch (ID/RF = Register Fetch)
 Execute/Evaluate memory address (EX/AG = Address Generate)
 Memory operand fetch (MEM)
 Store/writeback result (WB) WB
IF
Register File
Data
Register #
PC Address Instruction Registers ALU Address
ID/RF
Register #
Instruction EX/AG
memory Data
Register # memory
MEM
Data
28
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

What Is To Come: The Full MIPS Datapath
|     |     |     |                    |       |     |                     |     |     |     |     |     | PCSrc =Jump |     |     |
| --- | --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | --- | --- | ----------- | --- | --- |
|     |     |     | Instruction [25–0] | Shift |     | Jump address [31–0] |     |     |     |     |     | 1           |     |     |
left 2
|     |     |     |     | 26  | 28  |     |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |     |     | M   | M   |     |
PC+4 [31–28]
|     |     |     |     |     |     |     |     |     |     |         |     | u   | u   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |         |     | x   | x   |     |
|     |     |     |     |     |     |     |     |     |     | Add ALU |     | 1   | 0   |     |
result
|     |     | Add |     |     |     | RegDst |     |     | Shift |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | --- | ----- | --- | --- | --- | --- | --- |
PCSrc =Br Taken
|     |     |     |     |     |     | Jump |     |     | left 2 |     |     |     | 2   |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | --- | ------ | --- | --- | --- | --- | --- |
4
Branch
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
RegWrite
Instruction [25–21]
Read
| PC  | R e a d    |     |                     |     |     | register 1 |     |        |     |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | --- | ---------- | --- | ------ | --- | --- | --- | --- | --- | --- |
|     | ad d r ess |     |                     |     |     |            |     | Read   |     |     |     |     |     |     |
|     |            |     | Instruction [20–16] |     |     | Read       |     | data 1 |     |     |     |     |     |     |
bcZoenrdo
|     |          | Instruction |                     |     |     | register 2   |           |           |     |           |         |      |      |     |
| --- | -------- | ----------- | ------------------- | --- | --- | ------------ | --------- | --------- | --- | --------- | ------- | ---- | ---- | --- |
|     |          |             |                     |     | 0   |              | Registers | R e a d   |     | ALU A L U |         |      |      |     |
|     |          | [31–0]      |                     |     |     | Write        |           |           | 0   |           |         |      | Read |     |
|     |          |             |                     |     | M   |              |           | da t a  2 |     | re su l t | Address |      | data | 1   |
|     | In st ru | c ti o n    |                     |     | u   | r eg i s ter |           |           | M   |           |         |      |      | M   |
|     | m e m    | o r y       |                     |     | x   |              |           |           | u   |           |         |      |      |     |
|     |          |             | Instruction [15–11] |     |     | W ri t e     |           |           | x   |           |         |      |      | u   |
|     |          |             |                     |     | 1   | data         |           |           |     |           |         | D at | a    | x   |
|     |          |             |                     |     |     |              |           |           | 1   |           |         | m em | o ry | 0   |
Write
data
|     |     |     | Instruction [15–0] |     |     |     | 16  | 32  |     |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign
|     |     |     |     |     |     |     |     | extend |     | ALU operation |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------------- | --- | --- | --- | --- |
ALU
control
Instruction [5–0]
29
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
JAL, JR, JALR omitted

Single-Cycle Datapath for
Arithmetic and Logical Instructions
30

R-Type ALU Instructions
 Assembly (e.g., register-register signed addition)
ADD rd rs rt
reg reg reg
 Machine encoding
0 rs rt rd 0 ADD R-type
31 0
6-bit 5-bit 5-bit 5-bit 5-bit 6-bit
 Semantics
תבותכב ןורכזב אצמנש המ םא
if MEM[PC] == ADD rd rs rt
...זא ןימי ףגאבש ןכותל הווש PC
GPR[rd]  GPR[rs] + GPR[rt]
PC  PC + 4
31

ALU Datapath שומימה ןלהל
|     |     |     | rs  | rt rd |     |     |     |
| --- | --- | --- | --- | ----- | --- | --- | --- |
Add
4
ALU operation
|     |     | Read |     |     | 3   |     |     |
| --- | --- | ---- | --- | --- | --- | --- | --- |
25:21
| R e a d |     | register 1 |     |     |     |     |     |
| ------- | --- | ---------- | --- | --- | --- | --- | --- |
PC Read
ad d r ess
data 1
20:16 Read
|     |     | register 2 |     |     | Zero |     |     |
| --- | --- | ---------- | --- | --- | ---- | --- | --- |
Instruction
|     | Instruction | Registers |     |     | ALU |     |     |
| --- | ----------- | --------- | --- | --- | --- | --- | --- |
ALU
|             | 15:11 | Write    |        |     | result |     |     |
| ----------- | ----- | -------- | ------ | --- | ------ | --- | --- |
| Instruction |       | register | Read   |     |        |     |     |
| memory      |       |          | data 2 |     |        |     |     |
Write
data
RegWrite
1
|     |     |     | IF  | ID  | EX  | MEM | WB  |
| --- | --- | --- | --- | --- | --- | --- | --- |
if MEM[PC] == ADD rd rs rt
Combinational
GPR[rd]  GPR[rs] + GPR[rt]
state update logic
**Based on origiPnal Cfigu re fro mP [PC&H  C+O& D4, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
32
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

R-Type ALU שומימה ןלהל
|     |     |     |     | rs  | rt rd |     |     |     |
| --- | --- | --- | --- | --- | ----- | --- | --- | --- |
Add
4
ALU operation
|     |     |     | Read |     |     | 3   |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- |
25:21
| R e a d |     |     | register 1 |     |     |     |     |     |
| ------- | --- | --- | ---------- | --- | --- | --- | --- | --- |
PC Read
ad d r ess
data 1
20:16 Read
|     |             |             | register 2 |     |     | Zero |     |     |
| --- | ----------- | ----------- | ---------- | --- | --- | ---- | --- | --- |
|     |             | Instruction |            | ID  |     | EX   |     |     |
|     | Instruction |             | Registers  |     |     | ALU  |     |     |
ALU
|             |     | 15:11 | Write    |        |     | result |     |     |
| ----------- | --- | ----- | -------- | ------ | --- | ------ | --- | --- |
| Instruction |     |       | register | Read   |     |        |     |     |
| memory      |     |       |          | data 2 |     |        |     |     |
Write
data
WB
RegWrite
1
IF
|     |     |     |     | IF  | ID  | EX  | MEM | WB  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
GPR[rd]  GPR[rs] + GPR[rt]
Combinational
PC  PC + 4
state update logic
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
33
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

The General-Purpose Register file (GPR file). This unit is required
for the decode phase (and for the Write Back phase)
It includes the
32 registers the
programmer can
GPR file
access ($0 - $31) Read
5
register1
Read 32
data1
Read
The registers
5
indices
register2
Read data
Write
Read
5 32
register
data2
Write
32
Write data Data
CK
Let’s see how it is used:

The General-Purpose Register file (GPR).
There are 3 ports in this box we then gets the contents of $7 at the
Read data1 output
If we want to read from $7 via port 1
we mark it as: GPR[7]
we set Read register1 to 7 = 00111 It could be 103 for example
GPR file
Read
5
00111 = 7 register1
Read
Read 32 port 1
GPR[7] = 103
data1
Read
5
register2
Read
Write
5 Read 32 port 2
register
data2
Write
32 Write
Data
port
CK

The General-Purpose Register file (GPR).
add  $12, $7, $2
So if we have the instruction:
Rs Rt
we connect the Rs field Read reg1
and get GPR[Rs] at the Read data1 output
In our case we assumed GPR[7]=103
GPR file
Read
5
|     | 00111 = 7 = | Rs  |  register1 |     |     |     |     |
| --- | ----------- | --- | ---------- | --- | --- | --- | --- |
 Read
|     |     |     |     | Read | 32  |     | port 1 |
| --- | --- | --- | --- | ---- | --- | --- | ------ |
GPR[Rs]
  data1
Read
|     | 00010 = 2 = | Rt 5 |     |     | = GPR[7] | = 103 |     |
| --- | ----------- | ---- | --- | --- | -------- | ----- | --- |
 register2
 Read
Write
| In our case we also assume |     |     |     | Read | GPR[Rt] |     | port 2 |
| -------------------------- | --- | --- | --- | ---- | ------- | --- | ------ |
|                            |     | 5   |     |      | 32      |     |        |
 register
assumed that GPR[2]=62
|     |     |     |     |  data2 | = GPR[2] | = 62 |     |
| --- | --- | --- | --- | ------ | -------- | ---- | --- |
we connect the Rt field Read register2
Write
and get GPR[Rt] ate the
|     |     | 32  |     |     |     |     |  Write  |
| --- | --- | --- | --- | --- | --- | --- | ------- |
Data
| Read data2 output |     |     |     |     |     |     | port |
| ----------------- | --- | --- | --- | --- | --- | --- | ---- |
CK

The General-Purpose Register file (GPR).
add  $12, $7, $2
So this is the real picture:
| 31     | 26 25 | 21 20 | 16 15 | 11  | 6 5    | 0   |     |
| ------ | ----- | ----- | ----- | --- | ------ | --- | --- |
| 000000 | 00111 | 00010 | 01100 |     | 100000 |     |     |
ALU function code
ALU
control
GPR file
Read
|     |     |     | 00111  = 7 = Rs |     | 5   |     |     |
| --- | --- | --- | --------------- | --- | --- | --- | --- |
 register1 add code
GPR[Rs]
Read 32
  data1
Read +
|     |     |     | 00010  = 2 = | Rt  |     |     | = GPR[7] |
| --- | --- | --- | ------------ | --- | --- | --- | -------- |
5 165
 register2
= 103
|     |     |     |     |     |     | Write | GPR[Rt] |
| --- | --- | --- | --- | --- | --- | ----- | ------- |
01100  = 12 = Rd Read
|     |     |     |     |     | 5   |     | 32  |
| --- | --- | --- | --- | --- | --- | --- | --- |
 register
 data2 = GPR[2] = 62
Write
GPR[Rd] = 165
32
Data
CK
| So what’s next? |     | We want to add the 103 & 62 |     |     |     | 103 + 62 = 165 |     |
| --------------- | --- | --------------------------- | --- | --- | --- | -------------- | --- |
Now we want to write this  to Rd

I-Type ALU Instructions
 Assembly (e.g., register-immediate signed additions)
ADDI rt rs immediate
reg reg 16
 Machine encoding
I-type
ADDI rs rt immediate
6-bit 5-bit 5-bit 16-bit
 Semantics
if MEM[PC] == ADDI rt rs immediate
GPR[rt]  GPR[rs] + sign-extend (immediate)
PC  PC + 4
40

Datapath for R and I-Type ALU Insts.
Add
4
|     |     |     |     |     |     |     | 3   | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- |
Read
R e a d
|     | PC  |     |     | 25:21 | register 1 | Read |     |     |     | MemWrite |     |
| --- | --- | --- | --- | ----- | ---------- | ---- | --- | --- | --- | -------- | --- |
ad d r ess
data 1
Read
Zero
|     |     |             |             | Instruct2io0:n16 | register 2 |     |     |        |         |     |      |
| --- | --- | ----------- | ----------- | ---------------- | ---------- | --- | --- | ------ | ------- | --- | ---- |
|     |     |             | Instruction |                  | Registers  |     | ALU | ALU    |         |     |      |
|     |     |             |             |                  | Write      |     |     |        |         |     | Read |
|     |     |             |             |                  |            |     |     | result | Address |     |      |
|     |     | Instruction |             | 15:11            | register   |     |     |        |         |     | data |
Read
memory
|     |     |     |     |     | Write | data 2 |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----- | ------ | --- | --- | --- | --- | --- |
Data
|     |     |     |     | RegDest | data |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | ---- | --- | --- | --- | --- | --- | --- |
memory
|     |     |     |     | isItype | RegWrite |     |     |     | Write |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | ----- | --- | --- |
data
ALUSrc
1
16 32
isItype
|     |     |     |     |     |     | Sign |     |     |     | MemRead |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | ------- | --- |
extend
| if MEM[PC] == ADDI rt rs immediate           |     |     |     |     |     | IF  | ID            | EX  | MEM | WB  |     |
| -------------------------------------------- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- | --- |
| GPR[rt]  GPR[rs] + sign-extend (immediate)  |     |     |     |     |     |     | Combinational |     |     |     |     |
PC  PC + 4
state update logic
41
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Datapath for R and I-Type ALU Insts.
Add
4
|     |     |     |     |     |     |     |     | 3   | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- |
Read
R e a d
|     | PC  |     |     | 25:21 | register 1 |     | Read |     |     |     | MemWrite |     |
| --- | --- | --- | --- | ----- | ---------- | --- | ---- | --- | --- | --- | -------- | --- |
ad d r ess
data 1
Read
|     |     |             |             |                  |            | ID  |     |     | ZEerXo |         |     |      |
| --- | --- | ----------- | ----------- | ---------------- | ---------- | --- | --- | --- | ------ | ------- | --- | ---- |
|     |     |             |             | Instruct2io0:n16 | register 2 |     |     |     |        |         |     |      |
|     |     |             | Instruction |                  | Registers  |     |     | ALU | ALU    |         |     |      |
|     |     |             |             |                  | Write      |     |     |     |        |         |     | Read |
|     |     |             |             |                  |            |     |     |     | result | Address |     |      |
|     |     | Instruction |             | 15:11            | register   |     |     |     |        |         |     | data |
Read
memory
|     |     |     |     |     | Write | data 2 |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----- | ------ | --- | --- | --- | --- | --- | --- |
Data
|     |     |     |     | RegDest | data     |     |     |     |     |       |        |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | ----- | ------ | --- |
|     |     |     |     | WB      |          |     |     |     |     |       | memory |     |
|     |     |     |     | isItype | RegWrite |     |     |     |     | Write |        |     |
data
ALUSrc
1
|     |     |     | IF  |     |     | 16  | 32  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
isItype
|     |     |     |     |     |     | Sign |     |     |     |     | MemRead |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | ------- | --- |
extend
| GPR[rt]  GPR[rs] + sign-extend (immediate)  |     |     |     |     |     |     | IF  | ID  | EX  | MEM | WB  |     |
| -------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
PC  PC + 4
Combinational
state update logic
42
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Single-Cycle Datapath for
Data Movement Instructions
43

Load Instructions
 Assembly (e.g., load 4-byte word)
Load
| LW rt |  offset |  (base | )   |     | rs ומכ |
| ----- | ------- | ------ | --- | --- | ------ |
|       | reg     | 16     | reg |     |        |
I-type -ה תחפשממ אוה
 Machine encoding
I-type
|     | LW    |     | base  | rt    | offset |
| --- | ----- | --- | ----- | ----- | ------ |
|     | 6-bit |     | 5-bit | 5-bit | 16-bit |
 Semantics
if MEM[PC]==LW rt offset  (base)
16
EA = sign-extend(offset) + GPR[base]
GPR[rt]  MEM[ translate(EA) ]
PC  PC + 4
44

LW Datapath
ןורכזל םיבתוכ ונניא
Add
0
|     |            |     | 4   |            |      | add           |     |     |          |     |     |     |
| --- | ---------- | --- | --- | ---------- | ---- | ------------- | --- | --- | -------- | --- | --- | --- |
|     |            |     |     |            |      | ALU operation |     |     | MemWrite |     |     |     |
|     |            |     |     | Read       |      | 3             |     |     |          |     |     |     |
|     | R e a d    |     |     | register 1 |      |               |     |     | MemWrite |     |     |     |
| PC  | ad d r ess |     |     |            | Read |               |     |     |          |     |     |     |
data 1
Read
|     |             |             |             |            |           | Zero    |     | Address |        | Read |     |        |
| --- | ----------- | ----------- | ----------- | ---------- | --------- | ------- | --- | ------- | ------ | ---- | --- | ------ |
|     |             |             | Instruction | register 2 |           |         |     |         |        |      |     |        |
|     |             | Instruction |             | Registers  |           | ALU ALU |     |         |        | data | 16  | 32     |
|     |             |             |             |            |           |         |     |         | Read   |      |     | Sign   |
|     |             |             |             | Write      |           | result  |     | Address |        |      |     |        |
|     | Instruction |             |             | register   |           |         |     |         | data   |      |     | extend |
|     |             |             |             |            | R e a d   |         |     |         | Data   |      |     |        |
|     | memory      |             |             |            | da t a  2 |         |     | Write   |        |      |     |        |
|     |             |             |             | Write      |           |         |     | data    | memory |      |     |        |
Data
data
memory
|     |     |     | RegDest | RegWrite |     |     |     | Write |     |     |     |     |
| --- | --- | --- | ------- | -------- | --- | --- | --- | ----- | --- | --- | --- | --- |
data
|     |     |     | isItype |     |            | ALUSrc |     |                     |         |     |                        |     |
| --- | --- | --- | ------- | --- | ---------- | ------ | --- | ------------------- | ------- | --- | ---------------------- | --- |
|     |     |     |         | 1   |            |        |     |                     | MemRead |     |                        |     |
|     |     |     |         | 16  | 32 isItype |        |     |                     |         |     |                        |     |
|     |     |     |         |     | Sign       |        |     |                     | MemRead |     |                        |     |
|     |     |     |         |     | extend     |        |     |                     | 1       |     |                        |     |
|     |     |     |         |     |            |        |     | a. Data memory unit |         |     | b. Sign-extension unit |     |
ןורכזהמ םיארוק ונא
| if MEM[PC]==LW rt offset |     |     |  (base)  |     |     |     | IF  | ID  | EX  | MEM | WB  |     |
| ------------------------ | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
16
|        EA = sign-extend(offset) + GPR[base] |     |     |     |     |     |     |     | Combinational      |     |     |     |     |
| ------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- | --- | --- |
|        GPR[rt]  MEM[ translate(EA) ]       |     |     |     |     |     |     |     | state update logic |     |     | 45  |     |
       PC  PC + 4

LW Datapath
םיבתוכ ונניא
 ןורכזל
Add
4 add
0
ALU operation
|     |     |         |     | Read       |     |        | 3   |     |     |                  |     |     |     |     |
| --- | --- | ------- | --- | ---------- | --- | ------ | --- | --- | --- | ---------------- | --- | --- | --- | --- |
|     | PC  | R e a d |     | register 1 |     | IDRead |     |     |     | MMeemmWWrirteite |     |     |     |     |
ad d r ess
data 1
Read
|     |     |     |     | register 2 |     |     | Zero |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ---------- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
Instruction
|     |     |             | Instruction |          | Registers |        | ALU E A | X L U |                |     |             |     |        |     |
| --- | --- | ----------- | ----------- | -------- | --------- | ------ | ------- | ----- | -------------- | --- | ----------- | --- | ------ | --- |
|     |     |             |             |          |           |        |         |       |                |     | MRReEaeda M |     |        |     |
|     |     |             |             | Write    |           |        | r e su  | l t   | AAddddrreessss |     |             | d   |        |     |
|     |     | Instruction |             | register |           |        |         |       |                |     | dadtaata    |     | 16     | 32  |
|     |     |             |             |          |           | Read   |         |       |                |     |             |     | Sign   |     |
|     |     | memory      |             |          |           | data 2 |         |       |                |     |             |     |        |     |
|     |     |             |             | Write    |           |        |         |       |                |     |             |     | extend |     |
Data Data
|     |     |     |     | data |     |     |     |     | Write     |         |               |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | --- | --- | --------- | ------- | ------------- | --- | --- | --- |
|     |     |     |     | WB   |     |     |     |     | dWartiate | m m e e | m m o o ry ry |     |     |     |
RegDest RegWrite
data
isItype ALUSrc
1
|     |     |     |     |     |     | 16 32 isItype |     |     |     |         |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- | ------- | --- | --- | --- | --- |
|     |     | IF  |     |     |     | Sign          |     |     |     | MemRead |     |     |     |     |
|     |     |     |     |     |     | extend        |     |     |     | MemRead |     |     |     |     |
1
|     |     |     |     |     |     |     |     |     | a. Data memory unit |     |     |     | b. Sign-extension unit |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ------------------- | --- | --- | --- | ---------------------- | --- |
םיארוק ונא
ןורכזהמ
|     | EA = GPR[rs] + sign-extend(offset) |     |     |     |     |     |     | IF  | ID  |     | EX  | MEM | WB  |     |
| --- | ---------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Combinational
       GPR[rt]  MEM[ EA ]
|        PC  PC + 4 |     |     |     |     |     |     |     |     | state update logic |     |     |     | 46  |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- | --- | --- | --- |

Store Instructions
 Assembly (e.g., store 4-byte word)
| SW rt |  offset |  (base | )   |     |     |
| ----- | ------- | ------ | --- | --- | --- |
|       | reg     | 16     | reg |     |     |
rs ומכ
 Machine encoding
I-type
|     | SW    |     | base  | rt    | offset |
| --- | ----- | --- | ----- | ----- | ------ |
|     | 6-bit |     | 5-bit | 5-bit | 16-bit |
 Semantics
if MEM[PC]==SW rt offset  (base)
16
EA = sign-extend(offset) + GPR[base]
MEM[ translate(EA) ]  GPR[rt]
PC  PC + 4
47

SW Datapath
תותואה וכפהתה התע
Add
1
|     |            |     | 4   |            |      | add           |     |     |          |     |     |     |
| --- | ---------- | --- | --- | ---------- | ---- | ------------- | --- | --- | -------- | --- | --- | --- |
|     |            |     |     |            |      | ALU operation |     |     | MemWrite |     |     |     |
|     |            |     |     | Read       |      | 3             |     |     |          |     |     |     |
|     | R e a d    |     |     | register 1 |      |               |     |     | MemWrite |     |     |     |
| PC  | ad d r ess |     |     |            | Read |               |     |     |          |     |     |     |
data 1
Read
|     |             |             |             |            |           | Zero    |     | Address |        | Read |     |        |
| --- | ----------- | ----------- | ----------- | ---------- | --------- | ------- | --- | ------- | ------ | ---- | --- | ------ |
|     |             |             | Instruction | register 2 |           |         |     |         |        |      |     |        |
|     |             | Instruction |             | Registers  |           | ALU ALU |     |         |        | data | 16  | 32     |
|     |             |             |             |            |           |         |     |         | Read   |      |     | Sign   |
|     |             |             |             | Write      |           | result  |     | Address |        |      |     |        |
|     | Instruction |             |             | register   |           |         |     |         | data   |      |     | extend |
|     |             |             |             |            | R e a d   |         |     |         | Data   |      |     |        |
|     | memory      |             |             |            | da t a  2 |         |     | Write   |        |      |     |        |
|     |             |             |             | Write      |           |         |     | data    | memory |      |     |        |
Data
data
memory
|     |     |     | RegDest | RegWrite |     |     |     | Write |     |     |     |     |
| --- | --- | --- | ------- | -------- | --- | --- | --- | ----- | --- | --- | --- | --- |
data
|     |     |     | isItype | 0   |     | ALUSrc |     |     |     |     |     |     |
| --- | --- | --- | ------- | --- | --- | ------ | --- | --- | --- | --- | --- | --- |
MemRead
|                          |     |     |          | 16  | 32     | isItype |     |                     |         |     |                        |     |
| ------------------------ | --- | --- | -------- | --- | ------ | ------- | --- | ------------------- | ------- | --- | ---------------------- | --- |
|                          |     |     |          |     | Sign   |         |     |                     | MemRead |     |                        |     |
|                          |     |     |          |     | extend |         |     |                     | 0       |     |                        |     |
|                          |     |     |          |     |        |         |     | a. Data memory unit |         |     | b. Sign-extension unit |     |
| if MEM[PC]==SW rt offset |     |     |  (base)  |     |        |         |     |                     |         |     |                        |     |
16
|     |     |     |     |     |     |     | IF  | ID  | EX  | MEM | WB  |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
       EA = sign-extend(offset) + GPR[base]
Combinational
       MEM[ translate(EA) ]  GPR[rt]
|     |     |     |     |     |     |     |     | state update logic |     |     | 48  |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- | --- | --- |
        PC  PC + 4

SW Datapath
תותואה וכפהתה התע
Add
|     |     | 4   |     |     | add |     |     | 1   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALU operation
|         |     |     | Read       |        | 3   |     |     |                  |     |     |     |
| ------- | --- | --- | ---------- | ------ | --- | --- | --- | ---------------- | --- | --- | --- |
| R e a d |     |     | register 1 | IDRead |     |     |     | MMeemmWWritreite |     |     |     |
PC ad d r ess
data 1
Read
Zero
|     |             | Instruction | register 2 |     |         |       |     |     |     |     |     |
| --- | ----------- | ----------- | ---------- | --- | ------- | ----- | --- | --- | --- | --- | --- |
|     | Instruction |             | Registers  |     | ALU E A | X L U |     |     |     |     |     |
MRR EeaedM
|             |     |     | Write    |     | r e su | l t | AAddddrreessss |     | ad       |     |     |
| ----------- | --- | --- | -------- | --- | ------ | --- | -------------- | --- | -------- | --- | --- |
| Instruction |     |     | register |     |        |     |                |     | dadtaata | 16  | 32  |
Read
| memory |     |     |       | data 2 |     |     |     |     |     |     | Sign   |
| ------ | --- | --- | ----- | ------ | --- | --- | --- | --- | --- | --- | ------ |
|        |     |     | Write |        |     |     |     |     |     |     | extend |
Data
|     |     |     | data |     |     |     | Write | Data |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | ----- | ---- | --- | --- | --- |
memory memory
|     |     | RegDest | RegWrite |     |     |     | Wdarittae |     |     |     |     |
| --- | --- | ------- | -------- | --- | --- | --- | --------- | --- | --- | --- | --- |
data
|     |     | isItype | 0   |        | ALUSrc  |     |     |         |     |     |     |
| --- | --- | ------- | --- | ------ | ------- | --- | --- | ------- | --- | --- | --- |
|     |     |         |     | 16 32  | isItype |     |     |         |     |     |     |
| IF  |     |         |     | Sign   |         |     |     | MemRead |     |     |     |
|     |     |         |     | extend |         |     |     | MemRead |     |     |     |
0
|     |     |     |     |     |     |     | a. Data memory unit |     |     | b. Sign-extension unit |     |
| --- | --- | --- | --- | --- | --- | --- | ------------------- | --- | --- | ---------------------- | --- |
EA = GPR[rs] + sign-extend(offset)
|     |     |     |     |     |     | IF  | ID  | EX  | MEM | WB  |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
MEM[ EA ]  GPR[rt]
Combinational
         PC  PC + 4
|     |     |     |     |     |     |     | state update logic |     |     | 49  |     |
| --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- | --- | --- |

Load-Store Datapath
Add
add
4
ALU operation isStore
Read 3
PC Read register 1 Read MemWrite
address
data 1
Read
Instruction register 2 Zero
Instruction Registers ALU ALU
Write result Address Read
Instruction register data
Read
memory data 2
Write
Data
data
memory
Write
RegDest RegWrite
data
isItype !isStore ALUSrc
16 32
Sign isItype MemRead
extend
isLoad
50
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Datapath for Non-Control-Flow Insts.
Add
4
isStore
3 ALU operation
Read
R e a d
| PC  |     |     |     | register 1 |     |     | MemWrite |
| --- | --- | --- | --- | ---------- | --- | --- | -------- |
ad d r ess Read
data 1
Read
Zero
|     |             |             | Instruction | register 2 |         |         |      |
| --- | ----------- | ----------- | ----------- | ---------- | ------- | ------- | ---- |
|     |             | Instruction |             | Registers  | ALU ALU |         |      |
|     |             |             |             | Write      |         |         | Read |
|     |             |             |             |            | result  | Address |      |
|     | Instruction |             |             | register   |         |         | data |
Read
memory
Write data 2
Data
data
memory
|     |     |     | RegDest | RegWrite |     | Write |     |
| --- | --- | --- | ------- | -------- | --- | ----- | --- |
data
isItype
|     |     |     |     | !isStore | ALUSrc |     |     |
| --- | --- | --- | --- | -------- | ------ | --- | --- |
16 32
isItype
Sign MemRead
extend
isLoad
MemtoReg
isLoad
51
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

הכ-דע ודמלנש תוארוהה רובע datapath -ה לע ףסונ רבסהו הרזח
-מ םיחוקלה םיאבה םיפקשה 7-ב שדחמ תנתינ
CSE378 University of Washington
https://courses.cs.washington.edu/courses/cse378/10sp/lectures.ht
ml
ימצע דומילב השעי םיפקשה לע רבעמהו ןאכ םהילע בכעתנ אל ונא
תיבב

CSE378 ךותמ םיפקש תפסות ןאכ דע

Single-Cycle Datapath for
Control Flow Instructions
61

Unconditional Jump Instructions
 Assembly
J immediate
26
 Machine encoding
J immediate J-type
6-bit 26-bit
 Semantics
if MEM[PC]==J immediate
26
Guy> This is the addressing
target = { PC[31:28], immediate , 2’b00 }
26 mode convention:
PC  target
concatenate the PC+imm+2’b00
62

MIPS -ה ןורכיז תפמ תרוכזת
MIPS reference card -המ חוקל
16^7 = 2^28

Unconditional Jump Datapath
JR
isJ
Add
PCSrc
4
X
|     |         |     |            | ALU operation |     | 0        |
| --- | ------- | --- | ---------- | ------------- | --- | -------- |
|     |         |     | Read       | 3             |     |          |
| PC  | R e a d |     | register 1 |               |     | MemWrite |
ad d r ess Read
data 1
Read
Zero
Instruction register 2
|     |             | Instruction | Registers | ALU ALU |         |      |
| --- | ----------- | ----------- | --------- | ------- | ------- | ---- |
|     |             |             | Write     |         |         | Read |
|     |             |             |           | result  | Address | data |
|     | Instruction |             | register  |         |         |      |
Read
memory data 2
| concat |     |     | Write |     |     |     |
| ------ | --- | --- | ----- | --- | --- | --- |
Data
data
memory
|     |     |     | ?   |     | Write |     |
| --- | --- | --- | --- | --- | ----- | --- |
RegWrite
data
ALUSrc
0
16 32 X
Sign MemRead
extend
0
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]
if MEM[PC]==J immediate26
64
    PC = { PC[31:28], immediate26, 2’b00 } What about JR, JAL?

H&P CO&D
FIGURE 4.24 The simple control and datapath are extended to handle the jump instruction. An additional multiplexor (at
the upper right) is used to choose between the jump target and either the branch target or the sequential instruction
following this one. This multiplexor is controlled by the jump control signal. The jump target address is obtained by shifting
the lower 26 bits of the jump instruction left 2 bits, effectively adding 00 as the low-order bits, and then concatenating the
upper 4 bits of PC + 4 as the high-order bits, thus yielding a 32-bit address.
66
Copyright © 2014 Elsevier Inc. All rights reserved.

Aside: MIPS Cheat Sheet
http://www.ece.cmu.edu/~ece447/s15/lib/exe/fetch.php?media=mips_reference_data.pdf
Please download!
:ריכזהל
Pseudo Instructions לדומב אצמנ
67

Conditional Branch Instructions
 Assembly (e.g., branch if equal)
BEQ rs rt immediate
reg reg 16
 Machine encoding
BEQ rs rt immediate I-type
6-bit 5-bit 5-bit 16-bit
 Semantics (assuming no branch delay slot)
if MEM[PC]==BEQ rs rt immediate
16
target = PC + 4 + sign-extend(immediate) x 4
if GPR[rs]==GPR[rt] then PC  target
ALU-ב תישענ האוושה תלועפ￤
else PC  PC + 4
68

Conditional Branch Datapath (for you to finish)
watch out
PC + 4 from instruction datapath
Add
PCSrc
|     |     |     | Add Sum | Branch target |
| --- | --- | --- | ------- | ------------- |
4
Shift
left 2
| PC  | Read |     | sub |     |
| --- | ---- | --- | --- | --- |
address
ALU operation
|     |     | Read | 3   |     |
| --- | --- | ---- | --- | --- |
Instruction register 1
Read
Instruction data 1
Read
|        | Instruction | register 2 |               | To branch     |
| ------ | ----------- | ---------- | ------------- | ------------- |
|        |             | Registers  | ALU bZceonrod |               |
|        | memory      |            |               | control logic |
| concat |             | Write      |               |               |
register
Read
data 2
Write
data
RegWrite
0
16 32
Sign
extend
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
69

Conditional Branch Datapath (finished :-) )
PC + 4 from instruction datapath
Add
PCSrc
|     |     |     | Add Sum | Branch target |
| --- | --- | --- | ------- | ------------- |
4
Shift
left 2
| PC  | Read |     | sub |     |
| --- | ---- | --- | --- | --- |
address
ALU operation
|     |     | Read | 3   |     |
| --- | --- | ---- | --- | --- |
Instruction register 1
Read
Instruction data 1
Read
|        | Instruction | register 2 |               | To branch     |
| ------ | ----------- | ---------- | ------------- | ------------- |
|        |             | Registers  | ALU bZceonrod |               |
|        | memory      |            |               | control logic |
| concat |             | Write      |               |               |
register
Read
data 2
Write
data
RegWrite
0
16 32
Sign
extend
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
70

Credit: CSE378 Washington

The Final Datapath (without the controls)
Credit: CSE378 Washington

Putting It All Together
|     |     |     |                    |       |     |                     |     |     |     |     |     | PCSrc =Jump |     |     |
| --- | --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | --- | --- | ----------- | --- | --- |
|     |     |     | Instruction [25–0] | Shift |     | Jump address [31–0] |     |     |     |     |     | 1           |     |     |
left 2
|     |     |     |     | 26  | 28  |     |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |     |     | M   | M   |     |
PC+4 [31–28]
|     |     |     |     |     |     |     |     |     |     |         |     | u   | u   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |         |     | x   | x   |     |
|     |     |     |     |     |     |     |     |     |     | Add ALU |     | 1   | 0   |     |
result
|     |     | Add |     |     |     | RegDst |     |     | Shift |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | --- | ----- | --- | --- | --- | --- | --- |
PCSrc =Br Taken
|     |     |     |     |     |     | Jump |     |     | left 2 |     |     |     | 2   |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | --- | ------ | --- | --- | --- | --- | --- |
4
Branch
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
RegWrite
Instruction [25–21]
Read
| PC  | R e a d    |     |                     |     |     | register 1 |     |        |     |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | --- | ---------- | --- | ------ | --- | --- | --- | --- | --- | --- |
|     | ad d r ess |     |                     |     |     |            |     | Read   |     |     |     |     |     |     |
|     |            |     | Instruction [20–16] |     |     | Read       |     | data 1 |     |     |     |     |     |     |
bcZoenrdo
|     |          | Instruction |                     |     |     | register 2   |           |           |     |           |         |      |      |     |
| --- | -------- | ----------- | ------------------- | --- | --- | ------------ | --------- | --------- | --- | --------- | ------- | ---- | ---- | --- |
|     |          |             |                     |     | 0   |              | Registers | R e a d   |     | ALU A L U |         |      |      |     |
|     |          | [31–0]      |                     |     |     | Write        |           |           | 0   |           |         |      | Read |     |
|     |          |             |                     |     | M   |              |           | da t a  2 |     | re su l t | Address |      | data | 1   |
|     | In st ru | c ti o n    |                     |     | u   | r eg i s ter |           |           | M   |           |         |      |      | M   |
|     | m e m    | o r y       |                     |     | x   |              |           |           | u   |           |         |      |      |     |
|     |          |             | Instruction [15–11] |     |     | W ri t e     |           |           | x   |           |         |      |      | u   |
|     |          |             |                     |     | 1   | data         |           |           |     |           |         | D at | a    | x   |
|     |          |             |                     |     |     |              |           |           | 1   |           |         | m em | o ry | 0   |
Write
data
|     |     |     | Instruction [15–0] |     |     |     | 16  | 32  |     |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign
|     |     |     |     |     |     |     |     | extend |     | ALU operation |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------------- | --- | --- | --- | --- |
ALU
control
Instruction [5–0]
73
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL
JAL, JR, JALR omitted
RIGHTS RESERVED.]

Single-Cycle Control Logic
74

םיפקשה 10-ב datapath -ה לע םיטלושש הרקבה תותוא תא ריבסנ
ינד לש םיאבה

Control
0
M
u
x
ALU
|     |     |     |     |     | Add | 1   |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
result
| Add |     |        |     | Shift  |     |     |     |
| --- | --- | ------ | --- | ------ | --- | --- | --- |
|     |     | RegDst |     | left 2 |     |     |     |
| 4   |     | Branch |     |        |     |     |     |
MemRead
MemtoReg
Instruction [31–26]
Control
ALUOp
MemWrite
ALUSrc
RegWrite
Instruction [25–21]
Read
| PC R e a d  |                     | register 1 |        |     |     |     |     |
| ----------- | ------------------- | ---------- | ------ | --- | --- | --- | --- |
| a d d r ess |                     |            | Read   |     |     |     |     |
|             | Instruction [20–16] |            | data 1 |     |     |     |     |
Read
|     |     | register 2 |     |     | Zero |     |     |
| --- | --- | ---------- | --- | --- | ---- | --- | --- |
Instruction
| [31–0]      |                     | 0     | Registers R e a d | ALU | A L U             |        |     |
| ----------- | ------------------- | ----- | ----------------- | --- | ----------------- | ------ | --- |
|             |                     | M W   | ri t e da t a  2  | 0   | re su l t Address | R de a |     |
| Instruction |                     |       |                   |     |                   | da a t | 1   |
|             |                     | u r   | eg i s ter        | M   |                   |        | M   |
| memory      |                     | x     |                   | u   |                   |        |     |
|             | Instruction [15–11] | Write |                   | x   |                   |        | u   |
|             |                     | 1     |                   |     |                   | Data   | x   |
|             |                     | data  |                   | 1   |                   |        |     |
|             |                     |       |                   |     |                   | memory | 0   |
Write
data
|     | Instruction [15–0] |     | 16 32 |     |     |     |     |
| --- | ------------------ | --- | ----- | --- | --- | --- | --- |
Sign
extend
ALU
control
Instruction [5–0]

Let’s explain all Control Signals:
ALUSrc – 0 will connect GPR[Rt] to the ALU B input [Rtype, beq]
  1- will connect sext(imm) to the ALU B input [in lw or sw inst.]
ALUOP – Two bits: 00 force the ALU to add  [lw & sw].   01 force the ALU to sub [beq].  10 force the ALU to look at the funct. Field [Rtype].
MemRead – 0 - nothing happens.  1- data is read from M[ALU output]
MemWrite – 0 - nothing happens.  1- GPR[Rt] is written into M[ALU output]  at the next rising edge of the CK
0
M
u
x
A L U
|     |     |     |     |     | Addre su l t 1 |     |
| --- | --- | --- | --- | --- | -------------- | --- |
Add
Shift
|     |     | RegDst |     | left 2 |     |     |
| --- | --- | ------ | --- | ------ | --- | --- |
4
Branch
MemRead
|     | Instruction [31–26] | MemtoReg |     |     |     |     |
| --- | ------------------- | -------- | --- | --- | --- | --- |
Control ALUOp
MemWrite
ALUSrc
RegWrite
|     | Instruction [25–21] | Read |     |     |     |     |
| --- | ------------------- | ---- | --- | --- | --- | --- |
R e a d
| PC a d d r ess |                     | register 1 | Read   |     |     |     |
| -------------- | ------------------- | ---------- | ------ | --- | --- | --- |
|                | Instruction [20–16] |            | data 1 |     |     |     |
Read
| Instr u ct io n   |                     | r e g i s t er  2 |           |     | Z e r o            |               |
| ----------------- | ------------------- | ----------------- | --------- | --- | ------------------ | ------------- |
|                   |                     | 0 R egisters      | R e a d   |     | ALU A L U          |               |
| [ 31 – 0 ]        |                     | M W r i t e       | da t a  2 | 0   | re s u l t Address | R de a 1      |
| In st ru c ti o n |                     | u r e g i s t e r |           | M   |                    | da a t        |
| m e m o r y       |                     | x                 |           | u   |                    | M             |
|                   | Instruction [15–11] | W r i t e         |           | x   |                    | u             |
|                   |                     | 1 d a t a         |           |     |                    | D a t a x     |
|                   |                     |                   |           | 1   |                    | m e m o r y 0 |
Write
data
16 32
|     | Instruction [15–0] |     | Sign |     |     |     |
| --- | ------------------ | --- | ---- | --- | --- | --- |
extend
ALU
control
Instruction [5–0]
RegWrite – 0 –  if we do not write back to GPR [sw, beq].
                     1 –  if we do write beck to GPR [Rtype, lw]
MemToReg – 0 – The ALU output is fed to the GPR Write Data input [Rtype]. 1- Data read from Memory is fed to the GPR Write Data input [lw]
RegDst – 0 – The GPR Write Reg gets Rt field of the instruction [lw].  1- The GPR Write Reg gets Rd field of instruction [Rtype]
Branch – 0 – ia all instructions except beq.  1- in beq. Selects whether to branch or not.

Inputs
Op5
Op4 Control
Op3
Op2
Op1
Op0
We would like to build the Control Decoder together
Outputs
R-format Iw sw beq
RegDst
ALUSrc
MemtoReg
RegWrite
MemRead
MemWrite
Branch
ALUOp1
ALUOpO
Mem
ALU ALUOp Mem Mem to Reg Reg
Instr. Src [1:0] Read Write Reg Dst Write Branch
R-type
lw
sw
beq

0
M
u
x
A L U
|     |     |     |     |     |     |     |     | Add | 1   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
re su l t
Add
Shift
|     |     |     |     |     |     | RegDst | left 2 |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | ------ | --- | --- | --- |
4
Branch
MemRead
|     |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
|     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |                     |     | register 1 Read |     |     |     |     |
| --- | --- | ------- | --- | ------------------- | --- | --------------- | --- | --- | --- | --- |
|     |     |         |     | Instruction [20–16] |     | data 1          |     |     |     |     |
Read
|     |     |          | Instr u c t io n |                     |     | r e g i s t e r  2  |     | Z e r o    |         |               |
| --- | --- | -------- | ---------------- | ------------------- | --- | ------------------- | --- | ---------- | ------- | ------------- |
|     |     |          |                  |                     | 0   | R egisters R e a d  |     | ALU A L U  |         |               |
|     |     |          | [ 3 1 – 0 ]      |                     | M   | W r i t e da t a  2 | 0   | re s u l t | Address | R de a 1      |
|     |     | In st ru | c ti o n         |                     | u   | r e g i s te r      | M   |            |         | da a t        |
|     |     | m e      | m o r y          |                     |     |                     | u   |            |         | M             |
|     |     |          |                  | Instruction [15–11] | x   | W r i t e           | x   |            |         | u             |
|     |     |          |                  |                     | 1   | d a t a             |     |            |         | D a t a x     |
|     |     |          |                  |                     |     |                     | 1   |            |         | m e m o r y 0 |
Write
data
|                        |     |     |     |                    |     | 16 32 |     |     |     |     |
| ---------------------- | --- | --- | --- | ------------------ | --- | ----- | --- | --- | --- | --- |
| We can fill up columns |     |     |     | Instruction [15–0] |     | Sign  |     |     |     |     |
extend
ALU
control
| We only read from memeory in lw instruction, so |     |     |     |     |     | Instruction [5–0] |     |     |     |     |
| ----------------------------------------------- | --- | --- | --- | --- | --- | ----------------- | --- | --- | --- | --- |
We only write to memeory in sw instruction, so
Mem
|     | ALU | ALUOp | Mem | Mem | to  | Reg  Reg  |     |     | A better way is to follow |     |
| --- | --- | ----- | --- | --- | --- | --------- | --- | --- | ------------------------- | --- |
Each instruction and see
| Instr. | Src | [1:0] | Read | Write | Reg | Dst Write | Branch |     |     |     |
| ------ | --- | ----- | ---- | ----- | --- | --------- | ------ | --- | --- | --- |
What happens in the
| R-type |     |     | 0   | 0   |     |     |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Data-Path during the
Execution of the instruction
| lw  |     |     | 1   | 0   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
sw
|     |     |     | 0   | 1   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
beq
|     |     |     | 0   | 0   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Rtype
|     |     |     | add  Rd, Rs, Rt         |     |     |     |     |     | 0   |     |     |
| --- | --- | --- | ----------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
M
|     |     |     | GPR[Rd] = GPR[Rs]+GPR[Rt] |     |     |     |     |     | u   |     |     |
| --- | --- | --- | ------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
x
A L U
|     |     |     |     |     |     |     |     |     | Add 1 |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- |
re su l t
|     |     |     | Add |     |     |        |     |        | 0   |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --- |
|     |     |     |     |     |     |        |     | Shift  | 0   |     |     |
|     |     |     |     |     |     | RegDst |     | left 2 |     |     |     |
4
Branch
MemRead
|     |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
1
|     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |                     |     | register 1 | Read   |     |     |     |     |
| --- | --- | ------- | --- | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- |
|     |     |         |     | Instruction [20–16] |     |            | data 1 |     |     |     |     |
Read
|     |     |          | Instr u c t io n |                     |     | r e g i s t e r  2 |           |     | Z e r o            |            |     |
| --- | --- | -------- | ---------------- | ------------------- | --- | ------------------ | --------- | --- | ------------------ | ---------- | --- |
|     |     |          |                  |                     | 0   | R egisters         | R e a d   |     | ALU A L U          |            |     |
|     |     |          | [ 3 1 – 0 ]      |                     | M   | W r i t e          | da t a  2 | 0   | re s u l t Address | R e a d    | 1   |
|     |     | In st ru | c ti o n         |                     | u   | r e g i s te r     |           | M   |                    | d a t a    |     |
|     |     | m e      | m o r y          |                     |     |                    |           | u   |                    |            | M   |
|     |     |          |                  | Instruction [15–11] | x   | W r i t e          |           | x   |                    |            | u   |
|     |     |          |                  |                     | 1   | d a t a            |           |     |                    | D a t a    | x   |
|     |     |          |                  |                     |     |                    |           | 1   |                    | m e m o ry | 0   |
Write
data
| In Rtype we use GPR[Rs] op GPR[Rt] |     |     |     |                    |     |     | 16 32 |     |     |     |     |
| ---------------------------------- | --- | --- | --- | ------------------ | --- | --- | ----- | --- | --- | --- | --- |
|                                    |     |     |     | Instruction [15–0] |     |     | Sign  |     |     |     |     |
extend
| Thus, ALUSrc =0 |     |     |     |     |     |     |     | ALU |     |     |     |
| --------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
control
| In Rtype we must have  ALUSOP =10    (function) |     |     |     |     |     | Instruction [5–0] |     |     |     |     |     |
| ----------------------------------------------- | --- | --- | --- | --- | --- | ----------------- | --- | --- | --- | --- | --- |
10
MemRead=0 and MemWrite=0
MemToReg=0
Mem
RegDst=1 to select Rd
|        | ALU | ALUOp | Mem  | Mem   | to  | Reg  | Reg   |        |     |     |     |
| ------ | --- | ----- | ---- | ----- | --- | ---- | ----- | ------ | --- | --- | --- |
| Instr. | Src | [1:0] | Read | Write | Reg | Dst  | Write | Branch |     |     |     |
RegWrite=1 to write to the GPR
| R-type | 0   | 1    0 | 0   | 0   | 0   | 1   | 1   | 0   |     |     |     |
| ------ | --- | ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Branch=0 so we always get
PC=PC+4
| lw  |     |     | 1   | 0   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
sw
|     |     |     | 0   | 1   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
beq
|     |     |     | 0   | 0   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

|     |     |     |     | lw  Rt, imm(Rs)         |     |     |     |     |     |     |     | 0   |     | LW  |
| --- | --- | --- | --- | ----------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
M
|     |     |     |     | GPR[Rt] = M[ GPR[Rs]+sext(imm) ] |     |     |     |     |     |     |     | u   |     |     |
| --- | --- | --- | --- | -------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
x
A L U
|     |     |     |     |     |     |     |     |     |     | Add |     | 1   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
re su l t
|     |     |     | Add |     |     |     |        |     |        |     |     | 0   |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |        |     | Shift  |     | 0   |     |     |     |
|     |     |     |     |     |     |     | RegDst |     | left 2 |     |     |     |     |     |
4
Branch
MemRead
|     |     |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
1
|     |     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |     |                     |     | register 1 | Read   |     |     |     |     |     |     |
| --- | --- | ------- | --- | --- | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- | --- | --- |
|     |     |         |     |     | Instruction [20–16] |     |            | data 1 |     |     |     |     |     |     |
Read
|     |     |          | Instr    | u c t io n  |                     |     | r e g i s t e r  2 |           |     | Z     | e r o   |         |            |     |
| --- | --- | -------- | -------- | ----------- | ------------------- | --- | ------------------ | --------- | --- | ----- | ------- | ------- | ---------- | --- |
|     |     |          |          |             |                     | 0   | R egisters         | R e a d   |     | A LU  | A L U   |         |            |     |
|     |     |          |          | [ 3 1 – 0 ] |                     | M   | W r i t e          | da t a  2 | 0   | r e   | s u l t | Address | R e a d    | 1   |
|     |     | In st ru | c ti o n |             |                     | u   | r e g i s te r     |           | M   |       |         |         | d a t a    |     |
|     |     | m e      | m o r y  |             |                     |     |                    |           | u   |       |         |         |            | M   |
|     |     |          |          |             | Instruction [15–11] | x   | W r i t e          |           | x   |       |         |         |            | u   |
|     |     |          |          |             |                     | 1   | d a t a            |           |     | a d d |         |         | D a t a    | x   |
|     |     |          |          |             |                     |     |                    |           | 1   |       |         |         | m e m o ry | 0   |
Write
data
| In lw we use GPR[Rs] + sext(imm) |     |     |     |     |                    |     |     | 16 32  |     |     |     |     |     |     |
| -------------------------------- | --- | --- | --- | --- | ------------------ | --- | --- | ------ | --- | --- | --- | --- | --- | --- |
|                                  |     |     |     |     | Instruction [15–0] |     |     | Sign   |     |     |     |     |     |     |
|                                  |     |     |     |     |                    |     |     | extend |     |     |     | 1   |     |     |
| Thus, ALUSrc =1                  |     |     |     |     |                    |     |     |        | ALU |     |     |     |     |     |
control
| In lw we must have  ALUSOP =00    (add) |     |     |     |     |     |     | Instruction [5–0] |     |     |     |     |     |     |     |
| --------------------------------------- | --- | --- | --- | --- | --- | --- | ----------------- | --- | --- | --- | --- | --- | --- | --- |
00
MemRead=1 and MemWrite=0
MemToReg=1
Mem
|        | ALU | ALUOp |     | Mem  | Mem   | to  | Reg  | Reg   |        |     | RegDst=0 to select Rt |     |     |     |
| ------ | --- | ----- | --- | ---- | ----- | --- | ---- | ----- | ------ | --- | --------------------- | --- | --- | --- |
| Instr. | Src | [1:0] |     | Read | Write | Reg | Dst  | Write | Branch |     |                       |     |     |     |
RegWrite=1 to write to the GPR
| R-type | 0   | 1   | 0   | 0   | 0   | 0   | 1   | 1   | 0   |     |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Branch=0 so we always get
PC=PC+4
| lw  | 1   | 0     0 |     | 1   | 0   | 1   | 0   | 1   | 0   |     |     |     |     |     |
| --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
sw
|     |     |     |     | 0   | 1   |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
beq
|     |     |     |     | 0   | 0   |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

|     |     |     |     | sw  Rt, imm(Rs)                  |     |     |     |     |     |     | 0   |     | SW  |
| --- | --- | --- | --- | -------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     | M[ GPR[Rs]+sext(imm) ] = GPR[Rt] |     |     |     |     |     |     | M   |     |     |
u
x
A L U
|     |     |     |     |     |     |     |     |     |     | Add | 1   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
re su l t
|     |     |     | Add |     |     |     |        |     |        |     | 0   |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --- | --- |
|     |     |     |     |     |     |     |        |     | Shift  | 0   |     |     |     |
|     |     |     |     |     |     |     | RegDst |     | left 2 |     |     |     |     |
4
Branch
MemRead
|     |     |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
0
|     |     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |     |                     |     | register 1 | Read   |     |     |     | 1   |     |
| --- | --- | ------- | --- | --- | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- | --- |
|     |     |         |     |     | Instruction [20–16] |     |            | data 1 |     |     |     |     |     |
Read
|     |     |          | Instr    | u c t io n  |                     |     | r e g i s t e r  2 |           |     | Z e r o     |         |            |     |
| --- | --- | -------- | -------- | ----------- | ------------------- | --- | ------------------ | --------- | --- | ----------- | ------- | ---------- | --- |
|     |     |          |          |             |                     | 0   | R egisters         | R e a d   |     | A LU A L U  |         |            |     |
|     |     |          |          | [ 3 1 – 0 ] |                     | M   | W r i t e          | da t a  2 | 0   | r e s u l t | Address | R e a d    | 1   |
|     |     | In st ru | c ti o n |             |                     | u   | r e g i s te r     |           | M   |             |         | d a t a    |     |
|     |     | m e      | m o r y  |             |                     |     |                    |           | u   |             |         |            | M   |
|     |     |          |          |             | Instruction [15–11] | x   | W r i t e          |           | x   |             |         |            | u   |
|     |     |          |          |             |                     | 1   | d a t a            |           |     | a d d       |         | D a t a    | x   |
|     |     |          |          |             |                     |     |                    |           | 1   |             |         | m e m o ry | 0   |
Write
data
| In sw we use GPR[Rs] + sext(imm) |     |     |     |     |                    |     |     | 16 32 |     |     |     |     |     |
| -------------------------------- | --- | --- | --- | --- | ------------------ | --- | --- | ----- | --- | --- | --- | --- | --- |
|                                  |     |     |     |     | Instruction [15–0] |     |     | Sign  |     |     |     |     |     |
extend
| Thus, ALUSrc =1 |     |     |     |     |     |     |     |     | ALU |     |     |     |     |
| --------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
control
| In sw we must have  ALUSOP =00    (add) |     |     |     |     |     |     | Instruction [5–0] |     |     |     |     |     |     |
| --------------------------------------- | --- | --- | --- | --- | --- | --- | ----------------- | --- | --- | --- | --- | --- | --- |
00
MemRead=0 and MemWrite=1
MemToReg=X.  We do not write back!
Mem
ALU ALUOp Mem Mem to  Reg  Reg  RegDst=X.  We do not write back!
| Instr. | Src | [1:0] |     | Read | Write | Reg | Dst | Write | Branch |     |     |     |     |
| ------ | --- | ----- | --- | ---- | ----- | --- | --- | ----- | ------ | --- | --- | --- | --- |
RegWrite=0. We do not write back!
| R-type | 0   | 1   | 0   | 0   | 0   | 0   | 1   | 1   | 0   |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Branch=0 so we always get
PC=PC+4
| lw  | 1   | 0        | 0   | 1   | 0   | 1   | 0   | 1   | 0   |     |     |     |     |
| --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sw  | 1   |          |     |     |     |     | X X | 0   |     | 0   |     |     |     |
|     |     | 0      0 |     | 0   | 1   |     |     |     |     |     |     |     |     |
beq
|     |     |     |     | 0   | 0   |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Beq
|     |     |     | If GPR[Rs] == GPR[Rt]  then       |     |     |     |     |     |     | 0   |     |
| --- | --- | --- | --------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC=PC+4+sext(imm)*4; else PC=PC+4 |     |     |     |     |     |     | M   |     |
u
x
A L U
|     |     |     |     |     |     |     |     |     | Add | 1   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
re su l t
|     |     |     | Add |     |     |        |     |        |     | Zero |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | ------ | --- | ---- | --- |
|     |     |     |     |     |     |        |     | Shift  | 1   |      |     |
|     |     |     |     |     |     | RegDst |     | left 2 |     |      |     |
4
Branch
| Zero=1 if  |     |     |     |                     |     | MemRead  |     |     |     |     |     |
| ---------- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- | --- |
| ALU output |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |     |
Control
| is 000…000 |     |     |     |     |     | ALUOp |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- |
MemWrite
else Zero=0
ALUSrc
RegWrite
0
|     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |                     |     | register 1 | Read   |     |     |     |     |
| --- | --- | ------- | --- | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- |
|     |     |         |     | Instruction [20–16] |     |            | data 1 |     |     |     |     |
Read
|     |     |          | Instr u c t io n |                     |     | r e g i s t e r  2 |           |     | Z e r o Zero        |            |     |
| --- | --- | -------- | ---------------- | ------------------- | --- | ------------------ | --------- | --- | ------------------- | ---------- | --- |
|     |     |          |                  |                     | 0   | R egisters         | R e a d   |     | A LU A L U          |            |     |
|     |     |          | [ 3 1 – 0 ]      |                     | M   | W r i t e          | da t a  2 | 0   | r e s u l t Address | R e a d    | 1   |
|     |     | In st ru | c ti o n         |                     | u   | r e g i s te r     |           | M   |                     | d a t a    |     |
|     |     | m e      | m o r y          |                     |     |                    |           | u   |                     |            | M   |
|     |     |          |                  | Instruction [15–11] | x   | W r i t e          |           | x   |                     |            | u   |
|     |     |          |                  |                     | 1   | d a t a            |           |     | s u b               | D a t a    | x   |
|     |     |          |                  |                     |     |                    |           | 1   |                     | m e m o ry | 0   |
Write
data
| In beq we use GPR[Rs] - GPR[Rt] |     |     |     |                    |     |     | 16 32 |     |     |     |     |
| ------------------------------- | --- | --- | --- | ------------------ | --- | --- | ----- | --- | --- | --- | --- |
|                                 |     |     |     | Instruction [15–0] |     |     | Sign  |     |     |     |     |
extend
| Thus, ALUSrc =0 |     |     |     |     |     |     |     | ALU |     |     |     |
| --------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
control
| In be we subtract  so ALUSOP =01    (sub) |     |     |     |     |     | Instruction [5–0] |     |     |     |     |     |
| ----------------------------------------- | --- | --- | --- | --- | --- | ----------------- | --- | --- | --- | --- | --- |
01
MemRead=0 and MemWrite=0
MemToReg=X.  We do not write back!
Mem
ALU ALUOp Mem Mem to  Reg  Reg  RegDst= X.  We do not write back!
| Instr. | Src | [1:0] | Read | Write | Reg | Dst | Write | Branch |     |     |     |
| ------ | --- | ----- | ---- | ----- | --- | --- | ----- | ------ | --- | --- | --- |
RegWrite=0   We do not write back!
| R-type | 0   | 1   | 0 0 | 0   | 0   | 1   | 1   | 0   |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Branch=1 so we check Zero to
decide whether to
| lw  | 1   | 0   | 0 1 | 0   | 1   | 0   | 1   | 0   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
branch (PC= branch target)
| sw  | 1   | 0   | 0 0 | 1   | X   | X   | 0   | 0   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
or not to branch (PC=PC+4)
| beq | 0   | 0      1 | 0   | 0   | X   | X   | 0   | 1   |     |     |     |
| --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

0
M
u
x
A L U
|     |     |     |     |     |     |     |     |     | Add 1 |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- |
re su l t
Add
Shift
|     |     |     |     |     |     | RegDst |     | left 2 |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --- |
4
Branch
MemRead
|     |     |     |     | Instruction [31–26] |     | MemtoReg |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | -------- | --- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
|     |     |     |     | Instruction [25–21] |     | Read |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | ---- | --- | --- | --- | --- | --- |
R e a d
|     | PC  | a d d r | ess |                     |     | register 1 | Read   |     |     |     |     |
| --- | --- | ------- | --- | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- |
|     |     |         |     | Instruction [20–16] |     |            | data 1 |     |     |     |     |
Read
|     |     |          | Instr u c t io n |                     |     | r e g i s t e r  2 |           |     | Z e r o            |             |     |
| --- | --- | -------- | ---------------- | ------------------- | --- | ------------------ | --------- | --- | ------------------ | ----------- | --- |
|     |     |          |                  |                     | 0   | R egisters         | R e a d   |     | ALU A L U          |             |     |
|     |     |          | [ 3 1 – 0 ]      |                     | M   | W r i t e          | da t a  2 | 0   | re s u l t Address | R de a      | 1   |
|     |     | In st ru | c ti o n         |                     | u   | r e g i s te r     |           | M   |                    | da a t      |     |
|     |     | m e      | m o r y          |                     |     |                    |           | u   |                    |             | M   |
|     |     |          |                  | Instruction [15–11] | x   | W r i t e          |           | x   |                    |             | u   |
|     |     |          |                  |                     | 1   | d a t a            |           |     |                    | D a t a     | x   |
|     |     |          |                  |                     |     |                    |           | 1   |                    | m e m o r y | 0   |
Write
data
|     |     |     |     |                    |     |     | 16 32 |     |     |     |     |
| --- | --- | --- | --- | ------------------ | --- | --- | ----- | --- | --- | --- | --- |
|     |     |     |     | Instruction [15–0] |     |     | Sign  |     |     |     |     |
extend
ALU
control
Instruction [5–0]
So the final Control Decoder is as follows:
Mem
|        | ALU | ALUOp | Mem  | Mem   | to  | Reg  | Reg   |        |     |     |     |
| ------ | --- | ----- | ---- | ----- | --- | ---- | ----- | ------ | --- | --- | --- |
| Instr. | Src | [1:0] | Read | Write | Reg | Dst  | Write | Branch |     |     |     |
| R-type | 0   | 1     | 0 0  | 0     | 0   | 1    | 1     | 0      |     |     |     |
| lw     | 1   | 0     | 0 1  | 0     | 1   | 0    | 1     | 0      |     |     |     |
| sw     | 1   | 0     | 0 0  | 1     | X   | X    | 0     | 0      |     |     |     |
| beq    | 0   | 0     | 1 0  | 0     | X   | X    | 0     | 1      |     |     |     |

Inputs
Op5
| Op4 |     |     | Control Decoder |     |     |     |     |
| --- | --- | --- | --------------- | --- | --- | --- | --- |
Op3
Op2
Op1
Op0
Outputs
| R-format | Iw  | sw beq |     |     |     |     |     |
| -------- | --- | ------ | --- | --- | --- | --- | --- |
RegDst
ALUSrc
MemtoReg
RegWrite
MemRead
MemWrite
Branch
ALUOp1
ALUOpO
Mem
|        | ALU | ALUOp | Mem  | Mem   | to  | Reg  Reg  |        |
| ------ | --- | ----- | ---- | ----- | --- | --------- | ------ |
| Instr. | Src | [1:0] | Read | Write | Reg | Dst Write | Branch |
| R-type | 0   | 1 0   | 0    | 0     | 0   | 1 1       | 0      |
| lw     | 1   | 0 0   | 1    | 0     | 1   | 0 1       | 0      |
| sw     | 1   | 0 0   | 0    | 1     | X   | X 0       | 0      |
| beq    | 0   | 0 1   | 0    | 0     | X   | X 0       | 1      |

datapath -ה לע םיטלושש הרקבה תותוא לע ינד לש םיפקשה םויס

Single-Cycle Hardwired Control
 As combinational function of Inst=MEM[PC]
| 31     | 26        | 21    | 16        | 11    | 6     | 0   |        |
| ------ | --------- | ----- | --------- | ----- | ----- | --- | ------ |
| 0      | rs        | rt    | rd        | shamt | funct |     | R-type |
| 6-bit  | 5-bit     | 5-bit | 5-bit     | 5-bit | 6-bit |     |        |
| 31     | 26        | 21    | 16        |       |       | 0   |        |
| opcode | rs        | rt    | immediate |       |       |     | I-type |
| 6-bit  | 5-bit     | 5-bit | 16-bit    |       |       |     |        |
| 31     | 26        |       |           |       |       | 0   |        |
| opcode | immediate |       |           |       |       |     | J-type |
| 6-bit  | 26-bit    |       |           |       |       |     |        |
 Consider – םצמוצמ טס
 All R-type and I-type ALU instructions
 LW and SW
 BEQ, BNE, BLEZ, BGTZ
 J, JR, JAL, JALR 87

Putting It All Together
|     |     |     |     |     |     |     |     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------- | --- |
1
|     |     | Instruction [25–0] |     | Shift |     | Jump address [31–0] |     |     |     |     |     |     |     |
| --- | --- | ------------------ | --- | ----- | --- | ------------------- | --- | --- | --- | --- | --- | --- | --- |
left 2
|     |     |     |     | 26  | 28  |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |     |     | M   | M   |
PC+4 [31–28]
|     |     |     |     |     |     |     |     |     |     |         |     | u   | u   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |         |     | x   | x   |
|     |     |     |     |     |     |     |     |     |     | Add ALU |     | 1   | 0   |
result
|     |     | Add |     |     |     | RegDst |     |     | Shift |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | --- | ------ | --- | --- | ----- | --- | --- | ----- | --------- |
2
|     |     |     |     |     |     | Jump |     |     | left 2 |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | --- | ------ | --- | --- | --- | --- |
4
Branch
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
RegWrite
Instruction [25–21]
Read
| PC  | R e a d    |     |                     |     |     | register 1 |     |        |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | --- | ---------- | --- | ------ | --- | --- | --- | --- | --- |
|     | ad d r ess |     |                     |     |     |            |     | Read   |     |     |     |     |     |
|     |            |     | Instruction [20–16] |     |     | Read       |     | data 1 |     |     |     |     |     |
bZcoenrdo
|     |          | Instruction |                     |     |     | register 2   |           |           |     |           |         |      |        |
| --- | -------- | ----------- | ------------------- | --- | --- | ------------ | --------- | --------- | --- | --------- | ------- | ---- | ------ |
|     |          |             |                     |     | 0   |              | Registers | R e a d   |     | ALU A L U |         |      |        |
|     |          | [31–0]      |                     |     |     | Write        |           |           | 0   |           |         |      | Read   |
|     |          |             |                     |     | M   |              |           | da t a  2 |     | re su l t | Address |      | data 1 |
|     | In st ru | c ti o n    |                     |     | u   | r eg i s ter |           |           | M   |           |         |      | M      |
|     | m e m    | o r y       |                     |     | x   |              |           |           | u   |           |         |      | u      |
|     |          |             | Instruction [15–11] |     |     | W ri t e     |           |           | x   |           |         |      |        |
|     |          |             |                     |     | 1   | data         |           |           |     |           |         | D at | a x    |
|     |          |             |                     |     |     |              |           |           | 1   |           |         | m em | o ry 0 |
Write
data
|     |     |     | Instruction [15–0] |     |     |     | 16  | 32  |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign
|     |     |     |     |     |     |     |     | extend |     | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------------- | --- | --- | --- |
ALU
control
Instruction [5–0]
88
**Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL
JAL, JR, JALR omitted
RIGHTS RESERVED.]

Single-Bit Control Signals
When De-asserted When asserted Equation
RegDest GPR write select
GPR write select according
according opcode==0
to rd, i.e., inst[15:11]
to rt, i.e., inst[20:16]
ALUSrc 2nd ALU input from sign- (opcode!=0) &&
2nd ALU input from 2nd GPR extended 16-bit
(opcode!=BEQ) &&
read port
immediate
(opcode!=BNE)
MemtoReg
Steer ALU result to GPR Steer memory load to GPR
opcode==LW
write port wr. port
(opcode!=SW) &&
(opcode!=Bxx) &&
(opcode!=J) &&
RegWrite
(opcode!=JR))
GPR write disabled GPR write enabled
89
JAL and JALR require additional RegDest and MemtoReg options

Single-Bit Control Signals
|     | When De-asserted | When asserted | Equation |
| --- | ---------------- | ------------- | -------- |
Memory read port return opcode==LW
| MemRead | Memory read disabled |     |     |
| ------- | -------------------- | --- | --- |
 load value
opcode==SW
| MemWrite | Memory write disabled | Memory write enabled |     |
| -------- | --------------------- | -------------------- | --- |
next PC is based on 26-bit
(opcode==J) ||
| PCSrc | According to PCSrc |     |     |
| ----- | ------------------ | --- | --- |
 immediate jump target (opcode==JAL)
1 2
next PC is based on 16-bit
next PC = PC + 4 (opcode==Bxx) &&
PCSrc
 immediate branch target “bcond is satisfied”
2
90
JR and JALR require additional PCSrc options

| ALU Control   |        | ALUOp |          |
| ------------- | ------ | ----- | -------- |
|               | Instr. | [1:0] |          |
|               | R-type | 1 0   |          |
|  case opcode | lw     | 0 0   | 00 = Add |
ALUOP 01= Sub
R-type: ‘0’  select operation according to funct sw 0 0 10 = Funct.
|     | beq | 0 1 |     |
| --- | --- | --- | --- |
‘ALUi’  selection operation according to opcode
Funct. ALU
control
‘LW’  select addition
‘SW’  select addition
‘Bxx’  select bcond generation function
ALU CMD
 other inst.   don’t care
MIPS ALU CMDs
ALU CMD
|  Example of ALU CMD  (operations) | ALU CMD |     |     |
| ---------------------------------- | ------- | --- | --- |
ALU CMD
 ADD, SUB, AND, OR, XOR, NOR, etc.
bcond on equal, not equal, LE zero, GT zero, etc.

Taken from:
91

R-Type ALU
|     |     |                    |       |     |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |       |     | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] | Shift |     |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
RegWrite
1
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     | 0   |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     |     |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | u      |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | fuALnU | ct ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | ------ | ---------------- | --- | --- | --- |
control
Instruction [5–0]
92
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

I-Type ALU
|     |     |                    |       |     |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |       |     | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] | Shift |     |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 1    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 0   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     |     |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | u      |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | opAcLUode | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --------- | ------------- | --- | --- | --- |
control
Instruction [5–0]
93
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

LW
|     |     |                    |       |     |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |       |     | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] | Shift |     |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 1    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 0   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     |     |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | u      |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
1
|     |     |     |     |     |     | extend | AALdUd | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | ------ | ------------- | --- | --- | --- |
control
Instruction [5–0]
94
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

SW
|     |     |                    |     |       |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | --- | ----- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |     |       | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] |     | Shift |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
|     |     |     |     | Control | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | --- | --- |
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 0    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 1   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | Xu  | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     |     |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | X u    |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | AALdUd | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | ------ | ------------- | --- | --- | --- |
control
Instruction [5–0]
95
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Branch (Not Taken)
Some control signals are dependent
on the processing of data
|     |     |                    |     |       |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | --- | ----- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |     |       | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] |     | Shift |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
|     |     |     |     | Control | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | --- | --- |
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 0    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 0   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     | X   |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | X u    |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | bcALoUnd | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | ------------- | --- | --- | --- |
control
Instruction [5–0]
96
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Branch (Taken)
Some control signals are dependent
on the processing of data
|     |     |                    |     |       |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | --- | ----- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |     |       | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] |     | Shift |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
|     |     |     |     | Control | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | --- | --- |
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 0    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 0   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     | X   |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |      | X u    |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | bcALoUnd | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | ------------- | --- | --- | --- |
control
Instruction [5–0]
97
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Jump
|     |     |                    |     |       |                     |     |     |     |     | PCSrc =Jump |     |
| --- | --- | ------------------ | --- | ----- | ------------------- | --- | --- | --- | --- | ----------- | --- |
|     |     |                    |     |       | Jump address [31–0] |     |     |     |     | 1           |     |
|     |     | Instruction [25–0] |     | Shift |                     |     |     |     |     |             |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     |     | 0   | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | Xx  | x   |
ALU
|     |     |     |     |     |     |     |     | Add result |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
|     |     |     |     | Control | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | --- | --- |
ALUOp
MemWrite
ALUSrc
|     |            |     |                     |     | RegWrite   | 0    |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     | 0   |     |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |      |        |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | ---- | ------ |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address |      | Read 1 |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         |      | data   |
|     |                   |        |                     | X   |              |           | u   |           |         |      | M      |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           | X   |           |         |      | X u    |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at | a x    |
|     |                   |        |                     |     | data         |           | 1   |           |         |      |        |
|     |                   |        |                     |     |              |           |     |           |         | m em | o ry 0 |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ---- | --- | --- | --- | --- | --- |
0
|     |     |     |     |     |     | extend | ALU | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | --- | ------------- | --- | --- | --- |
X
control
Instruction [5–0]
98
**Based on original figure from [P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

What is in That Control Box?
 Combinational Logic  Hardwired Control
 Idea: Control signals generated combinationally based on instruction
 Necessary in a single-cycle microarchitecture…
 Sequential Logic  Sequential/Microprogrammed Control
 Idea: A memory structure contains the control signals associated with an instruction
 Control Store
!תדרפנ תגצמב רבסוי
99

Evaluating the Single-Cycle
Microarchitecture
100

A Single-Cycle Microarchitecture
 Is this a good idea/design?
 When is this a good design?
הבשחמל רמוח
 When is this a bad design?
 How can we design a better microarchitecture?
101

A Single-Cycle Microarchitecture: Analysis
 Every instruction takes 1 cycle to execute
 CPI (Cycles per instruction) is strictly 1
 How long each instruction takes is determined by how long the slowest instruction
takes to execute
 Even though many instructions do not need that long to execute
 Clock cycle time of the microarchitecture is determined by how long it takes to
complete the slowest instruction
 Critical path of the design is determined by the processing time of the slowest instruction
102

What is the Slowest Instruction to Process?
 Let’s go back to the basics
 All six phases of the instruction processing cycle take a single machine clock cycle to complete
 Fetch
 Decode 1. Instruction fetch (IF)
 Evaluate Address 2. Instruction decode and
 Fetch Operands register operand fetch (ID/RF)
םיפממ
 Execute 3. Execute/Evaluate memory address (EX/AG)
ןימימ םיבלשל
 Store Result 4. Memory operand fetch (MEM)
5. Store/writeback result (WB)
 Do each of the above phases take the same time (latency) for all instructions?
וללה םיבלשה לכל קקדזת רתויב תיטיאה הדוקפהש ריבס
103

Single-Cycle Datapath Analysis - המגוד
 Assume – המגוד קר יהוז
memory units (read or write): 200 ps

 ALU and adders: 100 ps
 register file (read or write): 50 ps
 other combinational logic: 0 ps
| steps | IF  | ID  | EX  | MEM | WB  |     |     |
| ----- | --- | --- | --- | --- | --- | --- | --- |
Delay
| resources | mem | RF  | ALU | mem | RF  |     |     |
| --------- | --- | --- | --- | --- | --- | --- | --- |
| R-type    | 200 | 50  | 100 |     | 50  | 400 |     |
| I-type    | 200 | 50  | 100 |     | 50  | 400 |     |
| LW        | 200 | 50  | 100 | 200 | 50  | 600 |     |
| SW        | 200 | 50  | 100 | 200 |     | 550 |     |
| Branch    | 200 | 50  | 100 |     |     | 350 |     |
| Jump      | 200 |     |     |     |     | 200 | 104 |

Let’s Find the Critical Path
|     |     |                    |       |                     |     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | ------------------- | --- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       | Jump address [31–0] |     |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |                     |     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M M |     |
|     |     |     |              |     |     |     |     |     |     | u u |     |
|     |     |     |              |     |     |     |     |     |     | x x |     |
ALU
|     |     |     |     |     |     |     |     | Add result | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --------------- | --- |
|     |     |     |     |     | Jump   |     | left 2 |     |     | 2               |     |
|     | 4   |     |     |     | Branch |     |        |     |     |                 |     |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
ALUSrc
RegWrite
|     |            |     | Instruction [25–21] |     | Read       |      |     |     |     |     |     |
| --- | ---------- | --- | ------------------- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
|     | R e a d    |     |                     |     | register 1 |      |     |     |     |     |     |
| PC  | ad d r ess |     |                     |     |            | Read |     |     |     |     |     |
data 1
|     |     |     | Instruction [20–16] |     | Read       |     |     |           |     |     |     |
| --- | --- | --- | ------------------- | --- | ---------- | --- | --- | --------- | --- | --- | --- |
|     |     |     |                     |     | register 2 |     |     | bcZoenrdo |     |     |     |
Instruction
|     |                   | [31–0] |                     | 0   | Registers    | R e a d   |     | ALU A L U |         |           |     |
| --- | ----------------- | ------ | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | --------- | --- |
|     |                   |        |                     | M   | Write        | da t a  2 | 0   | re su l t | Address | Read      | 1   |
|     | In st ru c ti o n |        |                     | u   | r eg i s ter |           | M   |           |         | data      |     |
|     |                   |        |                     |     |              |           | u   |           |         |           | M   |
|     | m e m o r y       |        | Instruction [15–11] | x   |              |           |     |           |         |           | u   |
|     |                   |        |                     | 1   | W ri t e     |           | x   |           |         | D at a    | x   |
|     |                   |        |                     |     | data         |           | 1   |           |         |           |     |
|     |                   |        |                     |     |              |           |     |           |         | m em o ry | 0   |
Write
data
|     |     |     |                    |     | 16  | 32     |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
105
[Based on original figure from P&H CO&D, COPYRIGHT 2004 Elsevier.
ALL RIGHTS RESERVED.]

R-Type and I-Type ALU → critical path
|     |     |                    |       |     |                     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       |     | Jump address [31–0] |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |     |                     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     | M   | M   |     |
|     |     |     |              |     |     |     |     |     |     | u u |     |
|     |     |     |              |     |     |     |     |     |     | x x |     |
ALU
|     |     |     |     |     |     |     |     | Add result | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
100ps
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --------------- | --- |
|     |     |     |     |     | Jump   |     | left 2 |     |     | 2               |     |
|     | 4   |     |     |     | Branch |     |        |     |     |                 |     |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
100ps
ALUSrc
RegWrite
|     |            |                          | Instruction [25–21] |     | Read          |           |     |           |         |           |     |
| --- | ---------- | ------------------------ | ------------------- | --- | ------------- | --------- | --- | --------- | ------- | --------- | --- |
|     | R e a d    |                          |                     |     | register 1    |           |     |           |         |           |     |
| PC  | ad d r ess |                          |                     |     |               | Read      |     |           |         |           |     |
|     |            | 200psInstruction [20–16] |                     |     |               | data 1    |     |           |         |           |     |
|     |            |                          |                     |     | R e a d       | 250ps     |     |           |         |           |     |
|     |            |                          |                     |     | re g is ter 2 |           |     | bZcoenrdo |         |           |     |
|     |            | Instruction              |                     | 0   |               | Registers |     | ALU       |         |           |     |
|     |            | [31–0]                   |                     |     |               | R e a d   | 0   | A L U     |         | Read      |     |
|     |            |                          |                     | M   | Write         | da t a  2 |     | re su l t | Address |           | 1   |
|     | In st ru c | ti o n                   |                     | u   | r eg i s ter  |           | M   |           |         | data      |     |
|     | m e m      | o r y                    |                     |     |               | 400ps     | u   |           |         |           | M   |
|     |            |                          | Instruction [15–11] | x   |               |           |     |           |         |           | u   |
|     |            |                          |                     | 1   | W ri t e      |           | x   | 350ps     |         | D at a    | x   |
|     |            |                          |                     |     | data          |           | 1   |           |         |           |     |
|     |            |                          |                     |     |               |           |     |           |         | m em o ry | 0   |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
106
[Based on original figure from P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

LW
|     |     |                    |       |                     |     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | ------------------- | --- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       | Jump address [31–0] |     |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |                     |     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     | 0   |     | 1   |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     | M   |     | M   |
|     |     |     |              |     |     |     |     |     |     | u   | u   |
|     |     |     |              |     |     |     |     |     |     | x   | x   |
ALU
|     |     |     |     |     |     |     |     | Add result | 1   |     | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
100ps
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc | =Br Taken |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | ----- | --------- |
|     |     |     |     |     | Jump   |     | left 2 |     |     |       | 2         |
|     | 4   |     |     |     | Branch |     |        |     |     |       |           |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
MemWrite
100ps
ALUSrc
RegWrite
|     |            |                          | Instruction [25–21] |             | Read          |           |     |           |         |        |         |
| --- | ---------- | ------------------------ | ------------------- | ----------- | ------------- | --------- | --- | --------- | ------- | ------ | ------- |
|     | R e a d    |                          |                     |             | register 1    |           |     |           |         |        |         |
| PC  | ad d r ess |                          |                     |             |               | Read      |     |           |         |        |         |
|     |            | 200psInstruction [20–16] |                     |             |               | data 1    |     |           |         |        |         |
|     |            |                          |                     |             | R e a d       | 250ps     |     |           |         |        |         |
|     |            |                          |                     |             | re g is ter 2 |           |     | bZcoenrdo |         |        |         |
|     |            | Instruction              |                     | 0           | Registers     |           |     | ALU       |         |        |         |
|     |            | [31–0]                   |                     |             |               | R e a d   | 0   | A L U     |         | R      | e a d   |
|     |            |                          |                     | M           | W r i t e     | da t a  2 |     | re su l t | Address |        | 551 0ps |
|     | In st ru c | ti o n                   |                     | u           | r eg i s ter  |           | M   |           |         | d      | a ta    |
|     | m e m      | o r y                    |                     |             |               |           | u   |           |         |        | M       |
|     |            |                          | Instruction [15–11] | x           |               |           |     |           |         |        | u       |
|     |            |                          |                     | 1 60data0ps | W r i t e     |           | x   | 350ps     |         | D at a | x       |
1
|     |     |     |     |     |     |     |     |     |     | m em o ry | 0   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | --- |
Write
data
|     |     |     |                    |     | 16  | 32     |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
107
[Based on original figure from P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

SW
|     |     |                    |       |     |                     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | --- | ------------------- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       |     | Jump address [31–0] |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |     |                     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     | M   | M   |     |
|     |     |     |              |     |     |     |     |     |     | u u |     |
|     |     |     |              |     |     |     |     |     |     | x x |     |
ALU
|     |     |     |     |     |     |     |     | Add result | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
100ps
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --------------- | --- |
|     |     |     |     |     | Jump   |     | left 2 |     |     | 2               |     |
|     | 4   |     |     |     | Branch |     |        |     |     |                 |     |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
100ps MemWrite
ALUSrc
RegWrite
|     |            |                          | Instruction [25–21] |     | Read          |           |     |           |         |         |     |
| --- | ---------- | ------------------------ | ------------------- | --- | ------------- | --------- | --- | --------- | ------- | ------- | --- |
|     | R e a d    |                          |                     |     | register 1    |           |     |           |         |         |     |
| PC  | ad d r ess |                          |                     |     |               | Read      |     |           |         |         |     |
|     |            | 200psInstruction [20–16] |                     |     |               | data 1    |     |           |         |         |     |
|     |            |                          |                     |     | R e a d       | 250ps     |     |           |         |         |     |
|     |            |                          |                     |     | re g is ter 2 |           |     | bZcoenrdo |         |         |     |
|     |            | Instruction              |                     | 0   | Registers     |           |     | ALU       |         |         |     |
|     |            | [31–0]                   |                     |     |               | R e a d   | 0   | A L U     |         |         |     |
|     |            |                          |                     | M   | Write         | da t a  2 |     | re su l t | Address | Read    | 1   |
|     | In st ru c | ti o n                   |                     | u   | r eg i s ter  |           | M   |           |         | data    |     |
|     | m e m      | o r y                    |                     |     |               |           | u   |           |         |         | M   |
|     |            |                          | Instruction [15–11] | x   |               |           |     |           |         |         | u   |
|     |            |                          |                     | 1   | W ri t e      |           | x   | 350ps     |         | D at a  | x   |
|     |            |                          |                     |     | data          |           | 1   |           | 550m    | epm sry |     |
|     |            |                          |                     |     |               |           |     |           |         | o       | 0   |
Write
data
16 32
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
108
[Based on original figure from P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Branch Taken
|     |     |                    |       |                     |     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | ------------------- | --- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       | Jump address [31–0] |     |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |                     |     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |       | 0   | 1   |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | ----- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |       | M   | M   |     |
|     |     |     |              |     |     |     |     | 200ps |     | u u |     |
|     |     |     |              |     |     |     |     |       |     | x x |     |
100ps
ALU
|     |     |     |     |     |     |     |     | Add result | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --------------- | --- |
|     |     |     |     |     | Jump   |     | left 2 |     |     | 2               |     |
|     | 4   |     |     |     | Branch |     |        |     |     |                 |     |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
| 350ps |     |     |     |     | MemWrite |     |     |     |     |     |     |
| ----- | --- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- |
ALUSrc
RegWrite
350ps
|     |            |                          | Instruction [25–21] |     | Read          |           |     |           |         |           |     |
| --- | ---------- | ------------------------ | ------------------- | --- | ------------- | --------- | --- | --------- | ------- | --------- | --- |
|     | R e a d    |                          |                     |     | register 1    |           |     |           |         |           |     |
| PC  | ad d r ess |                          |                     |     |               | Read      |     |           |         |           |     |
|     |            | 200psInstruction [20–16] |                     |     |               | data 1    |     |           |         |           |     |
|     |            |                          |                     |     | R e a d       | 250ps     |     |           |         |           |     |
|     |            |                          |                     |     | re g is ter 2 |           |     | bZcoenrdo |         |           |     |
|     |            | Instruction              |                     | 0   | Registers     |           |     | ALU       |         |           |     |
|     |            | [31–0]                   |                     |     |               | R e a d   | 0   | A L U     |         | Read      |     |
|     |            |                          |                     | M   | Write         | da t a  2 |     | re su l t | Address |           | 1   |
|     | In st ru c | ti o n                   |                     | u   | r eg i s ter  |           | M   |           |         | data      |     |
|     | m e m      | o r y                    |                     |     |               |           | u   |           |         |           | M   |
|     |            |                          | Instruction [15–11] | x   |               |           |     |           |         |           | u   |
|     |            |                          |                     | 1   | W ri t e      |           | x   |           |         | D at a    | x   |
|     |            |                          |                     |     | data          |           | 1   |           |         |           |     |
|     |            |                          |                     |     |               |           |     |           |         | m em o ry | 0   |
Write
data
|     |     |     |                    |     | 16  | 32     |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
109
[Based on original figure from P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

Jump
|     |     |                    |       |                     |     |     |     |     | PCSrc | =Jump |     |
| --- | --- | ------------------ | ----- | ------------------- | --- | --- | --- | --- | ----- | ----- | --- |
|     |     |                    |       | Jump address [31–0] |     |     |     |     |       | 1     |     |
|     |     | Instruction [25–0] | Shift |                     |     |     |     |     |       |       |     |
left 2
26 28
|     |     |     |              |     |     |     |     |     | 0   | 1   |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | PC+4 [31–28] |     |     |     |     |     | M   | M   |     |
|     |     |     |              |     |     |     |     |     |     | u u |     |
|     |     |     |              |     |     |     |     |     |     | x x |     |
100ps
ALU
|     |     |     |     |     |     |     |     | Add result | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- |
Add
|     |     |     |     |     | RegDst |     | Shift  |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | ------ | --- | ------ | --- | --- | --------------- | --- |
|     |     |     |     |     | Jump   |     | left 2 |     |     | 2               |     |
|     | 4   |     |     |     | Branch |     |        |     |     |                 |     |
MemRead
Instruction [31–26]
Control MemtoReg
ALUOp
| 200ps |     |     |     |     | MemWrite |     |     |     |     |     |     |
| ----- | --- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- |
ALUSrc
RegWrite
|     |            |                          | Instruction [25–21] |     | Read       |        |     |     |     |     |     |
| --- | ---------- | ------------------------ | ------------------- | --- | ---------- | ------ | --- | --- | --- | --- | --- |
|     | R e a d    |                          |                     |     | register 1 |        |     |     |     |     |     |
| PC  | ad d r ess |                          |                     |     |            | Read   |     |     |     |     |     |
|     |            | 200psInstruction [20–16] |                     |     |            | data 1 |     |     |     |     |     |
Read
|     |            |             |                     |     | register 2   |           |     | bZcoenrdo |         |           |     |
| --- | ---------- | ----------- | ------------------- | --- | ------------ | --------- | --- | --------- | ------- | --------- | --- |
|     |            | Instruction |                     | 0   | Registers    |           |     | ALU       |         |           |     |
|     |            | [31–0]      |                     |     |              | R e a d   | 0   | A L U     |         | Read      |     |
|     |            |             |                     | M   | Write        | da t a  2 |     | re su l t | Address |           | 1   |
|     | In st ru c | ti o n      |                     | u   | r eg i s ter |           | M   |           |         | data      |     |
|     | m e m      | o r y       |                     |     |              |           | u   |           |         |           | M   |
|     |            |             | Instruction [15–11] | x   |              |           |     |           |         |           | u   |
|     |            |             |                     | 1   | W ri t e     |           | x   |           |         | D at a    | x   |
|     |            |             |                     |     | data         |           | 1   |           |         |           |     |
|     |            |             |                     |     |              |           |     |           |         | m em o ry | 0   |
Write
data
|     |     |     |                    |     | 16  | 32     |     |               |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | ------ | --- | ------------- | --- | --- | --- |
|     |     |     | Instruction [15–0] |     |     | Sign   |     |               |     |     |     |
|     |     |     |                    |     |     | extend | ALU | ALU operation |     |     |     |
control
Instruction [5–0]
110
[Based on original figure from P&H CO&D, COPYRIGHT 2004
Elsevier. ALL RIGHTS RESERVED.]

datapath -ה ללגב קר םיבוכיע ונחנה וישכע דע
What About Control Logic?
?הרקבה לש דצב םיבוכיע םע הרוק המ
 How does that affect the critical path?
 Food for thought for you:
 Can control logic be on the critical path? (*)
 A note on CDC 5600: control store access too long…(**)
תורצונו םינותנב םייולת הרקבה תותוא .Branch Takenרובע םיפקש 2 ינפל ואר .ןכ טלחהב )*(
ביתנה לע םיאצמנ cache hit/miss -ב םירושקש הרקבה תותוא :תפסונ המגוד .תויהשה
.יטירקה
רבגתהל ידכ pipeline -ה תא ורציק םה .CDC -ב ישארה סדנהמה היה Seymour Cray )**( 
ךוראה השיגה ןמז תייעב לע
111

What is the Slowest Instruction to Process?
:איג
 Memory is not magic
 What if memory sometimes takes 100ms to access?
"magic"
memory
 Does it make sense to have a simple register to register add or jump to take {100ms+all
else to do a memory operation}?
 And, what if you need to access memory more than once to process an instruction?
 Which instructions need this?
 Do you provide multiple ports to memory?
112

Single Cycle μArch: Complexity
 Contrived (=םיקסעומ)
 All instructions run as slow as the slowest instruction
 Inefficient
 All instructions run as slow as the slowest instruction
 Need to replicate a resource if it is needed more than once by an instruction during different parts
of the instruction processing cycle
 Not necessarily the simplest way to implement an ISA
 Single-cycle implementation of REP MOVS (x86) or INDEX (VAX)?
 Not easy to optimize/improve performance
 Optimizing the common case does not work (e.g. common instructions)
 Need to optimize the worst case all the time
113

(Micro)architecture Design Principles
 Critical path design (Guy: optimize for performance)
לש היצזימיטפואל ןוצרה תורמל
 Find and decrease the maximum combinational logic delay לכונש ידכ יטירקה ביתנה
דימת אל ,רדתה תא תולעהל
 Break a path into multiple cycles if it takes too long
קפסהה תכירצ ללגב יוצר רבדה
 Bread and butter (common case) design
 Spend time and resources on where it matters most
 i.e., improve what the machine is really designed to do
 Common case vs. uncommon case
 Balanced design P is proportional to f^3
 Balance instruction/data flow through hardware components
 Design to eliminate bottlenecks: balance the hardware for the work
114

Single-Cycle Design vs. Design Principles
 Critical path design
 Bread and butter (common case) design
 Balanced design
How does a single-cycle microarchitecture fare in light of these principles?
115

Aside: System Design Principles
 When designing computer systems/architectures, it is important to follow good
principles
 Remember: “principled design” from our first lecture(*)
 Frank Lloyd Wright: “architecture […] based upon principle, and not upon precedent”
אבה ףקשה ואר .…טייר דיול קרפ לע ונגליד הנשה )*(
Guy: Patterson and Hennessy design principles:
(1) Simplicity favors regularity;
(2) Make the common case fast;
(3) Smaller is faster;
(4) Good design demands good compromises;
116

Aside: From Lecture 1
 “architecture […] based upon principle, and not upon precedent”
117

Aside: System Design Principles
 We will continue to cover key principles in this course
 Here are some references where you can learn more
 Yale Patt, “Requirements, Bottlenecks, and Good Fortune: Agents for Microprocessor
Evolution,” Proc. of IEEE, 2001. (Levels of transformation, design point, etc)
 Mike Flynn, “Very High-Speed Computing Systems,” Proc. of IEEE, 1966. (Flynn’s
Bottleneck  Balanced design)
 Gene M. Amdahl, "Validity of the single processor approach to achieving large scale
computing capabilities", AFIPS Conference, April 1967. (Amdahl’s Law  Common-
case design)
 Butler W. Lampson, “Hints for Computer System Design,” ACM Operating Systems
Review, 1983.
 http://research.microsoft.com/pubs/68221/acrobat.pdf
118

Aside: One Important Principle
 Keep it simple
 “Everything should be made as simple as possible, but no simpler.”
 Albert Einstein
 And, do not forget: “An engineer is a person who can do for a dime what any fool can
do for a dollar.”
:קיודמה טוטיצה
“An engineer can do for a dollar
what any fool can do for two"
119

Multi-Cycle Microarchitectures
120