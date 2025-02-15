#include "../include/gdt.h"
#include "../include/tss.h"

#define GDT_ENTRIES 6

static struct gdt_entry gdt[GDT_ENTRIES];
static struct gdt_ptr gdt_pointer;

// Set up a GDT entry
void gdt_set_gate(int32_t num, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran) {
    gdt[num].base_low = (base & 0xFFFF);
    gdt[num].base_middle = (base >> 16) & 0xFF;
    gdt[num].base_high = (base >> 24) & 0xFF;

    gdt[num].limit_low = (limit & 0xFFFF);
    gdt[num].granularity = ((limit >> 16) & 0x0F) | (gran & 0xF0);

    gdt[num].access = access;
}

void init_gdt(void) {
    // Set up GDT pointer
    gdt_pointer.limit = (sizeof(struct gdt_entry) * GDT_ENTRIES) - 1;
    gdt_pointer.base = (uint32_t)&gdt;

    // Null segment
    gdt_set_gate(0, 0, 0, 0, 0);

    // Code segment
    gdt_set_gate(1, 0, 0xFFFFFFFF, GDT_CODE_SEGMENT, GDT_GRANULARITY | GDT_32BIT);

    // Data segment
    gdt_set_gate(2, 0, 0xFFFFFFFF, GDT_DATA_SEGMENT, GDT_GRANULARITY | GDT_32BIT);

    // User mode code segment
    gdt_set_gate(3, 0, 0xFFFFFFFF, GDT_CODE_SEGMENT | GDT_RING3, GDT_GRANULARITY | GDT_32BIT);

    // User mode data segment
    gdt_set_gate(4, 0, 0xFFFFFFFF, GDT_DATA_SEGMENT | GDT_RING3, GDT_GRANULARITY | GDT_32BIT);

    // Initialize TSS
    init_tss(5, 0x10, 0x0);  // GDT entry 5, kernel data segment 0x10

    // Flush GDT and update segment registers
    gdt_flush((uint32_t)&gdt_pointer);
    tss_flush();  // Load TSS
} 