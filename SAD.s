# Begin subroutine
vbsme:		
			#addi    $sp, $sp, -4
			#sw		$ra, 0($sp)
			li		$v0,0				# Reset v0
			li		$v1,0				# Reset v1
			lui 	$s0,0xefff			# SAD Comparison Value
			ori 	$s0,$s0,0xffff
			lw		$s0,  0($a0)		# Frame Rows
			lw		$s1,  4($a0)		# Frame Cols
			lw		$s2,  8($a0)		# Window Rows
			lw		$s3, 12($a0)		# Window Cols
			sll		$s5,$s3,2			# Window Row Size
			mul		$s4,$s5,$s2			# End of Window
			addi	$s4,$s4,-4
			add     $s4, $s4, $a2       #End of Window Address
			sll     $s1, $s1 , 2	    # Frame width offset
			sll     $s3, $s3 , 2        # Window Cols offset
			sub     $s1, $s1, $s3       # Frame width - Window width
			addi    $s1, $s1,  4        # Frame Jump fix 
			addi 	$t3,$a1,0			# Current Frame Element
			addi	$t4,$a2,0			# Current Window Element
			add		$s6,$a1,$s5			# Frame-Window Row End
			addi	$s6,$s6,-4
WindowLoop:	lw		$t1, 0($t3)			# Frame Value
			lw		$t2, 0($t4)			# Window Value
			sub 	$t9,$t1,$t2			# Subtract Window Value from Frame Value
			slt 	$t8,$t9,$0			# if(t9 < 0) Perform Absolute Value Calculation
			beq 	$t8,$0,gtzero
			nor 	$t9,$t9,$0
			addi	$t9,$t9,1
gtzero:		add 	$t5,$t5,$t9			# Window SAD Total
			beq		$t4,$s4,checkSAD	# GoTo checkSAD if at the end of the window			
			addi 	$t4,$t4,4			# Goto Next Window Element	
			beq		$t3,$s6,NextRow		# Check End of Row
			addi	$t3,$t3,4			
			j 		WindowLoop
NextRow:	add		$s6,$s6,$s5			# Move to Next Row End
			add		$t3,$t3,$s1			# Frame Jump
			j		WindowLoop
checkSAD:	
			slt 	$t1,$s0,$t5		# Check if current SAD is less than existing
			bne 	$t1,$0,NextWindow
			addi	$s0,$t5,0
			# TODO: update v0 and v1
			addi	$v0,$0,0
			addi	$v1,$0,0
			jr      $ra
			#j		NextWindow
NextWindow:	# TODO