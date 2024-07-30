.section fsbl, "ax"
.globl _fsbl
.type _fsbl, @function

.extern _ssbl_start
.extern _ssbl_end
.extern _ssbl

_fsbl:
  la   t0, _ssbl_start # t0    = &_ssbl_start 
  la   t1, _ssbl_end   # t1    = &_ssbl_end 
  la   t2, _ssbl       # t2    = &_ssbl

# copy ssbl from flash to sram
loop:
  bgeu t0, t1, done    # if  t0 >= t1 then done
  lbu  s0, 0(t0)       # s0    = *(t0)
  sb   s0, 0(t2)       # *(t2) = s0
  addi t0, t0, 1;      # t0 = t0 + 1
  addi t2, t2, 1;      # t2 = t2 + 1
  j    loop            # jump to loop
  
# jump to _ssbl
done:
  la   s0, _ssbl       # s0 = &_ssbl
  jr   s0              # jump to s0             
  