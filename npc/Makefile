TOP_NAME = Vtop
BIN_PATH =

CSRC_DIR = csrc
VSRC_DIR = vsrc
INC_DIR = $(NPC_HOME)/csrc/include
OBJ_DIR = build

INCFLAGS = $(addprefix -I, $(INC_DIR))
CFLAGS += $(INCFLAGS)
LDFLAGS = -lreadline

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
	$(OBJ_DIR)/$(TOP_NAME) $(BIN_PATH)

run: sim

cleanobj:
	$(RM) $(OBJ_DIR)/*
	$(RM) *.vcd

include ../Makefile
