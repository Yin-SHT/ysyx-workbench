#include <proc.h>

#define MAX_NR_PROC 4

static PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

void switch_boot_pcb() {
  current = &pcb_boot;
}

void hello_fun(void *arg) {
  int j = 1;
  uint32_t cnt = 0;
  while (1) {
    if (cnt % 10000 == 0) {
      Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
      j ++;
    }
    cnt ++;
    yield();
  }
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  void *entry = (void *) loader(pcb, filename);

  // initialize kernel stack
  AddrSpace as = {};
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = ucontext(&as, kstack, entry);
  assert(pcb->cp);

  // initialize args
  void *area = heap.end - PGSIZE / 2; // used to store string (2048 Bytes)
  void *sp = heap.end - PGSIZE;

  int argc = 0;
  char **_argv_ = (char **)(sp + sizeof(uintptr_t));
  while (argv && argv[argc]) {
    _argv_[argc] = area;
    strcpy(area, argv[argc]);
    area = area + strlen(argv[argc]) + 1;
    argc ++;
  }
  _argv_[argc] = NULL;

  int envc = 0;
  char **_envp_ = _argv_ + argc + 1;
  while (envp && envp[envc]) {
    _envp_[envc] = area;
    area = strcpy(area, envp[envc]);
    area = area + strlen(envp[argc]) + 1;
    envc ++;
  }
  _envp_[envc] = NULL;

  // convention with navy-apps
  *((uintptr_t *)sp) = argc;
  pcb->cp->GPRx = (uintptr_t) sp;
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
  assert(pcb->cp);
}

void init_proc() {
  char *argv[] = {"/bin/pal", "--skip", NULL};
  char *envp[] = {NULL};

  context_kload(&pcb[0], hello_fun, "A");
  context_uload(&pcb[1], argv[0], argv, envp);
  switch_boot_pcb();

  Log("Initializing processes...");
}

Context* schedule(Context *prev) {
  current->cp = prev;
  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);
  return current->cp;
}
