#ifndef FORTH_H_
#define FORTH_H_ 1

#include <limits.h>

typedef unsigned int word_t;
#define ULIT(c) c
#define UMAX UINT_MAX
#define SIGN ((UMAX >> 1) + 1)
#define PRIX "X"

#ifndef PRI0
#if ! defined UMAX
#error "UMAX is not defined"
#elif UMAX <= ULIT(0xFF)
#define PRI0 "02" PRIX
#elif UMAX <= ULIT(0xFFFF)
#define PRI0 "04" PRIX
#elif UMAX <= ULIT(0xFFFFFFFF)
#define PRI0 "08" PRIX
#elif UMAX <= ULIT(0xFFFFFFFFFFFFFFFF)
#define PRI0 "016" PRIX
#else
#error "could not guess PRI0"
#endif
#endif

#define FAULTS \
FAULT("halt", HALT, halt) /* = 0 */ \
FAULT("abort", ABORT, abort) \
FAULT("invalid address", IADDR, iaddr) \
FAULT("inconsistent stack", STACK, stack) \
FAULT("underflow", UFLOW, uflow) \
FAULT("overflow", OFLOW, oflow) \
/* FAULTS */

typedef enum {
#define FAULT(MSG, UPPER, LOWER) \
	F##UPPER,
FAULTS
#undef FAULT
	NFAULTS
} fault_t;

#define STKPRIMS(NAME, VAR) \
PRIM("@R" #NAME, FETCHR##NAME, \
     dput(1); dpsh = r##VAR;) \
PRIM("!R" #NAME, STORER##NAME, \
     dget(1); r##VAR = dpop; rchk;) \
PRIM("@D" #NAME, FETCHD##NAME, \
     dput(1); x = d##VAR; dpsh = x;) \
PRIM("!D" #NAME, STORED##NAME, \
     dget(1); x = dpop; d##VAR = x; dchk;) \
/* STACKPRIMS */

#define PRIMS \
PRIM("ABORT", ABORT, goto abort;) /* = -1 */ \
PRIM("HALT", HALT, goto halt;) \
PRIM("EXIT", EXIT, rget(1); iptr = rpop;) \
PRIM("EXECUTE", EXECUTE, dget(1); rput(1); rpsh = iptr; iptr = dpop;) \
STKPRIMS(P, ptr) \
STKPRIMS(B, bot) \
STKPRIMS(T, top) \
/* PRIMS */

enum {
#define PRIM(NAME, ID, BODY) \
	P##ID,
PRIMS
#include "prims.h"
#undef PRIM
	NPRIMS
};

#endif /* ndef FORTH_H_ */
