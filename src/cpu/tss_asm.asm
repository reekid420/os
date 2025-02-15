global tss_flush    ; Allow the C code to call tss_flush()

tss_flush:
    mov ax, 0x2B    ; Load the index of our TSS structure - The index is 0x28, but we set the bottom two bits (CPL 3)
    ltr ax          ; Load 0x2B into the task state register.
    ret 