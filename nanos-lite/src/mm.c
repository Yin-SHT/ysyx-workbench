#include <memory.h>

static void *pf = NULL;

void* new_page(size_t nr_page) {
  pf = (void *)((uintptr_t)pf + nr_page * PGSIZE);
  return pf;
}

#ifdef HAS_VME
void* pg_alloc(int n) {
  uint8_t *a = (uint8_t *)new_page(n / PGSIZE) - n;
  /* set all pages to zero */
  for (int i = 0; i < n; i++) a[i] = 0;
  return (void *)a;
}
#endif

void free_page(void *p) {
  panic("not implement yet");
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
