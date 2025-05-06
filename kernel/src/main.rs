#![no_std]
#![no_main]

use core::panic::PanicInfo;

// Import necessary modules (to be implemented)
mod memory;
mod arch;

// GENERATOR: Define a module for multiboot2 handling
mod multiboot {
    // Multiboot2 information structure passed by bootloader
    #[repr(C)]
    #[derive(Debug)]
    pub struct MultibootInfo {
        pub total_size: u32,
        pub reserved: u32,
        // Additional fields follow in memory but their presence depends on flags
    }
    
    // Multiboot2 constants
    pub const MAGIC: u32 = 0x36d76289;
    
    // Define the multiboot2 tag types
    pub const TAG_END: u32 = 0;
    pub const TAG_BOOT_CMD_LINE: u32 = 1;
    pub const TAG_BOOT_LOADER_NAME: u32 = 2;
    pub const TAG_MODULE: u32 = 3;
    pub const TAG_MEMORY_INFO: u32 = 4;
    pub const TAG_BIOS_BOOT_DEVICE: u32 = 5;
    pub const TAG_MEMORY_MAP: u32 = 6;
    
    // Tag structure header
    #[repr(C)]
    #[derive(Debug)]
    pub struct TagHeader {
        pub tag_type: u32,
        pub size: u32,
    }
    
    impl MultibootInfo {
        pub fn is_valid_magic(magic: u32) -> bool {
            magic == MAGIC
        }
    }
}

// GENERATOR: Define VGA console for visual output
mod console {
    // VGA text mode memory address
    const VGA_BUFFER: usize = 0xB8000;
    const VGA_WIDTH: usize = 80;
    const VGA_HEIGHT: usize = 25;
    
    // Generator: Track current position and color
    static mut CURSOR_X: usize = 0;
    static mut CURSOR_Y: usize = 0;
    static mut COLOR: u8 = 0x0F; // Default: white on black
    
    // Initialize console
    pub fn init() {
        // Initialize cursor position
        unsafe {
            CURSOR_X = 0;
            CURSOR_Y = 0;
        }
    }
    
    // Clear the screen
    pub fn clear_screen() {
        let vga_buffer = VGA_BUFFER as *mut u8;
        // Discriminator: Validate that we clear the entire buffer
        for i in 0..VGA_WIDTH * VGA_HEIGHT {
            unsafe {
                *vga_buffer.offset(i as isize * 2) = b' ';
                *vga_buffer.offset(i as isize * 2 + 1) = COLOR;
            }
        }
        unsafe {
            CURSOR_X = 0;
            CURSOR_Y = 0;
        }
    }
    
    // Set text color
    pub fn set_color(color: u8) {
        unsafe {
            COLOR = color;
        }
    }
    
    // Print a single character
    pub fn putchar(c: char) {
        // Handle newline
        if c == '\n' {
            unsafe {
                CURSOR_X = 0;
                CURSOR_Y += 1;
                if CURSOR_Y >= VGA_HEIGHT {
                    scroll();
                    CURSOR_Y = VGA_HEIGHT - 1;
                }
            }
            return;
        }
        
        // Print character to screen
        unsafe {
            let vga_buffer = VGA_BUFFER as *mut u8;
            let index = CURSOR_Y * VGA_WIDTH + CURSOR_X;
            
            // Generator: Write character and color
            *vga_buffer.offset((index * 2) as isize) = c as u8;
            *vga_buffer.offset((index * 2 + 1) as isize) = COLOR;
            
            // Update cursor
            CURSOR_X += 1;
            if CURSOR_X >= VGA_WIDTH {
                CURSOR_X = 0;
                CURSOR_Y += 1;
                if CURSOR_Y >= VGA_HEIGHT {
                    scroll();
                    CURSOR_Y = VGA_HEIGHT - 1;
                }
            }
        }
    }
    
    // Print a string
    pub fn print(s: &str) {
        for c in s.chars() {
            putchar(c);
        }
    }
    
    // Print a string with newline
    pub fn println(s: &str) {
        print(s);
        putchar('\n');
    }
    
    // Scroll the screen up one line
    fn scroll() {
        unsafe {
            let vga_buffer = VGA_BUFFER as *mut u8;
            
            // Discriminator: Validate scroll behavior
            // Move each line up one line
            for y in 1..VGA_HEIGHT {
                for x in 0..VGA_WIDTH {
                    let src_idx = y * VGA_WIDTH + x;
                    let dst_idx = (y - 1) * VGA_WIDTH + x;
                    
                    let char_byte = *vga_buffer.offset((src_idx * 2) as isize);
                    let color_byte = *vga_buffer.offset((src_idx * 2 + 1) as isize);
                    
                    *vga_buffer.offset((dst_idx * 2) as isize) = char_byte;
                    *vga_buffer.offset((dst_idx * 2 + 1) as isize) = color_byte;
                }
            }
            
            // Clear the last line
            let last_line = (VGA_HEIGHT - 1) * VGA_WIDTH;
            for x in 0..VGA_WIDTH {
                *vga_buffer.offset(((last_line + x) * 2) as isize) = b' ';
                *vga_buffer.offset(((last_line + x) * 2 + 1) as isize) = COLOR;
            }
        }
    }
}

// GENERATOR: Define serial port for debugging output
mod serial {
    const PORT: u16 = 0x3F8; // COM1 port
    
    // Write a byte to the serial port
    pub unsafe fn write_byte(byte: u8) {
        use core::ptr::write_volatile;
        write_volatile(PORT as *mut u8, byte);
    }
    
    // Write a string to the serial port
    pub fn write_string(s: &str) {
        for byte in s.bytes() {
            unsafe { write_byte(byte); }
        }
    }
    
    // Initialize serial port
    pub fn init() {
        unsafe {
            // Disable interrupts
            use core::ptr::write_volatile;
            write_volatile((PORT + 1) as *mut u8, 0x00);
            
            // Set baud rate to 38400
            write_volatile((PORT + 3) as *mut u8, 0x80); // Enable DLAB
            write_volatile((PORT + 0) as *mut u8, 0x03); // Low byte: 38400 baud
            write_volatile((PORT + 1) as *mut u8, 0x00); // High byte
            
            // 8 bits, no parity, 1 stop bit
            write_volatile((PORT + 3) as *mut u8, 0x03);
            
            // Enable FIFO, clear with 14-byte threshold
            write_volatile((PORT + 2) as *mut u8, 0xC7);
            
            // IRQs enabled, RTS/DSR set
            write_volatile((PORT + 4) as *mut u8, 0x0B);
        }
    }
}

// GENERATOR: Implement formatting functions for debug output
// Convert a u32 to a hex string - simplified implementation
fn format_u32(num: u32) -> &'static str {
    // Static buffer for the result (max 10 chars including null terminator)
    static mut BUF: [u8; 10] = [0; 10];
    
    let digits = "0123456789abcdef".as_bytes();
    let mut i = 8;
    
    unsafe {
        // Fill the buffer from right to left
        let mut n = num;
        while i > 0 {
            BUF[i - 1] = digits[(n & 0xf) as usize];
            n >>= 4;
            i -= 1;
        }
        
        // Return the static str
        core::str::from_utf8_unchecked(&BUF[0..8])
    }
}

// Convert a usize to a hex string
fn format_usize(num: usize) -> &'static str {
    // On x86_64, usize is 64 bits
    static mut BUF: [u8; 16] = [0; 16];
    
    let digits = "0123456789abcdef".as_bytes();
    let mut i = 16;
    
    unsafe {
        // Fill the buffer from right to left
        let mut n = num;
        while i > 0 {
            BUF[i - 1] = digits[(n & 0xf) as usize];
            n >>= 4;
            i -= 1;
        }
        
        // Return the static str
        core::str::from_utf8_unchecked(&BUF[0..16])
    }
}

// GENERATOR: Define multiboot2 header constants and structures
const MULTIBOOT2_MAGIC: u32 = 0xE85250D6;
const MULTIBOOT_ARCHITECTURE: u32 = 0; // 32-bit protected mode
const HEADER_LENGTH: u32 = 16; // Basic header length (16 bytes)
// DISCRIMINATOR: Fix overflow in checksum calculation
const CHECKSUM: u32 = 0u32.wrapping_sub(MULTIBOOT2_MAGIC.wrapping_add(MULTIBOOT_ARCHITECTURE).wrapping_add(HEADER_LENGTH));

// GENERATOR: Simple multiboot header structure - the simplest that GRUB will accept
#[repr(C, align(8))]
#[derive(Clone, Copy)]
struct MultibootHeader {
    magic: u32,
    architecture: u32,
    header_length: u32,
    checksum: u32,
}

// GENERATOR: Multiboot2 header to make kernel bootable by GRUB and QEMU
// The header must be early in the binary and 8-byte aligned
#[link_section = ".multiboot_header"]
#[no_mangle]
pub static MULTIBOOT_HEADER: MultibootHeader = MultibootHeader {
    magic: MULTIBOOT2_MAGIC,
    architecture: MULTIBOOT_ARCHITECTURE,
    header_length: HEADER_LENGTH,
    checksum: CHECKSUM,
};

// GENERATOR: Define the multiboot info structure that GRUB passes to us
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Multiboot2Header {
    // This is just for the earlier static variable
    // The real multiboot info is defined in the multiboot module
    magic: u32,
    architecture: u32,
    header_length: u32,
    checksum: u32,
}

/// This function is called on panic.
/// DISCRIMINATOR: Validate proper panic handling
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // In a real implementation, we would log the panic info
    unsafe {
        // Print "PANIC" to VGA for visual feedback
        let vga_buffer = 0xb8000 as *mut u8;
        let panic_msg = b"PANIC!";
        for (i, &byte) in panic_msg.iter().enumerate() {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x4f; // Red on white
        }
    }
    loop {}
}

/// The entry point for the kernel called by our assembly bootstrap code
/// GENERATOR: Implement proper kernel initialization for multiboot2 with debugging
#[no_mangle]
pub extern "C" fn rust_main(multiboot_info_ptr: usize, magic: u32) -> ! {
    // GENERATOR: First, clear the screen (simplest VGA operation to validate the system is working)
    let vga_buffer = 0xb8000 as *mut u8;
    for i in 0..25 * 80 {
        unsafe {
            *vga_buffer.offset(i * 2) = b' ';
            *vga_buffer.offset(i * 2 + 1) = 0x07; // Light gray on black
        }
    }
    
    // DISCRIMINATOR: Display a basic boot message without complex operations
    let boot_msg = b"Kernel Boot Initiated";
    for (i, &byte) in boot_msg.iter().enumerate() {
        unsafe {
            *vga_buffer.offset(i as isize * 2) = byte;
            *vga_buffer.offset(i as isize * 2 + 1) = 0x0F; // White on black
        }
    }
    
    // GENERATOR: Initialize serial port for debug output
    // Even if VGA isn't working, we might get serial output
    serial::init();
    serial::write_string("\n\nKernel boot started!\n");
    serial::write_string("---------------------------\n");
    
    // DISCRIMINATOR: Very basic multiboot info debugging
    serial::write_string("Multiboot magic: 0x");
    
    // Manual number formatting to avoid complex operations
    let mut value = magic;
    let mut digits = [0u8; 8]; // 8 hex digits for u32
    for i in (0..8).rev() {
        let digit = (value & 0xF) as u8;
        digits[i] = if digit < 10 {
            b'0' + digit
        } else {
            b'a' + (digit - 10)
        };
        value >>= 4;
    }
    
    for &digit in &digits {
        unsafe {
            serial::write_byte(digit);
        }
    }
    
    serial::write_string("\n");
    serial::write_string("Multiboot info at: 0x");
    
    // Prepare info pointer for display
    let mut addr_value = multiboot_info_ptr;
    let mut addr_digits = [0u8; 16]; // 16 hex digits for usize
    for i in (0..16).rev() {
        let digit = (addr_value & 0xF) as u8;
        addr_digits[i] = if digit < 10 {
            b'0' + digit
        } else {
            b'a' + (digit - 10)
        };
        addr_value >>= 4;
    }
    
    for &digit in &addr_digits {
        unsafe {
            serial::write_byte(digit);
        }
    }
    serial::write_string("\n");

    // DISCRIMINATOR: Validate boot status with direct VGA writing
    let magic_valid = magic == 0x36d76289; // Multiboot2 magic value
    
    // Use separate handling for success/failure to avoid array size incompatibility
    if magic_valid {
        let success_msg = b"Boot Status: SUCCESS";
        // Display success message on a new line (green on black)
        for (i, &byte) in success_msg.iter().enumerate() {
            unsafe {
                *vga_buffer.offset((80 + i) as isize * 2) = byte;
                *vga_buffer.offset((80 + i) as isize * 2 + 1) = 0x2F; // Green on black
            }
        }
    } else {
        let error_msg = b"Boot Status: FAILURE - Invalid multiboot magic";
        // Display error message on a new line (red on black)
        for (i, &byte) in error_msg.iter().enumerate() {
            unsafe {
                *vga_buffer.offset((80 + i) as isize * 2) = byte;
                *vga_buffer.offset((80 + i) as isize * 2 + 1) = 0x4F; // Red on black
            }
        }
    }
    
    // Display more kernel information on subsequent lines
    let info_msg = b"Kernel Information:";
    for (i, &byte) in info_msg.iter().enumerate() {
        unsafe {
            *vga_buffer.offset((160 + i) as isize * 2) = byte;
            *vga_buffer.offset((160 + i) as isize * 2 + 1) = 0x0F; // White on black
        }
    }
    
    // Separator line
    let separator = b"------------------";
    for (i, &byte) in separator.iter().enumerate() {
        unsafe {
            *vga_buffer.offset((240 + i) as isize * 2) = byte;
            *vga_buffer.offset((240 + i) as isize * 2 + 1) = 0x0F; // White on black
        }
    }
    
    // DISCRIMINATOR: Validate multiboot info structure with basic checks
    if multiboot_info_ptr != 0 && magic_valid {
        // Write minimal multiboot info to screen
        let info_available = b"Multiboot info available";
        for (i, &byte) in info_available.iter().enumerate() {
            unsafe {
                *vga_buffer.offset((320 + i) as isize * 2) = byte;
                *vga_buffer.offset((320 + i) as isize * 2 + 1) = 0x0A; // Light green on black
            }
        }
        
        // Write minimal info to serial port too
        serial::write_string("Multiboot info is available and valid\n");
        
        // Send a basic message to show boot progression
        serial::write_string("Boot sequence running...\n");
    } else {
        // Show error if info not available
        let info_error = b"Multiboot info not available";
        for (i, &byte) in info_error.iter().enumerate() {
            unsafe {
                *vga_buffer.offset((320 + i) as isize * 2) = byte;
                *vga_buffer.offset((320 + i) as isize * 2 + 1) = 0x0C; // Light red on black
            }
        }
        
        serial::write_string("Multiboot info NOT available or invalid\n");
    }
    
    // DISCRIMINATOR: Show boot completion status
    let complete_msg = b"Boot validation complete";
    for (i, &byte) in complete_msg.iter().enumerate() {
        unsafe {
            *vga_buffer.offset((400 + i) as isize * 2) = byte;
            *vga_buffer.offset((400 + i) as isize * 2 + 1) = 0x0B; // Light cyan on black
        }
    }
    
    // Final status message
    let halted_msg = b"System running. Press Ctrl+C to exit.";
    for (i, &byte) in halted_msg.iter().enumerate() {
        unsafe {
            *vga_buffer.offset((480 + i) as isize * 2) = byte;
            *vga_buffer.offset((480 + i) as isize * 2 + 1) = 0x07; // Gray on black
        }
    }
    
    // Debug end message to serial
    serial::write_string("\nKernel initialization complete - entering halt loop\n");
    serial::write_string("----------------------------------------------------\n");
    
    // GENERATOR: Properly halt the CPU with diagnostics if something happens
    loop {
        // CPU halt (reduced power consumption in loop)
        unsafe {
            core::arch::asm!("hlt", options(nomem, nostack, preserves_flags));
        }
    }
}
