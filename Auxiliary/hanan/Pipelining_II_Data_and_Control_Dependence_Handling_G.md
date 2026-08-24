361.1.4201
Computer Architecture
Pipelining II:
Data Dependence Handling
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu, DD&CA By
Harris and Harris, and CO&D by H&P
Last edition: 13/5/2021, 19/5/2022, 27/4/2023, 6/6/2024, 27/5/2026

|              | RISC-V ! |     |       |     |
| ------------ | -------- | --- | ----- | --- |
| עובשה 16 ןב  |          | חמש | תדלוה | םוי |
CPU2026B, 5/2026

Recap of Last Lecture
 Wrap Up Microprogramming
 Horizontal vs. Vertical Microcode
 Nanocode vs. Millicode
 Pipelining םיאבה םיאשונה
 Basic Idea and Characteristics of An Ideal Pipeline
 Pipelined Datapath and Control
 Issues in Pipeline Design
 Resource Contention

3

z386: An Open-Source 80386 Built Around Original
Microcode
https://nand2mario.github.io/posts/2026/z386/

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence
Handling, State Maintenance and Recovery, …
 Branch Prediction
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, …
5

Today
● Dependences and Their Types
● Control vs. data (flow, anti, output)
● Five (Six*) Fundamental Ways of Handling Data
Dependences
● Dependence Detection
● Interlocking
● H/W: Scoreboarding vs. Combinational

Readings for Next Few Lectures (I)
 P&H CO&D Chapter 4.5-4.11 הבוח תאירק
תצלמומ האירק
 H&H Chapter 7 (all)
 Smith and Sohi, “The Microarchitecture of Superscalar
Processors,” Proceedings of the IEEE, 1995
 More advanced pipelining
 Interrupt and exception handling
 Out-of-order and superscalar execution concepts םיאבה םירועישל
ftp://ftp.cs.wisc.edu/sohi/papers/1995/ieee-proc.superscalar.pdf
 McFarling, “Combining Branch Predictors,” DEC WRL Technical
Report, 1993.
https://www.hpl.hp.com/techreports/Compaq-DEC/WRL-TN-36.pdf
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro 1999.
https://www.cis.upenn.edu/~milom/cis501-Fall09/papers/
Alpha21264.pdf
7

Readings for Next Few Lectures (II)
:OoO םיאבה םירועישל
 Smith and Plezskun, “Implementing Precise Interrupts
in Pipelined Processors,” IEEE Trans on Computers 1988
(earlier version in ISCA 1985).
https://ieeexplore.ieee.org/document/4607
8

Remember: An Ideal Pipeline - ןוזחה
 Goal: Increase throughput with little increase in cost
(hardware cost, in case of instruction processing)
תולע תפסות אלל םיבושיחה תומכ תלדגה
 Repetition of identical operations תועובק תוארוה לע תויתרזח
 The same operation is repeated on a large number of different
inputs (e.g., all laundry loads go through the same steps)
 Repetition of independent operations תונוש תולועפ עוציב תלוכי
 No dependencies between repeated operations
תולועפה ןיב תולת יא
 Uniformly partitionable sub-operations תודיחא תויהשה
 Processing is evenly divided into uniform-latency sub-
operations (that do not share resources)
 Fitting examples: automobile assembly line, doing laundry
 What about the instruction processing “cycle”?
9

Instruction Pipeline: Not An Ideal Pipeline
 Identical operations ... NOT! תואיצמה
 different instructions  not all need the same stages
Forcing different instructions to go through the same pipe stages
 external fragmentation (some pipe stages idle for some
instructions)
 Uniform sub-operations ... NOT!
 different pipeline stages  not the same latency
Need to force each stage to be controlled by the same clock
 internal fragmentation (some pipe stages are too fast but all take
the same clock cycle time)
 Independent operations ... NOT!
 instructions are not independent of each other
Need to detect and resolve inter-instruction dependencies to
ensure the pipeline provides correct results
 pipeline stalls (pipeline is not always moving)
10

Review: Pipelining Basic Idea
היצמינא
CLK
PCWrite
|     |     |     |          |              | Branch     |     |     |     | PCEn |     |
| --- | --- | --- | -------- | ------------ | ---------- | --- | --- | --- | ---- | --- |
|     |     |     |          | IorD Control | PCSrc      |     |     |     |      |     |
|     |     |     | MemWrite | Unit         | ALUControl |     |     |     |      |     |
2:0
|     |     |     |     | IRWrite | ALUSrcB |     |     |     |     |     |
| --- | --- | --- | --- | ------- | ------- | --- | --- | --- | --- | --- |
1:0
ALUSrcA
31:26 Op
RegWrite
5:0 Funct
|     |     |     |     | RegDst | MemtoReg |     |        |     |     |     |
| --- | --- | --- | --- | ------ | -------- | --- | ------ | --- | --- | --- |
|     | CLK |     |     |        | CLK      | CLK |        |     |     |     |
| CLK |     |     | CLK |        |          |     |        |     |     |     |
|     |     |     |     |        |          |     | 0 SrcA |     |     |     |
CLK
|        |       | WE  |       |       | WE3    | A 31:28 |     | Zero      |        |     |
| ------ | ----- | --- | ----- | ----- | ------ | ------- | --- | --------- | ------ | --- |
| PC' PC |       |     | Instr | 25:21 | A1 RD1 |         | 1   |           |        | 00  |
|        | 0 Adr | RD  |       |       |        | B       |     | ULA       |        |     |
|        |       | A   |       | 20:16 | A2 RD2 |         | 00  | ALUResult | ALUOut |     |
| EN     |       |     | EN    |       |        |         |     |           |        | 01  |
1
|     | Instr / Data |     |     |     |     |     | 4 01 SrcB |     |     | 10  |
| --- | ------------ | --- | --- | --- | --- | --- | --------- | --- | --- | --- |
20:16 0
|     |     | Memory |     |     | A3  |     | 10  |     |     |     |
| --- | --- | ------ | --- | --- | --- | --- | --- | --- | --- | --- |
15:11
|     |     |     | CLK | 1   | Register |     |     |     | PCJump |     |
| --- | --- | --- | --- | --- | -------- | --- | --- | --- | ------ | --- |
|     |     | WD  |     |     |          |     | 11  |     |        |     |
0 File
|     |     |     | Data |     | WD3 |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
1
<<2
<<2 27:0
ImmExt
15:0
Sign Extend
25:0 (Addr)
11

Review: Pipelined Datapath & Control
|     |     |     |     |           | CLK |           |     |     | CLK       |     |     | CLK       |     |
| --- | --- | --- | --- | --------- | --- | --------- | --- | --- | --------- | --- | --- | --------- | --- |
|     |     |     |     | RegWriteD |     | RegWriteE |     |     | RegWriteM |     |     | RegWriteW |     |
Control
|     |     |     |     | MemtoRegD |     | MemtoRegE |     |     | MemtoRegM |     |     | MemtoRegW |     |
| --- | --- | --- | --- | --------- | --- | --------- | --- | --- | --------- | --- | --- | --------- | --- |
Unit
|     |     |     |     |     |     | MemWriteE |     |     | MemWriteM |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --------- | --- | --- | --------- | --- | --- | --- | --- |
MemWriteD
|     |     |       |     | BranchD     |     | BranchE     |     |     | BranchM |        |     |     |     |
| --- | --- | ----- | --- | ----------- | --- | ----------- | --- | --- | ------- | ------ | --- | --- | --- |
|     |     | 31:26 |     |             |     |             |     |     |         | PCSrcM |     |     |     |
|     |     | Op    |     | ALUControlD |     | ALUControlE |     |     |         |        |     |     |     |
2:0
5:0 Funct
|     |     |     |     | ALUSrcD |     | ALUSrcE |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ------- | --- | ------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     | RegDstD |     | RegDstE |     |     |     |     |     |     |     |
ALUOutW
|     | CLK | CLK |     |     |     |     |     |     |     | CLK |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
CLK
|         |        |          | WE3 |     |     |     |       |     | ZeroM   |     | WE  |           |     |
| ------- | ------ | -------- | --- | --- | --- | --- | ----- | --- | ------- | --- | --- | --------- | --- |
| 0       |        | 25:21 A1 |     | RD1 |     |     | SrcAE |     |         |     |     |           |     |
| PC' PCF | InstrD |          |     |     |     |     |       |     |         |     |     |           | 0   |
| A RD    |        |          |     |     |     |     |       | ULA |         |     |     |           |     |
| 1       |        |          |     |     |     |     |       |     | ALUOutM |     |     | ReadDataW |     |
|         |        |          |     |     |     |     |       |     |         | A   | RD  |           | 1   |
Instruction
|     |     | 20:16 A2 |     | RD2 |     |     | 0 SrcBE |     |     |     | Data |     |     |
| --- | --- | -------- | --- | --- | --- | --- | ------- | --- | --- | --- | ---- | --- | --- |
Memory
|     |     | A3  |          |     |     |     | 1          |     |            |     | Memory |     |     |
| --- | --- | --- | -------- | --- | --- | --- | ---------- | --- | ---------- | --- | ------ | --- | --- |
|     |     |     | Register |     |     |     |            |     | WriteDataM |     |        |     |     |
|     |     | WD3 |          |     |     |     | WriteDataE |     |            | WD  |        |     |     |
File
RtE
|     |     | 20:16 |     |     |     | 0   | WriteRegE |     | WriteRegM |     |     | WriteRegW |     |
| --- | --- | ----- | --- | --- | --- | --- | --------- | --- | --------- | --- | --- | --------- | --- |
|     |     |       |     |     |     |     |           | 4:0 |           | 4:0 |     |           | 4:0 |
RdE
|     |     | 15:11 |             |     |     | 1        |     |     |     |     |     |     |     |
| --- | --- | ----- | ----------- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
| +   |     |       |             |     |     |          | <<2 |     |     |     |     |     |     |
|     |     | 15:0  | Sign Extend |     |     | SignImmE |     |     |     |     |     |     |     |
PCBranchM
4
+
| PCPlus4F |     | PCPlus4D |     |     |     | PCPlus4E |     |     |     |     |     |     |     |
| -------- | --- | -------- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
ResultW
Same control unit as single-cycle processor

Control delayed to proper pipeline stage

Issues in Pipeline Design
 Balancing work in pipeline stages – ונלש סרוקב ךכב ןודנ אל
How many stages and what is done in each stage
 Keeping the pipeline correct, moving, and full in the
presence of events that disrupt pipeline flow
–
Handling dependences
• Data
• Control
– Handling resource contention ןורכזה לע תורחת לשמל
–
Handling long-latency (multi-cycle) operations
ןועש ירוזחמ תואמ תחקול הארוה רשאכ הרוק המ
 Handling exceptions, interrupts
קוסענ הלא לכב
 Advanced: Improving pipeline throughput תואבה תואצרהב
– 13
Minimizing stalls

Causes of Pipeline Stalls
 Stall: A condition when the pipeline stops moving
 Resource contention e.g., two units want to write to the GPR file
 Dependences (between instructions)
e.g., instruction uses reg. data that is not updated yet
 Data
 Control e.g., next instruction is not known yet, what to do?
 Long-latency (multi-cycle) operations
e.g., instruction that has cache miss (data is not there)
or even page fault.
14

Dependences and Their Types
 Also called “dependency” or less desirably “hazard”
 Dependences dictate ordering requirements between
instructions
 Two types
e.g., instruction uses data created by another
 Data dependence
instruction
e.g., instruction waits to updated reg for comparison
 Control dependence
 Resource contention is sometimes called resource
dependence
 However, this is not fundamental to (dictated by) program
semantics, so we will treat it separately
הצק לע ןודנ – בשחמה תינכתב תוחפו הרמוחב רתוי רושק הז גוס
.דרפנ ןוידל אשונ והז ךא .אבה ףקשב גלזמה
15

Handling Resource Contention
 Happens when instructions in two pipeline stages need
the same resource
 Solution 1: Eliminate the cause of contention
תונורתפל ריחמ שי
תלדגה :הלא
 Duplicate the resource or increase its throughput תלדגה/תולעה
ביכרה חטש
 E.g., use separate instruction and data memories (caches)
 E.g., use multiple ports for memory structures
 Solution 2: Detect the resource contention and stall one
High bandwidth memories
of the contending stages
 Which stage do you stall?
 Example: What if you had a single read and write port for
the register file? ארוקש הז תא וא בתוכש הז תא רוצעל
(תמדוק הדוקפל תכייש) רתוי תינכדע דימת הביתכה - ארוקש הז תא
16

Data Dependence
17

Data Dependences
 Types of data dependences ןיילפייפב םידבועשכ לופיטל םיבצמ
רומחה
 Flow dependence (true data dependence – read after השולשהמ
write)
 Output dependence (write after write)
 Anti dependence (write after read)
 Which ones cause stalls in a pipelined machine?
ןמיונ ןופ לש לדומה תא רפהל אל ונילע
 For all of them, we need to ensure semantics of the
program is correct
 Flow dependences always need to be obeyed because they
constitute true dependence on a value
 Anti and output dependences exist due to limited number
of architectural registers
 They are dependence on a name, not a value אל ,םירטסיגר תקוצמ
ןכות ללגב
18
 We will later see what we can do about them

A Special Case of Data Dependence
 Control dependence
 Data dependence on the Instruction Pointer / Program
Counter
PC -ה ברועמ הב םינותנב תולת לש יטרפ הרקמ איה הרקבב תולת 
19

Control Dependence
לש יטרפ הרקמ data dependence
 Question: What should the fetch PC be in the next cycle?
 Answer: The address of the next instruction
 All instructions are control dependent on previous ones. Why?
!ןמיונ ןופ
 If the fetched instruction is a non-control-flow instruction:
 Next Fetch PC is the address of the next-sequential
instruction
 Easy to determine if we know the size of the fetched instruction
 If the instruction that is fetched is a control-flow
instruction:
:הנה הז הרקמב היעבה
 How do we determine the next Fetch PC?
 In fact, how do we know whether or not the fetched
instruction is a control-flow instruction? תררועתמ היעבה
20
ןיילפייפב םדקומ

:יללכה הרקמל הרזח
Review: Once You Detect the Dependence in
Hardware
עדימה לש תונימזל תוכחל ךירצ אלו םדקומ בלשב תולגל ןתינ תולתה תא :הנבות
 What do you do afterwards?
 Observation: Dependence between two instructions is
detected before the communicated data value becomes
available ID בלשב
 Option 1: Stall the dependent instruction right away
 Option 2: Stall the dependent instruction only when
necessary  data forwarding/bypassing
 Option 3: …(value prediction)
21

Data Forwarding/Bypassing
 Problem: A consumer (dependent) instruction has to
wait in decode stage until the producer (parent)
instruction writes its value in the register file
 Goal: We do not want to stall the pipeline unnecessarily
 Observation: The data value needed by the consumer
instruction can be supplied directly from a later stage in
the pipeline (instead of only from the register file)
 Idea: Add additional dependence check logic and data
forwarding paths (buses) to supply the producer’s value
to the consumer right after the value is available
 Benefit: Consumer can move in the pipeline until the
22
point the value can be supplied  less stalling

...רמולכ
דע ID ה בלשב רוצעל ךירצ )היולתה הארוהה( "ןכרצה" :היעבה 
RF -ב ךרעה תא בתוכ "ןרציה"ש
אלש יאדוובו ןתינה לככ PIPELINE ה תריצעמ ענמהל :הרטמה 
.ךרוצל
ורובע קפוסמ תויהל לוכי ול קוקז ןכרצהש ךרעה :תוננובתה 
רשאמ רתוי םדקומ ךא PIPELINE -ב רתוי םדקתמ בלשמ
.RF-המ
,הרבעה )BUS( לולסמו תולת תקידבל הקיגול תפסוה :ןויערה 
רובע רצוימה ךרעה תא קפסל ידכ םינותנ לש ,FORWARDING
.רצוימ עדימשכ דיימ ןכרצה
.ךשמהב ךכ לע ביחרנ 

Data Dependence Types
היצמינא
Flow dependence
 r3 -ל ןכות רציימ : producer
|     | r      r |     |   op  r |     |     |  Read-after-Write   |     |     |
| --- | --------- | --- | ------- | --- | --- | ------------------- | --- | --- |
|     | 3         |     | 1       |     | 2   |                     |     |     |
r3 -מ ןכות ךרוצ :consumer
|     | r     r |     |   op  r |     |     |     |    (RAW) |     |
| --- | -------- | --- | ------- | --- | --- | --- | -------- | --- |
|     | 5        |     | 3       |     | 4   |     |          |     |
 ןומה ונל ויה ול
Anti dependence הריתפ היעבה הפ
 התיה אל ,םירטסיגר
| r   |      r |     |   op  r |     |    Write-after-Read  |     |     |     |
| --- | ------- | --- | ------- | --- | -------------------- | --- | --- | --- |
 בותכל הביס תמאב
| 3   |     | 1   |     | 2   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
 וז רמולכ .r1 -ל אקוד
| r   |      r |     |   op  r |     |     | (WAR) |     |  אלא ךרע לש היעב אל |
| --- | ------- | --- | ------- | --- | --- | ----- | --- | ------------------- |
| 1   |         | 4   |         | 5   |     |       |     |                     |
 ותואב שומיש לש היעב
.רטסיגר לש םש
Output-dependence ל"נכ
|     | r     r |     |   op  r |     |     |   Write-after-Write  |     |  ,ןאכ םג ןפוא ותואב |
| --- | -------- | --- | ------- | --- | --- | -------------------- | --- | ------------------- |
|     | 3        |     | 1       |     | 2   |                      |     |                     |
 r3 ךותל הינשה הביתכה
|     | r     r |     |   op  r |     |     |     | (WAW) |     |
| --- | -------- | --- | ------- | --- | --- | --- | ----- | --- |
 הלכי איה .תיתורירש איה
|     | 5   |     | 3   |     | 4   |     |      |     |
| --- | --- | --- | --- | --- | --- | --- | ---- | --- |
 בתכהל הדימ התואב
|     | r     r |     |   op  r |     |     |     |     |     |
| --- | -------- | --- | ------- | --- | --- | --- | --- | --- |
...r1000 ךותל
|     | 3   |     | 6   |     | 7   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
24

lw $10, 20($1)
|     |     |     |     | sub $11, $2, $3 |     |     | lw $10, 20($1) |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --------------- | --- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- |
Instruction fetch Instruction decode Execution sub $11, $2, $3 lw $10, 20($1)
0
|     |     | M   |     |     |     |     |     |     |     |     | Memory |     | Write back |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | ---------- | --- |
0 u
0 x
M M
1 u
x u
x
1
1
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
| --- | --- | --- | ----- | --- | --- | ----- | --- | --- | ------ | --- | --- | ------ | --- | --- |
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
Add
Add
|     |     | 4 Add |     |     |     |     |     | Add Add |     |     |     |     |     |     |
| --- | --- | ----- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- |
result
|     |     | 4   |     |     |     |     |     | Add Add |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- |
result Add
|     |     | 4   |     |     |     |     | Shift | Add result |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | ---------- | --- | --- | --- | --- | --- | --- |
left 2
Shift
left 2 Shift
left 2
|     |     |         |     | noitcurtsnI Read            |             |     |     |     |     |     |     |     |     |     |
| --- | --- | ------- | --- | --------------------------- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Address |     | register 1                  |             |     |     |     |     |     |     |     |     |     |
|     | PC  |         |     | noitcurtsnI Read            | Read        |     |     |     |     |     |     |     |     |     |
|     | PC  | Address |     | noitcurtsnI register 1 Read | data 1 Read |     |     |     |     |     |     |     |     |     |
register 1 Read
|     | PC  | Address            |     | Read register 2            | data 1 Read |     |     | Zero                |     |         |     |      |     |     |
| --- | --- | ------------------ | --- | -------------------------- | ----------- | --- | --- | ------------------- | --- | ------- | --- | ---- | --- | --- |
|     |     | Instruction        |     |                            | data 1      |     |     | Zero                |     |         |     |      |     |     |
|     |     | Instruction memory |     | register 2 Read Registers  | Read        |     |     | ALU ALU             |     |         |     |      |     |     |
|     |     |                    |     | register 2 Write Registers | data 2 Read |     | 0   | ALU result Zero ALU |     | Address |     | Read | 1   |     |
Instruction memory Write register Registers data 2 0 M ALU Address Read data
|                             |     | memory |     | register       | Read   |     | 0 M   | result ALU |     |           |                    | Read data | 1 M   |     |
| --------------------------- | --- | ------ | --- | -------------- | ------ | --- | ----- | ---------- | --- | --------- | ------------------ | --------- | ----- | --- |
|                             |     |        |     | Write          | data 2 |     | u     | result     |     | Address   | Data               |           | 1 M u |     |
|                             |     |        |     | register Write |        |     | M u x |            |     |           | Data               | data      | u     |     |
|                             |     |        |     | W data r i te  |        |     | x u   |            |     |           | memory memory Data |           | M x   |     |
|                             |     |        |     | da t a         |        |     | 1     |            |     |           |                    |           | 0 x u |     |
| Pipelined Operation Example |     |        |     | Write          |        |     | 1 x   |            |     | Write     | memory             |           | 0 x   |     |
|                             |     |        |     | data           |        |     | 1     |            |     | Write     |                    |           |       |     |
|                             |     |        |     |                |        |     |       |            |     | data data |                    |           | 0     |     |
Write
|     |     |     |     | 16  | 32  |     |     |     |     | data |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- |
16 Sign 32
16 Sign 32
extend extend Sign
extend
היצמינא
Clock 5 Clock 1
Clock 3
lw $10, 20($1)
|     |                                   |     |     | sub $11, $2, $3                   |     |     | lw $10, 20($1) |     |     |     |     |     |     |     |
| --- | --------------------------------- | --- | --- | --------------------------------- | --- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- |
|     | sub $11, $2, $3 Instruction fetch |     |     | Instruction decode lw $10, 20($1) |     |     | Execution      |     |     |     |     |     |     |     |
sub $11, $2, $3
Instruction fetch Instruction decode sub $11, $2, $3 lw $10, 20($1)
|     |     | 0 0 0 |     |     |     |     | sub $11, $2, $3 |     |     | lw $10, 20($1) |     |     |     |     |
| --- | --- | ----- | --- | --- | --- | --- | --------------- | --- | --- | -------------- | --- | --- | --- | --- |
0
|     |     | 0 M M M M |     |     |     |     |           |     |     |     |        |     | Write back |     |
| --- | --- | --------- | --- | --- | --- | --- | --------- | --- | --- | --- | ------ | --- | ---------- | --- |
|     |     | u u u     |     |     |     |     |           |     |     |     | Memory |     | Write back |     |
|     |     | 0 M u x   |     |     |     |     | Execution |     |     |     | Memory |     |            |     |
M x u x x
1 1 1 x
1 u
1 x
1
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
| --- | --- | --- | ----- | --- | --- | ----- | --- | --- | ------ | --- | --- | ------ | --- | --- |
IF/ID IF/ID IF/ID ID/EX ID/EX ID/EX EX/MEM EX/MEM EX/MEM MEM/WB MEM/WB MEM/WB
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
| --- | --- | --- | ----- | --- | --- | ----- | --- | --- | ------ | --- | --- | ------ | --- | --- |
|     |     |     | IF/ID |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |     |
Add Add
Add Add
Add
|     |     | Add |     |     |     |     |                          | Add                        |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------------------------ | -------------------------- | --- | --- | --- | --- | --- | --- |
|     |     | 4 4 |     |     |     |     |                          | Add Add result Add Add Add |     |     |     |     |     |     |
|     |     | 4 4 |     |     |     |     |                          | Add Add result result Add  |     |     |     |     |     |     |
|     |     | 4   |     |     |     |     |                          | Add result Add             |     |     |     |     |     |     |
|     |     | 4   |     |     |     |     | Shift                    | Add result                 |     |     |     |     |     |     |
|     |     |     |     |     |     |     | Shift Shift Shift left 2 | result                     |     |     |     |     |     |     |
Shift left 2
left 2 Shift left 2
left 2
|     |       |                         |     | noitcurtsnI Read                        |                       |     | left 2 |                    |     |     |     |     |     |     |
| --- | ----- | ----------------------- | --- | --------------------------------------- | --------------------- | --- | ------ | ------------------ | --- | --- | --- | --- | --- | --- |
|     | PC    | Address                 |     | noitcurtsnI Read Read Read register 1   |                       |     |        |                    |     |     |     |     |     |     |
|     | PC    | Address                 |     | noitcurtsnI noitcurtsnI Read register 1 | Read                  |     |        |                    |     |     |     |     |     |     |
|     | PC PC | Address Address         |     | noitcurtsnI Read register 1 register 1  | data 1 Read Read Read |     |        |                    |     |     |     |     |     |     |
|     | PC    | Address                 |     | noitcurtsnI register 1 register 1 Read  | data 1 Read           |     |        |                    |     |     |     |     |     |     |
|     | PC    | Address                 |     | Read Read Read register 2               | data 1 data 1 Read    |     |        | Zero               |     |     |     |     |     |     |
|     |       | Instruction Instruction |     | Read register 2 Registers               | data 1 data 1         |     |        | ALU Zero Zero Zero |     |     |     |     |     |     |
Instruction Instruction memory Read register 2 register 2 Registers Read 0 ALU Zero ALU Read
Instruction memory register 2 register 2 Write Registers Registers data 2 Read Read R e a d 0 ALU ALU Zero result ALU A ALU L U Address Read 1
Instruction memory memory Write Write Write register Registers da Read t a  2 0 0 M ALU re ALU su l t Address Read Read data 1
memory memory Write register Registers data 2 data 2 Read 0u 0M ALU result result ALU Address Address Address Data Read data data 1 1 M
Write register register register W r i te data 2 data 2 M M M u x result result Address Data Read data data 1 1 M M M u
|     |     |     |     | register Write        |     |     | M u u x   |     |     |     | memory Data Data | data | M u x     |     |
| --- | --- | --- | --- | --------------------- | --- | --- | --------- | --- | --- | --- | ---------------- | ---- | --------- | --- |
|     |     |     |     | Write W da r i t te a |     |     | u u x x 1 |     |     |     | memory Data      |      | M u u u x |     |
What if th Write data et  SUB were d 1 x ependent on LWmem?ory memory memory Data u x x 0
|     |     |     |     | Write data data da a |         |     | 1 1 x |     |     | Write                | memory |     | 0 x x |     |
| --- | --- | --- | --- | -------------------- | ------- | --- | ----- | --- | --- | -------------------- | ------ | --- | ----- | --- |
|     |     |     |     | data                 |         |     | 1 1   |     |     | Write Write data     |        |     | 0 0 0 |     |
|     |     |     |     |                      |         |     |       |     |     | Write Write data     |        |     | 0     |     |
|     |     |     |     | 16                   |         | 32  |       |     |     | Write data data data |        |     |       |     |
|     |     |     |     | 16                   | Sign 32 |     |       |     |     | data                 |        |     |       |     |
16 16 Sign 32 32
16 16 extend32 Sign Sign 32
extend Sign Sign
extend extend extend
extend
|     |     | Clock 1 Clock 3 |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Clock 5
|     |                 | Clock 6 Clock 2 Clock 4 |     |                |     |     |     |     |     |     |     |     |     |     |
| --- | --------------- | ----------------------- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | sub $11, $2, $3 |                         |     | lw $10, 20($1) |     |     |     |     |     |     |     |     |     |     |
)sub-ב$10  בותכ היה $3 םוקמב)  ?r3-מ םוקמב r10-מ ארוק היה sub ול הרוק היה המ
|     | Instruction fetch |     |     | Instruction decode |     |     |                 |     |     |                |     |     |                 |     |
| --- | ----------------- | --- | --- | ------------------ | --- | --- | --------------- | --- | --- | -------------- | --- | --- | --------------- | --- |
|     |                   |     |     |                    |     |     | sub $11, $2, $3 |     |     | lw $10, 20($1) |     |     |                 | 25  |
|     |                   | 0   |     |                    |     |     |                 |     |     |                |     |     | sub $11, $2, $3 |     |
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
|     |     | 0 M |     |     |     |     | Execution |     |     |     | Memory |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --------- | --- | --- | --- | ------ | --- | --- | --- |
0 u
|     |     | M M x |     |     |     |     |     |     |     |     |     |     | Write back |     |
| --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- |
u
1 x u
x
1 1
|     |     |     | IF/ID       |     |     | ID/EX       |     |     | EX/MEM        |     |     | MEM/WB        |     |     |
| --- | --- | --- | ----------- | --- | --- | ----------- | --- | --- | ------------- | --- | --- | ------------- | --- | --- |
|     |     |     | IF/ID IF/ID |     |     | ID/EX ID/EX |     |     | EX/MEM EX/MEM |     |     | MEM/WB MEM/WB |     |     |
Add
Add Add
Add
|     |     | 4   |     |     |     |     |     | Add |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
result
|     |     | 4 4 |     |     |     |     |       | Add Add Add Add |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | --------------- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     | Shift | result result   |     |     |     |     |     |     |
Shift left 2 Shift
left 2 left 2
Read
noitcurtsnI
|     | PC    | Address         |     | register 1 Read              | Read          |     |     |              |     |     |     |     |     |     |
| --- | ----- | --------------- | --- | ---------------------------- | ------------- | --- | --- | ------------ | --- | --- | --- | --- | --- | --- |
|     |       |                 |     | noitcurtsnI noitcurtsnI Read |               |     |     |              |     |     |     |     |     |     |
|     | PC PC | Address Address |     | register 1 Read register 1   | data 1 Read   |     |     |              |     |     |     |     |     |     |
|     |       |                 |     |                              | Read          |     |     | Zero         |     |     |     |     |     |     |
|     |       | Instruction     |     | register 2 Read              | data 1 data 1 |     |     |              |     |     |     |     |     |     |
|     |       |                 |     | Read Registers               | Read          |     |     | ALU ALU Zero |     |     |     |     |     |     |
Instruction memory register 2 Write register 2 0 Zero Address Read
Instruction Registers Registers data 2 Read ALU ALU result ALU data 1
memory memory register Write Read 0 M 0 ALU Address Read Read M
|     |     |     |     | Write                   | data 2 data 2 |     | u     | result result |     | Address    | Data          | data | 1 1   |     |
| --- | --- | --- | --- | ----------------------- | ------------- | --- | ----- | ------------- | --- | ---------- | ------------- | ---- | ----- | --- |
|     |     |     |     | register Write register |               |     | M x M |               |     |            |               | data | u M   |     |
|     |     |     |     |                         |               |     | u u   |               |     |            | memory Data   |      | M x u |     |
|     |     |     |     | data Write              |               |     | 1 x   |               |     |            | Data          |      | u     |     |
|     |     |     |     | Write data              |               |     | x     |               |     | Write      | memory memory |      | 0 x x |     |
|     |     |     |     | data                    |               |     | 1 1   |               |     |            |               |      | 0     |     |
|     |     |     |     |                         |               |     |       |               |     | data Write |               |      | 0     |     |
Write data
|     |     |     |     | 16  | 32  |     |     |     |     | data |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- |
Sign
16 32
16 extend Sign 32
extend Sign
extend
Clock 4
Clock 2
Clock 6

Data Dependence Handling:
More Depth & Implementation
data dependence לש תועמשמה
?םילגמ ךיא
?םילפטמ ךיא
26

How to Handle Data Dependences
 Anti and output dependences are easier to handle
write to the destination in one stage and in program order
בור תא רותפל רשפא
Flow dependences are more interesting
תחקל לכונ םא תויעבה
לגעמב םייק רבכש עדימ
תוחפ – רתויב הטושפה השיגה
GPR -ב ןכדוע אלש וליפא
הליעי
Six fundamental ways of handling flow dependences
רותפל רשפא
•
Detect and wait until value is available in register file
תויעבהמ קלח
י"ע( הנכותב
•
Detect and forward/bypass data to dependent instruction .)רלייפמוקה
רלייפמוקה םא
•
Detect and eliminate the dependence at the software level
רוזעל לכוי אל
nop סינכי אוה
No need for the hardware to detect dependence
תודוקפל רתוי םיאתמ
•
Predict the needed value(s), execute “speculatively”, הציפק
Value prediction
and then verify
OoO
•
Detect and move it out of the way for independent instructions
ךשמהב דמליי
•
Do something else (fine-grained multithreading). No need to detec27t

Interlocking
 Detection of dependence between instructions in a
pipelined processor to guarantee correct execution
 Software based interlocking (interlock prevention)
vs.
 Hardware based interlocking (interlock prevention)
 MIPS acronym?
I P S
Microprocessor without nterlocking ipeline tages
28

Load delay slot
RISC-V -ב אל ךא MIPS -ב
A load delay slot is an instruction which executes immediately after a load (of a register from memory) but does not
see, and need not wait for, the result of the load. Load delay slots are very uncommon because load delays are
highly unpredictable on modern hardware. A load may be satisfied from RAM or from a cache, and may be slowed
by resource contention. Load delays were seen on very early RISC processor designs. The MIPS I ISA
(implemented in the R2000 and R3000 microprocessors) suffers from this problem.
The following example is MIPS I assembly code, showing both a load delay slot and a branch delay slot.
lw v0,4(v1) # load word from address v1+4 into v0
nop # wasted load delay slot
jr v0 # jump to the address specified by v0
nop # wasted branch delay slot
רלייפמוקה ידי-לע nop תסנכה אלו Stall עצבת הרמוחה RISC-V-ב
Credit: Wikipedia, https://en.wikipedia.org/wiki/Delay_slot

Credit: "See MIPS run” by Dominic Sweetman
nop
forwarding
:איג
MIPS דבעמב
,"ןשוימ" דואמ
אלל
FORWARDING
2 ושדיי ,ללכ
שי םא .NOPs
FORWARDING
NOP קיפסי זא
.דחא
Late data from load (load delay slot): Another consequence of the pipeline is that a
load instruction’s data arrives from the cache/memory system after the next
instruction’s ALU phase starts - so it is not possible to use the data from a load in the
following instruction. (See Figure 1.4 for how this works.)
The instruction position immediately after the is called the load delay slot, and an
optimizing compiler will try to do something useful with it.
The assembler will hide this from you but may end up putting to a nop.

Add with Rs=$2 after lw with Rt=$2 does not work!!
| IF  | ID  | EX  | DM  | WB  |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
lw $2, …
|     | IF  | ID  | EX  | DM  | WB  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
add …, $2, …
|     |     | IF  | ID  | EX  | DM  | WB  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | IF  | ID  | EX  | DM  | WB  |     |     |     |
|     |     |     |     | IF  | ID  | EX  | DM  | WB  |     |     |
|     |     |     |     |     | IF  | ID  | EX  | DM  | WB  |     |
|     |     |     |     |     |     | IF  | ID  | EX  | DM  | WB  |
31

In MIPS adding a nop to solves it  )SW solution(
היצמינא
| IF  | ID  | EX  | DM  | WB  |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
lw $2, …
|     | IF  | ID  | EX  | DM  | WB  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
nop
|     |     | IF  | ID  | EX  | DM  | WB  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
add …, $2, …
|     |     |     | IF  | ID  | EX  | DM  | WB  |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     | IF  | ID  | EX  | DM  | WB  |     |     |
|     |     |     |     |     | IF  | ID  | EX  | DM  | WB  |     |
|     |     |     |     |     |     | IF  | ID  | EX  | DM  | WB  |
This is a “delayed load”
32
And we have a “delay slot” of one instruction after the lw

Approaches to Dependence Detection (I)
 Scoreboarding See next slide
 Each register in register file has a VVaalliidd bbiitt associated with it
 An instruction that is writing to the register resets the Valid bit
in IF and sets it back to “1” at WB
 An instruction in Decode stage checks if all its source and
destination registers are Valid
 Yes: No need to stall… No dependence
 No: Stall the instruction (the register in RF is not ready yet)
תועדוי ךכ ."rd"-ל Valid Bit -ה תא םיספאמ decode בלשב
 Advantage:
.ןכדועמ אל אוהש תואבה תדוקפה
רטסיגרה ."1"-ל שדחמ קלדנ Valid Bit -ה WB ה בלשב
 Simple. 1 bit per register
(רוזמרב קורי רוא) .ןכדועמ
 Disadvantage: תויולתה יגוס לכ יבגל הז תא ליכהל םיצלאנ go=1
stall=0
 Need to stall for all types of dependences, not only flow dep.
33

רוטקוו-ב RF תא םירבגתמ
1-bit per register היעב ןיא =1 ,הנתשי רטסגירה =0

Approaches to Dependence Detection (II)
 Combinational dependence check logic
 Special logic that checks if any instruction in later stages is
supposed to write to any source register of the instruction
that is being decoded
 Yes: stall the instruction/pipeline
 No: no need to stall… no flow dependence
 Advantage:
 No need to stall on anti and output dependences
 Disadvantage:
 Logic is more complex than a scoreboard
 Logic becomes more complex as we make the pipeline
deeper and wider (flash-forward: think superscalar
execution)
35

 רובע רוצעל ךירצ אל , scoreboardל הביטנרטלא
היצמינא
anti dependence
consume
r
producer
0
M
u
x
1
|     |     | IF/ID |     | ID/EX |     | EX/MEM |     |     | MEM/WB |
| --- | --- | ----- | --- | ----- | --- | ------ | --- | --- | ------ |
Add
| 4   |     |     |     |     | Add | Add |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
result
Shift
left 2
rs
Read
noitcurtsnI
| PC Address |     |     | register 1 | Read |     |     |     |     |     |
| ---------- | --- | --- | ---------- | ---- | --- | --- | --- | --- | --- |
rt
|     |     |     | Read | data 1 |     |     |     |     |     |
| --- | --- | --- | ---- | ------ | --- | --- | --- | --- | --- |
Zero
|     | Instruction |     | register 2 |        |     |        |         |      |     |
| --- | ----------- | --- | ---------- | ------ | --- | ------ | ------- | ---- | --- |
|     |             |     | Registers  | Read   |     | ALU    |         |      |     |
|     | memory      |     |            |        | 0   | ALU    |         | Read |     |
|     |             |     | Write      | data 2 |     | result | Address |      | 1   |
|     |             |     | register   |        | M   |        |         | data |     |
|     |             |     |            |        | u   |        |         | Data | M   |
u
|     |     |     | Write |     | x   |     |     | memory | x   |
| --- | --- | --- | ----- | --- | --- | --- | --- | ------ | --- |
|     |     |     | data  |     | 1   |     |     |        |     |
0
Write
data
|     |     |     | 16  | 32  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign
extend
If rs == rd1 or
|     |     |     |     |     | rd1 |     | rd2 |     | rd3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
rs == rd2 or
rs == rd3  - Stall IF & ID
Same for rt.
producer

Once You Detect the Dependence in Hardware
 What do you do afterwards?
 Observation: Dependence between two instructions is
detected before the communicated data value becomes
available
 Option 1: Stall the dependent instruction right away
 Option 2: Stall the dependent instruction only when
necessary  data forwarding/bypassing
 Option 3: …
וללה םיגשומה תא הליחת רידגהל םיכירצ
ונרדגה אל ןיידע
37

Remember: Data Dependence Types
היצמינא
Flow dependence
| r   |      r |   op  r |     |     |  Read-after-Write   |          |     |
| --- | ------- | ------- | --- | --- | ------------------- | -------- | --- |
| 3   |         | 1       |     | 2   |                     |          |     |
| r   |     r  |   op  r |     |     |                     |    (RAW) |     |
| 5   |         | 3       |     | 4   |                     |          |     |
Anti dependence הריתפ היעבה הפ
| r   |      r |     |   op  r |     |    Write-after-Read  |       |     |
| --- | ------- | --- | ------- | --- | -------------------- | ----- | --- |
| 3   |         | 1   |         | 2   |                      |       |     |
| r   |      r |     |   op  r |     |                      | (WAR) |     |
| 1   |         | 4   |         | 5   |                      |       |     |
 אלו םשב איה תולתה
Output-dependence ל"נכ ךרעב
|     | r     r |     |   op  r |     |     |   Write-after-Write  |       |
| --- | -------- | --- | ------- | --- | --- | -------------------- | ----- |
|     | 3        |     | 1       |     | 2   |                      |       |
|     | r     r |     |   op  r |     |     |                      | (WAW) |
|     | 5        |     | 3       |     | 4   |                      |       |
|     | r     r |     |   op  r |     |     |                      |       |
|     | 3        |     | 6       |     | 7   |                      |       |
38

RAW Dependence Handling
היצמינא
 Which one of the following flow dependences lead to
conflicts in the 5-stage pipeline?
Producing register A
| addi   | ra  r-  | IF                   | ID  | EX  | MEM | WB  |     |
| ------ | ------- | -------------------- | --- | --- | --- | --- | --- |
|        |         |                      | IF  | ID  | EX  | MEM | WB  |
| addi   | r- ra - |                      |     |     |     |     |     |
| addi   | r- ra - | Consuming register A |     | IF  | ID  | EX  | MEM |
|        |         |                      |     |     | IF  | ID  | EX  |
| addi   | r- ra - |                      |     |     |     |     |     |
| addi   | r- ra - |                      |     |     |     | IF  | ID  |
ליגר םדקתהל תולוכי הלא תוארוה 2 קר
IF
| addi   | r- ra - |     |     |     |     |     |     |
| ------ | ------- | --- | --- | --- | --- | --- | --- |
39

רטסיגר ףאב היולת אל j הדוקפ
Register Data Dependence Analysis
|     | R/I-Type | LW  | SW  | Br  | J   | Jr  |
| --- | -------- | --- | --- | --- | --- | --- |
IF
| ID  | read RF | read RF | read RF | read RF |     | read RF |
| --- | ------- | ------- | ------- | ------- | --- | ------- |
EX
|     |     |  (השדח) האירקש ןכתיי |     |  תרחואמ הארוה = השדח הארוה |     |     |
| --- | --- | -------------------- | --- | -------------------------- | --- | --- |
רתוי
 הביתכב היולת רטסיגרמ
MEM
הקיתו הארוה = הנשי הארוה
רטסיגרל (הקיתו)
| WB  | write RF | write RF |     |     |     |     |
| --- | -------- | -------- | --- | --- | --- | --- |
For a given pipeline, when is there a potential conflict
between two data dependent instructions?
 dependence type: RAW, WAR, WAW?
 instruction types involved?
 distance between the two instructions?
יפיצפס םגדב אלו יללכ דבעמב קסוע אוהש םושמ בושח הזה ףקשה
40

RAW -ב  ןיילפייפב תומדקתה וא הריצעל יאנתה לש ילמרופ חוסינ
When it is Safe and Unsafe Movement of
Pipeline
forward
anti
output
stage X
| j:_r |     | Reg Read |     |     | j:r | _  |     | Reg Write | j:r | _  | Reg Write |
| ----- | --- | -------- | --- | --- | --- | --- | --- | --------- | --- | --- | --------- |
|       | k   |          |     |     | k   |     |     |           | k   |     |           |
|       | i j |          |     |     |     | i   | j   |           |     | i j |           |
|       | F   |          |     |     |     | A   |     |           |     | O   |           |
stage Y
| i:r | _             | Reg Write |     |     | i:_r |     |                | Reg Read | i:r | _             | Reg Write |
| --- | -------------- | --------- | --- | --- | ----- | --- | -------------- | -------- | --- | -------------- | --------- |
|     | k              |           |     |     |       | k   |                |          |     | k              |           |
|     | RAW Dependence |           |     |     |       |     | WAR Dependence |          |     | WAW Dependence |           |
|     |                |           |     |    |       |     |                |          |     |                |           |
קחרמה d i s t ( i , j )       d i s t ( X , Y )        U nsafe to keep j moving
|     |     |     | d i s t | ( i , j )      | d i | s t ( X | , Y )    |     ?? |     |     |     |
| --- | --- | --- | ------- | --------------- | --- | ------- | --------- | ------ | --- | --- | --- |
חוטב בצמל ןוירטירקה
הקיתו הארוה איה הטמל הארוה d i s t ( i , j )     >   d i s t ( X , Y )       S a fe
|     |     |     | d i s t | ( i , j )     > |   d i s | t ( X | , Y )    |     ? ? |     |     |     |
| --- | --- | --- | ------- | --------------- | ------- | ----- | --------- | ------- | --- | --- | --- |

41
השדח הארוה איה הלעמל הארוה

RAW Dependence Analysis Example
|     |     | R/I-Type |     | LW  | SW  |     | Br  | J   | Jr  |
| --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- |
IF
|     | ID  | read RF |     | read RF | read RF |     | read RF |     | read RF |
| --- | --- | ------- | --- | ------- | ------- | --- | ------- | --- | ------- |
EX
MEM
|                | WB  | write RF |        | write RF  |     |                 |     |             |     |
| -------------- | --- | -------- | ------ | --------- | --- | --------------- | --- | ----------- | --- |
| Instructions I |     |          |  and I |  (where I |     |  comes before I |     | ) have RAW  |     |

|     |     |     | A   | B   |     | A   |     | B   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
dependence iff
I  (R/I, LW, SW, Br or JR) reads a register written by I  (R/I or LW)

|     | B          |                                            |     |     |     |     |     |     | A   |
| --- | ---------- | ------------------------------------------ | --- | --- | --- | --- | --- | --- | --- |
|    | dist(I , I | )  dist(ID, WB) = 3(*) (MIPS) =2 (RISC-V) |     |     |     |     |     |     |     |
|     | A          | B                                          |     |     |     |     |     |     |     |
 הז םא .RF-ה תא ןועש ךלהמ ותואב אורקלו בותכל ןתינ אל םא 3 )*( 
.2 אוה חוורמה זא )םימישרתב רחשומ יצח( רשפאתמ
42

Pipeline Stall: Resolving Data Dependence
היצמינא
i הארוהב היולת j הארוה
|     | tttt | tttt | tttt | tttt | tttt | tttt |     |     |
| --- | ---- | ---- | ---- | ---- | ---- | ---- | --- | --- |
|     | 0000 | 1111 | 2222 | 3333 | 4444 | 5555 |     |     |
IIIInnnnsssstttt
|     | IIIIFFFF | IIIIDDDD | AAAALLLLUUUU | MMMMEEEEMMMM | WWWWBBBB |     |     |     |
| --- | -------- | -------- | ------------ | ------------ | -------- | --- | --- | --- |
hhhh
IIIInnnnsssstttt
|     | iiii | IIIIFFFF | IIIIDDDD | AAAALLLLUUUU | MMMMEEEEMMMM | WWWWBBBB |     |     |
| --- | ---- | -------- | -------- | ------------ | ------------ | -------- | --- | --- |
iiii
IIIInnnnsssstttt jjjj IIIIFFFF IIIIDDDD AIIIDDDLU MAIIDDLEUM WMAIDLEBUM WMALEBUM
jjjj
IIIInnnnsssstttt IIIIFFFF IIIIDFFF AIIIDFFLU MAIIDFLEUM WMAIDLEBUM
kkkk
| IIIInnnnsssstttt |     |     |     |     | IF  | IIDF | AIIDFLU | MAIIDFLEUM |
| ---------------- | --- | --- | --- | --- | --- | ---- | ------- | ---------- |
llll
הרמוחב וא הנכתב םשייל רשפא Bubble
|     |     |     |     |     |     | IF  | IIDF | AIIDFLU |
| --- | --- | --- | --- | --- | --- | --- | ---- | ------- |
iiii::::    rrrr     ____
|     | xxxx     |     |     |     |     |     | IF  | IIDF |
| --- | -------- | --- | --- | --- | --- | --- | --- | ---- |
Stall = make the dependent instruction
|     | jbbb: uuu_bbb  bbblll eeer |     |     |     |     |     |     |     |
| --- | --------------------------- | --- | --- | --- | --- | --- | --- | --- |
dist(i,j)=1
wait until its source data value is available
|     |                       | x           |     |     |     |     |     | IF  |
| --- | --------------------- | ----------- | --- | --- | --- | --- | --- | --- |
|     | jbb: uu_bb  bbll eer | dist(i,j)=2 |     |     |     |     |     |     |
1. stop all up-stream stages  (new inst.)
x
|     | jb: u_b  bl er | dist(i,j)=3 |     |     |     |     |     |     |
| --- | --------------- | ----------- | --- | --- | --- | --- | --- | --- |
2. drain all down-stream stages
x
|     | j: _  r | dist(i,j)=4 |     | (older1-s) |     |     |     |     |
| --- | -------- | ----------- | --- | ---------- | --- | --- | --- | --- |
43
x

הרמוחב stall (Bubble) שומימ
| upstream |     |     |     |     | downstream |     |     |     |     |     |
| -------- | --- | --- | --- | --- | ---------- | --- | --- | --- | --- | --- |
PCSrc
ID/EX
0
M
| u   |     |     |     | WB  |     |     | EX/MEM |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | --- |
x
1
|     |       |     | Control | M   |     |     | WB  |     | MEM/WB |     |
| --- | ----- | --- | ------- | --- | --- | --- | --- | --- | ------ | --- |
|     | IF/ID |     |         | EX  |     |     | M   |     | WB     |     |
Add
| 4   |     |     |     |     | Addresult | Add |     |     |     |     |
| --- | --- | --- | --- | --- | --------- | --- | --- | --- | --- | --- |
etirWgeR
Branch
Shift
|     |     |     |     |     | left 2 |     |     | etirWmeM |     |     |
| --- | --- | --- | --- | --- | ------ | --- | --- | -------- | --- | --- |
ALUSrc
|            | noitcurtsnI | Read       |     |     |     |     |     |     |     | geRotmeM |
| ---------- | ----------- | ---------- | --- | --- | --- | --- | --- | --- | --- | -------- |
| PC Address |             | register 1 |     |     |     |     |     |     |     |          |
Read
data 1
|             |     | Read        |           |     |     | Zero      |     |         |         |     |
| ----------- | --- | ----------- | --------- | --- | --- | --------- | --- | ------- | ------- | --- |
| Instruction |     | register 2  |           |     |     |           |     |         |         |     |
|             |     | Registers   | R e a d   |     | ALU | A L U     |     |         |         |     |
| memory      |     | W ri t e    | da t a  2 |     | 0   | re su l t |     | Address | R e a d | 1   |
|             |     | reg i s ter |           |     | M   |           |     |         | d a ta  |     |
|             |     |             |           |     |     |           |     | Data    |         | M   |
|             |     |             |           |     | u   |           |     | memory  |         | u   |
|             |     | Write       |           |     | x   |           |     |         |         | x   |
|             |     | data        |           |     | 1   |           |     |         |         |     |
0
Write
data
|     |     | Instruction | 16   | 32  | 6   |     |     |     |     |     |
| --- | --- | ----------- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |     | [15–0]      | Sign |     | ALU |     |     |     |     |     |
MemRead
|     |     |     | extend |     | control |     |     |     |     |     |
| --- | --- | --- | ------ | --- | ------- | --- | --- | --- | --- | --- |
Instruction
[20–16]
|     |     |     |     |     | 0 ALUOp |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- |
M
 disable תושעל ךירצ u
Instruction
|     |     | [15–11] |     |     | x   |     |     |     |     |     |
| --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
pipeline register -ל 1
RegDst
.PC-לו (IF/ID)
|     |     |     |     |     |     |     | V   |     | V   |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | V   |     |     | 0   |     |     |     |     |     |     |
 nop סינכהל ךירצ . UP STREAM ה תריצע
 valid bit. 0  םשב םירטסיגרב דחוימ טיב תפסוה ידי לע תאז תושעל ןתינ
 -ל רמולכ ,pipeline register-ל ןימימש רטסיגרל
control-ה תאיציב הרקבה יווק לכ סופיא י"ע וא ,nop ותועמשמ =
.ID/EX

RAW Data Dependence Exampהיlצeמינא
 One instruction writes a register ($s0) and next
instructions read this register => read after write (RAW)
dependence.
Only if the pipeline handles
  add writes into $s0 in the first half of cycle 5
 and reads $dsa0 toan  dcyecplee 3n,d oebntacineisn gw trhoen wgr!ong value

 or reads $s0 on cycle 4, again obtaining the wrong value

  sub reads $s0 in 2nd half of cycle 5, getting the correct
value
|                                                   | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8                  |
| ------------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | ------------------ |
|  subsequent instructions read the correct value o |     |     |     |     |     |     |     | f   $ s 0          |
|                                                  |     |     |     |     |     |     |     | T im e  (cy cle s) |
$s2
$s0
| add $s0, $s2, $s3 | IM add | RF  |     | DM  | RF  |     |     |     |
| ----------------- | ------ | --- | --- | --- | --- | --- | --- | --- |
|                   |        | $s3 | +   |     |     |     |     |     |
$s0
|                   |     | and |        |     | DM $t0 |     |     |     |
| ----------------- | --- | --- | ------ | --- | ------ | --- | --- | --- |
| and $t0, $s0, $s1 |     | IM  | RF $s1 | &   |        | RF  |     |     |
$s4
|                   |     |     | or  |        |     | DM  | $t1 |     |
| ----------------- | --- | --- | --- | ------ | --- | --- | --- | --- |
| or  $t1, $s4, $s0 |     |     | IM  | RF $s0 | |   |     | RF  |     |
$s0
$t2
| sub $t2, $s0, $s5 |     |     |     | IM sub | RF  |     | DM  | RF  |
| ----------------- | --- | --- | --- | ------ | --- | --- | --- | --- |
|                   |     |     |     |        | $s5 | -   |     |     |

Compile-Time Detection and Elimination
|     | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Time (cycles)
$s2
|                   | add |     |     | DM  | $s0 |     |     |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| add $s0, $s2, $s3 | IM  | RF  | +   |     | RF  |     |     |     |     |     |
$s3
|     |     | nop |     |     | DM  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| nop |     | IM  | RF  |     |     | RF  |     |     |     |     |
|     |     |     | nop |     |     | DM  |     |     |     |     |
| nop |     |     | IM  | RF  |     |     | RF  |     |     |     |
$s0
|                   |     |     |     | and |     |     | DM  | $t0 |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| and $t0, $s0, $s1 |     |     |     | IM  | RF  | &   |     | RF  |     |     |
$s1
$s4
|                   |     |     |     |     | or  |     |     | DM $t1 |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- |
| or  $t1, $s4, $s0 |     |     |     |     | IM  | RF  | |   |        | RF  |     |
$s0
$s0
|                   |     |     |     |     |     | sub |     |     | DM  | $t2 |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sub $t2, $s0, $s5 |     |     |     |     |     | IM  | RF  | -   |     | RF  |
$s5
 Insert enough NOPs for the required result to be ready
 Or (if you can) move independent useful instructions up

nop
)הקיזמ אל( קרס תדוקפ
MIPS uses
sll $0, $0, 0
as the nop instruction.
RISC-V
addi zero, zero, 0 (see H&H chapter 6)

How to Implement Stalling
PCSrc
ID/EX
0
M
| u   |     |     |     | WB  |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
EX/MEM
x
1
|     |     |     | Control | M   |     |     | WB  |     |     |     |     |
| --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | --- |
MEM/WB
|     | IF/ID |     |     | EX  |     |     | M   |     |     | WB  |     |
| --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Add
Add
| 4   |     |     |     |     | Addresult |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --------- | --- | --- | --- | --- | --- | --- |
etirWgeR
Branch
Shift
left 2
etirWmeM
ALUSrc
|            | noitcurtsnI | Read       |     |     |     |     |     |     |     |     | geRotmeM |
| ---------- | ----------- | ---------- | --- | --- | --- | --- | --- | --- | --- | --- | -------- |
| PC Address |             | register 1 |     |     |     |     |     |     |     |     |          |
Read
|     |     | Read       | data 1 |     |     |      |     |     |     |     |     |
| --- | --- | ---------- | ------ | --- | --- | ---- | --- | --- | --- | --- | --- |
|     |     | register 2 |        |     |     | Zero |     |     |     |     |     |
Instruction
| memory |     | Registers   | R e a d   |     | ALU | A L U     |     |         |         |     |     |
| ------ | --- | ----------- | --------- | --- | --- | --------- | --- | ------- | ------- | --- | --- |
|        |     | W ri t e    | da t a  2 |     | 0   | re su l t |     | Address | R e a d |     | 1   |
|        |     | reg i s ter |           |     | M   |           |     |         | d a ta  |     |     |
|        |     |             |           |     | u   |           |     | Data    |         |     | M   |
|        |     |             |           |     |     |           |     | memory  |         |     | u   |
|        |     | Write       |           |     | x   |           |     |         |         |     | x   |
|        |     | data        |           |     | 1   |           |     |         |         |     |     |
|        |     |             |           |     |     |           |     | Write   |         |     | 0   |
data
|     |     | Instruction | 16   | 32  | 6   |     |     |     |     |     |     |
| --- | --- | ----------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | [15–0]      | Sign |     | ALU |     |     |     |     |     |     |
MemRead
|     |     |     | extend |     | control |     |     |     |     |     |     |
| --- | --- | --- | ------ | --- | ------- | --- | --- | --- | --- | --- | --- |
Instruction
[20–16]
0
ALUOp
M
u
|     |     | Instruction |     |     | x   |     |     |     |     |     |     |
| --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
[15–11]
1
RegDst
Stall
 disable PC and IR latching; ensure stalled instruction stays in its stage
 Insert “invalid” instructions/nops into the stage following the stalled one
(called “bubbles”) 48
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Stall Conditions הריצעה יאנת ,םוכיסל
| Instructions I |  and I |  (where I |  comes before I | ) have RAW  |
| -------------- | ------ | --------- | --------------- | ----------- |

|     | A   | B   | A   | B   |
| --- | --- | --- | --- | --- |
dependence iff
I  (R/I, LW, SW, Br or JR) reads a register written by I  (R/I or LW)

| B   |     |     |     | A   |
| --- | --- | --- | --- | --- |
 dist(I , I )  dist(ID, WB) = 3(*) (or 2)
A B
Must stall the ID  stage when I  in ID stage wants to read a

B
| register to be written by I |     |  in EX, MEM or WB stage |     |     |
| --------------------------- | --- | ----------------------- | --- | --- |
A
49

היצמינא
Stall Condition Evaluation Logic
.תירוטניבמוקה ךרדה וז
Helper functions –   הארוהה רובע רזע ’נופ רידגנ
)scoreboard  וניא הז(
 rs(I) returns the rs field of I – הזה הדשב אצמנש רטסיגרה ימ
 use_rs(I) returns true if I requires  [rs] and rs!=r0
RF – ותוא אורקל שרדנ םאה
 םגו EX בלשב אצמנש rd-ל ההז ID -ב אצמנש rs רטסיגרה םא :ןושארה יאנתה ,המגודל
  EX-ב GPR-ל הביתכל הרקב תוא שי םגו רטסיגרה ותוא אורקל הכירצ ןכא ID-בש הדוקפה
 Stall signal when
 stall  עצבל ךירצ זא
רטסיגרה ותוא        &&     האירק היהת      &&        הביתכ היהת
|    | (rs( | IR  | )==dest |     | ) && use_rs( | IR  | ) && RegWrite |     | or  |     |
| --- | ---- | --- | ------- | --- | ------------ | --- | ------------- | --- | --- | --- |
|     |      |     | ID      | EX  |              |     | ID            | EX  |     |     |
 א"כ רובע
|     | (rs( |     | )==dest |     | ) && use_rs( |     | ) && RegWrite |     |  or |         |
| --- | ---- | --- | ------- | --- | ------------ | --- | ------------- | --- | --- | ------- |
|    |      | IR  |         |     |              |     | IR            |     |     |  תשולשמ |
|     |      |     | ID      | MEM |              |     | ID            | MEM |     |         |
 םיבצמה
םיירשפאה
|    | (rs( |     | )==dest |     | ) && use_rs( |     | ) && RegWrite |          |     |            |
| --- | ---- | --- | ------- | --- | ------------ | --- | ------------- | -------- | --- | ---------- |
|     |      | IR  |         |     |              |     | IR            |          |     |            |
|     |      |     | ID      | WB  |              |     | ID            | WB       |     |            |
|     | (rt( |     | )==dest |     | ) && use_rt( |     | ) && RegWrite |       or |     |            |
|    |      | IR  |         |     |              | IR  |               |          |     |  רופיסה לכ |
|     |      |     |         | EX  |              |     |               | EX       |     |            |
|     |      |     | ID      |     |              |     | ID            |          |     |            |
 הלעמלש
 םעפ
|    | (rt( | IR  | )==dest |     | ) && use_rt( |     | IR ) && RegWrite |     |   or |        |
| --- | ---- | --- | ------- | --- | ------------ | --- | ---------------- | --- | ---- | ------ |
|     |      |     | ID      | MEM |              |     | ID               | MEM |      |  תפסונ |
rt רובע
|     | (rt( |     | )==dest |     | ) && use_rt( |     | ) && RegWrite |     |     |     |
| --- | ---- | --- | ------- | --- | ------------ | --- | ------------- | --- | --- | --- |
|    |      | IR  |         |     |              | IR  |               |     |     |     |
|     |      |     | ID      | WB  |              |     | ID            | WB  |     |     |
 It is crucial that the EX, MEM and WB stages continue to advance
normally during stall cycles
50

וניארהש ןושארה יגולה יאנתה לש השחמה
היצמינא
Stall
signal
0
?RS1 תא ךירצ
Valid bit
RD
RS1==RD ?
EX EX
RegWrite
E
X

Detecting the Need to Forward
שומימה איה ינושל הביסה .םדוקה ףקשב ומכ 3 אלו הקידב יאנת 2 םיאור ונא ,7 קרפ H&H -ב ומכ ,ןאכ
)םדוקה ףקשב ומכ( םיבלשה ךותב וא )ןאכ ומכ( םיצצוחה םירטסיגרב Hazard Unit-ה לש הנושה
Pass register numbers along pipeline
e.g., ID/EX.RegisterRs1 = register number for Rs1
sitting in ID/EX pipeline register
ALU operand register numbers in EX stage
are given by
ID/EX.RegisterRs1, ID/EX.RegisterRs2
Data hazards when
Fwd from
1a. EX/MEM.RegisterRd = ID/EX.RegisterRs1
EX/MEM
pipeline reg
1b. EX/MEM.RegisterRd = ID/EX.RegisterRs2
2a. MEM/WB.RegisterRd = ID/EX.RegisterRs1 Fwd from
MEM/WB
2b. MEM/WB.RegisterRd = ID/EX.RegisterRs2
pipeline reg
Credit: H&P, CO&D RISC-V Ed. 2
Chapter 4 — The Processor — 52

?)stall signal( הריצעה תוא םע םישוע ונחנא המ
לש WRITE ENABLE אובמב )disable( םסוח רותב שמשמ -
PC-ה
VALID BIT -ה יונישל שמשמ -
השעמל ךכ ,0-ל ךופהי VALID BIT -ה זא 1 אוה תואה םא --
.)bubble( העובה תסנכומ
ךישמהל ךירצ pipeline-ה VALID BIT (Down stream) -ל ןימימ
dead lock ונל שי תרחא ,םדקתהל

Hardware Needed for Stalling
היצמינא
 Stalls are supported by
 adding enable inputs (EN) to the Fetch and Decode pipeline
registers
 and a synchronous reset/clear (CLR) input to the Execute
pipeline register
 or an INV bit associated with each pipeline register, indicating
that contents are INValid
 When a lw stall occurs
 StallD and StallF are asserted to force the Decode and
Fetch stage pipeline registers to hold their old values.
 FlushE is also asserted to clear the contents of the Execute
stage pipeline register, introducing a bubble

|      |        |       |   ”  |       |        |
| ---- | ------ | ----- | ---- | ----- | ------ |
| ךותמ | םיפקשה | תפוסא | ב צמ | רבסהה | קוזיחל |
H&P CO&D Chapter 4

Dependencies & Forwarding
Chapter 4 — The Processor — 56

Detecting the Need to Forward
Pass register numbers along pipeline
e.g., ID/EX.RegisterRs1 = register number for Rs1
sitting in ID/EX pipeline register
ALU operand register numbers in EX stage
are given by
ID/EX.RegisterRs1, ID/EX.RegisterRs2
Data hazards when
Fwd from
1a. EX/MEM.RegisterRd = ID/EX.RegisterRs1
EX/MEM
pipeline reg
1b. EX/MEM.RegisterRd = ID/EX.RegisterRs2
2a. MEM/WB.RegisterRd = ID/EX.RegisterRs1 Fwd from
MEM/WB
2b. MEM/WB.RegisterRd = ID/EX.RegisterRs2
pipeline reg
Chapter 4 — The Processor — 57

Detecting the Need to Forward
But only if forwarding instruction will write to a register!
EX/MEM.RegWrite, MEM/WB.RegWrite
And only if Rd for that instruction is not x0
EX/MEM.RegisterRd = Y 0,
MEM/WB.RegisterRd = Y 0
Chapter 4 — The Processor — 58

Forwarding Paths
Chapter 4 — The Processor — 59

Forwarding Conditions
Mux control Source Explanation
ForwardA = 00 ID/EX The first ALU operand comes from the register file.
ForwardA = 10 EX/MEM The first ALU operand is forwarded from the prior
ALU result.
ForwardA = 01 MEM/WB The first ALU operand is forwarded from data
memory or an earlier ALU result.
ForwardB = 00 ID/EX The second ALU operand comes from the register
file.
ForwardB = 10 EX/MEM The second ALU operand is forwarded from the prior
ALU result.
ForwardB = 01 MEM/WB The second ALU operand is forwarded from data
memory or an earlier ALU result.
Chapter 4 — The Processor — 60

Double Data Hazard
Consider the sequence:
add x1,x1,x2
add x1,x1,x3
add x1,x1,x4
Both hazards occur
Want to use the most recent
Revise MEM hazard condition
Only fwd if EX hazard condition isn’t true
Chapter 4 — The Processor — 61

Revised Forwarding Condition
MEM hazard
 if (MEM/WB.RegWrite
and (MEM/WB.RegisterRd =Y 0)
and not(EX/MEM.RegWrite and (EX/MEM.RegisterRd =Y 0)
and (EX/MEM.RegisterRd =Y ID/EX.RegisterRs1))
and (MEM/WB.RegisterRd = ID/EX.RegisterRs1)) ForwardA = 01
 if (MEM/WB.RegWrite
and (MEM/WB.RegisterRd =Y 0)
and not(EX/MEM.RegWrite and (EX/MEM.RegisterRd =Y 0)
and (EX/MEM.RegisterRd =Y ID/EX.RegisterRs2))
and (MEM/WB.RegisterRd = ID/EX.RegisterRs2)) ForwardB = 01
Chapter 4 — The Processor — 62

Datapath with Forwarding
Chapter 4 — The Processor — 63

Load-Use Hazard Detection
Check when using instruction is decoded in ID stage
ALU operand register numbers in ID stage are given by
IF/ID.RegisterRs1, IF/ID.RegisterRs2
Load-use hazard when
ID/EX.MemRead and
((ID/EX.RegisterRd = IF/ID.RegisterRs1) or
(ID/EX.RegisterRd = IF/ID.RegisterRs1))
If detected, stall and insert bubble
Chapter 4 — The Processor — 64

How to Stall the Pipeline
Force control values in ID/EX register
to 0
EX, MEM and WB do nop (no-operation)
Prevent update of PC and IF/ID register
Using instruction is decoded again
Following instruction is fetched again
1-cycle stall allows MEM to read data for ld
• Can subsequently forward to EX stage
Chapter 4 — The Processor — 65

Load-Use Data Hazard
Stall inserted
here
Chapter 4 — The Processor — 66

Datapath with Hazard Detection
Chapter 4 — The Processor — 67

Stalls and Performance
The BIG Picture
Stalls reduce performance
But are required to get correct results
Compiler can arrange code to avoid hazards and stalls
Requires knowledge of the pipeline structure
Chapter 4 — The Processor — 68

Branch Hazards
If branch outcome determined in MEM
Chapter 4 — The Processor — 69
§4.9
Control
Hazards
Flush these
instructions
(Set control
values to 0)
PC

Reducing Branch Delay
Move hardware to determine outcome to ID
stage
Target address adder
Register comparator
Example: branch taken
36: sub x10, x4, x8
40: beq x1, x3, 16 // PC-relative branch
// to 40+16*2=72
44: and x12, x2, x5
48: orr x13, x2, x6
52: add x14, x4, x2
56: sub x15, x6, x7
...
72: ld x4, 50(x7)
Chapter 4 — The Processor — 70

Example: Branch Taken
Chapter 4 — The Processor — 71

Example: Branch Taken
Chapter 4 — The Processor — 72

Data Hazards for Branches
If a comparison register is a destination of 2nd or 3rd
preceding ALU instruction
| add x1, x2, x3     | IF  | ID  | EX  | MEM | WB  |     |     |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- | --- |
| add x4, x5, x6     |     | IF  | ID  | EX  | MEM | WB  |     |     |
| …                  |     |     | IF  | ID  | EX  | MEM | WB  |     |
| beq x1, x4, target |     |     |     | IF  | ID  | EX  | MEM | WB  |
Can resolve using forwarding

Chapter 4 — The Processor — 73

Data Hazards for Branches
If a comparison register is a destination of preceding
ALU instruction or 2nd preceding load instruction
Need 1 stall cycle
| lw  x1, addr       | IF  | ID  | EX  | MEM | WB  |     |     |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- | --- |
| add x4, $x5, $x6   |     | IF  | ID  | EX  | MEM | WB  |     |     |
| beq stalled        |     |     | IF  | ID  |     |     |     |     |
| beq x1, x4, target |     |     |     |     | ID  | EX  | MEM | WB  |
Chapter 4 — The Processor — 74

Data Hazards for Branches
If a comparison register is a destination of immediately
preceding load instruction
Need 2 stall cycles
| lw  x1, addr       | IF  | ID  | EX  | MEM | WB  |     |     |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- | --- |
| beq stalled        |     | IF  | ID  |     |     |     |     |     |
| beq stalled        |     |     |     | ID  |     |     |     |     |
| beq x1, x0, target |     |     |     |     | ID  | EX  | MEM | WB  |
Chapter 4 — The Processor — 75

Back to CMU slides

Impact of Stall on Performance
 Each stall cycle corresponds to one lost cycle in which no
instruction can be completed
 For a program with N instructions and S stall cycles,
Average CPI=(N+S)/N
CPI=1 :רכומה בצמל ונרזח זא s=0 םא

 S depends on
frequency of RAW dependences

|  exact distance between the dependent instructions |     |     |     | המגוד |     |
| --------------------------------------------------- | --- | --- | --- | ----- | --- |
distance between dependences ןיילפייפה ךותב

suppose i ,i  and i  all depend on i , once i ’s dependence is
|             | 1 2    |   3              | 0   | 1   |     |
| ----------- | ------ | ---------------- | --- | --- | --- |
| resolved, i |  and i | must be okay too |     |     | 77  |
|             | 2      | 3                |     |     |     |

Intel Pentium 4 Prescott (2004)
https://techreport.com/review/6213/intels-pentium-4-prescott-processor/
A much longer pipeline — Probably the biggest news of the day is that fact that
Netburst’s main branch prediction/recovery pipeline has been lengthened from a
healthy 20 stages in its previous incarnation to 31 stages in Prescott. To give you
a point of reference, that’s longer than the Alaskan oil pipeline. Pipelines of around
10 stages are much more common. AMD’s Hammer core in the Athlon 64 and
Opteron processors is 12 stages.

Data Forwarding
79

Sample Assembly (P&H)
היצמינא
 for (j=i-1; j>=0 && v[j] > v[j+1]; j-=1) { ...... }
|     | addi  | $s1, $s0, -1 |
| --- | ----- | ------------ |
3 stalls
| for2tst: |       slti  |       $t0, $s1, 0 |
| -------- | ----------- | ----------------- |
3 stalls
|     | bne  | $t0, $zero, exit2          |
| --- | ---- | -------------------------- |
|     | sll  |       $t1, $s1, 2 3 stalls |
תוארוה 9
|     | add  | $t2, $a0, $t1 |
| --- | ---- | ------------- |
3 stalls
|     | lw  | $t3, 0($t2)          |
| --- | --- | -------------------- |
|     | lw  | $t4, 4($t2) 3 stalls |
3 stalls
|     | slt  | $t0, $t4, $t3 |
| --- | ---- | ------------- |
beq$t0, $zero, exit2
.........
|     | addi | $s1, $s1, -1 |
| --- | ---- | ------------ |
|     | j    | for2tst      |
exit2:
85
!stalls -ה תומכ תא תיתועמשמ םצמצל לכונ forwarding םשיינ םא לבא stalls הברהמ לבוס יחכונה דוקה

Sample Assembly, No Forwarding (P&H)
תרוכזת
 for (j=i-1; j>=0 && v[j] > v[j+1]; j-=1) { ...... }
|          | addi              | $s1, $s0, -1      | 3 stalls |
| -------- | ----------------- | ----------------- | -------- |
| for2tst: | slti  $t0, $s1, 0 |                   | 3 stalls |
|          | bne               | $t0, $zero, exit2 |          |
3 stalls
|     | sll $t1, $s1, 2 |     |     |
| --- | --------------- | --- | --- |
3 stalls
|     | add             | $t2, $a0, $t1 |     |
| --- | --------------- | ------------- | --- |
|     | lw  $t3, 0($t2) |               |     |
3 stalls
|     | lw $t4, 4($t2) |     |     |
| --- | -------------- | --- | --- |
3 stalls
|     | slt  $t0, $t4, $t3 |     |     |
| --- | ------------------ | --- | --- |
beq$t0, $zero, exit2
.........
|     | addi      | $s1, $s1, -1 |     |
| --- | --------- | ------------ | --- |
|     | j for2tst |              |     |
exit2:
104

Sample Assembly, Revisited (P&H)
םושיי רחאל
FORWARDING
 for (j=i-1; j>=0 && v[j] > v[j+1]; j-=1) { ...... }
addi $s1, $s0, -1
for2tst: slti $t0, $s1, 0
תרזעב
bne $t0, $zero, exit2
FORWARDING
לכ תא ונמלעה sll $t1, $s1, 2
STALLS-ה
add $t2, $a0, $t1
lw $t3, 0($t2)
lw $t4, 4($t2)
)MIPS( תענמנ יתלב nop תסנכה
nop
slt $t0, $t4, $t3
beq$t0, $zero, exit2
.........
addi $s1, $s1, -1
j for2tst
exit2: 105

תבכעתמ הארוהה םא לשמל .stall סינכהל ךרוצ שי ,איהש הביס לכמ ,בוכיע שי םא
הנושארה הגרדב וליפא stall ונל שי ןורכזהמ עיגהל

Questions to Ponder רהרהל
 What is the role of the hardware vs. the software in data
dependence handling?
 Software based interlocking
 Hardware based interlocking
 Who inserts/manages the pipeline bubbles?
 Who finds the independent instructions to fill “empty”
pipeline slots?
 What are the advantages/disadvantages of each?
107

Questions to Ponder
 What is the role of the hardware vs. the software in the
order in which instructions are executed in the pipeline?
 Software based instruction scheduling  static scheduling
 Hardware based instruction scheduling  dynamic
instruction scheduling
108

More on Software vs. Hardware
 Software based scheduling of instructions  static scheduling
 Compiler orders the instructions, hardware executes them in that
order
 Contrast this with dynamic scheduling (in which hardware can
execute instructions out of the compiler-specified order)
 How does the compiler know the latency of each instruction?
We need to expose the latency of each instruction to the compiler
 What information does the compiler not know that makes static
scheduling difficult?
 Answer: Anything that is determined at run time
 1) Variable-length operation latency, 2) memory addr, 3) branch direction
םינוש םיטלק םע םימעפ הברה ץירהל לוכי רלייפמוקה
4) Cache contents
.תוארוהה תא ןמזתל ךיא תוריבס י"פע חינהלו
 How can the compiler alleviate (לקהל) this (i.e., estimate the unknown)?
 Answer: Profiling
םיאבה םיפקשב םינורחאה םירבדה ינשל סחייתנ
109

רלייפמוקה ידי לע היצזימיטפוא

ךשמה

אבה אשונה
Control Dependence
Handling
113