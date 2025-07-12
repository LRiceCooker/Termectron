#!/bin/bash
set -euo pipefail

APP_NAME="$1"
BUILD_DIR="termectron-builds/windows"
APP_DIR="${BUILD_DIR}/${APP_NAME}-windows"
ZIP_NAME="${BUILD_DIR}/${APP_NAME}-windows-portable.zip"

echo "Packaging ${APP_NAME} for Windows..."

# Create build directory and clean up any existing package directory
mkdir -p "${BUILD_DIR}"
rm -rf "${APP_DIR}"
rm -f "${ZIP_NAME}"

# Create package directory
mkdir -p "${APP_DIR}"

# Download and copy Alacritty binary for Windows
ALACRITTY_DIR="termectron-builds/binaries/windows"
mkdir -p "$ALACRITTY_DIR"

if [ ! -f "$ALACRITTY_DIR/alacritty.exe" ]; then
    echo "Downloading Alacritty for Windows..."
    
    # Get the latest release download URL (use the same pattern as download-alacritty.sh)
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/alacritty/alacritty/releases/latest | grep "browser_download_url.*portable\.exe" | cut -d '"' -f 4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "❌ Failed to get Alacritty download URL"
        exit 1
    fi
    
    # Download the portable exe directly
    echo "Downloading from: $DOWNLOAD_URL"
    curl -L --progress-bar "$DOWNLOAD_URL" -o "$ALACRITTY_DIR/alacritty.exe"
    echo "✅ Windows Alacritty binary downloaded"
fi

cp "$ALACRITTY_DIR/alacritty.exe" "${APP_DIR}/"

# Copy app binary
APP_BINARY="target/release/${APP_NAME}.exe"
if [ ! -f "${APP_BINARY}" ]; then
    echo "Error: App binary not found at ${APP_BINARY}"
    echo "Please build the app first with 'cargo build --release'"
    exit 1
fi

cp "${APP_BINARY}" "${APP_DIR}/"

# Copy Alacritty config
cp "alacritty.yml" "${APP_DIR}/"

# Create launcher batch file
cat > "${APP_DIR}/run.bat" << EOF
@echo off
cd /d "%~dp0"
start "" alacritty.exe --config-file alacritty.yml -e ${APP_NAME}.exe
EOF

# Copy icon if it exists
if [ -f "icon.ico" ]; then
    cp "icon.ico" "${APP_DIR}/"
elif [ -f "assets/icon.ico" ]; then
    cp "assets/icon.ico" "${APP_DIR}/"
elif [ -f "icon.png" ]; then
    cp "icon.png" "${APP_DIR}/"
elif [ -f "assets/icon.png" ]; then
    cp "assets/icon.png" "${APP_DIR}/"
else
    echo "Warning: No icon found"
fi

# Create README for the package
cat > "${APP_DIR}/README.txt" << EOF
# ${APP_NAME} - Portable Windows Package

## Running the Application

Double-click run.bat to start the application.

Alternatively, open a command prompt in this directory and run:
alacritty.exe --config-file alacritty.yml -e ${APP_NAME}.exe

## Files

- alacritty.exe - Terminal emulator
- ${APP_NAME}.exe - Your application
- alacritty.yml - Terminal configuration
- run.bat - Launcher script (recommended)

## Requirements

This is a portable package and should run on Windows 10 and later without additional dependencies.
EOF

# Create ZIP archive if zip is available
if command -v zip >/dev/null 2>&1; then
    echo "Creating ZIP archive..."
    zip -r "${ZIP_NAME}" "${APP_DIR}"
    echo "✅ Windows portable package created: ${ZIP_NAME}"
else
    echo "⚠️  zip command not found. Package directory created at: ${APP_DIR}"
    echo "You can manually create a ZIP file or install zip utility"
fi

echo ""
echo "To test the package on Windows:"
echo "1. Copy ${APP_DIR} to a Windows machine"
echo "2. Double-click run.bat"