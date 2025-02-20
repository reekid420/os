#include "../include/pit.h"
#include "../include/isr.h"
#include "../include/pic.h"
#include "../include/vga.h"
#include "../include/string.h"
#include "../include/rust_timer.h"

// I/O port functions
static inline void outb(uint16_t port, uint8_t value) {
    asm volatile ("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    asm volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

// Timer callback wrapper for Rust
static void timer_callback_wrapper(registers_t regs) {
    (void)regs; // Unused parameter
    timer_callback(&TIMER);
}

void init_pit(void) {
    // Initialize Rust timer
    timer_init(&TIMER);
    
    // Register our Rust timer callback
    register_interrupt_handler(IRQ0, timer_callback_wrapper);
    pic_clear_mask(0);
    
    // Set up PIT frequency
    pit_set_frequency(PIT_CHANNEL0_HZ);
}

void pit_set_frequency(uint32_t frequency) {
    // Calculate divisor
    uint32_t divisor = PIT_FREQUENCY / frequency;
    
    // Set command byte
    uint8_t command = PIT_CHANNEL0_SELECT |    // Channel 0
                      PIT_ACCESS_WORD |        // Low/High byte access
                      PIT_MODE3 |              // Square wave generator
                      0;                       // Binary counter
    
    outb(PIT_COMMAND, command);
    
    // Set frequency divisor
    outb(PIT_CHANNEL0, divisor & 0xFF);         // Low byte
    outb(PIT_CHANNEL0, (divisor >> 8) & 0xFF);  // High byte
}

uint32_t pit_get_tick_count(void) {
    return timer_get_ticks(&TIMER);
}

void pit_wait(uint32_t milliseconds) {
    uint32_t start = pit_get_tick_count();
    uint32_t target_ticks = (milliseconds * PIT_CHANNEL0_HZ) / 1000;
    
    while (pit_get_tick_count() - start < target_ticks) {
        asm volatile("pause");  // More efficient than hlt for short waits
    }
} 