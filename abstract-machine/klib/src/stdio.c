#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

static char digits[] = "0123456789ABCDEF";

static void putc(char c) {
  putch(c);
}

static void printint(int xx, int base, int sgn) {
  char buf[16];
  int i, neg;
  unsigned long x;

  neg = 0;
  if(sgn && xx < 0){
    neg = 1;
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
  do{
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
    putc(buf[i]);
}

static void
printptr(uintptr_t x) {
  int i;
  putc('0');
  putc('x');
  for (i = 0; i < (sizeof(uintptr_t) * 2); i++, x <<= 4)
    putc(digits[x >> (sizeof(uintptr_t) * 8 - 4)]);
}

void vprintf(const char *fmt, va_list ap) {
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++) {
    c = fmt[i] & 0xff;
    if (state == 0) {
      if (c == '%') { 
        state = '%';
      } else {
        putc(c);
      }
    } else if(state == '%'){
      if(c == 'd'){
        printint(va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
        printint(va_arg(ap, uintptr_t), 10, 0);
      } else if(c == 'x') {
        printint(va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
        printptr(va_arg(ap, uintptr_t));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
          putc(*s);
          s++;
        }
      } else if(c == 'c'){
        putc(va_arg(ap, int));
      } else if(c == '%'){
        putc(c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc('%');
        putc(c);
      }
      state = 0;
    }
  }
}

int printf(const char *fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  vprintf(fmt, ap);
  
  return 0;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

static char* itoa(int num,char *str) {
  int i = 0;
  if(num < 0) {
      num = -num;
      str[i++] = '-';
  } 
  
  do {
      str[i++] = num % 10 + 48;
      num /= 10;
  } while(num);
  
  str[i] = '\0';
  int k = i;
  
  int j = 0;
  if(str[0] == '-') {
      j = 1;
      ++i;
  }
  for(; j < i / 2; j++) {
      str[j] = str[j] + str[i-1-j];
      str[i-1-j] = str[j] - str[i-1-j];
      str[j] = str[j] - str[i-1-j];
  } 
  
  return str + k;
}

int sprintf(char *out, const char *fmt, ...) {
  char str[1024] = { 0 };
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
