.section bootloader, "ax"
.globl _loader
.type _loader, @function

.extern _text_lma, _text_end, _text_vma
.extern _data_lma, _data_end, _data_vma
.extern _rodata_lma, _rodata_end, _rodata_vma
.extern _bss_start, _bss_end
.extern _start

_loader:
  # .text FLASH --> SRAM
  la   t0, _text_lma   # t1    = &_text_lma
  la   t1, _text_end   # t2    = &_text_end
  la   t2, _text_vma   # t2    = &_text_vma
text_loop:
  bgeu t0, t1, rodata_loader 
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  j    text_loop       # jump to text_loop
  
  # .rodata FLASH --> SRAM
rodata_loader:
  la   t0, _rodata_lma   # t1    = &_rodata_lma
  la   t1, _rodata_end   # t2    = &_rodata_end
  la   t2, _rodata_vma   # t2    = &_rodata_vma
rodata_loop:
  bgeu t0, t1, data_loader
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  j    rodata_loop     # jump to rodata_loop

  # .data FLASH --> SRAM
data_loader:
  la   t0, _data_lma   # t1    = &_data_lma
  la   t1, _data_end   # t2    = &_data_end
  la   t2, _data_vma   # t2    = &_data_vma
data_loop:
  bgeu t0, t1, bss_loader
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  j    data_loop       # jump to data_loop
  
  # zero out .bss
bss_loader:
  la   t0, _bss_start  # t1    = &_bss_start 
  la   t1, _bss_end    # t2    = &_bss_end 
bss_loop:
  bgeu t0, t1, done
  sb   x0, 0(t0)       # *(t0) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  j    bss_loop        # jump to bss_loop
  
# jump to sram
done:
  la   s0, _start      # s0    = &_start
  jr   s0              # jump to s0             
  