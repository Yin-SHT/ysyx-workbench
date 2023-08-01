#include <isa.h>
#include <paddr.h>
#include <utils.h>
#include <getopt.h>

void init_rand();
void init_log(const char *log_file);
void init_rlog(const char *rlog_file);
void init_mlog(const char *mlog_file);
void init_flog(const char *flog_file);
void init_elf_sym(const char *elf_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_disasm(const char *triple);
void init_verilator(int argc, char **argv);

static void welcome() {
  BLUE_PRINT("Build time: %s, %s\n", __TIME__, __DATE__);
  GREEN_PRINT("Welcome to RISCV32-NPC!\n");
  GREEN_PRINT("For help, type \"help\"\n");
}

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *rlog_file = NULL;
static char *mlog_file = NULL;
static char *flog_file = NULL;
static char *elf_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;

static long load_img() {
  if (img_file == NULL) {
    BLUE_PRINT("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if (!fp) {
    Assert("Can not open '%s'\n", img_file);
  }

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  BLUE_PRINT("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"rlog"     , required_argument, NULL, 'r'},
    {"mlog"     , required_argument, NULL, 'm'},
    {"flog"     , required_argument, NULL, 'f'},
    {"elf"      , required_argument, NULL, 'e'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:r:m:f:e:d:p:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'r': rlog_file = optarg; break;
      case 'm': mlog_file = optarg; break;
      case 'f': flog_file = optarg; break;
      case 'e': elf_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-r,--rlog=FILE          output iringbuf log to FILE\n");
        printf("\t-m,--mlog=FILE          output mtrace log to FILE\n");
        printf("\t-f,--flog=FILE          output ftrace log to FILE\n");
        printf("\t-e,--elf=FILE           read elf FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
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

  /* Open the flog file */
  init_flog(flog_file);

  /* Read elf file. */
  init_elf_sym(elf_file);

  /* Initialize memory. */
  init_mem();

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
