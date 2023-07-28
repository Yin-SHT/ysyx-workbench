#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char* itoa(int num,char *str) {
    int i = 0;
    if(num<0) {
        num = -num;
        str[i++] = '-';
    } 
    
    do {
        str[i++] = num % 10 + 48;
        num /= 10;
    } while(num);
    
    str[i] = '\0';
    
    int j = 0;
    if(str[0] == '-') {
        j = 1;
        ++i;
    }
    for(;j<i/2;j++) {
        str[j] = str[j] + str[i-1-j];
        str[i-1-j] = str[j] - str[i-1-j];
        str[j] = str[j] - str[i-1-j];
    } 
    
    return str + i;
}

int printf(const char *fmt, ...) {
  char str[512] = { 0 };
  const char *fp = fmt;
  char *p = str;

  va_list ap;
  int d;
  char *s;

  va_start(ap, fmt);
  while (*fp) {
    if (*fp == '%') {
      char next_ch = *(fp + 1);
      switch (next_ch) {
        case 's': 
          s = va_arg(ap, char *);
          int n = strlen(s);
          strcpy(p, s);
          p += n;
          break;
        case 'd':
          d = va_arg(ap, int);
          p = itoa(d, p);
          break;
        default : printf("Unsupport %% %c", next_ch); assert(0); break;
      }
      fp += 2;
    } else {
      *p++ = *fp++;
    }
  }
  va_end(ap);
  putstr(str);

  return p - str;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}


int sprintf(char *out, const char *fmt, ...) {
  char str[512] = { 0 };
  const char *fp = fmt;
  char *p = str;

  va_list ap;
  int d;
  char *s;

  va_start(ap, fmt);
  while (*fp) {
    if (*fp == '%') {
      char next_ch = *(fp + 1);
      switch (next_ch) {
        case 's': 
          s = va_arg(ap, char *);
          int n = strlen(s);
          strcpy(p, s);
          p += n;
          break;
        case 'd':
          d = va_arg(ap, int);
          p = itoa(d, p);
          break;
        default : printf("Unsupport %% %c", next_ch); assert(0); break;
      }
      fp += 2;
    } else {
      *p++ = *fp++;
    }
  }
  va_end(ap);
  strcpy(out, str);

  return p - str;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
