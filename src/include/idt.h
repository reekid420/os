#ifndef IDT_H
#define IDT_H
#include "stdint.h"
#include "isr.h"

// Interrupt gate types
#define IDT_INTERRUPT_GATE 0x8E
#define IDT_TRAP_GATE     0x8F

// Structure for IDT entry
typedef struct {
    uint16_t base_low;     // Lower 16 bits of handler function address
    uint16_t selector;     // Kernel segment selector
    uint8_t  zero;         // Always zero
    uint8_t  flags;        // Gate type, DPL, and P fields
    uint16_t base_high;    // Higher 16 bits of handler function address
} __attribute__((packed)) idt_entry_t;

// Structure for IDT pointer
typedef struct {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed)) idt_ptr_t;

// Function declarations
void init_idt(void);
void idt_set_gate(uint8_t num, uint32_t base, uint16_t selector, uint8_t flags);

// External assembly function
extern void idt_flush(uint32_t);

// ISR handlers
extern void isr0(void);
extern void isr1(void);
extern void isr2(void);
extern void isr3(void);
extern void isr4(void);
extern void isr5(void);
extern void isr6(void);
extern void isr7(void);
extern void isr8(void);
extern void isr9(void);
extern void isr10(void);
extern void isr11(void);
extern void isr12(void);
extern void isr13(void);
extern void isr14(void);
extern void isr15(void);
extern void isr16(void);
extern void isr17(void);
extern void isr18(void);
extern void isr19(void);
extern void isr20(void);
extern void isr21(void);
extern void isr22(void);
extern void isr23(void);
extern void isr24(void);
extern void isr25(void);
extern void isr26(void);
extern void isr27(void);
extern void isr28(void);
extern void isr29(void);
extern void isr30(void);
extern void isr31(void);

#endif // IDT_H 