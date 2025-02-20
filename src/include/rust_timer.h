#ifndef RUST_TIMER_H
#define RUST_TIMER_H

#include "stdint.h"

// Opaque type for the Rust Timer struct
typedef struct Timer Timer;

// External functions from Rust
extern Timer TIMER;
extern void timer_init(Timer* timer);
extern void timer_callback(Timer* timer);
extern uint32_t timer_get_ticks(Timer* timer);

#endif // RUST_TIMER_H 