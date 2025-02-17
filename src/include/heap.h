#ifndef HEAP_H
#define HEAP_H

#include "stdint.h"
#include "stddef.h"
#include "mm.h"

// Heap configuration
#define HEAP_START      0xD0000000  // Starting virtual address of the heap
#define HEAP_INITIAL_SIZE (1024 * 1024)  // 1MB initial size
#define HEAP_MIN_SIZE     (4 * 1024)     // 4KB minimum size
#define HEAP_MAX_SIZE     (256 * 1024 * 1024)  // 256MB maximum size
#define HEAP_MIN_BLOCK    32  // Minimum block size (including header)

// Block header flags
#define BLOCK_FREE     0
#define BLOCK_USED     1
#define BLOCK_LAST     (1 << 1)

// Block header structure (16 bytes)
typedef struct block_header {
    uint32_t magic;           // Magic number for validation
    uint32_t size;           // Size of the block (including header)
    uint8_t flags;           // Block flags (free/used, last)
    uint8_t reserved[3];     // Reserved for alignment
    struct block_header* prev;  // Previous block in list
    struct block_header* next;  // Next block in list
} __attribute__((packed)) block_header_t;

// Heap control structure
typedef struct {
    uint32_t start_addr;      // Start of heap area
    uint32_t end_addr;        // End of heap area
    uint32_t max_addr;        // Maximum heap address
    uint32_t total_size;      // Total size of heap
    uint32_t free_size;       // Total free space
    block_header_t* first_block;  // First block in the heap
} heap_t;

// Heap functions
void init_heap(void);
void* kmalloc(size_t size);
void* kcalloc(size_t num, size_t size);
void* krealloc(void* ptr, size_t new_size);
void kfree(void* ptr);

// Helper functions
size_t kheap_free_memory(void);
size_t kheap_used_memory(void);
void kheap_dump_info(void);  // For debugging

#endif // HEAP_H 