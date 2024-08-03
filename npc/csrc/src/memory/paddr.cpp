#include <common.h>
#include <device.h>
#include <paddr.h>
#include <map.h>
#include <utils.h>
#include <math.h>

#define BIT(x, idx) ((x >> idx) & 1)
#define BITMASK(bits) ((1ull << (bits)) - 1)
#define BITS(x, hi, lo) (((x) >> (lo)) & BITMASK((hi) - (lo) + 1)) // similar to x[hi:lo] in verilog

uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static void device_read(uint32_t araddr, uint32_t *rdata, uint32_t arsize) {
    int len = (arsize ? 2 << (arsize - 1) : 1);
    int off = araddr % 4;
    uint32_t data = mmio_read(araddr, len);

    *rdata = data << (off * 8);
}

static void pmem_read(uint32_t araddr, uint32_t *rdata) {
    uint32_t *PMEM = (uint32_t *)pmem;
    uint32_t offset = (araddr - RESET_VECTOR) >> 2;

    *rdata  = PMEM[offset];
}

static void device_write(uint32_t awaddr, uint32_t wdata, uint32_t awsize, uint32_t wstrb) {
    int len = (awsize ? 2 << (awsize - 1) : 1);
    int off = awaddr % 4;
    word_t data = wdata >> (off * 8);

    mmio_write(awaddr, len, data);
}

static void pmem_write(uint32_t awaddr, uint32_t wdata, uint32_t wstrb) {
    uint32_t *PMEM = (uint32_t *)pmem;
    uint32_t offset = (awaddr - RESET_VECTOR) >> 2;
    uint8_t *cont_p = (uint8_t *)(&PMEM[offset]);

    if (BIT(wstrb, 0)) cont_p[0] = BITS(wdata, 7,  0 );
    if (BIT(wstrb, 1)) cont_p[1] = BITS(wdata, 15, 8 );
    if (BIT(wstrb, 2)) cont_p[2] = BITS(wdata, 23, 16);
    if (BIT(wstrb, 3)) cont_p[3] = BITS(wdata, 31, 24);
}

extern "C" void axi4_read(uint32_t araddr, uint32_t *rdata, uint32_t arsize) {
    if (likely(in_pmem(araddr))) {
        pmem_read(araddr, rdata);
        return;
    }

    device_read(araddr, rdata, arsize);
}

extern "C" void axi4_write(uint32_t awaddr, uint32_t wdata, uint32_t awsize, uint32_t wstrb) {
    if (likely(in_pmem(awaddr))) {
        pmem_write(awaddr, wdata, wstrb);
        return;
    }

    device_write(awaddr, wdata, awsize, wstrb);   
}

#ifdef CONFIG_FAST_SIMULATION
void init_mem() {
    uint32_t *p = (uint32_t *)pmem;
    int i;
    for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
        p[i] = rand();
    }
    Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}
#elif CONFIG_SOC_SIMULATION
void init_mem() {
    Log("mrom  memory area [" FMT_PADDR ", " FMT_PADDR "]", MROM_LEFT, MROM_RIGHT);
    Log("sram  memory area [" FMT_PADDR ", " FMT_PADDR "]", SRAM_LEFT, SRAM_RIGHT);
    Log("flash memory area [" FMT_PADDR ", " FMT_PADDR "]", FLASH_LEFT, FLASH_RIGHT);
}
#endif
