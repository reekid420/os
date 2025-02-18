#ifndef PIC_H
#define PIC_H

#include "stdint.h"

// PIC ports
#define PIC1_COMMAND    0x20    // Master PIC command port
#define PIC1_DATA       0x21    // Master PIC data port
#define PIC2_COMMAND    0xA0    // Slave PIC command port
#define PIC2_DATA       0xA1    // Slave PIC data port

// PIC commands
#define PIC_EOI         0x20    // End of interrupt command
#define ICW1_ICW4       0x01    // ICW4 needed
#define ICW1_SINGLE     0x02    // Single mode
#define ICW1_INTERVAL4  0x04    // Call address interval 4
#define ICW1_LEVEL      0x08    // Level triggered mode
#define ICW1_INIT       0x10    // Initialization command
#define ICW4_8086       0x01    // 8086/88 mode
#define ICW4_AUTO       0x02    // Auto EOI
#define ICW4_BUF_SLAVE  0x08    // Buffered mode/slave
#define ICW4_BUF_MASTER 0x0C    // Buffered mode/master
#define ICW4_SFNM       0x10    // Special fully nested

// IRQ numbers
#define IRQ0            32      // Timer
#define IRQ1            33      // Keyboard
#define IRQ2            34      // Cascade for PIC2
#define IRQ3            35      // COM2
#define IRQ4            36      // COM1
#define IRQ5            37      // LPT2
#define IRQ6            38      // Floppy disk
#define IRQ7            39      // LPT1
#define IRQ8            40      // CMOS real-time clock
#define IRQ9            41      // Free for peripherals
#define IRQ10           42      // Free for peripherals
#define IRQ11           43      // Free for peripherals
#define IRQ12           44      // PS2 Mouse
#define IRQ13           45      // FPU
#define IRQ14           46      // Primary ATA hard disk
#define IRQ15           47      // Secondary ATA hard disk

// Function declarations
void init_pic(void);
void pic_send_eoi(uint8_t irq);
void pic_set_mask(uint8_t irq);
void pic_clear_mask(uint8_t irq);
uint16_t pic_get_irr(void);
uint16_t pic_get_isr(void);

#endif // PIC_H 