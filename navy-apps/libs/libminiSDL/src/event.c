#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

#define NR_KEYS (sizeof(keyname) / sizeof(keyname[0]))
static uint8_t keystate[NR_KEYS] = {0};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

static void process_event(char *buf, SDL_Event *event) {
  SDL_Event ev;
  char kmotion[32];
  char key[32];

  /* Process keyboard event */
  sscanf(buf, " %s %s ", kmotion, key);
  if (!strcmp(kmotion, "kd")) {
    ev.key.type =  SDL_KEYDOWN;
  } else if (!strcmp(kmotion, "ku")) {
    ev.key.type =  SDL_KEYUP;
  } else {
    assert(0);
  }
  uint8_t sym = 0;
  for (; sym < NR_KEYS; sym++) {
    if (!strcmp(keyname[sym], key)) {
      break;
    }
  }
  ev.key.keysym.sym = sym;

  if (event) {
    *event = ev;
    keystate[event->key.keysym.sym] = (event->key.type == SDL_KEYDOWN) ? 1 : 0;
  }
}

int SDL_PollEvent(SDL_Event *event) {
  char buf[64];

  if (NDL_PollEvent(buf, sizeof(buf))) {
    process_event(buf, event);
    return 1;
  }

  /* no event */
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];

  /* Waits indefinitely for the next available event */
  while (1) {
    if (NDL_PollEvent(buf, sizeof(buf))) {
      process_event(buf, event);
      return 0;
    }
  }

  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return keystate;
}