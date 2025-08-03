#!/bin/bash
set -e

# Configuration
PYTHON_VERSION=3.11.9
VENV_NAME=spice-build-env
PYENV_ROOT="$HOME/.pyenv"
PYENV="$PYENV_ROOT/bin/pyenv"
VENV_PATH="$PYENV_ROOT/versions/$PYTHON_VERSION/envs/$VENV_NAME"
PYTHON_BIN="$VENV_PATH/bin/python"
PIP="$VENV_PATH/bin/pip"

# Check if pyenv is installed
if [ ! -f "$PYENV" ]; then
    echo "Error: pyenv not found at $PYENV"
    echo "Please install it first: https://github.com/pyenv/pyenv#installation"
    exit 1
fi

# Add pyenv to PATH if needed
export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

# Install Python version if needed
if ! $PYENV versions --bare | grep -q "^$PYTHON_VERSION$"; then
    echo "Installing Python $PYTHON_VERSION..."
    $PYENV install -s $PYTHON_VERSION
fi

# Create virtual environment if needed
if ! $PYENV prefix $VENV_NAME &>/dev/null; then
    echo "Creating virtual environment '$VENV_NAME'..."
    $PYENV virtualenv $PYTHON_VERSION $VENV_NAME || {
        echo "Failed to create virtual environment"
        exit 1
    }
    
    # Activate the virtual environment
    export PYENV_VERSION=$VENV_NAME
    
    # Upgrade pip and install build dependencies
    $PIP install --upgrade pip setuptools wheel
    $PIP install meson ninja
    
    # Install build dependencies via Homebrew
    echo "Installing build dependencies via Homebrew..."
    brew install pkg-config openssl@3 libffi cairo gtk+3 gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-libav
    
    # Install jhbuild
    echo "Installing jhbuild..."
    cd /tmp
    if [ ! -d "jhbuild" ]; then
        git clone https://gitlab.gnome.org/GNOME/jhbuild.git || {
            echo "Failed to clone jhbuild"
            exit 1
        }
    fi
    
    cd jhbuild
    $PYTHON setup.py install --user || {
        echo "Failed to install jhbuild"
        exit 1
    }
    
    export PATH="$HOME/.local/bin:$PATH"
fi

# Activate the virtual environment
export PYENV_VERSION=$VENV_NAME
export PATH="$VENV_PATH/bin:$PATH"

# Set up build environment
export CFLAGS="-arch arm64"
export CXXFLAGS="-arch arm64"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib -L/opt/homebrew/lib -arch arm64"
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"
export PKG_CONFIG="/opt/homebrew/bin/pkg-config"
export PYTHONPATH=""
export MACOSX_DEPLOYMENT_TARGET="12.0"

# Clone spice-gtk if needed
cd "$(dirname "$0")"
if [ ! -d "checkout/spice-gtk-0.42" ]; then
    echo "Cloning spice-gtk..."
    mkdir -p checkout
    cd checkout
    git clone https://gitlab.freedesktop.org/spice/spice-gtk.git spice-gtk-0.42 || {
        echo "Failed to clone spice-gtk"
        exit 1
    }
    cd spice-gtk-0.42
    git checkout v0.42 || {
        echo "Failed to checkout v0.42"
        exit 1
    }
    cd ../..
fi

# Create jhbuildrc
cat > jhbuildrc << 'EOL'
# Auto-generated jhbuildrc
import os
modulesets_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "modulesets")
modules = ["spice-gtk"]
prefix = os.path.expanduser("~/spice-install")
checkoutroot = os.path.join(os.path.expanduser("~"), "jhbuild/checkout")
tarballdir = os.path.join(os.path.expanduser("~"), "jhbuild/tarballs")
buildroot = os.path.join(os.path.expanduser("~"), "jhbuild/build")
use_local_modulesets = True
skip = ["spice-gtk-tests"]
moduleset = "spice.xml"
os.environ["GIT_SSL_NO_VERIFY"] = "1"
os.environ["CFLAGS"] = "-arch arm64 -I/opt/homebrew/include"
os.environ["CXXFLAGS"] = "-arch arm64 -I/opt/homebrew/include"
os.environ["LDFLAGS"] = "-L/opt/homebrew/opt/openssl@3/lib -L/opt/homebrew/lib -arch arm64"
os.environ["PKG_CONFIG_PATH"] = "/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig"
os.environ["PATH"] = "/opt/homebrew/opt/pkg-config/bin:/opt/homebrew/bin:/usr/local/bin:" + os.environ.get("PATH", "")
os.environ["MACOSX_DEPLOYMENT_TARGET"] = "12.0"
os.environ["PYTHON"] = os.path.abspath("$VENV_PATH/bin/python")
os.environ["PYTHONPATH"] = ""
os.environ["MESON"] = os.path.abspath("$VENV_PATH/bin/meson")
os.environ["NINJA"] = os.path.abspath("$VENV_PATH/bin/ninja")
EOL

# Print environment info
echo "Environment summary:"
echo "  Python: $(which python)"
echo "  Python version: $(python --version 2>&1 || echo "not found")"
echo "  PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
echo "  pkg-config: $(which pkg-config 2>/dev/null || echo "not found")"
echo "  meson: $(which meson 2>/dev/null || echo "not found")"
echo "  ninja: $(which ninja 2>/dev/null || echo "not found")"
echo "  jhbuild: $(which jhbuild 2>/dev/null || echo "not found")"

# Run jhbuild
if ! command -v jhbuild >/dev/null 2>&1; then
    echo "Error: jhbuild not found in PATH"
    exit 1
fi

echo "jhbuild version: $(jhbuild --version 2>&1 || echo "version check failed")"

# Run the build
jhbuild -f jhbuildrc buildone -n spice-gtk
