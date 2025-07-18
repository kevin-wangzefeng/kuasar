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
- **Persistence**: Saves resource information to JSON files for monitoring
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

## Output

The sandboxer will create JSON files in the sandbox base directory containing extracted resource information:

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
