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
#elif defined(__ISA_X86__)
# define EXPECT_TYPE EM_X86_64
#elif defined(__ISA_MIPS32__)
# define EXPECT_TYPE EM_MIPS
#elif defined(__riscv)
# define EXPECT_TYPE EM_RISCV
#else
#error Unsupported ISA
#endif

uintptr_t loader(PCB *pcb, const char *filename) {
  // read ELF header
  int fd = fs_open(filename, 0, 0);
  assert(fd >= 0);
  Elf_Ehdr *ehdr = (Elf_Ehdr *)new_page(1);
  fs_lseek(fd, 0, SEEK_SET);
  fs_read(fd, ehdr, sizeof(Elf_Ehdr));

  // check elf format and ARCH
  assert(*(uint32_t *)ehdr->e_ident == 0x464c457f);
#if defined(__ISA_AM_NATIVE__)
  assert(ehdr->e_machine == EM_X86_64);
#elif defined(__riscv)
  assert(ehdr->e_machine == EM_RISCV);
#endif

  // read program header
  assert(ehdr->e_phnum * ehdr->e_phentsize < PGSIZE);
  Elf_Phdr *phdr = (Elf_Phdr *)new_page(1);
  fs_lseek(fd, ehdr->e_phoff, SEEK_SET);
  fs_read(fd, phdr, ehdr->e_phnum * ehdr->e_phentsize);

  // go through phdrs
  for (int i = 0; i < ehdr->e_phnum; i++) {
    if (phdr[i].p_type == PT_LOAD) {
      fs_lseek(fd, phdr[i].p_offset, SEEK_SET);

    #ifdef HAS_VME
      void *va = (void *)phdr[i].p_vaddr;
      void *va_end = (void *)phdr[i].p_vaddr +  phdr[i].p_memsz;
      for (; va < va_end; va += PGSIZE) {
        void *pa = new_page(1); // new page set page to zero
        map(&pcb->as, va, pa, PTE_W | PTE_X | PTE_R);
        fs_read(fd, pa, PGSIZE);
      }
    #else
      fs_read(fd, (void*)(uintptr_t)(phdr[i].p_vaddr), phdr[i].p_filesz);
      memset((void*)(uintptr_t)(phdr[i].p_vaddr + phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);    
    #endif
    }
  }

  fs_close(fd);

  return ehdr->e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p, %s", entry, filename);
  ((void(*)())entry) ();
}

