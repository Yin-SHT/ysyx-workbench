#include <common.h>
#include <device.h>
#include <paddr.h>
#include <map.h>
#include <utils.h>

uint8_t flash[16 * 1024 * 1024] PG_ALIGN = {};

uint8_t* guest_to_flash(paddr_t paddr) { return flash + paddr - CONFIG_FLASH_BASE; }
paddr_t flash_to_guest(uint8_t *haddr) { return haddr - flash + CONFIG_FLASH_BASE; }

extern "C" void flash_read(uint32_t addr, uint32_t *data) { 
    assert(0);
//    uint32_t *Flash = (uint32_t *)flash;
//    uint32_t offset = addr >> 2;
//    *data = Flash[offset];
}
