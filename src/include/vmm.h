#ifndef VMM_H
#define VMM_H

#include "stdint.h"
#include "stddef.h"

// Page directory/table entry flags
#define PAGE_PRESENT        (1 << 0)
#define PAGE_WRITE         (1 << 1)
#define PAGE_USER          (1 << 2)
#define PAGE_WRITETHROUGH  (1 << 3)
#define PAGE_CACHE_DISABLE (1 << 4)
#define PAGE_ACCESSED      (1 << 5)
#define PAGE_DIRTY         (1 << 6)
#define PAGE_GLOBAL        (1 << 8)

// Page directory and table structures
typedef uint32_t page_directory_entry_t;
typedef uint32_t page_table_entry_t;

#define PAGES_PER_TABLE 1024
#define PAGES_PER_DIR   1024

typedef struct {
    page_table_entry_t entries[PAGES_PER_TABLE];
} page_table_t;

typedef struct {
    page_directory_entry_t entries[PAGES_PER_DIR];
} page_directory_t;

// VMM functions
void init_vmm(void);
void switch_page_directory(page_directory_t* dir);
void map_page(void* physical, void* virtual, uint32_t flags);
void unmap_page(void* virtual);
void* get_physical_address(void* virtual);
void enable_paging(void);

#endif // VMM_H 