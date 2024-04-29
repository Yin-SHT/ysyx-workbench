/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdint.h>
#include <inttypes.h>
#include <stdbool.h>
#include <string.h>

#include <macro.h>

#include <stdlib.h>

#define CONFIG_RVE 1

#if CONFIG_MBASE + CONFIG_MSIZE > 0x100000000ul
#define PMEM64 1
#endif

typedef MUXDEF(CONFIG_ISA64, uint64_t, uint32_t) word_t;
typedef MUXDEF(CONFIG_ISA64, int64_t, int32_t)  sword_t;
#define FMT_WORD MUXDEF(CONFIG_ISA64, "0x%016" PRIx64, "0x%08" PRIx32)

typedef word_t vaddr_t;
typedef MUXDEF(PMEM64, uint64_t, uint32_t) paddr_t;
#define FMT_PADDR MUXDEF(PMEM64, "0x%016" PRIx64, "0x%08" PRIx32)
typedef uint16_t ioaddr_t;

#define __GUEST_ISA__ riscv32
#define CONFIG_PC_RESET_OFFSET 0x0
#define CONFIG_ISA "riscv32"

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Remember to change RESET_VECTOR in verilog
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Used for functional validation
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//#define CONFIG_FUNC 1

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Used for performance validation
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#define CONFIG_SOC 1
#define CONFIG_PEREVENT 1
//#define CONFIG_NVBOARD 1

/* Device Defines */
//#define CONFIG_DEVICE 1
//#define CONFIG_HAS_SERIAL 1
//#define CONFIG_HAS_TIMER 1
//#define CONFIG_HAS_VGA 1
//#define CONFIG_HAS_KEYBOARD 1

/* Trace Defines */
//#define CONFIG_WAVEFORM 1
//#define CONFIG_DIFFTEST 1

#endif
