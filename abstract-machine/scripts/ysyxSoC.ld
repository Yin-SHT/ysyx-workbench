ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT> mrom : text
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  . = ALIGN(0x8);
  _rodata_end = .;
  } > mrom AT> mrom
  .data : {
  _data_start = .;
    *(.data*)
  _data_end = .;
  } > sram AT> mrom : data
  .bss ALIGN(0x8) : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
	_bss_end = .;
  } > sram AT> mrom 

}
