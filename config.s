.equ	CPU_BITS,	32
.equ	CPU_BYTES,	CPU_BITS/8
.equ	HAS_ZBB,	0
	

.macro PUSH reg_to_save, offset_val
.if CPU_BITS == 64
	sd \reg_to_save, \offset_val*CPU_BYTES(sp) # RV64I double word
.else
	sw \reg_to_save, \offset_val*CPU_BYTES(sp) # RV32I word
.endif
.endm

.macro POP reg_to_load, offset_val
.if CPU_BITS == 64
	ld \reg_to_load, \offset_val*CPU_BYTES(sp)
.else
	lw \reg_to_load, \offset_val*CPU_BYTES(sp)
.endif
.endm

.macro FRAME num_regs
	addi	sp, sp, -CPU_BYTES*\num_regs
.endm

.macro EFRAME num_regs
	addi	sp, sp, CPU_BYTES*\num_regs
.endm


# Bloom table size - 527 bits (66 bytes)
# 100 items, 1% false positive, 2 hash functions
# https://hur.st/bloomfilter/?n=100&p=0.1&m=&k=2
.equ	BLOOM_TABLE_SIZE,	527
.equ	BLOOM_TABLE_BYTES,	66	# enough bytes to hold 527 bits	
	
