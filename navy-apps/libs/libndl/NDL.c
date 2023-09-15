#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <assert.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;
static struct timeval boot_time = {};

uint32_t NDL_GetTicks() {
  struct timeval tv;
  assert(gettimeofday(&tv, NULL) != -1);

#if defined(__ISA_NATIVE__)
  struct timeval now;
  gettimeofday(&now, NULL);
  long seconds = now.tv_sec - boot_time.tv_sec;
  long useconds = now.tv_usec - boot_time.tv_usec;
  tv.tv_usec = seconds * 1000000 + useconds;
#endif

  /* return system time as the number of microsecond */
  // 1. libos, libc, nanos-lite, linux: uptime->us = seconds * 1000000 + (useconds + 500);
  // 1. libos, libc, nanos-lite, nemu: us = now.tv_sec * 1000000 + now.tv_usec - boot_time;
  return tv.tv_usec / 1000;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events", 0);
  assert(fd != -1);
  int ret = read(fd, buf, len);
  assert(ret != -1);
  return ret;
}

void NDL_OpenCanvas(int *w, int *h) {
  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  } 

  printf("canvas_w: %d canvas_h: %d\n", *w, *h);
  if (*w > screen_w || *w == 0) {
    *w = screen_w;
  }
  if (*h > screen_h || *h == 0) {
    *h = screen_h;
  }
  canvas_w = *w;
  canvas_h = *h;
  printf("CANVAS_W: %d CANVAS_H: %d\n", canvas_w, canvas_h);
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  int fd = open("/dev/fb", 0);
  /* Upper left of canvas is (delta_x, delta_y) */
  int delta_x = (screen_w - canvas_w) / 2;
  int delta_y = (screen_h - canvas_h) / 2;
  for (int i = 0; i < h; i++) {
    lseek(fd, (delta_x + delta_y * screen_w + x + (y + i) * screen_w) * sizeof(uint32_t), SEEK_SET);
    write(fd, pixels + i * w, w * sizeof(uint32_t));
  }
}

void NDL_OpenAudio(int freq, int channels, int samples) {
  int cfg[3] = {freq, channels, samples};
  int fd = open("/dev/sbctl", O_WRONLY);
  write(fd, cfg, 12);
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  int fd = open("/dev/sb", O_WRONLY);
  while (NDL_QueryAudio() < len);
  return write(fd, buf, len);
}

int NDL_QueryAudio() {
  char buf[16] = {0};
  int fd = open("/dev/sbctl", O_RDONLY);
  read(fd, buf, 16);
  int avai = 0;
  sscanf(buf, " %d ", &avai);
  return avai;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }

  /* Get boot_time of system */
  gettimeofday(&boot_time, NULL);

  /* Get size of screen */
  char buf[128];
  int fd = open("/proc/dispinfo", 0);
  assert(fd != -1);
  assert(read(fd, buf, sizeof(buf)) != -1);
  sscanf(buf, "WIDTH : %d HEIGHT : %d", &screen_w, &screen_h);
  printf("SCREEN_W: %d SCREEN_H: %d\n", screen_w, screen_h);

  return 0;
}

void NDL_Quit() {
}
