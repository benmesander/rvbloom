.include "config.s"

.globl	bloom_table
.globl	bloom_insert_string
.globl	bloom_insert_integer
.globl	bloom_check_string
.globl	bloom_check_integer	

.data
# Bloom table
bloom_table:	
.rept	BLOOM_TABLE_BYTES
.byte	0
.endr	

.text
################################################################################
# routine: sum_key
#
# Calculate a sum of all bytes in a null-terminated string for hashing.
# Uses simple byte-by-byte addition.
#
# input registers:
# a0 = pointer to nul-terminated string
#
# output registers:
# a0 = sum of all bytes in string
################################################################################
sum_key:
	li	a1, 0			# accumulator
sum_key_loop:
	lbu	a2, 0(a0)		# load byte
	beqz	a2, sum_key_done
	add	a1, a1, a2
	addi	a0, a0, 1
	j	sum_key_loop
sum_key_done:
	mv	a0, a1			# return sum
	ret
.size sum_key, .-sum_key

################################################################################
# routine: hash_h1
#
# Primary hash function
# Uses modulo by table size for uniform distribution.
#
# input registers:
# a0 = key sum to hash
#
# output registers:
# a0 = bloom filter location in bits [0 ... BLOOM_TABLE_SIZE - 1]
################################################################################
hash_h1:
	FRAME	1
	PUSH	ra, 0

	li	a1, BLOOM_TABLE_SIZE	# Divisor for divremu
	jal	divremu			# a0=quotient, a1=remainder
	mv	a0, a1			# Return remainder in a0

	POP	ra, 0
	EFRAME	1
	ret
.size hash_h1, .-hash_h1

################################################################################
# routine: hash_h2
#
# Secondary hash function - computes probe step size.
# Uses modulo by (table size - 1) plus 1 to ensure coprime step size.
#
# input registers:
# a0 = key sum to hash
#
# output registers:
# a0 = bloom filter location in bits [0 ... BLOOM_TABLE_SIZE -1]
################################################################################
hash_h2:
	FRAME	1
	PUSH	ra, 0

	li	a1, BLOOM_TABLE_SIZE-1	# Divisor for divremu
	jal	divremu		        # a0=quotient, a1=remainder
	addi	a0, a1, 1		# Logical step is 1 to BLOOM_TABLE_SIZE-1 (this is in a1)
	POP	ra, 0
	EFRAME	1
	ret
.size hash_h2, .-hash_h2


################################################################################
# routine: bloom_insert_string
#
# Inserts a nul-terminated string pointed to by a0 into the bloom filter.
#
# input registers:
# a0 = pointer to string
#
# output registers:
# n/a
################################################################################

bloom_insert_string:
	FRAME	1
	PUSH	ra, 0
	jal	sum_key
	jal	bloom_insert_integer
	POP	ra, 0
	EFRAME	1
	ret

################################################################################
# routine: bloom_insert_integer
#
# Inserts an integer in a0 into the bloom filter.
#
# input registers:
# a0 = integer to insert
#
# output registers:
# n/a
################################################################################

bloom_insert_integer:
	FRAME	2
	PUSH	ra, 0
	PUSH	s0, 1

	mv	s0, a0
	jal	hash_h1
	jal	bloom_set_bit
	mv	a0, s0
	jal	hash_h2
	jal	bloom_set_bit

	POP	ra, 0
	POP	s0, 1
	EFRAME	2
	ret

################################################################################
# routine: bloom_check_integer
#
# checks to see if the integer in a0 might be in the bloom filter
#
# input registers:
# a0 = integer to check
#
# output registers:
# a0 = 1 if the integer might be in the bloom filter, 0 if it is not
################################################################################

bloom_check_integer:
	FRAME	3
	PUSH	ra, 0
	PUSH	s0, 1
	PUSH	s1, 2

	mv	s0, a0
	jal	hash_h1
	jal	bloom_get_bit
	mv	s1, a0

	mv	a0, s0
	jal	hash_h2
	jal	bloom_get_bit

	and	a0, a0, s1

	POP	ra, 0
	POP	s0, 1
	POP	s1, 2
	EFRAME 	3
	ret


################################################################################
# routine: bloom_check_string
#
# checks to see if the nul-terminated string pointed to by
# a0 might be in the bloom filter
#
# input registers:
# a0 = pointer to string to check
#
# output registers:
# a0 = 1 if the integer might be in the bloom filter, 0 if it is not
################################################################################
bloom_check_string:
	FRAME	1
	PUSH	ra, 0
	jal	sum_key
	jal	bloom_check_integer
	POP	ra, 0
	EFRAME	1
	ret

################################################################################
# routine: bloom_set_bit
#
# Sets a bit at the specified position in the bloom filter
#
# input registers:
# a0 = bit to set
#
# output registers:
# n/a
################################################################################

bloom_set_bit:
	andi	a1, a0, 0x7		# low order 3 bits is bit position within byte
	srli	a2, a0, 3		# divide bit number by 8 to get byte number
	la	a3, bloom_table
	add	a2, a2, a3		# form address of byte to modify
	lb	a3, 0(a2)
.if HAS_ZBB == 1
	bset	a3, a3, a1		# set bit directly if instruction is available
.else
	li	t0, 1
	sll	t0, t0, a1
	or	a3, a3, t0
.endif
	sb	a3, 0(a2)
	ret
	
################################################################################
# routine: bloom_get_bit
#
# Gets a bit at the specified position in the bloom filter
#
# input registers:
# a0 = bit to get
#
# output registers:
# a0 = 1 if bit set, 0 if bit not set
################################################################################

bloom_get_bit:
	andi	a1, a0, 0x7		# low order 3 bits is bit position within byte
	srli	a2, a0, 3		# divide bit number by 8 to get byte number
	la	a3, bloom_table
	add	a2, a2, a3		# form address of byte to modify
	lb	a3, 0(a2)
.if HAS_ZBB == 1
	bext	a3, a3, a1
.else
	li	t0, 1
	sll	t0, t0, a1
	and	a3, a3, t0
.endif
	snez	a0, a3
	ret
