# Kuasar E2E Testing (Rust-based)

This directory contains the Rust-based end-to-end testing framework for Kuasar, following modern Rust testing patterns and industry best practices.

## Migration from Go to Rust

### Why Rust?

Since Kuasar is primarily a Rust project, it makes sense to have the e2e tests written in Rust as well. This provides several benefits:

- **Consistency**: All code is in the same language as the main project
- **Type Safety**: Better compile-time guarantees and error handling
- **Performance**: Faster test execution and lower resource usage
- **Tooling**: Better integration with existing Rust tooling (cargo, rustfmt, clippy)
- **Dependencies**: No need for additional Go runtime environment

### Migration Summary

The original Go-based tests using Ginkgo/Gomega have been completely replaced with:

- **Rust Test Framework**: Using `tokio::test` for async testing
- **Serial Execution**: Using `serial_test` crate for tests requiring exclusive access
- **Structured Testing**: Clear test modules with proper setup/teardown
- **Binary Runner**: Standalone binary for flexible test execution
- **Native Integration**: Direct integration with Kuasar's Rust ecosystem

## Architecture

### Components

1. **Core Library** (`src/lib.rs`)
   - `E2EContext`: Test context and lifecycle management
   - `E2EConfig`: Configuration and environment handling
   - `TestResult`: Comprehensive test result tracking
   - CRI operations via `crictl` command execution

2. **Binary Runner** (`src/main.rs`)
   - Standalone test runner with comprehensive CLI options
   - Support for parallel and sequential execution
   - Detailed result reporting and error analysis

3. **Test Modules** (`src/tests.rs`)
   - Runtime lifecycle tests for all supported runtimes
   - Integration tests for service interactions
   - Error handling and edge case testing

### Test Structure

```
test/e2e/
├── Cargo.toml              # Rust project configuration
├── src/
│   ├── lib.rs             # Core e2e testing framework
│   ├── main.rs            # Binary test runner
│   └── tests.rs           # Test modules and implementations
└── configs/               # Test configuration files (from migration)
    ├── sandbox-*.yaml     # Sandbox configurations for each runtime
    └── container-*.yaml   # Container configurations for each runtime
```

## Usage

### Prerequisites

- Rust toolchain (rustc, cargo) - already available since this is a Rust project
- `crictl` command-line tool for CRI operations
- Kuasar binaries built and available

### Running Tests

#### Using Makefile (Recommended)

```bash
# Run full end-to-end integration tests (requires environment setup)
make test-e2e

# Run framework unit tests only (no service startup required) 
make test-e2e-framework

# Test specific runtimes
make test-e2e-runc          # Test only runc runtime
make test-e2e-wasm          # Test only wasm runtime  
make test-e2e-resource-slot # Test only resource-slot runtime

# Run tests in parallel
make test-e2e-parallel

# Verify environment setup
make verify-e2e

# Clean test artifacts
make clean-e2e
```

#### Using Binary Runner Directly

```bash
cd test/e2e

# Build the binary
cargo build --release --bin kuasar-e2e

# Run all tests
./target/release/kuasar-e2e

# Test specific runtimes
./target/release/kuasar-e2e --runtime runc,wasm
./target/release/kuasar-e2e --runtime resource-slot

# Run in parallel
./target/release/kuasar-e2e --parallel

# Show help
./target/release/kuasar-e2e --help
```

#### Using Cargo Test

```bash
cd test/e2e

# Run all tests (full e2e integration tests)
cargo test --release -- --test-threads=1 --nocapture

# Run only framework unit tests (no service startup) 
cargo test --release -- --test-threads=1 --nocapture test_invalid_runtime test_service_not_started test_configuration_files test_e2e_context_creation

# Run specific test
cargo test test_runc_runtime_lifecycle --release -- --nocapture

# Run with verbose logging
RUST_LOG=debug cargo test --release -- --test-threads=1 --nocapture
```

#### Using Shell Script

```bash
# Run comprehensive e2e tests
hack/e2e-test.sh

# With custom options
RUNTIME=runc PARALLEL=true LOG_LEVEL=debug hack/e2e-test.sh
```

### Configuration

Environment variables:

- `ARTIFACTS`: Directory for test artifacts (default: temp directory)
- `RUNTIME`: Comma-separated list of runtimes to test (default: `runc,wasm,resource-slot`)
- `PARALLEL`: Enable parallel execution (default: `false`)
- `LOG_LEVEL`: Logging level (`trace`, `debug`, `info`, `warn`, `error`)
- `RUST_LOG`: Rust-specific logging configuration

## Test Coverage

### Runtime Lifecycle Tests

Each supported runtime (runc, wasm, resource-slot) goes through a complete lifecycle test:

1. **Service Startup**: Start the appropriate sandboxer service
2. **Service Readiness**: Wait for service socket to become available
3. **Sandbox Creation**: Create sandbox using runtime-specific configuration
4. **Container Creation**: Create container within the sandbox
5. **Container Start**: Start the container process
6. **State Verification**: Verify container reaches running state
7. **Container Stop**: Gracefully stop the container
8. **State Verification**: Verify container reaches stopped state
9. **Cleanup**: Remove container and sandbox resources

### Integration Tests

- **Service Startup and Readiness**: Verify all services start correctly
- **Configuration Validation**: Ensure all config files exist and are valid
- **Socket Management**: Test socket file creation and permissions
- **Error Scenarios**: Handle and recover from various error conditions

### Test Categories

- **Unit Tests**: Individual component testing within the e2e framework
- **Integration Tests**: Cross-component interaction testing
- **End-to-End Tests**: Full system lifecycle testing
- **Error Handling Tests**: Failure scenario and recovery testing

## Development

### Building and Testing

```bash
# Check compilation without running tests
cargo check

# Build development version
cargo build

# Build optimized release version
cargo build --release

# Run tests with output
cargo test -- --nocapture

# Run specific test with logging
RUST_LOG=debug cargo test test_runc_runtime_lifecycle -- --nocapture
```

### Code Quality

```bash
# Format code
cargo fmt

# Lint code
cargo clippy --all-targets --all-features -- -D warnings

# Generate and view documentation
cargo doc --no-deps --open
```

### Adding New Tests

1. Add test functions to `src/tests.rs` following existing patterns
2. Use `#[tokio::test]` for async tests
3. Use `#[serial]` for tests requiring exclusive resource access
4. Follow the established setup/teardown pattern
5. Use appropriate assertions and comprehensive error handling

### Test Structure Example

```rust
#[tokio::test]
#[serial]
async fn test_new_runtime_lifecycle() {
    info!("Starting new runtime lifecycle test");
    
    let mut ctx = setup_test_context().await;
    ctx.start_services(&["new-runtime"]).await
        .expect("Failed to start new-runtime service");
    
    let result = timeout(TEST_TIMEOUT, ctx.test_runtime("new-runtime")).await
        .expect("Test timed out")
        .expect("Test execution failed");
    
    assert!(result.success, "New runtime test failed: {:?}", result.error);
    assert!(result.sandbox_created, "Sandbox should be created");
    assert!(result.container_running, "Container should reach running state");
    
    info!("New runtime lifecycle test completed successfully");
}
```

## Troubleshooting

### Common Issues

1. **"Go not found" Error**: This is expected and correct - we no longer use Go
2. **Permission Issues**: Ensure proper permissions for socket files and directories
3. **Port/Socket Conflicts**: Clean up any running services before testing
4. **Resource Constraints**: Consider sequential execution on resource-limited systems

### Debugging

```bash
# Enable verbose logging
RUST_LOG=debug cargo test -- --nocapture

# Check running services
systemctl status kuasar-*
ps aux | grep sandboxer

# Check socket files
ls -la /run/kuasar-*.sock

# Clean environment completely
make clean-e2e
pkill -f sandboxer
crictl rm --all --force
crictl rmp --all --force
```

### Artifacts and Logs

Test artifacts are stored in the configured artifacts directory:
- **Service Logs**: Output from sandboxer services
- **Test Execution Logs**: Detailed test execution traces
- **Configuration Dumps**: Copies of configurations used
- **Error Traces**: Detailed error information for failed tests

## Migration Guide

### For Users Familiar with the Go Version

| Go/Ginkgo Pattern | Rust Equivalent |
|-------------------|-----------------|
| `Describe("Component")` | `mod component_tests` |
| `Context("when X")` | Nested test module or test name |
| `It("should do Y")` | `#[tokio::test] async fn test_should_do_y()` |
| `BeforeEach()` | Setup function called in each test |
| `AfterEach()` | Cleanup in test or `Drop` implementation |
| `Eventually()` | Loop with timeout using `tokio::time` |
| `Expect(x).To(Equal(y))` | `assert_eq!(x, y)` |
| `Expect(x).To(BeTrue())` | `assert!(x)` |

### Key Differences

- **No Ginkgo CLI**: Use `cargo test` or the custom binary runner
- **Environment Variables**: Same names, but processed by Rust code
- **Configuration**: Same YAML files, but loaded by Rust serde
- **Execution**: Can use `cargo test` features like `--test-threads` and filters

### Benefits of the Migration

- **Unified Toolchain**: No need to install and manage Go toolchain
- **Better Performance**: Faster compilation and execution
- **Type Safety**: Compile-time guarantees prevent many runtime errors
- **Better Integration**: Native integration with Rust development workflow
- **Simplified Dependencies**: Fewer external dependencies to manage

## Contributing

1. **Follow Rust Conventions**: Use `cargo fmt` and `cargo clippy`
2. **Add Tests**: Every new feature should include corresponding tests
3. **Update Documentation**: Keep README and code comments current
4. **Test Thoroughly**: Ensure all existing tests pass
5. **Use Proper Error Handling**: Follow Rust error handling patterns

For more detailed information, refer to the main Kuasar documentation and Rust development guides.
