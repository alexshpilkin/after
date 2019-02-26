#if defined __GNUC__ || defined __clang__ || defined __icc__
#define slower(TEST) (__builtin_expect(!!(TEST), 0))
#define faster(TEST) (__builtin_expect(!!(TEST), 1))
#endif

#include <stdlib.h>

typedef unsigned int word_t;
#define UMAX UINT_MAX
#define SIGN ((UMAX >> 1) + 1)

#include "prims.c"

#define PRIMS \
PRIM("EXIT", EXIT, rget(1); iptr = rpop;) \
PRIM("EXECUTE", EXECUTE, dget(1); rput(1); rpsh = iptr; iptr = dpop;) \
/* PRIMS */

enum {
#define PRIM(NAME, ID, BODY) \
	P##ID,
PRIMS
#include "prims.h"
#undef PRIM
	NPRIMS
};

word_t *image,
        ibot, itop, iptr,
        rbot, rtop, rptr,
        dbot, dtop, dptr;

void run(void) {
	word_t insn;

#define addr(W) do { \
	word_t a = (W); \
	if slower(a < ibot || a >= itop) goto afault; \
} while(0)

#define get(STACK, N) do { \
	if slower(STACK##ptr - STACK##bot < (N)) goto ufault; \
} while(0)
#define put(STACK, N) do { \
	if slower(STACK##top - STACK##ptr < (N)) goto ofault; \
} while(0)
#define pop(STACK) image[--STACK##ptr]
#define psh(STACK) image[STACK##ptr++]

#define rget(N) get(r, (N))
#define rput(N) put(r, (N))
#define rpop    pop(r)
#define rpsh    psh(r)
#define dget(N) get(d, (N))
#define dput(N) put(d, (N))
#define dpop    pop(d)
#define dpsh    psh(d)

	addr(iptr); insn = image[iptr++];
	switch(~insn) {
	default: rput(1); rpsh = iptr; iptr = insn;
#define PRIM(NAME, ID, BODY) \
	case P##ID: { BODY } break;
PRIMS
#include "prims.h"
#undef PRIM
	}

ufault:
ofault:
afault:
	abort();
}
