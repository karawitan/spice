#!/bin/bash
set -e

echo "=== Simple Spice Connection Test ==="

# Check if spicy is available
if ! command -v spicy &> /dev/null; then
    echo "Installing spicy client..."
    brew install spice-gtk
fi

# Test basic spicy functionality
echo "Testing SPICE client installation..."
echo "==================================="
echo "SPICE client (spicy) version:"
/Users/kalou/spice/install/bin/spicy --version 2>&1

echo ""
echo "Checking for recorder symbols in library:"
nm /Users/kalou/spice/install/lib/libspice-client-glib-2.0.dylib | grep -c record

echo ""
echo "SPICE client build verification complete."

# Create a simple test configuration
cat > spice-test.vv << 'EOF'
[virt-viewer]
type=spice
host=localhost
port=5900
fullscreen=0
EOF

echo "=== Test Configuration Created ==="
echo "Created spice-test.vv file for testing"
echo ""
echo "To test Spice connection, you can:"
echo "1. Run a Spice server on localhost:5900"
echo "2. Connect with: spicy -h localhost -p 5900"
echo "3. Or use the config file: spicy --spice-file spice-test.vv"
echo ""
echo "=== Alternative Test Options ==="
echo ""
echo "Option 1: Use Docker (if available)"
echo "  docker run -d -p 5900:5900 --name spice-test \"
echo "    alpine:latest sh -c 'apk add --no-cache spice-server && spice-server --port 5900 --disable-ticketing'"
echo ""
echo "Option 2: Use QEMU with Spice"
echo "  qemu-system-x86_64 -m 512 -spice port=5900,disable-ticketing -vga qxl"
echo ""
echo "Option 3: Use existing Spice server"
echo "  If you have access to a Proxmox, KVM, or other Spice-enabled server"
echo "  spicy -h <server-ip> -p <port>"
echo ""
echo "=== Quick Connection Test ==="
echo "You can test the connection with:"
echo "  nc -z localhost 5900 && echo 'Port 5900 is open' || echo 'Port 5900 is closed'"
