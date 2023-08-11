#include <am.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

void __am_audio_init() {
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
  cfg->present = cfg->bufsize ? true : false;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR, ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
  outl(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  int total = inl(AUDIO_SBUF_SIZE_ADDR) / 2;
  int req_singals = ((uint8_t*)(ctl->buf.end) - (uint8_t*)(ctl->buf.start)) / 2;
  int16_t *src = (int16_t*)(uintptr_t)(ctl->buf.start);
  while (1) {
    int count = inl(AUDIO_COUNT_ADDR);
    int free_signals = total - count;
    if (free_signals >= req_singals) {
      for (int i = 0; i < req_singals; i++) {
        outw(AUDIO_INIT_ADDR, src[i]);
      }
      break;
    }
  }
}
