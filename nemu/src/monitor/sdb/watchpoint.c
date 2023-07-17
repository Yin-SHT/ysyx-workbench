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

#include "sdb.h"

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    for (int j = 0; j < WEXPR_SIZE; j++) {
      wp_pool[i].e[j] = '\0';
    }
    wp_pool[i].val = 0;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
void reset_wp(WP *wp) {
  assert(wp != NULL);

  for (int j = 0; j < WEXPR_SIZE; j++) {
    wp->e[j] = '\0';
  }
  wp->val = 0;
}

WP* new_wp() {
  if (!free_) {
    RED_PRINT("NO WP LEFT\n");
    return NULL;
  }

  WP *wp = free_;
  free_ = free_->next;
  wp->next = head;
  head = wp;
  return wp;
}

void free_wp(WP *wp) {
  if (!wp) {
    // wp is NULL
    RED_PRINT("wp is NULL\n");
    assert(0);
  }
  reset_wp(wp); // clear e and val field

  WP* pre = NULL;
  WP* p = head;
  while (p != wp) {
    pre = p;
    p = p->next;
  }
  if (p != wp) {
    RED_PRINT("CAN'T FIND WP IN HEAD LIST\n");
    assert(0);
  }

  if (pre == NULL) {
    head = head->next;
  } else {
    pre->next = p->next;
  }
  p->next = ( free_ == NULL ) ? NULL : free_->next;
  free_ = p;

  return;
}

WP* find_wp(int no) {
  WP* p = head;
  while (p) {
    if (p->NO == no) {
      return p;
    }
    p = p->next;
  }

  return NULL;
}

bool scan_wp_pool(char *inst) {
  bool stop = false;
  WP* p = head;
  while (p) {
    bool success = true;
    uint32_t new_val = expr(p->e, &success);
    assert(success == true);
    uint32_t val = p->val;
    if (val != new_val) {
      BLUE_PRINT("Watchpoint %d: %s\n\n", p->NO, p->e);
      GREEN_PRINT("Old value = %-15u (0x%08x)\n", val, val);
      YELLOW_PRINT("New value = %-15u (0x%08x)\n\n", new_val, new_val);
      p->val = new_val;
      stop = true;
    }
    p = p->next;
  }
  if (stop) {
    CYAN_PRINT("At Inst: %s\n", inst );
  }

  return stop;
}

void wp_display() {
  BLUE_PRINT("Num\t\tWhat\n");
  WP* p = head;
  while (p) {
    GREEN_PRINT("%d\t\t", p->NO);
    YELLOW_PRINT("%s\n", p->e);
    p = p->next;
  }
  return;
}

