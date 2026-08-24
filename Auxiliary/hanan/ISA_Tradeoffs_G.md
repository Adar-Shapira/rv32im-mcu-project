BGU 361-1-4201
Computer Architecture
Lecture 2: ISA Tradeoffs
Lecturer: Dr. Guy Tel-Zur
Based on a course by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
V1.1: 2/4/20
V1.2: 31/3/22
V1.3: 15/3/23
V 1.4: 8/5/24

Agenda for Today
 Deep dive into ISA and its tradeoffs
LC-3b יכוניח בשחמ
http://users.ece.utexas.edu/~patt/09s.360N/handouts/new_byte.pdf
2

Last Lecture Recap
 Levels of Transformation
 Algorithm, ISA, Microarchitecture
 Moore’s Law
Read his 1965 paper:
Cramming more components onto integrated circuits
 What is Computer Architecture :ןמיונ ןוו תרוטקטיכרא
:םינייפאמ 2
 Why Study Computer Architecture
.ןורכזב תנסחואמ תינכתה )1
ץורע לע ןותנ עגרב .תיתרדיס הצרה )2
 Fundamental Concepts
וא הדוקפה וא תרבעומ )Bus( ימינפה
 Von Neumann Model .תינמז וב םהינש אל לבא ןותנה
 Dataflow Model – data driven
 ISA vs. Microarchitecture
םינותנהו תינכתה וז הרוטקטיכראב
דוגינב תאזו ןורכיזה ותואב םינסחואמ
תינכתל הב דראווראה תרוטקטיכראל
.םידרפנ תונורכז םינותנלו
3

Review: ISA vs. Microarchitecture
 ISA
 Agreed upon interface between software
Problem
and hardware
Algorithm
 SW/compiler assumes, HW promises
Program
 What the software writer needs to know to
ISA
write and debug system/user programs
Microarchitecture
 Microarchitecture
Circuits
 Specific implementation of an ISA
Electrons
 Not visible to the software
 Microprocessor
 ISA, uarch, circuits
 “Architecture” = ISA + microarchitecture
4

Review: ISA
 Instructions
 Opcodes, Addressing Modes, Data Types
 Instruction Types and Formats
 Registers, Condition Codes
 Memory
 Address space, Addressability, Alignment
 Virtual memory management
 Call, Interrupt/Exception Handling
 Access Control, Priority/Privilege
 I/O: memory-mapped vs. instr.
 Task/thread Management
 Power and Thermal Management
 Multi-threading support, Multiprocessor support
םידומע +1000 לש רפס
https://www.intel.com/content/www/us/en/developer/articles/technical/intel- sdm.ht
ml 5

Microarchitecture
 Implementation of the ISA under specific design constraints
and goals
 Anything done in hardware without exposure to software
 Pipelining – ךכל ףשחנ אל תנכתמה
 In-order versus out-of-order instruction execution
 Memory access scheduling policy
 Speculative execution (make predictions and pre-load data to the
cache in order to save memory access latency - איג)
 Superscalar processing (multiple instruction issue?) - תולועפ עוציב
ףשחנ אל תנכתמה ךכל םג – ןועש רוזחמב תובורמ
 Clock gating
 Caching? Levels, size, associativity, replacement policy
cache ילוקישל ףשחנ אל תנכתמה כ"רדב
 Prefetching? - םיפקש 2 דוע ואר
 Voltage/frequency scaling? - שמתשמל ףושח היהיש ירשפא- רדת תדרוה
 Error correction? 6

,תחתמ ךא ,)ןמיונ ןופ( תיתרדס היהת ISA -הש ירשפא
...לובקימ ,OoO המגודל ,הנוש ןפואב לעפת הרוטקטיכראורקימה

Instruction prefetch
In computer architecture, instruction prefetch is a technique used in
microprocessors to speed up the execution of a program by reducing wait
states.
Modern microprocessors are much faster than the memory where the program
is kept, meaning that the program's instructions cannot be read fast enough to
keep the microprocessor busy. Adding a cache can provide faster access to
needed instructions. Prefetching occurs when a processor requests an
instruction from main memory before it is actually needed. Once the
instruction comes back from memory, it is placed in a cache. When an
instruction is actually needed, the instruction can be accessed much more
quickly from the cache than if it had to make a request from memory. Since
programs are generally executed sequentially, performance is likely to be best
when instructions are prefetched in program order. Alternatively, the prefetch
may be part of a complex branch prediction algorithm, where the processor
tries to anticipate the result of a calculation and fetch the right instructions in
advance.
Source: https://www.definitions.net/definition/instruction+prefetch

μ
Property of ISA vs. arch?
?הרוטקטיכראורקימל ךייש המו ISA-ל ךייש םכתעדל המ :ליגרת
 א) ADD instruction’s opcode
 ב) Number of general purpose registers
 ג) Number of ports to the register file
 ד) Number of cycles to execute the MUL instruction
 ה) Whether or not the machine employs pipelined instruction
execution
ורקימ )ה ורקימ )ד ורקימ )ג ורקימ םגו ISA )ב ISA )א :תובושת
 Remember
 Microarchitecture: Implementation of the ISA under specific
design constraints and goals
ISA ותוא רובע תובר תורוטקטיכראוריקמ תויהל תולוכי ןכל
9

Design Point
 A set of design considerations and their importance
 leads to tradeoffs in both ISA and uarch
 Considerations
Problem
 Cost Algorithm
 Performance Program
 Maximum power consumption ISA
 Energy consumption (battery life) Microarchitecture
Circuits
 Availability
 Reliability and Correctness Electrons
 Time to Market
 Design point determined by the “ Problem” space
(application space), the intended users/market
דבעמה הנבנ המשל הרטמה /דועייה :ת ?ןכתה תדוקנ תא עבוק המ :ש
10

הבוח תאירק
Reading assignment:
Application Space
“Requirements, Bottlenecks, and Good Fortune:
Agents for Microprocessor Evolution" by
Yale Patt
 Dream, and they will appear…
יעדמ בושיח
טמופסכ
םשרמ – םינותנ דוביע
ןיסולכואה
תשר תרובעת ידבעמ
תמא ןמז תכרעמ
תוצבושמ תוכרעמ
בשחמ
)ואדיו( הידמ דוביע
יללכ שומישל ישיא בשחמ
11

Tradeoffs: Soul of Computer Architecture
 ISA-level tradeoffs
 Microarchitecture-level tradeoffs
 System and Task-level tradeoffs
 How to divide the labor between hardware and software
 Computer architecture is the science and art of making the
appropriate trade-offs to meet a design point
תונוכנ תורשפ תיישע לש תונמאהו עדמה איה בשחמ תרוטקטיכרא 
ןכתה תדוקנ תא םייקל ידכ
 Why art? - אבה ףקשה האר
12

Why Is It (Somewhat) Art?
New demands Problem
from the top
Algorithm
(Look Up)
New demands and
Program/Language User
personalities of users
(Look Up)
Runtime System
(VM, OS, MM)
ISA
Microarchitecture
New issues and
Logic
capabilities
Circuits
at the bottom
(Look Down) Electrons
...תונתשהל יופצ לכה
 We do not (fully) know the future (applications, users, market)
“It’s Difficult to Make Predictions, Especially About the Future"
13

Why Is It (Somewhat) Art?
Changing demands Problem
at the top
Algorithm
(Look Up and Forward)
Changing demands and
Program/Language User
personalities of users
(Look Up and Forward)
Runtime System
(VM, OS, MM)
ISA
Microarchitecture
Changing issues and
Logic
capabilities
Circuits
at the bottom
(Look Down and Forward) Electrons
 And, the future is not constant (it changes)!
...)...םינש +10( םיידיתע םיכרצ לש היארב – דבעמ תיינב תמועל רשג תיינב לע ובשיח המגודל
14

“it is difficult to predict, especially the future” - Niels Bohr
Niels Bohr (1885-1962)
Was a Danish physicist who made foundational contributions to understanding
atomic structure and quantum theory, for which he received the Nobel Prize in
Physics in 1922. Bohr was also a philosopher and a promoter of scientific
research.

How Can We Adapt to the Future
 This is part of the task of a good computer architect
 Many options (bag of tricks)
 Keen (בהלנ) insight and good design
 Good use of fundamentals and principles
 Efficient design
 Heterogeneity
 Reconfigurability
 …
 Good use of the underlying technology
 …
16

ISA Principles and
Tradeoffs
17

General structure of
instructions
18

Many Different ISAs Over Decades
 x86
 PDP-x: Programmed Data Processor (PDP-11)
Me by a Cray-1, at the Supercomputing conference,
 VAX
SC18. Dallas, Tx, 2018
 IBM 360
 CDC 6600
 SIMD ISAs: CRAY-1, Connection Machine
 VLIW ISAs: Multiflow, Cydrome, IA-64 (EPIC)
 PowerPC, POWER
POWER = "Performance Optimization With Enhanced RISC"
 RISC ISAs: Alpha, MIPS, SPARC, ARM, RISC-V
 ⇒What are the fundamental differences?
 E.g., how instructions are specified and what they do
 E.g., how complex are the instructions
19

Seymour Cray (1925 – 1996) was an American electrical engineer and
supercomputer architect who designed a series of computers that were
the fastest in the world for decades, and founded Cray Research which
built many of these machines. Called "the father of supercomputing".
- Wikipedia
הנולצרבב CESCA םיבושיחה זכרמב 15/4/2008 :םוליצ

Instruction
 Basic element of the HW/SW interface
 Consists of
 opcode: what the instruction does
 operands: who it is to do it to
 Example from the Alpha ISA ל”ז:
...םירלייפמוק רתוי םימייק אלו רחאמ אפלא תודוא לגרתל ןתינ אל
.טיב 32 – עובק ךרוא .םיעובק תומוקמ :רודס הנבמ
21
https://en.wikipedia.org/wiki/DEC_Alpha

MIPS
R-type
| 0     | rs    | rt    | rd    | shamt | funct |
| ----- | ----- | ----- | ----- | ----- | ----- |
| 6-bit | 5-bit | 5-bit | 5-bit | 5-bit | 6-bit |
I-type
| opcode | rs    | rt    | immediate |     |     |
| ------ | ----- | ----- | --------- | --- | --- |
| 6-bit  | 5-bit | 5-bit | 16-bit    |     |     |
J-type
| opcode | immediate |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- |
| 6-bit  | 26-bit    |     |     |     |     |
22

תיתושדח העידי
8/3/2021
/https://www.eejournal.com/article/wait-what-mips-becomes-risc-v

https://www.microchip.com/en-us/products/microcontrollers-and-microprocessors/32-bit-mcus/pic32-32-bit-mcus/pic32mz-ef
:רושיקבש ץבוקה תא ואר PIC32MZ רקב-ורקימב MIPS תרוטקטיכרא לש שומימה תודוא דוע דומלל ידכ
https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/ReferenceManuals/60001192B.pdf

ARM
RISC-ל המוד
רתוי תצק ךא
בכרומ
25

Set of Instructions, Encoding, and Spec
 Example from LC-3b ISA
http://users.ece.utexas.edu/~patt/09s.360N/handouts/new_byte.pdf
 Why unused instructions?
 Aside: concept of “bit
steering”
 A bit in the instruction
determines the
interpretation of other bits
x86 רובע םידומע 1200 תמועל םידומע 25 קר
Bit steering concept – next slide
26

Reference: LC-3b ISA
http://users.ece.utexas.edu/~patt/09s.360N/handou
ts/new_byte.pdf
DR = Destination register.
Imm5 = A 5-bit immediate value
SR = Source Register

Bit Steering in Alpha
28

The Elements of ISA
29

What Are the Elements of an ISA?
 Instruction sequencing model – ונרביד רבכ ךכ לע
 Control flow vs. data flow
 Tradeoffs?
Instruction processing style
 Specifies the number of “operands” an instruction “operates” on
and how it does so
.implicit הדוקפ
 0, 1, 2, 3 address machines הריזחמו stack-ב םינוילעה תומוקמה 2 לע תלעופ
תינסחמב ןוילעה םוקמל האצותה תא
 0-address: stack machine (op, push A, pop A)
 1-address: accumulator machine (op ACC, ld A, st A)
 2-address: 2-operand machine (op S,D; one is both source and dest).
S=Source, D=Destination
 3-address: 3-operand machine (op S1,S2,D; source and dest separate)
 Tradeoffs?
 Larger operate instructions vs. more executed operations
 Code size vs. execution time vs. on-chip memory space
ןורכיזל השיגה תובכרומ .VS דבעמה תובכרומ
30

Compact Code and Stack Architectures
Reference: H-P Computer Organization, 4th Ed.
2.20-3 Historical Perspective and Further
Reading
תודוא הידפיקיווב אורקל םינמזומ םתא
)RPN( Reverse Polish Notation

Algebraic vs. RPN methods
TI57 Algebraic calculator
Sharing = divide (:)
םדוקה ףקשב HP לש םגדה לומ הוושה

Stack Machine - Example
Stack
pointer
תינסחמב םינוילעה םיכרעה 2 לע לעפי

An Example: Stack Machine
+ Small instruction size (no operands needed for operate
instructions) – דבלב דוק-פואה קר אלא הארוהב םידנרפוא ןיא
 Simpler logic
 Compact code
+ Efficient procedure calls: all parameters on stack
 No additional cycles for parameter passing
-- Computations that are not easily expressible with “postfix
notation” are difficult to map to stack machines
 Cannot perform operations on many values at the same time (only
top N values on the stack at the same time)
 Not flexible ינשה דצהמ תושימג רסוחו דחא דצמ תוליעי
34
https://www.tutorialspoint.com/what-is-postfix-
notation

An Example: Stack Machine (II)
:תושר
Koopman, “Stack Computers:
The New Wave,” 1989.
http://www.ece.cmu.edu/~koopm
an/stack_computers/sec3_2.html
:רפסה לש םניח הדרוהל רושיק
https://users.ece.cmu.edu/~koopman/stack_c
omputers/stack_computers_book.pdf
DS = Data Stack
RS = Return Stack
TOS = Top Of Stack register
PC = Program Counter
MAR = Memory Address Register
IR = Instruction Register
35

An Example: Stack Machine Operation
?האבה המגודב עצבתמ ליגרת הזיא
Koopman, “Stack Computers:
The New Wave,” 1989.
http://www.ece.cmu.edu/~koopm
an/stack_computers/sec3_2.html
:ןורתפ
89*)21+54(
36

Other Examples
 PDP-11: A 2-address machine
 PDP-11 ADD: 4-bit opcode, 2 6-bit operand specifiers
 Why? Limited bits to specify an instruction
 Disadvantage: One source operand is always clobbered with the
result of the instruction
 How do you ensure you preserve the old value of the source?
S op D → D
 X86: A 2-address (memory/memory) machine S = source
D = Destination
 Alpha: A 3-address (load/store) machine
Op = operation
 MIPS - 3 address machine
 ARM - 3 address machine
Clobbered = לברוסמ
Instead of: Source1 Source2 → Destination
⊛
We have: Source Destination → Destination
⊛
רוקמה תא "תסרוד" האצותה
37

PDP-11

What Are the Elements of An ISA?
 Instructions הדוקפה תא םיאיבמש ןפואה םג אלא ISA -המ קלח אוה הדוקפה גוס קר אל
addressing modes יגוס הברה םימייק
 Opcode
.ךשמהב ךכב קוסענ דוע
 Operand specifiers (addressing modes)
– How to obtain the operand?
Why are there different addressing modes?
 Data types םינותנה לא םיבר םינפואב תושימג רשפאל ידכ
 Definition: Representation of information for which there are
instructions that operate on the representation
 Integer, floating point, character, binary, decimal, BCD
 Doubly linked list, queue, string, bit vector, stack
– VAX: INSQUEUE and REMQUEUE instructions on a doubly linked list or
queue; FINDFIRST
– Digital Equipment Corp., “VAX11 780 Architecture Handbook,” 1977.
– X86: SCAN opcode operates on character strings; PUSH/POP
ISA -ה תובכרומ לע הכילשמ םינוש םינותנ יסופיטב הכימת
39

VAX-11/780

Semantic Gap
Semantic gap

Source: https://passlab.github.io/CSE564/notes/lecture04_ISA_supplement.pdf

Source:
https://passlab.github.io/CSE564/notes/lec
ture04_ISA_supplement.pdf

Semantic Gap
תודוקפ
תובכרומ
הזזה - translation
תודוקפ
תוטושפ
44

Data Type Tradeoffs
 What is the benefit of having more or high-level data types in
the ISA?
 What is the disadvantage?
 Think compiler/programmer vs. microarchitect
תיליעה הפשב םימייקה םיסופיטל ISA -ב םימייקה םיסופיטה םיבורק המכ
 Concept of semantic gap
 Data types coupled tightly to the semantic level, or complexity of
instructions
:רושיק
 Example: Early RISC architectures vs. Intel 432
 Early RISC: Only integer data type (המגודל MIPS)
 Intel 432: Object data type, capability based machine ( החנומ תונכת
:BCD טמרופב הכימת אוה םינותנ לש גוסל תפסונ המגוד
םימצע)
...אבה ףקשה ואר – Binary Coded Decimal
45

An Example: BCD היצמינא
 Each decimal digit is encoded with a fixed number of bits
"Binary clock" by Alexander Jones & Eric Pierce - Own work, based on Wapcaplet's Binary clock.png on the English Wikipedia.
Licensed under CC BY-SA 3.0 via Wikimedia Commons - http://commons.wikimedia.org/wiki/File:Binary_clock.svg#mediaviewer/
File:Binary_clock.svg
"Digital-BCD-clock" by Julo - Own work. Licensed under Public Domain via Wikimedia Commons -
47
http://commons.wikimedia.org/wiki/File:Digital-BCD-clock.jpg#mediaviewer/File:Digital-BCD-clock.jpg

,השחמהל
ISA-המ קלח אוה BCD
X86 לש

What Are the Elements of An ISA?
 Memory organization
 Address space: How many uniquely identifiable locations in תובותכה תומכ
ןורכיזה בחרמ
memory
 Addressability: How much data does each uniquely identifiable
םישמתשמה לבא דחא גוסב קר ךומתל הז טושפ יכה
location store
הנומת דוביע לש םימושיי לשמל .תושימג םיכירצ
.םיטייב לע תולועפל וקקדזי
 Byte addressable: most ISAs, characters are 8 bits
 Bit addressable: Burroughs 1700. Why?
איה ןורכיזב דדוב טיב לכל עיגהל השיגל השירד
:)Burroughs 1700( הרידנ
 64-bit addressable: Some supercomputers. Why?
"...הזה טיבה תא ןעט" המגודל
רמוח
 32-bit addressable: First Alpha(*) ISA לש היצזילאוטריוול דעוי בשחמהש ךכל הביסה
הבשחמל
,רתויב הנטקה עדימה תסיפ ןכלו )**( תכרעמ לכ לש
 Food for thought
.תושימגה םומיסקמ תא הרשפיא ,טיב
 How do you add 2 32-bit numbers with only byte addressability?
 How do you add 2 8-bit numbers with only 32-bit addressability?
 Big endian vs. little endian? MSB at low or high byte.
 Support for virtual memory
,shift ,הזזה תולועפ תושעל ךירצ היה טייב אורקל וצר םא ,דדוב טייב אורקל ןתינ היה אל )*(
תובקעב ךשמהב .טייב לע תולועפב הכימת אלל word לע תולועפב קר הכימת התיה masking-ו
.הנוש הז םישמתשמהמ השירד
virtualized ISA )**(
49

Byte-addressable memories are organized in a
big-endian or little-endian fashion, as shown in
Figure 6.3. In both formats, the most significant
byte (MSB) is on the left and the least significant
byte (LSB) is on the right.
In big-endian machines, bytes are numbered
starting with 0 at the big (most significant) end. In
little-endian machines, bytes are numbered
starting with 0 at the little (least significant) end.
Word addresses are the same in both for-
mats and refer to the same four bytes. Only the
addresses of bytes within a word differ.
רבסה
Credit: see next slide

:התיכב המגדה
lscpu תדוקפ לש טלפה
Credit for this slide and the previous slides:
Harris & Harris,
“Digital Design and Computer Architecture"

:)תושר( הרבחה תודוא םינוטרסל םירושיק
https://www.youtube.com/watch?v=eyOp
O-040W8
https://www.youtube.com/watch?v=Qeiu
VNDQg4k

Some Historical Readings – תושר תאירק
 If you want to dig deeper
 “ ,WilnerDesign of the Burroughs 1700.AFIPS 1972 ”,
 “ ,LevyThe Intel iAPX 432.1981 ”,
 http://www.cs.washington.edu/homes/levy/capabook/Chapter9.p
df
53

What Are the Elements of An ISA?
 Registers
 How many? ( the answer may include 0 )
 Size of each register
 Why is having registers a good idea?
 Because programs exhibit a characteristic called ddaattaa llooccaalliittyy
 A recently produced/accessed value is likely to be used more than
once (temporal locality)
 Storing that value in a register eliminates the need to go to memory
each time that value is needed
* Re-use the data!
54

Programmer Visible (Architectural) State
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
array of storage locations
memory address
indexed by an address
of the current instruction
Instructions (and programs) specify how to transform
the values of programmer visible state
55
אבה ףקשה ואר...תמועל

Aside: Programmer Invisible State
 Microarchitectural state
 Programmer cannot access this directly
 e.g. cache state
 e.g. pipeline registers
56

Evolution of Register Architecture
ןמזה ריצ
 Accumulator
 a legacy from the “adding” machine days
 Accumulator + address registers
 need register indirection
 initially address registers were special-purpose, i.e., can only be
loaded with an address for indirection
 eventually arithmetic on addresses became supported
 General purpose registers (GPR)
 all registers good for all purposes
 grew from a few registers to 32 (common for RISC) to 128 in Intel
IA-64
57

Instruction Classes תוארוה לש תוחפשמ
 Operate instructions – תולועפ עוציב לש תוארוה
 Process data: arithmetic and logical operations
 Fetch operands, compute result, store result
 Implicit sequential control flow
 Data movement instructions – םינותנ תזזה לש תוארוה
 Move data between memory, registers, I/O devices
 Implicit sequential control flow
 Control flow instructions תינכתה תומדקתה תרקב לש תוארוה
 Change the sequence of instructions that are executed
58

What Are the Elements of An ISA?
 Load/store vs. memory/memory architectures
 Load/store architecture: operate instructions operate only on
registers
 E.g., MIPS, ARM and many RISC ISAs
 Memory/memory architecture: operate instructions can operate
on memory locations
 E.g., x86, VAX and many CISC ISAs
RISC ב םייק אל לבא 
59

What Are the Elements of An ISA?
 Addressing modes specify how to obtain the operands
|  Absolute |     | LW rt, 10000 |     |     |     |     |
| ---------- | --- | ------------ | --- | --- | --- | --- |
use immediate value as address
|  Register Indirect:  |     |     | LW rt, (r | )   |     | Load Word |
| --------------------- | --- | --- | --------- | --- | --- | --------- |
base
| use GPR[r | ] as address |     |     |     |     |     |
| --------- | ------------ | --- | --- | --- | --- | --- |
base
 Displaced or based:LW rt, offset(r )
base
| use offset+GPR[r |     | ] as address |     |     |     |     |
| ---------------- | --- | ------------ | --- | --- | --- | --- |
base
|  Indexed: |         | LW rt, (r | , r          | )   |     |     |
| ---------- | ------- | --------- | ------------ | --- | --- | --- |
|            |         |           | base index   |     |     |     |
| use GPR[r  | ]+GPR[r |           | ] as address |     |     |     |
:לופכ רושרש
|     | base | index |     |     |  הנפמ רטסיגרב ךרעה  |     |
| --- | ---- | ----- | --- | --- | ------------------- | --- |
 תבותכל הנפמש ןורכיזב תבותכל
| Memory Indirect |     |     | LW rt ((r | ))  |     |     |
| --------------- | --- | --- | --------- | --- | --- | --- |

|     |     |     |     | base |  תא ןועטל שי הנממ ןורכיזב תיפוסה |     |
| --- | --- | --- | --- | ---- | -------------------------------- | --- |
ןותנה
| use value at M[ GPR[ r |     |     | ] ] as address |     |     |     |
| ---------------------- | --- | --- | -------------- | --- | --- | --- |
base
| Auto inc/decrement |     |     | LW Rt, (r | )   |     |     |
| ------------------ | --- | --- | --------- | --- | --- | --- |

base
| use GRP[r | ] as address, but inc. or dec. GPR[r |     |     |     |      | ] each time |
| --------- | ------------------------------------ | --- | --- | --- | ---- | ----------- |
|           | base                                 |     |     |     | base |             |
 לשמל רשאכ ליעי הזה ןונגסה .רטסיגרב ךרעה תא רסחה וא םדק הלועפה עוציב ירחא
 ךרעמ ינפ לע םירבוע

What Are the Benefits of Different Addressing Modes?
 Another example of programmer vs. microarchitect tradeoff
 Advantage of more addressing modes:
 Enables better mapping of high-level constructs to the machine:
some accesses are better expressed with a different mode 
reduced number of instructions and code size
 Think array accesses (autoincrement mode)
 Think indirection (pointer chasing): עיבצמל עיבצמ ,םיעיבצמ לש ןוסחא...
 Sparse matrix accesses – ספאמ םינושה םיטנמלאל םיעיבצמ לש ךרעמ
 Disadvantage:
 More work for the compiler – לולע הז תויורשפא הברה רלייפמוקל שי
וילע תושקהל
 More work for the microarchitect
61

ISA Orthogonality
 Orthogonal ISA: הרדגה
 All addressing modes can be used with all instruction types
 Example: VAX
 (~13 addressing modes) x (>300 opcodes) x (integer and FP formats)
הבר תושימג
 Who is this good for?
- the compiler designer
 Who is this bad for?
ואר
Orthogonal Instruction Set Wiki
62

Is the LC-3b ISA Orthogonal?
..אאלל ההבבווששתת
תתוודדווקקפפהה ללככלל אאלל ,,ללששממלל
iimmmmeeddiiaattee--בב ההככייממתת
63

LC-3b: Addressing Modes of ADD
ןועימ ידומ 2
64

LC-3b: Addressing Modes of JSR(R)
JSR = Jump to Subroutine
LC-3b is not
Orthogonal
Relative addressing
Left shift Sign extend
65

What Are the Elements of an ISA?
 How to interface with I/O devices
 Memory mapped I/O
 A region of memory is mapped to I/O devices
 I/O operations are loads and stores to those locations
 Special I/O instructions
 IN and OUT instructions in x86 deal with ports of the chip
– You can LOAD from the keyboard. You can STORE to the
monitor
 Tradeoffs?
 Which one is more general purpose?
– איג: Memory mapped I/O is more general purpose. Any kind of
device can be accessed as long as it can be mapped to a
memory location.
66

What Are the Elements of An ISA?
 Privilege modes – הזב קוסענ אל
 User vs supervisor
 Who can execute what instructions?
 Exception and interrupt handling
 What procedure is followed when something goes wrong with an instruction?
 What procedure is followed when an external device requests the processor?
 Vectored vs. non-vectored interrupts (early MIPS)
• Vectored – הקיספה תא עציב ןקתה הזיא ?דבעמל עירפה ימ עדימה תא שי רשאכ
• Non vectored interrups - ול עירפה ימ שחנל ךירצ דבעמה ,םייק אל עדימה
תובכרומ תמועל תוטשפ
 Virtual memory
 Each program has the illusion of the entire memory space, which is greater than
physical memory (Guy: "swap space" in Linux)
67

Another Question or Two
 Q: Does the LC-3b ISA contain complex instructions?
–
A: No
 How complex can an instruction be?
68

Complex vs. Simple Instructions
 Complex instruction: An instruction does a lot of work, e.g.
many operations
 Insert in a doubly linked list
 Compute FFT
 String copy
 Simple instruction: An instruction does small amount of work,
it is a primitive using which complex operations can be built
 Add
 XOR
 Multiply
69

Complex vs. Simple Instructions
 Advantages of Complex instructions
+ Denser encoding  smaller code size  better memory
utilization, saves off-chip bandwidth, better cache hit rate (better
packing of instructions)
+ Simpler compiler: no need to optimize small instructions as much
 Disadvantages of Complex Instructions
- Larger chunks of work  compiler has less opportunity to
optimize (limited in fine-grained optimizations it can do)
- More complex hardware  translation from a high level to control
signals and optimization needs to be done by hardware
70

ISA-level Tradeoffs: Semantic Gap
 Where to place the ISA? Semantic gap
 Closer to high-level language (HLL)  Small semantic gap,
complex instructions
 Closer to hardware control signals?  Large semantic gap, simple
instructions
 RISC vs. CISC machines
 RISC: Reduced instruction set computer
 CISC: Complex instruction set computer
 FFT, QUICKSORT, POLY, FP instructions?
 VAX INDEX instruction (array access with bounds checking)
71

Semantic Gap
תודוקפ
תובכרומ
הזזה - translation
תודוקפ
תוטושפ
72

ISA-level Tradeoffs: Semantic Gap
 Some tradeoffs (for you to think about)
 Simple compiler, complex hardware vs. complex compiler,
simple hardware
 Caveat הרהזא: Translation (indirection) can change the trade-off!
 Burden of backward compatibility
ואר
אבה ףקשה
 Performance? Energy Consumption?
 Optimization opportunity: Example of VAX INDEX instruction: who
(compiler vs. hardware) puts more effort into optimization?
 Instruction size, code size
73

CO&D old
edition:

X86: Small Semantic Gap: String Operations
 An instruction operates on a string
 Move one string of arbitrary length to another location
 Compare two strings
 Enabled by the ability to specify repeated execution of an
instruction (in the ISA)
 Using a “prefix” called REP prefix (REP = Repeat)
 Example: REP MOVS instruction
 Only two bytes: REP prefix byte and MOVS opcode byte (F2 A4)
 Implicit source and destination registers pointing to the two strings
(ESI, EDI) – (=Extended Source/Destination Index)
 Implicit count register (ECX) specifies how long the string is
75

המגוד
cld ; Clear direction flag (forward copy)
mov ecx, 100 ; Copy 100 bytes
mov esi, source_address
mov edi, destination_address
rep movsb ; Repeat move byte
cld sets the direction flag to forward, so ESI and EDI will be incremented.
mov ecx, 100 tells the rep movsb to move 100 bytes.
mov esi, source_address sets the source address.
mov edi, destination_address sets the destination address.
rep movsb then performs the byte copy.
The CPU checks if ECX is zero. If ECX is not zero, the process repeats.

X86: Small Semantic Gap: String Operations
...םינותנ סופיט לכל
REP MOVS (DEST SRC)
:לוקש דוק תמועל תחא הדוקפכ
הבשחמל רמוח
How many instructions does this take in MIPS?
77

Small Semantic Gap Examples in VAX
תובכרומ תודוקפ >--( רצק יטנמס קחרמל תופסונ תואמגוד
 FIND FIRST
 Find the first set bit in a bit field
 Helps OS resource allocation operations
 SAVE CONTEXT, LOAD CONTEXT
 Special context switching instructions
 INSQUEUE, REMQUEUE
 Operations on doubly linked list
 INDEX
 Array access with bounds checking
 STRING Operations
 Compare strings, find substrings, …
 Cyclic Redundancy Check Instruction
 EDITPC
 Implements editing functions to display fixed format output
Edit Packed to Character String
ASCII ל BCD -מ רפסמ תרמה לשמל .תוארוה ורקימל תמגרותמש תבכרומ ורקאמ תדוקפ יהוז
79
 Digital Equipment Corp., “VAX11 780 Architecture Handbook,” 1977-78.

Small versus Large Semantic Gap
 CISC vs. RISC
 Complex instruction set computer  complex instructions
 Initially motivated by “not good enough” code generation(*)
 Reduced instruction set computer  simple instructions
 John Cocke, mid 1970s, IBM 801(**)
 Goal: enable better compiler control and optimization
 RISC motivated by
 Memory stalls (no work done in a complex instruction when there
is a memory stall?)
 Simplifying the hardware  lower cost, higher frequency
 Enabling the compiler to optimize the code better
 Find fine-grained parallelism to reduce stalls(***)
קיפסמ םיבוט ויה אל םירלייפמוקה תישארב )*(
םינושארה RISC יבשחמ ןנכתמ .גנירויט סרפ ןתח )**(
תוליעיב םגופה ןורכיזל תושיג יוביר בקע םיבוכיע )***( 80

m
f
c.
5
1
1
3
8
0
2
_
e
k
c
o
c
/s
r
e
n
ni
w
_
d
r
a
w
a
/
g
r
o
.
m
c
a
.
g
n
ir
u
t
m
a
//
:s
p
tt
h

An Aside
 An Historical Perspective on RISC Development at IBM
 http://www-03.ibm.com/ibm/history/ibm100/us/en/icons/risc/
Guy> IBM’s “POWER” standing for “Performance Optimized With
Enhanced RISC,”
82

How High or Low Can You Go?
/lecture02/code :המגדה
 Very large semantic gap
 Each instruction specifies the complete set of control signals in
the machine
 Compiler generates control signals
 Microcode
 Gave way to optimizing compilers
 Very small semantic gap
 ISA is (almost) the same as high-level language
 Java machines, LISP machines, object-oriented machines,
capability-based machines – שרדנ ןתוא ץיאהל ידכ ,תויטיא תופש הלא
83
הרמוחב םיאתמ ןונכת

A Note on ISA Evolution
 ISAs have evolved to reflect/satisfy the concerns of the day
 Examples: If you have...
 Limited on-chip and off-chip memory size → תובכרומ תודוקפ ילוא
רוזעל ולכוי
 Limited compiler optimization technology → תודוקפל ןורתי ,בוש
תובכרומ
:תורשפ לש קחשמה יללכ תא "רבוש" translation ב שומיש
 Limited memory bandwidth → תובכרומ תודוקפל ןורתי
 Need for specialization in important applications (e.g., MMX)
 Use of translation (in HW and SW) enabled underlying
implementations to be similar, regardless of the ISA
 Concept of dynamic/static interface: translation/interpretation
 Contrast it with hardware/software interface
תונשל ידכ אבה ףקשה ואר >-- רחא ISA -ל דחא ISA-מ רבעמ
semantic gap-ה לש תורשפה תא 84

ISA (virtual ISA)  Implementation
ISA
HW/SW interface
לש וטבמ תניחבמ
:איג
תנכתמה
Virtualized (complex) ISA
השוע הרמוחה לטניא ידבעמב
translations-ה תא
Translation and execution interface
תוטושפ תודוקפ םע דבוע דבעמהש דועב תובכרומ תודוקפב שומיש תלוכי םיחיוורמ ונחנא
85

Effect of Translation
 One can translate from one ISA to another ISA to change the
semantic gap tradeoffs
 ISA (virtual ISA תנכתמה האורש המ הז)  Implementation ISA
 Examples
 Intel’s and AMD’s x86 implementations translate x86 instructions
into programmer-invisible micro-operations (simple instructions)
in hardware
 Rosetta 2 (Apple): Apple's Rosetta 2 technology dynamically
translates x86_64 applications to run on Apple Silicon (ARM) Macs.
 QEMU:is an open-source emulator and virtualizer that can
perform binary translation.
 Transmeta’s x86 implementations translated x86 instructions into
“secret” VLIW instructions in software (code morphing software -
CMS)
HW translator ה תוכזב RISC ל המוד לטניא לש םידבעמה בל
86
 Think about the tradeoffs

Hardware-Based Translation
תודוקפה הלא
תוצרומש
הבוח תאירק
Klaiber, “The Technology Behind Crusoe Processors,” Transmeta White Paper 2000.
https://web.stanford.edu/class/cs343/resources/crusoe.pdf :איג
87

Software-Based Translation
Dynamic
compiler
Klaiber, “The Technology Behind Crusoe Processors,” Transmeta White Paper 2000.
88

תפסונ האירקל
H&P CO&D Appendix E: A Survey of RISC
Architectures for Desktop, Server and Embedded
Computers.
Another Approach to Instruction Set Architecture—VAX
https://minnie.tuhs.org/CompArch/Resources/
webext3.pdf

םיפקשה רתיב רועישה רחאל ןייעל :םידימלת
וז גצמ ןאכ דע :ירובע

ISA-level Tradeoffs: Instruction Length תונורסחו תונורתי
 Fixed length: Length of all instructions the same
+ Easier to decode single instruction in hardware
+ Easier to decode multiple instructions concurrently
-- Wasted bits in instructions (Why is this bad?)
-- Harder-to-extend ISA (how to add new instructions?)
 Variable length: Length of instructions different (determined
by opcode and sub-opcode)
+ Compact encoding (Why is this good?)
Intel 432: Huffman encoding (sort of). 6 to 321 bit instructions. How? - אבה ףקש האר
-- More logic to decode a single instruction
-- Harder to decode multiple instructions concurrently
 Tradeoffs
 Code size (memory space, bandwidth, latency) vs. hardware complexity
 ISA extensibility and expressiveness vs. hardware complexity
 Performance? Smaller code vs. ease of decode
91

GDP = General Data Processor
http://www.bitsavers.org/components/intel/iAPX_432/171860-004_iAPX_432_General_Data_Processor_Architecture_Reference_Manual_Feb84.pd
f

ISA-level Tradeoffs: Uniform Decode
 Uniform decode: Same bits in each instruction correspond to
the same meaning
 Opcode is always in the same location
 Ditto operand specifiers, immediate values, …
 Many “RISC” ISAs: Alpha, MIPS, SPARC
+ Easier decode, simpler hardware
+ Enables parallelism: generate target address before knowing the
instruction is a branch
-- Restricts instruction format (fewer instructions?) or wastes space
 Non-uniform decode
 E.g., opcode can be the 1st-7th byte in x86
+ More compact and powerful instruction format
-- More complex decode logic
93

x86 vs. Alpha Instruction Formats
 x86:
 Alpha:
94

MIPS Instruction Format
 R-type, 3 register operands
R-type
| 0     | rs    | rt    | rd    | shamt | funct |
| ----- | ----- | ----- | ----- | ----- | ----- |
| 6-bit | 5-bit | 5-bit | 5-bit | 5-bit | 6-bit |
 I-type, 2 register operands and 16-bit immediate operand
I-type
| opcode | rs    | rt    | immediate |     |     |
| ------ | ----- | ----- | --------- | --- | --- |
| 6-bit  | 5-bit | 5-bit | 16-bit    |     |     |
 J-type, 26-bit immediate operand
J-type
| opcode | immediate |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- |
| 6-bit  | 26-bit    |     |     |     |     |
 Simple Decoding
 4 bytes per instruction, regardless of format
 must be 4-byte aligned          (2 lsb of PC must be 2b’00)
 format and fields easy to extract in hardware
95

ARM
96

A Note on Length and Uniformity
 Uniform decode usually goes with fixed length
 In a variable length ISA, uniform decode can be a property of
instructions of the same length
 It is hard to think of it as a property of instructions of different
lengths
97

A Note on RISC vs. CISC
 Usually, …
 RISC
 Simple instructions
 Fixed length
 Uniform decode
 Few addressing modes
 CISC
 Complex instructions
 Variable length
 Non-uniform decode
 Many addressing modes
98

CISC-ל RISC ןיב האוושה
Credit: Sivarama P. Dandamudi, "Introduction to AssemblyLanguage
ProgrammingFor Pentium and RISC Processors"

RISC vs. CISC
Credit:
“The Essentials of Computer
Organization and Architecture”,
5th edition by Linda Null

ISA-level Tradeoffs: Number of Registers
 Affects:
 Number of bits used for encoding register address
 Number of values kept in fast storage (register file)
 (uarch) Size, access time, power consumption of register file
 Large number of registers:
+ Enables better register allocation (and optimizations) by compiler
 fewer saves/restores
-- Larger instruction size
-- Larger register file size
101

ISA-level Tradeoffs: Addressing Modes
 Addressing mode specifies how to obtain an operand of an
instruction
 Register
 Immediate
 Memory (displacement, register indirect, indexed, absolute, memory
indirect, autoincrement, autodecrement, …)
 More modes:
+ help better support programming constructs (arrays, pointer-based
accesses)
-- make it harder for the architect to design
-- too many choices for the compiler?
 Many ways to do the same thing complicates compiler design
 Wulf, “Compilers and Computer Architecture,” IEEE Computer 1981
102

x86 vs. Alpha Instruction Formats
 x86:
 Alpha:
103

x86
register
indirect
absolute
register +
displacement
register
SIB byte → (scale * index) + base
104

x86
indexed
(base +
index)
scaled
(base +
index*4)
105

X86 SIB-D Addressing Mode
x86 Manual Vol. 1, page 3-22 -- see course resources on website
Also, see Section 3.7.3 and 3.7.5
106

X86 Manual: Suggested Uses of Addressing
Modes
x86 Manual Vol. 1, page 3-22 -- see course resources on website
Also, see Section 3.7.3 and 3.7.5
107

X86 Manual: Suggested Uses of Addressing
Modes
x86 Manual Vol. 1, page 3-22 -- see course resources on website
Also, see Section 3.7.3 and 3.7.5
108

Other Example ISA-level Tradeoffs
 Condition codes vs. not
 VLIW vs. single instruction
 Precise vs. imprecise exceptions
 Virtual memory vs. not
 Unaligned access vs. not
 Hardware interlocks vs. software-guaranteed interlocking
 Software vs. hardware managed page fault handling
 Cache coherence (hardware vs. software)
 …
109

Back to Programmer vs. (Micro)architect
 Many ISA features designed to aid programmers
 But, complicate the hardware designer’s job
 Virtual memory
 vs. overlay programming
 Should the programmer be concerned about the size of code
blocks fitting physical memory?
 Addressing modes
 Unaligned memory access
 Compile/programmer needs to align data
110

MIPS: Aligned Access
| MSB    |        |        | LSB    |     |
| ------ | ------ | ------ | ------ | --- |
| byte-3 | byte-2 | byte-1 | byte-0 |     |
| byte-7 | byte-6 | byte-5 | byte-4 |     |
 LW/SW alignment restriction: 4-byte word-alignment
 not designed to fetch memory bytes not within a word boundary
 not designed to rotate unaligned bytes into registers
 Provide separate opcodes for the “infrequent” case
|                 | A      | B      | C      | D   |
| --------------- | ------ | ------ | ------ | --- |
| LWL  rd 6(r0)  | byte-6 | byte-5 | byte-4 | D   |
LWR  rd 3(r0) 
|     | byte-6 | byte-5 | byte-4 | byte-3 |
| --- | ------ | ------ | ------ | ------ |
 LWL/LWR is slower
 Note LWL and LWR still fetch within word boundary
111

X86: Unaligned Access
 LD/ST instructions automatically align data that spans a “word”
boundary
 Programmer/compiler does not need to worry about where
data is stored (whether or not in a word-aligned location)
112

X86: Unaligned Access
113

What About ARM?
 https://www.scss.tcd.ie/~waldroj/3d1/arm_arm.pdf
 Section A2.8 - - אבה ףקש םג האר
!םידומע 1138
114

Aligned vs. Unaligned Access
 Pros of having no restrictions on alignment
 Cons of having no restrictions on alignment
 Filling in the above: an exercise for you…
116

Market share of embedded RISC
processors. From ExtremeTech.
https://www.righto.com/2023/07/the-complex-history-of-intel-i960-risc.html