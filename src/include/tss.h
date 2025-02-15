#ifndef TSS_H
#define TSS_H

#include "stdint.h"

// TSS structure as per Intel manual
typedef struct tss_entry_struct {
    uint32_t prev_tss;   // Previous TSS - used with hardware task switching
    uint32_t esp0;       // Stack pointer to load when changing to kernel mode
    uint32_t ss0;        // Stack segment to load when changing to kernel mode
    // Unused fields in our implementation - we don't use hardware task switching
    uint32_t esp1;       // Ring 1 stack (unused)
    uint32_t ss1;        // Ring 1 stack segment (unused)
    uint32_t esp2;       // Ring 2 stack (unused)
    uint32_t ss2;        // Ring 2 stack segment (unused)
    uint32_t cr3;        // Page directory base register
    uint32_t eip;
    uint32_t eflags;
    uint32_t eax;
    uint32_t ecx;
    uint32_t edx;
    uint32_t ebx;
    uint32_t esp;
    uint32_t ebp;
    uint32_t esi;
    uint32_t edi;
    uint32_t es;
    uint32_t cs;
    uint32_t ss;
    uint32_t ds;
    uint32_t fs;
    uint32_t gs;
    uint32_t ldt;        // Unused
    uint16_t trap;
    uint16_t iomap_base;
} __attribute__((packed)) tss_entry_t;

// TSS functions
void init_tss(uint32_t idx, uint16_t ss0, uint32_t esp0);
void tss_set_stack(uint16_t ss0, uint32_t esp0);
void tss_flush(void);

#endif // TSS_H 