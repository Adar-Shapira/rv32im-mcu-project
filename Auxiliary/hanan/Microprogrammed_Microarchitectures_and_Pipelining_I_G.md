תתייזזככררממ דדוובבייעע ’’חחיי תתררווטטקקטטייככרראא
336611--11--44220011
77
’’ססממ ההאאצצררהה
MMiiccrroopprrooggrraammmmeedd
MMiiccrrooaarrcchhiitteeccttuurreess aanndd PPiippeelliinniinngg II
ררווצצ-- ללתת אאייגג רר”” דד
Last update 19/5/2022, 27/4/2023, 12/6/2024

Multi-Cycle Control
(MIPS!)
Copyright © 2014 Elsevier Inc. All rights reserved.

Multi-cycle -ב רקבה
Control
MemtoReg
Unit
RegDst
IorD Multiplexer
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

RISC-V דבעמב םיבצמה תמרגאיד

MIPS FSM
*
הז םישרתב
10 םיראותמ
םיבצמ
FIGURE D.3.1 The finite-state diagram for multicycle control.
5
Copyright © 2014 Elsevier Inc. All rights reserved.

16 lines
2 lines
.תוסינכ 10
.תואיצי 20
ןוסחא המכ
?שרדנ דדוקנ םיבצמ 10
2^10 * םיטיב 4 תועצמאב
20=20,480bit=
=20kb=
2,560byte
FIGURE D.3.2 The control unit for MIPS will consist of some control logic and a register to hold the state. The
state register is written at the active clock edge and is stable during the clock cycle
6
Copyright © 2014 Elsevier Inc. All rights reserved.

PPLLAA
המגוד
1 2 3 4 5 6 7 8 9 A B CD E F
AND PCWrite= “1” + “A"
"1" = not(S0)*not(S1)*not(S2)*not(S3)
"A"=S3*not(S2)*not(S1)*S0
State9-ו State0-ב ליעפ אוה PCWrite ורכזת
State0=0000
State9=1001
D.3.4 -ב תמא תלבט ואר
OR
םינסחאמ ךיא :ש
?הלבט
PLA :ת

Multi-Cycle Microprogram Control
Implementing the Next-State
Function with a Sequencer
Appendix D Part 2 PPTs
Copyright © 2014 Elsevier Inc. All rights reserved.

state
next state
sequencer
FIGURE D.4.1 The control unit using an explicit counter to compute the next state. In this control unit, the next state is
computed using a counter (at least in some states). By comparison, Figure D.3.2 encodes the next state in the control logic for
every state. In this control unit, the signals labeled AddrCtl control how the next state is determined.
9
Copyright © 2014 Elsevier Inc. All rights reserved.

Next state
FIGURE D.4.2 This is the address select logic for the control unit of Figure D.4.1.
10
Copyright © 2014 Elsevier Inc. All rights reserved.

FIGURE D.4.6 The control unit as a microcode. The use of the word “micro” serves to distinguish between the
program counter in the datapath and the microprogram counter, and between the microcode memory and
the instruction memory.
11
Copyright © 2014 Elsevier Inc. All rights reserved.

Translating a Microprogram to
Hardware (Control Signals)
אלל וא םע םיפוס םיבצמ תנוכמכ םרגורפורקימ לש ןונגנמ שממל רשפאש וניאר
.SEQUENCER
:הנוש טעמ תולכתסה תדוקנב וישכע
תטלוש רשא תוארוה ורקימ לש )השדח( תונכת תפש ןיעמ רוציל תלוכי ונל שי
אבה ףקשה ואר – ןומזתה יבצמ 4 לעו הרקבה תותוא 18 לע

תלבט תא ואר
-ה לש תמאה
ALU decoder
תמדוקה תגצמב
= תוארוה 22
+ הרקב יוק 18
יבצמ 4
sequencer
FIGURE D.5.1 Each microcode field translates to a set of control signals to be set. These 22 different values of the fields
specify all the required combinations of the 18 control lines. Control lines that are not set, which correspond to actions, are 0
by default. Multiplexor control lines are set to 0 if the output matters. If a multiplexor control line is not explicitly set, its output is
a don’t care and is not used.
13
Copyright © 2014 Elsevier Inc. All rights reserved.

6 3
9 5
8 AdrCmp - 2 בצממ לוציפ
2
2
Decode -1 בצממ לוציפ
ולבקתי םיבצמה ראש לכ
תועצמאב בצמל 1 תפסוהמ
,הלחתהל בוש וליבוי וא הנומה
.אבה ףקשה ואר – 0 בצמ
FIGURE D.4.3 The dispatch ROMs each have 26 5 64 entries that are 4 bits wide, since that is the number of
bits in the state encoding. This figure only shows the entries in the ROM that are of interest for this subset. The
first column in each table indicates the value of Op, which is the address used to access the dispatch ROM. The
second column shows the symbolic name of the opcode. The third column indicates the value at that address in
the ROM.
14
Copyright © 2014 Elsevier Inc. All rights reserved.

The sequencing field can have 4 values: Fetch, Dispatch1,
Dispach2 and Sequential.
ןכל ,םיימעפ תועיפומ הלאה תורושה 2
םימור 2 םישרדנ
FIGURE D.5.2 The two microcode dispatch ROMs showing the contents in symbolic form and using the labels
in the microprogram.
Summary
Independent of whether the control is represented as a finite-state diagram or as a
microprogram, translation to a hardware control implementation is similar. Each state or
microinstruction asserts a set of control outputs and specifies how to choose the next state.
The next-state function may be implemented by either encoding it in a finite-state machine or
using an explicit sequencer. The explicit sequencer is more efficient if the number of states is
large and there are many sequences of consecutive states without branching.
15
Copyright © 2014 Elsevier Inc. All rights reserved.

The control signals decoder
T1
We just implement the table of slide 54:
      Let’s look at ALUSrcA: it is “0” in states 0 and 1 and it is “1” in states 2, 6 and 8. In all other states we don’t care.
     let’s look at PCWrite: it is “1” in states 0 and 9. In all other states it must be “0”.
And so, we’ll fill the table below and build the decoder.
|       | state |       |                | Control signals |     |     |
| ----- | ----- | ----- | -------------- | --------------- | --- | --- |
|       | S3 S2 | S1 S0 | ALUSrcAPCWrite | PCWriteCond     |     |     |
| fetch | 0 0   | 0 0   | 0              | 1               | 0   |     |
decode
|     | 0 0 | 0 1 | 0   | 0   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- |
AdrCmp
|     |  0 0 | 1 0 | 1   | 0   | 0   |     |
| --- | ---- | --- | --- | --- | --- | --- |
load
|     | 0 0 | 1 1 | X   | 0   | 0   |     |
| --- | --- | --- | --- | --- | --- | --- |
| WB  | 0 1 | 0 0 |     | 0   | 0   |     |
X
| store | 0 1 | 0 1 | X   | 0   | 0   |     |
| ----- | --- | --- | --- | --- | --- | --- |
ALU
|        | 0 1        | 1 0 | 1   |     |     |                  |
| ------ | ---------- | --- | --- | --- | --- | ---------------- |
|        |            |     |     | 0   | 0   |                  |
| WBR    | 0 1        | 1 1 | X   | 0   | 0   |                  |
| branch | 1 0        | 0 0 | 1   | 0   | 1   |                  |
| jump   |            |     |     |     |     | :ןוסחאה חפנ      |
|        | 1 0        | 0 1 | X   | 1   | 0   |                  |
|        | All other  |     | X   | 0   | 0   | 24X16 = 256bits  |
combinations

| T   |     | State Machine “next state calc.”  |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
2
logic
opcode
|     |                          |     |     |     |     | current state |       |     |     | next state |     |     |     |     |     |
| --- | ------------------------ | --- | --- | --- | --- | ------------- | ----- | --- | --- | ---------- | --- | --- | --- | --- | --- |
|     | IR31IR30IR29IR28IR27IR26 |     |     |     |     | S3            | S2 S1 | S0  | S3  | S2 S1      | S0  |     |     |     |     |
Fetch
      0
|     | X   | X   | X   | X X | X   | 0   | 0 0 | 0   | 0   | 0 0 | 1   |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Decode
| R-type | 0   | 0   | 0   | 0 0 | 0   | 0   | 0 0 | 1   | 0   | 1 1 | 0   |     |     |     |     |
| ------ | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
         1
j
|     |     |     |     |     |     |     |     |     |     |     |     |     | lw+sw | beq |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- |

|       | 1   | X   | X   | X X | X   | 0   | 0 0 | 1   | 0   | 0 1 | 0   | AdrCmp  |        |     |     |
| ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | ------ | --- | --- |
| lw+sw |     |     |     |     |     |     |     |     |     |     |     |         | R-type |     |     |
Jump
|     |     |     |     |     |     |     |     |     |     |     |     |         2 |     | Branch |      |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | --- | ------ | ---- |
| lw  | X   | X   | 0   | X X | X   | 0   | 0 1 | 0   | 0   | 0 1 | 1   |           | s   |        |    9 |
    8
|     |     |     |     |     |     |     |     |     |     |     |     | lw  | ALU |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
w
|     |     |     |     |     |     |     |     |     |     |     | Load |     |     6 |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | ----- | --- | --- |
| sw  |     |     |     |     |     | 0   | 0 1 | 0   | 0   | 1 0 | 1    |     |       |     |     |
|     | X   | X   | 1   | X X | X   |     |     |     |     |     |      |     | Store |     |     |

5

3
WBR
WB
|     |     |     |     |     |     |     |     |     |     |     |     |       4 |     7 |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | ----- | --- | --- |
R-type=000000, lw=100011, sw=101011, beq=000100, bne=000101, lui=001111,
j=0000010, jal=000011, addi=001000
 :ןוסחאה חפנ
210X4 = 4096bits

תודומע 16+2 לע )תורוש( םילימ רשע :הנומ םע שומימב ”לודגה“ ROM -ה ןכות ,התע
.םיטיב 180 כ"הס ,)םיטיב(
:)טיב 64( הסינכב םיבצמ 6 לע טיב 4 לש )אצומ=( בחורב א"כ ,dispatchers -ה 2 ,ףסונב
26 X 4 = 64 X 4 =256; 2^6 combinations X 4bit value
2 dispatchers: 2 X 256 = 512
Total: 180 + 512 = 692 bit
רשפא .)הנושארה ROM ה תסרג 4.3Kb תמועל( טיב 692 כ"הסבו ,טיב512 = 2 לופכ )64x4(
.sparse םה dispatchers-ה בורו רחאמ רתוי םצמצל וליפא
10X18=180bit
תורוש 10
בחורב
18=16+2
See table D.3.3
FIGURE D.4.5 The contents of the control memory for an implementation using an explicit counter. The first column shows
the state, while the second shows the datapath control bits, and the last column shows the address-control bits in each
control word. Bits 17–2 are identical to those in Figure D.3.7.
T1 T2
From & SQUENCER
:) אלל( ירוקמה לדומה יפ-לע
18
T1: 24 X 16 = 256 = הרקבה תותוא, T2: 210 X 4 = 4096, total: 4.3Kb -םיבצמה

180bit
512bit
FIGURE D.4.6 The control unit as a microcode. The use of the word “micro” serves to
distinguish between the program counter in the datapath and the microprogram counter,
and between the microcode memory and the instruction memory.
19
Copyright © 2014 Elsevier Inc. All rights reserved.

Motorola 68000
http://www.easy68k.
com/paulrsm/doc/dp
bm68k2.htm

https://www.righto.com/2023/04/8086-microcode-string-operations. html

Credit: Harris & Harris
DD&CA

End of Appendix D slides (MIPS)
Appendix C (RISC-V Edition)

Thoughts on Control &
Microprogramming

The Control Store: Some Questions
 What control signals can be stored in the control store?
Those independent on data םינותנב םייולת םניאש הלא
vs.
 What control signals have to be generated in hardwired
logic?
 i.e., what signal cannot be available without processing in
the datapath?
Those dependent on data םינותנב םייולתש הלא
 Remember the datapath
 One PCSrc signal depends on processing that happens in
the datapath (bcond logic)
25

Variable-Latency Memory
 The ready signal (R) enables memory read/write to
execute correctly
 Example: transition from one state to another state is
controlled by the R bit asserted by memory when memory
data is available
 Could we have done this in a single-cycle
microarchitecture?
בלשמ רבעמל בל םישנו אבה ףקשב – LC3b -מ המגוד תוארהל
.35 בלשל 33
:ץבוקה םוקימ
file:///home/telzur/science/Teaching/CPU/Materials/LC3b/state_machine.pdf
26

Aside: Memory Mapped I/O
 Address control logic determines whether the specified
address of LDx and STx are to memory or I/O devices
 Correspondingly enables memory or I/O devices and
sets up muxes
 This is another instance where the final control signals
(e.g., MEM.EN or INMUX/2) cannot be stored in the
control store
 These signals are dependent on address
28

See section C6
ארקמ
DDR=Display data register
DSR=Display status register
KBDR=Keyboard data register
KBSR=Keyboard status register

The Microsequencer: Advanced Questions
 What happens if the machine is interrupted?
 What if an instruction generates an exception?
 How can you implement a complex instruction using this
control structure?
 Think REP MOVS
(Guy: REP MOVS means: repeat moving data string into another
data string in memory. REP is an instruction prefix )
30

...REP MOVS תודוא דוע... :בגא תרעה

Some good examples for Microprogramming
 Implement REP MOVS in a microarchitecture using
microprogramming
 Guidelines: What changes, if any, do you make to the
 state machine?
 datapath?
 control store?
 microsequencer?
 Another good example: Implement unaligned word
memory access using microprogramming
32

https://developer.amd.com/wordpress/media/2012/10/SOG_16h_52128_PUB_Rev1_1.pdf

The Power of Abstraction
 The concept of a control store of microinstructions
enables the hardware designer with a new abstraction:
microprogramming
 The designer can translate any desired operation to a
sequence of microinstructions
 All the designer needs to provide is
 The sequence of microinstructions needed to implement
the desired operation
 The ability for the control logic to correctly sequence
through the microinstructions
 Any additional datapath control signals needed (no need if
the operation can be “translated” into existing control
signals)
35

Advantages of Microprogrammed Control
 Allows a very simple design to do powerful computation by
controlling the datapath (using a sequencer)
 High-level ISA translated into microcode (sequence of microinstructions)
 Microcode enables a minimal datapath to emulate an ISA
 Microinstructions can be thought of as a user-invisible ISA (micro ISA)
 Enables easy extensibility of the ISA
 Can support a new instruction by changing the microcode
 Can support complex instructions as a sequence of simple microinstructions
 If I can sequence an arbitrary instruction then I can
sequence an arbitrary “program” as a microprogram
sequence
 will need some new state (e.g. loop counters) in the microcode for
sequencing more elaborate programs
36

Update of Machine Behavior
 The ability to update/patch microcode in the field (after a
processor is shipped) enables
 Ability to add new instructions without changing the processor!
 Ability to “fix” buggy hardware implementations
 Examples
 IBM 370 Model 145: microcode stored in main memory, can be
updated after a reboot
 IBM System z: Similar to 370/145.
 Heller and Farrell, “Millicode in an IBM zSeries processor,” IBM
JR&D, May/Jul 2004.
 B1700 microcode can be updated while the processor is
running
 User-microprogrammable machine! 37

Credit: Stanford Seminar - New Golden Age for Computer
Architecture - John Hennessy
https://www.youtube.com/watch?v=bfPV4x-HrUI&t=3343s

IBM 370/145

IBM 370 Model 145
http://bitsavers.informatik.uni-stuttgart.de/pdf/ibm/370/GF20-0385-0_An_Introduction_to_Microprogramming_Dec71.pdf

היירפסה
תימואלה
1975
הנושב ,הזה בשחמב
היה ןתינ ,לבוקמהמ
u-ISA ה תא תוארל
תונשל היה ןתינ ףאו
הרוצב דוקורקימה תא
תעב תימניד
.הצר תכרעמהש
.םויכ וזכ תופיקש ןיא
הבוט תורשפא םג וז
ילילש דצ םג שי לבא
תחטבא ינוכיס אוהו
.עדימ

Intel 8086
-srossecorp-6808-woh/11/2202/moc.othgir.www//:sptth
:tiderc
lmth.enigne-edocorcim

Microcode update for Intel X86-64
(in my laptop)
Next slide

Microcode patch, an example:
CVE-2020-8696
Improper removal of sensitive information before storage
or transfer in some Intel(R) Processors may allow an
authenticated user to potentially enable information
disclosure via local access.
References:
https://lists.debian.org/debian-lts-announce/2021/02/msg00
007.html
https://nvd.nist.gov/vuln/detail/CVE-2020-8698
https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8
698

Review: The Power of Abstraction
 The concept of a control store of microinstructions enables
the hardware designer with a new abstraction:
microprogramming
היצקרטסבאה גשומ תא רתוי דוע ללכשמ microprogramming לש טפסנוקה
 The designer can translate any desired operation to a
sequence of microinstructions
 All the designer needs to provide is
 The sequence of microinstructions needed to implement the
desired operation
 The ability for the control logic to correctly sequence through
the microinstructions ( micro-sequencer )
 Any additional datapath elements and control signals needed
(no need if the operation can be “translated” into existing
control signals)
לש רדסה תא עובקל אוה רתונש המ לכ .תוארוה-ורקימ לש הרדסל הארוה לכ רימהל ןתינ
ספ-הטאדב יונישב ךרוצ ןיא םימייק םילנגיס לש םוגרתל תנתינ הארוהה םא .תוארוה-ורקימה 45

Microcoded Multi-Cycle MIPS
Design
:תורהבה - איג
:םימעט ינשמ תיתייעב וזה תרתוכה
ירחסמ דבעמ אוהש לקייס יטלומ דבעמ ןיא .1
דוק-ורקימב שומיש ושע אל MIPS ידבעמ .2
Copyright © 2014 Elsevier Inc. All rights reserved.

More Micro-Programming terminology

Horizontal Microcode
 A single control store provides the control signals
Microcode
ALUSrcA
storage
IorD
Datapath
Outputs coIRnWtrorlite
outputs
PCWrite
PCWriteCond
n-bit PC input ….
Input
1
Sequencing
Microprogram counter
control
Adder
Address select logic
Inputs from instruction
register opcode field
[Based on original figure from P&H CO&D, COPYRIGHT 48
2004 Elsevier. ALL RIGHTS RESERVED.]
tuptuo
langis
lortnoc
tib-k
MIPS design
From
P&H, Appendix D
Microprogram
counter
Control Store: 2n k bit (not including
sequencing)

Vertical Microcode
 Two-level control store: the first specifies abstract
operations
Microcode “PC  PC+4”
storage
“PC  ALUOut”
Datapath
“PC  PC[ 31:28 ],IR[ 25:0 ],2’b00”
Outputs control
o“uIRtp uts MEM[ PC ]”
“A  RF[ IR[ 25:21 ] ]”
“B  RF[ IR[ 20:16 ] ]” …….
Input ………….
1
Sequencing
Microprogram counter
control ROM
Adder
Address select logic
Inputs from instruction
register opcode field
…. PCWriteCond PCWrite IRWrite IorD ALUSrcA
1-bit signal means do this RT
(or combination of RTs)
Abstract
operations.
Register
Transfer Level
Operations
n-bit PC input
m-bit input
k-bit control signal output
[Based on original figure from P&H CO&D, COPYRIGHT
2004 Elsevier. ALL RIGHTS RESERVED.]
If done right (i.e., m<<n, and m<<k), two ROMs together
(2nm+2mk bit) should be smaller than horizontal microcode ROM (2nk bit)

Nanocode and Millicode
 Nanocode: a level below traditional microcode
 microprogrammed control for sub-systems (e.g., a
complicated floating-point module) that acts as a slave in a
microcontrolled datapath
 Millicode: a level above traditional microcode
 ISA-level subroutines that can be called by the microcontroller
to handle complicated operations and system functions
 E.g., Heller and Farrell, “Millicode in an IBM zSeries processor,”
IBM JR&D, May/Jul 2004.
.תושר רמאמ והז .אבה ףקשה םג ואר :היצביטומ
 In both cases, we avoid complicating the main u-controller
 You can think of these as “microcode” at different levels of
abstraction
50

Millicode in an IBM zSeries processor

Nanocode Concept Illustrated
a “coded” processor implementation
ROM
processor
datapath
PC
ירלודומ רתוי ןונכת
We refer to this
a “coded” FPU implementation
as “nanocode”
ROM
when a coded
arithmetic
subsystem is embedded
datapath
PC
in a coded system
52

Microcode
credit: https://everything2.com/title/microcode
Microcode is often used to refer to assembly language or even raw
machine language, but it isn't either of these things. It is actually
lower-level code, hard-coded on the silicon itself, that determines
how the processor responds to a given opcode and operand.
...
What is done is that a miniature ROM is on the chip. Every clock
cycle, based on an internal counter, a given set of bits is read from
the ROM. This set of bits covers all of the outputs needed to
manipulate the internal logic as well as a few of the external signals.
This set of bits is what asserts load and store lines, chip select lines,
activates adders, and so forth. The idea behind RISC was to make
each instruction just one line of these digital outputs.

Nanocode
credit: https://everything2.com/title/nanocode
As the name suggests, nanocode is at a lower-level than microcode.
Machine code is the raw instructions fed into a processor, this is first
decoded by the microcode. This is a translation from the hierarchical
organization of instructions that makes sense to humans, to the actual
steps that need to be taken in various parts of the processor.
Microcode is written in a lookup table to be referenced as each
instruction is executed.
Nanocode is more finely grained than microcode. It is responsible
for converting the logic of the microcode to the low-level electrical
signals that will cause the desired result. Nanocode is hardwired to
do such things as enabling logic gates to fire their output onto
interconnects, enabling the proper gates to input same, and setting
the proper flags on the ALU. Very low level stuff that each individual
block of a processor needs to carry out its little part of the instruction.

mt
h.2k
86m
bpd
Motorola 68000 processor
/cod
/msr
luap
/
moc
.k86
Microcode
ysa
e.w
ww
Nanocode
//
:ptth
1
901
=t?p
hp.c
ipot
weiv
/mur
of/te
n.dn
ims
etirp
s.ve
dne
g//:s
ptth
:tid
erC

U.S. Patent 4,325,121

Summary of findings
Microcode ךרעב ןייעל ץלמומ
Wikipedia-ב
https://en.wikipedia.org/wiki/Microcode

Multi-Cycle vs. Single-Cycle uArch
 Advantages
 Disadvantages
 You should be very familiar with this right now
58

Microprogrammed vs. Hardwired
Control
 Advantages
 Disadvantages
ךכל סחייתמ אבה ףקשה
59

expensive
Credit: https://ictbyte.com/microprocessor/difference-between-hardwired-and-micro-programmed-control-unit/

Microcode today
| Architecture | Microcode | Reason |
| ------------ | ------------------------ | ------------------------------------ |
| x86 | Yes (visible, updateable)| Complex variable-length instructions |
| MIPS | Mostly no | Simple fixed-length, RISC philosophy |
| RISC-V | “, Optional (cmplx cores)| Designed for simplicity |
| ARM | Internal μops | Performance optimization |
| ------------ | ------------------------ | ------------------------------------ |
On my computer:
telzur@TUF:~$ cat /proc/cpuinfo | grep microcode
microcode : 0x6134

Multi-Cycle -ה דבעמ תודוא ןאכ דע
דוק-ורקימב קוסיעהו

361.1.4201
Computer Architecture
Pipelining I
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
With Dr. Guy Tel-Zur & Danny’s modifications

|  101  | ףקש |  H&H Chapter 7- | ל   רובע |
| ----- | --- | --------------- | -------- |

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence Handling,
State Maintenance and Recovery, …
 Out-of-Order Execution
 Issues in OoO Execution: Load-Store Handling, …
65

Recap of Last & this Lecture
 Multi-cycle and Microprogrammed Microarchitectures
 Benefits vs. Design Principles
 When to Generate Control Signals
 “RISC-V” State Machine, Datapath, Control Structure
 Microprogrammed Control: uInstruction, uSequencer,
Control Store
 Microprogramming benefits
 Power of abstraction (for the HW designer)
 Advantages of uProgrammed Control
 Update of Machine Behavior
66

Why Pipelining?

Can We Do Better?
 What limitations do you see with the multi-cycle design?
 Limited concurrency
 Some hardware resources are idle during different phases
of instruction processing cycle
 “Fetch” logic is idle when an instruction is being “decoded”
or “executed”
 Most of the datapath is idle when a memory access is
happening
68

Can We Use the Idle Hardware to Improve
Concurrency?
 Goal: More concurrency  Higher instruction
throughput (i.e., more “work” completed in one cycle)
 Idea: When an instruction is using some resources in its
processing phase, process other instructions on idle
resources not needed by that instruction
 E.g., when an instruction is being decoded, fetch the next
instruction
 E.g., when an instruction is being executed, decode
another instruction
 E.g., when an instruction is accessing data memory (ld/st),
execute the next instruction
 E.g., when an instruction is writing its result into the
register file, access data memory for the next instruction 69

Pipelining
70

Pipelining: Basic Idea
 More systematically:
 Pipeline the execution of multiple instructions
Analogy: “Assembly line processing” of instructions – רוציי וק :תיגולנא המגוד
 Idea:
 Divide the instruction processing cycle into distinct “stages” of
processing
 Ensure there are enough hardware resources to process one
instruction in each stage
 Process a different instruction in each stage
 Instructions consecutive in program order are processed in
consecutive stages
Benefit: Increases instruction processing throughput =IPC
(=1/CPI)
 Downside: Start thinking about this… תונויער???
71

Example: Execution of Four Independent ADDs
היצמינא
 Multi-cycle: 4 cycles per instruction
F D E W
F D E W
F D E W
F D E W
Time
 Pipelined: 4 cycles per 4 instructions (steady state)
F D E W
F D E W
Is life always this beautiful?
F D E W
F D E W
Time
72

The Laundry Analogy
היצמינא
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order
A
B
C
D
 “place one dirty load of clothes in the washer”
 “when the washer is finished, place the wet load in the dryer”
6 PM 7 8 9 10 11 12 1 2 AM
Time
 “when the dryer is finished, take out the dry load and fold”
Task
 “when folding is finished, ask your roommate (??) to put the clothes
order
- steps to do a load are sequentially dependent
away” A
- no dependence between different loads
B
- different steps do not share resources
C
D
73
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Pipelining Multiple Loads of Laundry
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order
6 PM 7 8 9 10 11 12 1 2 AM
A
Time
Task
B
order
AC
DB
C
D
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
6 PM 7 8 9 10 11 12 1 2 AM
order
Time
A - 4 loads of laundry in parallel
Task
orderB
- no additional resources
A
C
- throughput increased by 4
B
D
- latency per load is the same
C
74
D
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Pipelining Multiple Loads of Laundry: In Practice
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order
A
6 PM 7 8 9 10 11 12 1 2 AM
Time
B
Task
order
C
A
D
B
C
D
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order
6 PM 7 8 9 10 11 12 1 2 AM
TimeA
B
Task
order
C
A
D
B
C
the slowest step decides throughput
D
75
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Pipelining Multiple Loads of Laundry: In Practice
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order
A6 PM 7 8 9 10 11 12 1 2 AM
Time
Task B
order
AC
D
B
C
D
6 PM 7 8 9 10 11 12 1 2 AM
Time
Task
order 6 PM 7 8 9 10 11 12 1 2 AM
Time
A A
Task
B
order B
AC
A
B
D
B
C
throughput restored (2 loads per hour) using 2 dryers
D
76
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

An Ideal Pipeline ?ילאדיא ןיילפייפל שרדנ המ
 Goal: Increase throughput with little increase in cost
(hardware cost, in case of instruction processing)
 Repetition of identical operations
 The same operation is repeated on a large number of different
inputs (e.g., all laundry loads go through the same steps)
 Repetition of independent operations
 No dependencies between repeated operations
 Uniformly partitionable suboperations תוליבחל הדיחא הקולח
ןמז
 Processing can be evenly divided into uniform-latency
suboperations (that do not share resources)
 Fitting examples: automobile assembly line, doing laundry
 What about the instruction processing “cycle”?
77

Ideal Pipelining
throughput
combinational logic (F,D,E,M,W)
BW=~(1/T)
T psec
BW=~(2/T)
T/2 ps (F,D,E) T/2 ps (M,W)
T/3 T/3 T/3
BW=~(3/T)
ps (F,D) ps (E,M) ps (M,W)
78

More Realistic Pipeline: Throughput
T=combinational logic
 Nonpipelined version with delay T
delay
S=latch delay
BW = 1/(T+S) where S = latch delay
T ps
 k-stage pipelined version Latch delay reduces throughput
(switching overhead b/w stages)
BW = 1 / (T/k +S )
k-stage
BW = 1 / (1 gate delay + S )
max
רשפאש לודג יכה ךרעל ףאוש k רשאכ לובגב
T/k T/k
ps ps
79

More Realistic Pipeline: Cost
 Nonpipelined version with combinational cost G
Cost = G+L where L = latch cost
:תונורסח
תולע-
היגרנא-
G gates
 k-stage pipelined version
Latches increase hardware cost
Cost = G + L*k
k-stage
G/k G/k
הנטק םירעשה תומכ
?לובקימ תוגרד לש ילאדיאה רפסמה המ
K רוטקפב
80

Pipelining Instruction
Processing
81

Remember: The Instruction Processing Cycle
 Fetch
1. Instruction fetch (IF)
2. InstDruecctoiodne decode and
register operand fetch (ID/RF)
 Evaluate Address
3. Execute/Evaluate memory address (EX/AG)
 Fetch Operands
4. Memory operand fetch (MEM)
 Execute
5. Store/writeback result (WB)
 Store Result
AG=Address Generation
82

Remember the Single-Cycle Uarch
|     |     | Instruction [25–0] | Shift Jump address [31–0] |     |     |     |     |          |
| --- | --- | ------------------ | ------------------------- | --- | --- | --- | --- | -------- |
|     |     |                    | left 2                    |     |     |     | PCS | rc =Jump |
|     |     | 26                 | 28                        |     |     |     | 0   | 1 1      |
|     |     | PC+4 [31–28]       |                           |     |     |     | M   | M        |
|     |     |                    |                           |     |     |     | u   | u        |
|     |     |                    |                           |     |     |     | x   | x        |
ALU
|     |     |     |     |     |     | Add result | 1   | 0   |
| --- | --- | --- | --- | --- | --- | ---------- | --- | --- |
Add
|     |     |     | RegDst |     | Shift  |     |     |     |
| --- | --- | --- | ------ | --- | ------ | --- | --- | --- |
|     |     |     | Jump   |     | left 2 |     |     |     |
| 4   |     |     | Branch |     |        |     |     |     |
MemRead
Instruction [31–26]
|     |     |     | Control MemtoReg |     |     |     |     | PCSrc =Br Taken |
| --- | --- | --- | ---------------- | --- | --- | --- | --- | --------------- |
2
ALUOp
MemWrite
ALUSrc
RegWrite
Instruction [25–21]
Read
| PC R e a d |     |                     | register 1 |        |     |     |     |     |
| ---------- | --- | ------------------- | ---------- | ------ | --- | --- | --- | --- |
| ad d r ess |     |                     |            | Read   |     |     |     |     |
|            |     | Instruction [20–16] |            | data 1 |     |     |     |     |
Read
|                 |             |                     | register 2 |            |     | Zero              |           |     |
| --------------- | ----------- | ------------------- | ---------- | ---------- | --- | ----------------- | --------- | --- |
|                 | Instruction |                     | 0          | Registers  |     | ALU               |           |     |
|                 | [31–0]      |                     |            | R e a d    | 0   | A L U             | Read      |     |
|                 |             |                     | M Write    | da t a  2  |     | re su l t Address |           | 1   |
| In st ru c ti o | n           |                     | u r        | eg i s ter | M   |                   | data      |     |
|                 |             |                     |            |            | u   |                   |           | M   |
| m e m o r       | y           | Instruction [15–11] | x          |            |     |                   |           | u   |
|                 |             |                     | 1 W        | ri t e     | x   |                   | D at a    | x   |
|                 |             |                     | data       |            | 1   |                   |           |     |
|                 |             |                     |            |            |     |                   | m em o ry | 0   |
Write
|     |     |                    |     |       |     | bcond data |     |     |
| --- | --- | ------------------ | --- | ----- | --- | ---------- | --- | --- |
|     |     | Instruction [15–0] |     | 16 32 |     |            |     |     |
Sign
extend
ALU
control
Instruction [5–0]
ALU operation
|     |     |     |     | T   |     |     |     | BW=~(1/T) |
| --- | --- | --- | --- | --- | --- | --- | --- | --------- |
Based on original figure from [P&H CO&D, COPYRIGHT 2004  83
Elsevier. ALL RIGHTS RESERVED.]

Dividing Into Stages
|     | 200ps | 100ps |     | 200ps | 200ps |     | 100ps |     |
| --- | ----- | ----- | --- | ----- | ----- | --- | ----- | --- |
IF: Instruction fetch ID: Instruction decode/ EX: Execute/ MEM: Memory access WB: Write back
|     |     | register file read |     | address calculation |     |     |     |     |
| --- | --- | ------------------ | --- | ------------------- | --- | --- | --- | --- |
0
M
u
x
ignore
1
for now
Add
Add
|     | 4   |     |     | Add |     |     | Register file |     |
| --- | --- | --- | --- | --- | --- | --- | ------------- | --- |
result
Shift
left 2
Read
| PC  | Address | register 1 | Read   |     |     |     |     |     |
| --- | ------- | ---------- | ------ | --- | --- | --- | --- | --- |
|     |         | Read       | data 1 |     |     |     |     |     |
Zero
register 2
|     | Instruction | Registers | R e a d   | ALU A L U |         |      |     |       |
| --- | ----------- | --------- | --------- | --------- | ------- | ---- | --- | ----- |
|     |             | Write     |           | 0         |         | Read |     | RF    |
|     |             |           | da t a  2 | re su l t | Address | data | 1   |       |
|     | Instruction | register  |           | M         |         |      | M   |       |
|     |             |           |           | u         | Data    |      |     |       |
|     | memory      | Write     |           | x         |         |      | u   |       |
|     |             |           |           |           | memory  |      | x   | write |
|     |             | data      |           | 1         |         |      |     |       |
|     |             |           |           |           | Write   |      | 0   |       |
data
|     |     | 16  | 32  |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign
extend
Is this the correct partitioning?
Why not 4 or 6 stages?  Why not different boundaries?
84
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Pipelined ןיבל multicycle ןיב האוושה
Instruction Pipeline Throughput
Program
|     |     | 2   |     | 4   | 6   |     | 8   | 10  | 12  | 14  | 16  | 18 x100ps |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- |
execution
Time
order
(in instructions)
|                | Instruction |     |      |     | Data   |     |             |     |     |      |     |     |
| -------------- | ----------- | --- | ---- | --- | ------ | --- | ----------- | --- | --- | ---- | --- | --- |
| lw $1, 100($0) |             | Reg | ALU  |     |        | Reg |             |     |     |      |     |     |
|                | fetch       |     |      |     | access |     |             |     |     |      |     |     |
|                |             |     |      |     |        |     | Instruction |     |     | Data |     |     |
| lw $2, 200($0) |             |     | 8 ns |     |        |     |             | Reg | ALU |      | Reg |     |
800ps
|     |     |     |     |     |     |     | fetch |     |     | access |     |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | ------ | --- | --- |
Instruction
| lw $3, 300($0) |     |     |     |     |     |     |     |     | 8 ns  |     |       |     |
| -------------- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | ----- | --- |
|                |     |     |     |     |     |     |     |     | 800ps |     | fetch |     |
...
|     |     |     | תוינש-וקיפ1000 |     |     |     |     |     |     |     |     |  8 ns |
| --- | --- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- | --- | ----- |
800ps
Program
|     |     | 2   |     | 4   | 6   |     | 8   | 10  | 12  | 14  | x100ps |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- |
execution
Time
order
(in instructions)
|                | Instruction |             |       |     |     | Data   |        |     |     |     |     |     |
| -------------- | ----------- | ----------- | ----- | --- | --- | ------ | ------ | --- | --- | --- | --- | --- |
| lw $1, 100($0) |             |             | Reg   | ALU |     |        | Reg    |     |     |     |     |     |
|                | fetch       |             |       |     |     | access |        |     |     |     |     |     |
|                |             | Instruction |       |     |     |        | Data   |     |     |     |     |     |
| lw $2, 200($0) | 2 ns        |             |       |     | Reg | ALU    |        | Reg |     |     |     |     |
|                |             |             | fetch |     |     |        | access |     |     |     |     |     |
200ps
|                |     |     |       | Instruction |     |       |       | Data   |       |     |     |     |
| -------------- | --- | --- | ----- | ----------- | --- | ----- | ----- | ------ | ----- | --- | --- | --- |
| lw $3, 300($0) |     |     | 2 ns  |             |     | Reg   | ALU   |        | Reg   |     |     |     |
|                |     |     | 200ps | fetch       |     |       |       | access |       |     |     |     |
|                |     |     |       | 2 ns        |     | 2 ns  | 2 ns  | 2 ns   | 2 ns  |     |     |     |
|                |     |     |       | 200ps       |     | 200ps | 200ps | 200ps  | 200ps |     |     |     |
5-stage speedup is 4, not 5 as predicted by the ideal model. Why?
 איה הצאהה .BW=1/200 :ןותחתה םישרתב ,BW=1/800 :ןוילעה םישרתב :הבושת
)1000/200 תועטב בשחל אל( 4 :רפושמהו שדחה בצמל ןשיה בצמה ןיב סחיה 85

Enabling Pipelined Processing: Pipeline Registers
IF: Instruction fetch ID: Instruction decode/ EX: Execute/ MEM: Memory access WB: Write back
|     |     |     | register file read |     |     |     | address calculation |     |     |     |     |     |     |
| --- | --- | --- | ------------------ | --- | --- | --- | ------------------- | --- | --- | --- | --- | --- | --- |
No resource is used by more than 1 stage!
0 0
M M
u
u
x x
1
1
|     |     | IF/ID |     |     |     | ID/EX |     |     | EX/MEM |     |     | MEM/WB |     |
| --- | --- | ----- | --- | --- | --- | ----- | --- | --- | ------ | --- | --- | ------ | --- |
|     |     | 4+    |     |     |     | 4+    |     |     |        |     |     |        |     |
M
|     | Add Add | D   |     |     |     |      |     |                          | CPn |     |     |     |     |
| --- | ------- | --- | --- | --- | --- | ---- | --- | ------------------------ | --- | --- | --- | --- | --- |
|     |         | CP  |     |     |     | CP E |     |                          |     |     |     |     |     |
|     |         |     |     |     |     |      |     | A A d dd d               |     |     |     |     |     |
|     | 44      |     |     |     |     |      |     | AAdddd rer se us lu tl t |     |     |     |     |     |
SShihftift
Next PC
lelfet f2t 2
Read
|            |                | noitcurtsnI | Read                  |           |               |     |     |         |      |     |     |     |     |
| ---------- | -------------- | ----------- | --------------------- | --------- | ------------- | --- | --- | ------- | ---- | --- | --- | --- | --- |
| PC CP PC F | AdAddrdersesss |             | register 1 register 1 |           | Read          | A E |     |         |      |     |     |     |     |
|            |                |             |                       |           | Read          |     |     |         | M    |     |     |     |     |
|            |                |             | Read                  |           | data 1 data 1 |     |     |         | tuoA |     |     |     |     |
|            |                |             | Read                  |           |               |     |     | Zero    |      |     |     | W   |     |
|            | Instruction    |             | register 2 register 2 |           |               |     |     | Zero    |      |     |     |     |     |
|            |                | D           |                       | Registers | Read          |     |     | ALU ALU |      |     |     | RDM |     |
memInosrtyruction RI Write Registers R e a d 00 ALU A L U Read
Write da data 2 t a  2 re result su l t Address Address Read data 1 1
|     |             |     | register register |     |     |     | M M |     |     |               | data |     | M   |
| --- | ----------- | --- | ----------------- | --- | --- | --- | --- | --- | --- | ------------- | ---- | --- | --- |
|     | Instruction |     |                   |     |     |     | u   |     |     | Data          |      |     | M   |
|     | memory      |     | Write             |     |     | E   | u x |     |     | Data          |      |     | u u |
|     |             |     | Write             |     |     | B   | x   |     |     | memory memory |      |     | x   |
|     |             |     | data data         |     |     |     | 1   |     |     |               |      |     | x   |
|     |             |     |                   |     |     |     | 1   |     |     |               |      |     | 0 0 |
Write Write
data
|     |     |     |     |     |         |       |     |     | M data |     |     | W    |     |
| --- | --- | --- | --- | --- | ------- | ----- | --- | --- | ------ | --- | --- | ---- | --- |
|     |     |     |     | 16  | 32      | mmI E |     |     |        |     |     | tuoA |     |
|     |     |     |     | 16  | Sign 32 |       |     |     | B      |     |     |      |     |
Sign
extend
extend
Pipeline registers
|     |     |     |     |     |     |     |     | T/k |     |     |     |     | T/k |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
T
|     |     |     |     |     |     |     |     |  ps |     |     |     |     |  ps |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
86
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

Pipelined Operation Example
Add 4 Add result
Shift
left 2
Address
Instruction memory 0
32
87
noitcurtsnI
lw
Instruction fetch
0
M
u x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read
data 1 Read register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M data u Data M u Write x memory x data 1 0 Write
data
16 Sign
extend
Add
4 Add result
Shift
left 2
Address
Instruction memory 0
32
noitcurtsnI
Add 4 Add
result
Shift
left 2
Address
Instruction memory 0
32
lw
0 Instruction decode
M u
x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read data 1
Read
register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M data u Data M u
Write x memory x
data 1 0
Write
data
16
Sign
extend
noitcurtsnI
lw
Instruction fetch
0
M
u
x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read
data 1
Read register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M data u Data M u Write x memory x data 1
0
Write
data
16
Sign
extend
Add 4 Add result
Shift
left 2
Address
Instruction memory 0
32
noitcurtsnI
lw
0 Instruction decode
M
u x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Add 4 Add result
Shift
left 2
Read PC Address register 1 Read
data 1 Read register 2 Zero Instruction Registers Read ALU ALU memory Write data 2 0 result Address Read 1 register M data u Data M u Write x memory x data 1 0 Write
data
16 32 Sign
extend
noitcurtsnI
lw
0
M Execution
u x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Add 4 Add result
Shift
left 2
Read PC Address register 1 Read
data 1 Read register 2 Zero Instruction Registers Read ALU ALU memory Write data 2 0 result Address Read 1 register M data u Data M u Write x memory x data 1 0 Write
data
16 32 Sign
extend
noitcurtsnI
lw
0
M Memory
u x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read
data 1 Read register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M Data data M u Write x memory u x data 1 0 Write
data
16 Sign
extend
Add 4 Add
result
Shift
left 2
Address
Instruction memory 0
32
noitcurtsnI
Add
4 Add result
Shift
left 2
Address
Instruction memory 0
32
0 lw
M
u Write back
x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read
data 1
Read register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M u Data data M
memory u Write x
x data 1
0
Write
data
16
Sign
extend
97108/Patterson
Figure 06.15
noitcurtsnI
lw
0
M Memory
u
x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read data 1
Read
register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M Data data M u Write x memory u x data 1 0
Write
data
16
Sign
extend
Add 4 Add result
Shift
left 2
Address
Instruction memory 0
32
noitcurtsnI
0 lw
M
u Write back x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Add 4 Add result
Shift
left 2
Read PC Address register 1 Read
data 1 Read register 2 Zero Instruction Registers Read ALU ALU memory Write data 2 0 result Address Read 1 register M u Data data M memory u Write x x data 1 0 Write
data
16 32 Sign
extend
97108/Patterson
Figure 06.15
noitcurtsnI
היצמינא
All instruction classes must follow the same path
and timing through the pipeline stages.
0
M
u Any performance impact? x
1
IF/ID ID/EX EX/MEM MEM/WB
Add
Read PC register 1 Read
data 1 Read register 2 Zero Registers Read ALU ALU Write data 2 result Address Read 1 register M data u Data M u Write x memory x data 1 0 Write
data
16 Sign
extend
Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.]

lw $10, 20($1)
Instruction fetch
|     |     |     |     |     |                    | sub $11, $2, $3 |     |     |     | lw $10, 20($1) |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | ------------------ | --------------- | --- | --- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     | Instruction decode |                 |     |     |     | Execution      |     |     |     |     |     |     |     |     |
0
M
|     |     |     |     |     |     |     |     |     |     |     |     |     | sub $11, $2, $3 |     |     |     | lw $10, 20($1) |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------------- | --- | --- | --- | -------------- | --- |
u
0 0 x
M M
|     |     |     | 1   |     |     |     |     |     |     |     |     |     |     | Memory |     |     | Write back |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | ---------- | --- |
u u
x x
1 1
|     |     |     |     | IF/ID       |     |     |     | ID/EX       |     |     |     | EX/MEM        |     |     |     | MEM/WB        |     |     |
| --- | --- | --- | --- | ----------- | --- | --- | --- | ----------- | --- | --- | --- | ------------- | --- | --- | --- | ------------- | --- | --- |
|     |     |     |     | IF/ID IF/ID |     |     |     | ID/EX ID/EX |     |     |     | EX/MEM EX/MEM |     |     |     | MEM/WB MEM/WB |     |     |
Add
|     |     | 4   | Add Add |     |     |     |     |     |     |     | Add Add |     |     |     |     |     |     |     |
| --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- |
result
|     |     |     |     |     |     |     |     |     | Shift  |     | Add           |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | ------------- | --- | --- | --- | --- | --- | --- | --- |
|     |     | 4 4 |     |     |     |     |     |     |        |     | Add Add Add   |     |     |     |     |     |     |     |
|     |     |     |     |     |     |     |     |     | left 2 |     | result result |     |     |     |     |     |     |     |
Shift
Shift
|     |     |         |     |     | noitcurtsnI | Read       |     |     | left 2 left 2 |     |     |     |     |     |     |     |     |     |
| --- | --- | ------- | --- | --- | ----------- | ---------- | --- | --- | ------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | PC  | Address |     |     |             | register 1 |     |     |               |     |     |     |     |     |     |     |     |     |
Read
data 1
|                             |     |         |                         |     | noitcurtsnI noitcurtsnI | Read Read Read                   |                    |     |     |     |               |     |                 |               |           |     |       |     |
| --------------------------- | --- | ------- | ----------------------- | --- | ----------------------- | -------------------------------- | ------------------ | --- | --- | --- | ------------- | --- | --------------- | ------------- | --------- | --- | ----- | --- |
|                             | PC  | Address |                         |     |                         | register 2 register 1 register 1 |                    |     |     |     | Zero          |     |                 |               |           |     |       |     |
|                             | PC  | Address | Instruction             |     |                         | Registers                        | Read Read          |     |     |     | ALU           |     |                 |               |           |     |       |     |
|                             |     |         | memory                  |     |                         |                                  | data 1 data 1 Read |     |     | 0   | ALU           |     |                 |               |           |     |       |     |
|                             |     |         |                         |     |                         | Write Read Read                  | data 2             |     |     |     | result        |     | Address         |               | Read      |     | 1     |     |
|                             |     |         |                         |     |                         | register register 2 register 2   |                    |     |     | M   | Zero Zero     |     |                 |               | data      |     |       |     |
|                             |     |         | Instruction Instruction |     |                         | Registers                        |                    |     |     | u   | ALU           |     |                 |               |           |     | M     |     |
|                             |     |         | memory memory           |     |                         | Registers                        | Read Read          |     |     | 0   | ALU ALU ALU   |     |                 | Data          | Read      |     | u     |     |
|                             |     |         |                         |     |                         | W Write Write r i te             | data 2 data 2      |     |     | 0 x | result result |     | Address Address | memory        | Read      |     | 1 1   |     |
|                             |     |         |                         |     |                         | da register register t a         |                    |     |     | M M |               |     |                 |               | data data |     | x     |     |
|                             |     |         |                         |     |                         |                                  |                    |     |     | 1 u |               |     |                 |               |           |     | 0 M M |     |
|                             |     |         |                         |     |                         |                                  |                    |     |     | u   |               |     | Write           | Data Data     |           |     | u u   |     |
|                             |     |         |                         |     |                         | Write Write                      |                    |     |     | x x |               |     | data            | memory memory |           |     | x     |     |
| Pipelined Operation Example |     |         |                         |     |                         | data data                        |                    |     |     | 1   |               |     |                 |               |           |     | x     |     |
|                             |     |         |                         |     |                         |                                  |                    |     |     | 1   |               |     |                 |               |           |     | 0 0   |     |
|                             |     |         |                         |     |                         | 16                               | 32                 |     |     |     |               |     | Write Write     |               |           |     |       |     |
|                             |     |         |                         |     |                         |                                  | Sign               |     |     |     |               |     | data data       |               |           |     |       |     |
extend
|     |     |     |     |     |     | 16 16 | 32 32 |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Sign Sign
extend
extend
היצמינא
Clock 1
|     |                                     | Clock 5        | Clock 3 |     |                                       |                 |     |     |     |                 |     |     |                 |     |     |     |                 |     |
| --- | ----------------------------------- | -------------- | ------- | --- | ------------------------------------- | --------------- | --- | --- | --- | --------------- | --- | --- | --------------- | --- | --- | --- | --------------- | --- |
|     | sub $11, $2, $3                     | lw $10, 20($1) |         |     |                                       | lw $10, 20($1)  |     |     |     |                 |     |     |                 |     |     |     |                 |     |
|     |                                     |                |         |     |                                       | sub $11, $2, $3 |     |     |     | lw $10, 20($1)  |     |     |                 |     |     |     |                 |     |
|     | Instruction fetch Instruction fetch |                |         |     | Instruction decode Instruction decode |                 |     |     |     | Execution       |     |     |                 |     |     |     |                 |     |
|     |                                     |                |         |     |                                       |                 |     |     |     | sub $11, $2, $3 |     |     | lw $10, 20($1)  |     |     |     | sub $11, $2, $3 |     |
|     |                                     |                |         |     |                                       |                 |     |     |     |                 |     |     | sub $11, $2, $3 |     |     |     | lw $10, 20($1)  |     |
0 0
0 0 0 0
|     |     |     | M M M M M M |     |     |     |     |     |     | Execution |     |     |     | Memory |     |     | Write back |     |
| --- | --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --------- | --- | --- | --- | ------ | --- | --- | ---------- | --- |
|     |     |     | u           |     |     |     |     |     |     |           |     |     |     | Memory |     |     | Write back |     |
u u u u u
x x x x x x
1
1 1 1 1 1
IF/ID IF/ID IF/ID IF/ID IF/ID IF/ID ID/EX ID/EX ID/EX ID/EX ID/EX ID/EX EX/MEM EX/MEM EX/MEM EX/MEM EX/MEM EX/MEM MEM/WB MEM/WB MEM/WB MEM/WB MEM/WB MEM/WB
Add Add Add Add Add Add
Add Add Add Add
|     |     | 4 4 4 4 4 4 |     |     |     |     |     |     |     |     | Add Add Add Add Add Add result Add Add |     |     |     |     |     |     |     |
| --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- | --- | -------------------------------------- | --- | --- | --- | --- | --- | --- | --- |
result result result result result
Shift Shift Shift Shift Shift
Shift
left 2 left 2 left 2 left 2 left 2 left 2
Read
|     |                   |                                                 |     |     | noitcurtsnI noitcurtsnI noitcurtsnI noitcurtsnI noitcurtsnI noitcurtsnI | Read Read Read Read Read                                          |      |     |     |     |     |     |     |     |     |     |     |     |
| --- | ----------------- | ----------------------------------------------- | --- | --- | ----------------------------------------------------------------------- | ----------------------------------------------------------------- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | PC PC PC PC PC PC | Address Address Address Address Address Address |     |     |                                                                         | register 1 register 1 register 1 register 1 register 1 register 1 | Read |     |     |     |     |     |     |     |     |     |     |     |
Read Read Read Read Read
|     |     |     |                                                 |     |     | Read                                                              | data 1 data 1 data 1 data 1 data 1 data 1 |     |     |     |                          |     |     |     |     |     |     |     |
| --- | --- | --- | ----------------------------------------------- | --- | --- | ----------------------------------------------------------------- | ----------------------------------------- | --- | --- | --- | ------------------------ | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |                                                 |     |     | Read Read Read Read Read                                          |                                           |     |     |     | Zero                     |     |     |     |     |     |     |     |
|     |     |     | Instruction Instruction                         |     |     | register 2 register 2 register 2 register 2 register 2 register 2 |                                           |     |     |     | Zero Zero Zero Zero Zero |     |     |     |     |     |     |     |
|     |     |     | Instruction Instruction Instruction Instruction |     |     | Registers Registers Registers Registers Registers                 | Read                                      |     |     |     | ALU ALU ALU ALU ALU ALU  |     |     |     |     |     |     |     |
memory memory memory memory memory memory Write Registers Read Read Read R R e e a a d d 0 0 0 0 0 ALU ALU ALU A A A L L L U U U Read Read Read Read
Write Write Write Write Write data 2 data 2 data 2 data 2 da da t t a a  2  2 0 result result re result re re su su su l l t t l t Address Address Address Address Address Address Read data Read 1 1 1 1 1 1
register register register register register register M M M M M M data data data data data M
|     |     |     |     |     |     |          |     |     |     | u u u u u |     |     |     | Data Data           |     |     | M M M M M   |     |
| --- | --- | --- | --- | --- | --- | -------- | --- | --- | --- | --------- | --- | --- | --- | ------------------- | --- | --- | ----------- | --- |
|     |     |     |     |     |     | W r i te |     |     |     | x u       |     |     |     | Data Data Data Data |     |     | u u u u u u |     |
Is li Write Write Write Write daf W r i te e always this x x x x x  beautiful? memory memory memory memory memory x x x x
|     |     |     |     |     |     | data data data data da t t a a |     |     |     | 1 1 1 1 1 |     |     |     | memory |     |     | x x         |     |
| --- | --- | --- | --- | --- | --- | ------------------------------ | --- | --- | --- | --------- | --- | --- | --- | ------ | --- | --- | ----------- | --- |
|     |     |     |     |     |     |                                |     |     |     | 1         |     |     |     |        |     |     | 0 0 0 0 0 0 |     |
Write Write Write Write Write Write
data data data data data
data
|     |     |     |     |     |     | 16             | 32               |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | -------------- | ---------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | 16 16 16 16 16 | Sign 32 32 32 32 | 32  |     |     |     |     |     |     |     |     |     |     |
Sign Sign Sign Sign Sign
extend extend extend extend
extend extend
|                                                                                         |                   | Clock 5                 | Clock 3 |     |                    |                |     |     |     |                 |     |     |                |     |     |     |                 |     |
| --------------------------------------------------------------------------------------- | ----------------- | ----------------------- | ------- | --- | ------------------ | -------------- | --- | --- | --- | --------------- | --- | --- | -------------- | --- | --- | --- | --------------- | --- |
|                                                                                         |                   | Clock 6 Clock 2 Clock 1 | Clock 4 |     |                    |                |     |     |     |                 |     |     |                |     |     |     |                 |     |
|                                                                                         | sub $11, $2, $3   |                         |         |     |                    | lw $10, 20($1) |     |     |     |                 |     |     |                |     |     |     |                 | 88  |
|                                                                                         |                   |                         |         |     |                    |                |     |     |     | sub $11, $2, $3 |     |     | lw $10, 20($1) |     |     |     | sub $11, $2, $3 |     |
| Based on original figure from [P&H CO&D, COPYRIGHT 2004 Elsevier. ALL RIGHTS RESERVED.] | Instruction fetch |                         |         |     | Instruction decode |                |     |     |     |                 |     |     |                |     |     |     |                 |     |
0 0
|     |     |     | M M |     |     |     |     |     |     | Execution |     |     |     | Memory |     |     | Write back |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | --- | --- | --- | ------ | --- | --- | ---------- | --- |
u u
0 x x
1 1
M
u
x
1
|     |     |     |         | IF/ID IF/ID |     |     |     | ID/EX ID/EX |     |     |     | EX/MEM EX/MEM |     |     |     | MEM/WB MEM/WB |     |     |
| --- | --- | --- | ------- | ----------- | --- | --- | --- | ----------- | --- | --- | --- | ------------- | --- | --- | --- | ------------- | --- | --- |
|     |     |     | Add Add | IF/ID       |     |     |     | ID/EX       |     |     |     | EX/MEM        |     |     |     | MEM/WB        |     |     |
Add Add
|     |     | 4 4 |     |     |     |     |     |     |     |     | Add Add result |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | -------------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | Add |     |     |     |     |     |     |     | result         |     |     |     |     |     |     |     |
Shift Shift
Add
|     |     | 4   |     |     |     |           |     |     | left 2 left 2 |     | Add result |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --------- | --- | --- | ------------- | --- | ---------- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     | Read Read |     |     | Shift         |     |            |     |     |     |     |     |     |     |
noitcurtsnI noitcurtsnI
|     | PC PC | Address Address |                         |     |             | register 1 register 1          | Read Read            |     | left 2 |     |               |     |                 |               |           |      |       |     |
| --- | ----- | --------------- | ----------------------- | --- | ----------- | ------------------------------ | -------------------- | --- | ------ | --- | ------------- | --- | --------------- | ------------- | --------- | ---- | ----- | --- |
|     |       |                 |                         |     |             | Read Read                      | data 1 data 1        |     |        |     |               |     |                 |               |           |      |       |     |
|     |       |                 |                         |     |             | Read                           |                      |     |        |     | Zero Zero     |     |                 |               |           |      |       |     |
|     |       |                 | Instruction Instruction |     | noitcurtsnI | register 2 register 2          |                      |     |        |     |               |     |                 |               |           |      |       |     |
|     | PC    | Address         |                         |     |             | register 1 Registers Registers | Read Read            |     |        |     | ALU ALU ALU   |     |                 |               |           |      |       |     |
|     |       |                 | memory memory           |     |             | Write                          | Read                 |     |        | 0 0 | ALU           |     |                 |               | Read Read |      |       |     |
|     |       |                 |                         |     |             | Write Read                     | data 2 data 2 data 1 |     |        |     | result result |     | Address Address |               | data      |      | 1 1   |     |
|     |       |                 |                         |     |             | register register              |                      |     |        | M M | Zero          |     |                 |               | data      |      | M     |     |
|     |       |                 | Instruction             |     |             | register 2                     |                      |     |        | u u |               |     |                 | Data Data     |           |      | M     |     |
|     |       |                 |                         |     |             | Write Registers                | Read                 |     |        | x   | ALU ALU       |     |                 |               |           |      | u u   |     |
|     |       |                 | memory                  |     |             | Write Write                    |                      |     |        | 0 x |               |     |                 | memory memory | Read      |      | x x   |     |
|     |       |                 |                         |     |             | data data                      | data 2               |     |        | 1 1 | result        |     |                 | Address       |           | data | 1     |     |
|     |       |                 |                         |     |             | register                       |                      |     |        | M   |               |     |                 |               |           |      | 0 0 M |     |
|     |       |                 |                         |     |             |                                |                      |     |        | u   |               |     | Write Write     | Data          |           |      |       |     |
|     |       |                 |                         |     |             | Write                          |                      |     |        | x   |               |     | data data       |               |           |      | u     |     |
|     |       |                 |                         |     |             |                                |                      |     |        |     |               |     |                 | memory        |           |      | x     |     |
|     |       |                 |                         |     |             | data 16                        | 32                   |     |        | 1   |               |     |                 |               |           |      |       |     |
|     |       |                 |                         |     |             | 16                             | Sign 32              |     |        |     |               |     |                 |               |           |      | 0     |     |
|     |       |                 |                         |     |             |                                | Sign                 |     |        |     |               |     |                 | Write         |           |      |       |     |
|     |       |                 |                         |     |             |                                | extend extend        |     |        |     |               |     |                 | data          |           |      |       |     |
|     |       |                 |                         |     |             | 16                             |                      | 32  |        |     |               |     |                 |               |           |      |       |     |
Sign
extend
|     |     | Clock 6 | Clock 4 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | ------- | ------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
Clock 2

Illustrating Pipeline Operation: Operation
View
היצמינא
|     | t   | t   | t   | t   | t   | t   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | 0   | 1   | 2   | 3   | 4   | 5   |     |     |
Inst
|     | IF  | ID  | EX  | MEM | WB  |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
0
Inst
|     |     | IF  | ID  | EX  | MEM | WB  |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
1
| Inst |     |     | IF  | ID  | EX  | MEM | WB  |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- |
2
| Inst |     |     |     | IF  | ID  |     |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|      |     |     |     |     |     | EX  | MEM | WB  |
3
| Inst |     |     |     |     | IF  |     |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|      |     |     |     |     |     | ID  | EX  | MEM |
4
|     |     |     |     |     |     | IF  | ID  | EX  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     | IF  | ID  |
steady state
IF
(full pipeline)
89

Illustrating Pipeline Operation: Resource View
היצמינא
| t   | t   | t   | t   | t   | t   | t   | t   | t   | t   | t   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  |
IF
|     | I   | I   | I   | I   | I   | I   | I   | I   | I   | I   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
I
|     | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   | 10  |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
0
ID
|     | I   | I   | I   | I   | I   | I   | I   | I   | I   | I   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   | 9   |
EX
|     |     | I   | I   | I   | I   | I   | I   | I   | I   | I   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     | 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |
MEM
|     |     |     | I   | I   | I   | I   | I   | I   | I   | I   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     | 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   |
WB
|     |     |     |     | I   | I   | I   | I   | I   | I   | I   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     | 0   | 1   | 2   | 3   | 4   | 5   | 6   |
90

Control Points in a Pipeline
PCSrc
0
M
u
x
1
|     | IF/ID |     | ID/EX |     |     | EX/MEM |     | MEM/WB |     |
| --- | ----- | --- | ----- | --- | --- | ------ | --- | ------ | --- |
Add
Add
| 4   |     |     |     | Add |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
result
Branch
Shift
|            |             | RegWrite   |     | left 2 |     |     |          |     |     |
| ---------- | ----------- | ---------- | --- | ------ | --- | --- | -------- | --- | --- |
|            | noitcurtsnI | Read       |     |        |     |     | MemWrite |     |     |
| PC Address |             | register 1 |     |        |     |     |          |     |     |
Read
data 1
|             |     | Read       |        | ALUSrc |          |     |         |      | MemtoReg |
| ----------- | --- | ---------- | ------ | ------ | -------- | --- | ------- | ---- | -------- |
|             |     | register 2 |        |        | ZeZreoro |     |         |      |          |
| Instruction |     | Registers  |        |        |          |     |         |      |          |
| memory      |     |            | Read   | 0      | ALU ALU  |     |         |      |          |
|             |     | Write      | data 2 |        | result   |     | Address | Read | 1        |
|             |     | register   |        | M      |          |     |         |      |          |
|             |     |            |        | u      |          |     |         | data | M        |
|             |     |            |        |        |          |     | Data    |      | u        |
|             |     | Write      |        | x      |          |     | memory  |      |          |
|             |     | data       |        |        |          |     |         |      | x        |
|             |     |            |        | 1      |          |     |         |      | 0        |
Write
data
Instruction
|     |     | [15–0] 16 |     | 6   |     |     |     |     |     |
| --- | --- | --------- | --- | --- | --- | --- | --- | --- | --- |
Sign 32
ALU
|     |     |     | extend | control |     |     | MemRead |     |     |
| --- | --- | --- | ------ | ------- | --- | --- | ------- | --- | --- |
Instruction
[20–16]
0
M ALUOp
Instruction
u
|     |     | [15–11] |     | x   |     |     |     |     |     |
| --- | --- | ------- | --- | --- | --- | --- | --- | --- | --- |
Based on original figure from [P&H CO&D,  1
COPYRIGHT 2004 Elsevier. ALL RIGHTS
RESERVED.] RegDst
Identical set of control points as the single-cycle datapath!! 91

Control Signals in a Pipeline
 For a given instruction
 same control signals as single-cycle, but
 control signals required at different cycles, depending on stage
 Option 1: decode once using the same logic as single-cycle and
buffer signals until consumed
Option 1: Decode once WB
and propagate
Instruction
Control M WB
EX M WB
Option 2: Decode on demand
IF/ID ID/EX EX/MEM MEM/WB
 Option 2: carry relevant “instruction word/field” down the
pipeline and decode locally within each or in a previous stage
Which one is better?
92
This option may reduce the cost of the latches – reduce the number of control latches

RegWrite הרקבה תואב דקמתנ תיחכונה המגודב
Pipelined Control Signals
היצמינא
PCSrc
ID/EX
0
M
| u   |     |     | WB  |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
EX/MEM
x
1
|     |     | Control | M   |     | WB  |     |     |
| --- | --- | ------- | --- | --- | --- | --- | --- |
MEM/WB
|     |     |     | EX  |     | M   | WB  |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
IF/ID
Add
Add
| 4   |     |     |     | Add |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- |
result
etirWgeR
Branch
Shift
|     |     |     | left 2 |     | etirWmeM |     |     |
| --- | --- | --- | ------ | --- | -------- | --- | --- |
ALUSrc
| noitcurtsnI | Read |     |     |     |     |     | geRotmeM |
| ----------- | ---- | --- | --- | --- | --- | --- | -------- |
register 1
| PC Address |      | Read   |     |     |     |     |     |
| ---------- | ---- | ------ | --- | --- | --- | --- | --- |
|            | Read | data 1 |     |     |     |     |     |
Zero
| Instruction | register 2 |        |     |          |         |      |     |
| ----------- | ---------- | ------ | --- | -------- | ------- | ---- | --- |
|             | Registers  |        |     | ALU      |         |      |     |
| memory      |            | Read   |     | ALU      |         |      |     |
|             | Write      | data 2 |     | 0 result | Address | Read | 1   |
|             | register   |        |     | M        |         | data |     |
|             |            |        |     |          | Data    |      | M   |
u
|     |       |     |     |     | memory |     | u   |
| --- | ----- | --- | --- | --- | ------ | --- | --- |
|     | Write |     |     | x   |        |     | x   |
|     | data  |     |     | 1   |        |     |     |
0
Write
data
Instruction
|     | 16     | 32   | 6   |     |     |     |     |
| --- | ------ | ---- | --- | --- | --- | --- | --- |
|     | [15–0] | Sign |     | ALU |     |     |     |
MemRead
|     |     | extend |     | control |     |     |     |
| --- | --- | ------ | --- | ------- | --- | --- | --- |
Instruction
[20–16]
0
ALUOp
M
|     | Instruction |     | u   |     |     |     |     |
| --- | ----------- | --- | --- | --- | --- | --- | --- |
x
[15–11]
1
RegDst
Based on original figure from [P&H CO&D,  93
COPYRIGHT 2004 Elsevier. ALL RIGHTS
RESERVED.]

Remember: An Ideal Pipeline - ןוזחה
 Goal: Increase throughput with little increase in cost
(hardware cost, in case of instruction processing) תומכ תלדגה
תולע תפסות אלל םיבושיחה
 Repetition of identical operationsםיעובק םידעצ לע תויתרזח
 The same operation is repeated on a large number of different
inputs (e.g., all laundry loads go through the same steps)
 Repetition of independent operations תונוש תולועפ עוציב תלוכי
 No dependencies between repeated operations ןיב תולת יא
תולועפה
 Uniformly partitionable suboperations תודיחא תויהשה
 Processing an be evenly divided into uniform-latency
suboperations (that do not share resources)
 Fitting examples: automobile assembly line, doing laundry
94
 What about the instruction processing “cycle”?

Instruction Pipeline: Not An Ideal Pipeline
תואיצמה
 Identical operations ... NOT!
 different instructions  not all need the same stages
Forcing different instructions to go through the same pipe stages
 external fragmentation (some pipe stages idle for some
instructions)
 Uniform suboperations ... NOT!
 different pipeline stages  not the same latency
Need to force each stage to be controlled by the same clock
 internal fragmentation (some pipe stages are too fast but all take
the same clock cycle time)
 Independent operations ... NOT!
 instructions are not independent of each other
Need to detect and resolve inter-instruction dependencies to
ensure the pipeline provides correct results
 pipeline stalls (pipeline is not always moving)
95

you can skip
A demo: Dr. MIPS
this slide
https://brunonova.github.io/drmips/
Folder:
/home/telzur/science/Teaching/CPU/SW/
DrMIPS_v2.0.3/DrMIPS_v2.0.3
Execute:
java -jar ./DrMIPS.jar &
then load your code, e.g. “guy1.asm”

you can skip
A demo: Dr. MIPS
this slide

Pipelining continues
in next lecture slides...
98