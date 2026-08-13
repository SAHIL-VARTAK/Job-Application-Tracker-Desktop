#!/usr/bin/env bash
set -e

# ============================================================
# Tauri Configuration
# ============================================================

TAURI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TAURI_DIR/.." && pwd)"

TAURI_SRC_DIR="$TAURI_DIR/src-tauri"

FRONTEND_DIR="$ROOT_DIR/workspace/Job-Application-Tracker-UI"

BACKEND_SOURCE_DIR="$ROOT_DIR/workspace/Job-Application-Tracker/target"
BACKEND_DIR="$TAURI_SRC_DIR/resources/backend"

RUNTIME_DIR="$TAURI_SRC_DIR/resources/runtime"

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
    echo -e "${BOLD}Job Application Tracker Tauri Manager${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./orchestrator.sh <command>"
    echo
    echo -e "${BLUE}Commands:${NC}"
    echo -e "  ${GREEN}start${NC}    Start the Tauri development application"
    echo -e "  ${GREEN}package${NC}  Create the Windows installer"
    echo -e "  ${GREEN}clean${NC}    Remove Tauri build artifacts"
    echo -e "  ${GREEN}help${NC}     Show this help message"
    echo
}

# ============================================================
# Prerequisites
# ============================================================

check_prerequisites() {
    if ! command -v cargo >/dev/null 2>&1; then
        print_error "Rust/Cargo is not installed."
        exit 1
    fi

    if ! command -v rustc >/dev/null 2>&1; then
        print_error "Rust is not installed."
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
    print_success "Rust/Cargo found."
}

# ============================================================
# Tauri Directory
# ============================================================

check_tauri_directory() {
    if [[ ! -f "$TAURI_SRC_DIR/Cargo.toml" ]]; then
        print_error "Tauri Cargo.toml was not found."
        echo
        echo "Expected:"
        echo "$TAURI_SRC_DIR/Cargo.toml"
        exit 1
    fi

    if [[ ! -f "$TAURI_SRC_DIR/tauri.conf.json" ]]; then
        print_error "Tauri configuration was not found."
        echo
        echo "Expected:"
        echo "$TAURI_SRC_DIR/tauri.conf.json"
        exit 1
    fi
}

# ============================================================
# Frontend Build Check
# ============================================================

check_frontend_build() {
    if [[ ! -f "$FRONTEND_DIR/dist/index.html" ]]; then
        print_error "React production build was not found."
        echo
        echo "Expected:"
        echo "$FRONTEND_DIR/dist/index.html"
        echo
        echo "Build the React frontend using the root orchestrator first."
        exit 1
    fi

    print_success "React production build found."
}

# ============================================================
# Copy Backend JAR
# ============================================================

copy_backend_jar() {
    print_header "Checking Spring Boot Backend"

    local existing_jar
    existing_jar=$(find "$BACKEND_DIR" -maxdepth 1 -type f -name "*.jar" | head -n 1)

    if [[ -n "$existing_jar" ]]; then
        print_info "Spring Boot JAR already exists."
        print_info "Backend:"
        echo "$existing_jar"
        return
    fi

    local jar_file
    jar_file=$(find "$BACKEND_SOURCE_DIR" -maxdepth 1 -type f -name "*.jar" | head -n 1)

    if [[ -z "$jar_file" ]]; then
        print_error "Spring Boot JAR was not found."
        echo
        echo "Expected either:"
        echo "$BACKEND_DIR/*.jar"
        echo "$BACKEND_SOURCE_DIR/*.jar"
        exit 1
    fi

    mkdir -p "$BACKEND_DIR"

    cp "$jar_file" "$BACKEND_DIR/"

    print_success "Spring Boot backend copied successfully."
    print_info "Backend:"
    echo "$BACKEND_DIR/$(basename "$jar_file")"
}

# ============================================================
# Create Custom Java Runtime
# ============================================================

create_runtime() {
    print_header "Creating Custom Java Runtime"

    if [[ -f "$RUNTIME_DIR/bin/java.exe" ]] &&
       [[ -f "$RUNTIME_DIR/bin/javaw.exe" ]]; then

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

    if [[ ! -f "$RUNTIME_DIR/bin/javaw.exe" ]]; then
        print_error "javaw.exe was not found in the custom runtime."
        exit 1
    fi

    print_success "Custom Java runtime created successfully."
}


# ============================================================
# Start Tauri Development Application
# ============================================================

start() {
    check_prerequisites
    check_tauri_directory

    copy_backend_jar
    create_runtime

    print_header "Starting Job Application Tracker Tauri"

    (
        cd "$TAURI_SRC_DIR"
        cargo tauri dev
    )
}

# ============================================================
# Package Tauri Application
# ============================================================

package() {
    check_prerequisites
    check_tauri_directory
    check_frontend_build

    copy_backend_jar
    create_runtime

    print_header "Creating Job Application Tracker Windows Installer"

    (
        cd "$TAURI_SRC_DIR"
        cargo tauri build
    )

    print_success "Tauri Windows build completed successfully."

    print_info "Build directory:"
    echo "$TAURI_SRC_DIR/target/release/"

    print_info "Installer directory:"
    echo "$TAURI_SRC_DIR/target/release/bundle/"

    print_info "Available installers:"

    find "$TAURI_SRC_DIR/target/release/bundle" \
        -type f \
        \( -name "*.exe" -o -name "*.msi" \) \
        -print 2>/dev/null || true
}

# ============================================================
# Clean Tauri Build Artifacts
# ============================================================

clean() {
    check_tauri_directory

    print_header "Cleaning Tauri Build Artifacts"

    print_info "Removing Rust/Tauri target..."
    rm -rf "$TAURI_SRC_DIR/target"

    print_info "Removing custom Java runtime..."
    rm -rf "$RUNTIME_DIR"

    print_info "Removing copied Spring Boot backend..."
    rm -rf "$BACKEND_DIR"

    print_success "Tauri build artifacts cleaned successfully."
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
