.section ssbl, "ax"
.globl _ssbl
.type _ssbl, @function

.extern _code_start
.extern _code_end
.extern _bss_start
.extern _bss_end
.extern _start

_ssbl:
  la   t0, _code_start # t0    = &_code_start 
  la   t1, _code_end   # t1    = &_code_end 
  la   t2, _start      # t2    = &_start

# copy code & data from flash to psram
loop:
  bgeu t0, t1, _bss    # if  t0 >= t1 then bss
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  j    loop            # jump to loop

# zero out .bss
_bss:
  la   t0, _bss_start  # t1    = &_bss_start 
  la   t1, _bss_end    # t2    = &_bss_end 
loop1:
  bgeu t0, t1, done    # if  t0 >= t1 then done
  sb   x0, 0(t0)       # *(t0) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  j    loop1           # jump to loop1
  
# jump to _start
done:
  la   s0, _start      # s0    = &_start
  jr   s0              # jump to s0             
  