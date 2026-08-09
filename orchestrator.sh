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
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
