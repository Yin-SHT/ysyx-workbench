.section bootloader, "ax"
.globl _loader
.type _loader, @function

.extern _code_start
.extern _code_end
.extern _bss_start
.extern _bss_end
.extern _start

_loader:
  la   t0, _code_start # t1    = &_code_start 
  la   t1, _code_end   # t2    = &_code_end 
  la   t2, _start      # t2    = &_start
loop:
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  bne  t0, t1, loop    # if  t0 != t1 then loop
# zero out .bss
  la   t0, _bss_start  # t1    = &_bss_start 
  la   t1, _bss_end    # t2    = &_bss_end 
loop1:
  sb   x0, 0(t0)       # *(t0) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  blt  t0, t1, loop1   # if t0 < t1 then loop1
  
# jump to sram
  la   s0, _start      # s0    = &_start
  jr   s0              # jump to s0             
  
  