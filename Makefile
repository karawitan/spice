.PHONY: all build clean deps install pyparsing python-setup

# ===== Configuration =====
PREFIX ?= $(HOME)/spice
JHBUILD_DIR = $(CURDIR)/jhbuild-src
JHBUILD = $(JHBUILD_DIR)/jhbuild
JHBUILD_CMD = $(PWD)/bin/jhbuild
JHBUILD_RC = $(PWD)/spice-jhbuild/jhbuildrc

# Build flags
CFLAGS += -Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error -Wno-unknown-warning-option

# ===== Environment Setup =====
HOMEBREW_PREFIX ?= /opt/homebrew
JHBUILD_ENV = \
	export ACLOCAL_PATH=$(PREFIX)/share/aclocal:$(HOMEBREW_PREFIX)/share/aclocal: ; \
	export PYENV_VERSION= ; \
	export PATH=$(HOMEBREW_PREFIX)/bin:$(HOMEBREW_PREFIX)/sbin:$(LOCAL_BIN):$(PREFIX)/bin:$(JHBUILD_SRC)/bin:$(PYENV_ROOT)/shims:$(PYENV_ROOT)/bin:$(PATH) ; \
	export CFLAGS="$(CFLAGS) -I$(HOMEBREW_PREFIX)/include" ; \
	export LDFLAGS="-L$(HOMEBREW_PREFIX)/lib" ; \
	export PKG_CONFIG_PATH="$(HOMEBREW_PREFIX)/lib/pkgconfig:$(HOMEBREW_PREFIX)/opt/openssl@1.1/lib/pkgconfig:$(PKG_CONFIG_PATH)" ; \
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
	$(JHBUILD_ENV) && $(JHBUILD_CMD) -f $(JHBUILD_RC) run sh -c 'meson install -C ~/jhbuild/checkout/spice-gtk-0.42/builddir --no-rebuild'

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
	@echo "=== Applying macOS-specific changes ==="
	@if [ -f ~/jhbuild/checkout/spice-gtk-0.42/src/meson.build ]; then \
		echo "Patching meson.build for macOS..."; \
		./patch-meson-build.sh; \
		echo "Patched meson.build applied successfully"; \
	else \
		echo "Error: src/meson.build not found in ~/jhbuild/checkout/spice-gtk-0.42/"; exit 1; \
	fi

# ===== Dependencies =====

# Install Python dependencies
pyparsing:
	@echo "=== Installing Python Dependencies ==="
	$(JHBUILD_ENV) && \
	echo "- Installing required Python packages..." && \
	if [ -f requirements.txt ]; then \
	  pip install -r requirements.txt; \
	fi && \
	echo "- Installing build dependencies..." && \
	pip install meson==1.8.3 six pyparsing

# Install system dependencies
deps: python-setup
	@echo "=== Installing System Dependencies ==="
	@echo "Installing required packages via Homebrew..."
	@if ! command -v brew >/dev/null; then \
		echo "Error: Homebrew is required but not installed. Please install it from https://brew.sh"; \
		exit 1; \
	fi
	brew update
	brew install \
		pkg-config \
		ninja \
		meson \
		glib \
		gobject-introspection \
		gtk+3 \
		cairo \
		pango \
		atk \
		gdk-pixbuf \
		libepoxy \
		gettext \
		libffi \
		openssl@1.1 \
		spice-protocol \
		gstreamer \
		gst-plugins-base \
		gst-plugins-good \
		gst-plugins-bad \
		gst-libav

	@echo "\n✓ Dependencies installed. Run 'make build' to start the build"

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

# Dependencies are now handled by the deps target above
	cpanm XML::Parser

clean:

doc: ## Show this help message
	@grep -hP '^[\w \-]+:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
