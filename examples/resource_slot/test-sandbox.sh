#!/bin/bash

# Test script for ResourceSlot sandboxer with example configurations

set -e

SANDBOXER_SOCKET="/tmp/resource-slot-sandboxer-example.sock"
SANDBOXER_DIR="/tmp/kuasar-resource-slot-example"
SANDBOXER_PID=""

cleanup() {
    echo "Cleaning up..."
    if [ -n "$SANDBOXER_PID" ]; then
        kill $SANDBOXER_PID 2>/dev/null || true
        wait $SANDBOXER_PID 2>/dev/null || true
    fi
    rm -rf "$SANDBOXER_DIR"
    rm -f "$SANDBOXER_SOCKET"
}

trap cleanup EXIT

echo "Starting ResourceSlot sandboxer example test..."

# Create test directory
mkdir -p "$SANDBOXER_DIR"

# Start the sandboxer
echo "Starting ResourceSlot sandboxer..."
../../resource_slot/target/release/resource-slot-sandboxer \
    --listen "$SANDBOXER_SOCKET" \
    --dir "$SANDBOXER_DIR" \
    --log-level debug &

SANDBOXER_PID=$!

# Wait for the sandboxer to start
sleep 2

# Check if the sandboxer is running
if ! kill -0 $SANDBOXER_PID 2>/dev/null; then
    echo "ERROR: ResourceSlot sandboxer failed to start"
    exit 1
fi

# Check if the socket was created
if [ ! -S "$SANDBOXER_SOCKET" ]; then
    echo "ERROR: ResourceSlot sandboxer socket not created"
    exit 1
fi

echo "ResourceSlot sandboxer started successfully!"
echo "Socket: $SANDBOXER_SOCKET"
echo "Directory: $SANDBOXER_DIR"
echo "PID: $SANDBOXER_PID"

# Let it run for a few seconds to demonstrate
sleep 5

# Show any resource info files that might have been created
echo "Checking for resource info files..."
find "$SANDBOXER_DIR" -name "resource_info.json" -exec cat {} \; 2>/dev/null || echo "No resource info files found yet"

echo "Example test completed successfully!"
echo "To test with real sandbox/container creation, use containerd/CRI tools"
