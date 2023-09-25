#include <fs.h>
#include <proc.h>
#include <common.h>
#include <sys/time.h>
#include "syscall.h"

static uintptr_t sys_brk(uintptr_t addr) {
  return 0;
}

static uintptr_t sys_gettimeofday(struct timeval *tv) {
  tv->tv_usec = io_read(AM_TIMER_UPTIME).us;
  return 0;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_gettimeofday: c->GPRx = sys_gettimeofday((struct timeval*)a[1]); break;
    case SYS_exit: halt(a[1]); break;
    case SYS_yield: yield(); c->GPRx = 0; break;
    case SYS_open: c->GPRx = fs_open((const char*)a[1], a[2], a[3]); break;
    case SYS_write: c->GPRx = fs_write(a[1], (void*)a[2], a[3]); break;
    case SYS_read: c->GPRx = fs_read(a[1], (void*)a[2], a[3]); break;
    case SYS_lseek: c->GPRx = fs_lseek(a[1], a[2], a[3]); break;
    case SYS_close: c->GPRx = fs_close(a[1]); break;
    case SYS_brk: c->GPRx = sys_brk(a[1]); break;
    case SYS_execve: {
      context_uload(select_pcb(1), (char *)(a[1]), (char **)(a[2]), (char **)(a[3])); 
      switch_boot_pcb();     
      yield();
      break;
    }
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}