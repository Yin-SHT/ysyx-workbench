#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

int SDL_PushEvent(SDL_Event *ev) {
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  char buf[64];
  if (!NDL_PollEvent(buf, sizeof(buf))) {
    return 0;
  }
  char kmotion[32];
  char key[32];
  sscanf(buf, " %s %s ", kmotion, key);
  if (!strcmp(kmotion, "kd")) {
    ev->key.type =  SDL_KEYDOWN;
  } else if (!strcmp(kmotion, "ku")) {
    ev->key.type =  SDL_KEYUP;
  } else {
    // TODO
  }
  uint8_t sym = 0;
  for (; sym < 64; sym++) {
    if (!strcmp(keyname[sym], key)) {
      break;
    }
  }
  ev->key.keysym.sym = sym;
  return 1;
}

int SDL_WaitEvent(SDL_Event *event) {
  char buf[64];
  while (1) {
    if (NDL_PollEvent(buf, sizeof(buf))) {
      char kmotion[32];
      char key[32];
      sscanf(buf, " %s %s ", kmotion, key);
      if (!strcmp(kmotion, "kd")) {
        event->key.type =  SDL_KEYDOWN;
      } else if (!strcmp(kmotion, "ku")) {
        event->key.type =  SDL_KEYUP;
      } else {
        // TODO
      }
      uint8_t sym = 0;
      for (; sym < 64; sym++) {
        if (!strcmp(keyname[sym], key)) {
          break;
        }
      }
      event->key.keysym.sym = sym;
      return 0;
    }
  }

  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  return NULL;
}
