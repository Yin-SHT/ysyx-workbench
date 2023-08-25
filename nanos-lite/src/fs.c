#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  ReadFn read;
  WriteFn write;
  size_t open_offset;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

/* This is the information about all files in disk. */
static Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write},
#include "files.h"
};

#define NR_FILE LENGTH(file_table)

int fs_open(const char *pathname, int flags, int mode) {
  for (int i = 0; i < NR_FILE; i++) {
    if (!strcmp(pathname, file_table[i].name)) {
      file_table[i].open_offset = 0;
      /* fs_write for regular write */
      if (!file_table[i].write) file_table[i].write = ramdisk_write;
      return i;
    }
  }
  // No "pathname" file 
  return -1;
}

size_t fs_read(int fd, void *buf, size_t len) {
  size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
  len = len < remain_len ? len : remain_len;

  ramdisk_read(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);
  file_table[fd].open_offset += len;

  return len;
}

size_t fs_write(int fd, const void *buf, size_t len) {
  if (fd >= 3) {
    /* Regular file */
    size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
    len = len < remain_len ? len : remain_len;
  }

  file_table[fd].write(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);
  if (fd >= 3) {
    /* Regular file */
    file_table[fd].open_offset += len;
  }

  return len;
}

size_t fs_lseek(int fd, size_t offset, int whence) {

  switch (whence) {
    case SEEK_SET: file_table[fd].open_offset = offset; break;
    case SEEK_CUR: file_table[fd].open_offset += offset; break;
    case SEEK_END: file_table[fd].open_offset = file_table[fd].size + offset; break;
    default: assert(0);
  }

  return file_table[fd].open_offset;
}

int fs_close(int fd) {
  return 0;
}

void init_fs() {
  // TODO: initialize the size of /dev/fb
}
