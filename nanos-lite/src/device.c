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
  char *str = (char*)buf;
  for (size_t i = 0; i < len; i++) {
    putch(str[i]);
  }
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (ev.keycode != AM_KEY_NONE) {
    return snprintf(buf, len, " %s %s ", ev.keydown ? "kd" : "ku", keyname[ev.keycode]);
  }
  return 0;
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  return snprintf(buf, len, "WIDTH : %d HEIGHT : %d", w, h);
}

static size_t canvas_w;
static size_t canvas_h;

size_t canvas_write(const void *buf, size_t offset, size_t len) {
  canvas_w = len;
  // 0 means success
  return 0;
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  int w = io_read(AM_GPU_CONFIG).width;
  int x = offset % w;
  int y = offset / w;
  canvas_h = len / sizeof(uint32_t) / canvas_w;
  char *tmp = malloc(len);
  memcpy(tmp, buf, len);
  io_write(AM_GPU_FBDRAW, x, y, tmp, canvas_w, canvas_h, false);
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, true);
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
