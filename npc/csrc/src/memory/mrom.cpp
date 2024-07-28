#include <paddr.h>

uint8_t mrom[CONFIG_MROMSIZE] PG_ALIGN = {};

uint8_t* mrom_to_host(paddr_t paddr) { return mrom + paddr - CONFIG_MROMBASE; }
paddr_t host_to_mrom(uint8_t *haddr) { return haddr - mrom + CONFIG_MROMBASE; }

extern "C" void mrom_read(uint32_t addr, uint32_t *rdata) { 
    if (addr < CONFIG_MROMBASE || addr >= CONFIG_MROMBASE + CONFIG_MROMSIZE)
        panic("0x%08x is out of mrom", addr);

    uint32_t *MROM = (uint32_t *)mrom;
    uint32_t offset = (addr - CONFIG_MROMBASE) >> 2;
    *rdata = MROM[offset];
}
