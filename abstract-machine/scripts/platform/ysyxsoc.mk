AM_SRCS := riscv/ysyxsoc/fsbl.S \
           riscv/ysyxsoc/ssbl.S \
           riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/ioe.c \
           riscv/ysyxsoc/uart.c \
           riscv/ysyxsoc/timer.c \
           riscv/ysyxsoc/input.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/gpu.c \
           riscv/ysyxsoc/trap.S \
		   riscv/ysyxsoc/vme.c \
           riscv/ysyxsoc/mpe.c

DATE := $(shell date +%Y%m%d)

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/ysyxsoc.ld 
LDFLAGS   += --gc-sections -e _fsbl
CFLAGS += -DMAINARGS=\"$(mainargs)\" -DDATE=0x$(DATE)
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/include
.PHONY: $(AM_HOME)/am/src/riscv/ysyxSoC/trm.c

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -s -C $(NPC_HOME) ARGS=-b IMG=$(abspath $(IMAGE).bin) prun
