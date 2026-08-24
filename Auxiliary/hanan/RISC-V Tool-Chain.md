RISC-V Toolchain - Phases from C/C++ application code to memory-based binary files

Contents
Phase 1 - Write and develop your HLL application using C/C++: ...................................................................... 1

1.  Option of using an online IDE: .................................................................................................................... 1

2.  Option of using local IDEs such as Visual Studio, CLion, etc: ........................................................................... 1

Phase 2 - Disassemble your C/C++ application using the RISC-V gcc-compiler: .............................................. 1

1.  Option of using an online gcc-compiler: ...................................................................................................... 1

2.  Option of using  a manual compilation: .................................................................................................... 1

Phase 3 – Use assembly RARS IDE: ................................................................................................................ 2

Phase 4 – Create ITCM.hex and DTCM.hex execution binary files: .................................................................. 2

Phase 1 - Write and develop your HLL application using C/C++:

1.  Option of using an online IDE:

C/C++ online IDE

2.  Option of using local IDEs such as Visual Studio, CLion, etc:

vs_WDExpress_2017.exe

Phase 2 - Disassemble your C/C++ application using the RISC-V gcc-compiler:

1.  Option of using an online gcc-compiler:

C/C++ to RV32I disassembly online gcc-compiler

Choose this gcc configuration

Choose the Execute mode

2.  Option of using  a manual compilation:

Write the equivalent assembly code yourself.

Note: In case the gcc disassembly code contains a system call to a standard C library function, we

can’t use the gcc-compiler for our unprivileged core (we need to compile the C/C++ code manually).

Phase 3 – Use assembly RARS IDE:

1.  Open the RARS assembly IDE:

RARS RISC-V Assembler, Simulator, and Runtime IDE (local)

2.  Make sure of the next RARS Configurations:

Choose this
DTCM of
Harvard
configuration

Note: For multiple assembly source files, prefix numbering is required according to their compilation

order.

3.  In case of using gcc disassembly (see Phase 2.1), make the following four changes:

i.  Add two directives at the beginning of the data segment:

.globl main

.data

ii.  Add the directives at the beginning of the code segment (before the label main):

.text

iii.  Replace the directive .zero with .space

iv.  Replace the assembly instruction name lla with la

4.  Create from the assembly code files ITCM.h and DTCM.h of Hexadecimal-Text format.

Phase 4 – Create ITCM.hex and DTCM.hex execution binary files:

Use the following application (for Windows ) to create binary execution files ITCM.hex and DTCM.hex

suitable for our platform: TextHex32bit-to-IntelHex32bit.exe

