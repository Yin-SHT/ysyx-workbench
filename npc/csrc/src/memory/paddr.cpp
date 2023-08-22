#include <common.h>
#include <utils.h>

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

word_t host_read(void *addr, int len) {
  switch (len) {
    case 1: return *(uint8_t  *)addr;
    case 2: return *(uint16_t *)addr;
    case 4: return *(uint32_t *)addr;
    case 8: return *(uint64_t *)addr;
    default: Assert(0, "Unsupported %d in read\n", len);
  }
}

void host_write(void *addr, int len, word_t data) {
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
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]\n", PMEM_LEFT, PMEM_RIGHT);
}