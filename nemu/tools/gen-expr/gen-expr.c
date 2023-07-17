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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";

int wr_ptr = 0;

uint32_t choose(uint32_t n) {
  return rand() % n;
}

void gen_num() {
  uint32_t num = choose(1000);
  int n = sprintf(buf + wr_ptr, "(unsigned)%u", num);
  wr_ptr += n;
}

void gen(char ch) {
  int n = sprintf(buf + wr_ptr, "%c", ch);
  wr_ptr += n;
}

void gen_rand_op() {
  char op;
  switch (choose(4)) {
    case 0: op = '/'; break;
    case 1: op = '*'; break;
    case 2: op = '+'; break;
    default: op = '-'; break;
  }
  int n = sprintf(buf + wr_ptr, "%c", op);
  wr_ptr += n;
}

static void gen_rand_expr() {
  int n = choose(3);
  if (wr_ptr > 100) n = 0;
  switch (n) {
    case 0: gen_num(); break;
    case 1: gen('('); gen_rand_expr(); gen(')'); break;
    default: gen_rand_expr(); gen_rand_op(); gen_rand_expr(); break;
  } 
}

void reset_buf() {
  for (int i = 0; i < 65536; i++) {
    buf[i] = '\0';
  }
  wr_ptr = 0; 
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    reset_buf();
    gen_rand_expr();

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);
    
    /* -Wall enable all warning to error, which makes ret
     *  not to zero when overflow and divbyzero happen.
     */
    int ret = system("gcc /tmp/.code.c -Werror -o /tmp/.expr");
    if (ret != 0) {
      fprintf(stderr,"Error happens, TRY AGAIN \n");
      i --; // try again
      continue;
    }

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
