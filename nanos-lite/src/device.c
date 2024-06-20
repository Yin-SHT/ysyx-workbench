#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  yield(); // simulate slow device access
  char *str = (char*)buf;
  int i = 0;
  while (i < len && str[i]) {
    putch(str[i]);
    i ++;
  }
  return i;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  yield(); // simulate slow device access
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (ev.keycode != AM_KEY_NONE) {
    return snprintf(buf, len, "%s %s\n", ev.keydown ? "kd" : "ku", keyname[ev.keycode]);
  }
  return 0;
}

static int screen_w = 0;
static int screen_h = 0;

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  screen_w = io_read(AM_GPU_CONFIG).width;
  screen_h = io_read(AM_GPU_CONFIG).height;
  return snprintf(buf, len, "WIDTH : %d\nHEIGHT : %d\n", screen_w, screen_h);
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  yield(); // simulate slow device access
  assert(screen_w != 0);
  int x = (offset / sizeof(uint32_t)) % screen_w;
  int y = (offset / sizeof(uint32_t)) / screen_w;
  void *pixels = (void *)buf;
  io_write(AM_GPU_FBDRAW, x, y, pixels, len / sizeof(uint32_t), 1, false);
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, true);
  return len;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
