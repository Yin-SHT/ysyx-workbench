#include <stdio.h>
#include <sys/time.h>

int main() {
  int sec = 1;
  struct timeval tv;
  while (1) {
    while(1) {
      gettimeofday(&tv, NULL);
      if (tv.tv_usec / 500000 >= sec) {
        break;
      }
    }
    printf("Hello, timer! (%d)\n", sec);
    sec ++;
  }
}