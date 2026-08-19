data segment:	;DTCM content
arr1 dc16 63,542,245,190,91,86,78,64,83,16,24,62,79,19
arr2 dc16 13,312,141,160,92,88,71,63,59,14,43,12,71,90
res ds16 14

code segment:	;ITCM content
mov r1,arr1
mov r2,arr2
mov r3,res
mov r4,0
mov r5,1
mov r6,14
ld  r7,0(r1)
ld  r8,0(r2)
and r9,r4,r5
sub r10,r9,r5
jc  2
sub r9,r7,r8
jmp 1
add r9,r7,r8
st  r9,0(r3)
add r1,r1,r5
add r2,r2,r5
add r3,r3,r5
add r4,r4,r5
sub r10,r4,r6 
jlo -15
done
nop
jmp -2