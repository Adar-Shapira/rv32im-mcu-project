.globl main
.data

size: .word  100
mat1: .word  
			 1 ,2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10,
	     11,12,13,14,15,16,17,18,19,20,
	     21,22,23,24,25,26,27,28,29,30,
	     31,32,33,34,35,36,37,38,39,40,
	     41,42,43,44,45,46,47,48,49,50,
	     51,52,53,54,55,56,57,58,59,60,
	     61,62,63,64,65,66,67,68,69,70,
	     71,72,73,74,75,76,77,78,79,80,
	     81,82,83,84,85,86,87,88,89,90,
	     91,92,93,94,95,96,97,98,99,100,
	     
mat2: .word  
			 100,99,98,97,96,95,94,93,92,91,
	      90,89,88,87,86,85,84,83,82,81,
	      80,79,78,77,76,75,74,73,72,71,
	      70,69,68,67,66,65,64,63,62,61,
	      60,59,58,57,56,55,54,53,52,51,
	      50,49,48,47,46,45,44,43,42,41,
	      40,39,38,37,36,35,34,33,32,31,
	      30,29,28,27,26,25,24,23,22,21,
	      20,19,18,17,16,15,14,13,12,11,
	      10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
	      
res1: .space 400  # size*4=400[Byte] - ADD result array
res2: .space 400  # size*4=400[Byte] - MUL result array
res3: .space 400  # size*4=400[Byte] - SUB result array


.text
main:
	la s0, size		# s0 points to size
	lw s0,0(s0)		# s0 = Mem[s0] = size
	la t1, mat1   # t1 points to mat1
	la t2, mat2		# t2 points to mat2
	la s1, res1		# s1 points to res1
	la s2, res2		# s2 points to res2
	la s4, res3		# s4 points to res3
	
loop:
	lw t3, 0(t1) 	# t3 = mat1[i] = Mem[t0]
	lw t4, 0(t2)	# t4 = mat2[i] = Mem[t1]
	
	add t5,t3,t4
	sw  t5,0(s1)	# Mem[s1] = res1[i]= mat1[i]+mat2[i]
	
	mul t5,t3,t4
	sw  t5,0(s2)	# Mem[s2] = res2[i]= mat1[i]*mat2[i]
	
	sub t5,t3,t4
	sw  t5,0(s4)	# Mem[s4] = res3[i]= mat1[i]-mat2[i]
	
	addi t1,t1,4
	addi t2,t2,4
	addi s1,s1,4
	addi s2,s2,4
	addi s4,s4,4
	addi s0,s0,-1
	
	bne  s0,x0,loop
	
end:	beq x0,x0,end
	 
