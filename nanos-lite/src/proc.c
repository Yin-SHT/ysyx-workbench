#include <proc.h>

#define MAX_NR_PROC 4

static PCB pcb[MAX_NR_PROC] __attribute__((used)) = {};
static PCB pcb_boot = {};
PCB *current = NULL;

void switch_boot_pcb() {
  current = &pcb_boot;
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
}

void context_uload(PCB *pcb, const char *filename) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  
  uintptr_t loader(PCB *pcb, const char *filename);
  void *entry = (void *)loader(NULL, filename);
  pcb->cp = ucontext(NULL, kstack, entry);
  pcb->cp->GPRx = (uintptr_t)heap.end;
}

void hello_fun(void *arg) {
  int j = 1;
  while (1) {
    Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
    j ++;
    yield();
  }
}

void init_proc() {
  context_kload(&pcb[0], hello_fun, "first");
  context_uload(&pcb[1], "/bin/pal");
  switch_boot_pcb();

  Log("Initializing processes...");

  // load program here
//  void naive_uload(PCB *pcb, const char *filename);
//  naive_uload(NULL, "/bin/nterm");

}

Context* schedule(Context *prev) {
  // save the context pointer
  current->cp = prev;

  // always select pcb[0] as the new process
  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);

  // then return the new context
  return current->cp;
}
