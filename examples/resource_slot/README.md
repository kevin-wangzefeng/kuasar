# Example configuration for ResourceSlot sandboxer

This directory contains example configurations for testing the ResourceSlot sandboxer.

## Files

- `pod-config.yaml`: Example pod configuration with resource limits and ResourceSlot runtime
- `container-config.json`: Example container configuration
- `runtime-class.yaml`: RuntimeClass configuration for ResourceSlot sandboxer
- `test-sandbox.sh`: Script to test the sandboxer with example configurations

## Setup

1. Create the RuntimeClass:
   ```bash
   kubectl apply -f runtime-class.yaml
   ```

2. Start the ResourceSlot sandboxer:
   ```bash
   resource-slot-sandboxer --listen /run/resource-slot-sandboxer.sock \
                           --dir /var/lib/kuasar-resource-slot \
                           --log-level info
   ```

## Usage

1. Run the test script:
   ```bash
   ./test-sandbox.sh
   ```

2. Create a pod with ResourceSlot runtime:
   ```bash
   kubectl apply -f pod-config.yaml
   ```

3. Check the extracted resource information:
   ```bash
   cat /var/lib/kuasar-resource-slot/*/resource_info.json
   ```
