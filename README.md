# SPICE-GTK macOS Build

This directory contains the files and patches needed to build SPICE-GTK on macOS with all features enabled.

## Files

- `build-spice-gtk.sh` - Build script for SPICE-GTK on macOS
- `0001-Fix-macOS-build-issues-and-enable-all-features.patch` - Patch file with all the fixes for macOS
- `spice-gtk-macos-build-summary.md` - Summary of the build process and results
- `test-spice-simple.sh` - Simple test script to verify SPICE client functionality
- `demonstrate-recorder.sh` - Script to demonstrate the recorder feature
- `spice-test.vv` - SPICE connection configuration file for testing

## Build Process

1. Run `./build-spice-gtk.sh` to build SPICE-GTK with all features enabled
2. The build will be installed in `/Users/kalou/spice/install`
3. Run `./test-spice-simple.sh` to verify the build
4. Run `./demonstrate-recorder.sh` to specifically test the recorder feature

## Features Enabled

- WebDAV support
- GTK interface
- USB redirection
- LZ4 compression
- GObject introspection
- Recorder instrumentation

## macOS-Specific Fixes

The patch file contains fixes for:
- GTK library symbol visibility issues
- Linker flag compatibility
- Meson build script syntax errors
- Coroutine implementation selection
- Version script handling

## QEMU Integration

For QEMU integration with SPICE support on macOS:
1. Uninstall existing QEMU: `brew uninstall qemu`
2. Install dependencies: `brew install spice-protocol spice-server`
3. Try to build QEMU from source with SPICE support enabled

Note: There may be Xcode version compatibility issues that need to be resolved for QEMU building.

## Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools
- Homebrew
- pyenv with Python 3.11.9

## Setup

1. Install dependencies:
   ```bash
   # Install build tools
   xcode-select --install
   
   # Install Homebrew if not installed
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   
   # Install dependencies
   brew install meson ninja pkg-config glib json-glib gstreamer gst-plugins-base gst-plugins-good \
                gst-plugins-bad gst-libav cairo gtk+3 gtk-doc openssl@3 jpeg-turbo opus
   
   # Install pyenv and Python
   brew install pyenv
   pyenv install 3.11.9
   pyenv virtualenv 3.11.9 spice-env
   pyenv activate spice-env
   pip install --upgrade pip
   ```

## Building Spice-GTK

1. Clone the repository and apply patches:
   ```bash
   git clone https://gitlab.freedesktop.org/spice/spice-gtk.git
   cd spice-gtk
   git checkout v0.42
   patch -p1 < ../macos-spice-gtk-fixes.patch
   ```

2. Configure and build:
   ```bash
   meson setup build \
     --prefix=/usr/local \
     --buildtype=release \
     -Dgtk=enabled \
     -Dvapi=true \
     -Dpolkit=disabled \
     -Dsmartcard=disabled \
     -Dusbredir=disabled \
     -Dintrospection=disabled \
     -Dgtk_doc=disabled \
     -Dvapi=true \
     -Dopus=enabled \
     -Dlz4=disabled \
     -Dgtk_doc=disabled
   
   ninja -C build
   ```

3. Install:
   ```bash
   DESTDIR=/path/to/install ninja -C build install
   ```

## Environment Variables

Add these to your shell profile:

```bash
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
export DYLD_LIBRARY_PATH="/usr/local/lib:$DYLD_LIBRARY_PATH"
export PATH="/usr/local/bin:$PATH"
```

## Testing

To verify the installation, run:

```bash
spicy --version
```

## License

This project is licensed under the LGPL-2.1 license.
