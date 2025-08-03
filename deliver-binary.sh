#!/bin/bash
set -e

# Configuration
PREFIX="/usr/local"
BUILD_DIR="$(pwd)/spice-build"
SOURCE_DIR="$(pwd)/spice-gtk-0.42"
PACKAGE_DIR="$(pwd)/spice-client-package"

# Clean previous builds
rm -rf "${BUILD_DIR}" "${PACKAGE_DIR}"
mkdir -p "${BUILD_DIR}" "${PACKAGE_DIR}"

# Install dependencies if needed
if ! command -v meson >/dev/null || ! command -v ninja >/dev/null; then
    echo "Installing build dependencies..."
    brew install meson ninja pkg-config
fi

# Configure
cd "${BUILD_DIR}"
meson setup "${SOURCE_DIR}" \
    --prefix="${PREFIX}" \
    --buildtype=release \
    -Dgtk_doc=disabled \
    -Dvapi=disabled \
    -Dpolkit=disabled \
    -Dusbredir=disabled \
    -Dsmartcard=disabled \
    -Dlz4=disabled \
    -Dintrospection=disabled \
    -Dspice-common:manual-link=false \
    -Dspice-common:generate-code=client \
    -Dspice-common:python=python3 \
    -Dc_args=-Wno-error=deprecated-declarations \
    -Dcoroutine=ucontext \
    -Dgtk=disabled

# Build
ninja

# Create package
DESTDIR="${PACKAGE_DIR}" ninja install

# Create archive
VERSION="0.42"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ZIP_FILE="spice-client-${VERSION}-${OS}-${ARCH}.zip"

cd "${PACKAGE_DIR}"
zip -r "${ZIP_FILE}" .
mv "${ZIP_FILE}" ..

echo ""
echo "Package created: $(pwd)/../${ZIP_FILE}"
echo ""
echo "To use the SPICE client:"
echo "  unzip ${ZIP_FILE}"
echo "  ./bin/spicy [host] [port]"
echo ""
