.text

.globl addMat
.globl subMat
.globl xorMat
#------------------------------------------------------
# 						Matrix addition function
#------------------------------------------------------
addMat:
	mv s7,a0
	mv s1,a1
	mv s2,a2
	mv s6,a3
loop1:
	lw s3, 0(s1) 			# s3 = arr1[i] = Mem[s1]
	addi s1,s1,4
	lw s4, 0(s2)			# s4 = arr2[i] = Mem[s2]
	addi s2,s2,4
	add s5,s3,s4
	addi s7,s7,-1
	sw s5,0(s6)				# Mem[s6] = res1[i]= arr1[i]+arr2[i] 
	addi s6,s6,4
	bne  s7,x0,loop1
	ret
#------------------------------------------------------
# 						Matrix subtraction function
#------------------------------------------------------
subMat:
	mv s7,a0
	mv s1,a1
	mv s2,a2
	mv s6,a3
loop2:
	lw s3, 0(s1) 			# s3 = arr1[i] = Mem[s1]
	addi s1,s1,4
	lw s4, 0(s2)			# s4 = arr2[i] = Mem[s2]
	addi s2,s2,4
	sub s5,s3,s4
	addi s7,s7,-1
	sw  s5,0(s6)			# Mem[s6] = res2[i]= arr1[i]-arr2[i]
	addi s6,s6,4
	bne  s7,x0,loop2
	ret
#------------------------------------------------------
# 						Matrix xor function
#------------------------------------------------------
xorMat:
	mv s7,a0
	mv s1,a1
	mv s2,a2
	mv s6,a3
loop3:
	lw s3, 0(s1) 			# s3 = arr1[i] = Mem[s1]
	addi s1,s1,4
	lw s4, 0(s2)			# s4 = arr2[i] = Mem[s2]
	addi s2,s2,4
	xor s5,s3,s4
	addi s7,s7,-1
	sw  s5,0(s6)			# Mem[s6] = res3[i]= arr1[i]^arr2[i]
	addi s6,s6,4
	bne  s7,x0,loop3
	ret
	
