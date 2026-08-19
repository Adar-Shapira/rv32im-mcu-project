.globl main
.data
arr1:
        .word   1
        .word   2
        .word   3
        .word   4
        .word   5
        .word   6
        .word   7
        .word   8
arr2:
        .word   8
        .word   7
        .word   6
        .word   5
        .word   4
        .word   3
        .word   2
        .word   1
res1:
        .space   32
res2:
        .space   32
res3:
        .space   32
SIZE:
        .word   8

.text
main:
        addi    sp,sp,-32			# sp -= 32 (allocate stack size of 32 bytes)
        sw      ra,28(sp)			# DTCM[sp+28] = RF[ra]
        sw      s0,24(sp)			# DTCM[sp+24] = RF[s0] (s0 is the function's frame pointer, fp)
        addi    s0,sp,32			# s0 = sp+32 (write to fp the stack's start address)
        sw      zero,-20(s0)	# DTCM[s0-20] = 0x00000000
        j       .L2
.L3:
        la     	a4,arr1				# a4 = arr1
        lw      a5,-20(s0)		# a5 = DTCM[s0-20] = 0x00000000 (index i=0)
        slli    a5,a5,2				# a5 = a5 << 2 = a5*4 (get the offset address of i)
        add     a5,a4,a5			# a5 = a4 + a5 (addres of arr1[i])
        lw      a4,0(a5)			# a4 = DTCM[a5] (arr1[i] value)
        la     	a3,arr2				# a3 = arr2
        lw      a5,-20(s0)		# a5 = DTCM[s0-20] = 0x00000000
        slli    a5,a5,2				# a5 = a5 << 2 = a5*4 (get the offset address of i)
        add     a5,a3,a5			# a5 = a3 + a5 (addres of arr2[i])
        lw      a5,0(a5)			# a5 = DTCM[a5] (arr2[i] value)
        add     a4,a4,a5			# a4 = a4 + a5 (arr1[i] + arr2[i])			
        la     	a3,res1				# a3 = res1				
        lw      a5,-20(s0)		# a5 = DTCM[s0-20] = 0x00000000 (index i=0)
        slli    a5,a5,2				# a5 = a5 << 2 = a5*4 (get the offset address of i)
        add     a5,a3,a5			# a5 = a3 + a5 (addres of res1[i])
        sw      a4,0(a5)			# DTCM[a5] = a4 (res1[i] = arr1[i] + arr2[i])
        la     	a4,arr1
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,0(a5)
        la     	a3,arr2
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        lw      a5,0(a5)
        sub     a4,a4,a5
        la     	a3,res2
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,0(a5)
        la     	a4,arr1
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a4,a5
        lw      a4,0(a5)
        la     	a3,arr2
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        lw      a5,0(a5)
        xor     a4,a4,a5
        la     	a3,res3
        lw      a5,-20(s0)
        slli    a5,a5,2
        add     a5,a3,a5
        sw      a4,0(a5)
        lw      a5,-20(s0)
        addi    a5,a5,1
        sw      a5,-20(s0)
.L2:
        la     	a5,SIZE			# a5 = &SIZE = 0x
        lw      a5,0(a5)		# a5 = SIZE = 8
        lw      a4,-20(s0)	# a4 = DTCM[s0-20] = 0x00000000
        blt     a4,a5,.L3		# if(a4 < a5) j .L3 
.L4:
        j       .L4