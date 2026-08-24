361-1-4201
Computer Architecture
Multi-Cycle
Dr. Guy Tel-Zur
Based on lectures by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
With Dr. Guy Tel-Zur & Dr. Danny Seidner modifications
Last update 12/5/2022, 27/4/2023, 5/6/2024

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence Handling,
State Maintenance and Recovery, …
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, …
2

םויהל האירק
Readings for Today -
 P&P, Revised Appendix C
 Microarchitecture of the LC-3b
אצמנו ץלמומ
 Appendix A (LC-3b ISA)
לדומב
 ץלמומ ךשמהב ךכל עיגנ
 P&H, Appendix D, Mapping Control to Hardware וא םויה רועישה
רועישה תליחתב
https://booksite.elsevier.com/9780123838728/references.php - ןשי
אבה
https://www.elsevier.com/__data/assets/pdf_file/0011/1191377/Appendix-D.PDF
 הרשעה
 Maurice Wilkes, “The Best Way to Design an Automatic Calculating Machine,” Manchester Univ.
Computer Inaugural Conf., 1951.
https://www.cs.princeton.edu/courses/archive/fall10/cos375/BestWay.pdf
3

Readings for Next Lecture
 Pipelining – דואמ יוצר
 P&H Chapter 4.5-4.8
4.5 is available online:
https://www.elsevier.com/__data/assets/pdf_file/0004/1092442/CH04A_Secur
ed.pdf
 The book website:
https://www.elsevier.com/books/computer-organization-and-design-mips-edi
tion/patterson/978-0-12-820109-1
 Pipelined LC-3b Microarchitecture - תושר
 https://users.ece.utexas.edu/~patt/05f.360N/handouts/360n.appC.pdf
4

Review: A Key System Design Principle
 Keep it simple
 “Everything should be made as simple as possible, but no
simpler.”
 Albert Einstein
 And, keep it low cost: “An engineer is a person who can do
for a dime what any fool can do for a dollar.”
 For more, see:
 Butler W. Lampson, “Hints for Computer System Design,” ACM Operating
Systems Review, 1983.
 http://research.microsoft.com/pubs/68221/acrobat.pdf
5

About Butler W. Lampson
Home page: https://web.archive.org/web/20081202174014/http://research.microsoft.com/
lampson/
Butler Lampson is a Technical Fellow at Microsoft Corporation and an Adjunct Professor at MIT. He has worked on computer
architecture, local area networks, raster printers, page description languages, operating systems, remote procedure call,
programming languages and their semantics, programming in the large, fault-tolerant computing, transaction processing, computer
security, WYSIWYG editors, and tablet computers. He was one of the designers of the SDS 940 time-sharing system, the Alto
personal distributed computing system, the Xerox 9700 laser printer, two-phase commit protocols, the Autonet LAN, the SPKI
system for network security, the Microsoft Tablet PC software, the Microsoft Palladium high-assurance stack, and several
programming languages. He received the ACM Software Systems Award in 1984 for his work on the Alto, the IEEE Computer
Pioneer award in 1996 and von Neumann Medal in 2001, the Turing Award in 1992, and the NAE’s Draper Prize in 2004.
Perfection is reached not when there is no longer anything to add,
but when there is no longer anything to take away. (A. Saint-Exupery)
Il semble que la perfection soit atteinte non quand il n'y a plus rien à
ajouter, mais quand il n'y a plus rien à retrancher.

Xerox Alto (1970)

lm
th.g
niro
tser
-otla
-x
orex
-srot
anib
moc
-y/
60/6
102
/m
oc.
othg
ir.w
ww
//
:ptth
/otla
-xor
ex-g
nika
erbd
nuor
g-eh
t-gn
irots
er/6
2/60
/610
2/m
oc.y
ada
kca
h//:s
ptth

הארשה שמיש הז בשחמ .ןוטרסה תא ואר
שוטניקמה בשחמ רובע סבו’ג ביטסל
https://www.youtube.com/watch?v=YupOC_6bfMI&t=4s

Review: (Micro)architecture Design Principles
 Critical path design
 Find and decrease the maximum combinational logic delay
 Break a path into multiple cycles if it takes too long
 Bread and butter (common case) design
 Spend time and resources on where it matters most
 i.e., improve what the machine is really designed to do
 Common case vs. uncommon case
 Balanced design
 Balance instruction/data flow through hardware components
 Design to eliminate bottlenecks: balance the hardware for the work
10

Review: Single-Cycle Design vs. Design Principles
 Critical path design
 Bread and butter (common case) design
 Balanced design
How does a single-cycle microarchitecture fare in light of these
principles?
11

Multi-Cycle Microarchitectures
12

Multi-Cycle Microarchitectures
 Goal: Let each instruction take (close to) only as much time
it really needs
 Idea
 Determine clock cycle time independently of instruction processing time
 Each instruction takes as many clock cycles as it needs to take
 Multiple state transitions per instruction
 The states followed by each instruction is different
 See next slide
13

Multi-Cycle Microarchitectures - Idea
The CK period is constant. Instead of having one long CK cycle, we will use
shorter CKs and use the required number of CKs for each instruction:
Single cycle
The CK period is constant,
but the instruction length
Long instruction
(time) is different per
instruction!
Short inst.

Remember: The “Process instruction” Step
 ISA specifies abstractly what AS’ should be, given an instruction
and AS
 It defines an abstract finite state machine where
 State = programmer-visible state
 Next-state logic = instruction execution specification
 From ISA point of view, there are no “intermediate states” between AS and AS’
during instruction execution
 One state transition per instruction
 Microarchitecture implements how AS is transformed to AS’
 There are many choices in implementation
 We can have programmer-invisible state to optimize the speed of instruction
execution: multiple state transitions per instruction
 Choice 1: AS  AS’ (transform AS to AS’ in a single clock cycle)
 Choice 2: AS  AS+MS1  AS+MS2  AS+MS3  AS’ (take multiple clock cycles to transform
AS to AS’)
 MS = Microarchitectural State
15

Multi-Cycle Microarchitecture
AS = Architectural (programmer visible) state
at the beginning of an instruction
Step 1: Process part of instruction in one clock cycle
Step 2: Process part of instruction in the next clock cycle
…
AS’ = Architectural (programmer visible) state
at the end of a clock cycle
16

Benefits of Multi-Cycle Design
 Critical path design
 Can keep reducing the critical path independently of the worst-case processing
time of any instruction
 Bread and butter (common case) design
 Can optimize the number of states it takes to execute “important” instructions
that make up much of the execution time
 Balanced design
 No need to provide more capability or resources than really needed
 An instruction that needs resource X multiple times does not require multiple X’s to
be implemented
 Leads to more efficient hardware: Can reuse hardware components needed multiple
times for an instruction
17

Remember: Performance Analysis
 Execution time of an instruction
 {CPI} x {clock cycle time}
 Execution time of a program
 Sum over all instructions [{CPI} x {clock cycle time}]
 {# of instructions} x {Average CPI} x {clock cycle time}
 Single cycle microarchitecture performance
 CPI = 1
 Clock cycle time = long
 Multi-cycle microarchitecture performance
 CPI = different for each instruction
Now, we have
 Average CPI  hopefully small
two degrees of freedom
 Clock cycle time = short to optimize independently
18

A Multi-Cycle Microarchitecture
A Closer Look
19

How Do We Implement This?
 Maurice Wilkes, “The Best Way to Design an Automatic
Calculating Machine,” Manchester Univ. Computer
Inaugural Conf., 1951.
https://www.cs.princeton.edu/courses/archive/fall10/cos375/BestWay.pdf
גנירויט סרפ ןתח
 The concept of microcoded/microprogrammed machines
20

Maurice Wilkes :לאמשמ .לוכשא יול מ”הור :ןימימ

Microprogrammed Multi-Cycle μArch
 Key Idea for Realization
 One can implement the “process instruction” step as a finite state
machine that sequences between states and eventually returns back
to the “fetch instruction” state
הרזחה דע םייפוס םיבצמ תנוכמ ךותב םירבעמ לש הרדסל הארוהה דוביע תא ךופהנ
)fetch( הלחתהל
 A state is defined by the control signals asserted in it
ורובע םיידוחיה הרקבה תותוא ידי לע ןייפואמ בצמ
 Control signals for the next state determined in current state
יחכונה בצמב רבכ םיעבקנ אבה בצמה רובע הרקבה תותוא
22

A Basic Multi-Cycle Microarchitecture
 Instruction processing cycle divided into “states” הארוההמ קלח אוה בצמ
 A state (a stage) in the instruction processing cycle can take multiple states
(Guy> for example in the LC-3b Fetch takes 3 clock cycles)
 A multi-cycle microarchitecture sequences from state to state to process
an instruction
 The behavior of the machine in a state is completely determined by control signals
in that state
 The behavior of the entire processor is specified fully by a finite state
machine
 In a state (clock cycle), control signals control two things:
 How the datapath should process the data
 How to generate the control signals for the next clock cycle
23

Microprogrammed Control Terminology םיחנומ
 Control signals associated with the current state
 Microinstruction
 Act of transitioning from one state to another
 Determining the next state and the microinstruction for the next state
 Microsequencing
 Control store stores control signals for every possible state
 Store for microinstructions for the entire FSM
 Microsequencer determines which set of control signals will
be used in the next clock cycle (i.e., next state)
24

What Happens In A Clock Cycle?
 The control signals (microinstruction) for the current state
control two things:
 Processing in the data path
 Generation of control signals (microinstruction) for the next cycle
 See Figure 1 in the next slide
 Datapath and microsequencer operate concurrently
 Question: why not generate control signals for the current
cycle in the current cycle?
 This will lengthen the clock cycle
 Why would it lengthen the clock cycle?
 See Figure 2 in two more slides
25

A Clock Cycle
.N רוזחמל datapath -ה דוביע )1
.אבה רוזחמל הרקבה תותוא תריצי )2
Upon Latch:
1) Results of current cycle N
2) Control signals needed for
the next cycle N+1
26

A Bad Clock Cycle!
לובקימ םוקמב תויתרדיס
הרקבה תותוא םירצוימ הליחת
-ה דבועמ ןכמ-רחאל קרו N רוזחמל
.N ,רוזחמה ותוא רובע datapath
היהי ןמז חקול 0 דעצ םא .0 דעצב יולת 1 דעצ
צ .ןועשה ןמז תא ךיראהל ךרוצ
If step 0 takes non-zero time, clock cycle increases unnecessarily
Violates the "Critical Path Design" principle
יטירקה ביתנה לש ןונכתה ןורקע לש הרפה
27

Chapter 7 <28>
ERUTCETIHCRAORCIM
Chapter 7 - Multi Cycle Only
Digital Design and Computer Architecture, 2nd Edition
David Money Harris and Sarah L. Harris
In these slides some minor changes and additions were made by Guy Tel-Zur for
BGU CPU Architecture course
The official content is available at Elsevier

Chapter 7 <29>
ERUTCETIHCRAORCIM
Chapter 7 :: Topics
•
Introduction
•
Performance Analysis
•
Single-Cycle Processor
• יחכונה רועישה
Multicycle Processor
•
Pipelined Processor
•
Exceptions
•
Advanced Microarchitecture

MIPS Single Cycle  according to H&P
Instruction [25–0] Jump address [31–0]
Shift
left 2
|     |     |     | 26           | 28  |     |     |     |     | PCSrc | =Jump |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | ----- | ----- | --- |
|     |     |     |              |     |     |     |     |     | 01    | 1     |     |
|     |     |     | PC+4 [31–28] |     |     |     |     |     | M     | M     |     |
|     |     |     |              |     |     |     |     |     | u     | u     |     |
|     |     |     |              |     |     |     |     |     | x     | x     |     |
ALU
|     |     |     |     |     |     |     |     | Add | 1   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
result
Add
|     |     |     |     |     | RegDst |     | Shift |     |     |     |     |
| --- | --- | --- | --- | --- | ------ | --- | ----- | --- | --- | --- | --- |
left 2
Jump
|     | 4   |     |     |     |     |     |     |     |     | PCSrc =Br Taken |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------------- | --- |
Branch
2
MemRead
Instruction [31–26]
|     |     |     |     | Control | MemtoReg |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | -------- | --- | --- | --- | --- | --- | --- |
ALUOp
MemWrite
ALUSrc
RegWrite
|     |     | Instruction [25–21] |     |     | Read |     |     |     |     |     |     |
| --- | --- | ------------------- | --- | --- | ---- | --- | --- | --- | --- | --- | --- |
R e a d
| PC  |     |     |     |     | register 1 | Read |     |     |     |     |     |
| --- | --- | --- | --- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
ad d r ess
|     |     | Instruction [20–16] |     |     |     | data 1 |     |     |     |     |     |
| --- | --- | ------------------- | --- | --- | --- | ------ | --- | --- | --- | --- | --- |
Read
|     |     |     |     |     | register 2 |     |     | Zero |     |     |     |
| --- | --- | --- | --- | --- | ---------- | --- | --- | ---- | --- | --- | --- |
Instruction
|     |     | [31–0] |     | 0   | Registers | R e a d   |     | AbLcUond A L U |         |      |     |
| --- | --- | ------ | --- | --- | --------- | --------- | --- | -------------- | ------- | ---- | --- |
|     |     |        |     | M   | Write     | da t a  2 | 0   | re su l t      | Address | Read | 1   |
data
|     | Instruction |                     |     | u   | register |     | M   |     |     |        | M   |
| --- | ----------- | ------------------- | --- | --- | -------- | --- | --- | --- | --- | ------ | --- |
|     | memory      |                     |     | x   |          |     | u   |     |     |        |     |
|     |             | Instruction [15–11] |     |     |          |     |     |     |     |        | u   |
|     |             |                     |     | 1   | Write    |     | x   |     |     | Data   | x   |
|     |             |                     |     |     | data     |     | 1   |     |     |        |     |
|     |             |                     |     |     |          |     |     |     |     | memory | 0   |
Write
data
16 32
|     |     | Instruction [15–0] |     |     |     | Sign |     |     |     |     |     |
| --- | --- | ------------------ | --- | --- | --- | ---- | --- | --- | --- | --- | --- |
extend
|     |     |     |     |     |     |     | ALU | ALU operation |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- |
control
Instruction [5–0]
30
[Based on original figure from P&H CO&D, COPYRIGHT 2004 Elsevier. ALL
RIGHTS RESERVED.]

MIPS Single-Cycle Processor according to H&H
ERUTCETIHCRAORCIM
Jump
MemtoReg
Control
MemWrite
Unit
Branch
PCSrc
ALUControl
2:0
31:26
Op ALUSrc
5:0 Funct RegDst
RegWrite
|     |     |     | CLK |     |     | CLK |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
CLK
| 0   |     |     | WE3 |     | SrcA | Zero | WE  |     |
| --- | --- | --- | --- | --- | ---- | ---- | --- | --- |
25:21
| 0 PC' | PC   | Instr | A1  | RD1 |     |           |          | 0      |
| ----- | ---- | ----- | --- | --- | --- | --------- | -------- | ------ |
| 1     | A RD |       |     |     |     | ULA       |          | Result |
|       |      |       |     |     |     | ALUResult | ReadData |        |
1
|     |     |     |     |     |     | A   | RD  | 1   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Instruction
|     |     | 20:16 | A2  | RD2 | 0    |     |      |     |
| --- | --- | ----- | --- | --- | ---- | --- | ---- | --- |
|     |     |       |     |     | SrcB |     | Data |     |
Memory
|     |     |     | A3  |     | 1   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Memory
|     |     |     | Register |     |     | WriteData |     |     |
| --- | --- | --- | -------- | --- | --- | --------- | --- | --- |
|     |     |     | WD3      |     |     | WD        |     |     |
File
20:16
0
PCJump
15:11 1
WriteReg
4:0
PCPlus4
+
SignImm
<<2
|     | 4   | 15:0 |     |     |     |     |     |     |
| --- | --- | ---- | --- | --- | --- | --- | --- | --- |
Sign Extend
PCBranch
+
27:0 31:28
25:0
<<2
Chapter 7 <31>

Comparing the drawings Processor
ERUTCETIHCRAORCIM
היצמינא
Jump address [31–0]
|     |     |     |     | Instruction [25–0] |     | Shift |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ------------------ | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
26 left 2 28
0 1
|     |     |     |     |     | PC+4 [31–28] |     |     |     |     |     |     | M   | M   |     | PC mux |
| --- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ |
u u
x x
|     |     |     |     |     |     |     |     |     |     |     | Addre A L U | 1   | 0   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------- | --- | --- | --- | --- |
su l t
|     |     |     | Add |     |     |     |     |     |     | Shift |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- |
RegDst
|     |     |     |     |     |     |     | Jump   |     |     | left 2 |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | ------ | --- | --- | --- | --- | --- |
|     |     | 4   |     |     |     |     | Branch |     |     |        |     |     |     |     |     |
MemRead
|     |     |     |     | Instruction [31–26] |     |     | MemtoReg |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ------------------- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
Control
ALUOp
MemWrite
ALUSrc
RegWrite
|     |     |                |                  | Instruction [25–21] |     |     | Read                    |           |     |     |              |           |            |     |     |
| --- | --- | -------------- | ---------------- | ------------------- | --- | --- | ----------------------- | --------- | --- | --- | ------------ | --------- | ---------- | --- | --- |
|     | PC  | R ad e d a r d | ess              |                     |     |     | register 1              | Read      |     |     |              |           |            |     |     |
|     |     |                |                  | Instruction [20–16] |     |     |                         | data 1    |     |     |              |           |            |     |     |
|     |     |                |                  |                     |     |     | Read r e g i s t e r  2 |           |     |     | Z e r o      |           |            |     |     |
|     |     |                | Instr u c t io n |                     |     | 0   | R egisters              | R e a     | d   |     | ALU A L U    |           |            |     |     |
|     |     |                | [ 3 1 – 0 ]      |                     |     | M   | W r i t e               | da t a  2 |     | 0   | re s u l t A | d d r ess | R e a d    | 1   |     |
|     |     | In st ru       | c ti o n         |                     |     | u   | r e g i s t e r         |           |     | M   |              |           | d a ta     | M   |     |
|     |     | m e            | m o r y          | Instruction [15–11] |     | x   |                         |           |     | u   |              |           |            | u   |     |
|     |     |                |                  |                     |     | 1   | W r i t e               |           |     | x   |              |           | D at a     | x   |     |
|     |     |                |                  |                     |     |     | d a t a                 |           |     | 1   |              |           | m em o r y | 0   |     |
W r it e
data
| PC adder |     |     |     |                    |     |     |     | 16     | 32  |     |     |     |     |     |     |
| -------- | --- | --- | --- | ------------------ | --- | --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- |
|          |     |     |     | Instruction [15–0] |     |     |     | Sign   |     |     |     |     |     |     |     |
|          |     |     |     |                    |     |     |     | extend |     | ALU |     |     |     |     |     |
control
ControRle gDst mux
Instruction [5–0]
Inst. Memory
|     |     |     | FSM |     |     |     |     |     |     |     |     | Data Memory |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------- | --- | --- | --- |
GPR file
bAraLnUch calc.
|     |     |     |     |     |      |         | Sext     |     | SrcA mux |     |     |     |     | MemToReg mux |     |
| --- | --- | --- | --- | --- | ---- | ------- | -------- | --- | -------- | --- | --- | --- | --- | ------------ | --- |
|     |     |     |     |     | Jump |         | MemtoReg |     |          |     |     |     |     |              |     |
|     |     |     |     |     |      | Control | MemWrite |     |          |     |     |     |     |              |     |
Unit
Branch
PCSrc
ALUControl
|     |     |     |     |     | 31:26 |       |        | 2:0 |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----- | ----- | ------ | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |       | Op    | ALUSrc |     |     |     |     |     |     |     |     |
|     |     |     |     |     | 5:0   | Funct | RegDst |     |     |     |     |     |     |     |     |
RegWrite
|     |     |     |     |     |     | CLK |     |     |     |     |     | CLK |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
CLK
| 0   |     |     |             |       |       |     | WE3      |     |     |      | Zero      |        | WE   |          |          |
| --- | --- | --- | ----------- | ----- | ----- | --- | -------- | --- | --- | ---- | --------- | ------ | ---- | -------- | -------- |
|     | 0   |     |             |       | 25:21 | A1  | RD1      |     |     | SrcA |           |        |      |          |          |
| 1   | PC' | PC  | A RD        | Instr |       |     |          |     |     |      | ULA       |        |      |          | 0 Result |
|     | 1   |     |             |       |       |     |          |     |     |      | ALUResult |        |      | ReadData |          |
|     |     |     | Instruction |       |       |     |          |     |     |      |           | A      | RD   |          | 1        |
|     |     |     |             |       | 20:16 | A2  | RD2      |     | 0   | SrcB |           |        |      |          |          |
|     |     |     | Memory      |       |       |     |          |     |     |      |           |        | Data |          |          |
|     |     |     |             |       |       | A3  |          |     | 1   |      |           | Memory |      |          |          |
|     |     |     |             |       |       |     | Register |     |     |      | WriteData |        |      |          |          |
|     |     |     |             |       |       | WD3 |          |     |     |      |           | WD     |      |          |          |
File
|     |     |     |     |     | 20:16 |     |     | 0   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
PCJump
|     |     |     |     |     | 15:11 |     |     | 1   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
WriteReg
|     |     |     | PCPlus4 |     |     |     |     | 4:0 |     |     |     |     |     |     |     |
| --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
+
SignImm
|     |     |     | 4   |     | 15:0 |             |     |     |     | <<2 |          |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | -------- | --- | --- | --- | --- |
|     |     |     |     |     |      | Sign Extend |     |     |     |     | PCBranch |     |     |     |     |
+
27:0 31:28
|     |     |     |     |     | 25:0 | <<2 |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <32>

Chapter 7 <33>
ERUTCETIHCRAORCIM
Multicycle MIPS Processor
•
Single-cycle:
+ simple
-
cycle time limited by longest instruction (lw)
-
2 adders/ALUs & 2 memories
•
Multicycle:
+ higher clock speed
+ simpler instructions run faster
+ reuse expensive hardware on multiple cycles
- sequencing overhead paid many times
•
Same design steps: datapath & control

Chapter 7 <34>
ERUTCETIHCRAORCIM
Multicycle State Elements
 Replace Instruction and Data memories with a single
unified memory – more realistic
CLK CLK
CLK
WE WE3
A1 RD1
PC' PC
RD
A A2 RD2
EN
Instr / Data
Memory
A3
Register
WD
File
WD3

Multicycle Datapath: Instruction Fetch
ERUTCETIHCRAORCIM
STEP 1: Fetch instruction
IRWrite
|     |     | CLK |     | CLK |     |
| --- | --- | --- | --- | --- | --- |
| CLK |     | CLK |     |     |     |
WE WE3
|     |     |     |       | A1  | RD1 |
| --- | --- | --- | ----- | --- | --- |
| PC' | PC  |     | Instr |     |     |
b RD
|     |     | A   |     | A2  | RD2 |
| --- | --- | --- | --- | --- | --- |
EN
Instr / Data
Memory
A3
Register
WD
File
WD3
In Fetch we do:     IR =  M[PC]
Chapter 7 <35>

Multicycle Datapath: lw Register Read
ERUTCETIHCRAORCIM היצמינא
STEP 2a: Read source operands from RF
Fetch Decode
IR=M[PC] A=GPR[rs]
IRWrite
|     |     | CLK |     | CLK |     | CLK |
| --- | --- | --- | --- | --- | --- | --- |
| CLK |     | CLK |     |     |     |     |
|     |     | WE  |     | WE3 |     | A   |
25:21
| PC' | PC  |     | Instr | A1  | RD1 |     |
| --- | --- | --- | ----- | --- | --- | --- |
b
RD
|     |     | A   |     | A2  | RD2 |     |
| --- | --- | --- | --- | --- | --- | --- |
EN
Instr / Data
|     |     | Memory |     | A3  |     |     |
| --- | --- | ------ | --- | --- | --- | --- |
Register
WD
File
WD3
| In Decode we do:     A = GPR[rs] |     |     |     | H&H notation:     A = R[rs] |     |     |
| -------------------------------- | --- | --- | --- | --------------------------- | --- | --- |
lw $t1, 4($t2)  # $t1 = Memory[$t2+4]
Chapter 7 <36>

Multicycle Datapath: lw Immediate
ERUTCETIHCRAORCIM היצמינא
STEP 2b: Sign-extend the immediate
IRWrite
|     |     | CLK |     | CLK | CLK |     |
| --- | --- | --- | --- | --- | --- | --- |
| CLK |     | CLK |     |     |     |     |
|     |     | WE  |     | WE3 |     | A   |
25:21
| PC' | PC  |     | Instr | A1  | RD1 |     |
| --- | --- | --- | ----- | --- | --- | --- |
b
RD
|     |     | A   |     | A2  | RD2 |     |
| --- | --- | --- | --- | --- | --- | --- |
EN
Instr / Data
|     |     | Memory |     | A3  |     |     |
| --- | --- | ------ | --- | --- | --- | --- |
Register
WD
File
WD3
SignImm
15:0 Sign Extend
In Decode we do:     A = GPR[rs]
and we also have  sext(imm) already available
Chapter 7 <37>

Multicycle Datapath: lw Address
ERUTCETIHCRAORCIM היצמינא
STEP 3: Compute the memory address
ADdrCmp
Fetch Decode
ALUOut=A+sext(imm)
IR=M[PC] A=GPR[rs]
IRWrite ALUControl
2:0
| CLK |     | CLK | CLK |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
CLK CLK
CLK
| WE  |       | WE3 |     | A   | SrcA |     |     |
| --- | ----- | --- | --- | --- | ---- | --- | --- |
|     | 25:21 | A1  | RD1 |     |      |     |     |
PC' b PC Instr
| RD  |     |     |     |     | ULA |           |        |
| --- | --- | --- | --- | --- | --- | --------- | ------ |
| A   |     | A2  | RD2 |     |     | ALUResult | ALUOut |
EN
| Instr / Data |     |     |     |     | SrcB |     |     |
| ------------ | --- | --- | --- | --- | ---- | --- | --- |
| Memory       |     | A3  |     |     |      |     |     |
Register
WD
File
WD3
SignImm
15:0
Sign Extend
In AdrCmp we calculate      ALUOut = A + sext(imm)
ALUOut=ALUResult
Chapter 7 <38>

Multicycle Datapath: lw Memory Read
ERUTCETIHCRAORCIM היצמינא
STEP 4: Read data from memory
|     | Fetch |     |     |     |     | Decode |     |     |     | AdrCmp |     |     |
| --- | ----- | --- | --- | --- | --- | ------ | --- | --- | --- | ------ | --- | --- |
ALUOut=A+sext(imm)
|     | IR=M[PC] |     |         |     |     | A=GPR[rs] |     |     |     |            |     |     |
| --- | -------- | --- | ------- | --- | --- | --------- | --- | --- | --- | ---------- | --- | --- |
|     | IorD     |     | IRWrite |     |     |           |     |     |     | ALUControl |     |     |
2:0
|        |       | CLK |     |       |       |     | CLK |     | CLK |      |           |        |
| ------ | ----- | --- | --- | ----- | ----- | --- | --- | --- | --- | ---- | --------- | ------ |
| CLK    |       |     |     | CLK   |       |     |     |     |     |      |           |        |
|        |       |     | WE  |       |       |     | WE3 |     |     | SrcA |           | CLK    |
|        |       |     |     |       | 25:21 |     |     |     | A   |      |           |        |
| PC' PC |       |     |     | Instr |       |     | A1  | RD1 |     |      |           |        |
| b      | 0 Adr |     | RD  |       |       |     |     |     |     |      | ULA       |        |
|        |       |     |     |       |       |     |     |     |     |      | ALUResult | ALUOut |
|        |       | A   |     | EN    |       |     | A2  | RD2 |     |      |           |        |
1
|     |     | Instr / Data |     |     |     |     |     |     |     | SrcB |     |     |
| --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- |
|     |     | Memory       |     |     |     |     | A3  |     |     |      |     |     |
CLK
Register
WD
|     |     |     |     | Data |     |     | File |     |     |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | ---- | --- | --- | --- | --- | --- |
WD3
Load
SignImm
|     | MDR=M[ALUOut] |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |
| --- | ------------- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- |
In Load we read from Data Mem. To the MDR      MDR = M[ALUOut]
Chapter 7 <39>

Multicycle Datapath: lw Write Register
ERUTCETIHCRAORCIM היצמינא
STEP 5: Write data back to register file
|     | Fetch |     |     |     |     | Decode |     |     |     | AdrCmp |     |     |
| --- | ----- | --- | --- | --- | --- | ------ | --- | --- | --- | ------ | --- | --- |
ALUOut=A+sext(imm)
|     | IR=M[PC] |     |         |     |     | A=GPR[rs] |          |     |     |            |     |     |
| --- | -------- | --- | ------- | --- | --- | --------- | -------- | --- | --- | ---------- | --- | --- |
|     | IorD     |     | IRWrite |     |     |           | RegWrite |     |     | ALUControl |     |     |
2:0
|        |     | CLK |     |       |       |     | CLK |     | CLK |      |           |        |
| ------ | --- | --- | --- | ----- | ----- | --- | --- | --- | --- | ---- | --------- | ------ |
| CLK    |     |     |     | CLK   |       |     |     |     |     |      |           |        |
|        |     |     | WE  |       |       |     | WE3 |     |     | SrcA |           | CLK    |
|        |     |     |     |       | 25:21 |     |     |     | A   |      |           |        |
| PC' PC |     |     |     | Instr |       |     | A1  | RD1 |     |      |           |        |
| b      | 0   |     | RD  |       |       |     |     |     |     |      | ULA       |        |
|        | Adr |     |     |       |       |     |     |     |     |      | ALUResult | ALUOut |
|        |     | A   |     | EN    |       |     | A2  | RD2 |     |      |           |        |
1
|     |     | Instr / Data |     |     |       |     |     |     |     | SrcB |     |     |
| --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- | ---- | --- | --- |
|     |     | Memory       |     |     | 20:16 |     | A3  |     |     |      |     |     |
CLK
Register
WD
|     |     |     |     | Data |     |     | File |     |     |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | ---- | --- | --- | --- | --- | --- |
WD3
WB
Load
GPR[rt]=MDR
SignImm
|     | MDR=M[ALUOut] |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |
| --- | ------------- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- |
In WB we write MDR into the GPR file:      GPR[rt]=MDR
Chapter 7 <40>

Multicycle Datapath: Increment PC
ERUTCETIHCRAORCIM היצמינא
STEP 6: Increment PC
| PCWrite | IorD  |     | IRWrite |       |       | RegWrite |     |     | ALUSrcA | ALUSrcB | ALUControl |           |        |
| ------- | ----- | --- | ------- | ----- | ----- | -------- | --- | --- | ------- | ------- | ---------- | --------- | ------ |
|         |       |     |         |       |       |          |     |     |         |         | 1:0        | 2:0       |        |
|         |       | CLK |         |       |       | CLK      |     | CLK |         |         |            |           |        |
| CLK     |       |     |         | CLK   |       |          |     |     |         |         |            |           |        |
|         |       |     |         |       |       |          |     |     |         | 0       | SrcA       |           |        |
|         |       |     | WE      |       |       | WE3      |     |     |         |         |            |           | CLK    |
|         |       |     |         |       | 25:21 |          |     |     | A       |         |            |           |        |
| PC' PC  |       |     |         | Instr |       | A1       | RD1 |     |         | 1       |            |           |        |
| b       | 0 Adr |     | RD      |       |       |          |     |     |         |         |            | ULA       |        |
|         |       | A   |         |       |       | A2       | RD2 |     |         | 00      |            | ALUResult | ALUOut |
| EN      |       |     |         | EN    |       |          |     |     |         |         |            |           |        |
1
|     |     | Instr / Data |     |     |       |     |     |     |     | 4 01 | SrcB |     |     |
| --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- | ---- | ---- | --- | --- |
|     |     | Memory       |     | CLK | 20:16 | A3  |     |     |     | 10   |      |     |     |
Register
|     |     | WD  |     |      |     |      |     |     |     | 11  |     |     |     |
| --- | --- | --- | --- | ---- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     | Data |     | File |     |     |     |     |     |     |     |
WD3
SignImm
|     |     |     |     |     | 15:0 | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | --- | --- | --- |
At some point we must increment PC by 4:                  PC=PC+4
| When should we do that? |     |     |     |     | It can be done during Fetch IR=M[PC] |     |     |     |     |     |     |     |     |
| ----------------------- | --- | --- | --- | --- | ------------------------------------ | --- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <41>

Chapter 7 <42>
ERUTCETIHCRAORCIM
Railroad Switch – רסקלפיטלומה תואלפנ
...םינוויכה ינשב עוסנל תולוכי תובכרו רחאמ יגולנא קוידב אל Guy

Guy


Multicycle Datapath: sw
ERUTCETIHCRAORCIM היצמינא
Write data in rt to memory
|     |     |     | Fetch |     |     |     | Decode |     |     |     |     |     | AdrCmp |     |     |
| --- | --- | --- | ----- | --- | --- | --- | ------ | --- | --- | --- | --- | --- | ------ | --- | --- |
ALUOut=A+sext(imm)
|     |     | IR=M[PC] |     |     |     |     | A=GPR[rs] |     |     |     |     |     |     |     |     |
| --- | --- | -------- | --- | --- | --- | --- | --------- | --- | --- | --- | --- | --- | --- | --- | --- |
&  B=GPR[rt]
PCWrite IorD MemWrite IRWrite RegWrite ALUSrcA ALUSrcB ALUControl
|     |     |     |     |     |     |     |     |     |     |     |     |     | 1:0  | 2:0 |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- |
|     |     |     | CLK |     |     |     | CLK |     |     | CLK |     |     |      |     |     |
|     | CLK |     |     |     | CLK |     |     |     |     |     |     |     |      |     |     |
|     |     |     |     |     |     |     |     |     |     |     | 0   |     | SrcA |     |     |
|     |     |     |     | WE  |     |     |     | WE3 |     |     |     |     |      |     | CLK |
A
| PC' | PC  |     |     |     | Instr | 25:21 | A1  |     | RD1 |     | 1   |     |     |           |        |
| --- | --- | --- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- | --------- | ------ |
|     | b   | 0   |     | RD  |       |       |     |     |     |     |     |     |     | ULA       |        |
|     |     | Adr |     |     |       |       |     |     |     | B   |     |     |     |           |        |
|     | EN  |     | A   |     | EN    | 20:16 | A2  |     | RD2 |     |     | 00  |     | ALUResult | ALUOut |
1
|     |     |     | Instr / Data |     |     |       |     |     |     |     | 4   | 01  | SrcB |     |     |
| --- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- | --- | --- | ---- | --- | --- |
|     |     |     | Memory       |     | CLK | 20:16 | A3  |     |     |     |     | 10  |      |     |     |
Register
|     |     |     | WD  |     |      |     |     |      |     |     |     | 11  |     |     |     |
| --- | --- | --- | --- | --- | ---- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | Data |     |     | File |     |     |     |     |     |     |     |
WD3
Store
M[ALUOut]=B
SignImm
|     |     |     |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- |
In sw we do:   M[GPR[rs] +sext(imm)] = GPR[rt]
Thus the first 3 steps are the same: Fetch, Decode, AdrCmp.
In Store we write GPR[rt] (B) into the D.Mem:      M[ALUOut]=B
Chapter 7 <43>

Multicycle Datapath: R-Type
ERUTCETIHCRAORCIM היצמינא

Read from rs and rt
|    | Write ALUResult to register file |     |     |     |     |        |     |     |     |     |     |     |     |
| --- | -------------------------------- | --- | --- | --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- |
|    | Write to rd (instead of rt)      |     |     |     |     |        |     |     |     |     |     |     |     |
|     | Fetch                            |     |     |     |     | Decode |     |     |     |     | ALU |     |     |
A=GPR[rs]
ALUOut=A op B
IR=M[PC]
&   B=GPR[rt]
PCWrite IorD MemWrite IRWrite RegDst MemtoReg RegWrite ALUSrcA ALUSrcB ALUControl
|     |     |     |     |     |     |     |     |     |     | 1:0  |     | 2:0 |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     |     | CLK |     |     |     | CLK |     | CLK |     |      |     |     |     |
| CLK |     |     |     | CLK |     |     |     |     |     |      |     |     |     |
|     |     |     |     |     |     |     |     |     | 0   | SrcA |     |     |     |
|     |     |     | WE  |     |     | WE3 |     | A   |     |      |     |     | CLK |
25:21
| PC' | PC    |     |     | Instr |       | A1  | RD1 |     | 1   |     |     |           |        |
| --- | ----- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --------- | ------ |
| b   | 0 Adr |     | RD  |       |       |     |     | B   |     |     | ULA |           |        |
|     |       |     |     |       | 20:16 |     |     |     |     |     |     | ALUResult | ALUOut |
|     | EN    | A   |     | EN    |       | A2  | RD2 |     | 00  |     |     |           |        |
1
|     |     | Instr / Data |     |     | 20:16 |     |     |     | 4 01 | SrcB |     |     |     |
| --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | ---- | ---- | --- | --- | --- |
0
|     |     | Memory |     |     |     | A3  |     |     | 10  |     |     |     |     |
| --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
15:11
|     |     |     |     | CLK  | 1   | Register |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ---- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
|     |     | WD  |     |      |     |          |     |     | 11  |     |     |     |     |
|     |     |     |     |      | 0   | File     |     |     |     |     |     |     |     |
|     |     |     |     | Data |     | WD3      |     |     |     |     |     |     |     |
1
WBR
SignImm
GPR[rd]=ALUOut
15:0
Sign Extend
In R-Type we do: GPR[rd] = GPR[rs] op GPR[rt]. In Decode we read from rs & rt.
| In ALU we calculate the op |     |     |     |     | and in WBR we write to GPR[rd] |     |     |     |     |     |     |     |     |
| -------------------------- | --- | --- | --- | --- | ------------------------------ | --- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <44>

Multicycle Datapath: beq
ERUTCETIHCRAORCIM היצמינא
Guy>  BTA = Branch Target Address
|    | rs = = rt? |     |     |     |     |     |     |     |     |     |
| --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
                  = (sign-extended immediate)x4 + (PC+4)
|    | BTA = (sign-extended immediate << 2) + (PC+4) |     |     |     |        |     |     |     |     |     |
| --- | --------------------------------------------- | --- | --- | --- | ------ | --- | --- | --- | --- | --- |
|     | Fetch                                         |     |     |     | Decode |     |     |     |     |     |
A=GPR[rs], B=GPR[rt]
IR=M[PC]
&   ALUOut =PC+ sext(imm) <<2
PCEn
IorD MemWrite IRWrite RegDst MemtoReg RegWrite ALUSrcA ALUSrcB ALUControl Branch PCWrite PCSrc
1:0 2:0
|     |     | CLK |     |     | CLK | CLK |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CLK |     |     | CLK |     |     |     |     |     |     |     |
0 SrcA
CLK
|     |       | WE  |       |       | WE3 |     | A   |     | Zero      |        |
| --- | ----- | --- | ----- | ----- | --- | --- | --- | --- | --------- | ------ |
|     |       |     |       | 25:21 | A1  | RD1 |     | 1   |           |        |
| PC' | PC    |     | Instr |       |     |     |     |     |           | 0      |
| b   | 0 Adr | RD  |       |       |     |     | B   |     | ULA       |        |
|     |       | A   |       | 20:16 | A2  | RD2 |     | 00  | ALUResult | ALUOut |
|     | EN    |     | EN    |       |     |     |     |     |           | 1      |
1
4 01
Instr / Data SrcB
20:16 0
|     |     | Memory |      |         | A3       |     |     | 10  |     |     |
| --- | --- | ------ | ---- | ------- | -------- | --- | --- | --- | --- | --- |
|     |     |        | CLK  | 15:11 1 | Register |     |     |     |     |     |
|     |     | WD     |      |         |          |     |     | 11  |     |     |
|     |     |        |      | 0       | File     |     |     |     |     |     |
|     |     |        | Data |         | WD3      |     |     |     |     |     |
1
<<2
SignImm
|     |     |     |     | 15:0 | Sign Extend |     |     |     |     |     |
| --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | --- |
Chapter 7 <45>

Multicycle Datapath: beq
ERUTCETIHCRAORCIM היצמינא
Guy>  BTA = Branch Target Address
|    | rs = = rt? |     |     |     |     |     |     |     |     |     |
| --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
                  = (sign-extended immediate)x4 + (PC+4)
|    | BTA = (sign-extended immediate << 2) + (PC+4) |     |     |     |     |     |     |     |     |     |
| --- | --------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALU
|     | Fetch |     |     |     | Decode |     |     |     |     |     |
| --- | ----- | --- | --- | --- | ------ | --- | --- | --- | --- | --- |
ALUOut=A – B
A=GPR[rs], B=GPR[rt]
IR=M[PC]
 & check Zero
&   ALUOut =PC+ sext(imm) <<2
PCEn
IorD MemWrite IRWrite RegDst MemtoReg RegWrite ALUSrcA ALUSrcB ALUControl Branch PCWrite PCSrc
1:0 2:0
|     |     | CLK |     |     | CLK | CLK |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CLK |     |     | CLK |     |     |     |     |     |     |     |
0 SrcA
CLK
|     |       | WE  |       |       | WE3 |     | A   |     | Zero      |        |
| --- | ----- | --- | ----- | ----- | --- | --- | --- | --- | --------- | ------ |
|     |       |     |       | 25:21 | A1  | RD1 |     | 1   |           |        |
| PC' | PC    |     | Instr |       |     |     |     |     |           | 0      |
| b   | 0 Adr | RD  |       |       |     |     | B   |     | ULA       |        |
|     |       | A   |       | 20:16 | A2  | RD2 |     | 00  | ALUResult | ALUOut |
|     | EN    |     | EN    |       |     |     |     |     |           | 1      |
1
4 01
Instr / Data SrcB
20:16 0
|     |     | Memory |      |         | A3       |     |     | 10  |     |     |
| --- | --- | ------ | ---- | ------- | -------- | --- | --- | --- | --- | --- |
|     |     |        | CLK  | 15:11 1 | Register |     |     |     |     |     |
|     |     | WD     |      |         |          |     |     | 11  |     |     |
|     |     |        |      | 0       | File     |     |     |     |     |     |
|     |     |        | Data |         | WD3      |     |     |     |     |     |
1
If Zero==1
<<2
PC= ALUOut
SignImm
|     |     |     |     | 15:0 | Sign Extend |     |     |     |     |     |
| --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | --- |
Chapter 7 <46>

Multicycle Processor
ERUTCETIHCRAORCIM
CLK
PCWrite
|     |     |     |     |      | Branch |     |     |     |     |     | PCEn |     |
| --- | --- | --- | --- | ---- | ------ | --- | --- | --- | --- | --- | ---- | --- |
|     |     |     |     | IorD | PCSrc  |     |     |     |     |     |      |     |
Control
|     |     |     |          | Unit | ALUControl |     |     |     |     |     |     |     |
| --- | --- | --- | -------- | ---- | ---------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | MemWrite |      |            | 2:0 |     |     |     |     |     |     |
ALUSrcB
IRWrite
1:0
|     |     |     |     | 31:26 | ALUSrcA |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- |
Op
RegWrite
5:0 Funct
|     |     |     |     | RegDst MemtoReg |     |     |     |     |      |     |     |     |
| --- | --- | --- | --- | --------------- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     |     | CLK |     |                 | CLK | CLK |     |     |      |     |     |     |
| CLK |     |     | CLK |                 |     |     |     |     |      |     |     |     |
|     |     |     |     |                 |     |     |     | 0   | SrcA |     |     |     |
CLK
|     |       | WE  |       |       | WE3 |     | A   |     |     | Zero      |        |     |
| --- | ----- | --- | ----- | ----- | --- | --- | --- | --- | --- | --------- | ------ | --- |
|     |       |     |       | 25:21 | A1  | RD1 |     | 1   |     |           |        |     |
| PC' | PC    |     | Instr |       |     |     |     |     |     |           |        | 0   |
|     | 0 Adr | RD  |       |       |     |     | B   |     |     | ULA       |        |     |
|     |       |     |       | 20:16 |     |     |     |     |     | ALUResult | ALUOut |     |
|     | EN    | A   | EN    |       | A2  | RD2 |     | 00  |     |           |        | 1   |
1
|     |     | Instr / Data |     |     |     |     |     | 4 01 | SrcB |     |     |     |
| --- | --- | ------------ | --- | --- | --- | --- | --- | ---- | ---- | --- | --- | --- |
20:16 0
Memory
|     |     |     |     |     | A3  |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
15:11 1
|     |     |     | CLK  |     | Register |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
|     |     | WD  |      |     |          |     |     | 11  |     |     |     |     |
|     |     |     |      | 0   | File     |     |     |     |     |     |     |     |
|     |     |     | Data |     | WD3      |     |     |     |     |     |     |     |
1
<<2
SignImm
|     |     |     |     | 15:0 | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <47>

Chapter 7 <48>
ERUTCETIHCRAORCIM
Multicycle Control
Control
MemtoReg
Unit
RegDst
IorD הנווכה
Multiplexer
PCSrc Selects םירסקלפיטלומל
Main
ALUSrcB
Controller 1:0
Opcode ALUSrcA
5:0 (FSM)
IRWrite FSM
MemWrite
Register
PCWrite
Enables
Branch
םירטסיגרל הנווכה
RegWrite
ALUOp
1:0
ALU
Funct ALUControl
5:0 Decoder 2:0

Main Controller FSM: Fetch
ERUTCETIHCRAORCIM
S0: Fetch
IorD = 0
AluSrcA = 0
Reset
ALUSrcB = 01
ALUOp = 00
PCSrc = 0
IRWrite
CLK
| PCWrite |     |     |     |     |     |     | PCWrite |     |     |     |     |     | 1   |      |     |
| ------- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | ---- | --- |
|         |     |     |     |     |     |     |         |     |     |     |     | 0   |     | PCEn |     |
Branch
|     |     |     |     |     |     | IorD | PCSrc |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
Control
|     |     |     |     |     | MemWrite | Unit | ALUControl |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | -------- | ---- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
2:0
|     |     |     |     |     |     | IRWrite | ALUSrcB |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
1:0
|     |     |     |     |     |     | 31:26 | ALUSrcA |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
Op
|     |     |     |     |     |     | 5:0 | RegWrite |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
Funct
|     |     |     |     |     |     | RegDst | MemtoReg |     |     |     |      |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | --- | --- | --- | ---- | --- | --- | --- | --- |
|     |     |     | CLK |     |     |        | CLK      |     | CLK | 0   |      |     |     |     |     |
|     |     |     |     | 0   |     |        |          | 0   |     |     |      |     |     |     |     |
|     | CLK |     |     |     | CLK |        |          |     |     | 0   | SrcA | 010 |     |     |     |
CLK
|     |        | 0   |              | WE  |       |         |     | WE3 | A   |     |         | Zero      |     |        | 0   |
| --- | ------ | --- | ------------ | --- | ----- | ------- | --- | --- | --- | --- | ------- | --------- | --- | ------ | --- |
|     | PC' PC |     |              |     | Instr | 25:21   | A1  | RD1 |     | 1   |         |           |     |        |     |
|     |        | 0   |              | RD  |       |         |     |     |     |     | 01      | ULA       |     |        | 0   |
|     |        |     | Adr          |     |       | 20:16   |     |     | B   |     |         | ALUResult |     | ALUOut |     |
|     | EN     |     | A            |     | EN    |         | A2  | RD2 |     |     | 00      |           |     |        | 1   |
|     |        | 1   |              |     |       | X       |     |     |     |     |         |           |     |        |     |
|     |        |     | Instr / Data |     |       |         |     |     |     | 4   | 01 SrcB |           |     |        |     |
|     | 1      |     |              |     | 1     | 20:16 0 |     |     |     |     |         |           |     |        |     |
Memory
|     |     |     |     |     |     |         | A3  |          |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | CLK | 15:11 1 |     | Register |     |     |     |     |     |     |     |
|     |     |     | WD  |     |     |         | X   |          |     |     | 11  |     |     |     |     |
File
0
|     |     |     |     |     | Data |     | WD3 |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
1
<<2
SignImm
|     |     |     |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <49>

Main Controller FSM: Fetch
ERUTCETIHCRAORCIM
PC = PC+4
IR  = M[PC]
S0: Fetch
IorD = 0
AluSrcA = 0
Reset
ALUSrcB = 01
ALUOp = 00
PCSrc = 0
| IRWrite |     |     |     |     |     | CLK |         |     |     |     |     |     |     |      |     |
| ------- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | ---- | --- |
| PCWrite |     |     |     |     |     |     | PCWrite |     |     |     |     |     | 1   |      |     |
|         |     |     |     |     |     |     |         |     |     |     |     | 0   |     | PCEn |     |
Branch
|     |     |     |     |     |     | IorD | PCSrc |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
Control
|     |     |     |     |     | MemWrite | Unit | ALUControl |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | -------- | ---- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
2:0
|     |     |     |     |     |     | IRWrite | ALUSrcB |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
1:0
|     |     |     |     |     |     | 31:26 | ALUSrcA |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
Op
|     |     |     |     |     |     | 5:0 | RegWrite |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- |
Funct
|     |     |     |     |     |     | RegDst | MemtoReg |     |     |     |      |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | --- | --- | --- | ---- | --- | --- | --- | --- |
|     |     |     | CLK |     |     |        | CLK      |     | CLK | 0   |      |     |     |     |     |
|     |     |     |     | 0   |     |        |          | 0   |     |     |      |     |     |     |     |
|     | CLK |     |     |     | CLK |        |          |     |     | 0   | SrcA | 010 |     |     |     |
CLK
|     |        | 0   |              | WE  |       |         |     | WE3 | A   |     |         | Zero      |     |        | 0   |
| --- | ------ | --- | ------------ | --- | ----- | ------- | --- | --- | --- | --- | ------- | --------- | --- | ------ | --- |
|     | PC' PC |     |              |     | Instr | 25:21   | A1  | RD1 |     | 1   |         |           |     |        |     |
|     |        | 0   |              | RD  |       |         |     |     |     |     | 01      | ULA       |     |        | 0   |
|     |        |     | Adr          |     |       | 20:16   |     |     | B   |     |         | ALUResult |     | ALUOut |     |
|     | EN     |     | A            |     | EN    |         | A2  | RD2 |     |     | 00      |           |     |        | 1   |
|     |        | 1   |              |     |       | X       |     |     |     |     |         |           |     |        |     |
|     |        |     | Instr / Data |     |       |         |     |     |     | 4   | 01 SrcB |           |     |        |     |
|     | 1      |     |              |     | 1     | 20:16 0 |     |     |     |     |         |           |     |        |     |
Memory
|     |     |     |     |     |     |         | A3  |          |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | CLK | 15:11 1 |     | Register |     |     |     |     |     |     |     |
|     |     |     | WD  |     |     |         | X   |          |     |     | 11  |     |     |     |     |
File
0
|     |     |     |     |     | Data |     | WD3 |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
1
<<2
SignImm
|     |     |     |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <50>

Main Controller FSM: Decode
ERUTCETIHCRAORCIM
| S0: Fetch |     |     |     | S1: Decode |     |     |     |     |     |     |     |     |     |     |     |     |
| --------- | --- | --- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
IorD = 0
AluSrcA = 0
Reset
ALUSrcB = 01
ALUOp = 00
PCSrc = 0
IRWrite
PCWrite
CLK
|     |     |     |     |     |     |     | PCWrite |     |     |     |     |     |     | 0   |      |     |
| --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | ---- | --- |
|     |     |     |     |     |     |     |         |     |     |     |     |     |     | 0   | PCEn |     |
Branch
|     |     |     |     |     |     | IorD Control | PCSrc |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------------ | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALUControl
|     |     |     |     |     | MemWrite | Unit |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
2:0
|     |     |     |     |     |     | IRWrite | ALUSrcB |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
1:0
|     |     |     |     |     |     | 31:26 | ALUSrcA |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Op
RegWrite
5:0 Funct
|     |     |     |     |     |     | RegDst | MemtoReg |     |     |     |     |     |      |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     |     |     | CLK |     |     |        | CLK      |     |     | CLK |     | X   |      |     |     |     |
|     | CLK |     |     | 0   | CLK |        |          |     | 0   |     |     |     |      |     |     |     |
|     |     |     |     |     |     |        |          |     |     |     | 0   |     | SrcA | XXX |     |     |
CLK
|     |     | X   |              | WE  |       |         |     | WE3 |     | A   |     |     |      | Zero      |        | X   |
| --- | --- | --- | ------------ | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | ---- | --------- | ------ | --- |
| PC' | PC  |     |              |     | Instr | 25:21   | A1  |     | RD1 |     | 1   |     |      |           |        |     |
|     |     | 0   |              | RD  |       |         |     |     |     |     |     |     | XX   | ULA       |        | 0   |
|     |     |     | Adr          |     |       | 20:16   |     |     |     | B   |     |     |      | ALUResult | ALUOut |     |
|     | EN  |     | A            |     | EN    |         | A2  |     | RD2 |     |     | 00  |      |           |        | 1   |
|     |     | 1   |              |     |       | X       |     |     |     |     |     |     |      |           |        |     |
|     |     |     | Instr / Data |     |       |         |     |     |     |     | 4   | 01  | SrcB |           |        |     |
|     | 0   |     |              |     | 0     | 20:16 0 |     |     |     |     |     |     |      |           |        |     |
Memory
|     |     |     |     |     |      |         | A3  |          |      |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | ------- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | CLK  | 15:11 1 |     | Register |      |     |     |     |     |     |     |     |
|     |     |     | WD  |     |      |         | X   |          |      |     |     | 11  |     |     |     |     |
|     |     |     |     |     |      |         | 0   |          | File |     |     |     |     |     |     |     |
|     |     |     |     |     | Data |         | WD3 |          |      |     |     |     |     |     |     |     |
1
<<2
SignImm
|     |     |     |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <51>

Main Controller FSM: Decode
ERUTCETIHCRAORCIM
| S0: Fetch |     |     |     | S1: Decode |     |     |     | A = GPR[rs] |     |     |     |     |     |     |     |     |
| --------- | --- | --- | --- | ---------- | --- | --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- |
IorD = 0
|     | AluSrcA = 0 |     |     |     |     |     |     | B = GPR[rt] |     |     |     |     |     |     |     |     |
| --- | ----------- | --- | --- | --- | --- | --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- |
Reset
|     | ALUSrcB = 01 |     |     |     |     | AluSrcA = 0 |     |     |     |     |     |     |     |     |     |     |
| --- | ------------ | --- | --- | --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALUOut = PC + sext(imm)<<2
|     | ALUOp = 00 |     |     |     |     | AluSrcB = 11 |     |     |     |     |     |     |     |     |     |     |
| --- | ---------- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ונחנאש ינפל דוע בשוחמ הז ךרעש בל ומיש
|     | PCSrc = 0 |     |     |     |     | ALUOP = 00 |     |     |     |     |     |     |     |     |     |     |
| --- | --------- | --- | --- | --- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
IRWrite
םיידיתע םידעצל הנכה וז .רבודמ הארוה וזיאב םיעדוי
PCWrite
CLK
|     |     |     |     |     |     |     | PCWrite |     |     |     |     |     |     | 0   |      |     |
| --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | ---- | --- |
|     |     |     |     |     |     |     |         |     |     |     |     |     |     | 0   | PCEn |     |
Branch
|     |     |     |     |     |     | IorD Control | PCSrc |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------------ | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALUControl
|     |     |     |     |     | MemWrite | Unit |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
2:0
|     |     |     |     |     |     | IRWrite | ALUSrcB |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
1:0
|     |     |     |     |     |     | 31:26 | ALUSrcA |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Op
RegWrite
5:0 Funct
|     |     |     |     |     |     | RegDst | MemtoReg |     |     |     |     |     |      |     |     |     |
| --- | --- | --- | --- | --- | --- | ------ | -------- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     |     |     | CLK |     |     |        | CLK      |     |     | CLK |     | X   |      |     |     |     |
|     | CLK |     |     | 0   | CLK |        |          |     | 0   |     |     |     |      |     |     |     |
|     |     |     |     |     |     |        |          |     |     |     | 0   |     | SrcA | XXX |     |     |
CLK
|     |     | X   |              | WE  |       |         |     | WE3 |     | A   |     |     |      | Zero      |        | X   |
| --- | --- | --- | ------------ | --- | ----- | ------- | --- | --- | --- | --- | --- | --- | ---- | --------- | ------ | --- |
| PC' | PC  |     |              |     | Instr | 25:21   | A1  |     | RD1 |     | 1   |     |      |           |        |     |
|     |     | 0   |              | RD  |       |         |     |     |     |     |     |     | XX   | ULA       |        | 0   |
|     |     |     | Adr          |     |       | 20:16   |     |     |     | B   |     |     |      | ALUResult | ALUOut |     |
|     | EN  |     | A            |     | EN    |         | A2  |     | RD2 |     |     | 00  |      |           |        | 1   |
|     |     | 1   |              |     |       | X       |     |     |     |     |     |     |      |           |        |     |
|     |     |     | Instr / Data |     |       |         |     |     |     |     | 4   | 01  | SrcB |           |        |     |
|     | 0   |     |              |     | 0     | 20:16 0 |     |     |     |     |     |     |      |           |        |     |
Memory
|     |     |     |     |     |      |         | A3  |          |      |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | ---- | ------- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | CLK  | 15:11 1 |     | Register |      |     |     |     |     |     |     |     |
|     |     |     | WD  |     |      |         | X   |          |      |     |     | 11  |     |     |     |     |
|     |     |     |     |     |      |         | 0   |          | File |     |     |     |     |     |     |     |
|     |     |     |     |     | Data |         | WD3 |          |      |     |     |     |     |     |     |     |
1
<<2
SignImm
|     |     |     |     |     |     | 15:0 |     | Sign Extend |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ---- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- |
Chapter 7 <52>

Main Controller FSM: Address
ERUTCETIHCRAORCIM
|     | S0: Fetch |     |     | S1: Decode |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --------- | --- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
IorD = 0
| Reset |     | AluSrcA = 0 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| ----- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
AluSrcA = 0
ALUSrcB = 01
|     |     | ALUOp = 00 |     |     |     | AluSrcB = 11 |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | ---------- | --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
PCSrc = 0
ALUOP = 00
IRWrite
PCWrite
Op = LW
or
CLK
| S2: MemAdr   | Op = SW |     |     |     |     |     |          |         |            |     |     |     |     |     |     |     |      |     |
| ------------ | ------- | --- | --- | --- | --- | --- | -------- | ------- | ---------- | --- | --- | --- | --- | --- | --- | --- | ---- | --- |
|              |         |     |     |     |     |     |          |         | PCWrite    |     |     |     |     |     |     |     | 0    |     |
|              |         |     |     |     |     |     |          |         | Branch     |     |     |     |     |     |     | 0   | PCEn |     |
|              |         |     |     |     |     |     | IorD     | Control | PCSrc      |     |     |     |     |     |     |     |      |     |
| ALUSrcA = 1  |         |     |     |     |     |     |          | Unit    | ALUControl |     |     |     |     |     |     |     |      |     |
|              |         |     |     |     |     |     | MemWrite |         |            |     | 2:0 |     |     |     |     |     |      |     |
| ALUSrcB = 10 |         |     |     |     |     |     | IRWrite  |         | ALUSrcB    |     |     |     |     |     |     |     |      |     |
1:0
| ALUOp = 00 |     |     |     |     |     |     |     |     | ALUSrcA |     |     |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
31:26 Op
RegWrite
5:0 Funct
RegDst MemtoReg
|     |     |     |       | CLK          |     |     |         |     | CLK |     |     | CLK | 1   |         |     |           |        |     |
| --- | --- | --- | ----- | ------------ | --- | --- | ------- | --- | --- | --- | --- | --- | --- | ------- | --- | --------- | ------ | --- |
|     |     |     |       |              | 0   |     |         |     |     |     | 0   |     |     |         |     |           |        |     |
|     |     | CLK |       |              |     | CLK |         |     |     |     |     |     |     |         |     |           |        |     |
|     |     |     |       |              |     |     |         |     |     |     |     |     | 0   | SrcA    | 010 |           |        |     |
|     |     |     | X     |              | WE  |     |         |     |     | WE3 |     | A   |     |         |     | Zero      | CLK    | X   |
|     |     |     |       |              |     |     | 25:21   |     | A1  |     | RD1 |     | 1   |         |     |           |        |     |
|     | PC' | PC  |       |              |     |     | Instr   |     |     |     |     |     |     | 10      |     |           |        | 0   |
|     |     |     | 0 Adr |              | RD  |     |         |     |     |     |     | B   |     |         | ULA |           |        |     |
|     |     |     |       | A            |     |     | 20:16   |     | A2  |     | RD2 |     |     | 00      |     | ALUResult | ALUOut |     |
|     |     | EN  |       |              |     | EN  |         |     |     |     |     |     |     |         |     |           |        | 1   |
|     |     |     | 1     |              |     |     |         | X   |     |     |     |     |     |         |     |           |        |     |
|     |     |     |       | Instr / Data |     |     |         |     |     |     |     |     | 4   | 01 SrcB |     |           |        |     |
|     |     | 0   |       |              |     |     | 0 20:16 | 0   |     |     |     |     |     |         |     |           |        |     |
Memory
|     |     |     |     |     |     |     |       |     | A3  |          |      |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | CLK | 15:11 | 1   |     | Register |      |     |     |     |     |     |     |     |
|     |     |     |     | WD  |     |     |       |     | X   |          |      |     |     | 11  |     |     |     |     |
|     |     |     |     |     |     |     |       |     | 0   |          | File |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     | Data  |     | WD3 |          |      |     |     |     |     |     |     |     |
1
<<2
SignImm
15:0
Sign Extend
Chapter 7 <53>

Main Controller FSM: Address
ERUTCETIHCRAORCIM
|     |     | S0: Fetch |     |     | S1: Decode |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --------- | --- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
IorD = 0
|     | Reset |     | AluSrcA = 0 |     |     |     |     |     |     |     |     |     |     | ALUOut = A + sext(imm) |     |     |     |     |     |     |
| --- | ----- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---------------------- | --- | --- | --- | --- | --- | --- |
AluSrcA = 0
ALUSrcB = 01
|     |     |     | ALUOp = 00 |     |     |     | AluSrcB = 11 |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---------- | --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
PCSrc = 0
ALUOP = 00
IRWrite
PCWrite
Op = LW
or
CLK
| S2: MemAdr   |     | Op = SW |     |     |     |     |     |          |         |            |     |     |     |     |     |     |     |     |      |     |
| ------------ | --- | ------- | --- | --- | --- | --- | --- | -------- | ------- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- |
|              |     |         |     |     |     |     |     |          |         | PCWrite    |     |     |     |     |     |     |     |     | 0    |     |
|              |     |         |     |     |     |     |     |          |         | Branch     |     |     |     |     |     |     |     | 0   | PCEn |     |
|              |     |         |     |     |     |     |     | IorD     | Control | PCSrc      |     |     |     |     |     |     |     |     |      |     |
| ALUSrcA = 1  |     |         |     |     |     |     |     |          | Unit    | ALUControl |     |     |     |     |     |     |     |     |      |     |
|              |     |         |     |     |     |     |     | MemWrite |         |            |     | 2:0 |     |     |     |     |     |     |      |     |
| ALUSrcB = 10 |     |         |     |     |     |     |     | IRWrite  |         | ALUSrcB    |     |     |     |     |     |     |     |     |      |     |
1:0
| ALUOp = 00 |     |     |     |     |     |     |     |     |     | ALUSrcA |     |     |     |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
31:26 Op
RegWrite
5:0 Funct
RegDst MemtoReg
|     |     |     |     |       | CLK          |     |     |         |     | CLK |     |     | CLK |     | 1   |      |     |           |        |     |
| --- | --- | --- | --- | ----- | ------------ | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --------- | ------ | --- |
|     |     |     |     |       |              | 0   |     |         |     |     |     | 0   |     |     |     |      |     |           |        |     |
|     |     |     | CLK |       |              |     | CLK |         |     |     |     |     |     |     |     |      |     |           |        |     |
|     |     |     |     |       |              |     |     |         |     |     |     |     |     | 0   |     | SrcA | 010 |           |        |     |
|     |     |     |     | X     |              | WE  |     |         |     |     | WE3 |     | A   |     |     |      |     | Zero      | CLK    | X   |
|     |     |     |     |       |              |     |     | 25:21   |     | A1  |     | RD1 |     | 1   |     |      |     |           |        |     |
|     |     | PC' | PC  |       |              |     |     | Instr   |     |     |     |     |     |     |     | 10   |     |           |        | 0   |
|     |     |     |     | 0 Adr |              | RD  |     |         |     |     |     |     | B   |     |     |      | ULA |           |        |     |
|     |     |     |     |       | A            |     |     | 20:16   |     | A2  |     | RD2 |     |     | 00  |      |     | ALUResult | ALUOut |     |
|     |     |     | EN  |       |              |     | EN  |         |     |     |     |     |     |     |     |      |     |           |        | 1   |
|     |     |     |     | 1     |              |     |     |         | X   |     |     |     |     |     |     |      |     |           |        |     |
|     |     |     |     |       | Instr / Data |     |     |         |     |     |     |     |     | 4   | 01  | SrcB |     |           |        |     |
|     |     |     | 0   |       |              |     |     | 0 20:16 | 0   |     |     |     |     |     |     |      |     |           |        |     |
Memory
|     |     |     |     |     |     |     |     |       |     | A3  |          |      |     |     | 10  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | -------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     | CLK | 15:11 | 1   |     | Register |      |     |     |     |     |     |     |     |     |
|     |     |     |     |     | WD  |     |     |       |     | X   |          |      |     |     | 11  |     |     |     |     |     |
|     |     |     |     |     |     |     |     |       |     | 0   |          | File |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     | Data  |     | WD3 |          |      |     |     |     |     |     |     |     |     |
1
<<2
SignImm
15:0
Sign Extend
Chapter 7 <54>

Chapter 7 <55>
ERUTCETIHCRAORCIM
Main Controller FSM: lw
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0 AluSrcA = 0
ALUSrcB = 01
ALUOp = 00 AluSrcB = 11
PCSrc = 0
ALUOP = 00
IRWrite
PCWrite
Op = LW
or
S2: MemAdr Op = SW
ALUSrcA = 1
ALUSrcB = 10
ALUOp = 00
Op = LW
S3: MemRead
MDR = M[ALUOut]
IorD = 1
S4: Mem
Writeback
GPR[Rt] = MDR
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <56>
ERUTCETIHCRAORCIM
Main Controller FSM: sw
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0 AluSrcA = 0
ALUSrcB = 01
ALUOp = 00 AluSrcB = 11
PCSrc = 0
ALUOP = 00
IRWrite
PCWrite
Op = LW
or
S2: MemAdr Op = SW
ALUSrcA = 1
ALUSrcB = 10
ALUOp = 00
Op = SW
Op = LW
S5: MemWrite
S3: MemRead
IorD = 1
IorD = 1 M[ALUOut] = B
MemWrite
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <57>
ERUTCETIHCRAORCIM
Main Controller FSM: R-Type
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0 AluSrcA = 0
ALUSrcB = 01
ALUOp = 00 AluSrcB = 11
PCSrc = 0
ALUOP = 00
IRWrite
PCWrite
Op = LW
Op = R-type
or
S2: MemAdr Op = SW
S6: Execute
ALUSrcA = 1 ALUSrcA = 1 ALUOut = A op B
ALUSrcB = 10 ALUSrcB = 00
ALUOp = 00 ALUOp = 10
Op = SW
Op = LW S7: ALU
S5: MemWrite
Writeback
S3: MemRead
RegDst = 1
IorD = 1 GPR[Rd] = ALUOut
IorD = 1 MemtoReg = 0
MemWrite
RegWrite
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <58>
ERUTCETIHCRAORCIM
Main Controller FSM: beq
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0
ALUSrcB = 01 ALUSrcA = 0
ALUOp = 00 ALUSrcB = 11
PCSrc = 0 ALUOp = 00
IRWrite
PCWrite
Op = BEQ
Op = LW
Op = R-type
or
S2: MemAdr Op = SW
S6: Execute
S8: Branch
ALUSrcA = 1
If A-B==0
ALUSrcA = 1 ALUSrcA = 1 ALUSrcB = 00
ALUSrcB = 10 ALUSrcB = 00 ALUOp = 01
PC= ALUOut
ALUOp = 00 ALUOp = 10 PCSrc = 1
Branch
Op = SW
Op = LW S7: ALU
S5: MemWrite
Writeback
S3: MemRead
RegDst = 1
IorD = 1
IorD = 1 MemtoReg = 0
MemWrite
RegWrite
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <59>
ERUTCETIHCRAORCIM
Multicycle Controller FSM
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0
ALUSrcB = 01 ALUSrcA = 0
ALUOp = 00 ALUSrcB = 11
PCSrc = 0 ALUOp = 00
S = State IRWrite
PCWrite
Op = BEQ
Op = LW
Op = R-type
or
S2: MemAdr Op = SW
S6: Execute
S8: Branch
ALUSrcA = 1
ALUSrcA = 1 ALUSrcA = 1 ALUSrcB = 00
ALUSrcB = 10 ALUSrcB = 00 ALUOp = 01
ALUOp = 00 ALUOp = 10 PCSrc = 1
Branch
Op = SW
Op = LW S7: ALU
S5: MemWrite
Writeback
S3: MemRead
RegDst = 1
IorD = 1
IorD = 1 MemtoReg = 0
MemWrite
RegWrite
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <60>
ERUTCETIHCRAORCIM
Extended Functionality: addi
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0
ALUSrcB = 01 ALUSrcA = 0
ALUOp = 00 ALUSrcB = 11
PCSrc = 0 ALUOp = 00
IRWrite
PCWrite
Op = ADDI
Op = BEQ
Op = LW
Op = R-type
or
S2: MemAdr Op = SW
S6: Execute S9: ADDI
S8: Branch
Execute
ALUSrcA = 1
ALUSrcA = 1 ALUSrcA = 1 ALUSrcB = 00
ALUSrcB = 10 ALUSrcB = 00 ALUOp = 01
ALUOp = 00 ALUOp = 10 PCSrc = 1
Branch
Op = SW
Op = LW S7: ALU
S5: MemWrite S10: ADDI
Writeback
S3: MemRead Writeback
RegDst = 1
IorD = 1
IorD = 1 MemtoReg = 0
MemWrite
RegWrite
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Chapter 7 <61>
ERUTCETIHCRAORCIM
Main Controller FSM: addi
S0: Fetch S1: Decode
IorD = 0
Reset AluSrcA = 0
ALUSrcB = 01 ALUSrcA = 0
ALUOp = 00 ALUSrcB = 11
PCSrc = 0 ALUOp = 00
IRWrite
PCWrite
Op = ADDI
Op = BEQ ALUOut =A +Sext(imm)
Op = LW
Op = R-type
or
S2: MemAdr Op = SW
S6: Execute S9: ADDI
S8: Branch
Execute
ALUSrcA = 1
ALUSrcA = 1 ALUSrcA = 1 ALUSrcB = 00 ALUSrcA = 1
ALUSrcB = 10 ALUSrcB = 00 ALUOp = 01 ALUSrcB = 10
ALUOp = 00 ALUOp = 10 PCSrc = 1 ALUOp = 00
Branch
Op = SW
Op = LW S7: ALU
S5: MemWrite S10: ADDI
Writeback
S3: MemRead Writeback
RegDst = 1 RegDst = 0
IorD = 1
IorD = 1 MemtoReg = 0 MemtoReg = 0
MemWrite
RegWrite RegWrite
GPR[Rt] = ALUOut
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite

Extended Functionality: j
ERUTCETIHCRAORCIM
PCEn
IorD MemWrite IRWrite RegDst MemtoReg RegWrite ALUSrcA ALUSrcB ALUControl Branch PCWrite PCSrc
|     |     |     |     |     |     |     |     |     | 1:0  | 2:0 |     | 1:0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     |     | CLK |     |     | CLK | CLK |     |     |      |     |     |     |
| CLK |     |     | CLK |     |     |     |     |     |      |     |     |     |
|     |     |     |     |     |     |     |     | 0   | SrcA |     |     |     |
CLK
|     |     | WE  |       |       | WE3 |     | A 31:28 |     |     | Zero |     |     |
| --- | --- | --- | ----- | ----- | --- | --- | ------- | --- | --- | ---- | --- | --- |
| PC' | PC  |     | Instr | 25:21 | A1  | RD1 |         | 1   |     |      |     |     |
00
|     | 0 Adr | RD  |     |       |     |     | B   |     |     | ULA       |        |     |
| --- | ----- | --- | --- | ----- | --- | --- | --- | --- | --- | --------- | ------ | --- |
|     |       | A   |     | 20:16 | A2  | RD2 |     | 00  |     | ALUResult | ALUOut |     |
|     | EN    |     | EN  |       |     |     |     |     |     |           |        | 01  |
1
|     |     | Instr / Data |     |       |     |     |     | 4 01 |      |     |     |     |
| --- | --- | ------------ | --- | ----- | --- | --- | --- | ---- | ---- | --- | --- | --- |
|     |     |              |     | 20:16 |     |     |     |      | SrcB |     |     | 10  |
0
|     |     | Memory |     |     | A3  |     |     | 10  |     |     |     |     |
| --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
15:11
|     |     |     | CLK  | 1   | Register |     |     |     |     |     | PCJump |     |
| --- | --- | --- | ---- | --- | -------- | --- | --- | --- | --- | --- | ------ | --- |
|     |     | WD  |      |     |          |     |     | 11  |     |     |        |     |
|     |     |     |      | 0   | File     |     |     |     |     |     |        |     |
|     |     |     | Data |     | WD3      |     |     |     |     |     |        |     |
1
<<2
<<2 27:0
SignImm
|     |     |     |     | 15:0 | Sign Extend |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ---- | ----------- | --- | --- | --- | --- | --- | --- | --- |
25:0 (jump)
Chapter 7 <62>

Main Controller FSM: j
ERUTCETIHCRAORCIM
S0: Fetch S1: Decode
IorD = 0
S11: Jump
| Reset | AluSrcA = 0  |              |     |        |     |
| ----- | ------------ | ------------ | --- | ------ | --- |
|       | ALUSrcB = 01 | ALUSrcA = 0  |     |        |     |
|       | ALUOp = 00   | ALUSrcB = 11 |     | Op = J |     |
|       | PCSrc = 00   | ALUOp = 00   |     |        |     |
IRWrite
PCWrite
Op = ADDI
Op = BEQ
Op = LW
|     | or  | Op = R-type |     |     |     |
| --- | --- | ----------- | --- | --- | --- |
S2: MemAdr
Op = SW
S6: Execute S9: ADDI
S8: Branch
Execute
ALUSrcA = 1
| ALUSrcA = 1  |     |     | ALUSrcA = 1  | ALUSrcB = 00 | ALUSrcA = 1  |
| ------------ | --- | --- | ------------ | ------------ | ------------ |
| ALUSrcB = 10 |     |     | ALUSrcB = 00 | ALUOp = 01   | ALUSrcB = 10 |
| ALUOp = 00   |     |     | ALUOp = 10   | PCSrc = 01   | ALUOp = 00   |
Branch
Op = SW
| Op = LW |     | S7: ALU |     |     |     |
| ------- | --- | ------- | --- | --- | --- |
S5: MemWrite S10: ADDI
Writeback
S3: MemRead
Writeback
|     |     |     | RegDst = 1 |     | RegDst = 0 |
| --- | --- | --- | ---------- | --- | ---------- |
IorD = 1
| IorD = 1 |     |     | MemtoReg = 0 |     | MemtoReg = 0 |
| -------- | --- | --- | ------------ | --- | ------------ |
MemWrite
|     |     |     | RegWrite |     | RegWrite |
| --- | --- | --- | -------- | --- | -------- |
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite
Chapter 7 <63>

Main Controller FSM: j
ERUTCETIHCRAORCIM
S0: Fetch S1: Decode
IorD = 0
S11: Jump
| Reset | AluSrcA = 0  |              |     |        |     | PC= j adrs |
| ----- | ------------ | ------------ | --- | ------ | --- | ---------- |
|       | ALUSrcB = 01 | ALUSrcA = 0  |     |        |     |            |
|       | ALUOp = 00   | ALUSrcB = 11 |     | Op = J |     |            |
PCSrc = 10
|     | PCSrc = 00 | ALUOp = 00 |     |     |     |     |
| --- | ---------- | ---------- | --- | --- | --- | --- |
PCWrite
IRWrite
PCWrite
Op = ADDI
Op = BEQ
Op = LW
|                    | or  | Op = R-type |     |     |     |     |
| ------------------ | --- | ----------- | --- | --- | --- | --- |
| S2: MemAdr Op = SW |     |             |     |     |     |     |
S6: Execute S9: ADDI
S8: Branch
Execute
ALUSrcA = 1
| ALUSrcA = 1  |     |     | ALUSrcA = 1  | ALUSrcB = 00 | ALUSrcA = 1  |     |
| ------------ | --- | --- | ------------ | ------------ | ------------ | --- |
| ALUSrcB = 10 |     |     | ALUSrcB = 00 | ALUOp = 01   | ALUSrcB = 10 |     |
| ALUOp = 00   |     |     | ALUOp = 10   | PCSrc = 01   | ALUOp = 00   |     |
Branch
Op = SW
| Op = LW |     | S7: ALU |     |     |     |     |
| ------- | --- | ------- | --- | --- | --- | --- |
S5: MemWrite
Writeback S10: ADDI
S3: MemRead
Writeback
|     |     |     | RegDst = 1 |     | RegDst = 0 |     |
| --- | --- | --- | ---------- | --- | ---------- | --- |
IorD = 1
| IorD = 1 |     |     | MemtoReg = 0 |     | MemtoReg = 0 |     |
| -------- | --- | --- | ------------ | --- | ------------ | --- |
MemWrite
|     |     |     | RegWrite |     | RegWrite |     |
| --- | --- | --- | -------- | --- | -------- | --- |
S4: Mem
Writeback
RegDst = 0
MemtoReg = 1
RegWrite
Chapter 7 <64>

Chapter 7 <65>
ERUTCETIHCRAORCIM
Multicycle Processor Performance
 Instructions take different number of cycles:
 3 cycles: beq, j
 4 cycles: R-Type, sw, addi
https://www.spec.org/cpu2000/results/
 5 cycles: lw
 CPI is weighted average
 SPECINT2000 benchmark:
 25% loads
 10% stores
 11% branches
 2% jumps
 52% R-type
ץבוק תוארהל :ימצעל הרעה
Average CPI = (0.11 + 0.02)*3 + (0.52 + 0.10)*4 + (0.25)*5 = 4.12 המגודל םיעוציב ןחבמ תואצות
branch
R type
jump load
store

Multicycle Processor Performance
ERUTCETIHCRAORCIM
Multicycle critical path:
יטירקה ביתנל תועובק תומורת

|     |     |     | T  = t |     |  + t |     |  + max(t |      | + t |     | , t |     | ) + t |     |       |     |     |     |
| --- | --- | --- | ------ | --- | ---- | --- | -------- | ---- | --- | --- | --- | --- | ----- | --- | ----- | --- | --- | --- |
|     |     |     | c      | pcq |      | mux |          | ALU  |     | mux |     | mem |       |     | setup |     |     |     |
םייתשה ןיבמ רימחמה
CLK
PCWrite
PCEn
Branch
|     |     |     |     |     |     |     | IorD Control | PCSrc |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------------ | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Unit ALUControl
MemWrite
2:0
ALUSrcB
|     |     |     |     |     |     |     | IRWrite |         | 1:0 |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     | 31:26   | ALUSrcA |     |     |     |     |     |     |     |     |     |     |
Op
RegWrite
5:0
Funct
RegDst MemtoReg
|     |     |     | CLK |     |     |     |       | CLK |     |     | CLK |     |     |     |      |           |        |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | ---- | --------- | ------ | --- |
|     | CLK |     |     |     |     | CLK |       |     |     |     |     |     |     |     |      |           |        |     |
|     |     |     |     |     |     |     |       |     |     |     |     |     | 0   |     | SrcA |           |        |     |
|     |     |     |     | WE  |     |     |       |     | WE3 |     |     |     |     |     |      | Zero      | CLK    |     |
|     |     |     |     |     |     |     | 25:21 |     |     |     |     | A   |     |     |      |           |        |     |
| PC' | PC  |     |     |     |     |     | Instr | A1  |     | RD1 |     |     | 1   |     |      |           |        | 0   |
|     |     | 0   |     |     | RD  |     |       |     |     |     |     |     |     |     |      | ULA       |        |     |
|     |     |     | Adr |     |     |     | 20:16 |     |     |     |     | B   |     |     |      | ALUResult | ALUOut |     |
|     | EN  |     | A   |     |     | EN  |       | A2  |     | RD2 |     |     |     | 00  |      |           |        | 1   |
1
|     |     |     | Instr / Data |     |     |     |     |     |     |     |     |     | 4   | 01  | SrcB |     |     |     |
| --- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
20:16 0
Memory
|     |     |     |     |     |     |     |         | A3  |          |     |     |     |     | 10  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | CLK | 15:11 1 |     | Register |     |     |     |     |     |     |     |     |     |
|     |     |     | WD  |     |     |     |         |     |          |     |     |     |     | 11  |     |     |     |     |
0 File
|     |     |     |     |     |     |     | Data | WD3 |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
1
<<2
SignImm
15:0
Sign Extend
Chapter 7 <66>

Multicycle Performance Example
ERUTCETIHCRAORCIM
| Element             | Parameter | Delay (ps) |
| ------------------- | --------- | ---------- |
| Register clock-to-Q | t         | 30         |
pcq_PC
| Register setup | t   | 20  |
| -------------- | --- | --- |
setup
| Multiplexer | t   | 25  |
| ----------- | --- | --- |
mux
| ALU |     | 200 |
| --- | --- | --- |
t
ALU
| Memory read | t   | 250 |
| ----------- | --- | --- |
mem
| Register file read |     | 150 |
| ------------------ | --- | --- |
t
RFread
| Register file setup | t   | 20  |
| ------------------- | --- | --- |
RFsetup
T  = ?
c
Chapter 7 <67>

Multicycle Performance Example
ERUTCETIHCRAORCIM
| Element             |     |     |     | Parameter |     |     |     | Delay (ps) |     |
| ------------------- | --- | --- | --- | --------- | --- | --- | --- | ---------- | --- |
| Register clock-to-Q |     |     |     | t         |     |     |     | 30         |     |
pcq_PC
| Register setup |     |     |     |     |     |     |     | 20  |     |
| -------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
t
setup
| Multiplexer |     |     |     | t   |     |     |     | 25  |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
mux
| ALU |     |     |     | t   |     |     |     | 200 |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ALU
| Memory read |     |     |     |     |     |     |     | 250 |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
t
mem
| Register file read |     |     |     |     |     |     |     | 150 |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- | --- | --- |
t
RFread
| Register file setup |     |     |     | t   |     |     |     | 20  |     |
| ------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
RFsetup
| T  = t  |        |  + t |  + max(t |      |       | + t | , t | ) + t |       |
| ------- | ------ | ---- | -------- | ---- | ----- | --- | --- | ----- | ----- |
| c       | pcq_PC |      | mux      |      | ALU   | mux | mem |       | setup |
|     = t |        |  + t |  + t     |  + t |       |     |     |       |       |
|         | pcq_PC |      | mux      | mem  | setup |     |     |       |       |
    = [30 + 25 + 250 + 20] ps
    = 325 ps
Chapter 7 <68>

Multicycle Performance Example
ERUTCETIHCRAORCIM
| Element             | Parameter | Delay (ps) |
| ------------------- | --------- | ---------- |
| Register clock-to-Q | t         | 30         |
pcq_PC
| Register setup |     | 20  |
| -------------- | --- | --- |
t
setup
| Multiplexer | t   | 25  |
| ----------- | --- | --- |
mux
| ALU | t   | 200 |
| --- | --- | --- |
ALU
| Memory read |     | 250 |
| ----------- | --- | --- |
t
mem
| Register file read |     | 150 |
| ------------------ | --- | --- |
t
RFread
| Register file setup | t   | 20  |
| ------------------- | --- | --- |
RFsetup
T  = ?
c
 אוה הדוקפל עצוממ ןמז זא  4.12 לש CPI חיננ םא .תוינש-וקיפ  325אוה לבקתמה רוזחמה ןמז
.)תוינש-וננ  1.339(  תוינש-וקיפ 1339
.תוינש 133.9 היהי ללוכה ןמזה תולועפ דראלימ  100 רובעו
Chapter 7 <69>

Chapter 7 <70>
ERUTCETIHCRAORCIM
Multicycle Performance Example
 For a program with 100 billion instructions executing on a multicycle MIPS processor
 CPI = 4.12
 T = 325 ps
c
=> T = 4.12 * 325 ps = 1339 ps
inst
Execution Time =
The single cycle was faster
T = T = 925 ps
inst C
925ps-ה ועיגה ןכיהמ הארנ ףכת

Chapter 7 <72>
ERUTCETIHCRAORCIM
Multicycle Performance Example
Program with 100 billion instructions
Execution Time =
(# instructions) × CPI × T
c
= (100 × 109)(4.12)(325 × 10-12)
= 133.9 seconds
This is slower than the single-cycle processor (92.5
seconds). Why?
Not all steps same length
Sequencing overhead for each step (t + t = 50 ps)
pcq setup
זא ,הארוהב םידעצ 8 םנשי עצוממבש לשמל חיננ םא
...רעפה תא ריבסהל לוכי הזו 1325=925+400 זאו 8X50=400

erutcetihcrAORCIM
Single-Cycle Performance
 Single-cycle critical path:
H&H Eq. 7.2
| T  = t |     |  + t |     |  + max(t |     |     | , t |  + t |     | ) + t |  + t |     |
| ------ | --- | ---- | --- | -------- | --- | --- | --- | ---- | --- | ----- | ---- | --- |

| c   | pcq_PC |         | mem |     |     | RFread |     | sext | mux |     | ALU | mem |
| --- | ------ | ------- | --- | --- | --- | ------ | --- | ---- | --- | --- | --- | --- |
| + t |  + t   |         |     |     |     |        |     |      |     |     |     |     |
|     | mux    | RFsetup |     |     |     |        |     |      |     |     |     |     |
 Typically, limiting paths are:
 memory, ALU, register file
H&H Eq. 7.3
|    | T  = t |        |  + 2t |     |  + t |        |  + t |  + t |     |  + t |         |     |
| --- | ------ | ------ | ----- | --- | ---- | ------ | ---- | ---- | --- | ---- | ------- | --- |
|     | c      | pcq_PC |       | mem |      | RFread |      | mux  | ALU |      | RFsetup |     |
Chapter 7 <73>

Chapter 7 <74>
erutcetihcrAORCIM תרוכזת
Guy

Guy

Credit: Harris & Harris, Figure 3.48

erutcetihcrAORCIM
Single-Cycle Performance Example
| Element             |     |     | Parameter |     |     | Delay (ps) |     |
| ------------------- | --- | --- | --------- | --- | --- | ---------- | --- |
| Register clock-to-Q |     |     |           |     |     | 30         |     |
t
pcq_PC
| Register setup |     |     | t   |     |     | 20  |     |
| -------------- | --- | --- | --- | --- | --- | --- | --- |
setup
| Multiplexer |     |     |     |     |     | 25  |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- |
t
mux
| ALU |     |     | t   |     |     | 200 |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
ALU
| Memory read |     |     | t   |     |     | 250 |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- |
mem
| Register file read |     |     |     |     |     | 150 |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- |
t
RFread
| Register file setup |     |     |     |     |     | 20  |     |
| ------------------- | --- | --- | --- | --- | --- | --- | --- |
t
RFsetup
| T  = t   |  + 2t |     |  + t   |  + t |  + t |     |  + t    |
| -------- | ----- | --- | ------ | ---- | ---- | --- | ------- |
| c pcq_PC |       | mem | RFread |      | mux  | ALU | RFsetup |
    = [30 + 2(250) + 150 + 25 + 200 + 20] ps
    = 925 ps
Chapter 7 <75>

Chapter 7 <76>
erutcetihcrAORCIM
Single-Cycle Performance
Example
Program with 100 billion instructions:
Execution Time = # instructions x CPI x T
C
= (100 × 109)(1)(925 × 10-12 s)
= 92.5 seconds

Review: Single-Cycle Processor    םוכיסל
ERUTCETIHCRAORCIM
Jump
MemtoReg
Control
MemWrite
Unit
Branch
PCSrc
ALUControl
2:0
31:26
Op ALUSrc
5:0 Funct RegDst
RegWrite
|     |     |     | CLK |     |     | CLK |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
CLK
| 0   |     |     | WE3 |     | SrcA | Zero | WE  |     |
| --- | --- | --- | --- | --- | ---- | ---- | --- | --- |
25:21
| 0 PC' | PC   | Instr | A1  | RD1 |     |           |          | 0      |
| ----- | ---- | ----- | --- | --- | --- | --------- | -------- | ------ |
| 1     | A RD |       |     |     |     | ULA       |          | Result |
|       |      |       |     |     |     | ALUResult | ReadData |        |
1
|     |     |     |     |     |     | A   | RD  | 1   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Instruction
|     |     | 20:16 | A2  | RD2 | 0    |     |      |     |
| --- | --- | ----- | --- | --- | ---- | --- | ---- | --- |
|     |     |       |     |     | SrcB |     | Data |     |
Memory
|     |     |     | A3  |     | 1   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Memory
|     |     |     | Register |     |     | WriteData |     |     |
| --- | --- | --- | -------- | --- | --- | --------- | --- | --- |
|     |     |     | WD3      |     |     | WD        |     |     |
File
20:16
0
PCJump
15:11 1
WriteReg
4:0
PCPlus4
+
SignImm
<<2
|     | 4   | 15:0 |     |     |     |     |     |     |
| --- | --- | ---- | --- | --- | --- | --- | --- | --- |
Sign Extend
PCBranch
+
27:0 31:28
25:0
<<2
Chapter 7 <77>

Review: Multicycle Processor
ERUTCETIHCRAORCIM
CLK
PCWrite
PCEn
Branch
IorD Control PCSrc
Unit ALUControl
MemWrite
2:0
ALUSrcB
IRWrite
1:0
31:26 ALUSrcA
Op
5:0 RegWrite
Funct
RegDst MemtoReg
|     |     | CLK |     | CLK | CLK |     |     |      |      |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---- | ---- | --- | --- |
| CLK |     |     | CLK |     |     |     |     |      |      |     |     |
|     |     |     |     |     |     |     | 0   | SrcA |      |     |     |
|     |     | WE  |     | WE3 |     |     |     |      | Zero | CLK |     |
A 31:28
| PC' PC |     |              | Instr 25:21 | A1  | RD1 |     | 1    |      |           |        |     |
| ------ | --- | ------------ | ----------- | --- | --- | --- | ---- | ---- | --------- | ------ | --- |
|        | 0   | RD           |             |     |     |     |      |      |           |        | 00  |
|        | Adr |              |             |     |     | B   |      | ULA  |           |        |     |
| EN     |     | A            | EN 20:16    | A2  | RD2 |     | 00   |      | ALUResult | ALUOut |     |
|        | 1   |              |             |     |     |     |      |      |           |        | 01  |
|        |     | Instr / Data |             |     |     |     | 4 01 | SrcB |           |        |     |
20:16 0 10
|     |     | Memory |     | A3  |     |     | 10  |     |     |     |     |
| --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- |
15:11 1 PCJump
|     |     |     | CLK  | Register |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | -------- | --- | --- | --- | --- | --- | --- | --- |
|     |     | WD  |      |          |     |     | 11  |     |     |     |     |
|     |     |     | 0    | File     |     |     |     |     |     |     |     |
|     |     |     | Data | WD3      |     |     |     |     |     |     |     |
1
<<2
27:0
<<2
ImmExt
15:0 Sign Extend
25:0 (Addr)
Chapter 7 <78>

Chapter 7 <79>
ERUTCETIHCRAORCIM
לש רפסהמ 7 קרפ ךותמ םיפקש ןאכ דע
H&H

D חפסנ הניה וז תגצמ
Computer Organization and Design רפסהמ
CO&D (5th Edition)
רנדיז ינדו רוצ-לת איג תאמ םירבסהו תופסות ’סמ םע
AAppppeennddiixx D
Mapping Control to Hardware
I) Single Cycle control
II) Multi-Cycle FSM control
III) Multi-Cycle MicroProgram control
Last modification 29/3/2021 Copyright © 2014 Elsevier Inc. All rights reserved.

Single Cycle Control
Copyright © 2014 Elsevier Inc. All rights reserved.

Single-Cysicnlegl eC ocynctlero -בl רקבה
Control
Unit
MemtoReg
MemWrite
Branch
Opcode
Main
5:0
ALUSrc
Decoder
RegDst
RegWrite
ALUOp
1:0
ALU
Funct ALUControl
5:0 2:0
Decoder
Also called ALU Control
Credit: H&H Ch. 7

single cycle -ב  רקבה לש תמאה תלבט וז
Figure 4.18 from H&P CO&D
Instruction Op RegWrite RegDst AluSrc Branch MemWrite MemtoReg ALUOp
|        | 5:0    |     |     |     |     |     |     | 1:0 |
| ------ | ------ | --- | --- | --- | --- | --- | --- | --- |
| R-type | 000000 | 1   | 1   | 0   | 0   | 0   | 0   | 10  |
|        | 100011 | 1   | 0   | 1   | 0   | 0   | 1   | 00  |
lw
|     | 101011 | 0   | X   | 1   | 0   | 1   | X   | 00  |
| --- | ------ | --- | --- | --- | --- | --- | --- | --- |
sw
|     | 000100 | 0   | X   | 0   | 1   | 0   | X   | 01  |
| --- | ------ | --- | --- | --- | --- | --- | --- | --- |
beq
From H&H Chapter 7

לש םירעשב שומימה
םדוקה ףקשהמ תמאה תלבט
FIGURE D.2.5 The structured implementation of the control function as described by the truth table in Figure
D.2.4. The structure, called a programmable logic array (PLA), uses an array of AND gates followed by an array
of OR gates. The inputs to the AND gates are the function inputs and their inverses (bubbles indicate inversion of a
signal). The inputs to the OR gates are the outputs of the AND gates (or, as a degenerate case, the function inputs
and inverses). The output of the OR gates is the function outputs.
84
Copyright © 2014 Elsevier Inc. All rights reserved.

ALU - המ תשרדנה תוילנויצקנופה וז
16 לעמ הכימת ןיא ונלש ידומילה דבעמב( טיב 4 ידי לע טלשנ ALU -ה
)תוארוה
FIGURE 4.12 How the ALU control bits are set depends on the ALUOp control bits and the different function codes for the
R-type instruction. The opcode, listed in the first column, determines the setting of the ALUOp bits. All the encodings are
shown in binary. Notice that when the ALUOp code is 00 or 01, the desired ALU action does not depend on the function
code field; in this case, we say that we “don’t care” about the value of the function code, and the funct field is shown as
XXXXXX. When the ALUOp value is 10, then the function code is used to set the ALU control input. See Appendix B.
85
Copyright © 2014 Elsevier Inc. All rights reserved.

ALU decoder -ה לש תמאה תלבט וז
)ALU control םג ארקנש(
Add
Sub
Add
Sub
AND
OR
SLT
אל םיטיבה 2
םילצונמ
FIGURE D.2.1 The truth table for the 4 ALU control bits (called Operation) as a function of the ALUOp and function code field. This table is the same as
that shown in Figure 4.13.
CO&D -ב 4.13 רויאכ םג עיפומ הז רויא
הלבטב 2-ו 1 הרוש גוזימ :םיאבה םילדבהב תמדוקה הלבטה ומכ איה וז הלבט
.יטנוולר וניא ךרעהש ןכיה X-ל הפלחהו תמדוקה
86
Copyright © 2014 Elsevier Inc. All rights reserved.

ALU Control -ה לש שומימה הזו
אל )4,5( םיטיבה 2
םילצונמ
FIGURE D.2.3 The ALU control block generates the four ALU control bits, based on the function code and
ALUOp bits. This logic is generated directly from the truth table in Figure D.2.2. Only four of the six bits in the
function code are actually needed as inputs, since the upper two bits are always don’t cares. Let’s examine how
this logic relates to the truth table of Figure D.2.2. Consider the Operation2 output, which is generated by two lines
in the truth table for Operation2. The second line is the AND of two terms (F1 5 1 and ALUOp1 5 1); the top two-
input AND gate corresponds to this term. The other term that causes Operation2 to be asserted is simply ALUOp0.
These two terms are combined with an OR gate whose output is Operation2. The outputs Operation0 and
Operation1 are derived in similar fashion from the truth table. Since Operation3 is always 0, we connect a signal
and its complement as inputs to an AND gate to generate 0.
87
Copyright © 2014 Elsevier Inc. All rights reserved.

Multi-Cycle Control
Copyright © 2014 Elsevier Inc. All rights reserved.

Multi-cycle -ב רקבה
תותוא רתוי
Control
MemtoReg
הרקב
Unit
RegDst
IorD
Multiplexer
םייפוס םיבצמ תנוכמ
PCSrc Selects
Main
ALUSrcB
Controller 1:0
Opcode ALUSrcA
5:0 (FSM)
IRWrite
MemWrite
Register
PCWrite
Enables
Branch
RegWrite
ALUOp
1:0
ALU
Funct ALUControl
5:0 Decoder 2:0
Credit: H&H Ch. 7 Also called ALU Control

FSM
הז םישרתב
10 םיראותמ
םיבצמ
*
FIGURE D.3.1 The finite-state diagram for multi-cycle control.
90
Copyright © 2014 Elsevier Inc. All rights reserved.

#
16 lines
20 כ"הס
2 lines
תואיצי
FSM -ה םישרתב
,םיבצמ 10 שי ונלש
דדוקל ןתינ ןכל
4 תועצמאב םתוא
)...ףדועב...( םיטיב
תוסינכ 10 כ"הס
S = State
NS = Next State
FIGURE D.3.2 The control unit for MIPS will consist of some control logic and a register to hold the state. The state register is written at the
active clock edge and is stable during the clock cycle
Next State = f ( Opecode, Current State)
91
Copyright © 2014 Elsevier Inc. All rights reserved.

תמאה תואלבט תא תונבל הנושאר ךרד
Copyright © 2014 Elsevier Inc. All rights reserved.

?Output-ה יולת ימב
$
םייולת ,הרקב יווק 16
בצמב קר םיקיר םיכרע
don’t בצמ םיגציימ
care
ףקש ואר ,םיבצמ 10
םייולת םיבצמה .*
OP-בו בצמב
*
םישרתה תרזעב אלמל ןתינ הלבטה תא
FIGURE D.3.3 The logic equations for the control unit shown in a shorthand form. Remember that “1” stands for OR in logic equations. The
state inputs and NextState outputs must be expanded by using the state encoding. Any blank entry is a don’t care.
93
Copyright © 2014 Elsevier Inc. All rights reserved.

** opcode -בו S[3:0] -ב תולתב NS[3:0] לש תויביסה 4-ל תמאה תואלבט
NS[3]
םיבצמה לש הקיגולה
:םיאבה
וקילדיש םיבצמה
לש תמאה תואלבט
NS3 טיבה תא
.אבה בצמה לש םיטיבה
ןכלו םיבצמ 10 םנשי
NS[2]
4-ב םתוא ראתל רשפא
תלבט טיב לכל .םיטיב
.ולשמ תמא
NS3 NS2 NS1 NS0
88,,99 4,5,6 2,3,6 1,3,5
,7 ,7 ,7,9
בצמה רפסמ
Op==2 in
NS[1]
יחכונה בצמה
Jump (j)
1 0,1,2
1,2,3 1,2,6
,6
,6
םיבצמה תמרגאיד ךותמ
NS[0]
sw ,2 בצמ
S0
sw=2b lw ,2 בצמ S2
hex
lw=23 S2
hex
S6
S1
FIGURE D.3.5 The four truth tables for the four next-state output bits (NS[3–0]). The next-state outputs depend on the value of Op[5-0], which is the
opcode field, and the current state, given by S[3–0]. The entries with X are don’t-care terms. Each entry with a don’t-care term corresponds to two
entries, one with that input at 0 and one with that input at 1. Thus an entry with n don’t-care terms actually corresponds to 2n truth table entries.
94
Copyright © 2014 Elsevier Inc. All rights reserved.

|     |                 |     |     |     |        |  4     |        |      |
| --- | --------------- | --- | --- | --- | ------ | ------ | ------ | ---- |
|     |                 |     |     |     | םיטיבה |        | ןיב    | רשקה |
| NS  | 4 bits decoding |     |     |     |        |        |        |      |
|     |                 |     |     |     |        | אבה    |   בצמה |   לש |
|     | NS3             | NS2 | NS1 | NS0 |        |        |        |      |
|     |                 |     |     |     |        | .      |        |      |
| 0   | 0               | 0   | 0   | 0   |        | יחכונה |        | בצמל |
| 1   | 0               | 0   | 0   | 1   |        |        |        |      |
| 2   | 0               | 0   | 1   | 0   |        |        |        |      |
NS3 : 8,9
| 3   | 0   | 0   | 1   | 1   |               |     |     |     |
| --- | --- | --- | --- | --- | ------------- | --- | --- | --- |
| 4   | 0   | 1   | 0   | 0   | NS2:  4,5,6,7 |     |     |     |
| 5   | 0   | 1   | 0   | 1   |               |     |     |     |
NS1: 2,3,6,7
| 6   | 0   | 1   | 1   | 0   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
NS0: 1,3,5,7,9
| 7   | 0   | 1   | 1   | 1   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 8   | 1   | 0   | 0   | 0   |     |     |     |     |
| 9   | 1   | 0   | 0   | 1   |     |     |     |     |
םדוקה ףקשבש לאמש דצב בותיכה תא ריבסהל דעונ הז ףקש

תואחסונב תמכוסמ תואלבטה ירוחאמ הקיגולה
תואבה
רמולכ .המשהל איה הנווכה ,= ,הווש ןמיסה עיפומש םוקמ לכב
⇐ :תויהל ךירצ ןוכנ רתוי ןמיס .שדחה בצמה תא ררוג ןימי ףגא
...תיקלח המישר יהוז

הרקבה תותוא יבגל וישכע
16 ךותמ( םיבצמה 10 לש נופכ הרקבה תותוא 16 לש תמאה תלבט
’
םליעפה הרקבה תותוא 3 בצמב ונא רשאכ המגודל .)םיירשפא םייטרואית
3 בצמ *-ב םג רזעיהל ןתינ .$ ףקש האר MemRead -ו IorD ויהי
המגוד
FIGURE D.3.6 The truth table for the 16 datapath control outputs, which depend only on the state inputs. The
values are determined from Figure D.3.4. Although there are 16 possible values for the 4-bit state field, only ten of
these are used and are shown here. The ten possible values are shown at the top; each column shows the setting
of the datapath control outputs for the state input value that appears at the top of the column. For example, when
the state inputs are 0011 (state 3), the active datapath control outputs are IorD or MemRead.
97
Copyright © 2014 Elsevier Inc. All rights reserved.

S[3:0] -ב תולתב הרקבה תותוא 16-ל תמאה תואלבט
PCWrite:
State 0
State 9
State 8
רובע תמא תואלבט 16
4 >-- הרקבה תותוא 16
לש היצקנופכ ,םיטיב
.םיבצמה 10
תואלבט 16
FIGURE D.3.4 The truth tables are shown for the 16 datapath control signals that depend only on the current-state input bits, which are shown for
each table. Each truth table row corresponds to 64 entries: one for each possible value of the six Op bits. Notice that some of the outputs are active under
nearly the same circumstances. For example, in the case of PCWriteCond, PCSource0, and ALUOp0, these signals are active only in state 8 (see b, i, and
k). These three signals could be replaced by one signal. There are other opportunities for reducing the logic needed to implement the control function by
taking advantage of further similarities in the truth tables.
98
Copyright © 2014 Elsevier Inc. All rights reserved.

:לבקנו םיפקש 2 ינפלמ הלבטה תא בבוסנ
T1
הרקבה יווק 16
םיבצמה תרשע
תורושל ןאכ וכפה םיפקש 2 ינפל תודומעה

11 בבצצממבב ייננאא םםאא
Op יכרעבו S יחכונה בצמב תולתכ NS אבה בצמה $ הלבטמ רזגנ
זזאא OOpp==00--ההוו
NNSS==66 בבצצממלל ךךללווהה ייננאא
** ףףקקשש ההאארר ––
:תבותכ חקינ המגודל
1000110001
11 6 9 8 2 2
6 4 תודשל דירפנ
+
(Op + בצמ(
םישרתב 0001 בצמה
10
הרושל םיאתמ D.3.7
םיבצמ
םשמ קיתענ .2-ה
.םיטיבה 16 תא
םיטיבה 6 ,ףסונב
101011
:ןימימ 2 הדומע םה
0010 רמולכ
תא ןתיי הז (NS)
תלעב תיפוסה הלימה
.טיב 20
FIGURE D.3.8 This table contains the lower 4 bits of the control word (the NS outputs), which depend on both the state inputs, S[3–0], and the
תבותכמ :םוכיסל
opcode, Op[5–0], which correspond to the instruction opcode. These values can be determined from Figure D.3.5. The opcode name is shown
ץלחנ םיטיב 10 תלעב
under the encoding in the heading. The four bits of the control word whose address is given by the current-state bits and Op bits are shown in
תלעב )הלימ( בצמ
each entry. For example, when the state input bits are 0000, the output is always 0001, independent of the other inputs; when the state is 2, the
םיטיב 20
next state is don’t care for three of the inputs, 3 for lw, and 5 for sw. Together with the entries in Figure D.3.7, this table specifies the contents of
the control unit ROM. For example, the word at address 1000110001 is obtained by finding the upper 16 bits in the table in Figure D.3.7 using
only the state input bits (0001) and concatenating the lower four bits found by using the entire address (0001 to find the row and 100011 to find
the column). The entry from Figure D.3.7 yields 0000000000011000, while the appropriate entry in the table immediately above is 0010. Thus
the control word at address 1000110001 is 00000000000110000010. The column labeled “Any other value” applies only when the Op bits do not
match one of the specified opcodes.
100
Copyright © 2014 Elsevier Inc. All rights reserved.

Programmed Logic Array
תנתינ אבה ףקשב
10 תלעב תבותכ
םיטיב הרקמ( תחא המגוד
רתוי ןפואב )יטרפ
.שגדומ
AND ירעש - ןוילעה קלחב
OR ירעש - ןותחתה קלחב
16 20
FIGURE D.3.9 This PLA implements the control function logic for the multicycle implementation. The inputs to the control
appear on the left and the outputs on the right. The top half of the figure is the AND plane that computes all the
minterms. The minterms are carried to the OR plane on the vertical lines. Each colored dot corresponds to a signal that
makes up the minterm carried on that line. The sum terms are computed from these minterms, with each gray dot
representing the presence of the intersecting minterm in that sum term. Each output consists of a single sum term.
101
Copyright © 2014 Elsevier Inc. All rights reserved.

המגוד
1 2 3 4 5 6 7 8 9 A B C D E F
םיווקה תומש
םייטנוולרה םייכנאה
AND
PCWrite= “1” + “A"
"1" = not(S0)*not(S1)*not(S2)*not(S3)
"A"=S3*not(S2)*not(S1)*S0
State9-ו State0-ב ליעפ אוה PCWrite ורכזת
State0=0000
State9=1001
D.3.4 -ב תמא תלבט ואר
OR

תמאה תואלבט תא תונבל היינשה ךרדה
Copyright © 2014 Elsevier Inc. All rights reserved.

The Multi-Cycle
Fetch
state diagram:
0
Decode
1
lw+sw j
beq
Jump
AdrCmp
R-type Branch 9
2
8
lw sw
ALU
6
Load
Store
3
5
WB WBR
4 7
*-ל המוד הז םישרת

| State name |   RTL description |     | Relevant control signals          |     |     |
| ---------- | ----------------- | --- | --------------------------------- | --- | --- |
| Fetch      | IR= M[PC]         |     | IorD=0,   MemRead=1,   IRWrite=1  |     |     |
|            |                   |     |                                   |     |     |
0
|     | PC=PC+4 |     | ALUSrcA=0,   ALUSrcB=01,     |     |     |
| --- | ------- | --- | ---------------------------- | --- | --- |
ALUop=00 (add),   PCSrc=00,
PCWrite=1

| Decode  | A = GPR[Rs]  |     | (no signals are needed)      |     |     |
| ------- | ------------ | --- | ---------------------------- | --- | --- |
|         | B = GPR[Rt]  |     |                              |     |     |
| 1       |              |     |                              |     |     |
|         | ALUOut =     |     | ALUSrcA=0,   ALUSrcB=11,     |     |     |
           PC+( sext(imm)<<2 )   ALUop=00 (add)             (for branch)
AdrCmp  ALUOut =  A+( sext(imm) )  ALUSrcA=1,   ALUSrcB=10,
|      |                   |     | ALUop=00 (add)             (for lw & sw)          |     |     |
| ---- | ----------------- | --- | ------------------------------------------------- | --- | --- |
| 2    |                   |     |                                                   |     |     |
|      | (B = GPR[Rt])     |     |                                          (for sw) |     |     |
| ALU  | ALUOut = A op B   |     | ALUSrcA=1,   ALUSrcB=00,                          |     |     |
| 6    |                   |     | ALUop=10 (funct bits determines op)               |     |     |

|         |                                  |     |                              |     |     |
| ------- | -------------------------------- | --- | ---------------------------- | --- | --- |
| Branch  | ALUout = A - B                   |     | ALUSrcA=1,   ALUSrcB=00,     |     |     |
|         | if (zero = = “1”)    PC=ALUOut   |     | ALUop=01(sub),               |     |     |
8  else       do nothing PCSrc=01,   PCWriteCond=1

| Jump  | PC=   |     | PCSrc=10,   PCWrite=1  |     |     |
| ----- | ----- | --- | ---------------------- | --- | --- |
9      PC[31:28]||(IR[25:0]<<2)

Load  MDR = M[ALUOut]   IorD=1,   MemRead=1
| 3   |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- |
Store  M[ALUOut] = B  IorD=1,   MemWrite=1
| 5    |                   |     |                                                   |     |     |
| ---- | ----------------- | --- | ------------------------------------------------- | --- | --- |
| WBR  | GPR[Rd] = ALUOut  |     | RegDest=1,   MemtoReg=0                           |     |     |
| 7    |                   |     | RegWrite=1                                        |     |     |

| WB  | GPR[Rt] = MDR  |     | RegDest=0,   MemtoReg=1                           |     |     |
| --- | -------------- | --- | ------------------------------------------------- | --- | --- |
| 4   |                |     | RegWrite=1                                        |     |     |
05/14/20

The Control Finite State Machine:
control signals
current state
PCWrite
State reg PCWriteCond
םיטיב 4
IorD
MemRead
MemWrite
next state Outputs IRWrite
next state
MemtoReg
decoder
calculation
PCSource
Opcode= IR[31:26]
ALUOp
zero, neg, etc.
ALUSrcB
םיטיב 6 ALUSrcA
RegWrite
ck RegDst
For 10 states coded 0-9, we need 4 bits, i.e., [S3,S2,S1,S0]

The control signals decoder
We just implement the table of 2 slides before:
      Let’s look at ALUSrcA: it is “0” in states 0 and 1 and it is “1” in states 2, 6 and 8. In all other states we don’t care.
     let’s look at PCWrite: it is “1” in states 0 and 9. In all other states it must be “0”.
And so, we’ll fill the table below and build the decoder.
|     | state |       |         | Control signals |             |
| --- | ----- | ----- | ------- | --------------- | ----------- |
|     | S3 S2 | S1 S0 | ALUSrcA | PCWrite         | PCWriteCond |
fetch
|     | 0 0 | 0 0 |     |     |     |
| --- | --- | --- | --- | --- | --- |
decode
|     | 0 0 | 0 1 |     |     |     |
| --- | --- | --- | --- | --- | --- |
AdrCmp
|     |  0 0 | 1 0 |     |     |     |
| --- | ---- | --- | --- | --- | --- |
load
|     | 0 0 | 1 1 |     |     |     |
| --- | --- | --- | --- | --- | --- |
WB
|       | 0 1 | 0 0 |     |     |     |
| ----- | --- | --- | --- | --- | --- |
| store | 0 1 | 0 1 |     |     |     |
ALU
|     | 0 1 | 1 0 |     |     |     |
| --- | --- | --- | --- | --- | --- |
| WBR | 0 1 | 1 1 |     |     |     |
branch
|     | 1 0 | 0 0 |     |     |     |
| --- | --- | --- | --- | --- | --- |
jump
|     | 1 0 | 0 1 |     |     |     |
| --- | --- | --- | --- | --- | --- |
All other
combinations

The control signals decoder
We just implement the table of slide 54:
      Let’s look at ALUSrcA: it is “0” in states 0 and 1 and it is “1” in states 2, 6 and 8. In all other states we don’t care.
     let’s look at PCWrite: it is “1” in states 0 and 9. In all other states it must be “0”.
And so, we’ll fill the table below and build the decoder.
|     | state |       |         | Control signals |             |
| --- | ----- | ----- | ------- | --------------- | ----------- |
|     | S3 S2 | S1 S0 | ALUSrcA | PCWrite         | PCWriteCond |
fetch
|     | 0 0 | 0 0 |     | 1   |     |
| --- | --- | --- | --- | --- | --- |
decode
|     | 0 0 | 0 1 |     | 0   |     |
| --- | --- | --- | --- | --- | --- |
AdrCmp
|     |  0 0 | 1 0 |     | 0   |     |
| --- | ---- | --- | --- | --- | --- |
load
|       | 0 0 | 1 1 |     | 0   |     |
| ----- | --- | --- | --- | --- | --- |
| WB    |     |     |     | 0   |     |
|       | 0 1 | 0 0 |     |     |     |
| store | 0 1 | 0 1 |     | 0   |     |
ALU
|     | 0 1 | 1 0 |     |     |     |
| --- | --- | --- | --- | --- | --- |
0
| WBR    | 0 1 | 1 1 |     | 0   |     |
| ------ | --- | --- | --- | --- | --- |
| branch |     |     |     | 0   |     |
|        | 1 0 | 0 0 |     |     |     |
jump
|     | 1 0        | 0 1 |     | 1   |     |
| --- | ---------- | --- | --- | --- | --- |
|     | All other  |     |     | 0   |     |
combinations

The control signals decoder
We just implement the table of slide 54:
      Let’s look at ALUSrcA: it is “0” in states 0 and 1 and it is “1” in states 2, 6 and 8. In all other states we don’t care.
     let’s look at PCWrite: it is “1” in states 0 and 9. In all other states it must be “0”.
And so, we’ll fill the table below and build the decoder.
|     | state |       |         | Control signals |             |
| --- | ----- | ----- | ------- | --------------- | ----------- |
|     | S3 S2 | S1 S0 | ALUSrcA | PCWrite         | PCWriteCond |
fetch
|     | 0 0 | 0 0 |     | 1   | 0   |
| --- | --- | --- | --- | --- | --- |
decode
|     | 0 0 | 0 1 |     | 0   | 0   |
| --- | --- | --- | --- | --- | --- |
AdrCmp
|     |  0 0 | 1 0 |     | 0   | 0   |
| --- | ---- | --- | --- | --- | --- |
load
|       | 0 0 | 1 1 |     | 0   | 0   |
| ----- | --- | --- | --- | --- | --- |
| WB    |     |     |     | 0   | 0   |
|       | 0 1 | 0 0 |     |     |     |
| store | 0 1 | 0 1 |     | 0   | 0   |
ALU
|        | 0 1 | 1 0 |     |     |     |
| ------ | --- | --- | --- | --- | --- |
|        |     |     |     | 0   | 0   |
| WBR    | 0 1 | 1 1 |     | 0   | 0   |
| branch |     |     |     | 0   |     |
|        | 1 0 | 0 0 |     |     | 1   |
jump
|     | 1 0        | 0 1 |     | 1   | 0   |
| --- | ---------- | --- | --- | --- | --- |
|     | All other  |     |     | 0   | 0   |
combinations

| T1  | The control signals decoder |     |     |     |     |
| --- | --------------------------- | --- | --- | --- | --- |
We just implement the table of slide 54:
      Let’s look at ALUSrcA: it is “0” in states 0 and 1 and it is “1” in states 2, 6 and 8. In all other states we don’t care.
     let’s look at PCWrite: it is “1” in states 0 and 9. In all other states it must be “0”.
And so, we’ll fill the table below and build the decoder.
|     | state |       |         | Control signals |             |
| --- | ----- | ----- | ------- | --------------- | ----------- |
|     | S3 S2 | S1 S0 | ALUSrcA | PCWrite         | PCWriteCond |
fetch
|     | 0 0 | 0 0 | 0   | 1   | 0   |
| --- | --- | --- | --- | --- | --- |
decode
|     | 0 0 | 0 1 | 0   | 0   | 0   |
| --- | --- | --- | --- | --- | --- |
AdrCmp
|     |  0 0 | 1 0 | 1   | 0   | 0   |
| --- | ---- | --- | --- | --- | --- |
load
|       | 0 0 | 1 1 | X   | 0   | 0   |
| ----- | --- | --- | --- | --- | --- |
| WB    |     |     |     | 0   | 0   |
|       | 0 1 | 0 0 | X   |     |     |
| store | 0 1 | 0 1 | X   | 0   | 0   |
ALU
|        | 0 1 | 1 0 |     |     |     |
| ------ | --- | --- | --- | --- | --- |
|        |     |     | 1   | 0   | 0   |
| WBR    | 0 1 | 1 1 | X   | 0   | 0   |
| branch |     |     | 1   | 0   |     |
|        | 1 0 | 0 0 |     |     | 1   |
jump :ןוסחאה חפנ
|     | 1 0 | 0 1 | X   | 1   | 0   |
| --- | --- | --- | --- | --- | --- |
24X16 = 256bits
|     | All other  |     | X   | 0   | 0   |
| --- | ---------- | --- | --- | --- | --- |
combinations

T2
State Machine “next state calc.” logic
opcode
|     |      |      |           |      |      | current state |       |     |     | next state |     |     |     |     |
| --- | ---- | ---- | --------- | ---- | ---- | ------------- | ----- | --- | --- | ---------- | --- | --- | --- | --- |
|     | IR31 | IR30 | IR29 IR28 | IR27 | IR26 | S3            | S2 S1 | S0  | S3  | S2 S1      | S0  |     |     |     |
Fetch
      0
|     | X   | X   | X X | X   | X   | 0   | 0 0 | 0   | 0   | 0 0 | 1   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Decode
| R-type | 0   | 0   | 0 0 | 0   | 0   | 0   | 0 0 | 1   | 0   | 1 1 | 0   |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
         1
j
|     |     |     |     |     |     |     |     |     |     |     |     |         |    lw+sw | beq |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | -------- | --- |
|     | 1   | X   | X X | X   | X   | 0   | 0 0 | 1   | 0   | 0 1 | 0   | AdrCmp  |          |     |
lw+sw
R-type
        2 Jump
Branch
   9
| lw  | X   | X   | 0 X | X   | X   | 0   | 0 1 | 0   | 0   | 0 1 | 1   |     | sw  |       8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- |
|     |     |     |     |     |     |     |     |     |     |     |     | lw  | ALU |         |
    6
Load
| sw  |     |     |     |     |     | 0   | 0 1 | 0   | 0   | 1 0 | 1   |     |       |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- |
|     | X   | X   | 1 X | X   | X   |     |     |     |     |     |     |     | Store |     |
        3
5

WBR
WB
    7
      4
R-type=000000, lw=100011, sw=101011, beq=000100, bne=000101, lui=001111, j=0000010, jal=000011,
addi=001000
210X4 = 4096bits :ןוסחאה חפנ

Multi-Cycle Microprogram Control
Implementing the Next-State Function
with a Sequencer
Copyright © 2014 Elsevier Inc. All rights reserved.

עבקנ ךיא -
?אבה בצמה
ונחנא ךיא(
”םילייטמ“
םישרתה ינפ-לע
)? *
AddrCtl תרזעב
הנומהו Op -ה
ןותחתה קלחה(
.)םישרתה לש
sequencer
הטיש הארנו
לש שומימל הליעי
.# םישרתה
FIGURE D.4.1 The control unit using an explicit counter to compute the next state. In this control unit, the next state is computed
using a counter (at least in some states). By comparison, Figure D.3.2 encodes the next state in the control logic for every state. In
this control unit, the signals labeled AddrCtl control how the next state is determined.
113
Copyright © 2014 Elsevier Inc. All rights reserved.

Next state
reset
FIGURE D.4.2 This is the address select logic for the control unit of Figure D.4.1.
114
Copyright © 2014 Elsevier Inc. All rights reserved.

6 3
9 5
8
AdrCmp - 2 בצממ לוציפ
2
2
Decode -1 בצממ לוציפ
1 תפסוהמ ולבקתי םיבצמה ראש לכ
וליבוי וא הנומה תועצמאב בצמל
ףקשה ואר – 0 בצמ ,הלחתהל בוש
.אבה
FIGURE D.4.3 The dispatch ROMs each have 26 5 64 entries that are 4 bits wide, since that is the number of bits in the state encoding. This
figure only shows the entries in the ROM that are of interest for this subset. The first column in each table indicates the value of Op, which is the
address used to access the dispatch ROM. The second column shows the symbolic name of the opcode. The third column indicates the value at
that address in the ROM.
115
Copyright © 2014 Elsevier Inc. All rights reserved.

לע תטלוש וז הדומע
םיבצמ 10 כהס םיטיב 2 ,רסקפיטלומה
1 ל ךלוה דימת 0
7 ל ךלוה דימת 6
if states== 4,5,7,8,9 then next state is 0
If state ==0 or state ==6 increment state by 1
FIGURE D.4.4 The values of the address-control lines are set in the control word that corresponds to each state.
116
Copyright © 2014 Elsevier Inc. All rights reserved.

.םיטיב 180 כ"הס ,)םיטיב( תודומע 16+2 לע )תורוש( םילימ רשע :הנומ םע שומימב ”לודגה“ ROM -ה ןכות ,התע
:)טיב 64( הסינכב םיבצמ 6 לע טיב 4 לש )אצומ=( בחורב א"כ ,dispatchers -ה 2 ,ףסונב
26 X 4 = 64 X 4 =256
2 dispatchers: 2 X 256 = 512
Total: 180 + 512 = 692 bit
בורו רחאמ רתוי םצמצל וליפא רשפא .)הנושארה ROM ה תסרג 4.3Kb תמועל( טיב 692 כ"הסבו ,טיב512 = 2 לופכ )64x4(
.sparse םה dispatchers-ה
10X18=180bit
pc source1
See table D.3.3 pcwrite
.)20 םוקמב( אצומב םיווק 18 ונל שי הזה לדומב
FIGURE D.4.5 The contents of the control memory for an implementation using an explicit counter. The first column shows the state, while the second shows
the datapath control bits, and the last column shows the address-control bits in each control word. Bits 17–2 are identical to those in Figure D.3.7.
T1 T2 :)SQUENCER אלל( ירוקמה לדומה יפ-לע
From &
T1: 24 X 16 = 256 – הרקבה תותוא, T2: 210 X 4 = 4096, total: 4.3Kb -םיבצמ11ה7

180bit
512bit
FIGURE D.4.6 The control unit as a microcode. The use of the word “micro” serves to distinguish between the
program counter in the datapath and the microprogram counter, and between the microcode memory and the
instruction memory.
118
Copyright © 2014 Elsevier Inc. All rights reserved.

Motorola 68000
http://www.easy68k.c
om/paulrsm/doc/dpbm
68k2.htm

https://www.righto.com/2023/04/8086-microcode-string-operations. html

Credit: Harris & Harris
DD&CA

End of Appendix D PPTs

Differences Between PLA and ROM
אוהש ךכב רתוי שימג אוה PLA .טלפ תרושל תורישי הפוממ )תבותכ( הסינכ תרוש לכ הבש הלודג הלבט ומכ אוה ROM
רובע רתוי ליעי תויהל לוכיש המ ,)OR יחנומ( טלפה תא רוציל ידכ םתוא בלשל דציכו )AND יחנומ( םיאנת רידגהל רשפאמ
.תובכרומ תויגול תויצקנופ
https://www.differencebetween.com/difference-between-pla-and-vs-rom/
https://www.quora.com/What-are-the-advantages-of-PLA-over-ROM?share=1

Thoughts on Control &
Microprogramming

The Control Store: Some Questions
 What control signals can be stored in the control store?
Those independent on data
vs.
 What control signals have to be generated in hardwired
logic?
 i.e., what signal cannot be available without processing in the datapath?
Those dependent on data
 Remember the MIPS datapath
 One PCSrc signal depends on processing that happens in the datapath
(bcond logic)
126

Variable-Latency Memory
 The ready signal (R) enables memory read/write to execute
correctly
 Example: transition from state 33 to state 35 is controlled by the R bit
asserted by memory when memory data is available
 Could we have done this in a single-cycle microarchitecture?
128

Aside: Memory Mapped I/O
 Address control logic determines whether the specified
address of LDx and STx are to memory or I/O devices
 Correspondingly enables memory or I/O devices and sets up
muxes
 This is another instance where the final control signals (e.g.,
MEM.EN or INMUX/2) cannot be stored in the control store
 These signals are dependent on address
129

The Microsequencer: Advanced Questions
 What happens if the machine is interrupted?
 What if an instruction generates an exception?
 How can you implement a complex instruction using this
control structure?
 Think REP MOVS
130

The Power of Abstraction
 The concept of a control store of microinstructions enables
the hardware designer with a new abstraction:
microprogramming
 The designer can translate any desired operation to a
sequence of microinstructions
 All the designer needs to provide is
 The sequence of microinstructions needed to implement the desired
operation
 The ability for the control logic to correctly sequence through the
microinstructions
 Any additional datapath control signals needed (no need if the operation can
be “translated” into existing control signals)
131

Some good examples for Microprogramming
 Implement REP MOVS in a microarchitecture using
microprogramming
 Guidelines: What changes, if any, do you make to the
 state machine?
 datapath?
 control store?
 microsequencer?
 Another good example: Implement unaligned word memory
access using microprogramming
132

Advantages of Microprogrammed Control
 Allows a very simple design to do powerful computation by
controlling the datapath (using a sequencer)
 High-level ISA translated into microcode (sequence of microinstructions)
 Microcode (ucode) enables a minimal datapath to emulate an ISA
 Microinstructions can be thought of as a user-invisible ISA (micro ISA)
 Enables easy extensibility of the ISA
 Can support a new instruction by changing the microcode
 Can support complex instructions as a sequence of simple microinstructions
 If I can sequence an arbitrary instruction then I can sequence
an arbitrary “program” as a microprogram sequence
 will need some new state (e.g. loop counters) in the microcode for sequencing more elaborate
programs
133

Update of Machine Behavior
 The ability to update/patch microcode in the field (after a
processor is shipped) enables
 Ability to add new instructions without changing the processor!
 Ability to “fix” buggy hardware implementations
 Examples
 IBM 370 Model 145: microcode stored in main memory, can be updated after a
reboot
 IBM System z: Similar to 370/145.
 Heller and Farrell, “Millicode in an IBM zSeries processor,” IBM JR&D, May/Jul 2004.
 B1700 microcode can be updated while the processor is running
 User-microprogrammable machine!
134

Z80 דבעמה :הירוטסיה לש עגר

The Z80 is an 8-bit microprocessor designed by Zilog,
first released in 1976, which became widely used in early
personal computers and gaming systems. It was known
for its compatibility with the Intel 8080 and its enhanced
instruction set, making it a popular choice for various
applications until its discontinuation in 2024.

ןיילפייפ-ל לקייס-יטלוממ רבעמה תפוקתב דבעמ
Z80 has "fetch/execute overlapping", which means that
it's possible to get (fetch) next instruction from memory
while the first instruction are executed. This system are
also used in the Intel 8080, and other processors from
that time. Another thing that are typical from that time is
that those processors are CISC-processors, and that
they have variable instructions length. The Z80 CPU
instructions length can be from one to four bytes long. To
increase the Z80 CPU speed most instructions are only
one byte long. 252 instructions are one byte, the rest are
2, 3 or 4 bytes long.

|        |       |           |     |            |         |
| ------ | ----- | --------- | --- | ---------- | ------- |
| םולצתל |       | רושיקה    | לע  | ץוחלל      | םינמזומ |
|        |       |           |     |            |         |
|        | ההובג | היצולוזרב |     | פוקסורקיממ |         |
 https://siliconpr0n.org/map/zilog/z0840006psc-z80cpu/bercovici_mz/#x=16704&y=26896&z=4

!וז תגצמ ןאכ דע