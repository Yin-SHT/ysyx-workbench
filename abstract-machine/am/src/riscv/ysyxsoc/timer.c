#include <am.h>
#include <riscv/riscv.h>

// Temp Device Addr, these will be changed in the future !!!
#define CLINT_ADDR 0x02000000

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  // Get High Bytes First !!!
  uint32_t high_bytes = inl(CLINT_ADDR + 4);
  uint32_t low_bytes = inl(CLINT_ADDR);
  uptime->us = ((uint64_t)high_bytes << 32) | ((uint64_t)low_bytes & 0x00000000FFFFFFFF);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}