ENTRY(_loader)

MEMORY {
  mrom  : ORIGIN = 0x20000000, LENGTH = 4K
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(flash);

  .loader : {
    *(bootloader)
  } > flash AT> flash 

  .text : ALIGN(8) {
    . = ALIGN(8);
    _text_vma = .;
    *(entry)
    *(.text*)
  } > psram AT> flash 

  .rodata : ALIGN(8) {
    . = ALIGN(8);
    _rodata_vma = .;
    *(.rodata*)
    *(.srodata*)
  } > psram AT> flash 

  .data : ALIGN(8) {
    . = ALIGN(8);
    _data_vma = .;
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

  _text_lma   = LOADADDR(.text);
  _text_end   = LOADADDR(.text) + SIZEOF(.text);
  _rodata_lma = LOADADDR(.rodata);
  _rodata_end = LOADADDR(.rodata) + SIZEOF(.rodata);
  _data_lma   = LOADADDR(.data);
  _data_end   = LOADADDR(.data) + SIZEOF(.data);
}
