#include "include/stddef.h"
#include "include/stdint.h"
#include "include/mm.h"
#include "include/multiboot.h"
#include "include/vmm.h"
#include "include/gdt.h"
#include "include/tss.h"
#include "include/idt.h"
#include "include/vga.h"

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

void kernel_main(void) {
    terminal_initialize();
    terminal_writestring("Welcome to your custom OS!\n");
    
    terminal_writestring("Initializing GDT and TSS...\n");
    init_gdt();  // This now includes TSS initialization
    terminal_writestring("GDT and TSS initialized!\n\n");
    
    terminal_writestring("Initializing IDT...\n");
    init_idt();
    terminal_writestring("IDT initialized!\n\n");
    
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

    terminal_writestring("Testing CPU features:\n");
    test_tss();
} 