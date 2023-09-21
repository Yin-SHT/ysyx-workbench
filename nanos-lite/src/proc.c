#include <proc.h>

#define MAX_NR_PROC 4

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

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
}

static void args_init(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  int nr_argv = 0;
  char  * const*p = argv;
  while (p && *p) {
    nr_argv ++;
    p ++;
  }

  int nr_envp = 0;
  p = envp;
  while (p && *p) {
    nr_envp ++;
    p ++;
  }

  void *ustack = new_page(8);
  char *str_st = (char *)((uint8_t *)ustack - 1024);
  uintptr_t *_argv = (uintptr_t *)((uint8_t *)ustack - 2048);
  uintptr_t *_envp = _argv + nr_argv + 1;

  /* Write filename */
  strcpy(str_st, filename);
  *(_argv + 0) = (uintptr_t)str_st;
  str_st += strlen(filename) + 1;

  /* Write regular args */
  for (int i = 0; i < nr_argv; i++) {
    strcpy(str_st, argv[i]);
    *(_argv + 1 + i) = (uintptr_t)str_st;
    str_st += strlen(argv[i]) + 1;
  }
  _argv[nr_argv] = 0;

  /* Write environment variables */
  for (int i = 0; i < nr_envp; i++) {
    strcpy(str_st, envp[i]);
    *(_envp + i) = (uintptr_t)str_st;
    str_st += strlen(envp[i]) + 1;
  }
  _envp[nr_envp] = 0;

  pcb->cp->GPRx = (uintptr_t)(_argv -1);
  *(_argv - 1) = nr_argv + 1;
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  
  uintptr_t loader(PCB *pcb, const char *filename);
  void *entry = (void *)loader(NULL, filename);
  pcb->cp = ucontext(NULL, kstack, entry);
//  pcb->cp->GPRx = (uintptr_t)heap.end;
  args_init(pcb, filename, argv, envp);
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
  char *argv[] = {"0", 0};
  char *envp[] = {"env", 0};

  context_kload(&pcb[0], hello_fun, "first");
  context_uload(&pcb[1], "/bin/exec-test", argv, envp);
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
