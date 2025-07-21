# Deprecated Test Scripts

This directory contains deprecated test scripts that have been replaced by the new e2e testing framework.

## Migration

These scripts have been replaced as follows:

- `test-runc.sh` → `make -f Makefile.e2e test-e2e-runc`
- `test-wasmedge.sh` → `make -f Makefile.e2e test-e2e-wasm`  
- `test-resource-slot.sh` → `make -f Makefile.e2e test-e2e-resource-slot`
- `test-kuasar.sh` → `make -f Makefile.e2e test-e2e`

## New Testing Framework

Please use the new e2e testing framework located in `test/e2e/`:

```bash
# Run all tests
make -f Makefile.e2e test-e2e

# Run specific runtime tests
make -f Makefile.e2e test-e2e-runc
make -f Makefile.e2e test-e2e-wasm
make -f Makefile.e2e test-e2e-resource-slot
```

For more information, see `test/e2e/README.md`.

## Removal Plan

These scripts will be removed in a future release once the migration is complete.
