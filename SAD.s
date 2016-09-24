vbsme:		
			#addi    $sp, $sp, -4
			#sw		$ra, 0($sp) 
			li		$v0,0				# Reset v0
			li		$v1,0				# Reset v1
			lui 	$s7,0x0fff			# SAD Comparison Value
			ori 	$s7,$s7,0xffff
			lw		$s0,  0($a0)		# Frame Rows
			lw		$s1,  4($a0)		# Frame Cols
			lw		$s2,  8($a0)		# Window Rows
			lw		$s3, 12($a0)		# Window Cols
			sll		$s5, $s3, 2			# Window Row Size
			mul		$s4, $s5, $s2		# End of Window
			addi	$s4, $s4, -4
			add     $s4, $s4, $a2       # End of Window Address
			sll     $s1, $s1, 2	        # Frame width offset
			sll     $s3, $s3, 2         # Window Cols offset
			sub     $s1, $s1, $s3       # Frame width - Window width
			addi    $s1, $s1, 4         # Frame Jump fix 
			addi 	$t3, $a1, 0			# Current Frame Element
			addi	$t4, $a2, 0			# Current Window Element
			add		$s6, $a2, $s5		# Frame-Window Row End
			addi	$s6, $s6, -4
			add     $s2,  $0, $0        # Saves Last move of window(INIT: 0, RIGHT: 1, UPR: 2, DWL: 3, DOWN: 4)
SAD_Routine:
			add	    $s0, $t3, $0        # Saves current initial Frame address before window scan
WindowLoop:	
			lw		$t1, 0($t3)			# Frame Value
			lw		$t2, 0($t4)			# Window Value
			sub 	$t9, $t1,$t2		# Subtract Window Value from Frame Value
			slt 	$t8, $t9,$0			# if(t9 < 0) Perform Absolute Value Calculation
			beq 	$t8, $0,gtzero
			nor 	$t9, $t9,$0
			addi	$t9, $t9,1
gtzero:		
			add 	$t5, $t5,$t9		# Window SAD Total
			beq		$t4, $s4,checkSAD	# GoTo checkSAD if at the end of the window			
			beq		$t4, $s6,NextRow	# Check End of Row
			addi 	$t4, $t4,4			# Goto Next Window Element	
			addi	$t3, $t3,4			# Goto Next Frame Element	
			j 		WindowLoop
NextRow:	
			add		$s6, $s6,$s5		# Move to Next Row End
			addi 	$t4, $t4,4			# Goto Next Window Element	
			add		$t3, $t3,$s1		# Frame Jump
			j		WindowLoop
checkSAD:	
			slt 	$t1, $s7,$t5		# Check if current SAD is less than existing
			bne 	$t1, $0, NextWindow 
			addi    $s7, $t5, 0         # update SAD with new comparison value
			li		$v0, 0				# Reset v0
			li		$v1, 0				# Reset v1
			sub     $t0, $s0,$a1        # Compute Frame offset from starting address
			srl     $t0, $t0, 2         # convert address offset to integer index
			lw		$s1, 4($a0)		    # Number of Frame Cols
			sub     $t0, $t0, $s1       # division by subraction
v0_loop:    
			slt     $t2, $t0, $0		# if(t0 < 0) t2 = 1 else if(t0 >= 0) t2 = 0
			bne 	$t2, $0, v0_done    # conitnue loop until t0 <= 0, t2 = 0
			addi    $v0, $v0, 1			# each column size subracted increments location index
			sub     $t0, $t0, $s1       # division by subraction
			j 		v0_loop
v0_done:	#Done with computing v0 use result to compute v1
			lw		$s1, 4($a0)		    # Number of Frame Cols
			sub     $t0, $s0,$a1        # Compute Frame offset from starting address
			srl     $t0, $t0, 2         # convert address offset to integer index
			mul     $t1, $s1, $v0       # result for v0 used here to compute v1
			sub     $v1, $t0, $t1       # v1 = (t0, current_index) - (s1, # of columns)*(v0, # of rows)
			j		NextWindow          # Finished go to next window		
NextWindow:
			lw		$t6,  0($a0)		# Frame Rows
			lw		$t7,  4($a0)		# Frame Cols
			mul     $t0, $t6, $t7       
			addi    $t0, $t0, -1
			sll     $t0, $t0, 2         # Frame offset for end of frame
			add     $t0, $t0, $a1       # End of Frame address
			beq     $t0, $t3, SAD_DONE  # Reached end of FRAME SAD Routine complete
			beq 	$s2, $0, Move_Right # Last move was initial always move right
			#Boundary checking required if last move was Right, DownLeft, UpRight, or Down
			#TODO: determine boundary then call correct move
			
Move_Right: 	# TODO
Move_DownLeft:  # TODO
Move_UpRight: 	# TODO
Move_Down:		# TODO
			j SAD_Routine               # After move is performed SAD_Routine is always called
SAD_DONE: 	#ROUTINE COMPLETE
			jr 		$ra

		   #note: t0, t6, t7 are reserved for temporary use can be overwritten at anytime
			