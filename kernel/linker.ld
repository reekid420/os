/* Kernel linker script for x86_64 */
/* Following GAN-inspired dual validation approach */

/* GENERATOR: Define the entry point */
ENTRY(_start)

/* GENERATOR: Define the sections */
SECTIONS {
    /* The kernel will be loaded at 1MB (conventional for bootloaders) */
    . = 1M;

    /* DISCRIMINATOR: Validate multiboot header placement */
    /* Multiboot header must be within the first 8KB of the kernel file */
    .multiboot_header : ALIGN(4) {
        /* Place multiboot header at the beginning */
        KEEP(*(.multiboot_header))
    }

    /* GENERATOR: Text section implementation */
    .text : ALIGN(4K) {
        *(.text .text.*)
        . = ALIGN(4K);
    }

    /* GENERATOR: Readonly data section implementation */
    .rodata : ALIGN(4K) {
        *(.rodata .rodata.*)
        . = ALIGN(4K);
    }

    /* GENERATOR: Data section implementation */
    .data : ALIGN(4K) {
        *(.data .data.*)
        . = ALIGN(4K);
    }

    /* GENERATOR: BSS section implementation */
    .bss : ALIGN(4K) {
        *(.bss .bss.*)
        . = ALIGN(4K);
    }

    /* DISCRIMINATOR: Validate section boundary */
    /* Discard unnecessary sections */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}
