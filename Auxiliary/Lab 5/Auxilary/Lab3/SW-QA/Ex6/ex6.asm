data segment:	;DTCM content
arr dc16 63,542,245,190,91,86,78,64,83,16,24,62,79,19
arr_odds dc16 0
arr_evens dc16 0

code segment:	;ITCM content
mov r1,arr
mov r2,0
mov r3,0
mov r4,0
mov r5,1
mov r6,14
ld  r7,0(r1)
and r8,r7,r5
sub r9,r8,r5
jc  2
add r3,r3,r7
jmp 1
add r2,r2,r7
add r1,r1,r5
add r4,r4,r5
sub r10,r4,r6 
jlo -11
mov r8,arr_odds
mov r9,arr_evens
st  r2,0(r8)
st  r3,0(r9)
done
nop
jmp -2