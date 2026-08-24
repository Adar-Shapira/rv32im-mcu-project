םיאבה םיכורב
BGU 361-1-4201
Computer Architecture
Lecture 1: Introduction and Basics
Lecturer: Dr. Guy Tel-Zur
Based on a course by: Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
Version 1.0, 19/03/2020
Version 1.1, 3/3/2021
Version 1.2, 8/3/2023
Version 2, 1/5/2024

An Example: Multi-Core Systems
CORE 1
2
SHARED
L3
CACHE
L2
CACHE
0
DRAM
INTERFACE
CORE 0
CORE 2 CORE 3
L2
CACHE
2
L2
CACHE
1
L2
CACHE
3
DRAM
BANKS
Multi-Core
Chip
DRAM MEMORY
CONTROLLER
היצקרטסבאה תובכש ןיב םירשקה תנבהב ךרוצה תא תושיחממה תואמגוד 3 ראתנ
*Die photo credit: AMD Barcelona

Unexpected Slowdowns in Multi-Core
4
3.5
3.04
3
2.5
2
1.5
1.07
1
0.5
0
matlab gcc
nwodwolS
1 ’סמ המגוד
Low priority
Memory Performance Hog
High priority
Matlab (Core 0) gcc (Core 1)
Moscibroda and Mutlu, “Memory performance attacks: Denial of memory service
in multi-core systems,” USENIX Security 2007.
3

A Question or Two
 Can you figure out why there is a disparity in
slowdowns if you do not know how the system executes
the programs?
םיעוציבב הטאהל הביסה תא ןיבהל תוסנל םילוכי םתא םאה
?תוינכתה תא הצירמ תכרעמה דציכ ןיבהל ילבמ
Can you fix the problem without knowing what is 
?”happening “underneath
שחרתמ המ תעדל ילבמ היעבה תא ןקתל םילוכי םתא םאה
?הלעפהה תכרעמלו םושייל תחתמש תובכשב
4

Why the Disparity in Slowdowns? היצמינא
Multi-Core
| CmOaRtlaEb 1 |     | COgRccE 2 |     |
| ------------ | --- | --------- | --- |
Chip
|     L2  |     |     L2  |     |
| ------- | --- | ------- | --- |
| CACHE   |     | CACHE   |     |
unfairness
INTERCONNECT
 ףדעתמ רקבה
Shared DRAM
 לבא.בלטמ תא
Memory System
?המל DRAM MEMORY CONTROLLER
ףתושמ באשמ
| DRAM   | DRAM   | DRAM   | DRAM   |
| ------ | ------ | ------ | ------ |
| Bank 0 | Bank 1 | Bank 2 | Bank 3 |
5

DRAM Bank Operation
(Row 0, Column 0)
Row Buffer
6
redoced
woR
Columns
(Row 0, Column 1)
(Row 0, Column 85)
(Row 1, Column 0)
RRooww aaddddrreessss 01
RERomowwp t 0y1 HHCIIOTTNFLICT !
CCCCoooolllluuuummmmnnnn aaaaddddddddrrrreeeessssssss 01085 Column mux
Data
Rows
היצמינא
Access Address:

DRAM Controllers
 A row-conflict memory access takes significantly
longer than a row-hit access
 Current controllers take advantage of the row buffer
 Commonly used scheduling policy (FR-FCFS)
[Rixner 2000]*
(1) Row-hit first: Service row-hit memory accesses first
(2) Oldest-first: Then service older accesses first
 This scheduling policy aims to maximize DRAM
throughput
*Rixner et al., “Memory Access Scheduling,” ISCA 2000.
*Zuravleff and Robinson, “Controller for a synchronous DRAM …,” US Patent 5,630,096, May 1997.
7

The Problem
 Multiple applications share the DRAM controller
 DRAM controllers designed to maximize DRAM data
throughput
 DRAM scheduling policies are unfair to some applications
 Row-hit first: unfairly prioritizes apps with high row buffer locality
 Threads that keep on accessing the same row
 Oldest-first: unfairly prioritizes memory-intensive applications
 DRAM controller vulnerable to denial of service attacks
 Can write programs to exploit unfairness
8

היצמינא
A Memory Performance Hog
// initialize large arrays A, B // initialize large arrays A, B
for (j=0; j<N; j++) { for (j=0; j<N; j++) {
index = j*linesize; index = rand();
streaming random
A[index] = B[index]; A[index] = B[index];
… …
} }
STREAM RANDOM
- Sequential memory access - Random memory access
- Very high row buffer locality (96% hit rate) - Very low row buffer locality (3% hit rate)
- Memory intensive - Similarly memory intensive
Moscibroda and Mutlu, “Memory Performance Attacks,” USENIX Security 2007.
https://users.ece.cmu.edu/~omutlu/pub/mph_usenix_security07.pdf
9

Each DIMM has
multiple
DRAMs, each of
which has
multiple banks,
each of which
has multiple
subarrays of
DRAM cells
:tiderC
/moc.gnireenigneimes//:sptth
-rof-tset-lacitcarp-a-ereht-sI
/ytilibarenluv-remmahwor

What Does the Memory Hog Do?
Row Buffer
11
redoced
woR
היצמינא
TTTTT00000::::: RRRRRooooowwwww 00000
TTT001::: RRRooowww 005
TT10: :R Rooww 1 011
TT10: :R Rooww 1 06
Memory Request Buffer
RRooww 00
Column mux
Row size: 8KB, cache block size: 64B
T0: STREAM
128 requests of T0 serviced before T1
(8KB/64B)
T1: RANDOM Data
Moscibroda and Mutlu, “Memory Performance Attacks,” USENIX Security 2007.

Now That We Know What Happens
Underneath
 How would you solve the problem?
 What is the right place to solve the problem?
 Programmer?
 System software?
 Compiler?
Problem
 Hardware (Memory controller)?
Algorithm
 Hardware (DRAM)?
Program/Language
 Circuits?
Runtime System
(VM, OS, MM)
 Two other goals of this course:
ISA (Architecture)
 Enable you to think critically
Microarchitecture
 Enable you to think broadly
Logic
Circuits
Electrons
12

Takeaway
 Breaking the abstraction layers (between components
and transformation hierarchy levels) and knowing what
is underneath enables you to solve problems
"mph_usenix_security07" :רמאמה תא ואריק :תיב ירועיש
:Memory Performance Attacks“
"Denial of Memory Service in Multi-Core Systems
by Thomas Moscibroda and Onur Mutlu
.8 ףיעסב הנקסמהו 7 דומעב 4 ףיעס דע
-ה רתאמ ודירוהל וא תגצמב רושיקב אוצמל ןתינ רמאמה תא
.ונלש moodle
13

Another Example – 2 ’סמ המגוד
 DRAM Refresh
14

A DRAM Cell
wordline
A DRAM cell consists of a capacitor and an access transistor
 It stores data in terms of charge in the capacitor
 A DRAM chip consists of (10s of 1000s of) rows of such cells
eniltib eniltib eniltib eniltib
(row enable)

DRAM Refresh
 DRAM capacitor charge leaks over time
 The memory controller needs to refresh each row periodically to restore charge
 Activate each row every N ms
 Typical N = 64 ms
 Downsides of refresh
-- Energy consumption: Each refresh consumes energy
-- Performance degradation: DRAM rank/bank unavailable while refreshed
-- QoS/predictability impact: (Long) pause times during refresh
-- Refresh rate limits DRAM capacity scaling
16

ןורכיז ביכר לש טרפמ ךותמ
...

Refresh Overhead: Performance
46%
8%
Liu et al., “RAIDR: Retention-Aware Intelligent DRAM Refresh,” ISCA 2012. 19

Refresh Overhead: Energy
47%
15%
Liu et al., “RAIDR: Retention-Aware Intelligent DRAM Refresh,” ISCA 2012. 20

How Do We Solve the Problem?
 Do we need to refresh all rows every 64ms?
 What if we knew what happened underneath and
exposed that information to upper layers?
21

Underneath: Retention Time Profile of DRAM
Retention = הרימש
Liu et al., “RAIDR: Retention-Aware Intelligent DRAM Refresh,” ISCA 2012. 22

Taking Advantage of This Profile
 Expose this retention time profile information to
 the memory controller
 the operating system
 the programmer?
 the compiler?
 How much information to expose?
 Affects hardware/software overhead, power consumption,
verification complexity, cost
 How to determine this profile information?
 Also, who determines it?
23

An Example: RAIDR
היעבה םע תודדומתהל תעצומ הטיש
 Observation: Most DRAM rows can be refreshed much less often without
losing data
[Kim+, EDL’09][Liu+ ISCA’13]
 Key idea: Refresh rows containing weak cells
more frequently, other rows less frequently
1. Profiling: Profile retention time of all rows
2. Binning: Store rows into bins by retention time in memory controller
Efficient storage with Bloom Filters (only 1.25KB for 32GB memory)
3. Refreshing: Memory controller refreshes rows in different bins at different rates
 Results: 8-core, 32GB, SPEC, TPC-C, TPC-H
 74.6% refresh reduction @ 1.25KB storage
 ~16%/20% DRAM dynamic/idle power reduction
 ~9% performance improvement
 Benefits increase with DRAM capacity
:Bloom לש רמאמל רושיק .תושר תאירק
http://www.dragonwins.com/domains/
getteched/bbc/literature/Bloom70.pdf
24
Liu et al., “RAIDR: Retention-Aware Intelligent DRAM Refresh,” ISCA 2012.

Bloom Filter - example
ןנסמה תיינב ,1 בלש
0
תא ונבש םיכרעה ןיבמ ךרע היהי אל רמולכ False negative ןתי אל םלועל ןנסמה :הנותחתה הרושה
.תפדוע הרוצב ללכי המישרב היה אלש ךרע רמולכ False positive תויהל לוכי לבא .ספספתיש ןנסמה
םיקוקז ויה אלש םיאת םג תפדוע הרוצב ןנערנ רתויה לכלו םישלחה םיאתה לכ תא אצמנ :ונלש רשקהב
ןכלו ןכ םג ופומיש םיפסונ םיאת ונכתי( ןנסמ ותואל תואדוב ופומי םישלחה םיאתה לכ ,רמולכ .ןונערל
.)קיזמ וניא הז זא ךרוצל אלש םתוא ןנערנ

Takeaway
 Breaking the abstraction layers (between components
and transformation hierarchy levels) and knowing what
is underneath enables you to solve problems and
design better future systems
 Cooperation between multiple components and layers
can enable more effective solutions and systems
)5 דומע דע( רמאמה תא אורקל :םיצלמומ תיב ירועיש
:רמאמה תדרוהל רושיק
https://users.ece.cmu.edu/~omutlu/pub/raidr-dram-refresh_isca12.pdf
.moodle -ה רתאמ םג הדרוהל ןתינ רמאמה
26

Yet Another Example – 3 ’סמ המגוד
 DRAM Row Hammer (or, DRAM Disturbance Errors)
 For further information:
 https://semiengineering.com/how-to-stop-row-hammer/
 Video on “How To Stop Row Hammer Attacks“:
 https://www.youtube.com/watch?v=yilumG1aP0M&t=13s
27

היצמינא
Disturbance Errors in Modern DRAM
Row of Cells Wordline
VRiocwtim Row
A
R
g
o
g
w
ressor
ROC opl
w
oesneedd VV
LHOIGWH
VRiocwtim Row
Row
Repeatedly opening and closing a row enough times within a
refresh interval induces disturbance errors in adjacent rows
in most real DRAM chips you can buy today
Kim+, “Flipping Bits in Memory Without Accessing Them: An Experimental Study of DRAM Disturbance Errors,”
ISCA 2014.
28

Most DRAM Modules Are At Risk
B
| A   |     |     |     | C   |     |
| --- | --- | --- | --- | --- | --- |

| company |     |     |     | company |     |
| ------- | --- | --- | --- | ------- | --- |

company
| 86%     |     | 83%     |     | 88% |     |
| ------- | --- | ------- | --- | --- | --- |
| (37/43) |     | (45/54) |     |     |     |
(28/32)
| Up to   |     | Up to   |     | Up to   |     |
| ------- | --- | ------- | --- | ------- | --- |
| errors  |     | errors  |     | errors  |     |
|         | 7   |         | 6   |         | 5   |
|         |     |         |     |         |     |
| 1.0×10  |     | 2.7×10  |     | 3.3×10  |     |
Kim+, “Flipping Bits in Memory Without Accessing Them: An Experimental Study of DRAM
Disturbance Errors,” ISCA 2014.
29

x86 CPU DRAM Module
loop:
mov (X), %eax
X
mov (Y), %ebx
clflush (X)
clflush (Y)
mfence Y
jmp loop

x86 CPU DRAM Module
loop:
  mov (X), %eax
|   mov (Y), %ebx | X   |     |
| --------------- | --- | --- |
  clflush (X)
  clflush (Y)
  mfence
|     | Y   |     |
| --- | --- | --- |
  jmp loop

x86 CPU DRAM Module
loop:
  mov (X), %eax
|   mov (Y), %ebx | X   |     |
| --------------- | --- | --- |
  clflush (X)
  clflush (Y)
  mfence
|     | Y   |     |
| --- | --- | --- |
  jmp loop

x86 CPU DRAM Module
loop:
  mov (X), %eax
|   mov (Y), %ebx | X   |     |
| --------------- | --- | --- |
  clflush (X)
  clflush (Y)
  mfence
|     | Y   |     |
| --- | --- | --- |
  jmp loop

Observed Errors in Real Systems
|                           | CPU Architecture | Errors | Access-Rate |
| ------------------------- | ---------------- | ------ | ----------- |
| Intel Haswell (2013)      |                  | 22.9K  | 12.3M/sec   |
| Intel Ivy Bridge (2012)   |                  | 20.7K  | 11.7M/sec   |
| Intel Sandy Bridge (2011) |                  | 16.1K  | 11.6M/sec   |
| AMD Piledriver (2012)     |                  | 59     | 6.1M/sec    |
• A real reliability & security issue
•
In a more controlled environment, we can induce as
many as ten million disturbance errors
34

Errors vs. Vintage
First
Appearance
All modules from are vulnerable
2012–2013
35

How Do We Solve The Problem?
 Do business as usual but better: Improve circuit and device
technology such that disturbance does not happen.
Use stronger error correcting codes.
 Tolerate it: Make DRAM and controllers more intelligent so
that they can proactively fix the errors
 Eliminate or minimize it: Replace DRAM with a different
technology that does not have the problem
 Embrace it: Design heterogeneous-reliability memories that
map error-tolerant data to less reliable portions
 …
36

More on DRAM Disturbance Errors
 Yoongu Kim, Ross Daly, Jeremie Kim, Chris Fallin, Ji Hye Lee, Donghyuk Lee,
Chris Wilkerson, Konrad Lai, and Onur Mutlu,
"Flipping Bits in Memory Without Accessing Them: An Experimental
Study of DRAM Disturbance Errors"
Proceedings of the 41st International Symposium on Computer Architecture
(ISCA), Minneapolis, MN, June 2014. Slides (pptx) (pdf) Lightning Session
Slides (pptx) (pdf) Source Code and Data
 Source Code to Induce Errors in Modern DRAM Chips
 https://github.com/CMU-SAFARI/rowhammer
 Link to the paper:
https://www.archive.ece.cmu.edu/~safari/pubs/kim-isca14.pdf
37
דע אורקל .moodle-המ םג הדרוהל ןתינ רמאמה
.6 דומעב 6 ףיעס

As of today (2025)
Row Hammer attacks remain a significant concern for current DRAM chips. Despite
various mitigation techniques. Researchers continue to find new ways to exploit this
vulnerability. Some key points:
Ongoing Vulnerability: Row Hammer attacks involve repeatedly accessing specific rows
in DRAM, causing bit flips in neighboring rows. This can compromise system integrity and
security.
New Techniques: Recent research has introduced methods like RowPress, which can
induce bit flips even in newer DDR4 chips that have built-in Row Hammer defenses. This
technique works by leaving memory regions open for longer periods, amplifying the
vulnerability.
Defense Mechanisms: While manufacturers have implemented defenses such as Target
Row Refresh (TRR) and other mitigations, these are not foolproof. Researchers continue
to explore ways to bypass these defenses.
Impact of DRAM Scaling: As DRAM cell sizes shrink and cell-to-cell spacing decreases,
the sensitivity to Row Hammer attacks increases. This makes it a persistent challenge in
modern DRAM technology.
Overall, while significant progress has been made in mitigating Row Hammer attacks, the
vulnerability still exists and evolves with new techniques. Continuous research and
development are essential to stay ahead of potential threats.

)2023(
תפסונ האירקל
https://arstechnica.com/security/2023/10/theres-a-new-way-to-flip-bits-in-dram-and-it-works-against-the-latest-defenses/

https://www.theregister.com/2025/07/13/infosec_in_brief/

Recap: Some Goals of our course
 Teach/enable/empower you to:
 Understand how a computing platform works
 Implement a simple platform (with not so simple parts), with a
focus on the processor.
 Understand how decisions made in hardware affect the
software/programmer as well as hardware designer
 Think critically (in solving problems)
 Think broadly across the levels of transformation
 Understand how to analyze and make tradeoffs in design
41

A Note on Hardware vs. Software
 This course is classified under “Computer Hardware”
 However, you will be much more capable if you master
both hardware and software (and the interface
between them)
 Can develop better software if you understand the underlying
hardware
 Can design better hardware if you understand what software it
will execute
 Can design a better computing system if you understand both
 This course covers the HW/SW interface and
microarchitecture
 We will focus on tradeoffs and how they affect software
42

What Do I Expect From You?
 Learn the material thoroughly
 attend lectures, do the readings, do the homeworks
 Do the work & work hard
 Perform the assigned readings
 Come to class on time
 Start early – do not procrastinate
 Remember:
“Chance favors the prepared mind.” (Pasteur)
43

Readings for This Week
Patt, “Requirements, Bottlenecks, and Good Fortune: Agents for
Microprocessor Evolution,” Proceedings of the IEEE 2001.
Moscibroda and Mutlu, “Memory Performance Attacks: Denial of Memory
Service in Multi-Core Systems,” USENIX Security 2007.
Liu+, “RAIDR: Retention-Aware Intelligent DRAM Refresh,” ISCA 2012.
Kim+, “Flipping Bits in Memory Without Accessing Them: An Experimental
Study of DRAM Disturbance Errors,” ISCA 2014.
:אבה רועישל הנכה
P&H 5th ed., Chapter 1 (Fundamentals. pp1-68) and Appendix
A (Instruction Set Principles, pp527-577).
A link to the book.
Our course website: 44
http://tel-zur.net/teaching/bgu/cpu/

4 ’סמ המגוד :סונוב
תושלוחה תחפשמ
Spectre
:ןיכומיס
https://scienceblog.c
om/544049/research
ers-uncover-new-hig
h-precision-attacks-t
argeting-billions-of-i
ntel-and-amd-proces
sors/

וז תגצמ ןאכ דע