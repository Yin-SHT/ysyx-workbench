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

static uintptr_t args_init(char *const argv[], char *const envp[]) {
  /* Create a new stack of 32kb */
  void *ustack = new_page(8);
  char *str_st = (char *)((uintptr_t)ustack - 512);

  /* Write process arguments */
  int nr_argv = 0;
  uintptr_t *_argv = (uintptr_t *)((uintptr_t)ustack - 1024);
  while (argv && *argv) {
    if ((uintptr_t)(*argv) < 0x80000000) break;
    strcpy(str_st, *argv ++);
    _argv[nr_argv ++] = (uintptr_t)str_st;
    str_st += strlen(str_st) + 1;
  }
  _argv[nr_argv] = 0;

  /* Write environment variables */
  int nr_envp = 0;
  uintptr_t *_envp = _argv + nr_argv + 1;
  while (envp && *envp) {
    if ((uintptr_t)(*envp) < 0x80000000) break;
    strcpy(str_st, *envp ++);
    _envp[nr_envp ++] = (uintptr_t)str_st; 
    str_st += strlen(str_st) + 1;
  }
  _envp[nr_envp] = 0;

  /* Write the number of process arguments */
  *(_argv - 1) = nr_argv;

  return (uintptr_t)(_argv - 1);
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};

  /* Get user process entry */
  void *entry = (void *)loader(pcb, filename);

  /* Create user process context */
  pcb->cp = ucontext(NULL, kstack, entry);

  /* Set user stack base address */
  pcb->cp->GPRx = args_init(argv, envp);  // convention with navy-apps
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
  char *argv[] = {"/bin/nterm", NULL};
  char *envp[] = {NULL};

  context_kload(&pcb[0], hello_fun, "first");
  context_uload(&pcb[1], argv[0], argv, envp);
  switch_boot_pcb();

  Log("Initializing processes...");

  // load program here
//  void naive_uload(PCB *pcb, const char *filename);
//  naive_uload(NULL, "/bin/nterm");

}

Context* schedule(Context *prev) {
  // save the context pointer
  current->cp = prev;

  // schedule the next process
  current = (current == &pcb[0] ? &pcb[1] : &pcb[0]);

  // then return the new context
  return current->cp;
}
