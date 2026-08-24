Digital Circuits
Power Analysis
©Hanan Ribo
1

Static Power Dissipation
2

CMOS Static Power Dissipation
In CMOS circuits, static power dissipation 𝑃  is the power consumed when
𝑠𝑡𝑎𝑡𝑖𝑐
the circuit is in a stable, idle state (non-switching), and primarily caused by
leakage currents.
The static power dissipation:
| 𝑃      | =   | 𝐼       |     | ∙ 𝑉 |     |     |
| ------ | --- | ------- | --- | --- | --- | --- |
| 𝑠𝑡𝑎𝑡𝑖𝑐 |     | 𝑙𝑒𝑎𝑘𝑎𝑔𝑒 |     | 𝐷𝐷  |     |     |
The static power dissipation through N-transistors:
tunneling electrons through
𝑁
|  𝑃     | =   | 𝑉   | σ   | 𝐼       |     |                      |
| ------ | --- | --- | --- | ------- | --- | -------------------- |
| 𝑠𝑡𝑎𝑡𝑖𝑐 |     | 𝐷𝐷  |     | 𝑙𝑒𝑎𝑘𝑎𝑔𝑒 |     | the gate dielectric  |
𝑖=1
𝑖
Current leakage from drain to source even though
MOSFET is “off” (subthreshold conduction)

Total DC leakage current
| The total DC leakage current 𝐼 |     |     |         | = 𝐼 | + 𝐼 | + 𝐼  |  includes: |
| ------------------------------ | --- | --- | ------- | --- | --- | ---- | ---------- |
|                                |     |     | 𝑙𝑒𝑎𝑘𝑎𝑔𝑒 | 𝑠𝑢𝑏 | 𝑜𝑥  | 𝐺𝐼𝐷𝐿 |            |
1. Subthreshold leakage 𝐼  flowing from the drain to the source
𝑠𝑢𝑏
when 𝑉 < 𝑉  , depends strongly on temperature and 𝑉  (gets larger as
|                      | 𝐺𝑆  | 𝑡ℎ  |        |                |     |     | 𝑡ℎ  |
| -------------------- | --- | --- | ------ | -------------- | --- | --- | --- |
| difference between 𝑉 |     |     |  and 𝑉 |  gets smaller) |     |     |     |
𝑡ℎ 𝐺
𝑜𝑓𝑓
2. Gate Oxide leakage 𝐼  tunneling through the gate dielectric (dependent
𝑜𝑥
on the gate oxide thickness and material)
3. Junction leakage 𝐼  caused by high electric fields in the drain junction
𝐺𝐼𝐷𝐿
(dependent on the voltage difference between the gate and drain)

Dynamic Power Dissipation
5

CMOS Dynamic Power Dissipation
Dynamic Power is
|                |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑉    |     | 𝑚𝑜𝑣𝑒𝑠 𝑓𝑟𝑜𝑚 𝐿 𝑡𝑜 𝐻 (C |     |     |     |     |     |     |  charges) |
| -------------- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | -------------------- | --- | --- | --- | --- | --- | --- | --------- |
| consumed when  |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑂𝑈𝑇  |     |                      |     |     |     |     |     | L   |           |
transistors actively
switch states.
Energy is drawn
from the supply to
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | = 𝐶 | +   | 𝐶    | +   | 𝑁 ∙ | 𝐶   |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | --- | --- | --- | --- | --- |
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑜𝑢𝑡 | 𝑙𝑖𝑛𝑒 |     |     | 𝑖𝑛  |     |     |     |
charge/discharge
node capacitances.
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑉   |      | 𝑚𝑜𝑣𝑒𝑠 𝑓𝑟𝑜𝑚 𝐻 𝑡𝑜 𝐿 (C |     |     |     |     |     |     |  discharges) |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | -------------------- | --- | --- | --- | --- | --- | --- | ------------ | --- |
|     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     | 𝑂𝑈𝑇  |                      |     |     |     |     |     |     | L            |     |
𝑑 𝑉
𝑜𝑢𝑡
| 𝑃   | = 𝐼 | ∙   | 𝑉   | =   | 𝐶 ∙ |     |     | ∙ 𝑉 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 𝑜𝑢𝑡 | 𝑜𝑢𝑡 |     | 𝑜𝑢𝑡 |     |     |     |     | 𝑜𝑢𝑡 |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |     |
𝑑𝑡
𝑇
𝑐𝑙𝑘
|           |     |     |     | 𝑇     |     | 𝑑 𝑉 |     |        |      |     | 𝑇   |     |     |     |     | 𝑉2  |     |     |     |     |     |     |      |     |               |
| --------- | --- | --- | --- | ----- | --- | --- | --- | ------ | ---- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---- | --- | ------------- |
|           |     |     |     |       | 𝑐𝑙𝑘 |     |     |        |      |     | 𝑐𝑙𝑘 |     |     |     |     |     |     | 𝐸   | =   | න   | 𝑃   |     | 𝑡 𝑑𝑡 | = 𝐶 | ∙ 𝑉 2  [Wsec] |
|           |     |     |     |       |     |     | 𝑜𝑢𝑡 |        |      |     |     |     |     |     |     | 𝑜𝑢𝑡 |     |     |     |     |     |     |      |     |               |
| 𝐸         |     | =   | −𝐶  | න     |     |     |     | ∙ 𝑉 𝑑𝑡 | = −𝐶 | න   |     | 𝑉   |  𝑑𝑉 | =   | 𝐶   |     |     | 𝑑𝑦𝑚 |     |     | 𝑜𝑢𝑡 |     |      |     | 𝐷𝐷            |
| 𝑑𝑖𝑠𝑐ℎ𝑎𝑟𝑔𝑒 |     |     |     |       |     |     |     | 𝑜𝑢𝑡    |      |     |     | 𝑜𝑢𝑡 |     | 𝑜𝑢𝑡 |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     |     |       |     | 𝑑𝑡  |     |        |      |     |     |     |     |     |     | 2   |     |     |     | 0   |     |     |      |     |               |
|           |     |     |     | 0     |     |     |     |        |      |     | 0   |     |     |     |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     | 𝑇   |       |     |     |     |        | 𝑇    |     |     |     |     | 𝑉2  |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     |     | 𝑐𝑙𝑘 𝑑 | 𝑉   |     |     |        | 𝑐𝑙𝑘  |     |     |     |     |     |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     |     |       | 𝑜𝑢𝑡 |     |     |        |      |     |     |     |     | 𝑜𝑢𝑡 |     |     |     | 𝑃   | =   | 𝑓   | ∙ 𝐸 |     | = 𝑓  | ∙ 𝐶 | ∙ 𝑉 2  [𝑊]    |
| 𝐸         |     | = 𝐶 | න   |       |     |     | ∙ 𝑉 | 𝑑𝑡 =   | 𝐶 න  | 𝑉   |  𝑑𝑉 |     | =   | 𝐶   |     |     |     | 𝑑𝑦𝑚 |     | 𝑐𝑙𝑘 | 𝑑𝑦𝑚 |     | 𝑐𝑙𝑘  |     | 𝐷𝐷            |
| 𝑐ℎ𝑎𝑟𝑔𝑒    |     |     |     |       |     |     | 𝑜𝑢𝑡 |        |      |     | 𝑜𝑢𝑡 | 𝑜𝑢𝑡 |     |     |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     | 𝑇   |       | 𝑑𝑡  |     |     |        | 𝑇    |     |     |     |     | 2   |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     | 𝑐𝑙𝑘 |       |     |     |     |        | 𝑐𝑙𝑘  |     |     |     |     |     |     |     |     |     |     |     |     |     |      |     |               |
|           |     |     | 2   |       |     |     |     |        | 2    |     |     |     |     |     |     |     |     |     |     |     |     |     |      |     |               |

Energy vs. Power
Energy:
• The total capacity to do work (is a measure of quantity), like a car's
total fuel or like battery total capacity.
• Energy measure unit is joules [J] = [Wsec].
Power:
• The rate at which that work is done over time (the speed the energy is
used), like a car's engine horsepower or battery electrical power.
• Power measure unit is watts [W] = [J/sec] (i.e., energy per second).
Electrical Power and Energy: 𝑃 = 𝐼 ∙ V [W] , E = 𝐼 ∙ V ∙ t [J]
How much energy a 100W light bulb running for 2 hours uses ?
E = 200 Wh = 200 ∙ 3600 𝐽 = 720,000 𝐽
©Hanan Ribo 7

CMOS Dynamic Power Dissipation
per chip
per node
How can we estimate the dynamic power dissipation per chip?
𝑓  = transitions (charge or/and discharge) frequency
𝐶𝐿𝐾
𝑁 = number of changing nodes
| Power dissipation (per node) = 𝑓 | ∙ 𝐶 ∙ | 𝑉 2 |
| -------------------------------- | ----- | --- |
𝐶𝐿𝐾
𝐷𝐷
| Power dissipation (per chip) = 𝑓 | ∙ 𝑁 ∙ 𝐶 | ∙ 𝑉 2 |
| -------------------------------- | ------- | ----- |
| 𝐶𝐿𝐾                              |         | 𝐷𝐷    |

CMOS Dynamic Power Dissipation - Example
per chip
per node
|     |      |      | 𝑐𝑦𝑐𝑙𝑒𝑠 |          | 𝑐ℎ𝑎𝑛𝑔𝑖𝑛𝑔 𝑛𝑜𝑑𝑒𝑠 |        |     |        |      |     | 𝐹𝑎𝑟𝑎𝑑 |       |     |
| --- | ---- | ---- | ------ | -------- | -------------- | ------ | --- | ------ | ---- | --- | ----- | ----- | --- |
|     |      |      | 9      |          | 8              |        |     |        |      | −15 |       |       |     |
| 𝑓 ≅ | 1𝐺𝐻𝑧 | = 10 |        | , 𝑁 ≅ 10 |                |        | , 𝐶 | ≅ 1 𝑓𝐹 | = 10 |     |       | , 𝑉 ≅ | 1𝑉  |
| 𝐶𝐿𝐾 |      |      |        |          |                |        | 𝑜𝑢𝑡 |        |      |     |       | 𝐷𝐷    |     |
|     |      |      | 𝑠𝑒𝑐    |          |                | 𝑐𝑦𝑐𝑙𝑒𝑠 |     |        |      |     | 𝑛𝑜𝑑𝑒  |       |     |
Estimation of the chip dynamic power dissipation?
|     |     |     |     |     |     |     | 2   | 9   | 8   | −15 | 2   |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
𝐷𝑦𝑛𝑎𝑚𝑖𝑐 𝑃𝑜𝑤𝑒𝑟 𝑑𝑖𝑠𝑠𝑖𝑝𝑎𝑡𝑖𝑜𝑛 = 𝑓 ∙ 𝑁 ∙ 𝐶 ∙ 𝑉 = 10 ∙ 10 ∙ 10 ∙ 1 = 100𝑊
|     |     |     |     |     | 𝐶𝐿𝐾 |     | 𝐷𝐷  |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |

Counter layout on an FPGA - example
©Hanan Ribo 10