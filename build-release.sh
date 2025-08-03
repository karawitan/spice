#!/bin/bash
set -e

# Configuration
SPICE_VERSION="0.42"
INSTALL_PREFIX="/usr/local"
BUILD_DIR="$(pwd)/spice-gtk-${SPICE_VERSION}-build"
SOURCE_DIR="$(pwd)/spice-gtk-${SPICE_VERSION}"
PACKAGE_DIR="$(pwd)/spice-gtk-${SPICE_VERSION}-macos"

# Clean up previous builds
rm -rf "${BUILD_DIR}" "${PACKAGE_DIR}"
mkdir -p "${BUILD_DIR}" "${PACKAGE_DIR}"

# Clone source if not present
if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Cloning Spice-GTK ${SPICE_VERSION}..."
    git clone --depth 1 --branch "v${SPICE_VERSION}" \
        https://gitlab.freedesktop.org/spice/spice-gtk.git "${SOURCE_DIR}"
fi

# Apply patches if needed
if [ -f "macos-spice-gtk-fixes.patch" ]; then
    echo "Applying macOS patches..."
    cd "${SOURCE_DIR}"
    if ! git apply --check "../macos-spice-gtk-fixes.patch" 2>/dev/null; then
        echo "Patch already applied or can't be applied cleanly, skipping..."
    else
        git apply "../macos-spice-gtk-fixes.patch"
    fi
    cd ..
fi

# Copy macOS linker script if it exists
if [ -f "macos-link.ld" ]; then
    echo "Copying macOS linker script..."
    cp -f "macos-link.ld" "${SOURCE_DIR}/src/"
fi

# Configure build
echo "Configuring Spice-GTK..."
cd "${BUILD_DIR}"

# Set up build environment
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"

# Activate Python virtual environment
if [ -f "venv/bin/activate" ]; then
    echo "Activating Python virtual environment..."
    source venv/bin/activate
else
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install six pyparsing
fi

# Run meson build with minimal options
meson setup \
    --prefix="${INSTALL_PREFIX}" \
    --buildtype=release \
    -Dgtk_doc=disabled \
    -Dvapi=disabled \
    -Dpolkit=disabled \
    -Dusbredir=disabled \
    -Dsmartcard=disabled \
    -Dlz4=disabled \
    -Dintrospection=disabled \
    -Dspice-common:manual-link=false \
    -Dc_link_args=-Wl,-exported_symbols_list,${SOURCE_DIR}/src/spice-glib-sym-file \
    -Dspice-common:generate-code=client \
    -Dspice-common:python=python3 \
    -Dspice-common:tests=false \
    -Dspice-common:python-checks=true \
    -Dspice-common:extra-checks=false \
    -Dspice-common:alignment-checks=false \
    "${SOURCE_DIR}"

# Build
echo "Building Spice-GTK..."
ninja -C "${BUILD_DIR}"

# Install to package directory
echo "Creating package..."
DESTDIR="${PACKAGE_DIR}" ninja -C "${BUILD_DIR}" install

# Fix library paths
find "${PACKAGE_DIR}${INSTALL_PREFIX}/lib" -name "*.dylib" -type f | while read lib; do
    install_name_tool -id "@rpath/$(basename "$lib")" "$lib"
    
    # Update dependencies
    otool -L "$lib" | grep "${INSTALL_PREFIX}" | awk '{print $1}' | while read dep; do
        install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$lib"
    done
done

# Create a DMG package
echo "Creating DMG package..."
DMG_NAME="spice-gtk-${SPICE_VERSION}-macos.dmg"
hdiutil create \
    -volname "Spice-GTK ${SPICE_VERSION}" \
    -srcfolder "${PACKAGE_DIR}" \
    -ov -format UDZO "${DMG_NAME}"

echo "\nBuild complete!"
echo "DMG package created: ${DMG_NAME}"
echo "To install, copy the contents of ${PACKAGE_DIR} to ${INSTALL_PREFIX}"
