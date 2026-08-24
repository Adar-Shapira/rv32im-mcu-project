Synchronous FSM
(Finite State Machine)
Rehearsal
©Hanan Ribo
1

Synchronous FSM definition
Clocked FSM

Synchronous FSM Abstraction

Synchronous FSM - Discrete State, Discrete Time

Synchronous FSM - Initialization

Mealy vs. Moore Machines
Moore
Mealy
©Hanan Ribo 6

Mealy vs. Moore Machines
|        | Moore   |       |        | Mealy     |       |
| ------ | ------- | ----- | ------ | --------- | ----- |
| 𝑜𝑢𝑡𝑝𝑢𝑡 | = 𝑓(𝑃𝑆) |       | 𝑜𝑢𝑡𝑝𝑢𝑡 | = 𝑓(𝑖𝑛𝑝𝑢𝑡 | , 𝑃𝑆) |
| 𝑁𝑆 =   | 𝑔(𝑖𝑛𝑝𝑢𝑡 | , 𝑃𝑆) | 𝑁𝑆 =   | 𝑔(𝑖𝑛𝑝𝑢𝑡   | , 𝑃𝑆) |
©Hanan Ribo
7

FSM design Example
8

FSM design Example
You are required to design Up/Down modulo 4 counter with the next spec:
• Input X uses as Up/Down selector (X=‘0’ Up counter, X=‘1’ Down counter).
• Output LED3,LED2 show the counter value.
• Output LED0 is set only on counter value transition from “00” to “11”.
• Output LED1 is set only on counter value transition from “11” to “00”.
©Hanan Ribo

FSM design Example
| (LED3,LED2) = |     | 𝑓     | 𝑃𝑆    |
| ------------- | --- | ----- | ----- |
| (LED1,LED0) = |     | 𝑓(𝑋   | , 𝑃𝑆) |
| 𝑁𝑆 =          | 𝑔(𝑋 | , 𝑃𝑆) |       |
©Hanan Ribo

Phase 1 – Drawing of States Diagram
Symbolic Legend:
Thumb rule: The transitions condition from each state out are disjoint and complement.
For example:
State1 transitions condition out are: x=1/00 , x=0/00 therefore 𝒙 ∙ 𝒙ഥ =0 (disjoint) and 𝒙 + 𝒙ഥ =1 (complement)
©Hanan Ribo

| Phase 2 – |         | Primitive Transitions Table |             |     |     |     |
| --------- | ------- | --------------------------- | ----------- | --- | --- | --- |
|           | Input X |                             | X=0         |     |     | X=1 |
PS
| State0 |     | NS/LED1,LED0 = State1/00 |     |      | NS/LED1,LED0 = State3/10 |     |
| ------ | --- | ------------------------ | --- | ---- | ------------------------ | --- |
| State1 |     | NS/LED1,LED0 = State2/00 |     |      | NS/LED1,LED0 = State0/00 |     |
| State2 |     | NS/LED1,LED0 = State3/00 |     |      | NS/LED1,LED0 = State1/00 |     |
| State3 |     | NS/LED1,LED0 = State0/01 |     |      | NS/LED1,LED0 = State2/00 |     |
|        |     | 𝑷𝑺                       | →ณ  | 𝑵𝑺 / | 𝑶𝒖𝒕𝒑𝒖𝒕                   |     |
𝒊𝒏𝒑𝒖𝒕 𝑿
This primitive table cannot be reduced (recall that two states are identical iff their NS and
Output are identical for the same input value).
©Hanan Ribo

| Phase 3 – | States Encoding and Transitions table |     |     |     |     |     |     |     |     |
| --------- | ------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
State Binary
|     |     |     |     | 𝑃𝑆 ≜ | 𝑃𝑟𝑒𝑠𝑒𝑛𝑡 | 𝑆𝑡𝑎𝑡𝑒 | =   | 𝑦 , 𝑦 |     |
| --- | --- | --- | --- | ---- | ------- | ----- | --- | ----- | --- |
2 1
|     | State0 | 00  |     |     |        |       |     |     |     |
| --- | ------ | --- | --- | --- | ------ | ----- | --- | --- | --- |
|     | State1 | 01  |     | 𝑁𝑆  | ≜ 𝑁𝑒𝑥𝑡 | 𝑆𝑡𝑎𝑡𝑒 | = 𝑌 | , 𝑌 |     |
2 1
|         | State2      | 10  |     |     |     |     |             |     |     |
| ------- | ----------- | --- | --- | --- | --- | --- | ----------- | --- | --- |
|         | State3      | 11  |     |     |     |     |             |     |     |
| Input X | X=0         |     | X=1 |     |     | X   | X=0         |     | X=1 |
| PS      |             |     |     |     |     | PS  |             |     |     |
State0 NS/LED1,LED0 = State1/00 NS/LED1,LED0 = State3/10 00 01/00 11/10
State1 NS/LED1,LED0 = State2/00 NS/LED1,LED0 = State0/00 01 10/00 00/00
State2 NS/LED1,LED0 = State3/00 NS/LED1,LED0 = State1/00 10 11/00 01/00
State3 NS/LED1,LED0 = State0/01 NS/LED1,LED0 = State2/00 11 00/01 10/00
©Hanan Ribo

Phase 4 – Implementation
| Input X | X=0         | X=1 |     |     | X   | X=0         | X=1 |
| ------- | ----------- | --- | --- | --- | --- | ----------- | --- |
| PS      |             |     |     |     | PS  |             |     |
State0 NS/LED1,LED0 = State1/00 NS/LED1,LED0 = State3/10 00 01/00 11/10
State1 NS/LED1,LED0 = State2/00 NS/LED1,LED0 = State0/00 01 10/00 00/00
State2 NS/LED1,LED0 = State3/00 NS/LED1,LED0 = State1/00 10 11/00 01/00
State3 NS/LED1,LED0 = State0/01 NS/LED1,LED0 = State2/00 11 00/01 10/00
|     |     |     | 𝑃𝑆 ≜ | 𝑃𝑟𝑒𝑠𝑒𝑛𝑡 | 𝑆𝑡𝑎𝑡𝑒 | =   | 𝑦 , 𝑦 |
| --- | --- | --- | ---- | ------- | ----- | --- | ----- |
2 1
|     |     |     | 𝑁𝑆  | ≜ 𝑁𝑒𝑥𝑡 | 𝑆𝑡𝑎𝑡𝑒 | = 𝑌 | , 𝑌 |
| --- | --- | --- | --- | ------ | ----- | --- | --- |
2 1
©Hanan Ribo

Phase 4 – Implementation
| 𝑃𝑆 ≜ | 𝑦 , 𝑦 |     |     |     |     |
| ---- | ----- | --- | --- | --- | --- |
2 1
| 𝑁𝑆 ≜ | 𝑌 , 𝑌 |     |     |     |     |
| ---- | ----- | --- | --- | --- | --- |
2 1
|      |       |          | 𝐿𝐸𝐷1 | = 𝑦 | ∙ 𝑦 ∙ 𝑥 |
| ---- | ----- | -------- | ---- | --- | ------- |
|      |       |          |      | 2   | 1       |
| 𝐿𝐸𝐷0 | = 𝑦   | ∙ 𝑦 ∙ 𝑥ҧ |      |     |         |
|      | 2     | 1        |      |     |         |
| 𝑌    | = 𝑥⨁𝑦 | ⨁𝑦       | 𝑌    | = 𝑦 |         |
1 1
| 2   |     | 2 1 |     |     |     |
| --- | --- | --- | --- | --- | --- |
©Hanan Ribo

Phase 4 – Implementation
Tradeoff:
#DFFs
vs.
ROM
FANin and FANout size
or
Explanation:
Pure
Depending the States
Combinational
Encoding Allocation (Binary
Logic
Encoding or Direct Encoding)
and
The target HW (LUT based
Next
Present
with low FANin but DFFs
DFFs Array State
abundantly as with FPGA or State
the opposite with ASIC).
©Hanan Ribo