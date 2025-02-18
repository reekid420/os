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
    
    // Test virtual memory
    void* virtual_addr = (void*)0x400000;  // 4MB
    void* physical = pmm_alloc_page();
    if (physical) {
        map_page(physical, virtual_addr, PAGE_PRESENT | PAGE_WRITE);
        terminal_writestring("Successfully mapped virtual page!\n");
        
        // Test the mapping
        *(char*)virtual_addr = 'A';  // Write to virtual address
        if (*(char*)virtual_addr == 'A') {
            terminal_writestring("Virtual memory test passed!\n");
        }
        
        unmap_page(virtual_addr);
        pmm_free_page(physical);
    }

    terminal_writestring("\nTesting CPU features:\n");
    test_tss();
    
    // Test heap allocator
    test_heap();
    
    // Test interrupts (this will halt the system due to division by zero)
    test_interrupts();
    
    terminal_writestring("\nAll tests completed!\n");
    
    // Enable interrupts
    asm volatile("sti");
    
    // Main loop
    for(;;) {
        asm volatile("hlt");  // Halt until next interrupt
    }
} 