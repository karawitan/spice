#!/bin/bash

# Set up environment
export PATH=$PATH:/Users/kalou/spice/jhbuild-src/bin
export PYTHONPATH=/Users/kalou/spice/jhbuild-src

# Check GLib version
echo "Checking GLib version..."
glib-config --version

# Check GStreamer version
echo "Checking GStreamer version..."
pkg-config --modversion gstreamer-1.0

# Check Cogl version
echo "Checking Cogl version..."
pkg-config --modversion cogl-1.0

# Check spice-gtk version
echo "Checking spice-gtk version..."
pkg-config --modversion spice-gtk-0.20
