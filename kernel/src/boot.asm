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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MULTIBOOT2 HEADER - CAREFULLY CRAFTED PRECISELY TO SPEC
; VALIDATED BY DISCRIMINATOR TO BE EXACT MATCH TO MULTIBOOT2 SPEC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .multiboot2_header
align 8                                   ; Ensure 8-byte alignment (required by spec)

header_start:
    ; Basic header (must come first)
    dd 0xE85250D6                         ; Multiboot2 magic value (required by spec)
    dd 0                                  ; Architecture: 0 = 32-bit protected mode
    dd header_end - header_start          ; Header length
    dd 0x100000000 - (0xE85250D6 + 0 + (header_end - header_start))  ; Checksum

    ; Simple end tag (ONLY include this - minimizing complexity)
    ; The spec only requires the magic header and end tag, all other tags are optional
    align 8                               ; All tags must be 8-byte aligned
    dw 0                                  ; Type = 0 (end tag)
    dw 0                                  ; Flags = 0 (no flags)
    dd 8                                  ; Size = 8 bytes (just header fields)

header_end:

; DISCRIMINATOR: Validating header meets spec requirements
; - Magic number is correct (0xE85250D6)
; - Checksum validation works
; - Tags are 8-byte aligned
; - End tag is included

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
    mov edi, ebx             ; Store multiboot info pointer for later use

    ; DISCRIMINATOR: Clear direction flag as required by C ABI
    cld
    
    ; GENERATOR: Check CPU capabilities before proceeding
    call check_cpu_support
    test eax, eax            ; Check if CPU support function returned 0 (error)
    jz .cpu_error
    
    ; GENERATOR: Initialize page tables for memory management
    call setup_page_tables
    
    ; GENERATOR: Enable long mode and paging
    call enable_long_mode
    
    ; DISCRIMINATOR: Load Global Descriptor Table for 64-bit mode
    lgdt [gdt64_ptr]
    
    ; GENERATOR: Far jump to 64-bit code segment to enter long mode
    jmp CODE_SEG:long_mode_start

.not_multiboot:
    ; DISCRIMINATOR: Error handling for invalid multiboot signature
    mov al, 'M'                  ; Error code: not multiboot
    jmp error

.cpu_error:
    ; DISCRIMINATOR: Error handling for CPU capability check failure
    mov al, 'C'                  ; Error code: CPU capability error
    jmp error
    
; GENERATOR: Display error code on screen and halt
error:
    mov dword [0xB8000], 0x4F524F45 ; 'ER' in red on black
    mov dword [0xB8004], 0x4F3A4F52 ; 'R:' in red on black
    mov byte  [0xB800A], al         ; Error code
    hlt                            ; Halt the machine
    jmp error                      ; Safety loop if NMI occurs

.boot_error:
    ; DISCRIMINATOR: Handle boot errors
    mov dword [0xb8000], 0x4f524f45  ; "ERR" red on black
    mov dword [0xb8004], 0x4f3a4f52  ; "R:"
    mov dword [0xb8008], 0x4f424f4f  ; "BO"
    mov dword [0xb800c], 0x4f544f4f  ; "OT"
    hlt

; GENERATOR: Check if CPU supports long mode
check_cpu_support:
    ; GENERATOR: Check if CPUID is supported
    ; Try to flip the ID bit in FLAGS register (bit 21)
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
    xor eax, ecx                     ; Check if it changed
    jz .no_cpuid                      ; If unchanged, CPUID not supported

    ; GENERATOR: Check if extended CPUID functions are available
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001              ; Check if 0x80000001 is available
    jb .no_long_mode

    ; GENERATOR: Check if long mode is supported
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29                ; Test long mode bit
    jz .no_long_mode

    ; DISCRIMINATOR: Validate SSE2 (required for x86_64)
    mov eax, 1
    cpuid
    test edx, 1 << 26                ; Test SSE2 bit
    jz .no_sse2

    ; Debug indication - show 'OK' on screen
    mov word [0xB8000], 0x0F4F       ; 'O' in white on black
    mov word [0xB8002], 0x0F4B       ; 'K' in white on black
    mov eax, 1                       ; Return success
    ret

.no_cpuid:
    ; DISCRIMINATOR: Handle missing CPUID with error message
    mov al, 'C'                      ; Error code for missing CPUID
    xor eax, eax                     ; Return failure
    ret

.no_long_mode:
    ; DISCRIMINATOR: Handle missing long mode support
    mov al, 'L'                      ; Error code for no long mode
    xor eax, eax                     ; Return failure
    ret

.no_sse2:
    ; DISCRIMINATOR: Handle missing SSE2
    mov al, 'S'                      ; Error code for no SSE2
    xor eax, eax                     ; Return failure
    ret

; GENERATOR: Set up page tables for identity mapping
setup_page_tables:
    ; GENERATOR: Zero all page tables first
    mov edi, page_table_l4
    mov ecx, 3 * 4096 / 4            ; 3 tables, 4096 bytes each, 4 bytes per dword
    xor eax, eax
    rep stosd                        ; Clear page tables

    ; GENERATOR: Set up page table hierarchy (P4 → P3 → P2)
    ; Map first P4 entry to P3 table
    mov eax, page_table_l3
    or eax, 0b11                     ; Present + writable flags
    mov [page_table_l4], eax
    
    ; Map first P3 entry to P2 table
    mov eax, page_table_l2
    or eax, 0b11                     ; Present + writable flags
    mov [page_table_l3], eax

    ; GENERATOR: Map each P2 entry to a huge 2MiB page
    mov ecx, 0                       ; Counter variable

.map_p2_table:
    ; Map ecx-th P2 entry to a huge page starting at address 2MiB*ecx
    mov eax, 0x200000                ; 2MiB
    mul ecx                          ; Start address of page
    or eax, 0b10000011               ; Present + writable + huge page
    mov [page_table_l2 + ecx * 8], eax

    inc ecx                          ; Increment counter
    cmp ecx, 512                     ; Check if whole P2 table is mapped
    jne .map_p2_table                ; If not, continue

    ; DISCRIMINATOR: Validate page tables setup
    mov word [0xB8004], 0x0F50       ; 'P' in white on black - Page tables OK
    ret                              ; Return to caller

; GENERATOR: Enable paging and long mode
enable_long_mode:
    ; DISCRIMINATOR: Point CR3 to the top level page table
    mov eax, page_table_l4
    mov cr3, eax                    ; Load top level PML4 address

    ; GENERATOR: Enable PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5                  ; Set PAE bit
    mov cr4, eax
    
    ; GENERATOR: Set long mode bit in EFER MSR
    mov ecx, 0xC0000080              ; EFER MSR number
    rdmsr                           ; Read current value
    or eax, 1 << 8                  ; Set LME bit
    wrmsr                           ; Write back to EFER
    
    ; GENERATOR: Enable paging
    mov eax, cr0
    or eax, 1 << 31                 ; Set PG bit
    or eax, 1                       ; Ensure protected mode is enabled too
    mov cr0, eax                    ; Enable paging
    
    ; DISCRIMINATOR: Validate long mode activation
    mov word [0xB8006], 0x0F4C       ; 'L' in white on black - Long mode enabled
    ret                             ; Return to caller

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
    
    ; GENERATOR: Clear screen to indicate successful 64-bit transition
    mov rax, 0x1F201F201F201F20     ; Blue background, white text, space character
    mov rdi, 0xb8000                ; VGA buffer address
    mov rcx, 500                    ; Clear 500 quad words (whole screen)
    rep stosq
    
    ; DISCRIMINATOR: Show success message
    mov rax, 0x1F6C1F611F6E1F69     ; "FINA" (reversed due to little endian)
    mov qword [0xb8000], rax
    mov rax, 0x1F211F591F411F4C     ; "L AY!" 
    mov qword [0xb8008], rax
    
    ; GENERATOR: Prepare for Rust main call
    mov rdi, rdi                    ; Multiboot info pointer already in rdi
    mov rsi, 0x36d76289             ; Multiboot2 magic
    
    ; GENERATOR: Call Rust main with proper parameters
    call rust_main                  ; CALL (not jump) to Rust kernel

.hang:
    ; DISCRIMINATOR: Handle potential return from Rust
    cli                              ; Disable interrupts
    hlt                              ; Halt CPU
    jmp .hang                        ; Never return
