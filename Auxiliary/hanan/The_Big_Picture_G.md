Computer Architecture – The Big Picture
Guy Tel-Zur
רעיה תמועל םיצעה
Credit:
1) Hennessy & Patterson books.
2) ECE 4750 Computer Architecture by Christina Delimitrou, Cornell.
Last update: 1/5/24

תולכירדא
 ,היינבה
 תונמא  איה  הרָ(cid:5) (cid:7)וּטקְ(cid:10) ט(cid:12) יכִ(cid:13) רָ(cid:10) א(cid:15)  וּא  ת(cid:7)וּלכִ(cid:5) ירָ(cid:13) דְ(cid:10) א(cid:15)
|  ןיב    |  תאצמנוּ |        |  ,םיללחוּ |           |  םינבמ |         |  בוּציעוּ |     |  ןוּנכִתב |  תקְסוּע |     |
| ------- | -------- | ------ | --------- | --------- | ------ | ------- | --------- | --- | --------- | -------- | --- |
|  ללחבוּ |          |  הנבמב |           |  קְוּסיעה |        |  .ןיינב |  תסדְנה   |     |  ןיבל     |  תוּנמא  |     |
 ,וּרָקְאמה
|     |     |  תמרָב |     |  תללוּכִה |     |  היוּנבה |     |  הביבסה |     |  תא |  ללוּכִ |
| --- | --- | ------ | --- | --------- | --- | -------- | --- | ------- | --- | --- | ------- |
 טוּהירָהוּ  הנבמה  יטרָפ  בוּציעל  דְע  ,ינוּרָיע  ןוּנכִתכִ
.)הידְפיקְיוּ( .וּרָקְימה תמרָב
ונלש ןכותה םלועל תולבקה
:םוגרת ןולימ
דבעמ >-<  הנבמ
םיבשחמ תסדנה >-< ןיינב תסדנה
םיילאירפירפ םיביכר >-< הביבסה
הרוטקטיכראורקימ >-< ורקימה תמר

Computer Architecture
IBM 360 → 370 → 3090
3270 terminal for IBM 370
The term “computer architecture” was coined by IBM in
1964 for use with the IBM 360. Amdahl, Blaauw, and
Brooks [1964] used the term to refer to the
programmer-visible portion of the instruction set.

Computer Architecture
In computer engineering, computer architecture

| is  a  | set             | of  rules  | and  | methods        |     | that  | describe  |      |
| ------ | --------------- | ---------- | ---- | -------------- | --- | ----- | --------- | ---- |
| the    | functionality,  |            |      | organization,  |     |       |           | and  |
implementation of computer systems.
| Computer  |     | architecture  |     | involves  |     | instruction  |     |     |
| --------- | --- | ------------- | --- | --------- | --- | ------------ | --- | --- |

| set  | architecture  |     | design,  |     | microarchitecture  |     |     |     |
| ---- | ------------- | --- | -------- | --- | ------------------ | --- | --- | --- |
design, logic design, and implementation.
Hennessy, John; Patterson, David. Computer Architecture: A
Quantitative Approach (Fifth ed.).

זא
Intel 4004 (1971)
The 4004 had 2,300 transistors.

   4004-
| פוקסורקימה | תחת | ה   |
| ---------- | --- | --- |

The 4004 team leader
Federico Faggin

https://www.youtube.com/watch?v=YpruA5mC7wg

םידסיימה רוד

Motorola 68000
The Motorola 68000 is a 16/32-bit microprocessor released in 1979, famously
used in the original Apple Macintosh, Commodore Amiga, Atari ST, and Sega
Genesis.
32-bit internal design — ahead of its time in 1979
●
• Clean instruction set — inspired many later processors
• Unix compatibility — became popular in workstations
• Motorola 68k family — evolved into 68020, 68030, 68040, PowerPC
| Feature | Details |
| ------------- | ------------------------------------ |
| Architecture | 16-bit external, 32-bit internal |
| Clock Speed | 8-16 MHz (original) |
| Registers | 8 × 32-bit data + 8 × 32-bit address |
| Address Space | 16 MB (24-bit address bus) |
| Transistors | ~68,000 |
| Computer | Year |
| ---------------------------------- | ---- |
| Apple Macintosh 128K | 1984 |
| Commodore Amiga | 1985 |
| Atari ST | 1985 |
| Sega Genesis | 1988 |
| Sony PlayStation (68k coprocessor) | 1994 |

"םויה”
11

Ipad A5
GPU
2 ARM cores
12

Apple M1
Credit: Wikipedia
13
SOC

Intel Core i9 (2019)
14

Intel Raptor Lake Core i9-13900K
15
https://wccftech.com/intel-raptor-lake-core-i9-13900k-gets-high-res-beautiful-cpu-die-shot/

Intel Raptor Lake Core i9-13900K
P core
E core
16

On my laptop
$ lscpu
Architecture: x86_64
CPU op-mode(s): 32-bit, 64-bit
Address sizes: 46 bits physical, 48 bits virtual
Byte Order: Little Endian
CPU(s): 20
On-line CPU(s) list: 0-19
Vendor ID: GenuineIntel
Model name: 13th Gen Intel(R) Core(TM) i9-13900H
CPU family: 6
Model: 186
Thread(s) per core: 2
Core(s) per socket: 14
Socket(s): 1
6 P-cores X 2 threads/core + 8 E-cores X 1 thread/core = 20 cores in total.
17

Nvidia H100 GPU
18

Dependability in Edge Computing
By Saurabh Bagchi, Muhammad-Bilal Siddiqui, Paul Wood, Heng Zhang
Communications of the ACM, January 2020, Vol. 63 No. 1, Pages 58-66
19

Dependability in Edge Computing
By Saurabh Bagchi, Muhammad-Bilal Siddiqui, Paul Wood, Heng Zhang
Communications of the ACM, January 2020, Vol. 63 No. 1, Pages 58-66
20

Sipeed Longan Nano - RISC-V Development Board
21

https://www.theregister.co.uk/2019/08/20/ibm_openpower_isa/

Quantum Computing – יחכִוּנה סרָוּקְה לש פוּקְסב אל
The quantum computer in the quantum computing
lab in Santa Barbara, CA.
23
https://www.macleans.ca/society/science/quantum-computing-could-solve-problems-we-dont-even-know-we
-have/

|      |  1  |      |       |     |      |
| ---- | --- | ---- | ----- | --- | ---- |
| רפסב | קרפ | ךותמ | םיפקש | התע | גיצנ |
CAQA 6th  Edition
24

Computer Architecture
A Quantitative Approach, Sixth Edition
Chapter 1
Fundamentals of Quantitative
Design and Analysis
Copyright © 2019, Elsevier Inc. All rights reserved. 25

Computer Technology
Performance improvements:

Improvements in semiconductor technology

Feature size, clock speed

Improvements in computer architectures

Enabled by HLL compilers, UNIX

Lead to RISC architectures

Together have enabled:

Lightweight computers

Productivity-based managed/interpreted programming

languages
Copyright © 2019, Elsevier Inc. All rights reserved. 26
Introduction

Single Processor Performance
Copyright © 2019, Elsevier Inc. All rights reserved. 27
Introduction
יוּנישה תמגמ

Current Trends in Architecture
Cannot continue to leverage Instruction-Level

parallelism (ILP)
Single processor performance improvement ended in 2003

New models for performance:

Data-level parallelism (DLP)

Thread-level parallelism (TLP)

Request-level parallelism (RLP)

These require explicit restructuring of the application

Copyright © 2019, Elsevier Inc. All rights reserved. 28
Introduction

Classes of Computers
Personal Mobile Device (PMD)

e.g. start phones, tablet computers

Emphasis on energy efficiency and real-time

Desktop Computing

Emphasis on price-performance

Servers

Emphasis on availability, scalability, throughput

Clusters / Warehouse Scale Computers

Used for “Software as a Service (SaaS)”

Emphasis on availability and price-performance

Sub-class: Supercomputers, emphasis: floating-point performance and

fast internal networks
Internet of Things/Embedded Computers

Emphasis: price

Copyright © 2019, Elsevier Inc. All rights reserved. 29
Classes
of
Computers

Parallelism
Classes of parallelism in applications:

Data-Level Parallelism (DLP)

Task-Level Parallelism (TLP)

Classes of architectural parallelism:

Instruction-Level Parallelism (ILP)

Vector architectures/Graphic Processor Units (GPUs)

Thread-Level Parallelism

Request-Level Parallelism

Copyright © 2019, Elsevier Inc. All rights reserved. 30
Classes
of
Computers

Flynn’s Taxonomy
Single instruction stream, single data stream (SISD)

Single instruction stream, multiple data streams (SIMD)

Vector architectures

Multimedia extensions

Graphics processor units

Multiple instruction streams, single data stream (MISD)

No commercial implementation

Multiple instruction streams, multiple data streams (MIMD)

Tightly-coupled MIMD

Loosely-coupled MIMD

Copyright © 2019, Elsevier Inc. All rights reserved. 31
Classes
of
Computers

Defining Computer Architecture
“Old” view of computer architecture:

Instruction Set Architecture (ISA) design

i.e. decisions regarding:

registers, memory addressing, addressing modes, instruction

operands, available operations, control flow instructions,
instruction encoding
“Real” computer architecture:

Specific requirements of the target machine

Design to maximize performance within constraints: cost,

power, and availability
Includes ISA, microarchitecture, hardware

Copyright © 2019, Elsevier Inc. All rights reserved. 32
Defining
Computer
Architecture

Defining Computer Architecture
Instruction Set Architecture
Class of ISA

 General-purpose registers
Register-memory vs load-store

RISC-V registers

|     |     |     |     | Register | Name | Use | Saver |
| --- | --- | --- | --- | -------- | ---- | --- | ----- |
 32 g.p., 32 f.p.
|          |       |             |        | x9      | s1       | saved        | callee |
| -------- | ----- | ----------- | ------ | ------- | -------- | ------------ | ------ |
| Register | Name  | Use         | Saver  | x10-x17 | a0-a7    | arguments    | caller |
| x0       | zero  | constant 0  | n/a    | x18-x27 | s2-s11   | saved        | callee |
| x1       | ra    | return addr | caller | x28-x31 | t3-t6    | temporaries  | caller |
| x2       | sp    | stack ptr   | callee | f0-f7   | ft0-ft7  | FP temps     | caller |
| x3       | gp    | gbl ptr     |        | f8-f9   | fs0-fs1  | FP saved     | callee |
|          |       |             |        | f10-f17 | fa0-fa7  | FP arguments | callee |
| x4       | tp    | thread ptr  |        |         |          |              |        |
| x5-x7    | t0-t2 | temporaries | caller |         |          |              |        |
|          |       |             |        | f18-f27 | fs2-fs21 | FP saved     | callee |
| x8       | s0/fp | saved/      | callee |         |          |              |        |
|          |       | frame ptr   |        | f28-f31 | ft8-ft11 | FP temps     | caller |
Copyright © 2019, Elsevier Inc. All rights reserved. 33

Instruction Set Architecture
Memory addressing

RISC-V: byte addressed, aligned accesses faster

Addressing modes

RISC-V: Register, immediate, displacement (base+offset)

Other examples: autoincrement, indexed, PC-relative

Types and size of operands

RISC-V: 8-bit, 32-bit, 64-bit

Copyright © 2019, Elsevier Inc. All rights reserved. 34
Defining
Computer
Architecture

Instruction Set Architecture
Operations

RISC-V: data transfer, arithmetic, logical, control, floating

point
See Fig. 1.5 in text

Control flow instructions

Use content of registers (RISC-V) vs. status bits (x86,

ARMv7, ARMv8)
Return address in register (RISC-V, ARMv7, ARMv8) vs. on

stack (x86)
Encoding

Fixed (RISC-V, ARMv7/v8 except compact instruction set)

vs. variable length (x86)
Copyright © 2019, Elsevier Inc. All rights reserved. 35
Defining
Computer
Architecture

Trends in Technology
 Integrated circuit technology (Moore’s Law)
 Transistor density: 35%/year
 Die size: 10-20%/year
 Integration overall: 40-55%/year
 DRAM capacity: 25-40%/year (slowing)
 8 Gb (2014), 16 Gb (2019), possibly no 32 Gb
 Flash capacity: 50-60%/year
 8-10X cheaper/bit than DRAM
 Magnetic disk capacity: recently slowed to 5%/year
 Density increases may no longer be possible, maybe increase from 7 to 9
platters
 8-10X cheaper/bit than Flash
 200-300X cheaper/bit than DRAM
Copyright © 2019, Elsevier Inc. All rights reserved. 36
Trends
in
Technology

Bandwidth and Latency
Bandwidth or throughput

Total work done in a given time

32,000-40,000X improvement for processors

300-1200X improvement for memory and disks

Latency or response time

Time between start and completion of an event

50-90X improvement for processors

6-8X improvement for memory and disks

Copyright © 2019, Elsevier Inc. All rights reserved. 37
Trends
in
Technology

Bandwidth and Latency
Log-log plot of bandwidth and latency milestones
Copyright © 2019, Elsevier Inc. All rights reserved. 38
Trends
in
Technology

Transistors and Wires
Feature size

Minimum size of transistor or wire in x or y

dimension
10 microns in 1971 to .011 microns in 2017

Transistor performance scales linearly

Wire delay does not improve with feature size!

Integration density scales quadratically

Copyright © 2019, Elsevier Inc. All rights reserved. 39
Trends
in
Technology

Power and Energy
Problem: Get power in, get power out

Thermal Design Power (TDP)

Characterizes sustained power consumption

Used as target for power supply and cooling system

Lower than peak power (1.5X higher), higher than average

power consumption
Clock rate can be reduced dynamically to limit power

consumption
Energy per task is often a better measurement

Copyright © 2019, Elsevier Inc. All rights reserved. 40
Trends
in
Power
and
Energy

Dynamic Energy and Power
Dynamic energy

Transistor switch from 0 -> 1 or 1 -> 0


½ x Capacitive load x Voltage2
Dynamic power


½ x Capacitive load x Voltage2 x Frequency switched
Reducing clock rate reduces power, not energy

Copyright © 2019, Elsevier Inc. All rights reserved. 41
Trends
in
Power
and
Energy

Power
Intel 80386

consumed ~ 2 W
3.3 GHz Intel Core

i7 consumes 130 W
Heat must be

dissipated from 1.5
x 1.5 cm chip
This is the limit of

what can be cooled
by air
Copyright © 2019, Elsevier Inc. All rights reserved. 42
Trends
in
Power
and
Energy

Reducing Power
Techniques for reducing power:

Do nothing well

Dynamic Voltage-Frequency Scaling

Low power state for DRAM, disks

Overclocking, turning off cores

Copyright © 2019, Elsevier Inc. All rights reserved. 43
Trends
in
Power
and
Energy
Dynamic
Voltage
Scaling

Dynamic Voltage-Frequency Scaling (DVFS)
DVFS is a power-saving technique that adjusts CPU voltage and frequency based on workload
demands.
Guy
# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
# Available governors
- performance # Always max
- powersave # Always low
- ondemand # Scales dynamically
- conservative # Gradual scaling
on my laptop:
$ cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
powersave
Copyright © 2019, Elsevier Inc. All rights reserved. 44

Static Power
Static power consumption

25-50% of total power

 Current x Voltage
static
Scales with number of transistors

To reduce: power gating

Copyright © 2019, Elsevier Inc. All rights reserved. 45
Trends
in
Power
and
Energy
Guy: FP

Trends in Cost
Cost driven down by learning curve

Yield

DRAM: price closely tracks cost

Microprocessors: price depends on volume

10% less for each doubling of volume

Copyright © 2019, Elsevier Inc. All rights reserved. 46
Trends
in
Cost

Integrated Circuit Cost
Integrated circuit

 Bose-Einstein formula:
 Defects per unit area = 0.016-0.057 defects per square cm (2010)
 N = process-complexity factor = 11.5-15.5 (40 nm, 2010)
Copyright © 2019, Elsevier Inc. All rights reserved. 47
Trends
in
Cost
Guy:
תיעוּבירָה הרָוּצב תוּבשחתה
הפשב חטש ידְספהוּ

Dependability
Module reliability

Mean time to failure (MTTF)

Mean time to repair (MTTR)

Mean time between failures (MTBF) = MTTF + MTTR

Availability = MTTF / MTBF

Copyright © 2019, Elsevier Inc. All rights reserved. 48
Dependability

Measuring Performance
 Typical performance metrics:
 Response time
 Throughput
 Speedup of X relative to Y
 Execution time / Execution time
Y X
 Execution time
 Wall clock time: includes all system overheads
 CPU time: only computation time
 Benchmarks
 Kernels (e.g. matrix multiply)
 Toy programs (e.g. sorting)
 Synthetic benchmarks (e.g. Dhrystone)
 Benchmark suites (e.g. SPEC06fp, TPC-C)
Copyright © 2019, Elsevier Inc. All rights reserved. 49
Measuring
Performance
Guy
םיעוּציב תינכִת לש המגדְה
:תיסיסב
/home/telzur/science/
Teaching/CPU/lectures/01/
code
$ gcc -O2 -o flops ./flops.c
$ time ./flops.c

Principles of Computer Design
Take Advantage of Parallelism

e.g. multiple processors, disks, memory banks, pipelining,

multiple functional units
Principle of Locality

Reuse of data and instructions

Focus on the Common Case

Amdahl’s Law

Copyright © 2019, Elsevier Inc. All rights reserved. 50
Principles

Principles of Computer Design
The Processor Performance Equation

Copyright © 2019, Elsevier Inc. All rights reserved. 51
Principles

Principles of Computer Design
Copyright © 2019, Elsevier Inc. All rights reserved. 52
Principles
Different instruction types having different CPIs


Fallacies and Pitfalls
All exponential laws must come to an end

Dennard scaling (constant power density)

Stopped by threshold voltage

Disk capacity

30-100% per year to 5% per year

Moore’s Law

Most visible with DRAM capacity

ITRS disbanded

Only four foundries left producing state-of-the-art logic

chips
11 nm, 3 nm might be the limit

Copyright © 2019, Elsevier Inc. All rights reserved. 53

Aside: What is Dennard Scaling?
Dennard Scaling (named after Robert Dennard) is the observation that as transistors get
smaller, their power density stays constant — meaning you can pack more transistors without
increasing power consumption.
The Key Insight
| As transistors shrink: | What happens |
| ---------------------- | ------------ |
| Dimensions (L, W) | ↓ 30% |
| Voltage | ↓ 30% |
| Current | ↓ 30% |
| Power (V² × f) | ↓ 30% |
Dennard Scaling: Power stays constant as transistors shrink
The End of Dennard Scaling (2005-2007)
| Era | What happened |
| ----------- | ------------------------------------------------- |
| Before 2005 | CPUs got faster + more cores, same power |
| After 2005 | "Power wall" — couldn't increase frequency |
| 2007+ | Shift to multi-core (more cores, lower frequency) |
Why It Ended?
| Problem | Cause |
| --------------- | -------------------------------------- |
| Leakage current | Transistors leak power even when "off" |
Guy
| Voltage limits | Can't go below ~1V (threshold voltage) |
| Heat | Power density started increasing |
Copyright © 2019, Elsevier Inc. All rights reserved. 54

CAQA לש 1 קרפמ םיפקשה ףוס
לע תוּמלשהוּ תוּבחרָה ,תוּרָזח רָפסמ דְוּע התע איבנ
הכִ-דְע דְמלנש המ
57

58

59

Patterson, Hennessy: Computer Organization and Design, 5th Edition
60
https://booksite.elsevier.com/9780124077263/downloads/histo
rial%20perspectives/section_1.12.pdf

Classes of Parallelism and Parallel
Architectures - I
1. Data-level parallelism (DLP) arises because there are many data items that can be
operated on at the same time.
2. Task-level parallelism (TLP) arises because tasks of work are created that can operate
independently and largely in parallel.
Computer hardware in turn can exploit these two kinds of application parallelism in
four major ways:
1. Instruction-level parallelism exploits data-level parallelism at modest levels
with compiler help using ideas like pipelining and at medium levels using ideas
like speculative execution.
2. Vector architectures, graphic processor units (GPUs), and multimedia instruction sets
exploit data-level parallelism by applying a single instruction to a collection of data in
parallel (SIMD).
3. Thread-level parallelism exploits either data-level parallelism or task-level par-
allelism in a tightly coupled hardware model that allows for interaction between
parallel threads.
4. Request-level parallelism exploits parallelism among largely decoupled tasks
specified by the programmer or the operating system.
61

Classes of Parallelism and Parallel
Architectures - II
:ואר םדוקה ףקשה תודוא ףסונ רבסהל
!ILP, DLP, TLP, RLP: Easily Explained
https://medium.com/@ramzi.baaguigui1/ilp-dlp-tlp-rlp-and-more-easily-explained-2b6ce22141bb
62

Energy α 1/2 C V 2 , Power α 1/2 C V 2f
:המגוד
חתמב הדירי אטבמ
רדתב הדירי אטבמ
63

האירקל רמאמ
Power: A First-Class Architectural Design Constr
aint.
.IEEE Computer T. Mudge, 2001
http://tnm.engin.umich.edu/wp-content/uploa
ds/sites/353/2017/12/2001.04.Power-a-First-Cl
ass-Architectural-Design-Constraint_Computer
.pdf
64

Measuring, Reporting, and Summarizing
Performance
Speedup:
65

Amdahl’s Law
66

The Processor Performance Equation
CPI=Cycles Per Instruction:
67

:
אבה יוטיבה תא רוכזלו ןיבהל
68

5 classic components of a computer
1. Input ונלש סרוקה
2. Output
3. Memory
4. Datapath
Processor
5. Control
H&P CO&D Chapter 1
69

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
The Computer Systems Stack
Application
Gap too large to bridge in one step
(but there are exceptions,
e.g., a magnetic compass)
Technology
In its broadest definition, computer architecture is the
development of the abstraction/implementation layers that allow us to
execute information processing applications efficiently
using available manufacturing technologies
ECE 4750 Course Overview

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
The Computer Systems Stack
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application Sort an array of numbers
2,6,3,8,4,5 -> 2,3,4,5,6,8
Out-of-place selection sort algorithm
Operating System
1. Find minimum number in array
2. Move minimum number into output array
3. Repeat steps 1 and 2 until finished
C implementation of selection sort
Gate Level
void sort( int b[], int a[], int n ) {
for ( int idx, k = 0; k < n; k++ ) {
int min = 100;
for ( int i = 0; i < n; i++ ) {
Technology if ( a[i] < min ) {
min = a[i];
idx = i;
}
}
b[k] = min;
a[idx] = 100;
}
}
ECE 4750 Course Overview

Instruction Set Architecture (ISA)
The ISA serves as the boundary
between the software and
hardware
72

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
The Computer Systems Stack
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application Mac OS X, Windows, Linux
Handles low-level hardware management
Operating System
MIPS32 Instruction Set
Instructions that machine executes
Gate Level
blez $a2, done
move $a7, $zero
li $t4, 99
Technology move $a4, $a1
move $v1, $zero
li $a3, 99
lw $a5, 0($a4)
addiu $a4, $a4, 4
slt $a6, $a5, $a3 (set on less than)
movn $v0, $v1, $a6
addiu $v1, $v1, 1
movn $a3, $a5, $a6
ECE 4750 Course Overview

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
The Computer Systems Stack
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application
How data flows
through system
Operating System
Boolean logic gates
and functions
Gate Level Combining devices
to do useful work
Transistors and wires
Technology
יחכונה סרוקה
Si Si Si
Silicon process
technology
Si Si Si
ECE 4750 Course Overview

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
Application Requirements vs. Technology Constraints
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
In its broadest definition, computer architecture is the
development of the abstraction/implementation layers that allow us to
execute information processing applications efficiently
using available manufacturing technologies
erutcetihcrA
retupmoC
Application
םושייה תושירד
Application Requirements
• Suggest how to improve architecture
• Provide revenue to fund development
Operating System
Computer engineers provide feedback to guide
application and technology research directions
Gate Level
Technology Constraints םייגולונכט םיצוליא
• Restrict what can be done efficiently
• New technologies make new arch possible
Technology
ECE 4750 Course Overview 3 / 37

• What is Computer Architecture? Computer Architecture Design
Logic, State, and Interconnect
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application
Logic State Logic State Logic
Operating System
Interconnect
Gate Level
State Logic State Logic State
Technology
Digital systems are implemented with three basic building blocks
• Logic to process data
• State to store data
• Interconnect to move data
ECE 4750 Course Overview

• What is Computer Architecture? • Activity 1 Trends in Computer Architecture Activity 2 Computer Architecture Design
Processors, Memories, and Networks
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application
Compute
Processor
data
Operating System
Input Output Move
Network
Data Data data
Gate Level
Store
Memory
data
Technology
Computer engineering basic building blocks
• Processors for computation
• Memories for storage
• Networks for communication
ECE 4750 Course Overview

What is Computer Architecture? Activity 1 • Trends in Computer Architecture • Activity 2 Computer Architecture Design
Application Requirements vs. Technology Constraints
Algorithm
Programming Language
Instruction Set Architecture
Microarchitecture
Register-Transfer Level
Circuits
Devices
erutcetihcrA
retupmoC
Application
Traditional
Application Requirements
Operating System
• As much processor compute as possible
• As much memory capacity as possible
• As much network bandwidth as possible
Gate Level
Traditional
Technology Constraints
• Exponential scaling of resources
Technology
ECE 4750 Course Overview 11 / 37

!רבייס – הטשפהה תובכשל ףסונ טבה
Source: Hardware CWE, Special Interest Group (SIG), MITRE
September 13, 2024.

Role of the (Computer) Architect
בחרמב
ןמזה
תובכשב
היכרריהה
בשחמב
http://users.ece.utexas.edu/~patt/
from Yale Patt’s lecture notes

So, I Hope You Are Here for This
“C” as a model of computation
םימדוק םיסרוק
Programmer’s view of how
a computer system works
 How does an assembly
program end up executing
Architect/microarchitect’s view:
as digital logic? How to design a computer that
meets system design goals.
 What happens in-
Choices critically affect both
the SW programmer and
between?
the HW designer
 How is a computer
designed using logic gates
and wires to satisfy specific
HW designer’s view of how
goals? a computer system works
Digital logic as a
model of computation
םימדוק םיסרוק
81

Levels of Transformation
“The purpose of computing is insight” (Richard Hamming)
We gain and generate insight by solving problems
How do we ensure problems are solved by electrons?
Problem
Algorithm
Program/Language
Runtime System
(VM, OS, MM)
ISA (Architecture)
Microarchitecture
Logic
Circuits
Electrons
82

הרשעה
Aside: A Paper By Hamming
תצלמומ האירק
 Hamming, “Error Detecting and Error Correcting Codes,”
Bell System Technical Journal 1950.
 Introduced the concept of Hamming distance
 number of locations in which the corresponding symbols of two
equal-length strings is different
 Developed a theory of codes used for error detection
and correction
תצלמומ האירק
...האנהל ץיקב....םידומע 25
 Also:
 Hamming, “You and Your Research,” Talk at Bell Labs,
1986.
 http://www.cs.virginia.edu/~robins/YouAndYourResearch.html
83

קחרמ והמ
ןיב Hamming
?הביתה יתמצ

The Power of Abstraction
 Levels of transformation create abstractions
 Abstraction: A higher level only needs to know about the interface to
the lower level, not how the lower level is implemented
 E.g., high-level language programmer does not really need to know
what the ISA is and how a computer executes instructions
 Abstraction improves productivity
 No need to worry about decisions made in underlying levels
 E.g., programming in Java vs. C vs. assembly vs. binary vs. by specifying
control signals of each transistor every cycle
 Then, why would you want to know what goes on underneath or above?
85

Crossing the Abstraction Layers
 As long as everything goes well, not knowing what happens in the underlying level (or
above) is not a problem.
 What if
 The program you wrote is running slow?
 The program you wrote does not run correctly?
 The program you wrote consumes too much energy?
 What if
 The hardware you designed is too hard to program?
 The hardware you designed is too slow because it does not provide the right
primitives to the software?
 What if
 You want to design a much more efficient and higher performance system?
86

Crossing the Abstraction Layers
 Two key goals of this course are
 to understand how a processor works underneath the software
layer and how decisions made in hardware affect the
software/programmer
 to enable you to be comfortable in making design and
optimization decisions that cross the boundaries of different
layers and system components
87

וז תגצמ ןאכ דע
תגצמל רובע
Introduction and Basics