#include <common.h>

void init_monitor(int, char *[]);
void sdb_mainloop();
void check_return_state();
void clean_up();

int main(int argc, char **argv) {

  init_monitor(argc, argv);

  sdb_mainloop();

  check_return_state();

  clean_up();

  return 0;
}
