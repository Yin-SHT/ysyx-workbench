#include <paddr.h>

uint8_t flash[CONFIG_FLASHSIZE] PG_ALIGN = {};

uint8_t* flash_to_host(paddr_t paddr) { return flash + paddr - CONFIG_FLASHBASE; }
paddr_t host_to_flash(uint8_t *haddr) { return haddr - flash + CONFIG_FLASHBASE; }

// YSYXSOC
// .addr({8'b0, in_paddr[23:2], 2'b0})
extern "C" void flash_read(uint32_t addr, uint32_t *data) { 
    if (addr >= CONFIG_FLASHSIZE)
        panic("0x%08x is out of flash", addr);

    uint32_t *FLASH = (uint32_t *)flash;
    uint32_t offset = addr >> 2;
    *data = FLASH[offset];
}
