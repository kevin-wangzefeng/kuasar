#!/bin/bash
# Purpose: Kuasar functionality test automation script
# Tests three types of sandbox applications: runc, resource-slot, wasmEdge

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Kuasar Functionality Testing Started ==="
echo "Current directory: $SCRIPT_DIR"

# Check if crictl is available
if ! command -v crictl &> /dev/null; then
    echo "Error: crictl command not found, please ensure crictl is installed and configured"
    exit 1
fi

# Check if required configuration files exist
REQUIRED_FILES=(
    "sandbox-runc.yaml"
    "container-runc.yaml"
    "sandbox-resource-slot.yaml"
    "container-resource-slot.yaml"
    "sandbox-wasmedge.yaml"
    "container-wasmedge.yaml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: Configuration file $file does not exist"
        exit 1
    fi
done

# Cleanup function
cleanup() {
    echo "Starting resource cleanup..."
    
    # Stop and remove containers (ignore errors)
    [ ! -z "$RUNC_CONTAINER_ID" ] && crictl stop "$RUNC_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$SLOT_CONTAINER_ID" ] && crictl stop "$SLOT_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$WASM_CONTAINER_ID" ] && crictl stop "$WASM_CONTAINER_ID" 2>/dev/null || true
    
    [ ! -z "$RUNC_CONTAINER_ID" ] && crictl rm "$RUNC_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$SLOT_CONTAINER_ID" ] && crictl rm "$SLOT_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$WASM_CONTAINER_ID" ] && crictl rm "$WASM_CONTAINER_ID" 2>/dev/null || true
    
    # Stop and remove sandboxes (ignore errors)
    [ ! -z "$RUNC_SANDBOX_ID" ] && crictl stopp "$RUNC_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$SLOT_SANDBOX_ID" ] && crictl stopp "$SLOT_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$WASM_SANDBOX_ID" ] && crictl stopp "$WASM_SANDBOX_ID" 2>/dev/null || true
    
    [ ! -z "$RUNC_SANDBOX_ID" ] && crictl rmp "$RUNC_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$SLOT_SANDBOX_ID" ] && crictl rmp "$SLOT_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$WASM_SANDBOX_ID" ] && crictl rmp "$WASM_SANDBOX_ID" 2>/dev/null || true
    
    echo "Cleanup complete"
}

# Set automatic cleanup on exit
trap cleanup EXIT

echo ""
echo "=== Test Type 1: Standard runc Application (0.5 CPU, 100MB Memory) ==="
echo "Creating runc sandbox..."
RUNC_SANDBOX_ID=$(crictl runp sandbox-runc.yaml)
echo "runc sandbox ID: $RUNC_SANDBOX_ID"

echo "Creating runc container..."
RUNC_CONTAINER_ID=$(crictl create "$RUNC_SANDBOX_ID" container-runc.yaml sandbox-runc.yaml)
echo "runc container ID: $RUNC_CONTAINER_ID"

echo "Starting runc container..."
crictl start "$RUNC_CONTAINER_ID"
echo "runc application created successfully!"

echo ""
echo "=== Test Type 2: resource-slot Application (1 CPU, 512MB Memory) ==="
echo "Creating resource-slot sandbox..."
SLOT_SANDBOX_ID=$(crictl runp sandbox-resource-slot.yaml)
echo "resource-slot sandbox ID: $SLOT_SANDBOX_ID"

echo "Creating resource-slot container..."
SLOT_CONTAINER_ID=$(crictl create "$SLOT_SANDBOX_ID" container-resource-slot.yaml sandbox-resource-slot.yaml)
echo "resource-slot container ID: $SLOT_CONTAINER_ID"

echo "Starting resource-slot container..."
crictl start "$SLOT_CONTAINER_ID"
echo "resource-slot application created successfully!"

echo ""
echo "=== Test Type 3: wasmEdge Application (0.1 CPU, 100MB Memory) ==="
echo "Creating wasmEdge sandbox..."
WASM_SANDBOX_ID=$(crictl runp sandbox-wasmedge.yaml)
echo "wasmEdge sandbox ID: $WASM_SANDBOX_ID"

echo "Creating wasmEdge container..."
WASM_CONTAINER_ID=$(crictl create "$WASM_SANDBOX_ID" container-wasmedge.yaml sandbox-wasmedge.yaml)
echo "wasmEdge container ID: $WASM_CONTAINER_ID"

echo "Starting wasmEdge container..."
crictl start "$WASM_CONTAINER_ID"
echo "wasmEdge application created successfully!"

echo ""
echo "=== Current Running Status ==="
echo "Running Pod Sandboxes:"
crictl pods

echo ""
echo "Running Containers:"
crictl ps

echo ""
echo "=== Detailed Status Check ==="
echo "Checking runc sandbox status:"
crictl inspectp "$RUNC_SANDBOX_ID" | grep -E "(id|state|runtime)"

echo ""
echo "Checking resource-slot sandbox status:"
crictl inspectp "$SLOT_SANDBOX_ID" | grep -E "(id|state|runtime)"

echo ""
echo "Checking wasmEdge sandbox status:"
crictl inspectp "$WASM_SANDBOX_ID" | grep -E "(id|state|runtime)"

echo ""
echo "=== System Resource Statistics ==="
crictl stats

echo ""
echo "=== Test Complete ==="
echo "All three types of sandbox applications have been successfully created and are running"
echo "- runc application: $RUNC_CONTAINER_ID (0.5 CPU, 100MB)"
echo "- resource-slot application: $SLOT_CONTAINER_ID (1 CPU, 512MB)"
echo "- wasmEdge application: $WASM_CONTAINER_ID (0.1 CPU, 100MB)"

# Wait for user confirmation
read -p "Press Enter to start resource cleanup..." 

# Cleanup will be executed automatically in EXIT trap
echo "Test script execution complete!"
