.data
seed: 	.word 	31415
wid:	.word	10
hgt:	.word	10
width:		.word	0
height:		.word	0
numLeft: .word	0
board: .space	1600
poolOfMoves: .space 	25
currentMazeLocation: .word 10


welcome: .asciiz	"Welcome to the maze generator!"
dimPrompt0: .asciiz "\nChoose a width between 5 and 40: "
dimPrompt1: .asciiz	"\nChoose a height between 5 and 40: "
dimPrompt2: .asciiz "Not a valid answer! Defaulted to upper or lower bounds.\n"
dimPrompt3: .asciiz "\n"

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
jal pickExit
jal pickEntrance
lw $t1, width
lw $t2, height
mult $t1, $t2
mflo $t0
addi $t0, $t0, -1
sw $t0, numLeft
MaintakeMoveLoop:
jal takeMove
lw $t4, numLeft 				#check numLeft. If it is 0 then go to printboard
beq $t4, $0, MainSkiptakeMove
j MaintakeMoveLoop
MainSkiptakeMove:
jal printBoard

















getSize:
la $a0, welcome
li $v0, 4
syscall
la $a0, dimPrompt0 						#dimPrompt0 is for width
li $v0,4
syscall
li $v0,5
syscall
li $t5,5
blt $v0,$t5,lessThan5Width
li $t5,40
bgt $v0,$t5,greaterThan40Width
move $t1,$v0
getSizeStoreWidth:
sw $t1, width
getSizeHeightInput:
la $a0, dimPrompt1						#dimPrompt1 is for height
li $v0,4
syscall
li $v0,5
syscall
li $t5,5
blt $v0,$t5,lessThan5Height
li $t5,40
bgt $v0,$t5,greaterThan40Height
move $t2,$v0
getSizeStoreHeight:
sw $t2, height
la $a0, dimPrompt3
li $v0, 4
syscall
jr $ra 									#we are done here, return to main routine
greaterThan40Width:
addi $t1, $0, 40
la $a0, dimPrompt2
li $v0, 4
syscall
j getSizeStoreWidth
lessThan5Width:
addi $t1, $0, 5
la $a0, dimPrompt2
li $v0, 4
syscall
j getSizeStoreWidth
greaterThan40Height:
addi $t2, $0, 40
la $a0, dimPrompt2
li $v0, 4
syscall
j getSizeStoreHeight
lessThan5Height:
addi $t2, $0, 5
la $a0, dimPrompt2
li $v0, 4
syscall
j getSizeStoreHeight




initBoard:
la $t0,board 							#t0 is the register our board is stored in.
#addi $t1, $t1, 2						#
#addi $t2, $t2, 1						#disabled as a hacky fix, init board was making a board that was height+1.					
move $t3,$0 							#make the width counter 0 to begin the loop
move $t4,$0								#Width is t3, height is t4
move $t6,$0
addi $t6, $0, 5							#make t6 5 so we can move from t5 into the array to make indexs 5.
addi $t1, $t1, 2						#Add 2 to our width for our initBoardTopRow
initBoardTopRow:
beq $t3, $t1, initBoardLoopBegin		#the first row of entries needs to be 5. The bottom also needs to be 5 but we do that last before we return
sw $t6, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
beq $t3, $t1, initBoardLoopBegin		#the first row of entries needs to be 5. The bottom also needs to be 5 but we do that last before we return
j initBoardTopRow
initBoardLoopBegin:
move $t3,$0
lw $t1, width
addi $t1, $t1, 1 						#expand width by 1 for edges.
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
addi $t0, $t0, 4						#edges are stored in the array back to back so we should also get a hit to leftEdge after this.
addi $t4, $t4, 1
j initBoardLoopMainRoutine
initBoardBottomRowBegin:
move $t3,$0
lw $t1, width
addi $t1, $t1, 2 					#reload our width register, add 1 again to account for edge.
initBoardBottomRow:
#beq $t3, $t1, initBoardReturn		#Here we account for our last row. It is a row of 5's so we simply need to keep track of our width and proceed to
sw $t6, 0($t0)						#break out of the loop if the width is the same as our maze width

beq $t3, $t1, initBoardReturn		#Here we account for our last row. It is a row of 5's so we simply need to keep track of our width and proceed to
addi $t0, $t0, 4
addi $t3, $t3, 1
j initBoardBottomRow
initBoardReturn:
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
lw $t1, width
addi $t1, $t1, 2 						#add 2 to go past edges
addi $t0, $0, 4
mult $t0,$t1							#width+2 times 4
mflo $t0
la $a0, board 							#load board
add $a0, $t0, $a0						#add width+2*4 to address
addi $a0, $a0, 4						#adding 8 puts us past the 5's at the edge.
li $t0,1 								#re-appropriate t0 for 1 so we can store it at the address in a0.
sw $t0, 0($a0)
sw $a0, currentMazeLocation
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
sub $t0, $t0, $t3 				#here we actually do the subtraction. Now we need to add v0/our random number to t0 (our final location)
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


takeMove:
#t9 is current cell
#t5 is cell we are checking
#t1 is neighbor count
#t2 is number to check against
#t0 is going to be width+2*4 to easily access the south cell
#t4 is our array pointer
#t7 and are free for use

#We will use an array to choose our side we want to open to.

#Get the location from currentMazeLocation

#We will check each side, deferring to a subroutine if it is 0. If it is we jump to a subroutine, and in that subroutine we add 4 to the
#array pointer. We will not add 4 to the array pointer if it is NOT 0. We will repeat for every side as they all need their own routines
#to find their respective sides.

#NOTE: North cell will be 'current location address' - width+2*4. South cell will be 'current location address' + width+2*4
#NOTE: East cell is 'current address + 4', west cell is 'current address' -4

#We will also keep count of how many neighbors are 0. If only 1 is zero then get the number in index 0 of the array and depending only
#what that number is (1,2,3,4), we set the respective side to link to our current cell we are looking at.

#We will also check if all the sides are taken (if our count of neighbors is 0) then we do not do anything and break out of the loop. 

#Once this is done we MUST decrement numLeft.

#We then store the address of whatever cell we just linked to in currentMazeLocation and return.
#t2 is the number to check against so it must be left unchanged until we are done.

#final note: take move is regulated here. We will perform a check with numLeft everytime we enter takeMove.

addi $sp, $sp, 4	#save our return pointer to the stack, REMEMBER TO RETRIEVE AT THE END OF takeMOVE!!!!			
sw $ra, 0($sp)

move $t0,$0
move $t1,$0
move $t2,$0
move $t4,$0
move $t5,$0
move $t7,$0
move $t9,$0


lw $t4, numLeft 				#check numLeft. If it is 0 then we return.
beq $t4, $0, takeMoveReturn

lw $t9, currentMazeLocation							#treat is as a word because we stored it that way originally.
li $t4, 5
lw $t7, 0($t9)
beq $t7, $t4, takeMoveReturnIncrement 				#before we need to do anything we need to check if "currentMazeLocation" is 5. 
													#If it is we increment currentMazeLocation by 4 and return.

la $t4, poolOfMoves 			#t4 is array pointer, needs to start at beginning of poolOfMoves
lw $t0, width 					#get width+2*4 into t0
addi $t0, $t0, 2
li $t7, 4
mult $t7, $t0
mflo $t0 						#t0 is loaded with width+2*4 now.
li $t2, 0 						#t2 is what we check against
lw $t7, 0($t9)

#check left then right first as it's easier.
takeMoveCheckWest:
lw $t5, -4($t9)
beq $t5, $t2, takeMoveWestIsAvailable

takeMoveCheckEast:
lw $t5, 4($t9)
beq $t5, $t2, takeMoveEastIsAvailable

#now we need to check if the north and south are open.
#their addresses are t9 - t0 for North and t9 + t0 for South
takeMoveCheckNorth:
move $t5, $t9 							#copy t9 into t5 because we need to perform some 2-step arithmetic
sub $t5, $t5, $t0 						#and we need to preserve t5
lw $t5, 0($t5) 							#overwrite t5 with the value in the address the subtraction pointed to
										#watch this section in case this method doesnt work. Particularly LoadWord and storing an address.
beq $t5, $t2, takeMoveNorthIsAvailable

takeMoveCheckSouth:
move $t5, $t9 							#copy t9 into t5 because we need to perform some 2-step arithmetic
add $t5, $t5, $t0 						#and we need to preserve t5
lw $t5, 0($t5) 							#overwriting again
beq $t5, $t2, takeMoveSouthIsAvailable

takeMoveSelectCell:
beq $t1, $0, takeMove0Neighbors #if our neighbor count is 0, then set "CurrentLocationWeAreLookingAt" to the first address of the board 
								#This is so that when we fill the rest of the maze later we don't accidentally override any neighbors.

move $a0,$t1 					#takes our neighbor count and feeds it to rand.
jal rand

lw $t0, width 					#get width+2*4 into t0 AGAIN because it is overwritten with when we called rand
addi $t0, $t0, 2
li $t7, 4
mult $t7, $t0
mflo $t0 						#t0 is loaded with width+2*4 now.

li $t7, 4
mult $t7, $v0 					#takes the result of rand and multiplies *4 because it is an integer array
mflo $v0 						#moves it back to v0 for temporary use.
la $t7, poolOfMoves
add $t7, $v0, $t7
lw $t7, 0($t7)
#A number is true means we can link that cell to our current cell. Make sure not to mix the numbers you place at a location up. It is the
#opposite side of whatever number was picked.

li $t2, 4						#check if our picked side is 4
beq $t7, $t2, takeMovePickWest

li $t2, 2 						#check if we picked 2
beq $t7, $t2, takeMovePickEast

li $t2, 1
beq $t7, $t2, takeMovePickNorth

li $t2, 3
beq $t7, $t2, takeMovePickSouth

takeMovePickWest:
li $t7, 2
sw $t7, -4($t9)
j takeMoveReturnIncrement

takeMovePickEast:
li $t7, 4
sw $t7, 4($t9)
j takeMoveReturnIncrement

takeMovePickNorth:
li $t7, 3
lw $t9, currentMazeLocation
sub $t5, $t9, $t0 				#reuse t5 because we will increment t9 AKA "currentCellWeAreLookingAt" to the next cell.
sw $t7, 0($t5)					#in other words we are preserving t9 here and at the next comment below
j takeMoveReturnIncrement

takeMovePickSouth:
li $t7, 1
lw $t9, currentMazeLocation
add $t5, $t9, $t0 				#reuse t5 because we will increment t9 AKA "currentCellWeAreLookingAt" to the next cell.
sw $t7, 0($t5)
j takeMoveReturnIncrement

takeMove0Neighbors:
la $t7, board
sw $t7, currentMazeLocation
j takeMoveReturn

takeMoveReturnIncrement:
addi $t9, $t9, 4
sw $t9, currentMazeLocation 			#if we changed a cell we should be jumping here. numLeft gets decremented, currentMazeLocation
lw $t7, numLeft 						#gets overwritten. Then from here we will naturally move down to takeMoveReturn to
addi $t7, $t7, -1						#restore the stack pointer
sw $t7, numLeft
takeMoveReturn:
lw $ra, 0($sp)							#get the return address back from the stack			
addi $sp, $sp, -4
jr $ra

takeMoveWestIsAvailable:
li $t7, 4 				#4 indicates that the west cell is an option
sw $t7, 0($t4)
addi $t4, $t4, 4		#move array pointer over 4
addi $t1, $t1, 1 		#increment neighbor count
j takeMoveCheckEast
takeMoveEastIsAvailable:
li $t7, 2 				#2 indicates that the east cell is an option
sw $t7, 0($t4)
addi $t4, $t4, 4		#move array pointer over 4
addi $t1, $t1, 1 		#increment neighbor count
j takeMoveCheckNorth
takeMoveNorthIsAvailable:
li $t7, 1 				#4 indicates that the north cell is an option
sw $t7, 0($t4)
addi $t4, $t4, 4		#move array pointer over 4
addi $t1, $t1, 1 		#increment neighbor count
j takeMoveCheckSouth
takeMoveSouthIsAvailable:
li $t7, 3 				#3 indicates that the south cell is an option
sw $t7, 0($t4)
addi $t4, $t4, 4		#move array pointer over 4
addi $t1, $t1, 1 		#increment neighbor count
j takeMoveSelectCell
#we may want to consider an extra check if numLeft is 0 

printBoard: 
#t9 is counter for columns as we go across the row
#t5 is counter for rows as you travel down the maze
#t1 is ACTUAL width which we will get from the .word 'width'
#t2 is ACTUAL height which we will get from the .word 'height'
#t0, t7, and t4 are free for use


move $t0, $0 			#Wipe out t0, t4, t5 t7, t9 for computations
move $t4, $0
move $t9, $0
move $t5, $0
move $t7, $0
addi $t0, $t0, 4
lw $t1, width 			#get width into t1
addi $t1, $t1, 2 		#adds 2 to account for border
la $t8,board 			#puts the address of board in t8
mult $t1, $t0 			#multiply width by 4, put it in t0
mflo $t0
add $t8, $t0, $t8 		#add width*4 to t8 (board) to get starting address
addi $t8, $t8, 4		#Adds 4 to the final address because when we loop around to the second row the first entry is 5. Adding 4 puts the real first entry.

addi $v0, $0, 4						    #we will only be printing strings for this so v0 can be 4 for the duration.
lw $t1, width
lw $t2, height

move $t5, $0							#set our height counter to 0
#t3 will keep track of the cell above the current cell. We will have to check if it is open downward as it to can influence the North wall
#of the current cell
la $t3, board
add $t3, $t3, 4

#Quick reference: 
#t1 is width and t2 is our height. 
#t3 is the cell above our current cell
#t4 is the content of the cell above us during the north wall print phase
#t5 is the counter for rows (the height counter loop)
#t6 is the first cell we check
#t7 is our general computations register. 
#t8 is our current address
#t9 is the counter for columns (the loop as we move across)
#We come back here after we finish printing columns
printBoardNorthCheckStart:
addi $t7, $0, 1							#we will check against t7, since 1 tells us to print a door.
move $t6,$t8 							#t6 marks the address of the beginning of our row. We will save it since the columns needs it
printBoardNorthCheck:
lw $t0, 0($t8) 							#load the value in the board pointer to t0. This is to check the number
lw $t4, 0($t3)
beq $t9, $t1, printBoardEndOfRow

la $a0, mazeBorder						#always print the cute little plus signs, they come before every single square/cell
syscall									#also this should be after the EndOfRow subroutine as it will print its own border

beq $t7, $t0, printBoardNorthIsOpen		#our 'if statement' if the cell has "1" in it then do NOT print the north wall.
li $t7, 3 								#we also need to check the cell to the north. If it is 3 then we print an open door.
beq $t7, $t4, printBoardNorthIsOpen		#t4 is the reserved address for the cell above us
li $t7, 1 								#load 1 back into t7 for use next time around.
la $a0, mazeHorizontalWall				#if none of these are true then that means the north wall is closed. So print a closed wall.
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
bgt $t5, $t2, printBoardLastRow			#CHANGE THIS TO JUMP WHEREVER WE GO WHEN WE ARE DONE PRINTING OUR BOARD
j printBoardWestCheckStart

printBoardWestCheckStart:
#When we print the columns we will always print a column before doing any check
#we will reuse t9 as our loop counter, recall we set it to 0 in printBoardEndOfRow so that's taken care of
#t6 is already set to the first address of the same row, from when we printed the rows so we'll increment from there.
addi $t7, $0, 4							#t7 is what we'll be checking against
la $a0, mazeVerticalWall
syscall
printBoardWestCheck:
lw $t0, 0($t6)
beq $t9, $t1, printBoardEndOfRowColumn
beq $t0, $t7, printBoardWestIsOpen		#if our current 'cell/square' has a 4 in it (meaning west is open) then do NOT print the west wall
addi $t6, $t6, -4						#we also need to check the cell to the left, if it has 2 in it then we also do not print a door.
lw $t0, 0($t6)
li $t7, 2
beq $t0, $t7, printBoardWestIsOpenAdjacent
li $t7,4
addi $t6, $t6, 4						#after we check if the cell to the left is 2 then we undo our operations to t0 and t7
lw $t0, 0($t6)
la $a0, mazeVerticalWall
syscall
j printBoardWestIncrement
printBoardWestIsOpen:
la $a0, mazeVerticalDoor 				#print vertical door because west is open
syscall
j printBoardWestIncrement
printBoardWestIsOpenAdjacent:
la $a0, mazeVerticalDoor 				#print vertical door because west is open
syscall
li $t7,4								#Just like above, if the adjacent cell was not 2, we need to undo our operations
addi $t6, $t6, 4						#after we check if the cell to the left is 2 then we undo our operations to t0 and t7
lw $t0, 0($t6)
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
