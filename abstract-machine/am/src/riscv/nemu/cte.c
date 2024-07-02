#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

void __am_get_cur_as(Context *c);
void __am_switch(Context *c);

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
#ifdef __riscv_e
  int syscall_num = c->gpr[15];   // x15/a5
#else
  int syscall_num = c->gpr[17];   // x17/a7
#endif

  // reserve old pdir
  __am_get_cur_as(c);

  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      // 11: Environment call from M-mode
      case 11: {
        if (syscall_num >= 0) { ev.event = EVENT_SYSCALL; c->mepc += 4; } 
        else if (syscall_num == -1) { ev.event = EVENT_YIELD; c->mepc += 4; } 
        else { ev.event = EVENT_ERROR; }
        break;
      }
      default: ev.event = EVENT_ERROR; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  // switch to new pdir
  __am_switch(c);

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
  Context context = {};

  /* Initial state of a process to be executed */  
  context.GPR2 = (uintptr_t)arg;  // a0-a7 save args
  context.mepc = (uintptr_t)entry;
  context.mstatus = 0x1800;

  Context *cp = (Context *)kstack.end - 1;
  *cp = context;

  return cp;
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
