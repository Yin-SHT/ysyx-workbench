#include <NDL.h>
#include <SDL.h>
#include <assert.h>

static int period = 0;
static uint8_t stream[1024] = {0};
static uint32_t lastest_time = 0;
void (*callback)(void *userdata, uint8_t *stream, int len) = NULL;

void CallbackHelper(void) {
  assert(period != 0);
  assert(callback != NULL);

  if (lastest_time == 0) {
    lastest_time = NDL_GetTicks();
  }

  uint32_t current_time = NDL_GetTicks();
  if ((current_time - lastest_time) >= period) {
    callback(NULL, stream, 1024);
    lastest_time = NDL_GetTicks();
  
    /* Count number of sound signal */
    int nr_read = 0;
    uint16_t *signals = stream;
    for (; nr_read < 512; nr_read++) {
      if (signals[nr_read] == 0) {
        /* Slience means that end of sound */
        break;
      }
    }

    /* Get available bytes of /dev/sb */
    int avai_bytes = NDL_QueryAudio();
    if (avai_bytes >= (nr_read * 2)) {
      NDL_PlayAudio(stream, nr_read * 2);
    }
  }
}

int SDL_OpenAudio(SDL_AudioSpec *desired, SDL_AudioSpec *obtained) {
//  NDL_OpenAudio(desired->freq, desired->channels, desired->samples);

//  /* Register callback function */
//  callback = desired->callback;

//  /* perios: x micro seconds */
//  period = desired->samples / (desired->freq / 1000);
//  printf("freq: %d samples: %d\n", desired->freq, desired->samples);
//  printf("period: %d\n", period);
  return 0;
}

void SDL_CloseAudio() {
}

void SDL_PauseAudio(int pause_on) {
//  if (pause_on == 0) {
//    for (int i = 0; i < 1024; i++) {
//      stream[i] = 0;
//    }
//  } else {
//    CallbackHelper();
//  }
}

void SDL_MixAudio(uint8_t *dst, uint8_t *src, uint32_t len, int volume) {
}

SDL_AudioSpec *SDL_LoadWAV(const char *file, SDL_AudioSpec *spec, uint8_t **audio_buf, uint32_t *audio_len) {
  return NULL;
}

void SDL_FreeWAV(uint8_t *audio_buf) {
}

void SDL_LockAudio() {
}

void SDL_UnlockAudio() {
}
