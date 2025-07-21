#!/bin/bash
# Purpose: Script for testing wasmEdge applications independently

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Testing wasmEdge Application Independently ==="

# Generate unique identifier
TIMESTAMP=$(date +%s)
RANDOM_ID=$(shuf -i 1000-9999 -n 1)
UNIQUE_ID="${TIMESTAMP}-${RANDOM_ID}"

# Create temporary configuration files
TEMP_SANDBOX="sandbox-wasmedge-${UNIQUE_ID}.yaml"
TEMP_CONTAINER="container-wasmedge-${UNIQUE_ID}.yaml"

# Create sandbox configuration with unique ID
sed "s/wasmedge-sandbox-uid-001/wasmedge-sandbox-uid-${UNIQUE_ID}/g; s/name: wasmedge-sandbox/name: wasmedge-sandbox-${UNIQUE_ID}/g" sandbox-wasmedge.yaml > "$TEMP_SANDBOX"

# Create container configuration with unique ID
sed "s/wasmedge-container/wasmedge-container-${UNIQUE_ID}/g; s|/tmp/wasmedge-container.log|/tmp/wasmedge-container-${UNIQUE_ID}.log|g" container-wasmedge.yaml > "$TEMP_CONTAINER"

# Cleanup function
cleanup() {
    echo "Cleaning up resources..."
    [ ! -z "$WASM_CONTAINER_ID" ] && crictl stop "$WASM_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$WASM_CONTAINER_ID" ] && crictl rm "$WASM_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$WASM_SANDBOX_ID" ] && crictl stopp "$WASM_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$WASM_SANDBOX_ID" ] && crictl rmp "$WASM_SANDBOX_ID" 2>/dev/null || true
    
    # Clean up temporary files and log files
    rm -f "$TEMP_SANDBOX" "$TEMP_CONTAINER"
    rm -f "/tmp/wasmedge-container-${UNIQUE_ID}.log" 2>/dev/null || true
    echo "Cleanup complete"
}

# Set automatic cleanup on exit
trap cleanup EXIT

# Create sandbox
echo "Creating wasmEdge sandbox..."
WASM_SANDBOX_ID=$(crictl runp "$TEMP_SANDBOX")
echo "Created wasmEdge sandbox: $WASM_SANDBOX_ID"

# Create container
echo "Creating wasmEdge container..."
WASM_CONTAINER_ID=$(crictl create "$WASM_SANDBOX_ID" "$TEMP_CONTAINER" "$TEMP_SANDBOX")
echo "Created wasmEdge container: $WASM_CONTAINER_ID"

# Start container
echo "Starting wasmEdge container..."
crictl start "$WASM_CONTAINER_ID"

# Query status
echo "Querying sandbox status:"
crictl inspectp "$WASM_SANDBOX_ID" | head -20

echo "Querying container status:"
crictl inspect "$WASM_CONTAINER_ID" | head -20

echo "Viewing container logs:"
crictl logs "$WASM_CONTAINER_ID" 2>/dev/null || echo "No container log output (WASM application may have no output or completed execution)"

echo ""
echo "Checking log file:"
LOG_FILE="/tmp/wasmedge-container-${UNIQUE_ID}.log"
if [ -f "$LOG_FILE" ]; then
    echo "Log file $LOG_FILE exists ✓"
    if [ -s "$LOG_FILE" ]; then
        echo "Log content:"
        head -10 "$LOG_FILE"
    else
        echo "Log file is empty (WASM application may have no output)"
    fi
else
    echo "Log file does not exist"
fi

echo "wasmEdge test completed!"
echo "Press Enter to continue cleanup, or Ctrl+C to exit..."
read -r
