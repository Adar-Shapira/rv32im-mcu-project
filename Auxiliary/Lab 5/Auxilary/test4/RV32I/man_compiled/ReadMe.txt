1) How to activate MARS multiple files project:

MARS simulator has "Settings/Assemble all files in directory" setting, which allows for multiple files to link into single program.
When switch to the editor tab with main.asm (! important, when the edit tab is switched to func.asm, the build process
will execute func.asm result as stand-alone app - a bit clunky and weird behaviour), and hit build button (with the "all files" setting ON), 
the resulting binary will start in main.asm by loading $t5 with address, and then calling the printAsciiz function from func.asm.

2) What is a syscall instruction:

The syscall is used to request a service from the kernel (On a real MIPS machine, you would use syscall transfer control the kernel to 
invoke a specific function). For MIPS, the service number/code must be passed in $v0 and arguments are passed
in a few of the other designated registers. 
For example, to print we might do:

	li $v0, 1
	add $a0, $t0, $zero
	syscall

3) Advanced example of a syscall instruction:

For example, this is a basic hello world program in MIPS 32-bit assembly for a linux machine.
---------------------------------------------------------------------------------------------
# CS341L Fall 2008
# Lab Exercise #1
# Matthew J. Barrick <barrick@cs.unm.edu>

#include <asm/regdef.h> 
#include <sys/syscall.h>

.data
    hello:  .asciz  "Hello World\n"
    length: .word   12
.text
    .globl  main
    .ent    main
main:
    li  a0, 1
    la  a1, hello
    lw  a2, length
    li  v0, SYS_write
    syscall
    move    v0, zero
    jr  ra
    .end    main
----------------------------------------------------------------------------------------------
This corresponds very closely to the C code (if you have trouble following the MIPS assembly).
------------------------------------
#include <stdio.h>

int main(int argc, char** argv) {
    char* hello = "Hello World\n";
    write(STDOUT_FILENO,hello, 12);
    return 0;
}
------------------------------------
First note that headers are included to give the registers symbolic names (asm/regdef.h) and a header that will pull in symbolic names 
for the system calls (sys/syscall.h) so we don't have to refer to the syscalls by number. The conventions for making a system call here 
are pretty much the same as calling a function, load a# register with arguments, then we load which system call we want into $v0 and 
invoke syscall. SYS_write corresponds to the basic write(2) function for linux/unix (1 being standard out).
--------------------------------------------------------
ssize_t write(int fd, const void *buf, size_t count);
--------------------------------------------------------
So we're telling the kernel to write to the file handle 1 (stdout), the string hello, using length bytes. On linux you can see syscalls(2) 
for all the different syscalls available but they pretty much correspond the core functions that the kernel provides and that (g)libc 
either wraps or builds upon for C/C++ programs.

Linux (and most unix-likes going back the 4BSD route) have a function syscall(2) which is effectively the same thing.

Once you start doing more complex stuff you'll either find yourself wrapping the syscall invoking into handy functions, or better yet 
just calling the corresponding libc versions (surprisingly easy to do, but another discussion).
