#include <proc.h>
#include <elf.h>
#include <fs.h>

#define ELF_MAGIC 0x464c457f

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
  ramdisk_read(&ehdr, 0, sizeof(Elf_Ehdr));
  assert(*(uint32_t *)ehdr.e_ident == ELF_MAGIC);
  assert(ehdr.e_machine == EXPECT_TYPE);

  Elf_Phdr phdr = {};
  for (int i = 0; i < ehdr.e_phnum; i ++) {
    ramdisk_read(&phdr, ehdr.e_phoff + i * ehdr.e_phentsize, sizeof(Elf_Phdr));
    if (phdr.p_type == PT_LOAD) {
      ramdisk_read((void*)phdr.p_vaddr, phdr.p_offset, phdr.p_filesz);
      memset((void*)phdr.p_vaddr + phdr.p_filesz, 0, phdr.p_memsz - phdr.p_filesz);
    }
  }

  return ehdr.e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

