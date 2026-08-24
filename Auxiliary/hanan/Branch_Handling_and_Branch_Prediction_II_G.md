361.1.4201
Computer Architecture
Branch Prediction II
Dr. Guy Tel-Zur
Based on slides by Prof. Onur Mutlu
Carnegie Mellon University
Spring 2015
With Dr. Guy Tel-Zur & Danny Seidner’s modifications
Last update: 27/5/2021, 2/6/2022, 31/5/2023, 10/7/2024, 6/6/2026

Agenda for Today & Next Few Lectures
 Single-cycle Microarchitectures
היצמינא
 Multi-cycle and Microprogrammed Microarchitectures
 Pipelining
 Issues in Pipelining: Control & Data Dependence Handling
 Branch prediction
 State Maintenance and Recovery, …
 Out-of-Order Execution
2
 Issues in OoO Execution: Load-Store Handling, …

Reminder: Readings for Next Few Lectures (I)
 Guy: P&H CO&D, Chapter 4 – “The Processor”
 Guy: H&P CAQA, Appendix C - "Pipelining: Basic and
 Intermediate Concepts"
 Smith and Sohi, “The Microarchitecture of Superscalar
Processors,” Proceedings of the IEEE, 1995
 More advanced pipelining
 Interrupt and exception handling
 Out-of-order and superscalar execution concepts
 McFarling, “Combining Branch Predictors,” DEC WRL
Technical Report, 1993.
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro
1999.

Reminder: Readings for Next Few
Lectures (II)
 Smith and Plezskun, “Implementing Precise Interrupts
in Pipelined Processors,” IEEE Trans on Computers 1988
(earlier version in ISCA 1985).
4

Recap of Last Lecture
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
5

Review: More Sophisticated Direction
Prediction
 Compile time (static)
 Always not taken
 Always taken
 BTFN (Backward taken, forward not taken)
 Profile based (likely direction)
 Program analysis based (likely direction)
 Today: Run time (dynamic)
 Last time prediction (single-bit)
 Two-bit counter based prediction
 Two-level prediction (global vs. local)
 Hybrid
 Advanced algorithms (e.g., using perceptrons)
6

Review: Importance of The Branch Problem
 Assume N = 20 (20 pipe stages), W = 5 (5 wide fetch)
 Assume: 1 out of 5 instructions is a branch
 Assume: Each 5 instruction-block ends with a branch
How long does it take to fetch 500 instructions?
 100% accuracy
 100 cycles (all instructions fetched on the correct path)
 No wasted work
 99% accuracy
 100 (correct path) + 20 (wrong path) = 120 cycles
 20% extra instructions fetched
 98% accuracy
 100 (correct path) + 20 * 2 (wrong path) = 140 cycles
 40% extra instructions fetched
 95% accuracy
 100 (correct path) + 20 * 5 (wrong path) = 200 cycles
7
 100% extra instructions fetched

Importance of The Branch Problem - continued
 Assume N = 20 (20 pipe stages), W = 5 (5 wide fetch)
 Assume: 1 out of 5 instructions is a branch
 Assume: Each 5 instruction-block ends with a branch
 How long does it take to fetch 500 instructions?
איה ןאכ הריפסה
 100% accuracy
ןועש ירוזחמב
 100 cycles (all instructions fetched on the correct path)
 No wasted work; IPC = 500/100
 90% accuracy
 100 (correct path) + 20 * 10 (wrong path) = 300 cycles
 200% extra instructions fetched; IPC = 500/300
 85% accuracy
 100 (correct path) + 20 * 15 (wrong path) = 400 cycles
 300% extra instructions fetched; IPC = 500/400
 80% accuracy
 100 (correct path) + 20 * 20 (wrong path) = 500 cycles
8
 400% extra instructions fetched; IPC = 500/500

תימניד הטיש
Dynamic Branch Prediction
 Idea: Predict branches based on dynamic information
(collected at run-time)
 Advantages
+ Prediction based on history of the execution of branches
+ It can adapt to dynamic changes in branch behavior ידכ ךות
תינכתה תציר
+ No need for static profiling: input set representativeness
problem goes away
 Disadvantages
-- More complex (requires additional hardware)
9

Last Time Predictor
 Last time predictor
 Single bit per branch (stored in BTB) BTB=Branch Target Buffer
 Indicates which direction branch went last time it executed
TTTTTTTTTTNNNNNNNNNN  90% accuracy
לש תיזחתבו הנושארה תיזחתב הצמחה היהת .10%-ה ןכיהמ
20 ךותמ 2 .המגמה ךופיה
 Always mispredicts the last iteration and the first iteration
of a loop branch
 Accuracy for a loop with N iterations = (N-2)/N
+ Loop branches for loops with large N (number of iterations)
-- Loop branches for loops with small N (number of iterations)
TNTNTNTNTNTNTNTNTNTN  0% accuracy
Last-time predictor CPI = [ 1 + (0.20*0.15) * 2 ] = 1.06 (Assuming 85% accuracy)
10

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
nextPC
The 1-bit BHT (Branch History Table) entry is updated with
the correct outcome after each execution of a branch
12

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
13

Improving the Last Time Predictor
 Problem: A last-time predictor changes its prediction from
TNT or NTT too quickly
 even though the branch may be mostly taken or mostly not
taken
 Solution Idea: Add hysteresis to the predictor so that
prediction does not change on a single different outcome
 Use two bits to track the history of predictions for a branch
instead of a single bit
 Can have 2 states for T or NT instead of 1 state for each
 Smith, “A Study of Branch Prediction Strategies,” ISCA 1981.
14

Two-Bit Counter Based Prediction
 Each branch associated with a two-bit counter (2BC)
 One more bit provides hysteresis
 A strong prediction does not change with one single
different outcome
 Also called binomial prediction
 Accuracy for a loop with N iterations = (N-1)/N
TNTNTNTNTNTNTNTNTNTN  50% accuracy
העדה תא תונשל ידכ N םיימעפ ךירצ
(assuming counter initialized to weakly taken)
10% >-- 20 ךותמ 2 :המגודב
+ Better prediction accuracy
2BC predictor CPI = [ 1 + (0.20*0.10) * 2 ] = 1.04 (90% accuracy)
-- More hardware cost (but counter can be part of a BTB entry)
16

Hysteresis Using a 2-bit Counter
actually
actually
“weakly
!taken
taken
taken”
| “strongly | pred  | pred  |
| --------- | ----- | ----- |
| taken”    | taken | taken |
|           | 11    | 10    |
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
|         | pred   | pred   |
| ------- | ------ | ------ |
| “weakly | !taken | !taken |
actually
|     | 01  | 00  |
| --- | --- | --- |
actually
!taken” !taken
taken
Change prediction after 2 consecutive mistakes 17

Credit: H&P CAQA 3.9

State Machine for 2-bit Saturating Counter
 Counter using saturating arithmetic
 Arithmetic with maximum and minimum values
19

Is This Good Enough?
 ~85-90% accuracy for many programs with 2-bit counter
based prediction (also called bimodal prediction)
 Is this good enough?
 How big is the branch problem?
20

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
21

תושר רמאמ
Alternative implementations of two-level adaptive branch prediction
Authors: Tse-YuYeh, Yale N.Patt
https://dl.acm.org/doi/10.1145/146628.139709

תושר רמאמ
Dynamic Branch Prediction Modeller for RISC Architecture
Harsh Arora; Sagar Kotecha; Romil Samyal
2013 International Conference on Machine Intelligence and Research
Advancement
https://ieeexplore.ieee.org/document/6918861
DOI: 10.1109/ICMIRA.2013.84

Review: Can We Do Better?
(than always taken or always
not taken)
 Last-time and 2BC predictors exploit “last-time”
predictability
תונבות
 Realization 1: A branch’s outcome can be correlated with
other branches’ outcomes
 Global branch correlation – לש םינוש םיעפומ ןיב רושקל ןתינ
תויופעתסה
 Realization 2: A branch’s outcome can be correlated with
past outcomes of the same branch (other than the outcome
of the branch “last-time” it was executed)
 Local branch correlation – תירוטסיה םע יחכונ בצמ רושקל ןתינ
תופעתסהה
25
Yeh and Patt, “Two-Level Adaptive Training Branch Prediction,” MICRO 1991.

ןושארה הרקמהמ ליחתנ
Global Branch Correlation (I)
 Recently executed branch outcomes in the execution
path is correlated with the outcome of the next branch
1 המגוד
 If first branch not taken, second also not taken
2 המגוד
וא
 If first branch taken, second definitely not taken
26

Global Branch Correlation (II)
 If Y and Z both taken, then X also taken
 If Y or Z not taken, then X also not taken
27

Global Branch Correlation (III)
-מ החוקל וז המגוד  :איג
 Eqntott, SPEC 1992
H&P Computer Architecture  3.3
EQNTOTT דוקל תכייש המגודה
| if (aa==2)   |            ;; B1 |     |
| ------------ | ---------------- | --- |
SPEC89-מ
     aa=0;
| if (bb==2) |            ;; B2 | םיאנתהמ דחא לע קר םילכתסמ םא |
| ---------- | ---------------- | ---------------------------- |
.B3 תא קיסהל ןתינ אל B2 וא B1
     bb=0;
המושרש הנקסמה תא עובקל ידכ ןכל
| if (aa!=bb) { | }          ;; B3 |     |
| ------------- | ---------------- | --- |
תויופעתסהה לע תעדל ךירצ הטמל
.B2 לש ןהו B1 לש ןה
| if (aa==bb) { |  }         ;; B3 |     |
| ------------- | ---------------- | --- |
     ….

28

Demo :ימצעל הרעה
EQNTOTT
~/.../CPU/lectures/10/code/eqntott-tests
test2 תא םגדה
https://nullstone.com/eqntott/eqntott.htm

Global Branch Correlation (III) - ךשמה
If b1 is not taken (i.e., aa==0@b3) and b2 is not taken (i.e. bb=0@b3)
then b3 is certainly taken
.יוגש היהי םילוציפהמ דחא ס"ע קר תיזחת תושעל ןויסינ
.הנוכנ תיזחת ןתית םילוציפה ינשב תובשחתה קר
.Correlating תארקנ תחא תופעתסהמ רתוי ךמס לע תיזחת
Credit: H&P CAQA 5th Ed., section 3.3

SPEC
SPEC = Standard Performance Evaluation Corporation
https://www.spec.org/
SPECint and SPECfp

Capturing Global Branch Correlation
 Idea: Associate branch outcomes with “global T/NT history”
of all branches
 Make a prediction based on the outcome of the branch the
last time the same global branch history was encountered
 Implementation:
 Keep track of the “global T/NT history” of all branches in a
register  Global History Register (GHR)
 Use GHR to index into a table that recorded the outcome that
was seen for each GHR value in the recent past  Pattern
History Table (table of 2-bit counters)
 Global history/branch predictor
 Uses two levels of history (GHR + history at that GHR)
Yeh and Patt, “Two-Level Adaptive Training Branch Prediction,” MICRO 1991.
33

Two Level Global Branch Prediction
התע םיקסוע ונחנא :תרוכזת
 First level: Global branch history register (N bits) תחיקל יבגל הצלמהב קר
םשל .תבותכב אל .תופעתסהה
 The direction of last N branches BTB -ה ונשי ךכ
 Second level: Table of saturating counters for each history entry
 The direction the branch took the last time the same history was
seen
טיב N Pattern History Table (PHT)
00 …. 00
1 1 ….. 1 0
00 …. 01
2 3
GHR
previous 00 …. 10
(global
branch’s
history
direction
register)
index
0 1
םג ארקנ
BHR=Branch History
Register
11 …. 11
Yeh and Patt, “Two-Level Adaptive Training Branch Prediction,” MICRO 1991. 34

Yeh & Patt 1991 ירוקמה רמאמה ךותמ
Shift left when update
branch result

How Does the Global Predictor Work?
1110 הארה GR רשאכ J תאלולל ונסנכנ
This branch tests I.
GR = Global Register Last 3 branches test j
History: TTTN
בצייתת תינבתהו 1101 בוש לבקנ 1110 ירחא
Predict taken for i
המצע לע רוזחתו
Next history: TTNT
אל MCFARLING .יתימא GR שממ אלו PC רפ אוה רמאמבש GR -ה ,תוויע תצק שי הפ
(shift in last outcome)
בצמ תוארל םייופצ ונייה תרחא !!!I לש הקידבהמ האצותכ GR-ה לש יונישב בשחתמ
רמאמב וא ףקשב הארנ אלש 1111
36
 McFarling, “Combining Branch Predictors,” DEC WRL TR 1993.

McFarling, “ Combining Branch Predictors,” DEC WRL TR
1993

McFarling, “ Combining Branch Predictors,” DEC WRL TR
1993

Correlating Branches – ידממ-וד סקודניא
Branch address (4 bits)
Idea: taken/not taken of
recently executed branches
is related to behavior of
2-bits per branch
next branch (as well as the
local predictors
history of that branch
behavior)
.דבלב םיטיב 4 ס”ע תמיוסמ תופעתסה לש תבותכ
.תויופעתסה 16 כ”הס
– Then behavior of recent
)תורוש 16 תוארנ אל הז םישרתב(
branches selects between, say,
Prediction
Prediction
4 predictions of next branch,
updating just that prediction
• (2,2) predictor: 2-bit global,
2-bit local
תורוש 16 >- תופעתסהה תבותכ לש טיב 4
תריחב
תודומע 4 >- תילבולג הירוטסיה לש טיב 2 הדומעה
2-bit global
תיזחתה תא שי הדומעל הרושה ןיב ךותיחה ךותב
branch history
(01 = not taken then taken)
3/16/01 CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.39

Following Yeh & Patt
םדוקה םישרתה ומכ
בבוסמ קר
credit:
“Modern Processor
Design” by
S3h/1e6/n01 & Lipasti CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.40

הירוטסיה – תבותכ :X-X סקודניא
תילבולג
3/16/01 CS252/Patterson
https://sites.pitt.edu/~juy9/2162/slides-F2009/6_BranchPred.pdf
Edited by D. Seidner, 4/04 Lec 5.42

Correlating branch prediction
y
a>0
n
y
Say that a and b are random b>0
variables uniformly
n
distributed from -1 to +1.
It is clear that
The statistics of the 3rd
y
branch depends on the 1st
a+b>0
and 2nd branches
n
3/16/01 CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.43

Correlating branch prediction
y
y
a>0
a=b
n
n
y
Note that the “global” part of b>0
the prediction means that we
n
are not sure which were the
last 2 previous branches.
We might mix statistics of
y
several paths in the program.
a+b>0
n
וניה ןוידה
לש הביטקפסקפב
תישילשה תופעתסהה
3/16/01 CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.44

(m,n) predictor:
Correlating Branches
(cont.)
היצמינא
m bit global,
n bit local
Branch address
Size=2kx 2m x n (k LSBs of PC)
2-bits per branch
here n=2
local predictors
Branch
address
Prediction
k
2
2
k
2
Next m
state
m-bit global .calc
Taken
branch history Taken ןוכדעה
m-bit global
branch history
וניאר ןכ ינפל .יללכה הרקמה הארנ ןאכ
m=2 רובע תואמגוד
3/16/01 CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.45

תפסונ האירקל
https://www.geeksforgeeks.org/correlating-branch-prediction/
3/16/01 CS252/Patterson
Edited by D. Seidner, 4/04 Lec 5.46

Intel Pentium Pro Branch Predictor
 Two level global branch predictor
 4-bit global history register
McFarling לש רמאמב םדוק המגודב וניארש לדוג ותואב קוידב 
 Multiple pattern history tables (of 2 bit counters)
•
Which pattern history table to use is determined by lower
order bits of the branch address
 First widely commercially successful out-of-order
execution machine
47

Intel Pentium Pro (1995)
Processor chip Level 2 cache chip
Multi-chip module package
49
By Moshen - http://en.wikipedia.org/wiki/Image:Pentiumpro_moshen.jpg, CC BY-SA 2.5, https://commons.wikimedia.org/w/index.php?curid=2262471

Improving Global Predictor Accuracy
 Idea: Add more context information to the global predictor to take into
account which branch is being predicted
 Gshare predictor: GHR hashed with the Branch PC
+ More context information used for prediction
+ Better utilization of the two-bit counter array (PHT = Pattern History
Table).
-- Increases access latency
50
 McFarling, “Combining Branch Predictors,” DEC WRL Tech Report, 1993.

Review: One-Level Branch Predictor
Direction predictor (2-bit counters)
taken?
PC + inst size
Next Fetch
Address
Program
hit?
Counter
Address of the
current instruction
target address
Cache of Target Addresses (BTB: Branch Target Buffer)
51

Two-Level Global History Branch Predictor
Direction predictor (2-bit counters)
Which direction earlier
branches went
taken?
Global branch
history PC + inst size
Next Fetch
Address
Program
hit?
Counter
Address of the
current instruction
target address
Cache of Target Addresses (BTB: Branch Target Buffer)
52

Two-Level Gshare Branch Predictor
Direction predictor (2-bit counters)
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
current instruction
target address
תירוטסיה ןיב עדימה בוליש
ןיבל תויופעתסהה
PC-ב ךרעה
Cache of Target Addresses (BTB: Branch Target Buffer)
53

Combining Branch Predictors
Scott McFarling

Scott McFarling, “Combining Branch Predictors”
בלושמ
יוזיחב תואטחה יתש ןיב תוארוהה רפסמ

Scott McFarling, “Combining Branch Predictors”

Can We Do Better?
 Last-time and 2BC predictors exploit only “last-time”
predictability for a given branch
 Realization 1: A branch’s outcome can be correlated with
other branches’ outcomes
 Global branch correlation
 Realization 2: A branch’s outcome can be correlated with
past outcomes of the same branch (in addition to the
outcome of the branch “last-time” it was executed)
 Local branch correlation
57

Local Branch Correlation
 McFarling, “Combining Branch Predictors,” DEC WRL TR 1993.
58

Scott McFarling, “Combining Branch Predictors”
ןוכדע תנזה
:תואלבט 2
תויופעתסה לש הירוטסיהה :תילאמשה .1
הלבטב ךרעה ךותמ הפוממ :תינמיה .2
.2BC ןוגכ הנומ הליכמו תילאמשה

More Motivation for Local History
Loop closing branch’s history
תבותכה PHT
 To predict a loop
11101110111011101110 0000
branch “perfectly”,
0001
4 bit address,
we want to identify
0010
1 bit prediction
the last iteration of 0011
for example:
the loop 0100
01110 (top right)
0101
0110
 By having a separate 0111 00
1000
PHT entry for each
1001
local history, we can 3 דע 0-מ תרפוסש האלולב
1110 איה תופעתסהה 1010
distinguish different
T םימעפ3 :)ןימיל לאמשמ( 1011 11
iterations of a loop
תלבטב ןכל .NT תחא םעפו 1100
תוסלכואמ תויופעתסהה
 Works for “short” 1101 11
תויטנוולרה תורושה קר
1110 11
loops
1111
...אבה ףקשב םג המוד םישרת
60

Local History Predictor Example
ךשמהו NT לש תינבת
האלולה
םויס לש תינבת
האלול
Credit: Shen & Lipasti, Figure 9.7 :רפסה ךותמ םעפה ,םישרתה ותוא

Capturing Local Branch Correlation
 Idea: Have a per-branch history register
 Associate the predicted outcome of a branch with “T/NT
history” of the same branch
 Make a prediction based on the outcome of the branch
the last time the same local branch history was
encountered
 Called the local history/branch predictor
 Uses two levels of history (Per-branch history register +
history at that history register value)
62

היצמינא
Two Level Local Branch Prediction
ףקשב ףסונ רבסה
 First level: A set of local history registers (N bits each)
אבה
 Select the history register based on the PC of the branch
 Second level: Table of saturating counters for each history entry
 The direction the branch took the last time the same history was
seen
ןונגנמב השענש הזל המוד ןאכ לופיטה
Pattern History Table (PHT)
!ילבולגה
00 …. 00
1 1 ….. 1 0
00 …. 01
2 3
00 …. 10
index
0 1
Local history
11 …. 11
registers
63
Yeh and Patt, “Two-Level Adaptive Training Branch Prediction,” MICRO 1991.

ףסונ םישרת
2^7=128
2^7*12 + 2^12*2 = 1536 + 8192 = 9728bits=9.5kb

Two-Level Local History Branch Predictor
Which directions earlier instances of *this branch* went
היצמינא
Direction predictor (2-bit counters)
taken?
PC + inst size
Next Fetch
Address
Program
hit?
Counter
Address of the
current instruction
target address
Cache of Target Addresses (BTB: Branch Target Buffer)
65

Can We Do Even Better?
 Predictability of branches varies
 Some branches are more predictable using local history
 Some branches are more predictable using global
 For others, a simple two-bit counter is enough
 Yet for others, a single bit is enough
 Observation: There is heterogeneity in predictability
behavior of branches
 No one-size fits all branch prediction algorithm for all
branches
 Idea: Exploit that heterogeneity by designing
heterogeneous (hybrid) branch predictors
66

Hybrid Branch Predictors היצמינא
 Idea: Use more than one type of predictor (i.e., multiple
algorithms) and select the “best” prediction
 E.g., hybrid of 2-bit counters and global predictor
 Advantages:
+ Better accuracy: different predictors are better for different branches
+ Reduced warmup time (faster-warmup predictor used until the
slower-warmup predictor warms up)
 Disadvantages:
-- Need “meta-predictor” or “selector”
-- Longer access latency
-- More hardware & complexity
 McFarling, “Combining Branch Predictors,” DEC WRL Tech Report, 1993. 67

Alpha 21264 Tournament Predictor
בוט היה ימ
רתוי
םימעפב
?תומדוקה
ילבולג יוזיח :רופא עבצב
 Minimum branch penalty: 7 cycles
 Typical branch penalty: 11+ cycles
 48K bits of target addresses stored in I-cache
 Predictor tables are reset on a context switch
 Kessler, “The Alpha 21264 Microprocessor,” IEEE Micro 19 6 9 8 9.

Kessler, "THE ALPHA 21264 MICROPROCESSOR”

Biased Branches and Branch Filtering
 Observation: Many branches are biased in one direction
(e.g., 99% taken)
 Problem: These branches pollute the branch prediction
structures  make the prediction of other branches
difficult by causing “interference” in branch prediction
tables and history registers
 Solution: Detect such biased branches, and predict them
with a simpler predictor (e.g., last time, static, …)
)ןתינ םא( יוזיחה ךרוצל רתויב טושפה ןונגנמב שמתשהל ףידענ
 Chang et al., “Branch classification: a new mechanism for improving
branch predictor performance,” MICRO 1994.
70

Are We Done w/ Branch Prediction?
 Hybrid branch predictors work well
 E.g., 90-95% prediction accuracy on average
 Some “difficult” workloads still suffer, though!
 E.g., gcc
 Max IPC with tournament prediction: 9
 Max IPC with perfect prediction: 35
9/35 ≈ 26% prediction accutacy
71

Some Other Branch Predictor Types
 Loop branch detector and predictor – תואלולב החמתמה יוזיח ןונגנמ
 Loop iteration count detector/predictor
 Works well for loops with small number of iterations, where iteration
count is predictable
 Used in Intel Pentium M
 Perceptron branch predictor (Global)
 Learns the direction correlations between individual branches
 Assigns weights to correlations
 Jimenez and Lin, “Dynamic Branch Prediction with Perceptrons,” HPCA
2001.
 Used in AMD Zen/Zen2 family
 Hybrid history length based predictor
 Uses different tables with different history lengths
 Seznec, “Analysis of the O-Geometric History Length branch predictor,”
ISCA 2005.
72
 Used in AMD Zen/Zen2 family

Intel Pentium M Predictors: Loop and Jump
A Single Entry
of the Loop
Predictor Table
Used
in the Pentium-
M Processor.
Gochman et al.,
“The Intel Pentium M Processor: Microarchitecture and Performance,”
Intel Technology Journal, May 2003.
אבה ףקשב ןתינ רמאמה ךותמ רבסה 73

Intel Pentium M (2003) היצמינא
75
https://www.anandtech.com/show/1083/3

More Advanced Branch Prediction
76

Perceptrons for Learning Linear Functions
 A perceptron is a simplified model of a biological neuron
 It is also a simple binary classifier
 A perceptron maps an input vector X to a 0 or 1
 Input = Vector X (םיכרע לש טס)
 Perceptron learns the linear function (if one exists) of how each
element of the vector affects the output (stored in an internal
Weight vector)
 Output = Weight·X + Bias, if > 0 → Output=1 else Output=0;
תויופעתסהה לש הירוטסיהל םילקשמ ןתמ
 In the branch prediction context
 Vector X: Branch history register bits
 Output: Prediction for the current branch, 1=Taken, 0=NT
77
Rosenblatt, “Principles of Neurodynamics: Perceptrons and the Theory of Brain Mechanisms,” 1962

Perceptron Branch Predictor (I)
 Idea: Use a perceptron to learn the correlations between branch
history register bits and branch outcome
 A perceptron learns a target Boolean function of N inputs
Each branch associated with a perceptron
A perceptron contains a set of weights wi
→Each weight corresponds to a bit in
the GHR
→How much the bit is correlated with the
direction of the branch
→ Positive correlation: large positive weight
→ Negative correlation: large negative weight
Prediction:
→ Express GHR bits as 1 (T) and -1 (NT)
→ Take dot product of GHR and weights
→ If output > 0, predict taken
78
 Jimenez and Lin, “Dynamic Branch Prediction with Perceptrons,” HPCA 2001.
 Rosenblatt, “Principles of Neurodynamics: Perceptrons and the Theory of Brain Mechanisms,” 1962

Perceptron Branch Predictor (II)
היצמינא
Prediction function:
Dot product of GHR
and perceptron weights
Output
Bias weight
compared
(bias of branch, independent of
to 0
the history)
t={ -1, +1}, let theta be the
threshold, a parameter
to the training algorithm
used to decide when
Training function:
enough training has
been done.
תולועפ עוציבב ךרוצ שי .ההובג תובכרומ
תובורמ לפכ
Daniel A. Jiménez and Calvin Lin, “Dynamic Branch Prediction with Perceptrons”

Perceptron Branch Predictor (III)
 Advantages
+ More sophisticated learning mechanism → better accuracy
+ Enables long branch history lengths → better accuracy
 Disadvantages
-- Complexity (adder tree to compute perceptron output)
-- Can learn only linearly-separable functions
e.g., cannot learn XOR type of correlation between 2
history bits and branch outcome
A successful example of use of machine learning in processor design
See, e.g., Grayson+, “Evolution of the Samsung Exynos CPU Microarchitecture,” ISCA 2020.
80

Recommended Reading
81
Grayson+, “Evolution of the Samsung Exynos CPU Microarchitecture,” ISCA 2020.

AMD Piledriver/Zen/Zen2 (2012-Present)
 Employ a perceptron branch predictor
Perceptron
...םיבורקה םיפקשב
82
https://fuse.wikichip.org/news/2458/a-look-at-the-amd-zen-2-core/

Another Idea: TAGE
83

Prediction Using Multiple History Lengths
לודגה לא ןטקהמ תוירוטסיה ךרוא
 Observation: Different
branches require
different history
lengths for better
prediction accuracy
טושפ רוטקידרפ
 Idea: Have multiple
PHTs indexed with
GHRs with different
history lengths and
intelligently allocate
PHT entries to
different branches
Seznec and Michaud, “A case for (partially) tagged Geometric History Length
Branch Prediction,” JILP 2006.
יוזיח ינונגנמ לש תירטמואיג הלדג הרדס
84
הירוטסיה יפ-לע

Different Branches: Different History Lengths
“...An entry on a tagged table consists of the partial tag, the jump target, the
confidence bit and a 2-bit useful counter”
85
https://fuse.wikichip.org/news/2458/a-look-at-the-amd-zen-2-core/

TAGE Branch Predictor
 Advantages
+ Chooses the “best” history length to predict each branch →
better accuracy
+ Enables long branch history lengths → better accuracy
 Disadvantages
-- Hardware (design) complexity is not low
-- Need to choose good hash functions and table sizes to
maximize accuracy and minimize latency
A successful recent idea that is used in many modern processor designs
86

Seznec & Michaud
comp = component

AMD Zen2 TAGE Predictor (2019)
88
https://fuse.wikichip.org/news/2458/a-look-at-the-amd-zen-2-core/

State of the Art in Branch Prediction
היצמינא
 See the Branch Prediction Championship
 https://www.jilp.org/cbp2016/program.html
Andre Seznec,
“TAGE-SC-L branch predictors,”
CBP 2014.
Andre Seznec,
“TAGE-SC-L branch predictors
again,” CBP 2016.
89

https://www.jilp.org/cbp2016/program.html

“For pioneering contributions to branch prediction
and cache memories.”

Branch Confidence Estimation
 Idea: Estimate if the prediction is likely to be correct
 i.e., estimate how “confident” you are in the prediction
 Why?
 Could be very useful in deciding how to speculate:
 What predictor/PHT to choose/use
 Whether to keep fetching on this path
 Whether to switch to some other way of handling the branch, e.g.
dual-path execution (eager execution) or dynamic predication
 …
 Jacobsen et al., “Assigning Confidence to Conditional Branch
Predictions,” MICRO 1996.
92

Speculative Processor

How to Estimate Confidence
 An example estimator:
 Keep a record of correct/incorrect outcomes for the past N
instances of the “branch”
 Based on the correct/incorrect patterns, guess if the
current prediction will likely be correct/incorrect
CIR =
Correct / Incorrect
Register
94
Jacobsen et al., “Assigning Confidence to Conditional Branch Predictions,” MICRO 1996.

What to Do With Confidence Estimation?
 An example application: Pipeline Gating
.יוזיחה תונימאל )ןויצ( גורד ןתמ
הובג M .)ןימא אל יוזיחה יכ( יחכונה יוזיחב לופיטה קספיי זא M>N םא .ףס ךרע אוה N
.ןימא אל יוזיח ושוריפ
Manne et al., “Pipeline Gating: Speculation Control for Energy Reduction,” ISCA 1998.

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
:רמאמה ךותמ
ןוכסח
יטגרנא
ןורתי
הטישה
ןוכסח
יטגרנא

ןאכ דע
Dynamic branch prediction
-ל רוזחנ
Predicated execution
It was already discussed in previous lecture but
here we add a few more details
98

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
99

Review: Predicate Combining (not Predicated
Execution)
 Complex predicates are converted into multiple branches
 if ((a == b) && (c < d) && (a > 5000)) { … }
 3 conditional branches
 Problem: This increases the number of control
dependencies
 Idea: Combine predicate operations to feed a single branch
instruction
 Predicates stored and operated on using condition registers
 A single branch checks the value of the combined predicate
+ Fewer branches in code  fewer mipredictions/stalls
-- Possibly unnecessary work
-- If the first predicate is false, no need to compute other predicates
100
 Condition registers exist in IBM RS6000 and the POWER architecture

Predication (Predicated Execution)
 Idea: Convert control dependence to data dependence
 Simple example: Suppose we had a Conditional Move
instruction…
 CMOV condition, R1 ← R2
 R1 = (condition == true) ? R2 : R1
 Employed in most modern ISAs (x86, Alpha)
 Code example with branches vs. CMOVs
if (a == 5) {b = 4;} else {b = 3;}
CMPEQ condition, a, 5;
CMOV condition, b ← 4;
CMOV !condition, b ← 3;
101

Conditional Move Operations
 Very limited form of predicated execution
 CMOV R1  R2
 R1 = (ConditionCode == true) ? R2 : R1
 Employed in most modern ISAs (x86, Alpha)
102

היצמינא
Predication (Predicated Execution)
 Idea: Compiler converts control dependence into data
dependence  branch is eliminated
 Each instruction has a predicate bit set based on the predicate computation
 Only instructions with TRUE predicates are committed (others turned into
NOPs)
(normal branch code) (predicated code)
A
A
T N
if (cond) {
B
C B
b = 0;
C
}
D
D
else {
A
p1 = (cond)
b = 1;
A
branch p1, TARGET p1 = (cond)
} B
mov b, 1
B
(!p1) mov b, 1
jmp JOIN
C
TARGET: C
(p1) mov b, 0
mov b, 0
D D
add x, b, 1
add x, b, 1 103

| Predicated Execution (II) |     |     | היצמינא |     |
| ------------------------- | --- | --- | ------- | --- |
 Predicated execution can be high performance and
energy-efficient
Predicated Execution
A
Fetch  Decode  Rename  Schedule RegisterRead Execute
CDFEAB DFECAB CDEBFA CDEABF CDABEF DCEABF CDFAEB DCFEBAF CDEABE DCDBA CCAB BAB AA
| C   | B   |     | n   |     |
| --- | --- | --- | --- | --- |
|     |     |     | o p |     |
Branch Prediction
D Fetch  Decode  Rename  Schedule RegisterRead Execute
|     |     | F E | D B | A   |
| --- | --- | --- | --- | --- |
E
Pipeline flush!!
F
104

Predicated Execution (III)
 Eliminates branches → enables straight line code (i.e., larger
basic blocks in code)
 Advantages:
+ Eliminates mispredictions for hard-to-predict branches
+ No need for branch prediction for some branches
+ Good if misprediction cost > useless work due to predication
+ Enables code optimizations hindered (י”ע ערפומ) by the control dependency
+ Can move instructions more freely within predicated code
 Disadvantages:
-- Causes useless work for branches that are easy to predict
-- Reduces performance if misprediction cost < useless work
-- Adaptivity: Static predication is not adaptive to run-time branch behavior. Branch
behavior changes based on input set, program phase, control-flow path.
-- Additional hardware and ISA support
-- Cannot eliminate all hard to predict branches
105
-- Loop branches

Predicated Execution vs. Branch Prediction
+ Eliminates mispredictions for hard-to-predict branches
+ No need for branch prediction for some branches
+ Good if misprediction cost > useless work due to predication
-- Causes useless work for branches that are easy to predict
-- Reduces performance if misprediction cost < useless work
-- Adaptivity: Static predication is not adaptive to run-time
branch behavior. Branch behavior changes based on input set,
program phase, control-flow path.
106

Intel Itanium
Intel Itanium Architecture Software Developer's Manual
לופיטה לש תויורשפאה ןווגמ טוריפב קסוע ךירדמב 4 קרפ
Predication-ה ןונגנמב תויופעתסהב

Predicated Execution in Intel Itanium
 Each instruction can be separately predicated
 64 one-bit predicate registers
each instruction carries a 6-bit predicate field
 An instruction is effectively a NOP if its predicate is false
p1 p2 cmp
cmp
p2 else1
br
p1 then1
else1
join1
else2
p1 then2
br
p2 else2
then1
join2
then2
join1
join2
108

Intel Itanium
p1, p3 םיאנתה םה
Reference:
Intel® Itanium ® Architecture
Software Developer’s Manual. Volume 1: Application Architecture
Revision 2.3, May 2010
Section 2.5 - Predication

movn and movz in MIPS
int bar(int,int); foo:
slt $2,$5,$4
int foo(int a, int b){ movn $5,$0,$2
if (a <= b) movz $4,$0,$2
a = 0; j bar
else nop
b = 0;
return bar(a, b);
} רושיקה לע ץחל .המגדה עצב
Version 1: -O0 -march=mips32 -fno-delayed-branch
Version 2: -O3 -march=mips32 -fno-delayed-branch
:המוד המגוד
Show a demo:
:~/science/Teaching/CPU/lectures/10/code/movz

$ cat ./run_me.sh
#!/bin/sh
mips-linux-gnu-gcc -S -O0 -march=mips32 -fno-delayed-branch ./test1.c
mv test1.s test1_not_optimized.s
mips-linux-gnu-gcc -S -O3 -march=mips32 -fno-delayed-branch ./test1.c
mv test1.s ./test1_optimized.s

Conditional Execution in the ARM ISA
 Almost all ARM instructions can include an optional
condition code.
 An instruction with a condition code is executed only if the
condition code flags in the CPSR meet the specified
condition.
CPSR = Current Program Status Register
At any given moment, you have access to 16 registers (R0-R15) and
the Current Program Status Register (CPSR).
(In User mode, a restricted form of the CPSR called the Application Program
Status Register (APSR) is accessed instead.)
Source: ARM Cortex-A Series Programmer's Guide for ARMv7-A. https://developer.arm.com/documentation/den0013/d/ARM-Processor-
Modes-and-Registers/Registers/Program-Status-Registers
112

Conditional Execution in ARM ISA
4 bit
סוטטסה רטסיגרב שומיש תושועש תוארוהה דודיקמ קלח םה COND -ה לש םיטיבה 4
113

Conditional Execution in ARM ISA
114

Conditional Execution in ARM ISA
ADD Always
יאנת אלל
in the CPSR
in the CPSR
Reference (Guy):
https://developer.arm.com/documentation/ddi0344/b/ch16s02s01 115

ADDAL – ADD Always regardless of the condition flag
ADDEQ (Add if Equal)
ADDNE (Add if Not Equal)
ADDGT (Add if Greater Than)
ADDVS (Add if Overflow Set)
ADDS – S suffux: this means that the instruction will update the condition
flags (N,Z,C,V) in the CPSR according to the result of the addition.
N – Negative
Z – Zero
C – Carry
V - Overflow
רטסיגר סוטטסה תא ןכדעמה דומ ןיבו ליגר דומ ןיב האוושה

Conditional Execution in ARM ISA
.אבה ףקשב דוקה
GCD = Greatest Common Divisor
The greatest common divisor (GCD) of integers a and b, at least one of which is nonzero, is the
greatest positive integer d such that d is a divisor of both a and b; that is, there are integers e and f
117
such that a = de and b = df, and d is the largest such integer. The GCD of a and b is generally
denoted gcd(a, b).[8]

Conditional Execution in ARM ISA
תיטמוטוא תוליעפמ האוושה תולועפ
conditional bits-ה תא
118

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
of both possible paths) (multipath execution)
119

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
 Global branch correlation  Two-level global predictor
 Local branch correlation  Two-level local predictor
 Hybrid branch predictors
 Predicated execution
 Multi-path execution – הרצקב דואמ
 Return address stack & Indirect branch prediction
131

וז תגצמ ןאכ דע