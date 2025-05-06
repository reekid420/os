# Rust OS - 64-bit Operating System

A 64-bit operating system built from scratch using Rust, C++, C, and assembly language.

## Project Overview

This operating system follows a modern design approach using Rust for memory safety and performance, with C++ for specific components, and C/assembly for low-level operations.

- **Primary Languages**: Rust, C++
- **Secondary Languages**: C, Assembly
- **Architecture**: x86_64
- **Testing Environment**: QEMU

## Development Philosophy

Our development follows a dual validation system inspired by GAN architecture:

- **Generator Role**: Implements features, proposes solutions, analyzes requirements
- **Discriminator Role**: Validates implementations, challenges assumptions, identifies issues

Each phase is validated against technical criteria and architectural principles before proceeding.

## Getting Started

### Prerequisites

- Rust and Cargo (latest stable)
- NASM or FASM for assembly
- GCC/Clang for C/C++
- QEMU for testing
- GDB for debugging

### Building the OS

1. Clone the repository
2. Install required Rust components:
   ```
   rustup component add rust-src llvm-tools-preview
   ```
3. Run the build script:
   ```
   ./tools/build/build.sh
   ```

### Running in QEMU

After building, run the OS in QEMU using:
```
./tools/qemu/run.sh
```

Add the `--debug` flag to enable GDB debugging:
```
./tools/qemu/run.sh --debug
```

## Project Structure

```
os/
├── boot/                  # Bootloader code
│   ├── uefi/              # UEFI bootloader implementation
│   └── stage2/            # Second stage loader
├── kernel/                # Kernel implementation
│   ├── arch/              # Architecture-specific code
│   ├── memory/            # Memory management
│   ├── process/           # Process management
│   ├── interrupts/        # Interrupt handling
│   ├── drivers/           # Hardware drivers
│   ├── fs/                # File systems
│   └── ipc/               # Inter-process communication
├── userspace/             # User space code
├── tools/                 # Development tools
├── docs/                  # Documentation
└── tests/                 # System tests
```

## Development Plan

See [OS_Development_Plan.md](OS_Development_Plan.md) for the detailed development plan, which outlines the 5-phase approach to building this operating system.

## Contributing

Please read the Contribution Guidelines in the [OS_Development_Plan.md](OS_Development_Plan.md) document before submitting pull requests.

## License

This project is open source, available under [insert your preferred license].
