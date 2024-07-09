#include <stdio.h>
#include <sys/time.h>
#include <NDL.h>

// millisecond
#define TV(sec) ((uint32_t)(sec * 1000))

int main() {
  int cnt = 0;
  uint32_t last = NDL_GetTicks();
  uint32_t now = NDL_GetTicks();

  while (1) {
    uint32_t now = NDL_GetTicks();
    if (now  - last >= TV(0.5)) {
      last = now;
      cnt ++;
      printf("Hello World (%d)!\n", cnt);
    }
  }

  return 0;
}