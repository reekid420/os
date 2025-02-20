#include "../include/vmm.h"
#include "../include/mm.h"
#include "../include/stdbool.h"

static page_directory_t* current_directory = NULL;

// Convert virtual address to page directory index
static uint32_t virtual_to_dir_index(void* virtual) {
    return (uint32_t)virtual >> 22;
}

// Convert virtual address to page table index
static uint32_t virtual_to_table_index(void* virtual) {
    return ((uint32_t)virtual >> 12) & 0x3FF;
}

void init_vmm(void) {
    // Allocate page directory
    page_directory_t* dir = (page_directory_t*)pmm_alloc_page();
    
    // Clear the directory
    for (int i = 0; i < PAGES_PER_DIR; i++) {
        dir->entries[i] = 0;
    }
    
    current_directory = dir;
}

void map_page(void* physical, void* virtual, uint32_t flags) {
    uint32_t dir_index = virtual_to_dir_index(virtual);
    uint32_t table_index = virtual_to_table_index(virtual);
    
    // Get or create page table
    page_table_t* table;
    if (!(current_directory->entries[dir_index] & PAGE_PRESENT)) {
        table = (page_table_t*)pmm_alloc_page();
        current_directory->entries[dir_index] = ((uint32_t)table) | PAGE_PRESENT | PAGE_WRITE;
        
        // Clear the new table
        for (int i = 0; i < PAGES_PER_TABLE; i++) {
            table->entries[i] = 0;
        }
    } else {
        table = (page_table_t*)(current_directory->entries[dir_index] & ~0xFFF);
    }
    
    // Map the page
    table->entries[table_index] = ((uint32_t)physical) | flags;
}

void unmap_page(void* virtual) {
    uint32_t dir_index = virtual_to_dir_index(virtual);
    uint32_t table_index = virtual_to_table_index(virtual);
    
    if (current_directory->entries[dir_index] & PAGE_PRESENT) {
        page_table_t* table = (page_table_t*)(current_directory->entries[dir_index] & ~0xFFF);
        table->entries[table_index] = 0;
        
        // Check if page table is empty
        bool table_empty = true;
        for (int i = 0; i < PAGES_PER_TABLE; i++) {
            if (table->entries[i] != 0) {
                table_empty = false;
                break;
            }
        }
        
        // If table is empty, free it
        if (table_empty) {
            pmm_free_page(table);
            current_directory->entries[dir_index] = 0;
        }
    }
}

void* get_physical_address(void* virtual) {
    uint32_t dir_index = virtual_to_dir_index(virtual);
    uint32_t table_index = virtual_to_table_index(virtual);
    uint32_t offset = (uint32_t)virtual & 0xFFF;
    
    if (current_directory->entries[dir_index] & PAGE_PRESENT) {
        page_table_t* table = (page_table_t*)(current_directory->entries[dir_index] & ~0xFFF);
        if (table->entries[table_index] & PAGE_PRESENT) {
            return (void*)((table->entries[table_index] & ~0xFFF) | offset);
        }
    }
    return NULL;
}

// This function needs to be called from assembly after setting up CR3
extern void load_page_directory(page_directory_t* dir);
extern void enable_paging_asm(void);

void switch_page_directory(page_directory_t* dir) {
    current_directory = dir;
    load_page_directory(dir);
}

void enable_paging(void) {
    // Identity map the first 16MB for kernel space
    for (uint32_t i = 0; i < 4096; i++) {  // 4096 pages = 16MB
        void* phys = (void*)(i * 4096);
        void* virt = phys;  // Identity mapping
        map_page(phys, virt, PAGE_PRESENT | PAGE_WRITE);
    }
    
    // Map additional 16MB for heap (starting at 16MB)
    for (uint32_t i = 0; i < 4096; i++) {
        void* phys = (void*)((4096 + i) * 4096);  // Start after kernel space
        void* virt = phys;
        map_page(phys, virt, PAGE_PRESENT | PAGE_WRITE);
    }
    
    // Map VGA buffer
    void* vga_phys = (void*)0xB8000;
    void* vga_virt = (void*)0xB8000;
    map_page(vga_phys, vga_virt, PAGE_PRESENT | PAGE_WRITE);
    
    // Load page directory and enable paging
    switch_page_directory(current_directory);
    enable_paging_asm();
} 