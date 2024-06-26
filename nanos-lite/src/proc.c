#include <proc.h>

#define MAX_NR_PROC 4

uintptr_t loader(PCB *pcb, const char *filename);

static PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

PCB *select_pcb(int i) {
  assert(i >= 0 && i <= 3);
  return pcb + i;
}

void switch_boot_pcb() {
  current = &pcb_boot;
}

static uintptr_t args_init(AddrSpace *as, char *const argv[], char *const envp[]) {
  void *bottom = new_page(8);
  void *top = bottom + 8 * PGSIZE;
  void *area = top - PGSIZE / 2; // used to store string (2048 Bytes)
  void *sp = top - PGSIZE;

#ifdef HAS_VME
  void *va_end = as->area.end;
  void *va = as->area.end - 8 * PGSIZE;
  void *pa = bottom;
  for (; va < va_end; va += PGSIZE) {
    map(as, va, pa, PTE_R | PTE_W);
    pa += PGSIZE;
  }
  assert(va == as->area.end);
  assert(pa == top);
#endif

  // copy process arguments
  int argc = 0;
  char **_argv_ = (char **)(sp + sizeof(uintptr_t));
  while (argv && argv[argc]) {
    _argv_[argc] = area;
    strcpy(area, argv[argc]);
    area = area + strlen(argv[argc]) + 1;
    argc ++;
  }
  _argv_[argc] = NULL;

  // copy environment variables
  int envc = 0;
  char **_envp_ = _argv_ + argc + 1;
  while (envp && envp[envc]) {
    _envp_[envc] = area;
    area = strcpy(area, envp[envc]);
    area = area + strlen(envp[argc]) + 1;
    envc ++;
  }
  _envp_[envc] = NULL;

  *((uintptr_t *)sp) = argc;

  return (uintptr_t)sp;
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
#ifdef HAS_VME
  protect(&pcb->as);
#endif

  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};

  /* Get user process entry */
  void *entry = (void *)loader(pcb, filename);

  /* Create user process context */
  pcb->cp = ucontext(&pcb->as, kstack, entry);

  /* Set user stack base address */
  pcb->cp->GPRx = args_init(&pcb->as, argv, envp);  // convention with navy-apps
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};

  /* Create user process context */
  pcb->cp = kcontext(kstack, entry, arg);
}

void hello_fun(void *arg) {
  int j = 1;
  while (1) {
    if (j % 50000 == 0) {
      Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
    }
    j ++;
    yield();
  }
}

void init_proc() {
  char *argv[] = {"/bin/dummy", "--skip", NULL};
  char *envp[] = {NULL};

  context_kload(&pcb[0], hello_fun, "first");
  context_uload(&pcb[1], argv[0], argv, envp);
  switch_boot_pcb();

  Log("Initializing processes...");
}

Context* schedule(Context *prev) {
  // save the context pointer
  current->cp = prev;

  // schedule the next process
//  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);
  current = &pcb[1];

  // then return the new context
  return current->cp;
}
