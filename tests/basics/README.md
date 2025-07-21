# Kuasar Test Files Documentation

This directory contains configuration files and scripts for testing different Kuasar runtimes.

## File Structure

### Sandbox Configuration Files (CRI YAML)
- `sandbox-runc.yaml` - runc sandbox configuration
- `sandbox-resource-slot.yaml` - resource-slot sandbox configuration
- `sandbox-wasmedge.yaml` - wasmEdge sandbox configuration

### Container Configuration Files (CRI YAML)
- `container-runc.yaml` - runc container configuration
- `container-resource-slot.yaml` - resource-slot container configuration
- `container-wasmedge.yaml` - wasmEdge container configuration

### Test Scripts
- `local-up-kuasar.sh` - Local startup of Kuasar services for e2e testing
- `test-kuasar.sh` - Main test script, tests all three runtimes simultaneously
- `test-runc.sh` - Test runc runtime independently
- `test-resource-slot.sh` - Test resource-slot runtime independently
- `test-wasmedge.sh` - Test wasmEdge runtime independently
- `quick-test.sh` - Quick functionality verification script

## Usage

### Manual e2e Testing Process

1. **Start Kuasar Services**
```bash
cd /path/to/kuasar/tests/basics

# Start all default components (runc, wasm, resource-slot)
./local-up-kuasar.sh

# Start only specified components
./local-up-kuasar.sh -c runc,resource-slot

# View help
./local-up-kuasar.sh --help
```

2. **Run tests in another terminal**
```bash
cd /path/to/kuasar/tests/basics
./test-runc.sh
./test-resource-slot.sh
```

3. **Stop services**: Press `Ctrl+C` in the startup script terminal

### Run Complete Tests
```bash
cd /path/to/kuasar/tests/basics
chmod +x *.sh
./test-kuasar.sh
```

### Run Individual Tests
```bash
./test-runc.sh           # Test runc runtime
./test-resource-slot.sh  # Test resource-slot runtime
./test-wasmedge.sh       # Test wasmEdge runtime
```

### Manual crictl Commands
```bash
# Create and run runc application
crictl runp sandbox-runc.yaml
crictl create <sandbox-id> container-runc.yaml sandbox-runc.yaml
crictl start <container-id>

# View status
crictl pods
crictl ps
crictl stats

# Cleanup
crictl stop <container-id>
crictl rm <container-id>
crictl stopp <sandbox-id>
crictl rmp <sandbox-id>
```

## Resource Configuration

| Runtime Type | CPU Limit | Memory Limit | Purpose |
|--------------|-----------|--------------|---------|
| runc | 0.5 CPU | 100MB | Standard container runtime |
| resource-slot | 1 CPU | 512MB | Resource slot sandbox |
| wasmEdge | 0.1 CPU | 100MB | WebAssembly runtime |

## local-up-kuasar.sh Script Documentation

### Features
- Automatically check runtime dependencies (Rust, runc, crictl, etc.)
- **Provide detailed dependency installation instructions**
- Support selective compilation and startup of components
- Automatic cleanup of processes and temporary files
- Provide detailed log output
- Support debug mode

### Usage Parameters
```bash
./local-up-kuasar.sh [OPTIONS]

Options:
  -c, --components COMPONENTS   Specify components to compile and start, comma-separated
                               Available values: runc,wasm,resource-slot,vmm,quark
                               Default: runc,wasm,resource-slot
  -h, --help                   Show help information
  --skip-build                 Skip compilation step, start existing binaries directly
  --debug                      Enable debug mode
  --check-deps                 Only check dependencies, do not compile and start
```

### Usage Examples
```bash
# Use default components
./local-up-kuasar.sh

# Start only runc and resource-slot
./local-up-kuasar.sh -c runc,resource-slot

# Skip compilation, start directly
./local-up-kuasar.sh --skip-build

# Debug mode
./local-up-kuasar.sh --debug

# Check dependencies only
./local-up-kuasar.sh --check-deps
```

### Dependency Management

The script automatically checks the following dependencies and provides detailed installation instructions:

**Required Dependencies:**
- `cargo`, `rustc` - Rust toolchain
- `make`, `gcc`, `pkg-config` - Compilation tools
- `crictl` - CRI client tool
- `runc` - Container runtime (when runc component is selected)

**Optional Dependencies:**
- `containerd` - Container runtime
- `wasmedge`/`wasmtime` - WebAssembly runtime (when wasm component is selected)
- `qemu-system-x86_64` - Virtual machine manager (when vmm component is selected)

When missing dependencies are found, the script displays installation commands for different operating systems.

## Notes

1. Ensure Kuasar runtimes are properly installed and configured
2. Ensure crictl tool is installed and configured
3. Ensure sufficient permissions for container operations
4. Test scripts will automatically clean up created resources
5. If tests fail, check Kuasar service status and logs
