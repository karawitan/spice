#!/bin/bash
set -e

echo "🚀 Creating minimal SPICE client package..."

# Create package directory
PACKAGE_DIR="spice-client-minimal"
rm -rf "${PACKAGE_DIR}"
mkdir -p "${PACKAGE_DIR}/lib"

# Copy the pre-built binary (if available)
if [ -f "spice-gtk-0.42/src/spicy" ]; then
    cp "spice-gtk-0.42/src/spicy" "${PACKAGE_DIR}/"
    echo "✅ Copied spicy client"
else
    echo "⚠️  Warning: spicy binary not found. Building from source..."
    
    # Install dependencies if needed
    if ! command -v meson >/dev/null; then
        echo "Installing build dependencies..."
        brew install meson ninja pkg-config
    fi
    
    # Build
    mkdir -p build
    cd build
    meson .. -Dgtk=disabled -Dvapi=disabled -Dpolkit=disabled -Dusbredir=disabled \
             -Dsmartcard=disabled -Dlz4=disabled -Dintrospection=disabled -Dgtk_doc=disabled \
             -Dspice-common:generate-code=client -Dspice-common:python=python3
    ninja
    cd ..
    
    cp "build/src/spicy" "${PACKAGE_DIR}/"
fi

# Copy required libraries
echo "📦 Collecting dependencies..."

# Create a simple launcher script
cat > "${PACKAGE_DIR}/spice-client" << 'EOL'
#!/bin/bash
BASEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DYLD_LIBRARY_PATH="${BASEDIR}/lib" "${BASEDIR}/spicy" "$@"
EOL
chmod +x "${PACKAGE_DIR}/spice-client"

# Create README
cat > "${PACKAGE_DIR}/README.txt" << 'EOL'
SPICE Client for macOS
=====================

To connect to a SPICE server:
    ./spice-client spice://hostname:port

Dependencies:
- GTK+ 3.0
- OpenSSL
- Other required libraries should be in the lib/ directory

For more information: https://www.spice-space.org/
EOL

# Create archive
VERSION="0.42"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ZIP_FILE="spice-client-${VERSION}-${OS}-${ARCH}.zip"

echo "📦 Creating ${ZIP_FILE}..."
zip -r "${ZIP_FILE}" "${PACKAGE_DIR}"

echo ""
echo "✅ Package created: ${ZIP_FILE}"
echo ""
echo "To use the SPICE client:"
echo "  unzip ${ZIP_FILE}"
echo "  cd ${PACKAGE_DIR}"
echo "  ./spice-client spice://your-server:5900"
echo ""
