VHDL - Sequential Code
(PROCESS elements)
©Hanan Ribo

1

Introduction

• VHDL code can be concurrent (combinational logic) or sequential

(sequential logic).

• Combinational logic - definition:

The output is a pure function of the present input only (implemented by
Boolean circuits, using conventional logic gates only – no memory, no
feedback).
Intuitively, the circuit information flows in parallel.

•

©Hanan Ribo

2

Introduction

• Sequential logic - definition:

The output does depend on present inputs and previous inputs
(implemented using storage, flip-flops elements, which are connected to
the combinational logic block through a feedback loop).
Intuitively, the circuit information flows in serial triggered by clk signal.

•

©Hanan Ribo

3

Introduction

• Note: not any circuit that possesses storage elements is sequential.
• Example: RAM memory.

The storage elements appear in a forward path rather than in a feedback
loop. The memory-read operation depends only on the present address
vector input (with nothing to do with previous memory accesses).

©Hanan Ribo

4

Introduction

• There are four types of ARCHITECTURE Modeling styles:

 Dataflow modeling = Concurrent Code

 Structural modeling = Concurrent Code

 Behavioral modeling = Sequential Code

 Mixed modeling = Concurrent Code

©Hanan Ribo

5

Sequential (behavioral) Code
• VHDL code is inherently concurrent but there are three sequential design
units PROCESSES, FUNCTIONS and PROCEDURES are the only sections of
code that are executed sequentially. However, as a whole, any of these
blocks is still concurrent with any other statements placed outside it.

• One important aspect of sequential code is that it is not limited to sequential
logic. Indeed, with it we can build sequential circuits as well as combinational
circuits (but not mixed together, which called Mixed PROCESS).

• Sequential statements are allowed only inside PROCESSES, FUNCTIONS, or
PROCEDURES as concurrent statements are allowed only outside of them.

• In this section we will concentrate on PROCESSES only. The design units

FUNCTIONS and PROCEDURES are very similar, but are intended for system-
level design (will be discussed later).

©Hanan Ribo

6

PROCESS
• A PROCESS is a sequential section of VHDL code. It is placed only in the

ARCHITECTURE body (after BEGIN) and can contain the sequential
statements IF, WAIT, CASE, LOOP (in addition to signals assignment) and
use of VARIABLES.

• Syntax:

• The use of a label (improves code readability) and VARIABLES are optional.
• The VARIABLES initial value is not synthesizable (for simulation only).

©Hanan Ribo

7

• Syntax:

PROCESS

• A PROCESS is executed every time a signal in the sensitivity list changes (on an

EVENT occurrence) or the condition related to WAIT is fulfilled.

• PROCESS as a code element is performed as a single concurrent statement inside
ARCHITECTURE body, thus using of two PROCESS (or more) inside ARCHITECTURE
constitute using of  two (or more) concurrent statements.

©Hanan Ribo

8

Signals assignment inside PROCESS
• A PROCESS is a sequential section of VHDL code. It is placed only in the

ARCHITECTURE body (after BEGIN) and can contain the sequential
statements IF, WAIT, CASE, LOOP (in addition to signals assignment).

• Signals assignment:

• When SIGNAL is used in a PROCESS, its new value is generally only
guaranteed to be available after the conclusion (different between
combinatorial or sequential PROCESS) of the present run of the PROCESS.

• In case of multiple assignments to the same SIGNAL, only the last

assignment is taken into consideration by the compiler, the rest are ignored
(differ from the case of concurrent code – multiple driven).

©Hanan Ribo

9

Sequential statement  IF-THEN

Syntax:

Notes:
• When the command contains conflicting terms, the first of them will be executed
• Multiple separate IF-THEN statement contains assignment to the same SIGNAL

must be avoided (causes sick hardware).

©Hanan Ribo

10

Sequential statement  IF-THEN

• Example:

• Example – Sick Hardware:

©Hanan Ribo

11

Sequential statement  CASE

Syntax:

Example:

©Hanan Ribo

12

CASE (sequential) vs WHEN (concurrent)
• For both of them all permutations must be tested, so the keyword OTHERS is
often helpful (differ from IF-THEN statement). This means that both will be
synthesized mux based.

• Another important keyword is NULL for CASE (for WHEN is UNAFFECTED),

which should be used when no action is to take place.

©Hanan Ribo

13

Sequential statements  LOOP, FOR ,WHILE
• As the name says, LOOP kinds is useful when a piece of code must be
instantiated several times (the compiler unfold the inner body loop
statements statically), can only be used inside a PROCESS, FUNCTION, or
PROCEDURE.
• FOR / LOOP:
 The loop is repeated a fixed number of times, the loop limits of the range must be

static (0 TO 5  or 5 DOWNTO 0).

 Using of label is optional.

©Hanan Ribo

14

Sequential statements  LOOP, FOR ,WHILE

• WHILE / LOOP:
 The loop is repeated until a condition no longer holds.
 Using of label is optional.

©Hanan Ribo

15

Sequential statements  LOOP, FOR ,WHILE

• EXIT: Used for ending the loop.

 Syntax:
 Example:

• NEXT: Used for skipping loop steps.

 Syntax:
 Example:

©Hanan Ribo

16

Sequential statements  LOOP, FOR ,WHILE

• LOOP:
 The loop is repeated forever until a  EXIT condition holds.
 Using of label is optional.

©Hanan Ribo

17

Sequential statement WAIT (for simulation generally)
• When WAIT is employed the PROCESS cannot have a sensitivity list.
• There are two synthesizable forms of WAIT (WAIT UNTIL and WAIT ON).
• WAIT UNTIL:
 Syntax:

 The WAIT UNTIL statement accepts only one signal (thus being more

appropriate for synchronous code).

 Since the PROCESS has no sensitivity list in this case, WAIT UNTIL must

be  the first statement in the PROCESS instead.

©Hanan Ribo

18

Sequential statement WAIT (for simulation generally)
• WAIT ON:
 Syntax:

 The WAIT ON, accepts multiple signals.
 Since the PROCESS has no sensitivity list in this case, WAIT ON must be

the first statement in the PROCESS instead.

 The PROCESS is put on hold until any of the signals listed changes (on

EVENT occurrence).

©Hanan Ribo

19

Sequential statement WAIT (for simulation generally)

• Examples:

©Hanan Ribo

20

WAIT FOR <time_expression> - simulation only
• WAIT FOR is intended for simulation only (intended for waveform generation

for testbenches).

• Examples:
 Stop the process until the 5ns elapsed.

 Can be combined: Stop the process until the condition holds for 5µs elapsed.

©Hanan Ribo

21

Signals and Variables

• A SIGNAL can be declared in a PACKAGE, ENTITY or ARCHITECTURE (in its
declarative part), while a VARIABLE can only be declared inside a piece of
sequential code (in a PROCESS, FUNCTION, PROCEDURE). Therefore, while the
value of SIGNAL can be global, the value of VARIABLE is always local.

• VHDL has two ways of passing non-static values, by means of a SIGNAL or a

VARIABLE. The value of a VARIABLE can never be passed out of the PROCESS
directly, if necessary, then it must be assigned to a SIGNAL.

• The update of a VARIABLE is immediate (we can promptly count on its new value
in the next line of code). When SIGNAL is used in a PROCESS, its new value is
generally only guaranteed to be available after the conclusion of the present run
of the PROCESS.

©Hanan Ribo

22

VARIABLE
• Contrary to CONSTANT and SIGNAL, a VARIABLE represents only local

information. It can only be used inside a PROCESS, FUNCTION, or
PROCEDURE (its declaration can only be done in the declarative part), and
its value can not be passed out directly.

• VARIABLE update is immediate, so the new value can be promptly used in
the next line of code (When SIGNAL is used in a PROCESS, its new value is
generally only guaranteed to be available after the conclusion of the
present run of the PROCESS).

• VARIABLE is a local element, its main purpose is for Intermediate

calculations (for simulation. Vanished in synthesis - uses as a “glue”
between SIGNALS, that is wires) inside PROCESS.

• We can not track VARIABLE in simulation.

©Hanan Ribo

23

• VARIABLE declaration (inside the PROCESS's declarative part):

VARIABLE

like in the case of a SIGNAL, the initial value of VARIABLE is not
synthesizable, being only considered in simulation.

• VARIABLE use (inside the PROCESS's body):

©Hanan Ribo

24

Rule of using VARIABLES in PROCESS
• Do not use SIGNALS for intermediate calculations, use only VARIABLES for

that purpose.

• The Rule - Separate the PROCESS into three sub parts:

 Upper part:

Set VARIABLES value (from constants or SIGNALS).

 Middle part:

Intermediate calculations using those VARIABLES.

 Lower part:

SIGNALS assignments using those VARIABLES.

©Hanan Ribo

25

Comparison between SIGNAL and VARIABLE

©Hanan Ribo

26

Carry Ripple Adder – Behavioral modeling

• Solution 1 – using VARIABLES of type STD_LOGIC_VECTOR
• Solution 2 – using VARIABLES of type INTEGER

©Hanan Ribo

27

Carry Ripple Adder – solution 1

Set VARIABLES value

Intermediate calculations
using those VARIABLES

SIGNALS assignments
using those VARIABLES

©Hanan Ribo

28

Carry Ripple Adder – solution 2

Set VARIABLES value

Intermediate
calculations using
those VARIABLES

SIGNALS assignments
using those VARIABLES
©Hanan Ribo

29

Carry Ripple Adder – Simulation Results

• Given: the sum of a and b solely, is equal to 0xFF
•
•

For cin=1, the 9-bit output [s=0x00, cout=1] equal to 256
For cin=0, the 9-bit output [s=0xFF, cout=0] equal to 255

©Hanan Ribo

30

