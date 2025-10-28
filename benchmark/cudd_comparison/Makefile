# Makefile for CUDD benchmarks

CC = gcc
CFLAGS = -O3 -Wall -Wextra -I.
LDFLAGS = -L./cudd/cudd/.libs -lcudd -lm

CUDD_LIB = cudd/cudd/.libs/libcudd.a

all: benchmark_cudd

benchmark_cudd: benchmark_cudd.c $(CUDD_LIB)
	$(CC) $(CFLAGS) -o benchmark_cudd benchmark_cudd.c $(CUDD_LIB) -lm

$(CUDD_LIB):
	cd cudd && ./configure --enable-silent-rules && make

run: benchmark_cudd
	./benchmark_cudd

clean:
	rm -f benchmark_cudd

distclean: clean
	cd cudd && make distclean || true

.PHONY: all run clean distclean
