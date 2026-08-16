#!/usr/bin/env bash

set -e

# ============================================================
# WPF Configuration
# ============================================================

WPF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT="$WPF_DIR/WPF.csproj"

DOTNET_DIR="$(cd "$WPF_DIR/.." && pwd)"

PUBLISH_DIR="$DOTNET_DIR/publish/WPF"

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
    echo -e "${BOLD}Job Application Tracker WPF Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}    Build and start the WPF application"
    echo -e "  ${GREEN}build${NC}    Build the WPF application"
    echo -e "  ${GREEN}publish${NC}  Publish the WPF application"
    echo -e "  ${GREEN}clean${NC}    Remove WPF build artifacts"
    echo -e "  ${GREEN}help${NC}     Show this help message"
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
# Build WPF
# ============================================================

build() {
    print_header "Building WPF"

    dotnet build "$PROJECT"

    print_success "WPF build completed successfully."
}

# ============================================================
# Publish WPF
# ============================================================

publish() {
    check_prerequisites

    print_header "Publishing WPF"

    rm -rf "$PUBLISH_DIR"

    dotnet publish "$PROJECT" \
        -c Release \
        -r win-x64 \
        --self-contained true \
        -o "$PUBLISH_DIR"

    print_success "WPF published successfully."

    print_info "Publish directory:"
    echo "$PUBLISH_DIR"
}

# ============================================================
# Start WPF
# ============================================================

start() {
    check_prerequisites

    print_header "Starting Job Application Tracker WPF"

    dotnet run --project "$PROJECT"
}

# ============================================================
# Clean
# ============================================================

clean() {
    print_header "Cleaning WPF Build Artifacts"

    print_info "Removing bin..."
    rm -rf "$WPF_DIR/bin"

    print_info "Removing obj..."
    rm -rf "$WPF_DIR/obj"

    print_info "Removing publish..."
    rm -rf "$PUBLISH_DIR"

    print_success "WPF build artifacts cleaned successfully."
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