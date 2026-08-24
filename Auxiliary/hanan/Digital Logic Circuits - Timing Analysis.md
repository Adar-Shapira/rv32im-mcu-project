Digital Logic Circuits
Timing Analysis
©Hanan Ribo
1

Combinational Circuits
Timing Analysis
2

Logic Gates Timing
𝑡 : Time from state change at input to state change at output
𝑝𝑑
In
Out
t
t
t
pd
©Hanan Ribo 3

CMOS NOT Gate VTC (Voltage Transfer Curve)
𝑪 𝑳
𝑪
𝑳
| 𝐶 = 𝐶 | +   | 𝐶    | + 𝑁 | ∙ 𝐶 |
| ----- | --- | ---- | --- | --- |
| 𝐿     | 𝑜𝑢𝑡 | 𝑙𝑖𝑛𝑒 |     | 𝑖𝑛  |
𝐶  - parasitic capacitance due to transistors
𝑜𝑢𝑡
configuration between output and GND
𝐶  - parasitic capacitance due to lines
𝑙𝑖𝑛𝑒
connection
| 𝑁 ∙ 𝐶 | - input capacitance of N gates at the next rank only  |     |     |     |
| ----- | ----------------------------------------------------- | --- | --- | --- |
𝑖𝑛
(CMOS), connected to its output (affects the Fanout)
| 𝑡 = | 𝑓 𝐶  , | 𝑇 ℃ | , 𝑉 |     |
| --- | ------ | --- | --- | --- |
| 𝑝𝑑  | 𝐿      |     | 𝐶𝐶  |     |
©Hanan Ribo
4

Digital Logic Abstraction
The noise margins overcome the noise that is added to the
signal in the transition from one component to another
©Hanan Ribo 5

CMOS Timing Specifications
6

Propagation delay (𝑡 ):
𝑃𝐷
7

Contamination Delay
8

Combinational Example
9

Static Discipline Obedience
• Definition: guarantee on logical elements that "if inputs meet valid input
thresholds, then the system guarantees outputs will meet valid output
thresholds", named by Stephen A. Ward and Robert H. Halstead in 1990.
• Implication: Output guaranteed to be valid when all inputs have been valid for
at least 𝑡 , and, outputs may become invalid no earlier than 𝑡 after an
𝑃𝐷 𝐶𝐷
input changes!
©Hanan Ribo 10

Cascaded gates delay
in out
| 𝑡 = | 𝑡   | + 𝑡 +𝑡  |
| --- | --- | ------- |
| 𝑝𝑑  | 𝑝𝑑1 | 𝑝𝑑2 𝑝𝑑3 |
©Hanan Ribo
11

Fan-out delay
• The delay of a gate is proportional to its output capacitance. Connecting the
output of a gate to more than one other gate increases its output capacitance.
• Driving wires also contribute to fan-out delay.
©Hanan Ribo 12

Synchronous Circuits
Timing Analysis
©Hanan Ribo 13

NOR based SR Latch
1-bit Memory=previous state (there are two possible different stable states)
Only a single stable state
Invalid input causes a race condition when the input changes at the same time
from s=r=‘1’ to s=r=‘0’ (there are two possible different stable states)
©Hanan Ribo 14

NAND based SR Latch
Invalid input causes a race condition when the input changes at the same time
from s=r=‘0’ to s=r=‘1’ (there are two possible different stable states)
Only a single stable state
1-bit Memory=previous state (there are two possible different stable states)
©Hanan Ribo 15

Gated D-Latch
To eliminate the race condition (to achieve zero probability) in the SR-Latch,
we need to modify it to a Gated D-Latch.
Output
| E=Enable | D=Data | Q Qbar |
| -------- | ------ | ------ |
1-bit Memory=previous state
| 0   | x=don’t care | Q Qbar |
| --- | ------------ | ------ |
| 1   | 0            | 0 1    |
Write operation
| 1   | 1   | 1 0 |
| --- | --- | --- |
Symbol for a gated D latch
A gated D-latch based on an SR-latch NOR-based A gated D-latch based on an SR- latch NAND-based
©Hanan Ribo
16

D Flip-Flop = DFF
To sample the input data at a single point in time (positive or negative edge
trigger), we need to use a rising/falling derivator structure.
clk
=
Rising edge trigger
Negative edge DFF
Symbol for a DFF
clk
=
Falling edge trigger
Positive edge DFF
©Hanan Ribo 17

Dynamic Discipline Obedience
The output of each combinational logic path between two registers must be
steady before each clock’s transition (rising / falling edge).
©Hanan Ribo 18

Synchronous Data Movement
A single flip-flop is used on each cycle boundary. Data advances from one
cycle to the next on each clock rising edge.
©Hanan Ribo 19

Reminder - Combinational timing analysis
©Hanan Ribo 20

DFF timing analysis
Aperture time (D must not change in this region) = 𝑡 +𝑡
𝑠𝑢 ℎ𝑜𝑙𝑑
𝐷 𝑚𝑢𝑠𝑡 𝑏𝑒 𝑠𝑡𝑎𝑏𝑙𝑒 𝑡  𝑡𝑖𝑚𝑒
𝐷 𝑚𝑢𝑠𝑡 𝑏𝑒 𝑠𝑡𝑎𝑏𝑙𝑒 𝑡  𝑡𝑖𝑚𝑒
𝑠𝑢 ℎ𝑜𝑙𝑑
 𝒃𝒆𝒇𝒐𝒓𝒆 𝑟𝑖𝑠𝑖𝑛𝑔 𝑒𝑑𝑔𝑒  𝒂𝒇𝒕𝒆𝒓 𝑟𝑖𝑠𝑖𝑛𝑔 𝑒𝑑𝑔𝑒 to avoid race condition
at the 2nd Latch
𝑓𝑟𝑜𝑚 𝑟𝑖𝑠𝑖𝑛𝑔 𝑡𝑖𝑙𝑙 𝑠𝑡𝑎𝑏𝑙𝑒 𝑄 is 𝑡  = 𝑡
𝑐𝑞 𝑝𝑑(𝐹𝐹)
Symbol for a DFF
𝑡
𝑡
𝑠𝑢 𝑐𝑞
𝑓
𝑚𝑎𝑥
𝐻𝑊 𝑟𝑒𝑞𝑢𝑖𝑟𝑒𝑚𝑒𝑛𝑡:
|                   | 𝑡 < | 𝑡 <  | 𝑡   | < 𝑡 |
| ----------------- | --- | ---- | --- | --- |
|                   | 𝑠𝑢  | ℎ𝑜𝑙𝑑 | 𝑐𝑑  | 𝑐𝑞  |
|                   | 𝑇   | = 𝑡  | +   | 𝑡   |
|                   |     | 𝑚𝑖𝑛  | 𝑐𝑞  | 𝑠𝑢  |
| Positive edge DFF |     | 1    |     | 1   |
|                   | 𝑓   | =    | =   |     |
𝑚𝑎𝑥
|     |     | 𝑇   | 𝑡   | + 𝑡 |
| --- | --- | --- | --- | --- |
| clk |     | 𝑚𝑖𝑛 | 𝑐𝑞  | 𝑠𝑢  |
21
©Hanan Ribo

DFF Timing recap
• 𝑡 = 𝑡 : time after clock change that the output is guaranteed to be
𝑐𝑞 𝑝𝑑(𝐹𝐹)
stable (propagation delay).
• 𝑡 : time before clock edge, data must be stable (Setup time)
𝑠𝑢
• 𝑡 : time after clock edge data must be stable (Hold time)
ℎ𝑜𝑙𝑑
• 𝑡 = 𝑡 +𝑡 : time around clock edge data must be stable (Aperture time)
𝑎 𝑠𝑢 ℎ𝑜𝑙𝑑
• 𝑡 : time after clock edge that Q is stable by the previous value
𝑐𝑑
(Contamination delay)
©Hanan Ribo 22

Performance
Measurement
©Hanan Ribo 23

Components of Path Delay
Propagation delay 𝑡 factors:
𝑝𝑑
1. # of levels of logic
2. Internal cell delay
3. Wire delay
4. Cell input capacitance
5. Cell fan-out
6. Cell output drive strength
©Hanan Ribo 24

|     | Timing Delay Constraints of 𝑡 |     |     |     |     |     |     |     |     |     |  and 𝑡 |     |     |
| --- | ----------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- |
𝑠𝑒𝑡𝑢𝑝 ℎ𝑜𝑙𝑑
𝐼𝑛𝑝𝑢𝑡 𝑂𝑢𝑡𝑝𝑢𝑡
𝑇
𝑐𝑙𝑘
|     |     |     |     |     |     |     |     |     | 𝑡   | (=  | )   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
𝑠𝑢
|     |     |     |     | (= 𝑡 | )   |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
𝑝𝑑
𝐹𝐹1
| FF1 output |     |     | 𝑡   |     |     |     |     |     |     |     |     |     |     |
| ---------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
𝑐𝑑𝐹𝐹
1
𝑡
𝑐𝑑𝐶𝐿
FF2 input
𝑡
ℎ𝑜𝑙𝑑
Same value
|     |     | 𝑎𝑠𝑠𝑜𝑐𝑖𝑎𝑡𝑒𝑑 𝑤𝑖𝑡ℎ 𝑐𝑦𝑐𝑙𝑒 𝑛  |     |     |     |     |     | 𝑎𝑠𝑠𝑜𝑐𝑖𝑎𝑡𝑒𝑑 𝑤𝑖𝑡ℎ 𝑐𝑦𝑐𝑙𝑒 𝑛 |     |     |     | + 1  |     |
| --- | --- | ------------------------ | --- | --- | --- | --- | --- | ----------------------- | --- | --- | --- | ---- | --- |
𝑠𝑒𝑡𝑢𝑝 𝑠𝑙𝑎𝑐𝑘
|     |     | 𝑇 ≥ |  𝑡  | + 𝑡 | +   | 𝑡   |    ,   𝑡 |     | <   | 𝑡   | + 𝑡 |     |     |
| --- | --- | --- | --- | --- | --- | --- | -------- | --- | --- | --- | --- | --- | --- |
ℎ𝑜𝑙𝑑 𝑠𝑙𝑎𝑐𝑘
|     |     | 𝑐𝑙𝑘 | 𝑝𝑑  | 𝑝𝑑  |     | 𝑠𝑢  |     | ℎ𝑜𝑙𝑑 |     | 𝑐𝑑 𝐹𝐹1 |     | 𝑐𝑑 𝐶𝐿 |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | ------ | --- | ----- | --- |
|     |     |     | 𝐹𝐹1 |     | 𝐶𝐿  | 𝐹𝐹2 |     |      | 𝐹𝐹2 |        |     |       |     |
𝑇
| 𝑐𝑙𝑘𝑚𝑖𝑛𝑖𝑚𝑢𝑚 |     |     |     |     |     | ©Hanan Ribo |     |     |     |     |     |     | 25  |
| ---------- | --- | --- | --- | --- | --- | ----------- | --- | --- | --- | --- | --- | --- | --- |

High Level System Description
• The most common mistake is to start HDL coding before describing the
required digital system in high-level RTL form.
• In the RTL system description, it becomes clear what the system’s
combinational and synchronous subunits are.
• Any digital logic system can be disassembled to Combinational Logic blocks
chained to FFs (registers).
©Hanan Ribo 26

Critical Path
• Critical Path: the path in the entire design with the maximum delay.
• This could be from state element to state element, from input to state element, state
element to output, from input to output (unregistered paths).
• Example: what is the critical path in this circuit?
©Hanan Ribo 27

RTL design - example
Question:
Where given that each logic
| cell has 𝑡 = | 1𝑛𝑠, what is  |     |     |
| ------------ | ------------- | --- | --- |
𝑝𝑑
the critical path 𝑡 ?
𝑝𝑑
Answer:
| 𝑐𝑟𝑖𝑡𝑖𝑐𝑎𝑙 𝑝𝑎𝑡ℎ 𝑡 | = max | 𝑡     |     |
| --------------- | ----- | ----- | --- |
|                 | 𝑝𝑑    | 𝑝𝑑(𝐶𝐿 | )   |
𝑖
𝑖
| 𝑐𝑟𝑖𝑡𝑖𝑐𝑎𝑙 𝑝𝑎𝑡ℎ 𝑡 | = 3𝑛𝑠 |     |     |
| --------------- | ----- | --- | --- |
𝑝𝑑
©Hanan Ribo
28

𝑓  𝑐𝑎𝑙𝑐𝑢𝑙𝑎𝑡𝑖𝑜𝑛 – dynamic discipline Obedience
𝑚𝑎𝑥
1. Notations:
| • Each 𝐶𝐿 |  has its own 𝑡 |     |       |     |     |     |     |     |     |     |     |     |     |     |     |
| --------- | -------------- | --- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|           | 𝑖              |     | 𝑝𝑑(𝐶𝐿 | )   |     |     |     |     |     |     |     |     |     |     |     |
𝑖
• We assume same technology for all FFs, means same 𝑡 (= 𝑡 ), 𝑡 , 𝑡 , 𝑡
|     |     |     |     |     |     |     |     |     |     |     | 𝑐𝑞  | 𝑝𝑑  |     | 𝑐𝑑 𝑠𝑢 | ℎ𝑜𝑙𝑑 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | ---- |
𝐹𝐹
2. Timing condition between the path from FF1 to FF2:
| • FF2 setup condition:  𝑡   |     |     |         | +   | 𝑡       |     | +   | 𝑡         |     | ≤   | 𝑇   |     |     |     |     |
| --------------------------- | --- | --- | ------- | --- | ------- | --- | --- | --------- | --- | --- | --- | --- | --- | --- | --- |
|                             |     |     | 𝑐𝑞(𝐹𝐹1) |     | 𝑝𝑑(𝐶𝐿1) |     |     | 𝑠𝑢(𝐹𝐹2)   |     |     | 𝑐𝑙𝑘 |     |     |     |     |
| • FF2 hold condition:    𝑡  |     |     |         | +   | 𝑡       |     | ≥   | 𝑡         |     |     |     |     |     |     |     |
|                             |     |     | 𝑐𝑑(𝐹𝐹1) |     | 𝑐𝑑(𝐶𝐿1) |     |     | ℎ𝑜𝑙𝑑(𝐹𝐹2) |     |     |     |     |     |     |     |
| 3. General expression for 𝑓 |     |     |         | :   |         |     |     |           |     |     |     |     |     |     |     |
The Critical Path, we strive in our design for balanced CL paths
𝑚𝑎𝑥
1
| • Setup condition: 𝑡 |     |     | + max | 𝑡     |     | +   | 𝑡   | =   | 𝑇   |   → |   𝑓 | =   |     |     |     |
| -------------------- | --- | --- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|                      |     | 𝑐𝑞  |       | 𝑝𝑑(𝐶𝐿 |     | )   | 𝑠𝑢  |     | 𝑚𝑖𝑛 |     | 𝑚𝑎𝑥 |     |     |     |     |
|                      |     |     | 𝑖     |       | 𝑖   |     |     |     |     |     |     |     | 𝑇   |     |     |
𝑚𝑖𝑛
| • Hold condition:   𝑡 |     |     | + min | 𝑡     |     | ≥   | 𝑡    |     |     |     |     |     |     |     |     |
| --------------------- | --- | --- | ----- | ----- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- |
|                       |     | 𝑐𝑑  |       | 𝑐𝑑(𝐶𝐿 | )   |     | ℎ𝑜𝑙𝑑 |     |     |     |     |     |     |     |     |
𝑖
𝑖
©Hanan Ribo
29

|     |     | 𝑓   |  𝑐𝑎𝑙𝑐𝑢𝑙𝑎𝑡𝑖𝑜𝑛  |     |     | −  𝑒𝑥𝑎𝑚𝑝𝑙𝑒 1 |     |     |
| --- | --- | --- | ------------- | --- | --- | ------------ | --- | --- |
𝑚𝑎𝑥
The given data:
𝑡 = 200𝑝𝑠
𝑠𝑢
𝑡 = 300𝑝𝑠
𝑐𝑞
| 𝑡 = | 100𝑝𝑠 |     |     |     |     |     |     |     |
| --- | ----- | --- | --- | --- | --- | --- | --- | --- |
𝑝𝑑
𝑔𝑎𝑡𝑒
Critical Path
1
| 𝑇   | = 𝑡 | +2 ∙ | 𝑡    | + 𝑡 | = 700𝑝𝑠  | →   𝑓 | =   | = 1.428GHz |
| --- | --- | ---- | ---- | --- | -------- | ----- | --- | ---------- |
| 𝑚𝑖𝑛 | 𝑐𝑞  |      | 𝑝𝑑   | 𝑠𝑢  |          | 𝑚𝑎𝑥   |     |            |
|     |     |      | 𝑔𝑎𝑡𝑒 |     |          |       | 𝑇   |            |
𝑚𝑖𝑛
©Hanan Ribo
30

|     |     |     |     |     | 𝑓   |     |     |  𝑐𝑎𝑙𝑐𝑢𝑙𝑎𝑡𝑖𝑜𝑛  |     |     |     |     |     |     | −   |  𝑒𝑥𝑎𝑚𝑝𝑙𝑒 2 |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | ------------- | --- | --- | --- | --- | --- | --- | --- | ---------- | --- | --- | --- | --- | --- | --- |
𝑚𝑎𝑥
1. FF intrinsic delays:
| 𝑡   |     | =      | 1𝑛𝑠, | 𝑡    |     | =   | 3𝑛𝑠, |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | ------ | ---- | ---- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 𝑐𝑑  |     |        |      |      | 𝑝𝑑  |     |      |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     | 𝐹𝐹  |        |      |      | 𝐹𝐹  |     |      |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|  𝑡  |     | = 2𝑛𝑠, |      | 𝑡    |     |     | =    | 2𝑛𝑠 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| 𝑠𝑢  |     |        |      | ℎ𝑜𝑙𝑑 |     |     |      |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     | 𝐹𝐹  |        |      |      |     | 𝐹𝐹  |      |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
2. CL delays:
(=CL)
|  𝑡  |     | =?  | , 𝑡 |     | =   | 5𝑛𝑠 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 𝑐𝑑  |     |     | 𝑝𝑑  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
|     | 𝐶𝐿  |     |     | 𝐶𝐿  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
Questions:
| 1.  | What is the constraint for the 𝑡 |     |     |     |     |     |     |     |     |     |     |  ?  |     |     |     |     |     |     |     |     |     |     |
| --- | -------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
cd
CL
| 2.  | What is the circuit 𝑓 |     |     |     |     |     |     |     | ?   |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --------------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
max
| 3.  | In case 𝑡 |     |     |     | =   | 2𝑛𝑠 what is the slack value of 𝑡 |     |     |     |     |     |     |     |     |      |     |  ?  |     |     |     |     |     |
| --- | --------- | --- | --- | --- | --- | -------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- |
|     |           |     | 𝑐𝑑  |     |     |                                  |     |     |     |     |     |     |     |     | ℎ𝑜𝑙𝑑 |     |     |     |     |     |     |     |
𝐶𝐿
Answers:
| 1.  | The constraint: 𝑡 |     |     |     |     |      |     | ≤   | 𝑡   | +   | 𝑡   |     |   → | 2𝑛𝑠 | ≤   | 1𝑛𝑠 | +   | 𝑡   |     | → 𝑡 |     | ≥ 1𝑛𝑠 |
| --- | ----------------- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- |
|     |                   |     |     |     |     | ℎ𝑜𝑙𝑑 |     |     | 𝑐𝑑  |     | 𝑐𝑑  |     |     |     |     |     |     | 𝑐𝑑  |     |     | 𝑐𝑑  |       |
|     |                   |     |     |     |     |      |     |     | 𝐹𝐹  |     |     | 𝐶𝐿  |     |     |     |     |     |     | 𝐶𝐿  |     | 𝐶𝐿  |       |
1
| 2.  | 𝑇   | ≥   | 𝑡   |     | +   | 𝑡   |     | +   | 𝑡   | =   | 10𝑛𝑠  |     | →   | 𝑓   |     | =   | =   | 100𝑀𝐻𝑧 |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | --- | --- |
|     | 𝑐𝑙𝑘 |     | 𝑝𝑑  |     |     | 𝑝𝑑  |     |     | 𝑠𝑢  |     |       |     |     | 𝑚𝑎𝑥 |     |     |     |        |     |     |     |     |
|     |     |     |     | 𝐹𝐹  |     |     | 𝐶𝐿  |     | 𝐹𝐹  |     |       |     |     |     |     | 𝑇   |     |        |     |     |     |     |
𝑐𝑙𝑘
| 3.  | 𝑡    |     | ≤   | 𝑡   |     | +   | 𝑡   |     |   → |   𝑠𝑙𝑎𝑐𝑘 |     |      | =   | 𝑡   |     | +   | 𝑡   | −   | 𝑡    |     | =   | 1𝑛𝑠 |
| --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | ------- | --- | ---- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- |
|     | ℎ𝑜𝑙𝑑 |     |     |     | 𝑐𝑑  |     |     | 𝑐𝑑  |     |         |     | ℎ𝑜𝑙𝑑 |     |     | 𝑐𝑑  |     | 𝑐𝑑  |     | ℎ𝑜𝑙𝑑 |     |     |     |
|     |      | 𝐹𝐹  |     |     | 𝐹𝐹  |     |     | 𝐶𝐿  |     |         |     |      |     |     | 𝐹𝐹  |     | 𝐶𝐿  |     |      | 𝐹𝐹  |     |     |
©Hanan Ribo 31

Clock Skew
(Clock Uncertainty)
©Hanan Ribo 32

Wire Delay
• Signal wave-front moves close to the speed of
light ~1feet/ns (1 foot = 30.48cm)
• ICs’ most wires are short, and the transit times are
relatively short (can be ignored ) compared to the
clock period, except for clock lines (longer than
ICs’ most wires, the clock signals take time to
move from one location to another).
• Physically, the wires have resistance, capacitance,
and inductance (frequency-dependent), causing
clock skew (phase difference) between the
systems' FFs.
©Hanan Ribo 33

Clock Skew
Clock should theoretically arrive simultaneously at all sequential circuits. Practically, it
arrives at different times. The differences are called clock skews.
| 𝑡    | ≜ 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |         | − 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |        | = 𝐶𝐿𝐾2(𝑃𝐻𝐴𝑆𝐸) | − 𝐶𝐿𝐾1(𝑃𝐻𝐴𝑆𝐸) |
| ---- | ------------ | ------- | ------------ | ------ | ------------- | ------------- |
| 𝑠𝑘𝑒𝑤 |              | 𝑐𝑎𝑝𝑡𝑢𝑟𝑒 |              | 𝑙𝑎𝑢𝑛𝑐ℎ |               |               |
|      |              | 𝐹𝐹      |              | 𝐹𝐹     |               |               |
Clock skew consists of the following components:
• Systematic is the portion existing under nominal conditions. It can be minimized by an
appropriate design.
• Random is caused by process variations like devices’ channel length, oxide thickness,
threshold voltage, wire thickness, width, and space. It can be measured on silicon and
adjusted by delay components.
©Hanan Ribo 34

Positive Clock Skew
| 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |         | > 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |        |  →  𝑇 | > 0 |
| ---------- | ------- | ------------ | ------ | ----- | --- |
|            | 𝑐𝑎𝑝𝑡𝑢𝑟𝑒 |              | 𝑙𝑎𝑢𝑛𝑐ℎ | 𝑠𝑘𝑒𝑤  |     |
|            | 𝐹𝐹      |              |        | 𝐹𝐹    |     |
Explanation:
clk_src =  The clock arrives at the capture
FFs later than it does at the
launch FF. This effectively extends
the time available for the data
propagation, allowing a shorter
clock period (a higher frequency).
©Hanan Ribo
35

Positive Clock Skew
To guarantee that dynamic discipline is not violated for any register, we perform the worst-
case analysis.
𝑇
𝑐𝑙𝑘 𝑚𝑖𝑛𝑖𝑚𝑢𝑚
| 𝑐𝑙𝑘2 | 𝑝ℎ𝑎𝑠𝑒 |     |     | = 𝑐𝑙𝑘1 | 𝑝ℎ𝑎𝑠𝑒 |     | +   | 𝑡    |   →   | 𝑡    | > 0 |
| ---- | ----- | --- | --- | ------ | ----- | --- | --- | ---- | ----- | ---- | --- |
|      |       |     |     |        |       |     |     | 𝑠𝑘𝑒𝑤 |       | 𝑠𝑘𝑒𝑤 |     |
Timing constraint (FF1 to FF2):
| 1.  | 𝑇    | ≥   |  𝑡                               | +   | 𝑡   | +   | 𝑡   |      | − 𝑡  |   →                          | ℎ𝑖𝑔ℎ𝑒𝑟 𝑓𝑚𝑎𝑥 |
| --- | ---- | --- | -------------------------------- | --- | --- | --- | --- | ---- | ---- | ---------------------------- | ----------- |
|     | 𝑐𝑙𝑘  |     | 𝑝𝑑                               |     | 𝑝𝑑  |     | 𝑠𝑢  |      | 𝑠𝑘𝑒𝑤 |                              |             |
|     |      |     |                                  | 𝐹𝐹1 |     | 𝐶𝐿1 |     | 𝐹𝐹2  |      |                              |             |
| 2.  | 𝑡    |     | <                                | 𝑡   | +   | 𝑡   | −   | 𝑡    |   →  |  𝑟𝑒𝑑𝑢𝑐𝑒𝑑 ℎ𝑜𝑙𝑑 𝑚𝑎𝑟𝑔𝑖𝑛 (𝑠𝑙𝑎𝑐𝑘) |             |
|     | ℎ𝑜𝑙𝑑 |     |                                  | 𝑐𝑑  |     | 𝑝𝑑  |     | 𝑠𝑘𝑒𝑤 |      |                              |             |
|     |      | 𝐹𝐹2 |                                  | 𝐹𝐹1 |     | 𝐶𝐿1 |     |      |      |                              |             |
| 3.  | 𝑡    |     | → 𝑖𝑛𝑐𝑟𝑒𝑎𝑠𝑒𝑑 𝑠𝑒𝑡𝑢𝑝 𝑚𝑎𝑟𝑔𝑖𝑛 (𝑠𝑙𝑎𝑐𝑘) |     |     |     |     |      |      |                              |             |
𝑠𝑢
𝐹𝐹2
36
©Hanan Ribo

Positive Clock Skew
©Hanan Ribo 37

Negative Clock Skew
| 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |         | < 𝐶𝐿𝐾(𝑃𝐻𝐴𝑆𝐸) |        |   →  𝑇 | < 0 |
| ---------- | ------- | ------------ | ------ | ------ | --- |
|            | 𝑐𝑎𝑝𝑡𝑢𝑟𝑒 |              | 𝑙𝑎𝑢𝑛𝑐ℎ | 𝑠𝑘𝑒𝑤   |     |
|            | 𝐹𝐹      |              |        | 𝐹𝐹     |     |
Explanation:
The clock arrives at the capture FFs
earlier than the launch FF.
This reduces the time available for
data propagation, requiring a
longer clock period to ensure the
data is stable before the clock
clk_src =  edge.
©Hanan Ribo
38

Negative Clock Skew
To guarantee that dynamic discipline is not violated for any register, we perform the worst-
case analysis.
𝑇
𝑐𝑙𝑘
𝑚𝑖𝑛𝑖𝑚𝑢𝑚
| 𝑐𝑙𝑘2 | 𝑝ℎ𝑎𝑠𝑒 |     |     | = 𝑐𝑙𝑘1 |     | 𝑝ℎ𝑎𝑠𝑒 |     | +   | 𝑡    |     | →   𝑡 |     | < 0 |
| ---- | ----- | --- | --- | ------ | --- | ----- | --- | --- | ---- | --- | ----- | --- | --- |
|      |       |     |     |        |     |       |     |     | 𝑠𝑘𝑒𝑤 |     | 𝑠𝑘𝑒𝑤  |     |     |
Timing constraint (FF1 to FF2):
| 1.  | 𝑇    | ≥   |  𝑡  |                      | +   | 𝑡   | +   | 𝑡   |      | +   | 𝑡                               |     | → 𝑙𝑜𝑤𝑒𝑟 𝑓𝑚𝑎𝑥 |
| --- | ---- | --- | --- | -------------------- | --- | --- | --- | --- | ---- | --- | ------------------------------- | --- | ------------ |
|     | 𝑐𝑙𝑘  |     | 𝑝𝑑  |                      |     | 𝑝𝑑  |     | 𝑠𝑢  |      |     | 𝑠𝑘𝑒𝑤                            |     |              |
|     |      |     |     | 𝐹𝐹1                  |     | 𝐶𝐿1 |     |     | 𝐹𝐹2  |     |                                 |     |              |
| 2.  | 𝑡    |     | <   | 𝑡                    |     | + 𝑡 |     | +   | 𝑡    |     | → 𝑖𝑛𝑐𝑟𝑒𝑎𝑠𝑒𝑑 ℎ𝑜𝑙𝑑 𝑚𝑎𝑟𝑔𝑖𝑛 (𝑠𝑙𝑎𝑐𝑘) |     |              |
|     | ℎ𝑜𝑙𝑑 |     |     | 𝑐𝑑                   |     | 𝑝𝑑  |     |     | 𝑠𝑘𝑒𝑤 |     |                                 |     |              |
|     |      | 𝐷2  |     |                      | 𝐹𝐹1 |     | 𝐶𝐿1 |     |      |     |                                 |     |              |
| 3.  | 𝑡    |     | →   | 𝑟𝑒𝑑𝑢𝑐𝑒𝑑 𝑠𝑒𝑡𝑢𝑝 𝑚𝑎𝑟𝑔𝑖𝑛 |     |     |     |     |      |     |                                 |     |              |
𝑠𝑢
𝐷2
39
©Hanan Ribo

Clock Skew - example
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑐𝑙𝑘2(𝑝ℎ𝑎𝑠𝑒) |     | = 𝑐𝑙𝑘1(𝑝ℎ𝑎𝑠𝑒) | + 𝑡 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------- | --- | ------------- | --- |
𝑠𝑘𝑒𝑤
Da𝑡𝑎: 𝑡 = 2𝑛𝑠 , 𝑡 = 3𝑛𝑠 , 𝑡 = 4𝑛𝑠 , 𝑡 = 5𝑛𝑠 , 𝑡 = 4𝑛𝑠 , 𝑡 = 2𝑛𝑠
|     | 𝑠𝑢  |     |     |     | ℎ𝑜𝑙𝑑 |     |     | 𝑐𝑑  |     |     | 𝑐𝑞  |     |     | 𝑝𝑑  |     |     | 𝑝𝑑  |     |
| --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |      |     |     |     |     |     |     |     |     |     | 𝐶𝐿1 |     | 𝐶𝐿2 |     |
𝑸𝒖𝒆𝒔𝒕𝒊𝒐𝒏:
What is the system 𝑓𝑚𝑎𝑥
|     |     |     |     |     |     |     |     |     |     | 𝑇   | =   | max | 𝑇   |      | , 𝑇  | =   | 16𝑛𝑠 |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | ---- | --- | ---- | --- |
|     |     |     |     |     |     |     |     |     |     |     | 𝑚𝑖𝑛 |     |     | 𝑚𝑖𝑛1 | 𝑚𝑖𝑛2 |     |      |     |
𝑨𝒏𝒔𝒘𝒆𝒓:
|     |     |     |     |     |     |     |     |     |     |     | 𝑓   | =   | 1/𝑇 |     | = 62.5𝑀𝐻𝑧 |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |     | 𝑚𝑎𝑥 |     |     | 𝑚𝑖𝑛 |           |     |     |     |
FF1 to FF2 (positive skew):
| 𝑡 + | 𝑡   |     | −   | 𝑡    |     | ≥   | 𝑝ℎ𝑎𝑠𝑒 |     | − 𝑝ℎ𝑎𝑠𝑒 |     |     | →   | 𝑡    |     | ≤ 3𝑛𝑠 |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | ----- | --- | ------- | --- | --- | --- | ---- | --- | ----- | --- | --- | --- |
| 𝑐𝑑  | 𝑝𝑑  |     |     | ℎ𝑜𝑙𝑑 |     |     |       | 𝐹𝐹2 |         |     | 𝐹𝐹1 |     | 𝑠𝑘𝑒𝑤 |     |       |     |     |     |
𝐶𝐿2
| 𝑇    | =   | 𝑡   | +   | 𝑡   |     | +   | 𝑡 − | (𝑝ℎ𝑎𝑠𝑒 |     | −   | 𝑝ℎ𝑎𝑠𝑒 |     | )   | =   | 5𝑛𝑠+2ns+2ns−3ns=11ns |     |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | ----- | --- | --- | --- | -------------------- | --- | --- | --- |
| 𝑚𝑖𝑛1 |     | 𝑐𝑞  |     | 𝑝𝑑  |     |     | 𝑠𝑢  |        | 𝐹𝐹2 |     |       | 𝐹𝐹1 |     |     |                      |     |     |     |
𝐶𝐿2
FF2 to FF1 (negative skew):
| 𝑡 + | 𝑡   |     | −   | 𝑡    |     | ≥   | 𝑝ℎ𝑎𝑠𝑒 |     | − 𝑝ℎ𝑎𝑠𝑒 |     |     | →   | 𝑡    |     | ≥ −5𝑛𝑠 |     |     |     |
| --- | --- | --- | --- | ---- | --- | --- | ----- | --- | ------- | --- | --- | --- | ---- | --- | ------ | --- | --- | --- |
| 𝑐𝑑  | 𝑝𝑑  |     |     | ℎ𝑜𝑙𝑑 |     |     |       | 𝐹𝐹1 |         |     | 𝐹𝐹2 |     | 𝑠𝑘𝑒𝑤 |     |        |     |     |     |
𝐶𝐿1
| 𝑇    | =   | 𝑡   | +   | 𝑡   |     | +   | 𝑡 − | (𝑝ℎ𝑎𝑠𝑒 |     | −   | 𝑝ℎ𝑎𝑠𝑒 |     | )   | =   | 5𝑛𝑠+4ns+2ns-(-5ns)=16ns |     |     |     |
| ---- | --- | --- | --- | --- | --- | --- | --- | ------ | --- | --- | ----- | --- | --- | --- | ----------------------- | --- | --- | --- |
| 𝑚𝑖𝑛2 |     | 𝑐𝑞  |     | 𝑝𝑑  |     |     | 𝑠𝑢  |        | 𝐹𝐹1 |     |       | 𝐹𝐹2 |     |     |                         |     |     |     |
𝐶𝐿1
40
©Hanan Ribo