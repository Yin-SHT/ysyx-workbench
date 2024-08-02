#include <isa.h>
#include <paddr.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
static const uint32_t img [] = {
#ifdef CONFIG_FUNC
    0x00000297,  // auipc t0,0
    0x00028823,  // sb  zero,16(t0)
    0x0102c503,  // lbu a0,16(t0)
    0x00100073,  // ebreak (used as nemu_trap)
    0xdeadbeef,  // some data
#else
    0x100007b7,  // lui	a5,0x10000
    0x04100713,  // li	a4,65
    0x00e78023,  // sb	a4,0(a5) # 10000000 
    0x00a00713,  // li	a4,10
    0x00e78023,  // sb	a4,0(a5)
    0x0000006f,  // j	20000014 
#endif
};

static void restart() {
    /* Set the initial program counter. */
    cpu.pc = FLASH_VECTOR;

    /* The zero register is always 0. */
    cpu.gpr[0] = 0;
}

void init_isa() {
    /* Load built-in image. */
#ifdef CONFIG_FAST_SIMULATION
    memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
#else 
//    memcpy(mrom_to_host(MROM_VECTOR), img, sizeof(img));
    memcpy(flash_to_host(FLASH_VECTOR), img, sizeof(img));
#endif

    /* Initialize this virtual computer system. */
    restart();
}
