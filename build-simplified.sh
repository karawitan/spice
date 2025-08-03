#!/bin/bash
set -e

# Configuration
PREFIX="/Users/kalou/spice/install"
BUILD_DIR="$(pwd)/spice-gtk-build"
SOURCE_DIR="$(pwd)/spice-gtk"

# Create directories
mkdir -p "${PREFIX}" "${BUILD_DIR}"

# Set up environment
export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:/opt/homebrew/lib/pkgconfig"
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"

# Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install six pyparsing

export PYTHONPATH="$(python3 -c 'import site; print(site.getsitepackages()[0])'):$PYTHONPATH"

# Configure with meson
cd "${BUILD_DIR}"

# Configure with meson
cd "${BUILD_DIR}"

# First configure with default options to generate build files
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
    -Dspice-common:tests=false \
    -Dspice-common:python-checks=true \
    -Dspice-common:extra-checks=false \
    -Dspice-common:alignment-checks=false \
    -Dc_args=-Wno-error=deprecated-declarations \
    -Dcoroutine=ucontext \
    -Dgtk=disabled \
    -Dc_link_args= \
    -Dcpp_link_args=

# Patch the build files to remove unsupported linker flags
find "${BUILD_DIR}" -type f -name "*.build" -o -name "*.ninja" | while read -r file; do
    LC_ALL=C sed -i '' -e 's/-export-symbols//g' -e 's/-Wl,--version-script=[^ ]* //g' "$file"
done

# Build and install
ninja
ninja install

echo "\nSpice client installed to ${PREFIX}"
echo "Add to your PATH: export PATH=\"${PREFIX}/bin:\$PATH\""
