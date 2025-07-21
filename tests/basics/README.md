# Kuasar Test Migration Notice

**NOTICE: Test files have been reorganized to follow Kubernetes e2e testing patterns.**

## New Structure

The test files have been moved and restructured as follows:

- **E2E Tests:** `test/e2e/` - Ginkgo/Gomega-based e2e test suite
- **Setup Scripts:** `hack/local-up-kuasar.sh` - Moved to hack directory
- **Configuration Files:** `test/e2e/configs/` - YAML configs for testing
- **Legacy Scripts:** Removed - functionality integrated into e2e framework

## Running Tests

### New E2E Framework (Recommended)

Use the new e2e testing framework:

```bash
# Run all e2e tests
make -f Makefile.e2e test-e2e

# Run specific runtime tests
make -f Makefile.e2e test-e2e-runc
make -f Makefile.e2e test-e2e-wasm
make -f Makefile.e2e test-e2e-resource-slot

# Start local cluster for manual testing
make -f Makefile.e2e local-up
```

### Manual Testing

Start Kuasar services manually:

```bash
# Start all default components (runc, wasm, resource-slot)
hack/local-up-kuasar.sh

# Start only specified components
hack/local-up-kuasar.sh --components runc,resource-slot

# View help
hack/local-up-kuasar.sh --help
```

### Legacy Test Scripts

The individual test scripts (`test-*.sh`) have been replaced by the unified e2e framework. 
For equivalent functionality:

- `test-runc.sh` → `make -f Makefile.e2e test-e2e-runc`
- `test-wasmedge.sh` → `make -f Makefile.e2e test-e2e-wasm`  
- `test-resource-slot.sh` → `make -f Makefile.e2e test-e2e-resource-slot`
- `test-kuasar.sh` → `make -f Makefile.e2e test-e2e`

## Migration Benefits

The new structure provides:

- **Kubernetes-style testing** using Ginkgo/Gomega framework
- **Better CI/CD integration** with JUnit XML reporting
- **Parallel test execution** for faster feedback
- **Comprehensive test lifecycle management**
- **Improved error handling and cleanup**
- **Standardized logging and debugging**

## Documentation

For detailed information about the new testing framework, see:
- `test/e2e/README.md` - Complete e2e testing guide
- `hack/e2e-test.sh --help` - Test runner options
- `hack/local-up-kuasar.sh --help` - Cluster setup options

## Configuration Files

Test configurations are now located in `test/e2e/configs/`:

| File | Purpose |
|------|---------|
| `sandbox-runc.yaml` | runc sandbox configuration |
| `container-runc.yaml` | runc container configuration |
| `sandbox-resource-slot.yaml` | resource-slot sandbox configuration |
| `container-resource-slot.yaml` | resource-slot container configuration |
| `sandbox-wasmedge.yaml` | wasmEdge sandbox configuration |
| `container-wasmedge.yaml` | wasmEdge container configuration |

## Resource Configuration

| Runtime Type | CPU Limit | Memory Limit | Purpose |
|--------------|-----------|--------------|---------|
| runc | 0.5 CPU | 100MB | Standard container runtime |
| resource-slot | 1 CPU | 512MB | Resource slot sandbox |
| wasmEdge | 0.1 CPU | 100MB | WebAssembly runtime |

## Notes

1. Ensure Kuasar runtimes are properly installed and configured
2. Ensure crictl tool is installed and configured
3. Ensure sufficient permissions for container operations
4. Test framework automatically handles cleanup of created resources
5. If tests fail, check Kuasar service status and logs in the artifacts directory

For any issues with the migration, please refer to the new documentation or file an issue in the repository.
