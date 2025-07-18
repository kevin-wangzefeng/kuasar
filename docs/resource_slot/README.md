# ResourceSlot Sandboxer

ResourceSlot sandboxer is a specialized fake sandbox implementation for Kuasar that simulates container resource allocation without actually allocating system resources.

## Overview

The ResourceSlot sandboxer is designed as a testing and development tool that provides a fully functional sandbox API while tracking resource requirements without the overhead of actual resource allocation. This makes it ideal for:

- Testing container configurations
- Development and debugging of container orchestration systems
- Resource planning and capacity estimation
- Performance testing of container management systems

## Architecture

The ResourceSlot sandboxer consists of:

- **ResourceSlotSandboxer**: The main sandboxer implementation that manages sandbox lifecycle
- **ResourceSlotSandbox**: Individual sandbox instances that track resource requirements
- **ResourceSlotContainer**: Container instances within sandboxes
- **ResourceInfo**: Structure that extracts and stores resource information from configurations

## Features

### Resource Tracking

The sandboxer extracts and tracks the following resource information:

- **CPU**: CPU limits and requests (cores)
- **Memory**: Memory limits and requests (bytes)
- **PID**: Process ID limits
- **Storage**: Storage limits (future)
- **Network**: Network bandwidth limits (future)

### Configuration Sources

Resource information is extracted from multiple sources:

1. **CRI Annotations**: Kubernetes-style resource annotations
   - `resources.limits.cpu`
   - `resources.limits.memory`
   - `resources.requests.cpu`
   - `resources.requests.memory`
   - `resources.limits.pid`

2. **OCI Spec**: Linux resource specifications
   - CPU shares, quota, and period
   - Memory limits
   - PID limits

3. **Sandbox Metadata**: Additional resource metadata

### Logging and Monitoring

The sandboxer provides detailed logging of:

- Sandbox lifecycle events (create, start, stop, delete)
- Resource allocation simulation
- Container operations
- Configuration extraction

### Persistence

Resource information is saved to JSON files in the sandbox directory for:

- Debugging and inspection
- Integration with monitoring systems
- Historical tracking

## Usage

### Basic Usage

```bash
# Start the ResourceSlot sandboxer
resource-slot-sandboxer --listen /run/resource-slot-sandboxer.sock \
                       --dir /var/lib/kuasar-resource-slot \
                       --log-level info
```

### Configuration with systemd

```bash
# Install and start the service
sudo systemctl enable kuasar-resource-slot
sudo systemctl start kuasar-resource-slot
```

### Integration with containerd

Configure containerd to use the ResourceSlot sandboxer:

```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.resource-slot]
  runtime_type = "io.containerd.kuasar.v1"
  
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.resource-slot.options]
  BinaryName = "resource-slot-sandboxer"
  Root = "/var/lib/kuasar-resource-slot"
  Address = "/run/resource-slot-sandboxer.sock"
```

Then create a RuntimeClass:

```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: resource-slot
handler: resource-slot
```

## API Implementation

The ResourceSlot sandboxer implements the full Kuasar sandbox API:

### Sandboxer Interface

- `create(id, options)`: Create a new sandbox
- `start(id)`: Start the sandbox
- `stop(id, force)`: Stop the sandbox
- `delete(id)`: Delete the sandbox
- `update(id, data)`: Update sandbox configuration
- `sandbox(id)`: Get sandbox reference

### Sandbox Interface

- `status()`: Get sandbox status
- `ping()`: Health check
- `append_container(id, options)`: Add container to sandbox
- `update_container(id, options)`: Update container configuration
- `remove_container(id)`: Remove container from sandbox
- `exit_signal()`: Get exit signal

## Output Example

When a sandbox is created, the sandboxer logs resource information:

```log
[2024-01-01T10:00:00Z INFO  resource_slot_sandboxer] Creating ResourceSlot sandbox: test-sandbox
[2024-01-01T10:00:00Z DEBUG resource_slot_sandboxer] Extracted resource info: ResourceInfo { cpu_limit: Some(2.0), cpu_request: Some(1.0), memory_limit: Some(2147483648), memory_request: Some(1073741824), pid_limit: Some(1000), storage_limit: None, network_bandwidth: None }
[2024-01-01T10:00:00Z INFO  resource_slot_sandboxer] ResourceSlot sandbox test-sandbox created successfully
```

Resource information is also saved to `{sandbox_dir}/resource_info.json`:

```json
{
  "cpu_limit": 2.0,
  "cpu_request": 1.0,
  "memory_limit": 2147483648,
  "memory_request": 1073741824,
  "pid_limit": 1000,
  "storage_limit": null,
  "network_bandwidth": null
}
```

## Development

### Building

```bash
# Build the sandboxer
cd resource_slot
cargo build --release

# Or build using the main Makefile
make resource-slot
```

### Testing

```bash
# Run the test script
./test_resource_slot.sh

# Run unit tests
cd resource_slot
cargo test
```

### Adding New Resource Types

To add support for new resource types:

1. Add the field to `ResourceInfo` struct
2. Update `from_sandbox_data()` and `from_container_data()` methods
3. Add extraction logic for the new resource type
4. Update logging and documentation

## Limitations

The ResourceSlot sandboxer has the following limitations:

- **No Process Execution**: Does not execute actual processes
- **No Resource Enforcement**: Does not enforce resource limits
- **No Networking**: Does not create network interfaces
- **No Storage**: Does not mount storage volumes
- **No Security**: Does not provide security isolation

These limitations are by design, as the sandboxer is intended for testing and development purposes only.

## Use Cases

### Container Testing

Use ResourceSlot sandboxer to test container configurations without resource allocation:

```bash
# Apply RuntimeClass
kubectl apply -f runtime-class.yaml

# Create pod with ResourceSlot runtime
kubectl apply -f pod-config.yaml

# Inspect resource extraction
cat /var/lib/kuasar-resource-slot/*/resource_info.json
```

### CI/CD Integration

Integrate ResourceSlot sandboxer in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Test container configuration
  run: |
    resource-slot-sandboxer --listen /tmp/test.sock --dir /tmp/test &
    sleep 2
    crictl --runtime-endpoint unix:///tmp/test.sock runp test-config.yaml
```

### Performance Testing

Use ResourceSlot sandboxer for performance testing of container management systems:

```bash
# Measure container creation overhead
time for i in {1..1000}; do
  crictl runp test-config-$i.yaml
done
```

## Future Enhancements

Planned enhancements for ResourceSlot sandboxer:

- **Metrics Export**: Export resource metrics to Prometheus
- **Policy Simulation**: Simulate resource policies and constraints
- **Resource Scheduling**: Simulate resource scheduling algorithms
- **Cost Estimation**: Estimate resource costs based on configurations
- **Resource Profiling**: Profile resource usage patterns
