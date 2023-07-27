TOP_NAME = Vtop
UTILS_DIR = utils
DEST_DIR = .
TARGET_DIR =

CSRCDIR = csrc
VSRCDIR = vsrc
OBJDIR = obj_dir

CSRCS = $(shell find $(CSRCDIR) -name "*.cpp" )
VSRCS = $(shell find $(VSRCDIR) -name "*.v" )

VERILATOR = verilator
COMPILE_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc
SIM_FLAG = --cc --trace --top-module top --Wall --timing -Ivsrc --exe --build -j 80 

TRACE = 
_CFALGS = 
ifeq ($(TRACE),true)
SIM_FLAG += -CFLAGS -DTRACE
endif

test:
	echo $(SIM_FLAG)

all:
	@echo "Write this Makefile by your self."

compile:
	$(VERILATOR) $(COMPILE_FLAG) $(VSRCS)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(VERILATOR) $(SIM_FLAG) $(CSRCS) $(VSRCS)
	$(OBJDIR)/$(TOP_NAME)

cleanobj:
	$(RM) $(OBJDIR)/*
	$(RM) *.vcd

include ../Makefile
