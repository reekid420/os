#include "../include/isr.h"
#include "../include/idt.h"
#include "../include/vga.h"

// Exception messages
const char *exception_messages[] = {
    "Division By Zero",
    "Debug",
    "Non Maskable Interrupt",
    "Breakpoint",
    "Into Detected Overflow",
    "Out of Bounds",
    "Invalid Opcode",
    "No Coprocessor",
    "Double Fault",
    "Coprocessor Segment Overrun",
    "Bad TSS",
    "Segment Not Present",
    "Stack Fault",
    "General Protection Fault",
    "Page Fault",
    "Unknown Interrupt",
    "Coprocessor Fault",
    "Alignment Check",
    "Machine Check",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved",
    "Reserved"
};

void isr_handler(registers_t regs) {
    if (regs.int_no < 32) {
        terminal_writestring("Received interrupt: ");
        char s[3];
        itoa(regs.int_no, s);
        terminal_writestring(s);
        terminal_writestring("\n");
        terminal_writestring(exception_messages[regs.int_no]);
        terminal_writestring("\n");
        for(;;); // Halt the system
    }
} 