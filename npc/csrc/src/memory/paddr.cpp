#include <common.h>
#include <device.h>
#include <paddr.h>
#include <map.h>
#include <utils.h>

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
uint8_t mrom[CONFIG_MROMSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

uint8_t* mrom_guest_to_host(paddr_t paddr) { return mrom + paddr - CONFIG_MROMBASE; }
paddr_t mrom_host_to_guest(uint8_t *haddr) { return haddr - mrom + CONFIG_MROMBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static word_t __mrom_read(paddr_t addr, int len) {
  word_t ret = host_read(mrom_guest_to_host(addr), len);
  return ret;
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

  p = (uint32_t *)mrom;
  for (i = 0; i < (int) (CONFIG_MROMSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
  Log("mask rom area [" FMT_PADDR ", " FMT_PADDR "]", MROM_LEFT, MROM_RIGHT);
}

extern "C" int paddr_read(int raddr, int *rresp) {
  /* Process addr  */
  raddr &= (~(0x3u));
  *rresp = 0;

  if (likely(in_pmem(raddr))) return pmem_read(raddr, 4);
  IFDEF(CONFIG_DEVICE, return mmio_read(raddr, 4));
  out_of_bound(raddr);
  return 0;
}

extern "C" void paddr_write(int waddr, int wdata, char wmask, int *bresp) {
  /* Process addr */
  *bresp = 0;
  int len = 0;
  waddr = waddr & (~(0x3u));
  switch (wmask) {
    case 0b00000001: waddr += 0; len = 1; break;
    case 0b00000011: waddr += 0; len = 2; break;
    case 0b00001111: waddr += 0; len = 4; break;
    case 0b00000010: waddr += 1; len = 1; break;
    case 0b00000110: waddr += 1; len = 2; break;
    case 0b00000100: waddr += 2; len = 1; break;
    case 0b00001100: waddr += 2; len = 2; break;
    case 0b00001000: waddr += 3; len = 1; break;
    default: panic("Unsupported mask %u\n", wmask);
  }

  if (likely(in_pmem(waddr))) { pmem_write(waddr, len, wdata); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(waddr, len, wdata); return);
  out_of_bound(waddr);
}

extern "C" void flash_read(uint32_t addr, uint32_t *data) { assert(0); }
extern "C" void mrom_read(uint32_t addr, uint32_t *data) { 
  *data = __mrom_read(addr, 4);
}
