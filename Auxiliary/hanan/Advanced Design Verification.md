VHDL
Design Advanced Verification
©Hanan Ribo
1

Design Flow
Verification
Validation
©Hanan Ribo 2

Test-bench-based Verification
Let's focus on this part
©Hanan Ribo 3

Test-bench-based Verification
Let's focus on this part
©Hanan Ribo 4

VHDL
Assertions
©Hanan Ribo 5

Assert verses
• During simulation time, we can send messages to the “transcript” terminal
to detect special cases, such as illegal input combinations, overflow
detection, timing violations, etc.
• Syntax:
;
• Severity level definition:
There are five severity levels: note, warning, error, failure, fatal. The default least level
for simulation exiting is a Failure (changeable).
©Hanan Ribo 6

Pre-Defined Data Types – Simulation only
• REAL data type: Real numbers ranging from -1.0E38 to +1.0E38.
Using real data types in VHDL
• Physical literals: Used to inform physical quantities, like time, voltage,
etc. Useful in simulations.
Using physical data types in VHDL
• Character and String data types:
©Hanan Ribo 7

Three possible locations for Assert verse
There are three possible locations for Assert verse:
• Concurrent assertion:
✓ Location: On its own, inside a ARCHITECTURE.
✓ Activation: on boolean_condition event from true to false.
• Sequential assertion:
✓ Location: inside PROCESS, FUNCTION or PRECEDURE.
✓ Activation: when boolean_condition is false.
• Inside ENTITY assertion:
✓ Location: inside an Entity after begin (called passive part).
✓ Activation: when boolean_condition is false.
©Hanan Ribo 8

Concurrent assertion – SR Latch Example
Memory=previous state (there are two possible different stable states)
Only a single stable state
Invalid input, causes a race condition when the input changes at the same time
from s=r=‘1’ to s=r=‘0’ (there are two possible different stable states)
©Hanan Ribo 9

Concurrent assertion – SR Latch Example
To detect illegal s=r=‘1’ input combination, we use assert verse in point-wise.
Invalid input
©Hanan Ribo 10

Sequential assertion – SR Latch Example
Invalid input
©Hanan Ribo 11

Sequential assertion – SR Latch Example
Invalid input
©Hanan Ribo 12

Inside ENTITY assertion – SR Latch Example
Invalid input
©Hanan Ribo 13

String conversion-based on Assert verse
To use assert verses containing dynamic values, we can use two options:
• For scalar values (1D) – use image attribute:
• For any dimension value use to_sring() function:
©Hanan Ribo 14

String conversion-based Assert verse
Solution – using VARIABLES of type STD_LOGIC_VECTOR
©Hanan Ribo 15

Carry Ripple Adder
Set VARIABLES value
Intermediate calculations
using those VARIABLES
SIGNALS assignments
using those VARIABLES
©Hanan Ribo 16

to_sring() based Assert verse
Even though we can't
simulate VARIABLE
values, we track them
using Assert.
©Hanan Ribo 17

Function to_sring() – VHDL 2008
• enhancements in VHDL-2008
• Set the VHDL-2008 properties in ModelSim for to_sring() using.
©Hanan Ribo 18

to_sring() assertion
©Hanan Ribo 19

Alias Verses
• In order to simplify our code objects (SIGNAL, CONSTANT, VARIABLE) we
can give them an alias.
• Syntax:
• Examples:
Alias of Constants
defined is work
PACKAGE
©Hanan Ribo 20

Simulator ’s
Breakpoint
and Single-Step
©Hanan Ribo 21

Reminder - Simulation and Delta cycles
• Phase 1: the compiler reads the whole code for
signals initialization.
• Phase 2: the compiler waits for at least a SIGNAL
event from PROCESSES sensitive list or from
concurrent statements (called implied PROCESS).
• Phase 3: when SIGNAL event has happened, the
compiler makes for each stimulated PROCESS a
sequential list of buffers for the consecutive SIGNALS
assignments. At line END PROCESS all those
assignments are performed in parallel (causes inner
loops – Delta cycles).
• Phase 4: advance time (causes outer loops – Simulation
cycles)
©Hanan Ribo 22

Using Break-Point and Single Step
Phases:
1) Start simulation (use )
2) Choose signals and open Wave window
3) Open the required *.vhd file (use open icon ) and set the break points
you need
4) Run the simulation
5) Use single steps buttons and explore the results
6) Use restart if needed, back to step 4
©Hanan Ribo 23

Break-Point and Single Step - SR Latch Example
Phase 3 – set a Break-point
Phase 4 – Run the simulation, a blue arrow get Break-Point. From here use single steps.
©Hanan Ribo 24

Break-Point and Single Step - SR Latch Example
Partial results after running simulation till
150ns, using single steps
©Hanan Ribo 25

Testbench
Signal Generators
©Hanan Ribo 26

Simulation Generators – Using wait verses
• WAIT UNTIL:
✓ Syntax:
✓ The WAIT UNTIL statement accepts only one signal
✓ The PROCESS holds until the condition exists.
• WAIT ON:
✓ Syntax:
✓ The WAIT ON, accepts multiple signals.
✓ The PROCESS holds until any of the signals listed changes (on EVENT occurrence).
• WAIT FOR:
✓ Syntax:
✓ The PROCESS holds until the 5ns elapsed.
• Pure WAIT:
Stops the PROCESS forever.
©Hanan Ribo 27

WAIT ON and WAIT UNTIL combination
Uses as sensitivity list AND Condition on a single SIGNAL
This means that the PROCESS holds till the boolean_condition is true
AND at least one signal event occurs
Example:
©Hanan Ribo 28

WAIT UNTIL and WAIT FOR combination
Condition on a single SIGNAL OR Delay time value
This means that the PROCESS holds till the boolean_condition is true
OR the delay time elapsed
Example:
Stop the process until the condition holds for 5µs elapsed.
©Hanan Ribo 29

WAIT ON, WAIT UNTIL and WAIT FOR combination
Uses as sensitivity list AND Condition on a single SIGNAL OR Delay time value
Reminder: the precedence order is AND then OR
This means that the PROCESS holds till the boolean_condition is true
AND at least one signal event occurs OR the delay time elapsed
Example:
©Hanan Ribo 30

Simulation Generators - Periodic Signal
©Hanan Ribo 31

Simulation Generators - Non-Periodic Signal
©Hanan Ribo 32

Simulation Generators – Finite Periodic Signal
©Hanan Ribo 33

Simulation Generators – frequency sweep Signal
©Hanan Ribo 34

Simulation Generators – dirty periodic Signal
Dirty period
©Hanan Ribo 35

A simple UART TX generator
©Hanan Ribo 36

A simple UART TX generator
©Hanan Ribo 37

A simple UART TX generator
idle idle
| Data(0) | Data(1) | Data(2) | Data(3) |
| ------- | ------- | ------- | ------- |
©Hanan Ribo
38

Delay-Based Verification
( )
enrichment material
©Hanan Ribo 39

Delay-Based Simulation
• In case our design requires delay-based simulation, we can use the built-in
delay mechanism of VHDL.
• TDC (Time to Digital Converter) Example:
✓ The START signal is propagated through a delay line, on the arrival of the STOP signal,
the propagated START signal is latched. This directly gives a thermometer time code
(Unary Code).
✓ The number of stages flipped to one gives the timing information.
✓ The resolution of the TDC is given by the buffer or inverter propagation time τ .
©Hanan Ribo 40

Carrychain based TDC
• The line length N can be calculated with:
| 𝑻   |     | 𝟏   |
| --- | --- | --- |
𝑺𝑻𝑶𝑷
| 𝑵 ≥ =      |     |              |
| ---------- | --- | ------------ |
| 𝒓𝒆𝒔𝒐𝒍𝒖𝒕𝒊𝒐𝒏 | 𝒇   | ∙ 𝒓𝒆𝒔𝒐𝒍𝒖𝒕𝒊𝒐𝒏 |
𝑺𝑻𝑶𝑷
     Where, resolution is the carry propagation delay and N is the number of the carry units.
• In the case of a 200 MHz clock frequency acting as STOP signal and a resolution of 20 ps,
the line length is 250 carries.
©Hanan Ribo
41

VHDL Delay Models
• The delay mechanism allows introducing propagation times of described systems.
• Delay mechanisms can be applied to signals assignment only (It is not allowed to
specify delays in variable assignments).
• Delays are not synthesizable (simulation only).
• There are two delay mechanism available in VHDL:
✓ Inertial delay
✓ Transport delay
©Hanan Ribo 42

Inertial Delay
• Default delay type
• Allows for user specified delay
• Absorbs pulses of shorter duration than the specified delay
Absorbed pulse
©Hanan Ribo 43

Transport Delay
• Must be explicitly specified by user (using the reserved word transport)
• Allows for user specified delay
• Passes all input transitions with delay
The signal is propagated through the line
©Hanan Ribo 44

Ripple Adder tpd – delay based simulation
©Hanan Ribo 45

Ripple Adder tpd – delay based simulation
In synthesis case
In simulation case.
Synthesis and tpd are constants
defined in a PACKAGE
(enhancements in VHDL-2008)
©Hanan Ribo 46

Ripple Adder tpd – delay based simulation
• Synthesis result (the whole design is kept synthesizable):
• Simulation result:
©Hanan Ribo 47

Ripple Adder tpd – delay-based simulation
©Hanan Ribo 48