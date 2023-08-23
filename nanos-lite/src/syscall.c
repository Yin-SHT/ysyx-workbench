#include <common.h>
#include "syscall.h"

static uintptr_t sys_write(int fd, void *buf, size_t count) {
  if (fd == 0 || fd == 1) {
    char *str = (char*)buf;
    for (size_t i = 0; i < count; i++) {
      putch(str[i]);
    }
    return count;
  }
  return -1;
}

static int sys_brk(uintptr_t addr) {
  return 0;
}

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_exit: halt(a[1]); break;
    case SYS_yield: yield(); break;
    case SYS_write: c->GPRx = sys_write(a[1], (void*)a[2], a[3]); break;
    case SYS_brk: c->GPRx = sys_brk(a[1]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}