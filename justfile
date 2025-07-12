# Termlectron build and packaging commands

# Build the Rust application
build:
    cargo build --release

# Run the application with Alacritty
run:
    #!/usr/bin/env bash
    # Build the application
    cargo build
    
    # Generate Alacritty config from termectron.toml (TOML format)
    # Read values from termectron.toml
    NAME=$(grep '^name = ' termectron.toml | cut -d'"' -f2)
    WIDTH=$(grep '^width = ' termectron.toml | cut -d' ' -f3)
    HEIGHT=$(grep '^height = ' termectron.toml | cut -d' ' -f3)
    FULLSCREEN=$(grep '^fullscreen = ' termectron.toml | cut -d' ' -f3)
    
    echo "[window]" > alacritty.toml
    echo "title = \"$NAME\"" >> alacritty.toml
    if [ "$FULLSCREEN" = "true" ]; then
        echo "startup_mode = \"Fullscreen\"" >> alacritty.toml
    fi
    echo "" >> alacritty.toml
    echo "[window.dimensions]" >> alacritty.toml
    echo "columns = $WIDTH" >> alacritty.toml
    echo "lines = $HEIGHT" >> alacritty.toml
    
    # Launch Alacritty with the terminal app
    ./alacritty/alacritty --config-file ./alacritty.toml -e $(pwd)/target/debug/termectron


# Package for macOS (.app bundle)
package-macos:
    #!/usr/bin/env bash
    cargo build --release
    NAME=$(grep '^name = ' termectron.toml | cut -d'"' -f2)
    WIDTH=$(grep '^width = ' termectron.toml | cut -d' ' -f3)
    HEIGHT=$(grep '^height = ' termectron.toml | cut -d' ' -f3)
    FULLSCREEN=$(grep '^fullscreen = ' termectron.toml | cut -d' ' -f3)
    
    # Generate Alacritty config
    echo "[window]" > alacritty.toml
    echo "title = \"$NAME\"" >> alacritty.toml
    if [ "$FULLSCREEN" = "true" ]; then
        echo "startup_mode = \"Fullscreen\"" >> alacritty.toml
    fi
    echo "" >> alacritty.toml
    echo "[window.dimensions]" >> alacritty.toml
    echo "columns = $WIDTH" >> alacritty.toml
    echo "lines = $HEIGHT" >> alacritty.toml
    
    # Copy the actual binary to the expected name
    cp target/release/termectron "target/release/$NAME"
    ./scripts/package-macos.sh "$NAME"

# Package for Linux (AppImage)
package-linux:
    #!/usr/bin/env bash
    cargo build --release
    NAME=$(grep '^name = ' termectron.toml | cut -d'"' -f2)
    # Copy the actual binary to the expected name
    cp target/release/termectron "target/release/$NAME"
    ./scripts/package-linux.sh "$NAME"

# Package for Windows (.exe)
package-windows:
    #!/usr/bin/env bash
    cargo build --release
    NAME=$(grep '^name = ' termectron.toml | cut -d'"' -f2)
    # Copy the actual binary to the expected name
    cp target/release/termectron "target/release/$NAME"
    ./scripts/package-windows.sh "$NAME"

# Clean build artifacts
clean:
    cargo clean
    rm -f alacritty.yml alacritty.toml
    rm -rf termectron-builds

# Install dependencies (requires just to be installed)
install:
    cargo build

# Download Alacritty binaries for current platform
download-alacritty:
    ./scripts/download-alacritty.sh

# Show current platform info
platform-info:
    #!/usr/bin/env bash
    echo "OS: $(uname -s)"
    echo "Architecture: $(uname -m)"
    echo "Alacritty binary status:"
    if [ -f "alacritty/alacritty" ]; then
        echo "  ✓ Found at alacritty/alacritty"
        file alacritty/alacritty
    elif [ -f "alacritty/alacritty.exe" ]; then
        echo "  ✓ Found at alacritty/alacritty.exe"
    else
        echo "  ✗ Not found - run 'just download-alacritty'"
    fi
