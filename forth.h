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

#endif /* ndef FORTH_H_ */
