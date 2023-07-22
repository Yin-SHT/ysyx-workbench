#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

static char* Int2String(int num,char *str) {
    int i = 0;//指示填充str
    if(num<0)//如果num为负数，将num变正 
    {
        num = -num;
        str[i++] = '-';
    } 
    //转换 
    do
    {
        str[i++] = num%10+48;//取num最低位 字符0~9的ASCII码是48~57；简单来说数字0+48=48，ASCII码对应字符'0' 
        num /= 10;//去掉最低位    
    }while(num);//num不为0继续循环
    
    str[i] = '\0';
    
    //确定开始调整的位置 
    int j = 0;
    if(str[0]=='-')//如果有负号，负号不用调整 
    {
        j = 1;//从第二位开始调整 
        ++i;//由于有负号，所以交换的对称轴也要后移1位 
    }
    //对称交换 
    for(;j<i/2;j++)
    {
        //对称交换两端的值 其实就是省下中间变量交换a+b的值：a=a+b;b=a-b;a=a-b; 
        str[j] = str[j] + str[i-1-j];
        str[i-1-j] = str[j] - str[i-1-j];
        str[j] = str[j] - str[i-1-j];
    } 
    
    return str + i;//返回转换后的值 
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
          p = Int2String(d, p);
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
