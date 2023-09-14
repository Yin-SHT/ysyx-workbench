#include <am.h>
#include <NDL.h>
#include <string.h>

#define _KEYS(_) \
  _(ESCAPE) _(F1) _(F2) _(F3) _(F4) _(F5) _(F6) _(F7) _(F8) _(F9) _(F10) _(F11) _(F12) \
  _(GRAVE) _(1) _(2) _(3) _(4) _(5) _(6) _(7) _(8) _(9) _(0) _(MINUS) _(EQUALS) _(BACKSPACE) \
  _(TAB) _(Q) _(W) _(E) _(R) _(T) _(Y) _(U) _(I) _(O) _(P) _(LEFTBRACKET) _(RIGHTBRACKET) _(BACKSLASH) \
  _(CAPSLOCK) _(A) _(S) _(D) _(F) _(G) _(H) _(J) _(K) _(L) _(SEMICOLON) _(APOSTROPHE) _(RETURN) \
  _(LSHIFT) _(Z) _(X) _(C) _(V) _(B) _(N) _(M) _(COMMA) _(PERIOD) _(SLASH) _(RSHIFT) \
  _(LCTRL) _(APPLICATION) _(LALT) _(SPACE) _(RALT) _(RCTRL) \
  _(UP) _(DOWN) _(LEFT) _(RIGHT) _(INSERT) _(DELETE) _(HOME) _(END) _(PAGEUP) _(PAGEDOWN)

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

#define NR_KEYS (sizeof(keyname) / sizeof(keyname[0]))
static uint8_t keystate[NR_KEYS] = {0};

static void process_event(char *buf, AM_INPUT_KEYBRD_T *kbd) {
  char kmotion[32];
  char key[32];

  /* Process keyboard event */
  sscanf(buf, " %s %s ", kmotion, key);
  if (!strcmp(kmotion, "kd")) {
    kbd->keydown = true;
  } else if (!strcmp(kmotion, "ku")) {
    kbd->keydown = false;
  }
  
  uint8_t sym = 0;
  for (; sym < NR_KEYS; sym++) {
    if (!strcmp(keyname[sym], key)) {
      break;
    }
  }
  kbd->keycode = sym;
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  char buf[64] = {0};
  int nr_r = NDL_PollEvent(buf, 64);
  if (nr_r == 0) kbd->keycode = 0;
}
