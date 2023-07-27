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
  panic("Not implemented");
}
 
/*
 * DESCRIPTION:
 *       The memset() function fills the first n bytes of the memory area pointed to by s with the constant byte c.
 * RETURN VALUE:
 *       The memset() function returns a pointer to the memory area s.
*/
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

/*
 * DESCRIPTION:
 *      The  memmove()  function  copies  n  bytes from memory area src to memory area dest.  The memory areas may overlap: copying
 *      takes place as though the bytes in src are first copied into a temporary array that does not overlap src or dest,  and  the
 *      bytes are then copied from the temporary array to dest.
 * RETURN VALUE:
 *      The memmove() function returns a pointer to dest.
*/
void *memmove(void *dst, const void *src, size_t n) {
  assert(dst != NULL);
  assert(src != NULL);

  if (src == dst) return dst;

  // Backword move
  const uint8_t *src_sentry = (uint8_t*)src;
  uint8_t *dst_sentry = (uint8_t*)dst;
  const uint8_t *src_back = src + n - 1;
  uint8_t *dst_back = dst + n - 1;

  while (src_back >= src_sentry) {
    *dst_back = *src_back;
    dst_back--;
    src_back--;
  }
  assert(src_back + 1 == src_sentry);
  assert(dst_back + 1 == dst_sentry);

  return dst;
}

/*
 * DESCRIPTION
 *        The  memcpy()  function  copies  n bytes from memory area src to memory area dest.  The memory areas must not overlap.  Use
 *        memmove(3) if the memory areas do overlap.
 * RETURN VALUE
 *        The memcpy() function returns a pointer to dest.
*/

static size_t pointer_abs(const void *p1, const void *p2) {
  const uint8_t *_p1 = (uint8_t*)p1;
  const uint8_t *_p2 = (uint8_t*)p2;
  size_t diff = (_p1 > _p2) ? _p1 - _p2 : _p2 - _p1;
  return diff;
}

void *memcpy(void *out, const void *in, size_t n) {
  assert(in != NULL);
  assert(out != NULL);

  size_t diff = pointer_abs(out, in);
  assert( n >= diff );  // Ensure that not overlap

  const uint8_t *in_sentry = (uint8_t*)in + n;
  const uint8_t *in_forward = (uint8_t*)in;
  uint8_t *out_sentry = (uint8_t*)out + n;
  uint8_t *out_forward = (uint8_t*)out;

  while (in_forward < in_sentry) {
    *out_forward = *in_forward;
    out_forward++;
    in_forward++;
  }
  assert(in_forward == in_sentry);
  assert(out_forward == out_sentry);

  return out;
}

/*
 * DESCRIPTION:
 *        The memcmp() function compares the first n bytes (each interpreted as unsigned char) of the memory areas s1 and s2.
 * RETURN VALUE:
 *        The memcmp() function returns an integer less than, equal to, or greater than zero if the first n bytes of s1 is found, re‐
 *        spectively, to be less than, to match, or be greater than the first n bytes of s2.
 *        For a nonzero return value, the sign is determined by the sign of the difference between the first pair  of  bytes  (inter‐
 *        preted as unsigned char) that differ in s1 and s2.
 *        If n is zero, the return value is zero.
*/
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













