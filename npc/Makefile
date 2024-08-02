TOPNAME = ysyxSoCFull
INC_PATH = $(NPC_HOME)/csrc/include

VERILATOR = verilator
VERILATOR_FLAGS += -MMD --build -cc -Wall --trace \
				-O3 --x-assign fast --x-initial fast --noassert  \
				--timescale "1ns/1ns" --no-timing -Wno-ASSIGNDLY --autoflush \
				-y $(SOC_HOME)/perip/uart16550/rtl -y $(SOC_HOME)/perip/spi/rtl -y $(NPC_HOME)/vsrc \
				-Wno-DECLFILENAME \
				-Wno-PINCONNECTEMPTY \
				-Wno-DEFPARAM \
				-Wno-UNUSEDSIGNAL \
				-Wno-UNUSEDPARAM \
				-Wno-UNDRIVEN \
				-Wno-SYNCASYNCNET \
				-Wno-BLKSEQ       \

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir

PERF_BIN = $(BUILD_DIR)/ysyxSoCFull_perf			# FOR PERFORMANCE SIMULATION
FUNC_BIN = $(BUILD_DIR)/ysyxSoCFull_func			# FOR FUNCTIONAL SIMULATION 

default: $(PERF_BIN)

$(shell mkdir -p $(BUILD_DIR))
$(shell mkdir -p $(BUILD_DIR)/output)

# constraint file
NXDC_FILES = constr/ysyxSoCFull.nxdc
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source for PERFORMANCE SIMULATION
PERF_VSRCS = $(SOC_HOME)/build/ysyxSoCFull.v
PERF_VSRCS += $(shell find $(SOC_HOME)/perip -name "*.v")
PERF_VSRCS += $(shell find $(NPC_HOME)/vsrc -name "*.v")

PERF_CSRCS = $(shell find $(NPC_HOME)/csrc/src -name "*.c" -or -name "*.cc" -or -name "*.cpp")
PERF_CSRCS += $(SRC_AUTO_BIND) $(NPC_HOME)/csrc/npc_main.cpp

# project source for FUNCTION SIMULATION
FUNC_VSRCS = $(NPC_HOME)/top/ysyxSoCFull.v
FUNC_VSRCS += $(shell find $(NPC_HOME)/vsrc -name "*.v")

FUNC_CSRCS = $(shell find $(NPC_HOME)/csrc/src -name "*.c" -or -name "*.cc" -or -name "*.cpp")
FUNC_CSRCS += $(NPC_HOME)/csrc/npc_main.cpp

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS = $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" \
		 $(shell llvm-config --cxxflags) 
LDFLAGS = -lreadline -lSDL2 $(shell llvm-config --libs) -lSDL2 -lSDL2_image -lSDL2_ttf

# command for PERFORMANCE BIN
$(PERF_BIN): $(PERF_VSRCS) $(PERF_CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(PERF_BIN))

# command for FUNCTION BIN
$(FUNC_BIN): $(FUNC_VSRCS) $(FUNC_CSRCS) 
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(FUNC_BIN))

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(BUILD_DIR)/$(TOPNAME) -b $(ARGS) $(IMG)

all: default

# Command to execute NPC 
IMG ?=
ARGS ?=
PERF_EXEC := $(PERF_BIN) $(ARGS) -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so $(IMG)
FUNC_EXEC := $(FUNC_BIN) $(ARGS) -d $(NEMU_HOME)/build/riscv32-nemu-interpreter-so $(IMG)

pbin: $(PERF_BIN)

fbin: $(FUNC_BIN)

prun: pbin
	$(PERF_EXEC)

frun: fbin
	$(FUNC_EXEC)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile

# Include rules for menuconfig
include $(NPC_HOME)/csrc/scripts/config.mk

.PHONY: default all clean run pbin fbin
