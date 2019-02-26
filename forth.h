#ifndef FORTH_H_
#define FORTH_H_ 1

#include <limits.h>

typedef unsigned int word_t;
#define UMAX UINT_MAX
#define SIGN ((UMAX >> 1) + 1)

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
