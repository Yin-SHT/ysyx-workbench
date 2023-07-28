#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  const char *p = s;

  while(*p) p++;

  return p - s;
}

char *strcpy(char *dst, const char *src) {
  if (dst == src) return dst;

  size_t len = strlen(src);
  if (dst < src) {
    char *dst_forward = dst;
    const char *src_forward = src;
    while (*src_forward) {
      *dst_forward = *src_forward;
      dst_forward++;
      src_forward++;
    }
    *dst_forward = 0;
  } else if (dst > src) {
    char *dst_backward = dst + len;
    const char* src_backward = src + len;
    while (src_backward >= src) {
      *dst_backward = *src_backward;
      dst_backward--;
      src_backward--;
    }
  }

  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;

  for (i = 0; i < n && src[i] != '\0'; i++)
      dst[i] = src[i];
  for ( ; i < n; i++)
      dst[i] = '\0';

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
    if (*p1 != *p2) return *p1 > *p2 ? 1 : -1;
    p1++;
    p2++;
  }

  if (*p1 == 0 && *p2 == 0) return 0;
  else if (*p1 != 0 && *p2 == 0) return 1;
  else if (*p1 == 0 && *p2 != 0) return -1;

  return 0;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  const char *p1 = s1;
  const char *p2 = s2;
  size_t count = 0;

  while (count < n && *p1 && *p2) {
    if (*p1 != *p2) return *p1 > *p2 ? 1 : -1;
    p1++;
    p2++;
    count++;
  }

  if (count == n) return 0;

  if (*p1 == 0 && *p2 == 0) return 0;
  else if (*p1 != 0 && *p2 == 0) return 1;
  else if (*p1 == 0 && *p2 != 0) return -1;

  return 0;
}
 
void *memset(void *s, int c, size_t n) {
  assert(s != NULL);

  uint8_t *p = (uint8_t*)s;
  uint8_t *sentry = (uint8_t*)s + n;

  while (p < sentry) {
    *p = c;
    p++;
  }
  assert(p == sentry);

  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  if (src == dst) return dst;

  if ((uint8_t*)dst < (uint8_t*)src) {
    uint8_t *dst_forward = (uint8_t*)dst;
    const uint8_t *src_forward = (uint8_t*)src;
    const uint8_t *src_sentry = src + n;
    
    while (src_forward < src_sentry) {
      *dst_forward = *src_forward;
      dst_forward++;
      src_forward++;
    }
  } else if ((uint8_t*)dst > (uint8_t*)src) {
    uint8_t *dst_backward = dst + n - 1;
    const uint8_t *src_backward = src + n - 1;
    const uint8_t *src_sentry = (uint8_t*)src;

    while (src_backward >= src_sentry) {
      *dst_backward = *src_backward;
      dst_backward--;
      src_backward--;
    }
  }

  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  if (out == in) return out;

  if ((uint8_t*)out < (uint8_t*)in) {
    uint8_t *out_forward = (uint8_t*)out;
    const uint8_t *in_sentry = (uint8_t*)in + n;
    const uint8_t *in_forward = (uint8_t*)in;

    while (in_forward < in_sentry) {
      *out_forward = *in_forward;
      out_forward++;
      in_forward++;
    }
  } else if ((uint8_t*)out > (uint8_t*)in) {
    uint8_t *out_backward = out + n - 1;
    const uint8_t *in_backward = in + n - 1;
    const uint8_t *in_sentry = (uint8_t*)in;

    while (in_backward >= in_sentry) {
      *out_backward = *in_backward;
      out_backward--;
      in_backward--;
    }
  }

  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  assert(s1 != NULL);
  assert(s2 != NULL);

  const uint8_t *s1_sentry = (uint8_t*)s1 + n;
  const uint8_t *s2_sentry = (uint8_t*)s2 + n;
  const uint8_t *s1_forward = (uint8_t*)s1;
  const uint8_t *s2_forward = (uint8_t*)s2;

  while (s1_forward < s1_sentry && s2_forward < s2_sentry) {
    if (*s1_forward != *s2_forward) {
      return *s1_forward - *s2_forward;
    }
    s1_forward++;
    s2_forward++;
  }

  return 0;
}

#endif













