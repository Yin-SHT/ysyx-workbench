ENTRY(_fsbl)

MEMORY {
  mrom  : ORIGIN = 0x20000000, LENGTH = 4K
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  flash : ORIGIN = 0x30000000, LENGTH = 16M
  psram : ORIGIN = 0x80000000, LENGTH = 4M
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
    . = ALIGN(8);
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

  _ssbl_start = LOADADDR(.ssbl);
  _ssbl_end   = LOADADDR(.ssbl) + SIZEOF(.ssbl);
  _code_start = LOADADDR(.text);
  _code_end   = LOADADDR(.data) + SIZEOF(.data);

}
