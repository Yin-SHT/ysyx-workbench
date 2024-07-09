#include <NDL.h>
#include <sdl-timer.h>
#include <stdio.h>

SDL_TimerID SDL_AddTimer(uint32_t interval, SDL_NewTimerCallback callback, void *param) {
  return NULL;
}

int SDL_RemoveTimer(SDL_TimerID id) {
  return 1;
}

/**
 * Get the number of milliseconds since SDL 
 * library initialization. Returns an 
 * unsigned 32-bit value representing the number 
 * of milliseconds since the SDL library initialized.
 */
uint32_t SDL_GetTicks() {
  return NDL_GetTicks();
}

/**
 * Wait a specified number of milliseconds before returning.
 * This function waits a specified number of milliseconds before returning. 
 * It waits at least the specified time, but possibly longer due to OS scheduling.
 */
void SDL_Delay(uint32_t ms) {
  uint32_t begin = NDL_GetTicks();
  while ((NDL_GetTicks() - begin) < ms);
  return;
}
