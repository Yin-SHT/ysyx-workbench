#ifndef __DEVICE_H__
#define __DEVICE_H__

#define DEVICE_BASE 0xa0000000
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)

uint64_t get_time();

#endif