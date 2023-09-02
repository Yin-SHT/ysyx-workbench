#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <common.h>
#include <utils.h>
#include <elf.h>

FILE *log_fp = NULL;
FILE *flog_fp = NULL;
FILE *elf_fp = NULL;
FILE *mlog_fp = NULL;

#ifdef CONFIG_ITRACE
void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'\n", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout");
}
#else
void init_log(const char *log_file) { }
#endif

#ifdef CONFIG_FTRACE
void init_flog(const char *flog_file, const char *elf_file) {
  if (flog_file == NULL) return;
  
  FILE *fp = fopen(flog_file, "w");
  Assert(fp, "Can not open '%s'", flog_file);
  flog_fp = fp;
  Log("FLog is written to %s", flog_file ? flog_file : "stdout");

  void init_elf_sym(const char *elf_file);
  init_elf_sym(elf_file);
}
#else
void init_flog(const char *flog_file, const char *elf_file) { }
#endif

typedef struct syminfo {
    int idx;
    char name[128];
    Elf32_Addr st_value;
    Elf32_Word st_size;
} SymInfo;

typedef struct funinfo {
    SymInfo syminfos[128];
    int top;
} FunInfo;

FunInfo fun_record;

void init_elf_sym(const char *elf_file) {
  if (elf_file == NULL) return;
  FILE *fp = fopen(elf_file, "r");
  Assert(fp, "Can not read %s\n", elf_file);

  int UNUSED __attribute__((unused));
  // 读取程序头表，获取节头表的偏移与节头表表项的数目
  Elf32_Ehdr *ehdr = (Elf32_Ehdr*)calloc(1, sizeof(Elf32_Ehdr));
  UNUSED = fseek(fp, 0, SEEK_SET);
  UNUSED = fread(ehdr, sizeof(Elf32_Ehdr), 1, fp);
  Elf32_Off e_shoff = ehdr->e_shoff;
  Elf32_Half e_shnum = ehdr->e_shnum;

  // 重定位fp文件流内部读写指针，读取节头表
  Elf32_Shdr *shdr = (Elf32_Shdr*)calloc(e_shnum, sizeof(Elf32_Shdr));
  UNUSED = fseek(fp, e_shoff, SEEK_SET);
  UNUSED = fread(shdr, sizeof(Elf32_Shdr), e_shnum, fp);

  // 遍历节头表，获取symtab和strtab的信息
  Elf32_Half sym_sh_num = 0;
  Elf32_Off sym_sh_offset = 0;
  Elf32_Word str_sh_size = 0;
  Elf32_Off str_sh_offset = 0;
  for (Elf32_Half i = 0; i < e_shnum; i++) {
    Elf32_Shdr shdr_entry = shdr[i];
      if (shdr_entry.sh_type == SHT_SYMTAB) {
        sym_sh_num = shdr_entry.sh_size / shdr_entry.sh_entsize;
        sym_sh_offset = shdr_entry.sh_offset;
      } else if (shdr_entry.sh_type == SHT_STRTAB && i != ehdr->e_shstrndx ) {
        str_sh_offset = shdr_entry.sh_offset;
        str_sh_size = shdr_entry.sh_size;
      }
  }

  // 读取symtab
  Elf32_Sym *sym = (Elf32_Sym*)calloc(sym_sh_num, sizeof(Elf32_Sym));
  UNUSED = fseek(fp, sym_sh_offset, SEEK_SET);
  UNUSED = fread(sym, sizeof(Elf32_Sym), sym_sh_num, fp);

  // 读取strtab
  char *str = (char*)calloc(str_sh_size, sizeof(char));
  UNUSED = fseek(fp, str_sh_offset, SEEK_SET);
  UNUSED = fread(str, 1, str_sh_size, fp);

  // 遍历symtab
  fun_record.top = 0;
  for (Elf32_Half i = 0; i < sym_sh_num; i++) {
    Elf32_Sym sym_entry = sym[i];
    if (sym_entry.st_info % 16 == STT_FUNC) {
      fun_record.syminfos[fun_record.top].idx = i;
      strcpy(fun_record.syminfos[fun_record.top].name, str + sym_entry.st_name);
      fun_record.syminfos[fun_record.top].st_value = sym_entry.st_value;
      fun_record.syminfos[fun_record.top].st_size = sym_entry.st_size;
      fun_record.top++;
    }
  }
}

void func_sym_display() {
  printf("Num\tValue\t\tSize\tName\n");
  for (int i = 0; i < fun_record.top; i++) {
    int idx = fun_record.syminfos[i].idx;
    Elf32_Addr st_value = fun_record.syminfos[i].st_value;
    Elf32_Word st_size = fun_record.syminfos[i].st_size;
    printf("%d\t%08x\t%u\t%s\n", idx, st_value, st_size, fun_record.syminfos[i].name);
  }
}

static int call_count __attribute__((unused)) = -1;

#ifdef CONFIG_FTRACE
void ftrace_call(vaddr_t pc, vaddr_t dnpc) {
  for (int i = 0; i < fun_record.top; i++) {
    Elf32_Addr st_value = fun_record.syminfos[i].st_value;
    Elf32_Word st_size = fun_record.syminfos[i].st_size;
    if (dnpc >= st_value && dnpc < st_value + st_size) {
      flog_write("%#08x: ", pc);
      call_count++;
      for (int i = 0; i < call_count; i++) {
        flog_write("  ");
      }
      flog_write("call[%s@%#08x]\n", fun_record.syminfos[i].name, dnpc);
      return;
    }
  }
  printf("No call!!!\n");
  assert(0);
  return;
}
#else
void ftrace_call(vaddr_t pc, vaddr_t dnpc) { }
#endif

#ifdef CONFIG_FTRACE
void ftrace_ret(vaddr_t pc, vaddr_t dnpc) {
  for (int i = 0; i < fun_record.top; i++) {
    Elf32_Addr st_value = fun_record.syminfos[i].st_value;
    Elf32_Word st_size = fun_record.syminfos[i].st_size;
    if (pc >= st_value && pc < st_value + st_size) {
      flog_write("%#08x: ", pc);
      for (int i = 0; i < call_count; i++) {
        flog_write("  ");
      }
      flog_write("ret[%s@%#08x]\n", fun_record.syminfos[i].name, dnpc);
      call_count--;
      return;
    }
  }
  printf("No ret!!!\n");
  assert(0);
  return;
}
#else
void ftrace_ret(vaddr_t pc, vaddr_t dnpc) { }
#endif