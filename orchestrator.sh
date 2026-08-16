#!/usr/bin/env bash

set -e

# ============================================================
# Repository Configuration
# ============================================================

BACKEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker.git"
FRONTEND_REPO="https://github.com/SAHIL-VARTAK/Job-Application-Tracker-UI.git"

WORKSPACE_DIR="workspace"

BACKEND_NAME="Job-Application-Tracker"
FRONTEND_NAME="Job-Application-Tracker-UI"

BACKEND_DIR="$WORKSPACE_DIR/$BACKEND_NAME"
FRONTEND_DIR="$WORKSPACE_DIR/$FRONTEND_NAME"

ELECTRON_DIR="electron"
TAURI_DIR="tauri"
DOTNET_DIR="dotnet"

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
    echo -e "${BOLD}Job Application Tracker Repository Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}clone${NC}    Clone the backend and frontend repositories"
    echo -e "  ${GREEN}update${NC}   Pull the latest changes from both repositories"
    echo -e "  ${GREEN}build${NC}    Build the backend JAR and frontend production bundle"
    echo -e "  ${GREEN}clean${NC}    Remove all build artifacts"
    echo -e "  ${GREEN}electron-start${NC}    Start the Electron application"
    echo -e "  ${GREEN}electron-package${NC}  Create the Windows installer using Electron Builder"
    echo -e "  ${GREEN}electron-clean${NC}  Remove Electron build artifacts"
    echo -e "  ${GREEN}tauri-start${NC}    Start the Tauri application"
    echo -e "  ${GREEN}tauri-package${NC}  Create the Windows installer using Tauri"
    echo -e "  ${GREEN}tauri-clean${NC}  Remove Tauri build artifacts"
    echo -e "  ${GREEN}dotnet-prepare${NC}          Prepare frontend, backend and Java runtime"
    echo -e "  ${GREEN}dotnet-start-wpf${NC}       Start the WPF application"
    echo -e "  ${GREEN}dotnet-start-winui3${NC}    Start the WinUI 3 application"
    echo -e "  ${GREEN}dotnet-build-wpf${NC}       Build the WPF application"
    echo -e "  ${GREEN}dotnet-build-winui3${NC}    Build the WinUI 3 application"
    echo -e "  ${GREEN}dotnet-publish-wpf${NC}     Publish the WPF application"
    echo -e "  ${GREEN}dotnet-publish-winui3${NC}  Publish the WinUI 3 application"
    echo -e "  ${GREEN}dotnet-publish-single${NC}  Publish WinUI 3 single-file"
    echo -e "  ${GREEN}dotnet-installer-wpf${NC}   Create the WPF installer"
    echo -e "  ${GREEN}dotnet-installer-winui3${NC} Create the WinUI 3 installer"
    echo -e "  ${GREEN}dotnet-installer-single${NC} Create the WinUI 3 single-file installer"
    echo -e "  ${GREEN}dotnet-installers${NC}      Create all .NET installers"
    echo -e "  ${GREEN}dotnet-clean${NC}           Remove .NET build artifacts"
    echo -e "  ${GREEN}help${NC}     Show this help message"
    echo
}

# ============================================================
# Prerequisites
# ============================================================

check_prerequisites() {
    if ! command -v git >/dev/null 2>&1; then
        print_error "Git is not installed."
        exit 1
    fi

    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js is not installed."
        exit 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm is not installed."
        exit 1
    fi
}

# ============================================================
# Workspace
# ============================================================

create_workspace() {
    mkdir -p "$WORKSPACE_DIR"
}

# ============================================================
# Clone Repository
# ============================================================

clone_repository() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name="$3"

    if [[ -d "$target_dir/.git" ]]; then
        print_info "$repo_name already exists. Skipping clone."
        return
    fi

    if [[ -d "$target_dir" ]]; then
        print_error "$target_dir exists but is not a Git repository."
        exit 1
    fi

    print_info "Cloning $repo_name..."

    git clone "$repo_url" "$target_dir"

    print_success "$repo_name cloned successfully."
}

# ============================================================
# Clone Both Repositories
# ============================================================

clone() {
    check_prerequisites
    create_workspace

    print_header "Cloning Job Application Tracker"

    clone_repository \
        "$BACKEND_REPO" \
        "$BACKEND_DIR" \
        "$BACKEND_NAME"

    clone_repository \
        "$FRONTEND_REPO" \
        "$FRONTEND_DIR" \
        "$FRONTEND_NAME"

    print_header "Repositories ready"
}

# ============================================================
# Update Repository
# ============================================================

update_repository() {
    local repo_dir="$1"
    local repo_name="$2"

    if [[ ! -d "$repo_dir/.git" ]]; then
        print_error "$repo_name was not found."
        echo
        echo "Run './orchestrator.sh clone' first."
        exit 1
    fi

    echo
    print_info "Updating $repo_name..."

    (
        cd "$repo_dir"

        git fetch --all --prune

        current_branch=$(git rev-parse --abbrev-ref HEAD)

        print_info "$repo_name branch: $current_branch"

        git pull --ff-only origin "$current_branch"
    )

    print_success "$repo_name updated successfully."
}

# ============================================================
# Update Both Repositories
# ============================================================

update() {
    check_prerequisites
    create_workspace

    print_header "Updating Job Application Tracker"

    update_repository \
        "$BACKEND_DIR" \
        "$BACKEND_NAME"

    update_repository \
        "$FRONTEND_DIR" \
        "$FRONTEND_NAME"

    print_header "Repositories updated"
}

# ============================================================
# Build Both Applications
# ============================================================

build_backend() {
    print_info "Building backend..."

    if [[ ! -d "$BACKEND_DIR/.git" ]]; then
        print_error "Backend repository not found."
        echo "Run './orchestrator.sh clone' first."
        exit 1
    fi

    (
        cd "$BACKEND_DIR"

        chmod +x mvnw

        ./mvnw clean package
    )

    print_success "Backend built successfully."
}

build_frontend() {
    print_info "Building frontend..."

    if [[ ! -d "$FRONTEND_DIR/.git" ]]; then
        print_error "Frontend repository not found."
        echo "Run './orchestrator.sh clone' first."
        exit 1
    fi

    (
        cd "$FRONTEND_DIR"

        npm ci
        npm run build
    )

    print_success "Frontend built successfully."
}

build() {
    check_prerequisites
    create_workspace

    print_header "Building Job Application Tracker"

    build_backend

    echo

    build_frontend

    print_header "Build completed successfully"
}

# ============================================================
# Electron
# ============================================================

electron_start() {
    print_header "Starting Job Application Tracker Electron"

    bash "$ELECTRON_DIR/orchestrator.sh" start
}

electron_package() {
    print_header "Creating Job Application Tracker Windows Installer using Electron Builder"

    bash "$ELECTRON_DIR/orchestrator.sh" package

    print_header "Electron packaging completed successfully"
}

electron_clean() {
    print_header "Cleaning Electron build artifacts"

    bash "$ELECTRON_DIR/orchestrator.sh" clean

    print_header "Electron clean completed successfully"
}

# ============================================================
# Tauri
# ============================================================

tauri_start() {
    print_header "Starting Job Application Tracker Tauri"

    bash "$TAURI_DIR/orchestrator.sh" start
}

tauri_package() {
    print_header "Creating Job Application Tracker Windows Installer using Tauri"

    bash "$TAURI_DIR/orchestrator.sh" package

    print_header "Tauri packaging completed successfully"
}

tauri_clean() {
    print_header "Cleaning Tauri build artifacts"

    bash "$TAURI_DIR/orchestrator.sh" clean

    print_header "Tauri clean completed successfully"
}

# ============================================================
# .NET
# ============================================================

dotnet_prepare() {
    print_header "Preparing Job Application Tracker .NET"

    bash "$DOTNET_DIR/orchestrator.sh" prepare

    print_header ".NET preparation completed successfully"
}

dotnet_start_wpf() {
    print_header "Starting Job Application Tracker WPF"

    bash "$DOTNET_DIR/orchestrator.sh" start-wpf
}

dotnet_start_winui3() {
    print_header "Starting Job Application Tracker WinUI 3"

    bash "$DOTNET_DIR/orchestrator.sh" start-winui3
}

dotnet_build_wpf() {
    print_header "Building Job Application Tracker WPF"

    bash "$DOTNET_DIR/orchestrator.sh" build-wpf

    print_header "WPF build completed successfully"
}

dotnet_build_winui3() {
    print_header "Building Job Application Tracker WinUI 3"

    bash "$DOTNET_DIR/orchestrator.sh" build-winui3

    print_header "WinUI 3 build completed successfully"
}

dotnet_publish_wpf() {
    print_header "Publishing Job Application Tracker WPF"

    bash "$DOTNET_DIR/orchestrator.sh" publish-wpf

    print_header "WPF publish completed successfully"
}

dotnet_publish_winui3() {
    print_header "Publishing Job Application Tracker WinUI 3"

    bash "$DOTNET_DIR/orchestrator.sh" publish-winui3

    print_header "WinUI 3 publish completed successfully"
}

dotnet_publish_single() {
    print_header "Publishing Job Application Tracker WinUI 3 Single-File"

    bash "$DOTNET_DIR/orchestrator.sh" publish-single

    print_header "WinUI 3 single-file publish completed successfully"
}

dotnet_installer_wpf() {
    print_header "Creating Job Application Tracker WPF Installer"

    bash "$DOTNET_DIR/orchestrator.sh" installer-wpf

    print_header "WPF installer created successfully"
}

dotnet_installer_winui3() {
    print_header "Creating Job Application Tracker WinUI 3 Installer"

    bash "$DOTNET_DIR/orchestrator.sh" installer-winui3

    print_header "WinUI 3 installer created successfully"
}

dotnet_installer_single() {
    print_header "Creating Job Application Tracker WinUI 3 Single-File Installer"

    bash "$DOTNET_DIR/orchestrator.sh" installer-single

    print_header "WinUI 3 single-file installer created successfully"
}

dotnet_installers() {
    print_header "Creating All Job Application Tracker .NET Installers"

    bash "$DOTNET_DIR/orchestrator.sh" installers

    print_header ".NET installers created successfully"
}

dotnet_clean() {
    print_header "Cleaning .NET build artifacts"

    bash "$DOTNET_DIR/orchestrator.sh" clean

    print_header ".NET clean completed successfully"
}

# ============================================================
# Clean Workspace
# ============================================================

clean() {
    print_header "Cleaning Job Application Tracker Workspace"

    if [[ ! -d "$WORKSPACE_DIR" ]]; then
        print_info "Workspace directory does not exist."
        return
    fi

    print_info "Removing workspace: $WORKSPACE_DIR"

    rm -rf "$WORKSPACE_DIR"

    print_success "Workspace cleaned successfully."
}

# ============================================================
# Main
# ============================================================

case "${1:-help}" in
    clone)
        clone
        ;;
    update)
        update
        ;;
    build)
        build
        ;;
    clean)
        clean
        ;;

    electron-start)
        electron_start
        ;;
    electron-package)
        electron_package
        ;;
    electron-clean)
        electron_clean
        ;;

    tauri-start)
        tauri_start
        ;;
    tauri-package)
        tauri_package
        ;;
    tauri-clean)
        tauri_clean
        ;;

    dotnet-prepare)
        dotnet_prepare
        ;;
    dotnet-start-wpf)
        dotnet_start_wpf
        ;;
    dotnet-start-winui3)
        dotnet_start_winui3
        ;;
    dotnet-build-wpf)
        dotnet_build_wpf
        ;;
    dotnet-build-winui3)
        dotnet_build_winui3
        ;;
    dotnet-publish-wpf)
        dotnet_publish_wpf
        ;;
    dotnet-publish-winui3)
        dotnet_publish_winui3
        ;;
    dotnet-publish-single)
        dotnet_publish_single
        ;;
    dotnet-installer-wpf)
        dotnet_installer_wpf
        ;;
    dotnet-installer-winui3)
        dotnet_installer_winui3
        ;;
    dotnet-installer-single)
        dotnet_installer_single
        ;;
    dotnet-installers)
        dotnet_installers
        ;;
    dotnet-clean)
        dotnet_clean
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
