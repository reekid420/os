; boot.asm - Assembly boot code for kernel
; Following GAN-inspired dual validation approach

; GENERATOR: Start in 32-bit mode as required by multiboot2
bits 32

; DISCRIMINATOR: Export our entry point symbol
global _start

; GENERATOR: Define external Rust entry point
extern rust_main

; STACK SIZE (16kb)
STACK_SIZE       equ 16384

; GENERATOR: Define multiboot2 header for GRUB (must be 8-byte aligned)
section .multiboot_header
align 8
header_start:
    ; DISCRIMINATOR: Basic header fields - must be first
    dd 0xE85250D6                     ; Magic number for multiboot2
    dd 0                              ; Architecture (0 = 32-bit protected mode)
    dd header_end - header_start      ; Header length
    ; Checksum calculation: -(magic + arch + header_length) mod 2^32
    dd 0x100000000 - (0xE85250D6 + 0 + (header_end - header_start))
    
    ; Tags are required by multiboot2 spec
    ; Information request tag
    dw 1        ; type=1 (information request)
    dw 0        ; flags=0
    dd 12       ; size=12 bytes (including this header)
    dd 1        ; Request memory map information
    
    ; Module alignment tag
    dw 6        ; type=6 (module alignment)
    dw 0        ; flags=0
    dd 8        ; size=8 bytes

    ; Minimum required end tag
    dw 0        ; type=0 (end)
    dw 0        ; flags=0
    dd 8        ; size=8 bytes
header_end:

; GENERATOR: GDT for 64-bit mode
section .rodata
align 8
gdt64:
    ; Null descriptor
    dq 0
    ; Code segment descriptor
    dq (1 << 44) | (1 << 47) | (1 << 41) | (1 << 43) | (1 << 53)
    ; Data segment descriptor
    dq (1 << 44) | (1 << 47) | (1 << 41)

; DISCRIMINATOR: Validate GDT structure
gdt64_ptr:
    dw $ - gdt64 - 1                 ; GDT size (16 bits)
    dq gdt64                         ; GDT address (64 bits)

; GENERATOR: Constants for code/data segments
CODE_SEG equ 0x08
DATA_SEG equ 0x10

; GENERATOR: Setup page tables for identity mapping
section .bss
align 4096

; DISCRIMINATOR: Validate page table alignment
page_table_l4:
    resb 4096
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096

; GENERATOR: Stack for kernel initialization
align 16
stack_bottom:
    resb STACK_SIZE                  ; 16 KB stack
stack_top:

; GENERATOR: Kernel entry point
section .text
; GENERATOR: Define the kernel entry point
_start:
    ; DISCRIMINATOR: First validate that we were loaded by multiboot2
    cmp eax, 0x36d76289      ; Check for multiboot2 magic value
    jne .not_multiboot

    ; GENERATOR: Set up the stack before we do anything else
    mov esp, stack_top
    
    ; DISCRIMINATOR: Ensure stack pointer is 16-byte aligned for System V ABI
    and esp, -16             ; Align stack to 16 bytes
    
    ; GENERATOR: Save multiboot info pointer from ebx
    mov edi, ebx             ; Store multiboot info pointer in edi for later

    ; DISCRIMINATOR: Clear direction flag as required by C ABI
    cld
    
    ; GENERATOR: Pass parameters to the Rust kernel entry point
    ; First parameter (rdi in 64-bit, pushed in reverse for 32-bit) - multiboot info ptr
    ; Second parameter (rsi in 64-bit) - multiboot magic number
    push ebx                 ; Multiboot info structure pointer
    push eax                 ; Multiboot magic number
    
    ; GENERATOR: Call Rust kernel entry point
    call rust_main

.halt:
    ; DISCRIMINATOR: We should never return from rust_main, but if we do, halt
    cli                      ; Disable interrupts
    hlt                      ; Halt the CPU
    jmp .halt                ; Jump back to halt if an NMI is fired

.not_multiboot:
    ; GENERATOR: Handle case where kernel was not loaded by multiboot2
    ; This is an error condition - write error code to first VGA text cell
    mov word [0xB8000], 0x4F21  ; '!' in red on black
    jmp .halt

; GENERATOR: Check for CPU capabilities
    call check_cpu_support

    ; GENERATOR: Initialize page tables
    call setup_page_tables

    ; GENERATOR: Enable paging and long mode
    call enable_long_mode

    ; DISCRIMINATOR: Load 64-bit GDT
    lgdt [gdt64_ptr]

    ; GENERATOR: Jump to 64-bit code segment
    jmp CODE_SEG:long_mode_start

.boot_error:
    ; DISCRIMINATOR: Handle boot errors
    mov dword [0xb8000], 0x4f524f45  ; "ERR" red on black
    mov dword [0xb8004], 0x4f3a4f52  ; "R:"
    mov dword [0xb8008], 0x4f424f4f  ; "BO"
    mov dword [0xb800c], 0x4f544f4f  ; "OT"
    hlt

; GENERATOR: Check if CPU supports long mode
check_cpu_support:
    ; CPUID supported?
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21                 ; Flip ID bit
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx                     ; Did it change?
    jz .no_cpuid

    ; Check for long mode support
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001              ; Extended functions available?
    jb .no_long_mode

    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29                ; Long mode bit
    jz .no_long_mode

    ret

.no_cpuid:
    ; DISCRIMINATOR: Handle missing CPUID
    mov dword [0xb8000], 0x4f524f45  ; "ERR" red on black
    mov dword [0xb8004], 0x4f3a4f52  ; "R:"
    mov dword [0xb8008], 0x4f504f43  ; "CP"
    mov dword [0xb800c], 0x4f444f49  ; "ID"
    hlt

.no_long_mode:
    ; DISCRIMINATOR: Handle missing long mode
    mov dword [0xb8000], 0x4f524f45  ; "ERR" red on black
    mov dword [0xb8004], 0x4f3a4f52  ; "R:"
    mov dword [0xb8008], 0x4f364f36  ; "64"
    mov dword [0xb800c], 0x4f544f42  ; "BT"
    hlt

; GENERATOR: Set up page tables for identity mapping
setup_page_tables:
    ; Zero all page tables first
    mov edi, page_table_l4
    mov ecx, 3 * 4096 / 4            ; 3 tables, 4096 bytes each, 4 bytes per dword
    xor eax, eax
    rep stosd

    ; P4[0] -> P3
    mov eax, page_table_l3
    or eax, 0b11                     ; Present, writable
    mov [page_table_l4], eax

    ; P3[0] -> P2
    mov eax, page_table_l2
    or eax, 0b11                     ; Present, writable
    mov [page_table_l3], eax

    ; Map P2 entries to 2MB pages
    mov ecx, 0
.map_p2:
    mov eax, 0x200000                ; 2MB page size
    mul ecx                          ; Calculate physical address
    or eax, 0b10000011               ; Present, writable, huge page
    mov [page_table_l2 + ecx * 8], eax
    inc ecx
    cmp ecx, 512                     ; Map first 1GB (512 entries)
    jne .map_p2

    ret

; GENERATOR: Enable long mode and paging
enable_long_mode:
    ; Set CR3 to point to P4
    mov eax, page_table_l4
    mov cr3, eax

    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5                   ; PAE flag
    mov cr4, eax

    ; Enable long mode
    mov ecx, 0xC0000080               ; EFER MSR
    rdmsr
    or eax, 1 << 8                   ; Long mode bit
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31                  ; Paging bit
    mov cr0, eax

    ret

; GENERATOR: 64-bit mode code
section .text
bits 64
long_mode_start:
    ; GENERATOR: Initialize data segment registers
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; DISCRIMINATOR: Validate successful transition to 64-bit mode
    mov dword [0xb8000], 0x2f592f41  ; "AY" green on black
    mov dword [0xb8004], 0x2f212f21  ; "!!" green on black
    
    ; GENERATOR: Call Rust main function
    ; rdi already contains multiboot info pointer
    ; We need to set rsi to the magic number
    mov rsi, 0x36d76289              ; Multiboot2 magic
    jmp rust_main                    ; Jump to Rust kernel

.hang:
    ; DISCRIMINATOR: Handle potential return from Rust
    cli                              ; Disable interrupts
    hlt                              ; Halt CPU
    jmp .hang                        ; Never return
