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

#ifdef __LP64__
# define Elf_Addr Elf64_Addr
#else
# define Elf_Addr Elf32_Addr
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

static size_t read_length(Elf_Addr vaddr, Elf_Addr end) {
  size_t len = 0;
  if ((vaddr & 0xfff) == 0) {
    /* Aligin 0x1000 */
    if (vaddr + PGSIZE <= end) len = PGSIZE;
    else if (vaddr + PGSIZE > end) len = end - vaddr;
  } else if ((vaddr & 0xfff) != 0) {
    if (vaddr + PGSIZE <= end) len = ((vaddr + PGSIZE) & (~(0xfff))) - vaddr;
    else if (vaddr + PGSIZE > end) {
      if (end >= ((vaddr + PGSIZE) & (~(0xfff)))) {
        len = ((vaddr + PGSIZE) & (~(0xfff))) - vaddr;
      } else if (end < ((vaddr + PGSIZE) & (~(0xfff)))) {
        len = end - vaddr;
      }
    }
  }
  return len;
}

uintptr_t loader(PCB *pcb, const char *filename) {
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
      Elf_Addr vaddr = phdr[i].p_vaddr;
      Elf_Addr fend = phdr[i].p_vaddr + phdr[i].p_filesz;
      Elf_Addr mend = phdr[i].p_vaddr + phdr[i].p_memsz;
      while (vaddr < fend) {
        void *pa = pg_alloc(PGSIZE);
        map(&(pcb->as), (void*)(vaddr & (~(0xfff))), pa, 0xE);

        size_t len = read_length(vaddr, fend);
        assert(len >= 0);
          
        fs_lseek(fd, phdr[i].p_offset + (vaddr - phdr[i].p_vaddr), SEEK_SET);
        fs_read(fd, (void*)(vaddr), len);
        vaddr += len;
      }

      while (vaddr < mend) {
        void *pa = pg_alloc(PGSIZE);
        map(&(pcb->as), (void*)(vaddr & (~(0xfff))), pa, 0xE);

        size_t len = read_length(vaddr, mend);
        assert(len >= 0);

        memset((void *)vaddr, 0, len);
        vaddr += len;
      }
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

