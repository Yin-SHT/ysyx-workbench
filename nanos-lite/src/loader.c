#include <proc.h>
#include <elf.h>
#include <fs.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

#if defined(__ISA_AM_NATIVE__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__riscv)
# define EXPECT_TYPE EM_RISCV
#else
#error Unsupported ISA
#endif

static uintptr_t loader(PCB *pcb, const char *filename) {
  Elf_Ehdr ehdr = {};
  int fd = fs_open(filename, 0, 0);
  assert(fd != -1);
  fs_lseek(fd, 0, SEEK_SET);
  fs_read(fd, &ehdr, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)ehdr.e_ident == 0x464c457f);
  assert(ehdr.e_machine == EXPECT_TYPE);

  Elf_Phdr phdr = {};
  for (int i = 0; i < ehdr.e_phnum; i ++) {
    fs_lseek(fd, ehdr.e_phoff + i * ehdr.e_phentsize, SEEK_SET);
    fs_read(fd, &phdr, sizeof(Elf_Phdr));
    if (phdr.p_type == PT_LOAD) {
      void *va = (void *) ROUNDDOWN(phdr.p_vaddr, PGSIZE);
      void *end = (void *) ROUNDUP(phdr.p_vaddr + phdr.p_memsz, PGSIZE);
      size_t nr_page = (end - va) / PGSIZE;
      void *old = new_page(nr_page);
      memset(old, 0, nr_page * PGSIZE);
      for (void *pa = old; va < end;) {
        map(&pcb->as, (void*) ROUNDDOWN(va, PGSIZE), (void*) ROUNDDOWN(pa, PGSIZE), 0x001 | 0x002);
        va += PGSIZE;
        pa += PGSIZE;
      }
      assert(va == end);

      fs_lseek(fd, phdr.p_offset, SEEK_SET);
      fs_read(fd, (void*)((uintptr_t)old + (phdr.p_vaddr & 0xfff)), phdr.p_filesz);
    }
  }

  return ehdr.e_entry;
}

static void args_uload(void *sp, void *area, char *const argv[], char *const envp[]) {
  int argc = 0;
  char **ARGV = (char **)(sp + sizeof(uintptr_t));
  while (argv[argc]) {
    ARGV[argc] = area;
    strcpy(area, argv[argc]);
    area = area + strlen(argv[argc]) + 1;
    argc ++;
  }
  ARGV[argc] = NULL;

  int envc = 0;
  char **ENVP = ARGV + argc + 1;
  while (envp[envc]) {
    ENVP[envc] = area;
    strcpy(area, envp[envc]);
    area = area + strlen(envp[envc]) + 1;
    envc ++;
  }
  ENVP[envc] = NULL;

  // set stack pointer (convention with navy-apps)
  *((uintptr_t *)sp) = argc; 
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

void context_uload(PCB *pcb, const char *filename, char *const argv[], char *const envp[]) {
  // copy kernel mappings
  protect(&pcb->as);

  // load program to mem
  void *entry =  (void*) loader(pcb, filename);
  assert(entry != NULL);

  // create initial state to execute
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = ucontext(&pcb->as, kstack, entry);
  assert(pcb->cp);

  // initialize stack
  void *pa = new_page(8);  // stack size: 32 KB
  void *va = pcb->as.area.end - 8 * PGSIZE;
  assert(!((uintptr_t)pa % PGSIZE));
  assert(!((uintptr_t)va % PGSIZE));
  for (int _ = 0; _ < 8; _ ++) {
    map(&pcb->as, va, pa, 0x001 | 0x002);
    va += PGSIZE;   
    pa += PGSIZE;
  }
  assert(va == pcb->as.area.end);
  pcb->cp->GPRx = (uintptr_t) va - PGSIZE;
  args_uload(pa - PGSIZE, pa - PGSIZE / 2, argv, envp);
}

void context_kload(PCB *pcb, void (*entry)(void *), void *arg) {
  Area kstack = {.start = pcb->stack, .end = pcb->stack + STACK_SIZE};
  pcb->cp = kcontext(kstack, entry, arg);
  assert(pcb->cp);
}
