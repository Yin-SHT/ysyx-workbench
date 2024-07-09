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

void context_uload(PCB *pcb, char *filename) {
  void *entry = (void *) loader(pcb, filename);

  AddrSpace as = {};
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = ucontext(&as, kstack, entry);
  assert(pcb->cp);

  // convention with navy-apps
  pcb->cp->GPRx = (uintptr_t) heap.end;
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
  assert(pcb->cp);
}

void init_proc() {
  context_kload(&pcb[0], hello_fun, "A");
  context_uload(&pcb[1], "/bin/pal");
  switch_boot_pcb();

  Log("Initializing processes...");
}

Context* schedule(Context *prev) {
  current->cp = prev;
  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);
  return current->cp;
}
