#include <common.h>
#include <isa.h>
#include <sim.h>
#include <cpu.h>
#include <difftest.h>
#include <device.h>

CPU_state cpu = {};

void trace_and_difftest(vaddr_t pc, vaddr_t dnpc) {
    extern int last_commit;
    if (last_commit) difftest_step(pc, dnpc);
}

void exec_once() {
    extern int curr_pc;
    void single_cycle();

    single_cycle();
    IFDEF(CONFIG_DIFFTEST, trace_and_difftest(curr_pc, cpu.pc));
    IFDEF(CONFIG_DEVICE, device_update());
}

static void execute(uint64_t n) {
    for (;n > 0; n --) {
        exec_once();
        if (npc_state.state != NPC_RUNNING) break;
    }
}

void cpu_exec(uint64_t n) {
    switch (npc_state.state) {
        case NPC_END: case NPC_ABORT:
        printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
        return;
        default: npc_state.state = NPC_RUNNING;
    }

    execute(n);

    switch (npc_state.state) {
        case NPC_RUNNING: npc_state.state = NPC_STOP; break;

        case NPC_END: case NPC_ABORT:
        Log("npc: %s at pc = " FMT_WORD,
            (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
            (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
                ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
            npc_state.halt_pc);
        // fall through
        case NPC_QUIT: return;
    }
}
