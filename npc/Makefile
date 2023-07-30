TOP_NAME = Vtop
BIN_PATH =
DEST_DIR = .
TARGET_DIR =

CSRCDIR = csrc
VSRCDIR = vsrc
OBJDIR = build

CSRCS = $(shell find $(CSRCDIR) -name "*.cpp" )
VSRCS = $(shell find $(VSRCDIR) -name "*.v" )

VERILATOR = verilator
COMPILE_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc -Mdir $(OBJDIR)
SIM_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc -Mdir $(OBJDIR) --exe --build -j 80

TRACE =
_CFALGS =
ifeq ($(TRACE),true)
SIM_FLAG += -CFLAGS -DTRACE
endif

all:
	@echo "Write this Makefile by your self."

compile:
	$(VERILATOR) $(COMPILE_FLAG) $(VSRCS)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(SIM_FLAG) $(CSRCS) $(VSRCS)
	$(OBJDIR)/$(TOP_NAME) $(BIN_PATH)

run: sim
	echo "DONE"

cleanobj:
	$(RM) $(OBJDIR)/*
	$(RM) *.vcd

include ../Makefile
