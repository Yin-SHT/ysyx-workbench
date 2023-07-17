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

#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

word_t expr(char *e, bool *success);
void check_par_match(int p, int q, bool *success);
bool check_parentheses(int p, int q, bool *success);

// for watchpoint
#define WEXPR_SIZE 128 
#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  char e[WEXPR_SIZE];

  uint32_t val;

  /* TODO: Add more members if necessary */

} WP;

WP* new_wp();
void free_wp(WP *wp);
WP* find_wp(int no);
bool scan_wp_pool(char *inst);
void wp_display();
#endif
