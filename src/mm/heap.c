#include "../include/heap.h"
#include "../include/vmm.h"
#include "../include/string.h"

#define HEAP_MAGIC 0x12345678  // Magic number for block validation

// Global heap structure
static heap_t kernel_heap;

// Helper function to align size to 4 bytes
static uint32_t align_size(uint32_t size) {
    return (size + 3) & ~3;
}

// Helper function to check if a block can be split
static int can_split(block_header_t* block, size_t size) {
    return (block->size - size) >= (HEAP_MIN_BLOCK + sizeof(block_header_t));
}

// Helper function to split a block
static block_header_t* split_block(block_header_t* block, size_t size) {
    // Calculate the size of the new block
    size_t new_size = block->size - size - sizeof(block_header_t);
    
    // Create the new block after the allocated space
    block_header_t* new_block = (block_header_t*)((uint32_t)block + size + sizeof(block_header_t));
    new_block->magic = HEAP_MAGIC;
    new_block->size = new_size;
    new_block->flags = BLOCK_FREE;
    new_block->prev = block;
    new_block->next = block->next;
    
    // Update the original block
    block->size = size;
    block->next = new_block;
    
    // Update the next block's prev pointer if it exists
    if (new_block->next) {
        new_block->next->prev = new_block;
    }
    
    return new_block;
}

// Helper function to merge adjacent free blocks
static block_header_t* merge_blocks(block_header_t* first) {
    if (!first || !first->next || !(first->flags & BLOCK_FREE)) {
        return first;
    }
    
    block_header_t* second = first->next;
    if (!(second->flags & BLOCK_FREE)) {
        return first;
    }
    
    // Merge the blocks
    first->size += sizeof(block_header_t) + second->size;
    first->next = second->next;
    if (second->next) {
        second->next->prev = first;
    }
    
    return first;
}

// Initialize the heap
void init_heap(void) {
    // Initialize heap control structure
    kernel_heap.start_addr = HEAP_START;
    kernel_heap.end_addr = HEAP_START + HEAP_INITIAL_SIZE;
    kernel_heap.max_addr = HEAP_START + HEAP_MAX_SIZE;
    kernel_heap.total_size = HEAP_INITIAL_SIZE;
    kernel_heap.free_size = HEAP_INITIAL_SIZE - sizeof(block_header_t);
    
    // Map initial heap pages
    for (uint32_t addr = HEAP_START; addr < kernel_heap.end_addr; addr += PAGE_SIZE) {
        void* page = pmm_alloc_page();
        if (!page) {
            // Handle allocation failure
            return;
        }
        map_page(page, (void*)addr, PAGE_PRESENT | PAGE_WRITE);
    }
    
    // Create initial block
    kernel_heap.first_block = (block_header_t*)HEAP_START;
    kernel_heap.first_block->magic = HEAP_MAGIC;
    kernel_heap.first_block->size = HEAP_INITIAL_SIZE - sizeof(block_header_t);
    kernel_heap.first_block->flags = BLOCK_FREE;
    kernel_heap.first_block->prev = NULL;
    kernel_heap.first_block->next = NULL;
}

// Allocate memory
void* kmalloc(size_t size) {
    if (size == 0) return NULL;
    
    // Align size to 4 bytes
    size = align_size(size);
    
    // Find a suitable block
    block_header_t* current = kernel_heap.first_block;
    while (current) {
        if (current->magic != HEAP_MAGIC) {
            // Heap corruption detected
            return NULL;
        }
        
        if ((current->flags & BLOCK_FREE) && current->size >= size) {
            // Found a suitable block
            if (can_split(current, size)) {
                split_block(current, size);
            }
            
            current->flags = BLOCK_USED;
            kernel_heap.free_size -= current->size + sizeof(block_header_t);
            
            // Return pointer to usable memory (after header)
            return (void*)((uint32_t)current + sizeof(block_header_t));
        }
        
        current = current->next;
    }
    
    // No suitable block found, try to expand heap
    // TODO: Implement heap expansion
    
    return NULL;
}

// Allocate and zero memory
void* kcalloc(size_t num, size_t size) {
    size_t total = num * size;
    void* ptr = kmalloc(total);
    if (ptr) {
        memset(ptr, 0, total);
    }
    return ptr;
}

// Reallocate memory
void* krealloc(void* ptr, size_t new_size) {
    if (!ptr) return kmalloc(new_size);
    if (new_size == 0) {
        kfree(ptr);
        return NULL;
    }
    
    // Get block header
    block_header_t* block = (block_header_t*)((uint32_t)ptr - sizeof(block_header_t));
    if (block->magic != HEAP_MAGIC) {
        // Invalid pointer or heap corruption
        return NULL;
    }
    
    // If new size fits in current block, we're done
    if (new_size <= block->size) {
        if (can_split(block, new_size)) {
            split_block(block, new_size);
        }
        return ptr;
    }
    
    // Allocate new block
    void* new_ptr = kmalloc(new_size);
    if (!new_ptr) return NULL;
    
    // Copy old data
    memcpy(new_ptr, ptr, block->size);
    kfree(ptr);
    
    return new_ptr;
}

// Free memory
void kfree(void* ptr) {
    if (!ptr) return;
    
    // Get block header
    block_header_t* block = (block_header_t*)((uint32_t)ptr - sizeof(block_header_t));
    if (block->magic != HEAP_MAGIC) {
        // Invalid pointer or heap corruption
        return;
    }
    
    // Mark block as free
    block->flags = BLOCK_FREE;
    kernel_heap.free_size += block->size + sizeof(block_header_t);
    
    // Merge with adjacent free blocks
    if (block->prev) {
        block = merge_blocks(block->prev);
    }
    merge_blocks(block);
}

// Get free memory size
size_t kheap_free_memory(void) {
    return kernel_heap.free_size;
}

// Get used memory size
size_t kheap_used_memory(void) {
    return kernel_heap.total_size - kernel_heap.free_size;
}

// Dump heap information (for debugging)
void kheap_dump_info(void) {
    block_header_t* current = kernel_heap.first_block;
    while (current) {
        // Print block info here
        current = current->next;
    }
} 