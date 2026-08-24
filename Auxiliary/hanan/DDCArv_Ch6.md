Digital Design &
Computer Architecture
Sarah Harris & David Harris
Chapter 6:
Architecture

Chapter 6 :: Topics
•
Introduction
|     | • Assembly Language |     |
| --- | ------------------- | --- |
•
Programming
|     | • Machine Language         |     |
| --- | -------------------------- | --- |
|     | • Addressing Modes         |     |
|     | • Lights, Camera, Action:  |     |
Compiling, Assembly, & Loading
|     | • Odds & Ends                          |              |
| --- | -------------------------------------- | ------------ |
| 2   | Digital Design & Computer Architecture | Architecture |

Introduction
•
Jumping up a few levels of
abstraction
|     | • Architecture: programmer’s view  |     |
| --- | ---------------------------------- | --- |
of computer
– Defined by instructions & operand
locations
|     | • Microarchitecture: how to  |     |
| --- | ---------------------------- | --- |
implement an architecture in
hardware (covered in Chapter 7)
| 3   | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Assembly Language
|     | • Instructions: commands in a computer’s  |     |
| --- | ----------------------------------------- | --- |
language
–
Assembly language: human-readable format of
instructions
– Machine language: computer-readable format
(1’s and 0’s)
|     | • RISC-V architecture: |     |
| --- | ---------------------- | --- |
– Developed by Krste Asanovic, David Patterson
and their colleagues at UC Berkeley in 2010.
– First widely accepted open-source computer
architecture
  Once you’ve learned one architecture, it’s easier to learn others
| 4   | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Kriste Asanovic
| •   | Professor of Computer  |     |
| --- | ---------------------- | --- |
Science at the University of
California, Berkeley
| •   | Developed RISC-V during one  |     |
| --- | ---------------------------- | --- |
summer
| •   | Chairman of the Board of the  |     |
| --- | ----------------------------- | --- |
RISC-V Foundation
| •   | Co-Founder of SiFive, a  |     |
| --- | ------------------------ | --- |
company that commercializes
and develops supporting
tools for RISC-V
| 5   | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Andrew Waterman
•
Co-founded SiFive with Krste
Asanovic
| •   | Weary of existing instruction  |     |
| --- | ------------------------------ | --- |
set architectures (ISAs), he
co-designed the RISC-V
architecture and the first
RISC-V cores
| •   | Earned his PhD in computer  |     |
| --- | --------------------------- | --- |
science from UC Berkeley in
2016
| 6   | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

David Patterson
| •   | Professor of Computer Science at  |     |
| --- | --------------------------------- | --- |
the University of California,
Berkeley since 1976
| •   | Coinvented the Reduced  |     |
| --- | ----------------------- | --- |
Instruction Set Computer (RISC)
with John Hennessy in the 1980’s
•
Founding member of RISC-V team.
| •   | Was given the Turing Award (with  |     |
| --- | --------------------------------- | --- |
John Hennessy) for pioneering a
quantitative approach to the
design and evaluation of computer
architectures.
| 7   | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

John Hennessy
• President of Stanford University from
2000 - 2016.
• Professor of Electrical Engineering and
Computer Science at Stanford since
1977
• Coinvented the Reduced Instruction Set
Computer (RISC) with David Patterson
in the 1980’s
• Was given the Turing Award (with David
Patterson) for pioneering a quantitative
approach to the design and evaluation
of computer architectures.
8 Digital Design & Computer Architecture Architecture

Architecture Design Principles
Underlying design principles, as articulated by
Hennessy and Patterson:
1.Simplicity favors regularity
2.Make the common case fast
3.Smaller is faster
4.Good design demands good compromises
9 Digital Design & Computer Architecture Architecture

Chapter 6: Architecture
Instructions

Instructions: Addition
C Code RISC-V assembly code
a = b + c; add a, b, c
|     | • add:   |     | mnemonic indicates operation to perform |     |
| --- | -------- | --- | --------------------------------------- | --- |
|     | • b, c:  |     |                                         |     |
source operands (on which the operation is
|     |                                        |     | performed)                                   |              |
| --- | -------------------------------------- | --- | -------------------------------------------- | ------------ |
|     | • a:                                   |     | destination operand (to which the result is  |              |
|     |                                        |     | written)                                     |              |
| 11  | Digital Design & Computer Architecture |     |                                              | Architecture |

Instructions: Subtraction
Similar to addition - only mnemonic changes
C Code RISC-V assembly code
a = b - c; sub a, b, c
|     | • sub:  mnemonic         |     |
| --- | ------------------------ | --- |
|     | • b, c:  source operands |     |
|     | • a:                     |     |
destination operand
| 12  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Design Principle 1
Simplicity favors regularity
•
Consistent instruction format
|     | • Same number of operands (two sources  |     |
| --- | --------------------------------------- | --- |
and one destination)
|     | • Easier to encode and handle in hardware |              |
| --- | ----------------------------------------- | ------------ |
| 13  | Digital Design & Computer Architecture    | Architecture |

Multiple Instructions
More complex code is handled by multiple
RISC-V instructions.
C Code RISC-V assembly code
a = b + c - d; add t, b, c # t = b + c
sub a, t, d # a = t - d
14 Digital Design & Computer Architecture Architecture

Design Principle 2
Make the common case fast
|     | • RISC-V includes only simple, commonly used  |     |
| --- | --------------------------------------------- | --- |
instructions
|     | • Hardware to decode and execute instructions can  |     |
| --- | -------------------------------------------------- | --- |
be simple, small, and fast
•
More complex instructions (that are less common)
performed using multiple simple instructions
|     | • RISC-V is a reduced instruction set computer (RISC),  |     |
| --- | ------------------------------------------------------- | --- |
with a small number of simple instructions
|     | • Other architectures, such as Intel’s x86, are complex  |     |
| --- | -------------------------------------------------------- | --- |
instruction set computers (CISC)
| 15  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Chapter 6: Architecture
Operands

Operands
|     | • Operand location: physical location  |     |
| --- | -------------------------------------- | --- |
in computer
– Registers
– Memory
– Constants (also called immediates)
| 17  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Operands: Registers
|     | • RISC-V has 32 32-bit registers       |     |
| --- | -------------------------------------- | --- |
|     | • Registers are faster than memory     |     |
|     | • RISC-V called “32-bit architecture”  |     |
because it operates on 32-bit data
| 18  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Design Principle 3
Smaller is Faster
|     | • RISC-V includes only a small number  |     |
| --- | -------------------------------------- | --- |
of registers
| 19  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

RISC-V Register Set
|     | Name | Register Number | Usage |     |
| --- | ---- | --------------- | ----- | --- |
zero
|     |     | x0  | Constant value 0 |     |
| --- | --- | --- | ---------------- | --- |
ra
|     |     | x1  | Return address |     |
| --- | --- | --- | -------------- | --- |
|     | sp  | x2  | Stack pointer  |     |
|     | gp  | x3  | Global pointer |     |
tp
|     |     | x4  | Thread pointer |     |
| --- | --- | --- | -------------- | --- |
t0-2
|     |       | x5-7 | Temporaries                    |     |
| --- | ----- | ---- | ------------------------------ | --- |
|     | s0/fp | x8   | Saved register / Frame pointer |     |
|     | s1    | x9   | Saved register                 |     |
a0-1
|     |     | x10-11 | Function arguments / return values |     |
| --- | --- | ------ | ---------------------------------- | --- |
a2-7
|     |                                        | x12-17 | Function arguments |              |
| --- | -------------------------------------- | ------ | ------------------ | ------------ |
|     | s2-11                                  | x18-27 | Saved registers    |              |
|     | t3-6                                   | x28-31 | Temporaries        |              |
| 20  | Digital Design & Computer Architecture |        |                    | Architecture |

Operands: Registers
|     | • Registers: |     |
| --- | ------------ | --- |
Can use either name (i.e., ra, zero) or x0, x1,
–
etc.
– Using name is preferred
|     | • Registers used for specific purposes:  |     |
| --- | ---------------------------------------- | --- |
• zero always holds the constant value 0.
• the saved registers, s0-s11, used to hold
variables
• the temporary registers, t0-t6, used to
hold intermediate values during a larger
computation
• Discuss others later
| 21  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Instructions with Registers
Revisit add instruction
•
|     | C Code RISC-V assembly code |     |
| --- | --------------------------- | --- |
# s0 = a, s1 = b, s2 = c
|     | a = b + c; add s0, s1, s2 |     |
| --- | ------------------------- | --- |
# indicates a single-line comment
| 22  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Instructions with Constants
|     | • addi instruction          |     |
| --- | --------------------------- | --- |
|     | C Code RISC-V assembly code |     |
# s0 = a, s1 = b
|     | a = b + 6; addi s0, s1, 6              |              |
| --- | -------------------------------------- | ------------ |
| 23  | Digital Design & Computer Architecture | Architecture |

Chapter 6: Architecture
Memory Operands

Operands: Memory
|     | • Too much data to fit in only 32 registers |     |
| --- | ------------------------------------------- | --- |
|     | • Store more data in memory                 |     |
|     | • Memory is large, but slow                 |     |
|     | • Commonly used variables kept in           |     |
registers
| 25  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Memory
|     | • First, we’ll discuss word-addressable  |     |
| --- | ---------------------------------------- | --- |
memory
|     | • Then we’ll discuss byte-addressable  |     |
| --- | -------------------------------------- | --- |
memory
       RISC-V is byte-addressable
| 26  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Word-Addressable Memory
|     | • Each 32-bit data word has a unique  |     |     |     |     |
| --- | ------------------------------------- | --- | --- | --- | --- |
address
|     |     | Word Address |     | Data    | Word Number |
| --- | --- | ------------ | --- | ------- | ----------- |
|     |     | 00000004     | C D | 1 9 A 6 | 5 B Word 4  |
|     |     | 00000003     | 4 0 | F 3 0 7 | 8 8 Word 3  |
|     |     |              | 0 1 | E E 2 8 | 4 2         |
00000002 Word 2
|     |     |     | F 2 | F 1 A C | 0 7 |
| --- | --- | --- | --- | ------- | --- |
00000001 Word 1
|     |     | 00000000 | A B | C D E F | 7 8 Word 0 |
| --- | --- | -------- | --- | ------- | ---------- |
width = 4 bytes
RISC-V uses byte-addressable memory, which we’ll talk about next.
| 27  | Digital Design & Computer Architecture |     |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | --- | ------------ |

Reading Word-Addressable Memory
|     | • Memory read called load  |     |
| --- | -------------------------- | --- |
|     | • Mnemonic: load word (lw) |     |
|     | • Format:                  |     |
  lw t1, 5(s0)
  lw destination, offset(base)
|     | • Address calculation: |     |
| --- | ---------------------- | --- |
add base address (s0) to the offset (5)
–
address = (s0 + 5)
–
|     | • Result: |     |
| --- | --------- | --- |
– t1 holds the data value at address (s0 + 5)
Any register may be used as base address

| 28  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Reading Word-Addressable Memory
|     | • Example: read a word of data at memory  |     |     |     |     |
| --- | ----------------------------------------- | --- | --- | --- | --- |
address 1 into s3
– address = (0 + 1) = 1
– s3 = 0xF2F1AC07 after load
Assembly code
lw s3, 1(zero) # read memory word 1 into s3
|     |                                        | Word Address |     | Data  | Word Number  |
| --- | -------------------------------------- | ------------ | --- | ----- | ------------ |
|     |                                        | 00000004     | C D | 1 9 A | 6 5 B Word 4 |
|     |                                        | 00000003     | 4 0 | F 3 0 | 7 8 8 Word 3 |
|     |                                        | 00000002     | 0 1 | E E 2 | 8 4 2 Word 2 |
|     |                                        | 00000001     | F 2 | F 1 A | C 0 7 Word 1 |
|     |                                        | 00000000     | A B | C D E | F 7 8 Word 0 |
| 29  | Digital Design & Computer Architecture |              |     |       | Architecture |

Writing Word-Addressable Memory
|     | • Memory write is called a store       |              |
| --- | -------------------------------------- | ------------ |
|     | • Mnemonic: store word (sw)            |              |
| 30  | Digital Design & Computer Architecture | Architecture |

Writing Word-Addressable
Memory
Example: Write (store) the value in t4 into
•
memory address 3
add the base address (zero) to the offset (0x3)
–
– address: (0 + 0x3) = 3
– for example, if t4 holds the value 0xFEEDCABB, then after this
instruction completes, word 3 in memory will contain that value
Assembly code
Offset can be
sw t4, 0x3(zero)  # write the value in t4
written in
                  # to memory word 3
decimal
(default) or  WWoorrdd  AAddddrreessss DDaattaa WWoorrdd  NNuummbbeerr
hexadecimal
|     |                                        |                  | CC DD 11 | 99 AA 66 55 | BB              |
| --- | -------------------------------------- | ---------------- | -------- | ----------- | --------------- |
|     |                                        | 0000000000000044 |          |             | WWoorrdd  44    |
|     |                                        | 0000000000000033 | 4F 0E FE | 3D C0 A7 B8 | B8 WWoorrdd  33 |
|     |                                        | 0000000000000022 | 00 11 EE | EE 22 88 44 | 22 WWoorrdd  22 |
|     |                                        | 0000000000000011 | FF 22 FF | 11 AA CC 00 | 77 WWoorrdd  11 |
|     |                                        | 0000000000000000 | AA BB CC | DD EE FF 77 | 88 WWoorrdd  00 |
| 31  | Digital Design & Computer Architecture |                  |          |             | Architecture    |

Byte-Addressable Memory
|     | • Each data byte has a unique address               |     |     |     |     |     |     |
| --- | --------------------------------------------------- | --- | --- | --- | --- | --- | --- |
|     | • Load/store words or single bytes: load byte (lb)  |     |     |     |     |     |     |
and store byte (sb)
|     | • 32-bit word = 4 bytes, so word address increments  |     |     |     |     |     |     |
| --- | ---------------------------------------------------- | --- | --- | --- | --- | --- | --- |
by 4
|     |     | Byte Address |       | Word Address |     | Data  | Word Number  |
| --- | --- | ------------ | ----- | ------------ | --- | ----- | ------------ |
|     |     | 13 12        | 11 10 | 00000010     | C D | 1 9 A | 6 5 B Word 4 |
|     |     | F E          | D C   | 0000000C     | 4 0 | F 3 0 | 7 8 8 Word 3 |
|     |     | B A          | 9 8   | 00000008     | 0 1 | E E 2 | 8 4 2 Word 2 |
|     |     | 7 6          | 5 4   | 00000004     | F 2 | F 1 A | C 0 7        |
Word 1
|     |     | 3 2 | 1 0 | 00000000 | A B | C D E | F 7 8 Word 0 |
| --- | --- | --- | --- | -------- | --- | ----- | ------------ |
|     |     | MSB | LSB |          |     |       |              |
width = 4 bytes
| 32  | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- |

Reading Byte-Addressable Memory
|     | • The address of a memory word must now be  |     |
| --- | ------------------------------------------- | --- |
multiplied by 4.  For example,
– the address of memory word 2 is 2 × 4 = 8
the address of memory word 10 is 10 × 4 = 40
–
(0x28)
|     | • RISC-V is byte-addressed, not word- |     |
| --- | ------------------------------------- | --- |
addressed
| 33  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Reading Byte-Addressable Memory
|     | • Example: Load a word of data at memory  |     |     |     |     |     |     |
| --- | ----------------------------------------- | --- | --- | --- | --- | --- | --- |
address 8 into s3.
|     | • s3 holds the value 0x1EE2842 after load |     |     |     |     |     |     |
| --- | ----------------------------------------- | --- | --- | --- | --- | --- | --- |
RISC-V assembly code
lw s3, 8(zero)  # read word at address 8 into s3
|     |     | Byte Address |       | Word Address |     | Data  | Word Number  |
| --- | --- | ------------ | ----- | ------------ | --- | ----- | ------------ |
|     |     | 13 12        | 11 10 | 00000010     | C D | 1 9 A | 6 5 B Word 4 |
|     |     | F E          | D C   | 0000000C     | 4 0 | F 3 0 | 7 8 8 Word 3 |
|     |     | B A          | 9 8   | 00000008     | 0 1 | E E 2 | 8 4 2 Word 2 |
|     |     | 7 6          | 5 4   | 00000004     | F 2 | F 1 A | C 0 7        |
Word 1
|     |     | 3 2 | 1 0 | 00000000 | A B | C D E | F 7 8 Word 0 |
| --- | --- | --- | --- | -------- | --- | ----- | ------------ |
|     |     | MSB | LSB |          |     |       |              |
width = 4 bytes
| 34  | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- |

Writing Byte-Addressable Memory
• Example: store the value held in t7 into memory address
0x10 (16)
– if t7 holds the value 0xAABBCCDD, then after the sw completes,
word 4 (at address 0x10) in memory will contain that value
RISC-V assembly code
sw t7, 0x10(zero) # write t7 into address 16
BByyttee AAddddrreessss WWoorrdd AAddddrreessss DDaattaa WWoorrdd NNuummbbeerr
1133 1122 1111 1100 0000000000001100 AC AD B1 B9 CA C6 D5 DB WWoorrdd 44
FF EE DD CC 00000000000000CC 44 00 FF 33 00 77 88 88 WWoorrdd 33
BB AA 99 88 0000000000000088 00 11 EE EE 22 88 44 22 WWoorrdd 22
77 66 55 44 0000000000000044 FF 22 FF 11 AA CC 00 77 WWoorrdd 11
33 22 11 00 0000000000000000 AA BB CC DD EE FF 77 88 WWoorrdd 00
MMSSBB LLSSBB
wwiiddtthh == 44 bbyytteess
35 Digital Design & Computer Architecture Architecture

Chapter 6: Architecture
Generating Constants

Generating 12-Bit Constants
|     | • 12-bit signed constants (immediates) using  |     |
| --- | --------------------------------------------- | --- |
addi:
C Code RISC-V assembly code
// int is a 32-bit signed word # s0 = a, s1 = b
int a = -372; addi s0, zero, -372
int b = a + 6; addi s1, s0, 6
Any immediate that needs more than 12 bits
cannot use this method.
| 37  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Generating 32-bit Constants
Use load upper immediate (lui) and addi
•
|     | • lui: puts an immediate in the upper 20 bits  |     |
| --- | ---------------------------------------------- | --- |
of destination register and 0’s in lower 12
bits

|     | C Code | RISC-V assembly code |
| --- | ------ | -------------------- |
# s0 = a
|     | int a = 0xFEDC8765; | lui  s0, 0xFEDC8 |
| --- | ------------------- | ---------------- |
addi s0, s0, 0x765
Remember that addi sign-extends its 12-bit
immediate
| 38  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Generating 32-bit Constants
|     | • If bit 11 of 32-bit constant is 1, increment  |     |     |     |     |
| --- | ----------------------------------------------- | --- | --- | --- | --- |
upper 20 bits by 1 in lui
C Code
Note: -341 = 0xEAB
int a = 0xFEDC8EAB;
RISC-V assembly code
# s0 = a
|     | lui  s0, 0xFEDC9                       |     |     | # s0 = 0xFEDC9000              |              |
| --- | -------------------------------------- | --- | --- | ------------------------------ | ------------ |
|     | addi s0, s0, -341                      |     |     | # s0 = 0xFEDC9000 + 0xFFFFFEAB |              |
|     |                                        |     |     | #    = 0xFEDC8EAB              |              |
| 39  | Digital Design & Computer Architecture |     |     |                                | Architecture |

Chapter 6: Architecture
Logical / Shift
Instructions

Programming
|     | • High-level languages:  |     |
| --- | ------------------------ | --- |
– e.g., C, Java, Python
– Written at higher level of abstraction
|     | • High-level constructs: loops, conditional  |     |
| --- | -------------------------------------------- | --- |
statements, arrays, function calls
|     | • First, introduce instructions that support  |     |
| --- | --------------------------------------------- | --- |
these:
– Logical operations
– Shift instructions
– Multiplication & division
– Branches & Jumps
| 41  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Ada Lovelace, 1815-1852
| •   | Wrote the first  |     |
| --- | ---------------- | --- |
computer program
| •   | Her program calculated  |     |
| --- | ----------------------- | --- |
the Bernoulli numbers
on Charles Babbage’s
Analytical Engine
| •   | She was the daughter  |     |
| --- | --------------------- | --- |
of the poet Lord Byron
| 42  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Logical Instructions
• and, or, xor
– and: useful for masking bits
• Masking all but the least significant byte of a value:
0xF234012F AND 0x000000FF = 0x0000002F
– or: useful for combining bit fields
• Combine 0xF2340000 with 0x000012BC:
0xF2340000 OR 0x000012BC = 0xF23412BC
– xor: useful for inverting bits:
• A XOR -1 = NOT A (remember that -1 = 0xFFFFFFFF)
43 Digital Design & Computer Architecture Architecture

Logical Instructions: Example 1
|     |     |     | S o u r | c e   R e g | i s t e r s |
| --- | --- | --- | ------- | ----------- | ----------- |
s 1 0 1 0 0   0 1 1 0 1 0 1 0   0 0 0 1 1 1 1 1   0 0 0 1 1 0 1 1   0 1 1 1
s 2 1 1 1 1   1 1 1 1 1 1 1 1   1 1 1 1 0 0 0 0   0 0 0 0 0 0 0 0   0 0 0 0
|     | A s s e m b l y   C | o d e |     | R e s u l | t   |
| --- | ------------------- | ----- | --- | --------- | --- |
a n d   s 3 ,   s 1 ,   s 2 s 3 0 1 0 0   0 1 1 0 1 0 1 0   0 0 0 1 0 0 0 0   0 0 0 0 0 0 0 0   0 0 0 0
o r     s 4 ,   s 1 ,   s 2 s 4 1 1 1 1   1 1 1 1 1 1 1 1   1 1 1 1 1 1 1 1   0 0 0 1 1 0 1 1   0 1 1 1
x o r   s 5 ,   s 1 ,   s 2 s 5 1 0 1 1   1 0 0 1 0 1 0 1   1 1 1 0 1 1 1 1   0 0 0 1 1 0 1 1   0 1 1 1
| 44  | Digital Design & Computer Architecture |     | Architecture |     |     |
| --- | -------------------------------------- | --- | ------------ | --- | --- |

Logical Instructions: Example 2
Source Values
t3 0011 1010 0111 0101 0000 1101 0110 1111
imm 1111 1111 1111 1111 1111 1010 0011 0100
sign-extended
Assembly Code Result
andi s5, t3, -1484 s5 0011 1010 0111 0101 0000 1000 0010 0100
ori s6, t3, -1484 s6 1111 1111 1111 1111 1111 1111 0111 1111
xori s7, t3, -1484 s7 1100 0101 1000 1010 1111 0111 0101 1011
-1484 = 0xA34 in 12-bit 2’s complement representation.
45 Digital Design & Computer Architecture Architecture

Shift Instructions
Shift amount is in (lower 5 bits of) a register
|     | • sll: shift left logical |     |
| --- | ------------------------- | --- |
– Example:  sll t0, t1, t2 # t0 = t1 << t2
|     | • srl: shift right logical |     |
| --- | -------------------------- | --- |
Example:  srl t0, t1, t2 # t0 = t1 >> t2
–
|     | • sra: shift right arithmetic |     |
| --- | ----------------------------- | --- |
– Example:  sra t0, t1, t2 # t0 = t1 >>> t2
| 46  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Immediate Shift Instructions
Shift amount is an immediate between 0 to 31
|     | • slli: shift left logical immediate |     |
| --- | ------------------------------------ | --- |
– Example:  slli t0, t1, 23 # t0 = t1 << 23
|     | • srli: shift right logical immediate |     |
| --- | ------------------------------------- | --- |
Example:  srli t0, t1, 18 # t0 = t1 >> 18
–
|     | • srai: shift right arithmetic immediate |     |
| --- | ---------------------------------------- | --- |
– Example:  srai t0, t1, 5 # t0 = t1 >>> 5
| 47  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Chapter 6: Architecture
Multiplication and
Division

Multiplication
32 × 32 multiplication → 64 bit result
mul s3, s1, s2
  s3 = lower 32 bits of result
mulh s4, s1, s2
  s4 = upper 32 bits of result, treats operands as signed
{s4, s3} = s1 x s2
Example:
s1 = 0x40000000 = 230; s2 = 0x80000000 = -231
|     |     |     | s1 x s2 = -261 = 0xE0000000 00000000 |     |
| --- | --- | --- | ------------------------------------ | --- |
|     |     |     | s4  = 0xE0000000; s3 = 0x00000000    |     |

| 49  | Digital Design & Computer Architecture |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | ------------ |

Division
32-bit division → 32-bit quotient & remainder
|     | –   | div  s3, s1, s2  # s3 = s1/s2 |     |     |
| --- | --- | ----------------------------- | --- | --- |
|     | –   | rem  s4, s1, s2  # s4 = s1%s2 |     |     |
Example:
s1 = 0x00000011 = 17; s2 = 0x00000003 = 3
|     |                                        |     | s1 / s2 = 5                       |              |
| --- | -------------------------------------- | --- | --------------------------------- | ------------ |
|     |                                        |     | s1 % s2 = 2                       |              |
|     |                                        |     | s3  = 0x00000005; s4 = 0x00000002 |              |
| 50  | Digital Design & Computer Architecture |     |                                   | Architecture |

Chapter 6: Architecture
Branches & Jumps

Branching
• Execute instructions out of sequence
• Types of branches:
– Conditional
• branch if equal (beq)
• branch if not equal (bne)
• branch if less than (blt)
• branch if greater than or equal (bge)
– Unconditional
• jump (j)
We’ll talk
• jump register (jr)
about these
• jump and link (jal) when discuss
function calls
• jump and link register (jalr)
52 Digital Design & Computer Architecture Architecture

Conditional Branching
# RISC-V assembly
|     |  addi s0, zero, 4     |     |     | # s0 = 0 + 4 = 4  |     |
| --- | --------------------- | --- | --- | ----------------- | --- |
|     |  addi s1, zero, 1     |     |     | # s1 = 0 + 1 = 1  |     |
|     |  slli s1, s1, 2       |     |     | # s1 = 1 << 2 = 4 |     |
|     |  beq  s0, s1, target  |     |     | # branch is taken |     |
 addi s1, s1, 1         # not executed
|     |  sub  s1, s1, s0    |     |     | # not executed   |     |
| --- | ------------------- | --- | --- | ---------------- | --- |
|     | target:             |     |     | # label          |     |
|     |  add  s1, s1, s0    |     |     | # s1 = 4 + 4 = 8 |     |
Labels indicate instruction location. They can’t be reserved words and
must be followed by a colon (:)
| 53  | Digital Design & Computer Architecture |     |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | --- | ------------ |

The Branch Not Taken (bne)
# RISC-V assembly

|     |    addi  | s0, zero, 4         # s0 = 0 + 4 = 4  |                      |
| --- | -------- | ------------------------------------- | -------------------- |
|     |    addi  | s1, zero, 1         # s1 = 0 + 1 = 1  |                      |
|     |    slli  | s1, s1, 2           # s1 = 1 << 2 = 4 |                      |
|     |    bne   | s0, s1, target                        |   # branch not taken |
|     |    addi  | s1, s1, 1                             |   # s1 = 4 + 1 = 5   |
|     |    sub   | s1, s1, s0                            |   # s1 = 5 – 4 = 1   |
target:
|     |    add                                 | s1, s1, s0   |   # s1 = 1 + 4 = 5 |
| --- | -------------------------------------- | ------------ | ------------------ |
| 54  | Digital Design & Computer Architecture |              | Architecture       |

Unconditional Branching (j)
# RISC-V assembly
|     |    j        target       |     | # jump to target |
| --- | ------------------------ | --- | ---------------- |
   srai     s1, s1, 2        # not executed
   addi     s1, s1, 1        # not executed
|     |    sub      s1, s1, s0   |     | # not executed |
| --- | ------------------------ | --- | -------------- |
  target:
|     |    add                                 | s1, s1, s0   | # s1 = 1 + 4 = 5 |
| --- | -------------------------------------- | ------------ | ---------------- |
| 55  | Digital Design & Computer Architecture |              | Architecture     |

Chapter 6: Architecture
Conditional
Statements & Loops

Conditional Statements & Loops
•
Conditional Statements
– if statements
– if/else statements
|     | • Loops |     |
| --- | ------- | --- |
– while loops
– for loops
| 57  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

If Statement
C Code RISC-V assembly code
# s0 = f, s1 = g, s2 = h
# s3 = i, s4 = j
if (i == j) bne s3, s4, L1
f = g + h; add s0, s1, s2
L1:
f = f – i; sub s0, s0, s3
Assembly tests opposite case (i != j) of high-level code (i == j)
58 Digital Design & Computer Architecture Architecture

If/Else Statement
C Code RISC-V assembly code
# s0 = f, s1 = g, s2 = h
# s3 = i, s4 = j
if (i == j) bne s3, s4, L1
f = g + h; add s0, s1, s2
j done
else L1:
f = f – i; sub s0, s0, s3
done:
Assembly tests opposite case (i != j) of high-level code (i == j)
59 Digital Design & Computer Architecture Architecture

While Loops
|     | C Code RISC-V assembly code                |     |
| --- | ------------------------------------------ | --- |
|     | // determines the power # s0 = pow, s1 = x |     |
// of x such that 2x = 128
|     | int pow = 1;        addi s0, zero, 1    |     |
| --- | --------------------------------------- | --- |
|     | int x   = 0;        add  s1, zero, zero |     |
       addi t0, zero, 128
|     | while (pow != 128) { while:               |     |
| --- | ----------------------------------------- | --- |
|     |   pow = pow * 2;        beq  s0, t0, done |     |
|     |   x = x + 1;        slli s0, s0, 1        |     |
|     | }        addi s1, s1, 1                   |     |
       j    while
done:
Assembly tests opposite case (pow == 128) of high-level code
( pow != 128)
| 60  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

For Loops
for (initialization; condition; loop operation)
    statement
| •   | initialization: executes before the loop begins         |              |
| --- | ------------------------------------------------------- | ------------ |
| •   | condition: is tested at the beginning of each iteration |              |
| •   | loop operation: executes at the end of each iteration   |              |
| •   | statement: executes each time the condition is met      |              |
| 61  | Digital Design & Computer Architecture                  | Architecture |

For Loops
|     | C Code                         | RISC-V assembly code       |
| --- | ------------------------------ | -------------------------- |
|     | // add the numbers from 0 to 9 | # s0 = i, s1 = sum         |
|     | int sum = 0;                   |        addi s1, zero, 0    |
|     | int i;                         |        add  s0, zero, zero |
       addi t0, zero, 10
|     | for (i=0; i!=10; i = i+1) { | for:                     |
| --- | --------------------------- | ------------------------ |
|     |   sum = sum + i;            |        beq  s0, t0, done |
|     | }                           |        add  s1, s1, s0   |
       addi s0, s0, 1
       j    for
done:
| 62  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Less Than Comparison
|     | C Code                         | RISC-V assembly code       |
| --- | ------------------------------ | -------------------------- |
|     | // add the powers of 2 from 1  | # s0 = i, s1 = sum         |
|     | // to 100                      |        addi  s1, zero, 0   |
|     | int sum = 0;                   |        addi  s0, zero, 1   |
|     | int i;                         |        addi  t0, zero, 101 |
loop:
|     | for (i=1; i < 101; i = i*2) { |        bge   s0, t0, done |
| --- | ----------------------------- | ------------------------- |
|     |   sum = sum + i;              |        add   s1, s1, s0   |
|     | }                             |        slli  s0, s0, 1    |
       j     loop
done:
| 63  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Less Than Comparison: Version 2
| C Code                         |     | RISC-V assembly code       |
| ------------------------------ | --- | -------------------------- |
| // add the powers of 2 from 1  |     | # s0 = i, s1 = sum         |
| // to 100                      |     |        addi  s1, zero, 0   |
| int sum = 0;                   |     |        addi  s0, zero, 1   |
| int i;                         |     |        addi  t0, zero, 101 |
loop:
for (i=1; i < 101; i = i*2) {
       slt   t2, s0, t0
|   sum = sum + i; |     |        beq   t2, zero, done |
| ---------------- | --- | --------------------------- |
| }                |     |        add   s1, s1, s0     |
       slli  s0, s0, 1
       j     loop
done:
slt: set if less than instruction
slt t2, s0, t0   # if s0 < t0, t2 = 1
                                        # otherwise  t2 = 0
| 64  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Chapter 6: Architecture
Arrays

Arrays
|     | • Access large amounts of similar data |              |
| --- | -------------------------------------- | ------------ |
|     | • Index: access each element           |              |
|     | • Size: number of elements             |              |
| 66  | Digital Design & Computer Architecture | Architecture |

Arrays
|     | • 5-element array                              |     |
| --- | ---------------------------------------------- | --- |
|     | • Base address = 0x123B4780 (address of first  |     |
element, array[0])
|     | • First step in accessing an array: load base  |     |
| --- | ---------------------------------------------- | --- |
address into a register
Data
Address
123B4790 array[4]
123B478C array[3]
123B4788 array[2]
123B4784 array[1]
123B4780 array[0]
Main Memory
| 67  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Accessing Arrays
// C Code
int array[5];
array[0] = array[0] * 2;
array[1] = array[1] * 2;
# RISC-V assembly code
# s0 = array base address
lui s0, 0x123B4 # 0x123B4 in upper 20 bits of s0
addi s0, s0, 0x780 # s0 = 0x123B4780
lw t1, 0(s0) # t1 = array[0]
slli t1, t1, 1 # t1 = t1 * 2
sw t1, 0(s0) # array[0] = t1
lw t1, 4(s0) # t1 = array[1]
slli t1, t1, 1 # t1 = t1 * 2
sw t1, 4(s0) # array[1] = t1
68 Digital Design & Computer Architecture Architecture
1
1
1
1
1
A
2
2
2
2
2
d
3
3
3
3
3
d
B
B
B
B
B
r e s s
4 7 9
4 7 8
4 7 8
4 7 8
4 7 8
0
C
8
4
0
a
a
a
a
a
r
r
r
r
r
M
D
r
r
r
r
r
a
a t a
a y [
a y [
a y [
a y [
a y [
in M
4
3
2
1
0
e
]
]
]
]
]
m o r y

Accessing Arrays Using For Loops
// C Code
|     |   int array[1000];               |     |
| --- | -------------------------------- | --- |
|     |   int i;                         |     |
|     |   for (i=0; i < 1000; i = i + 1) |     |
|     |      array[i] = array[i] * 8;    |     |
# RISC-V assembly code
# s0 = array base address, s1 = i
| 69  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Accessing Arrays Using For Loops
# RISC-V assembly code
# s0 = array base address, s1 = i
# initialization code
lui s0, 0x23B8F # s0 = 0x23B8F000
ori s0, s0, 0x400 # s0 = 0x23B8F400
addi s1, zero, 0 # i = 0
addi t2, zero, 1000 # t2 = 1000
loop:
bge s1, t2, done # if not then done
slli t0, s1, 2 # t0 = i * 4 (byte offset)
add t0, t0, s0 # address of array[i]
lw t1, 0(t0) # t1 = array[i]
slli t1, t1, 3 # t1 = array[i] * 8
sw t1, 0(t0) # array[i] = array[i] * 8
addi s1, s1, 1 # i = i + 1
j loop # repeat
done:
70 Digital Design & Computer Architecture Architecture

ASCII Code
• ASCII: American Standard Code for
Information Interchange
• Each text character has unique byte
value
– For example, S = 0x53, a = 0x61, A = 0x41
– Lower-case and upper-case differ by 0x20 (32)
71 Digital Design & Computer Architecture Architecture

Cast of Characters: ASCII Encodings
|     | # Char                                 | # Char | # Char | # Char       | # Char | # Char |
| --- | -------------------------------------- | ------ | ------ | ------------ | ------ | ------ |
|     | 20 space                               | 30 0   | 40 @   | 50 P         | 60 `   | 70 p   |
|     | 21 !                                   | 31 1   | 41 A   | 51 Q         | 61 a   | 71 q   |
|     | 22 “                                   | 32 2   | 42 B   | 52 R         | 62 b   | 72 r   |
|     | 23 #                                   | 33 3   | 43 C   | 53 S         | 63 c   | 73 s   |
|     | 24 $                                   | 34 4   | 44 D   | 54 T         | 64 d   | 74 t   |
|     | 25 %                                   | 35 5   | 45 E   | 55 U         | 65 e   | 75 u   |
|     | 26 &                                   | 36 6   | 46 F   | 56 V         | 66 f   | 76 v   |
|     | 27 ‘                                   | 37 7   | 47 G   | 57 W         | 67 g   | 77 w   |
|     | 28 (                                   | 38 8   | 48 H   | 58 X         | 68 h   | 78 x   |
|     | 29 )                                   | 39 9   | 49 I   | 59 Y         | 69 i   | 79 y   |
|     | 2A *                                   | 3A :   | 4A J   | 5A Z         | 6A j   | 7A z   |
|     | 2B +                                   | 3B ;   | 4B K   | 5B [         | 6B k   | 7B {   |
|     | 2C ,                                   | 3C <   | 4C L   | 5C \         | 6C l   | 7C |   |
|     | 2D -                                   | 3D =   | 4D M   | 5D ]         | 6D m   | 7D }   |
|     | 2E .                                   | 3E >   | 4E N   | 5E ^         | 6E n   | 7E ~   |
|     | 2F /                                   | 3F ?   | 4F O   | 5F _         | 6F o   |        |
| 72  | Digital Design & Computer Architecture |        |        | Architecture |        |        |

Accessing Arrays of Characters
// C Code
|     |   char str[80] = “CAT”;       |     |
| --- | ----------------------------- | --- |
|     |   int len = 0;                |     |
|     |   // compute length of string |     |
   while (str[len]) len++;
# RISC-V assembly code
# s0 = array base address, s1 = len
        addi s1, zero, 0         # len = 0
while:  add t0, s0, s1         # address of str[len]
        lw t1, 0(t0)             # load str[len]
        beq  t1, zero, done      # are we at the end of the string?
        addi s1, s1, 1           # len++
        j while                  # repeat while loop
done:
| 73  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Chapter 6: Architecture
Function Calls

Function Calls
|     | • Caller: calling function (in this case, main) |     |
| --- | ----------------------------------------------- | --- |
|     | • Callee: called function (in this case, sum)   |     |
C Code
void main()
{
  int y;
  y = sum(42, 7);
  ...
}
int sum(int a, int b)
{
  return (a + b);
}
| 75  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Simple Function Call
| C Code |     | RISC-V assembly code |     |     |
| ------ | --- | -------------------- | --- | --- |
int main() {
|   simple();  |     | 0x00000300 main:   jal  simple      # call |          |     |
| ------------ | --- | ------------------------------------------ | -------- | --- |
|   a = b + c; |     | 0x00000304         add  s0, s1, s2         |          |     |
| }            |     | ...                                        |      ... |     |
void simple() {
|   return; |     | 0x0000051c simple: jr   ra     |     |  # return |
| --------- | --- | ------------------------------ | --- | --------- |
}
void means that simple doesn’t return a value
jal simple:
  ra = PC + 4 (0x00000304)
jumps to simple label (PC = 0x0000051c)

jr ra:
PC = ra (0x00000304)

| 76  | Digital Design & Computer Architecture |     | Architecture |     |
| --- | -------------------------------------- | --- | ------------ | --- |

Function Calling Conventions
• Caller:
– passes arguments to callee
– jumps to callee
• Callee:
– performs the function
– returns result to caller
– returns to point of call
– must not overwrite registers or memory needed by
caller
77 Digital Design & Computer Architecture Architecture

RISC-V Function Calling Conventions
|     | • Call Function: jump and link (jal func)     |              |
| --- | --------------------------------------------- | ------------ |
|     | • Return from function: jump register (jr ra) |              |
|     | • Arguments: a0 – a7                          |              |
|     | • Return value: a0                            |              |
| 78  | Digital Design & Computer Architecture        | Architecture |

Input Arguments & Return Value
C Code
int main()
{
int y;
...
y = diffofsums(2, 3, 4, 5); // 4 arguments
...
}
int diffofsums(int f, int g, int h, int i)
{
int result;
result = (f + g) - (h + i);
return result; // return value
}
79 Digital Design & Computer Architecture Architecture

Input Arguments & Return Value
RISC-V assembly code
# s7 = y
main:
. . .
addi a0, zero, 2 # argument 0 = 2
addi a1, zero, 3 # argument 1 = 3
addi a2, zero, 4 # argument 2 = 4
addi a3, zero, 5 # argument 3 = 5
jal diffofsums # call function
add s7, a0, zero # y = returned value
. . .
# s3 = result
diffofsums:
add t0, a0, a1 # t0 = f + g
add t1, a2, a3 # t1 = h + i
sub s3, t0, t1 # result = (f + g) − (h + i)
add a0, s3, zero # put return value in a0
jr ra # return to caller
80 Digital Design & Computer Architecture Architecture

Input Arguments & Return Value
RISC-V assembly code
# s3 = result
diffofsums:
add t0, a0, a1 # t0 = f + g
add t1, a2, a3 # t1 = h + i
sub s3, t0, t1 # result = (f + g) − (h + i)
add a0, s3, zero # put return value in a0
jr ra # return to caller
• diffofsums overwrote 3 registers: t0, t1, s3
•diffofsums can use stack to temporarily store registers
81 Digital Design & Computer Architecture Architecture

Chapter 6: Architecture
The Stack

The Stack
|     | • Memory used to temporarily  |     |
| --- | ----------------------------- | --- |
save variables
|     | • Like stack of dishes, last-in- |     |
| --- | -------------------------------- | --- |
first-out (LIFO) queue
|     | • Expands: uses more memory  |     |
| --- | ---------------------------- | --- |
when more space needed
|     | • Contracts: uses less memory  |     |
| --- | ------------------------------ | --- |
when the space is no longer
needed
| 83  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

The Stack
|     | • Grows down (from higher to lower memory  |     |     |     |     |     |
| --- | ------------------------------------------ | --- | --- | --- | --- | --- |
addresses)
|     | • Stack pointer: sp points to top of the stack |          |     |          |          |     |
| --- | ---------------------------------------------- | -------- | --- | -------- | -------- | --- |
|     | Address                                        | Data     |     | Address  | Data     |     |
|     | BEFFFAE8                                       | AB000001 | sp  | BEFFFAE8 | AB000001 |     |
|     | BEFFFAE4                                       |          |     | BEFFFAE4 | 12345678 |     |
FFEEDDCC
|     | BEFFFAE0 |     |     | BEFFFAE0 |     | sp  |
| --- | -------- | --- | --- | -------- | --- | --- |
|     | BEFFFADC |     |     | BEFFFADC |     |     |
Make room on stack for 2 words.
| 84  | Digital Design & Computer Architecture |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | ------------ | --- | --- |

How Functions use the Stack
|     | • Called functions must have no unintended  |     |
| --- | ------------------------------------------- | --- |
side effects
|     | • But diffofsums overwrites 3 registers: t0,  |     |
| --- | --------------------------------------------- | --- |
t1, s3
# RISC-V assembly
# s3 = result
diffofsums:
  add  t0, a0, a1   # t0 = f + g
  add  t1, a2, a3   # t1 = h + i
  sub  s3, t0, t1   # result = (f + g) − (h + i)
  add  a0, s3, zero # put return value in a0
  jr   ra           # return to caller
| 85  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Storing Register Values on the Stack
# s3 = result
diffofsums:
addi sp, sp, -12 # make space on stack to
# store three registers
sw s3, 8(sp) # save s3 on stack
sw t0, 4(sp) # save t0 on stack
sw t1, 0(sp) # save t1 on stack
add t0, a0, a1 # t0 = f + g
add t1, a2, a3 # t1 = h + i
sub s3, t0, t1 # result = (f + g) − (h + i)
add a0, s3, zero # put return value in a0
lw s3, 8(sp) # restore s3 from stack
lw t0, 4(sp) # restore t0 from stack
lw t1, 0(sp) # restore t1 from stack
addi sp, sp, 12 # deallocate stack space
jr ra # return to caller
86 Digital Design & Computer Architecture Architecture

The Stack During diffofsums Call
| Address  |     | Data |     | Address    | Data |     |     | Address  | Data |     |
| -------- | --- | ---- | --- | ---------- | ---- | --- | --- | -------- | ---- | --- |
| BEF0F0FC |     | ?    | sp  | BEF0F0FC   |      | ?   |     | BEF0F0FC | ?    | sp  |
| BEF0F0F8 |     |      |     | e BEF0F0F8 |      | s3  |     | BEF0F0F8 |      |     |
m
a
r
| BEF0F0F4 |     |     |     | f BEF0F0F4 |     | t0  |     | BEF0F0F4 |     |     |
| -------- | --- | --- | --- | ---------- | --- | --- | --- | -------- | --- | --- |
  k
c
a
| BEF0F0F0 |     |     |     | BEF0F0F0 |     | t1  | sp  | BEF0F0F0 |     |     |
| -------- | --- | --- | --- | -------- | --- | --- | --- | -------- | --- | --- |
t
s
|     | Before Call                            |     |     |     | During Call |              |     |     | After Call |     |
| --- | -------------------------------------- | --- | --- | --- | ----------- | ------------ | --- | --- | ---------- | --- |
| 87  | Digital Design & Computer Architecture |     |     |     |             | Architecture |     |     |            |     |

Preserved Registers
Preserved Nonpreserved
Callee-Saved Caller-Saved
s0-s11 t0-t6
sp a0-a7
ra
stack above sp stack below sp
88 Digital Design & Computer Architecture Architecture

Storing Saved Registers on the Stack
# s3 = result
diffofsums:
addi sp, sp, -4 # make space on stack to
# store one register
sw s3, 0(sp) # save s3 on stack
add t0, a0, a1 # t0 = f + g
add t1, a2, a3 # t1 = h + i
sub s3, t0, t1 # result = (f + g) − (h + i)
add a0, s3, zero # put return value in a0
lw s3, 0(sp) # restore s3 from stack
addi sp, sp, 4 # deallocate stack space
jr ra # return to caller
89 Digital Design & Computer Architecture Architecture

Optimized diffofsums
# a0 = result
diffofsums:
add t0, a0, a1 # t0 = f + g
add t1, a2, a3 # t1 = h + i
sub a0, t0, t1 # result = (f + g) − (h + i)
jr ra # return to caller
90 Digital Design & Computer Architecture Architecture

Non-Leaf Function Calls
Non-leaf function:
a function that calls another function
func1:
addi sp, sp, -4 # make space on stack
sw ra, 0(sp) # save ra on stack
jal func2
...
lw ra, 0(sp) # restore ra from stack
addi sp, sp, 4 # deallocate stack space
jr ra # return to caller
Must preserve ra before function call.
91 Digital Design & Computer Architecture Architecture

Non-Leaf Function Call Example
# f1 (non-leaf function) uses s4-s5 and needs a0-a1 after call to f2
f1:
addi sp, sp, -20 # make space on stack for 5 words
sw a0, 16(sp)
sw a1, 12(sp)
sw ra, 8(sp) # save ra on stack
sw s4, 4(sp)
sw s5, 0(sp)
jal func2
...
lw ra, 8(sp) # restore ra (and other regs) from stack
...
addi sp, sp, 20 # deallocate stack space
jr ra # return to caller
# f2 (leaf function) only uses s4 and calls no functions
f2:
addi sp, sp, -4 # make space on stack for 1 word
sw s4, 0(sp)
...
lw s4, 0(sp)
addi sp, sp, 4 # deallocate stack space
jr ra # return to caller
92 Digital Design & Computer Architecture Architecture

Stack during Function Calls
A d d r e s s D a t a A d d r e s s D a t a A d d r e s s D a t a
| B E F | 7 F F 0 C | ?   | s p | B E F 7   | F F 0 C | ?   | B E   | F 7 F F 0 C | ?   |     |
| ----- | --------- | --- | --- | --------- | ------- | --- | ----- | ----------- | --- | --- |
| B E F | 7 F F 0 8 |     |     | B E F 7   | F F 0 8 | a 0 | B E   | F 7 F F 0 8 | a 0 |     |
|       |           |     |     | e         |         |     | e     |             |     |     |
|       |           |     |     | m         |         |     | m     |             |     |     |
| B E F | 7 F F 0 4 |     |     | a B E F 7 | F F 0 4 | a 1 | a B E | F 7 F F 0 4 | a 1 |     |
|       |           |     |     | r         |         |     | r     |             |     |     |
|       |           |     |     | f         |         |     | f     |             |     |     |
|       |           |     |     |           |         |     |       |             |     |     |
|       |           |     |     | k         |         |     | k     |             |     |     |
r a
| B E F | 7 F F 0 0 |     |     | c B E F 7 | F F 0 0 |     | c B E | F 7 F F 0 0 | r a |     |
| ----- | --------- | --- | --- | --------- | ------- | --- | ----- | ----------- | --- | --- |
|       |           |     |     | a         |         |     | a     |             |     |     |
|       |           |     |     | t         |         |     | t     |             |     |     |
|       |           |     |     | s         |         |     | s     |             |     |     |
| B E F | 7 F E F C |     |     |   B E F 7 | F E F C | s 4 |   B E | F 7 F E F C | s 4 |     |
|       |           |     |     | s         |         |     | s     |             |     |     |
|       |           |     |     | ' 1       |         |     | ' 1   |             |     |     |
|       |           |     |     | f         |         |     | f     |             |     |     |
B E F 7 F E F 8 B E F 7 F E F 8 s 5 s p   B E F 7 F E F 8 s 5
k
c
e
a
| B E F | 7 F E F 4 |     |     | B E F 7 | F E F 4 |     | m B E | F 7 F E F 4 | s 4 | s p |
| ----- | --------- | --- | --- | ------- | ------- | --- | ----- | ----------- | --- | --- |
t
s a

sr
'f
2
f
B e f o r e   C a l l s A f t e r   C a l l   t o   f 1 A f t e r   C a l l   t o   f 2
| 93  | Digital Design & Computer Architecture |     |     |     |     | Architecture |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- |

Function Call Summary
|     | • Caller |     |
| --- | -------- | --- |
– Save any needed registers (ra, maybe t0-t6/a0-a7)
– Put arguments in a0-a7
Call function: jal callee
–
– Look for result in a0
– Restore any saved registers
|     | • Callee |     |
| --- | -------- | --- |
– Save registers that might be disturbed (s0-s11)
– Perform function
– Put result in a0
– Restore registers
– Return: jr ra
| 94  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Chapter 6: Architecture
Recursive Functions

Recursive Function Example
|     | • Function that calls itself |     |
| --- | ---------------------------- | --- |
•
When converting to assembly code:
–
In the first pass, treat recursive calls as if it’s calling a
different function and ignore overwritten registers.
– Then save/restore registers on stack as needed.
| 96  | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Recursive Function Example
•
Factorial function:
|     | –   | factorial(n) = n!          |                             |     |
| --- | --- | -------------------------- | --------------------------- | --- |
|     |     |                            |    = n*(n-1)*(n-2)*(n-3)…*1 |     |
|     | –   | Example: factorial(6) = 6! |                             |     |
                                          = 6*5*4*3*2*1
                                          = 720
| 97  | Digital Design & Computer Architecture |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | ------------ |

Recursive Function Example
High-Level Code Example: n = 3
int factorial(int n) { factorial(3): returns 3*factorial(2)
if (n <= 1) factorial(2): returns 2*factorial(1)
return 1; factorial(1): returns 1
else
return (n*factorial(n−1));
Thus,
}
factorial(1): returns 1
factorial(2): returns 2*1 = 2
factorial(3): returns 3*2 = 6
98 Digital Design & Computer Architecture Architecture

Recursive Function Example
High-Level Code RISC-V Assembly
int factorial(int n) { factorial:
addi t0, zero, 1 # temporary = 1
if (n <= 1) bgt a0, t0, else # if n>1, go to else
return 1; addi a0, zero, 1 # otherwise, return 1
jr ra # return
else else:
return (n*factorial(n−1)); addi a0, a0, -1 # n = n − 1
} jal factorial # recursive call
n return value: factorial(n-1)
Pass 1. Treat as if calling another
function. Ignore stack.
mul a0, a0, a0 # a0=n*factorial(n−1)
Pass 2. Save overwritten registers
jr ra # return
(needed after function call) on the
stack before call. Problem: n (a0) was overwritten by function call!
Must save it (and ra) on stack before function call.
99 Digital Design & Computer Architecture Architecture

Recursive Function Example
High-Level Code RISC-V Assembly
int factorial(int n) { factorial:
addi sp, sp, -8 # save regs
sw a0, 4(sp)
sw ra, 0(sp)
addi t0, zero, 1 # temporary = 1
if (n <= 1) bgt a0, t0, else # if n>1, go to else
return 1; addi a0, zero, 1 # otherwise, return 1
addi sp, sp, 8 # restore sp
jr ra # return
else else:
return (n*factorial(n−1)); addi a0, a0, -1 # n = n − 1
} jal factorial # recursive call
lw t1, 4(sp) # restore n into t1
lw ra, 0(sp) # restore ra
Pass 1. Treat as if calling another
addi sp, sp, 8 # restore sp
function. Ignore stack.
mul a0, t1, a0 # a0=n*factorial(n−1)
Pass 2. Save overwritten registers
jr ra # return
(needed after function call) on the
stack before call. Note: n is restored from stack into t1 so it doesn’t
overwrite return value in a0.
100 Digital Design & Computer Architecture Architecture

Recursive Functions
0x8500 factorial: addi sp, sp, -8 # save registers
0x8504 sw a0, 4(sp)
0x8508 sw ra, 0(sp)
0x850C addi t0, zero, 1 # temporary = 1
0x8510 bgt a0, t0, else # if n > 1, go to else
0x8514 addi a0, zero, 1 # otherwise, return 1
0x8518 addi sp, sp, 8 # restore sp
0x851C jr ra # return
0x8520 else: addi a0, a0, -1 # n = n − 1
0x8524 jal factorial # recursive call
0x8528 lw t1, 4(sp) # restore n into t1
0x852C lw ra, 0(sp) # restore ra
0x8530 addi sp, sp, 8 # restore sp
0x8534 mul a0, t1, a0 # a0 = n*factorial(n−1)
0x8538 jr ra # return
PC+4 = 0x8528 when factorial is called recursively.
101 Digital Design & Computer Architecture Architecture

Stack During Recursive Function
When factorial(3) is called:
A d d r e s s D a t a A d d r e s s D a t a A d d r e s s D a t a
| F F | 0   | s p | F F          | 0             | s p | F F          | 0             | s p | a 0   =    6        |
| --- | --- | --- | ------------ | ------------- | --- | ------------ | ------------- | --- | ------------------- |
| F E | C   |     | F E          | C a 0   ( 3 ) |     | F E          | C a 0   ( 3 ) |     |                     |
|     |     |     |              |               |     |              |               |     | n   =  3            |
| F E | 8   |     | F E          | 8             | s p | F E          | 8             | s p | a 0   =    3   x  2 |
|     |     |     | semarf kcats | r a           |     | semarf kcats | r a           |     |                     |
| F E | 4   |     | F E          | 4 a 0   ( 2 ) |     | F E          | 4 a 0   ( 2 ) |     |                     |
|     |     |     |              |               |     |              |               |     | n   =  2            |
F E 0 F E 0 r a   ( 0 x 8 5 2 8 ) s p F E 0 r a   ( 0 x 8 5 2 8 ) s p a 0   =    2   x  1
| F D | C   |     | F D | C           |     | F D | C           |     |     |
| --- | --- | --- | --- | ----------- | --- | --- | ----------- | --- | --- |
|     |     |     |     | a 0   ( 1 ) |     |     | a 0   ( 1 ) |     |     |
F D 8 F D 8 r a   ( 0 x 8 5 2 8 ) s p F D 8 r a   ( 0 x 8 5 2 8 ) s p a 0   =  1
B e f o r e   C a l l s A f t e r   R e c u r s i v e   C a l l s R e t u r n i n g   f r o m   C a l l s
| 102 | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- | --- | --- |

Chapter 6: Architecture
More on Jumps &
Pseudoinstructions

Jumps
• RISC-V has two types of unconditional jumps
– Jump and link (jal rd, imm )
20:0
• rd = PC+4; PC = PC + imm
– jump and link register (jalr rd, rs, imm )
11:0
• rd = PC+4; PC = [rs] + SignExt(imm)
104 Digital Design & Computer Architecture Architecture

Pseudoinstructions
|     | • Pseudoinstructions are not actual RISC-V  |     |
| --- | ------------------------------------------- | --- |
instructions but they are often more convenient for
the programmer.
|     | • Assembler converts them to real RISC-V instructions. |              |
| --- | ------------------------------------------------------ | ------------ |
| 105 | Digital Design & Computer Architecture                 | Architecture |

Jump Pseudoinstructions
•
RISC-V has four jump psuedoinstructions
|     | – j   imm                              |     | jal  x0, imm                   |              |
| --- | -------------------------------------- | --- | ------------------------------ | ------------ |
|     | – jal imm                              |     | jal  ra, imm                   |              |
|     | – jr  rs                               |     | jalr x0, rs, 0                 |              |
|     | – ret                                  |     | jr   ra (i.e., jalr x0, ra, 0) |              |
| 106 | Digital Design & Computer Architecture |     |                                | Architecture |

Labels
• Label indicates where to jump
• Represented in jump as immediate offset
– imm = # bytes past jump instruction
– In example, below, imm = (51C-300) = 0x21C
– jal simple = jal ra, 0x21C
RISC-V assembly code
0x00000300 main: jal simple # call
0x00000304 add s0, s1, s1
... ...
0x0000051c simple: jr ra # return
107 Digital Design & Computer Architecture Architecture

Long Jumps
• The immediate is limited in size
– 20 bits for jal, 12 bits for jalr
– Limits how far a program can jump
• Special instruction to help jumping further
– auipc rd, imm: add upper immediate to PC
• rd = PC + {imm , 12’b0}
31:12
• Pseudoinstruction: call imm
31:0
– Behaves like jal imm, but allows 32-bit immediate offset
auipc ra, imm
31:12
jalr ra, ra, imm
11:0
108 Digital Design & Computer Architecture Architecture

More RISC-V Pseudoinstructions
Pseudoinstruction RISC-V Instructions
j label jal zero, label
jr ra jalr zero, ra, 0
mv t5, s3 addi t5, s3, 0
not s7, t2 xori s7, t2, -1
nop addi zero, zero, 0
li s8, 0x56789DEF lui s8, 0x5678A
addi s8, s8, 0xDEF
bgt s1, t3, L3 blt t3, s1, L3
bgez t2, L7 bge t2, zero, L7
call L1 auipc ra, imm
31:12
jalr ra, ra, imm
11:0
ret jalr zero, ra, 0
See Appendix B for more pseudoinstructions.
109 Digital Design & Computer Architecture Architecture

Chapter 6: Architecture
Machine Language

Machine Language
• Binary representation of instructions
• Computers only understand 1’s and 0’s
• 32-bit instructions
– Simplicity favors regularity: 32-bit data &
instructions
• 4 Types of Instruction Formats:
– R-Type
– I-Type
– S/B-Type
– U/J-Type
111 Digital Design & Computer Architecture Architecture

R-Type
|     | • Register-type        |                 |     |                              |                      |     |     |     |     |
| --- | ---------------------- | --------------- | --- | ---------------------------- | -------------------- | --- | --- | --- | --- |
|     | • 3 register operands: |                 |     |                              |                      |     |     |     |     |
|     | –                      | rs1, rs2:       |     |                              | source registers     |     |     |     |     |
|     | –                      | rd:             |     |                              | destination register |     |     |     |     |
|     | • Other fields:        |                 |     |                              |                      |     |     |     |     |
|     | –                      | op:             |     | the operation code or opcode |                      |     |     |     |     |
|     | –                      | funct7,funct3:  |     |                              |                      |     |     |     |     |
|     |                        |                 |     |                              |                      |     |     |     |     |
the function (7 bits and 3-bits, respectively)
|     |     |       |       | with opcode, tells computer what operation to perform |             |       |       |         |       |
| --- | --- | ----- | ----- | ----------------------------------------------------- | ----------- | ----- | ----- | ------- | ----- |
|     |     |       |       |                                                       | R -         | T y p | e     |         |       |
|     |     | 3 1 : | 2 5   | 2 4 : 2                                               | 0 1 9 : 1 5 | 1 4   | : 1 2 | 1 1 : 7 | 6 : 0 |
|     |     | f u n | c t 7 | r s 2                                                 | r s 1       | f u n | c t 3 | r d     | o p   |
7   b i t s 5   b i t s 5   b i t s 3   b i t s 5   b i t s 7   b i t s
| 112 | Digital Design & Computer Architecture |     |     |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | --- | ------------ | --- | --- |

R-Type Examples
A s s e m b l y F i e l d   V a l u e s M a c h i n e   C o d e
f u n c t 7 r s 2 r s 1 f u n c t 3 r d o p f u n c t 7 r s 2 r s 1 f u n c t 3 r d o p
| aa dd dd    sx | 21 ,8  , sx 31 ,9  , sx 42 |       |       |     |     |     |     |     |     |     |     |
| -------------- | -------------------------- | ----- | ----- | --- | --- | --- | --- | --- | --- | --- | --- |
|                |                            | 0 2 0 | 1 9 0 | 1 8 | 5 1 |     |     |     |     |     |     |
0 0 0 0 0  0 0 0 1 0 1 0 0 1 0 0 1 1 0 0 0 1 0 0 1 0 0 1 1  0 0 1 1 ( 0 x 0 1 4 9 8 9 3 3 )
| ss uu bb    tx | 05 ,,    tx 16 ,,    tx 27 | 3 2 7 | 6 0 | 5   | 5 1 |                        |                 |           |                |               |           |
| -------------- | -------------------------- | ----- | --- | --- | --- | ---------------------- | --------------- | --------- | -------------- | ------------- | --------- |
|                |                            |       |     |     | 0   | 1 0 0  0 0 0 0 0 1 1 1 | 0 0 1 1 0 0 0 0 | 0 0 1 0 1 | 0 1 1  0 0 1 1 | ( 0 x 4 0 7 3 | 0 2 B 3 ) |
7  b its 5  b its 5  b its 3  b its 5  b its 7  b its 7  b its 5  b its 5  b its 3  b its 5  b its 7  b its
| 113 | Digital Design & Computer Architecture |     |     |     |     | Architecture |     |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- | --- |

Chapter 6: Architecture
Machine Language:
More Formats

I-Type
• Immediate-type
• 3 operands:
|     | – rs1:  | register source operand      |     |     |     |     |
| --- | ------- | ---------------------------- | --- | --- | --- | --- |
|     | – rd:   | register destination operand |     |     |     |     |
|     | – imm:  |                              |     |     |     |     |
12-bit two’s complement immediate
• Other fields:
|     | – op:  | the opcode |     |     |     |     |
| --- | ------ | ---------- | --- | --- | --- | --- |
– Simplicity favors regularity: all instructions have opcode
|     | – funct3: the function (3-bit function code) |     |     |     |     |     |
| --- | -------------------------------------------- | --- | --- | --- | --- | --- |
– with opcode, tells computer what operation to perform
I-Type
|     |     | 31:20 | 19:15 | 14:12  | 11:7 | 6:0 |
| --- | --- | ----- | ----- | ------ | ---- | --- |
|     |     | imm   | rs1   | funct3 | rd   | op  |
11:0
|     |                                        | 12 bits | 5 bits | 3 bits | 5 bits       | 7 bits |
| --- | -------------------------------------- | ------- | ------ | ------ | ------------ | ------ |
| 115 | Digital Design & Computer Architecture |         |        |        | Architecture |        |

I-Type Examples
116 Digital Design & Computer Architecture Architecture
aaaallllll ddddwwhhbb
A
dddd iiii
s s
sxsxtxsxsx 0821271942
e
,,,8,,,,,0
m
,
,
sxtx--2200
b
19166677xx ,,,,((((11
l y
sxzxFF
11--31e0(( 2211)9r)sx
44
)o
42
)
)0
)
im
0
1
m
1 1
1 2
- 1 4
- 6
2 7
x 1 F
2 b its
:0
F i e l d
r s 1
9
6
1 9
0
2 0
5 b its
V
f u
3
a
n
0
0
2
1
0
b
l u
c t
its
3
e s
5
r d
8
1 8
7
9
2 0
b its 7
o p
1 9
1 9
3
3
3
b its
0
1
1
0
0
0
1
1
0
0
0
1
1
0
0
im
0 0
1 1
1 1
0 0
0 0
1
m
0 0
1 1
1 1
0 0
0 0
2 b
1 1 :0
0 1
1 0
1 1
1 1
1 1
its
1
0
0
0
1
0
1
1
1
1
M
0
0
0
1
1
a
0
0
1
0
1
c
r s
1 0
0 1
0 0
0 0
0 1
5 b
h i
1
0 1
1 0
1 1
0 0
0 0
its
n
f
e
u n
0 0
0 0
0 1
0 0
0 0
3 b
C
c t
0
0
0
1
0
its
o
3
d
0
1
0
0
1
e
r d
1 0
0 0
0 1
1 0
0 1
5 b
0 0
1 0
1 1
0 1
0 0
its
0
0
0
0
0
0
0
0
0
0
1
1
0
0
0
7
o p
0 0
0 0
0 0
0 0
0 0
b its
1
1
1
1
1
1
1
1
1
1
(
(
(
(
(
0
0
0
0
0
x
x
x
x
x
0
F
F
0
0
0
F
F
1
1
C
2
A
B
F
4
3
9
0
A
8
0
A
1
0
4
9
3
4
A
1
1
8
8
0
3
3
3
3
3
)
)
)
)
)

S/B-Type
|     | • Store-Type                        |       |       |        |      |     |        |
| --- | ----------------------------------- | ----- | ----- | ------ | ---- | --- | ------ |
|     | • Branch-Type                       |       |       |        |      |     |        |
|     | • Differ only in immediate encoding |       |       |        |      |     |        |
|     | 31:25                               | 24:20 | 19:15 | 14:12  | 11:7 | 6:0 |        |
|     | imm                                 | rs2   | rs1   | funct3 | imm  | op  | S-Type |
11:5 4:0
B-Type
|     | imm | rs2 | rs1 | funct3 | imm | op  |     |
| --- | --- | --- | --- | ------ | --- | --- | --- |
12,10:5 4:1,11
|     | 7 bits                                 | 5 bits | 5 bits | 3 bits | 5 bits       | 7 bits |     |
| --- | -------------------------------------- | ------ | ------ | ------ | ------------ | ------ | --- |
| 117 | Digital Design & Computer Architecture |        |        |        | Architecture |        |     |

S-Type
|     | • Store-Type  |                              |     |     |     |     |     |
| --- | ------------- | ---------------------------- | --- | --- | --- | --- | --- |
|     | • 3 operands: |                              |     |     |     |     |     |
|     | – rs1:        | base register                |     |     |     |     |     |
|     | – rs2:        | value to be stored to memory |     |     |     |     |     |
|     | – imm:        |                              |     |     |     |     |     |
12-bit two’s complement immediate
|     | • Other fields: |            |     |     |     |     |     |
| --- | --------------- | ---------- | --- | --- | --- | --- | --- |
|     | – op:           | the opcode |     |     |     |     |     |
– Simplicity favors regularity: all instructions have opcode
|     | – funct3: the function (3-bit function code) |     |     |     |     |     |     |
| --- | -------------------------------------------- | --- | --- | --- | --- | --- | --- |
– with opcode, tells computer what operation to perform
S-Type
|     |                                        | 31:25  | 24:20  | 19:15  | 14:12  | 11:7         | 6:0    |
| --- | -------------------------------------- | ------ | ------ | ------ | ------ | ------------ | ------ |
|     |                                        | imm    | rs2    | rs1    | funct3 | imm          | op     |
|     |                                        | 11:5   |        |        |        | 4:0          |        |
|     |                                        | 7 bits | 5 bits | 5 bits | 3 bits | 5 bits       | 7 bits |
| 118 | Digital Design & Computer Architecture |        |        |        |        | Architecture |        |

S-Type Examples
A s s e m b l y F i e l d   V a l u e s M a c h i n e   C o d e
im m r s 2 r s 1 f u n c t 3 im m o p im m r s 2 r s 1 f u n c t 3 im m o p
|                         |                | 1 1 :5 | 4 :0 | 1 1 :5 | 4 :0 |
| ----------------------- | -------------- | ------ | ---- | ------ | ---- |
| ss ww    tx 27 ,,    -- | 66 (( sx 31 )9 |        |      |        |      |
) 1 1 1 1  1 1 1 7 1 9 2 1 1 0 1 0 3 5 1 1 1 1  1 1 1 0 0 1 1 1 1 0 0 1 1 0 1 0 1 1 0 1 0 0 1 0  0 0 1 1 ( 0 x F E 7 9 A D 2 3 )
| ss hh    sx 42 ,0  , 22 | 33 (( tx 05 )) |     |     |     |     |
| ----------------------- | -------------- | --- | --- | --- | --- |
0 0 0 0  0 0 0 2 0 5 1 1 0 1 1 1 3 5 0 0 0 0  0 0 0 1 0 1 0 0 0 0 1 0 1 0 0 1 1 0 1 1 1 0 1 0  0 0 1 1 ( 0 x 0 1 4 2 9 B A 3 )
ss bb    tx 53 ,0  , 00 xx 22 DD (( zx e0 r) o ) 0 0 0 0  0 0 1 3 0 0 0 0 1 1 0 1 3 5 0 0 0 0  0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 1 0  0 0 1 1 ( 0 x 0 3 E 0 0 6 A 3 )
7  b its 5  b its 5  b its 3  b its 5  b its 7  b its 7  b its 5  b its 5  b its 3  b its 5  b its 7  b its
| 119 | Digital Design & Computer Architecture |     |     | Architecture |     |
| --- | -------------------------------------- | --- | --- | ------------ | --- |

B-Type
• Branch-Type (similar format to S-Type)
• 3 operands:
|     | – rs1:  | register source 1                                    |     |     |     |     |     |
| --- | ------- | ---------------------------------------------------- | --- | --- | --- | --- | --- |
|     | – rs2:  | register source 2                                    |     |     |     |     |     |
|     | – imm   | : 12-bit two’s complement immediate – address offset |     |     |     |     |     |
12:1
• Other fields:
|     | – op:  | the opcode |     |     |     |     |     |
| --- | ------ | ---------- | --- | --- | --- | --- | --- |
– Simplicity favors regularity: all instructions have opcode
|     | – funct3: the function (3-bit function code) |     |     |     |     |     |     |
| --- | -------------------------------------------- | --- | --- | --- | --- | --- | --- |
– with opcode, tells computer what operation to perform
|     |                                        |               |            | B -        | T y p e     |              |            |
| --- | -------------------------------------- | ------------- | ---------- | ---------- | ----------- | ------------ | ---------- |
|     |                                        | 3 1 : 2 5     | 2 4 : 2 0  | 1 9 : 1 5  | 1 4 : 1 2   | 1 1 : 7      | 6 : 0      |
|     |                                        | i m m         | r s 2      | r s 1      | f u n c t 3 | i m m        | o p        |
|     |                                        | 1 2 , 1 0 : 5 |            |            |             | 4 :1 , 1 1   |            |
|     |                                        | 7   b it s    | 5   b it s | 5   b it s | 3   b it s  | 5   b it s   | 7   b it s |
| 120 | Digital Design & Computer Architecture |               |            |            |             | Architecture |            |

B-Type Example
• The 13-bit immediate encodes where to branch (relative
to the branch instruction)
• Immediate encoding is strange
• Example:
# RISC-V Assembly
0x70     beq  s0, t5, L1
1
|     |     |     | 0x74     add  s1, s2, s3 |     |     | 2   |     |     |
| --- | --- | --- | ------------------------ | --- | --- | --- | --- | --- |
0x78     sub  s5, s6, s7
3
0x7C     lw   t0, 0(s1)
4
0x80 L1: addi s1, s1, -15

L1 is 4 instructions (i.e., 16 bytes) past beq
|     |     | imm  = 16 | 0    0  0  0 0   0 0 0 1   0 0 0 0 |     |     |     |     |     |
| --- | --- | --------- | ---------------------------------- | --- | --- | --- | --- | --- |
12:0
|          |     | bit number | 12   11 10 9 8   7 6 5 4   3 2 1 0 |            |        |              |            |        |
| -------- | --- | ---------- | ---------------------------------- | ---------- | ------ | ------------ | ---------- | ------ |
| Assembly |     |            | Field Values                       |            |        | Machine Code |            |        |
|          |     | imm        | rs2 rs1                            | funct3 imm | op imm | rs2 rs1      | funct3 imm | op     |
|          |     | 12,10:5    |                                    |            | 4:1,11 | 12,10:5      |            | 4:1,11 |
beq s0, t5,  L1
(0x01E40863)
0000 000 30 8 0 1000 0 99 0000 000 11110 01000 000 1000 0 110 0011
 beq x8, x30, 16
7 bits 5 bits 5 bits 3 bits 5 bits 7 bits 7 bits 5 bits 5 bits 3 bits 5 bits 7 bits
| 121 | Digital Design & Computer Architecture |     |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ | --- | --- |

U/J-Type
• Upper-Immediate-Type
• Jump-Type
• Differ only in immediate encoding
|     |                                        |       | 3 1 : 1 2                 |       | 1 1 : 7      | 6 : 0       |       |       |
| --- | -------------------------------------- | ----- | ------------------------- | ----- | ------------ | ----------- | ----- | ----- |
|     |                                        |       | i m m                     |       | r d          | o p         | U - T | y p e |
|     |                                        |       | 3 1 : 1 2                 |       |              |             |       |       |
|     |                                        | i m m |                           |       | r d          | o p         | J - T | y p e |
|     |                                        |       | 2 0 , 1 0 : 1 , 1 1 , 1 9 | : 1 2 |              |             |       |       |
|     |                                        |       | 2 0   b i t s             |       | 5   b i t s  | 7   b i t s |       |       |
| 122 | Digital Design & Computer Architecture |       |                           |       | Architecture |             |       |       |

U-Type
• Upper-immediate-Type
• Used for load upper immediate (lui)
• 2 operands:
|     | – rd:  | destination register                 |     |     |
| --- | ------ | ------------------------------------ | --- | --- |
|     | – imm  | :upper 20 bits of a 32-bit immediate |     |     |
31:12
• Other fields:
|     | – op:  | the operation code or opcode – tells computer what  |     |     |
| --- | ------ | --------------------------------------------------- | --- | --- |
|     |        | operation to perform                                |     |     |
U-Type
|     |     | 31:12 | 11:7 | 6:0 |
| --- | --- | ----- | ---- | --- |
|     |     | imm   | rd   | op  |
31:12
|     |                                        | 20 bits | 5 bits       | 7 bits |
| --- | -------------------------------------- | ------- | ------------ | ------ |
| 123 | Digital Design & Computer Architecture |         | Architecture |        |

U-Type Example
• Upper-immediate-Type
• Used for load upper immediate (lui)
• 2 operands:
|     | – rd:  | destination register                 |     |     |     |     |     |
| --- | ------ | ------------------------------------ | --- | --- | --- | --- | --- |
|     | – imm  | :upper 20 bits of a 32-bit immediate |     |     |     |     |     |
31:12
• Other fields:
|     | – op:  | the operation code or opcode – tells computer what  |     |     |     |     |     |
| --- | ------ | --------------------------------------------------- | --- | --- | --- | --- | --- |
|     |        | operation to perform                                |     |     |     |     |     |
A s s e m b l y F i e l d   V a l u e s M a c h i n e   C o d e
|     |     | im m | r d | o p | im m | r d | o p |
| --- | --- | ---- | --- | --- | ---- | --- | --- |
3 1 :1 2 3 1 :1 2
| ll uu ii    sx 52 ,1 |  , 00 xx 88 CC DD EE FF |     |     |     |     |     |     |
| -------------------- | ----------------------- | --- | --- | --- | --- | --- | --- |
0 x 8 C D E F 2 1 5 5 1 0 0 0  1 1 0 0   1 1 0 1  1 1 1 0   1 1 1 1 1 0 1 0 1 0 1 1  0 1 1 1 ( 0 x 8 C D E F A B 7 )
|     |                                        | 2 0  b its | 5  b its | 7  b its | 2 0  b its   | 5  b its | 7  b its |
| --- | -------------------------------------- | ---------- | -------- | -------- | ------------ | -------- | -------- |
| 124 | Digital Design & Computer Architecture |            |          |          | Architecture |          |          |

J-Type
• Jump-Type
• Used for jump-and-link instruction (jal)
• 2 operands:
|     | – rd:  |     |     |     | destination register                 |     |     |
| --- | ------ | --- | --- | --- | ------------------------------------ | --- | --- |
|     | – imm  |     |     | :   | 20 bits (20:1) of a 21-bit immediate |     |     |
20,10:1,11,19:12
• Other fields:
|     | – op:  | the operation code or opcode – tells computer what  |     |     |     |     |     |
| --- | ------ | --------------------------------------------------- | --- | --- | --- | --- | --- |
|     |        | operation to perform                                |     |     |     |     |     |

|     |     |       |               | J - T             | y p e |             |             |
| --- | --- | ----- | ------------- | ----------------- | ----- | ----------- | ----------- |
|     |     |       | 3 1 : 1 2     |                   |       | 1 1 : 7     | 6 : 0       |
|     |     | i m m |               |                   |       | r d         | o p         |
|     |     |       | 2 0 , 1 0 : 1 | , 1 1 , 1 9 : 1 2 |       |             |             |
|     |     |       | 2 0   b i t   | s                 |       | 5   b i t s | 7   b i t s |
Note: jalr is I-type, not j-type, to specify rs1
•
| 125 | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- |

J-Type Example
|     |     |     | #   |   A d d | r e s | s      |               |     R I | S C -     | V   A s  | s e m b l y |     |     |     |
| --- | --- | --- | --- | ------- | ----- | ------ | ------------- | ------- | --------- | -------- | ----------- | --- | --- | --- |
|     |     |     | 0   | x 0 0 0 | 0 5 4 | 0 C    |               |     j a | ld.    rs | a1 ,   f | u n, c 1    |     |     |     |
|     |     |     | 0   | x 0 0 0 | 0 5 4 | 1 0    |               |     a d |           | ,   s    | 2   s 3     |     |     |     |
0xABC04 – 0x540C =
|     |     |     | .   | . . |     |     |       |     . . |     |     |     |     |     |     |
| --- | --- | --- | --- | --- | --- | --- | ----- | ------- | --- | --- | --- | --- | --- | --- |
          0XA67F8
|     |     |     | 0   | x 0 0 0 | A B C   | 0 4        | f u n c  1  | :   a d   | d.    s   | 4 ,   s   | 5 ,   s 8 |     |     |     |
| --- | --- | --- | --- | ------- | ------- | ---------- | ----------- | --------- | --------- | --------- | --------- | --- | --- | --- |
|     |     |     | .   | . .     |         |            |             |     . .   |           |           |           |     |     |     |
|     |     |     |     | f       | u n c 1 |   is   0 x | A 6 7 F 8   |   b y t e | s   p a s | t   j a l |           |     |     |     |
im m   =   0 x A 6 7 F 8   0       1     0     1     0       0     1     1     0       0     1   1   1       1   1   1   1       1   0   0   0
b it   n u m b e r 2 0     1 9   1 8   1 7   1 6     1 5   1 4   1 3   1 2     1 1   1 0   9   8       7   6   5   4       3   2   1   0
A s s e m b l y F i e l d   V a l u e s M a c h i n e   C o d e
|             |                    | im  | m   |            |             |     | r d | o p |     | im  | m              |             | r d | o p |
| ----------- | ------------------ | --- | --- | ---------- | ----------- | --- | --- | --- | --- | --- | -------------- | ----------- | --- | --- |
|             |                    |     | 2 0 | ,1 0 :1 ,1 | 1 ,1 9 :1 2 |     |     |     |     |     | 2 0 ,1 0 :1 ,1 | 1 ,1 9 :1 2 |     |     |
| j a ll    r | a ,   f u nA c6 17 |     |     |            |             |     |     |     |     |     |                |             |     |     |
0 1 1 1  1 1 1 1  1 0 0 0  1 0 1 0  0 1 1 0 1 1 1 1 0 1 1 1  1 1 1 1  1 0 0 0  1 0 1 0  0 1 1 0 0 0 0 0 1 1 1 0  1 1 1 1 ( 0 x 7 F 8 A 6 0 E F )
| j a x | 1 ,   0 x F 8                          |     |     |            |     |     |          |          |     |              |            |     |          |          |
| ----- | -------------------------------------- | --- | --- | ---------- | --- | --- | -------- | -------- | --- | ------------ | ---------- | --- | -------- | -------- |
|       |                                        |     |     | 2 0  b its |     |     | 5  b its | 7  b its |     |              | 2 0  b its |     | 5  b its | 7  b its |
| 126   | Digital Design & Computer Architecture |     |     |            |     |     |          |          |     | Architecture |            |     |          |          |

Review: Instruction Formats
7   b i t s 5   b i t s 5   b i t s 3   b i t s 5   b i t s 7   b i t s
|     |           |       |       |       |       |     |     | R -   | T y p e |
| --- | --------- | ----- | ----- | ----- | ----- | --- | --- | ----- | ------- |
| f   | u n c t 7 | r s 2 | r s 1 | f u n | c t 3 | r d | o p |       |         |
|     |           |       |       |       |       |     |     | I - T | y p e   |
|     | i m m     |       | r s 1 | f u n | c t 3 | r d | o p |       |         |
1 1 : 0
|     |               |       |       |       |         |             |     | S - T | y p e   |
| --- | ------------- | ----- | ----- | ----- | ------- | ----------- | --- | ----- | ------- |
| i m | m             | r s 2 | r s 1 | f u n | c t 3   | i m m       | o p |       |         |
|     | 1 1 : 5       |       |       |       |         | 4 : 0       |     |       |         |
|     |               |       |       |       |         |             |     | B -   | T y p e |
| i m | m             | r s 2 | r s 1 | f u n | c t 3 i | m m         | o p |       |         |
|     | 1 2 , 1 0 : 5 |       |       |       |         | 4 : 1 , 1 1 |     |       |         |
|     |               | i m m |       |       |         | r d         | o p | U -   | T y p e |
3 1 : 1 2
|     |                                        |           |                 |       |     |              |             | J - T | y p e |
| --- | -------------------------------------- | --------- | --------------- | ----- | --- | ------------ | ----------- | ----- | ----- |
|     | i m                                    | m         |                 |       |     | r d          | o p         |       |       |
|     |                                        | 2 0 , 1 0 | : 1 , 1 1 , 1 9 | : 1 2 |     |              |             |       |       |
|     |                                        | 2 0       | b i t s         |       |     | 5   b i t s  | 7   b i t s |       |       |
| 127 | Digital Design & Computer Architecture |           |                 |       |     | Architecture |             |       |       |

Design Principle 4
Good design demands good compromises
•
Multiple instruction formats allow flexibility
|     | - add, sub:   |     |      use 3 register operands |     |
| --- | ------------- | --- | ---------------------------- | --- |
- lw, sw, addi:     use 2 register operands and a
|     |                                            |     |      constant |     |
| --- | ------------------------------------------ | --- | ------------- | --- |
|     | • Number of instruction formats kept small |     |               |     |
- to adhere to design principles 1 and 3
(simplicity favors regularity and smaller is
faster).
| 128 | Digital Design & Computer Architecture |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | ------------ |

Chapter 6: Architecture
Immediate Encodings

Constants / Immediates
|     | • lw and sw use constants or immediates   |                      |
| --- | ----------------------------------------- | -------------------- |
|     | • immediately available from instruction  |                      |
|     | • 12-bit two’s complement number          |                      |
|     | • addi: add immediate                     |                      |
|     | • Is subtract immediate (subi) necessary? |                      |
|     | C Code                                    | RISC-V assembly code |
# s0 = a, s1 = b
|     | a = a + 4;                             | addi s0, s0, 4   |
| --- | -------------------------------------- | ---------------- |
|     | b = a – 12;                            | addi s1, s0, -12 |
| 130 | Digital Design & Computer Architecture | Architecture     |

Constants / Immediates
Immediate Bits
|     |     | i m | m   |     |     | i m m   | i m m | I ,   S |
| --- | --- | --- | --- | --- | --- | ------- | ----- | ------- |
|     |     |     | 1 1 |     |     | 1 1 : 1 |       | 0       |
|     |     | i m | m   |     |     | i m m   | 0     | B       |
1 2 1 1 : 1
UJ
|     | i m | m   |     | i m m |     | 0   |     |     |
| --- | --- | --- | --- | ----- | --- | --- | --- | --- |
3 1 : 2 1 2 0 : 1 2
|     | i m | m   |     | i m m |     | i m m | 0   |     |
| --- | --- | --- | --- | ----- | --- | ----- | --- | --- |
22 05 2  01 : 1 21 1 15 :  1
3 1   3 0   2 9   2 8   2 7   2 6     2 4   2 3   2 2   2 1   2 0   1 9   1 8   1 7   1 6 5   4   1 3   1 2   1 1   1 0     9     8     7     6     4     3     2     1     0
| 131 | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- | --- |

Immediate Encodings
Instruction Bits
• Immediate bits mostly occupy consistent instruction bits.
• Simplifies hardware to build the microprocessor
• Sign bit of signed immediate is in msb of instruction.
• Recall that rs2 of R-type can encode immediate shift amount.
132 Digital Design & Computer Architecture Architecture
1
1
1
3
2
3
1
1
2
1
0
1
1
1
1
3
1
3
0
0
0
0
0
0
2
2
9
9
9
9
9
9
f
2
2
u
8
8
8
8
8
8
n c
2
2
7
7
7
7
7
7
t 7
2
2
6
6
6
6
6
6
2
2
5
5
5
5
5
5
2
2
4
4
4
4
4
2
2
3
3
3
3
3
r
r
2
2
s
s
2
2
2
2
2
2
2
2
2
1
1
1
1
1
2
1
2
0
0
0
1
0
1
1
1
9
9
9
1
1
1
8
8
8
r
r
r
r
s
s
s
s
1
1
1
7
7
7
1
1
1
1
1
1
1
6
6
6
1
1
1
5
5
5
1
1
1
f
f
f
f
4
4
4
u
u
u
u
n
n
n
n
1
1
1
3
3
3
c
c
c
c
t
t
t
t
1
1
1
3
3
3
3
2
2
2 1
4
4
1 1
3
3
0
r
r
r
r
d
d
2
2
d
d
9
1
1
8
1
0
1
7
R
I
SB
UJ

Composition of 32-bit Immediates
Instruction Bits
|     |           | f  u n  c  | t  7        |           |                 |     | r s 1 |     | f u n c t 3 | r d | R   |
| --- | --------- | ---------- | ----------- | --------- | --------------- | --- | ----- | --- | ----------- | --- | --- |
|     |           |            |             |     4     | 3     2     1   |   0 |       |     |             |     |     |
I
1 1   1 0     9     8     7     6     5     4     3     2     1     0 r s 1 f u n c t 3 r d
1 1   1 0     9     8     7     6     5               r   s   2                        r  s    1                 f  u  n    c   t  3      4     3     2     1     0 SB
|     |     |     |     |     | r s 2  |     | r  s  1 |     | f  u  n  c t  3  |     |     |
| --- | --- | --- | --- | --- | ------ | --- | ------- | --- | ---------------- | --- | --- |
1 2   1 0     9     8     7     6     5                                                                   4     3     2     1   1 1
UJ
3 1   3 0   2 9   2 8   2 7   2 6   2 5   2 4   2 3   2 2   2 1   2 0   1 9   1 8   1 7   1 6   1 5   1 4   1 3   1 2   r d
2 0   1 0     9     8     7     6     5     4     3     2     1   1 1   1 9   1 8   1 7   1 6   1 5   1 4   1 3   1 2   r d
3 1   3 0   2 9   2 8   2 7   2 6   2 5   2 4   2 3   2 2   2 1   2 0   1 9   1 8   1 7   1 6   1 5   1 4   1 3   1 2   1 1   1 0     9     8     7
|     | 3 1 |     | 3 1 |     |     | 3 1 |     | 3 1 | 3 0 : 2 5 | 2 4 : 2 1 | 2 0 I |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | --------- | ----- |
t
i
b
S
|     | 3 1 |     | 3 1 |     |     | 3 1 |     | 3 1 | 3 0 : 2 5 | 1 1 : 8 | 7   |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --------- | ------- | --- |
n
o
| i   | 3 1 |     | 3 1 |     |     | 3 1 |     | 3 0 | 2 9 : 2 5 ,   1 1 | 1 0 : 7 | 0 B |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ----------------- | ------- | --- |
t
c
u UJ
|     | 3 1 |     | 3 0 : 2 | 0   |     | 1 9 : | 1 2 | 0   | 0   | 0   | 0   |
| --- | --- | --- | ------- | --- | --- | ----- | --- | --- | --- | --- | --- |
r
t
s
|     | 3 1 |     | 3  15 |     |     | 1  96 :1 | 15 21 | 2 0 | 2  18 : 17 6  | 1 5 : 1 2 | 0   |
| --- | --- | --- | ----- | --- | --- | -------- | ----- | --- | ------------- | --------- | --- |
n
i
3 1   3 0   2 9   2 8   2 7   2 6 2   2 4   2 3   2 2   2 1   2 0   1 9   1 8   1 7 1     4   1 3   1 2   1 1   1 0     9         6     5     4     3     2     1     0
Immediate Bits
| 133 | Digital Design & Computer Architecture |     |     |     |     |     | Architecture |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- |

Chapter 6: Architecture
Reading
Machine Language &
Addressing Operands

Instruction Fields & Formats
|     | Instruction | op  | funct3 | Funct7 | Type |
| --- | ----------- | --- | ------ | ------ | ---- |
add
|     |     | 0110011 (51) | 000 (0) | 0000000 (0) | R-Type |
| --- | --- | ------------ | ------- | ----------- | ------ |
sub
|     |     | 0110011 (51) | 000 (0) | 0100000 (32) | R-Type |
| --- | --- | ------------ | ------- | ------------ | ------ |
and
|     |     | 0110011 (51) | 111 (7) | 0000000 (0) | R-Type |
| --- | --- | ------------ | ------- | ----------- | ------ |
or
|     |     | 0110011 (51) | 110 (6) | 0000000 (0) | R-Type |
| --- | --- | ------------ | ------- | ----------- | ------ |
addi
|     |     | 0010011 (19) | 000 (0) | -   | I-Type |
| --- | --- | ------------ | ------- | --- | ------ |
beq
|     |     | 1100011 (99) | 000 (0) | -   | B-Type |
| --- | --- | ------------ | ------- | --- | ------ |
bne
|     |     | 1100011 (99) | 001 (1) | -   | B-Type |
| --- | --- | ------------ | ------- | --- | ------ |
lw
|     |     | 0000011 (3) | 010 (2) | -   | I-Type |
| --- | --- | ----------- | ------- | --- | ------ |
sw
|     |     | 0100011 (35) | 010 (2) | -   | S-Type |
| --- | --- | ------------ | ------- | --- | ------ |
jal
|     |     | 1101111 (111) | -   | -   | J-Type |
| --- | --- | ------------- | --- | --- | ------ |
jalr
|     |     | 1100111 (103) | 000 (0) | -   | I-Type |
| --- | --- | ------------- | ------- | --- | ------ |
lui
|     |     | 0110111 (55) | -   | -   | U-Type |
| --- | --- | ------------ | --- | --- | ------ |
See Appendix B for other instruction encodings
| 135 | Digital Design & Computer Architecture |     | Architecture |     |     |
| --- | -------------------------------------- | --- | ------------ | --- | --- |

Interpreting Machine Code
|     | • Write in binary                              |     |     |     |     |     |
| --- | ---------------------------------------------- | --- | --- | --- | --- | --- |
|     | • Start with op: tells how to parse rest       |     |     |     |     |     |
|     | • Extract fields                               |     |     |     |     |     |
|     | • op, funct3, and funct7 fields tell operation |     |     |     |     |     |
|     | • Ex: 0x41FE83B3 and 0xFDA58393                |     |     |     |     |     |
0x41FE83B3: 0100 0001 1111 1110 1000 0011 1011 0011
                                                         op = 51, funct3 = 0: add or sub (R-type)
|     |     |     |     |     |    funct7 = 0100000: sub |     |
| --- | --- | --- | --- | --- | ------------------------ | --- |
0xFDA48393: 1111 1101 1010 0100 1000 0011 1001 0011
                                                                        op = 19, funct3 = 0: addi (I-type)
| 136 | Digital Design & Computer Architecture |     |     |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ |

Interpreting Machine Code
|     | • Write in binary                              |     |     |     |     |     |     |     |     |
| --- | ---------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | • Start with op: tells how to parse rest       |     |     |     |     |     |     |     |     |
|     | • Extract fields                               |     |     |     |     |     |     |     |     |
|     | • op, funct3, and funct7 fields tell operation |     |     |     |     |     |     |     |     |
|     | • Ex: 0x41FE83B3 and 0xFDA58393                |     |     |     |     |     |     |     |     |
M a c h i n e   C o d e F i e l d   V a l u e s A s s e m b l y
fu n c t 7 r s 2 r s 1 fu n c t 3 r d o p fu n c t 7 r s 2 r s 1 fu n c t 3 r d o p
ss uu bb    xt 72 ,,    xt 24 9, ,  xt 36 1
( 0 x 4 1 F E 8 3 B 3 ) 0 1 0 0  0 0 0 1 1 1 1 1 1 1 1 0 1 0 0 0 0 0 1 1 1 0 1 1  0 0 1 1 3 2 3 1 2 9 0 7 5 1
7  b its 5  b its 5  b its 3  b its 5  b its 7  b its 7  b its 5  b its 5  b its 3  b its 5  b its 7  b its
|     |     | im m   | r s 1 fu | n c t 3 r d | o p | im m   | r s 1 fu | n c t 3 r d | o p |
| --- | --- | ------ | -------- | ----------- | --- | ------ | -------- | ----------- | --- |
|     |     | 1 1 :0 |          |             |     | 1 1 :0 |          |             |     |
aa dd dd ii    xt 72 ,,    xs 91 ,,    -- 33 88
( 0 x F D A 4 8 3 9 3 ) 1 1 1 1  1 1 0 1  1 0 1 0 0 1 0 0 1 0 0 0 0 0 1 1 1 0 0 1  0 0 1 1 - 3 8 9 0 7 1 9
1 2  b its 5  b its 3  b its 5  b its 7  b its 1 2  b its 5  b its 3  b its 5  b its 7  b its
| 137 | Digital Design & Computer Architecture |     |     |     |     | Architecture |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ | --- | --- | --- |

Addressing Modes
How do we address the operands?
|     | • Register Only |     |
| --- | --------------- | --- |
|     | • Immediate     |     |
•
Base Addressing
•
PC-Relative
| 138 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Addressing Modes
Register Only
|     | • Operands found in registers |     |
| --- | ----------------------------- | --- |
– Example: add s0, t2, t3
– Example: sub t6, s1, 0
Immediate
|     | • 12-bit signed immediate used as an operand |     |
| --- | -------------------------------------------- | --- |
– Example: addi s4, t5, -73
– Example: ori  t3, t7, 0xFF
| 139 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Addressing Modes
Base Addressing
• Loads and Stores
• Address of operand is:
base address + immediate
– Example: lw s4, 72(zero)
• address = 0 + 72
– Example: sw t2, -25(t1)
• address = t1 - 25
140 Digital Design & Computer Architecture Architecture

Addressing Modes
PC-Relative Addressing: branches and jal
Example:

|     |     | Address  |     | Instruction |     |                 |     |     |     |     |
| --- | --- | -------- | --- | ----------- | --- | --------------- | --- | --- | --- | --- |
|     |     | 0x354    |     | L1:         |     | addi s1, s1, 1  |     |     |     |     |
|     |     | 0x358    |     |             |     | sub  t0, t1, s7 |     |     |     |     |
|     |     | ...      |     |             |     | ...             |     |     |     |     |
|     |     | 0xEB0    |     |             |     | bne  s8, s9, L1 |     |     |     |     |
The label is (0xEB0-0x354) = 0xB5C (2908) instructions before bne
im m   =   - 2 9 0 8 1         0     1     0   0       1   0   1   0       0   1   0   0
1 2 :0
|     |     | b it   n u | m b e r | 1 2       1 | 1   1 0   9 |   8       7 |   6   5   4 |       3   2 |   1   0 |     |
| --- | --- | ---------- | ------- | ----------- | ----------- | ----------- | ----------- | ----------- | ------- | --- |
A s s e m b l y F i e l d   V a l u e s M a c h i n e   C o d e
im m r s 2 r s 1 fu n c t 3 im m o p im m r s 2 r s 1 fu n c t 3 im m o p
|     |     | 1 2 ,1 0 :5 |     |     | 4 :1 ,1 1 |     | 1 2 ,1 0 | :5  |     | 4 :1 ,1 1 |
| --- | --- | ----------- | --- | --- | --------- | --- | -------- | --- | --- | --------- |
b n e   s 8 ,     s 9 ,     L 1 1 1 0 0  1 0 1 2 4 2 5 1 0 0 1 0  0 9 9 1 1 0 0  1 0 1 1 1 0 0 0 1 1 0 0 1 0 0 1 0 0 1 0  0 1 1 0  0 0 1 1 ( 0 x C B 8 C 9 2 6 3 )
( b n e   x 2 4 ,   x 2 5 ,   L 1 ) 7  b its 5  b its 5  b its 3  b its 5  b its 7  b its 7  b its 5  b its 5  b its 3  b its 5  b its 7  b its
| 141 | Digital Design & Computer Architecture |     |     |     |     |     | Architecture |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | --- | ------------ | --- | --- | --- |

Chapter 6: Architecture
Compiling,
Assembling, & Loading
Programs

The Power of the Stored Program
|     | • 32-bit instructions & data stored in memory |     |
| --- | --------------------------------------------- | --- |
|     | • Sequence of instructions: only difference   |     |
between two applications
|     | • To run a new program: |     |
| --- | ----------------------- | --- |
– No rewiring required
– Simply store new program in memory
|     | • Program Execution: |     |
| --- | -------------------- | --- |
– Processor fetches (reads) instructions from memory
in sequence
– Processor performs the specified operation
| 143 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

The Stored Program
|     | Assembly Code |     |     | Machine Code |     |     |
| --- | ------------- | --- | --- | ------------ | --- | --- |
add  s2, s3, s4
0x01498933
|     | sub  t0, t1, t2  |          |              | 0x407302B3 |       |     |
| --- | ---------------- | -------- | ------------ | ---------- | ----- | --- |
|     | addi s2, t1, -14 |          |              | 0xFF230913 |       |     |
|     | lw   t2, -6(s3)  |          |              | 0xFFA9A383 |       |     |
|     |                  | Address  | Instructions |            |       |     |
|     |                  | 0000083C | F F          | A 9 A      | 3 8 3 |     |
|     |                  | 00000838 | F F          | 2 3 0      | 9 1 3 |     |
Program Counter
|     |     |     | 4 0 | 7 3 0 | 2 B 3 |     |
| --- | --- | --- | --- | ----- | ----- | --- |
00000834
(PC): keeps track of
PC
|     |     | 00000830 | 0 1 | 4 9 8 | 9 3 3 |     |
| --- | --- | -------- | --- | ----- | ----- | --- |
current instruction
Main Memory
| 144 | Digital Design & Computer Architecture |     |     |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | --- | --- | ------------ |

Alan Turing, 1912 - 1954
• British mathematician and computer
scientist
• Founder of theoretical computer science
• Invented the Turing machine: a
mathematical model of computation
• Designed the Automatic Computing
Engine, one of first stored program
computers
• In 1952, was prosecuted for homosexual
acts. Two years later, he died of cyanide
poisoning.
• The Turing Award was named in his honor,
which is the highest honor in computing.
145 Digital Design & Computer Architecture Architecture

How to Compile & Run a Program
|     |     | H i g h   | L e v e l   C   | o d e |
| --- | --- | --------- | --------------- | ----- |
|     |     | C         | o m p i l e r   |       |
|     |     | A s s e   | m b l y   C o   | d e   |
|     |     | A         | s s e m b l e r |       |
OL bb jer cr ty   F  i l e ss
|     |     | O b | je c t   F i l | e   |
| --- | --- | --- | -------------- | --- |
i a F i l e
|     |                                        |     | L i n k e r   |              |
| --- | -------------------------------------- | --- | ------------- | ------------ |
|     |                                        | E x | e c u t a b l | e            |
|     |                                        |     | L o a d e r   |              |
|     |                                        | M   | e m o r y     |              |
| 146 | Digital Design & Computer Architecture |     |               | Architecture |

Grace Hopper, 1906 - 1992
| •   | Graduated from Yale University  |     |
| --- | ------------------------------- | --- |
with a Ph.D. in mathematics
•
Developed first compiler
•
Helped develop the COBOL
programming language
| •   | Highly awarded naval officer   |     |
| --- | ------------------------------ | --- |
| •   | Received World War II Victory  |     |
Medal and National Defense
Service Medal, among others
| 147 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

What is Stored in Memory?
|     | • Instructions (also called text) |     |
| --- | --------------------------------- | --- |
|     | • Data                            |     |
– Global/static: allocated before program begins
– Dynamic: allocated within program
|     | • How big is memory? |     |
| --- | -------------------- | --- |
– At most 232 = 4 gigabytes (4 GB)
– From address 0x00000000 to 0xFFFFFFFF
| 148 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Example RISC-V Memory Map
|     |     | A d d       | r e s s   | S e g m e n     | t     |     |
| --- | --- | ----------- | --------- | --------------- | ----- | --- |
|     |     | 0 x F F F   | F F F F C |                 |       |     |
|     |     |             |           | O p e r a t in  | g     |     |
|     |     |             | S         | y s t e m   &   | I / O |     |
|     |     | 0 x 8 0 0 0 | 0 0 0 4   |                 |       |     |
s p
|     |     | 0 x 8 0 0 0 | 0 0 0 0   | S t a c k         |       |     |
| --- | --- | ----------- | --------- | ----------------- | ----- | --- |
|     |     |             | D         | y n a m i c   D   | a t a |     |
|     |     | 0 x 1 0 0 0 | 1 0 0 0   | H e a p           |       |     |
|     |     | 0 x 1 0 0 0 | 0 F F C   |                   |       |     |
|     |     |             |           | G l o b a l   D a | t a   | g p |
|     |     | 0 x 1 0 0   | 0 0 0 0 0 |                   |       |     |
T e x t
|     |     | 0 x 0 0 0 | 0 8 0 0 0 |                 |     |     |
| --- | --- | --------- | --------- | --------------- | --- | --- |
|     |     |           |           | E x c e p t io  | n   |     |
|     |     |           |           | H a n d l e r s |     |     |
p c
|     |                                        | 0 x 0 0 0 | 0 0 0 0 0 |     |              |     |
| --- | -------------------------------------- | --------- | --------- | --- | ------------ | --- |
| 149 | Digital Design & Computer Architecture |           |           |     | Architecture |     |

Example Program: C Code
int f, g, y; // global variables
int func(int a, int b) {
if (b < 0)
return (a + b);
else
return(a + func(a, b-1));
}
void main() {
f = 2;
g = 3;
y = func(f,g);
return;
}
150 Digital Design & Computer Architecture Architecture

Example Program: RISC-V Assembly
Address Machine Code RISC-V Assembly Code Maintain 4-word
alignment of sp (for
10144: ff010113 func: addi sp,sp,-16
compatibility with
10148: 00112623 sw ra,12(sp)
RV128I) even though
1014c: 00812423 sw s0,8(sp)
only space for 2 words
10150: 00050413 mv s0,a0
needed.
10154: 00a58533 add a0,a1,a0
10158: 0005da63 bgez a1,1016c <func+0x28>
1015c: 00c12083 lw ra,12(sp)
10160: 00812403 lw s0,8(sp)
10164: 01010113 addi sp,sp,16
10168: 00008067 ret Pseudoinstructions:
1016c: fff58593 addi a1,a1,-1 mv: addi a0, s0, 0
ret (return): jr ra
10170: 00040513 mv a0,s0
10174: fd1ff0ef jal ra,10144 <func>
10178: 00850533 add a0,a0,s0
1017c: fe1ff06f j 1015c <func+0x18>
151 Digital Design & Computer Architecture Architecture

Example Program: RISC-V Assembly
Address Machine Code RISC-V Assembly Code
10180: ff010113 main: addi sp,sp,-16 gp = 0x11DE0
10184: 00112623 sw ra,12(sp)
10188: 00200713 li a4,2
1018c: c4e1a823 sw a4,-944(gp) # 11a30 <f>
10190: 00300713 li a4,3
10194: c4e1aa23 sw a4,-940(gp) # 11a34 <g>
10198: 00300593 li a1,3
1019c: 00200513 li a0,2
101a0: fa5ff0ef jal ra,10144 <func>
101a4: c4a1ac23 sw a0,-936(gp) # 11a38 <y>
101a8: 00c12083 lw ra,12(sp)
101ac: 01010113 addi sp,sp,16
101b0: 00008067 ret
Put 2 and 3 in f and g (and argument registers) and call func. Then put
result in y and return.
152 Digital Design & Computer Architecture Architecture

Example Program: Symbol Table
Address                                            Size            Symbol Name
00010074 l     d  .text  00000000 .text
000115e0 l     d  .data  00000000 .data
00010144 g     F .text  0000003c func
00010180 g     F .text  00000034 main
00011a30 g     O .bss  00000004 f
00011a34 g     O .bss  00000004 g
00011a38 g     O .bss  00000004 y
|     | • text segment:                        |     | address 0x10074                   |              |
| --- | -------------------------------------- | --- | --------------------------------- | ------------ |
|     | • data segment:                        |     | address 0x115e0                   |              |
|     | • func function:                       |     | address 0x10144 (size 0x3c bytes) |              |
|     | • main function:                       |     | address 0x10180 (size 0x34 bytes) |              |
|     | • f:                                   |     | address 0x11a30 (size 0x4 bytes)  |              |
|     | • g:                                   |     | address 0x11a34 (size 0x4 bytes)  |              |
|     | • y:                                   |     | address 0x11a38 (size 0x4 bytes)  |              |
| 153 | Digital Design & Computer Architecture |     |                                   | Architecture |

Example Program in Memory
|     | Address Memory        |     |     |            |     |
| --- | --------------------- | --- | --- | ---------- | --- |
|     | 0xFFFFFFFC Operating  |     |     | 0x00008067 |     |
System & I/O
0x80000000
|     | 0x7FFFFFF0 | sp = 0x7FFFFFF0 |     | 0x01010113 |     |
| --- | ---------- | --------------- | --- | ---------- | --- |
Stack
0x00c12083
Dynamic Data
0xc4a1ac23
|     | 0x00022DC4 Heap |                 |     |            |     |
| --- | --------------- | --------------- | --- | ---------- | --- |
|     | 0x00022DC0      |                 |     | 0xfa5ff0ef |     |
|     |                 | gp = 0x00011DE0 |     | 0x00200513 |     |
y
g 0x00300593
0x00011A30 f
0xc4e1aa23
Address of main:
0x000115E0
0x00300713
|     |     |     |     | 0xc4e1a823 | 0x10180 |
| --- | --- | --- | --- | ---------- | ------- |
0x00008067
|     | 0x01010113 |     |     | 0x00200713 |     |
| --- | ---------- | --- | --- | ---------- | --- |
0x00c12083
|     | 0xc4a1ac23 |     |     | 0x00112623 |     |
| --- | ---------- | --- | --- | ---------- | --- |
0xfa5ff0ef
|     | 0x00200513 |     | 0x00010180 | 0xff010113 | pc = 0x00010180 |
| --- | ---------- | --- | ---------- | ---------- | --------------- |
0x00300593
|     | 0xc4e1aa23 |     |     | 0xfe1ff06f |     |
| --- | ---------- | --- | --- | ---------- | --- |
0x00300713
|     | 0xc4e1a823 |     |     | 0x00850533 |     |
| --- | ---------- | --- | --- | ---------- | --- |
0x00200713
|     | 0x00112623            |                 |     | 0xfd1ff0ef |     |
| --- | --------------------- | --------------- | --- | ---------- | --- |
|     | 0x00010180 0xff010113 | pc = 0x00010180 |     |            |     |
0x00040513
0xfe1ff06f
0x00850533
0xfff58593
0xfd1ff0ef
0x00040513
0x00008067
0xfff58593
0x00008067
0x01010113
0x01010113
0x00812403
0x00812403
0x00c12083
0x0005da63
0x00c12083
0x00a58533
0x00050413
|     | 0x00812423 |     |     | 0x0005da63 |     |
| --- | ---------- | --- | --- | ---------- | --- |
0x00112623
|     | 0x00010144 0xff010113 |     |     | 0x00a58533 |     |
| --- | --------------------- | --- | --- | ---------- | --- |
... 0x00050413
...
... 0x00812423
0x00010074
|     | Exception |     |     | 0x00112623 |     |
| --- | --------- | --- | --- | ---------- | --- |
Handlers
|     |                                        |     | 0x00010144 | 0xff010113   |     |
| --- | -------------------------------------- | --- | ---------- | ------------ | --- |
| 154 | Digital Design & Computer Architecture |     |            | Architecture |     |

Chapter 6: Architecture
Endianness

Big-Endian & Little-Endian Memory
|     | • How to number bytes within a word?                      |     |     |     |     |     |     |     |     |
| --- | --------------------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
|     | • Little-endian: byte numbers start at the little (least  |     |     |     |     |     |     |     |     |
significant) end
• Big-endian: byte numbers start at the big (most significant)
end
|     | • Word address is the same for big- or little-endian |            |         |     |         |      |               |         |     |
| --- | ---------------------------------------------------- | ---------- | ------- | --- | ------- | ---- | ------------- | ------- | --- |
|     |                                                      | Big-Endian |         |     |         |      | Little-Endian |         |     |
|     |                                                      |            | Byte    |     |         | Word |               | Byte    |     |
|     |                                                      |            | Address |     | Address |      |               | Address |     |
|     |                                                      | C          | D       | E F |         | C    | F             | E       | D C |
|     |                                                      | 8          | 9       | A B |         | 8    | B             | A       | 9 8 |
|     |                                                      | 4          | 5       | 6 7 |         | 4    | 7             | 6       | 5 4 |
|     |                                                      | 0          | 1       | 2 3 |         | 0    | 3             | 2       | 1 0 |
|     |                                                      | MSB        |         | LSB |         |      | MSB           |         | LSB |
| 156 | Digital Design & Computer Architecture               |            |         |     |         |      | Architecture  |         |     |

Big-Endian & Little-Endian Memory
|     | • Jonathan Swift’s Gulliver’s Travels: the Little-Endians  |     |     |     |     |     |     |     |     |
| --- | ---------------------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
broke their eggs on the little end of the egg and the
Big-Endians broke their eggs on the big end
|     | • It doesn’t really matter which addressing type used –  |     |     |     |     |     |     |     |     |
| --- | -------------------------------------------------------- | --- | --- | --- | --- | --- | --- | --- | --- |
except when the two systems need to share data!
|     |                                        | Big-Endian |         |     |         |      | Little-Endian |         |     |
| --- | -------------------------------------- | ---------- | ------- | --- | ------- | ---- | ------------- | ------- | --- |
|     |                                        |            | Byte    |     |         | Word |               | Byte    |     |
|     |                                        |            | Address |     | Address |      |               | Address |     |
|     |                                        | C          | D       | E F |         | C    | F             | E       | D C |
|     |                                        | 8          | 9       | A B |         | 8    | B             | A       | 9 8 |
|     |                                        | 4          | 5       | 6 7 |         | 4    | 7             | 6       | 5 4 |
|     |                                        | 0          | 1       | 2 3 |         | 0    | 3             | 2       | 1 0 |
|     |                                        | MSB        |         | LSB |         |      | MSB           |         | LSB |
| 157 | Digital Design & Computer Architecture |            |         |     |         |      | Architecture  |         |     |

Big-Endian & Little-Endian Example
|     | • Suppose t0 initially contains 0x23456789              |     |     |     |     |     |     |     |
| --- | ------------------------------------------------------- | --- | --- | --- | --- | --- | --- | --- |
|     | • After following code runs on big-endian system, what  |     |     |     |     |     |     |     |
value is s0?
|     | • In a little-endian system? |                |     |                 |     |     |     |     |
| --- | ---------------------------- | -------------- | --- | --------------- | --- | --- | --- | --- |
|     |                              | sw t0, 0(zero) |     |                 |     |     |     |     |
|     |                              | lb s0, 1(zero) |     |                 |     |     |     |     |
|     | • Big-endian:                |                |     | s0 = 0x00000045 |     |     |     |     |
s0 = 0x00000067
|     | • Little-endian:  |     |            |     |     |               |     |     |
| --- | ----------------- | --- | ---------- | --- | --- | ------------- | --- | --- |
|     |                   |     | Big-Endian |     |     | Little-Endian |     |     |
Word
|     |                                        | Byte Address | 0 1   | 2 3   | Address | 3 2          | 1 0   | Byte Address |
| --- | -------------------------------------- | ------------ | ----- | ----- | ------- | ------------ | ----- | ------------ |
|     |                                        | Data Value   | 23 45 | 67 89 | 0       | 23 45        | 67 89 | Data Value   |
|     |                                        |              | MSB   | LSB   |         | MSB          | LSB   |              |
| 158 | Digital Design & Computer Architecture |              |       |       |         | Architecture |       |              |

Chapter 6: Architecture
Signed & Unsigned
Instructions

Signed & Unsigned Instructions
|     | • Multiplication and division          |              |
| --- | -------------------------------------- | ------------ |
|     | • Branches                             |              |
|     | • Set less than                        |              |
|     | • Loads                                |              |
|     | • Detecting overflow                   |              |
| 160 | Digital Design & Computer Architecture | Architecture |

Multiplication
|     | • Signed:  |     | mulh |     |     |
| --- | ---------- | --- | ---- | --- | --- |
mulhu, mulhsu
|     | • Unsigned:  |     |     |     |     |
| --- | ------------ | --- | --- | --- | --- |
– mulhu: treat both operands as unsigned
– mulhsu: treat first operand as signed, second as unsigned
– 32 lsbs are identical whether signed/unsigned; use mul
Example: s1 = 0x80000000; s2 = 0xC0000000
|     | mulh s4, s1, s2 |     | mulhu s4, s1, s2 |     | mulhsu s4, s1, s2 |
| --- | --------------- | --- | ---------------- | --- | ----------------- |
|     | mul  s3, s1, s2 |     | mul   s3, s1, s2 |     | mul    s3, s1, s2 |
s1 = -231; s2 = -230 s1 = 231; s2 = 3x230 s1 = -231; s2 = 3x230
|     | s1 x s2 = 261                          |     | s1 x s2 = 3x261 |              | s1 x s2 = -3x261 |
| --- | -------------------------------------- | --- | --------------- | ------------ | ---------------- |
|     | s4 = 0x20000000                        |     | s4 = 0x60000000 |              | s4 = 0xA0000000  |
|     | s3 = 0x00000000                        |     | s3 = 0x00000000 |              | s3 = 0x00000000  |
| 161 | Digital Design & Computer Architecture |     |                 | Architecture |                  |

Division & Remainder
|     | • Signed:                              |     | div, rem   |              |
| --- | -------------------------------------- | --- | ---------- | ------------ |
|     | • Unsigned:                            |     | divu, remu |              |
| 162 | Digital Design & Computer Architecture |     |            | Architecture |

Branches
|     | • Signed:    |     | blt, bge   |     |
| --- | ------------ | --- | ---------- | --- |
|     | • Unsigned:  |     | bltu, bgeu |     |
Examples:
s1 = 0x80000000; s2 = 0x40000000
blt  s1, s2
s1 = -231; s2 = 230
taken
bltu s1, s2
s1 = 231; s2 = 230
not taken
| 163 | Digital Design & Computer Architecture |     |     | Architecture |
| --- | -------------------------------------- | --- | --- | ------------ |

Set Less Than
|     | • Signed:  |     | slt, slti |     |
| --- | ---------- | --- | --------- | --- |
sltu, sltiu
|     | • Unsigned:  |     |     |     |
| --- | ------------ | --- | --- | --- |
Note: RISC-V always sign-extends the immediate,
even for sltiu
Examples:
s1 = 0x80000000; s2 = 0x40000000
|     | slt  t0, s1, s2                        |     | slti  t2, s1, -1  # -1 = 0xFFF       |              |
| --- | -------------------------------------- | --- | ------------------------------------ | ------------ |
|     | s1 = -231; s2 = 230                    |     | s1 = -231; imm = 0xFFFFFFFF = -1     |              |
|     | t0 = 1                                 |     | t2 = 1                               |              |
|     | sltu t1, s1, s2                        |     | sltiu t3, s1, -1  # -1 = 0xFFF       |              |
|     | s1 = 231; s2 = 230                     |     | s1 = 231; imm = 0xFFFFFFFF = 232 - 1 |              |
|     | t1 = 0                                 |     | t3 = 1                               |              |
| 164 | Digital Design & Computer Architecture |     |                                      | Architecture |

Loads
|     | • Signed:       |             |         |        |           |       |
| --- | --------------- | ----------- | ------- | ------ | --------- | ----- |
|     | – Sign-extends  | to  create  | 32-bit  | value  | to  load  | into  |
register
Load halfword: lh
–
– Load byte: lb
|     | • Unsigned: |     |     |     |     |     |
| --- | ----------- | --- | --- | --- | --- | --- |
– Zero-extends to create 32-bit value
– Load halfword unsigned: lhu
– Load byte: lbu
| 165 | Digital Design & Computer Architecture |     | Architecture |     |     |     |
| --- | -------------------------------------- | --- | ------------ | --- | --- | --- |

Detecting Overflow
| •   | RISC-V        | does  | not           | provide  | unsigned   | addition  | or       |
| --- | ------------- | ----- | ------------- | -------- | ---------- | --------- | -------- |
|     | instructions  |       | or  overflow  |          | detection  | because   | it  can  |
be done with existing instructions:
| •   | Example: Detecting unsigned overflow: |     |     |     |     |     |     |
| --- | ------------------------------------- | --- | --- | --- | --- | --- | --- |
        add  t0, t1, t2
   bltu t0, t1, overflow
•
Example: Detecting signed overflow:
   add  t0, t1, t2
   slti t3, t2, 0        # t3=1 if t2 neg.
   slt  t4, t0, t1       # t4=1 if result < t1
   bne  t3, t4, overflow # overflow if:
                         # t2 neg & result>=t1 or
                         # t2 pos & result<t1
| 166 | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- |

Chapter 6: Architecture
Compressed
Instructions

Compressed Instructions
|     | • 16-bit RISC-V instructions                 |     |
| --- | -------------------------------------------- | --- |
|     | • Replace common integer and floating-point  |     |
instructions with 16-bit versions.
|     | • Most RISC-V compilers/processors can use a  |     |
| --- | --------------------------------------------- | --- |
mix of 32-bit and 16-bit instructions (and
use 16-bit instructions whenever possible).
|     | • Uses prefix: c. |     |
| --- | ----------------- | --- |
|     | • Examples:       |     |
– add  → c.add
– lw   → c.lw
– addi → c.addi
| 168 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Compressed Instructions Example
C Code RISC-V assembly code
int i; # s0 = scores base address, s1 = i
int scores[200];
c.li s1, 0 # i = 0
addi t2, zero, 200 # t2 = 200
for (i=0; i<200; i=i+1) for:
bge s1, t2, done # I >= 200? done
scores[i] = scores[i]+10; c.lw a3, 0(s0) # a3 = scores[i]
c.addi a3, 10 # a3 = scores[i]+10
c.sw a3, 0(s0) # scores[i] = a3
c.addi s0, 4 # next element
c.addi s1, 1 # i = i+1
c.j for # repeat
done:
• 200 is too big to fit in compressed immediate, so
noncompressed addi used instead.
• c.addi s0,4 is equivalent to addi s0,s0,4.
• c.bge doesn’t exist, so bge is used.
169 Digital Design & Computer Architecture Architecture

Compressed Machine Formats
|     | • Some compressed instructions use a 3-bit  |     |
| --- | ------------------------------------------- | --- |
register code (instead of 5-bit). These specify
registers x8 to x15.
|     | • Immediates are 6-11 bits.            |              |
| --- | -------------------------------------- | ------------ |
|     | • Opcode is 2 bits.                    |              |
| 170 | Digital Design & Computer Architecture | Architecture |

Compressed Machine Formats
 15   14   13   12  11   10   9   8   7    6   5   4   3   2     1   0
|     |        |     |        |     |     |     |            |
| --- | ------ | --- | ------ | --- | --- | --- | ---------- |
|     | funct4 |     | rd/rs1 |     | rs2 |     | op CR-Type |
CI-Type
|     | funct3 | imm | rd/rs1 |     | imm |     | op  |
| --- | ------ | --- | ------ | --- | --- | --- | --- |
CS-Type
|     | funct3 | imm |       | rs1'     | imm    | rs2' | op          |
| --- | ------ | --- | ----- | -------- | ------ | ---- | ----------- |
|     | funct6 |     |       | rd'/rs1' | funct2 | rs2' | op CS -Type |
|     | funct3 | imm |       | rs1'     | imm    |      | op CB-Type  |
|     | funct3 | imm | funct | rd'/rs1' | imm    |      | op CB -Type |
|     | funct3 | imm |       |          |        |      | op CJ-Type  |
CSS-Type
|     | funct3 | imm |     |     | rs2 |     | op  |
| --- | ------ | --- | --- | --- | --- | --- | --- |
CIW-Type
|     | funct3                                 | imm |     |      |     | rd'          | op         |
| --- | -------------------------------------- | --- | --- | ---- | --- | ------------ | ---------- |
|     | funct3                                 | imm |     | rs1' |     |              | op CL-Type |
|     |                                        |     |     |      | imm | rd'          |            |
| 171 | Digital Design & Computer Architecture |     |     |      |     | Architecture |            |

Chapter 6: Architecture
Floating-Point
Instructions

RISC-V Floating-Point Extensions
• RISC-V offers three floating point extensions:
• RVF: single-precision (32-bit)
• 8 exponent bits, 23 fraction bits
• RVD: double-precision (64-bit)
• 11 exponent bits, 52 fraction bits
• RVQ: quad-precision (128-bit)
• 15 exponent bits, 112 fraction bits
173 Digital Design & Computer Architecture Architecture

Floating-Point Registers
• 32 Floating point registers
• Width is highest precision – for example, if
RVQ is implemented, registers are 128 bits
wide
• When multiple floating point extensions are
implemented, the lower-precision values
occupy the lower bits of the register
174 Digital Design & Computer Architecture Architecture

Floating-Point Registers
| Name |     | Register Number | Usage |
| ---- | --- | --------------- | ----- |
ft0-7
|     |     | f0-7 | Temporary variables |
| --- | --- | ---- | ------------------- |
fs0-1
|        |     | f8-9   | Saved variables                  |
| ------ | --- | ------ | -------------------------------- |
| fa0-1  |     | f10-11 | Function arguments/Return values |
| fa2-7  |     | f12-17 | Function arguments               |
| fs2-11 |     | f18-27 | Saved variables                  |
ft8-11
|     |                                        | f28-31 | Temporary variables |
| --- | -------------------------------------- | ------ | ------------------- |
| 175 | Digital Design & Computer Architecture |        | Architecture        |

Floating-Point Instructions
•
|     | Append  | .s  (single),  |     | .d  (double),  |     | .q  | (quad)  | for  |
| --- | ------- | -------------- | --- | -------------- | --- | --- | ------- | ---- |
precision. I.e., fadd.s, fadd.d, and fadd.q
| •   | Arithmetic operations |     |     |     |     |     |     |     |
| --- | --------------------- | --- | --- | --- | --- | --- | --- | --- |
:
|     | fadd,  | fsub,  | fdiv,  | fsqrt,  | fmin,  | fmax,  | multiply-add  |     |
| --- | ------ | ------ | ------ | ------- | ------ | ------ | ------------- | --- |
(fmadd, fmsub, fnmadd, fnmsub)
| •   | Other instructions:                |     |     |     |     |     |     |     |
| --- | ---------------------------------- | --- | --- | --- | --- | --- | --- | --- |
|     | move (fmv.x.w, fmv.w.x)            |     |     |     |     |     |     |     |
|     | convert (fcvt.w.s, fcvt.s.w, etc.) |     |     |     |     |     |     |     |
comparison (feq, flt, fle)

classify (fclass)

|     | sign injection (fsgnj, fsgnjn, fsgnjx) |     |     |     |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | --- | --- | --- |
   See Appendix B for additional RISC-V floating-point instructions.
| 176 | Digital Design & Computer Architecture |     |     |     | Architecture |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | ------------ | --- | --- | --- |

Floating-Point Multiply-Add
| •   | fmadd is the most critical instruction for signal  |     |
| --- | -------------------------------------------------- | --- |
processing programs.
| •                                  | Requires four registers.               |                      |
| ---------------------------------- | -------------------------------------- | -------------------- |
|            fmadd.f f1, f2, f3, f4  |                                        |  # f1 = f2 x f3 + f4 |
| 177                                | Digital Design & Computer Architecture | Architecture         |

Floating-Point Example
| C Code |              | RISC-V assembly code               |     |
| ------ | ------------ | ---------------------------------- | --- |
| int i; |              | # s0 = scores base address, s1 = i |     |
| float  | scores[200]; |   addi s1, zero, 0        # i = 0  |     |
  addi t2, zero, 200      # t2 = 200
  addi t0, zero, 10       # ft0 = 10.0
  fcvt.s.w ft0,  t0
| for (i=0; i<200; i=i+1) |     | for: |     |
| ----------------------- | --- | ---- | --- |
  bge    s1, t2, done     # i>=200? done
  slli   t0, s1, 2        # t0 = i*4
  add    t0, t0, s0       # scores[i] address
scores[i]=scores[i]+10;   flw    ft1, 0(t0)       # ft1=scores[i]
  fadd.s ft1, ft1, ft0    # ft1=scores[i]+10
  fsw    ft1, 0(t0)       # scores[i] = t1
  addi   s1, s1, 1        # i = i+1
  j      for              # repeat
done:
| 178 | Digital Design & Computer Architecture |     | Architecture |
| --- | -------------------------------------- | --- | ------------ |

Floating-Point Instruction Formats
•
Use R-, I-, and S-type formats
•
|     | Introduce     |     |     | another  |       | format  |     | for       | multiply-add  |            |     |
| --- | ------------- | --- | --- | -------- | ----- | ------- | --- | --------- | ------------- | ---------- | --- |
|     | instructions  |     |     |          | that  | have    | 4   | register  |               | operands:  |     |
R4-type
|     |     |           |       |       |         | R 4 - T   | y p e   |       |       |     |       |
| --- | --- | --------- | ----- | ----- | ------- | --------- | ------- | ----- | ----- | --- | ----- |
|     |     |           | 2 6 : | 2 5   | 2 4 : 2 | 0 1 9 : 1 | 5 1 4 : | 1 2   | 1 1 : | 7   | 6 : 0 |
|     |     | 3 1 : 2 7 |       |       |         |           |         |       |       |     |       |
|     |     | r s 3     | f u n | c t 2 | r s 2   | r s 1     | f u n   | c t 3 | r d   |     | o p   |
5   b i t s 2   b i t s 5   b i t s 5   b i t s 3   b i t s 5   b i t s 7   b i t s
| 179 | Digital Design & Computer Architecture |     |     |     |     |     | Architecture |     |     |     |     |
| --- | -------------------------------------- | --- | --- | --- | --- | --- | ------------ | --- | --- | --- | --- |

Chapter 6: Architecture
Exceptions

Exceptions
|     | • Unscheduled function call to exception handler |     |
| --- | ------------------------------------------------ | --- |
|     | • Caused by:                                     |     |
– Hardware, also called an interrupt, e.g., keyboard
– Software, also called traps, e.g., undefined instruction
|     | • When exception occurs, the processor: |     |
| --- | --------------------------------------- | --- |
–
Records the cause of the exception
– Jumps to exception handler
–
Returns to the program
| 181 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Exception Causes
Exception Cause
|     | Instruction address misaligned         | 0            |
| --- | -------------------------------------- | ------------ |
|     | Instruction access fault               | 1            |
|     | Illegal instruction                    | 2            |
|     | Breakpoint                             | 3            |
|     | Load address misaligned                | 4            |
|     | Load access fault                      | 5            |
|     | Store address misaligned               | 6            |
|     | Store access fault                     | 7            |
|     | Environment call from U-Mode           | 8            |
|     | Environment call from S-Mode           | 9            |
|     | Environment call from M-Mode           | 11           |
| 182 | Digital Design & Computer Architecture | Architecture |

RISC-V Privilege Levels
|     | • In RISC-V, exceptions occur at various privilege levels. |     |
| --- | ---------------------------------------------------------- | --- |
|     | • Privilege levels limit access to memory or certain       |     |
(privileged) instructions.
|     | • RISC-V privilege modes are (from highest to lowest): |     |
| --- | ------------------------------------------------------ | --- |
– Machine mode (bare metal)
– System mode (operating system)
– User mode (user program)
–
Hypervisor mode (to support virtual machines)
|     | • For example, a program running in M-mode (machine  |     |
| --- | ---------------------------------------------------- | --- |
mode) can access all memory or instructions – it has
the highest privilege level.
| 183 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Exception Registers
|     | • Each privilege level has registers to handle exceptions  |     |
| --- | ---------------------------------------------------------- | --- |
|     | • These registers are called control and status registers  |     |
(CSRRs)
|     | • We discuss M-mode (machine mode) exceptions, but  |     |
| --- | --------------------------------------------------- | --- |
other modes are similar
|     | • M-mode registers used to handle exceptions are: |     |
| --- | ------------------------------------------------- | --- |
– mtvec, mcause, mepc, mscratch
(Likewise, S-mode exception registers are: stvec, scause,
sepc, and mscratch; and so on for the other modes.)
| 184 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Exception Registers
• CSRRs are not part of register file
• M-mode CSRRs used to handle exceptions
– mtvec: holds address of exception handler code
– mcause: Records cause of exception
– mepc (Exception PC): Records PC where exception
occurred
– mscratch: scratch space in memory for
exception handlers
185 Digital Design & Computer Architecture Architecture

Exception-Related Instructions
• Called privileged instructions (because they
access CSRRs)
– csrr: CSR register read
– csrw: CSR register write
– csrrw: CSR register read/write
– mret: returns to address held in mepc
• Examples:
csrr t1, mcause # t1 = mcause
csrw mepc, t2 # mepc = t2
cwrrw t0, mscratch, t1 # t0 = mscratch
# mscratch = t1
186 Digital Design & Computer Architecture Architecture

Exception Handler Summary
• When a processor detects an exception:
– It jumps to exception handler address in mtvec
– The exception handler then:
• saves registers on small stack pointed to by mscratch
• Uses csrr (CSR read) to look at cause of exception (in
mcause)
• Handles exception
• When finished, optionally increments mepc by 4 and
restores registers from memory
• And then either aborts the program or returns to user
code (using mret, which returns to address held in
mepc)
187 Digital Design & Computer Architecture Architecture

Example Exception Handler Code
|     | • Check for two types of exceptions: |     |
| --- | ------------------------------------ | --- |
• Illegal instruction (mcause = 2)
• Load address misaligned (mcause = 4)
| 188 | Digital Design & Computer Architecture | Architecture |
| --- | -------------------------------------- | ------------ |

Example Exception Handler Code
# save registers that will be overwritten
csrrw t0, mscratch, t0 # swap t0 and mscratch
sw t1, 0(t0) # [mscratch] = t1
sw t2, 4(t0) # [mscratch+4] = t2
# check cause of exception
csrr t1, mcause # t1=mcause
addi t2, x0, 2 # t2=2 (illegal instruction exception code)
illegalinstr:
bne t1, t2, checkother # branch if not an illegal instruction
csrr t2, mepc # t2=exception PC
addi t2, t2, 4 # increment exception PC
csrw mepc, t2 # mepc=t2
j done # restore registers and return
checkother:
addi t2, x0, 4 # t2=4 (load address misaligned exception code)
bne t1, t2, done # branch if not a misaligned load
j exit # exit program
# restore registers and return from the exception
Checks for two types of
done:
exceptions:
lw t1, 0(t0) # t1 = [mscratch]
lw t2, 4(t0) # t2 = [mscratch+4] • Illegal instruction
csrrw t0, mscratch, t0 # swap t0 and mscratch (mcause = 2)
mret # return to program
• Load address misaligned
exit:
(mcause = 4)
...
189 Digital Design & Computer Architecture Architecture

About these Notes
Digital Design and Computer Architecture Lecture Notes
© 2021 Sarah Harris and David Harris
These notes may be used and modified for educational and/or
non-commercial purposes so long as the source is attributed.
190 Digital Design & Computer Architecture Architecture