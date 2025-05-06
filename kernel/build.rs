// build.rs - Kernel build script
// Following GAN-inspired dual validation approach

use std::env;
use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    // GENERATOR: Tell Cargo to rerun this script if any of these files change
    println!("cargo:rerun-if-changed=linker.ld");
    println!("cargo:rerun-if-changed=src/boot.asm");
    
    // GENERATOR: Set the linker script path
    let cargo_manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let linker_path_str = format!("{}/linker.ld", cargo_manifest_dir);
    let linker_script = Path::new(&linker_path_str);
    
    // DISCRIMINATOR: Validate linker script exists
    if !linker_script.exists() {
        panic!("Error: Linker script not found at {}", linker_script.display());
    }
    
    // DISCRIMINATOR: Validate target architecture
    #[cfg(not(target_arch = "x86_64"))]
    compile_error!("Kernel must be compiled for x86_64 architecture");
    
    // GENERATOR: Tell cargo to use our linker script
    println!("cargo:rustc-link-arg=-T{}", linker_script.display());
    
    // DISCRIMINATOR: Validate that assembly files are built correctly
    let boot_asm_path = Path::new(&cargo_manifest_dir).join("src").join("boot.asm");
    
    // Make sure the boot.asm file exists
    if !boot_asm_path.exists() {
        panic!("Error: boot.asm file not found at {}", boot_asm_path.display());
    }
    
    // Generate a more detailed debug message
    println!("cargo:warning=Building assembly bootcode: {}", boot_asm_path.display());
    
    // Compile the assembly code
    compile_boot_assembly(boot_asm_path);
    
    // Specify the object file to link
    let out_dir = env::var("OUT_DIR").unwrap();
    println!("cargo:rustc-link-arg={}/boot.o", out_dir);
    
    // DISCRIMINATOR: Set validation flags - use direct LLD flags
    println!("cargo:rustc-link-arg=--gc-sections");
    println!("cargo:rustc-link-arg=--entry=_start");
    
    // Print debug information
    println!("cargo:warning=Linker script: {}", linker_script.display());
    println!("cargo:warning=Assembly output: {}/boot.o", out_dir);
}

// GENERATOR: Compile the assembly boot code
fn compile_boot_assembly(boot_asm_path: PathBuf) {
    let out_dir = env::var("OUT_DIR").unwrap();
    
    // DISCRIMINATOR: Validate input parameters
    if !boot_asm_path.exists() {
        panic!("Assembly file not found at: {}", boot_asm_path.display());
    }
    
    // Determine appropriate assembler based on host platform
    let nasm_command = if cfg!(target_os = "windows") { "nasm.exe" } else { "nasm" };
    
    // Execute NASM to assemble the boot code
    let output = Command::new(nasm_command)
        .args([
            "-f", "elf64",              // Output format: 64-bit ELF
            "-o", &format!("{}/boot.o", out_dir), // Output file
            boot_asm_path.to_str().unwrap()   // Input assembly file
        ])
        .output()
        .expect("Failed to execute nasm");
    
    // DISCRIMINATOR: Validate assembly process
    if !output.status.success() {
        // Print the error message from nasm
        panic!(
            "Failed to assemble boot.asm:\n{}\n{}", 
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
    }
    
    // Build successful, print object file location
    println!("cargo:warning=Assembly object file created at: {}/boot.o", out_dir);
}
