#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"
ALACRITTY_DIR="alacritty"

print_info "Downloading Alacritty for $OS ($ARCH)..."

# Create alacritty directory if it doesn't exist
mkdir -p "$ALACRITTY_DIR"
cd "$ALACRITTY_DIR"

# Clean up any existing files
rm -f alacritty alacritty.exe Alacritty.dmg Alacritty-*.AppImage Alacritty-windows-portable.zip

case "$OS" in
    "Darwin")
        print_info "Downloading Alacritty for macOS..."

        # Get the latest release DMG URL
        print_info "Finding latest Alacritty release..."
        DMG_URL=$(curl -s https://api.github.com/repos/alacritty/alacritty/releases/latest | grep "browser_download_url.*\.dmg" | cut -d '"' -f 4)
        
        if [ -z "$DMG_URL" ]; then
            print_error "Could not find DMG download URL"
            exit 1
        fi
        
        print_info "Downloading DMG from: $DMG_URL"
        curl -L -o Alacritty.dmg "$DMG_URL"

        print_info "Mounting DMG..."
        # Mount the DMG and get the mount point
        ATTACH_OUTPUT=$(hdiutil attach Alacritty.dmg -nobrowse 2>&1)
        MOUNT_POINT=$(echo "$ATTACH_OUTPUT" | grep "/Volumes/" | awk '{print $NF}')

        if [ -z "$MOUNT_POINT" ]; then
            print_error "Failed to mount DMG"
            exit 1
        fi

        print_info "Extracting Alacritty binary from $MOUNT_POINT..."

        # Find the Alacritty.app bundle and extract the binary
        if [ -d "$MOUNT_POINT/Alacritty.app" ]; then
            cp "$MOUNT_POINT/Alacritty.app/Contents/MacOS/alacritty" ./alacritty
            chmod +x ./alacritty
            print_success "Alacritty binary extracted successfully"
        else
            print_error "Alacritty.app not found in DMG"
            hdiutil detach "$MOUNT_POINT" -quiet
            exit 1
        fi

        # Unmount the DMG
        print_info "Unmounting DMG..."
        hdiutil detach "$MOUNT_POINT" -quiet

        # Clean up DMG file
        rm -f Alacritty.dmg

        print_success "macOS Alacritty binary ready at alacritty/alacritty"
        ;;

    "Linux")
        print_info "Downloading Alacritty AppImage for Linux..."

        # Try to find AppImage URL
        print_info "Finding latest Alacritty release..."
        APPIMAGE_URL=$(curl -s https://api.github.com/repos/alacritty/alacritty/releases/latest | grep "browser_download_url.*AppImage" | cut -d '"' -f 4)
        
        if [ -n "$APPIMAGE_URL" ]; then
            print_info "Downloading AppImage from: $APPIMAGE_URL"
            if curl -L -f -o Alacritty-x86_64.AppImage "$APPIMAGE_URL" 2>/dev/null; then
                chmod +x Alacritty-x86_64.AppImage
                print_info "AppImage downloaded successfully"
            else
                print_error "Failed to download AppImage"
                exit 1
            fi
        else
            print_error "Linux AppImage not available for latest release"
            print_info "Please install Alacritty using your package manager:"
            print_info "  Ubuntu/Debian: sudo apt install alacritty"
            print_info "  Fedora: sudo dnf install alacritty"  
            print_info "  Arch: sudo pacman -S alacritty"
            print_info "Then create a symlink: ln -s \$(which alacritty) ./alacritty"
            exit 1
        fi

        print_info "Extracting binary from AppImage..."

        # Extract the AppImage
        ./Alacritty-x86_64.AppImage --appimage-extract > /dev/null 2>&1

        if [ -f "squashfs-root/usr/bin/alacritty" ]; then
            cp squashfs-root/usr/bin/alacritty ./alacritty
            chmod +x ./alacritty
            print_success "Alacritty binary extracted successfully"
        else
            print_error "Failed to extract alacritty binary from AppImage"
            exit 1
        fi

        # Clean up extraction files
        rm -rf squashfs-root Alacritty-x86_64.AppImage

        print_success "Linux Alacritty binary ready at alacritty/alacritty"
        ;;

    "MINGW"*|"MSYS"*|"CYGWIN"*)
        print_info "Downloading Alacritty for Windows..."

        # Get the latest release portable exe URL
        print_info "Finding latest Alacritty release..."
        PORTABLE_URL=$(curl -s https://api.github.com/repos/alacritty/alacritty/releases/latest | grep "browser_download_url.*portable\.exe" | cut -d '"' -f 4)
        
        if [ -z "$PORTABLE_URL" ]; then
            print_error "Could not find portable exe download URL"
            exit 1
        fi
        
        print_info "Downloading portable exe from: $PORTABLE_URL"
        curl -L -o Alacritty-portable.exe "$PORTABLE_URL"

        # The portable exe is the binary itself
        if [ -f "Alacritty-portable.exe" ]; then
            mv "Alacritty-portable.exe" "alacritty.exe"
            chmod +x ./alacritty.exe
            print_success "Windows Alacritty binary ready at alacritty/alacritty.exe"
        else
            print_error "Failed to download Alacritty portable executable"
            exit 1
        fi
        ;;

    *)
        print_error "Unsupported operating system: $OS"
        print_info "Supported platforms:"
        print_info "  - macOS (Darwin)"
        print_info "  - Linux"
        print_info "  - Windows (MINGW/MSYS/Cygwin)"
        print_info ""
        print_info "Please manually download Alacritty from:"
        print_info "https://github.com/alacritty/alacritty/releases/latest"
        exit 1
        ;;
esac

# Verify the binary works
cd ..
print_info "Verifying Alacritty binary..."

if [ "$OS" = "Darwin" ] || [ "$OS" = "Linux" ]; then
    if ./alacritty/alacritty --version >/dev/null 2>&1; then
        VERSION=$(./alacritty/alacritty --version)
        print_success "Verification successful: $VERSION"
    else
        print_warning "Binary extracted but version check failed (this might be normal)"
    fi
elif [[ "$OS" == "MINGW"* ]] || [[ "$OS" == "MSYS"* ]] || [[ "$OS" == "CYGWIN"* ]]; then
    if [ -f "alacritty/alacritty.exe" ]; then
        print_success "Windows binary ready (version check skipped)"
    else
        print_error "Windows binary not found"
        exit 1
    fi
fi

print_success "Alacritty download and extraction completed!"
print_info "You can now run: just build && just run"
