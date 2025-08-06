#!/bin/bash

set -e

# Configuration
SPICE_GTK_VERSION="0.42"
INSTALL_PREFIX="/Users/kalou/spice/install"
BUILD_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}-build"
SOURCE_DIR="$(pwd)/spice-gtk-${SPICE_GTK_VERSION}"

# Create build and install directories
mkdir -p "${BUILD_DIR}" "${INSTALL_PREFIX}"

# Install Homebrew dependencies if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install required dependencies
echo "Installing build dependencies..."
# Install required dependencies
echo "Installing build dependencies..."
brew install pkg-config meson ninja glib gtk+3 cairo openssl@3 opus jpeg-turbo json-glib libusb spice-protocol
brew install gstreamer gst-plugins-base gst-plugins-good gst-libav
brew install libsoup orc libnice libvpx

# Install optional dependencies
echo "Installing optional dependencies..."
brew install libsrtp || echo "libsrtp not available, continuing without it"

# Update pkg-config paths
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"

# Install ccache for faster builds
if ! command -v ccache &> /dev/null; then
    echo "Installing ccache..."
    brew install ccache
fi

# Set up compiler environment
export CC="/usr/bin/cc"
export CXX="/usr/bin/c++"

# Set up build flags
export LDFLAGS="-L/opt/homebrew/lib -lspice-protocol -lspice-client-glib-2.0 -lspice-client-gtk-3.0 -lspice-controller"
export CPPFLAGS="-I/opt/homebrew/include -I/opt/homebrew/include/spice-client-glib-2.0 -I/opt/homebrew/include/spice-1"

# Ensure we can find Homebrew's pkg-config
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/spice-protocol/share/pkgconfig:${PKG_CONFIG_PATH}"

# Check for required commands
for cmd in meson ninja pkg-config clang; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is required but not installed."
        exit 1
    fi
done

# Clone source if not present
if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Cloning Spice-GTK ${SPICE_GTK_VERSION}..."
    git clone --depth 1 --branch "v${SPICE_GTK_VERSION}" \
        https://gitlab.freedesktop.org/spice/spice-gtk.git "${SOURCE_DIR}"
fi

# Set up environment
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"

# Configure build
echo "Configuring Spice-GTK..."
cd "${BUILD_DIR}"
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
ninja

# Install
echo "Installing Spice-GTK..."
ninja install

# Fix rpath for macOS
echo "Fixing library paths..."
find "${INSTALL_PREFIX}/lib" -name "*.dylib" -exec install_name_tool -add_rpath "${INSTALL_PREFIX}/lib" {} \;

echo "\nBuild and installation complete!"
echo "Spice-GTK has been installed to: ${INSTALL_PREFIX}"
echo "You may want to add ${INSTALL_PREFIX}/bin to your PATH"
