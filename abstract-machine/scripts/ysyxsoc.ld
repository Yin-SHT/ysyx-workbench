ENTRY(_start)

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(mrom);

  .text : {
    *(entry)
    *(.text*)
  } > mrom AT> mrom 

  .rodata : {
  . = ALIGN(8);
    *(.rodata*)
    *(.srodata*)
  } > mrom AT> mrom

  .data : {
  . = ALIGN(8);
    _data_start = .;
    *(.data*)
    *(.sdata*)
  } > sram AT> mrom 

  .bss : {
  . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  } > sram AT> mrom 

  _data_load_start = LOADADDR(.data);
  _data_load_end   = LOADADDR(.data) + SIZEOF(.data);
}
