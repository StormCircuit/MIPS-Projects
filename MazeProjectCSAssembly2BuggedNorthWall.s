.data
seed: 	.word 	31415
wid:	.word	10
hgt:	.word	10
width:		.word	0
height:		.word	0
numLeft: .word	0
board: .space	1600

welcome: .asciiz	"Welcome to the maze generator!\n"
dimPrompt: .asciiz	"Choose a dimension between 5 and 40 (If you choose above or below it will default to upper or lower bound"

mazeBorder: .asciiz	"+"
mazeBorderEndOfRow: .asciiz "+\n"
mazeHorizontalWall: .asciiz	"--"
mazeVerticalWall: .asciiz "|  "
mazeVerticalWallRightBorder: .asciiz "\n"
mazeHorizontalDoor: .asciiz "  "
mazeVerticalDoor: .asciiz "   "

.text
#Program begins here:
#t0 and t7 can be used after the subroutines but before printboard.
jal getSize
jal initBoard
#jal pickExit
jal pickEntrance
mult $t1, $t2
mflo $t0
addi $t0, $t0, -1
sw $t0, numLeft
jal printBoard

















getSize:
la $a0, welcome
li $v0, 4
syscall
la $a0, dimPrompt
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
										#set to the main routine, this is our way back
getSizeSaveSize:
sw $t1, width
sw $t2, height
jr $ra
greaterThan40:
addi $t1, $t1, 40						
addi $t2, $t2, 40
j getSizeSaveSize
lessThan5:
addi $t1, $t1, 5
addi $t2, $t2, 5
j getSizeSaveSize

initBoard:
la $t0,board 							#t0 is the register our board is stored in.
addi $t1, $t1, 1						#Add 1 to our width and height to account for the outer border. Because we start at 0 in our array we already get the +1
addi $t2, $t2, 1						
move $t3,$0 							#make the width counter 0 to begin the loop
move $t4,$0								#Width is t3, height is t4
move $t6,$0
addi $t6, $0, 5							#make t6 5 so we can move from t5 into the array to make indexs 5.
initBoardTopRow:
beq $t3, $t1, initBoardLoopBegin		#the first row of entries needs to be 5. The bottom also needs to be 5 but we do that last before we return
sw $t6, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j initBoardTopRow
initBoardLoopBegin:
move $t3,$0
initBoardLoopMainRoutine:
beq $t3, $0, leftEdge					#Go to leftedge if the loop counter is 0 
beq $t3, $t1, rightEdge					#go to rightedge if loop counter = width
beq $t4, $t2, initBoardBottomRow
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
addi $t0, $t0, 4						#edges are stored in the array back to back
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

#because we're doing our operations using addresses this may not be necessary
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
move $t0,$0								#we will use t0 to load numbers for computations
addi $sp, $sp, 4						#Wasnt sure how big ra was so I just allocated enough for a word
sw $ra, 0($sp)
move $a0, $t1
addi $a0, $a0, -2						#a0 -2 from the 5's at the edges, this prevents us from generating a number that puts us
jal rand 								#outside the interior of the maze
beq $v0, $0, pickEntranceReturns0
pickEntranceRoutine:
#load the address of the first entry in the array. Add width*4 to it and then add 4. This puts us at the beginning
#of the valid rows for an entrance. Now add random*4 to that to get a valid square to place our entrance
#Recall that Cx and Cy also need to be the square we end up choosing
addi $t0, $0, 4
mult $t0,$t1							#width times 4
mflo $t0
la $a0, board 							#load board
add $a0, $t0, $a0						#add width*4 to address
addi $a0, $a0, 4						#adding 4 puts us past the 5 at the edge.
#sw $t0, cx 							#Sorry about storing cx and cy, this will store the address of the entrance for use in takeMove
#sw $t0, cy  								 								
li $t0,1 								#re-appropriate t0 for 1 so we can store it at the address in a0.
sw $t0, 0($a0)
lw $ra, 0($sp)							#get the return address back from the stack			
addi $sp, $sp, -4
jr $ra 									#this is where we exit the routine. After possibly bounding to the 'if we get 0 back' 
pickEntranceReturns0:
addi $v0, $0, 1
j pickEntranceRoutine


pickExit:
#reg usage:
#v0 is our random number, add it to the final address to get the location of our exit.
#t0, t3, and t4 are all general use.
move $t0, $0
addi $sp, $sp, 4				
sw $ra, 0($sp)
lw $a0, width
#addi $a0, $a0, -2				#this is a hacky solution to pickexit choosing an edge. We're gonna limit its options here.
								#because of the arithmetic it should only choose a cell after the first 2
jal rand
beq $v0, $0, pickExitReturns0
pickExitRoutine:
addi $t0, $0, 4
mult $v0, $t0
mflo $v0						#this sets the random number to be *4.								
lw $t0, width 					#get width and height, then puts 4 in register t4
addi $t0, $t0, 2				#add 2 to both width and height to account for the borders
lw $t3, height
addi $t3, $t3, 2
li $t4, 4
mult $t0, $t3
mflo $t0
mult $t0, $t4 					#Multiply result of width*height by 4 to get to the end of the board. Now we need to regress to beginning of row.
mflo $t0
								#Subtract width+2*4 to get to beginning of row
lw $t3, width
addi $t3, $t3, 2
li $t4, 4
mult $t3, $t4
mflo $t3
add $t0, $t0, $t3 				#here we actually do the subtraction. Now we need to add v0/our random number to t0 (our final location)
add $t0, $t0, $v0
								#finally we need to load the address of board and add t0 to it.
la $t3, board
add $t0, $t3, $t0
li $t3, 1						#load the number 1 into t3.
sw $t3, 0($t0) 					#store the number 1 at the location in t0.
lw $ra, 0($sp)					
addi $sp, $sp, -4
jr $ra 							#this is where we exit the routine. After possibly bounding to the 'if we get 0 back' 
pickExitReturns0:
addi $v0, $0, 1
j pickExitRoutine


printBoard: 
#t9 is counter for columns as we go across the row
#t5 is counter for rows as you travel down the maze
#t1 is ACTUAL width which we will get from the .word 'width'
#t2 is ACTUAL height which we will get from the .word 'height'
#t0, t7, and t4 are free for use

move $t0, $0 			#Wipe out t0, t7 for computations
move $t7, $0
addi $t0, $t0, 4
lw $t1, width 			#get width into t1
addi $t1, $t1, 2 		#adds 2 to account for border
la $t8,board 			#puts the address of board in t8
mult $t1, $t0 			#multiply width by 4, put it in t0
mflo $t0
add $t8, $t0, $t8 		#add width*4 to t8 (board) to get starting address
#addi $t8, $t8, 4		#Adds 4 to the final address because when we loop around to the second row the first entry is 5. Adding 4 puts the real first entry.

addi $v0, $0, 4						    #we will only be printing strings for this so v0 can be 4 for the duration.
lw $t1, width
lw $t2, height
#addi $t1, $t1, -1						#we subtract 1 from the height and 1 from our width because we need to account for the 5's
#addi $t2, $t2, -1						#on either side.
move $t5, $0							#set our height counter to 0
#t3 will keep track of the cell above the current cell. We will have to check if it is open downward as it to can influence the North wall
#of the current cell
la $t3, board
add $t3, $t3, 4

#Quick reference: 
#t1 is width and t2 is our height. 
#t3 is the cell above our current cell
#t6 is the first cell we check
#t7 is our general computations register. 
#t8 is our current address
#t9 is the counter for columns (the loop as we move across)
#t5 is the counter for rows (the height counter loop)
#We come back here after we finish printing columns
printBoardNorthCheckStart:
addi $t7, $0, 1							#we will check against t7, since 1 tells us to print a door.
move $t6,$t8 							#t6 marks the address of the beginning of our row. We will save it since the columns needs it
lw $t0, 0($t8) 							#load the value in the board pointer to t0. This is to check the number
printBoardNorthCheck:
beq $t9, $t1, printBoardEndOfRow
beq $t7, $t0, printBoardNorthIsOpen		#our 'if statement' if the cell has "1" in it then do NOT print the north wall.
li $t7, 3 								#we also need to check the cell to the north. If it is 3 then we print an open door.
lw $t0, 0($t3)
beq $t7, $t3, printBoardNorthIsOpen
li $t7, 1 								#load 1 back into t7 for use next time around.
lw $t0, 0($t8)							#puts our curent cell back into t8
la $a0, mazeBorder						#always print the cute little plus signs, they come after every single square/cell
syscall
la $a0, mazeHorizontalWall
syscall
j printBoardNorthIncrement
printBoardNorthIsOpen:
la $a0, mazeHorizontalDoor
syscall
j printBoardNorthIncrement
printBoardNorthIncrement:
addi $t9, $t9, 1						#increment our width loop counter by 1
addi $t8, $t8, 4 						#add 4 to t8, our address to move to the next cell.
addi $t3, $t3, 4						#add 4 to t3, the address of the cell above the current one
j printBoardNorthCheck
printBoardEndOfRow:
la $a0, mazeBorderEndOfRow
syscall
move $t9,$0								#set our loop counter to 0
addi $t8, $t8, 8 						#increment our address by 8 because we have 2 edges back to back so we need to move 5 index spaces.
addi $t3, $t3, 8 						#increment t3 by 8 to move it to the next row as well.
addi $t5, $t5, 1						#t5 is our height loop. We want to NOT print the columns underneath the last row so when this equals our height we bail.
beq $t5, $t2, printBoardLastRow			#CHANGE THIS TO JUMP WHEREVER WE GO WHEN WE ARE DONE PRINTING OUR BOARD
j printBoardWestCheckStart

printBoardWestCheckStart:
#When we print the columns we will always print a column before doing any check
#we will reuse t9 as our loop counter, recall we set it to 0 in printBoardEndOfRow so that's taken care of
#t6 is already set to the first address of the next row, from when we printed the rows so we'll increment from there.
addi $t7, $0, 4							#t7 is what we'll be checking against
la $a0, mazeVerticalWall
syscall
printBoardWestCheck:
lw $t0, 0($t6)
beq $t9, $t1, printBoardEndOfRowColumn
beq $t0, $t7, printBoardWestIsOpen		#if our current 'cell/square' has a 4 in it (meaning west is open) then do NOT print the west wall
addi $t0, $t0, -4						#we also need to check the cell to the left, if it has 2 in it then we also do not print a door.
li $t7,2
beq $t0, $t7, printBoardWestIsOpen
li $t7,4
addi $t0, $t0, 4						#after we check if the cell to the left is 2 then we undo our operations to t0 and t7
la $a0, mazeVerticalWall
syscall
j printBoardWestIncrement
printBoardWestIsOpen:
la $a0, mazeVerticalDoor
syscall
j printBoardWestIncrement
printBoardWestIncrement:
addi $t9, $t9, 1
addi $t6, $t6, 4
j printBoardWestCheck
printBoardEndOfRowColumn:
la $a0, mazeVerticalWallRightBorder
syscall
move $t9,$0
j printBoardNorthCheckStart

printBoardLastRow:
#as opposed to printing columns we will simply exit instead here.
#PROGRAM IS INTENDED TO HALT HERE!!
li $v0,10
syscall

rand:
lw $v0, seed
sll $t0, $v0, 13
xor $v0, $v0, $t0
srl $t0, $v0, 17
xor $v0, $v0, $t0
sll $t0, $v0, 5
xor $v0, $v0, $t0
sw $v0, seed
andi $v0, $v0, 0xFFFF
div $v0, $a0
mfhi $v0
jr $ra
