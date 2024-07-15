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
    if (cnt % 1000000 == 0) {
      Log("Hello World from Nanos-lite with arg '%s' for the %dth time!", (char *)arg, j);
      j ++;
    }
    cnt ++;
    yield();
  }
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
//  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);
  current = &pcb[1];
  return current->cp;
}
