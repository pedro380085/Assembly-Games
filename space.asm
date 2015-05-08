# MIPS assembly program written by Pedro Góes

# Additions since v1
#	- Default Scene

.data
# Store all important and starting data in this section, and make any other necessary notes
# even if it does endup huge being enourmous.

stageWidth:			.half 32			# Store stage size
stageHeight:		.half 32			# Usual settings $gp, 32x32, 16xScaling, 512x512

spaceX:			.half 7				# Store player position in memory
spaceY:			.half 5	

defaultDir:		.word 0x01000000		# Store default dir as right
shotDir:		.word 0x00000001		# Store default dir as right
	
drawColour:		.word 0x0022EE22		# Store colour to draw objects
bgColour:		.word 0x00000000		# Store colour to draw background
shotColour:         	.word 0x00EE2222      		# Store color for shot
monsterColour:         	.word 0x00859EE2      		# Store color for monster
							
.text
# Main and other methods go here. Hopefully they'll cooperate and play nicely, because 
# I really want to play snake, and there's definately not any snake clones available elsewhere...
Main:
			# Seed pseudorandom number generator 1 with lower order bytes of system clock
			ori $v0, $zero, 30		# Retrieve system time
			syscall
			or $a1, $zero, $a0		# Move the low order bytes to a1
			ori $a0, $zero, 1		# Set generator number
			ori $v0, $zero, 40		# Seed the generator with it
			syscall				

Main_init:
			# Load player info
			# S0 = SPACE LOCATION
			lh $a0, spaceX 			# Get player's head position
			lh $a1, spaceY			
			jal CoordsToAddress		# Calculate position in stage memory
			nop
			or $s0, $zero, $v0		# Store stage memory position in s0
			
			# S1 = SHOT POSITION
			ori $a0, $zero, 0
			ori $a1, $zero, 0
			jal CoordsToAddress
			nop
			or $s1, $zero, $v0
			# S2 = MONSTER POSITION
			ori $a0, $zero, 4
			ori $a1, $zero, 2
			jal CoordsToAddress
			nop
			or $s2, $zero, $v0

			# S4 = DEFAULT DIRECTION 
			lw $s4, defaultDir		# Store default dir in s4
			lw $s5, shotDir
			
			# Draw player's initial head
			lw $s6, drawColour		# Store drawing colour in s6
			or $a0, $zero, $s6		# Load draw colour	
			or $a1, $zero, $s0		# Load position
			jal PaintMemory			# Call the paint function
			nop

Scene_paint:
			# Load some scene defaults

			# Object on screen
			ori $a0, $zero, 11 			# Random position
			ori $a1, $zero, 10			
			jal CoordsToAddress
			or $a1, $zero, $v0			# Store stage memory position
			ori $a0, $zero, 0x00DE3875	# Store random colour
			jal PaintMemory				# Call the paint function
			nop

			ori $a0, $zero, 11
			ori $a1, $zero, 11			
			jal CoordsToAddress
			or $a1, $zero, $v0
			ori $a0, $zero, 0x00DE3875
			jal PaintMemory
			nop

			ori $a0, $zero, 10
			ori $a1, $zero, 11			
			jal CoordsToAddress
			or $a1, $zero, $v0
			ori $a0, $zero, 0x00DE3875
			jal PaintMemory
			nop

Main_waitLoop:
			# Wait for the player to press a key
			jal Sleep			# Zzzzzzzzzzz...
			nop
			lw $t0, 0xFFFF0000		# Retrieve transmitter control ready bit
			blez $t0, Main_waitLoop		# Check if a key was pressed
			nop

###############
# MAIN LOOP BEGIN
###############
Main_gameLoop:
			# Main game loop in which the program should spend most of it's time
			jal Sleep			# Sleep for 60 miliseconds so that the game is playable
			nop
			
			b Main_shotBegin	# Start game
			nop

###############
# SHOT 
###############
Main_shotBegin:
			lw $s7, bgColour
			or $a0, $zero, $s7		# Reset background
			or $a1, $zero, $s1		# Load addresss
			jal PaintMemory			# Call the paint function
			nop

			or $a0, $zero, $s1 			# Get player's head position
			jal AddressToCoords		# Calculate position in stage memory
			nop
			ori $a0, $zero, 0
			beq $v0, $a0, Main_monsterBegin
			lh $a0, stageWidth
			subi $a0, $a0, 1
			beq $v0, $a0, Main_monsterBegin
			
			or $t7, $zero, $s5
			or $a0, $zero, $s1		# Set a0 to current position
			or $a1, $zero, 1		# Set distance to one
							
Main_shotRight:
			bne, $t7, 0x00000001, Main_shotUp
			nop
			jal MoveRight			# Right
			nop
			j Main_shotDone
			nop
Main_shotUp:
			bne, $t7, 0x00000002, Main_shotLeft
			nop
			jal MoveUp			# Up
			nop
			j Main_shotDone
			nop
Main_shotLeft:
			bne, $t7, 0x00000003, Main_shotDown
			nop
			jal MoveLeft			# Left
			nop
			j Main_shotDone
			nop
Main_shotDown:
			bne, $t7, 0x00000004, Main_shotNone
			nop
			jal MoveDown			# Down
			nop
			j Main_shotDone
			nop
			
Main_shotNone:
			or $t7, $zero, $s5		# default to previous direction
			b Main_shotRight
			nop

Main_shotDone:
			or $s1, $zero, $v0		# Store player's new shot position

			lw $s7, shotColour
			or $a0, $zero, $s7		# Reset background
			or $a1, $zero, $s1		# Load addresss
			jal PaintMemory			# Call the paint function
			nop

###############
# MONSTER 
###############

Main_monsterBegin:
			lw $s7, bgColour
			or $a0, $zero, $s7		# Reset background
			or $a1, $zero, $s2		
			jal PaintMemory			
			nop
			
			jal GetRandomDir    		# Get random direction
			nop
			or $t7, $zero, $v0
			or $a0, $zero, $s2		# Set a0 to current position
			or $a1, $zero, 1		# Set distance to one
			
Main_monsterRight:
			bne, $t7, 0x00000001, Main_monsterUp
			nop
			jal MoveRight			# Right
			nop
			j Main_monsterDone
			nop
Main_monsterUp:
			bne, $t7, 0x00000002, Main_monsterLeft
			nop
			jal MoveUp			# Up
			nop
			j Main_monsterDone
			nop
Main_monsterLeft:
			bne, $t7, 0x00000003, Main_monsterDown
			nop
			jal MoveLeft			# Left
			nop
			j Main_monsterDone
			nop
Main_monsterDown:
			bne, $t7, 0x00000004, Main_monsterNone
			nop
			jal MoveDown			# Down
			nop
			j Main_monsterDone
			nop
			
Main_monsterNone:
			or $t7, $zero, $s5		# default to previous direction
			b Main_monsterRight
			nop

Main_monsterDone:
			or $a3, $zero, $v0		# Save temporarily

			lh $a0, stageWidth 		# Get our screen width
			lh $a1, stageHeight			
			jal CoordsToAddress		# Calculate position in stage memory
			nop
			sub $a2, $v0, $a3
			bltz $a2, Main_monsterBegin	# Compare out of bounds
			nop

			ori $a0, $zero, 0
			ori $a1, $zero, 0			
			jal CoordsToAddress		# Calculate position in stage memory
			nop
			sub $a2, $a3, $v0
			bltz $a2, Main_monsterBegin	# Compare out of bounds
			nop

			or $s2, $zero, $a3		# Store monster's new position

			lw $s7, monsterColour
			or $a0, $zero, $s7		# Paint monster
			or $a1, $zero, $s2		
			jal PaintMemory			
			nop

###############
# HEAD 
###############
Main_spaceBegin:
			lw $s6, bgColour
			or $a0, $zero, $s6		# Redraw current position with direction headed in the alpha bytes
			or $a1, $zero, $s0		
			jal PaintMemory
			nop

			# Now it's time to move the player's head
			jal GetKey			# Get direction from keyboard
			nop
			or $t6, $zero, $v0		# Backup direction from keyboard
			
			or $a0, $zero, $s0		# Load position
			ori $a1, $zero, 1		# Set distance to move

Main_spaceRight:
			bne, $t6, 0x01000000, Main_spaceUp
			nop
			jal MoveRight			# Right
			or $s0, $zero, $v0		# Store player's new head position
			nop
			j Main_spaceDone
			nop
Main_spaceUp:
			bne, $t6, 0x02000000, Main_spaceLeft
			nop
			jal MoveUp			# Up
			or $s0, $zero, $v0		# Store player's new head position
			nop
			j Main_spaceDone
			nop
Main_spaceLeft:
			bne, $t6, 0x03000000, Main_spaceDown
			nop
			jal MoveLeft			# Left
			or $s0, $zero, $v0		# Store player's new head position
			nop
			j Main_spaceDone
			nop
Main_spaceDown:
			bne, $t6, 0x04000000, Main_spaceSpace
			nop
			jal MoveDown			# Down
			or $s0, $zero, $v0		# Store player's new head position
			nop
			j Main_spaceDone
			nop
Main_spaceSpace:
			bne, $t6, 0x05000000, Main_spaceNone
			nop
			or $s1, $zero, $a0
			nop
			j Main_spaceDone
			nop
Main_spaceNone:
			or $t6, $zero, $s4		#default to previous direction
			b Main_spaceRight
			nop
Main_spaceDone:
			or $s4, $zero, $t6		# Backup new direction as previous direction
			
			lw $s6, drawColour
			or $a0, $zero, $s6		# Redraw current position with direction headed in the alpha bytes
			or $a1, $zero, $s0		
			jal PaintMemory
			nop

#			lh $a0, stageWidth 			# Get player's head position
#			lh $a1, stageHeight			
#			jal CoordsToAddress		# Calculate position in stage memory
#			nop
#			sub $a2, $s0, $v0
#			bgez $s0, Main_spaceResetToBegin
#			nop

#			ori $a0, $zero, 0 			# Get player's head position
#			ori $a1, $zero, 0			
#			jal CoordsToAddress		# Calculate position in stage memory
#			nop
#			sub $a2, $v0, $s0
#			bgez $s0, Main_spaceResetToEnd
#			nop

			b Main_spaceFinalCheck



#Main_spaceResetToBegin:
#			ori $a0, $zero, 0 			# Get player's head position
#			ori $a1, $zero, 0			
#			jal CoordsToAddress		# Calculate position in stage memory
#			nop
#			or $s0, $zero, $v0
#			b Main_spaceFinalCheck

#Main_spaceResetToEnd:
#			lh $a0, stageWidth 			# Get player's head position
#			lh $a1, stageHeight			
#			jal CoordsToAddress		# Calculate position in stage memory
#			nop
#			or $s0, $zero, $v0
#			b Main_spaceFinalCheck

Main_spaceFinalCheck:
			beq $s0, $s2, Main_reset	# Exit if space found monster
			nop
			beq $s1, $s2, Main_reset		# Shot found monster
			nop
			b Main_gameLoop
			nop

###############
# MAIN LOOP END
###############

Main_reset:
			# You died. Oh dead :C
			ori $v0, $zero, 32		# Syscall sleep
			ori $a0, $zero, 1200		# For this many miliseconds
			syscall
			b Main_exit

Main_exit:
			ori $v0, $zero, 10		# Syscall terminate
			syscall
			
###########################################################################################
# Sleep function for game loop
# Takes none
# Returns none
Sleep:
			ori $v0, $zero, 32		# Syscall sleep
			ori $a0, $zero, 60		# For this many miliseconds
			syscall
			jr $ra				# Return
			nop
###########################################################################################
# Function to convert coordinates into stage memory addresses
# Takes a0 = x, a1 = y
# Returns  v0 = address
CoordsToAddress:
		or $v0, $zero, $a0		# Move x coordinate to v0
		lh $a0, stageWidth		# Load the screen width into a0
		multu $a0, $a1			# Multiply y coordinate by the screen width
		nop
		mflo $a0			# Retrieve result from lo register
		addu $v0, $v0, $a0		# Add the result to the x coordinate and store in v0
		sll $v0, $v0, 2			# Multiply v0 by 4 (bytes) using a logical shift
		addu $v0, $v0, $gp		# Add gp to v0 to give stage memory address
		jr $ra				# Return
		nop
###########################################################################################
# Function to convert stage memory addresses into coordinates
# Takes a0 = address
# Returns  v0 = x, v1 = y
AddressToCoords:
		subu $a0, $a0, $gp
		srl $a0, $a0, 2
		lh $a2, stageWidth
		divu $a0, $a2
		mflo $v1
		multu $v1, $a2
		mflo $a1
		subu $v0, $a0, $a1
		jr $ra				# Return
		nop
###########################################################################################
# Function to draw the given colour to the given stage memory address (gp)
# Takes a0 = colour, a1 = address
# Returns none
PaintMemory:
		sw $a0, ($a1)			# Set colour
		jr $ra				# Return
		nop
###########################################################################################
# Function to move a given stage memory address right by a given number of tiles
# Takes a0 = address, a1 = distance
# Returns v0 = new address
MoveRight:
		#address + (distance*width*4)
		or $v0, $zero, $a0		# Move address to v0
		sll $a0, $a1, 2			# Multiply distance by 4 using a logical shift
		add $v0, $v0, $a0		# Add result to v0
		jr $ra				# Return
		nop
###########################################################################################
# Function to move a given stage memory address up by a given number of tiles
# Takes a0 = address, a1 = distance
# Returns v0 = new address
MoveUp:
		or $v0, $zero, $a0		# Move address to v0
		lh $a0, stageWidth		# Load the screen width into a0
		multu $a0, $a1			# Multiply distance by screen width
		nop
		mflo $a0			# Retrieve result from lo register
		sll $a0, $a0, 2			# Multiply v0 by 4 using a logical shift
		subu $v0, $v0, $a0		# Add result to v0
		jr $ra				# Return
		nop
###########################################################################################
# Function to move a given stage memory address left by a given number of tiles
# Takes a0 = address, a1 = distance
# Returns v0 = new address
MoveLeft:
		or $v0, $zero, $a0		# Move address to v0
		sll $a0, $a1, 2			# Multiply distance by 4 using a logical shift
		subu $v0, $v0, $a0		# Subtract result from v0
		jr $ra				# Return
		nop
###########################################################################################
# Function to move a given stage memory address down by a given number of tiles
# Takes a0 = address, a1 = distance
# Returns v0 = new address
MoveDown:
		or $v0, $zero, $a0		# Move address to v0
		lh $a0, stageWidth		# Load the screen width into a0
		multu $a0, $a1			# Multiply distance by screen width
		nop
		mflo $a0			# Retrieve result from lo register
		sll $a0, $a0, 2			# Multiply v0 by 4 using a logical shift
		addu $v0, $v0, $a0		# Subtract result from v0
		jr $ra				# Return
		nop
###########################################################################################
# Function to retrieve input from the kyboard and return it as an alpha channel direction
# Takes none
# Returns v0 = direction
GetKey:
		lw $t0, 0xFFFF0004		# Load input value
		
GetKey_right:
		bne, $t0, 100, GetKey_up
		nop
		ori $v0, $zero, 0x01000000	# Right
		j GetKey_done
		nop
GetKey_up:
		bne, $t0, 119, GetKey_left
		nop
		ori $v0, $zero, 0x02000000	# Up
		j GetKey_done
		nop
GetKey_left:
		bne, $t0, 97, GetKey_down
		nop
		ori $v0, $zero, 0x03000000	# Left
		j GetKey_done
		nop
GetKey_down:
		bne, $t0, 115, GetKey_space
		nop
		ori $v0, $zero, 0x04000000	# Down
		j GetKey_done
		nop

GetKey_space:
		bne, $t0, 32, GetKey_none
		nop
		ori $v0, $zero, 0x05000000	# Space
		j GetKey_done
		nop
		
GetKey_none:
						# Do nothing
GetKey_done:
		jr $ra				# Return
		nop
###########################################################################################
# Function to fill the stage memory with a given colour
# Takes a0 = colour
# Returns none
FillMemory:
		lh $a1, stageWidth		# Calculate ending position
		lh $a2, stageHeight
		multu $a1, $a2			# Multiply screen width by screen height
		nop
		mflo $a2					# Retrieve total tiles
		sll $a2, $a2, 2			# Multiply by 4
		add $a2, $a2, $gp		# Add global pointer
		
		or $a1, $zero, $gp		# Set loop var to global pointer
FillMemory_l:	
		sw $a0, ($a1)
		add $a1, $a1, 4
		blt $a1, $a2, FillMemory_l
		nop
		
		jr $ra				# Return
		nop

###########################################################################################
# Function to return a viable address at random
# Takes none
# Returns v0 = viable address
GetRandomPos:
		lh $a1, stageWidth		# Calculate the max
		lh $a2, stageHeight
		multu $a1, $a2			# Multiply screen width by screen height
		nop
		mflo $a3					# Retrieve total tiles
		sub $a3, $a3, 2			# take two for width boundaries
		sub $a3, $a3, $a2		# take two stage widths for height boundaries
		sub $a3, $a3, $a2
		
GetRandomPos_tryAgain:	
		ori $v0, $zero, 42		# use syscall 42 to get a random integer under this number
		ori $a0, $zero, 1
		or $a1, $zero, $a3
		syscall
		
		sll $v0, $v0, 2			# multiply by 4 for word size
		add $v0, $v0, $gp		# add to global pointer
		
		lw $t0, ($v0)			# Check status of tile chosen at random
		srl $t0, $t0, 24
		bne $t0, 0xFF, GetRandomPos_tryAgain	# Try and find a different spot, this one is taken
		nop
		
		jr $ra				# Return
		nop

###########################################################################################
# Function to return a direction at random
# Takes a0 = position
# Returns v0 = viable address
GetRandomDir:
		# do nothing
GetRandomDir_tryAgain:	
		ori $v0, $zero, 42		# use syscall 42 to get a random integer under this number
		ori $a0, $zero, 1
		ori $a1, $zero, 4
		syscall
		
		or $v0, $zero, $a0
		nop
		
		jr $ra				# Return
		nop
###########################################################################################
