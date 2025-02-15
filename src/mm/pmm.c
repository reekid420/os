#include "../include/mm.h"

static struct page* page_array;
static uint32_t total_pages;
static uint32_t free_pages;
static uint32_t kernel_start_page;
static uint32_t kernel_end_page;

// Convert address to page index
static uint32_t addr_to_page_idx(uint64_t addr) {
    return (uint32_t)(addr / PAGE_SIZE);
}

// Convert page index to address
static void* page_idx_to_addr(uint32_t idx) {
    return (void*)(uint32_t)(idx * PAGE_SIZE);
}

void init_pmm(multiboot_info_t* mboot_ptr) {
    // Get memory map from multiboot
    struct multiboot_mmap_entry* mmap = (struct multiboot_mmap_entry*)mboot_ptr->mmap_addr;
    uint32_t mmap_end = mboot_ptr->mmap_addr + mboot_ptr->mmap_length;

    // Find total memory size and calculate total pages
    uint64_t max_addr = 0;
    while ((uint32_t)mmap < mmap_end) {
        if (mmap->type == 1) { // Available memory
            uint64_t end_addr = mmap->addr + mmap->len;
            if (end_addr > max_addr) {
                max_addr = end_addr;
            }
        }
        mmap = (struct multiboot_mmap_entry*)((uint32_t)mmap + mmap->size + sizeof(mmap->size));
    }

    total_pages = addr_to_page_idx(max_addr);
    free_pages = total_pages;

    // Place page array after kernel
    extern uint32_t end; // Defined in linker script
    page_array = (struct page*)&end;
    uint32_t page_array_size = total_pages * sizeof(struct page);

    // Initialize all pages as free
    for (uint32_t i = 0; i < total_pages; i++) {
        page_array[i].flags = PAGE_FREE;
        page_array[i].ref_count = 0;
    }

    // Mark kernel pages as used
    kernel_start_page = addr_to_page_idx(0x100000); // 1MB (kernel start)
    kernel_end_page = addr_to_page_idx((uint32_t)page_array + page_array_size);
    
    for (uint32_t i = kernel_start_page; i < kernel_end_page; i++) {
        page_array[i].flags = PAGE_USED | PAGE_KERNEL;
        page_array[i].ref_count = 1;
        free_pages--;
    }

    // Mark reserved/unusable regions as used
    mmap = (struct multiboot_mmap_entry*)mboot_ptr->mmap_addr;
    while ((uint32_t)mmap < mmap_end) {
        if (mmap->type != 1) { // Not available memory
            uint32_t start_page = addr_to_page_idx(mmap->addr);
            uint32_t end_page = addr_to_page_idx(mmap->addr + mmap->len);
            
            for (uint32_t i = start_page; i < end_page; i++) {
                if (i < total_pages && page_array[i].flags == PAGE_FREE) {
                    page_array[i].flags = PAGE_USED;
                    page_array[i].ref_count = 1;
                    free_pages--;
                }
            }
        }
        mmap = (struct multiboot_mmap_entry*)((uint32_t)mmap + mmap->size + sizeof(mmap->size));
    }
}

void* pmm_alloc_page(void) {
    if (free_pages == 0) {
        return NULL;
    }

    // Find first free page
    for (uint32_t i = kernel_end_page; i < total_pages; i++) {
        if (page_array[i].flags == PAGE_FREE) {
            page_array[i].flags = PAGE_USED;
            page_array[i].ref_count = 1;
            free_pages--;
            return page_idx_to_addr(i);
        }
    }

    return NULL;
}

void pmm_free_page(void* page_addr) {
    uint32_t page_idx = addr_to_page_idx((uint32_t)page_addr);
    
    if (page_idx >= total_pages) {
        return;
    }

    if (page_array[page_idx].ref_count > 0) {
        page_array[page_idx].ref_count--;
        if (page_array[page_idx].ref_count == 0) {
            page_array[page_idx].flags = PAGE_FREE;
            free_pages++;
        }
    }
}

size_t pmm_get_free_pages(void) {
    return free_pages;
} 