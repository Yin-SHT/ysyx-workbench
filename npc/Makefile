TOP_NAME = Vtop
NPC_ARGS = --log=$(NPC_HOME)/output/log.txt --flog=$(NPC_HOME)/output/flog.txt --elf=$(NPC_HOME)/dummy.elf \
          --diff=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so
IMG_PATH = $(NPC_HOME)/dummy.bin

CSRC_DIR = csrc
VSRC_DIR = vsrc
INC_DIR = $(NPC_HOME)/csrc/include
OBJ_DIR = build

INCFLAGS = $(addprefix -I, $(INC_DIR))
CFLAGS += $(INCFLAGS) $(shell llvm-config --cxxflags)
LDFLAGS = -lreadline $(shell llvm-config --libs)


CSRCS = $(shell find $(CSRC_DIR) -name "*.cpp" )
VSRCS = $(shell find $(VSRC_DIR) -name "*.v" )

VERILATOR = verilator
COMPILE_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc -Mdir $(OBJ_DIR)
SIM_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc -Mdir $(OBJ_DIR) --exe --build -j 80

all:
	@echo "Write this Makefile by your self."

compile:
	$(VERILATOR) $(COMPILE_FLAG) $(VSRCS)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(SIM_FLAG) $(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) $(CSRCS) $(VSRCS)
	$(OBJ_DIR)/$(TOP_NAME) $(NPC_ARGS) $(NPC_HOME)/dummy.bin

run: sim

clean:
	$(RM) $(OBJ_DIR)/*
	$(RM) output/*

include ../Makefile
