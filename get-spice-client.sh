#!/bin/bash
set -e

# Configuration
VERSION="0.42"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
PACKAGE_DIR="spice-client-${VERSION}"
ZIP_FILE="spice-client-${VERSION}-${OS}-${ARCH}.zip"

# Clean up
rm -rf "${PACKAGE_DIR}" "${ZIP_FILE}"

# Create package directory
mkdir -p "${PACKAGE_DIR}"

# Create a simple script that explains how to install the dependencies
cat > "${PACKAGE_DIR}/INSTALL.txt" << 'EOL'
SPICE Client for macOS
=====================

1. Install Homebrew if you haven't already:
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

2. Install required dependencies:
   brew install spice-gtk

3. Run the SPICE client:
   spicy

To connect to a server:
   spicy spice://hostname:port

For more information: https://www.spice-space.org/
EOL

# Create a simple script that will use the system's spice-gtk
cat > "${PACKAGE_DIR}/spice-client" << 'EOL'
#!/bin/bash
echo "Checking for spice-gtk installation..."
if ! command -v spicy &> /dev/null; then
    echo "spicy command not found. Installing dependencies..."
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing spice-gtk..."
    brew install spice-gtk
fi

echo "Starting SPICE client..."
spicy "$@"
EOL
chmod +x "${PACKAGE_DIR}/spice-client"

# Create a README
cat > "${PACKAGE_DIR}/README.txt" << 'EOL'
SPICE Client Launcher for macOS
==============================

This is a simple launcher that will help you install and run the SPICE client
on your macOS system.

To use:
  1. Make the script executable: chmod +x spice-client
  2. Run it: ./spice-client spice://your-server:5900

The first time you run it, it will install the necessary dependencies
using Homebrew if they're not already installed.

For more information, see INSTALL.txt
EOL

# Create archive
echo "Creating ${ZIP_FILE}..."
zip -r "${ZIP_FILE}" "${PACKAGE_DIR}"

# Clean up
rm -rf "${PACKAGE_DIR}"

echo ""
echo "✅ Package created: ${ZIP_FILE}"
echo ""
echo "To use the SPICE client:"
echo "  unzip ${ZIP_FILE}"
echo "  cd spice-client-${VERSION}"
echo "  ./spice-client spice://your-server:5900"
echo ""
echo "The first run will install any necessary dependencies using Homebrew."
echo ""
