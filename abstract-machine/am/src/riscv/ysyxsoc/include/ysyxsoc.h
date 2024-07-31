#ifndef NPC_H__
#define NPC_H__

#include <klib-macros.h>
#include <riscv/riscv.h>

// Temp Device Addr, these will be changed in the future !!!
#define DATA_READY  0x01
#define TX_EMPTY    0x20
#define UART_ADDR   0x10000000
#define UART_RX     inb(UART_ADDR)
#define UART_LSR    inb(UART_ADDR + 0x5)
#define UART_LCR    inb(UART_ADDR + 0x3)

#define SERIAL_PORT 0x10000000  // uart16550: 0x1000_0000~0x1000_0fff
#define SRAM_START  0x0f000000  // 
#define SRAM_END    0x0f002000  // sram:      0x0f00_0000~0x0f00_1fff
#define PSRAM_START 0x80000000  // 
#define PSRAM_END   0x80400000  // psram:     0x8000_0000~0x8040_0000
#define SDRAM_START 0xa0000000  // 
#define SDRAM_END   0xa8000000  // sdram:     0xa000_0000~0xa800_0000
#define GPIO_BASE   0x10002000
#define GPIO_LED    GPIO_BASE
#define GPIO_BUT    (GPIO_BASE + 4)
#define GPIO_DIG    (GPIO_BASE + 8)


#define PGSIZE    4096

#endif
