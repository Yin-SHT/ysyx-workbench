#include <memory.h>

static void *pf = NULL;

void* new_page(size_t nr_page) {
  void *old = (void *)ROUNDUP(pf, PGSIZE);
  pf = old + nr_page * PGSIZE;
  assert(pf <= heap.end);
  char *p = (char *)old;
  for (int _ = 0; _ < nr_page * PGSIZE; _ ++)
    p[_] = 0;
  return old;
}

#ifdef HAS_VME
static void* pg_alloc(int n) {
  assert((n % PGSIZE) == 0);
  char *addr = new_page(n / PGSIZE);
  return (void *)addr;
}
#endif

void free_page(void *p) {
  // don't free mem for simplify
  return;
}

/* The brk() system call handler. */
int mm_brk(uintptr_t brk) {
  return 0;
}

void init_mm() {
  pf = (void *)ROUNDUP(heap.start, PGSIZE);
  Log("free physical pages starting from %p", pf);

#ifdef HAS_VME
  vme_init(pg_alloc, free_page);
#endif
}
