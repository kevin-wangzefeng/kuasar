#!/bin/bash

# Test script for ResourceSlot sandboxer

set -e

SANDBOXER_SOCKET="/tmp/resource-slot-sandboxer-test.sock"
SANDBOXER_DIR="/tmp/kuasar-resource-slot-test"
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

echo "Starting ResourceSlot sandboxer test..."

# Create test directory
mkdir -p "$SANDBOXER_DIR"

# Start the sandboxer
echo "Starting ResourceSlot sandboxer..."
cargo run --manifest-path resource_slot/Cargo.toml -- \
    --listen "$SANDBOXER_SOCKET" \
    --dir "$SANDBOXER_DIR" \
    --log-level debug &

SANDBOXER_PID=$!

# Wait for the sandboxer to start and compile
echo "Waiting for sandboxer to compile and start..."
sleep 10

# Check if the sandboxer is running
if ! kill -0 $SANDBOXER_PID 2>/dev/null; then
    echo "ERROR: ResourceSlot sandboxer failed to start"
    exit 1
fi

# Wait for the socket to be created (with timeout)
echo "Waiting for socket to be created..."
for i in {1..10}; do
    if [ -S "$SANDBOXER_SOCKET" ]; then
        break
    fi
    sleep 1
done

# Check if the socket was created
if [ ! -S "$SANDBOXER_SOCKET" ]; then
    echo "ERROR: ResourceSlot sandboxer socket not created after waiting"
    exit 1
fi

echo "ResourceSlot sandboxer started successfully!"
echo "Socket: $SANDBOXER_SOCKET"
echo "Directory: $SANDBOXER_DIR"
echo "PID: $SANDBOXER_PID"

# Let it run for a few seconds
sleep 3

echo "Test completed successfully!"
