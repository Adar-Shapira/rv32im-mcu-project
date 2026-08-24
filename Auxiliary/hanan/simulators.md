Computer Architecture
Simulators
Course: 361-1-4201
Dr. Guy Tel-Zur
לש הנבהב עייסל םילוכי רשא ,םיישפוח ,היצלומיס ילכ םיראותמ וז תגצמב
.ימצע לוגרת תועצמאב דומילה ירמוח
11/4/2024 :ןורחא ןוכדע .תעל תעמ ןכדעתת תגצמה
11/1/2026

In 3 Parts...
Part 1: MIPS
Part 2: RISC-V
Part 3: Additional tools

Part 1: MIPS
Starting from 2026B we
totally migrate to RISC-V

MARS
Java based MIPS simulator
Home page:
http://courses.missouristate.edu/KenVollmar/MARS/
Starting from 2026B we
totally migrate to RISC-V

MARS
Invocation (Linux):
Starting from 2026B we
totally migrate to RISC-V.
You can ignore MARS and
all the other MIPS
simulators

MARS
1) 2)
Starting from 2026B we
Run→ Assemble Go
totally migrate to RISC-V
The code
Memory
The registers
Terminal

MARS
Tools → X-Ray
Starting from 2026B we
totally migrate to RISC-V
2) Execute
1) Connect to MIPS

SPIM / QtSPIM
https://
spimsimulator.sourceforge.net/
Starting from 2026B we
totally migrate to RISC-V

QtSPIM
The code is loaded
into the simulator.
To execute click on
“Simulator” →
Run (F5) or
Single Step (F10)
Starting from 2026B we
totally migrate to RISC-V

EduMIPS
https://
edumips.org/
Starting from 2026B we
totally migrate to RISC-V

Home screen
Starting from 2026B we
totally migrate to RISC-V

While running a code
Starting from 2026B we
totally migrate to RISC-V

Dr. MIPS
https://brunonova.github.io/drmips/
https://github.com/brunonova/drmips
https://www.youtube.com/watch?v=dyDSV-3v1Ns
Starting from 2026B we
totally migrate to RISC-V

Dr. MIPS
Starting from 2026B we
totally migrate to RISC-V

Single cycle
Starting from 2026B we
totally migrate to RISC-V

Pipelined
Starting from 2026B we
totally migrate to RISC-V

Dr. MIPS
There is a support for several micro-
architectures
(* but there isn’t support for Jump in
many of them * )
Starting from 2026B we
totally migrate to RISC-V

QtMIPS
This is an advanced MIPS simulation tool!
Home page: https://comparch.edu.cvut.cz/qtmips/app/
See a screen capture in the next slide
Starting from 2026B we
Tutorial video: totally migrate to RISC-V
https://www.youtube.com/watch?v=6xH72UBvnaY

QtMIPS
Starting from 2026B we
totally migrate to RISC-V

Part 2: RISC-V
Starting from 2026B RISC-V
is the course architecture

RARS
RARS = RISC-V Assembler and Runtime Simulator
Similar to MARS there is RARS for the RISC-V processor.
Home page: https://github.com/TheThirdOne/rars
Invocation:
java -jar /path/to/the/jar/file/RARS/rars1_4.jar

RISC-V
Home page: https://riscv-programming.org/ale/#home
(it was tested on Google Chrome)
This is a portal for executing RISC-V code.
RISC-V emulation is done here in two stages:
1) build: This is done on the local (Linux) machine with the RISC-V tool
chain.
2) Upload and execute the code in the portal.
A video tutorial:
https://www.youtube.com/watch?v=Av5kg5xavuo

RISC-V
QtRVSim
QtRVSim is the counter part to the QtMIPS simulator
Tutorial are available at:
https://comparch.edu.cvut.cz/slides/ewc22-qtrvsim.pdf
and:
https://drive.google.com/file/d/1Rxd6-Qm6LhkDjd9740IAkY_kX1roLOeO/view
The simulator is available at:
https://github.com/cvut/qtrvsim
and must be downloaded to the local computer.
In addition there is an online version (like in the case of the QtMIPS) is available
from here:
https://comparch.edu.cvut.cz/qtrvsim/app/

RISC-V
QtRVSim

Ripes
A graphical processor simulator and assembly editor for the RISC-V ISA
Homepage:
https://github.com/mortbopet/Ripes/
Documentation:
https://github.com/mortbopet/Ripes/tree/master/docs
Easy install:
In Linux as AppImage just do
chmod u+x Ripes-v2.2.6-linux-x86_64.AppImage

The
The assembly
disassembled  The registers
|     | code  |     |
| --- | ----- | --- |
code

Venus
https://venus.kvakil.me/
https://venus.cs61c.org/
Open source:
https://github.com/kvakil/venus
User guide:
https://github.com/kvakil/venus/wiki

Venus
The Editor tab:
The Editor tab:
The Simulator tab:

Venus as a VS-Code Extension
ext install hm.riscv-venus

emulsiV
https://eseo-tech.github.io/emulsiV/

WebRISC-V
https://webriscv.altervista.org/
https://github.com/Mariotti94/WebRISC-V

Interactive RISC-V Simulator
https://riscv-simulator-five.vercel.app/

RISC-V Functional Simulator
https://risc-v-cpu-visualizer.vercel.app/simulator

ret
https://ret.futo.org/riscv/

CPUlator Computer System Simulator - I
1) Select the
system
2) Check the
link
https://cpulator.01xz.net/

CPUlator Computer System Simulator - II
3) You will be
redirected to
the simulator

QEMU
RISC-V 64 Bit Emulator
https://www.qemu.org/download/#windows
Build from the source:
git clone git clone https://gitlab.com/qemu-project/qemu.git
+ The RISC-V Toolchain

Spike
https://github.com/riscv-software-src /riscv-isa-sim
Spike is the official or golden‑reference–style RISC‑V Instruction Set Simulator
(ISS)
telzur@TUF:~/science/Teaching/CPU/SW/spike/guy$ riscv64-unknown-elf-gcc -o hello ./hello.c
telzur@TUF:~/science/Teaching/CPU/SW/spike/guy$ spike --isa=rv64gcv $(which pk) hello
Hello World!
Spike is best suited for:
✔ Reference ISA‑level correctness
✔ Early software development (bare‑metal & small programs)
✔ Debugging and inspecting architectural state
✔ Verification and compliance testing
✔ Exploring ISA extensions and configurations
✔ Running RISC‑V code when hardware is not available

Get a RISC-V core!
https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32c3/esp32-c3-devkitm-1/index.html
Install Espressif IDF and/or Arduino IDE

Part 3: Additional simulators
Compiler Explorer
Reorder Buffer
Tomasulo Algorithm

Compiler Explorer
https://
godbolt.org/

Reorder Buffer
https://www.ecs.umass.edu/ece/koren/architecture/ROB/rob_simulator.htm
יח יצח הזה רתאה
(SSL חטבואמ אל רתאה)

Tomasulo Algorithm
http://nathantypanski.github.io/tomasulo-simulator/

Tomasulo Algorithm
https://www.ecs.umass.edu/ece/koren/architecture/Tomasulo/AppletTomasulo.html
Can work from Chrome but requires Java Plug-in.
For example: Cheerp Java Applet Runner.

Tomasulo’s Algorithm V1.5
https://www.icsa.inf.ed.ac.uk/cgi-bin/hase/ident.pl?Tomasulo
works on Chrome with CheerpJ java applet addon
ללגב לעופ אל
הכימת תעינמ
םינפדפדב הווא’גב
.םיינרדומ

FreeSS
!שדח רוטלומיס
WCAE'25 - Workshop on Computer Architecture
Education, June 21--25, 2025, Tokyo, Japan
paper:https://arxiv.org/abs/2506.07665
code:
https://github.com/robgiorgi/freess

RIDECORE: RIsc-v Dynamic Exection CORE
RIDECORE's microarchitecture is based on "Modern Processor Design: Fundamentals of Superscalar Processors"
https://github.com/ridecore/ridecore/tree/master

References
Roberto Giorgi, “FREESS: An Educational Simulator of a RISC-V-Inspired
Superscalar Processor Based on Tomasulo’s Algorithm”, Proceedings of per cycle,
also known as Flynn’s bottleneck. This limitation is over-Workshop on Computer
Architecture Education (WCAE ’25).