#!/bin/bash

# Build script for Rust OS
# Follows the GAN-inspired dual validation system

# --- Generator (Implementation) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUST_TARGET_FILE="$PROJECT_ROOT/x86_64-rust-os.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Discriminator (Validation) ---
# Validate development environment
function validate_environment() {
    echo -e "${BLUE}[Discriminator]${NC} Validating development environment..."
    
    # Check if rustc is installed
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}Error: rustc is not installed.${NC}"
        echo "Please install Rust using rustup: https://rustup.rs/"
        return 1
    fi
    
    # Check if cargo is installed
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}Error: cargo is not installed.${NC}"
        echo "Please install Rust using rustup: https://rustup.rs/"
        return 1
    fi
    
    # Check if nasm is installed
    if ! command -v nasm &> /dev/null; then
        echo -e "${YELLOW}Warning: nasm is not installed.${NC}"
        echo "It will be required for assembly parts. Install using your package manager."
    fi
    
    # Check if lld is available
    if ! rustc --print target-libdir | grep -q "lld"; then
        echo -e "${YELLOW}Warning: lld linker might not be available.${NC}"
        echo "Install the rust-src and lld components using: rustup component add rust-src llvm-tools-preview"
    fi
    
    # Check if custom target file exists
    if [ ! -f "$RUST_TARGET_FILE" ]; then
        echo -e "${RED}Error: Target specification file not found: $RUST_TARGET_FILE${NC}"
        return 1
    fi
    
    return 0
}

# --- Generator (Implementation) ---
# Build the bootloader
function build_bootloader() {
    echo -e "${GREEN}[Generator]${NC} Building UEFI bootloader..."
    
    cd "$PROJECT_ROOT/boot/uefi"
    cargo build -Z build-std=core,alloc,compiler_builtins --target x86_64-unknown-uefi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to build bootloader${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[Discriminator]${NC} Validating UEFI bootloader artifact..."
    if [ ! -f "$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader.efi" ]; then
        echo -e "${YELLOW}Warning: UEFI bootloader was built but not found at expected location${NC}"
        echo -e "${YELLOW}Checking alternative locations...${NC}"
        
        if [ -f "$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader" ]; then
            echo -e "${GREEN}Found UEFI bootloader at alternative location, creating .efi copy${NC}"
            cp "$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader" \
               "$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader.efi"
        else
            echo -e "${RED}UEFI bootloader not found${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}UEFI bootloader built successfully${NC}"
    return 0
}

# Build the kernel
function build_kernel() {
    echo -e "${GREEN}[Generator]${NC} Building kernel..."
    
    cd "$PROJECT_ROOT/kernel"
    rustup component add rust-src
    cargo build -Z build-std=core,alloc,compiler_builtins --target "$PROJECT_ROOT/x86_64-rust-os.json"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to build kernel${NC}"
        return 1
    fi
    
    # *** DISCRIMINATOR: Validate kernel artifact ***
    echo -e "${BLUE}[Discriminator]${NC} Validating kernel artifact..."
    KERNEL_PATH="$PROJECT_ROOT/target/x86_64-rust-os/debug/kernel"
    if [ ! -f "$KERNEL_PATH" ]; then
        echo -e "${RED}Error: Kernel binary not found at expected location: $KERNEL_PATH${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Kernel built successfully${NC}"
    return 0
}

# --- Discriminator (Validation) ---
# Verify build artifacts
function verify_artifacts() {
    echo -e "${BLUE}[Discriminator]${NC} Verifying build artifacts..."
    
    # Verify bootloader artifact
    BOOTLOADER_PATH="$PROJECT_ROOT/target/x86_64-unknown-uefi/debug/uefi-bootloader.efi"
    if [ ! -f "$BOOTLOADER_PATH" ]; then
        echo -e "${RED}Error: UEFI Bootloader artifact not found: $BOOTLOADER_PATH${NC}"
        return 1
    fi
    
    # Verify kernel artifact
    KERNEL_PATH="$PROJECT_ROOT/target/x86_64-rust-os/debug/kernel"
    if [ ! -f "$KERNEL_PATH" ]; then
        echo -e "${RED}Error: Kernel artifact not found: $KERNEL_PATH${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Build artifacts verified successfully.${NC}"
    return 0
}

# --- Main execution flow ---
echo -e "${BLUE}=== Rust OS Build System ===${NC}"
echo -e "${BLUE}GAN-inspired Dual Validation Approach${NC}"

# Validate environment
validate_environment
if [ $? -ne 0 ]; then
    echo -e "${RED}Environment validation failed. Fix the issues and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Environment validation succeeded.${NC}"

# Build bootloader
build_bootloader
if [ $? -ne 0 ]; then
    echo -e "${RED}Bootloader build failed.${NC}"
    exit 1
fi

# Build kernel
build_kernel
if [ $? -ne 0 ]; then
    echo -e "${RED}Kernel build failed.${NC}"
    exit 1
fi

# Verify artifacts
verify_artifacts
if [ $? -ne 0 ]; then
    echo -e "${RED}Artifact verification failed.${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully!${NC}"
echo "To run the OS in QEMU, use: $PROJECT_ROOT/tools/qemu/run.sh"
exit 0
