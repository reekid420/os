#ifndef GDT_H
#define GDT_H

#include "stdint.h"

// GDT entry access byte flags
#define GDT_PRESENT        0x80
#define GDT_RING0         0x00
#define GDT_RING3         0x60
#define GDT_SYSTEM        0x10
#define GDT_EXECUTABLE    0x08
#define GDT_READWRITE     0x02
#define GDT_ACCESSED      0x01

// GDT flags
#define GDT_GRANULARITY   0x80
#define GDT_32BIT         0x40

// GDT segment types
#define GDT_CODE_SEGMENT  (GDT_PRESENT | GDT_RING0 | GDT_SYSTEM | GDT_EXECUTABLE | GDT_READWRITE)
#define GDT_DATA_SEGMENT  (GDT_PRESENT | GDT_RING0 | GDT_SYSTEM | GDT_READWRITE)

// GDT entry structure
struct gdt_entry {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t base_middle;
    uint8_t access;
    uint8_t granularity;
    uint8_t base_high;
} __attribute__((packed));

// GDT pointer structure
struct gdt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

// GDT functions
void init_gdt(void);
extern void gdt_flush(uint32_t gdt_ptr);
extern void tss_flush(void);
void gdt_set_gate(int32_t num, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran);

#endif // GDT_H 