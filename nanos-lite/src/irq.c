#include <common.h>
#include <proc.h>

void do_syscall(Context *c);

static Context* do_event(Event e, Context* c) {
  switch (e.event) {
    case EVENT_SYSCALL: do_syscall(c); break;
    case EVENT_YIELD: c = schedule(c); break;

    // patch for native
    case EVENT_IRQ_TIMER: break;
    case EVENT_IRQ_IODEV: break;
    default: panic("Unhandled event ID = %d", e.event);
  }

  return c;
}

void init_irq(void) {
  Log("Initializing interrupt/exception handler...");
  cte_init(do_event);
}
