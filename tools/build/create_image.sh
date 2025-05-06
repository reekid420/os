#!/bin/bash

# Create bootable ISO script
# Following GAN-inspired dual validation approach

# --- Generator (Implementation) ---
# Environment setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KERNEL_BIN="$PROJECT_ROOT/target/x86_64-rust-os/debug/kernel"
ISO_DIR="$PROJECT_ROOT/target/bootable/iso"
IMG_DIR="$PROJECT_ROOT/target/bootable"
ISO_FILE="$IMG_DIR/os.iso"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Discriminator (Validation) ---
# Validate prerequisites
echo -e "${BLUE}[Discriminator]${NC} Validating prerequisites..."

# Check for required tools
if ! command -v grub-mkrescue &> /dev/null; then
    echo -e "${RED}Error: grub-mkrescue not found. Install with: sudo apt-get install grub-common grub-pc-bin${NC}"
    exit 1
fi

if ! command -v xorriso &> /dev/null; then
    echo -e "${RED}Error: xorriso not found. Install with: sudo apt-get install xorriso${NC}"
    exit 1
fi

# Verify kernel exists
if [ ! -f "$KERNEL_BIN" ]; then
    echo -e "${RED}Error: Kernel binary not found. Please build the kernel first.${NC}"
    echo "Run: ./tools/build/build.sh"
    exit 1
fi

# --- Generator (Implementation) ---
# Clean up previous files
rm -rf "$ISO_DIR" "$ISO_FILE"
mkdir -p "$ISO_DIR/boot/grub"

# Copy kernel binary
echo -e "${GREEN}[Generator]${NC} Setting up boot environment..."
cp "$KERNEL_BIN" "$ISO_DIR/boot/kernel"

# Create multiboot-compatible GRUB configuration
echo -e "${GREEN}Creating GRUB configuration...${NC}"
cat > "$ISO_DIR/boot/grub/grub.cfg" << EOF
# GRUB configuration for RustOS
# Generator Role: GRUB bootloader configuration
# Discriminator Role: Validate multiboot2 protocol compliance

# Reduce timeout for faster development cycle
set timeout=1
set default=0

# Enable serial console for debugging
terminal_input serial
terminal_output serial
serial --unit=0 --speed=115200

# Boot entry for our kernel
menuentry "RustOS - Multiboot2" {
    # Use multiboot2 protocol to load the kernel
    # This ensures proper parameter passing to _start
    echo "Loading RustOS kernel with multiboot2 protocol..."
    multiboot2 /boot/kernel
    
    # Additional modules could be loaded here in the future
    # module2 /path/to/module modulename
    
    # Start execution
    boot
}
EOF

# Generate ISO with GRUB - verbose output to debug issues
echo -e "${GREEN}Creating bootable ISO with GRUB...${NC}"
grub-mkrescue -o "$ISO_FILE" "$ISO_DIR" -v

# --- Discriminator (Validation) ---
echo -e "${BLUE}[Discriminator]${NC} Validating bootable media..."

# Check if ISO was created
if [ -f "$ISO_FILE" ]; then
    echo -e "${GREEN}ISO file successfully created: $ISO_FILE${NC}"
    echo -e "${GREEN}ISO Size: $(du -h "$ISO_FILE" | cut -f1)${NC}"
    
    # Symbolic link for QEMU script compatibility
    ln -sf "$ISO_FILE" "$IMG_DIR/disk.img" 2>/dev/null
else
    echo -e "${RED}ERROR: Failed to create bootable ISO!${NC}"
    exit 1
fi

exit 0
