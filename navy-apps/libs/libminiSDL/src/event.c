#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>
#include <debug.h>

#define keyname(k) #k,
#define NR_KEYS (sizeof(keyname) / sizeof(keyname[0]))

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};
static uint8_t keystate[NR_KEYS] = {0};

int SDL_PushEvent(SDL_Event *ev) {
  TODO("SDL_PushEvent");
  return 0;
}

/**
 * Poll for currently pending events.
 * Returns 1 if there is a pending event 
 * or 0 if there are none available.
 */
int SDL_PollEvent(SDL_Event *ev) {
  uint8_t sym;
  char kmotion[32];
  char key[32];
  char buf[64];

  // no pending event
  if (!NDL_PollEvent(buf, sizeof(buf))) return 0;

  // ev is NULL
  if (!ev) return 1;

  sscanf(buf, " %s %s ", kmotion, key);
  if (!strcmp(kmotion, "kd")) ev->key.type =  SDL_KEYDOWN;
  else if (!strcmp(kmotion, "ku")) ev->key.type =  SDL_KEYUP;
  for (; sym < NR_KEYS; sym++) {
    if (!strcmp(keyname[sym], key)) {
      ev->key.keysym.sym = sym;
      break;
    }
  }
  keystate[sym] = (ev->key.type == SDL_KEYDOWN) ? 1 : 0;
  return 1;
}

/**
 * Wait indefinitely for the next available event.
 * Returns 1 on success or 0 if there was an error 
 * while waiting for events.
 */
int SDL_WaitEvent(SDL_Event *event) {
  while (!SDL_PollEvent(event));
  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  TODO("SDL_PeepEvents");
  return 0;
}

/**
 * Get a snapshot of the current state of the keyboard.
 * Returns a pointer to an array of key states.
 * A array element with a value of 1 means that the key 
 * is pressed and a value of 0 means that it is not. 
 */
uint8_t* SDL_GetKeyState(int *numkeys) {
  return keystate;
}
