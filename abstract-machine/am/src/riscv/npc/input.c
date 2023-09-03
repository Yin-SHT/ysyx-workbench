#include <am.h>
#include "./include/npc.h"
#include "../riscv.h"

#define KEYDOWN_MASK 0x8000
#define SCANCODE_MASK 0x000000FF

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t kbd_reg = inl(KBD_ADDR);
  kbd->keydown = kbd_reg & KEYDOWN_MASK;
  kbd->keycode = kbd_reg & SCANCODE_MASK;
}