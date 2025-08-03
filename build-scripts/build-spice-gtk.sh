#!/bin/bash

set -e

# Configuration
SPICE_GTK_VERSION="0.42"
INSTALL_PREFIX="/usr/local"
BUILD_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}-build"
SOURCE_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}"

# Create build directory
mkdir -p "${BUILD_DIR}"

# Clone source if not already present
if [ ! -d "${SOURCE_DIR}" ]; then
    git clone --depth 1 --branch "v${SPICE_GTK_VERSION}" \
        https://gitlab.freedesktop.org/spice/spice-gtk.git "${SOURCE_DIR}"
    
    # Apply patches
    cd "${SOURCE_DIR}"
    patch -p1 < "../macos-spice-gtk-fixes.patch"
fi

# Configure build
cd "${BUILD_DIR}"
meson setup "${SOURCE_DIR}" \
    --prefix="${INSTALL_PREFIX}" \
    --buildtype=release \
    -Dgtk=enabled \
    -Dvapi=true \
    -Dpolkit=disabled \
    -Dsmartcard=disabled \
    -Dusbredir=disabled \
    -Dintrospection=enabled \
    -Dgtk_doc=disabled \
    -Dvapi=true \
    -Dopus=enabled \
    -Dlz4=disabled \
    -Dgtk_doc=disabled

# Build
ninja

# Install
sudo ninja install

# Update dynamic linker cache
sudo ldconfig

echo "Spice-GTK ${SPICE_GTK_VERSION} has been successfully installed to ${INSTALL_PREFIX}"
