======================================================================
LAB 3: Simple RISC Multi-Cycle CPU Design
DUT VHDL Files Description
======================================================================

1. top.vhd
   The top-level entity of the design. It integrates the Control Unit and the Datapath modules, and manages the interface with the external Testbench through the Program Memory (ITCM) and Data Memory (DTCM) buses.

2. Control.vhd
   The brain of the CPU, implemented as a Synchronized Mealy Finite State Machine (FSM). It receives the current Instruction Opcode and ALU status flags as inputs, and generates all the necessary control signals to route data through the Datapath across multiple clock cycles.

3. Datapath.vhd
   The execution core of the CPU based on a 1-BUS architecture. It contains the Arithmetic Logic Unit (ALU), Program Counter (PC), Instruction Register (IR), and routing multiplexers. It performs the actual arithmetic, logic, and memory addressing operations.

4. RF.vhd
   The Register File module. It contains an array of 16 general-purpose 16-bit registers (where R[0] is hard-wired to zero). It allows reading from two registers and writing to one register based on control signals.

5. Prog_Mem.vhd
   The Instruction Memory (ITCM) module. It is implemented as a Single Port RAM with an UNREGISTERED output, allowing immediate instruction fetch in the same clock cycle the address is provided.

6. dataMem.vhd
   The Data Memory (DTCM) module. It is implemented as a Single Port RAM with a REGISTERED output, used to store application data and results. The registered output prevents bus contention on the single shared Datapath bus.

7. aux_package.vhd
   A VHDL package containing global constants, type definitions, and component declarations used across the project to maintain clean, organized, and modular code.