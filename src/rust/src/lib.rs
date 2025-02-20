#![no_std]
#![feature(const_mut_refs)]

pub mod lib {
    pub mod timer;
}

use lib::timer::Timer;

#[no_mangle]
pub static TIMER: Timer = Timer::new();
