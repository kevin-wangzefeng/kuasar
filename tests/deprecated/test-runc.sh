#!/bin/bash
# Purpose: Script for testing runc applications independently

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Testing runc Application Independently ==="

# Generate unique identifier
TIMESTAMP=$(date +%s)
RANDOM_ID=$(shuf -i 1000-9999 -n 1)
UNIQUE_ID="${TIMESTAMP}-${RANDOM_ID}"

# Create temporary configuration files
TEMP_SANDBOX="sandbox-runc-${UNIQUE_ID}.yaml"
TEMP_CONTAINER="container-runc-${UNIQUE_ID}.yaml"

# Create sandbox configuration with unique ID
sed "s/runc-sandbox-uid-001/runc-sandbox-uid-${UNIQUE_ID}/g; s/name: runc-sandbox/name: runc-sandbox-${UNIQUE_ID}/g" sandbox-runc.yaml > "$TEMP_SANDBOX"

# Create container configuration with unique ID
sed "s/runc-container/runc-container-${UNIQUE_ID}/g; s|/tmp/runc-container.log|/tmp/runc-container-${UNIQUE_ID}.log|g" container-runc.yaml > "$TEMP_CONTAINER"

# Cleanup function
cleanup() {
    echo "Cleaning up resources..."
    [ ! -z "$RUNC_CONTAINER_ID" ] && crictl stop "$RUNC_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$RUNC_CONTAINER_ID" ] && crictl rm "$RUNC_CONTAINER_ID" 2>/dev/null || true
    [ ! -z "$RUNC_SANDBOX_ID" ] && crictl stopp "$RUNC_SANDBOX_ID" 2>/dev/null || true
    [ ! -z "$RUNC_SANDBOX_ID" ] && crictl rmp "$RUNC_SANDBOX_ID" 2>/dev/null || true
    
    # Clean up temporary files and log files
    rm -f "$TEMP_SANDBOX" "$TEMP_CONTAINER"
    rm -f "/tmp/runc-container-${UNIQUE_ID}.log" 2>/dev/null || true
    echo "Cleanup complete"
}

# Set automatic cleanup on exit
trap cleanup EXIT

# Create sandbox
echo "Creating runc sandbox..."
RUNC_SANDBOX_ID=$(crictl runp "$TEMP_SANDBOX")
echo "Created runc sandbox: $RUNC_SANDBOX_ID"

# Create container
echo "Creating runc container..."
RUNC_CONTAINER_ID=$(crictl create "$RUNC_SANDBOX_ID" "$TEMP_CONTAINER" "$TEMP_SANDBOX")
echo "Created runc container: $RUNC_CONTAINER_ID"

# Start container
echo "Starting runc container..."
crictl start "$RUNC_CONTAINER_ID"

# Query status
echo "Querying sandbox status:"
crictl inspectp "$RUNC_SANDBOX_ID" | head -20

echo "Querying container status:"
crictl inspect "$RUNC_CONTAINER_ID" | head -20

echo "Viewing container logs:"
crictl logs "$RUNC_CONTAINER_ID" 2>/dev/null || echo "No container log output (normal situation, as sleep command has no output)"

echo ""
echo "Checking log file:"
LOG_FILE="/tmp/runc-container-${UNIQUE_ID}.log"
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

echo "runc test completed!"
echo "Press Enter to continue cleanup, or Ctrl+C to exit..."
read -r
