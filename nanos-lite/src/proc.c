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
    if (cnt % 1000 == 0) {
      Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
      j ++;
    }
    cnt ++;
    yield();
  }
}

void init_proc() {
  char *argv[] = {NULL};
  char *envp[] = {NULL};

  context_uload(&pcb[0], "/bin/hello", argv, envp);
  context_uload(&pcb[1], "/bin/nterm", argv, envp);
  switch_boot_pcb();

  Log("Initializing processes...");
}

Context* schedule(Context *prev) {
  current->cp = prev;
  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);
  switch_as(current->cp);
  return current->cp;
}
