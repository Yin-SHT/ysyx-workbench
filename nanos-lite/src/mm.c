#include <memory.h>
#include <proc.h>

static void *pf = NULL;

void* new_page(size_t nr_page) {
  void *old = pf;
  pf += (nr_page * PGSIZE);
  assert(pf <= heap.end);
  return old;
}

#ifdef HAS_VME
static void* pg_alloc(int n) {
  assert(!(n % PGSIZE));
  void *addr = new_page(n / PGSIZE);
  memset(addr, 0, n);
  return addr;
}
#endif

void free_page(void *p) {
  panic("not implement yet");
}

/* The brk() system call handler. */
int mm_brk(uintptr_t brk) {
  assert(!(current->max_brk % PGSIZE));

  if (brk > current->max_brk) {
    brk = ROUNDUP(brk, PGSIZE);
    size_t nr_page = (brk - current->max_brk) / PGSIZE;

    // build new mappings
    void *va = (void*) current->max_brk;
    void *pa = new_page(nr_page);
    memset(pa, 0, nr_page * PGSIZE);
    for (int _ = 0; _ < nr_page; _ ++) {
      map(&current->as, va, pa, 0x001 | 0x002);
      va += PGSIZE;
      pa += PGSIZE;
    }

    // advance max_brk
    current->max_brk += nr_page * PGSIZE;
    assert((uintptr_t)va == brk);
    assert(current->max_brk == brk);
    assert(!(current->max_brk % PGSIZE));
  }
  return 0;
}

void init_mm() {
  pf = (void *)ROUNDUP(heap.start, PGSIZE);
  Log("free physical pages starting from %p", pf);

#ifdef HAS_VME
  vme_init(pg_alloc, free_page);
#endif
}
