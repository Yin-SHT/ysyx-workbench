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

#include <isa.h>
#include <memory/vaddr.h>
#include <memory/paddr.h>

#define PTE_V 0x01
#define PTE_R 0x02
#define PTE_W 0x04
#define PTE_X 0x08
#define PTE_U 0x10
#define PTE_A 0x40
#define PTE_D 0x80

#define VPN_1(va) (((uint32_t)va) >> 22)
#define VPN_2(va) ((((uint32_t)va) << 10) >> 22)

paddr_t addr_translate(vaddr_t vaddr) {
  uint32_t pgtbl = (uint32_t)((cpu.satp & 0x3fffff) << 12);
  uint32_t pte_1 = paddr_read(pgtbl + VPN_1(vaddr) * 4, 4);
  assert(pte_1 & PTE_V);

  uint32_t leaf = (uint32_t)((pte_1 >> 10) << 12);
  uint32_t pte_2 = paddr_read(leaf + VPN_2(vaddr) * 4, 4);
  assert(pte_2 & PTE_V);

  paddr_t paddr = ((pte_2 >> 10) << 12) | (vaddr & 0xfff);
  assert(vaddr == paddr);
  return paddr;
}

paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
  switch (isa_mmu_check(vaddr, len, type)) {
    case MMU_DIRECT: return (paddr_t)vaddr;
    case MMU_TRANSLATE: return addr_translate(vaddr);
    case MMU_FAIL: panic("mmu translate failed!");
  }
  panic("Unexpected page fault!");
}
