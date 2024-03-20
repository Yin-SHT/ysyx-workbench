#include <common.h>
#include <device.h>
#include <paddr.h>
#include <map.h>
#include <utils.h>

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

extern "C" void flash_read(uint32_t addr, uint32_t *data) { assert(0); }
extern "C" void mrom_read(uint32_t addr, uint32_t *data) { 
  *data = pmem_read(addr, 4);
 }
