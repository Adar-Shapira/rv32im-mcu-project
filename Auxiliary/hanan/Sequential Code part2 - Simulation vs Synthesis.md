VHDL - Sequential Code
(Simulation vs Synthesis)
©Hanan Ribo
1

Simulation and Delta cycles
| • Phase 1: | the compiler reads the whole code for  |     |     |
| ---------- | -------------------------------------- | --- | --- |
signals initialization.
| • Phase 2: | the compiler waits for at least | a SIGNAL  |     |
| ---------- | ------------------------------- | --------- | --- |
event from PROCESSES sensitive list or from
concurrent statements (called implied PROCESS).
| • Phase 3: | when SIGNAL event has happened, the  |     |     |
| ---------- | ------------------------------------ | --- | --- |
compiler makes for each stimulated PROCESS a
sequential list of buffers for the consecutive SIGNALS
assignments. At line END PROCESS all those
assignments are performed in parallel (causes inner
| loops – | Delta cycles). |     |     |
| ------- | -------------- | --- | --- |
•
| Phase 4: | advance time (causes outer loops – |     | Simulation   |
| -------- | ---------------------------------- | --- | ------------ |
cycles)
©Hanan Ribo
2

Simulation and Delta cycles
case3 code
simulation
doesn't
describe
AND gate
Don’t use SIGNALS for
Intermediate calculations
©Hanan Ribo 3

Simulation and Delta cycles
Case1, Case2, Case4
codes simulation
describe AND gate
©Hanan Ribo 4

Simulation vs Synthesis - summary
• Case3 code doesn't describe AND gate while Case3 code synthesis does
describe AND gate!
• Case1, Case2, Case4 codes simulation and Synthesis describe AND gate.
• Synthesis tools and Simulation tools translate PROCESS based VHDL code in
different ways (concurrent code translated in the same way).
• Synthesis tools search for adjustment of HDL code to one of the next three
template kinds (ieee-1076.6 standard):
Combinational Logic, Synchronous Logic, Latch based Logic.
• Our goal: writing of HDL code which will be translated in the same exact
way by all Synthesis and Simulation tools.
©Hanan Ribo 5