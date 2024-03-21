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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

static uint8_t mrom[MROM_SIZE] PG_ALIGN = {};
static uint8_t sram[SRAM_SIZE] PG_ALIGN = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static word_t ysyxSoC_read(paddr_t addr, int len) {
  bool in_mrom =  (addr >= MROM_BASE) && (addr < MROM_BASE + MROM_SIZE);
  bool in_sram =  (addr >= SRAM_BASE) && (addr < SRAM_BASE + SRAM_SIZE);

  if (in_mrom) {
    return host_read(mrom + addr - MROM_BASE, len);
  } else if (in_sram) {
    return host_read(sram + addr - SRAM_BASE, len);
  } 

  /* Should not run in here */
  Assert(0, "0x%08x is illegal for read\n", addr);
}

static void ysyxSoC_write(paddr_t addr, int len, word_t data) {
  bool in_mrom =  (addr >= MROM_BASE) && (addr < MROM_BASE + MROM_SIZE);
  bool in_sram =  (addr >= SRAM_BASE) && (addr < SRAM_BASE + SRAM_SIZE);

  if (in_mrom) {
    host_write(mrom + addr - MROM_BASE, len, data);
  } else if (in_sram) {
    host_write(sram + addr - SRAM_BASE, len, data);
  } 
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
#ifdef CONFIG_MEM_RANDOM
  uint32_t *p = (uint32_t *)pmem;
  int i;
  for (i = 0; i < (int) (CONFIG_MSIZE / sizeof(p[0])); i ++) {
    p[i] = rand();
  }
#endif
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  IFDEF(CONFIG_MTRACE, mtrace_write("%#08x: \tAddr: %#08x\tLen: %d\t Read\n", cpu.pc, addr, len));
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
  if (likely(in_ysyxSoC(addr))) return ysyxSoC_read(addr, len);
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  IFDEF(CONFIG_MTRACE, mtrace_write("%#08x: \tAddr: %#08x\tLen: %d\t Write\n", cpu.pc, addr, len));
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
  if (likely(in_ysyxSoC(addr))) { ysyxSoC_write(addr, len, data); return; }
  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
