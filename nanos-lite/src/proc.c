#include <proc.h>
#include <memory.h>

#define MAX_NR_PROC 4

static PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

PCB *pick_pcb(int i) {
  assert(i >= 0 && i < MAX_NR_PROC);
  return &pcb[i];
}

void switch_boot_pcb() {
  current = &pcb_boot;
}

void hello_fun(void *arg) {
  int j = 1;
  uint32_t cnt = 0;
  while (1) {
    if (cnt % 100000 == 0) {
      Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
      j ++;
    }
    cnt ++;
    yield();
  }
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  // create initial state to execute
  AddrSpace as = {};
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = ucontext(&as, kstack, (void *)get_entry(filename));
  assert(pcb->cp);

  // arrange args & envs
  void *ustack = new_page(8) + 8 * PGSIZE;  // stack size: 32 KB
  void *area = ustack - PGSIZE / 2; // used to store string (2048 Bytes)
  void *sp = ustack - PGSIZE;
  
  int argc = 0;
  char **ARGV = (char **)(sp + sizeof(uintptr_t));
  while (argv[argc]) {
    ARGV[argc] = area;
    strcpy(area, argv[argc]);
    area = area + strlen(argv[argc]) + 1;
    argc ++;
  }
  ARGV[argc] = NULL;

  int envc = 0;
  char **ENVP = ARGV + argc + 1;
  while (envp[envc]) {
    ENVP[envc] = area;
    strcpy(area, envp[envc]);
    area = area + strlen(envp[envc]) + 1;
    envc ++;
  }
  ENVP[envc] = NULL;

  // set stack pointer (convention with navy-apps)
  *((uintptr_t *)sp) = argc;
  pcb->cp->GPRx = (uintptr_t) sp;

  // load program to mem
  loader(pcb, filename);
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
  assert(pcb->cp);
}

void init_proc() {
  char *argv[] = {"/bin/nterm", NULL};
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
