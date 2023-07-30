#include <stdio.h>
#include <time.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "init.h"

void init_mem() {
  srand(time(0));
  pmem = (uint32_t*)calloc(CONFIG_MSIZE / sizeof(pmem[0]), sizeof(uint32_t));
  for (int i = 0; i < (int) (CONFIG_MSIZE / sizeof(pmem[0])); i ++) {
    pmem[i] = rand();
  }
}

void init_isa() {
  /* Load built-in image. */
  memcpy(pmem, img, 20);
}

long load_img(int argc, char **argv, char *img_file) {
  img_file = NULL;
  if (argc == 2) {
    img_file = argv[1];
  }
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if (!fp) {
    printf("Can not open '%s'\n", img_file);
    assert(0);
  }

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(pmem, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}
