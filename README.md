# Termectron

A minimal framework that lets Rust developers build **terminal UI applications** and package them into standalone, cross-platform GUI-like executables (macOS .app, Linux .AppImage, Windows .exe) — using **Alacritty** instead of a browser engine.

This provides an **Electron-like experience for the terminal**.

<img width="916" height="367" alt="image" src="https://github.com/user-attachments/assets/6d54b957-b92d-40d6-b0f5-28d2706297b3" />


## Warning

Honestly this project is very dumb, it may be not very secure, be careful when using it. I wouldn't recommend it for production usage. But I believe this still a fun project to play with! Enjoy! :D

## Features

- 🦀 **Rust-based**: Build terminal applications in Rust
- 🖥️ **Cross-platform packaging**: Create native app bundles for macOS, Linux, and Windows
- ⚡ **Fast**: Uses Alacritty terminal emulator
- 📦 **Simple configuration**: Single TOML file for app settings
- 🎨 **Customizable**: Configure window size, fullscreen mode, and icons

## Quick Start

### 1. Install Dependencies

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Just (task runner)
cargo install just

# Create your Termectron project
git clone https://github.com/LRiceCooker/Termectron.git <your project name>
```

### 2. Download Alacritty Binaries

The Termectron dev mode requires you to install an Alacritty binary compatible with your current OS.

```bash
# Download for your current platform
just download-alacritty
```

### 3. Configure Your App

Edit `termectron.toml`:

```toml
name = "MyAwesomeApp"
entry = "src/main.rs"
fullscreen = false
width = 120
height = 30
icon = "assets/icon.ico"
```

### 4. Build and Run

```bash
# Build your Rust application
just build

# Run with Alacritty
just run
```

## Configuration Reference

### termectron.toml

| Field        | Type    | Description                 | Default         |
| ------------ | ------- | --------------------------- | --------------- |
| `name`       | String  | Application name (required) | -               |
| `entry`      | String  | Entry point file            | `"src/main.rs"` |
| `fullscreen` | Boolean | Start in fullscreen mode    | `false`         |
| `width`      | Integer | Terminal width in columns   | `80`            |
| `height`     | Integer | Terminal height in lines    | `24`            |
| `icon`       | String  | Path to app icon            | -               |

## Packaging for Distribution

### macOS (.app bundle)

```bash
just package-macos
```

Creates `MyApp.app` bundle with:

- Embedded Alacritty and your Rust binary
- Proper macOS app structure
- Icon support (.icns)
- Double-click to launch

### Linux (AppImage)

```bash
just package-linux
```

Creates `MyApp.AppImage` with:

- Portable single-file executable
- Works on most Linux distributions
- Icon and desktop integration
- Requires `appimagetool` (auto-downloaded if needed)

### Windows (Portable .exe)

```bash
just package-windows
```

Creates `MyApp-windows-portable.zip` with:

- Portable directory with all dependencies
- Batch file launcher
- Icon support (.ico)
- No installation required

## Example Terminal Application

Here's a simple example of a Rust terminal application:

```rust
// src/main.rs
fn main() {
    println!("Hello from MyTerminalApp!");
    println!("This is a simple terminal application running inside Alacritty.");
    println!("Press Enter to exit...");
    let mut input = String::new();
    std::io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");

    // Your actual terminal application logic goes here
    // For now, this is just a demo
}
```

## Project Structure

```
my-terminal-app/
├── justfile                 # Build and package commands
├── termectron.toml          # App configuration
├── Cargo.toml               # Rust dependencies
├── alacritty/               # Alacritty binaries
│   └── alacritty           # Downloaded binary for dev mode
├── scripts/                 # Packaging scripts
│   ├── package-macos.sh
│   ├── package-linux.sh
│   └── package-windows.sh
├── src/
│   └── main.rs             # Your Rust application
├── assets/                 # Icons and resources
│   └── icon.png
└── README.md
```

## Advanced Usage

### Using with TUI Libraries

Termectron works great with Rust TUI libraries:

```toml
# Cargo.toml
[dependencies]
ratatui = "0.24"
crossterm = "0.27"
```

### Embedding Assets

Use `include_bytes!` to embed assets in your binary:

```rust
const SOMETHING: &[u8] = include_bytes!("../assets/something.txt");

fn main() {
    println!("{}", String::from_utf8_lossy(SOMETHING));
}
```

## Commands Reference

| Command                   | Description                      |
| ------------------------- | -------------------------------- |
| `just build`              | Build the Rust application       |
| `just run`                | Run your application in dev mode |
| `just package-macos`      | Package for macOS                |
| `just package-linux`      | Package for Linux                |
| `just package-windows`    | Package for Windows              |
| `just download-alacritty` | Download Alacritty binary        |
| `just platform-info`      | Show platform information        |
| `just clean`              | Clean build artifacts            |

## Troubleshooting

### Alacritty Binary Not Found

```bash
# Check if binary exists
just platform-info

# Download for your platform
just download-alacritty
```

### Build Errors

```bash
# Clean and rebuild
just clean
just build
```

### Permission Issues (Linux/macOS)

```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x alacritty/alacritty
```

## Platform Support Roadmap

Current development and testing status:

### ✅ macOS

- [x] Development mode (`just run`)
- [x] App bundle packaging (`just package-macos`)
- [x] Icon support (.ico → .icns conversion)
- [x] Code signing (ad-hoc)
- [x] Fully tested and working

### ⚠️ Windows

- [ ] Development mode (`just run`) - Not tested
- [ ] Portable .exe packaging (`just package-windows`) - Not tested
- [ ] Icon support - Not tested
- [ ] Testing needed

### ⚠️ Linux

- [ ] Development mode (`just run`) - Not tested
- [ ] AppImage packaging (`just package-linux`) - Not tested
- [ ] Icon support - Not tested
- [ ] Testing needed

**Note**: While packaging scripts exist for Windows and Linux, they haven't been tested yet. macOS is the primary development platform and is fully functional.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms
5. Submit a pull request

## License

Beerware - see LICENSE file for details.

## Inspiration

- [Electron](https://www.electronjs.org/) - For the packaging concept
- [Alacritty](https://alacritty.org/) - For the fast terminal emulator
- [Tauri](https://tauri.app/) - For Rust-based app development inspiration
