/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <device/map.h>
#include <SDL2/SDL.h>

#define FREQ_OFFSET 0x00
#define CHAN_OFFSET 0x04
#define SAMP_OFFSET 0x08
#define SIZE_OFFSET 0x0c
#define INIT_OFFSET 0x10
#define COUN_OFFSET 0x14

enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t *sbuf = NULL;
static uint32_t *audio_base = NULL;
static bool is_data = false;
static int front = 0;
static int rear = 0;

static void signal_enqueue(int16_t signal) {
  int16_t *dst = (int16_t*)sbuf;
  int n = audio_base[reg_sbuf_size] / 2;
  dst[rear] = signal;
  rear = (rear + 1) % n;
  Assert(rear != front, "key queue overflow!");
}

static int16_t signal_dequeue() {
  int16_t signal = 0;
  int16_t *src = (int16_t*)sbuf;
  int n = audio_base[reg_sbuf_size] / 2;
  if (rear != front) {
    signal = src[front];
    front = (front + 1) % n;
  }
  return signal;
}

void sdl_AudioCallback(void *userdata, Uint8 *stream, int len) {
  int n = audio_base[reg_sbuf_size] / 2;
  int count = (rear - front + n) % n;
  int16_t *dst = (int16_t*)stream;
  
  int i = 0;
  len /= 2;   // Note that difference between byte and int16_t
  while (i < len && i < count) {
    dst[i] = signal_dequeue();
    i++;
  }

  while (i < len) {
    dst[i] = 0;
    i++;
  }
}

static void init_sdl_audio() {
  SDL_AudioSpec s = {};

  s.format = AUDIO_S16SYS;  // 假设系统中音频数据的格式总是使用16位有符号数来表示
  s.userdata = NULL;        // 不使用
  s.freq = audio_base[reg_freq];
  s.channels = audio_base[reg_channels];
  s.samples = audio_base[reg_samples];
  s.callback = sdl_AudioCallback;

  SDL_InitSubSystem(SDL_INIT_AUDIO);
  SDL_OpenAudio(&s, NULL);
  SDL_PauseAudio(0);
}

static void audio_io_handler(uint32_t offset, int len, bool is_write) {
  assert(len == 1 || len == 2 || len == 4);
  if (is_write) {
    // Write 
    switch (offset) {
      case FREQ_OFFSET:
      case CHAN_OFFSET:
      case SAMP_OFFSET:
        break;
      case INIT_OFFSET: 
        if (!is_data) {
          init_sdl_audio();
          is_data = true;
        } else {
          signal_enqueue(audio_base[reg_init]);
        }
        break;
      default: panic("do not support offset = %d", offset);
    }
    return;
  }
  // Read
  int n = audio_base[reg_sbuf_size] / 2;
  switch (offset) {
    case SIZE_OFFSET: audio_base[reg_sbuf_size] = CONFIG_SB_SIZE; break;
    case COUN_OFFSET: audio_base[reg_count] = (rear - front + n) % n; break;
    default: panic("do not support offset = %d", offset);
  }
}

void init_audio() {
  uint32_t space_size = sizeof(uint32_t) * nr_reg;
  audio_base = (uint32_t *)new_space(space_size);
#ifdef CONFIG_HAS_PORT_IO
  add_pio_map ("audio", CONFIG_AUDIO_CTL_PORT, audio_base, space_size, audio_io_handler);
#else
  add_mmio_map("audio", CONFIG_AUDIO_CTL_MMIO, audio_base, space_size, audio_io_handler);
#endif

  sbuf = (uint8_t *)new_space(CONFIG_SB_SIZE);
  add_mmio_map("audio-sbuf", CONFIG_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);
}
