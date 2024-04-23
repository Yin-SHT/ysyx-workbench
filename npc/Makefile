TOPNAME = ysyxSoCFull
NXDC_FILES = constr/ysyxSoCFull.nxdc
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
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))
$(shell mkdir -p $(BUILD_DIR)/output)

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(SOC_HOME)/build/ysyxSoCFull.v
VSRCS += $(shell find $(SOC_HOME)/perip -name "*.v")
VSRCS += $(shell find $(NPC_HOME)/vsrc -name "*.v")

CSRCS = $(shell find $(NPC_HOME)/csrc -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CFLAGS = $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\"" \
		 $(shell llvm-config --cxxflags) 
LDFLAGS = -lreadline -lSDL2 $(shell llvm-config --libs) -lSDL2 -lSDL2_image -lSDL2_ttf

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$(BUILD_DIR)/$(TOPNAME) -b $(ARGS) $(IMG)

all: default

# Command to execute NEMU
IMG ?=
ARGS ?=
YSYXSOC_EXEC := $(BIN) $(ARGS) -d /home/gtl/Code/system/ysyx-workbench/nemu/build/riscv32-nemu-interpreter-so $(IMG)

run: $(BIN)
	$(YSYXSOC_EXEC)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile

.PHONY: default all clean run
