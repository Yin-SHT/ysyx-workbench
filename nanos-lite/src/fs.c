#include <fs.h>

typedef size_t (*ReadFn) (void *buf, size_t offset, size_t len);
typedef size_t (*WriteFn) (const void *buf, size_t offset, size_t len);

typedef struct {
  char *name;
  size_t size;
  size_t disk_offset;
  size_t open_offset;
  ReadFn read;
  WriteFn write;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB, FD_DISPINFO, FD_EVENT};

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
  [FD_STDIN]    = {"stdin",          0, 0, 0, invalid_read,  invalid_write},
  [FD_STDOUT]   = {"stdout",         0, 0, 0, invalid_read,  serial_write},
  [FD_STDERR]   = {"stderr",         0, 0, 0, invalid_read,  serial_write},
  [FD_FB]       = {"/dev/fb",        0, 0, 0, invalid_read,  fb_write},
  [FD_DISPINFO] = {"/proc/dispinfo", 0, 0, 0, dispinfo_read, invalid_write},
  [FD_EVENT]    = {"/dev/events",    0, 0, 0, events_read,   invalid_write},
#include "files.h"
};

#define NR_FILE LENGTH(file_table)

void init_fs() {
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  file_table[FD_FB].size = w * h * sizeof(uint32_t);
  Log("frame buffer size is %x", file_table[FD_FB].size);

  for (int _ = FD_EVENT + 1; _ < NR_FILE; _ ++) {
    file_table[_].open_offset = 0;
    file_table[_].read = NULL;
    file_table[_].write = NULL;
  }
}

int fs_open(const char *pathname, int flags, int mode) {
  for (int i = 0; i < NR_FILE; i ++) {
    if (!strcmp(file_table[i].name, pathname)) {
      file_table[i].open_offset = 0;  // very important !!!
      return i;
    }
  }
  return -1;
}

size_t fs_read(int fd, void *buf, size_t len) {
  assert(fd >= 0 && fd < NR_FILE);

  // calculate number of bytes to read
  if (!file_table[fd].read) {
    size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
    len = len < remain_len ? len : remain_len; 
  }

  // read len bytes from fd into buf
  ReadFn read = file_table[fd].read ? file_table[fd].read : ramdisk_read;
  size_t offset = file_table[fd].disk_offset + file_table[fd].open_offset;
  size_t r_len = read(buf, offset, len);

  // advance file's open_offset
  if (!file_table[fd].read) {
    file_table[fd].open_offset += r_len;
    assert(file_table[fd].open_offset <= file_table[fd].size);
  }

  return r_len;
}

size_t fs_write(int fd, const void *buf, size_t len) {
  assert(fd >= 0 && fd < NR_FILE);

  // calculate number of bytes to write
  if (!file_table[fd].write || fd == FD_FB) {
    size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
    len = len < remain_len ? len : remain_len; 
  }

  // write len bytes from buf into fd
  WriteFn write = file_table[fd].write ? file_table[fd].write : ramdisk_write;
  size_t offset = file_table[fd].disk_offset + file_table[fd].open_offset;
  size_t w_len = write(buf, offset, len);

  // advance file's open_offset
  if (!file_table[fd].write || fd == FD_FB) {
    file_table[fd].open_offset += w_len;
    assert(file_table[fd].open_offset <= file_table[fd].size);
  }

  return w_len;
}

size_t fs_lseek(int fd, size_t offset, int whence) {
  assert((fd == FD_FB) || (fd > FD_EVENT && fd < NR_FILE));

  switch (whence) {
    case SEEK_SET: file_table[fd].open_offset = offset; break;
    case SEEK_CUR: file_table[fd].open_offset += offset; break;
    case SEEK_END: file_table[fd].open_offset = file_table[fd].size + offset; break;
    default: assert(0);
  }
  assert(file_table[fd].open_offset <= file_table[fd].size);

  return file_table[fd].open_offset;
}

int fs_close(int fd) {
  return 0;
}