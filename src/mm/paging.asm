global load_page_directory
global enable_paging_asm

section .text
load_page_directory:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]    ; Get page directory address
    mov cr3, eax          ; Load page directory
    mov esp, ebp
    pop ebp
    ret

enable_paging_asm:
    push ebp
    mov ebp, esp
    
    mov eax, cr0          ; Get current cr0
    or eax, 0x80000000    ; Set paging bit
    mov cr0, eax          ; Enable paging
    
    mov esp, ebp
    pop ebp
    ret 