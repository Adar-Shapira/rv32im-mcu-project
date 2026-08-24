VHDL – Package
(Private Sub-Library)

©Hanan Ribo

1

•

Introduction
In order to allow common pieces of code to be reused, shared and partitioning, it is
more usual to place them in a LIBRARY, which is helpful when dealing with long codes.
• Generally, frequently used pieces of code can be written in the form of COMPONENTS,
FUNCTIONS, or PROCEDURES, then placed in a PACKAGE, which is finally compiled into
the destination LIBRARY.

• As we have already seen, that at least three LIBRARIES are generally needed in a

design: ieee, std, and work. In this chapter we will learn how to construct our own sub-
libraries using Package (VHDL element), which can then be added to the work LIBRARY.

©Hanan Ribo

2

PACKAGE

• As mentioned, the importance of this technique is that it allows code

partitioning, code sharing, and code reuse.

• Package syntax is composed of two parts (must have the same name):

 Package declarative part – mandatory.
 Package Body - necessary only when FUNCTION or PROCEDURE are declared in the

upper part, in which case it must contain the descriptions (bodies) of the subprograms.

• The declarative part can contain the following elements:
COMPONENT, FUNCTION, PROCEDURE, TYPE, CONSTANT, etc.

• Package syntax:

©Hanan Ribo

3

PACKAGE – example 1

Package with Declarative part only:

©Hanan Ribo

4

PACKAGE – example 2

Package with Declarative and Body parts:

©Hanan Ribo

5

