#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

// SYS_CALL num that reversed in a7/a5
enum {
  SYS_exit, SYS_yield, SYS_open, SYS_read, SYS_write,
  SYS_kill, SYS_getpid, SYS_close, SYS_lseek, SYS_brk,
  SYS_fstat, SYS_time, SYS_signal, SYS_execve, SYS_fork,
  SYS_link, SYS_unlink, SYS_wait, SYS_times, SYS_gettimeofday
};

Context* __am_irq_handle(Context *c) {
#ifdef __riscv_e
  int syscall_num = c->gpr[15];   // x15/a5
#else
  int syscall_num = c->gpr[17];   // x17/a7
#endif

  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      // 11: Environment call from M-mode
      case 11: {
        switch (syscall_num) {
          case -1: ev.event = SYS_yield; break;
          default: ev.event = EVENT_ERROR; break;
        }
        break;
      }
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  return NULL;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
