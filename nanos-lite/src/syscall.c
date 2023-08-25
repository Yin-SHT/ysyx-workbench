#include <common.h>
#include <fs.h>
#include "syscall.h"

static uintptr_t sys_write(int fd, void *buf, size_t len) {
  return fs_write(fd, buf, len);
}

static uintptr_t sys_brk(uintptr_t addr) {
  return 0;
}

static uintptr_t sys_open(const char *pathname, int flags, int mode) {
  return fs_open(pathname, flags, mode);
}

static uintptr_t sys_read(int fd, void *buf, size_t len) {
  return fs_read(fd, buf, len);
}

static uintptr_t sys_lseek(int fd, size_t offset, int whence) {
  return fs_lseek(fd, offset, whence);
}

static uintptr_t sys_close(int fd) {
  return fs_close(fd);
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
    case SYS_open: c->GPRx = sys_open((const char*)a[1], a[2], a[3]); break;
    case SYS_write: c->GPRx = sys_write(a[1], (void*)a[2], a[3]); break;
    case SYS_read: c->GPRx = sys_read(a[1], (void*)a[2], a[3]); break;
    case SYS_lseek: c->GPRx = sys_lseek(a[1], a[2], a[3]); break;
    case SYS_close: c->GPRx = sys_close(a[1]); break;
    case SYS_brk: c->GPRx = sys_brk(a[1]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}