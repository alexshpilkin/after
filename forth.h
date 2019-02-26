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

#endif /* ndef FORTH_H_ */
