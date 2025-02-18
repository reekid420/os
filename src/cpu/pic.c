#include "../include/pic.h"

// I/O port functions
static inline void outb(uint16_t port, uint8_t value) {
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void io_wait(void) {
    outb(0x80, 0);  // Write to an unused port
}

// Initialize the PIC
void init_pic(void) {
    uint8_t a1, a2;

    // Save masks
    a1 = inb(PIC1_DATA);
    a2 = inb(PIC2_DATA);

    // Start initialization sequence in cascade mode
    outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
    io_wait();
    outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);
    io_wait();

    // ICW2: Set vector offset
    outb(PIC1_DATA, IRQ0);     // Master PIC vector offset (IRQ 0-7: 32-39)
    io_wait();
    outb(PIC2_DATA, IRQ8);     // Slave PIC vector offset (IRQ 8-15: 40-47)
    io_wait();

    // ICW3: Tell Master PIC that there is a slave PIC at IRQ2
    outb(PIC1_DATA, 4);        // Slave PIC is connected to IRQ2
    io_wait();
    outb(PIC2_DATA, 2);        // Tell Slave PIC its cascade identity
    io_wait();

    // ICW4: Set 8086 mode
    outb(PIC1_DATA, ICW4_8086);
    io_wait();
    outb(PIC2_DATA, ICW4_8086);
    io_wait();

    // Restore saved masks
    outb(PIC1_DATA, a1);
    outb(PIC2_DATA, a2);
}

// Send end of interrupt signal to PIC
void pic_send_eoi(uint8_t irq) {
    if (irq >= 8)
        outb(PIC2_COMMAND, PIC_EOI);
    outb(PIC1_COMMAND, PIC_EOI);
}

// Set interrupt mask
void pic_set_mask(uint8_t irq) {
    uint16_t port;
    uint8_t value;

    if (irq < 8) {
        port = PIC1_DATA;
    } else {
        port = PIC2_DATA;
        irq -= 8;
    }
    value = inb(port) | (1 << irq);
    outb(port, value);
}

// Clear interrupt mask
void pic_clear_mask(uint8_t irq) {
    uint16_t port;
    uint8_t value;

    if (irq < 8) {
        port = PIC1_DATA;
    } else {
        port = PIC2_DATA;
        irq -= 8;
    }
    value = inb(port) & ~(1 << irq);
    outb(port, value);
}

// Get Interrupt Request Register
uint16_t pic_get_irr(void) {
    outb(PIC1_COMMAND, 0x0A);  // Read IRR command
    outb(PIC2_COMMAND, 0x0A);
    return (inb(PIC2_COMMAND) << 8) | inb(PIC1_COMMAND);
}

// Get In-Service Register
uint16_t pic_get_isr(void) {
    outb(PIC1_COMMAND, 0x0B);  // Read ISR command
    outb(PIC2_COMMAND, 0x0B);
    return (inb(PIC2_COMMAND) << 8) | inb(PIC1_COMMAND);
} 