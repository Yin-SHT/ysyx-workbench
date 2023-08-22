#include <common.h>
#include <utils.h>
#include <paddr.h>
#include <device.h>
#include <difftest.h>

extern "C" int npc_pmem_read(int addr) {
  /* Try Device */
  if ((addr == RTC_ADDR) || (addr == RTC_ADDR + 4)) {
    difftest_skip_ref();
    uint64_t us = get_time();
    return addr == RTC_ADDR ? (uint32_t)us : (uint32_t)(us >> 32);
  } 

  Assert((in_pmem(addr)), "0x%08x is out of bound ( READ )\n", addr);
  addr = addr & (~(0x3u));
  word_t ret = host_read(guest_to_host(addr), 4);

  return ret;
}

extern "C" void npc_pmem_write(int addr, int wdata, char wmask) {
  /* Try Device */
  if (addr == SERIAL_PORT) {
    difftest_skip_ref();
    putchar(wdata & 0xff);
    return;
  }

  Assert((in_pmem(addr)), "0x%08x is out of bound ( WRITE )\n", addr);
  int len = 0;
  addr = addr & (~(0x3u));
  switch (wmask) {
    case 0b00000001: addr += 0; len = 1; break;
    case 0b00000011: addr += 0; len = 2; break;
    case 0b00001111: addr += 0; len = 4; break;
    case 0b00000010: addr += 1; len = 1; break;
    case 0b00000110: addr += 1; len = 2; break;
    case 0b00000100: addr += 2; len = 1; break;
    case 0b00001100: addr += 2; len = 2; break;
    case 0b00001000: addr += 3; len = 1; break;
    default: printf("Unsupported mask %u\n", wmask); assert(0);
  }

  host_write(guest_to_host(addr), len, wdata);
}

