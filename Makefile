.PHONY: all build clean deps install pyparsing python-setup

# ===== Configuration =====
PREFIX ?= $(CURDIR)
JHBUILD_DIR = $(CURDIR)/jhbuild-src
JHBUILD = $(JHBUILD_DIR)/jhbuild
JHBUILD_CMD = $(PWD)/bin/jhbuild
JHBUILD_RC = $(PWD)/spice-jhbuild/jhbuildrc

# Build flags
CFLAGS += -Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error

# ===== Environment Setup =====
JHBUILD_ENV = \
	export ACLOCAL_PATH=$(PREFIX)/share/aclocal:$(HOMEBREW_PREFIX)/share/aclocal: ; \
	export PYENV_VERSION= ; \
	export PATH=$(HOMEBREW_PREFIX)/bin:$(HOMEBREW_PREFIX)/sbin:$(LOCAL_BIN):$(PREFIX)/bin:$(JHBUILD_SRC)/bin:$(PYENV_ROOT)/shims:$(PYENV_ROOT)/bin:$(PATH) ; \
	export CFLAGS="$(CFLAGS)" ; \
	export PREFIX=$(PREFIX) ; \
	export PYTHONPATH=$(JHBUILD_SRC) ; \
	export PERL5LIB=$(PERL5LIB):

# ===== Main Targets =====
all: deps build

# Build the project
build: pyparsing checkout-sources apply-patches
	@echo "Building spice-gtk..."
	$(JHBUILD_ENV) && $(JHBUILD_CMD) -f $(JHBUILD_RC) build -a spice-gtk

# Install the project
install: build
	@echo "Installing the project..."
	$(JHBUILD_ENV) && $(JHBUILD_CMD) -f $(JHBUILD_RC) install spice-gtk

# Bootstrap the build environment
bootstrap: deps
	@echo "Bootstrapping the project..."
	$(JHBUILD_ENV) && $(JHBUILD_CMD) -f $(JHBUILD_RC) bootstrap --skip=pkgconf

# ===== Source Management =====

# Check out source code
checkout-sources:
	@echo "Checking out spice-gtk sources..."
	$(JHBUILD_ENV) && \
	$(JHBUILD_CMD) -f $(JHBUILD_RC) run sh -c '\
	  cd ~/jhbuild/checkout && \
	  if [ ! -d spice-gtk-0.42 ]; then \
	    echo "Cloning spice-gtk repository..." && \
	    git clone --branch v0.42 https://gitlab.freedesktop.org/spice/spice-gtk.git spice-gtk-0.42; \
	  else \
	    echo "spice-gtk-0.42 directory already exists, using existing sources"; \
	  fi'

# Apply necessary patches for macOS
apply-patches: checkout-sources
	@echo "\n=== Applying macOS-specific patches ==="
	@cd ~/jhbuild/checkout/spice-gtk-0.42 || (echo "Error: Could not enter source directory" && exit 1)
	@if [ ! -f meson.build ]; then \
	  echo "Error: meson.build not found"; \
	  exit 1; \
	fi
	@echo "- Creating backup of meson.build..."
	@cp -v meson.build meson.build.orig
	@echo "- Applying macOS-specific changes..."
	@# Fix the darwin system check and version script handling
	@sed -i '' -e '/if host_machine.system() == darwin/ {\
	  s/darwin/"darwin"/\
	}' meson.build
	@# Ensure proper if/else/endif structure
	@sed -i '' -e '/if not spice_gtk_has_version_script/,/endif/ {\
	  /^[[:space:]]*if host_machine/s/^/  /\
	  /^[[:space:]]*spice_gtk_version_script/s/^/  /\
	  /^[[:space:]]*else/s/^/  /\
	  /^[[:space:]]*spice_gtk_version_script/s/^/  /\
	  /^[[:space:]]*endif/s/^/  /\
	}' meson.build
	@echo "✓ Successfully modified meson.build for macOS"

# ===== Dependencies =====

# Install Python dependencies
pyparsing:
	@echo "=== Installing Python Dependencies ==="
	$(JHBUILD_ENV) && \
	echo "- Installing required Python packages..." && \
	if [ -f requirements.txt ]; then \
	  pip install -r requirements.txt; \
	fi && \
	echo "- Installing meson build system..." && \
	pip install meson==1.8.3

# Install system dependencies
deps:
	@echo "=== Installing System Dependencies ==="
	@echo "Please ensure the following packages are installed:"
	@echo "- Python 3.11.9 (via pyenv)"
	@echo "- git"
	@echo "- pkg-config"
	@echo "- meson (installed via pip)"
	@echo "- ninja"
	@echo "- glib"
	@echo "- gtk+3"
	@echo "- spice-protocol"
	@echo "\nRun 'make python-setup' to set up the Python environment"

# Set up Python environment
python-setup:
	@echo "=== Setting up Python Environment ==="
	@if ! command -v pyenv >/dev/null; then \
	  echo "Error: pyenv is required but not installed"; \
	  exit 1; \
	fi
	@echo "- Setting up Python 3.11.9..."
	pyenv install -s 3.11.9
	pyenv virtualenv 3.11.9 spice-env
	pyenv local spice-env
	@echo "\n✓ Python environment setup complete. Run 'make deps' to continue"

# ===== Cleanup =====

# Clean build artifacts
clean:
	@echo "=== Cleaning Build Artifacts ==="
	@echo "- Removing Python cache and build files..."
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type f -name "*.py[co]" -delete
	@echo "- Removing build directories..."
	@rm -rf build dist *.egg-info .pytest_cache .mypy_cache

# Remove all build and downloaded files
clean-all: clean
	@echo "\n=== Deep Clean ==="
	@echo "- Removing Python virtual environment..."
	@if pyenv virtualenvs | grep -q "spice-env"; then \
	  pyenv uninstall -f spice-env; \
	fi
	@echo "- Removing build directories..."
	@rm -rf ~/jhbuild/checkout/spice-gtk-0.42
	@rm -rf ~/.cache/meson
	@echo "- Removing installed packages..."
	@rm -rf ~/.local/lib/python3.11/site-packages/meson*
	@echo "\n✓ Clean complete. Run 'make python-setup' to start fresh."

# ===== Help =====

.PHONY: help
help:
	@echo "\n=== Spice Build System ===\n"
	@echo "Setup:"
	@echo "  make python-setup  - Set up Python 3.11.9 environment"
	@echo "  make deps         - Show system dependencies"
	@echo "  make pyparsing    - Install Python dependencies"
	@echo ""
	@echo "Build:"
	@echo "  make build        - Build the project"
	@echo "  make install      - Install to PREFIX ($(PREFIX))"
	@echo "  make bootstrap    - Bootstrap the build environment"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make clean-all    - Remove everything (including venv)"
	@echo ""
	@echo "Environment:"
	@echo "  PREFIX    - Installation prefix (default: $(PWD))"
	@echo "  CFLAGS    - Compiler flags (currently: $(CFLAGS))"
	@echo "  PYTHON    - Python interpreter: $(shell which python)"
	@echo ""
	@echo "Example workflow:"
	@echo "  make python-setup   # First time setup"
	@echo "  source ~/.zshrc     # Reload shell"
	@echo "  make deps          # Install system dependencies"
	@echo "  make build         # Build the project"
	@echo "  make install       # Install to PREFIX"
	@echo ""

# Default target
.DEFAULT_GOAL := help

venv: python-setup
	@echo "Creating pyenv virtual environment..."
	pyenv virtualenv 3.11.9 spice-env || true

	pyenv local spice-env ;\
		pip install --upgrade pip

	pyenv local spice-env ;\
		pip install wheel setuptools meson PyGObject dbus-python google-genai

jhbuild: venv
	cd /Users/kalou/spice/jhbuild-src && ./autogen.sh && make && make install

doc:

deps:
	defaults write org.macosforge.xquartz.X11 enable_iglx -bool true
	brew install mesa mesa-glu gettext gobject-introspection libx11 libxext libxfixes libxdamage libxcomposite libxrandr pkg-config iso-codes libgdata libgee gtk-doc glib gst-plugins-base gst-plugins-good gst-plugins-bad libxml2 expat cpanm gtk+3 cairo pango atk gdk-pixbuf libepoxy
	brew install meson ninja pkg-config glib cairo pixman

	cpanm --local-lib=~/perl5 local::lib
	cpanm XML::Parser

clean:

doc: ## Show this help message
	@grep -hP '^[\w \-]+:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
