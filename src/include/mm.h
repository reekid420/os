#ifndef MM_H
#define MM_H

#include "stdint.h"
#include "stddef.h"
#include "multiboot.h"

// Memory management constants
#define PAGE_SIZE 4096
#define PAGE_ALIGN_MASK (PAGE_SIZE - 1)

// Page flags
#define PAGE_FREE       0
#define PAGE_USED      (1 << 0)
#define PAGE_KERNEL    (1 << 1)
#define PAGE_READONLY  (1 << 2)

// Memory map entry from multiboot
struct multiboot_mmap_entry {
    uint32_t size;
    uint64_t addr;
    uint64_t len;
    uint32_t type;
} __attribute__((packed));

// Page structure
struct page {
    uint32_t flags;
    uint32_t ref_count;
};

// Physical memory manager functions
void init_pmm(multiboot_info_t* mboot_ptr);
void* pmm_alloc_page(void);
void pmm_free_page(void* page_addr);
size_t pmm_get_free_pages(void);

#endif // MM_H 