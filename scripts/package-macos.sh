#!/bin/bash
set -euo pipefail

APP_NAME="$1"
BUILD_DIR="termectron-builds/macos"
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Packaging ${APP_NAME} for macOS..."

# Create build directory and clean up any existing .app bundle
mkdir -p "${BUILD_DIR}"
rm -rf "${APP_DIR}"

# Create .app bundle structure
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Download and copy Alacritty binary for macOS
ALACRITTY_DIR="termectron-builds/binaries/macos"
mkdir -p "$ALACRITTY_DIR"

if [ ! -f "$ALACRITTY_DIR/alacritty" ]; then
    echo "Downloading Alacritty for macOS..."
    
    # Get the latest release download URL (use the same pattern as download-alacritty.sh)
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/alacritty/alacritty/releases/latest | grep "browser_download_url.*\.dmg" | cut -d '"' -f 4)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "❌ Failed to get Alacritty download URL"
        exit 1
    fi
    
    TEMP_FILE="/tmp/Alacritty.dmg"
    
    # Download the DMG with progress
    echo "Downloading from: $DOWNLOAD_URL"
    curl -L --progress-bar "$DOWNLOAD_URL" -o "$TEMP_FILE"
    
    # Mount the DMG
    echo "Mounting DMG..."
    MOUNT_POINT=$(hdiutil attach "$TEMP_FILE" -nobrowse | grep "/Volumes" | cut -f3 | tail -1)
    
    if [ -z "$MOUNT_POINT" ]; then
        echo "❌ Failed to mount DMG"
        rm "$TEMP_FILE"
        exit 1
    fi
    
    # Extract the Alacritty binary from the app bundle
    echo "Extracting binary..."
    cp "$MOUNT_POINT/Alacritty.app/Contents/MacOS/alacritty" "$ALACRITTY_DIR/alacritty"
    
    # Unmount and clean up
    hdiutil detach "$MOUNT_POINT" > /dev/null
    rm "$TEMP_FILE"
    
    chmod +x "$ALACRITTY_DIR/alacritty"
    echo "✅ macOS Alacritty binary downloaded"
fi

cp "$ALACRITTY_DIR/alacritty" "${MACOS_DIR}/Alacritty"

# Copy app binary
APP_BINARY="target/release/${APP_NAME}"
if [ ! -f "${APP_BINARY}" ]; then
    echo "Error: App binary not found at ${APP_BINARY}"
    echo "Please build the app first with 'cargo build --release'"
    exit 1
fi

cp "${APP_BINARY}" "${MACOS_DIR}/${APP_NAME}"

# Copy Alacritty config
cp "alacritty.toml" "${RESOURCES_DIR}/"

# Handle icon - convert from termectron.toml config
ICON_PATH=$(grep '^icon = ' termectron.toml | cut -d'"' -f2 2>/dev/null || echo "")
if [ -n "$ICON_PATH" ] && [ -f "$ICON_PATH" ]; then
    echo "Processing icon: $ICON_PATH"
    if [[ "$ICON_PATH" == *.ico ]]; then
        # Convert .ico to .icns
        sips -s format icns "$ICON_PATH" --out "${RESOURCES_DIR}/icon.icns" 2>/dev/null || {
            echo "Warning: Failed to convert .ico to .icns, trying to copy as is"
            cp "$ICON_PATH" "${RESOURCES_DIR}/"
        }
    elif [[ "$ICON_PATH" == *.icns ]]; then
        # Copy .icns directly
        cp "$ICON_PATH" "${RESOURCES_DIR}/"
    else
        echo "Warning: Unsupported icon format. Use .ico or .icns"
    fi
elif [ -f "icon.icns" ]; then
    cp "icon.icns" "${RESOURCES_DIR}/"
elif [ -f "assets/icon.icns" ]; then
    cp "assets/icon.icns" "${RESOURCES_DIR}/"
fi

# Create launcher script
cat > "${MACOS_DIR}/launcher" << EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$SCRIPT_DIR/Alacritty" --config-file "\$SCRIPT_DIR/../Resources/alacritty.toml" -e "\$SCRIPT_DIR/${APP_NAME}"
EOF

chmod +x "${MACOS_DIR}/launcher"

# Create Info.plist
cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.termectron.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.14</string>
EOF

# Add icon reference if icon exists
if [ -f "${RESOURCES_DIR}/icon.icns" ]; then
    cat >> "${CONTENTS_DIR}/Info.plist" << EOF
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
EOF
fi

cat >> "${CONTENTS_DIR}/Info.plist" << EOF
</dict>
</plist>
EOF

# Make binaries executable
chmod +x "${MACOS_DIR}/Alacritty"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Sign the app bundle (use ad-hoc signature for local development)
echo "Signing app bundle..."
codesign --force --deep --sign - "${APP_DIR}" 2>/dev/null || {
    echo "Warning: Code signing failed. App may not run on newer macOS versions."
    echo "To fix this, you can manually run: codesign --force --deep --sign - ${APP_DIR}"
}

echo "✅ macOS app bundle created: ${APP_DIR}"
echo "You can now run: open ${APP_DIR}"
