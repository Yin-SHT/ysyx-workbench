/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <elf.h>
#include <cpu/decode.h>
#include <dirent.h>

extern uint64_t g_nr_guest_inst;
FILE *itrace_fp = NULL;
FILE *ltrace_fp = NULL;
FILE *mtrace_fp = NULL;
FILE *ftrace_fp = NULL;
FILE *dtrace_fp = NULL;
FILE *etrace_fp = NULL;

#ifdef CONFIG_ITRACE
void init_itrace(const char *itrace_file) {
  if (!itrace_file) {
    Log("itrace_file is NULL\n");
    return;
  }

  FILE *fp = fopen(itrace_file, "w");
  Assert(fp, "Can not open '%s'", itrace_file);
  itrace_fp = fp;
  Log("Overall instructions trace is written to %s", itrace_file);
}
#else
void init_itrace(const char *itrace_file) { }
#endif

/* Instruction RingBuf Trace */
typedef struct iringbuf {
  int top;
  char *log[16];
} IRingBuf;

static IRingBuf irbuf;

void flush_iringbuf() {
  for (int i = 0; i < 16; i++) {
    char *p __attribute_maybe_unused__ = irbuf.log[i];
    if (( i + 1 ) % 16 == irbuf.top) {
      ltrace_write(" -----> %s\n", p);
    } else {
      ltrace_write("        %s\n", p);
    }
  }
}

void update_iringbuf(Decode *s) {
  int top = irbuf.top; 
  irbuf.top = (top + 1) % 16;
  char *p = irbuf.log[top];

  p += snprintf(p, 128, FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst.val;
  for (i = ilen - 1; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

#ifdef CONFIG_LTRACE
  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, irbuf.log[top] + 128 - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst.val, ilen);
#endif
}

#ifdef CONFIG_LTRACE
static void init_iringbuf() {
  irbuf.top = 0;
  for (int i = 0; i < 16; i++) {
    irbuf.log[i] = (char*)calloc(128, sizeof(char));
  }
}

void init_ltrace(const char *ltrace_file) {
  if (ltrace_file == NULL) {
    Log("ltrace_file is NULL\n");
    return;
  }

  FILE *fp = fopen(ltrace_file, "w");
  Assert(fp, "Can not open '%s'", ltrace_file);
  ltrace_fp = fp;
  Log("Latest instructions trace is written to %s", ltrace_file);
  init_iringbuf();
}
#else
void init_ltrace(const char *rlog_file) { }
#endif

#ifdef CONFIG_MTRACE
void init_mtrace(const char *mtrace_file) {
  if (mtrace_file == NULL) {
    Log("mtrace_file is NULL\n");
    return;
  }
  
  FILE *fp = fopen(mtrace_file, "w");
  Assert(fp, "Can not open '%s'", mtrace_file);
  mtrace_fp = fp;
  Log("memory access trace is written to %s", mtrace_file);
}
#else
void init_mtrace(const char *mtrace_file) { }
#endif

#ifdef CONFIG_DTRACE
void init_dtrace(const char *dtrace_file) {
  if (dtrace_file == NULL) {
    Log("dtrace_file is NULL\n");
    return;
  }
  
  FILE *fp = fopen(dtrace_file, "w");
  Assert(fp, "Can not open '%s'", dtrace_file);
  dtrace_fp = fp;
  Log("device access trace is written to %s", dtrace_file);
}
#else
void init_dtrace(const char *dtrace_file) { }
#endif

#ifdef CONFIG_ETRACE
void init_etrace(const char *etrace_file) {
  if (etrace_file == NULL) {
    printf("etrace_file is NULL\n");
    return;
  }
  
  FILE *fp = fopen(etrace_file, "w");
  Assert(fp, "Can not open '%s'", etrace_file);
  etrace_fp = fp;
  Log("expection access trace is written to %s", etrace_file ? etrace_file : "stdout");
}
#else
void init_etrace(const char *etrace_file) { }
#endif

#ifdef CONFIG_FTRACE
typedef struct syminfo {
  int idx;
  char name[128];
  Elf32_Addr st_value;
  Elf32_Word st_size;
} SymInfo;

typedef struct funinfo {
  SymInfo syminfos[1024];
  int top;
} FunInfo;

static void init_elf_sym(const char *elf_file, FunInfo *record) {
  if (elf_file == NULL) return;

  FILE *fp = fopen(elf_file, "r");
  if (!fp) {
    RED_PRINT("Can not read %s\n", elf_file);
    assert(0);
  }

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
  record->top = 0;
  for (Elf32_Half i = 0; i < sym_sh_num; i++) {
    Elf32_Sym sym_entry = sym[i];
    if (sym_entry.st_info % 16 == STT_FUNC) {
      record->syminfos[record->top].idx = i;
      strcpy(record->syminfos[record->top].name, str + sym_entry.st_name);       
      record->syminfos[record->top].st_value = sym_entry.st_value;
      record->syminfos[record->top].st_size = sym_entry.st_size;
      if (!strcmp(record->syminfos[record->top].name, "__am_asm_trap")) {
        record->syminfos[record->top].st_size = 310;
      }
      record->top++;
      assert(record->top <= 1024);
    }
  }
}
#endif

#ifdef CONFIG_FTRACE
static struct {
  char *files[64];
  int top;
} slave_files;

static FunInfo master_record;
static FunInfo slave_record;
static struct {
  SymInfo syms[1024];
  int top;
} sym_stack;

void init_ftrace(const char *ftrace_file, const char *master_file) {
  if (ftrace_file == NULL) { panic("ftrace_file is NULL"); }
  
  FILE *fp = fopen(ftrace_file, "w");
  Assert(fp, "Can not open '%s'", ftrace_file);
  ftrace_fp = fp;
  Log("function access trace is written to %s", ftrace_file);

  /* Record master elf file function info */
  if (master_file == NULL) { panic("master_file is NULL"); }
  init_elf_sym(master_file, &master_record);
  sym_stack.top = -1;


  /* Find out all slave files */
  slave_files.top = 0;

  DIR *dr;
  struct dirent *en;
  char work_dir[128];

  strcat(strcpy(work_dir, getenv("NAVY_HOME")), "/fsimg/bin");
  dr = opendir(work_dir); //open all or present directory
  if (dr) {
    while ((en = readdir(dr)) != NULL) {
      if (strcmp(en->d_name, ".") && strcmp(en->d_name, "..")) {
        char bin[128];
        strcat(strcat(strcpy(bin, work_dir), "/"), en->d_name);
        assert(slave_files.top < 64);
        slave_files.files[slave_files.top] = calloc(128, sizeof(char));
        memcpy(slave_files.files[slave_files.top], bin, 128);
        slave_files.top ++;
      }
    }
    closedir(dr); //close all directory
  }
}
#else
void init_ftrace(const char *flog_file, const char *master_file) { }
#endif

#ifdef CONFIG_FTRACE
static int call_count __attribute_maybe_unused__ = -1;
static bool slave_find __attribute_maybe_unused__ = false;

static bool find_symbol(FunInfo *record, vaddr_t pc, vaddr_t dnpc, char *op) {
  for (int i = 0; i < record->top; i++) {
    Elf32_Addr st_value = record->syminfos[i].st_value;
    Elf32_Word st_size = record->syminfos[i].st_size;
    if (dnpc >= st_value && dnpc < st_value + st_size) {
      ftrace_write("%#08x: ", pc);
      if (!strcmp(op, "call")) {
        sym_stack.top++;
        strcpy(sym_stack.syms[sym_stack.top].name, record->syminfos[i].name);
        call_count++;
      }
      for (int i = 0; i < call_count; i++) {
        ftrace_write("  ");
      }
      if (!strcmp(op, "ret")) call_count--;

      if (!strcmp(op, "call")) {
        ftrace_write("%s[%s@%#08x]\n", op, record->syminfos[i].name, dnpc);
      } else if (!strcmp(op, "ret")) {
        assert(sym_stack.top >= 0);
        ftrace_write("%s [%s@%s %#08x]\n", op, sym_stack.syms[sym_stack.top].name, record->syminfos[i].name, dnpc);
        sym_stack.top--;
      }
      return true;
    }
  }
  return false;
}

void ftrace(vaddr_t pc, vaddr_t dnpc, char *op) {
  /* Try master elf file */
  if (find_symbol(&master_record, pc, dnpc, op)) return;

  /* Try slave elf file */
  if (slave_find == false) {
    init_elf_sym("/home/yin/Code/system/ysyx-workbench/navy-apps/fsimg/bin/nslider", &slave_record);
    if (find_symbol(&slave_record, pc, dnpc, op)) {
      slave_find = true;
      return;
    }
  } else if (slave_find == true) {
    if (find_symbol(&slave_record, pc, dnpc, op)) return;
  }
  panic("Can't find symbol, pc: %#08x dnpc: %#08x op: %s\n", pc, dnpc, op);
}

#else
void ftrace(vaddr_t pc, vaddr_t dnpc, char *op) { }
#endif


bool log_enable() {
  return MUXDEF(CONFIG_TRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
}
