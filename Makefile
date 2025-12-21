# RV64GC
TARGET	?=riscv64
ARCH	?=rv64gc
ABI	?=lp64

#RV32GC
#TARGET	?=riscv32
#ARCH	?=rv32gc
#ABI	?=ilp32d

#CH32V003 - RV32E 
#TARGET	?=riscv32
#ARCH	?=rv32ec_zicsr
#ABI	?=ilp32e

CC	:= clang
LD	:= ld.lld
CFLAGS	:= --target=$(TARGET) -march=$(ARCH) -mabi=$(ABI)
LDFLAGS	:=

SRCS	:= bloom.s
OBJS	:= $(SRCS:.s=.o)
EXES	:= bloom-tests.x
LIB	:= librvbloom.a
RVINT	:= ../rvint/src/librvint.a

BLOOM_TESTS_OBJS	:= bloom-tests.o bloom.o

.PHONY:	all clean

all: $(EXES) $(LIB)

%.o: %.s
	$(CC) $(CFLAGS) -c $< -o $@

bloom.o: bloom.s config.s

bloom-tests.x: bloom-tests.o $(LIB) $(RVINT)
	$(LD) $(LDFLAGS) $^ $(RVINT) -o $@

$(LIB): $(OBJS)
	$(AR) $(ARFLAGS) $(LIB) $(OBJS)

clean:
	rm -f *.o $(OBJS) $(EXES) $(LIB)
