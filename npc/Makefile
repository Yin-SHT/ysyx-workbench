IMG =
TOP_NAME = Vtop
ARGS = -b \
			 --log=$(NPC_HOME)/output/log.txt \
			 --diff=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so

CSRC_DIR = csrc
VSRC_DIR = vsrc-v2
INC_DIR = $(NPC_HOME)/csrc/include
OBJ_DIR = build

INCFLAGS = $(addprefix -I, $(INC_DIR))
CFLAGS += $(INCFLAGS) $(shell llvm-config --cxxflags) 
LDFLAGS = -lreadline -lSDL2 $(shell llvm-config --libs)

CSRCS = $(shell find $(CSRC_DIR) -name "*.cpp" )
VSRCS = $(shell find $(VSRC_DIR) -name "*.v" )

VERILATOR = verilator
COMPILE_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc-v2 -Mdir $(OBJ_DIR)
SIM_FLAG = $(COMPILE_FLAG) --exe --build -j 80

all:
	@echo "Write this Makefile by your self."

compile:
	$(VERILATOR) $(COMPILE_FLAG) $(VSRCS)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$(VERILATOR) $(SIM_FLAG) \
			$(addprefix -CFLAGS , $(CFLAGS)) \
			$(addprefix -LDFLAGS , $(LDFLAGS)) \
			$(CSRCS) $(VSRCS)
	$(OBJ_DIR)/$(TOP_NAME) $(ARGS) $(IMG)

run: sim

clean:
	$(RM) $(OBJ_DIR)/*
	$(RM) output/*

include ../Makefile
