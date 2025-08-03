#!/bin/bash
set -e

# Configuration
PREFIX="/Users/kalou/spice/install"
BUILD_DIR="$(pwd)/spice-gtk-build"
SOURCE_DIR="$(pwd)/spice-gtk"

# Create directories
mkdir -p "${PREFIX}" "${BUILD_DIR}"

# Install build dependencies
echo "Installing build dependencies..."
brew install \
    cmake \
    pkg-config \
    intltool \
    gettext \
    gtk-doc \
    vala \
    gobject-introspection \
    python@3.13 \
    cairo \
    gdk-pixbuf \
    glib \
    gstreamer \
    gst-plugins-base \
    gtk+3 \
    jpeg-turbo \
    json-glib \
    libepoxy \
    libsoup \
    libusb \
    lz4 \
    openssl@3 \
    opus \
    pango \
    phodav \
    pixman \
    spice-protocol \
    usbredir \
    libvpx \
    orc \
    libnice

# Set up Python virtual environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install six pyparsing

# Clone spice-gtk if not exists
if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Cloning spice-gtk..."
    git clone https://gitlab.freedesktop.org/spice/spice-gtk.git "${SOURCE_DIR}"
    cd "${SOURCE_DIR}"
    git checkout v0.42  # Use the latest stable version
    cd ..
fi

# Configure and build
cd "${BUILD_DIR}"

# Set up environment
export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig:/opt/homebrew/lib/pkgconfig"
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"

# Configure with CMake
cd "${BUILD_DIR}"
cmake "${SOURCE_DIR}/src" \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_GTK_DOC=OFF \
    -DENABLE_VAPI=OFF \
    -DENABLE_POLKIT=OFF \
    -DENABLE_USBREDIR=OFF \
    -DENABLE_SMART_CARD=OFF \
    -DENABLE_LZ4=OFF \
    -DENABLE_INTROSPECTION=OFF \
    -DWITH_SASL=OFF \
    -DWITH_GTK=ON \
    -DWITH_GSTREAMER=ON \
    -DWITH_OPENGL=ON \
    -DWITH_GTK=ON \
    -DSPICE_GTK_LOCALEDIR="${PREFIX}/share/locale"

# Build and install
make -j$(sysctl -n hw.ncpu)
make install

echo "\nSpice client installed to ${PREFIX}"
echo "Add to your PATH: export PATH=\"${PREFIX}/bin:\$PATH\""
