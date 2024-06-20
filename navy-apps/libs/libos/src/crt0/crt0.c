#include <stdint.h>
#include <stdlib.h>
#include <assert.h>

int main(int argc, char *argv[], char *envp[]);
extern char **environ;
void call_main(uintptr_t *args) {
//  char *empty[] =  {NULL };
//  environ = empty;
//  exit(main(0, empty, empty));
  int argc = *args; // convention with nanos-lite
  char **argv = (char **)(args + 1); 
  char **envp = (char **)(args + 1 + argc + 1); 
  environ = envp;
  exit(main(argc, argv, envp));
  assert(0);
}
