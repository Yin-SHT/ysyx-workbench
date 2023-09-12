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

extern uint8_t ramdisk_start;
extern uint8_t ramdisk_end;

size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);

static uintptr_t loader(PCB *pcb, const char *filename) {
  // 0. Find file 
  int fd = fs_open(filename, 0, 0);
  assert(fd >= 0);

  // 1. Read ELF header
  Elf_Ehdr *ehdr = malloc(sizeof(Elf_Ehdr));
  fs_lseek(fd, 0, SEEK_SET);
  fs_read(fd, ehdr, sizeof(Elf_Ehdr));

  // Check elf format and ARCH
  assert(*(uint32_t *)ehdr->e_ident == 0x464c457f);
#if defined(__ISA_AM_NATIVE__)
  assert(ehdr->e_machine == EM_X86_64);
#elif defined(__riscv)
  assert(ehdr->e_machine == EM_RISCV);
#endif

  // 2. Read Program header
  Elf_Phdr *phdr = malloc(ehdr->e_phnum * ehdr->e_phentsize);
  fs_lseek(fd, ehdr->e_phoff, SEEK_SET);
  fs_read(fd, phdr, ehdr->e_phnum * ehdr->e_phentsize);

  // 3. Go through phdrs
  for (int i = 0; i < ehdr->e_phnum; i++) {
    if (phdr[i].p_type == PT_LOAD) {
      fs_lseek(fd, phdr[i].p_offset, SEEK_SET);
      fs_read(fd, (void*)(uintptr_t)(phdr[i].p_vaddr), phdr[i].p_filesz);
      memset((void*)(uintptr_t)(phdr[i].p_vaddr + phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);    
    }
  }
  return ehdr->e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p, %s", entry, filename);
  ((void(*)())entry) ();
}

