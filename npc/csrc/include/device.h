#ifndef __DEVICE_H__
#define __DEVICE_H__

#include <common.h>

#define TIMER_HZ 60
#define DEVICE_BASE 0xa0000000
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)

#define CONFIG_VGA_SIZE_400x300 1
#define CONFIG_VGA_CTL_MMIO 0xa0000100
#define CONFIG_FB_ADDR 0xa1000000
#define CONFIG_SERIAL_MMIO 0xa00003f8
#define CONFIG_RTC_MMIO 0xa0000048
#define CONFIG_I8042_DATA_MMIO 0xa0000060

word_t mmio_read(paddr_t addr, int len);
void mmio_write(paddr_t addr, int len, word_t data);
void device_update();

uint64_t get_time();

#endif