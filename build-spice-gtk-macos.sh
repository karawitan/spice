#!/bin/bash

set -e

# Configuration
SPICE_GTK_VERSION="0.42"
INSTALL_PREFIX="/usr/local"
BUILD_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}-build"
SOURCE_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}"

# Create build directory

# Clone source if not already present
if [ ! -d "${SPICE_DIR}/spice-gtk-0.42" ]; then
    echo "Cloning Spice-GTK 0.42..."
    git clone --depth 1 --branch "v0.42" \
        https://gitlab.freedesktop.org/spice/spice-gtk.git "${SPICE_DIR}/spice-gtk-0.42"
fi

# Copy the macOS linker script to the source directory
cp "${SPICE_DIR}/macos-link.ld" "${SPICE_DIR}/spice-gtk-0.42/src/"

# Build Spice-GTK using JHBuild
echo "Building Spice-GTK with JHBuild..."
cd "${JHBUILD_DIR}"

# Run JHBuild with our custom moduleset
jhbuild -f "${JHBUILD_DIR}/jhbuildrc" build spice-gtk

echo "\nSpice-GTK has been successfully installed to ${PREFIX}"
echo "You may need to add the following to your shell profile:"
echo "  export PATH=\"${PREFIX}/bin:${PATH}\""
echo "  export PKG_CONFIG_PATH=\"${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}\""
echo "  export DYLD_LIBRARY_PATH=\"${PREFIX}/lib:${DYLD_LIBRARY_PATH}\""

echo "\nTo test the installation, you can run:"
echo "  python3 test_spice.py"
