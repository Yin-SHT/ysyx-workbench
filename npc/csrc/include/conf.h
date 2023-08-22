#ifndef __CONF_H__
#define __CONF_H__

#define CONFIG_PC_RESET_OFFSET 0x0
#define CONFIG_MSIZE 0x8000000
#define CONFIG_MBASE 0x80000000
#define CONFIG_ISA "riscv32"

#define PMEM_LEFT  ((paddr_t)CONFIG_MBASE)
#define PMEM_RIGHT ((paddr_t)CONFIG_MBASE + CONFIG_MSIZE - 1)

#define __GUEST_ISA__ riscv32

#endif