# Kuasar ResourceSlot Sandboxer

A fake sandbox implementation for Kuasar that simulates resource allocation without actually allocating system resources.

## Overview

The ResourceSlot sandboxer is designed to:

- Accept sandbox configurations including resource requirements (CPU, memory, PID limits, etc.)
- Create sandbox and container objects that track resource requirements
- Log resource allocation information for monitoring and debugging
- Provide a fully functional sandbox API without actual resource allocation

## Features

- **Resource Tracking**: Extracts and tracks CPU, memory, PID, and other resource limits from sandbox/container configurations
- **Logging**: Detailed logging of resource allocations and sandbox lifecycle events
- **Full API Compliance**: Implements all required Sandbox and Sandboxer trait methods
- **No Resource Allocation**: Does not actually allocate system resources or create real containers

## Use Cases

- **Testing**: Test sandbox configurations without resource allocation
- **Development**: Develop and test containerd configurations
- **Resource Planning**: Understand resource requirements of workloads
- **Debugging**: Debug sandbox configurations and resource specifications

## Configuration

The sandboxer extracts resource information from:

- CRI annotations (resources.limits.*, resources.requests.*)
- OCI spec Linux resources (CPU, memory, PID limits)
- Sandbox metadata

## Installation

```bash
cargo build --release
sudo cp target/release/resource-slot-sandboxer /usr/local/bin/
sudo systemctl enable kuasar-resource-slot
sudo systemctl start kuasar-resource-slot
```

## Usage

Run the sandboxer with:

```bash
resource-slot-sandboxer --listen /run/resource-slot-sandboxer.sock --dir /var/lib/kuasar-resource-slot --log-level info
```

## Logging Output

The sandboxer logs resource information for each sandbox and container:

```
[INFO] Creating ResourceSlot sandbox: test-sandbox
[INFO] ResourceSlot sandbox test-sandbox resource simulation:
[INFO]   - CPU limit: 2 cores
[INFO]   - Memory limit: 2147483648 bytes
[INFO]   - PID limit: 1000
[INFO] ResourceSlot sandbox test-sandbox started successfully
```
