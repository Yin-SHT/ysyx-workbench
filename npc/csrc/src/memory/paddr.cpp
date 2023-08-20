#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <common.h>
#include <utils.h>
#include <sys/time.h>

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }
void difftest_skip_ref();

static bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

static word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    case 8: return *(uint64_t *)addr;
    default: Assert(0, "Unsupported %d in read\n", len);
  }
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
    case 8: *(uint64_t *)addr = data; return;
    default: Assert(0, "Unsupported %d in write\n", len);
  }
}

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

extern "C" int npc_pmem_read(int addr) {
  if (!in_pmem(addr)) {
    Assert(0, "0x%08x is out of bound ( READ )\n", addr);
  }
  addr = addr & (~(0x3u));
  word_t ret = host_read(guest_to_host(addr), 4);
  return ret;
}

#define DEVICE_BASE 0xa0000000
#define RTC_ADDR    (DEVICE_BASE + 0x0000048)
static uint64_t boot_time = 0;

static uint64_t get_time_internal() {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint64_t us = now.tv_sec * 1000000 + now.tv_usec;
  return us;
}

uint64_t get_time() {
  if (boot_time == 0) boot_time = get_time_internal();
  uint64_t now = get_time_internal();
  return now - boot_time;
}

extern "C" int data_npc_pmem_read(int addr) {
  // Try Device Addr
  if (addr == RTC_ADDR) {
    difftest_skip_ref();
    uint64_t us = get_time();
    return (uint32_t)us;
  } else if (addr == RTC_ADDR + 4) {
    difftest_skip_ref();
    uint64_t us = get_time();
    return (uint32_t)(us >> 32);
  }

  if (!in_pmem(addr)) {
    Assert(0, "%x is out of bound ( READ )\n", addr);
  }
  addr = addr & (~(0x3u));
  word_t ret = host_read(guest_to_host(addr), 4);
  return ret;
}

#define DEVICE_BASE 0xa0000000
#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
extern "C" void npc_pmem_write(int addr, int wdata, char wmask) {
  // Try Device Addr
  if (addr == SERIAL_PORT) {
    difftest_skip_ref();
    char ch = wdata & 0xff;
    putchar(ch);
    return;
  }

  if (!in_pmem(addr)) {
    Assert(0, "%x is out of bound ( WRITE )\n", addr);
  }
  addr = addr & (~(0x3u));
  int len = 0;
  if ( wmask == 0b00000001 ) {
    // 8'b0000_0001
    addr = addr + 0;
    len = 1;
  } else if ( wmask == 0b00000011 ) {
    // 8'b0000_0011
    addr = addr + 0;
    len = 2;
  } else if ( wmask == 0b00001111 ) {
    // 8'b0000_1111
    addr = addr + 0;
    len = 4;
  } else if ( wmask == 0b00000010 ) {
    // 8'b0000_0010
    addr = addr + 1;
    len = 1;
  } else if ( wmask == 0b00000110 ) {
    // 8'b0000_0110
    addr = addr + 1;
    len = 2;
  } else if ( wmask == 0b00000100 ) {
    // 8'b0000_0100
    addr = addr + 2;
    len = 1;
  } else if ( wmask == 0b00001100 ) {
    // 8'b0000_1100
    addr = addr + 2;
    len = 2;
  } else if ( wmask == 0b00001000 ) {
    // 8'b0000_1000
    addr = addr + 3;
    len = 1;
  } else {
    printf("Unsipported mask\n");
    assert (0);
  }
  host_write(guest_to_host(addr), len, wdata);
}

word_t paddr_read(paddr_t addr, int len) {
  if (in_pmem(addr)) return pmem_read(addr, len);
  Assert(0, "%x is out of bound\n", addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (in_pmem(addr)) { pmem_write(addr, len, data); return; }
  Assert(0, "%x is out of bound\n", addr);
}

void init_mem() {
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
}



