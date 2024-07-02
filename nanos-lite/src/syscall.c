#include <common.h>
#include <fs.h>
#include "syscall.h"

size_t serial_write(const void *buf, size_t offset, size_t len);

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_exit:  halt(a[1]); break;
    case SYS_yield: yield(); c->GPRx = 0; break;
    case SYS_open:  c->GPRx = fs_open((const char*)a[1], a[2], a[3]); break;
    case SYS_write: if (a[1] == 1 || a[1] == 2) 
                      c->GPRx = serial_write((void *)a[2], 0, a[3]);
                    else 
                      c->GPRx = fs_write(a[1], (void*)a[2], a[3]); 
                    break;
    case SYS_read:  c->GPRx = fs_read(a[1], (void*)a[2], a[3]); break;
    case SYS_lseek: c->GPRx = fs_lseek(a[1], a[2], a[3]); break;
    case SYS_close: c->GPRx = fs_close(a[1]); break;
    case SYS_brk:   c->GPRx = 0; break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
