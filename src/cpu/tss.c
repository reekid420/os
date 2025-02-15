#include "../include/tss.h"
#include "../include/gdt.h"
#include "../include/string.h"

static tss_entry_t tss_entry;

void init_tss(uint32_t idx, uint16_t ss0, uint32_t esp0) {
    // Get the address of the TSS
    uint32_t base = (uint32_t)&tss_entry;
    
    // Add the TSS descriptor to the GDT
    gdt_set_gate(idx, base, base + sizeof(tss_entry_t), 0x89, 0x40);
    
    // Zero out the TSS
    memset(&tss_entry, 0, sizeof(tss_entry_t));
    
    // Set up the basic TSS fields
    tss_entry.ss0 = ss0;    // Kernel stack segment
    tss_entry.esp0 = esp0;  // Kernel stack pointer
    
    // Set default segment selectors
    tss_entry.cs = 0x0b;    // Kernel code segment
    tss_entry.ss = tss_entry.ds = tss_entry.es = tss_entry.fs = tss_entry.gs = 0x13; // User data segment
    
    // Set the IO permission bitmap to the end of the TSS
    tss_entry.iomap_base = sizeof(tss_entry_t);
}

void tss_set_stack(uint16_t ss0, uint32_t esp0) {
    tss_entry.ss0 = ss0;
    tss_entry.esp0 = esp0;
}

// Assembly function to load TSS
extern void tss_flush(void); 