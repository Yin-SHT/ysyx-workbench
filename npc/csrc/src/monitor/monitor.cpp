#include <isa.h>
#include <paddr.h>
#include <utils.h>
#include <getopt.h>
#include <common.h>

void init_rand();
void init_log(const char *log_file);
void init_flog(const char *log_file, const char *elf_file);
void init_mem();
void init_mrom();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_disasm(const char *triple);
void init_verilator(int argc, char **argv);
void init_device();

extern uint8_t *mrom;

static void welcome() {
  BLUE_BOLD_PRINT("Build time: %s, %s\n", __TIME__, __DATE__);
  printf("Welcome to RISCV32-NPC!\n");
  printf("For help, type \"help\"\n");
}

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *flog_file = NULL;
static char *elf_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *img_mrom_file = NULL;
static int difftest_port = 1234;

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(mrom, size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"flog"     , required_argument, NULL, 'f'},
    {"elf"      , required_argument, NULL, 'e'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"mrom"     , required_argument, NULL, 'm'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ((o = getopt_long(argc, argv, "-bhl:f:e:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'f': flog_file = optarg; break;
      case 'e': elf_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 'm': img_mrom_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-f,--flog=FILE          output flog to FILE\n");
        printf("\t-e,--elf=FILE           read elf FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-m,--mrom=FILE          read mrom img file\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Set random seed. */
  init_rand();

  /* Open the log file. */
  init_log(log_file);

  /* Open the flog file. */
  init_flog(flog_file, elf_file);

  /* Initialize memory. */
  init_mem();

  /* Initialize device. */
  init_device();

  /* Perform ISA dependent initialization. */
  init_isa();

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize differential testing. */
  init_difftest(diff_so_file, img_size, difftest_port);

  /* Init llvm disasm */
  init_disasm("riscv32" "-pc-linux-gnu");

  /* Init verilator to simulation */
  init_verilator(argc, argv);

  /* Display welcome message. */
  welcome();
}