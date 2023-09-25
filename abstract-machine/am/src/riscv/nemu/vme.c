#include <am.h>
#include <nemu.h>
#include <klib.h>

static AddrSpace kas = {};
static void* (*pgalloc_usr)(int) = NULL;
static void (*pgfree_usr)(void*) = NULL;
static int vme_enable = 0;

static Area segments[] = {      // Kernel memory mappings
  NEMU_PADDR_SPACE
};

#define PPN(pte) (((uintptr_t)pte) >> 10)
#define VPN_1(va) (((uintptr_t)va) >> 22)
#define VPN_2(va) ((((uintptr_t)va) << 10) >> 22)
#define USER_SPACE RANGE(0x40000000, 0x80000000)

static inline void set_satp(void *pdir) {
  uintptr_t mode = 1ul << (__riscv_xlen - 1);
  asm volatile("csrw satp, %0" : : "r"(mode | ((uintptr_t)pdir >> 12)));
}

static inline uintptr_t get_satp() {
  uintptr_t satp;
  asm volatile("csrr %0, satp" : "=r"(satp));
  return satp << 12;
}

bool vme_init(void* (*pgalloc_f)(int), void (*pgfree_f)(void*)) {
  pgalloc_usr = pgalloc_f;
  pgfree_usr = pgfree_f;

  kas.ptr = pgalloc_f(PGSIZE);

  int i;
  for (i = 0; i < LENGTH(segments); i ++) {
    void *va = segments[i].start;
    for (; va < segments[i].end; va += PGSIZE) {
      map(&kas, va, va, 0);
    }
  }

  set_satp(kas.ptr);
  vme_enable = 1;

  return true;
}

void protect(AddrSpace *as) {
  PTE *updir = (PTE*)(pgalloc_usr(PGSIZE));
  as->ptr = updir;
  as->area = USER_SPACE;
  as->pgsize = PGSIZE;
  // map kernel space
  memcpy(updir, kas.ptr, PGSIZE);
}

void unprotect(AddrSpace *as) {
}

void __am_get_cur_as(Context *c) {
  c->pdir = (vme_enable ? (void *)get_satp() : NULL);
}

void __am_switch(Context *c) {
  if (vme_enable && c->pdir != NULL) {
    set_satp(c->pdir);
  }
}

void map(AddrSpace *as, void *va, void *pa, int prot) {
  /* Get first level page table entry */
  PTE *pt1_base = (PTE *)(as->ptr);         
  PTE pte_1 = pt1_base[VPN_1(va)];    

  if (!(pte_1 & 0x1)) {
    PTE *pt2_base = pgalloc_usr(PGSIZE);

    pte_1 = 0 | (((uintptr_t)pt2_base >> 12) << 10) | 0x1;
    pt1_base[VPN_1(va)] = pte_1; 
  }

  PTE *pt2_base = (PTE *)(PPN(pte_1) << 12);       
  PTE pte_2 = pt2_base[VPN_2(va)];               

  if (!(pte_2 & 0x1)) {
    /* Second page table entry invalid */
    PTE new_pte_2 = 0 | (((PTE)pa >> 12) << 10) | 0x1; 
    pt2_base[VPN_2(va)] = new_pte_2;
  } else {
    /* Second page table entry valid */
    assert(pte_2 == (0 | (((PTE)pa >> 12) << 10) | 0x1));
  }
}

Context *ucontext(AddrSpace *as, Area kstack, void *entry) {
  Context context = {};

  /* Initial state of a process to be executed */  
  context.mepc = (uintptr_t)entry;
  context.mstatus = 0x1800;

  Context *cp = (Context *)kstack.end - 1;
  *cp = context;

  return cp;
}
