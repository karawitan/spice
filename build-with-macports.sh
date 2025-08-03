#!/bin/bash
set -e

# Configuration
PREFIX="/Users/kalou/spice/install"
BUILD_DIR="$(pwd)/spice-gtk-build"
SOURCE_DIR="$(pwd)/spice-gtk"
MACPORTS_PREFIX="/opt/local"

# Create directories
mkdir -p "${PREFIX}" "${BUILD_DIR}"

# Function to install MacPorts
install_macports() {
    echo "MacPorts not found. Installing MacPorts..."
    
    # Download and install MacPorts
    # For macOS 15 (Sequoia) - trying this for macOS 26.0
    MACPORTS_PKG="MacPorts-2.11.4-15-Sequoia.pkg"
    curl -O "https://distfiles.macports.org/MacPorts/${MACPORTS_PKG}"
    
    # Install MacPorts (requires sudo)
    echo "Please enter your password to install MacPorts:"
    sudo installer -pkg "${MACPORTS_PKG}" -target /
    
    # Add MacPorts to PATH
    export PATH="${MACPORTS_PREFIX}/bin:${PATH}"
    echo 'export PATH="/opt/local/bin:/opt/local/sbin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
    
    # Update MacPorts
    sudo port -v selfupdate
    
    # Install basic tools
    sudo port install git pkgconfig
}

# Check if MacPorts is installed
if ! command -v port &> /dev/null; then
    install_macports
fi

# Install required dependencies
echo "Installing build dependencies with MacPorts..."
sudo port install \
    meson ninja \
    pkgconfig \
    intltool \
    gettext \
    gtk-doc \
    vala \
    gobject-introspection \
    python313 \
    cairo \
    gdk-pixbuf2 \
    glib2 \
    gstreamer1-gst-plugins-base \
    gtk3 \
    jpeg-turbo \
    json-glib \
    libepoxy \
    libsoup3 \
    libusb \
    lz4 \
    openssl3 \
    opus \
    pango \
    phodav \
    pixman \
    spice-protocol \
    usbredir \
    libvpx \
    orc \
    libnice \
    gstreamer1-gst-plugins-good \
    gstreamer1-gst-plugins-bad \
    gstreamer1-gst-libav

# Set up Python virtual environment
python3.13 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install six pyparsing

# Set up environment
export PATH="${MACPORTS_PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${MACPORTS_PREFIX}/lib/pkgconfig:${MACPORTS_PREFIX}/share/pkgconfig"
export LDFLAGS="-L${MACPORTS_PREFIX}/lib"
export CPPFLAGS="-I${MACPORTS_PREFIX}/include"
export PYTHONPATH="$(python3 -c 'import site; print(site.getsitepackages()[0])'):$PYTHONPATH"

# Clone spice-gtk if not exists
if [ ! -d "${SOURCE_DIR}" ]; then
    echo "Cloning spice-gtk..."
    git clone https://gitlab.freedesktop.org/spice/spice-gtk.git "${SOURCE_DIR}"
    cd "${SOURCE_DIR}"
    git checkout v0.42  # Use the latest stable version
    cd ..
fi

# Configure with meson
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
    -Dspice-common:python=python3.13 \
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
