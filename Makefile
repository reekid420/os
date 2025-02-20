# Compiler and flags
ASM=nasm
CC=/usr/bin/gcc
LD=/usr/bin/ld
RUSTC=/bin/rustc

# Check if we're on a 64-bit system and need multilib
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    # Add multilib flag for 64-bit systems
    MULTILIB=-m32
else
    MULTILIB=
endif

ASMFLAGS=-f elf32
CFLAGS=$(MULTILIB) -nostdlib -nostdinc -fno-builtin -fno-stack-protector -nostartfiles -nodefaultlibs -Wall -Wextra -I$(SRC_DIR)/include -I$(SRC_DIR)
LDFLAGS=-m elf_i386 -T link.ld

# Directories
BUILD_DIR=build
SRC_DIR=src
RUST_DIR=$(SRC_DIR)/rust
RUST_TARGET=i686-unknown-none
RUST_LIB=$(BUILD_DIR)/libos_rust_components.a

# Source files
ASM_SOURCES=$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(SRC_DIR)/mm/*.asm) $(wildcard $(SRC_DIR)/cpu/*.asm)
C_SOURCES=$(wildcard $(SRC_DIR)/*.c) \
         $(wildcard $(SRC_DIR)/mm/*.c) \
         $(wildcard $(SRC_DIR)/cpu/*.c) \
         $(wildcard $(SRC_DIR)/lib/*.c) \
         $(wildcard $(SRC_DIR)/drivers/*.c)

ASM_OBJECTS=$(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.o,$(ASM_SOURCES))
C_OBJECTS=$(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SOURCES))

# Output binary
KERNEL=os.bin

.PHONY: all clean run debug check-deps info rust

# Default target
all: check-deps rust $(KERNEL)

# Check dependencies and create directories
check-deps:
	@echo "Checking build dependencies..."
	@if [ ! -f $(CC) ]; then \
		echo "Error: GCC not found at $(CC)"; \
		echo "Please install build-essential and gcc-multilib"; \
		exit 1; \
	fi
	@if ! which $(ASM) >/dev/null 2>&1; then \
		echo "Error: NASM not found"; \
		echo "Please install nasm"; \
		exit 1; \
	fi
	@if [ ! -f $(LD) ]; then \
		echo "Error: LD not found at $(LD)"; \
		echo "Please install binutils"; \
		exit 1; \
	fi
	@if [ ! -f $(RUSTC) ]; then \
		echo "Error: Rustc not found at $(RUSTC)"; \
		echo "Please install Rust"; \
		exit 1; \
	fi
	@echo "All dependencies found."
	@mkdir -p $(BUILD_DIR)/cpu $(BUILD_DIR)/mm $(BUILD_DIR)/lib $(BUILD_DIR)/drivers

# Build Rust components
rust: $(RUST_DIR)/src/lib/timer.rs
	@echo "Building Rust components..."
	@mkdir -p $(BUILD_DIR)
	cd $(RUST_DIR) && RUSTFLAGS="-C target-cpu=i686" cargo build \
		--target i686-unknown-none.json \
		-Z build-std=core \
		--release
	cp $(RUST_DIR)/target/i686-unknown-none/release/libos_rust_components.a $(BUILD_DIR)/

# Link the kernel
$(KERNEL): $(ASM_OBJECTS) $(C_OBJECTS) rust
	@echo "Linking $@ with objects and Rust library"
	$(LD) $(LDFLAGS) -o $@ $(ASM_OBJECTS) $(C_OBJECTS) $(BUILD_DIR)/libos_rust_components.a
	@echo "Build complete!"

# Compile assembly files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm
	@echo "Compiling ASM $< -> $@"
	@mkdir -p $(dir $@)
	$(ASM) $(ASMFLAGS) $< -o $@

# Compile C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "Compiling C $< -> $@"
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build files
clean:
	@echo "Cleaning build files..."
	rm -rf $(BUILD_DIR) $(KERNEL) *.log

# Run in QEMU
run: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL)

# Debug in QEMU
debug: $(KERNEL)
	@echo "Starting QEMU in debug mode..."
	@rm -f debug.log serial.log debugcon.log
	@echo "=== Debug Session Started: $$(date) ===" > debug.log
	@echo "=== Debug Session Started: $$(date) ===" > serial.log
	qemu-system-i386 -kernel $(KERNEL) \
		-monitor stdio \
		-d cpu_reset,guest_errors,page \
		-D debug.log \
		-no-shutdown \
		-no-reboot \
		-serial file:serial.log \
		-debugcon file:debugcon.log

# Add a new target for full debug output
debug-full: $(KERNEL)
	@echo "Starting QEMU in full debug mode..."
	@rm -f debug-full.log
	@echo "=== Full Debug Session Started: $$(date) ===" > debug-full.log
	qemu-system-i386 -kernel $(KERNEL) \
		-monitor stdio \
		-d int,cpu_reset,guest_errors,page,trace:pit_* \
		-D debug-full.log \
		-no-shutdown \
		-no-reboot

# Show build info
info:
	@echo "Build configuration:"
	@echo "  ASM: $(ASM)"
	@echo "  CC: $(CC)"
	@echo "  LD: $(LD)"
	@echo "  RUSTC: $(RUSTC)"
	@echo "  Rust target: $(RUST_TARGET)"
	@echo "\nSource files:"
	@echo "  Assembly sources:"
	@for src in $(ASM_SOURCES); do echo "    $$src"; done
	@echo "\n  C sources:"
	@for src in $(C_SOURCES); do echo "    $$src"; done
	@echo "\nObject files to build:"
	@for obj in $(ASM_OBJECTS) $(C_OBJECTS); do echo "    $$obj"; done 