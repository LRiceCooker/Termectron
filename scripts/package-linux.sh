#!/bin/bash
set -euo pipefail

APP_NAME="$1"
BUILD_DIR="termectron-builds/linux"
APP_DIR="${BUILD_DIR}/AppDir"
APPIMAGE_NAME="${BUILD_DIR}/${APP_NAME}.AppImage"

echo "Packaging ${APP_NAME} for Linux (AppImage)..."

# Create build directory and clean up any existing AppDir
mkdir -p "${BUILD_DIR}"
rm -rf "${APP_DIR}"
rm -f "${APPIMAGE_NAME}"

# Create AppDir structure
mkdir -p "${APP_DIR}"

# Copy Alacritty binary
if [ ! -f "alacritty/alacritty" ]; then
    echo "Error: Alacritty binary not found at alacritty/alacritty"
    echo "Please download and extract Alacritty binary first"
    exit 1
fi

cp "alacritty/alacritty" "${APP_DIR}/"

# Copy app binary
APP_BINARY="target/release/${APP_NAME}"
if [ ! -f "${APP_BINARY}" ]; then
    echo "Error: App binary not found at ${APP_BINARY}"
    echo "Please build the app first with 'cargo build --release'"
    exit 1
fi

cp "${APP_BINARY}" "${APP_DIR}/"

# Copy Alacritty config
cp "alacritty.yml" "${APP_DIR}/"

# Create AppRun launcher script
cat > "${APP_DIR}/AppRun" << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
exec ./alacritty --config-file ./alacritty.yml -e ./${APP_NAME}
EOF

chmod +x "${APP_DIR}/AppRun"

# Create desktop file
cat > "${APP_DIR}/${APP_NAME}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Exec=AppRun
Icon=${APP_NAME}
Categories=Utility;
EOF

# Copy icon if it exists
if [ -f "icon.png" ]; then
    cp "icon.png" "${APP_DIR}/${APP_NAME}.png"
elif [ -f "assets/icon.png" ]; then
    cp "assets/icon.png" "${APP_DIR}/${APP_NAME}.png"
else
    # Create a simple placeholder icon
    echo "Warning: No icon found, creating placeholder"
    # Create a simple 64x64 PNG placeholder (this is a base64 encoded 1x1 transparent PNG)
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" | base64 -d > "${APP_DIR}/${APP_NAME}.png"
fi

# Make binaries executable
chmod +x "${APP_DIR}/alacritty"
chmod +x "${APP_DIR}/${APP_NAME}"

# Check if appimagetool is available
if command -v appimagetool >/dev/null 2>&1; then
    echo "Creating AppImage with appimagetool..."
    appimagetool "${APP_DIR}" "${APPIMAGE_NAME}"
    echo "✅ Linux AppImage created: ${APPIMAGE_NAME}"
else
    echo "⚠️  appimagetool not found. AppDir created at: ${APP_DIR}"
    echo "To create the AppImage, install appimagetool and run:"
    echo "appimagetool ${APP_DIR} ${APPIMAGE_NAME}"
    echo ""
    echo "You can download appimagetool from:"
    echo "https://github.com/AppImage/AppImageKit/releases"
    echo ""
    echo "For now, you can test the app by running:"
    echo "./${APP_DIR}/AppRun"
fi