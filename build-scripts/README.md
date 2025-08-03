# Spice-GTK Build Scripts for macOS arm64

This directory contains scripts to build Spice-GTK on macOS arm64.

## Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools
- Homebrew
- Python 3.11.9 (recommended, managed by pyenv)

## Dependencies

```bash
# Install build tools
xcode-select --install

# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install meson ninja pkg-config glib json-glib gstreamer gst-plugins-base gst-plugins-good \
             gst-plugins-bad gst-libav cairo gtk+3 gtk-doc openssl@3 jpeg-turbo opus \
             gobject-introspection

# Install pyenv and Python (recommended)
brew install pyenv
pyenv install 3.11.9
pyenv virtualenv 3.11.9 spice-env
pyenv activate spice-env
pip install --upgrade pip PyGObject
```

## Building Spice-GTK

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd spice/build-scripts
   ```

2. Run the build script:
   ```bash
   ./build-spice-gtk.sh
   ```

   This will:
   - Download Spice-GTK 0.42 source
   - Apply necessary patches for macOS arm64
   - Build and install to /usr/local

## Verifying the Installation

Run the test script to verify the installation:

```bash
python3 test_spice.py
```

## Troubleshooting

### Python Bindings

If you encounter issues with Python bindings, ensure that:

1. The GObject-Introspection typelib files are in your `GI_TYPELIB_PATH`:
   ```bash
   export GI_TYPELIB_PATH="/usr/local/lib/girepository-1.0:$GI_TYPELIB_PATH"
   ```

2. The library path is set correctly:
   ```bash
   export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
   ```

### Build Issues

If the build fails due to missing dependencies, ensure all required packages are installed:

```bash
brew install <missing-package>
```

## License

This project is licensed under the LGPL-2.1 license.
