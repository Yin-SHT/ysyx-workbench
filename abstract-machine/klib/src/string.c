#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  const char *p = s;
  size_t count = 0;

  while(*p) {
    count++;
    p++;
  }

  return count;
}

char *strcpy(char *dst, const char *src) {
  char *d = dst;
  const char *s = src;

  while (*s) *d++ = *s++;
  *d = '\0';

  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  char *d;
  size_t i;

  for (i = 0; i < n && src[i] != '\0'; i++)
    d[i] = src[i];
  for ( ; i < n; i++)
    d[i] = '\0';

  return dst;
}

char *strcat(char *dst, const char *src) {
  char *d = dst;
  
  while (*d) d++;
  strcpy(d, src);

  return dst;
}

int strcmp(const char *s1, const char *s2) {
  const char *p1 = s1;
  const char *p2 = s2;

  while (*p1 && *p2) {
    if (*p1 != *p2) return *p1 - *p2;
    p1++;
    p2++;
  }

  if (*p1 == 0 && *p2 == 0) return 0;
  else if (*p1 != 0 && *p2 == 0) return 1;
  else return -1;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
  uint8_t *p = s;
  size_t count = 0;
  
  while (count < n) {
    *p = c;
    count++;
    p++;
  }

  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const uint8_t *p1 = s1;
  const uint8_t *p2 = s2;
  int count = 0;

  while (count < n) {
    if (*p1 != *p2) {
      return *p1 - *p2;
    }
    count++;
    p1++;
    p2++;
  }

  return 0;
}

#endif
