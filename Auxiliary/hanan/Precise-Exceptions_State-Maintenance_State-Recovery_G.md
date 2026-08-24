361.1.4201
Computer Architecture
Precise Exceptions,
State Maintenance, State Recovery
Dr. Guy Tel-Zur
Base on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
and comments by Dr. Danny Seidner
Last update: 14/6/2022, 31/5/2023, 10/7/2024, 19/6/2025

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence Handling,
State Maintenance and Recovery, …
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, …
2

Readings for past and the next few lectures
 Guy: P&H CO&D, Chapter 4 – “The Processor”
 Guy: H&P CAQA, Appendix C - "Pipelining: Basic and
 Intermediate Concepts"
 Smith and Plezskun, “Implementing Precise Interrupts in
Pipelined Processors,” IEEE Trans on Computers 1988 (earlier
version in ISCA 1985).
 Smith and Sohi, “The Microarchitecture of Superscalar Processors,”
Proceedings of the IEEE, 1995
 More advanced pipelining
 Interrupt and exception handling
 Out-of-order and superscalar execution concepts
3

Recall: How to Handle Data Dependences
 Anti and output dependences are easier to handle
 write to the destination only in last stage and in program order
...תאז ונדמל םרט ךא ,ןוכנ
 Flow dependences are more interesting
 Six fundamental ways of handling flow dependences
 Detect and wait until value is available in register file
 Detect and forward/bypass data to dependent instruction
 Detect and eliminate the dependence at the software level
 No need for the hardware to detect dependence
 Detect and move it out of the way for independent instructions
 Predict the needed value(s), execute “speculatively”, and verify
 Do something else (fine-grained multithreading)
4
 No need to detect

Review: How to Handle Control Dependences
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
5

Review of Last Few Lectures
 Control dependence handling in pipelined machines
 Delayed branching
 Fine-grained multi-threading
 Branch prediction
 Compile time (static)
 Always NT, Always T, Backward T Forward NT, Profile based
 Run time (dynamic)
 Last time predictor
 Hysteresis: 2BC predictor
 Global branch correlation --> Two-level global predictor תויצלרוק
 Local branch correlation --> Two-level local predictor
 Hybrid branch predictors
 Predicated execution (Arm)
 Multipath execution (RS6000) – ונרכזה קר
 Return address stack & Indirect branch prediction – ונרביד אל 6

Pipelining and Precise Exceptions:
Preserving Sequential Semantics

Credit: Modern Processor Design by Shen & Lipasti
יראלקס-רפוס דבעמ

Multi-Cycle Execution
 Not all instructions take the same amount of time for
“execution”
 Idea: Have multiple different functional units that take
different number of cycles
 Can be pipelined or not pipelined
 Can let independent instructions start execution on a different
functional unit before a previous long-latency instruction finishes
execution
Integer add
E
Integer mul
E E E E
?
F D FP mul
E E E E E E E E
. . .
E E E E E E E E
Load/store
9

| Issues in Pipelining:  |     |     | Multi-Cycle Execute |     |     |     |     |     |
| ---------------------- | --- | --- | ------------------- | --- | --- | --- | --- | --- |
Instructions can take different number of cycles in EXECUTE

stage
E תודיחי המכ ןנשי
 Integer ADD versus FP MULtiply
עוציב ירוזחמ 8
| FMUL R4  R1, R2    | F D | E E | E E | E E | E E | W   |        |     |
| ------------------- | --- | --- | --- | --- | --- | --- | ------ | --- |
|                     |     |     |     |     | *   |     |  הביתכ |     |
| ADD   R3  R11, R12 | F   | D E | W   |     |     |     |        |     |
 אל רדסב
|     |     | F D | E W |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
ןיקת
ןיקת לכה הרואכל,רדסה יפל D-ו F
|     |     | F   | D E | W   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | F D | E E | E E | E E | E E | W   |
FMUL R2  R5, R6
| ADD   R7  R15, R16 |     |     | F   | D E | W   |     |     |     |
| ------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|                     |     |     |     | F D | E W |     |     |     |
What is wrong with this picture?
 Sequential semantics of the ISA NOT preserved!
 What if FMUL incurs (תושחרתהל םרוג) an exception? * בלשב לשמל
ןמיונ ןופ תנוכמל הריתס .הלאכ םיבצמ גבדל רשפא יא

ינוטקטיכראה בצמה תא רזחשל ןתינ אל הנוש תוהש ןמז םע תוארוה שי םא
|     |     |     |     |     |     |     |    | 10  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

Exceptions and Interrupts
 “Unplanned” changes or interruptions in program
execution
 Due to internal problems in execution of the program
→ Exceptions = הגירח
 Due to external events that need to be handled by the
processor
→ Interrupts = הקיספ
 Both exceptions and interrupts require
 stopping of the current program
 saving the architectural state
 handling the exception/interrupt → switch to handler
 return back to program execution (if possible and makes sense)
11

Exceptions vs. Interrupts
 Cause
 Exceptions: internal to the running thread . ספאב הקולח לשמל
ףכת( רגבד םע דובעל אציש ימל
 Interrupts: external to the running thread
.)םיגדנ
השעמל אוה break point
(ינוציח רוקמ) שקמ לע הציחל .exception
ןכ ינפל הרקש המ לכש איה החנהה
 When to Handle .גבדל ןתינ אל תרחא,םייתסה
 Exceptions: when detected (and known to be non-speculative)
 Interrupts: when convenient
 Except for very high priority ones
 Power failure
 Machine check (error), e.g error in the cache
ךילהתה תובישחב היולת הגירחה תובישח
 Priority: process (exception), depends (interrupt)
Page Fault, divide by zero – internal to the thread :איג
 Handling Context: process (exception), system (interrupt)
12

...
םדוקה ףקשל ךשמהב
:הביסה םרוג
.THREAD -ה ליבשב ימינפ עוריא – הגירח
.THREAD-ל ינוציח עוריא – הקיספ
:לפטל יתמ
.ידיימב ,הלגתמ רשאכ – הגירח
.(...חוכ תקפסא תדירי וא ןומטמ תלקת ןוגכ םיגירח םירקמ איצוהל) "חונ" רשאכ – הקיספ
:ףודעת
.לופיט תבייחמ הגירח
.יולת הז – הקיספ
(תוסחייתהה ףקיה) טסקטנוק
ךילהתה תמרב :הגירח
.תכרעמה תמרב :הקיספ

|   תועצמאב |   ונל |   הלגתמ |   ינוטקטיכראה |   בצמה |
| --------- | ----- | ------- | ------------- | ------ |
רגאבדה

Precise Exceptions/Interrupts
 The architectural state should be consistent (precise)
when the exception/interrupt is ready to be handled
:ןמיונ-ןופ לדומל םאתהב
1. All previous instructions should be completely retired.
2. No later instruction should be retired.
Retire = commit = finish execution and update arch. state
retired=ינוטקטיכראה בצמה תא ןכדעל ומייס
15

Checking for and Handling Exceptions in
Pipelining
 When the oldest instruction ready-to-be-retired is detected
to have caused an exception, the control logic should:
 Ensures architectural state is precise (register file, PC, memory)
 Flushes all younger instructions in the pipeline
 Saves PC and registers (as specified by the ISA)
 Redirects the fetch engine to the appropriate exception
handling routine
16

הנכתל הרמוחה ןיב קשממה יללכל תויצ

Why Do We Want Precise Exceptions?
 Semantics of the von Neumann model ISA specifies it
 Remember von Neumann vs. Dataflow
 Aids software debugging – ראשל ,ינוטקטיכרא בצמ רוזחיש שרדנ הז ךרוצל
ךבוסמ הז ךא יקלח בצמ רומשל םג רשפא םירקמה
 Enables (easy) recovery from exceptions, e.g. page faults
Aside: A memory page fault occurs when a program tries to access data that is not
currently loaded in the physical memory (RAM). The operating system then retrieves
the required data from secondary storage, allowing the program to continue running.
 Enables (easily) restartable processes
בצמה לכ תא ןורכיזה לא דירוהל תלוכי איה שרדנש המ זא לוחתא תושעל תלוכי הז םיצורש המ םא
הרזחב ותוא אורקל כ"חאו ינוטקטיכראורקימה
 Enables traps into software (e.g., software implemented
opcodes)
A try-catch exception is a programming construct used to handle errors in code. The "try" block
contains code that might cause an error, and if an error occurs, the "catch" block executes to handle
18
the error gracefully, allowing the program to continue running.

|      |       |  :    |
| ---- | ----- | ----- |
| ספאב | הקולח | המגדה |
demo:
/home/telzur/science/Teaching/CPU/lectures/11/code/except.c

RISC-V tolerates div by 0 and no
exception will be thrown
http://127.0.0.1:5000/
target remote :1234 see: readme

Why RISC-V tolerates divide by zero and doesn't
throw an exception?
What RISC-V does:
Integer divide-by-zero returns all 1s (0xFFFFFFFF = -1 for signed, UINT_MAX for unsigned). No
exception.
Why:
1. Simplicity — Exception handling adds hardware complexity (priority logic, trap vectors,
saved state). RISC-V aims for minimal, clean architecture.
2. Performance — Not checking for zero before every division saves cycles. The hardware just
does the operation.
3. Consistent, defined behavior — Returning all 1s is predictable. Software that cares can
explicitly check for zero first. It's easier to add a check in software than to handle
exceptions when you don't want them.
4. Some code wants that value — Saturating arithmetic, certain crypto routines, or bitwise
operations may actually need 0xFFFFFFFF. Having a defined result is more useful than
crashing.
5. Comparison:
• x86 and MIPS → throws #DE exception (divide error)
• ARM → configurable, can trap or return all 1s
• RISC-V → returns all 1s, no trap
Bottom line: RISC-V follows the principle of "hardware does the simple thing, software
handles edge cases when needed." It's not tolerating bad behavior — it's explicitly
defined.

Ensuring Precise Exceptions
 Easy to do in single-cycle and multi-cycle machines
 Single-cycle
 Instruction boundaries == Cycle boundaries
 Multi-cycle
 Add special states in the control FSM that lead to the
exception or interrupt handlers
 Switch to the handler only at a precise state → before fetching
the next instruction
22
See H&H Section 7.7 for a treatment of exceptions in multi-cycle uarch

Precise Exceptions in MIPS Multi-Cycle Datapath
יתשב הכימת
תוגירח
EPC register: Holds the exception causing PC
Cause register: Holds the cause of the exception
Exception Handler starts at address 0x80000180
23
See H&H Section 7.7 for a treatment of exceptions in multi-cycle uarch

Precise Exceptions in MIPS Multi-Cycle FSM
שחרתת אבה רוזחמב
ECP handler -ל הציפק
see: H&H MIPS 7.7
24

Precise Exceptions in MIPS Multi-Cycle Datapath
25

Mips coprocessor 0

...הפי רתוי תצק םישרת
return from
exception
Vectored vs. Polled exception: A vectored exception uses a
specific address in memory to directly call the appropriate
interrupt handler based on the type of exception, allowing
for faster response times. In contrast, a polled exception
requires the CPU to continuously check each device to see
if it needs attention, which can be less efficient.

 Instructions can take different number of cycles in EXECUTE
stage → This complicates exception/interrupt
Multi-Cycle Execute: More Complications
handling
Integer ADD versus Integer DIVide
|    |     |     |     |     |     | Exception-causing  |     |     |
| --- | --- | --- | --- | --- | --- | ------------------ | --- | --- |
instruction
|     | F D | E E | E E | E E | E E | W   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
DIV     R4  R1, R2
| ADD   R3  R1, R2 | F   | D E | W   |     |     |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|                   |     | F D | E W |     |     |     |     |     |
|                   |     | F   | D E | W   |     |     |     |     |
|                   |     |     | F D | E E | E E | E E | E E | W   |
DIV     R2  R5, R6
| ADD   R7  R5, R6 |     |     | F   | D E | W   |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|                   |     |     |     | F D | E W |     |     |     |
 What is wrong with this picture in a Von Neumann
architecture?
 Sequential semantics of the ISA NOT preserved!
30
 What if DIV incurs an exception?

The clean and minimalist RISC-V way
| Register | Purpose |
| -------- | ----------------------------------------------- |
| mtvec | Trap vector — address of exception handler |
| mcause | Exception cause code (what happened) |
| mepc | Saved PC where exception occurred |
| mtval | Additional info (faulting address, instruction) |
| mstatus | Status flags (interrupt enable, privilege mode) |
1. Trap occurs (exception or interrupt)
2. Hardware auto-saves: mepc ← PC, mcause ← reason, mtval ← details, mstatus flags updated
3. Jump to mtvec handler address
4. Handler runs — reads mcause, decides what to do
5. Return via MRET/SRET/uret — restores PC and privilege mode
Exception Codes (mcause)
• 0 = instruction address misaligned
• 1 = instruction access fault
• 2 = illegal instruction
• 3 = breakpoint (ebreak)
• 4 = load address misaligned
• 5 = load access fault
* Exceptions always trap up to a higher privilege level.
• ...and so on

 Idea: Make each operation take the same amount of time
Ensuring Precise Exceptions in Pipelining
| FMUL R3  R1, R2  | F   | D E | E E | E E | E E | E   | W   |     |     |     |
| ----------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ADD   R4  R1, R2 |     | F D | E E | E E | E E | E   | E W |     |     |     |
|                   |     | F   | D E | E E | E E | E   | E E | W   |     |     |
|                   |     |     | F D | E E | E E | E   | E E | E W |     |     |
|                   |     |     | F   | D E | E E | E   | E E | E E | W   |     |
|                   |     |     |     | F D | E E | E   | E E | E E | E W |     |
|                   |     |     |     | F   | D E | E   | E E | E E | E E | W   |
:לבא ןומזת לש היעב ןיא תעכ
 Downside
Worst-case instruction latency determines all instructions’ latency

What about memory operations?

Each functional unit takes worst-case number of cycles?

32

How do we support precise
Solutions
exceptions in the presence of
instructions completing out of
 Reorder buffer
program order?
 History buffer
 Future register file קמועל אל ךא ןודנ הלא תשולשב
 Checkpointing
 Readings
 Smith and Plezskun, “Implementing Precise Interrupts in Pipelined
Processors,” IEEE Trans on Computers 1988 and ISCA 1985.
 Hwu and Patt, “Checkpoint Repair for Out-of-order Execution
Machines,” ISCA 1987.
33

דמלנ ךכ לע
האצרהב
האבה
ROB
P&H CO&D 4.10

Credit: Shen & Lipasti
Mod.Proc.Des.

 Idea: Complete instructions out-of-order, but reorder them
before making results visible to architectural state
Solution I: Reorder Buffer (ROB)
 When instruction is decoded it reserves an entry in the ROB
 When instruction completes, it writes result into ROB entry
 When instruction oldest in ROB and it has completed
without exceptions, its result moved to reg. file or memory
Func Unit
Register
Instruction Reorder
Func Unit
File
Cache Buffer
(ROB)
Func Unit
36

 Buffers information about all instructions that are
Reorder Buffer
decoded but not yet retired/committed
A re-order buffer is a hardware unit [ used in an extension to
the Tomasulo algorithm – next lecture ] to support out-of-
order and speculative instruction execution. The extension
forces instructions to be committed in-order.
37

Reorder Buffer
 A hardware structure that keeps information
about all instructions that are decoded but
not yet retired/committed
Oldest instruction
Entry 0
Entry 1 )pointer to ROB entry
Entry 2
that contains information
about oldest instruction
in the machine(
Entry 8 Youngest instruction
Entry 13
Entry 14
Entry 15
38
ROB is implemented as a circular queue in hardware
?dilaV
yrtnE
DI
ger
tseD
eulav
ger
tseD
?nettirw
ger
tseD
valid = הארוהל האצקה התשענ
dest id / value = ךרעה / םשה המ
written? = ?אל וא בתכנ רבכ ךרעה

What’s in a ROB Entry?
הלוכת
Valid bits for reg/data
V DestRegID DestRegVal StoreAddr StoreData PC Exception?
+ control bits
עיבצמ
עעווצצייבב ססווטטטטסס ?הגירח
רטסיגר
ןןווררככייזז
)ךכב ןודנ אל(
 Everything required to:
 correctly reorder instructions back into the program order
 update the architectural state with the instruction’s result(s),
if instruction can retire without any issues
 handle an exception/interrupt precisely, if an
exception/interrupt needs to be handled before retiring the
instruction
 Need valid bits to keep track of readiness of the result(s)
and find out if the instruction has completed execution
39

הריעצ יכה הארוהה סנכת ןכל
הקיתו יכה הארוהה
תא בבוסנ םא
90-ב הלבטה
ןוויכב תולעמ
איה ,ןועשה
תמאות היהת
ןוילעה קלחל
Credit: Shen & Lipasti
Mod.Proc.Des.

Reorder Buffer: Independent Operations
Result first written to ROB on instruction completion

 Result written to register file at commit time
:ארקמ
| F D | E E | E E | E E | E E | R W |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
R = ROB
| F   | D E | R   |     |     |     | W   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
W = Commit
|     | F D | E R |     |     |     | W   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | F   | D E | R   |     |     |     | W   |     |
|     |     | F D | E E | E E | E E | E E | R W |     |
|     |     | F   | D E | R   |     |     |     | W   |
|     |     |     | F D | E R |     |     |     | W   |
 What if a later instruction needs a value in the reorder
buffer?
 One option: stall the operation → stall the pipeline
43
 Better: Read the value from the reorder buffer. How?

Reorder Buffer: How to Access?
 A register value can be in the register file, reorder buffer,
(or bypass/forwarding paths)
Random Access Memory
(indexed with Register ID,
Register
Instruction
which is the address of an entry(
File
Cache
Func Unit
Func Unit
Reorder Func Unit
Content Buffer
Addressable
bypass paths
Memory
)searched with
register ID,
which is part of the content of an entry(
44

Reorder Buffer Example
Register File )RF( Reorder Buffer )ROB(
Oldest
R0 Entry 0
R1 Entry 1 instruction
R2 Entry 2
R3
R4
R5
R6
R7
Entry 8 Youngest
instruction
Entry 13
Entry 14
Entry 15
46
?dilaV
eulaV
Value
?dilaV
yrtnE
DI
ger
tseD
eulav
ger
tseD
?nettirw
ger
tseD
Initially: all registers
are valid in RF
& ROB is empty
Simulate:
MUL R1, R2 → R3
MUL R3, R4 → R11
ADD R5, R6 → R3
ADD R3, R8 → R12

ינושארה בצמה

הנושארה הארוהל decode

הינשה הארוהל decode

|   המייס |   הנושארה |   הארוההש |     |   חיננ |   התע |
| ------- | --------- | --------- | --- | ------ | ----- |
|         |           |           | R3- |        |       |
|         |           |           |     | ל ךרע  | שיו   |
1
 תא שפחנ
ROB -ב R3

תישילשה הארוהל decode
WAW dependence
on R3 which is a false
dependence

תיעיברה הארוהל decode
פפ
עע
וו
לל
תת
הה
חח
יי
פפ
וו
שש
בב
--
BB
OO
RR
““
יי
קק
R3 תא שפחל שי
רר
הה
”” לדומל םאתהב ROB-ב
תולועפ( CAM -ה
)תורזוח האוושה
ךרעב שמתשהלו
ינפלש ולש ןורחאה
הנודנה הארוהה
רמולכ ןימז היהישכל
1-ל הנתשי לגדה

RAM vs. CAM (Guy)
RAM (Random Access Memory) is used for storing data and programs that the CPU needs in
real-time, while CAM (Content Addressable Memory) allows for high-speed data retrieval
based on content rather than specific addresses. CAM is particularly useful in applications
requiring rapid searches
Credit:
https://www.geeksforgeeks.org/difference-between-random-access-memory-ram
-and-content-addressable-memory-cam/

Simplifying Reorder Buffer Access
 Idea: Replace CAM with indirection
םיביכרה תומכ תלדגהו הקיגול תפסוה ,יטירקה ביתנה תכראה :לברוסמ םדוקה םישרתה
CAM-ב לברוסמה שופיחה ןורתפל העצה – 
 Access register file first לייפ רטסיגרל םישגינ הליחת
 If register not valid, register file stores the ID of the reorder
buffer entry that contains (or will contain) the value of the
register
 Mapping of the register to a ROB entry: Register file maps the
register to a reorder buffer entry if there is an in-flight
instruction writing to the register
 Access reorder buffer next רפאבל םישגינ ןכמ רחאלו
(האבה האצרהה) OOO לע דמלנשכ ךשמהב םג ונתוא שמשי הזכש יופימ 56
 Now, reorder buffer does not need to be content
addressable

Reorder Buffer Example
Register File )RF( Reorder Buffer )ROB(
Oldest
R0 Entry 0
R1 Entry 1 instruction
R2 Entry 2
R3
R4
R5
R6
R7
Entry 8 Youngest
instruction
Entry 13
Entry 14
Entry 15
57
?dilaV
eulaV
Value
?dilaV
yrtnE
DI
ger
tseD
eulav
ger
tseD
?nettirw
ger
tseD
Tag
(pointer to
ROB entry)
Initially: all registers
are valid in RF
& ROB is empty
Simulate:
MUL R1, R2 → R3
MUL R3, R4 → R11
ADD R5, R6 → R3
ADD R3, R8 → R12

הנושארה הארוהל Decode

תישילשה הארוהל Decode
החנהב
לש decode-הש
השענ 3 הארוה
הארוהה םרטב
המייס הנושארה

ROB -בש דועב תלבגומ םירטסיגרה תומכ RF -ב
לוכי ןותנ לכו םינותנ הברה רומשל רשפא
רטסיגר לש הנוש יופימ תויהל
Architectural registers → Physical registers (ROB
or another structure…)
Size of ROB in Pentium 4: 128 entries

Boggs et al., “The
Microarchitecture of the
Pentium 4 Processor,”
Reorder Buffer in Intel Pentium III
Intel Technology Journal,
2001.
Register Alias Table
םירטסיגר
Retirement Register
םינכומ
File
64

Intel Pentium Pro (1995)
Processor chip Level 2 cache chip
Multi-chip module package
65
By Moshen - http://en.wikipedia.org/wiki/Image:Pentiumpro_moshen.jpg, CC BY-SA 2.5, https://commons.wikimedia.org/w/index.php?curid=2262471

Important: Register Renaming with a Reorder Buffer
 Output and anti dependencies are not true dependencies
 WHY? The same register refers to values that have nothing to
do with each other
 They exist due to lack of register ID’s (i.e. names) in the ISA
 The register ID is renamed to the reorder buffer entry that
will hold the register’s value
 Register ID → ROB entry ID ( a larger name space!)
 Architectural register ID → Physical register ID
 After renaming, ROB entry ID used to refer to the register
 This eliminates anti- and output- dependences
 Gives the illusion that there are a large number of registers
OOO רדסה י"פע אלש הצרהל ןאכ ורצונש תונויערה תא רושקנ האבה האצרהב
69

Recall: Data Dependence Types
True (flow) dependence
| r         ←   r |      |   op  r |     |            Read-after-Write   |     |
| --------------- | ---- | ------- | --- | ----------------------------- | --- |
| 3               |      | 1       | 2   |                               |     |
| r               | ←  r |   op  r |     | (RAW) -- True                 |     |
| 5               |      | 3       | 4   |                               |     |
Anti dependence
| r   | ←   r |   op  r |     | Write-after-Read  |     |
| --- | ----- | ------- | --- | ----------------- | --- |
| 3   |       | 1       | 2   |                   |     |
| r   | ←   r |   op  r |     | (WAR) -- Anti     |     |
| 1   |       | 4       | 5   |                   |     |

Output-dependence
| r   | ←  r |   op  r |     | Write-after-Write  |     |
| --- | ---- | ------- | --- | ------------------ | --- |
| 3   |      | 1       | 2   |                    |     |
| r   | ←  r |   op  r |     | (WAW) -- Output    |     |
| 5   |      | 3       | 4   |                    |     |
| r   | ←  r |   op  r |     |                    | 70  |
| 3   |      | 6       | 7   |                    |     |

Renaming Example םכרובע ליגרת
 Assume
 Register file has a pointer to the reorder buffer entry that
contains or will contain the value, if the register is not valid
 Reorder buffer works as described before
 Where is the latest definition of R3 for each instruction
below in sequential order?
LD R0(0) → R3
LD R3, R1 → R10
MUL R1, R2 → R3
MUL R3, R4 → R11
ADD R5, R6 → R3
ADD R7, R8 → R12
71

Register Renaming Example (On Your Own)
 Assume
 Register file has a pointer to the reorder buffer entry that
contains or will contain the value, if the register is not valid
 Reorder buffer works as described before
 Where is the latest definition of R3 for each instruction
below in sequential order?
LD R0(0) → R3
LD R3, R1 → R10
MUL R1, R2 → R3
MUL R3, R4 → R11
ADD R5, R6 → R3
ADD R3, R8 → R12
72

Reorder Buffer Example
Register File )RF( Reorder Buffer )ROB(
Oldest
R0 Entry 0
R1 Entry 1 instruction
R2 Entry 2
R3
R4
R5
R6
R7
Entry 8 Youngest
instruction
Entry 13
Entry 14
Entry 15
73
?dilaV
eulaV
Value
?dilaV
yrtnE
DI
ger
tseD
eulav
ger
tseD
?nettirw
ger
tseD
Tag
(pointer to
ROB entry)
Initially: all registers
are valid in RF
& ROB is empty
Simulate:
LD R0(0) → R3
LD R3, R1 → R10
MUL R1, R2 → R3
MUL R3, R4 → R11
ADD R5, R6 → R3
ADD R3, R8 → R12

Reorder Buffer Simulation
https://aca-iiith.vlabs.ac.in/exp/reorder-buffers/simulation/index.html
דוקה ותוא
ףקשהמ
םדוקה

Valid and Ready bits
Valid Bit
• Means: The instruction has finished executing and its result is ready
• Set to 1 when the execution unit writes the result back to the ROB
entry
• Before this, the entry holds a placeholder (or the instruction is still
executing)
Ready Bit
• Means: All operands needed by this instruction are available
• Set to 1 when all source registers have been resolved (either from the
register file or forwarded from earlier instructions that completed)
• The instruction can only start executing once the ready bit is 1

| ROB - | ה   תלוכת |   לש |   ףסונ |   םישרת |
| ----- | --------- | ---- | ------ | ------- |

In-Order Pipeline with Reorder Buffer
 Decode (D): Access regfile/ROB, allocate entry in ROB, check if
instruction can execute, if so dispatch חוליש instruction
 Execute (E): Instructions can complete out-of-order
 Completion (R): Write result to reorder buffer
 Retirement/Commit (W): Check for exceptions; if none, write result to
architectural register file or memory; else, flush pipeline and start from
םוכיסל
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
ROB
Load/store
79

המגוד
New 2023 1 out of 2
Credit: https://fuse.wikichip.org/news/7531/arm-introduces-the-cortex-x4-its-newest-
flagship-performance-core/

המגוד
New 2023 2 out of 2
Credit:
https://fuse.wikichip.org/news/7531/arm-introduces-the-cortex-x4-its-newe
st-flagship-performance-core/
see also:
https://en.wikipedia.org/wiki/ARM_Cortex-X4

Reorder Buffer Tradeoffs
 Advantages
 Conceptually simple for supporting precise exceptions
 Can eliminate false dependencies
 Disadvantages
 Reorder buffer needs to be accessed to get the results that
are yet to be written to the register file
 CAM or indirection → increased latency and complexity
 Other solutions aim to eliminate the disadvantages
Guy: Wikipedia: Content-addressable memory (CAM) is a
 History buffer
special type of computer memory used in certain very-high-
speed searching applications. It is also known as associative
 Future file
memory or associative storage[a] and compares input search
data (tag) against a table of stored data, and returns the
 Checkpointing
address of matching data 82

Solution II: History Buffer (HB)
 Idea: Update the register file when instruction completes,
but UNDO UPDATES when an exception occurs
 When instruction is decoded, it reserves an HB entry
 When the instruction completes, it stores the old value of
its destination in the HB
 When instruction is oldest and no exceptions/interrupts,
the HB entry discarded
 When instruction is oldest and an exception needs to be
handled, old values in the HB are written back into the
architectural state from tail to head
.RF תא ןכדע ןכמ רחאלו םייתסת הארוההש דע הכח – ימיספ אוה ROB
.םינוכדעה תא קחמ הגירח שי םא ךא RF תא דיימ ןכדע – ימיטפוא אוה HB
83

History Buffer
Func Unit
Register
Instruction History
Func Unit
File
Cache Buffer
Func Unit
Used only on exceptions
 Advantage:
 Register file contains up-to-date values for incoming instructions
→ History buffer access not on critical path
 Disadvantage:
 Need to read the old value of the destination register
 Need to unwind the history buffer upon an exception →
increased exception/interrupt handling latency 84

תונורסחה לע ףסונ רבסה
RF -ה ןיבל HB-ה ןיב ףסונ טרופב ךרוצ )1
.HB -ה יוקינב ךרוצ שי הגירח לש הרקמב )2
רדסה יפל הרזח בותכל( םישרת ואר
)הלעמל הטמלמ
קיתוה עיבצמה
תוארוה 1000 לש לוטיב
...ןמז חקול
HB
Write back all the
ריעצה עיבצמה values

Comparison of Two Approaches
 Reorder buffer – תינכתה רדס י"פע ,רחואמ לייפ רטסיגרה תא ןכדעמ
 Pessimistic register file update
 Update only with non-speculative values (in program order)
 Leads to complexity/delay in accessing the new values
 History buffer – הארוה םויס םע תידיימ לייפ רטסיגרה תא ןכדעמ
 Optimistic register file update
*
 Update immediately, but log the old value for recovery
**  Leads to complexity/delay in logging old values ( לש הרקמב
recovery)
Can we get the best of both worlds?
** -מ לובסל ילבמ * מ תונהל
 Principle: Heterogeneity םגו םג – ןורתפה
 Idea: Have both types of register files 86

Solution III: Future File (FF) + ROB
 Idea: Keep two register files (speculative and
architectural)
 Arch reg file: Updated in program order for precise exceptions
 Use a reorder buffer to ensure in-order updates
 Future reg file: Updated as soon as an instruction completes
(if the instruction is the youngest one to write to a register)
 Future file is used for fast access to latest register values
(speculative state) יביטלוקפס ןכלו תינכתה רדס יפל אל הז
 Frontend register file
 Architectural file is used for state recovery on exceptions
(architectural state)
 Backend register file 87

Future File
Func Unit
Arch.
Future
Instruction
ROB
Func Unit File
File
Cache
Func Unit
Data and Tag V
Used only on exceptions
 Advantage
 No need to read the new values from the ROB (no CAM or
םירמשנ ןאכ
indirection) or the old value of destination register
יפ לע םירטסיגרה
לא השיגב ךרוצ ןיא התע
םישדח םיכרע ליכמ
םהלש רדסה
 Disadvantage "יביטלוקפס" ROB -ה
אל( תינכתב
)םייביטלוקפס
 Multiple register files
 Need to copy arch. reg. file to future file on an exception
םירטסיגרה רפסמל יתנוכתמ ןמז .הגירח לש הרקמב םירטסיגרה תא קיתעהל ךירצ 88

תפסונ האירקל
Smith and Pleszkun [1988]
P&H CAQA Appendix C
(C.5)

In-Order Pipeline with Future File and Reorder Buffer
 Decode (D): Access future file, allocate entry in ROB, check if instruction
can execute, if so dispatch instruction
 Execute (E): Instructions can complete out-of-order
 Completion (R): Write result to reorder buffer and future file
 Retirement/Commit (W): Check for exceptions; if none, write result to
architectural register file or memory; else, flush pipeline, copy
architectural file to future file, and start from exception handler
 In-order dispatch/execution, out-of-order completion, in-order
Integer add
retirement
E
Integer mul
E E E E
R W
F D FP mul
E E E E E E E E
. . .
E E E E E E E E
Load/store
90

Can We Reduce the Overhead of Two Register Files?
?סלייפ רטסיגר ינש בקע תורוקת םצמצל ךיא
 Idea: Use pointers to data in front-end and retirement
 Have a single storage that stores register data values
 Keep two register maps (speculative and architectural); also called
register alias tables (RATs)
 Future map used for fast access to latest register values
(speculative state)
 Front-end register map
 Architectural map is used for state recovery on exceptions
(architectural state)
 Back-end register map
91

Future Map in Intel Pentium 4
A single
Future map
Boggs et al., “The
Microarchitecture of
RAT Register Alias Table
the Pentium 4
Processor,” Intel
Technology Journal,
2001.
Many modern
processors are similar:
-MIPS R10K
-Alpha 21264
הפמה
תינוטקטיכראה
תופמ יתשו דיחי ןורכז
92

םעפ לכ ןכדעתמ
תמייתסמש
הארוה
EAX תופמה יתשב המגודל םא
ןוסחאב םוקמ ותואל הנופ
הביתכ ןיאש רמוא הז
הזה רטסיגרל
רדס י"פע ףוסב ןכדעתמ
תינכתה

Reorder Buffer vs. Future Map Comparison
לוציפ רבע ןורכזה
)םוצמצ(
RAT Register Alias Table
ןסחאמ ןסחאמ
םינותנ סוטטס
םינוסחא ינש ,תחא הפמ דחא ןוסחא ,םייופימ 2
94
RRF=Retirement RF

Before We Get to Checkpointing …
 Let’s cover what happens on exceptions
 And branch mispredictions
95

Checking for and Handling Exceptions in Pipelining
 When the oldest instruction ready-to-be-retired is detected to
have caused an exception, the control logic:
 Recovers architectural state (register file, IP, and memory)
 Flushes all younger instructions in the pipeline
 Saves IP and registers (as specified by the ISA)
 Redirects the fetch engine to the exception handling routine
 Vectored exceptions = ה לא גולידל הגירחה גוס המ עדימ שישכ- exception
handler
ןיילפייפב תוגירחב לופיטו הקידב
:אבה ןפואב לעפת הרקבה לש הקיגולה ,וז הארוהב הגירח תילגתמו שורפל הנכומ הקיתו יכה הארוהה רשאכ
.)ןורכיזו RF, PC) ינוטקטיכראה בצמה רוזחש .א
.ןיילפייפב תוריעצה תוארוהה לכ לש הקיחמ .ב
.ISA-ה ידי-לע שרדנש יפכ םירטסיגרהו )IP) PC-ה תרימש .ג
.הגירחב תלפטמה הניטורל FETCH-ה ןונגנמ תיינפה .ד
(םרוגה היה המ) הגירחה לש גוסה המ עדימ םג אלא תיללכ הניטור שי קר אל רשאכ – תירוטקו ה 9 ג 6 ירח

Pipelining Issues: Branch Mispredictions
 A branch misprediction resembles an “exception”
 Except it is not visible to software (i.e., it is microarchitectural)
 What about branch misprediction recovery?
 Similar to exception handling except can be initiated before
the branch is the oldest instruction (not architectural)
 All three state recovery methods can be used
ROB, History Buffer, FF-ל הנווכה
 Difference between exceptions and branch mispredictions?
 Branch mispredictions are much more common than
exceptions
→ need fast state recovery to minimize performance impact
of mispredictions
97

How Fast Is State Recovery?
 Latency of state recovery affects
 Exception service latency
 Interrupt service latency
 Latency to supply the correct data to instructions fetched
after a branch misprediction
 Which ones above need to be fast?
 How do the three state maintenance methods fare in
terms of recovery latency?
 Reorder buffer
 History buffer
 Future file
98

Branch State Recovery Actions and Latency
 Reorder Buffer
 Flush instructions in pipeline younger than the branch
 Finish all instructions in the reorder buffer
 History buffer
 Flush instructions in pipeline younger than the branch
 Undo all instructions after the branch by rewinding from the
tail of the history buffer until the branch & restoring old
values one by one into the register file
 Future file
 Wait until branch is the oldest instruction in the machine
 Copy arch. reg. file to future file
 Flush entire pipeline
99

Can We Do Better?
 Goal: Restore the frontend state (future file) such that the
correct next instruction after the branch can execute right
away after the branch misprediction is resolved
 Idea: Checkpoint the frontend register state/map at the
time a branch is decoded and keep the checkpointed state
updated with results of instructions older than the branch
 Upon branch misprediction, restore the checkpoint associated
with the branch
 Hwu and Patt, “Checkpoint Repair for Out-of-order
Execution Machines,” ISCA 1987.
100

Checkpointing
 When a branch is decoded
 Make a copy of the future file/map and associate it with the
branch
 When an instruction produces a register value
 All future file/map checkpoints that are younger than the
instruction are updated with the value
 When a branch misprediction is detected
 Restore the checkpointed future file/map for the mispredicted
branch when the branch misprediction is resolved
 Flush instructions in pipeline younger than the branch
 Deallocate checkpoints younger than the branch
102

Checkpointing
 Advantages
 Correct frontend register state available right after
checkpoint restoration → Low state recovery latency
 …
 Disadvantages
 Storage overhead
 Complexity in managing checkpoints
 …
103

Many Modern Processors Use Checkpointing
 MIPS R10000
 Alpha 21264
 Pentium 4
 Yeager, “The MIPS R10000 Superscalar Microprocessor,”
IEEE Micro, April 1996
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro,
March-April 1999.
 Boggs et al., “The Microarchitecture of the Pentium 4
Processor,” Intel Technology Journal, 2001.
104

Summary: Maintaining Precise State
 Reorder buffer
תונורתפ 3
 History buffer
תוגירחל
 Future register file
תוששואתהה תצאה
 Checkpointing
 Readings
 Smith and Plezskun, “Implementing Precise Interrupts in Pipelined
Processors,” IEEE Trans on Computers 1988 and ISCA 1985.
 Hwu and Patt, “Checkpoint Repair for Out-of-order Execution Machines,”
ISCA 1987.
105

|         |     |     |
| ------- | --- | --- |
| וז תגצמ | ןאכ | דע  |