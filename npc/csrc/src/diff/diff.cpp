#include <dlfcn.h>
#include <isa.h>
#include <paddr.h>
#include <utils.h>
#include <common.h>
 
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

static bool is_skip_ref __attribute_maybe_unused__ = false;
static int skip_dut_nr_inst __attribute_maybe_unused__ = 0;

#ifdef CONFIG_DIFFTEST
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}
#else
void difftest_skip_ref() {}
#endif

#ifdef CONFIG_DIFFTEST
void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void (*)(paddr_t, void*, size_t, bool))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void (*)(void*, bool))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void (*)(uint64_t))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void (*)(uint64_t))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void(*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s\n", "ON");
  Log("The result of every instruction will be compared with %s.\n", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}
#else
void init_difftest(char *ref_so_file, long img_size, int port) { }
#endif

static void checkregs(CPU_state *ref, vaddr_t npc) {
  bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t npc);
  if (!isa_difftest_checkregs(ref, npc)) {
    void isa_diff_reg_display(CPU_state *ref_r);
    npc_state.state = NPC_ABORT;
    isa_diff_reg_display(ref);
  }
}

void difftest_step(vaddr_t npc) {
  CPU_state ref_r;

  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, npc);
}
