#include <proc.h>
#include <elf.h>

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

extern uint8_t ramdisk_start;
extern uint8_t ramdisk_end;
size_t ramdisk_read(void *buf, size_t offset, size_t len);
size_t ramdisk_write(const void *buf, size_t offset, size_t len);

static uintptr_t loader(PCB *pcb, const char *filename) {
  // 1. Read ELF header
  Elf_Ehdr *ehdr = malloc(sizeof(Elf_Ehdr));
  ramdisk_read(ehdr, 0, sizeof(Elf_Ehdr));

  // 2. Read Program header
  Elf_Phdr *phdr = malloc(ehdr->e_phnum * ehdr->e_phentsize);
  ramdisk_read(phdr, ehdr->e_phoff, ehdr->e_phnum * ehdr->e_phentsize);

  // 3. Go through phdrs
  for (int i = 0; i < ehdr->e_phnum; i++) {
    if (phdr[i].p_type == PT_LOAD) {
      ramdisk_read((void*)(uintptr_t)(phdr[i].p_vaddr), phdr[i].p_offset, phdr[i].p_filesz);
      memset((void*)(uintptr_t)(phdr[i].p_vaddr + phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);    
    }
  }
  return ehdr->e_entry;
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", entry);
  ((void(*)())entry) ();
}

