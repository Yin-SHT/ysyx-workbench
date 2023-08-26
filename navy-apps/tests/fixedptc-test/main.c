#include <stdio.h>
#include <assert.h>
#include <fixedptc.h>

int main() {
  fixedpt a = fixedpt_rconst(1.2);

  int a_floor = fixedpt_toint(fixedpt_floor(a));
  assert(a_floor == 1);

  int a_ceil = fixedpt_toint(fixedpt_ceil(a));
  assert(a_ceil == 2);

  a = fixedpt_rconst(1);

  a_floor = fixedpt_toint(fixedpt_floor(a));
  assert(a_floor == 1);

  a_ceil = fixedpt_toint(fixedpt_ceil(a));
  assert(a_ceil == 1);

  return 0;
}