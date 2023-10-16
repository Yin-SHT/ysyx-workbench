#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

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

static char *ito_hexa(unsigned int num, char* str) {
  int i = 0;
  while (num) {
    if (num < 0) {
      str[i++] = '-';
      num = -num;
    }
    str[i] = num % 16;
    if (str[i] > 9) {
      str[i] += 55;
      i++;
    } else {
      str[i] += 48;
      i++;
    }
    num /= 16;
  }
  str[i] = '\0';
  int left = (str[0] == '-') ? 1 : 0, right = i - 1;
  while (left < right) {
    char temp = str[left];
    str[left] = str[right];
    str[right] = temp;
    left++;
    right--;
  }
  return str + i;
}
 
static void reverse_str(char *left, char *right) {
	while(left < right) {
		char tmp = *left;
		*left = *right;
		*right = tmp;
		left++;
		right--;
	}
}

// Size of str is a magic number
// It should be carefully selected

int printf(const char *fmt, ...) {
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
        case 'X':
        case 'p':
        case 'x':
          d = va_arg(ap, int);
          p = ito_hexa(d, p);
          break;
        case '0': {
          int nr_chs = *(fp + 2) - '0';
          d = va_arg(ap, int);
          char *temp_p = p;
          if (*(fp + 3) == 'd') {
            p = itoa(d, p);
          } else if ( *(fp + 3) == 'x') {
            p = ito_hexa(d, p);
          }
          int nr_num = p - temp_p;
          if (nr_num > nr_chs) {
            fp += 2;
            break;
          }
          for (int i = nr_num; i < nr_chs; i++) {
            *p++ = '0';
          }
          *p = '\0';
          reverse_str(temp_p, temp_p + nr_num - 1);
          reverse_str(temp_p, p - 1);
          fp += 2;
          break; 
        }
        default : {
          if (*(fp + 1) <= '9' && *(fp + 1) >= '0') {
            int nr_chs = *(fp + 1) - '0';
            char *temp_p = p;
            switch (*(fp + 2)) {
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
              case 'X':
              case 'x':
                d = va_arg(ap, int);
                p = ito_hexa(d, p);
                break;
              default: assert(0); break;
            }
            int nr_num = p - temp_p;
            if (nr_num > nr_chs) {
              fp += 1;
              break;
            }
            for (int i = nr_num; i < nr_chs; i++) {
              *p++ = ' ';
            }
            *p = '\0';
            reverse_str(temp_p, temp_p + nr_num - 1);
            reverse_str(temp_p, p - 1);
            fp += 1;
            break; 
          } else {
            assert(0);
          }
          break;
        }
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
  char str[4096] = { 0 };
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
  strncpy(out, str, n);
  out[n] = '\0'; // ensure that end of line

  return n;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
