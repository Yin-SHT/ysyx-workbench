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

#define PPN(pte) (((uint32_t)pte) >> 10)
#define VPN_1(va) (((uint32_t)va) >> 22)
#define VPN_2(va) ((((uint32_t)va) << 10) >> 22)

paddr_t addr_translate(vaddr_t vaddr) {
  /* 1. Access first level page table */
  uint32_t pt1_base = (uint32_t)(cpu.satp << 12);
  uint32_t pte_1 = paddr_read(pt1_base + VPN_1(vaddr) * 4, 4);
  assert(pte_1 & 0x1);

  /* 2. Access second level page table */
  uint32_t pt2_base = (uint32_t)(PPN(pte_1) << 12);
  uint32_t pte_2 = paddr_read(pt2_base + VPN_2(vaddr) * 4, 4);

  /* 3. Get mapped physical address */
  paddr_t paddr = (PPN(pte_2) << 12) | (vaddr & 0xfff);
  assert(paddr == vaddr);
  return paddr;
}

paddr_t isa_mmu_translate(vaddr_t vaddr, int len, int type) {
  if (isa_mmu_check(vaddr, len, type) == MMU_DIRECT) return (paddr_t)vaddr;
  if (isa_mmu_check(vaddr, len, type) == MMU_TRANSLATE) return addr_translate(vaddr);
  panic("Unexpected page fault!");
}
