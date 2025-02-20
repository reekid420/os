#include "include/stddef.h"
#include "include/stdint.h"
#include "include/mm.h"
#include "include/multiboot.h"
#include "include/vmm.h"
#include "include/gdt.h"
#include "include/tss.h"
#include "include/idt.h"
#include "include/isr.h"
#include "include/pic.h"
#include "include/pit.h"
#include "include/vga.h"
#include "include/heap.h"
#include "include/string.h"

void test_tss(void) {
    terminal_writestring("Testing TSS...\n");
    
    // Initialize TSS with kernel stack
    uint32_t kernel_stack = 0x100000; // 1MB mark for test stack
    init_tss(5, 0x10, kernel_stack);  // 5 is TSS index in GDT, 0x10 is kernel data segment
    
    // Flush TSS
    tss_flush();
    
    terminal_writestring("TSS initialized and loaded.\n");
    
    // Test stack switching
    tss_set_stack(0x10, kernel_stack + 0x1000);
    terminal_writestring("TSS stack switch test completed.\n");
}

void test_heap(void) {
    terminal_writestring("\nTesting heap allocator...\n");
    
    // Test basic allocation
    char* str = (char*)kmalloc(32);
    if (str) {
        terminal_writestring("Successfully allocated 32 bytes\n");
        memset(str, 'A', 31);
        str[31] = '\0';
        terminal_writestring("Writing to allocated memory: ");
        terminal_writestring(str);
        terminal_writestring("\n");
        kfree(str);
        terminal_writestring("Memory freed successfully\n");
    }
    
    // Test array allocation and zeroing
    int* numbers = (int*)kcalloc(5, sizeof(int));
    if (numbers) {
        terminal_writestring("Successfully allocated and zeroed array\n");
        // Verify zeroing
        int is_zeroed = 1;
        for (int i = 0; i < 5; i++) {
            if (numbers[i] != 0) {
                is_zeroed = 0;
                break;
            }
        }
        if (is_zeroed) {
            terminal_writestring("Array correctly zeroed\n");
        }
        kfree(numbers);
    }
    
    // Test reallocation
    char* dynamic = (char*)kmalloc(16);
    if (dynamic) {
        terminal_writestring("Testing reallocation...\n");
        memset(dynamic, 'B', 15);
        dynamic[15] = '\0';
        
        dynamic = (char*)krealloc(dynamic, 32);
        if (dynamic) {
            terminal_writestring("Successfully reallocated to 32 bytes\n");
            dynamic[31] = '\0';
            kfree(dynamic);
        }
    }
    
    // Print heap statistics
    char buf[32];
    size_t free_mem = kheap_free_memory();
    size_t used_mem = kheap_used_memory();
    
    terminal_writestring("\nHeap statistics:\n");
    terminal_writestring("Free memory: ");
    itoa(free_mem, buf);
    terminal_writestring(buf);
    terminal_writestring(" bytes\n");
    
    terminal_writestring("Used memory: ");
    itoa(used_mem, buf);
    terminal_writestring(buf);
    terminal_writestring(" bytes\n");
}

// Test interrupt handling
void test_interrupts(void) {
    terminal_writestring("\nTesting interrupt handling...\n");
    
    // Test division by zero (ISR 0)
    terminal_writestring("Testing division by zero exception...\n");
    int a = 10;
    int b = 0;
    int c = a / b;  // This should trigger an exception
    
    // We should never reach here
    terminal_writestring("Failed: Division by zero didn't cause exception!\n");
}

// Test PIT functionality
void test_pit(void) {
    terminal_writestring("\nTesting PIT (Timer)...\n");
    
    // Get initial tick count
    uint32_t initial_ticks = pit_get_tick_count();
    terminal_writestring("Initial tick count: ");
    char tick_str[32];
    itoa(initial_ticks, tick_str);
    terminal_writestring(tick_str);
    terminal_writestring("\n");
    
    // Wait for 1 second
    terminal_writestring("Waiting for 1 second...\n");
    pit_wait(1000);
    
    // Get final tick count
    uint32_t final_ticks = pit_get_tick_count();
    terminal_writestring("Final tick count: ");
    itoa(final_ticks, tick_str);
    terminal_writestring(tick_str);
    terminal_writestring("\n");
    
    // Calculate and display ticks elapsed
    uint32_t ticks_elapsed = final_ticks - initial_ticks;
    terminal_writestring("Ticks elapsed: ");
    itoa(ticks_elapsed, tick_str);
    terminal_writestring(tick_str);
    terminal_writestring("\n");
    
    if (ticks_elapsed >= 100) { // Should be approximately 100 ticks for 1 second
        terminal_writestring("PIT test passed!\n");
    } else {
        terminal_writestring("PIT test failed: incorrect tick count\n");
    }
}

void kernel_main(void) {
    terminal_initialize();
    terminal_writestring("Welcome to your custom OS!\n");
    
    terminal_writestring("Initializing GDT and TSS...\n");
    init_gdt();  // This now includes TSS initialization
    terminal_writestring("GDT and TSS initialized!\n\n");
    
    terminal_writestring("Initializing IDT...\n");
    init_idt();
    terminal_writestring("IDT initialized!\n\n");
    
    terminal_writestring("Initializing interrupt handlers...\n");
    init_interrupt_handlers();
    terminal_writestring("Interrupt handlers initialized!\n\n");
    
    terminal_writestring("Initializing PIT...\n");
    init_pit();
    terminal_writestring("PIT initialized!\n\n");
    
    terminal_writestring("Initializing physical memory manager...\n");
    extern multiboot_info_t* multiboot_info;
    init_pmm(multiboot_info);
    
    size_t free_pages = pmm_get_free_pages();
    char buf[32];
    itoa(free_pages, buf);
    terminal_writestring("Free pages: ");
    terminal_writestring(buf);
    
    terminal_writestring("\nInitializing virtual memory manager...\n");
    init_vmm();
    enable_paging();
    terminal_writestring("Paging enabled successfully!\n");
    
    // Initialize heap after paging is enabled
    terminal_writestring("\nInitializing heap allocator...\n");
    init_heap();
    terminal_writestring("Heap initialized successfully!\n");
    
    // Enable interrupts
    asm volatile("sti");
    
    // Remove the timer test since we have continuous timer display now
    terminal_writestring("\nSystem initialized and running.\n");
    terminal_writestring("Timer ticks will be displayed on the bottom line.\n");
    
    // Main loop - just halt and wait for interrupts
    while(1) {
        asm volatile("hlt");
    }
} 