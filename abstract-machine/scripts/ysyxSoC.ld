ENTRY(_start)
/*
PHDRS { text PT_LOAD; data PT_LOAD; }
*/
MEMORY {
  mrom : ORIGIN = 0x30000000, LENGTH = 16M
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT> mrom 
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  . = ALIGN(0x8);
  _rodata_end = .;
  } > mrom AT> mrom
  .data : {
  _data_start = .;
    *(.data*)
    *(.sdata*)
  _data_end = .;
  } > sram AT> mrom 
  .bss ALIGN(0x8) : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  } > sram AT> mrom 

}
