361.1.4201
Computer Architecture
Branch Prediction I
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
With Dr. Guy Tel-Zur & Danny Seidner modifications
Last update: 20/5/2021, 2/6/2022, 30/4/2023, 28/6/2024, 30/5/2026

Control Dependence
Handling
2

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence
Handling, State Maintenance and Recovery, …
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, … 3

Readings for Next Few Lectures (I)
 Guy: P&H CO&D, Chapter 4 – “The Processor”
 Guy: H&P CAQA, Appendix C - "Pipelining: Basic and
Intermediate Concepts"
 Smith and Sohi, “The Microarchitecture of Superscalar
Processors,” Proceedings of the IEEE, 1995
 More advanced pipelining
 Interrupt and exception handling
 Out-of-order and superscalar execution concepts
 McFarling, “Combining Branch Predictors,” DEC WRL
Technical Report, 1993.
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro
1999.
4

Readings for Next Few Lectures
:הדרוהל תבותכ
ftp://ftp.cs.wisc.edu/sohi/papers/1995/ieee-proc.superscalar.pdf
Gurindar S. Sohi
James Smith
5

רמאמה ריצקת
Abstract - ילש ןה תושגדהה
Superscalar processing is the latest in a long series of innovations aimed at producing
ever-faster microprocessors.
By exploiting instruction-level parallelism, superscalar processors are capable of
executing more than one instruction in a clock cycle. This paper discusses the
microarchitecture of superscalar processors. We begin with a discussion of the
general problem solved by superscalar processors: converting an ostensibly sequential
program into a more parallel one. The principles underlying this process, and the
constraints that must be met, are discussed.
The paper then provides a description of the specific implementation techniques used in
the important phases of superscalar processing. The major phases include: i) instruction
fetching and conditional branch processing, ii) the determination of data dependences
involving register values, iii) the initiation, or issuing, of instructions for parallel execution,
iv) the communication of data values through memory via loads and stores, and v)
committing the process state in correct order so that precise interrupts can be
supported.
Examples of recent superscalar microprocessors,
the MIPS R10000, the DEC 21164, and the AMD K5 are used to illustrate a variety of
superscalar methods.

ריצקתה םוגרת
רצייל םתרטמש םישודיח לש הכורא הרדסב ןורחאה אוה ירלקס-רפוס דוביע
.רתויו רתוי םיריהמ םידבעמ-ורקימ
םילגוסמ םיירלקס-רפוס םידבעמ ,תוארוה תמרב תויליבקמ לוצינ ידי לע
הרוטקטיכרא-ורקימב ןד הז רמאמ .ןועש רוזחמב תחא הארוהמ רתוי עצבל
תרתפנה תיללכה היעבב ןוידב םיליחתמ ונא .םיירלקס-רפוס םידבעמ לש
תינכותל הפיצר הרואכל תינכות תרמה :םיירלקס-רפוס םידבעמ ידי לע
שיש םיצוליאהו הז ךילהת סיסבב םידמועה תונורקעה .רתוי הליבקמ
.םינודנ ,םהב דומעל
תושמשמה תויפיצפסה םושייה תוקינכט לש רואית קפסמ רמאמה ,ןכמ רחאל
)i :םיללוכ םיירקיעה םיבלשה .ירלקס-רפוס דוביע לש םיבושחה םיבלשב
יכרע תללוכה םינותנ תולת תעיבק )ii ,הנתומ םיפנע דוביעו תוארוה רוזחא
יכרע תרושקת )iv ,ליבקמ עוציבל תוארוה לש הקפנה וא םוזיי )iii ,רגוא
ךילהתה בצמ עוציב )v-ו ,םינסחאמו תוניעט תועצמאב ןורכיז ךרד םינותנ
.תוקיודמ תוקיספב ךומתל היהי ןתינש ךכ ןוכנה רדסב

Readings for Next Few Lectures (II)
Smith and Plezskun, “Implementing Precise Interrupts in
Pipelined Processors,” IEEE Trans on Computers 1988
(earlier version in ISCA 1985).
8

Recap of Last Lecture
 Data Dependence Handling
 Data Forwarding/Bypassing
 In-depth Implementation
 MIPS Pipelining
 Register dependence analysis
 Stalling
 Performance analysis with and without forwarding
 Questions to Ponder
 HW vs. SW handling of data dependences
 Static versus dynamic scheduling
 What makes compiler based instruction scheduling difficult?
 Profiling (representative input sets needed; dynamic adaptation difficult) –
demo: see next slide
Introduction to static instruction scheduling (e.g., fix-up code)
9

Control Dependence
Handling
10

Review: Control Dependence
 Question: What should the fetch PC be in the next cycle?
 Answer: The address of the next instruction
 All instructions are control dependent on previous ones. Why?
 If the fetched instruction is a non-control-flow instruction:
 Next Fetch PC is the address of the next-sequential instruction
 Easy to determine if we know the size of the fetched
instruction
 If the instruction that is fetched is a control-flow
instruction:
 How do we determine the next Fetch PC?
 In fact, how do we even know whether or not the fetched
instruction is a control-flow instruction?
11

Branch Types
Number of
|      | Direction at fetch  |                | When is next fetch  |
| ---- | ------------------- | -------------- | ------------------- |
| Type |                     | possible next  |                     |
|      | time                |                | address resolved?   |
fetch addresses?
| Conditional  |         |     | Execution (register  |
| ------------ | ------- | --- | -------------------- |
|              | Unknown | 2   |                      |
| (beq, bne)   |         |     | dependent)           |
Unconditional
|     | Always taken | 1   | Decode (PC + offset) |
| --- | ------------ | --- | -------------------- |
(j)
| Call  (jal) | Always taken | 1   | Decode(PC + offset) |
| ----------- | ------------ | --- | ------------------- |
Execution (register
| Return   (jr) | Always taken | Many |     |
| ------------- | ------------ | ---- | --- |
dependent)
Execution (register
| Indirect  (jr) | Always taken | Many |     |
| -------------- | ------------ | ---- | --- |
dependent)
Different branch types are being handled differently
12

How to Handle Control Dependences
 Critical to keep the pipeline full with correct sequence of
dynamic instructions.
 Potential solutions if the instruction is a control-flow
instruction: :םיירשפא תונורתפ השיש
בוט אל ןורתפ
 Stall the pipeline until we know the next fetch address
 Guess the next fetch address (branch prediction) H/W
 Employ delayed branching (branch delay slot) S/W
 Do something else (fine-grained multithreading)
 Eliminate control-flow instructions (predicated
execution)
 Fetch from both possible paths (if you know the
addresses of both possible paths) (multipath execution)
2 -ב דקמתנ ךשמהבו 3-6 ,1 תונורתפה תא הרצקב ראתנ
13

 Stall Fetch Until Next PC is Available: Good Idea?
 תויופעתסה לש הרדיס תיארנ ףקשב .םדוקה ףקשהמ הנושארה תורשפאה
.תונתומ יתלב
היצמינא
|     | ttttttt | ttttttt |     | ttttttt | ttttttt |     | ttttttt | ttttttt |     |
| --- | ------- | ------- | --- | ------- | ------- | --- | ------- | ------- | --- |
|     | 0000000 | 1111111 |     | 2222222 | 3333333 |     | 4444444 | 5555555 |     |
IIIIIIInnnnnnnsssssssttttttt
|     | IIIIIIIFFFFFFF | IIIIIIDDDDDD | AAAAALLLLLUUUUU | MMMMEEEEMMMM |     | WWWBBB |     |     |     |
| --- | -------------- | ------------ | --------------- | ------------ | --- | ------ | --- | --- | --- |
hhhhhhh
IIIIIIInnnnnnnsssssssttttttt
|     |     | IIIIIIFFFFFF |     | IIIIIFFFFF | IIIIDDDD | AAALLLUUU | MMEEMM |     | WB  |
| --- | --- | ------------ | --- | ---------- | -------- | --------- | ------ | --- | --- |
iiiiiii
| IIIIIIInnnnnnnsssssssttttttt |     |     |     |     | IIIIFFFF |     | IIIFFF | IIDD | ALU |
| ---------------------------- | --- | --- | --- | --- | -------- | --- | ------ | ---- | --- |
jjjjjjj
| IIIIIIInnnnnnnsssssssttttttt |     |     |     |     |     |     |     | IIFF | IF  |
| ---------------------------- | --- | --- | --- | --- | --- | --- | --- | ---- | --- |
kkkkkkk
IIIIIIInnnnnnnsssssssttttttt
 ליגרה הרקמב
lllllll
 תעדל לוכי ינא
 לוכי ינא תופעתסה לש הרקמב
 יכ PC ה תא
 ןכלו ID רחאל קר PC תא עובקל
יתרדיס אוה
)bubble( העוב תסנכנ
This is the case with non-control-flow and unconditional br instructions!
14

How to Handle Control Dependences
 Critical to keep the pipeline full with correct sequence of
dynamic instructions.
 Potential solutions if the instruction is a control-flow
instruction:
 Stall the pipeline until we know the next fetch address
אל ןורתפ
 Guess the next fetch address (branch prediction)
בוט
 Employ delayed branching (branch delay slot)
ךכ לע רבדנ
 Do something else (fine-grained multithreading)
אבה קרפב
 Eliminate control-flow instructions (predicated
execution)
 Fetch from both possible paths (if you know the
addresses of both possible paths) (multipath execution)
15

Doing Better than Stalling Fetch …
 Rather than waiting for true-dependence on PC to resolve, just guess nextPC =
PC+4 to keep fetching every cycle
PC+4 דימת חינהל :יסיסב יכה גוסהמ תיזחת
Is this a good guess?
What do you lose if you guessed incorrectly?
 ~20% of the instruction mix is control flow
 ~50 % of “forward” control flow (i.e., if-then-else) is taken
 ~90% of “backward” control flow (i.e., loop back) is taken Not Take ==>
next PC =
Overall, typically ~70% taken and ~30% not taken
PC+4
[Lee and Smith, 1984]
 Expect “nextPC = PC+4” ~86% of the time, but what about the remaining 14%?
80% + 20%*30% = 86%, 100%-86% = 14% רבסה
16

Guessing NextPC = PC + 4
 Always predict the next sequential instruction is the next
instruction to be executed
 This is a form of next fetch address prediction (and
branch prediction)
 How can you make this more effective?
 Idea: Maximize the chances that the next sequential
instruction is the next instruction to be executed
 Software: Lay out the control flow graph such that the
“likely next instruction” is on the not-taken path of a branch
 Profile guided code positioning  Pettis & Hansen, PLDI
ףקשה
אבה 1990.
 Hardware: ??? (how can you do this in hardware…)
 Cache traces of executed instructions  Trace cache
17

Adjust code according to profiling - SW
היצמינא
| Compiler profile: |     |     | Option I:      | Option II:      |
| ----------------- | --- | --- | -------------- | --------------- |
|                   |     |     | A;             | A;              |
|                   |     |     | if (x)  { B }  | if (!x)  { C }  |
A;
|       |     |         | else  {C}; | else  {B}; |
| ----- | --- | ------- | ---------- | ---------- |
|       |     |         | D;         | D;         |
| (99%) | T   | NT (1%) |            |            |
x
?
|     |     |     | A;  | A;  |
| --- | --- | --- | --- | --- |
|     |     |     | C;  | B;  |
| B;  |     | C;  |     |     |
|     |     |     | D;  | D;  |
דוקה ןוגרא
ךכ יתרדיסה
ףיצר היהיש
D;
ההובג תוריבסב
|     |     |     | B;  | C;  |
| --- | --- | --- | --- | --- |
Option II is better since in 99% of the cases NT is PC+4:

Trace Cache (adjust by HW)
קולב לכב תוארוה 5 חיננ
A B D
תוארוה 15 כ"הס
5 5 5
עצובמש המ .traces - תובקעה תא רמוש ןומטמה
A B D
.ןומטמב םג תיתרדיס בתכי םג תיתרדיס
Trace cache הדוקפה לש (prediction) שוחינל וב שמתשנ
.(PC-ב אבה ךרעה) האבה
לפטל םגו) אבה PC-המ ץוח תודש דוע ךירצ
.(תועטב
לוכי ןומטמה ,תינכתה ךשמהב יוניש לוחי םא
A C D
לופיטהמ קלח םג הז) .ונכות תא תונשלו לגתסהל
(תועטב
התע .ןורכיזל בתוכה רלייפמוקה י"ע עצובמש הנכותב ןורתפ וניאר םדוקה ףקשב
.ןומטמב בתכנו הרמוחב אוה ןורתפה
.יתאצות ,ימניד ןורתפ והז ךכיפל - םייונישל לגתסהל לוכי Trace cache -ה
.4 םויטנפב ךכ עצבתמ

Trace Cache - read
https://en.wikipedia.org/wiki/Trace_cache :הידפיקוו ,ואר אנא
Trace Cache: a Low Latency
Approach to High Bandwidth
Instruction Fetching
by Rotenberg, Bemmett & Smith
http://www.eecs.harvard.edu/
cs146-246/micro.trace-cache.pdf

Pentium 4
Trace cache
Microcode
Source: Hinton et al, "The Microarchitecture of the Pentium 4
Processor", Intel Technology Journal Q1, 2001

רמאמה ךותמ
Note to self: /home/telzur/science/Teaching/CPU/lectures/09/extra_reading/Pentium4.pdf

Credi: http://www.chip-
architect.org/news/Northwood_13
0nm_die_text_1600x1200.jpg

Credit:
http://www.chip-architect.org/news/2003_03_06_
Intel's Prescott (2003) Looking_at_Intels_Prescott.html#(1)%20%20Inst
ruction%20Trace%20Cache%20Extended

Guessing NextPC = PC + 4 , more!
 How else can you make this more effective?
 Idea: Get rid of control flow instructions (or minimize
their occurrence)
 How?
= םיאנת דוחיא
1. Get rid of unnecessary control flow instructions 
combine predicates (predicate combining)
= תונתומ תודוקפ
2. Convert control dependences into data dependences 
predicated execution = שארמ עובק עוציב
This is actually #5 - Eliminate control-flow instructions
25

Predicate Combining (not Predicated Execution)
םיאנת דוחיא
 Complex predicates are converted into multiple branches
 if ((a == b) && (c < d) && (a > 5000)) { … }
 3 conditional branches
 Problem: This increases the number of control
dependencies אבה ףקשב רבסה
 Idea: Combine predicate operations to feed a single branch
instruction instead of having one branch for each
 Predicates stored and operated on using condition registers
 A single branch checks the value of the combined predicate
+ = Fewer branches in code  fewer mipredictions/stalls
-
= Possibly unnecessary work ןורסיחה
-- If the first predicate is false, no need to compute other predicates
 Condition registers exist in IBM RS6000 and the POWER architecture26

Predicate Combining
תבכרומ תופעתסהב ליעי אלה דוקה תשחמה
if (a != b) j X
ףקשה יאנתל לוקש
if (c>=d) j Y םדוקה
if (a<=5000) j Z
do A
.
.
X:
.
.
Y:
.
.
Z:

1) Predicate Combining – םיאנת דוחיא
If(x && y && z ) {A};
T NT
x
?
bit 0 of CondReg=x
bit 1 of CondReg=y
T NT bit 2 of CondReg=z
y
?
T NT
T NT
z CReg=7
?
A
A

היצמינא
2) Predicated Execution
הנתומ עוציב
 Idea: Convert control dependence to data dependence
 Simple example: Suppose we had a Conditional Move instruction…
 CMOV condition, R1  R2
If true R1=R2
 R1 = (condition == true) ? R2 : R1
If false then nop
 Employed in most modern ISAs (x86, Alpha, ARM)
תויופעתסה םילעהל ןתינ CMOV תארוה תועצמאב ןכל
 Code example with branches vs. CMOVs
if (a == 5) {b = 4;} else {b = 3;}
אללו ףצרב תועצבתמ תוארוהה לכ
CMPEQ condition, a, 5; PC -ב יוניש ןיא ןכל .תוציפק
CMOV condition, b  4;
CMOV !condition, b  3; 30

C# -ו C תופשב המגוד
Demo: /home/telzur/science/Teaching/CPU/lectures/09/code/predicate_exe

היצמינא
Predicate Execution
Instead of: We have:
CMPEQ condition, a, 5; CMPEQ condition, a, 5;
NT T
CMOV condition, b  4;
cond
MOV, b  3; MOV, b  4;
CMOV !condition, b  3;
ףילחת םיווהמ םיאבה םיפקשה :2: ןוכדע
ןאכ דוקל
Both CMOV instructions are executed,
Show a demo:
one of them becomes NOP
/home/telzur/science/Teaching/CPU/
lectures/09/code/predicate_exe

Let’s check with Compiler Explorer
X86 → 13 LOC
No branch!
branch!

Let’s check with Compiler Explorer
Old MIPS → 21 LOC
Branch!

Conditional execution

Predicated Execution - summary
 Eliminates branches  enables straight line code (i.e., larger basic
blocks in code)
 Advantages
 Always-not-taken prediction works better (no branches)
 Compiler has more freedom to optimize code (no branches)
 control flow does not hinder (עירפהל) inst. reordering optimizations
 code optimizations hindered only by data dependencies
 Disadvantages
 Useless work: some instructions fetched/executed but discarded
(especially bad for easy-to-predict branches)
 Requires additional ISA support
 )דוקה תלדגה( תויופעתסה לש בכרומ ףרג
 Q: Can we eliminate all branches this way?
36
A: No (loops….)

How to Handle Control Dependences
 Critical to keep the pipeline full with correct sequence of dyהnרaטmמiהc
instructions.
 Potential solutions if the instruction is a control-flow instruction:
:םיירשפא תונורתפ השיש
 Stall the pipeline until we know the next fetch address
 Guess the next fetch address (branch prediction)
תיחכונה האצרהה לש סוקופה הז
 Employ delayed branching (branch delay slot)
 Do something else (fine-grained multithreading)
 Eliminate control-flow instructions (predicated execution)
 Fetch from both possible paths (if you know the addresses of
both possible paths) (multipath execution)
37

Review: Guessing NextPC = PC + 4
 Always predict the next sequential instruction is the next
instruction to be executed
 This is a form of next fetch address prediction (and
branch prediction)
 How can you make this more effective?
 Idea: Maximize the chances that the next sequential
instruction is the next instruction to be executed
 Software: Lay out the control flow graph such that the
“likely next instruction” is on the not-taken path of a branch
 Profile guided code positioning  Pettis & Hansen, PLDI
1990.
 Hardware: ??? (how can you do this in hardware…)
 Cache traces of executed instructions  Trace cache
38

Review: Guessing Next PC = PC + 4
 How else can you make this more effective?
 Idea: Get rid of control flow instructions (or minimize their
occurrence)
 How?
1. Get rid of unnecessary control flow instructions 
predicate combining → condition registers
2. Convert control dependences into data dependences 
predicated execution
םימדוקה םיפקשב ונרביד רבכ הלא לע
39

Reducing number of branches
executed
Demo:
~/science/Teaching/CPU/lectures/09/code/loop_unrolling
רוציקל היבסה וזו ןומטמה םע ביטמ יונישהש ןכתי ,יונישהמ םינהנש םינקחש דוע שי :caution
תויופעתסהה םוצמיצ אלו הצירה ןמזב יטמרדה
Credit:
https://www.eecs.umich.edu/courses/eecs470/OLD/w14/lectures/470L17W14.pdf

How to Handle Control Dependences
היצמינא
 Critical to keep the pipeline full with correct sequence of
dynamic instructions.
 Potential solutions if the instruction is a control-flow
instruction:
 Stall the pipeline until we know the next fetch address
 Guess the next fetch address (branch prediction)
 Employ delayed branching (branch delay slot)
 Do something else (fine-grained multithreading)
 Eliminate control-flow instructions (predicated
execution)
 Fetch from both possible paths (if you know the
addresses of both possible paths) (multipath execution)
41

Delayed Branching (I)
 Change the semantics of a branch instruction
 Branch takes effect after N instructions (תידיימ הרוק אל)
 Or the branch takes effect after N cycles תמדוקל הלוקש הרימא וז
 Idea: Delay the execution of a branch. N instructions (delay
slots) that come after the branch are always executed
regardless of branch direction.
In MIPS N=1 (1 delay slot)
 Problem: How do you find instructions to fill the delay slots?
 Branch must be independent of delay slot instructions
 Unconditional branch: Easier to find instructions to fill the delay slot
 Conditional branch: Condition computation should not depend on
instructions in delay slots  difficult to fill the delay slot
42

היצמינא
Delayed Branching (II)
| Normal code: |     | Timeline: | Delayed branch code: |     | Timeline: |
| ------------ | --- | --------- | -------------------- | --- | --------- |
|              | A   |           |                      | A   |           |
if ex
if ex
|     | B   |     |     | C    |     |
| --- | --- | --- | --- | ---- | --- |
|     | C   | A   |     | BC X | A   |
|     |     | B A |     | B    | C A |
BC X
|     |     | C B |     | D   | BC C |
| --- | --- | --- | --- | --- | ---- |
D
|     |     |       |     | E    | B BC |
| --- | --- | ----- | --- | ---- | ---- |
|     | E   | BC C  |     |      |      |
|     | F   | -- BC |     | F    | G B  |
| X:  | G   | G --  |     | X: G |      |
5 cycles
6 cycles
 Branch-ה רחאל B תא ונרבעה .16.67% -ב םיעוציב רופיש
43

Fancy Delayed Branching (III)
 Delayed branch with squashing
In SPARC

 Semantics: If the branch falls through (i.e., it is not taken),
the delay slot instruction is not executed
|  Why could this help? |     |     |     |
| ---------------------- | --- | --- | --- |
Normal code: Delayed branch code: Delayed branch w/ squashing:
ךועמ
|     | X: A | X: A | A    |
| --- | ---- | ---- | ---- |
|     | B    | B    | X: B |
|     | C    | C    | C    |
|     | BC X | BC X | BC X |
delay slot  -ה יולימ
 branchה םא
|     | D   | NOP | A   |
| --- | --- | --- | --- |
 בשחנ חקליי
|     | E   | D   | D   |
| --- | --- | --- | --- |
 אל םאו A תא
ךעמי A
|  אלמל היונפ הארוה ןיא ןאכ |     | E   | E   |
| ------------------------- | --- | --- | --- |
delay slot -ה תא
האלול לש הרקמב בוט הז
MIPS לש ךרדה 44

Delayed Branching (IV)
 Advantages:
+ Keeps the pipeline full with useful instructions in a simple way assuming
1. Number of delay slots == number of instructions to keep the pipeline full
before the branch resolves ןיילפייפה יולימל יאנתה תא קפסל רתוי השק רתוי לודג ןיילפייפהש לככ ןכל(
(
2. All delay slots can be filled with useful instructions
 Disadvantages:
-- Not easy to fill the delay slots (even with a 2-stage pipeline)
1. Number of delay slots increases with pipeline depth, superscalar execution
width )ישעמ אל הזו 20-ל 10 ןיב ענ רפסמה ינכדע יתמצוע דבעמב(
2. Number of delay slots should be variable with variable latency operations.
Why?
-- Ties ISA semantics to hardware implementation
-- SPARC, MIPS, HP-PA: 1 delay slot (?םירכוז ,”הרוחא“ לכתסהל)
-- What if pipeline implementation changes with the next design?
בשחמה לש אבה רודב הנתשמ שומימה םא שדחמ לפמקל ךירצ 45

An Aside: Filling the Delay Slot
|     | a.  From before | b.  From target | c.  From fall through |
| --- | --------------- | --------------- | --------------------- |
 םא הרוק המ
sub $t4, $t5, $t6
|     | add $s1, $s2, $s3 |     | add $s1, $s2, $s3 |
| --- | ----------------- | --- | ----------------- |
reordering data
 שי sub םוקמב
…
|     | if $s2 = 0 then |     | if $s1 = 0 then |
| --- | --------------- | --- | --------------- |
independent  הקולחהו  div
add $s1, $s2, $s3  ?ספאב איה
|            |            |     |            |
| ---------- | ---------- | --- | ---------- |
| (RAW, WAW, | Delay slot |     | Delay slot |
 רציימ הז רבד
if $s1 = 0 then
  .exception
WAR)
sub $t4, $t5, $t6
Delay slot  םאה
instructions
 exception-ה
does not change  ותוא גהנתי
|     | Becomes | Becomes | Becomes |
| --- | ------- | ------- | ------- |
 םוקמב רבדה
program semantics
delay  ה לש
|     |     | sub $t4, $t5, $t6 | add $s1, $s2, $s3 |
| --- | --- | ----------------- | ----------------- |
????slot
|     | if $s2 = 0 then |     | if $s1 = 0 then |
| --- | --------------- | --- | --------------- |
add $s1, $s2, $s3
|     |  add $s1, $s2, $s3 |     |   sub $t4, $t5, $t6 |
| --- | ------------------ | --- | ------------------- |
if $s1 = 0 then
Safe?
   sub $t4, $t5, $t6
within same
For correctness:  For correctness:
basic block
add a new instruction add a new instruction
to the not-taken path? to the taken path?
Fix-up code (compensation code)
46
[Based on original figure from P&H CO&D, COPYRIGHT
2004 Elsevier. ALL RIGHTS RESERVED.]

FIGURE 4.64 Scheduling the branch delay slot. The top box in each pair shows the code before scheduling;
the bottom box shows the scheduled code. In (a), the delay slot is scheduled with an independent instruction
from before the branch. This is the best choice. Strategies (b) and (c) are used when (a) is not possible. In the
code sequences for (b) and (c), the use of $s1 in the branch condition prevents the add instruction (whose
destination is $s1) from being moved into the branch delay slot. In (b) the branch delay slot is scheduled from
the target of the branch; usually the target instruction will need to be copied because it can be reached by
another path. Strategy (b) is preferred when the branch is taken with high probability, such as a loop branch.
Finally, the branch may be scheduled from the not-taken fall-through as in (c). To make this optimization legal for
(b) or (c), it must be OK to execute the sub instruction when the branch goes in the unexpected direction. By
“OK” we mean that the work is wasted, but the program will still execute correctly. This is the case, for example,
if $t4 were an unused temporary register when the branch goes in the unexpected direction.
47
Copyright © 2014 Elsevier Inc. All rights reserved.
[Based on original figure from P&H CO&D, COPYRIGHT
2004 Elsevier. ALL RIGHTS RESERVED.]

How to Handle Control Dependences
היצמינא
 Critical to keep the pipeline full with correct sequence of
dynamic instructions.
 Potential solutions if the instruction is a control-flow
instruction:
 Stall the pipeline until we know the next fetch address
 Guess the next fetch address (branch prediction)
 Employ delayed branching (branch delay slot)
 Do something else (fine-grained multithreading)
 Eliminate control-flow instructions (predicated execution)
 Fetch from both possible paths (if you know the addresses
48
of both possible paths) (multipath execution)

?????Data Dependence םע המ לבא Control Dependence-ל הנעמ ןאכ שי

d םישרת ךותל STALLS ולחלחי הזכ הרקמב :הבושת

...םירטסיגר קיפסמ שיש

Fine-Grained Multi-threading
 Idea: Hardware has multiple thread contexts. Each cycle,
fetch engine fetches from a different thread.
 By the time the fetched branch/instruction resolves, no
instruction is fetched from the same thread
 Branch/instruction resolution latency overlapped with
execution of other threads’ instructions
+ No logic needed for handling control and
data dependences within a thread
-- Single thread performance suffers
)םירוזחמ N -ב םעפ(
-- Extra logic for keeping thread contexts
-- Does not overlap latency if not enough
threads to cover the whole pipeline
53
(םוקמב nops ולעפי ,םינוכילהת קיפסמ ןיא םא(

Fine-grained Multi-threading (II)
 Idea: Switch to another thread every cycle such that no two
instructions from a thread are in the pipeline concurrently
 Tolerates the control and data dependency latencies by
overlapping the latency with useful work from other
threads
 Improves pipeline utilization by taking advantage of
multiple threads
 Thornton, “Parallel Operation in the Control Data 6600,” AFIPS
1964.
 Smith, “A pipelined, shared resource MIMD computer,” ICPP
1978.
.הלא םירמאמ ינשמ םירוכזא םיאבומ םיאבה םיפקשה ינשב
54

Fine-grained Multi-threading: History
 CDC 6600’s peripheral processing unit is fine-grained
multi-threaded
 Thornton, “Parallel Operation in the Control Data 6600,” AFIPS
1964.
 Processor executes a different I/O thread every cycle
 An operation from the same thread is executed every 10 cycles
 Denelcor HEP (Heterogeneous Element Processor)
 Smith, “A pipelined, shared resource MIMD computer,” ICPP 1978.
 120 threads/processor
 available queue vs. unavailable (waiting) queue for threads
 each thread can have only 1 instruction in the processor pipeline; each
thread independent
 to each thread, processor looks like a non-pipelined machine
 system throughput vs. single thread performance trade-off
55

Wikipedia: The Heterogeneous Element Processor (HEP) was introduced by Denelcor, Inc. in
1982 as the world's first commercial MIMD computer. The HEP's architect was Burton Smith.
The machine was designed to solve fluid dynamics problems for the Ballistic Research
Laboratory.[1] A HEP system, as the name implies, was pieced together from many
heterogeneous components -- processors, data memory modules, and I/O modules. The
components were connected via a switched network.

Fine-grained Multi-threading in HEP
 Cycle time: 100ns
 8 stages  800 ns to
complete an
instruction
 assuming no
memory access
 No control and data
dependency checking
59

Multi-threaded Pipeline Example - MIPS

Multi-threaded Pipeline Example
61
Slide credit: Joel Emer

היצמינא
Sun Niagara Multithreaded Pipeline
Kongetira et al., “Niagara: A 32-Way Multithreaded Sparc Processor,” IEEE Micro 2005.
63

Thread #
Decode Memory
Execute WB
instruction
select
Fetch

Fine-grained Multi-threading
 Advantages
+ No need for dependency checking between instructions
(only one instruction in pipeline from a single thread)
+ No need for branch prediction logic
+ Otherwise-bubble cycles used for executing useful instructions from
different threads
+ Improved system throughput, latency tolerance, utilization
 Disadvantages
- Extra hardware complexity: multiple hardware contexts (PCs,
register files, …), thread selection logic
- Reduced single thread performance (one instruction fetched every
N cycles from the same thread)
- Resource contention between threads in caches and memory
- Some dependency checking logic between threads remains
(load/store) 67

תא םיקלוח םינוכילהתה
ןיא
ותוא רובע דוביעה תודיחי
לוצינ
ןועש רוזחמ
bubbles
אלמ
Credit: EEC 171 John Owens, “Parallel Architectures”
https://www.nvidia.com/content/cudazone/cudau/courses/ucdavis/lectures/tlp2.pdf

H&P CAQA, 7th Edition

Credit for this slide and the next two slides:
ANKIK JOSHI and DHARMESH TANK, “A FINE-GRAIN MULTITHREADING
SUPERSCALAR ARCHITECTURE"

היצמינא
How to Handle Control Dependences
 Critical to keep the pipeline full with correct sequence of
dynamic instructions.
 Potential solutions if the instruction is a control-flow
instruction:
 Stall the pipeline until we know the next fetch address
 Guess the next fetch address (branch prediction)
 Employ delayed branching (branch delay slot)
 Do something else (fine-grained multithreading)
 Eliminate control-flow instructions (predicated execution)
 Fetch from both possible paths (if you know the addresses
of both possible paths) (multipath execution)
73

Branch Prediction
74

Prediction
Branch : Guess the Next Instruction
to Fetch
היצמינא
PC 00000xxxxx?00000?000000000067845
I-$ DEC RF WB
0x0001
LD R1, MEM[R0]
תופעתסהה תאצות
0x0002 D-$
ADD R2, R2, #1
הזה בלשב תררבתמ
0x0003
BR 0x0001
ZERO
0x0004
ADD R3, R2, #1 12 cycles
0x0005
MUL R1, R2, R3
0x0006
LD R2, MEM[R2] Branch prediction
0x0007
LD R0, MEM[R2]
8 cycles
החנהב
ןוכנ וניזחש

היצמינא
Misprediction Penalty
PC
Flush!!
I-$ DEC RF WB
0x0001
LD R1, MEM[R0] 0x0007 0x0006 0x0005 0x0004 0x0003
0x0002 D-$
ADD R2, R2, #1
0x0003
BR 0x0001
ZERO
0x0004
ADD R3, R2, #1
0x0005
MUL R1, R2, R3
0x0006
LD R2, MEM[R2]
0x0007
LD R0, MEM[R2]

היצמינא
Branch Prediction
 Processors are pipelined to increase concurrency
 How do we keep the pipeline full in the presence of branches?
 Guess the next instruction when a branch is fetched
 Requires guessing the direction and target of a branch
A
Branch condition, TARGET
B1 B3 Pipeline
Fetch Decode Rename Schedule RegisterRead Execute
D
BBDFAE13 BDAFE1 BDFAE1 DBAFE1 DBFAE1 BDFEA1 BDAFE1 DBFAE1 BDFAE1 DBAE1 BDA1 BA1 A
E WTFaehrtagcteh tt o fMr ofeimstpc trhhe end eiccxotitro?rne cDt etatergcetetd! Flush tVheer ipfyip tehlein ePrediction
F
דע םיבלש 13 ךירצמש ךורא ןיילפייפ הארנ םישרתב
!תופעתסהה ןוויכ ררבתמ רשא 77

ןיילפייפ ילעב םידבעמל תואמגוד
קומע

...תאז תמועל
Credit: https://microchipdeveloper.com/32arm:m0-pipeline

Branch Prediction: Always PC+4
היצמינא
|              | ttt    | ttt  | ttt    | ttt | ttt | ttt |
| ------------ | ------ | ---- | ------ | --- | --- | --- |
|              | 000    | 111  | 222    | 333 | 444 | 555 |
| IIInnnsssttt | IIIFFF |      |        |     |     |     |
|              |        | IIDD | AALLUU | MEM |     |     |
hhh
PPPCCC
IIInnnsssttt
|     |     | IIFF | IIDD | ALU |     |     |
| --- | --- | ---- | ---- | --- | --- | --- |
iii
PPCC++44
| IIInnnsssttt |     |     | IIFF     | ID  |     |     |
| ------------ | --- | --- | -------- | --- | --- | --- |
| jjj          |     |     | PPCC++88 |     |     |     |
| IIInnnsssttt |     |     |          | IF  |     |     |
kkk
target
IIInnnsssttt
| lll |     |     |     | Inst |  branch condition and target |     |
| --- | --- | --- | --- | ---- | ---------------------------- | --- |
h
evaWluahteend ain b AraLnUch resolves

- branch target (Inst ) is fetched
k
- all instructions fetched since
  inst (so called “wrong-path”
h
  instructions) must be flushed80
| Inst  is a branch |     |     |     |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- |
h

Pipeline Flush on a Misprediction
היצמינא
|     | t   | t   | t   | t   | t   | t   |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
|     | 0   | 1   | 2   | 3   | 4   | 5   |     |
Inst
|     | IF  | ID  | ALU | MEM | WB  |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
h PC
| Inst |     | IF  | ID  | killed |     |     |     |
| ---- | --- | --- | --- | ------ | --- | --- | --- |
i
PC+4
| Inst |     |     | IF  | killed |     |     |     |
| ---- | --- | --- | --- | ------ | --- | --- | --- |
j
PC+8
| Inst |     |     |     | IF  | ID  | ALU | WB  |
| ---- | --- | --- | --- | --- | --- | --- | --- |
k
target
| Inst |     |     |     |     | IF  | ID  | ALU |
| ---- | --- | --- | --- | --- | --- | --- | --- |
l
|     |     |     |     |     |     | IF  | ID  |
| --- | --- | --- | --- | --- | --- | --- | --- |
IF
| Inst  is a branch |     |     |     |     |     |     | 81  |
| ----------------- | --- | --- | --- | --- | --- | --- | --- |
h

. branch תושעל םא עבוק memory ה בלשב AND-ה רעש ךא ALU ה בלשב תבשוחמ תבותכה
.ןמז ךוסחל היה רשפא הלאמש רתוי וא תחא הגרד תזזומ התיה הקיגולה םא
FLUSH ךירצ AND -ל לאמשמש המ לכ ךכ וא ךכ
Branch resolution.
Taken or not taken
Branch being evaluated

Performance Analysis
 correct guess  no penalty, 80%+0.2*0.3=86% of the time
 incorrect guess  3 bubbles, 14% of the time
 Assume
 no data dependency related stalls – תולת לש םירחא םיטקפא ןיא
 20% control flow instructions
 Always taken. 30% correct guesses and 70% are wrong
guesses הטלחה ןתנהב תועטה לש ריחמה
הנוכנ התיה אלש TAKEN
 CPI = [ 1 + (0.20*0.7) * 3 ] =
= [ 1 + 0.14 * 3 ] = 1.42
,רתוי קומע ןיילפייפה םא
pprroobbaabbiilliittyy ooff ppeennaallttyy ffoorr לדגת ףא וז המורת
aa wwrroonngg gguueessss aa wwrroonngg gguueessss
ינש תא ןיטקהל ךירצ םיעוציבה רופישל
םימרוגה
Can we reduce either of the two penalty terms?
83

Performance Analysis
 correct guess  no penalty, 80%+0.2*0.3=86% of the time
 incorrect guess  2 bubbles, 14% of the time
 Assume
 no data dependency related stalls – תולת לש םירחא םיטקפא ןיא
 20% control flow instructions
 Always taken. Of them 70% are wrong guesses
ןתנהב תועטה לש ריחמה ,התע
 CPI = [ 1 + (0.20*0.7) * 2 ] =
הנוכנ התיה אלש TAKEN הטלחה
= [ 1 + 0.14 * 2 ] = 1.28
,רתוי קומע ןיילפייפה םא
probability of penalty for
לדגת ףא וז המורת
a wrong guess a wrong guess
ךירצ םיעוציבה רופישל
םימרוגה ינש תא ןיטקהל
Can we reduce either of the two penalty terms?
84

היצמינא
Reducing Branch Misprediction Penalty
 Resolve branch condition and target address early
IF.Flush לש הלאמש הזזהה
Hazard התיחפה הקיגולה
detection
unit
1-ל penalty-ה תא
M ID/EX
u
x
WB
EX/MEM
M
Control u M WB
0 x MEM/WB
IF/ID EX M WB
4 Shift
left 2
M
u
x
=
Registers
PC In m st e ru m c o ti r o y n ALU m D em at o a ry M
u
M x
u
x
Is this a good idea?
Sign
extend
M
comparator u
x
Forwarding
unit
[Based on original figure from P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]
85
CPI = [ 1 + (0.2*0.7) * 1 ] = 1.14

Carnegie Mellon
Recall: Pipeline with Early Branch Resolution
Idea: Calculate branch target and condition in the Decode Stage
Dependence Detection Logic
86
Credit: Lecture 14, DDCA Spring 2022
https://www.youtube.com/watch?v=XaW_O9nKPe0&list=PL5Q2soXY2Zi97Ya5DEUpMpO2bbAoaG7c6&index=15

המגודל ליגרת
Source: HP CO&D Section 4.8
לש הקידבה תא םיזיזמ ונחנאש החנהב .אבה דוקה עטק ןותנ
ןכא תופעתסההו ,םדוקה םישרתב ומכ ,הלאמש דחא םוקמ תופעתסהה
.שחרתמה תא וראת ,תשחרתמ
(PC+4) + 7 words =
(PC+4) + 7*4bytes
תאז ריאשמ
םכרובע ליגרתכ
...dehsulf eb ot evah lliw ti tub
44 noitcurtsni sehctef rossecorp ehT
הפתרון:

םינושארה ןועשה ירוזחמ 3
CLR
....ןורתפה הנה ,בוט ונ

)4 רוזחמ( ךשמהה

Branch Prediction (Enhanced)
 Idea: Predict the next fetch address (to be used in the next
cycle) םדוק עדי ךמס-לע תבותכה תא תוזחל
 Requires three things to be predicted at fetch stage:
 Whether the fetched instruction is a branch
 (Conditional) branch direction
 Branch target address (if taken)
 Observation: Target address remains the same for a
conditional direct branch across dynamic instances
 Idea: Store the target address from previous instance and
access it with the PC
 Called Branch Target Buffer (BTB) or Branch Target Address
90
Cache

רבכש תויופעתסהה תובותכ לכ תא ןסחאתש )BTB( הלבט הנבנ
וזש חיננ ןכלו BTB -ב הלגתת איה בוש עיפות וז תבותכ םא זאו ורק
האבה תבותכה היהת
BTB
PC ADDR
If PC == ADDR I already know then it’s a branch

Credit: H&P CAQA 7th Edition (RISC-V)

Credit: H&P CAQA 7th Edition (RISC-V)
דדוב ןולשיכ ס”ע
הלבטהמ ךרעה קחמיי

Credit: H&P CAQA 7th Edition (RISC-V)

| Instruction | Instr. Decode |     | Execute    | Memory | Write |
| ----------- | ------------- | --- | ---------- | ------ | ----- |
| Fetch       | Reg. Fetch    |     | Addr. Calc | Access | Back  |
4
MUX
adder
Next PC
Branch PC
Return PC
(Addr + 4)
BTB
Address
|     | RS1 | Reg File | MUX |     | MEM/WB |
| --- | --- | -------- | --- | --- | ------ |
EX/MEM
|     | RS2 | ID/EX |     |     |     |
| --- | --- | ----- | --- | --- | --- |
ALU
| ICache |     |     |     | Memory |     |
| ------ | --- | --- | --- | ------ | --- |
|        |     |     | MUX | Data   |     |
IF/ID
MUX
Sign ataD BW
Imm Extend
|     |     | RD  | RD  | RD  |     |
| --- | --- | --- | --- | --- | --- |
• BTB target & direction predictions
Credit:
• Note BTB smaller (faster) than ICache, shortens path
Christopher Carothers
Computer  Architecture
3/16/01 CS252/Patterson
CS4250
Edited by D. Seidner, 4/04 Lec 5.95

Fetch Stage with BTB and Direction Prediction
Direction predictor (taken?)
By S/W or H/W
Taken? 1 דימת חיננ תעכ
?תחקל הצלמה
PC + inst size
Next Fetch
Address
4
Program
רבכ הרק רמולכ ,רגאמב םייק hit?
Counter םעפ
Address of the
current branch
target address
דימת taken=1 הז בלשב חיננ םא
Cache of Target Addresses (BTB: Branch Target Buffer)
תופעתסה תוחיכש
Always taken CPI = [ 1 + (0.20*0.3) * 2 ] = 1.12 (70% of branches taken)
96
םירקמהמ 30%-ב העטא ןכלו ”חקלנ דימת“ חינמ ינא ךא ,תוחקלנ תויופעתסההמ 70% .תמדוקה תירפסמה המגודב החנהל הכופה ןאכ החנהה ,בל ומיש

More Sophisticated Branch Direction Prediction
Direction predictor (taken?)
Which direction earlier
branches went
taken?
Global branch
history PC + inst size
Next Fetch
XOR
Address
Program
hit?
Counter
Address of the
current branch
target address
Cache of Target Addresses (BTB: Branch Target Buffer)
McFarling לש רמאמה :ןיכומיס
97

Three Things to Be Predicted
 Requires three things to be predicted at fetch stage:
1. Whether the fetched instruction is a branch
2. (Conditional) branch direction
לע תונעל לגוסמ תויהל דבעמה לע
:תולאשה 3
3. Branch target address (if taken)
?תופעתסה תארוה ונינפל םאה (1
?תחקלנ איה םאה ,ןכ םא (2
וזיאל זא ,תחקלנ איה םא (3
 Third (3.) can be accomplished using a BTB ?ףעתסהל תבותכ
 Remember target address computed last time branch was
executed
 First (1.) can be accomplished using a BTB
 If BTB provides a target address for the program counter, then
it must be a branch
 Or, we can store “branch metadata” bits in instruction
cache/memory  partially decoded instruction stored in I-cache
98
 Second (2.): How do we predict the direction?

Simple Branch Direction Prediction Schemes
 Compile time prediction (static)
 Always not taken
 Always taken
 BTFN (Backward taken, forward not taken)
 Profile based (likely direction)
 Run time prediction (dynamic)
 Last time prediction (single-bit)
99

More Sophisticated Direction Prediction
 Compile time prediction (static)
 Always not taken
 Always taken
 BTFN (Backward taken, forward not taken)
םיאבה םיפקשה
 Profile based (likely direction)
 Program analysis based (likely direction)
 Run time prediction (dynamic)
 Last time prediction (single-bit)
- הלא לכב ןודנ ןכמ רחאל
 Two-bit counter based prediction
 Two-level prediction (global vs. local)
 Hybrid
100

Static Branch Prediction (I)
 Always not-taken
 Simple to implement: no need for BTB, no direction prediction
 Low accuracy: ~30-40% (for conditional branches)
 Remember: Compiler can layout code such that the likely path
is the “not-taken” path  more effective prediction
 Always taken
 No direction prediction
 Better accuracy: ~60-70% (for conditional branches)
 Backward branches (i.e. loop branches) are usually taken
 Backward branch: target address lower than branch PC
 Backward taken, forward not taken (BTFN)
 Predict backward (loop) branches as taken, others not-taken
101

Static Branch Prediction (II)
 Profile-based תמכחותמ רתוי השיג
 Idea: Compiler determines likely direction for each branch
using a profile run. Encodes that direction as a hint bit in
the branch instruction format.
תויופעתסהה לכל תפרוג התייה N וא T הטלחהה ,ןכל םדוק
+ Per branch prediction (more accurate than schemes in
previous slide)  accurate if profile is representative!
-- Requires hint bits in the branch instruction format
-- Accuracy depends on dynamic branch behavior:
TTTTTTTTTTNNNNNNNNNN  50% accuracy
TNTNTNTNTNTNTNTNTNTN  50% accuracy
-- Accuracy depends on the representativeness of profile
input set
102

Itanium (IA-64): The Intel Itanium architecture (IA-64), based on the Explicitly Parallel Instruction
Computing (EPIC) paradigm, heavily relied on compiler cooperation for performance. It had explicit
branch hints in its instruction set. The compiler was responsible for providing these hints to the
hardware, guiding the branch predictor. This was a core part of its design philosophy to expose
more hardware details to the compiler.
x86 (with nuances): The x86 architecture has a more complex history with explicit branch hints.
Early Intel Processors (e.g., NetBurst architecture like Pentium 4): Some older Intel architectures
did indeed respect specific instruction prefixes (0x2E for "Branch Not Taken" and 0x3E for "Branch
Taken") as branch hints.
Later Intel Processors (e.g., Core 2 to Broadwell/Skylake): For a long time, these hints were
largely considered "no-ops" by compilers and processors, as dynamic branch predictors became
highly sophisticated and often out-performed static hints. The processors would primarily rely on
their internal dynamic predictors and static heuristics (like "backward taken, forward not taken").
Newer Intel Processors (e.g., Redwood Cove P-cores in Meteor Lake and later): Interestingly,
Intel has reintroduced the utility of these branch hint prefixes (0x3E for "Branch Taken" hint,
specifically) for certain scenarios. These hints are now used by the processor when its internal
branch predictor has no stored information about a particular branch. This can be particularly useful
for infrequently executed branches that are almost always taken, preventing an initial misprediction.
Compilers like GCC and LLVM/Clang have added support for emitting these hints based on profile-
guided optimization.

...דיתעב המגדה אובת הפ – םוקמ אלממ ףקש

Static Branch Prediction (III)
 Program-based (or, program analysis based)
 Idea: Use heuristics based on program analysis to determine
statically-predicted direction
הקיטסירויה השוע רלייפמוקה גנילייפורפ םוקמב
 Example opcode heuristic: Predict BLEZ as NT (negative integers used
as error values in many programs)
...הרקי אל הזש םה םייוכיסה בורו רחאמ
 Example loop heuristic: Predict a branch guarding a loop execution
as taken (i.e., execute the loop)
ןוויכה תא תוזחל םיעדוי ונחנא תואלולב ,המוד ןפואב
.םימעפה בורב
תואוושה םישוע ונחנא שופיח תויעבב :תפסונ המגוד
+ Does not require profiling ןורתי
האצותל עיגנשכ קרו NT הניהת ןה בורל .םירטניופ ןיב
T היהי
-- Heuristics might be not representative or good ןורסח
-- Requires compiler analysis and ISA support (ditto - ל”נכ for other static
methods)
 Ball and Larus, ”Branch prediction for free,” PLDI 1993.
 20% misprediction rate
105

Static Branch Prediction (IV)
 Programmer-based
 Idea: Programmer provides the statically-predicted direction
 Via pragmas in the programming language that qualify a branch
as likely-taken versus likely-not-taken
:רמאמה ואר המגודל
Compiler-assisted Source-to-Source
Skeletonization of Application Models for
System Simulation
https://www.osti.gov/servlets/purl/1513073
+ Does not require profiling or program analysis
+ Programmer may know some branches and their program better
than other analysis techniques
-- Requires programming language, compiler, ISA support
-- Burdens the programmer?
106

Pragmas
 Idea: Keywords that enable a programmer to convey
hints to lower levels of the transformation hierarchy
תואמגוד תוארהל :איג
 if (likely(x)) { ... }
.אבה ףקשב העיפומ - 1 המגוד
2 המגוד
 if (unlikely(error)) { … }
 Many other hints and optimizations can be enabled with
pragmas
 E.g., whether a loop can be parallelized
 #pragma omp parallel
 Description
 The omp parallel directive explicitly instructs the compiler to
parallelize the chosen segment of code.
107

In gcc: -fguess-branch-probability is enabled by
default at -O1 and higher.
int f(int i) { int f(int n) {
switch(i) { if (n > 5) [[unlikely]] {
case 1: g(0);
[[fallthrough]]; return n * 2 + 1;
[[likely]] case 2: }
C++20
return 1;
return 3;
}
}
return 2;
}

gcc רלייפמוקה לש דועיתה ךותמ
https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html

Static Branch Prediction
 All previous techniques can be combined
 Profile based - גנילייפורפ
 Program based – החינמ תינכתה
 Programmer based – תנכתמה לש הקיטסירויה
 How would you do that? תוטישה 3 תא דחאל ןתינ
 What is the common disadvantage of all three techniques?
 Cannot adapt to dynamic changes in branch behavior
 This can be mitigated by a dynamic compiler, but not at a fine
granularity (and a dynamic compiler has its overheads…)
 What is a Dynamic Compiler?
 Remember Transmeta? Code Morphing Software?
110
 Java JIT (just in time) compiler, Microsoft CLR (common lang. runtime)

*תומגדה
Note to self:
Demos folders:
~/science/Teaching/CPU/lectures/09/code
* Profiling:
/home/telzur/science/Teaching/CPU/lectures/09/code/profiling
* loop unrolling(**):
/home/telzur/science/Teaching/CPU/lectures/09/code/loop_unrolling
* Predicate:
~/science/Teaching/CPU/lectures/09/code/predicate_exe
* likely/unlikely:
~/science/Teaching/CPU/lectures/09/code/branch_prediction2
רגתאלו הבשחמל רמוח תווהמ לבא ...תומלשומ ןניא וללה תומגדהה *

גנילייפורפל המגדה
Note to self:
Folder:
~/science/Teaching/CPU/lectures/09/code/profiling/May2025
.יפוס אל ,חותיפב :המגדהה סוטטס
המגדהה םלעתהל רשפא :םידימלת

גנילייפורפל המגדה
Note to self:
Folder:
~/science/Teaching/CPU/lectures/09/code/profiling/May2025
See the two folders: A) Instrumented, B) Optimized
echo 0 | sudo tee /proc/sys/kernel/perf_event_paranoid
rm *.gcda
gcc -O2 -g --ffpprrooffiillee--ggeenneerraattee -o test_profile1.o -c test_profile1.c -lm
gcc -g -fprofile-generate -o test_profile1 test_profile1.o -lm
./test_profile1
gcc -g -O3 -fprofile-use -o test_profile1.o -c test_profile1.c -lm
gcc -g -O2 -fprofile-generate -o test_profile1.o -c test_profile1.c -lm
gcc -g -fprofile-generate -o my_program_instrumented test_profile1.o -lm
./my_program_instrumented # Run with your typical workload
gcc -g -O3 -fprofile-use -o test_profile1.o -c test_profile1.c -lm
# For linking:
gcc -g -fprofile-use -o my_program_optimized test_profile1.o -lm
./my_program_optimized
perf record -e branches,branch-misses ./my_program_optimized
sudo perf test
sudo perf list
sudo perf record -e branches,branch-misses -- ./my_program_optimized
# select the "cpu_core/branch-misses/" and then click a (for annotate)
sudo perf report
see:
./instrumented
./optimized
two profilings: the instrumented contains many more braches and mis-predicted branches

a = func1();
Demo #1: Profiling
b = func2();
for (int i=0;i<N;i++) {
#include<math.h>
#include<stdlib.h> x = (float)rand()/(float)RAND_MAX;
#include<stdio.h> if (a==b)
int NMAX=100;
{ c = func1(); printf("computing c\n"); }
float func1() {
else if (a>b+20+x)
int i;
{ d = func1(); printf("computing d\n"); }
float x = 0;
else if (a>b+17+x)
for (i=0;i<NMAX;i++) {
{ e = func1(); printf("computing e\n"); }
x+=sin((float)i/(float)NMAX); }
return x+10; } else if (a>b+9.5+x) // should somewhat be here
float func2() { { f = func1(); printf("computing f\n"); }
int i;
else if (a>b+9+x) // should somewhat be here
float x =0;
{ g = func1(); printf("computing g\n"); }
for (i=0;i<NMAX;i++) {
else
x+=sin((float)i/(float)NMAX); }
{ h = func1(); printf("computing h\n"); }
return x; }
}
int main() {
float a,b,c,d,e,f,g,h; return 0;
float x;
}
int N = 100;
}

Using gcov
$ info gcov # gcov - coverage testing
tool
$ cat ./run_gcov.sh
#!/bin/sh
rm *.gcda
rm *.c.gcov
gcc -fprofile-arcs -ftest-coverage -o
test_profile1 ./test_profile1.c -lm
./test_profile1
gcov -b ./test_profile1.c

the output

output of:
test_profile1.c.gcov
100 iterations in
total (43 + 57)

note to self:
demo folders:
/home/telzur/science/Teaching/CPU/lectures/09/
code/profiling/May2025/optimized
/home/telzur/science/Teaching/CPU/lectures/09/
code/profiling/May2025/optimized
script: readme_guy.sh
using “perf”

תויופעתסה
תובורמ

Call graph (Guy)
דוקה ךותב םירשק לש יופימ
!יטטס יופימ והז לבא
Cflow
Sourcetrail
$ ~/appimages/Sourcetrail_2021_4_19_Linux_64bit.AppImage --no-sandbox

Perf + FlameGraph !
דוקה ךותב םירשק לש יופימ
!ימאניד יופימ והז התע
FlameGraph is a visualization tool for profiling data (CPU, memory,
etc.). It shows where time/samples are spent in your program as an
inverted "flame" chart — each layer represents a function/call in the
stack, wider = more time spent.
file:///home/telzur/science/Teaching/CPU/lectures/09/code/profiling/
May2025/FlameGraph/callgraph.svg

Demo #2: Loop unrolling
The original code

The same code with loop unrolling

The results
תויצזימיטפוא ידי-לע תכסוממ תואלול תסירפ לש טקפאה תמגדה :תוגייתסה
היצזירוטקו ןשארבו עצבמ רלייפמוקהש תופסונ

Demo #3: Predicate execution
gcc -S ./test1.c
Compiler Explorer -ב שומיש םע םדוק רבכ הנתינ וז המגוד
https://godbolt.org/

AMD64
CMOVGE
conditional move if greater or equal .
The CMOVcc instructions check the
state of one or more of the status
flags in the EFLAGS register (CF, OF,
PF, SF, and ZF) and perform a move
operation if the flags are in a specified
state (or condition). A condition code
(cc) is associated with each
instruction to indicate the condition
being tested for. If the condition is not
satisfied, a move is not performed
and execution continues with the
instruction following the CMOVcc
instruction.

MIPS
MOVZ rd, rs, rt
This instruction means:
If the value in register rt is zero,
then copy the contents of register
rs into register rd. Otherwise, do
nothing (i.e., rd retains its original
value).
Therefore there is no branch as a
result of this instruction!

RISC-V 64

Guy
Aside: compare the code size

Branch hints: Likely/Unlikely
3 versions
version0: no “hints” – to be used as a reference version
Reference:
https://medium.com/software-design/likely-unlikely-directives-802c09bd5232

a script to test the
codes, for X86 and
for MIPS
folder:
/home/telzur/science/Teaching/CPU/
lectures/09/code/branch_prediction2

The results:
םיאנתה ךופיה
םיאנתה ךופיה

version 1

version 2

Dynamic Branch Prediction
הדימב

Dynamic Branch Prediction
 Idea: Predict branches based on dynamic information
(collected at run-time)
 Advantages
+ Prediction based on history of the execution of branches
+ It can adapt to dynamic changes in branch behavior
תינכתה תציר ידכ ךות תולגתסה
+ No need for static profiling: input set representativeness
problem goes away
 Disadvantages
-- More complex (requires additional hardware)
138

Last Time Predictor
 Last time predictor
 Single bit per branch (stored in BTB)
BTB=Branch Target Buffer
 Indicates which direction branch went last time it executed
TTTTTTTTTTNNNNNNNNNN  90% accuracy
הנושארה תיזחתב הצמחה היהת :הבושת ?10%-ה ןכיהמ
20 ךותמ 2 .המגמה ךופיה לש תיזחתבו
 Always mispredicts the last iteration and the first iteration
of a loop branch
 Accuracy for a loop with N iterations = (N-2)/N
+ Loop branches for loops with large N (number of iterations)
-- Loop branches for loops with small N (number of iterations)
TNTNTNTNTNTNTNTNTNTN  0% accuracy
Last-time predictor CPI = [ 1 + (0.20*0.15) * 2 ] = 1.06 (Assuming 85% accuracy)
139
האטחהל יוכיס 15%-ו תופעתסהל יוכיס 20% םיחינמ הפ

Implementing the Last-Time Predictor
BTB=Branch Target Buffer
tag BTB idx PC
BHT=Branch History Table
BHT:
N-bit
One
tag BTB: one target
Bit
table address per entry
per
entry
taken?
PC+4
= 1 0
The 1-bit BHT (Branch History Table) entry is updated with
nextPC
the correct outcome after each execution of a branch
141

State Machine for Last-Time Prediction
1 bit FSM
actually
taken actually
actually
taken
not taken
predict
predict
not
taken
taken
actually
not taken
142

Improving the Last Time Predictor
 Problem: A last-time predictor changes its prediction
from TNT or NTT too quickly
 even though the branch may be mostly taken or mostly not
taken
 Solution Idea: Add hysteresis to the predictor so that
prediction does not change on a single different
outcome
 Use two bits to track the history of predictions for a branch
instead of a single bit
 Can have 2 states for T or NT instead of 1 state for each
 Smith, “A Study of Branch Prediction Strategies,” ISCA
1981.
143

רופיש רכינ כ”הסב
תמועל היינשה היגטרטסאב
הנושארה היגטרטסאה

)לשח( סיזרטסיהה םוקע
.םייטנגמורפ םירמוחב רמוחב טנגמה תמצוע
תירויש תויטנגמ
ןוויכב היפכ חכ תלעפה
ךופהה
יטנגמה הדשה תמצוע
ינוציחה

Two-Bit Counter Based Prediction
T=Taken
 Each branch associated with a two-bit counter
N=Not Taken
 One more bit provides hysteresis
 A strong prediction does not change with one single
different outcome
 Accuracy for a loop with N iterations = (N-1)/N
2 תועצמאב יוזיח רובע
TNTNTNTNTNTNTNTNTNTN  50% accuracy
םיטיב
(assuming counter initialized to weakly taken)
דחא טיב לש ןונגנמב םירקמהמ 100% -ב םוקמב ,יוזיחה תא תונשל ידכ N םיימעפ ךירצ
+ Better prediction accuracy
10% >-- 20 ךותמ םירקמ 2-ב העטנ :TT...TTTNNN...NNN םיפקש רפסמ ינפלמ המגודב
2BC predictor CPI = [ 1 + (0.20*0.10) * 2 ] = 1.04 (90% accuracy)
-- More hardware cost (but counter can be part of a BTB entry)
146

Hysteresis Using a 2-bit Counter
actually
actually
“weakly
!taken
taken
taken”
pred
pred
“strongly
taken
taken
taken”
11 10
actually
actually
taken
actually
!taken
taken
actually
“strongly
!taken
!taken”
pred pred
“weakly !taken !taken actually
01 00
actually
!taken” !taken
taken
Change prediction after 2 consecutive mistakes 147

Credit: H&P CAQA 7th Edition, appendix C

State Machine for 2-bit Saturating Counter
 Counter using saturating arithmetic
 Arithmetic with maximum and minimum values
149

H&P.CO&D RISC-V Ed. ,
Chapter 4

Is This Good Enough?
 ~85-90% accuracy for many programs with 2-bit counter
based prediction (also called bimodal prediction)
 Is this good enough?
 How big is the branch problem?
151

Rethinking the The Branch Problem
 Control flow instructions (branches) are frequent
 15-25% of all instructions
 Problem: Next fetch address after a control-flow
instruction is not determined after N cycles in a pipelined
processor
 N cycles: (minimum) branch resolution latency
 If we are fetching W instructions per cycle (i.e., if the
pipeline is W wide)
 A branch misprediction leads to N x W wasted instruction
slots
152

Importance of The Branch Problem
 Assume N = 20 (20 pipe stages), W = 5 (5 wide fetch)
 Assume: 1 out of 5 instructions is a branch
 Assume: Each 5 instruction-block ends with a branch
 How long does it take to fetch 500 instructions?
 100% accuracy
 100 cycles (all instructions fetched on the correct path)
ןועש רוזחמ לכב :ילאדיא בצמ
 No wasted work, IPC=500/100=5 ושרדי ןכל .תוארוה 5 תועצובמ
םירוזחמ 100=500/5
 99% accuracy
)תוארוה 500( ןועש ירוזחמ 100 שי םא
 100 (correct path) + 20 (wrong path) = 120 cycles
ודבאי זא יוגש יוזיח היה םירוזחמה דחאבו
 20% extra instructions fetched, IPC=500/120=4.17 .םהילע רוזחל ךרטצנש ןועש ירוזחמ 20
100+20 כ"הס
 98% accuracy
 100 (correct path) + 20 * 2 (wrong path) = 140 cycles
 40% extra instructions fetched, IPC=500/140=3.57
 95% accuracy
לש throughput -המ 50% דבאמ
 100 (correct path) + 20 * 5 (wrong path) = 200 cycles בושיחה
153
 100% extra instructions fetched, IPC=500/200=2.5

תוארוה 5 לש עוציב תלוכיו תוגרד 20 ךרואב ןיילפייפ
ליבקמב
ףסונ רבסה
םדוקה ףקשל
:יובינב החלצה 95% רובע :יובינב החלצה 100% רובע
םירוזחמה דחאבו )תוארוה 500( ןועש ירוזחמ 100 שי םא 100 -ב ןכל .תוארוה 5 תועצובמ ןועש רוזחמ לכב
הז .רוזחל ךרטצנש ןועש ירוזחמ 20 ודבאי זא יוגש יוזיח היה .תוארוה 500 ועצובי ןועש ירוזחמ
5 יפ תרמוא תאז 95% אוה קוידה םא לבא .99% לש קויד
.ןועש ירוזחמ 100 רמולכ דוביאל וכליש ןועש ירוזחמ רתוי
,ןועש ירוזחמ 100+ 100-ב בושיחה תא םילשנ םעפה כהס
.ןועש ירוזחמ 200-ל קקדזנ רמולכ
IPC=500/200=2.5 IPC=500/100=5

Can We Do Better?
 Last-time and 2BC predictors exploit “last-time”
predictability
תמדוקה םעפהמ תופעתסהה לש הירוטסיהל קר סחייתמ
 Realization 1: A branch’s outcome can be correlated with
other branches’ outcomes
 → Global branch correlation
 Realization 2: A branch’s outcome can be correlated with
past outcomes of the same branch (other than the
outcome of the branch “last-time” it was executed)
 → Local branch correlation
2BC=2 bit counter
155

What did we cover in this lecture?
 Predicated Execution Primer
)רטסיגרל ”םא“ יאנת קוריפ תרוכזת( שארמ עובק עוציב
 Delayed Branching
 With and without squashing
 Branch Prediction
 Reducing misprediction penalty (branch resolution latency)
 Branch target buffer (BTB)
 Static Branch Prediction
 Dynamic Branch Prediction
 How Big Is the Branch Problem?
156

Spectre & Meltdown Side Channels Attacks

man gcc
GCC Mitigation (check )
Branch target injection takes advantage of the indirect branch predictors used by processors to
direct what operations are speculatively executed after a near indirect branch instruction. By
controlling how indirect branch predictors operate (“training”), an attacker can cause certain
instructions to be speculatively executed and then use the effects the malicious code has on the
processor’s caches to infer data values.
Ref: https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/advisory-guidance/branch-target-injection.html

Output of lscpu

וז תגצמ ןאכ דע