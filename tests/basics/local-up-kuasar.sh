#!/bin/bash
# Purpose: Local startup of Kuasar for e2e testing
# Supports selective compilation and startup of different sandbox implementations

set -e

# Default configuration
DEFAULT_COMPONENTS="runc,wasm,resource-slot"
KUASAR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$KUASAR_ROOT/logs"
PID_FILE="$LOG_DIR/kuasar.pid"

# Create log directory
mkdir -p "$LOG_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Display usage help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -c, --components COMPONENTS   Specify components to compile and start, comma-separated
                               Available values: runc,wasm,resource-slot,vmm,quark
                               Default: $DEFAULT_COMPONENTS
  -h, --help                   Show this help information
  --skip-build                 Skip compilation step, start existing binaries directly
  --debug                      Enable debug mode
  --check-deps                 Only check dependencies, do not compile and start

Description:
  This script automatically checks runtime dependencies and provides detailed 
  installation instructions if missing dependencies are found.

Examples:
  $0                           # Use default components (runc,wasm,resource-slot)
  $0 -c runc,resource-slot     # Only compile and start runc and resource-slot
  $0 -c runc --skip-build      # Only start pre-compiled runc component
  $0 --debug                   # Start in debug mode
  $0 --check-deps              # Only check dependency installation status

EOF
}

# Parse command line arguments
COMPONENTS="$DEFAULT_COMPONENTS"
SKIP_BUILD=false
DEBUG_MODE=false
CHECK_DEPS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--components)
            COMPONENTS="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        --check-deps)
            CHECK_DEPS_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown parameter: $1"
            show_help
            exit 1
            ;;
    esac
done

log_info "Kuasar Local Startup Script"
log_info "Working directory: $KUASAR_ROOT"
log_info "Selected components: $COMPONENTS"

# Convert component string to array
IFS=',' read -ra COMPONENT_ARRAY <<< "$COMPONENTS"

# Cleanup function
cleanup() {
    log_info "Cleaning up Kuasar processes..."
    
    # Terminate all Kuasar-related processes
    if [[ -f "$PID_FILE" ]]; then
        while IFS= read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                log_info "Terminating process $pid"
                kill -TERM "$pid" 2>/dev/null || true
                sleep 1
                if kill -0 "$pid" 2>/dev/null; then
                    log_warn "Force terminating process $pid"
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    
    # Clean up other Kuasar processes
    pkill -f "kuasar-" 2>/dev/null || true
    pkill -f "runc-sandboxer" 2>/dev/null || true
    pkill -f "resource-slot-sandboxer" 2>/dev/null || true
    
    # Clean up temporary files
    log_info "Cleaning temporary files..."
    rm -rf /tmp/kuasar-test-* 2>/dev/null || true
    rm -rf /var/run/kuasar* 2>/dev/null || true
    
    log_info "Cleanup complete"
}

# Set automatic cleanup on exit
trap cleanup EXIT INT TERM

# Show installation instructions
show_installation_instructions() {
    local dep=$1
    
    case "$dep" in
        cargo|rustc)
            echo "    Install Rust:"
            echo "      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            echo "      source ~/.cargo/env"
            ;;
        make)
            echo "    Install make:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y build-essential"
            echo "      # CentOS/RHEL:"
            echo "      sudo yum groupinstall -y 'Development Tools'"
            ;;
        gcc)
            echo "    Install gcc:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y gcc"
            echo "      # CentOS/RHEL:"
            echo "      sudo yum install -y gcc"
            ;;
        pkg-config)
            echo "    Install pkg-config:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y pkg-config"
            echo "      # CentOS/RHEL:"
            echo "      sudo yum install -y pkgconfig"
            ;;
        runc)
            echo "    Install runc:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y runc"
            echo "      # Or compile from source:"
            echo "      git clone https://github.com/opencontainers/runc.git"
            echo "      cd runc && make && sudo make install"
            ;;
        crictl)
            echo "    Install crictl:"
            echo "      # Download latest version:"
            echo "      VERSION=\"v1.28.0\""
            echo "      wget https://github.com/kubernetes-sigs/cri-tools/releases/download/\$VERSION/crictl-\$VERSION-linux-amd64.tar.gz"
            echo "      sudo tar zxvf crictl-\$VERSION-linux-amd64.tar.gz -C /usr/local/bin"
            echo "      rm -f crictl-\$VERSION-linux-amd64.tar.gz"
            ;;
        containerd)
            echo "    Install containerd:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y containerd"
            echo "      # Or from official binary:"
            echo "      wget https://github.com/containerd/containerd/releases/download/v1.7.0/containerd-1.7.0-linux-amd64.tar.gz"
            echo "      sudo tar Cxzvf /usr/local containerd-1.7.0-linux-amd64.tar.gz"
            ;;
        wasmedge)
            echo "    Install WasmEdge:"
            echo "      curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash"
            echo "      source ~/.bashrc"
            ;;
        wasmtime)
            echo "    Install Wasmtime:"
            echo "      curl https://wasmtime.dev/install.sh -sSf | bash"
            echo "      source ~/.bashrc"
            ;;
        qemu-system-x86_64)
            echo "    Install QEMU:"
            echo "      # Ubuntu/Debian:"
            echo "      sudo apt-get update && sudo apt-get install -y qemu-system-x86"
            echo "      # CentOS/RHEL:"
            echo "      sudo yum install -y qemu-kvm"
            ;;
        *)
            echo "    Please refer to the official documentation for $dep installation instructions"
            ;;
    esac
    echo ""
}

# Check dependencies
check_dependencies() {
    log_info "Checking runtime dependencies..."
    
    local missing_deps=()
    local missing_optional=()
    
    # Base dependencies
    local base_deps=("cargo" "rustc" "make" "gcc" "pkg-config")
    for dep in "${base_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check Rust version
    if command -v rustc &> /dev/null; then
        local rust_version=$(rustc --version | awk '{print $2}')
        log_info "Detected Rust version: $rust_version"
    fi
    
    # Check component-specific dependencies based on selected components
    for component in "${COMPONENT_ARRAY[@]}"; do
        case "$component" in
            runc)
                if ! command -v runc &> /dev/null; then
                    missing_deps+=("runc")
                fi
                ;;
            wasm)
                if ! command -v wasmedge &> /dev/null && ! command -v wasmtime &> /dev/null; then
                    missing_optional+=("wasmedge")
                    log_warn "WasmEdge or Wasmtime not found, WASM functionality may not work properly"
                fi
                ;;
            vmm)
                if ! command -v qemu-system-x86_64 &> /dev/null; then
                    missing_optional+=("qemu-system-x86_64")
                    log_warn "QEMU not found, VMM functionality may not work properly"
                fi
                ;;
        esac
    done
    
    # Check containerd related
    if ! command -v containerd &> /dev/null; then
        missing_optional+=("containerd")
        log_warn "containerd not found, some functionality may be limited"
    fi
    
    if ! command -v crictl &> /dev/null; then
        missing_deps+=("crictl")
    fi
    
    # Report missing required dependencies
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing the following required dependencies:"
        echo ""
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}  ✗ $dep${NC}"
            show_installation_instructions "$dep"
        done
        log_error "Please install the missing required dependencies and try again"
        
        # If optional dependencies are missing, also show installation instructions
        if [[ ${#missing_optional[@]} -gt 0 ]]; then
            echo ""
            log_warn "Missing the following optional dependencies (does not affect basic functionality):"
            echo ""
            for dep in "${missing_optional[@]}"; do
                echo -e "${YELLOW}  ! $dep${NC}"
                show_installation_instructions "$dep"
            done
        fi
        
        exit 1
    fi
    
    # Show installation instructions for optional dependencies
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo ""
        log_warn "Recommend installing the following optional dependencies for full functionality:"
        echo ""
        for dep in "${missing_optional[@]}"; do
            echo -e "${YELLOW}  ! $dep${NC}"
            show_installation_instructions "$dep"
        done
        echo ""
        log_warn "You can choose to continue, or install these dependencies first for better experience"
        read -p "Continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Startup cancelled"
            exit 0
        fi
    fi
    
    log_info "Dependency check complete ✓"
}

# Build component
build_component() {
    local component=$1
    log_info "Building component: $component"
    
    case "$component" in
        runc)
            cd "$KUASAR_ROOT/runc"
            cargo build --release
            ;;
        wasm)
            cd "$KUASAR_ROOT/wasm"
            cargo build --release
            ;;
        resource-slot)
            cd "$KUASAR_ROOT/resource_slot"
            cargo build --release
            ;;
        vmm)
            cd "$KUASAR_ROOT/vmm"
            make build
            ;;
        quark)
            cd "$KUASAR_ROOT/quark"
            cargo build --release
            ;;
        *)
            log_error "Unknown component: $component"
            return 1
            ;;
    esac
    
    log_info "Component $component build complete ✓"
}

# Start component
start_component() {
    local component=$1
    log_info "Starting component: $component"
    
    local binary=""
    local args=""
    local log_file="$LOG_DIR/$component.log"
    
    case "$component" in
        runc)
            binary="$KUASAR_ROOT/runc/target/release/runc-sandboxer"
            args="--listen /run/kuasar-runc.sock --dir /run/kuasar-runc"
            ;;
        wasm)
            binary="$KUASAR_ROOT/wasm/target/release/wasm-sandboxer"
            args="--listen /run/kuasar-wasm.sock --dir /run/kuasar-wasm"
            ;;
        resource-slot)
            binary="$KUASAR_ROOT/resource_slot/target/release/resource-slot-sandboxer"
            args="--listen /run/kuasar-resource-slot.sock --dir /run/kuasar-resource-slot"
            ;;
        vmm)
            binary="$KUASAR_ROOT/vmm/target/release/vmm-sandboxer"
            args="--listen /run/kuasar-vmm.sock --dir /run/kuasar-vmm"
            ;;
        quark)
            binary="$KUASAR_ROOT/quark/target/release/quark-sandboxer"
            args="--listen /run/kuasar-quark.sock --dir /run/kuasar-quark"
            ;;
        *)
            log_error "Unknown component: $component"
            return 1
            ;;
    esac
    
    if [[ ! -f "$binary" ]]; then
        log_error "Binary file does not exist: $binary"
        log_error "Please build the component first or use --skip-build parameter"
        return 1
    fi
    
    # Create runtime directory
    local run_dir="/run/kuasar-$component"
    sudo mkdir -p "$run_dir"
    sudo chmod 755 "$run_dir"
    
    # Start component
    log_info "Starting: $binary $args"
    if [[ "$DEBUG_MODE" == "true" ]]; then
        sudo "$binary" $args 2>&1 | tee "$log_file" &
    else
        sudo "$binary" $args > "$log_file" 2>&1 &
    fi
    
    local pid=$!
    echo "$pid" >> "$PID_FILE"
    
    # Wait for service to start
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        log_info "Component $component started successfully (PID: $pid) ✓"
    else
        log_error "Component $component failed to start"
        log_error "Check logs: $log_file"
        return 1
    fi
}

# Verify service status
verify_services() {
    log_info "Verifying service status..."
    
    for component in "${COMPONENT_ARRAY[@]}"; do
        local sock_file="/run/kuasar-$component.sock"
        if [[ -S "$sock_file" ]]; then
            log_info "Component $component socket OK: $sock_file ✓"
        else
            log_warn "Component $component socket not found: $sock_file"
        fi
    done
}

# Show running status
show_status() {
    log_info "Kuasar service status:"
    echo "===================="
    
    if [[ -f "$PID_FILE" ]]; then
        echo "Running processes:"
        while IFS= read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                local cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
                echo "  PID $pid: $cmd"
            fi
        done < "$PID_FILE"
    else
        echo "No running processes"
    fi
    
    echo ""
    echo "Socket files:"
    for component in "${COMPONENT_ARRAY[@]}"; do
        local sock_file="/run/kuasar-$component.sock"
        if [[ -S "$sock_file" ]]; then
            echo "  $component: $sock_file ✓"
        else
            echo "  $component: $sock_file ✗"
        fi
    done
    
    echo ""
    echo "Log file location: $LOG_DIR"
    echo "===================="
}

# Main function
main() {
    cd "$KUASAR_ROOT"
    
    # Check dependencies
    check_dependencies
    
    # If only checking dependencies, exit
    if [[ "$CHECK_DEPS_ONLY" == "true" ]]; then
        log_info "Dependency check complete, exiting"
        exit 0
    fi
    
    # Build components
    if [[ "$SKIP_BUILD" == "false" ]]; then
        log_info "Starting to build selected components..."
        for component in "${COMPONENT_ARRAY[@]}"; do
            build_component "$component"
        done
        log_info "All components build complete ✓"
    else
        log_info "Skipping build step"
    fi
    
    # Start components
    log_info "Starting selected components..."
    for component in "${COMPONENT_ARRAY[@]}"; do
        start_component "$component"
    done
    
    # Verify services
    verify_services
    
    # Show status
    show_status
    
    log_info "Kuasar services startup complete!"
    log_info "You can now run test scripts in another terminal:"
    log_info "  cd $KUASAR_ROOT/tests/basics"
    log_info "  ./test-runc.sh"
    log_info "  ./test-resource-slot.sh"
    log_info ""
    log_info "Press Ctrl+C to stop all services"
    
    # Wait for user interruption
    while true; do
        sleep 1
    done
}

# Run main function
main "$@"
