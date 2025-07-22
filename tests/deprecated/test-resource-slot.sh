#!/bin/bash
# Purpose: Script for testing resource-slot applications independently

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Testing resource-slot Application Independently ==="

# Generate unique identifier
TIMESTAMP=$(date +%s)
RANDOM_ID=$(shuf -i 1000-9999 -n 1)
UNIQUE_ID="${TIMESTAMP}-${RANDOM_ID}"

# Create temporary configuration files
TEMP_SANDBOX="sandbox-resource-slot-${UNIQUE_ID}.yaml"
TEMP_CONTAINER="container-resource-slot-${UNIQUE_ID}.yaml"

# Create sandbox configuration with unique ID
sed "s/resource-slot-sandbox-uid-001/resource-slot-sandbox-uid-${UNIQUE_ID}/g; s/name: resource-slot-sandbox/name: resource-slot-sandbox-${UNIQUE_ID}/g" sandbox-resource-slot.yaml > "$TEMP_SANDBOX"

# Create container configuration with unique ID
sed "s/resource-slot-container/resource-slot-container-${UNIQUE_ID}/g; s|/tmp/resource-slot-container.log|/tmp/resource-slot-container-${UNIQUE_ID}.log|g" container-resource-slot.yaml > "$TEMP_CONTAINER"

# Cleanup function
cleanup() {
    echo "Cleaning up resources..."
    [ ! -z "$SLOT_CONTAINER_ID" ] && crictl stop "$SLOT_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$SLOT_CONTAINER_ID" ] && crictl rm "$SLOT_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$SLOT_SANDBOX_ID" ] && crictl stopp "$SLOT_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$SLOT_SANDBOX_ID" ] && crictl rmp "$SLOT_SANDBOX_ID" 2>/dev/null || true
    
    # Clean up temporary files and log files
    rm -f "$TEMP_SANDBOX" "$TEMP_CONTAINER"
    rm -f "/tmp/resource-slot-container-${UNIQUE_ID}.log" 2>/dev/null || true
    echo "Cleanup complete"
}

# Set automatic cleanup on exit
trap cleanup EXIT

# Create sandbox
echo "Creating resource-slot sandbox..."
SLOT_SANDBOX_ID=$(crictl runp "$TEMP_SANDBOX")
echo "Created resource-slot sandbox: $SLOT_SANDBOX_ID"

# Create container
echo "Creating resource-slot container..."
SLOT_CONTAINER_ID=$(crictl create "$SLOT_SANDBOX_ID" "$TEMP_CONTAINER" "$TEMP_SANDBOX")
echo "Created resource-slot container: $SLOT_CONTAINER_ID"

# Start container
echo "Starting resource-slot container..."
crictl start "$SLOT_CONTAINER_ID"

# Query status
echo "Querying sandbox status:"
crictl inspectp "$SLOT_SANDBOX_ID" | head -20

echo "Querying container status:"
crictl inspect "$SLOT_CONTAINER_ID" | head -20

echo "Viewing container logs:"
crictl logs "$SLOT_CONTAINER_ID" 2>/dev/null || echo "No container log output (normal situation, as sleep command has no output)"

echo ""
echo "Checking log file:"
LOG_FILE="/tmp/resource-slot-container-${UNIQUE_ID}.log"
if [ -f "$LOG_FILE" ]; then
    echo "Log file $LOG_FILE exists ✓"
    if [ -s "$LOG_FILE" ]; then
        echo "Log content:"
        head -10 "$LOG_FILE"
    else
        echo "Log file is empty (normal situation, sleep command has no output)"
    fi
else
    echo "Log file does not exist"
fi

echo "resource-slot test completed!"
echo "Press Enter to continue cleanup, or Ctrl+C to exit..."
read -r
