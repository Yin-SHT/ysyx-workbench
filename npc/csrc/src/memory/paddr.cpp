#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <common.h>
#include <utils.h>

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

static word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    case 8: return *(uint64_t *)addr;
    default: assert(0);
  }
}

static inline void host_write(void *addr, int len, word_t data) {
  switch (len) {
    case 1: *(uint8_t  *)addr = data; return;
    case 2: *(uint16_t *)addr = data; return;
    case 4: *(uint32_t *)addr = data; return;
    case 8: *(uint64_t *)addr = data; return;
    default: assert(0);
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
    Assert("%x is out of bound ( READ )\n", addr);
  }
  addr = addr & (~(0x3u));
  word_t ret = host_read(guest_to_host(addr), 4);
  return ret;
}

extern "C" int data_npc_pmem_read(int addr) {
  if (!in_pmem(addr)) {
    Assert("%x is out of bound ( READ )\n", addr);
  }
  addr = addr & (~(0x3u));
  word_t ret = host_read(guest_to_host(addr), 4);
  return ret;
}

extern "C" void npc_pmem_write(int addr, int wdata, char wmask) {
  if (!in_pmem(addr)) {
    Assert("%x is out of bound ( WRITE )\n", addr);
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
  } else if ( wmask = 0b00000100 ) {
    // 8'b0000_0100
    addr = addr + 2;
    len = 1;
  } else if ( wmask = 0b00001100 ) {
    // 8'b0000_1100
    addr = addr + 2;
    len = 2;
  } else if ( wmask = 0b00001000 ) {
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
  Assert("%x is out of bound\n", addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (in_pmem(addr)) { pmem_write(addr, len, data); return; }
  Assert("%x is out of bound\n", addr);
}

void init_mem() {
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
  Log("physical memory area [%x , %x]\n", CONFIG_MBASE, CONFIG_MBASE + CONFIG_MSIZE);
}



