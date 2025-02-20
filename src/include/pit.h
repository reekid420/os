#ifndef PIT_H
#define PIT_H

#include "stdint.h"

// PIT ports
#define PIT_CHANNEL0    0x40    // Channel 0 data port (read/write)
#define PIT_CHANNEL1    0x41    // Channel 1 data port (read/write)
#define PIT_CHANNEL2    0x42    // Channel 2 data port (read/write)
#define PIT_COMMAND     0x43    // Mode/Command register (write only)

// PIT command bits
#define PIT_CHANNEL0_SELECT  0x00    // Select channel 0
#define PIT_CHANNEL1_SELECT  0x40    // Select channel 1
#define PIT_CHANNEL2_SELECT  0x80    // Select channel 2
#define PIT_ACCESS_LATCH     0x00    // Latch count value command
#define PIT_ACCESS_LOBYTE    0x10    // Lobyte only
#define PIT_ACCESS_HIBYTE    0x20    // Hibyte only
#define PIT_ACCESS_WORD      0x30    // Low byte then high byte
#define PIT_MODE0            0x00    // Interrupt on terminal count
#define PIT_MODE1            0x02    // Hardware retriggerable one-shot
#define PIT_MODE2            0x04    // Rate generator
#define PIT_MODE3            0x06    // Square wave generator
#define PIT_MODE4            0x08    // Software triggered strobe
#define PIT_MODE5            0x0A    // Hardware triggered strobe
#define PIT_BCD              0x01    // BCD counter (default is binary)

// PIT configuration
#define PIT_FREQUENCY    1193180     // Input frequency (Hz)
#define PIT_CHANNEL0_HZ  100         // Desired frequency for channel 0 (Hz)

// Function declarations
void init_pit(void);
void pit_set_frequency(uint32_t frequency);
uint32_t pit_get_tick_count(void);
void pit_wait(uint32_t milliseconds);

#endif // PIT_H 