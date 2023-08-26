#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;

int open(const char *path, int flags, ...);

uint32_t NDL_GetTicks() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return tv.tv_usec;
}

int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events", 0);
  return read(fd, buf, len);
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
  } else {
    char buf[128];
    int fd = open("/proc/dispinfo", 0);
    read(fd, buf, sizeof(buf));
    sscanf(buf, "WIDTH : %d HEIGHT : %d", &screen_w, &screen_h);
    printf("SCREEN_W: %d SCREEN_H: %d\n", screen_w, screen_h);
    printf("CANVAS_W: %d CANVAS_H: %d\n", *w, *h);
    if (*w > screen_w) {
      *w = screen_w;
      printf("A-CANVAS_W: %d ", *w);
    }
    if (*h > screen_h) {
      *h = screen_h;
      printf("A-CANVAS_H: %d\n", *h);
    }
  }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  int fd = open("/dev/fb", 0);
  int canvas_fd = open("/proc/canvas", 0);
  lseek(fd, x + y * screen_w, SEEK_SET);
  if (!x && !y && !w && !h) {
    /* Tell the width of canvas to os */
    write(canvas_fd, NULL, screen_w);
    write(fd, pixels, screen_w * screen_h * sizeof(uint32_t));
  } else {
    write(canvas_fd, NULL, w);
    write(fd, pixels, w * h * sizeof(uint32_t));
  }
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
