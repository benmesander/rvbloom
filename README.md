# rvbloom

## Description

Simple Bloom filter implemented in RISC-V assembly for RV32I and RV64I
instruction sets. Makes optional use of the Zbb instruction set if
available.

A [Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter) is a
highly space-efficient data structure similar to a set. Unlike a set,
a Bloom returns "maybe in set", and "definitely not in set" whereas
a set returns "definitely in set" and "definitely not in set". The
advantage of a Bloom filter is a large gain in space efficiency for
large sets.

The particular Bloom filter implemented here is designed to allow
for storage of 100 items with a 1% false positive rate. It was
designed with this [Bloom filter calculator](https://hur.st/bloomfilter/?n=100&p=0.1&m=&k=2)
It uses 66 bytes of storage to store the 100 items.

This implementation uses two hash functions, both of which are simple
modulus hashes (ie, not very good, but quite fast), and as a result it
works best if the entropy of the lower 9 bits of the items being
inserted is high. If this is not the case, then I suggest replacing
the hash_h1 and hash_h2 functions in bloom.s with something more
sophisticated; [MurmurHash](https://en.wikipedia.org/wiki/MurmurHash)
is a commonly used hashing function for this application.

## API

rvbloom's public API consists of four routines:

### bloom_insert_string - insert a string value into the Bloom filter.
Input: a0 contains a pointer to a nul-terminated string.

### bloom_insert_integer - insert an integer value into the Bloom filter.
Input: a0 contains integer to insert.

### bloom_check_string - determine if a string is possibly in the bloom filter.
Input: a0 contains a pointer to a nul-terminated string.
Output: a0 = 1 if string is possibly in filter, else 0.

### bloom_check_integer - determine if an integer value is possibly in the bloom filter.
Input: a0 contains integer to check.
Output: a0 = 1 if integer is possibly in filter, else 0.

## Dependencies

rvbloom depends upon my [rvint](https://github.com/benmesander/rvint)
package of RISC-V integer mathematical routines. You will need to
download and build rvint prior to building rvbloom.

rvbloom is built with [LLVM](https://github.com/llvm/llvm-project). It
is possible to use the GNU toolchain by modifying the Makefile.

## Building

1. Download and build [rvint](https://github.com/benmesander/rvint)
2. edit rvbloom/config.s and set the CPU_BITS and HAS_ZBB equates as appropriate.
3. edit Makefile, setting TARGET, ARCH, ABI and RVINT variables as appropriate
4. make. This will build the rvbloom.a library, suitable for linking with your
   application, as well as the bloom-tests.x example executable.

## Expected output from bloom-tests.x

bloom-tests.x runs on systems which support Linux syscalls.  Expected
output from running on the [RISC-V ALE
emulator](https://riscv-programming.org/ale/)

```
$ whisper /bloom-tests.x --newlib --setreg sp=0x7FFFFF
C --isa acdfimsu
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 01000000 00000100 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
--------
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00100001 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 01000000 00000100 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
00000000 00000000 00000000 00000000 00000000 00000000 
--------
maybe in
maybe in
not in  
Target program exited with code 0
User stop
Retired 16481 instructions in 0.52s  31633 inst/s
$ 
```