#!/usr/bin/env bash

set -e

# ============================================================
# Electron Configuration
# ============================================================

ELECTRON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUNTIME_DIR="$ELECTRON_DIR/runtime"

JAVA_PATH="/c/Program Files/Java/jdk-22"

# ============================================================
# Colors
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# Helper Functions
# ============================================================

print_header() {
    echo
    echo -e "${BOLD}=========================================${NC}"
    echo -e "${BOLD} $1${NC}"
    echo -e "${BOLD}=========================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================
# Help
# ============================================================

show_help() {
    echo
    echo -e "${BOLD}Job Application Tracker Electron Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}    Build and start the Electron application"
    echo -e "  ${GREEN}package${NC}  Build and create the Windows installer"
    echo -e "  ${GREEN}clean${NC}     Remove Electron build artifacts"
    echo -e "  ${GREEN}help${NC}     Show this help message"
    echo
}

# ============================================================
# Prerequisites
# ============================================================

# ============================================================
# Prerequisites
# ============================================================

check_prerequisites() {
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is not installed."
        exit 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is not installed."
        exit 1
    fi

    # --------------------------------------------------------
    # Locate JDK
    # --------------------------------------------------------

    if [[ -n "${JAVA_HOME:-}" ]] &&
       [[ -f "$JAVA_HOME/bin/jlink.exe" ]]; then

        print_info "Using JDK from JAVA_HOME:"
        echo "$JAVA_HOME"

    elif [[ -f "/c/Program Files/Java/jdk-22/bin/jlink.exe" ]]; then
        export JAVA_HOME="$JAVA_PATH"

        print_info "Using JDK:"
        echo "$JAVA_HOME"

    else
        print_error "JDK 22 was not found."
        echo
        echo "Expected location:"
        echo "C:/Program Files/Java/jdk-22"
        echo
        echo "Install JDK 22 or set JAVA_HOME manually."
        exit 1
    fi

    # --------------------------------------------------------
    # Verify jlink
    # --------------------------------------------------------

    if [[ ! -f "$JAVA_HOME/bin/jlink.exe" ]]; then
        print_error "jlink was not found."
        echo
        echo "Expected:"
        echo "$JAVA_HOME/bin/jlink.exe"
        exit 1
    fi

    # --------------------------------------------------------
    # Verify JDK modules
    # --------------------------------------------------------

    if [[ ! -d "$JAVA_HOME/jmods" ]]; then
        print_error "JDK jmods directory was not found."
        echo
        echo "Expected:"
        echo "$JAVA_HOME/jmods"
        exit 1
    fi

    print_success "JDK 22 found."
}

# ============================================================
# Electron Directory
# ============================================================

check_electron_directory() {
    if [[ ! -f "$ELECTRON_DIR/package.json" ]]; then
        print_error "Electron package.json was not found."
        exit 1
    fi
}

# ============================================================
# Install Electron Dependencies
# ============================================================

install_dependencies() {
    if [[ -d "$ELECTRON_DIR/node_modules" ]] &&
       [[ -f "$ELECTRON_DIR/node_modules/.bin/tsc" ]]; then
        print_info "Electron dependencies already installed."
        return
    fi

    print_header "Installing Electron Dependencies"

    (
        cd "$ELECTRON_DIR"

        npm ci
    )

    print_success "Electron dependencies installed successfully."
}

# ============================================================
# Create Custom Java Runtime
# ============================================================

create_runtime() {
    print_header "Creating Custom Java Runtime"

    if [[ -f "$RUNTIME_DIR/bin/java.exe" ]]; then
        print_info "Custom Java runtime already exists."
        print_info "Runtime: $RUNTIME_DIR"
        return
    fi

    print_info "JDK: $JAVA_HOME"
    print_info "Runtime: $RUNTIME_DIR"

    rm -rf "$RUNTIME_DIR"

    "$JAVA_HOME/bin/jlink.exe" \
        --module-path "$JAVA_HOME/jmods" \
        --add-modules \
        java.base,java.sql,java.naming,java.management,java.instrument,java.desktop,java.security.jgss,jdk.crypto.ec,jdk.unsupported \
        --output "$RUNTIME_DIR" \
        --strip-debug \
        --no-man-pages \
        --no-header-files \
        --compress=2

    if [[ ! -f "$RUNTIME_DIR/bin/java.exe" ]]; then
        print_error "Failed to create Java runtime."
        exit 1
    fi

    print_success "Custom Java runtime created successfully."
}

# ============================================================
# Build Electron
# ============================================================

build_electron() {
    print_header "Building Electron"

    (
        cd "$ELECTRON_DIR"

        npm run build
    )

    print_success "Electron build completed successfully."
}

# ============================================================
# Start Electron Application
# ============================================================

start() {
    check_prerequisites
    check_electron_directory

    install_dependencies

    create_runtime
    build_electron

    print_header "Starting Job Application Tracker Electron"

    (
        cd "$ELECTRON_DIR"

        npx electron .
    )
}

# ============================================================
# Package Electron Application
# ============================================================

package() {
    check_prerequisites
    check_electron_directory

    install_dependencies

    create_runtime
    build_electron

    print_header "Creating Job Application Tracker Windows Installer"

    (
        cd "$ELECTRON_DIR"

        npx electron-builder --win
    )

    print_success "Windows installer created successfully."

    print_info "Installer:"
    echo "$ELECTRON_DIR/release/Job Application Tracker - Electron Setup 1.0.0.exe"

    print_info "Unpacked application:"
    echo "$ELECTRON_DIR/release/win-unpacked/"
}

# ============================================================
# Clean Electron Build Artifacts
# ============================================================

clean() {
    check_electron_directory

    print_header "Cleaning Electron Build Artifacts"

    print_info "Removing node_modules..."
    rm -rf "$ELECTRON_DIR/node_modules"

    print_info "Removing dist..."
    rm -rf "$ELECTRON_DIR/dist"

    print_info "Removing release..."
    rm -rf "$ELECTRON_DIR/release"

    print_info "Removing custom Java runtime..."
    rm -rf "$ELECTRON_DIR/runtime"

    print_success "Electron build artifacts cleaned successfully."
}

# ============================================================
# Main
# ============================================================

case "${1:-help}" in
    start)
        start
        ;;
    package)
        package
        ;;
    clean)
        clean
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac