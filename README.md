# Custom x86 Operating System

A bare metal operating system implementation focusing on modern OS concepts and clean architecture. This project implements a 32-bit x86 operating system from scratch, including bootloader, kernel, and essential system components.

## 🌟 Features

### Completed
- ✅ Multiboot-compliant bootloader
- ✅ Physical Memory Management (PMM)
- ✅ Virtual Memory Management (VMM)
- ✅ Global Descriptor Table (GDT)
- ✅ Task State Segment (TSS)
- ✅ Basic VGA Driver
- ✅ Basic IDT setup
- ✅ Exception handlers (ISRs 0-31)

### In Progress
- 🔄 IRQ handlers
  - PIC initialization
  - Timer (PIT)
  - Keyboard support
- 🔄 Enhanced VGA driver
- 🔄 Heap allocator

### Planned
- 📋 Process Management
- 📋 File System
- 📋 User Mode Support
- 📋 System Calls
- 📋 Basic Shell
- 📋 Network Stack
- 📋 Multi-core Support

## 🛠 Prerequisites

- GCC with multilib support
- NASM (Netwide Assembler)
- GNU Make
- QEMU for testing
- GNU Binutils

For Arch Linux:
```bash
sudo pacman -S gcc-multilib nasm make qemu binutils
```

## 🚀 Building

1. Clone the repository:
```bash
git clone https://github.com/reekid420/os.git
cd os
```

2. Build the project:
```bash
make
```

3. Run in QEMU:
```bash
make run
```

4. For debugging:
```bash
make debug
```

## 📁 Project Structure

```
.
├── src/
│   ├── boot.asm           # Multiboot bootloader
│   ├── kernel.c           # Kernel entry point
│   ├── cpu/               # CPU-specific code
│   │   ├── gdt.c         # Global Descriptor Table
│   │   ├── idt.c         # Interrupt Descriptor Table
│   │   ├── isr.c         # Interrupt Service Routines
│   │   └── tss.c         # Task State Segment
│   ├── mm/                # Memory Management
│   │   ├── pmm.c         # Physical Memory Manager
│   │   └── vmm.c         # Virtual Memory Manager
│   ├── drivers/           # Device Drivers
│   │   └── vga.c         # VGA Text Mode Driver
│   ├── lib/               # Library Functions
│   │   └── string.c      # String Operations
│   └── include/          # Header Files
├── Makefile              # Build Configuration
└── link.ld              # Linker Script
```

## 🔧 Technical Details

- **Architecture**: x86 (32-bit)
- **Memory Model**: Higher-half kernel
- **Boot Protocol**: Multiboot
- **Memory Management**: Paging enabled, virtual memory support
- **Text Mode**: 80x25 VGA text mode
- **Build System**: GNU Make with cross-compilation support

## 🎯 Current Focus

The project is currently in Phase 1: Core Kernel Infrastructure, focusing on:
1. Completing the IDT implementation
2. Setting up IRQ handlers
3. Implementing the PIC
4. Developing the keyboard driver

## 📚 Development Roadmap

See [roadmap.txt](roadmap.txt) for detailed development phases and progress.

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## ⚖ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The MIT License was chosen because it:
- Requires users to give credit (attribution) when using the code
- Allows others to freely use and modify the code
- Permits commercial use
- Is simple and widely understood
- Has minimal restrictions while protecting the original author

When using this code, you must:
1. Keep the copyright notice
2. Include the MIT License text
3. Give credit to the original author

## 🔍 Code Style

The project follows these development guidelines:
- Modular and reusable code
- Clean separation of concerns
- Consistent naming conventions
- Comprehensive documentation
- Error handling for robustness

## 🐛 Debugging

The project supports debugging through QEMU:
- Monitor interface for system control
- CPU state inspection
- Interrupt debugging
- Memory examination

## 📊 Memory Map

- Kernel starts at 1MB
- VGA buffer at 0xB8000
- Sections:
  - .text (code)
  - .rodata (read-only data)
  - .data (initialized data)
  - .bss (uninitialized data) 