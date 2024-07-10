#include <common.h>
#include <fs.h>
#include <sys/time.h>
#include "syscall.h"

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_yield:  yield(); c->GPRx = 0; break;
    case SYS_open:   c->GPRx = fs_open((const char*)a[1], a[2], a[3]); break;
    case SYS_write:  c->GPRx = fs_write(a[1], (void*)a[2], a[3]); break;
    case SYS_read:   c->GPRx = fs_read(a[1], (void*)a[2], a[3]); break;
    case SYS_lseek:  c->GPRx = fs_lseek(a[1], a[2], a[3]); break;
    case SYS_close:  c->GPRx = fs_close(a[1]); break;
    case SYS_brk:    c->GPRx = 0; break;
    case SYS_exit:   {
      if (a[1] != 0) halt(a[1]);

      char *argv[] = {"/bin/nterm", NULL};
      char *envp[] = {NULL};
      context_uload(pick_pcb(1), argv[0], argv, envp); 
      switch_boot_pcb();     
      yield();
      break;
    }
    case SYS_execve: {
      if (fs_open((char *)(a[1]), 0, 0) == -1) {
        c->GPRx = -2;
        break;
      }

      context_uload(pick_pcb(1), (char *)(a[1]), (char **)(a[2]), (char **)(a[3])); 
      switch_boot_pcb();     
      yield();
      break;
    }
    case SYS_gettimeofday: {
      // Returns the time elapsed since the system was started. 
      ((struct timeval*)a[1])->tv_usec = io_read(AM_TIMER_UPTIME).us; 
      ((struct timeval*)a[1])->tv_sec  = 0;
      c->GPRx = 0;
      break;
    }
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
