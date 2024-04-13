ENTRY(_fsbl)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  sdram : ORIGIN = 0xa0000000, LENGTH = 128M
}

SECTIONS {
  . = ORIGIN(flash);

  .fsbl : {
    *(fsbl)
  } > flash AT> flash 

  .ssbl : ALIGN(8) {
    *(ssbl)
  } > sram AT> flash 

  .text : ALIGN(8) {
    *(entry)
    *(.text*)
  } > sdram AT> flash 

  .rodata : ALIGN(8) {
  . = ALIGN(8);
    *(.rodata*)
    *(.srodata*)
  } > sdram AT> flash

  .data : ALIGN(8) {
  . = ALIGN(8);
    _data_start = .;
    *(.data*)
    *(.sdata*)
  } > sdram AT> flash 

  .bss : ALIGN(8) {
  . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  . = ALIGN(0x8);
  _heap_start = .;
  } > sdram AT> flash 

  _ssbl_start = LOADADDR(.ssbl);
  _ssbl_end   = LOADADDR(.ssbl) + SIZEOF(.ssbl);
  _code_start = LOADADDR(.text);
  _code_end   = LOADADDR(.data) + SIZEOF(.data);
}
