#include <stdio.h>
#include <sys/time.h>
#include <NDL.h>

int main() {
  int sec = 1;
  NDL_Init(0);

  uint32_t boot_time = NDL_GetTicks();
  while (1) {
    while(1) {
      uint32_t usec = NDL_GetTicks() - boot_time;
      if (usec / 500 >= sec) {
        break;
      }
    }
    printf("Hello, timer! (%d)\n", sec);
    sec ++;
  }
  NDL_Quit();
  return 0;
}