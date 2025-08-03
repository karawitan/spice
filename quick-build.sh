#!/bin/bash
set -e

# Configuration
PREFIX="/usr/local"
BUILD_DIR="$(pwd)/quick-build"
SOURCE_DIR="$(pwd)/spice-gtk-0.42"
PACKAGE_DIR="$(pwd)/spice-client-package"

# Clean up
rm -rf "${BUILD_DIR}" "${PACKAGE_DIR}"
mkdir -p "${BUILD_DIR}" "${PACKAGE_DIR}"

# Configure with minimal options
cd "${BUILD_DIR}"
meson setup "${SOURCE_DIR}" \
    --prefix="${PREFIX}" \
    --buildtype=release \
    -Dgtk=disabled \
    -Dvapi=disabled \
    -Dpolkit=disabled \
    -Dusbredir=disabled \
    -Dsmartcard=disabled \
    -Dlz4=disabled \
    -Dintrospection=disabled \
    -Dgtk_doc=disabled \
    -Dcoroutine=ucontext \
    -Dspice-common:manual-link=false \
    -Dspice-common:generate-code=client \
    -Dspice-common:python=python3 \
    -Dc_args=-Wno-error=deprecated-declarations

# Build only the client library
ninja -C "${BUILD_DIR}" src/libspice-client-glib-2.0.dylib

# Create package
mkdir -p "${PACKAGE_DIR}/lib"
cp "${BUILD_DIR}/src/libspice-client-glib-2.0.dylib" "${PACKAGE_DIR}/lib/"

# Create a simple launcher script
cat > "${PACKAGE_DIR}/spicy" << 'EOL'
#!/bin/bash
BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export DYLD_LIBRARY_PATH="${BASEDIR}/lib:${DYLD_LIBRARY_PATH}"
"${BASEDIR}/../quick-build/src/spicy" "$@"
EOL
chmod +x "${PACKAGE_DIR}/spicy"

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
echo "  ./spicy [host] [port]"
echo ""
