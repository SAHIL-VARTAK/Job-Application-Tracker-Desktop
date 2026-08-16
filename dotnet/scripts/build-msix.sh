#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTNET_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT="$DOTNET_DIR/WinUI3/WinUI3.csproj"
CERTIFICATE="$DOTNET_DIR/JobApplicationTracker-Dev.pfx"
OUTPUT="$DOTNET_DIR/publish/WinUI3-MSIX"

# ============================================================
# Locate SignTool
# ============================================================

SIGNTOOL=$(find "/c/Program Files (x86)/Windows Kits/10/bin" \
    -type f \
    -path "*/x64/signtool.exe" \
    2>/dev/null | sort -V | tail -n 1)

if [ -z "$SIGNTOOL" ]; then
    echo "Error: signtool.exe was not found."
    exit 1
fi

echo "SignTool:"
echo "$SIGNTOOL"

ENV_FILE="$DOTNET_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Check certificate
if [ ! -f "$CERTIFICATE" ]; then
    echo "Error: signing certificate not found:"
    echo "$CERTIFICATE"
    exit 1
fi

# Check SignTool
if [ ! -f "$SIGNTOOL" ]; then
    echo "Error: signtool.exe not found:"
    echo "$SIGNTOOL"
    exit 1
fi

# Check certificate password
if [ -z "${MSIX_CERT_PASSWORD:-}" ]; then
    echo "Error: MSIX_CERT_PASSWORD environment variable is not set."
    echo
    echo "Set it with:"
    echo "  export MSIX_CERT_PASSWORD='your-password'"
    exit 1
fi

# Remove previous MSIX output
rm -rf "$OUTPUT"
mkdir -p "$OUTPUT"

echo
echo "Building MSIX..."

dotnet build "$PROJECT" \
    -c Release \
    -p:Platform=x64 \
    -p:GenerateAppxPackageOnBuild=true \
    -p:AppxPackageDir="$OUTPUT/"

# Find generated MSIX
MSIX=$(find "$OUTPUT" -type f -name "*.msix" | head -n 1)

if [ -z "$MSIX" ]; then
    echo
    echo "Error: MSIX package was not generated."
    exit 1
fi

echo
echo "MSIX generated:"
echo "$MSIX"

# Convert Git Bash paths to Windows paths
CERTIFICATE_WIN=$(cygpath -w "$CERTIFICATE")
MSIX_WIN=$(cygpath -w "$MSIX")

echo
echo "Signing MSIX..."

MSYS_NO_PATHCONV=1 "$SIGNTOOL" sign \
    /fd SHA256 \
    /tr http://timestamp.digicert.com \
    /td SHA256 \
    /f "$CERTIFICATE_WIN" \
    /p "$MSIX_CERT_PASSWORD" \
    "$MSIX_WIN"

echo
echo "Verifying signature..."

MSYS_NO_PATHCONV=1 "$SIGNTOOL" verify \
    /pa \
    /v \
    "$MSIX_WIN"

echo
echo "========================================"
echo "MSIX build and signing completed."
echo "========================================"
echo
echo "Output:"
echo "$MSIX"