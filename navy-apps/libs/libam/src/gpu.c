#include <am.h>
#include <NDL.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

void __am_gpu_init() {
  int w = 0, h = 0;

  NDL_Init(0);
  NDL_OpenCanvas(&w, &h);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  cfg->present = true; // ?
  cfg->has_accel = false; // ?

  /* Get size of screen */
  char buf[128];
  int fd = open("/proc/dispinfo", 0);
  int screen_w = 0;
  int screen_h = 0;
  read(fd, buf, sizeof(buf));
  sscanf(buf, "WIDTH : %d HEIGHT : %d", &screen_w, &screen_h);
  cfg->width = screen_w;
  cfg->height = screen_h;
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  NDL_DrawRect(ctl->pixels, ctl->x, ctl->y, ctl->w, ctl->h);
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
