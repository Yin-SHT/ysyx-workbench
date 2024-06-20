#include <am.h>

bool vme_init(void* (*pgalloc_f)(int), void (*pgfree_f)(void*)) {
  return false;
}

void protect(AddrSpace *as) {
}

void unprotect(AddrSpace *as) {
}

void map(AddrSpace *as, void *va, void *pa, int prot) {
}

Context *ucontext(AddrSpace *as, Area kstack, void *entry) {
  Context context = {};

  /* Initial state of a process to be executed */  
  context.mepc = (uintptr_t)entry;
//  context.mstatus = 0x1800;

  Context *cp = (Context *)kstack.end - 1;
  *cp = context;

  return cp;
}
