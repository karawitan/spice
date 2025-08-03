#!/bin/bash

# Create installation directories
INSTALL_PREFIX="/Users/kalou/spice/spice-jhbuild/install"
LIB_DIR="$INSTALL_PREFIX/lib"
INCLUDE_DIR="$INSTALL_PREFIX/include/spice-client-glib-2.0"
PKG_CONFIG_DIR="$INSTALL_PREFIX/lib/pkgconfig"

mkdir -p "$LIB_DIR" "$INCLUDE_DIR" "$PKG_CONFIG_DIR"

# Copy libraries
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/build/src/libspice-client-glib-2.0*.dylib "$LIB_DIR/"
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/build/src/libspice-client-gtk-3.0*.dylib "$LIB_DIR/"
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/build/subprojects/spice-common/common/libspice-common*.a "$LIB_DIR/"

# Copy headers
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/build/src/*.h "$INCLUDE_DIR/"
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/subprojects/spice-common/common/*.h "$INCLUDE_DIR/"
cp -v /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/src/*.h "$INCLUDE_DIR/"

# Create symlinks for development
cd "$LIB_DIR"
ln -sf libspice-client-glib-2.0.8.dylib libspice-client-glib-2.0.dylib
ln -sf libspice-client-gtk-3.0.5.dylib libspice-client-gtk-3.0.dylib

# Update pkg-config paths
for pc in /Users/kalou/spice/spice-jhbuild/checkout/spice-gtk-0.42/build/meson-private/*.pc; do
  sed -e "s|^prefix=.*|prefix=$INSTALL_PREFIX|" \
      -e "s|-I/usr/local/include|-I$INCLUDE_DIR|" \
      -e "s|-L/usr/local/lib|-L$LIB_DIR|" \
      < "$pc" > "$PKG_CONFIG_DIR/$(basename "$pc")"
done

echo "Libraries and headers have been installed to $INSTALL_PREFIX"
echo "Add the following to your environment:"
echo "export PKG_CONFIG_PATH=\"$PKG_CONFIG_PATH:$PKG_CONFIG_DIR\""
echo "export DYLD_LIBRARY_PATH=\"$DYLD_LIBRARY_PATH:$LIB_DIR\""
