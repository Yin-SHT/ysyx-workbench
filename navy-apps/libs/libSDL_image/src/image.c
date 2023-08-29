#define SDL_malloc  malloc
#define SDL_free    free
#define SDL_realloc realloc

#define SDL_STBIMAGE_IMPLEMENTATION
#include "SDL_stbimage.h"
#include <stdio.h>

SDL_Surface* IMG_Load_RW(SDL_RWops *src, int freesrc) {
  assert(src->type == RW_TYPE_MEM);
  assert(freesrc == 0);
  return NULL;
}

long fsize(FILE *fp){
  long n;
  fpos_t fpos; 
  fgetpos(fp, &fpos); 
  fseek(fp, 0, SEEK_END);
  n = ftell(fp);
  fsetpos(fp,&fpos); 
  return n;
}

SDL_Surface* IMG_Load(const char *filename) {
  FILE *fp = NULL;
  if((fp = fopen(filename, "rb")) == NULL){ 
    printf("Failed to open %s...", filename);
    assert(0);
  }
  long size = fsize(fp);
  char *buf = SDL_malloc(size);
  fread(buf, 1, size, fp);
  SDL_Surface *s = STBIMG_LoadFromMemory(buf, size);
//  SDL_free(buf);
  return s;
}

int IMG_isPNG(SDL_RWops *src) {
  return 0;
}

SDL_Surface* IMG_LoadJPG_RW(SDL_RWops *src) {
  return IMG_Load_RW(src, 0);
}

char *IMG_GetError() {
  return "Navy does not support IMG_GetError()";
}
