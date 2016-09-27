vbsme:		
			li		$v0,0				# Reset v0
			li		$v1,0				# Reset v1
			lui 	$s7,0x7fff			# SAD Comparison Value
			ori 	$s7,$s7,0xffff
			lw		$s0,  0($a0)		# Frame Rows
			lw		$s1,  4($a0)		# Frame Cols
			lw		$s2,  8($a0)		# Window Rows
			lw		$s3, 12($a0)		# Window Cols
			sll		$s5, $s3, 2			# Window Row Size
			mul		$s4, $s5, $s2		# End of Window Offset
			addi	$s4, $s4, -4
			add     $s4, $s4, $a2       # End of Window Address
			sll     $t7, $s1, 2	        # Frame width offset
			sll     $t1, $s3, 2         # Window Cols offset
			sub     $t7, $t7, $t1       # Frame width - Window width
			addi    $t7, $t7, 4         # Frame Jump fix 
			addi 	$t6, $a1, 0			# Current Frame Element/ Initial Frame Address
			#addi	$t4, $a2, 0			# Current Window Element
			add		$t9, $a2, $s5		# Frame-Window Row End
			addi	$t9, $t9, -4
			add     $s6,  $0, $0        # Saves Last move of window(INIT: 0, RIGHT: 1, UPR: 2, DWL: 3, DOWN: 4)
SAD_Routine:
			add		$t9, $a2, $s5		# Frame-Window Row End
			addi	$t9, $t9, -4
			addi	$t5,  $0, 0			# Reset SAD Window Total
			add	    $t3, $t6, $0        # Saves current initial Frame address before window scan
			add     $t4, $a2, $0        # Reset current Window address
WindowLoop:	
			lw		$t1, 0($t3)			# Frame Value
			lw		$t2, 0($t4)			# Window Value
			sub 	$t1, $t1,$t2		# Subtract Window Value from Frame Value
			slt 	$t2, $t1,$0			# if(t1 < 0) Perform Absolute Value Calculation
			beq 	$t2, $0,gtzero
			nor 	$t1, $t1,$0
			addi	$t1, $t1,1
gtzero:		
			add 	$t5, $t5, $t1			# Window SAD Total
			beq		$t4, $s4, returnUpdate	# GoTo checkSAD if at the end of the window			
			beq		$t4, $t9, NextRow		# Check End of Row
			addi 	$t4, $t4, 4				# Goto Next Window Element	
			addi	$t3, $t3, 4				# Goto Next Frame Element	
			j 		WindowLoop
NextRow:	
			add		$t9, $t9, $s5			# Move to Next Row End
			addi 	$t4, $t4, 4				# Goto Next Window Element	
			add		$t3, $t3, $t7			# Frame Jump
			j		WindowLoop
returnUpdate:	
			addi    $t0, $t0, 0		
			sub     $t1, $t6, $a1        	# Compute Frame offset from starting address
			srl     $t1, $t1, 2         	# convert address offset to integer index
IndexLoop:									# Determines the index of the current row
			slt     $t8, $t1, $s1			# if(t0 < 0) t2 = 1 else if(t0 >= 0) t2 = 0
			bne		$t8, $0, CheckSAD 		# conitnue loop until t0 <= 0, t2 = 0
			sub     $t1, $t1, $s1       	# division by subraction
			addi	$t0, $t0, 1
			j 		IndexLoop
CheckSAD:
			slt 	$t1, $s7,$t5		# Check if current SAD is less than existing
			bne 	$t1, $0, CheckExit 
        	addi    $s7, $t5, 0         # update SAD with new comparison value
			addi	$v0, $t0, 0
			addi	$v1, $t1, 0
CheckExit:	
			sub		$t2,$s1,$s3			# Calc Greatest Possible Column
			sub		$t3,$s0,$s2			# Calc Greatest Possible Row
			bne		$t0, $t3, NextWindow
			bne     $t1, $t2, NextWindow
			j 		End
NextWindow:
			bne		$s6,$0,lastDown		# If Last Move was not init (0000), try Down
			beq		$s6,$0,MoveRight	# End If No Move Right Possible - FIX FOR POSSIBLE MOVE DOWN
			j		End					# else End
lastDown:	andi	$t8,$s6,1			# Test Value for Last Move Down (0001)
			bne		$t8,$0,lastRight	# If Last Move Was Not Down, Try lastRight
			beq		$t1,$0,MoveUR		# If In first Column, next move is Up & Right...
			beq		$t1,$t2,MoveDL		# else...If In Last Possible Column, next Move is Down & Left
			j		End
lastRight:	andi	$t8,$s6,2			# Test Value for last Move Right (0010)
			beq		$t8,$0,lastUR		# If Last Move Was Not Right, Try Up & Right
			beq		$t0,$0,MoveDL		# If We are in the top row Move Down & Left
			beq		$t0,$t3,MoveUR		# If We are in the Lowest Row Possible Move Up & Right
			j		End			
lastUR:		andi	$t8,$s6,4			# Test Value for Last Move Up & Right (0100)
			beq		$t8,$0,lastDL		# If Last Move was Not Up & Right, Try Down & Left
			beq		$t1,$t2,MoveDown	# If We are In the Last column, Move Down
			beq		$t1,$0,MoveRight	# If We are In the top Row, Move Right
			j		MoveUR				# Otherwise Move Up & Right
lastDL:		andi	$t8,$s6,8			# Test Value for Last Move Down & Left (1000)
			beq		$t8,$0,BadEnd		# WE SHOULD *NEVER* BRANCH HERE, BUT...
			beq		$t0,$t3,MoveRight	# If we are in the Bottom Row, Move Right
			beq		$t1,$0,MoveDL		# If we are in the Left Most Column, Move Down
			j		MoveDL				# Otherwise Move Down & Left
			
# STARTING HERE WE CAN REUSED ALL $t*, BEFORE jing YOU MUST
# SET $t5 to the last move (1, 2, 4 or 8), and $t0 & $t1 to zero 
MoveDown:	add		$s5,$s5,$s1			# Move Current Frame Forward the Width of One Frame
			li		$t5,1				# Set Last Move Down (0...0001)
			li		$t0,0				# Reset Frame Offset to Zero
			li		$t1,0				# Reset Window Offset to Zero
			j		SAD_Routine			
MoveRight:	addi	$t6, $t6,4			# Move Current Frame Forward One Block
			li		$t5, 2				# Set Last Move Right (0...0010)
			j		SAD_Routine
MoveUR:		sub		$s5,$s5,$s1			# Move Current Frame Back the Width of One Frame
			addi	$s5,$s5,1			# Move Current Frame Forward One Block
			li		$t5,4				# Set Last Move Up & Right (0...0100)
			li		$t0,0				# Reset Frame Offset to Zero
			li		$t1,0				# Reset Window Offset to Zero
			j		SAD_Routine
MoveDL:		add		$s5,$s5,$s1			# Move Current Frame Forward the Width of One Frame
			addi	$s5,$s5,-1			# Move Current Frame Back One Block
			li		$t5,8				# Set Last Move Down & Left (0...01000)
			li		$t0,0				# Reset Frame Offset to Zero
			li		$t1,0				# Reset Window Offset to Zero
			j		SAD_Routine
End:					
			j		End
BadEnd:		addi	$v0,$0,-1
			addi	$v1,$0,-1
			jr		$ra