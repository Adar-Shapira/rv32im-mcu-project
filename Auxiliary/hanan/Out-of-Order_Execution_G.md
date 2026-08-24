361.1.4201
Computer Architecture
Out-of-Order Execution
(Dynamic Instruction Scheduling)
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
With Dr. Guy Tel-Zur & Danny Sidner’s modifications
Last update: 17/6/2021 23/6/2022, 7/6/2023, 17/6/2024, 20/6/2026

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence
Handling, State Maintenance and Recovery, …
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, …
 Alternative Approaches to Instruction Level Parallelism
2

Readings Specifically for Today
 Smith and Sohi, “The Microarchitecture of Superscalar
Processors,” Proceedings of the IEEE, 1995
 More advanced pipelining
 Interrupt and exception handling
 Out-of-order and superscalar execution concepts
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro
1999.
3

Recap of Last Lecture
 Exceptions vs. Interrupts
 Precise Exceptions/Interrupts
 Why Do We Want Precise Exceptions?
 How Do We Ensure Precise Exceptions?
 Reorder buffer
 History buffer
 Future register file (best of both worlds)
 Checkpointing
 Register renaming with a reorder buffer
 How to Handle Exceptions
 How to Handle Branch Mispredictions
 Speed of State Recovery: Recovery and Interrupt Latency
 Checkpointing
 Registers vs. Memory
4

Important: Register Renaming with a Reorder Buffer
 Output and anti dependencies are not true
dependencies
 WHY? The same register refers to values that have nothing
to do with each other
 They exist due to lack of register ID’s (i.e. names) in the
ISA
 The register ID is renamed to the reorder buffer entry
that will hold the register’s value
 Register ID  ROB entry ID
 Architectural register ID  Physical register ID
 After renaming, ROB entry ID used to refer to the register
 This eliminates anti- and output- dependencies
 Gives the illusion that there are a large number of registers
5

Review: Register Renaming Examples
לוקש RAT-ה
tag-ה תדומעל
Future file
RF-ב םדוק ונרציש
pointers
Architectural register file
Architectural register file
Boggs et al., “The Microarchitecture of the Pentium 4
Processor,” Intel Technology Journal, 2001. 6

Review: Checkpointing Idea
 Goal: Restore the frontend state (future file) such that the
correct next instruction after the branch can execute right
away after the branch misprediction is resolved
ידיימב עצבתהל לכות ,תופעתסה לש יוגש יוזיח לש הרקמב האבה ,הארוההש ךכ FF-ה רוזחש
 Idea: Checkpoint the frontend register state/map at the
time a branch is decoded and keep the checkpointed state
updated with results of instructions older than the branch
 Upon branch misprediction, restore the checkpoint
associated with the branch
ןתינ היהיש ידכ תופעתסהה חונעפ ןמזב FF -ה לש )checkpoint( יוביג :הטישה
יוזיחש ררבתמו הדימב יוביגה רוזחש תועצמאב ,הלעמל בתכנש יפכ ,םשל רוזחל
יוגש היה תופעתסהה
 Hwu and Patt, “Checkpoint Repair for Out-of-order
Execution Machines,” ISCA 1987.
7

Review: Checkpointing
 When a branch is decoded
 Make a copy of the future file/map and associate it with the
branch
 When an instruction produces a register value
 All future file/map checkpoints that are younger than the
instruction are updated with the value
 When a branch misprediction is detected
 Restore the checkpointed future file/map for the
mispredicted branch when the branch misprediction is
resolved
 Flush instructions in pipeline younger than the branch
 Deallocate checkpoints younger than the branch
8

Review: In-Order Pipeline with Reorder Buffer
 Decode (D): Access register file/ROB, allocate entry in ROB, check if
instruction can execute, if so dispatch instruction (send to functional
unit)
 Execute (E): Instructions can complete out-of-order
 Completion (R): Write result to reorder buffer
 Retirement/Commit (W): Check for exceptions; if none, write result to
architectural register file or memory; else, flush pipeline and start from
exception handler
 In-order dispatch/execution, out-of-order completion, in-order
Integer add
retirement
E
Integer mul
E E E E
R W
F D FP mul
E E E E E E E E
R
. . .
E E E E E E E E
Load/store
12
ROB is implemented as a circular queue in hardware

Remember:
Static vs. Dynamic
Scheduling
13

Remember: Questions to Ponder
 What is the role of the hardware vs. the software in the
order in which instructions are executed in the pipeline?
 Software based instruction scheduling  static scheduling
 Hardware based instruction scheduling  dynamic
scheduling
 What information does the compiler not know that
makes static scheduling difficult?
 Answer: Anything that is determined at run time
 Variable-length operation latency, memory addr, branch
direction
14

Dynamic Instruction Scheduling
 Hardware has knowledge of dynamic events on a per-
instruction basis (i.e., at a very fine granularity)
 Cache misses
 Branch mispredictions
 Load/store addresses
 Wouldn’t it be nice if hardware did the scheduling of
instructions?
15

Out-of-Order Execution
(Dynamic Instruction
Scheduling)

An In-order Pipeline
Integer add
E
Integer mul
E E E E
R W
F D FP mul
E E E E E E E E
. . .
E E E E E E E E
Cache miss
 Dispatch: Act of sending an instruction to a functional
unit
 Renaming with ROB eliminates stalls due to false
dependences
 Problem: A true data dependency stalls dispatch of
younger instructions into functional (execution) units
Dispatch-ה לש ,stall ,הריצע היהתש םיצור אל ונחנא 
17

Can We Do Better?
 What do the following two pieces of code have in common
(with respect to execution in the previous design)?
IMUL R3  R1, R2 LD R3  R1 (0)
ADD R3  R3, R1 ADD R3  R3, R1
ADD R1  R6, R7 ADD R1  R6, R7
IMUL R5  R6, R8 IMUL R5  R6, R8
ADD R7  R9, R9 ADD R7  R9, R9
 Answer: First ADD stalls the whole pipeline!
 ADD cannot dispatch because its source registers unavailable
 Later independent instructions cannot get executed
 How are the above code portions different?
 Answer: Load latency is variable (unknown until runtime)
 What does this affect? Think compiler vs. microarchitecture
18

Preventing Dispatch Stalls
 Problem: in-order dispatch (scheduling, or execution)
 Solution: out-of-order dispatch (scheduling, or execution)
 Actually, we have seen the basic idea before:
 Dataflow: “fire” an instruction only when its inputs are ready
 We will use similar principles, but not expose it in the ISA
 Aside: Any other way to prevent dispatch stalls?
1. Compile-time instruction scheduling/reordering -תלוכיב לבגומ
2. Value prediction – ירשפא אלו ךבוסמ
3. Fine-grained multi-threading – םימיוסמ םיאנתב בוט דובעל לוכי
19

Out-of-order Execution
(Dynamic Scheduling)
 Idea: Move the dependent instructions out of the way of
independent ones (such that independent ones can
execute)
 Rest areas for dependent instructions: “Reservation stations"
 Monitor the source “values” of each instruction in the
resting area
 When all source “values” of an instruction are available,
“fire” (i.e. dispatch) the instruction
 Instructions dispatched in dataflow (not control-flow) order
הקיגול תפסות תשרדנ
data flow model :תורכזת
 Benefit:
תוהשה תא ונתבוטל םילצנמ :ןורתי
 Latency tolerance: Allows independent instructions to execute
and complete in the presence of a long latency operation
20

In-order vs. Out-of-order Dispatch
 In order dispatch + precise exceptions:
IMUL  R3  R1, R2
| F   | D   | E   | E   | E   | E   | R   | W   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ADD   R3  R3, R1
|     | F   | D   |     | STALL |     | E   | R   | W   |     |     |     |     |     |
| --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
ADD   R1  R6, R7
|     |     | F   |     |       |     | D   | E   | R   | W   |     |     |                   |     |
| --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | ----------------- | --- |
|     |     |     |     | STALL |     |     |     |     |     |     |     | IMUL  R5  R6, R8 |     |
ADD   R7  R3, R5
|     |     |     |     |     |     | F   | D   | E   | E E   | E   | R W |     |                 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --------------- |
|     |     |     |     |     |     |     | F   | D   | STALL |     | E R | W   |  שוריפ לוחכ עבצ |
תויולת יתלב תוארוה
 Out-of-order dispatch + precise exceptions:
| F   | D   |     | E   | E    | E   |     | W    |     |     |     |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | ---- | --- | --- | --- | --- | --- | --- |
|     |     | E   |     |      |     | R   |      |     |     |     |     |     |     |
|     | F   | D   |     | WAIT |     | E   | R    | W   |     |     |     |     |     |
|     |     | F   | D   | E    | R   |     |      |     | W   |     |     |     |     |
|     |     |     | F   | D    | E   | E   | E    | E   | R W |     |     |     |     |
|     |     |     |     | F    | D   |     | WAIT |     | E R | W   |     |     |     |
 15 vs. 12 cycles
21

Enabling OoO Execution
1. Need to link the consumer of a value to the producer :ךרוצה
 Register renaming: Associate a “tag” with each data value
הנעמה
2. Need to buffer instructions until they are ready to execute :ךרוצה
 Insert instruction into reservation stations after renaming
הנעמה
3. Instructions need to keep track of readiness of source values
ךרוצה
 Broadcast the “tag” when the value is produced הנעמה
 Instructions compare their “source tags” to the broadcast tag
 if match, source value becomes ready
4. When all source values of an instruction are ready, need to
dispatch the instruction to its functional unit (FU) :ךרוצה
 Instruction wakes up if all sources are ready הנעמה
 If multiple instructions are awake, need to select one per FU
22

Tomasulo’s Algorithm
 OoO with register renaming invented by Robert Tomasulo
 Used in IBM 360/91 Floating Point Units
 Read: Tomasulo, “An Efficient Algorithm for Exploiting Multiple
Arithmetic Units,” IBM Journal of R&D, Jan. 1967. - אבה ףקשה ואר
הבוח וניאו תושר רמאמה
 What is the major difference today?
 Precise exceptions: IBM 360/91 did NOT have this
 Patt, Hwu, Shebanow, “HPS, a new microarchitecture: rationale and
introduction,” MICRO 1985.
 Patt et al., “Critical issues regarding HPS, a high performance
microarchitecture,” MICRO 1985.
 Variants are used in most high-performance processors
 Initially in Intel Pentium Pro, AMD K5
 Alpha 21264, MIPS R10000, IBM POWER5, IBM z196, Oracle UltraSPARC T4, ARM Cortex A15
23

IBM 360/91

IBM 360/91 in Real World
25
http://www.columbia.edu/cu/computinghistory/36091.html

Robert (Bob) Tomasulo
Robert (Bob) Tomasulo joined IBM research in 1956 after graduating from Manhattan College. After nearly a
decade gaining broad experience in a variety of technical and leadership roles, he transitioned to mainframe
development, including the IBM System/360 Model 91 and its successors. Following his 25 year career with
IBM, Tomasulo worked on an incubator project at Storage Technology Corporation to develop the first CMOS-
based mainframe system; co-founded, a startup to develop one of the earliest microprocessor-based server
systems; and worked as a consultant on processor architecture and for Amdahl Consulting.
On 30 January 2008, Tomasulo spoke at the University of Michigan College of Engineering about his career
and the history and development of out-of-order execution. View the seminar, believed to be his last public
appearance. (source: https://www.computer.org/profiles/robert-tomasulo)
His last public lecture from 2008:
http://leccap.engin.umich.edu/leccap/vi
ewer/r/pvSbKs
https://www.cs.virginia.edu/~evans/
greatworks/tomasulo.pdf

Tomasulo’s Algorithm תודוא תפסונ האירק
H&P CAQA 7th edition, 3.5-3.6

Two Humps in a  Modern Pipeline
TAG and VALUE Broadcast Bus
S
R
Integer add
|     | C   | E   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- |
E
|     | H   |     |     | Integer mul |     |     |
| --- | --- | --- | --- | ----------- | --- | --- |
O
|     | E   | E E | E E |     |     |     |
| --- | --- | --- | --- | --- | --- | --- |
F D
R W
D
FP mul
|     | U   | E E | E E | E E | E E | D   |
| --- | --- | --- | --- | --- | --- | --- |
|     | L   |     |     |     |     | E   |
. . .
|     | E   | E E | E E | E E | E E |     |
| --- | --- | --- | --- | --- | --- | --- |
R
Load/store
| in order |     | out of order |     |     |     | in order |
| -------- | --- | ------------ | --- | --- | --- | -------- |
 Hump 1: Reservation stations (scheduling window)
תויולתה תוארוהה קרש םדוק רמאנש הממ הנושב ,ןאכל תוסנכנ תוארוהה לכ
 Hump 2: Reordering (reorder buffer, aka instruction
window or active window)
28

Two Humps in a Modern Pipeline
TAG and VALUE Broadcast Bus
S
R
C
E
H
|     | S   |     |     |     | O   |     |
| --- | --- | --- | --- | --- | --- | --- |
|     |     |     | E   |     |     | R   |
Integer add
|     | C   | E   |     |     | R   |     |
| --- | --- | --- | --- | --- | --- | --- |
D
E
|     | H   |     |     | Integer mul |     |     |
| --- | --- | --- | --- | ----------- | --- | --- |
D
|     |     |     | U   |     |     | O   |
| --- | --- | --- | --- | --- | --- | --- |
|     |     | E E | E E |     |     |     |
|     | E   |     |     |     | E   |     |
| F D |     |     | L   |     |     | R   |
W
|     | D   |     |     |     | R FP mul |     |
| --- | --- | --- | --- | --- | -------- | --- |
E
D
|     |     | E E | E E | E E | E E |     |
| --- | --- | --- | --- | --- | --- | --- |
U
E
L . . .
R
|     |     | E E | E E | E E | E E |     |
| --- | --- | --- | --- | --- | --- | --- |
E
Load/store
| in order |     | out of order |     |     |     | in order |
| -------- | --- | ------------ | --- | --- | --- | -------- |
 Hump 1: Reservation stations (scheduling window)
 Hump 2: Reordering (reorder buffer, aka instruction
window or active window)
29
Photo credit: http://true-wildlife.blogspot.ch/2010/10/bactrian-camel.html

General Organization of an OOO Processor
החונמה תונחת
reorder -ה תנחת
 Smith and Sohi, “The Microarchitecture of Superscalar Processors,” Proc. IEEE, Dec.
1995.
30

Tomasulo’s Machine: IBM 360/91
)floating point-ב קר קסוע ולוסמוט לש ןונגנמה(
FP registers
from instruction unit
from memory
load
תוארוה
buffers תועיגמ store buffers
decode
operation bus
reservation
stations
to memory
FP FU FP FU
לפכ ’חי לשמל
רוביח ’חי לשמל
Common data bus
FP=Floating Point, FU=Functional Unit, CDB = Common Data Bus :תובית ישאר
31

Recall Once More: Register Renaming
 Output and anti dependences are not true dependences
 WHY? The same register refers to values that have nothing to
do with each other
 They exist due to lack of register ID’s (i.e. names) in ISA
 The register ID is renamed to the reorder buffer entry (or
reservation station entry) that will hold the register’s value
 Register ID  ROB or RS entry ID
 Architectural register ID  Physical register ID
 After renaming, ROB or RS entry ID used to refer to the register
 This eliminates anti and output dependences
 Gives the illusion that there are a large number of registers
 Approximates the performance benefit of having more
registers
32

Tomasulo’s Algorithm
 If reservation station available before renaming התוא אלמ – הנימז הנחתה םא
 Instruction + renamed operands (source value/tag) inserted into the
reservation station
 Only rename if reservation station is available
 Else stall רוצע ,אל םא
 While in reservation station, each instruction: הנחתב הארוה ההוש דוע לכ
 Watches common data bus (CDB) for tag of its sources
 When tag seen, grab value for the source and keep it in the reservation station
 When both operands available, instruction ready to be dispatched
 Dispatch instruction to the Functional Unit when instruction is ready
 After instruction finishes in the Functional Unit
 Put tagged value onto CDB (tag broadcast)
 Register file is connected to the CDB
 Register contains a tag indicating the latest writer to the register
 If the tag in the register file matches the broadcast tag, write broadcast value
into register (and set valid bit)
 Reclaim rename tag
 no valid copy of tag in system!
33

...םומיחל תינושאר המגוד
add $f7, $f2, $f1
Tomasulo Organization
mult $f4, $f7, $f3
sub $f5, $f0, $f4
היצמינא
FP Registers
From Mem FP Op
Queue
Load Buffers
Load1
Load2
Load3
Load4
Load5 Store
Load6
Buffers
Add1
Add2 Mult1
Add3 Mult2
Reservation
To Mem
Stations
FP adders FP multipliers
FP adders FP multipliers
Common Data Bus (CDB)

add $f7,$f2,$f1
Tomasulo Organization
mult $f4,$f7,$f3
sub $f5,$f0,$f4
FP Registers
From Mem FP Op
Queue
Load Buffers
Load1
Load2
Load3
Load4
Load5 Store
Load6
Buffers
Add1 add
$f2 $f1
Add2 Mult1
Add3 Mult2
Reservation
To Mem
Stations
FP adders FP multipliers
FP adders FP multipliers
Common Data Bus (CDB)

add $f7,$f2,$f1
Tomasulo Organization
mult $f4,$f7,$f3
sub $f5,$f0,$f4
FP Registers
From Mem FP Op
Queue
Load Buffers
Load1
Load2
Load3
Load4
Load5 Store
Load6
Buffers
Add1 add
$f2 $f1
Add2 Mult1 mult Add1 $f3
Add3 Mult2
Reservation
To Mem
Stations
FP adders FP multipliers
FP adders FP multipliers
Common Data Bus (CDB)

add $f7,$f2,$f1
Tomasulo Organization
mult $f4,$f7,$f3
sub $f5,$f0,$f4
FP Registers
From Mem FP Op
Queue
Load Buffers
Load1
Load2
Load3
Load4
Load5 Store
Load6
Buffers
Add1 add
$f2 $f1
mult
Add2 sub mult1 Mult1 Add1 $f3
$f0
Add3 Mult2
Reservation
To Mem
Stations
FP adders FP multipliers
FP adders FP multipliers
Common Data Bus (CDB)

היצמינא
Reservation Station Components
Op: Operation to perform in the unit (e.g., add or sub)
Vj, Vk: Value of Source operands
– Store buffers has one V field, =result to be stored
Qj, Qk: Specifies the Reservation Stations that supposed
to produce the source registers (= the values to be
written into Vj,Vk)
– Note: Qj,Qk=0 means ready (Values in Vj,Vk are valid)
– Store buffers only have Qi, Vi for RS producing result
Busy: Indicates reservation station or FU is busy
Register Status - Qi: Indicates which Reservation station
is supposed to write to the register.
Regs[i]: the Value of the register. The value is correct
when Qi=0 means that there are no pending instructions
that will write to that register.

היצמינא
Three Stages of Tomasulo Algorithm
1. Issue—get instruction from FP Op Queue
If reservation station free (no structural hazard),
control issues instruction & sends operands (=renames the registers).
2. Execute—operate on operands (EX)
When both operands ready then execute;
if not ready, watch Common Data Bus for result
3. Write result—finish execution (WB)
Write on Common Data Bus to all awaiting units;
mark reservation station available
• Normal data bus: data + destination (“go to” bus)
• Common data bus: data + source (“come from” bus)
– 64 bits of data + 4 bits of Functional Unit source address
– Write if matches expected Functional Unit (produces result)
– Does the broadcast
• The units speed in the following example is:
3 clocks for FP add/sub; 10 for mult; 40 clks for divide

Details of Tomasulo Algorithm

Details of Tomasulo Algorithm
FIGURE 3.5 Steps in the algorithm and what is required for each step. For the issuing
instruction, rd is the destination,rs and rt are the source register numbers, imm is the sign-
extended immediate field, and r is the reservation station or buffer that the instruction is
assigned to. RS is the reservation-station data structure. The value returned by a FP unit or by
the load unit is called result. RegisterStat is the register status data structure (not the register
file, which is Regs[ ] ). When an instruction is issued, the destination register has its Qi field
set to the number of the buffer or reservation station to which the instruction is issued. If the
operands are available in the registers, they are stored in the V fields. Otherwise,the Q fields
are set to indicate the reservation station that will produce the values needed as source
operands. The instruction waits at the reservation station until both its operands are available,
indicated by zero in the Q fields. The Q fields are set to zero either when this instruction is
issued, or when an instruction on which this instruction depends completes and does its write
back. When an instruction has finished execution and the CDB is available, it can do its write
back. All the buffers, registers, and reservation stations whose value of Qj or Qk is the same
as the completing reservation station update their values from the CDB and mark the Q fields
to indicate that values have been received. Thus, the CDB can broadcast its result to many
destinations in a single clock cycle, and if the waiting instructions have their operands, they
can all begin execution on the next clock cycle. Loads go through two steps in Execute, and
stores perform slightly differently during Write Result, where they may have to wait for the
value to store. Remember that to preserve exception behavior, instructions should not be
allowed to execute if a branch that is earlier in program order has not yet completed. Because
any concept of program order is not maintained after the Issue stage, this restriction is usually
implemented by preventing any instruction from leaving the Issue step, if there is a pending
branch already in the pipeline. Later, we will see how speculation support removes this
.restriction

תלועפ ןפואל הנושאר המגוד התע איבנ
:ולוסמוט לש םתירוגלאה
Tomasulo’s algorithm
Example #1
42

| Instruction stream         |             |     |     |     |                  | היצמינא |        |     |       |      | The “system”:     |     |
| -------------------------- | ----------- | --- | --- | --- | ---------------- | ------- | ------ | --- | ----- | ---- | ----------------- | --- |
| Shown for ease –           |             |     |     |     | Tomasulo Example |         |        |     |       |      | Everything below  |     |
| (not a part of the system) |             |     |     |     |                  |         |        |     |       |      | the black line    |     |
| Instruction status:        |             |     |     |     |                  | Exec    | Write  |     |       |      |                   |     |
|                            |             |     |     |     | Issue            | Comp    | Result |     |       | Busy | Address           |     |
|                            | Instruction |     | j   | k   |                  |         |        |     |       |      |                   |     |
|                            | LD          | F6  | 34+ | R2  |                  |         |        |     | Load1 | No   |                   |     |
|                            | LD          | F2  | 45+ | R3  |                  |         |        |     | Load2 | No   |                   |     |
|                            | MULTD       | F0  | F2  | F4  |                  |         |        |     | Load3 | No   |                   |     |
|                            | SUBD        | F8  | F6  | F2  |                  |         |        |     |       |      |                   |     |
|                            | DIVD        | F10 | F0  | F6  |                  |         |        |     |       |      |                   |     |
3 Load/Buffers
|     | ADDD | F6  | F8  | F2  |     |     |     |     |     |     |     |     |
| --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Reservation Stations:
|     |          |      |      |      |     | S1  | S2  | RS  | RS  |     |     |     |
| --- | -------- | ---- | ---- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |          | Time | Name | Busy | Op  | Vj  | Vk  | Qj  | Qk  |     |     |     |
|     |          |      | Add1 | No   |     |     |     |     |     |     |     |     |
|     | FU count |      | Add2 | No   |     |     |     |     |     |     |     |     |
3 FP Adder R.S.
|     |     |     | Add3 | No  |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
down
2 FP Mult R.S.
|     |     |     | Mult1 | No  |     |     |     |     |     |     |     |     |
| --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | Mult2 | No  |     |     |     |     |     |     |     |     |
Register result status:
|     | Clock |     |     |     | F0  | F2  | F4  | F6  | F8  | F10 | F12 | ... F30 |
| --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- |
|     | 0     |     |     | FU  |     |     |     |     |     |     |     |         |
Clock cycle
counter

Tomasulo Example Cycle 1
issue LD1
| Instruction status: |     |        |     |       | Exec | Write  |     |       |      |         |     |
| ------------------- | --- | ------ | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- |
|                     |     |        |     | Issue | Comp | Result |     |       | Busy | Address |     |
| Instruction         |     | j      | k   |       |      |        |     |       |      |         |     |
| LD                  |     | F6 34+ | R2  | 1     |      |        |     | Load1 | Yes  | 34+R2 , |     |
| LD                  |     | F2 45+ | R3  |       |      |        |     | Load2 | No   |         |     |
| MULTD               |     | F0 F2  | F4  |       |      |        |     | Load3 | No   |         |     |
| SUBD                |     | F8 F6  | F2  |       |      |        |     |       |      |         |     |
| DIVD                |     | F10 F0 | F6  |       |      |        |     |       |      |         |     |
| ADDD                |     | F6 F8  | F2  |       |      |        |     |       |      |         |     |
Reservation Stations:
|     |     |           |      |     | S1  | S2  | RS  | RS  |     |     |     |
| --- | --- | --------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time Name | Busy | Op  | Vj  | Vk  | Qj  | Qk  |     |     |     |
Add1 No
Add2 No
Add3 No
Mult1 No
Mult2 No
Register result status:
| Clock |     |     |     | F0  | F2  | F4  | F6    | F8  | F10 | F12 | ... F30 |
| ----- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | ------- |
|       | 1   |     | FU  |     |     |     | Load1 |     |     |     |         |

Tomasulo Example Cycle 2
היצמינא
issue LD2 (+calc adr of LD1)
| Instruction status: |     |        |     |       | Exec | Write  |     |       |      |         |     |
| ------------------- | --- | ------ | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- |
|                     |     |        |     | Issue | Comp | Result |     |       | Busy | Address |     |
| Instruction         |     | j      | k   |       |      |        |     |       |      |         |     |
| LD                  |     | F6 34+ | R2  | 1     |      |        |     | Load1 | Yes  | 34+R2   |     |
45+,
| LD    |     | F2 45+ | R3  | 2   |     |     |     | Load2 | Yes | R3  |     |
| ----- | --- | ------ | --- | --- | --- | --- | --- | ----- | --- | --- | --- |
| MULTD |     | F0 F2  | F4  |     |     |     |     | Load3 | No  |     |     |
| SUBD  |     | F8 F6  | F2  |     |     |     |     |       |     |     |     |
| DIVD  |     | F10 F0 | F6  |     |     |     |     |       |     |     |     |
| ADDD  |     | F6 F8  | F2  |     |     |     |     |       |     |     |     |
Reservation Stations:
|     |     |           |      |     | S1  | S2  | RS  | RS  |     |     |     |
| --- | --- | --------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time Name | Busy | Op  | Vj  | Vk  | Qj  | Qk  |     |     |     |
Add1 No
Add2 No
Add3 No
Mult1 No
Mult2 No
Register result status:
| Clock |     |     |     | F0  | F2    | F4  | F6    | F8  | F10 | F12 | ... F30 |
| ----- | --- | --- | --- | --- | ----- | --- | ----- | --- | --- | --- | ------- |
|       | 2   |     | FU  |     | Load2 |     | Load1 |     |     |     |         |
Note: Can have multiple loads outstanding

Tomasulo Example Cycle 2
issue LD2 (+calc adr of LD1)
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |       |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | ----- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |       |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |       |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     |      |        |     | Load1 | Yes  |         | 34+R2 |     |     |
45+,
| LD                    |     | F2  | 45+ | R3  | 2   |     |     |     | Load2 | Yes |                      | R3  |     |     |
| --------------------- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | -------------------- | --- | --- | --- |
| MULTD                 |     | F0  | F2  | F4  |     |     |     |     | Load3 | No  |                      |     |     |     |
| SUBD                  |     | F8  | F6  | F2  |     |     |     |     |       |     |                      |     |     |     |
| DIVD                  |     | F10 | F0  | F6  |     |     |     |     |       |     |                      |     |     |     |
| ADDD                  |     | F6  | F8  | F2  |     |     |     |     |       |     | We see that for      |     |     |     |
| Reservation Stations: |     |     |     |     |     |     |     |     |       |     | the next instr., F4  |     |     |     |
|                       |     |     |     |     |     | S1  | S2  | RS  | RS    |     |                      |     |     |     |
is ready (Q=0),
|     |     | Time | Name | Busy | Op  | Vj  | Vk  | Qj  | Qk  |     |                    |     |     |     |
| --- | --- | ---- | ---- | ---- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- | --- |
|     |     |      | Add1 | No   |     |     |     |     |     |     | but F2 is waiting  |     |     |     |
|     |     |      | Add2 | No   |     |     |     |     |     |     |                    |     |     |     |
for the Load unit
|     |     |     | Add3 | No  |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
(Q=Load2)
|     |     |     | Mult1 | No  |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | Mult2 | No  |     |     |     |     |     |     |     |     |     |     |
Register result status:
| Clock |     |     |     |     | F0  | F2    | F4  | F6    | F8  | F10 |     | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | --- | ----- | --- | ----- | --- | --- | --- | --- | --- | --- |
|       | 2   |     |     | FU  | 0   | Load2 | 0   | Load1 | 0   |     | 0   | 0   |     | 0   |

Tomasulo Example Cycle 3
היצמינא
issue Mult, complete LD1 (Memory rd)
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    |        |     | Load1 | Yes  | 34+R2   |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     |      |        |     | Load2 | Yes  | 45+R3   |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  |       |      |        |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  |       |      |        |     |       |      |         |     |     |
 If now someone
| ADDD |     | F6  | F8  | F2  |     |     |     |     |     |     | So we have  Qk=0,  |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- |
writes into F4, we still
| Reservation Stations: |     |     |     |     |     | S1  | S2  | RS  | RS  |     | and Vk=F4,  while  |     |     |
| --------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------------------ | --- | --- |
have its value in the
|     |     |      |      | Busy | Op  | Vj  | Vk  | Qj  | Qk  |     | Qj=Load2, i.e.,  |     |     |
| --- | --- | ---- | ---- | ---- | --- | --- | --- | --- | --- | --- | ---------------- | --- | --- |
|     |     | Time | Name |      |     |     |     |     |     |     |                  |     |     |
Mult1 Vk register =>
|     |     |     | Add1 | No  |     |     |     |     |     |     | Mult1 waits for  |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | ---------------- | --- | --- |
no WAR hazard can
|     |     |     | Add2 | No  |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Load2
|     |     |     | Add3  | No  |       |     |       |       |     | occur ! |     |     |     |
| --- | --- | --- | ----- | --- | ----- | --- | ----- | ----- | --- | ------- | --- | --- | --- |
|     |     |     | Mult1 | Yes | MULTD | ?   | R(F4) | Load2 | 0   |         |     |     |     |
(not in final Reg F4 or
|     |     |     | Mult2 | No  |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
in Vk of Mult1)
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6    | F8  | F10 | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ----- | --- | --- | --- | --- | --- |
|       | 3   |     |     | FU  | Mult1 | Load2 | 0   | Load1 | 0   | 0   | 0   |     | 0   |
• Note: registers names are removed (“renamed”) in
Reservation Stations; MULT issued
• Load1 completing; what waits for Load1?
F6 +Sub

Tomasulo Example Cycle 4
היצמינא
Issu Sub, Complete Ld2, WB LD1
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    |        |     | Load2 | Yes  | 45+R3   |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     |      |        |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  |       |      |        |     |       |      |         |     |     |
Writing from the
| ADDD |     | F6  | F8  | F2  |     |     |     |     |     |     |     |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
CDB to F6 and
| Reservation Stations: |     |      |      |      |      |       |     |     |       |     | Add1 means        |     |     |
| --------------------- | --- | ---- | ---- | ---- | ---- | ----- | --- | --- | ----- | --- | ----------------- | --- | --- |
|                       |     |      |      |      |      | S1    | S2  | RS  | RS    |     |                   |     |     |
|                       |     | Time | Name | Busy | Op   | Vj    | Vk  | Qj  | Qk    |     | Write Back to F6  |     |     |
|                       |     |      | Add1 | Yes  | SUBD | M(A1) | ?   | 0   | Load2 |     |                   |     |     |
and Forwarding
|     |     |     | Add2 | No  |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
to the FP Add
|     |     |     | Add3 | No  |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
unit
|     |     |     | Mult1 | Yes | MULTD | ?   | R(F4) | Load2 | 0   |     |     |     |     |
| --- | --- | --- | ----- | --- | ----- | --- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     |     | Mult2 | No  |       |     |       |       |     |     |     |     |     |
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6    | F8   | F10 | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ----- | ---- | --- | --- | --- | --- |
|       | 4   |     |     | FU  | Mult1 | Load2 | 0   | M(A1) | Add1 | 0   | 0   |     | 0   |
•
Load2 completing; what is waiting for Load2?
F2 + Mult1+Add1

Tomasulo Example Cycle 5
היצמינא
Issu Div, start Execute Sub & Mult, WB LD2
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     |      |        |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  |       |      |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |        |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------ | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name   | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | 2 Add1 | Yes  | SUBD       | M(A1) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add2   | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | Add3   | No   |            |       |       |       |     |     |     |     |     |
|     |     | 10   | Mult1  | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2  | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6    | F8   | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ----- | ---- | ----- | --- | --- | --- |
|       | 5   |     |     | FU  | Mult1 | M(A2) | 0   | M(A1) | Add1 | Mult2 | 0   |     | 0   |
|       |     |     |     |     |       |       | 0   | 0     |      |       |     |     |     |
•
Timer starts down for Add1, Mult1

Tomasulo Example Cycle 6
היצמינא
Issu Add, cont. Execute Sub & Mult
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     |      |        |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  | 6     |      |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | 1 Add1  | Yes  | SUBD       | M(A1) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add2    | Yes  | ADDD       |       | M(A2) | Add1  | 0   |     |     |     |     |
|     |     |      | Add3    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 9 Mult1 | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6   | F8   | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ---- | ---- | ----- | --- | --- | --- |
|       | 6   |     |     | FU  | Mult1 | M(A2) | 0   | Add2 | Add1 | Mult2 | 0   |     | 0   |
0
•
Issue ADDD here despite name dependency on F6?
   No problem! Since o ld value of F6 as already in Vk of Mult2

Tomasulo Example Cycle 7
היצמינא
Complete Sub, cont. Execute the Mult
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     | 7    |        |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  | 6     |      |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | 0 Add1  | Yes  | SUBD       | M(A1) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add2    | Yes  | ADDD       |       | M(A2) | Add1  | 0   |     |     |     |     |
|     |     |      | Add3    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 8 Mult1 | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6   | F8   | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ---- | ---- | ----- | --- | --- | --- |
|       | 7   |     |     | FU  | Mult1 | M(A2) | 0   | Add2 | Add1 | Mult2 | 0   |     | 0   |
0
•
Add1 (SUBD) completing; what is waiting for it?

Tomasulo Example Cycle 8
WB the Sub, cont. the Mult, start the Add
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     | 7    | 8      |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  | 6     |      |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | Add1    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 2 Add2  | Yes  | ADDD       | (M-M) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add3    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 7 Mult1 | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6   | F8    | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ---- | ----- | ----- | --- | --- | --- |
|       | 8   |     |     | FU  | Mult1 | M(A2) | 0   | Add2 | (M-M) | Mult2 | 0   |     | 0   |
|       |     |     |     |     |       |       | 0   |      |       | 0     |     |     |     |

Tomasulo Example Cycle 9
cont. the Mult & the Add
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     | 7    | 8      |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  | 6     |      |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | Add1    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 1 Add2  | Yes  | ADDD       | (M-M) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add3    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 6 Mult1 | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6   | F8    | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ---- | ----- | ----- | --- | --- | --- |
|       | 9   |     |     | FU  | Mult1 | M(A2) | 0   | Add2 | (M-M) | Mult2 | 0   |     | 0   |
|       |     |     |     |     |       |       | 0   |      |       | 0     |     |     |     |

Tomasulo Example Cycle 10
היצמינא
cont. the Mult, complete the Add
| Instruction status: |     |     |     |     |       | Exec | Write  |     |       |      |         |     |     |
| ------------------- | --- | --- | --- | --- | ----- | ---- | ------ | --- | ----- | ---- | ------- | --- | --- |
|                     |     |     |     |     | Issue | Comp | Result |     |       | Busy | Address |     |     |
| Instruction         |     |     | j   | k   |       |      |        |     |       |      |         |     |     |
| LD                  |     | F6  | 34+ | R2  | 1     | 3    | 4      |     | Load1 | No   |         |     |     |
| LD                  |     | F2  | 45+ | R3  | 2     | 4    | 5      |     | Load2 | No   |         |     |     |
| MULTD               |     | F0  | F2  | F4  | 3     |      |        |     | Load3 | No   |         |     |     |
| SUBD                |     | F8  | F6  | F2  | 4     | 7    | 8      |     |       |      |         |     |     |
| DIVD                |     | F10 | F0  | F6  | 5     |      |        |     |       |      |         |     |     |
| ADDD                |     | F6  | F8  | F2  | 6     | 10   |        |     |       |      |         |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1    | S2    | RS    | RS  |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | ----- | ----- | ----- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj    | Vk    | Qj    | Qk  |     |     |     |     |
|     |     |      | Add1    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 0 Add2  | Yes  | ADDD       | (M-M) | M(A2) | 0     | 0   |     |     |     |     |
|     |     |      | Add3    | No   |            |       |       |       |     |     |     |     |     |
|     |     |      | 5 Mult1 | Yes  | MULTDM(A2) |       | R(F4) | 0     | 0   |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |       | M(A1) | Mult1 |     |     |     |     |     |
0
Register result status:
| Clock |     |     |     |     | F0    | F2    | F4  | F6   | F8    | F10   | F12 | ... | F30 |
| ----- | --- | --- | --- | --- | ----- | ----- | --- | ---- | ----- | ----- | --- | --- | --- |
|       | 10  |     |     | FU  | Mult1 | M(A2) | 0   | Add2 | (M-M) | Mult2 | 0   |     | 0   |
|       |     |     |     |     |       |       | 0   |      |       | 0     |     |     |     |
•
Add2 (ADDD) completing; what is waiting for it?

Tomasulo Example Cycle 11
היצמינא
cont. the Mult,  WB the Add
| Instruction status: |             |     |        |     |       | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  | 1     |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  | 2     |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  | 3     |      |     |        |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  | 4     |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  | 5     |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  | 6     |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1  |     | S2    | RS    | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj  |     | Vk    | Qj    | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | 4 Mult1 | Yes  | MULTDM(A2) |     |     | R(F4) | 0     |     | 0   |     |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |     |     | M(A1) | Mult1 |     |     |     |     |     |     |     |
0
Register result status:
|     | Clock |     |     |     | F0    | F2    |     | F4  | F6           | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ----- | ----- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- |
|     | 11    |     |     | FU  | Mult1 | M(A2) |     | 0   | (M-M+M()M-M) |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |       |       | 0   |     | 0            |     | 0   |       |     |     |     |     |
• Write result of ADDD here?
• All quick instructions complete in this cycle!
(=OOO completion)

Tomasulo Example Cycle 12
cont. the Mult (Div still waiting)
| Instruction status: |             |     |        |     |       | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  | 1     |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  | 2     |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  | 3     |      |     |        |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  | 4     |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  | 5     |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  | 6     |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1  |     | S2    | RS    | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj  |     | Vk    | Qj    | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | 3 Mult1 | Yes  | MULTDM(A2) |     |     | R(F4) | 0     |     | 0   |     |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |     |     | M(A1) | Mult1 |     |     |     |     |     |     |     |
0
Register result status:
|     | Clock |     |     |     | F0    | F2    |     | F4  | F6           | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ----- | ----- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- |
|     | 12    |     |     | FU  | Mult1 | M(A2) |     | 0   | (M-M+M()M-M) |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |       |       | 0   |     | 0            |     | 0   |       |     |     |     |     |

Tomasulo Example Cycle 13
cont. the Mult
| Instruction status: |             |     |        |     |       | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  | 1     |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  | 2     |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  | 3     |      |     |        |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  | 4     |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  | 5     |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  | 6     |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1  |     | S2    | RS    | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj  |     | Vk    | Qj    | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | 2 Mult1 | Yes  | MULTDM(A2) |     |     | R(F4) | 0     |     | 0   |     |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |     |     | M(A1) | Mult1 |     |     |     |     |     |     |     |
0
Register result status:
|     | Clock |     |     |     | F0    | F2    |     | F4  | F6           | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ----- | ----- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- |
|     | 13    |     |     | FU  | Mult1 | M(A2) |     | 0   | (M-M+M()M-M) |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |       |       | 0   |     | 0            |     | 0   |       |     |     |     |     |

Tomasulo Example Cycle 14
cont. the Mult
| Instruction status: |             |     |        |     |       | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  | 1     |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  | 2     |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  | 3     |      |     |        |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  | 4     |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  | 5     |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  | 6     |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1  |     | S2    | RS    | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj  |     | Vk    | Qj    | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | 1 Mult1 | Yes  | MULTDM(A2) |     |     | R(F4) | 0     |     | 0   |     |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |     |     | M(A1) | Mult1 |     |     |     |     |     |     |     |
0
Register result status:
|     | Clock |     |     |     | F0    | F2    |     | F4  | F6           | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ----- | ----- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- |
|     | 14    |     |     | FU  | Mult1 | M(A2) |     | 0   | (M-M+M()M-M) |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |       |       | 0   |     | 0            |     | 0   |       |     |     |     |     |

Tomasulo Example Cycle 15
היצמינא
complete the Mult
| Instruction status: |             |     |        |     |       | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  | 1     |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  | 2     |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  | 3     |      | 15  |        |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  | 4     |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  | 5     |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  | 6     |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |            | S1  |     | S2    | RS    | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op         | Vj  |     | Vk    | Qj    | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |            |     |     |       |       |     |     |     |     |     |     |     |
|     |     |      | 0 Mult1 | Yes  | MULTDM(A2) |     |     | R(F4) | 0     |     | 0   |     |     |     |     |     |
|     |     |      | Mult2   | Yes  | DIVD       |     |     | M(A1) | Mult1 |     |     |     |     |     |     |     |
0
Register result status:
|     | Clock |     |     |     | F0    | F2    |     | F4  | F6           | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ----- | ----- | --- | --- | ------------ | --- | --- | ----- | --- | --- | --- | --- |
|     | 15    |     |     | FU  | Mult1 | M(A2) |     | 0   | (M-M+M()M-M) |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |       |       | 0   |     | 0            |     | 0   |       |     |     |     |     |
•
Mult1 (MULTD) completing; what is waiting for it?
F0 + Mult1

Tomasulo Example Cycle 16
היצמינא
WB the Mult & start the Div
| Instruction status: |             |        |     |       |     | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | ------ | --- | ----- | --- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |        |     | Issue |     | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction | j      | k   |       |     |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          | F6 34+ | R2  |       | 1   |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          | F2 45+ | R3  |       | 2   |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       | F0 F2  | F4  |       | 3   |      | 15  | 16     |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        | F8 F6  | F2  |       | 4   |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 F0 | F6  |       | 5   |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        | F6 F8  | F2  |       | 6   |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |           |      |     |     | S1  |     | S2  | RS  | RS  |     |     |     |     |     |     |
| --- | --- | --------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time Name | Busy | Op  |     | Vj  |     | Vk  | Qj  | Qk  |     |     |     |     |     |     |
Add1 No
Add2 No
Add3 No
Mult1 No
|     |     | 40 Mult2 | Yes | DIVD |     | M*F4 |     | M(A1) |     |     |     |     |     |     |     |     |
| --- | --- | -------- | --- | ---- | --- | ---- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |          |     |      |     |      |     |       | 0   |     | 0   |     |     |     |     |     |
Register result status:
|     | Clock |     |     | F0   |     | F2    |     | F4             | F6  | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | ---- | --- | ----- | --- | -------------- | --- | --- | --- | ----- | --- | --- | --- | --- |
|     | 16    |     | FU  | M*F4 |     | M(A2) |     | 0 (M-M+M()M-M) |     |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |      | 0   |       | 0   |                | 0   |     | 0   |       |     |     |     |     |
•
Just waiting for Mult2 (DIVD) to complete

Tomasulo Example Cycle 55
cont. the Div
| Instruction status: |             |     |        |     |       |     | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | --- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue |     | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |     |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  |       | 1   |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  |       | 2   |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  |       | 3   |      | 15  | 16     |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  |       | 4   |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  |       | 5   |      |     |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  |       | 6   |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |      |     | S1   |     | S2    | RS  | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---- | --- | ---- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op   |     | Vj   |     | Vk    | Qj  | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Mult1   | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | 1 Mult2 | Yes  | DIVD |     | M*F4 |     | M(A1) |     |     |     |     |     |     |     |     |
|     |     |      |         |      |      |     |      |     |       | 0   |     | 0   |     |     |     |     |     |
Register result status:
|     | Clock |     |     |     | F0   |     | F2    |     | F4             | F6  | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ---- | --- | ----- | --- | -------------- | --- | --- | --- | ----- | --- | --- | --- | --- |
|     | 55    |     |     | FU  | M*F4 |     | M(A2) |     | 0 (M-M+M()M-M) |     |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |      | 0   |       | 0   |                | 0   |     | 0   |       |     |     |     |     |

Tomasulo Example Cycle 56
היצמינא
complete the Div
| Instruction status: |             |     |        |     |       |     | Exec |     | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | ------ | --- | ----- | --- | ---- | --- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |        |     | Issue |     | Comp |     | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j      | k   |       |     |      |     |        |     |       |     |      |         |     |     |     |
|                     | LD          |     | F6 34+ | R2  |       | 1   |      | 3   | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          |     | F2 45+ | R3  |       | 2   |      | 4   | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       |     | F0 F2  | F4  |       | 3   |      | 15  | 16     |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        |     | F8 F6  | F2  |       | 4   |      | 7   | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0     | F6  |       | 5   |      | 56  |        |     |       |     |      |         |     |     |     |
|                     | ADDD        |     | F6 F8  | F2  |       | 6   |      | 10  | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |         |      |      |     | S1   |     | S2    | RS  | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ------- | ---- | ---- | --- | ---- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name    | Busy | Op   |     | Vj   |     | Vk    | Qj  | Qk  |     |     |     |     |     |     |
|     |     |      | Add1    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Add2    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Add3    | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | Mult1   | No   |      |     |      |     |       |     |     |     |     |     |     |     |     |
|     |     |      | 0 Mult2 | Yes  | DIVD |     | M*F4 |     | M(A1) |     |     |     |     |     |     |     |     |
|     |     |      |         |      |      |     |      |     |       | 0   |     | 0   |     |     |     |     |     |
Register result status:
|     | Clock |     |     |     | F0   |     | F2    |     | F4             | F6  | F8  |     | F10   |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ---- | --- | ----- | --- | -------------- | --- | --- | --- | ----- | --- | --- | --- | --- |
|     | 56    |     |     | FU  | M*F4 |     | M(A2) |     | 0 (M-M+M()M-M) |     |     |     | Mult2 |     | 0   |     | 0   |
|     |       |     |     |     |      | 0   |       | 0   |                | 0   |     | 0   |       |     |     |     |     |
•
Mult2 (DIVD) is completing; what is waiting for it?

Tomasulo Example Cycle 57
היצמינא
WB the Div
| Instruction status: |             |     |     |     |       |     | Exec | Write  |     |       |     |      |         |     |     |     |
| ------------------- | ----------- | --- | --- | --- | ----- | --- | ---- | ------ | --- | ----- | --- | ---- | ------- | --- | --- | --- |
|                     |             |     |     |     | Issue |     | Comp | Result |     |       |     | Busy | Address |     |     |     |
|                     | Instruction |     | j   | k   |       |     |      |        |     |       |     |      |         |     |     |     |
|                     | LD          | F6  | 34+ | R2  |       | 1   | 3    | 4      |     | Load1 |     | No   |         |     |     |     |
|                     | LD          | F2  | 45+ | R3  |       | 2   | 4    | 5      |     | Load2 |     | No   |         |     |     |     |
|                     | MULTD       | F0  | F2  | F4  |       | 3   | 15   | 16     |     | Load3 |     | No   |         |     |     |     |
|                     | SUBD        | F8  | F6  | F2  |       | 4   | 7    | 8      |     |       |     |      |         |     |     |     |
|                     | DIVD        | F10 | F0  | F6  |       | 5   | 56   | 57     |     |       |     |      |         |     |     |     |
|                     | ADDD        | F6  | F8  | F2  |       | 6   | 10   | 11     |     |       |     |      |         |     |     |     |
Reservation Stations:
|     |     |      |       |      |      |     | S1   | S2    | RS  | RS  |     |     |     |     |     |     |
| --- | --- | ---- | ----- | ---- | ---- | --- | ---- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | Time | Name  | Busy | Op   |     | Vj   | Vk    | Qj  | Qk  |     |     |     |     |     |     |
|     |     |      | Add1  | No   |      |     |      |       |     |     |     |     |     |     |     |     |
|     |     |      | Add2  | No   |      |     |      |       |     |     |     |     |     |     |     |     |
|     |     |      | Add3  | No   |      |     |      |       |     |     |     |     |     |     |     |     |
|     |     |      | Mult1 | No   |      |     |      |       |     |     |     |     |     |     |     |     |
|     |     |      | Mult2 | Yes  | DIVD |     | M*F4 | M(A1) |     |     |     |     |     |     |     |     |
|     |     |      |       |      |      |     |      |       | 0   |     | 0   |     |     |     |     |     |
Register result status:
|     | Clock |     |     |     | F0   |     | F2    | F4             | F6  | F8  |     | F10    |     | F12 | ... | F30 |
| --- | ----- | --- | --- | --- | ---- | --- | ----- | -------------- | --- | --- | --- | ------ | --- | --- | --- | --- |
|     | 56    |     |     | FU  | M*F4 |     | M(A2) | 0 (M-M+M()M-M) |     |     |     | Result |     | 0   |     | 0   |
|     |       |     |     |     |      | 0   |       | 0              | 0   |     | 0   |        |     |     |     |     |
•
Once again: In-order issue, out-of-order execution and
out-of-order completion.

RAW hazard prevention
• RAW is prevented by setting the Qj & Qk of each
Reservation Station (FU) to the value of the unit
supposed to write into these registers when
issuing instruction Ij to Reservation Station r.
• That way, the r Reservation Station, will always
wait for the results of the 2 units calculating Vj
and Vk
• I.e., we always start calculation when Vj & Vk are
ready => No RAW hazards

WAR hazard prevention
• Since when a result of any unit is ready, we copy it
into the appropriate Reservation Station registers,
(and to the Register file) we actually “renamed’’ the
registers. ( )
use other registers instead of the orig ones
• The data in these “renamed” registers stays there,
even if someone writes to the Register File. => No
WAR hazards
• No one writes into the Reservation Station registers
Vj and Vk while it is still busy
• So, once a calculated result is ready, it is
immediately read and renamed and any subsequent
write to the register file, has no influence on the
execution of that instruction
• The renaming during the issue stage ensures that an
issued instruction is always performed OK

WAW hazard prevention
• WAW happens only when we do not use the result of
the first write. If we use it, there is a WAR
• In the Issue stage we set RegisterStat[Rd].Qi=r
• Issue is “in order”. This means that the last
instruction that is supposed to write to that
register, Ij, determines its Qi field
• Therefore, when that instruction finishes, it will
update the register. (and will set Qi to 0)
• If that Qi field had a different r value, coming from
an earlier instruction, Ik, it is overwritten when Ij is
issued, so even if that early instruction completes
operation later than the Ij instruction, Qi is already
0, and no WAW occurs, since the Register File is not
updated

WAW hazard prevention (cont.)
• Furthermore, the Register File value is available
for future (later) instructions
• WAW and WAR: Say that an instruction, Ip, that is
between Ik and Ij needs the result of Ik. When
that instruction is issued, the Qi field still holds
the FU specified by Ik, so that instruction waits
for “the result of Ik”, and the later issued
instruction Ij has no influence. (This is actually a
WAR hazard prevention for the instruction Ip)
• As mentioned before,the renaming during the
issue stage makes sure that an instruction is
always performed correctly – eliminating the
WAR

Tomasulo’s scheme
• Performs an instruction as early as possible using multiple FUs (having many
input regs pairs)
• Prevents RAW hazards by waiting for the input registers to be ready before
starting execution in a FU
• Prevents WAR hazards by copying registers (or FU’s results) into the FUs input
registers = Renaming
• During issue the appropriate reg in the Register file is flagged to wait for the
appropriate FU result. Since Issue of instructions is in order, the last instruction
determines which FU writes to the Reg File – Thus, no WAW can ever occur
תודיחיה יבג-לע ןתינש םדקומ יכה תוארוה עצבמ ולוסמוט לש םתירוגלאה
.תוילנויצקנופה
ליחתמ זאו םינכומ ויהיש דע םיטלקל הנתמה ידי-לע RAW תנכס ענומ םתירוגלאה -
.FU-ב עוציבב
יוניש( FU -ל טלקכ םירטסיגרה לש ןכות תריצי ידי-לע WAR תולת םג ענומ םתרוגלאה -
.)םש
WAW גוסמ תולת םג ןיא ןכלו עבוקה אוה רטסיגרה לש ןורחאה ךרעה-

Tomasulo Drawbacks
• Complexity
– delays of 360/91, MIPS 10000, Alpha 21264
• Many associative stores (CDB) at high speed
• Performance limited by Common Data Bus
– Each CDB must go to multiple functional units
high capacitance, high wiring density
– Number of functional units that can complete per cycle limited to one!
» Multiple CDBs  more FU logic for parallel assoc stores
• Non-precise interrupts!
– We will address this later

About Loads and Stores
• Say we Load from a memory location and then
Store to the same memory location.The order
must be kept to prevent WAR hazard
• Say we Store to a memory location and then Load
from the same memory location. The order must
be kept in order to prevent RAW hazard
• In a similar manner, WAW hazards should be
prevented.
• In order to do this, we must compare the
effective memory address (i.e., after the address
calculation)
• A simple way to ensure correctness is to
calculate all the effective addresses “in-order”
( )
order of Loads before Store doesn’t matter

End of Example #1
on Tomasulo’s algorithm
71

Tomasulo’s Algorithm: Renaming
 Register rename table (register alias table)
|     | tag | value | valid? |                       |
| --- | --- | ----- | ------ | --------------------- |
| R0  |     |       | 1      |  םעפה םירבדה לע רוזחנ |
| R1  |     |       | 1      |  הנוש טעמ היצנבנוק םע |
.תפסונ המגוד הארנ םגו
| R2  |     |     | 1   |     |
| --- | --- | --- | --- | --- |
| R3  |     |     | 1   |     |
| R4  |     |     | 1   |     |
| R5  |     |     | 1   |     |
| R6  |     |     | 1   |     |
R7
1
R8
1
| R9  |     |     | 1   |     |
| --- | --- | --- | --- | --- |
72

Tomasulo’s Algorithm - תרוכזת
 If reservation station available before renaming אלמ – הנימז הנחתה םא
התוא
 Instruction + renamed operands (source value/tag) inserted into the
reservation station
CDB=Common Data Bus
 Only rename if reservation station is available
 Else stall רוצע ,אל םא
 While in reservation station, each instruction:
 Watches common data bus (CDB) for tag of its sources
 When tag seen, grab value for the source and keep it in the reservation
station
 When both operands available, instruction ready to be dispatched
 Dispatch instruction to the Functional Unit when instruction is ready
 After instruction finishes in the Functional Unit
 Arbitrate (רורבל) for CDB
 Put tagged value onto CDB (tag broadcast)
 Register file is connected to the CDB
 Register contains a tag indicating the latest writer to the register
 If the tag in the register file matches the broadcast tag, write broadcast value
into register (and set valid bit)
 Reclaim rename tag
73
 no valid copy of tag in system!

An Exercise
MUL R3  R1, R2 Pipeline F D E W
ADD R5  R3, R4
ADD R7  R2, R6
ADD F D E E E E W
ADD R10  R8, R9
MUL R11  R7, R10
MUL F D E E E E E E E E W
ADD R5  R5, R11
 Assume ADD (4 cycle execute), MUL (6 cycle execute)
 Assume one adder and one multiplier
 How many cycles
 in a non-pipelined machine: 50 cycles (4*7 + 2*11)
 in an in-order-dispatch pipelined machine with imprecise
exceptions (no forwarding and forwarding)
 in an out-of-order dispatch pipelined machine imprecise
exceptions (forwarding)
74

Register alias table (v=valid bit, tag, value)
אוה ,הזה רטסיגרל בותכל דמוע והשימ V=0
Reservation station
.ןיילפייפב
ול שי תרחא ךרע ול שי זא V valid ןמיס רטסיגרל םא
tag
גת ול שי תרחא ךרע ול שי ןיקת רטסיגר םא

CDB=Common Data Bus
)Tag bus( םיגתה רוביחל סאב

לפוכל םג לשמל buses דוע םנשיו
Value bus
לש תורוקמה לש V -ה ינש רשאכ
היהי )true( םיפקת הלועפה
DISPATCH
-ה לש ID -ה אוה גתה
reservation station

Exercise Continued
pipeline structure
Can take multiple cycles
How many cycles total without data forwarding?
78

Exercise Continued
in-order-dispatch pipelined machine
w/o forwarding: 31 cycles
Execution timeline with scoreboarding
in-order-dispatch pipelined machine
w/ forwarding: 25 cycles
Execution timeline with forwarding
79

Exercise Continued
MUL R3  R1, R2
ADD R5  R3, R4
ADD R7  R2, R6
ADD R10  R8, R9
MUL R11  R7, R10
ADD R5  R5, R11
out-of-order dispatch pipelined machine
w/ forwarding: 20 cycles
Tomasulo’s algorithm + full forwarding
31 cycles → 25 cycles → 20 cycles. 11/31=0.35, 35% improvement!
80

How It Works
Register alias table
לש םתירוגלאה עוציבל הינש המגוד התע איבנ
המגודל האוושהב םילדבה ינשב ולוסמוט
:הנושארה
.FU לכל דרפנ RS שי וז המגודב .א
טעמ RS-ב תודומעה תומש לש היצנבנוקה .ב
.הנוש
Reservation station
for adder
םידרפנ םיסב שיש חיננ
רבחמלו לפוכל
81

Our First OoO Machine Simulation
Program We Will Simulate
| MUL R1, R2 |    | R3  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
Initially:
| ADD R3, R4 |     | R5  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |

|            |     |     | 1.  | Reservation Stations (RS’s) are all Invalid (Empty) |     |     |     |     |
| ---------- | --- | --- | --- | --------------------------------------------------- | --- | --- | --- | --- |
| ADD R2, R6 |    | R7  |     |                                                     |     |     |     |     |
|            |     |     | 2.  | All Registers are Valid                             |     |     |     |     |
| ADD R8, R9 |     | R10 |     |                                                     |     |     |     |     |

| MUL R7, R10 |     | R11 |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     | R5  |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

|          |           |       | RS for ADD Unit |       |             | RS for MUL Unit |       |             |
| -------- | --------- | ----- | --------------- | ----- | ----------- | --------------- | ----- | ----------- |
| Register | Valid Tag | Value |                 |       |             |                 |       |             |
|          |           |       | Source 1        |       | Source 2    | Source 1        |       | Source 2    |
| R1       | 1         | 1     |                 |       |             |                 |       |             |
|          |           |       | V Tag           | Value | V Tag Value | V Tag           | Value | V Tag Value |
| R2       | 1         | 2     |                 |       |             |                 |       |             |
| R3       | 1         | 3     | a               |       |             | x               |       |             |
| R4       | 1         | 4     | b               |       |             | y               |       |             |
| R5       | 1         | 5     |                 |       |             |                 |       |             |
|          |           |       | c               |       |             | z               |       |             |
| R6       | 1         | 6     |                 |       |             |                 |       |             |
|          |           |       | d               |       |             | t               |       |             |
| R7       | 1         | 7     |                 |       |             |                 |       |             |
| R8       | 1         | 8     |                 |       |             |                 |       |             |
∗
+
| R9  | 1   | 9   |     |           |     |     |     |       |
| --- | --- | --- | --- | --------- | --- | --- | --- | ----- |
| R10 | 1   | 10  |     |           |     |     |     |       |
|     |     |     |     | Tag Value |     |     | Tag | Value |
| R11 | 1   | 11  |     |           |     |     |     |       |
Register Alias Table
ADD and MUL Execution Units
have separate Tag & Value buses 82

Cycle 0
Cycle
| MUL R1, R2 |    | R3  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R3, R4 |     | R5  |     |     |     |     |     |     |

| ADD R2, R6 |    | R7  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R8, R9 |     | R10 |     |     |     |     |     |     |

| MUL R7, R10 |     | R11 |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     | R5  |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid Tag | Value |          |       |             |          |       |             |
| -------- | --------- | ----- | -------- | ----- | ----------- | -------- | ----- | ----------- |
|          |           |       | Source 1 |       | Source 2    | Source 1 |       | Source 2    |
| R1       | 1         | 1     |          |       |             |          |       |             |
| R2       | 1         | 2     | V Tag    | Value | V Tag Value | V Tag    | Value | V Tag Value |
| R3       | 1         | 3     |          |       |             |          |       |             |
|          |           | a     |          |       | x           |          |       |             |
| R4       | 1         | 4     |          |       |             |          |       |             |
|          |           | b     |          |       | y           |          |       |             |
| R5       | 1         | 5     |          |       |             |          |       |             |
|          |           | c     |          |       | z           |          |       |             |
| R6       | 1         | 6     |          |       |             |          |       |             |
|          |           | d     |          |       | t           |          |       |             |
| R7       | 1         | 7     |          |       |             |          |       |             |
| R8       | 1         | 8     |          |       |             |          |       |             |
∗
+
| R9  | 1   | 9   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   | 10  |     |     |     |     |     |     |
| R11 | 1   | 11  |     |     |     |     |     |     |
83

Cycle 1
|            |     |     | Cycle 1 |     |     |     |     |     |     |
| ---------- | --- | --- | ------- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3 F    |     |     |     |     |     |     |
| ADD R3, R4 |     |     | R5      |     |     |     |     |     |     |

| ADD R2, R6 |     |    | R7  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R8, R9 |     |     | R10 |     |     |     |     |     |     |

| MUL R7, R10 |     |     | R11 |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |          |       |             |          |       |             |
| -------- | ----- | --- | ----- | -------- | ----- | ----------- | -------- | ----- | ----------- |
|          |       |     |       | Source 1 |       | Source 2    | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |          |       |             |          |       |             |
| R2       | 1     |     | 2     | V Tag    | Value | V Tag Value | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 3     |          |       |             |          |       |             |
|          |       |     | a     |          |       | x           |          |       |             |
| R4       | 1     |     | 4     |          |       |             |          |       |             |
|          |       |     | b     |          |       | y           |          |       |             |
| R5       | 1     |     | 5     |          |       |             |          |       |             |
|          |       |     | c     |          |       | z           |          |       |             |
| R6       | 1     |     | 6     |          |       |             |          |       |             |
|          |       |     | d     |          |       | t           |          |       |             |
| R7       | 1     |     | 7     |          |       |             |          |       |             |
| R8       | 1     |     | 8     |          |       |             |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 10  |     |     |     |     |     |     |
| R11 | 1   |     | 11  |     |     |     |     |     |     |
84

MUL gets decoded and allocated into RS x
Cycle 2
Step 1: Check if reservation station available. Yes: x
|     |     | Cycle 1 | 2   |     | Step 2: Access the Register Alias Table |     |     |     |     |
| --- | --- | ------- | --- | --- | --------------------------------------- | --- | --- | --- | --- |
MUL R1, R2  R3 F D Step 3: Put source registers into reservation station x
| ADD R3, R4 |     | R5  | F   |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Step 4: Rename destination register R3  x
| ADD R2, R6 |    | R7  |     |     |     |                          |     |     |     |
| ---------- | --- | --- | --- | --- | --- | ------------------------ | --- | --- | --- |
| ADD R8, R9 |     | R10 |     |     |     |                          |     |     |     |
|            |    |     |     |     |     | R3 is now renamed to x.  |     |     |     |
MUL R7, R10 R11 Its new value will produced by the reservation station

| ADD R5, R11 |     | R5  |     |     |     | that is identified by tag x. |     |     |     |
| ----------- | --- | --- | --- | --- | --- | ---------------------------- | --- | --- | --- |

| Register | Valid Tag | Value |     |             |             |     |          |       |             |
| -------- | --------- | ----- | --- | ----------- | ----------- | --- | -------- | ----- | ----------- |
|          |           |       |     | Source 1    | Source 2    |     | Source 1 |       | Source 2    |
| R1       | 11        | 11    |     |             |             |     |          |       |             |
| R2       | 11        | 22    |     | V Tag Value | V Tag Value |     | V Tag    | Value | V Tag Value |
|          |           |       |     |             |             |     | ~        |       | ~           |
| R3       | 10 x      | 3     |     |             |             |     |          |       |             |
|          |           |       | a   |             |             |     | x        |       |             |
| R4       | 1         | 4     |     |             |             |     | y        |       |             |
b
| R5  | 1   | 5   |     |     |     |     | z   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
c
t
| R6  | 1   | 6   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
d
| R7  | 1   | 7   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R8  | 1   | 8   |     |     |     |     |     |     |     |
∗
+
| R9  | 1   | 9   |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   | 10  |     |     |     |     |     |     |     |
| R11 | 1   | 11  |     |     |     |     |     |     |     |
MUL in RS x is ready to execute in the next cycle!
85

1. MUL in RS x starts executing
Cycle 3
2. ADD gets decoded and allocated into RS a
|     |     | Cycle 1 | 2 3 |     | Check readiness (Both sources ready?)  Wakeup |     |     |     |
| --- | --- | ------- | --- | --- | ---------------------------------------------- | --- | --- | --- |
MUL R1, R2  R3 F D E Ready  Dispatch the instruction to the MUL unit
1
| ADD R3, R4 |     | R5  | F D |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |

Same Steps 1-4 for ADD… Rename R5  a
F
| ADD R2, R6 |    | R7  |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R8, R9 |     | R10 |     |     |     |     |     |     |

| MUL R7, R10 |     | R11 |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     | R5  |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid Tag | Value |     |             |             |          |       |             |
| -------- | --------- | ----- | --- | ----------- | ----------- | -------- | ----- | ----------- |
|          |           |       |     | Source 1    | Source 2    | Source 1 |       | Source 2    |
| R1       | 1         | 1     |     |             |             |          |       |             |
| R2       | 1         | 2     |     | V Tag Value | V Tag Value | V Tag    | Value | V Tag Value |
~
| R3  | 00 xx |     |     |     |     |       |     |       |
| --- | ----- | --- | --- | --- | --- | ----- | --- | ----- |
|     |       |     | a   |     |     | x 1 ~ | 1   | 1 ~ 2 |
| R4  | 11    | 44  |     |     |     |       |     |       |
|     |       |     | b   |     |     | y     |     |       |
| R5  | 10 a  | 5   |     |     |     |       |     |       |
|     |       |     | c   |     |     | z     |     |       |
| R6  | 1     | 6   |     |     |     |       |     |       |
|     |       |     | d   |     |     | t     |     |       |
| R7  | 1     | 7   |     |     |     |       |     |       |
| R8  | 1     | 8   |     |     |     |       |     |       |
∗ 6
+
| R9  | 1   | 9   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Cycles
| R10 | 1   | 10  |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R11 | 1   | 11  |     |     |     |     |     |     |
ADD in RS a cannot execute in the next cycle: one source is not valid
86

Cycle 4
Cycle 1 2 3 4 ADD in RS a waits because one source is not valid.
| MUL R1, R2 |     |    | R3  | F   | D E | E   |     |     |     |               |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- |
|            |     |     |     |     |     | 1 2 |     |     |     | Rename R7  b |     |     |     |
| ADD R3, R4 |     |     | R5  |     | F D | -   |     |     |     |               |     |     |     |

F D
| ADD R2, R6 |     |    | R7  |     |     |     |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R8, R9 |     |     | R10 |     |     | F   |     |     |     |     |     |     |     |

| MUL R7, R10 |     |     | R11 |     |     |     |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |          |       |          |       |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | -------- | ----- | -------- | ----- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     | Source 1 |       | Source 2 |       |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |          |       |          |       |     |          |       |             |
| R2       | 11    |     | 22    |     |     | V Tag    | Value | V Tag    | Value |     | V Tag    | Value | V Tag Value |
| R3       | 0     | x   |       |     |     |          |       |          |       |     |          |       |             |
|          |       |     |       |     | a   | 0 x      |       | 1 ~      | 4     | x   | 1 ~      | 1     | 1 ~ 2       |
|          |       |     |       |     |     | ~        |       | ~        |       |     |          |       |             |
| R4       | 1     |     | 4     |     |     |          |       |          |       |     |          |       |             |
|          |       |     |       |     | b   |          |       |          |       | y   |          |       |             |
| R5       | 0     | a   |       |     |     |          |       |          |       |     |          |       |             |
|          |       |     |       |     | c   |          |       |          |       | z   |          |       |             |
| R6       | 11    |     | 66    |     |     |          |       |          |       |     |          |       |             |
|          |       |     |       |     | d   |          |       |          |       | t   |          |       |             |
| R7       | 10    | b   | 7     |     |     |          |       |          |       |     |          |       |             |
| R8       | 1     |     | 8     |     |     |          |       |          |       |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 10  |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 11  |     |     |     |     |     |     |     |     |     |     |
ADD in RS b is ready to execute in the next cycle!
It will be executed out of order in the next cycle.
87

Cycle 5
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   |     |     |     |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   |     |     |     |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   |     |     |     |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   |     |     |     |     |     |     |     |

|            |     |     |     |     |     | F   | D   | E   |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6 |     |    | R7  |     |     |     |     | 1   |     |     |     |     |     |     |     |
| ADD R8, R9 |     |     | R10 |     |     |     | F   | D   |     |     |     |     |     |     |     |

| MUL R7, R10 |     |     | R11 |     |     |     |     | F   |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |     |          |       |     |          |       |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | ----- | --- | -------- | ----- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |       |     | Source 2 |       |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |       |     |          |       |     |          |       |             |
| R2       | 1     |     | 2     |     |     | V   | Tag      | Value | V   | Tag      | Value |     | V Tag    | Value | V Tag Value |
| R3       | 0     | x   |       |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | a   | 0   | x        |       | 1   | ~        | 4     | x   | 1 ~      | 1     | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | b   | 1   | ~        | 2     | 1   | ~        | 6     | y   |          |       |             |
|          |       |     |       |     |     | 1   | ~        | 8     | 1   | ~        | 9     |     |          |       |             |
| R5       | 0     | a   |       |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | c   |     |          |       |     |          |       | z   |          |       |             |
| R6       | 1     |     | 6     |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | d   |     |          |       |     |          |       | t   |          |       |             |
| R7       | 0     | b   |       |     |     |     |          |       |     |          |       |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     |     |          |       |     |          | 4     |     |          | ∗     |             |
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Cycles
| R10 | 10  | c   | 10  |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R11 | 1   |     | 11  |     |     |     |     |     |     |     |     |     |     |     |     |
ADD in RS c is ready to execute in the next cycle!
88

Cycle 6
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5 6 |     |     |     |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E E |     |     |     |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | - - |     |     |     |     |     |     |     |

|             |     |     |     |     |     | F   | D   | E E |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6  |     |    | R7  |     |     |     |     | 1   | 2   |     |     |     |     |     |     |
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D E |     |     |     |     |     |     |     |
|             |     |    |     |     |     |     |     |     | 1   |     |     |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F D |     |     |     |     |     |     |     |

| ADD R5, R11 |     |     | R5  |     |     |     |     | F   |     |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |     |          |       |     |          |       |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | ----- | --- | -------- | ----- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |       |     | Source 2 |       |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |       |     |          |       |     |          |       |             |
| R2       | 1     |     | 2     |     |     | V   | Tag      | Value | V   | Tag      | Value |     | V Tag    | Value | V Tag Value |
| R3       | 0     | x   |       |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | a   | 0   | x        |       | 1   | ~        | 4     | x   | 1 ~      | 1     | 1 ~ 2       |
|          |       |     |       |     |     |     |          |       |     |          |       |     | 0 b      |       | 0 c         |
| R4       | 1     |     | 4     |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | b   | 1   | ~        | 2     | 1   | ~        | 6     | y   |          |       |             |
| R5       | 0     | a   |       |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | c   | 1   | ~        | 8     | 1   | ~        | 9     | z   |          |       |             |
| R6       | 1     |     | 6     |     |     |     |          |       |     |          |       |     |          |       |             |
|          |       |     |       |     | d   |     |          |       |     |          |       | t   |          |       |             |
| R7       | 0     | b   |       |     |     |     |          |       |     |          |       |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |       |     |          |       |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 10  | y   | 11  |     |     |     |     |     |     |     |     |     |     |     |     |
89

All six instructions are now decoded and renamed
Cycle 7
Note what happened to R5: Renamed twice!
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   |     |     |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   | E   | E   |     |     |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   |     |     |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   | -   | -   |     |     |     |     |     |     |

|             |     |     |     |     |     | F   | D   | E   | E   | E   |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6  |     |    | R7  |     |     |     |     | 1   | 2   | 3   |     |     |     |     |     |     |
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D   | E   | E   |     |     |     |     |     |     |
|             |     |    |     |     |     |     |     |     | 1   | 2   |     |     |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   |     |     |     |     |     |     |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |     |          |     |       |          |       |     |          |       |     |           |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | -------- | ----- | --- | -------- | ----- | --- | --------- |
|          |       |     |       |     |     |     | Source 1 |     |       | Source 2 |       |     | Source 1 |       |     | Source 2  |
| R1       | 1     |     | 1     |     |     |     |          |     |       |          |       |     |          |       |     |           |
|          |       |     |       |     |     |     |          |     |       |          |       |     | V Tag    | Value | V   | Tag Value |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V Tag    | Value |     |          |       |     |           |
x
| R3  | 0   | x   |     |     |     |     |     |     |     |     |     |     | 1 ~ | 1   | 1   | ~ 2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | a   | 0   | x   |     | 1 ~ | 4   |     |     |     |     |     |
| R4  | 1   |     | 4   |     |     |     |     |     |     |     |     | y   | 0 b |     | 0   | c   |
|     |     |     |     |     |     | b   | 1   | ~   | 2   | 1 ~ | 6   |     |     |     |     |     |
| R5  | 00  | da  |     |     |     |     |     |     |     |     |     | z   |     |     |     |     |
|     |     |     |     |     |     | c   | 1   | ~   | 8   | 1 ~ | 9   |     |     |     |     |     |
| R6  | 1   |     | 6   |     |     |     | 0   | a   |     | 0 y |     | t   |     |     |     |     |
d
| R7  | 0   | b   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R8  | 1   |     | 8   |     |     |     |     |     |     |     |     |     |     |     |     |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
90

Cycle 8 (First Slide)
MUL in RS x is done
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |     |                         |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------------------- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   |     |                         |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     | Broadcast MUL’s tag (x) |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   | -   | -   |     |     |                         |     |     |     |     |

 Check tag
|            |     |     |     |     |     | F   | D   | E   | E   | E   |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6 |     |    | R7  |     |     |     |     | 1   | 2   | 3   |     |     |     |     |     |     |     |
 Check for invalidity
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D   | E   | E   |     |     |                            |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | -------------------------- | --- | --- | --- | --- |
|             |     |    |     |     |     |     |     |     | 1   | 2   |     |     |                            |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   |     |     |                            |     |     |     |     |
|             |     |    |     |     |     |     |     |     |     |     |     |     | Broadcast MUL’s result (2) |     |     |     |     |
| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   |     |     |                            |     |     |     |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | -------- | ----- | --- | --------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     | Source 1 |       |     | Source 2  |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     | V Tag    | Value | V   | Tag Value |
|          |       |     |       |     |     |     | 1        |     | 2     |     |          |       |     |          |       |     |           |
| R3       | 01    | x   | 2     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | a   | 0        | x   |       | 1   | ~        | 4     | x   | 1 ~      | 1     | 1   | ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     | y   | 0 b      |       | 0   | c         |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     | z   |          |       |     |           |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       | t   |          |       |     |           |
| R7       | 0     | b   |       |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | x   | 2   |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     | x   | 2   |     |
91
ADD in RS a is ready to execute in the next cycle!

Cycle 8 (Second Slide)
ADD in RS b is also done
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |     |                         |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------------------- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   |     |                         |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     | Broadcast ADD’s tag (b) |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   |     |                         |     |     |     |     |

 Check tag
|            |     |     |     |     |     | F   | D   | E   | E   | E   | E   |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6 |     |    | R7  |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |     |
 Check for invalidity
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D   | E   | E   |     |     |                            |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | -------------------------- | --- | --- | --- | --- |
|             |     |    |     |     |     |     |     |     | 1   | 2   |     |     |                            |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   |     |     |                            |     |     |     |     |
|             |     |    |     |     |     |     |     |     |     |     |     |     | Broadcast ADD’s result (8) |     |     |     |     |
| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   |     |     |                            |     |     |     |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | -------- | ----- | --- | --------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     | Source 1 |       |     | Source 2  |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     | V Tag    | Value | V   | Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     | x   | 1 ~      | 1     | 1   | ~ 2       |
|          |       |     |       |     |     |     |          |     |       |     |          |       |     | 1        | 8     |     |           |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     | y   | 0 b      |       | 0   | c         |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     | z   |          |       |     |           |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       | t   |          |       |     |           |
| R7       | 01    | b   | 8     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |          |       |     |           |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     | b   | 8   |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     | b   | 8   |     |     |     |     |     |     |     |
92
MUL in RS y is still NOT ready to execute in the next cycle!

Cycle 8 (Third Slide)
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |     |     |     |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   |     |     |     |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   |     |     |     |     |     |

|             |     |     |     |     |     | F   | D   | E   | E   | E   | E   |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6  |     |    | R7  |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D   | E   | E   | E   |     |     |     |     |     |
|             |     |    |     |     |     |     |     |     | 1   | 2   | 3   |     |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   | -   |     |     |     |     |     |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   | -   |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |          |       |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     | x   | 1 ~      | 1     | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     | y   | 1 ~      | 8     | 0 c         |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     | z   |          |       |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       | t   |          |       |             |
| R7       | 1     | b   | 8     |     |     |     |          |     |       |     |          |       |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
93

Cycle 9
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   |     |                      |     |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | -------------------- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |                      |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |                      |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   |     |                      |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   |     |                      |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |                      |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |                      |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   |     | Broadcast and Update |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |                      |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   |     |                      |     |     |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   | -   | -   |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |          |       |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |          |       |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     | x   | 1 ~      | 1     | 1 ~ 2       |
1 ~ 17
| R4  | 1   |     | 4   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | b   | 1   | ~   | 2   | 1   | ~   | 6   | y   | 1 ~ | 8   | 0 c |
| R5  | 0   | d   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     | c   | 1   | ~   | 8   | 1   | ~   | 9   | z   |     |     |     |
| R6  | 1   |     | 6   |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     | d   | 0   | a   |     | 0   | y   |     | t   |     |     |     |
| R7  | 1   |     | 8   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R8  | 1   |     | 8   |     |     |     |     |     |     |     |     |     |     |     |     |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 01  | c   | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     | c   | 17  |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
MUL in RS y is ready to execute in the next cycle!
94

Cycle 10
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  |     |     |     |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |     |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |     |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   |     |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   |     |     |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |     |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   |     |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   |     |     |     |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   |     |     |     |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     | x   | 1 ~      | 1     | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     | y   | 1 ~      | 8     | 1 ~ 17      |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     | z   |          |       |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       |     | t   |          |       |             |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
95

Cycle 11
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  |     |     |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |     |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |     |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   |     |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |     |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   | E   |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   | 2   |     |     |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   | -   |     |     |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     | x   | 1 ~      | 1     | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     | y   | 1 ~      | 8     | 1 ~ 17      |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     | z   |          |       |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       |     | t   |          |       |             |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
96

Cycle 12
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12  |                      |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | -------------------- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |     |                      |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |     |                      |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   | E   | Broadcast and Update |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   | 4   |                      |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |     |                      |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |     |                      |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |                      |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |                      |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   | E   | E   |                      |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   | 2   | 3   |                      |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   | -   | -   |                      |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1 ~ 17      |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |             |
|          |       |     |       |     |     |     | 1        | ~   | 6     |     |          |       |     |     |          |           |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | d   | 0        | a   |       | 0   | y        |       |     |     | t        |           |             |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     | a   | 6   |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
97

Cycle 13
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12 13 |     |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |       |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |       |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   | E W   |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   | 4     |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |       |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |       |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |       |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |       |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   | E   | E E   |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   | 2   | 3 4   |     |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   | -   | - -   |     |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | ----- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |       | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V Tag    | Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1 ~    | 1     | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1 ~    | 8     | 1 ~ 17      |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |       |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
|          |       |     |       |     |     | d   | 1        | ~   | 6     | 0   | y        |       |     |     | t        |       |             |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |       |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
98

Cycle 14
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12 13 | 14  |     |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |       |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |       |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   | E W   |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   | 4     |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |       |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |       |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |       |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |       |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   | E   | E E   | E   |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   | 2   | 3 4   | 5   |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   | -   | - -   | -   |     |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | ----------- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           | Source 2    |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V Tag Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1 ~ 2       |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1 ~ 17      |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |             |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
|          |       |     |       |     |     | d   | 1        | ~   | 6     | 0   | y        |       |     |     | t        |           |             |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |             |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
99

Cycle 15
|            |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12 13 | 14 15 |     |     |
| ---------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | ----- | --- | --- |
| MUL R1, R2 |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |       |       |     |     |
|            |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |       |       |     |     |
| ADD R3, R4 |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   | E W   |       |     |     |
|            |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   | 4     |       |     |     |
|            |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |       |       |     |     |
| ADD R2, R6 |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |       |       |     |     |
| ADD R8, R9 |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |       |       |     |     |
|            |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |       |       |     |     |
Broadcast and
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   | -   | -   | E   | E   | E E | E E |     |        |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ |
|             |     |    |     |     |     |     |     |     |     |     |     |     | 1   | 2   | 3 4 | 5 6 |     | Update |
| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   | -   | -   | -   | -   | - - | - - |     |        |

| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | -------- | ----- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           | Source 2 |       |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V Tag    | Value |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1        | ~ 2   |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1        | ~ 17  |
| R5       | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |          |       |
|          |       |     |       |     |     |     |          |     |       | 1   | ~        | 13    |     |     |          |           |          |       |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
|          |       |     |       |     |     | d   | 1        | ~   | 6     | 0   | y        | 6     |     |     | t        |           |          |       |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |          |       |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | y   | 136 |     |
| R11 | 01  | y   | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
ADD in RS d is ready to execute in the next cycle!
100

Cycle 16
|             |       |     | Cycle | 1   | 2   | 3   | 4        | 5   | 6     | 7   | 8        | 9     | 10  | 11  | 12 13    | 14 15     | 16  |           |
| ----------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | --- | --------- |
| MUL R1, R2  |       |    | R3    | F   | D   | E   | E        | E   | E     | E   | E        | W     |     |     |          |           |     |           |
|             |       |     |       |     |     | 1   | 2        | 3   | 4     | 5   | 6        |       |     |     |          |           |     |           |
| ADD R3, R4  |       |     | R5    |     | F   | D   | -        | -   | -     | -   | -        | E     | E   | E   | E W      |           |     |           |
|             |       |    |       |     |     |     |          |     |       |     |          | 1     | 2   | 3   | 4        |           |     |           |
|             |       |     |       |     |     | F   | D        | E   | E     | E   | E        | W     |     |     |          |           |     |           |
| ADD R2, R6  |       |    | R7    |     |     |     |          | 1   | 2     | 3   | 4        |       |     |     |          |           |     |           |
| ADD R8, R9  |       |     | R10   |     |     |     | F        | D   | E     | E   | E        | E     | W   |     |          |           |     |           |
|             |       |    |       |     |     |     |          |     | 1     | 2   | 3        | 4     |     |     |          |           |     |           |
| MUL R7, R10 |       |     | R11   |     |     |     |          | F   | D     | -   | -        | -     | E   | E   | E E      | E E       | W   |           |
|             |       |    |       |     |     |     |          |     |       |     |          |       | 1   | 2   | 3 4      | 5         | 6   |           |
| ADD R5, R11 |       |     | R5    |     |     |     |          |     | F     | D   | -        | -     | -   | -   | - -      | - -       | E   |           |
|             |       |    |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     | 1         |
| Register    | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           |     | Source 2  |
| R1          | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
| R2          | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V   | Tag Value |
| R3          | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1   | ~ 2       |
| R4          | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1   | ~ 17      |
| R5          | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |     |           |
| R6          | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | d   | 1        | ~   | 6     | 1   | ~        | 136   |     |     | t        |           |     |           |
| R7          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
| R8          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
101

Cycle 17
|             |       |     | Cycle | 1   | 2   | 3   | 4        | 5   | 6     | 7   | 8        | 9     | 10  | 11  | 12 13    | 14 15     | 16  | 17        |
| ----------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | --- | --------- |
| MUL R1, R2  |       |    | R3    | F   | D   | E   | E        | E   | E     | E   | E        | W     |     |     |          |           |     |           |
|             |       |     |       |     |     | 1   | 2        | 3   | 4     | 5   | 6        |       |     |     |          |           |     |           |
| ADD R3, R4  |       |     | R5    |     | F   | D   | -        | -   | -     | -   | -        | E     | E   | E   | E W      |           |     |           |
|             |       |    |       |     |     |     |          |     |       |     |          | 1     | 2   | 3   | 4        |           |     |           |
|             |       |     |       |     |     | F   | D        | E   | E     | E   | E        | W     |     |     |          |           |     |           |
| ADD R2, R6  |       |    | R7    |     |     |     |          | 1   | 2     | 3   | 4        |       |     |     |          |           |     |           |
| ADD R8, R9  |       |     | R10   |     |     |     | F        | D   | E     | E   | E        | E     | W   |     |          |           |     |           |
|             |       |    |       |     |     |     |          |     | 1     | 2   | 3        | 4     |     |     |          |           |     |           |
| MUL R7, R10 |       |     | R11   |     |     |     |          | F   | D     | -   | -        | -     | E   | E   | E E      | E E       | W   |           |
|             |       |    |       |     |     |     |          |     |       |     |          |       | 1   | 2   | 3 4      | 5         | 6   |           |
| ADD R5, R11 |       |     | R5    |     |     |     |          |     | F     | D   | -        | -     | -   | -   | - -      | - -       | E   | E         |
|             |       |    |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     | 1 2       |
| Register    | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           |     | Source 2  |
| R1          | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
| R2          | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V   | Tag Value |
| R3          | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1   | ~ 2       |
| R4          | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1   | ~ 17      |
| R5          | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |     |           |
| R6          | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
|             |       |     |       |     |     | d   | 1        | ~   | 6     | 1   | ~        | 136   |     |     | t        |           |     |           |
| R7          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
| R8          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |           |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
102

Cycle 18
|             |       |     | Cycle | 1   | 2   | 3   | 4        | 5   | 6     | 7   | 8        | 9     | 10  | 11  | 12 13    | 14 15     | 16  | 17       | 18    |
| ----------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | --- | -------- | ----- |
| MUL R1, R2  |       |    | R3    | F   | D   | E   | E        | E   | E     | E   | E        | W     |     |     |          |           |     |          |       |
|             |       |     |       |     |     | 1   | 2        | 3   | 4     | 5   | 6        |       |     |     |          |           |     |          |       |
| ADD R3, R4  |       |     | R5    |     | F   | D   | -        | -   | -     | -   | -        | E     | E   | E   | E W      |           |     |          |       |
|             |       |    |       |     |     |     |          |     |       |     |          | 1     | 2   | 3   | 4        |           |     |          |       |
|             |       |     |       |     |     | F   | D        | E   | E     | E   | E        | W     |     |     |          |           |     |          |       |
| ADD R2, R6  |       |    | R7    |     |     |     |          | 1   | 2     | 3   | 4        |       |     |     |          |           |     |          |       |
| ADD R8, R9  |       |     | R10   |     |     |     | F        | D   | E     | E   | E        | E     | W   |     |          |           |     |          |       |
|             |       |    |       |     |     |     |          |     | 1     | 2   | 3        | 4     |     |     |          |           |     |          |       |
| MUL R7, R10 |       |     | R11   |     |     |     |          | F   | D     | -   | -        | -     | E   | E   | E E      | E E       | W   |          |       |
|             |       |    |       |     |     |     |          |     |       |     |          |       | 1   | 2   | 3 4      | 5         | 6   |          |       |
| ADD R5, R11 |       |     | R5    |     |     |     |          |     | F     | D   | -        | -     | -   | -   | - -      | - -       | E   | E        | E     |
|             |       |    |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     | 1        | 2 3   |
| Register    | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
|             |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           |     | Source 2 |       |
| R1          | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
| R2          | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V   | Tag      | Value |
| R3          | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
|             |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1   | ~        | 2     |
| R4          | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
|             |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1   | ~        | 17    |
| R5          | 0     | d   |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
|             |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |     |          |       |
| R6          | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
|             |       |     |       |     |     | d   | 1        | ~   | 6     | 1   | ~        | 136   |     |     | t        |           |     |          |       |
| R7          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
| R8          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
103

Cycle 19
|             |     |     | Cycle | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  | 11  | 12 13 | 14 15 | 16  | 17  | 18  | 19  |
| ----------- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | ----- | --- | --- | --- | --- |
| MUL R1, R2  |     |    | R3    | F   | D   | E   | E   | E   | E   | E   | E   | W   |     |     |       |       |     |     |     |     |
|             |     |     |       |     |     | 1   | 2   | 3   | 4   | 5   | 6   |     |     |     |       |       |     |     |     |     |
| ADD R3, R4  |     |     | R5    |     | F   | D   | -   | -   | -   | -   | -   | E   | E   | E   | E W   |       |     |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     | 1   | 2   | 3   | 4     |       |     |     |     |     |
|             |     |     |       |     |     | F   | D   | E   | E   | E   | E   | W   |     |     |       |       |     |     |     |     |
| ADD R2, R6  |     |    | R7    |     |     |     |     | 1   | 2   | 3   | 4   |     |     |     |       |       |     |     |     |     |
| ADD R8, R9  |     |     | R10   |     |     |     | F   | D   | E   | E   | E   | E   | W   |     |       |       |     |     |     |     |
|             |     |    |       |     |     |     |     |     | 1   | 2   | 3   | 4   |     |     |       |       |     |     |     |     |
| MUL R7, R10 |     |     | R11   |     |     |     |     | F   | D   | -   | -   | -   | E   | E   | E E   | E E   | W   |     |     |     |
|             |     |    |       |     |     |     |     |     |     |     |     |     | 1   | 2   | 3 4   | 5     | 6   |     |     |     |
| ADD R5, R11 |     |     | R5    |     |     |     |     |     | F   | D   | -   | -   | -   | -   | - -   | - -   | E   | E   | E   | E   |
|             |     |    |       |     |     |     |     |     |     |     |     |     |     |     |       |       |     | 1   | 2   | 3 4 |
Broadcast and Update
| Register | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
| -------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | --- | -------- | ----- | --- |
|          |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           |     | Source 2 |       |     |
| R1       | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
| R2       | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V   | Tag      | Value |     |
| R3       | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
|          |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1   | ~        |       | 2   |
| R4       | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
|          |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1   | ~        |       | 17  |
| R5       | 01    | d   | 142   |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
|          |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |     |          |       |     |
| R6       | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
|          |       |     |       |     |     | d   | 1        | ~   | 6     | 1   | ~        | 136   |     |     | t        |           |     |          |       |     |
| R7       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
| R8       | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     | d   | 142 |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
104

Cycle 20
|             |       |     | Cycle | 1   | 2   | 3   | 4        | 5   | 6     | 7   | 8        | 9     | 10  | 11  | 12 13    | 14 15     | 16  | 17       | 18    | 19  | 20  |
| ----------- | ----- | --- | ----- | --- | --- | --- | -------- | --- | ----- | --- | -------- | ----- | --- | --- | -------- | --------- | --- | -------- | ----- | --- | --- |
| MUL R1, R2  |       |    | R3    | F   | D   | E   | E        | E   | E     | E   | E        | W     |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     | 1   | 2        | 3   | 4     | 5   | 6        |       |     |     |          |           |     |          |       |     |     |
| ADD R3, R4  |       |     | R5    |     | F   | D   | -        | -   | -     | -   | -        | E     | E   | E   | E W      |           |     |          |       |     |     |
|             |       |    |       |     |     |     |          |     |       |     |          | 1     | 2   | 3   | 4        |           |     |          |       |     |     |
|             |       |     |       |     |     | F   | D        | E   | E     | E   | E        | W     |     |     |          |           |     |          |       |     |     |
| ADD R2, R6  |       |    | R7    |     |     |     |          | 1   | 2     | 3   | 4        |       |     |     |          |           |     |          |       |     |     |
| ADD R8, R9  |       |     | R10   |     |     |     | F        | D   | E     | E   | E        | E     | W   |     |          |           |     |          |       |     |     |
|             |       |    |       |     |     |     |          |     | 1     | 2   | 3        | 4     |     |     |          |           |     |          |       |     |     |
| MUL R7, R10 |       |     | R11   |     |     |     |          | F   | D     | -   | -        | -     | E   | E   | E E      | E E       | W   |          |       |     |     |
|             |       |    |       |     |     |     |          |     |       |     |          |       | 1   | 2   | 3 4      | 5         | 6   |          |       |     |     |
| ADD R5, R11 |       |     | R5    |     |     |     |          |     | F     | D   | -        | -     | -   | -   | - -      | - -       | E   | E        | E     | E   | W   |
|             |       |    |       |     |     |     |          |     |       |     |          |       |     |     |          |           |     | 1        | 2     | 3 4 |     |
| Register    | Valid | Tag | Value |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     |     | Source 1 |     |       |     | Source 2 |       |     |     | Source 1 |           |     | Source 2 |       |     |     |
| R1          | 1     |     | 1     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
| R2          | 1     |     | 2     |     |     |     | V Tag    |     | Value | V   | Tag      | Value |     |     | V        | Tag Value | V   | Tag      | Value |     |     |
| R3          | 1     |     | 2     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     | a   | 1        | ~   | 2     | 1   | ~        | 4     |     |     | x 1      | ~ 1       | 1   | ~        |       | 2   |     |
| R4          | 1     |     | 4     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     | b   | 1        | ~   | 2     | 1   | ~        | 6     |     |     | y 1      | ~ 8       | 1   | ~        |       | 17  |     |
| R5          | 1     |     | 142   |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     | c   | 1        | ~   | 8     | 1   | ~        | 9     |     |     | z        |           |     |          |       |     |     |
| R6          | 1     |     | 6     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
|             |       |     |       |     |     | d   | 1        | ~   | 6     | 1   | ~        | 136   |     |     | t        |           |     |          |       |     |     |
| R7          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
| R8          | 1     |     | 8     |     |     |     |          |     |       |     |          |       |     |     |          |           |     |          |       |     |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 1   |     | 17  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 1   |     | 136 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
105

Some Questions
 What is needed in hardware to perform tag broadcast
and value capture?
Wires, Comparators & Logic
-> make a value valid
הבר הרמוח תשרדנ
-> wake up an instruction
 Does the tag have to be the ID of the Reservation
Station Entry? No, could be any unique name that enables linking
of producer to consumer
 What can potentially become the critical path?
 Tag broadcast -> value capture -> instruction wake up
 How can you reduce the potential critical paths?
 More pipelining
106

1 -
רוטלומיס
https://www.ecs.umass.edu/ece/koren/architecture/Tomasulo/AppletTomasulo.html
https://www.ecs.umass.edu/ece/koren/architecture/Tomasulo/AppletTomasulo.html

2 -
רוטלומיס
https://nathantypanski.github.io/tomasulo-simulator/

Dataflow Graph for Our Example
MUL R3  R1, R2
ADD R5  R3, R4
ADD R7  R2, R6
ADD R10  R8, R9
MUL R11  R7, R10
ADD R5  R5, R11
Easy task for you: Draw the dataflow graph for the above code
109

State of RAT and RS in Cycle 7
Cycle 1 2 3 4 5 6 7 All 6 instructions are decoded and renamed
| MUL R1, R2 |     |    | R3  | F   | D   | E   | E   | E   | E   | E   |                                          |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---------------------------------------- | --- | --- | --- | --- | --- |
|            |     |     |     |     |     | 1   | 2   | 3   | 4   | 5   | Note what happened to R5: Renamed twice! |     |     |     |     |     |
| ADD R3, R4 |     |     | R5  |     | F   | D   | -   | -   | -   | -   |                                          |     |     |     |     |     |

|             |     |     |     |     |     | F   | D   | E   | E   | E   |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD R2, R6  |     |    | R7  |     |     |     |     | 1   | 2   | 3   |     |     |     |     |     |     |
| ADD R8, R9  |     |     | R10 |     |     |     | F   | D   | E   | E   |     |     |     |     |     |     |
|             |     |    |     |     |     |     |     |     | 1   | 2   |     |     |     |     |     |     |
| MUL R7, R10 |     |     | R11 |     |     |     |     | F   | D   | -   |     |     |     |     |     |     |

| ADD R5, R11 |     |     | R5  |     |     |     |     |     | F   | D   |     |     |     |     |     |     |
| ----------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

|          |       |     |       |     |     |     | RS for ADD Unit |     |       |          |       |     | RS for MUL Unit |       |     |           |
| -------- | ----- | --- | ----- | --- | --- | --- | --------------- | --- | ----- | -------- | ----- | --- | --------------- | ----- | --- | --------- |
| Register | Valid | Tag | Value |     |     |     |                 |     |       |          |       |     |                 |       |     |           |
|          |       |     |       |     |     |     | Source 1        |     |       | Source 2 |       |     | Source 1        |       |     | Source 2  |
| R1       | 1     |     | 1     |     |     |     |                 |     |       |          |       |     |                 |       |     |           |
|          |       |     |       |     |     |     |                 |     |       |          |       |     | V Tag           | Value | V   | Tag Value |
| R2       | 1     |     | 2     |     |     |     | V Tag           |     | Value | V Tag    | Value |     |                 |       |     |           |
x
| R3  | 0   | x   |     |     |     |     |     |     |     |     |     |     | 1 ~ | 1   | 1   | ~ 2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | a   | 0   | x   |     | 1 ~ | 4   |     |     |     |     |     |
| R4  | 1   |     | 4   |     |     |     |     |     |     |     |     | y   | 0 b |     | 0   | c   |
|     |     |     |     |     |     | b   | 1   | ~   | 2   | 1 ~ | 6   |     |     |     |     |     |
| R5  | 00  | da  |     |     |     |     |     |     |     |     |     | z   |     |     |     |     |
|     |     |     |     |     |     | c   | 1   | ~   | 8   | 1 ~ | 9   |     |     |     |     |     |
| R6  | 1   |     | 6   |     |     | 0   |     | a   |     | 0 y |     | t   |     |     |     |     |
d
| R7  | 0   | b   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R8  | 1   |     | 8   |     |     |     |     |     |     |     |     |     |     |     |     |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
Register Alias Table
110

State of RAT and RS in Cycle 7
Slightly harder tasks for you:
|          |       |     | 1. Draw the dataflow graph for the executing code  |     |                 |       |          |       |     |                 |       |             |
| -------- | ----- | --- | -------------------------------------------------- | --- | --------------- | ----- | -------- | ----- | --- | --------------- | ----- | ----------- |
|          |       |     | 2. Provide the executing code in sequential order  |     |                 |       |          |       |     |                 |       |             |
|          |       |     |                                                    |     | RS for ADD Unit |       |          |       |     | RS for MUL Unit |       |             |
| Register | Valid | Tag | Value                                              |     |                 |       |          |       |     |                 |       |             |
|          |       |     |                                                    |     | Source 1        |       | Source 2 |       |     | Source 1        |       | Source 2    |
| R1       | 1     |     | 1                                                  |     |                 |       |          |       |     |                 |       |             |
|          |       |     |                                                    |     |                 |       |          |       |     | V Tag           | Value | V Tag Value |
| R2       | 1     |     | 2                                                  |     | V Tag           | Value | V Tag    | Value |     |                 |       |             |
x
| R3  | 0   | x   |     |     |     |     |     |     |     | 1 ~ | 1   | 1 ~ 2 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- |
|     |     |     |     | a   | 0 x |     | 1 ~ | 4   |     |     |     |       |
| R4  | 1   |     | 4   |     |     |     |     |     | y   | 0 b |     | 0 c   |
|     |     |     |     | b   | 1 ~ | 2   | 1 ~ | 6   |     |     |     |       |
| R5  | 00  | da  |     |     |     |     |     |     | z   |     |     |       |
|     |     |     |     | c   | 1 ~ | 8   | 1 ~ | 9   |     |     |     |       |
| R6  | 1   |     | 6   |     | 0 a |     | 0 y |     | t   |     |     |       |
d
| R7  | 0   | b   |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R8  | 1   |     | 8   |     |     |     |     |     |     |     |     |     |
∗
+
| R9  | 1   |     | 9   |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R10 | 0   | c   |     |     |     |     |     |     |     |     |     |     |
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |
Register Alias Table
111

All 6 instructions are now decoded and renamed
היצמינא
Cycle 7
Note what happened to R5!
| MUL R1, R2  |     |     | R3 Cycle | 1   | 2   | 3   | 4   | 5 6 | 7   |     |                                 |                                  |     |                     |     |     |
| ----------- | --- | --- | -------- | --- | --- | --- | --- | --- | --- | --- | ------------------------------- | -------------------------------- | --- | ------------------- | --- | --- |
|             |     | →   |          |     |     |     |     |     |     |     |                                 |  לש םינוש םיבלשב שי יכ םיאור ונא |     |                     |     |     |
| ADD R3, R4  |     |     | R5       | F   | D   | E   | E   | E E | E   |     |                                 |                                  |     |                     |     |     |
|             |     | →   |          |     |     | 1   | 2   | 3   | 4   | 5   |                                 |  תנחתב הנתמהב תוארוה 4 עוציב     |     |                     |     |     |
|             |     |     |          |     | F   | D   | -   | - - | -   |     |                                 |                                  |     |                     |     |     |
| ADD R2, R6  |     | →   | R7       |     |     |     |     |     |     |     |  תנחתב הנתמהב תוארוה 2-ו רוביחה |                                  |     |                     |     |     |
|             |     |     |          |     |     | F   | D   | E E | E   |     |                                 |                                  |     |                     |     |     |
|             |     |     |          |     |     |     |     | 1   | 2   | 3   |                                 |                                  |     |                     |     |     |
| ADD R8, R9  |     | →   | R10      |     |     |     |     |     |     |     |                                 |                                  |     | תוארוה 6 כ”הס .לפכה |     |     |
|             |     |     |          |     |     |     | F   | D E | E   |     |                                 |                                  |     |                     |     |     |
|             |     |     |          |     |     |     |     |     | 1   | 2   |                                 |                                  |     |                     |     |     |
| MUL R7, R10 |     |     | R11      |     |     |     |     |     |     |     |                                 |                                  |     |                     |     |     |
→
|             |       |     |       |     |     |     |          | F D       | -   |          |       |     |     |          |         |           |
| ----------- | ----- | --- | ----- | --- | --- | --- | -------- | --------- | --- | -------- | ----- | --- | --- | -------- | ------- | --------- |
| ADD R5, R11 |       |     | R5    |     |     |     |          |           |     |          |       |     |     |          |         |           |
|             |       | →   |       |     |     |     |          | F         | D   |          |       |     |     |          |         |           |
| Register    | Valid | Tag | Value |     |     |     |          |           |     |          |       |     |     |          |         |           |
| R1          | 1     |     | 1     |     |     |     |          |           |     |          |       |     |     |          |         |           |
|             |       |     |       |     |     |     |          |           |     |          |       |     |     | Source 1 |         | Source 2  |
|             |       |     |       |     |     |     | Source 1 |           |     | Source 2 |       |     |     |          |         |           |
|             |       |     |       |     |     |     |          |           |     |          |       |     |     | V Tag    | Value V | Tag Value |
| R2          | 1     |     | 2     |     |     |     |          |           |     |          |       |     |     |          |         |           |
|             |       |     |       |     |     |     | V        | Tag Value | V   | Tag      | Value |     |     |          |         |           |
|             |       |     |       |     |     |     |          |           |     |          |       |     | x   | 1 ~      | 1 1     | ~ 2       |
| R3          | 0     | x   |       |     |     |     |          |           |     |          |       |     |     |          |         |           |
|             |       |     |       |     |     | a   | 0        | x         | 1   | ~        | 4     |     |     |          |         |           |
y
|     |     |     |     |     |     |     |     |     |     |     |     |     |     | 0 b | 0   | c   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | b   | 1   | ~ 2 | 1   | ~   | 6   |     |     |     |     |     |
| R4  | 1   |     | 4   |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |     | c   | 1   | ~ 8 | 1   | ~   | 9   |     |     |     |     |     |
z
| R5  | 0   | ad  |     |     |     |     | 0   | a   | 0   | y   |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | 0   |     |     |     |     | d   |     |     |     |     |     |     |     |     |     |     |
t
| R6  | 1   |     | 6   |     |                                     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ----------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R7  | 0   | b   |     |     |                                     |     |     |     |     |     |     |     |     |     |     |     |
|     |     |     |     |     |                                     |     |     | ++  |     |     |     |     |     |     | ∗+  |     |
| R8  | 1   |     | 8   |     |                                     |     |     |     |     |     |     |     |     |     |     |     |
| R9  | 1   |     | 9   |     |                                     |     |     |     |     |     |     |     |     |     |     |     |
| R10 | 0   | c   |     |     | R5 was a and in cycle 7 it became d |     |     |     |     |     |     |     |     |     |     |     |
112
| R11 | 0   | y   |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Corresponding Dataflow Graph (Reverse Engineered)
6 ןנשי
טטרשנ .תוארוה
םילוגיע 6
data םישרתל
flow
תולועפ :םיתמצה
י”ע תועצבתמה
.תוארוהה
הלחתהל ףוסהמ םישרתה תא טטרשנ י”פע תויגת :תותשקה
לש םתירוגלאה
הארוהב R5 לש תולתהמ ליחתנ ןכלו
ולוסמוט
דוקה הלעמב הלענו הנורחאה 113

Some More Questions (Design Choices)
 When is a reservation station entry deallocated?
 Should the reservation stations be dedicated to each
functional unit or global across functional units?
 Centralized vs. Distributed: What are the tradeoffs?
 Should reservation stations and ROB store data values or
should there be a centralized physical register file where
all data values are stored?
 What are the tradeoffs?
 Many other design choices for OoO engines
114

Tomasulo’s algorithm
with reorder buffer
(11 slides )
115

What about Precise Interrupts?
• Tomasulo had:
In-order issue, out-of-order execution, and
out-of-order completion
• Need to “fix” the out-of-order completion
aspect so that we can find precise breakpoint
in instruction stream.
( )
We prefer to address this later – in speculative H/W
• A similar problem in branch. Instruction
following the branch may update the GPR
before branch is resolved.This was solved by
not issuing an instruction until all branch
instructions preceding it are resolved!

H/W speculation:
H/w speculation means:
We assume that we predict the branch correctly
and therefore continue execution.
If it turns out that our guess was wrong, we should
be able to reverse the calculation.
To do that, we won’t update the GPR or the
Memory until all previous branches are resolved
ונילע יוגש היה שוחינהש ררבתמ םא .תופעתסהה לש ןוכנ יוזיח םיחינמ ונא
דע ןורכיזה תא וא GPR -ה תא ןכדענ אל תאז תושעל ידכ .בושיחה תא לטבל
.ורתפנ הארוהל ומדקש תויופעתסהה רשא

Speculative Tomasulo Algorithm
In the original scheme we issued instructions
although earlier instructions were stalled. That was
the main idea.The instructions were issued in-order,
executed out-of-order and completed (& wrote to
the GPR) also in out-of-order fashion
To prevent control hazards (due to branch
instructions), we stalled the issue process when we
had an unresolved branch prior to the instruction
trying to be issued
This means that we did not issue instructions from
different Basic Blocks and had stalls in loops
ןתינ אל ..תופעתסה יוזיח ןיבל ,הכ-דע ונרכהש יפכ ,OOO בושיח ןיב םיניינע דוגינ שי
...דחיב םהינש תא םייקל
In the speculative scheme we avoid this by avoiding
out of order completion. We want in-order
completion!

Speculative Tomasulo Algorithm
• So, in the speculative scheme we in-order issue, out-of-order
execution and in-order completion (writing to the GPR or
Memory)
• To do that, we need to have another buffer, replacing the GPR
for keeping the calculated results (that are already calculated
but still waiting to their turn to be written back to the GPR).
We also need a mechanism that keeps track of the order of
completion (Here completion is called Commit )
• A simple solution is a cyclic buffer (FIFO like) to which we write
down the instruction when it is issued. That buffer, called the
Reorder Buffer (ROB) has therefore, the correct order of the
instructions. We use this buffer also for storing the result that
is supposed to be written into the GPR when the instruction
commits
• The head of the ROB has the instruction that commits
(completes). If this is a regular instruction, we update the GPR
or the Memory with the result kept in the ROB, and delete the
instruction from the ROB. The next instruction is now
committing. If this a correctly predicted branch, we just delete
it. If this is a mispredicted branch, we clear the ROB and start
executing the correct instructions

רדסה יפע אל עוציב ,רדסה יפל חוליש הצרנ םתירוגלאב רומאכ .יביטלוקפס ולוסמוט םתירוגלא
.ןורכזלו GPR -ל הביתכ רמולכ רדסה יפע םויסו
=============================================
לבא ובשוח רבכש תואצות רומשל וב GPR -ה תפלחהל ףסונ רפאב ךרטצנ תאז תושעל ידכ
רשא םויסה לש רדסה רחא בוקעיש ןונגנמ ךרטצנ ןכ-ומכ .הרזח בתכיהל ןהלש רותל תוניתממש
.COMMIT חנומב התע הנוכי
=============================================
.תוחלשנ ןה רשאכ תוארוהה תובתכנ וילאש )FIFO ןונגסב ילקיצ) ילגעמ רפאב אוה טושפ ןורתפ
תמייתסמ הארוהה רשאכ תואצות לע הרימש ךרוצל םג ROB -ב שמתשנ .ROB-ה השעמל והז
הארוהה לע הארמ ROB-ה שארל עיבצמ .)האצותה תרמשנ םגו רדסה דעותמ םג רמולכ(
תא תא קחמנ זאו ןורכיזה תא וא GPR -ה תא ןכדענ הליגר הארוה וז םא .)COMMIT( תמייתסמש
התיה תמדוקה הארוהה םא COMMIT תושעל הצור האבה הארוהה התע .ROB -המ הארוהה
ןוכנ אל היה יוזיחה םא ,תאז תמועל .ROB -המ התוא קוחמנ טושפ זא ןוכנ התזחנש תופעתסה
.תונוכנה תוארוהה לש עוציבב ליחתנו ROB -ה תא הקננ

היצמינא
Four Steps of Speculative Tomasulo
Algorithm
1. Issue—get instruction from FP Op Queue
If reservation station and reorder buffer slot free, issue instr & send
operands & reorder buffer no. for destination (this stage sometimes
called “dispatch”)
2. Execution—operate on operands (EX)
When both operands ready then execute; if not ready, watch CDB for
result; when both in reservation station, execute; checks RAW
(sometimes called “issue”)
3. Write result—finish execution (WB)
Write on Common Data Bus to all awaiting FUs
& reorder buffer; mark reservation station available.
4. Commit—update register with reorder result
When instr. at head of reorder buffer & result present, update register
with result (or store to memory) and remove instr from reorder buffer.
Mispredicted branch flushes reorder buffer (sometimes called
“graduation”)

Differences between the Speculative
Tomasulo Algorithm & the previous one
1. The main difference: Results are not written to the Register
File, but to the Reorder Buffer (ROB).
2. In the original algorithm, the FUs results are written back
(via the CDB) to all Reservation Station waiting for that
data and to the appropriate register in the Register File – In
the speculative algorithm, the FUs results are written back
(also via the CDB) to all Reservation Station waiting for that
data and to the appropriate entry in the ROB. So the
Register File is updated only during the Commit phase
3. In the speculative scheme, the ROB data is written to the
appropriate register in the GPR only when the instruction
commits
4. Instead of marking Qj & Qk with the FU calculating them,
they are marked with the ROB entry number of the
instruction that produces them. So the FU (Reservation
Station) needs to have a tag with this number and transmit
the tag on the CDB when result is ready (and the CDB
available)

:ולוסמוט ימתירוגלא 2 ןיב םילדבהה
.ROB-ל אלא GPR-ל רשי תובתכנ אל תואצותש אוה ירקעה לדבהה
תומוקמב CDB-ה תרזעב תובתכנ FU-ה תואצות ירוקמה םתירוגלאב
תובתכנ FU -ה תואצות יביטלוקפסה םתירוגלאב .GPR -בו RS -ב םינוכנה
ןכדעתי GPR-ה .ROB -ב הנוכנה הסינכל םגו RS -ב םינוכנה תומוקמה לכל
.COMMIT-ה בלשב קר
.COMMIT שישכ קר GPR-ל בתכנ ROB-המ עדימה תיביטלוקפסה הטישב
הסינכה רפסמב םתוא ןמסנ ,FU- המ םשה םע Qj, Qk תא ןמסל םוקמב
.ROB-ב ההזמה

היצמינא
HW support for precise interrupts
• Need HW buffer for results of – תויפוס אל תואצות רובע רפאבל קקדזנ
.ROB-ה והז
uncommitted instructions:
reorder buffer
– 3 fields: instr, destination, value
Reorder
– Use reorder buffer number instead
Buffer
of reservation station when FP
execution completes
Op
– Supplies the operands between Queue
FP Regs
execution complete & commit
– (Reorder buffer can be operand
source => more registers like RS)
– Instructions commit Res Stations Res Stations
– Once instruction commits,
FP Adder FP Mult.
result is put into register
– As a result, easy to undo speculated
instructions
on mispredicted branches
or exceptions

Graphic representation
The program The instructions sent to
the execution units
Here we had a good
Branch prediction
וניזח Here we had a
תופעתסה
missprediction
החקלנש
These instructions should
וניזח
אלל ךשמה be flushed the minute we
תופעתסה
identify the missprediction!
וניעטו

Relationship between precise
interrupts and specultation:
• Speculation is a form of guessing.
• Important for branch prediction:
– Need to “take our best shot” at predicting branch direction.
• If we speculate and are wrong, need to back up and
restart execution to point at which we predicted
incorrectly:
– This is exactly same as precise exceptions!
• Technique for both precise interrupts/exceptions and
speculation: in-order completion or commit

End of 11 slides
on Tomasulo’s algorithm
with reorder buffer
127

An Exercise, with Precise Exceptions
MUL R3  R1, R2
ADD R5  R3, R4
ADD R7  R2, R6 F D E R W
ADD R10  R8, R9
MUL R11  R7, R10
ADD R5  R5, R11
 Assume ADD (4 cycle execute), MUL (6 cycle execute)
 Assume one adder and one multiplier
 How many cycles
 in a non-pipelined machine
 in an in-order-dispatch pipelined machine with reorder
buffer (and full forwarding)
 in an out-of-order dispatch pipelined machine with reorder
buffer (full forwarding)
128

Out-of-Order Execution with Precise Exceptions
 Idea: Use a reorder buffer to reorder instructions before
committing them to architectural state
 An instruction updates the RAT when it completes
execution
 Also called frontend register file
 An instruction updates a separate architectural register
file when it retires
 i.e., when it is the oldest in the machine and has completed
execution
 In other words, the architectural register file is always
updated in program order
 On an exception: flush pipeline, copy architectural register
file into frontend register file
129

ROB Architectural Register File
תינכתה רדס יפל ןכדעתמ דימת
תכפוה הארוהה רשאכ
רתויב הקיתוה תויהל
ROB -המ תרבעומ איה
ARF-ל
Frontend RF, used for renaming
,הרוטקטיכראורקימ ןיטולחל הז
תנכתמה י"ע הארנ אל רמולכ

הגירח שי רשאכ
תוריעצה תוארוהה תקיחמ
ןכותה תקיחמ
RS-ב
Fronend RF:
Register Alias Table
RAT -ה לא ARF -ה תקתעה

Out-of-Order Execution with Precise Exceptions
TAG and VALUE Broadcast Bus ROB
RS
בצמה ןוכדע
ינוטקטיכראה
S
Integer add R רדס יפל
C E תינכתה
E
H Integer mul
O
E E E E
F D E
R W
FP mul
D
D
E E E E E E E E
U
E
. . .
L
E E E E E E E E R
E
Load/store
in order out of order in order
 Hump 1: Reservation stations (scheduling window)
 Hump 2: Reordering (reorder buffer, aka instruction
window or active window)
132

Modern OoO Execution w/ Precise Exceptions
 Most modern processors use
 Reorder buffer to support in-order retirement of instructions
 A single register file to store registers (speculative and
architectural) – INT and FP are still separate
 Future register map  used for renaming
 Architectural register map  used for state recovery
133

An Example from Modern
Processors
Boggs et al., “The Microarchitecture of the Pentium 4
Processor,” Intel Technology Journal, 2001. 135

Enabling OoO Execution, Revisited
1. Link the consumer of a value to the producer
 Register renaming: Associate a “tag” with each data value
2. Buffer instructions until they are ready
 Insert instruction into reservation stations after renaming
3. Keep track of readiness of source values of an instruction
 Broadcast the “tag” when the value is produced
 Instructions compare their “source tags” to the broadcast
tag  if match, source value becomes ready
4. When all source values of an instruction are ready,
dispatch the instruction to functional unit (FU)
 Wakeup and select/schedule the instruction
136

Summary of OoO Execution Concepts
 Register renaming eliminates false dependencies, enables
linking of producer to consumers
ןיבל ”ןרציה“ ןיב רושקל רשפאמו תומודמ תויולת םילעמ םירטסיגר לש םש יוניש
"ןכרצה“
 Buffering enables the pipeline to move for independent ops
ןיילפייפב תויולת יתלב תוארוה םדקל רשפאמ רפאבב שומיש
 Tag broadcast enables communication (of readiness of
produced value) between instructions
תוארוהה ןיב ובשוחש םיכרעה תונכומ תודוא תרושקת רשפאמ םיגתה רודיש
 Wakeup and select enables out-of-order dispatch
רדסה י"פע אלש םויס רשפאמ הארוהה תריחבו תוררועתהה ןונגנמ
137

OoO Execution: Restricted Dataflow
 An out-of-order engine dynamically builds the dataflow
graph of a piece of the program
!שדח גשומ
 which piece?
 The dataflow graph is limited to the instruction
window
 Instruction window: all decoded but not yet retired
instructions
 Can we do it for the whole program?
 Why would we like to?
 In other words, how can we have a large instruction
window?
 Can we do it efficiently with Tomasulo’s algorithm? 138

How we do that in MIPS
(next 6 slides)
139

Simple integer MIPS
int.
ALU
int. Data
PC IR
GPR Mem
Inst.
Mem
Integer instruction only that are issued in-order
Execute in-order and completed in-order (5 CKs for all inst.)

MIPS with FP pipeline
int.
ALU
int. Data
PC IR
GPR Mem
Inst.
Mem
FP Adder
FP
GPR
FP Mutltiplier
Integer & FP instruction are issued in-order
Dif. In length causes Out-Of-Order completion

היצמינאX2
MIPS with Tomasulo style ILP
int.
ALU
int. Data
PC IR
GPR Mem
Inst.
Mem
FP CDB
store load
GPR queue queue
Here we have
Several Functional
RS1 +
Units (adders,
FU1
Multipliers, etc.)
that are fed whenever FP inst.
RS2 +
a new FP instruction is queue
FU2
fetched.
The units work in RS3 +
FU3
parallel and handle
data dependence on
their own.
FP path is separated from Integer path and uses
OOO execution and completion

היצמינא x4
MIPS with speculative Tomasulo ILP
int.
ALU
int. Data
PC IR
GPR Mem
Inst.
ROB
address
Mem
wr data
Fwd from ROB
CDB
FP Dotted lines
We connected the
stand for
integer path & the FP GPR
RS1 + FU1
FWD paths
path to the ROB.
In red we see the
Fwd in loads
issue of int & FP
FP+int+lw+sw
instructions. In black, RS2 +
inst. queue
FU2
we see their
Note: we use the int
execution. In green
ALU for address
We see the write RS3 +
FU3 calculations
result. In blue we see
(i.e., no special Load
the commit, i.e., copy
or Store units)
to GPRs or to Data
Mem Here we have in-order issue of FP & Int instructions,
OOO execution and write result, but in-order completion

Questions to Ponder
 Why is OoO execution beneficial?
 What if all operations take a single cycle?
 Latency tolerance: OoO execution tolerates the latency of
multi-cycle operations by executing independent
operations concurrently
 What if an instruction takes 1000 cycles?
 How large of an instruction window do we need to
continue decoding?
 How many cycles of latency can OoO tolerate?
 What limits the latency tolerance scalability of Tomasulo’s
algorithm?
 Instruction window size: how many decoded but not yet
retired instructions you can keep in the machine.
144

General Organization of an OoO Processor
A single FP
register file
RS
A single INT
register file
ROB
 Smith and Sohi, “The Microarchitecture of Superscalar Processors,” Proc. IEEE, Dec.
1995.
145

A Modern OoO Design: Intel
Pentium 4
Reservation stations
Functional units
Streaming
SIMD
Extensions
146
Boggs et al., “The Microarchitecture of the Pentium 4 Processor,” Intel Technology Journal, 2001.

Intel Pentium 4 Simplified
RS
Mutlu+, “Runahead Execution,”
HPCA 2003. Execution units
147

Alpha 21264
RS
148
Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro, March-April 1999.

Alpha 21264
Compaq Alpha Server

MIPS R10000
RS
RF FU
150
Yeager, “The MIPS R10000 Superscalar Microprocessor,” IEEE Micro, April 1996

MIPS R10000

IBM POWER 4 - 17 stages pipeline
Tendler et al., “POWER4 system microarchitecture,” IBM J R&D, 2002.
F = instruction fetch, IC = instruction cache, BP = branch predict, D0 = decode stage
0, Xfer = transfer, GD = group dispatch, MP = mapping, ISS = instruction issue, RF = register file read, EX =
execute, EA = compute address, DC = data caches, F6 = six-cycle floating-point execution pipe, Fmt = data
format, WB = write back, and CP = group commit

IBM POWER4
 2 cores, out-of-order execution
 100-entry instruction window in each core
 8-wide instruction fetch, issue, execute
 Large, local+global hybrid branch predictor
 1.5MB, 8-way L2 cache
153

IBM POWER5 – 12 pipeline stages
 Kalla et al., “IBM Power5 Chip: A Dual-Core Multithreaded Processor,” IEEE
Micro 2004.
RS
ROB
SMT: 2 threads
154

FreeSS
!שדח רוטלומיס
WCAE'25 - Workshop on Computer Architecture
Education, June 21--25, 2025, Tokyo, Japan
paper:https://arxiv.org/abs/2506.07665
code:
https://github.com/robgiorgi/freess
note to self:
on my laptop:
/home/telzur/science/Teaching/CPU/SW/freess

RIDECORE: RIsc-v Dynamic Exection CORE
RIDECORE (RIsc-v Dynamic Execution CORE) is an Out-of-Order
processor written in Verilog HDL. RIDECORE implements RISC-V
and its microarchitecture is based on "Modern Processor Design:
Fundamentals of Superscalar Processors". RIDECORE can also be
implemented on an FPGA.
RIDECORE's microarchitecture is based on "Modern Processor Design: Fundamentals of Superscalar Processors"
https://github.com/ridecore/ridecore/tree/master

The Berkeley Out-of-Order Machine (BOOM)
https://docs.boom-core.org/en/latest/sections/intro-overview/boom.html

The Berkeley Out-of-Order Machine (BOOM)
https://docs.boom-core.org/en/latest/sections/intro-overview/boom.html
Guy> # pipeline stages is configurable. Usually ~12
• Fetch can be ~4 cycles (PC select, icache hit/miss)
• Decode may be multiple
• Rename often 1-2 stage
• Issue can be split
• Execute spans multiple functional units
• Writeback may have multiple
• Commit (retire) also has internal stages

ההררששעעהה
NaxRiscv https://github.com/SpinalHDL/NaxRiscv
●
Out of order execution with register renaming
Superscalar (ex : 2 decode, 3 execution units, 2 retire)
RIDECORE (RISC-V Dynamic Execution CORE) – already mentioned
●
an Out-of-Order processor written in Verilog HDL,
https://github.com/ridecore/ridecore/tree/master
RSD is a 32-bit RISC-V out-of-order superscalar processor core,
●
https://github.com/rsd-devel/rsd/tree/master

NaxRiscv

Handling Out-of-Order
Execution
of Loads and Stores
ןןאאככ דדעע

Registers versus Memory
 So far, we considered mainly registers as part of state
 What about memory?
 What are the fundamental differences between
registers and memory?
 Register dependences known statically – memory
dependences determined dynamically
 Register state is small – memory state is large
 Register state is not visible to other threads/processors –
memory state is shared between threads/processors (in a
shared memory multiprocessor)
162

Memory Dependence Handling (I)
 Need to obey memory dependences in an out-of-order
machine
 and need to do so while providing high performance
 Observation and Problem: Memory address is not known
until a load/store executes
 Corollary 1: Renaming memory addresses is difficult
 Corollary 2: Determining dependence or independence of
loads/stores has to be handled after their (partial)
execution
 Corollary 3: When a load/store has its address ready, there
may be older/younger stores/loads with unknown
addresses in the machine
163

Memory Dependence Handling (II)
 When do you schedule a load instruction in an OOO
engine?
 Problem: A younger load can have its address ready before
an older store’s address is known
 Known as the memory disambiguation problem or the
unknown address problem
 Approaches
 Conservative: Stall the load until all previous stores have
computed their addresses (or even retired from the
machine)
 Aggressive: Assume load is independent of unknown-
address stores and schedule the load right away
 Intelligent: Predict (with a more sophisticated predictor) if
the load is dependent on any unknown address store 164

Handling of Store-Load Dependences
 A load’s dependence status is not known until all previous store
addresses are available.
 How does the OOO engine detect dependence of a load instruction
on a previous store?
 Option 1: Wait until all previous stores committed (no need to
check for address match)
 Option 2: Keep a list of pending stores in a store buffer and
check whether load address matches a previous store address
 How does the OOO engine treat the scheduling of a load
instruction wrt previous stores?
 Option 1: Assume load dependent on all previous stores
 Option 2: Assume load independent of all previous stores
 Option 3: Predict the dependence of a load on an outstanding
store
165

Memory Disambiguation (I)
 Option 1: Assume load is dependent on all previous
stores
+ No need for recovery
-- Too conservative: delays independent loads unnecessarily
 Option 2: Assume load is independent of all previous
stores
+ Simple and can be common case: no delay for independent loads
-- Requires recovery and re-execution of load and dependents on
misprediction
 Option 3: Predict the dependence of a load on an
outstanding store
+ More accurate. Load store dependencies persist over time
-- Still requires recovery/re-execution on misprediction
 Alpha 21264 : Initially assume load independent, delay loads found to be 166
dependent
 Moshovos et al., “Dynamic speculation and synchronization of data
dependences,” ISCA 1997.
 Chrysos and Emer, “Memory Dependence Prediction Using Store Sets,” ISCA 1998.

Memory Disambiguation (II)
 Chrysos and Emer, “Memory Dependence Prediction Using
Store Sets,” ISCA 1998.
167

Memory Disambiguation (II)
 Chrysos and Emer, “Memory Dependence Prediction Using
Store Sets,” ISCA 1998.
 Predicting store-load dependencies important for
performance
 Simple predictors (based on past history) can achieve most of
the potential performance
168

Data Forwarding Between Stores and Loads
 We cannot update memory out of program order
 Need to buffer all store and load instructions in instruction
window
 Even if we know all addresses of past stores when we
generate the address of a load, two questions still remain:
1. How do we check whether or not it is dependent on a store
2. How do we forward data to the load if it is dependent on a
store
 Modern processors use a LQ (load queue) and a SQ for
this
 Can be combined or separate between loads and stores
 A load searches the SQ after it computes its address. Why?
169
 A store searches the LQ after it computes its address. Why?

Out-of-Order Completion of Memory Ops
 When a store instruction finishes execution, it writes its
address and data in its reorder buffer entry (or SQ entry)
 When a later load instruction generates its address, it:
 searches the SQ with its address
 accesses memory with its address
 receives the value from the youngest older instruction that
wrote to that address (either from ROB or memory)
 This is a complicated “search logic” implemented as a
Content Addressable Memory
 Content is “memory address” (but also need size and age)
 Called store-to-load forwarding logic
170

Store-Load Forwarding Complexity
 Content Addressable Search (based on Load Address)
 Range Search (based on Address and Size of both the
Load and earlier Stores)
 Age-Based Search (for last written values)
 Load data can come from a combination of multiple
places
 One or more stores in the Store Buffer (SQ)
 Memory/cache
171

Step by step for
Dynamic Scheduling by reorder
buffer
(13 slides)
Copyright by
John Kubiatowicz (http.cs.berkeley.edu/~kubitron)

היצמינא
Four Steps of Speculative Tomasulo Algorithm
:תרוכזת
1. Issue—get instruction from FP Op Queue
– If reservation station and reorder buffer slot free, issue instr & send operands
& reorder buffer no. for destination (this stage sometimes called “dispatch”)
2. Execution—operate on operands (EX)
– When both operands ready then execute; if not ready, watch CDB for result;
when both in reservation station, execute; checks RAW (sometimes called
“issue”)
3. Write result—finish execution (WB)
– Write on Common Data Bus to all awaiting FUs & reorder buffer; mark
reservation station available.
4. Commit—update register with reorder result
– When instr. at head of reorder buffer & result present, update register with
result (or store to memory) and remove instr from reorder buffer.
– Mispredicted branch or interrupt flushes reorder buffer (sometimes called
“graduation”)

Tomasulo With Reorder buffer:
Done?
FP Op
ROB7 Newest
Queue
ROB6
ROB5
Reorder Buffer ROB4
ROB3
ROB2 Oldest
F0 LD F0,10(R2) N
F0 LD F0,10(R2) N ROB1
Registers
To
Memory
Dest
Dest from
Memory
Dest
Reservation 1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op
ROB7 Newest
Queue
ROB6
ROB5
Reorder Buffer ROB4
ROB3
F10 ADDD F10,F4,F0 N
F10 ADDD F10,F4,F0 N ROB2 Oldest
F0 LD F0,10(R2) N
F0 LD F0,10(R2) N ROB1
Registers
To
Memory
Dest
Dest from
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
Dest
Reservation 1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op ROB7
Newest
Queue
ROB6
ROB5
Reorder Buffer ROB4
| F2  | DIVD F2,F10,F6 | N      |        |
| --- | -------------- | ------ | ------ |
| F2  | DIVD F2,F10,F6 | N ROB3 |        |
| F10 | ADDD F10,F4,F0 | N      |        |
| F10 | ADDD F10,F4,F0 | N ROB2 | Oldest |
| F0  | LD F0,10(R2)   | N      |        |
| F0  | LD F0,10(R2)   | N ROB1 |        |
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
3 DIVD ROB2,R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op ROB7
Newest
Queue
| F0  | ADDD F0,F4,F6 | N ROB6 |     |
| --- | ------------- | ------ | --- |
| F0  | ADDD F0,F4,F6 | N      |     |
| F4  | LD F4,0(R3)   | N ROB5 |     |
| F4  | LD F4,0(R3)   | N      |     |
| --  | BNE F2,<…>    | N      |     |
Reorder Buffer ROB4
| --  | BNE F2,<…>     | N      |        |
| --- | -------------- | ------ | ------ |
| F2  | DIVD F2,F10,F6 | N      |        |
| F2  | DIVD F2,F10,F6 | N ROB3 |        |
| F10 | ADDD F10,F4,F0 | N      |        |
| F10 | ADDD F10,F4,F0 | N ROB2 | Oldest |
| F0  | LD F0,10(R2)   | N      |        |
| F0  | LD F0,10(R2)   | N ROB1 |        |
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
6 ADDD ROB5, R(F6) 3 DIVD ROB2,R(F6)
6 ADDD ROB5, R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations 6  0+R3
6  0+R3
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op ROB7
| --  | ROB5 | ST 0(R3),F4 | N   | Newest |
| --- | ---- | ----------- | --- | ------ |
| --  | ROB5 | ST 0(R3),F4 | N   |        |
Queue
| F0  |     | ADDD F0,F4,F6 | N ROB6 |     |
| --- | --- | ------------- | ------ | --- |
| F0  |     | ADDD F0,F4,F6 | N      |     |
| F4  |     | LD F4,0(R3)   | N ROB5 |     |
| F4  |     | LD F4,0(R3)   | N      |     |
| --  |     | BNE F2,<…>    | N      |     |
Reorder Buffer ROB4
| --  |     | BNE F2,<…>     | N      |        |
| --- | --- | -------------- | ------ | ------ |
| F2  |     | DIVD F2,F10,F6 | N      |        |
| F2  |     | DIVD F2,F10,F6 | N ROB3 |        |
| F10 |     | ADDD F10,F4,F0 | N      |        |
| F10 |     | ADDD F10,F4,F0 | N ROB2 | Oldest |
| F0  |     | LD F0,10(R2)   | N      |        |
| F0  |     | LD F0,10(R2)   | N ROB1 |        |
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
6 ADDD ROB5, R(F6) 3 DIVD ROB2,R(F6)
6 ADDD ROB5, R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations 6  0+R3
6  0+R3
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op ROB7
| -- M[10] |       | ST 0(R3),F4 | Y   | Newest |
| -------- | ----- | ----------- | --- | ------ |
| --       | M[10] | ST 0(R3),F4 | Y   |        |
Queue
ROB6
| F0  |     | ADDD F0,F4,F6 | N   |     |
| --- | --- | ------------- | --- | --- |
| F0  |     | ADDD F0,F4,F6 | N   |     |
ROB5
| F4 M[10] |       | LD F4,0(R3) | Y   |     |
| -------- | ----- | ----------- | --- | --- |
| F4       | M[10] | LD F4,0(R3) | Y   |     |
| --       |       | BNE F2,<…>  | N   |     |
Reorder Buffer ROB4
| --  |     | BNE F2,<…>     | N      |        |
| --- | --- | -------------- | ------ | ------ |
| F2  |     | DIVD F2,F10,F6 | N      |        |
| F2  |     | DIVD F2,F10,F6 | N ROB3 |        |
| F10 |     | ADDD F10,F4,F0 | N      |        |
| F10 |     | ADDD F10,F4,F0 | N ROB2 | Oldest |
| F0  |     | LD F0,10(R2)   | N      |        |
| F0  |     | LD F0,10(R2)   | N ROB1 |        |
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
6 ADDD M[10],R(F6) 3 DIVD ROB2,R(F6)
6 ADDD M[10],R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

Tomasulo With Reorder buffer:
Done?
FP Op ROB7
| -- M[10] | ST 0(R3),F4 | Y   | Newest |
| -------- | ----------- | --- | ------ |
| -- M[10] | ST 0(R3),F4 | Y   |        |
Queue
ROB6
| F0 --- | ADDD F0,F4,F6 | Ex  |     |
| ------ | ------------- | --- | --- |
| F0 --- | ADDD F0,F4,F6 | Ex  |     |
ROB5
| F4 M[10] | LD F4,0(R3) | Y   |     |
| -------- | ----------- | --- | --- |
| F4 M[10] | LD F4,0(R3) | Y   |     |
| --       | BNE F2,<…>  | N   |     |
Reorder Buffer ROB4
| --  | BNE F2,<…>     | N      |        |
| --- | -------------- | ------ | ------ |
| F2  | DIVD F2,F10,F6 | N      |        |
| F2  | DIVD F2,F10,F6 | N ROB3 |        |
| F10 | ADDD F10,F4,F0 | N      |        |
| F10 | ADDD F10,F4,F0 | N ROB2 | Oldest |
| F0  | LD F0,10(R2)   | N      |        |
| F0  | LD F0,10(R2)   | N ROB1 |        |
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
3 DIVD ROB2,R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

היצמינא
Tomasulo With Reorder buffer:
Done?
FP Op ROB7
| -- M[10] | ST 0(R3),F4 | Y   | Newest |
| -------- | ----------- | --- | ------ |
| -- M[10] | ST 0(R3),F4 | Y   |        |
Queue
ROB6
| F0 --- | ADDD F0,F4,F6 | Ex  |     |
| ------ | ------------- | --- | --- |
| F0 --- | ADDD F0,F4,F6 | Ex  |     |
ROB5
| F4 M[10] | LD F4,0(R3) | Y   |     |
| -------- | ----------- | --- | --- |
| F4 M[10] | LD F4,0(R3) | Y   |     |
| --       | BNE F2,<…>  | N   |     |
Reorder Buffer ROB4
| --  | BNE F2,<…>     | N      |        |
| --- | -------------- | ------ | ------ |
| F2  | DIVD F2,F10,F6 | N      |        |
| F2  | DIVD F2,F10,F6 | N ROB3 |        |
| F10 | ADDD F10,F4,F0 | N      |        |
| F10 | ADDD F10,F4,F0 | N ROB2 | Oldest |
What about memory
| F0  | LD F0,10(R2) | N      |     |
| --- | ------------ | ------ | --- |
| F0  | LD F0,10(R2) | N ROB1 |     |
hazards???
Registers
To
Memory
Dest
from
Dest
2 ADDD R(F4),ROB1 Memory
2 ADDD R(F4),ROB1
3 DIVD ROB2,R(F6)
3 DIVD ROB2,R(F6)
Dest
Reservation  1 10+R2
1 10+R2
Stations
FP adders FP multipliers
FP adders FP multipliers

Memory Disambiguation: Handling RAW Hazards in memory
היצמינא
Question: Given a load that follows a store in program order, are the two
related?
– (Alternatively: is there a RAW hazard between the store and the load)?
Eg: st 0(R2),R5
ld R6,0(R3)
Can we go ahead and start the load early?
– Store address could be delayed for a long time by some calculation
that leads to R2 (divide?).
– We might want to issue/begin execution of both operations in same
cycle.
Two techiques:
• No Speculation: we are not allowed to start load until we know for sure
that address 0(R2)  0(R3)
• Speculation: We might guess at whether or not they are dependent
(called “dependence speculation”) and use reorder buffer to fixup if
we are wrong.

היצמינא
Hardware Support for Memory Disambiguation
Need buffer to keep track of all outstanding stores to
memory, in program order.
–
Keep track of address (when becomes available) and value
(when becomes available)
–
FIFO ordering: will retire stores from this buffer in program
order
When issuing a load, record current head of store queue
(know which stores are ahead of you).
When have address for load, check store queue:
–
If any store prior to load is waiting for its address, stall load.
–
If load address matches earlier store address (associative
lookup), then we have a memory-induced RAW hazard:
• store value available  return value
• store value not available  return ROB number of source
–
Otherwise, send out request to memory
Actual stores commit in order, so no worry about
WAR/WAW hazards through memory.

Memory Disambiguation:
Done?
FP Op ROB7
Newest
Queue
ROB6
ROB5
| --  | LD F4, 10(R3) | N   |     |
| --- | ------------- | --- | --- |
Reorder Buffer ROB4
| --         | LD F4, 10(R3)  | N      |        |
| ---------- | -------------- | ------ | ------ |
| F2         | ST 10(R3), F5  | N      |        |
| F2         | ST 10(R3), F5  | N ROB3 |        |
| F0         | LD F0,32(R2)   | N      |        |
| F0         | LD F0,32(R2)   | N ROB2 | Oldest |
| -- <val 1> | ST 0(R3), F4   | Y      |        |
| -- <val 1> | ST 0(R3), F4   | Y ROB1 |        |
Registers
To
Memory
Dest
from
Dest
Memory
Dest
Reservation  2 32+R2
2 32+R2
Stations 4 ROB3
4 ROB3
FP adders FP multipliers
FP adders FP multipliers

לע הרימש ךות תויופעתסה יוזיח
היגרנאב ןוכסח
.8991 ACSI
”,noitcudeR
ygrenE
rof
lortnoC
noitalucepS
:gnitaG
enilepiP“
,.la
te
ennaM

וז תגצמ ןאכ דע