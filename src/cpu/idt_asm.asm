global idt_flush

idt_flush:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]  ; Get the pointer to the IDT, passed as a parameter
    lidt [eax]        ; Load the IDT pointer
    pop ebp
    ret

; ISR handlers
global isr0
global isr1
global isr2
global isr3
global isr4
global isr5
global isr6
global isr7
global isr8
global isr9
global isr10
global isr11
global isr12
global isr13
global isr14
global isr15
global isr16
global isr17
global isr18
global isr19
global isr20
global isr21
global isr22
global isr23
global isr24
global isr25
global isr26
global isr27
global isr28
global isr29
global isr30
global isr31

; ISR handlers that don't push an error code by default
%macro ISR_NOERRCODE 1
    isr%1:
        cli
        push byte 0     ; Push dummy error code
        push byte %1    ; Push interrupt number
        jmp isr_common_stub
%endmacro

; ISR handlers that push an error code
%macro ISR_ERRCODE 1
    isr%1:
        cli
        push byte %1    ; Push interrupt number
        jmp isr_common_stub
%endmacro

; Define ISRs
ISR_NOERRCODE 0  ; Division by zero
ISR_NOERRCODE 1  ; Debug
ISR_NOERRCODE 2  ; Non-maskable interrupt
ISR_NOERRCODE 3  ; Breakpoint
ISR_NOERRCODE 4  ; Overflow
ISR_NOERRCODE 5  ; Bound range exceeded
ISR_NOERRCODE 6  ; Invalid opcode
ISR_NOERRCODE 7  ; Device not available
ISR_ERRCODE   8  ; Double fault
ISR_NOERRCODE 9  ; Coprocessor segment overrun
ISR_ERRCODE   10 ; Invalid TSS
ISR_ERRCODE   11 ; Segment not present
ISR_ERRCODE   12 ; Stack-segment fault
ISR_ERRCODE   13 ; General protection fault
ISR_ERRCODE   14 ; Page fault
ISR_NOERRCODE 15 ; Reserved
ISR_NOERRCODE 16 ; x87 FPU error
ISR_ERRCODE   17 ; Alignment check
ISR_NOERRCODE 18 ; Machine check
ISR_NOERRCODE 19 ; SIMD floating-point
ISR_NOERRCODE 20 ; Virtualization
ISR_NOERRCODE 21 ; Reserved
ISR_NOERRCODE 22 ; Reserved
ISR_NOERRCODE 23 ; Reserved
ISR_NOERRCODE 24 ; Reserved
ISR_NOERRCODE 25 ; Reserved
ISR_NOERRCODE 26 ; Reserved
ISR_NOERRCODE 27 ; Reserved
ISR_NOERRCODE 28 ; Reserved
ISR_NOERRCODE 29 ; Reserved
ISR_NOERRCODE 30 ; Reserved
ISR_NOERRCODE 31 ; Reserved

; Common ISR stub
extern isr_handler

isr_common_stub:
    pusha

    mov ax, ds
    push eax

    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call isr_handler

    pop eax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    popa
    add esp, 8
    sti
    iret 