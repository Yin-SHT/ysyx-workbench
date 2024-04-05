ENTRY(_loader)
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(flash);
  .loader : {
    *(bootloader)
  } > flash AT> flash 

  .text : ALIGN(8) {
    *(entry)
    *(.text*)
  } > psram AT> flash 

  .rodata : ALIGN(8) {
  . = ALIGN(8);
    *(.rodata*)
    *(.srodata*)
  } > psram AT> flash

  .data : ALIGN(8) {
  . = ALIGN(8);
    _data_start = .;
    *(.data*)
    *(.sdata*)
  } > psram AT> flash 

  .bss : ALIGN(8) {
  . = ALIGN(8);
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  . = ALIGN(0x8);
  _heap_start = .;
  } > psram AT> flash 

  _code_start = LOADADDR(.text);
  _code_end   = LOADADDR(.data) + SIZEOF(.data);
}
