#ifndef FORTH_H_
#define FORTH_H_ 1

#include <limits.h>

typedef unsigned int word_t;
#define ULIT(c) c
#define UMAX UINT_MAX
#define SIGN ((UMAX >> 1) + 1)
#define PRIX "X"

#ifndef PRI0
#if UMAX <= ULIT(0xFF)
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

#define PRIMS \
PRIM("ABORT", ABORT, goto abort;) /* = -1 */ \
PRIM("HALT", HALT, goto halt;) \
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

#endif /* ndef FORTH_H_ */
