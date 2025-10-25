.include	"config.s"

.data
space:	.asciz	" "
nl:	.asciz 	"\n"
line:	.asciz	"--------" # len = 8
text1:	.asciz 	"the quick brown fox"
text2:	.asciz 	"jumped over the lazy dog"
text3:	.asciz	"oink oink oink oink oink oink oink"
maybe:	.asciz  "maybe in\n" # len = 9
notin:	.asciz	"not in  \n" # len = 9

.text
.globl _start
_start:
#	jal	print_table

# insert string and dump bloom table, two bits should be set
	la	a0, text1
	jal 	bloom_insert_string
	jal	print_table

# insert string and dump bloom table, four bits should be set
	la	a0, text2
	jal 	bloom_insert_string
	jal	print_table

## test 1 - string should be "maybe in"

	la	a0, text1
	jal	bloom_check_string
	beqz	a0, no1
	la	a1, maybe
	j	next1
no1:	
	la	a1, notin
next1:	
	li	a2, 9
	jal	print

## test 2 - string should be "maybe in"

	la	a0, text2
	jal	bloom_check_string
	beqz	a0, no2
	la	a1, maybe
	j	next2
no2:	
	la	a1, notin
next2:	
	li	a2, 9
	jal	print

## test 3 - string should be "not in"

	la	a0, text3
	jal	bloom_check_string
	beqz	a0, no3
	la	a1, maybe
	j	next3
no3:	
	la	a1, notin
next3:	
	li	a2, 9
	jal	print

	j	_end

## Print out the bloom table

print_table:
	FRAME	1
	PUSH	ra, 0
	la	s1, bloom_table
	li      s0, BLOOM_TABLE_BYTES   # remaining bytes
	li      t1, 0                   # bytes printed in current line

print_loop:
	lb      a0, 0(s1)               # load current byte
	mv      t0, a0                 	# save current byte

	# print bloom table byte in binary
	li      a1, 1
	li      a2, 0
	jal     to_bin
	mv      a2, a1
	mv      a1, a0
	jal     print

	li      a2, 1
	la      a1, space
	jal     print

	add     s1, s1, 1               # next byte
	addi    t1, t1, 1               # increment bytes-in-line
	addi    s0, s0, -1              # decrement remaining bytes

	# print newline every 6 bytes
	li      t2, 6
	bne     t1, t2, skip_newline

	li      a2, 1
	la      a1, nl
	jal     print
	li      t1, 0                    # reset bytes-in-line

skip_newline:
	bnez    s0, print_loop

	li      a2, 1
	la      a1, nl
	jal     print

	li	a2, 8
	la	a1, line
	jal	print

	li      a2, 1
	la      a1, nl
	jal     print

	POP	ra, 0
	EFRAME	1
	ret

_end:
        li	a0, 0		# exit code
        li	a7, 93		# exit syscall
        ecall

# a1 - ptr to string to print
# a2 - # bytes to print
print:
	li	a0, 1		# stdout
	li	a7, 64		# write syscall
	ecall
	ret
