# Compiler and flags
ASM=nasm
CC=/usr/bin/gcc
LD=/usr/bin/ld

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

.PHONY: all clean run debug check-deps info

# Default target
all: check-deps $(KERNEL)

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
	@echo "All dependencies found."
	@mkdir -p $(BUILD_DIR)/cpu $(BUILD_DIR)/mm $(BUILD_DIR)/lib $(BUILD_DIR)/drivers

# Link the kernel
$(KERNEL): $(ASM_OBJECTS) $(C_OBJECTS)
	@echo "Linking $@ with objects: $^"
	$(LD) $(LDFLAGS) -o $@ $^
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
	rm -rf $(BUILD_DIR) $(KERNEL)

# Run in QEMU
run: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL)

# Debug in QEMU
debug: $(KERNEL)
	qemu-system-i386 -kernel $(KERNEL) -monitor stdio -d int,cpu_reset -no-reboot

# Show build info
info:
	@echo "Build configuration:"
	@echo "  ASM: $(ASM)"
	@echo "  CC: $(CC)"
	@echo "  LD: $(LD)"
	@echo "\nSource files:"
	@echo "  Assembly sources:"
	@for src in $(ASM_SOURCES); do echo "    $$src"; done
	@echo "\n  C sources:"
	@for src in $(C_SOURCES); do echo "    $$src"; done
	@echo "\nObject files to build:"
	@for obj in $(ASM_OBJECTS) $(C_OBJECTS); do echo "    $$obj"; done 