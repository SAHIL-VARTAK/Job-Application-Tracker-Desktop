#!/usr/bin/env bash

set -e

# ============================================================
# Installer Configuration
# ============================================================

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTNET_DIR="$(cd "$INSTALLER_DIR/.." && pwd)"

INSTALLER_OUTPUT="$DOTNET_DIR/publish/installers"

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
    echo -e "${BOLD}Job Application Tracker Installer Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}wpf${NC}             Create WPF installer"
    echo -e "  ${GREEN}winui3${NC}          Create WinUI 3 normal installer"
    echo -e "  ${GREEN}winui3-single${NC}   Create WinUI 3 single-file installer"
    echo -e "  ${GREEN}all${NC}             Create all Inno Setup installers"
    echo -e "  ${GREEN}clean${NC}           Remove installer output"
    echo -e "  ${GREEN}help${NC}            Show this help message"
    echo
}

# ============================================================
# Prerequisites
# ============================================================

check_prerequisites() {
    if ! command -v iscc >/dev/null 2>&1; then
        print_error "Inno Setup command-line compiler (iscc) was not found."
        echo
        echo "Make sure Inno Setup is installed and ISCC.exe is in PATH."
        exit 1
    fi

    print_success "Inno Setup compiler found."
}

# ============================================================
# Verify Published Output
# ============================================================

check_wpf_publish() {
    WPF_PUBLISH_DIR="$DOTNET_DIR/publish/WPF"

    if [[ ! -f "$WPF_PUBLISH_DIR/JobApplicationTracker-Dotnet.exe" ]]; then
        print_error "WPF published application was not found."
        echo
        echo "Expected:"
        echo "$WPF_PUBLISH_DIR/JobApplicationTracker-Dotnet.exe"
        echo
        echo "Run:"
        echo "  ./../orchestrator.sh publish-wpf"
        exit 1
    fi
}

check_winui3_publish() {
    WINUI3_PUBLISH_DIR="$DOTNET_DIR/publish/WinUI3"

    if [[ ! -f "$WINUI3_PUBLISH_DIR/JobApplicationTracker-Dotnet.exe" ]]; then
        print_error "WinUI 3 published application was not found."
        echo
        echo "Expected:"
        echo "$WINUI3_PUBLISH_DIR/JobApplicationTracker-Dotnet.exe"
        echo
        echo "Run:"
        echo "  ./../orchestrator.sh publish-winui3"
        exit 1
    fi
}

check_winui3_single_file_publish() {
    SINGLE_FILE_DIR="$DOTNET_DIR/publish/WinUI3-SingleFile"

    if [[ ! -f "$SINGLE_FILE_DIR/JobApplicationTracker-Dotnet.exe" ]]; then
        print_error "WinUI 3 single-file application was not found."
        echo
        echo "Expected:"
        echo "$SINGLE_FILE_DIR/JobApplicationTracker-Dotnet.exe"
        echo
        echo "Run:"
        echo "  ./../orchestrator.sh publish-single"
        exit 1
    fi
}

# ============================================================
# WPF Installer
# ============================================================

wpf() {
    check_prerequisites
    check_wpf_publish

    print_header "Creating WPF Installer"

    iscc "$INSTALLER_DIR/WPF/WPF.iss"

    print_success "WPF installer created successfully."

    print_info "Output:"
    echo "$INSTALLER_OUTPUT/JobApplicationTracker-WPF-Setup.exe"
}

# ============================================================
# WinUI 3 Normal Installer
# ============================================================

winui3() {
    check_prerequisites
    check_winui3_publish

    print_header "Creating WinUI 3 Installer"

    ISS_FILE="$INSTALLER_DIR/WinUI3/WinUI3.iss"
    ISS_FILE_WIN=$(cygpath -w "$ISS_FILE")

    MSYS_NO_PATHCONV=1 iscc \
        /DBuildType=Normal \
        "$ISS_FILE_WIN"

    print_success "WinUI 3 installer created successfully."

    print_info "Output:"
    echo "$INSTALLER_OUTPUT/JobApplicationTracker-WinUI3-Setup.exe"
}

# ============================================================
# WinUI 3 Single-File Installer
# ============================================================

winui3_single() {
    check_prerequisites
    check_winui3_single_file_publish

    print_header "Creating WinUI 3 Single-File Installer"

    ISS_FILE="$INSTALLER_DIR/WinUI3/WinUI3.iss"
    ISS_FILE_WIN=$(cygpath -w "$ISS_FILE")

    MSYS_NO_PATHCONV=1 iscc \
        /DBuildType=SingleFile \
        "$ISS_FILE_WIN"

    print_success "WinUI 3 single-file installer created successfully."

    print_info "Output:"
    echo "$INSTALLER_OUTPUT/JobApplicationTracker-WinUI3-SingleFile-Setup.exe"
}

# ============================================================
# All Installers
# ============================================================

all() {
    check_prerequisites

    check_wpf_publish
    check_winui3_publish
    check_winui3_single_file_publish

    print_header "Creating All Installers"

    WPF_ISS="$INSTALLER_DIR/WPF/WPF.iss"
    WINUI3_ISS="$INSTALLER_DIR/WinUI3/WinUI3.iss"

    WPF_ISS_WIN=$(cygpath -w "$WPF_ISS")
    WINUI3_ISS_WIN=$(cygpath -w "$WINUI3_ISS")

    iscc "$WPF_ISS_WIN"

    MSYS_NO_PATHCONV=1 iscc \
        /DBuildType=Normal \
        "$WINUI3_ISS_WIN"

    MSYS_NO_PATHCONV=1 iscc \
        /DBuildType=SingleFile \
        "$WINUI3_ISS_WIN"

    print_success "All installers created successfully."

    print_info "Installer directory:"
    echo "$INSTALLER_OUTPUT"
}

# ============================================================
# Clean
# ============================================================

clean() {
    print_header "Cleaning Installer Artifacts"

    rm -rf "$INSTALLER_OUTPUT"

    print_success "Installer artifacts cleaned successfully."
}

# ============================================================
# Main
# ============================================================

case "${1:-help}" in
    wpf)
        wpf
        ;;
    winui3)
        winui3
        ;;
    winui3-single)
        winui3_single
        ;;
    all)
        all
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