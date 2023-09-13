#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;

int open(const char *path, int flags, ...);

uint32_t NDL_GetTicks() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  /* return system time as the number of microsecond */
  return (tv.tv_sec * 1000000 + tv.tv_usec) / 1000;
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
    printf("canvas_W: %d canvas_H: %d\n", *w, *h);
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
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  int fd = open("/dev/fb", 0);
  int rect_fd = open("/proc/rect", 0);
  /* Upper left of canvas is (delta_x, delta_y) */
  if (!canvas_w) {
    canvas_w = screen_w;
  }
  if (!canvas_h) {
    canvas_h = screen_h;
  }
  int delta_x = (screen_w - canvas_w) / 2;
  int delta_y = (screen_h - canvas_h) / 2;
  lseek(fd, (delta_x + delta_y * screen_w + x + y * canvas_w) * sizeof(uint32_t), SEEK_SET);
  write(rect_fd, NULL, w);
  write(fd, pixels, w * h * sizeof(uint32_t));
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

  /* Get size of screen */
  char buf[128];
  int fd = open("/proc/dispinfo", 0);
  read(fd, buf, sizeof(buf));
  sscanf(buf, "WIDTH : %d HEIGHT : %d", &screen_w, &screen_h);
  printf("SCREEN_W: %d SCREEN_H: %d\n", screen_w, screen_h);

  return 0;
}

void NDL_Quit() {
}
