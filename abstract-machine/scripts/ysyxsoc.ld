ENTRY(_start)

MEMORY {
  mrom  : ORIGIN = 0x20000000, LENGTH = 4K
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(flash);

  .text : {
    *(entry)
    *(.text*)
  } > flash AT> flash 

  .rodata : {
  . = ALIGN(8);
    *(.rodata*)
    *(.srodata*)
  } > flash AT> flash

  .data : {
  . = ALIGN(8);
    _data_start = .;
    *(.data*)
    *(.sdata*)
  } > psram AT> flash 

  .bss : {
  . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  _heap_start = ALIGN(0x1000);
  } > psram 

  _data_load_start = LOADADDR(.data);
  _data_load_end   = LOADADDR(.data) + SIZEOF(.data);
}
