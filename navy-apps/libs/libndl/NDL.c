#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <assert.h>
#include <sys/time.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int fb_fd = -1;
static int delta_x = 0, delta_y = 0;
static int canvas_w = 0, canvas_h = 0;
static int screen_w = 0, screen_h = 0;
static struct timeval boot_time = {};

/*
 * Returns the time elapsed since 
 * the system was booted in millisecond.
*/
uint32_t NDL_GetTicks() {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint32_t secs = now.tv_sec - boot_time.tv_sec;
  uint32_t usecs = now.tv_usec - boot_time.tv_usec;
  return (secs * 1000000 + usecs) / 1000;
}

/*
 * Read an event message and write it to 'buf', 
 * with the longest being written to 'len' bytes.
 * If a valid event is read, the function returns 1; 
 * otherwise, it returns 0.
*/
int NDL_PollEvent(char *buf, int len) {
  int fd = open("/dev/events", 0);
  if (fd == -1) return 0; // file open failed
  int ret = read(fd, buf, len);
  if (ret == -1 || ret == 0) return 0; // read file failed or no event be read
  return 1;
}

/*
 * Open a canvas of (*w) X (*h), if *w and *h are both 0, 
 * use the full system screen as the canvas and 
 * set *w and *h to the size of the system screen, respectively.
 * Size of canvas can't over size of screen.
*/
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

  if (*w > screen_w || *w == 0) *w = screen_w;
  if (*h > screen_h || *h == 0) *h = screen_h;
  canvas_w = *w;
  canvas_h = *h;
  delta_x = (screen_w - canvas_w) / 2;
  delta_y = (screen_h - canvas_h) / 2;
}

/*
 * Draw a rectangular image of 'w * h' at the coordinates 
 * of the canvas '(x, y)' and synchronize the drawing area 
 * to the screen. Image pixels are stored in a row first 
 * manner in pixels, and each pixel is described as a color 
 * using a 32-bit integer in the form of 00RRGGBB.
*/
void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  /* Upper left of canvas is (delta_x, delta_y) */
  for (int i = 0; i < h; i++) {
    lseek(fb_fd, (delta_x + delta_y * screen_w + x + (y + i) * screen_w) * sizeof(uint32_t), SEEK_SET);
    write(fb_fd, pixels + i * w, w * sizeof(uint32_t));
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

  /* Get boot_time of system */
  gettimeofday(&boot_time, NULL);

  /* Get size of screen */
  char buf[128];
  int fd = open("/proc/dispinfo", 0);
  assert(fd != -1);
  int ret = read(fd, buf, sizeof(buf));
  assert(ret != -1);
  sscanf(buf, "WIDTH : %d HEIGHT : %d", &screen_w, &screen_h);

  /* Get fd of /dev/fb */
  fb_fd = open("/dev/fb", 0);
  assert(fb_fd != -1);

  return 0;
}

void NDL_Quit() {
}
