.data
wid:	.word	10
hgt:	.word	10
cx:	.word	0
cy:	.word	0
numLeft: .word	0
board: .space	1600

welcome: .asciiz	"Welcome to the maze generator!"
dimPrompt: .asciiz	"Choose a dimension between 5 and 40 (If you choose above or below it will default to upper or lower bound"

.text

getSize:
lw $a0,welcome
li $v0,4
syscall
lw $a0,dimPrompt
li $v0,4
syscall
li $v0,5
syscall
li $t5,5
blt $v0,$t5,lessThan5
li $t5,40
bgt $v0,$t5,greaterThan40
move $t1,$v0
move $t2,$v0							#For general reference, t1 is width and t2 is height
jr $ra									#set to the main routine, this is our way back
greaterThan40:
addi $t1, $t1, 40						
addi $t2, $t2, 40
jr $ra
lessThan5:
addi $t1, $t1, 5
addi $t2, $t2, 5
jr $ra

initBoard:
la $t0,board 							#t0 is the register our board is stored in.
addi $t1, $t1, 1						#Add 1 to our width and height to account for the outer border. Because we start at 0 in our array we already get the +1
addi $t2, $t2, 1						
move $t3,$0 							#make the width counter 0 to begin the loop
move $t4,$0								#Width is t3, height is t4
move $t6,$0
addi $t6, $t6, 5
initBoardTopRow:
beq $t3, $t1, initBoardLoopBegin		#the first row of entries needs to be 5. The bottom also needs to be 5 but we do that last before we return
sw $t6, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j initBoardTopRow
initBoardLoopBegin:
move $t3,$0
addi $t0 $t0, 4
addi $t3, $t3, 1
initBoardLoopMainRoutine:
beq $t4, $t2, initBoardBottomRow
beq $t3, $0, leftEdge						#Go to edge if the loop counter is 0 or = t1 (our width)
beq $t3, $t1, rightEdge
sw $0, 0($t0)
addi $t0 $t0, 4
addi $t3, $t3, 1
j initBoardLoopMainRoutine
leftEdge: 									
sw $t6, 0($t0)
addi $t0 $t0, 4
addi $t3, $t3, 1
j initBoardLoopMainRoutine
rightEdge: 									
sw $t6, 0($t0)
move $t3,$0								#reset our width loop since this is the right edge. Increment height counter by 1 instead. Still increment our array since
addi $t0 $t0, 4							#edges are stored in the array back to back
addi $t4, $t4, 1
j initBoardLoopMainRoutine
initBoardBottomRow:
beq $t3, $t1, initBoardReturn		#Here we account for our last row. It is a row of 5's so we simply need to keep track of our width and proceed to
sw $t6, 0($t0)						#break out of the loop if the width is the same as our maze width
addi $t0, $t0, 4
addi $t3, $t3, 1
j initBoardBottomRow
initBoardReturn:

jr $ra

placeInSquare:
lw $t0, wid 							#Trying to respect order of operations here
lw $t1, cy
mult $t0, $t1
mflo $t0
lw $t1, cx
add $t0, $t0, $t1
lw $t1, board
add $t0, $t0, $t1
sw $a0, 0($t0)
jr $ra

pickEntrance:
addi $sp, $sp, 4						#Wasnt sure how big ra was so I just allocated enough for a word
sw $ra, 0($sp)
li $a0, $t1								#why???
addi $a0, $a0, -1
jal rand
beq $v0, $0, pickEntranceReturns0
pickEntranceRoutine:
move $a0,$0
addi $a0, $a0, 4
mult $a0, $v0
mflo $v0
move $a0,$0
addi $a0, $a0, 4
mult $a0, $t1
addi $a0, $a0, 1
sw $a0, 0($v0)
sw $v0, cx								#We set cx to be the ADDRESS of the entrance
lw $ra, 0($sp)					
addi $sp, $sp, -4
jr $ra 									#this is where we exit the routine. After possibly bounding to the 'if we get 0 back' 
pickEntranceReturns0:
addi $v0, $v0, 1
j pickEntranceRoutine

pickExit:
addi $sp, $sp, 4				
sw $ra, 0($sp)
li $a0, $t1
addi $a0, $a0, -1
jal rand
beq $v0, $0, pickExitReturns0
pickExitRoutine:
move $a0,$0
addi $a0, $a0, 4
mult $a0, $v0
mflo $v0
move $a0,$0
li $a0, $t2
mult $a0, $v0					#Exit address is gonna be RandomValue * 4 (for integer) * height, we then put the exit address in v0
mflo $v0
move $a0,$0
addi $a0, $a0, 1				#load 1 into a0 to mark the exit
sw $a0, 0($v0)
lw $ra, 0($sp)					
addi $sp, $sp, -4
jr $ra 							#this is where we exit the routine. After possibly bounding to the 'if we get 0 back' 
pickExitReturns0:
addi $v0, $v0, 1
j pickExitRoutine

printBoard:
#t9 is counter for rows
#t5 is counter for columns
printBoardMain:
