#!/bin/bash

# QEMU run script for Rust OS
# Part of the GAN-inspired dual validation system

# --- Generator (Implementation) ---
# Set up environment variables and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KERNEL_BIN="$PROJECT_ROOT/target/x86_64-rust-os/debug/kernel"
BOOTLOADER="$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader.efi"
OVMF_DIR="$PROJECT_ROOT/tools/qemu/OVMF"
EFI_DIR="$PROJECT_ROOT/target/uefi-disk"
DISK_IMG="$PROJECT_ROOT/target/bootable/disk.img"
QEMU_ARGS=""

# --- Discriminator (Validation) ---
# Validate build artifacts exist
function validate_build() {
    echo "Validating build artifacts..."
    
    if [ ! -f "$KERNEL_BIN" ]; then
        echo "Error: Kernel binary not found. Please build the kernel first."
        echo "Run: ./tools/build/build.sh"
        return 1
    fi
    
    # Check if disk image exists, if not create it
    if [ ! -f "$DISK_IMG" ]; then
        echo "Disk image not found. Creating bootable disk image..."
        "$PROJECT_ROOT/tools/build/create_image.sh"
        
        if [ $? -ne 0 ]; then
            echo "Failed to create disk image. Aborting."
            return 1
        fi
    fi
    
    # Generator: Print summary information
    echo "Using kernel: $KERNEL_BIN"
    echo "Using disk image: $DISK_IMG"
    
    return 0
}

# No additional helper functions needed for disk image approach

# --- Generator (Implementation) ---
# Parse command line arguments
function parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                QEMU_ARGS="$QEMU_ARGS -s -S"
                shift
                ;;
            --graphics)
                # Default is to use graphics
                shift
                ;;
            --no-graphics)
                QEMU_ARGS="$QEMU_ARGS -nographic"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: $0 [--debug] [--no-graphics]"
                exit 1
                ;;
        esac
    done
}

# Run QEMU with the appropriate arguments
function run_qemu() {
    echo "Starting QEMU with direct kernel boot..."
    echo "Note: Using simplified approach without UEFI for now"
    
    # Generator Role: Boot from ISO file with GRUB bootloader
    ISO_FILE="$PROJECT_ROOT/target/bootable/os.iso"
    
    if [ ! -f "$ISO_FILE" ]; then
        echo "Creating bootable ISO..."
        "$PROJECT_ROOT/tools/build/create_image.sh"
        
        if [ $? -ne 0 ] || [ ! -f "$ISO_FILE" ]; then
            echo "Failed to create bootable ISO. Aborting."
            return 1
        fi
    fi
    
    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"
    
    # Clear previous logs
    LOG_DIR="$PROJECT_ROOT/logs"
    QEMU_LOG="$LOG_DIR/qemu_debug.log"
    KERNEL_LOG="$LOG_DIR/kernel.log"
    
    echo "" > "$QEMU_LOG"
    echo "" > "$KERNEL_LOG"
    
    # Generator Role: More verbose debugging for QEMU
    echo "Booting from ISO file: $ISO_FILE with enhanced debugging"
    
    qemu-system-x86_64 \
        -cdrom "$ISO_FILE" \
        -serial file:$KERNEL_LOG \
        -display gtk \
        -machine q35 \
        -m 4G \
        -cpu qemu64 \
        -smp 4 \
        -d int,cpu_reset,guest_errors,page,trace:multiboot_load_os \
        -D "$QEMU_LOG" \
        -no-reboot \
        -debugcon file:"$LOG_DIR/debugcon.log" \
        -global isa-debugcon.iobase=0x402 \
        -monitor stdio \
        -device qemu-xhci \
        -device usb-kbd \
        -device usb-mouse \
        -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
        $QEMU_ARGS
        
    # Discriminator Role: Validate boot outcome
    echo "QEMU exited with code $?"
    echo "Debug logs saved to: $LOG_DIR/"
    echo "Analyzing logs for kernel boot issues..."
    
    if grep -q "error" "$QEMU_LOG"; then
        echo -e "\e[31mErrors found in QEMU log:\e[0m"
        grep -A 2 -B 2 "error" "$QEMU_LOG"
    else
        echo "No explicit errors found in QEMU log."
    fi
        
    # Discriminator Role: Validate exit status
    exit_code=$?
    
    # QEMU returns 1 if exited by isa-debug-exit
    if [ $exit_code -eq 1 ]; then
        echo "QEMU exited successfully (via debug exit)"
        exit 0
    elif [ $exit_code -ne 0 ]; then
        echo "QEMU exited with an error: $exit_code"
        exit $exit_code
    fi
}

# --- Discriminator (Validation) ---
# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "Error: qemu-system-x86_64 is not installed."
    echo "Please install QEMU using your package manager."
    exit 1
fi

# --- Main execution flow ---
# Parse arguments
parse_args "$@"

# Validate build artifacts
validate_build
if [ $? -ne 0 ]; then
    exit 1
fi

# Run QEMU
run_qemu
