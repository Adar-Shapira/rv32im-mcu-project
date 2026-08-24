BGU 361-1-4201
Computer Architecture
Lecture 2: ISA Tradeoffs (Continued) and
RISC-V ISA
Lecturer: Dr. Guy Tel-Zur
Based on lectures and slides
by Prof. Onur Mutlu
Kevin Chang
Carnegie Mellon University
Spring 2015
1

ISA-level Tradeoffs: Instruction Length
Fixed length: Length of all instructions the same
– + Easier to decode single instruction in hardware
– + Easier to decode multiple instructions concurrently (superscalar processors –
next slide)
– -- Wasted bits in instructions (Why is this bad?)
– -- Harder-to-extend ISA (how to add new instructions?)
Variable length: Length of instructions different (determined by opcode and sub-opcode)
• + Compact encoding (Why is this good?)
• Intel 432: Huffman encoding (sort of). 6 to 321 bit instructions. How?
• - More logic to decode a single instruction רתוי םיירלקסרפוס םידבעמ
םיבכרומ
• - Harder to decode multiple instructions concurrently
Tradeoffs
– Code size (memory space, bandwidth, latency) vs. hardware complexity
– ISA extensibility and expressiveness vs. hardware complexity
– Performance? Energy? Smaller code vs. ease of decode
– ביטימ תודוקפ לש הנתשמ ךרוא :תרושקתל בושיחה סחי לע לכתסנ םא – םיעוציב
עובק ךרוא ינפ לע הנתשמ ךרואל ןורתי שיש ןכתי ןכלו ןורכזה םע.
2
– ןבלו רוחש ןיא היגרנא תניחבמ...

םיטייב 4 ךרואב תוארוה 4
םיחנעפמ 4
ןפואב םידבועה
עובק לדוגב תוארוה םע
יולת יתלב
-ה תדובע תא לבקמל ןתינ
instruction decoders
הנתשמ לדוגב תוארוה םע
-ה תדובעב תילאירס תולת שי
instruction decoders
רלאקס-רפוס

iAPX432 לש דועיתה ךותמ
GDP = General Data Processor
ןהלש העפוהה תורידת תא קודבנו תודוקפה לכ לש גנילייפורפ השענ
http://www.bitsavers.org/components/intel/iAPX_432/171860-004_iAPX_432_General_Data_Processor_Architecture_Reference_Manual_Feb84.pd
f

ISA-level Tradeoffs: Uniform Decode
 Uniform decode: Same bits in each instruction correspond to the
same meaning
 Opcode is always in the same location – ספימב ומכ
 Ditto operand specifiers, immediate values, …
 Many “RISC” ISAs: Alpha, MIPS, SPARC
+ Easier decode, simpler hardware
+ Enables parallelism: generate target address before knowing the instruction is a
branch
- Restricts instruction format (fewer instructions?) or wastes space
 Non-uniform decode
 E.g., opcode can be the 1st-7th byte in x86 – הנבמ רשפאמ הזו םילדג לש חווט םייק
יטקפמוק רתוי
+ More compact and powerful instruction format
- More complex decode logic
6

x86 vs. Alpha Instruction Formats
 x86: ינפוא
ןועימה
 Alpha:
הנבמה תוכזב
רשפאתמ עובקה
ןמזב :לובקימ
decode השענש
ןתינ הדוקפה לש
הרוצב
תיביטלוקפס
ןכותה תא ךירעהל
םיטיבה 21 לש
לש ינשה קלחב
הדוקפה 7

The SIB byte is structured as follows:
[Scale] [Index] [Base]
* Scale (2 bits): This field specifies a scaling factor that multiplies the value in the
index register.
- The possible values are: 00: Scale = 1, 01: Scale = 2, 10: Scale = 4, 11: Scale = 8
- The scaled index register is used to access elements of arrays with different
element sizes.
* Index (3 bits):
- This field specifies an index register (e.g., EAX, ECX, EDX, EBX, ESI, EDI).
- The value in the index register is multiplied by the scale factor.
* Base (3 bits):
- This field specifies a base register (e.g., EAX, ECX, EDX, EBX, ESI, EDI, ESP,
EBP).7
- The value in the base register is added to the scaled index value and any
displacement to calculate the final memory address.

* Address Calculation. The final memory address is calculated as follows:
Address = Base + (Index * Scale) + Displacement
- `Base`: The value in the base register (or 0 if no base register).
- `Index`: The value in the index register (or 0 if no index register).
- `Scale`: The scaling factor (1, 2, 4, or 8).
- `Displacement`: An optional signed displacement value (8, 32 bit).
* Example:
Consider the following assembly instruction:
mov eax, [ebx + ecx * 4]
In this case:
- `ebx` is the base register.
- `ecx` is the index register.
- The scale factor is 4.
The corresponding SIB byte would be:
- Scale: 10 (which is 4)
- Index: The encoding for `ecx`
- Base: The encoding for `ebx`

MIPS Instruction Format
R-type, 3 register operands

R-type
| 0     | rs    | rt    | rd    | shamt | funct |
| ----- | ----- | ----- | ----- | ----- | ----- |
| 6-bit | 5-bit | 5-bit | 5-bit | 5-bit | 6-bit |
I-type, 2 register operands and 16-bit immediate operand

I-type
| opcode | rs    | rt    | immediate |     |     |
| ------ | ----- | ----- | --------- | --- | --- |
| 6-bit  | 5-bit | 5-bit | 16-bit    |     |     |
J-type, 26-bit immediate operand

J-type
| opcode | immediate |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- |
| 6-bit  | 26-bit    |     |     |     |     |
Simple Decoding

 4 bytes per instruction, regardless of format
 must be 4-byte aligned (2 lsb of PC must be 2b’00)
format and fields easy to extract in hardware

10

RISC-V Instruction Format
R - Register-register operations
I - Short immediates and loads
S - Stores
B - Conditional branches
U - Long immediates
J - Unconditional jumps

ARM
12

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
14

ISA-level Tradeoffs: Number of Registers
 Affects:
 Number of bits used for encoding register address
םוקמ ספות הזה עדימה
 Number of values kept in fast storage (register file)
 (uarch) Size, access time, power consumption of register file
 Large number of registers:
+ Enables better register allocation (and optimizations) by compiler
+ Fewer saves/restores
- Larger instruction size
- Larger register file size (קפסה רתוי)
register allocation -ב רגתאה תא םיגדמ אבה ףקשה
15

ISA-level Tradeoffs: Addressing Modes
Addressing mode specifies how to obtain an operand of an instruction

Register

Immediate

Memory (displacement, register indirect, indexed, absolute, memory indirect, auto-

increment, auto-decrement, …)
More addressing modes: (→ smaller semantic gap)

+ help better support programming constructs (arrays, pointer-based accesses)
-- make it harder for the architect to design
-- too many choices for the compiler?
 Many ways to do the same thing complicates compiler design
 Wulf, “Compilers and Computer Architecture,” IEEE Computer 1981
17

ףסונ רבסה

Other Examples of ISA-level Tradeoffs –
םימדקתמ םיאשונ
 Condition codes vs. not – יאנת לש ומויק ךמס לע הלועפ, see "Status Register"
VLIW (=Very Long Instruction Word) vs. single instruction
 Precise vs. imprecise exceptions
 Virtual memory vs. not
 Unaligned access vs. not
 Hardware interlocks vs. software-guaranteed interlocking
 Software vs. hardware managed page fault handling
 Cache coherence (hardware vs. software)
 …
הנכותה וא הרמוחה י"ע תולת תקידב
25

Back to Programmer vs. (Micro)architect
 Many ISA features designed to aid programmers
 But, complicate the hardware designer’s job
:ךכל תואמגוד
 Virtual memory
 vs. overlay programming
 Should the programmer be concerned about the size of code blocks fitting
physical memory?
רשאכ ,Embedded תוכרעמב
 Addressing modes
ןורכיזל תסנכנ אל הלודג תינכת
תקלוחמ איה זאו לבגומה
 Unaligned memory access
י”פע ןורכיזל םינעטנש םילודומל
 Compiler/programmer needs to align data םע Swap השענ ןכ-ומכ .ךרוצה
תורחא תוינכת לש םיעטקמ
26

MIPS: Aligned Access
r0
|     | 3   | 2   | 1   | 0000 |     |
| --- | --- | --- | --- | ---- | --- |
MSB LSB
|     | byte-3 | byte-2 | byte-1 | byte-0 |     |
| --- | ------ | ------ | ------ | ------ | --- |
2 words
|     | byte-7 | byte-6 | byte-5 | byte-4 |     |
| --- | ------ | ------ | ------ | ------ | --- |
|     |        | 6      | 5      | 4      |     |
 LW/SW alignment restriction: 4-byte word-alignment
not designed to fetch memory bytes not within a word boundary

 not designed to rotate unaligned bytes into registers
 Provide separate opcodes for the “infrequent” case
LWL/LWR (=Load Word Left/Right) is slower

 Note LWL and LWR still fetch within word boundary
|     |     | A   | B   | C   | D   |
| --- | --- | --- | --- | --- | --- |
המ תא לאמשל אלמ
הנימי 6 ’סמ םוקממ אצמנש
| )םיטייבב איה הריפסה( |     | byte-6 | byte-5 | byte-4 | D   |
| -------------------- | --- | ------ | ------ | ------ | --- |
LWL  rd 6(r0) 
LWR  rd 3(r0) 
|     |     | byte-6 | byte-5 | byte-4 | byte-3 |
| --- | --- | ------ | ------ | ------ | ------ |
המ תא הנימי דמצה rd
הלאמשו 3 םוקמב אצמנש
)םיטייבב איה הריפסה(  ?N-bytes לדוגל  )aligned( תרשוימ איה A תבותכ םא םיקדוב ךיא
|     | MIPS: N=4 רובע |     |   ?A%N==0 לודומה תא םיקדוב טושפ |     |     |
| --- | -------------- | --- | ------------------------------- | --- | --- |
27

Demo
In the next slide there is a screen shot of the MARS MIPS simulator
For the instructor:
working directory:
/home/telzur/science/Teaching/CPU/lectures/02/code
Code: lwl_lwr_demo.asm
Open mars in the terminal.

| תבותככ שמשי | 123456 |  = 0001E240 |     |     |
| ----------- | ------ | ----------- | --- | --- |
|             | 10     |             | 16  |     |
|             | 3      | 2           | 1   | 0   |
 יכרע תלבט
 םירטסיגרה
 םוקמה
הלדגהב
םיטייבב

X86: Unaligned Access
םילימל השיג
תורשוימ אל
30

X86: Unaligned Access
 LD/ST instructions automatically align data that spans a “word”
boundary
 Programmer/compiler does not need to worry about where data is
stored (whether or not in a word-aligned location)
שי לבא בצמ לכב הכימת שי
םיעוציבב םולשת 31

What About ARM?
https://www.scss.tcd.ie/~waldroj/3d1/arm_arm.pdf
 ARM Architecture Reference Manual, Section A2.8
32

Aligned vs. Unaligned Access
...
םכרובע ליגרת
 Pros of having no restrictions on alignment
 Cons of having no restrictions on alignment
 Filling in the above: an exercise for you…
34

RISC vs. CISC
Credit:
“The Essentials of Computer
Organization and Architecture”,
5th edition by Linda Null

.יללכ ןפואב ISA -ה אשונ תגצה ןאכ דע
MIPS דבעמ לש ISA תא ריכנו ךישמנ ןאכמ

MIPS ISA
טוריפב דמלנ האבה תגצמב
.MIPS דבעמ לש ISA-ה לע
ISA-ה תודוא םיפקש וז תגצמ ךשמהב
לע-טבמב MIPS לש
תגצמה( MIPS לש ילבמסא לע דומילה רמוח
תוגצמה .H&H לש רפסב 6 קרפ ךותמ חקלנ )האבה
.לדומב תואצמנ

MIPS R2000 Program VViissiibbllee SSttaattee
Program Counter
**Note** r0=0
32-bit memory address r1
r2
of the current instruction
General Purpose
Register File
M[0]
32 32-bit words
M[1]
named r0...r31
M[2]
M[3]
M[4]
Memory
232 by 8-bit locations (4 Giga Bytes)
32-bit address
M[N-1]

Data Format
 Most things are 32 bits
instruction and data addresses
signed and unsigned integers
just bits
 Also 16-bit half word and 8-bit byte
 Floating-point numbers
IEEE standard 754
float: 8-bit exponent, 23-bit significant
double: 11-bit exponent, 52-bit significant

Big Endian vs. Little Endian
(Part I, Chapter 4, Gulliver’s Travels)
 32-bit signed or unsigned integer comprises 4 bytes
LSB
MSB
(least significant)
|     | 8-bit |     | 8-bit | 8-bit | 8-bit |     |     |
| --- | ----- | --- | ----- | ----- | ----- | --- | --- |
(most significant)
On a byte-addressable machine . . . . . . .

Big Endian    L S B         M   S B         Little Endian
MSB LSB
| byte 0 | byte 1 | byte 2  | byte 3  | byte 3  | byte 2  | byte 1 | byte 0 |
| ------ | ------ | ------- | ------- | ------- | ------- | ------ | ------ |
| byte 4 | byte 5 | byte 6  | byte 7  | byte 7  | byte 6  | byte 5 | byte 4 |
| byte 8 | byte 9 | byte 10 | byte 11 | byte 11 | byte 10 | byte 9 | byte 8 |
byte 12 byte 13 byte 14 byte 15 byte 15 byte 14 byte 13 byte 12
byte 16 byte 17 byte 18 byte 19 byte 19 byte 18 byte 17 byte 16
pointer points to the big end pointer points to the little end
 What difference does it make?

htonl = Host TO Network Long
It's used in network programming to convert a 32-bit integer from host byte order to network byte
order (big-endian). This is important because different systems may use different byte orders, and
network protocols typically use big-endian order.
My computer byte order is Little Endian
and this is why the order got reversed

Instruction Formats
 3 simple formats

  R-type, 3 register operands
R-type
| 0     | rs    | rt    | rd    | shamt | funct |
| ----- | ----- | ----- | ----- | ----- | ----- |
| 6-bit | 5-bit | 5-bit | 5-bit | 5-bit | 6-bit |
  I-type, 2 register operands and 16-bit immediate operand
I-type
| opcode | rs    | rt    | immediate |     |     |
| ------ | ----- | ----- | --------- | --- | --- |
| 6-bit  | 5-bit | 5-bit | 16-bit    |     |     |
  J-type, 26-bit immediate operand
J-type
| opcode | immediate |     |     |     |     |
| ------ | --------- | --- | --- | --- | --- |
| 6-bit  | 26-bit    |     |     |     |     |
Simple Decoding

  4 bytes per instruction, regardless of format
  must be 4-byte aligned          (2 lsb of PC must be 2b’00)
  format and fields readily extractable

ALU Instructions
 Assembly (e.g., register-register signed addition)
| ADD rd |  rs  rt |     |     |     |     |
| ------ | ------- | --- | --- | --- | --- |
| reg    | reg reg |     |     |     |     |
Machine encoding

R-type
| 0     | rs    | rt    | rd    | 0     | ADD   |
| ----- | ----- | ----- | ----- | ----- | ----- |
| 6-bit | 5-bit | 5-bit | 5-bit | 5-bit | 6-bit |
Semantics

  GPR[rd] ←  GPR[rs] + GPR[rt]
  PC ←  PC + 4
 Exception on “overflow”
 Variations
  Arithmetic: {signed, unsigned} x {ADD, SUB}
  Logical: {AND, OR, XOR, NOR}
  Shift: {Left, Right-Logical, Right-Arithmetic}

Reg-Reg Instruction Encoding
םיבצמ 8 → טיב 3
[MIPS R4000 Microprocessor User’s Manual]
תוארוהה
– תודחוימ תוארוה
תוידוסיה
ואר – ISA-ה תבחרה
)טיב 6 כ”הס(
.אבה ףקשה
What patterns do you see? Why are they there?

MIPS -ב ISA-ה לש הבחרה
R4000

ALU Instructions
 Assembly (e.g., regi-immediate signed additions)
| ADDI rt |  rs  immediate |     |     |
| ------- | -------------- | --- | --- |
| reg     | reg            | 16  |     |
Machine encoding

I-type
| ADDI  | rs    | rt    | immediate |
| ----- | ----- | ----- | --------- |
| 6-bit | 5-bit | 5-bit | 16-bit    |
Semantics

  GPR[rt] ←  GPR[rs] + sign-extend (immediate)
  PC ←  PC + 4
 Exception on “overflow”
 Variations
  Arithmetic: {signed, unsigned} x {ADD, SUB}
  Logical: {AND, OR, XOR, LUI}

Assembly Programming 101
 Break down high-level program constructs into a sequence
of elemental operations
 E.g. High-level Code
f = ( g + h ) – ( i + j )
Assembly Code

|   suppose f, g, h, i, j are in r |     |                     |     |     |     | , r | , r | , r | , r |
| -------------------------------- | --- | ------------------- | --- | --- | --- | --- | --- | --- | --- |
|                                  |     |                     |     |     |     | f   | g   | h i | j   |
|   suppose r                      |     |  is a free register |     |     |     |     |     |     |     |
temp
|     | add r |      |  r   |  r  | # r      |  = g+h |      |     |     |
| --- | ----- | ---- | ---- | --- | -------- | ------ | ---- | --- | --- |
|     |       | temp |      | g h | temp     |        |      |     |     |
|     | add r |  r   |  r   | # r |  = i+j   |        |      |     |     |
|     |       | f    | i j  |     | f        |        |      |     |     |
|     | sub r |  r   |      |  r  | # f = r  |        |  – r |     |     |
|     |       | f    | temp | f   |          | temp   |      | f   |     |

Load Instructions
 Assembly (e.g., load 4-byte word)
| LW rt |  offset |  (base | )   |     |
| ----- | ------- | ------ | --- | --- |
|       | reg     | 16     | reg |     |
Machine encoding

I-type
| LW    |     | base  | rt    | offset |
| ----- | --- | ----- | ----- | ------ |
| 6-bit |     | 5-bit | 5-bit | 16-bit |
Semantics

  effective_address = sign-extend(offset) + GPR[base]
  GPR[rt] ←  MEM[ translate(effective_address) ]
  PC ←  PC + 4
 Exceptions
  address must be “word-aligned”
  What if you want to load an unaligned word?
  MMU (=Memory Management Unit) exceptions

Store Instructions
 Assembly (e.g., store 4-byte word)
| SW rt |  offset |  (base | )   |     |
| ----- | ------- | ------ | --- | --- |
|       | reg     | 16     | reg |     |
Machine encoding

I-type
| SW    |     | base  | rt    | offset |
| ----- | --- | ----- | ----- | ------ |
| 6-bit |     | 5-bit | 5-bit | 16-bit |
Semantics

  effective_address = sign-extend(offset) + GPR[base]
  MEM[ translate(effective_address) ] ←  GPR[rt]
  PC = PC + 4
 Exceptions
  address must be “word-aligned”
  MMU exceptions

Assembly Programming 201
 E.g. High-level Code
A[ 8 ] = h + A[ 0 ]
where A is an array of integers (4–byte each)
 Assembly Code
| suppose &A, h are in r |     |     |     |     | , r |     |
| ---------------------- | --- | --- | --- | --- | --- | --- |

|             |     |     |                     |     | A h |     |
| ----------- | --- | --- | ------------------- | --- | --- | --- |
|   suppose r |     |     |  is a free register |     |     |     |
temp
| LW r  |      |  0(r  | )     # r      |     |  = A[0]     |      |
| ----- | ---- | ----- | -------------- | --- | ----------- | ---- |
|       | temp |       | A              |     | temp        |      |
| add r |      |  r    |  r             | # r |  = h + A[0] |      |
|       | temp |       | h temp         |     | temp        |      |
| SW r  |      |  32(r | )   # A[8] = r |     |             |      |
|       | temp |       | A              |     |             | temp |
# note A[8] is 32 bytes

                # from A[0]

Load Delay Slots
LW ra ---
addi r- ra r-
addi r- ra r-
 R2000 load has an architectural latency of 1 inst*.
the instruction immediately following a load (in the “delay slot”)
still sees the old register value
the load instruction no longer has an atomic semantics
Why would you do it this way?
 Is this a good idea? (hint: R4000 redefined LW to complete
atomically)
*BTW, notice that latency is defined in “instructions” not cyc. or sec.

Control Flow Instructions
Assembly Code
Control Flow Graph
(linearized)
 C-Code
code A code A
{ code A }
if X==Y then if X==Y if X==Y
True False
goto
{ code B }
code C
else
code B code C
{ code C }
{ code D }
goto
code B
code D
code D
these things are called basic blocks

(Conditional) Branch Instructions
 Assembly (e.g., branch if equal)
| BEQ rs  rt |  immediate |     |     |
| ---------- | ---------- | --- | --- |
reg reg 16
Machine encoding

I-type
| BEQ   | rs    | rt    | immediate |
| ----- | ----- | ----- | --------- |
| 6-bit | 5-bit | 5-bit | 16-bit    |
Semantics

  target = PC + sign-extend(immediate) x 4
|   if GPR[rs]==GPR[rt]  |       | then        | PC = target |
| ---------------------- | ----- | ----------- | ----------- |
|                        | else  | PC = PC + 4 |             |
 How far can you jump?
 Variations
PC + 4 w/
  BEQ, BNE, BLEZ, BGTZ branch delay slot
Why isn’t there a BLE or BGT instruction?

Jump Instructions
 Assembly
J immediate
26
 Machine encoding
J-type
J immediate
6-bit 26-bit
 Semantics
target = PC[31:28]x228 | zero-extend(immediate)x4
bitwise-or
PC ← target
 How far can you jump?
 Variations
- Jump and Link PC + 4 w/
- Jump Registers branch delay slot

Assembly Programming 301
 E.g. High-level Code
fork
if (i == j) then
then
e = g
else
else
e = h
f = e
Assembly Code join

|   - suppose e, f, g, h, i, j are in r |     |     | , r | , r , r | , r , r |
| ------------------------------------- | --- | --- | --- | ------- | ------- |
|                                       |     |     | e f | g h     | i j     |
  bne r
|     |  r  L1 | # L1 and L2 are addr labels |     |     |     |
| --- | ------ | --------------------------- | --- | --- | --- |
i j
# assembler computes offset
|   add r |  r  r0 | # e = g |     |     |     |
| ------- | ------ | ------- | --- | --- | --- |
e g
  j L2
| L1:  add r |  r  r0 | # e = h |     |     |     |
| ---------- | ------ | ------- | --- | --- | --- |
e h
| L2:  add r |  r  r0 | # f = e |     |     |     |
| ---------- | ------ | ------- | --- | --- | --- |
f e
  . . . .

Branch Delay Slots
R2000 branch instructions also have an architectural latency of

1 instructions
  the instruction immediately after a branch is always executed (in
fact PC-offset is computed from the delay slot instruction)
  branch target takes effect on the 2nd instruction
|     |     | bbnnee  rr |   rr |   LL11 |
| --- | --- | ---------- | ---- | ------ |
bne r  r  L1
|     |     |     | ii  | jj  |
| --- | --- | --- | --- | --- |
i j
nnoopp
|     |     | add r |  r  |  r0  |
| --- | --- | ----- | --- | ---- |
add r  r  r0
|     |     |     | e   | g   |
| --- | --- | --- | --- | --- |
e g
j L2
j L2
j L2
|            |        | add r nop  |  r         |  r0         |
| ---------- | ------ | ---------- | ---------- | ----------- |
|            |        |            | e          | g           |
| L1:  add r |  r  r0 | LL11::     | aadddd  rr |   rr   rr00 |
ee hh
e h
|            |        | LL22::     | aadddd  rr |   rr   rr00 |
| ---------- | ------ | ---------- | ---------- | ----------- |
| L2:  add r |  r  r0 |            |            |             |
ff ee
f e
|     |     |        | ..  ..  ..  ..   |     |
| --- | --- | ------ | ---------------- | --- |
. . . .

Function Call and Return
Jump and Link: JAL offset

26
return address = PC + 8
target = PC[31:28]x228 | zero-extend(immediate)x4
bitwise-or
PC ← target
GPR[r31] ← return address
On a function call, the callee needs to know where to go back to
afterwards
Jump Indirect: JR rs

reg
target = GPR [rs]
PC ← target
PC-offset jumps and branches always jump to the same target
every time the same instruction is executed
Jump Indirect allows the same instruction to jump to any
location specified by rs (usually r31)

Assembly Programming 401
Callee
Caller
_myfxn: ... code B ...
... code A ...
JR r31
JAL _myfxn
... code C ...
JAL _myfxn
... code D ...
..... A  B  C  B  D .....

call return call return
 How do you pass argument between caller and callee?
 If A set r10 to 1, what is the value of r10 when B returns to C?
 What registers can B use?
 What happens to r31 if B calls another function

Caller and Callee Saved Registers
 Callee-Saved Registers
Caller says to callee, “The values of these registers should not
change when you return to me.”
Callee says, “If I need to use these registers, I promise to save
the old values to memory first and restore them before I return
to you.”
 Caller-Saved Registers
Caller says to callee, “If there is anything I care about in these
registers, I already saved it myself.”
Callee says to caller, “Don’t count on them staying the same
values after I am done.

R2000 Register Usage Convention
 r0: always 0
 r1: reserved for the assembler
 r2, r3: function return values
 r4~r7: function call arguments
 r8~r15: “caller-saved” temporaries
 r16~r23 “callee-saved” temporaries
 r24~r25 “caller-saved” temporaries
 r26, r27: reserved for the operating system
 r28: global pointer
 r29: stack pointer
 r30: callee-saved temporaries
 r31: return address

R2000 Memory Usage Convention
high address
stack space
grow down
free space
stack pointer
GPR[r29]
grow up
dynamic data
static data
binary executable
text
reserved
low address

Calling Convention
caller saves caller-saved registers
1.
caller loads arguments into r4~r7
2.
caller jumps to callee using JAL
3.
callee allocates space on the stack (dec. stack pointer)
4.
callee saves callee-saved registers to stack (also r4~r7, old
5.
r29, r31)
....... body of callee (can “nest” additional calls) .......
callee loads results to r2, r3
1.
callee restores saved register values
2.
JR r31
3.
caller continues with return values in r2, r3
4.
........
eugolorp
eugolipe
.......

To Summarize: RISC-V / MIPS / RISC
 Simple operations
2-input, 1-output arithmetic and logical operations
few alternatives for accomplishing the same thing
 Simple data movements
ALU ops are register-to-register (need a large register file)
“Load-store” architecture
 Simple branches
limited varieties of branch conditions and targets
 Simple instruction encoding
all instructions encoded in the same number of bits
only a few formats
Loosely speaking, an ISA intended for compilers rather than
assembly programmers