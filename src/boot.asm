; Multiboot header constants
MBALIGN     equ 1<<0
MEMINFO     equ 1<<1
FLAGS       equ MBALIGN | MEMINFO
MAGIC       equ 0x1BADB002
CHECKSUM    equ -(MAGIC + FLAGS)

section .multiboot
align 4
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

section .bss
align 16
stack_bottom:
    resb 16384 ; 16 KiB
stack_top:

section .data
global multiboot_info
multiboot_info: dd 0

section .text
global start
start:
    ; Save multiboot info pointer
    mov [multiboot_info], ebx

    ; Set up stack
    mov esp, stack_top

    ; Enter high-level kernel
    extern kernel_main
    call kernel_main

    ; Infinite loop if kernel returns
    cli                   ; Disable interrupts
.hang:
    hlt                   ; Halt the CPU
    jmp .hang            ; Jump back to halt if interrupted

; Add IDT setup
setup_idt:
    ; IDT setup code here 