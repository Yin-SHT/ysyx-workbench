#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t size = inl(VGACTL_ADDR);
  cfg->present = true; // ?
  cfg->has_accel = false; // ?
  cfg->width = size >> 16;
  cfg->height = size & 0x0000ffff;
}

static void write_pixels(AM_GPU_FBDRAW_T *ctl) {
  int W = inw(VGACTL_ADDR + 2);
  int H = inw(VGACTL_ADDR);
  uint32_t *dst = (uint32_t*)(uintptr_t)FB_ADDR + ctl->x + ctl->y * W; 
  uint32_t *src = (uint32_t*)(uintptr_t)ctl->pixels;
  int nr_rows = (H - ctl->y) < ctl->h ? (H - ctl->y) : ctl->h;
  for (int i = 0; i < nr_rows; i++) {
    int nr_cols = (W - ctl->x) < ctl->w ? (W - ctl->x) : ctl->w;
    memcpy(dst + i * W, src + i * ctl->w, nr_cols * 4);
  }
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  write_pixels(ctl);
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
