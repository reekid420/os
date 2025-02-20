#![no_std]

use core::sync::atomic::{AtomicU32, Ordering};
use core::ptr::write_volatile;
use core::panic::PanicInfo;

const PIT_FREQUENCY: u32 = 1193180;
const PIT_CHANNEL0_HZ: u32 = 100;
const PIT_COMMAND: u16 = 0x43;
const PIT_CHANNEL0: u16 = 0x40;
const PIT_CHANNEL0_SELECT: u8 = 0x00;
const PIT_ACCESS_WORD: u8 = 0x30;
const PIT_MODE3: u8 = 0x06;

// Debug control
const DEBUG_INTERVAL: u32 = 100; // Only debug output every 100 ticks

// VGA buffer constants
const VGA_BUFFER: *mut u16 = 0xB8000 as *mut u16;
const VGA_WIDTH: usize = 80;
const VGA_HEIGHT: usize = 25;

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    unsafe {
        // Clear screen
        for i in 0..(VGA_WIDTH * VGA_HEIGHT) {
            write_volatile(VGA_BUFFER.add(i), 0x0720);
        }
        
        // Write panic message
        let msg = b"PANIC!";
        for (i, &byte) in msg.iter().enumerate() {
            write_volatile(VGA_BUFFER.add(i), (byte as u16) | 0x4F00); // White on red
        }
    }
    loop {}
}

#[repr(C)]
pub struct Timer {
    tick_count: AtomicU32,
}

// Safety: VGA buffer is only accessed through atomic operations
unsafe impl Send for Timer {}
unsafe impl Sync for Timer {}

impl Timer {
    pub const fn new() -> Self {
        Self {
            tick_count: AtomicU32::new(0),
        }
    }

    #[no_mangle]
    pub unsafe extern "C" fn timer_init(&self) {
        let divisor = PIT_FREQUENCY / PIT_CHANNEL0_HZ;
        let command = PIT_CHANNEL0_SELECT | PIT_ACCESS_WORD | PIT_MODE3;
        
        outb(PIT_COMMAND, command);
        outb(PIT_CHANNEL0, (divisor & 0xFF) as u8);
        outb(PIT_CHANNEL0, ((divisor >> 8) & 0xFF) as u8);
        
        // Write initialization message to VGA buffer
        let msg = b"Timer Initialized (Rust)";
        for (i, &byte) in msg.iter().enumerate() {
            write_volatile(VGA_BUFFER.add(i), (byte as u16) | 0x0F00);
        }
    }

    #[no_mangle]
    pub extern "C" fn timer_get_ticks(&self) -> u32 {
        self.tick_count.load(Ordering::SeqCst)
    }

    #[no_mangle]
    pub extern "C" fn timer_callback(&self) {
        let count = self.tick_count.fetch_add(1, Ordering::SeqCst);
        
        // Only update display on certain intervals to reduce CPU usage
        if count % 10 != 0 {
            return;
        }

        unsafe {
            // Clear status line (last line of screen)
            let status_line = (VGA_HEIGHT - 1) * VGA_WIDTH;
            for i in 0..VGA_WIDTH {
                write_volatile(VGA_BUFFER.add(status_line + i), 0x0720);
            }
            
            // Write tick count on status line
            let msg = b"System Ticks: ";
            for (i, &byte) in msg.iter().enumerate() {
                write_volatile(VGA_BUFFER.add(status_line + i), (byte as u16) | 0x0F00);
            }
            
            // Convert count to string and write it
            let mut num = count + 1;
            let mut pos = status_line + msg.len();
            if num == 0 {
                write_volatile(VGA_BUFFER.add(pos), (b'0' as u16) | 0x0F00);
            } else {
                let mut digits = [0u8; 20];
                let mut i = 0;
                while num > 0 {
                    digits[i] = (num % 10) as u8 + b'0';
                    num /= 10;
                    i += 1;
                }
                while i > 0 {
                    i -= 1;
                    write_volatile(VGA_BUFFER.add(pos), (digits[i] as u16) | 0x0F00);
                    pos += 1;
                }
            }
            
            // Add time indicator
            let time_msg = b" | Time: ";
            for (i, &byte) in time_msg.iter().enumerate() {
                write_volatile(VGA_BUFFER.add(pos), (byte as u16) | 0x0F00);
                pos += 1;
            }
            
            // Calculate and display time
            let seconds = (count + 1) / PIT_CHANNEL0_HZ;
            let minutes = seconds / 60;
            let hours = minutes / 60;
            
            // Format as HH:MM:SS
            let time_digits: [u32; 8] = [
                (hours % 24) / 10,
                (hours % 24) % 10,
                10, // ':' character
                (minutes % 60) / 10,
                (minutes % 60) % 10,
                10, // ':' character
                (seconds % 60) / 10,
                (seconds % 60) % 10
            ];
            
            for &digit in time_digits.iter() {
                let ch = if digit == 10 { b':' } else { digit as u8 + b'0' };
                write_volatile(VGA_BUFFER.add(pos), (ch as u16) | 0x0F00);
                pos += 1;
            }
        }
    }
}

#[inline(always)]
unsafe fn outb(port: u16, value: u8) {
    core::arch::asm!(
        "out dx, al",
        in("dx") port,
        in("al") value,
        options(nomem, nostack)
    );
}

#[no_mangle]
pub static TIMER: Timer = Timer::new(); 