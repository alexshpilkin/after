#include <stdio.h>
#include <stdlib.h>
#include "forth.h"

#if __STDC_VERSION__ < 199901L
#define restrict
#endif

#if defined __GNUC__ || defined __clang__ || defined __icc__
#define slower(TEST) (__builtin_expect(!!(TEST), 0))
#define faster(TEST) (__builtin_expect(!!(TEST), 1))
#else
#define slower(TEST) (TEST)
#define faster(TEST) (TEST)
#endif

#define verifyof(E) (0 * (int)sizeof(int [1 - 2*!!(E)]))
#if defined __GNUC__ || defined __clang__
#define countof(A) \
	(sizeof(A) / sizeof((A)[0]) + \
	 verifyof(__builtin_types_compatible_p(__typeof__(A), \
	                                       __typeof__(&(A)[0]))))
#else
#define countof(A) (sizeof(A) / sizeof((A)[0]))
#endif

#ifndef NTRACE
#define trace if (0); else
#else
#define trace if (1); else
#endif

#include "prims.c"

char const *const *symbol;
word_t *restrict memory,
        ibot, itop, iptr,
        rbot, rtop, rptr,
        dbot, dtop, dptr;

fault_t run(void) {

#define addr(W) do { \
	word_t a = (W); \
	if slower(a < ibot || a >= itop) goto iaddr; \
} while(0)

#define get(STACK, N) do { \
	if slower(STACK##ptr - STACK##bot < (N)) goto uflow; \
} while(0)
#define put(STACK, N) do { \
	if slower(STACK##top - STACK##ptr < (N)) goto oflow; \
} while(0)
#define pop(STACK) memory[--STACK##ptr]
#define psh(STACK) memory[STACK##ptr++]

#define rget(N) get(r, (N))
#define rput(N) put(r, (N))
#define rpop    pop(r)
#define rpsh    psh(r)
#define dget(N) get(d, (N))
#define dput(N) put(d, (N))
#define dpop    pop(d)
#define dpsh    psh(d)

	for (;;) {
		word_t insn;

		trace fprintf(stderr, "%" PRI0 " ", iptr);
		addr(iptr); insn = memory[iptr++];
		trace fprintf(stderr, "%" PRI0 " ", insn);
		switch ((word_t)~insn) {
		default:
			trace fprintf(stderr, "%-16s ",
			              insn >= ibot && insn < itop && symbol &&
			              symbol[insn] ? symbol[insn] : "");
			rput(1); rpsh = iptr; iptr = insn; break;
#define PRIM(NAME, ID, BODY) \
		case P##ID: \
			trace fprintf(stderr, "%-16s ", NAME); \
			{ BODY } break;
PRIMS
#include "prims.h"
#undef PRIM
		}
		trace {
			word_t i;
			fprintf(stderr, "( ");
			for (i = dbot; i < dptr; i++)
				fprintf(stderr, "%" PRIX " ", memory[i]);
			fprintf(stderr, ") ( R: ");
			for (i = rbot; i < rptr; i++)
				fprintf(stderr, "%" PRIX " ", memory[i]);
			fprintf(stderr, ")\n");
		}
	}

#define FAULT(MSG, UPPER, LOWER) \
LOWER: \
	trace fprintf(stderr, "%s\n", MSG); \
	return F##UPPER;
FAULTS
#undef FAULT
}

word_t image[] = {
	0, 0, 0, 0,
	8, 0xA, ~PHALT, 0,
	~PEXIT, 0, 8, ~PEXIT,
};
char const *const imsym[countof(image)] = {
	0, 0, 0, 0,
	"COLD", 0, 0, 0,
	"ONE", 0, "TWO", 0,
};

int main(int argc, char** argv) {
	memory = &image[0]; symbol = &imsym[0];
	dbot = dptr = dtop = rbot = rptr = 0,
	rtop = ibot = iptr = 4;
	itop = countof(image);

	return run() ? EXIT_FAILURE : EXIT_SUCCESS;
}
