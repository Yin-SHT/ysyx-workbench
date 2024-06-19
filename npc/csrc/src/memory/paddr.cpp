#include <common.h>
#include <device.h>
#include <paddr.h>
#include <map.h>
#include <utils.h>

#define BIT(x, idx) ((x >> idx) & 1)
#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo) (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static void pmem_read(uint32_t araddr, uint32_t *rdata_high, uint32_t *rdata_low) {
    uint64_t *PMEM = (uint64_t *)pmem;
    uint64_t offset = (araddr - 0x80000000) >> 3;
    uint64_t content = PMEM[offset];

    *rdata_high = (uint32_t)(content >> 32);
    *rdata_low  = (uint32_t)(content);
}

static void pmem_write(uint32_t awaddr, uint32_t wdata_high, uint32_t wdata_low, uint32_t wstrb) {
  uint64_t *PMEM = (uint64_t *)pmem;
  uint64_t offset = (awaddr - 0x80000000) >> 3;
  uint64_t wdata = (((uint64_t)wdata_high) << 32) | ((uint64_t)wdata_low);
  uint8_t *cont_p = (uint8_t *)(&PMEM[offset]);

  if (BIT(wstrb, 0)) cont_p[0] = BITS(wdata, 7,  0 );
  if (BIT(wstrb, 1)) cont_p[1] = BITS(wdata, 15, 8 );
  if (BIT(wstrb, 2)) cont_p[2] = BITS(wdata, 23, 16);
  if (BIT(wstrb, 3)) cont_p[3] = BITS(wdata, 31, 24);
  if (BIT(wstrb, 4)) cont_p[4] = BITS(wdata, 39, 32);
  if (BIT(wstrb, 5)) cont_p[5] = BITS(wdata, 47, 40);
  if (BIT(wstrb, 6)) cont_p[6] = BITS(wdata, 55, 48);
  if (BIT(wstrb, 7)) cont_p[7] = BITS(wdata, 63, 56);
}

extern "C" void axi4_read(uint32_t araddr, uint32_t *rdata_high, uint32_t *rdata_low, uint32_t arsize) {
    if (likely(in_pmem(araddr))) {
        pmem_read(araddr, rdata_high, rdata_low);
        return;
    }

    int len =   (arsize == 0) ? 1 :
                (arsize == 1) ? 2 :
                (arsize == 2) ? 4 : 
                (arsize == 3) ? 8 : 1024;
    word_t data = mmio_read(araddr, len);
    if ((araddr % 8) == 0) {
        *rdata_high = 0;
        *rdata_low = data;
    } else if ((araddr % 8) == 4) {
        *rdata_high = data;
        *rdata_low = 0;
    } else {
        panic("axi4_read: unsupported offset %d\n", araddr % 8);
    }
}

extern "C" void axi4_write(uint32_t awaddr, uint32_t wdata_high, uint32_t wdata_low, uint32_t awsize, uint32_t wstrb) {
    if (likely(in_pmem(awaddr))) {
        pmem_write(awaddr, wdata_high, wdata_low, wstrb);
        return;
    }
    
    uint64_t wdata = (((uint64_t)wdata_high) << 32) | ((uint64_t)wdata_low);
    int len =   (awsize == 0) ? 1 :
                (awsize == 1) ? 2 :
                (awsize == 2) ? 4 : 
                (awsize == 3) ? 8 : 1024;
    int cnt = 0, bit = wstrb & 0x1;
    while (!bit) {
        cnt ++;
        wstrb >>= 1;
        bit = wstrb & 0x1;
    }
    for (int i = 0; i < cnt; i ++) {
        wdata >>= 8;
    }
    word_t data = (word_t)wdata;
    mmio_write(awaddr, len, data);
}

void init_mem() {
    uint32_t *p = (uint32_t *)pmem;
    int i;
    for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
        p[i] = rand();
    }
    Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}
