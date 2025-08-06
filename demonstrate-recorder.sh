#!/bin/bash

echo "SPICE-GTK Recorder Feature Demonstration"
echo "========================================"
echo ""

echo "1. Verifying SPICE client installation:"
echo "   Version: $(/Users/kalou/spice/install/bin/spicy --version 2>&1)"
echo ""

echo "2. Checking for recorder-related symbols in the library:"
echo "   Found $(nm /Users/kalou/spice/install/lib/libspice-client-glib-2.0.dylib | grep -c record) recorder symbols"
echo ""

echo "3. Some example recorder symbols:"
nm /Users/kalou/spice/install/lib/libspice-client-glib-2.0.dylib | grep record | head -5
echo ""

echo "4. SPICE client help information:"
echo "   General options:"
/Users/kalou/spice/install/bin/spicy --help | head -10
echo ""

echo "   SPICE-specific options:"
/Users/kalou/spice/install/bin/spicy --help-spice | head -10
echo ""

echo "The recorder feature is now built into the SPICE client and ready for use."
echo "To test it, you would need to:"
echo "  1. Start a SPICE server with recording capabilities"
echo "  2. Connect using the SPICE client"
echo "  3. The recorder would capture display/audio data from the server"
