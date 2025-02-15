# Project Focus: os

**Current Goal:** Project directory structure and information

**Key Components:**
├─ 📄 Focus.md
├─ 📄 LICENSE
├─ 📄 Makefile
├─ 📄 README.md
├─ 📄 link.ld
├─ 📄 os.bin
├─ 📄 roadmap.txt
└─ 📁 src
   ├─ 📄 boot.asm
   ├─ 📄 kernel.c
   ├─ 📁 cpu
   │  ├─ 📄 gdt.c
   │  ├─ 📄 gdt_asm.asm
   │  ├─ 📄 idt.c
   │  ├─ 📄 idt_asm.asm
   │  ├─ 📄 isr.c
   │  ├─ 📄 tss.c
   │  └─ 📄 tss_asm.asm
   ├─ 📁 drivers
   │  ├─ 📄 vga.c
   │  └─ 📄 vga.h
   ├─ 📁 include
   │  ├─ 📄 gdt.h
   │  ├─ 📄 idt.h
   │  ├─ 📄 isr.h
   │  ├─ 📄 mm.h
   │  ├─ 📄 multiboot.h
   │  ├─ 📄 stdbool.h
   │  ├─ 📄 stddef.h
   │  ├─ 📄 stdint.h
   │  ├─ 📄 string.h
   │  ├─ 📄 tss.h
   │  ├─ 📄 vga.h
   │  └─ 📄 vmm.h
   ├─ 📁 lib
   │  └─ 📄 string.c
   └─ 📁 mm
      ├─ 📄 paging.asm
      ├─ 📄 pmm.c
      └─ 📄 vmm.c

**Project Context:**
Type: File and directory tracking
Target Users: Users of os
Main Functionality: Project directory structure and information
Key Requirements:
- Type: Generic Project
- File and directory tracking
- Automatic updates

**Development Guidelines:**
- Keep code modular and reusable
- Follow best practices for the project type
- Maintain clean separation of concerns

# File Analysis
`src/kernel.c` (74 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<test_tss>: This function validates input | Takes void
<kernel_main>: This function validates input | Takes void

`src/cpu/gdt.c` (47 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<gdt_set_gate>: Takes int32 t num and uint32 t base and uint32 t limit and uint8 t access and uint8 t gran
<init_gdt>: Creates gdt | Takes void

`src/cpu/idt.c` (60 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<init_idt>: Creates idt | Takes void
<idt_set_gate>: Takes uint8 t num and uint32 t base and uint16 t selector and uint8 t flags

`src/cpu/isr.c` (52 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<isr_handler>: This function validates regs.int_no < 32 | Takes registers t regs | Ensures int_no < 32

`src/cpu/tss.c` (35 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<init_tss>: Creates tss | Takes uint32 t idx and uint16 t ss0 and uint32 t esp0
<tss_set_stack>: Takes uint16 t ss0 and uint32 t esp0

`src/drivers/vga.c` (93 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<vga_entry_color>: Takes enum vga color fg and enum vga color bg | Returns fg | bg << 4
<vga_entry>: Takes unsigned char uc and uint8 t color | Returns (uint16_t) uc | (uint16_t) color << 8
<terminal_initialize>: Takes void
<terminal_putentryat>: Takes char c and uint8 t color and size t x and size t y
<terminal_putchar>: Takes char c
<terminal_writestring>: Takes const char* data
<itoa>: Takes int num and char* str | Ensures num < 0

`src/drivers/vga.h` (7 lines)
**Main Responsibilities:** Project file

`src/include/gdt.h` (45 lines)
**Main Responsibilities:** Project file

`src/include/isr.h` (54 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<declarations>: Takes void

`src/include/mm.h` (38 lines)
**Main Responsibilities:** Project file

`src/include/multiboot.h` (32 lines)
**Main Responsibilities:** Project file

`src/include/stdbool.h` (9 lines)
**Main Responsibilities:** Project file

`src/include/stddef.h` (9 lines)
**Main Responsibilities:** Project file

`src/include/stdint.h` (16 lines)
**Main Responsibilities:** Project file

`src/include/string.h` (9 lines)
**Main Responsibilities:** Project file

`src/include/tss.h` (43 lines)
**Main Responsibilities:** Project file

`src/include/vga.h` (34 lines)
**Main Responsibilities:** Project file

`src/include/vmm.h` (40 lines)
**Main Responsibilities:** Project file

`src/lib/string.c` (16 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<memset>: Takes void* dest and int val and size t len | Returns dest
<memcpy>: Takes void* dest and const void* src and size t len | Returns dest

`src/mm/pmm.c` (115 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<addr_to_page_idx>: Takes uint64 t addr | Returns (uint32_t)(addr / PAGE_SIZE)
<page_idx_to_addr>: Takes uint32 t idx | Returns (void*)(uint32_t)(idx * PAGE_SIZE)
<init_pmm>: Creates pmm | Takes multiboot info t* mboot ptr
<pmm_alloc_page>: Takes void | Returns NULL
<pmm_free_page>: Takes void* page addr | Ensures ref_count > 0
<pmm_get_free_pages>: Takes void | Returns free_pages

`src/mm/vmm.c` (110 lines)
**Main Responsibilities:** Project file
**Key Functions:**
<virtual_to_dir_index>: Takes void* virtual | Returns (uint32_t)virtual >> 22
<virtual_to_table_index>: Takes void* virtual | Returns ((uint32_t)virtual >> 12) & 0x3FF
<init_vmm>: Creates vmm | Takes void
<map_page>: Takes void* physical and void* virtual and uint32 t flags
<unmap_page>: This function validates table->entries[i] not = 0 | Takes void* virtual
<get_physical_address>: Retrieves physical address data | Takes void* virtual | Returns NULL
<needs>: Takes page directory t* dir
<switch_page_directory>: Takes page directory t* dir
<enable_paging>: Takes void | Ensures i < 1024

# Project Metrics Summary
Total Files: 31
Total Lines: 938

**Files by Type:**
- .c: 9 files (602 lines)
- .h: 12 files (336 lines)

**Code Quality Alerts:**
- 🚨 Severe Length Issues: 0 files
- ⚠️ Critical Length Issues: 0 files
- 📄 Length Warnings: 0 files
- 🔄 Duplicate Functions: 0

Last updated: February 15, 2025 at 03:55 PM