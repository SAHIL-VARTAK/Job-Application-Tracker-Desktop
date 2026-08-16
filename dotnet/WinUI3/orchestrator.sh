#!/usr/bin/env bash

set -e

# ============================================================
# WinUI 3 Configuration
# ============================================================

WINUI3_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT="$WINUI3_DIR/WinUI3.csproj"

DOTNET_DIR="$(cd "$WINUI3_DIR/.." && pwd)"

PUBLISH_DIR="$DOTNET_DIR/publish/WinUI3"
SINGLE_FILE_DIR="$DOTNET_DIR/publish/WinUI3-SingleFile"

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
    echo -e "${BOLD}Job Application Tracker WinUI 3 Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}         Build and start WinUI 3"
    echo -e "  ${GREEN}build${NC}         Build WinUI 3"
    echo -e "  ${GREEN}publish${NC}       Publish normal WinUI 3"
    echo -e "  ${GREEN}single-file${NC}   Publish single-file WinUI 3"
    echo -e "  ${GREEN}msix${NC}          Build and sign MSIX"
    echo -e "  ${GREEN}clean${NC}         Remove WinUI 3 build artifacts"
    echo -e "  ${GREEN}help${NC}          Show this help message"
    echo
}

# ============================================================
# Prerequisites
# ============================================================

check_prerequisites() {
    if ! command -v dotnet >/dev/null 2>&1; then
        print_error ".NET SDK is not installed."
        exit 1
    fi

    print_success ".NET SDK found."
}

# ============================================================
# Build
# ============================================================

build() {
    check_prerequisites

    print_header "Building WinUI 3"

    dotnet build "$PROJECT"

    print_success "WinUI 3 build completed successfully."
}

# ============================================================
# Start
# ============================================================

start() {
    check_prerequisites

    print_header "Starting Job Application Tracker WinUI 3"

    dotnet run --project "$PROJECT"
}

# ============================================================
# Normal Publish
# ============================================================

publish() {
    check_prerequisites

    print_header "Publishing WinUI 3"

    rm -rf "$PUBLISH_DIR"

    dotnet publish "$PROJECT" \
        -c Release \
        -r win-x64 \
        --self-contained true \
        -o "$PUBLISH_DIR"

    print_success "WinUI 3 published successfully."

    print_info "Publish directory:"
    echo "$PUBLISH_DIR"
}

# ============================================================
# Single-File Publish
# ============================================================

single_file() {
    check_prerequisites

    print_header "Publishing WinUI 3 Single-File"

    rm -rf "$SINGLE_FILE_DIR"

    dotnet publish "$PROJECT" \
        -c Release \
        -r win-x64 \
        --self-contained true \
        -p:SingleFile=true \
        -o "$SINGLE_FILE_DIR"

    print_success "WinUI 3 single-file publish completed successfully."

    print_info "Publish directory:"
    echo "$SINGLE_FILE_DIR"
}

# ============================================================
# MSIX
# ============================================================

msix() {
    print_header "Building and Signing WinUI 3 MSIX"

    "$DOTNET_DIR/scripts/build-msix.sh"
}

# ============================================================
# Clean
# ============================================================

clean() {
    print_header "Cleaning WinUI 3 Build Artifacts"

    print_info "Removing bin..."
    rm -rf "$WINUI3_DIR/bin"

    print_info "Removing obj..."
    rm -rf "$WINUI3_DIR/obj"

    print_info "Removing normal publish..."
    rm -rf "$PUBLISH_DIR"

    print_info "Removing single-file publish..."
    rm -rf "$SINGLE_FILE_DIR"

    print_success "WinUI 3 build artifacts cleaned successfully."
}

# ============================================================
# Main
# ============================================================

case "${1:-help}" in
    start)
        start
        ;;
    build)
        build
        ;;
    publish)
        publish
        ;;
    single-file)
        single_file
        ;;
    msix)
        msix
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