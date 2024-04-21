#include <am.h>
#include "./include/ysyxSoC.h"
#include "../riscv.h"

#define VAG_BASE 0x21000000

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  cfg->present = true; // ?
  cfg->has_accel = false; // ?
  cfg->width = 640;
  cfg->height = 480;
}

static void write_pixels(AM_GPU_FBDRAW_T *ctl) {
  int W = 640;
  int H = 480;
  uint32_t *dst = (uint32_t*)(uintptr_t)VAG_BASE + ctl->x + ctl->y * W; 
  uint32_t *src = (uint32_t*)(uintptr_t)ctl->pixels;
  int nr_rows = (H - ctl->y) < ctl->h ? (H - ctl->y) : ctl->h;
  for (int i = 0; i < nr_rows; i++) {
    int nr_cols = (W - ctl->x) < ctl->w ? (W - ctl->x) : ctl->w;
    for (int j = 0; j < nr_cols; j ++) {
      uint32_t wdata = *(src + i * ctl->w + j);
      outl((uintptr_t)(dst + i * W + j), wdata);
    }
  }
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  write_pixels(ctl);
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
