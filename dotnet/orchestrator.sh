#!/usr/bin/env bash

set -e

# ============================================================
# .NET Configuration
# ============================================================

DOTNET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$DOTNET_DIR/.." && pwd)"

RUNTIME_DIR="$DOTNET_DIR/resources/runtime"
FRONTEND_DIR="$DOTNET_DIR/resources/frontend/dist"
BACKEND_DIR="$DOTNET_DIR/resources/backend"

WPF_ORCHESTRATOR="$DOTNET_DIR/WPF/orchestrator.sh"
WINUI3_ORCHESTRATOR="$DOTNET_DIR/WinUI3/orchestrator.sh"
INSTALLER_ORCHESTRATOR="$DOTNET_DIR/installer/orchestrator.sh"

JAVA_PATH="/c/Program Files/Java/jdk-22"

# ============================================================
# Workspace Build Artifacts
# ============================================================

WORKSPACE_BACKEND="$PROJECT_ROOT/workspace/Job-Application-Tracker/target"
WORKSPACE_FRONTEND="$PROJECT_ROOT/workspace/Job-Application-Tracker-UI/dist"

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
    echo -e "${BOLD}Job Application Tracker .NET Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Resource Commands:${NC}"
    echo -e "  ${GREEN}prepare${NC}            Copy frontend/backend and create runtime"
    echo
    echo -e "${BLUE}Application Commands:${NC}"
    echo -e "  ${GREEN}start-wpf${NC}          Build and start WPF"
    echo -e "  ${GREEN}start-winui3${NC}       Build and start WinUI 3"
    echo
    echo -e "${BLUE}Build Commands:${NC}"
    echo -e "  ${GREEN}build-wpf${NC}          Build WPF"
    echo -e "  ${GREEN}build-winui3${NC}       Build WinUI 3"
    echo
    echo -e "${BLUE}Publish Commands:${NC}"
    echo -e "  ${GREEN}publish-wpf${NC}        Publish WPF"
    echo -e "  ${GREEN}publish-winui3${NC}     Publish WinUI 3"
    echo -e "  ${GREEN}publish-single${NC}     Publish WinUI 3 single-file"
    echo
    echo -e "${BLUE}Installer Commands:${NC}"
    echo -e "  ${GREEN}installer-wpf${NC}      Create WPF installer"
    echo -e "  ${GREEN}installer-winui3${NC}   Create WinUI 3 installer"
    echo -e "  ${GREEN}installer-single${NC}   Create WinUI 3 single-file installer"
    echo -e "  ${GREEN}installers${NC}         Create all installers"
    echo
    echo -e "${BLUE}Maintenance:${NC}"
    echo -e "  ${GREEN}clean${NC}              Clean all .NET build artifacts"
    echo -e "  ${GREEN}help${NC}               Show this help message"
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

    # --------------------------------------------------------
    # Locate JDK
    # --------------------------------------------------------

    if [[ -n "${JAVA_HOME:-}" ]] &&
       [[ -f "$JAVA_HOME/bin/jlink.exe" ]]; then

        print_info "Using JDK from JAVA_HOME:"
        echo "$JAVA_HOME"

    elif [[ -f "$JAVA_PATH/bin/jlink.exe" ]]; then

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
# Copy Frontend
# ============================================================

copy_frontend() {
    print_header "Preparing Frontend"

    if [[ ! -d "$WORKSPACE_FRONTEND" ]]; then
        print_error "Frontend dist directory was not found:"
        echo "$WORKSPACE_FRONTEND"
        exit 1
    fi

    rm -rf "$FRONTEND_DIR"
    mkdir -p "$FRONTEND_DIR"

    cp -R "$WORKSPACE_FRONTEND/." "$FRONTEND_DIR/"

    print_success "Frontend dist copied successfully."

    print_info "Source:"
    echo "$WORKSPACE_FRONTEND"

    print_info "Destination:"
    echo "$FRONTEND_DIR"
}

# ============================================================
# Copy Backend
# ============================================================

copy_backend() {
    print_header "Preparing Backend"

    if [[ ! -d "$WORKSPACE_BACKEND" ]]; then
        print_error "Backend target directory was not found:"
        echo "$WORKSPACE_BACKEND"
        exit 1
    fi

    BACKEND_JAR=$(find "$WORKSPACE_BACKEND" \
        -maxdepth 1 \
        -type f \
        -name "*.jar" \
        ! -name "*-sources.jar" \
        ! -name "*-javadoc.jar" \
        | head -n 1)

    if [[ -z "$BACKEND_JAR" ]]; then
        print_error "Backend JAR was not found:"
        echo "$WORKSPACE_BACKEND"
        exit 1
    fi

    rm -rf "$BACKEND_DIR"
    mkdir -p "$BACKEND_DIR"

    cp "$BACKEND_JAR" "$BACKEND_DIR/"

    print_success "Backend JAR copied successfully."

    print_info "Source:"
    echo "$BACKEND_JAR"

    print_info "Destination:"
    echo "$BACKEND_DIR"
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
# Prepare Resources
# ============================================================

prepare_resources() {
    check_prerequisites

    copy_frontend
    copy_backend
    create_runtime
}

# ============================================================
# WPF
# ============================================================

start_wpf() {
    "$WPF_ORCHESTRATOR" start
}

build_wpf() {
    "$WPF_ORCHESTRATOR" build
}

publish_wpf() {
    "$WPF_ORCHESTRATOR" publish
}

# ============================================================
# WinUI 3
# ============================================================

start_winui3() {
    "$WINUI3_ORCHESTRATOR" start
}

build_winui3() {
    "$WINUI3_ORCHESTRATOR" build
}

publish_winui3() {
    "$WINUI3_ORCHESTRATOR" publish
}

publish_single() {
    "$WINUI3_ORCHESTRATOR" single-file
}

# ============================================================
# Installers
# ============================================================

installer_wpf() {
    "$INSTALLER_ORCHESTRATOR" wpf
}

installer_winui3() {
    "$INSTALLER_ORCHESTRATOR" winui3
}

installer_single() {
    "$INSTALLER_ORCHESTRATOR" winui3-single
}

installers() {
    "$INSTALLER_ORCHESTRATOR" all
}

# ============================================================
# Clean
# ============================================================

clean() {
    print_header "Cleaning .NET Build Artifacts"

    "$WPF_ORCHESTRATOR" clean
    "$WINUI3_ORCHESTRATOR" clean
    "$INSTALLER_ORCHESTRATOR" clean

    print_info "Removing frontend resources..."
    rm -rf "$FRONTEND_DIR"

    print_info "Removing backend resources..."
    rm -rf "$BACKEND_DIR"

    print_info "Removing custom Java runtime..."
    rm -rf "$RUNTIME_DIR"

    print_info "Removing publish directory..."
    rm -rf "$DOTNET_DIR/publish"

    print_success ".NET build artifacts cleaned successfully."
}

# ============================================================
# Main
# ============================================================

case "${1:-help}" in
    prepare)
        prepare_resources
        ;;
    start-wpf)
        start_wpf
        ;;
    start-winui3)
        start_winui3
        ;;
    build-wpf)
        build_wpf
        ;;
    build-winui3)
        build_winui3
        ;;
    publish-wpf)
        publish_wpf
        ;;
    publish-winui3)
        publish_winui3
        ;;
    publish-single)
        publish_single
        ;;
    installer-wpf)
        installer_wpf
        ;;
    installer-winui3)
        installer_winui3
        ;;
    installer-single)
        installer_single
        ;;
    installers)
        installers
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