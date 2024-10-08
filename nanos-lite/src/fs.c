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
  int type;
} Finfo;

enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB, FD_DEV_EVENTS, FD_PROC_DISPINFO, FD_PROC_RECT};
enum {REGULAR_FILE, DEVICE_FILE};

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
  [FD_STDIN]  = {"stdin", 0, 0, invalid_read, invalid_write, 0, DEVICE_FILE},
  [FD_STDOUT] = {"stdout", 0, 0, invalid_read, serial_write, 0, DEVICE_FILE},
  [FD_STDERR] = {"stderr", 0, 0, invalid_read, serial_write, 0, DEVICE_FILE},
  [FD_FB] = {"/dev/fb", 0, 0, invalid_read, fb_write, 0, REGULAR_FILE},
  [FD_DEV_EVENTS] = {"/dev/events", 0, 0, events_read, invalid_write, 0, DEVICE_FILE},
  [FD_PROC_DISPINFO] = {"/proc/dispinfo", 0, 0, dispinfo_read, invalid_write, 0, DEVICE_FILE},
#include "files.h"
};

#define NR_FILE LENGTH(file_table)

int fs_open(const char *pathname, int flags, int mode) {
  for (int i = 0; i < NR_FILE; i++) {
    if (!strcmp(pathname, file_table[i].name)) {
      file_table[i].open_offset = 0;
      /* Real file system for regular write */
      if (!file_table[i].read || !file_table[i].write) {
        assert(file_table[i].type == REGULAR_FILE);
        file_table[i].read = ramdisk_read;
        file_table[i].write = ramdisk_write;
      }
      return i;
    }
  }
  // No "pathname" file 
  panic("No %s\n", pathname);
}

size_t fs_read(int fd, void *buf, size_t len) {
  assert(fd >= 0 && fd < NR_FILE);

  if (file_table[fd].type == REGULAR_FILE) {
    size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
    len = len < remain_len ? len : remain_len;
  }

  size_t r_len = file_table[fd].read(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);

  if (file_table[fd].type == REGULAR_FILE) {
    file_table[fd].open_offset += r_len;
    assert(file_table[fd].open_offset <= file_table[fd].size);
  }


  return r_len;
}

size_t fs_write(int fd, const void *buf, size_t len) {
  assert(fd >= 0 && fd < NR_FILE);

  if (file_table[fd].type == REGULAR_FILE) {
    size_t remain_len = file_table[fd].size - file_table[fd].open_offset;
    len = len < remain_len ? len : remain_len;
  }

  size_t w_len = file_table[fd].write(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);

  if (file_table[fd].type == REGULAR_FILE) {
    file_table[fd].open_offset += w_len;
    assert(file_table[fd].open_offset <= file_table[fd].size);
  }

  return w_len;
}

size_t fs_lseek(int fd, size_t offset, int whence) {
  assert(fd >= 0 && fd < NR_FILE);
  assert(file_table[fd].type == REGULAR_FILE);

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
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  file_table[FD_FB].size = w * h * sizeof(uint32_t);
  Log("Initializing file system: /dev/fb has %d bytes", file_table[FD_FB].size);
}
