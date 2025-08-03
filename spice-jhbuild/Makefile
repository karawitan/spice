.PHONY: all clean venv build install check-pyenv

# ============================================================================
# PYENV CONFIGURATION
# ============================================================================

# Check if pyenv is installed and in PATH
PYENV_ROOT := $(HOME)/.pyenv
PYENV := $(shell command -v pyenv 2>/dev/null || echo "$(PYENV_ROOT)/bin/pyenv")

# Verify pyenv is installed
ifeq (,$(wildcard $(PYENV)))
    $(error pyenv not found. Please install it first: https://github.com/pyenv/pyenv#installation)
endif

# Ensure pyenv is properly initialized
PYENV_INIT := $(shell $(PYENV) --version 2>&1)
ifneq (,$(findstring "not found",$(PYENV_INIT)))
    $(error pyenv is not properly initialized. Please make sure to add it to your PATH and initialize it in your shell config)
endif

# Python version and virtual environment settings
PYTHON_VERSION := 3.11.9
VENV_NAME := spice-build-env
VENV_PATH := $(shell $(PYENV) prefix $(VENV_NAME) 2>/dev/null || echo "$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)")
PYTHON := $(VENV_PATH)/bin/python
PIP := $(VENV_PATH)/bin/pip
JHBUILD := $(PYTHON) -m jhbuild.main

# Export environment variables
export PYENV_ROOT
PYENV_VERSION := $(PYTHON_VERSION)
export PYENV_VERSION

# Set up shell and path
SHELL := /bin/bash -e -o pipefail
PATH := $(VENV_PATH)/bin:$(PYENV_ROOT)/bin:$(PYENV_ROOT)/shims:$(PATH)
export PATH

# Check for required commands
REQUIRED_CMDS := git make curl
$(foreach cmd,$(REQUIRED_CMDS),\
    $(if $(shell command -v $(cmd) 2>/dev/null),,\
        $(error Required command '$(cmd)' not found. Please install it first)))

# ============================================================================
# TARGETS
# ============================================================================

# Check pyenv setup
check-pyenv:
	@echo "=== Checking pyenv setup ==="
	@echo "pyenv root: $(PYENV_ROOT)"
	@echo "pyenv version: $(PYENV_VERSION)"
	@echo "Virtual environment: $(VENV_NAME)"
	@echo "Virtual environment path: $(VENV_PATH)"
	@echo "Python: $(shell $(PYENV) which python 2>/dev/null || echo 'Not found')"
	@echo "pip: $(shell $(PYENV) which pip 2>/dev/null || echo 'Not found')"
	@echo "Python version: $(shell $(PYENV) exec python --version 2>/dev/null || echo 'Not found')"
	@echo "Virtual environments:"
	@$(PYENV) virtualenvs || echo "No virtual environments found"
	@echo "\nEnvironment variables:"
	@echo "  PATH: $(PATH)"
	@echo "  PYTHONPATH: $(PYTHONPATH)"
	@echo "  PKG_CONFIG_PATH: $(PKG_CONFIG_PATH)"
	@echo "\nBuild tools:"
	@echo "  meson: $(shell which meson 2>/dev/null || echo 'Not found')"
	@echo "  ninja: $(shell which ninja 2>/dev/null || echo 'Not found')"
	@echo "  pkg-config: $(shell which pkg-config 2>/dev/null || echo 'Not found')"
	@echo "  jhbuild: $(shell which jhbuild 2>/dev/null || echo 'Not found')"

# Ensure Python version is installed
check-python:
	@echo "=== Checking Python $(PYTHON_VERSION) ==="
	@if ! $(PYENV) versions --bare | grep -q "^$(PYTHON_VERSION)$$"; then \
		echo "Python $(PYTHON_VERSION) not found. Installing..."; \
		$(PYENV) install -s $(PYTHON_VERSION) || (echo "Failed to install Python $(PYTHON_VERSION)"; exit 1); \
	else \
		echo "Python $(PYTHON_VERSION) is installed."; \
	fi

# Create and activate virtual environment
venv: check-python
	@echo "=== Setting up virtual environment '$(VENV_NAME)' ==="
	@if ! $(PYENV) prefix $(VENV_NAME) >/dev/null 2>&1; then \
		echo "Creating virtual environment '$(VENV_NAME)' with Python $(PYTHON_VERSION)..."; \
		$(PYENV) virtualenv $(PYTHON_VERSION) $(VENV_NAME) || (echo "Failed to create virtual environment"; exit 1); \
		echo "Installing build dependencies..."; \
		$(PYENV) shell $(VENV_NAME) && \
		$(PIP) install --upgrade pip setuptools wheel || (echo "Failed to install build dependencies"; exit 1); \
	else \
		echo "Virtual environment '$(VENV_NAME)' already exists."; \
	fi
	@echo "Virtual environment path: $(VENV_PATH)"
	@echo "Python: $(shell $(PYENV) which python)"
	@echo "Pip: $(shell $(PYENV) which pip)"

# Clean virtual environment
clean-venv:
	@echo "=== Removing virtual environment '$(VENV_NAME)' ==="
	@if $(PYENV) prefix $(VENV_NAME) >/dev/null 2>&1; then \
		echo "Removing virtual environment '$(VENV_NAME)'..."; \
		$(PYENV) uninstall -f $(VENV_NAME) || (echo "Failed to remove virtual environment"; exit 1); \
	else \
		echo "Virtual environment '$(VENV_NAME)' not found."; \
	fi

# Recreate virtual environment
recreate-venv: clean-venv venv
	@echo "Virtual environment has been recreated"

# Cross-compilation flags for Darwin arm64
CFLAGS += -arch arm64
CXXFLAGS += -arch arm64
LDFLAGS += -L/opt/homebrew/opt/openssl/lib -arch arm64

# Set macOS deployment target
MACOSX_DEPLOYMENT_TARGET ?= 12.0
export MACOSX_DEPLOYMENT_TARGET

# Additional build flags for macOS
MESON_FLAGS = -Dgtk=disabled -Dvapi=disabled -Dsmartcard=disabled -Dpolkit=disabled -Dusbredir=disabled -Dwebdav=disabled

# JHBuild options
JHBUILD_OPTS = build --nodeps

# Jhbuild configuration
export JHBUILDRC = $(CURDIR)/jhbuildrc

# Create a custom jhbuildrc
$(CURDIR)/jhbuildrc: $(CURDIR)/modulesets/spice.xml
	@echo '#!/bin/bash' > $@
	@echo '# Auto-generated jhbuildrc' >> $@
	@echo 'export PYENV_ROOT="$(PYENV_ROOT)"' >> $@
	@echo 'export PATH="$(PYENV_ROOT)/bin:$(PYENV_ROOT)/shims:$(PATH)"' >> $@
	@echo 'eval "$$($(PYENV) init -)"' >> $@
	@echo 'eval "$$($(PYENV) virtualenv-init -)"' >> $@
	@echo 'export PYENV_VERSION=$(VENV_NAME)' >> $@
	@echo '' >> $@
	@echo '# Build configuration' >> $@
	@echo 'export PREFIX="$(CURDIR)/install"' >> $@
	@echo 'export CHECKOUTROOT="$(CURDIR)/checkout"' >> $@
	@echo 'export BUILDDIR="$(CURDIR)/build"' >> $@
	@echo 'export TARBALLDIR="$(CURDIR)/tarballs"' >> $@
	@echo '' >> $@
	@echo '# Compiler and linker flags' >> $@
	@echo 'export CFLAGS="$(CFLAGS)"' >> $@
	@echo 'export CXXFLAGS="$(CXXFLAGS)"' >> $@
	@echo 'export LDFLAGS="$(LDFLAGS)"' >> $@
	@echo 'export PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)"' >> $@
	@echo 'export PYTHONPATH=""' >> $@
	@echo 'export MESON="$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin/meson"' >> $@
	@echo 'export NINJA="$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin/ninja"' >> $@
	@echo 'export MACOSX_DEPLOYMENT_TARGET="12.0"' >> $@
	@echo '' >> $@
	@echo '# Module configuration' >> $@
	@echo 'MODULESET_DIR="$(CURDIR)/modulesets"' >> $@
	@echo 'MODULES="spice-gtk"' >> $@
	@echo 'SKIP_MODULES="spice-common spice-protocol"' >> $@
	@chmod +x $@

# Main build target
build: venv $(CURDIR)/jhbuildrc
	@echo "=== Building spice-gtk for Darwin arm64 ==="
	@echo "Environment setup:"
	@echo "  Python: $(shell $(PYENV) which python)"
	@echo "  Python version: $(shell $(PYENV) exec python --version 2>&1)"
	@echo "  pip: $(shell $(PYENV) which pip)"
	@echo "  Virtual env: $(VENV_PATH)"

	# Activate virtual environment and install build dependencies
	@echo "=== Installing build dependencies ==="
	$(PYENV) shell $(VENV_NAME) && \
	$(PIP) install --upgrade pip setuptools wheel && \
	$(PIP) install meson ninja || { \
		echo "Failed to install build dependencies"; \
		exit 1; \
	}

	# Set up build environment
	@echo "=== Setting up build environment ==="
	$(PYENV) shell $(VENV_NAME) && \
	export CFLAGS="$(CFLAGS)" && \
	export CXXFLAGS="$(CXXFLAGS)" && \
	export LDFLAGS="$(LDFLAGS)" && \
	export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig" && \
	export PKG_CONFIG="/opt/homebrew/bin/pkg-config" && \
	export PYTHONPATH="" && \
	export MACOSX_DEPLOYMENT_TARGET="12.0" && \
	export PATH="$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin:$(PATH)" && \

	# Ensure we're in the right directory
	cd $(CURDIR) && \

	# Clone spice-gtk if needed
	if [ ! -d "checkout/spice-gtk-0.42" ]; then \
		echo "=== Cloning spice-gtk... ===" && \
		mkdir -p checkout && \
		cd checkout && \
		git clone https://gitlab.freedesktop.org/spice/spice-gtk.git spice-gtk-0.42 && \
		cd spice-gtk-0.42 && \
		git checkout v0.42 || { \
			echo "Failed to checkout v0.42"; \
			exit 1; \
		}; \
		cd ../..; \
	fi

	# Install jhbuild in the virtual environment
	@echo "=== Setting up jhbuild ==="
	$(PYENV) shell $(VENV_NAME) && \
	if ! command -v jhbuild >/dev/null 2>&1; then \
		echo "Installing jhbuild..." && \
		cd /tmp && \
		if [ ! -d "jhbuild" ]; then \
			git clone https://gitlab.gnome.org/GNOME/jhbuild.git || { \
				echo "Failed to clone jhbuild"; \
				exit 1; \
			} && \
			cd jhbuild && \
			$(PYTHON) setup.py install --user || { \
				echo "Failed to install jhbuild"; \
				exit 1; \
			}; \
		fi && \
		export PATH="$$HOME/.local/bin:$$PATH"; \
	fi

	# Verify environment
	@echo "=== Verifying build environment ==="
	cd $(CURDIR) && \
	$(PYENV) shell $(VENV_NAME) && \
	echo "Environment summary:" && \
	echo "  Python: $$(which python)" && \
	echo "  Python version: $$(python --version 2>&1 || echo "not found")" && \
	echo "  pip: $$(which pip)" && \
	echo "  PKG_CONFIG_PATH: $$PKG_CONFIG_PATH" && \
	echo "  pkg-config: $$(which pkg-config 2>/dev/null || echo "not found")" && \
	echo "  meson: $$(which meson 2>/dev/null || echo "not found")" && \
	echo "  ninja: $$(which ninja 2>/dev/null || echo "not found")" && \
	echo "  jhbuild: $$(which jhbuild 2>/dev/null || echo "not found")" && \
	echo "  CFLAGS: $$CFLAGS" && \
	echo "  CXXFLAGS: $$CXXFLAGS" && \
	echo "  LDFLAGS: $$LDFLAGS"

	@if ! command -v jhbuild >/dev/null 2>&1; then \
		echo "Error: jhbuild not found in PATH"; \
		exit 1; \
	fi

	@echo "jhbuild version: $$(jhbuild --version 2>&1 || echo "version check failed")"
	@echo "=== Starting build with jhbuild ==="
	cd $(CURDIR) && \
	$(PYENV) shell $(VENV_NAME) && \
	echo "Running: jhbuild -f $(CURDIR)/jhbuildrc buildone -n spice-gtk" && \
	. $(CURDIR)/jhbuildrc && \
	export PATH="$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin:$$PATH" && \
	jhbuild -f $(CURDIR)/jhbuildrc buildone -n spice-gtk

venv:
	@echo "Setting up pyenv virtual environment..."
	if ! command -v pyenv >/dev/null; then \
		echo "Error: pyenv is not installed" >&2; \
		exit 1; \
	fi
	if ! pyenv versions --bare | grep -q "^$(PYTHON_VERSION)$$\|^[[:space:]]*$(PYTHON_VERSION)"; then \
		echo "Installing Python $(PYTHON_VERSION) with pyenv..."; \
		pyenv install -s $(PYTHON_VERSION) || { \
			echo "Failed to install Python $(PYTHON_VERSION)" >&2; \
			exit 1; \
		}; \
	fi
	if ! pyenv versions --bare | grep -q "/$(VENV_NAME)$$"; then \
		echo "Creating virtual environment '$(VENV_NAME)'..."; \
		pyenv virtualenv $(PYTHON_VERSION) $(VENV_NAME) || { \
			echo "Failed to create virtual environment '$(VENV_NAME)'" >&2; \
			exit 1; \
		}; \
	fi
	@echo "Installing Python dependencies..."
	$(PIP) install --upgrade pip setuptools || { \
		echo "Failed to upgrade pip and setuptools" >&2; \
		exit 1; \
	}
	$(PIP) install six pyparsing meson ninja || { \
		echo "Failed to install required Python packages" >&2; \
		exit 1; \
	}
	@echo "Virtual environment setup complete at $(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)"

# Clean build artifacts
clean:
	@echo "=== Cleaning build artifacts ==="
	rm -rf $(CURDIR)/checkout $(CURDIR)/build $(CURDIR)/install
	@echo "To clean the virtual environment, run: make clean-venv"

# Install the built package
install: build
	@echo "=== Installing spice-gtk ==="
	$(PYENV) shell $(VENV_NAME) && \
	cd $(CURDIR)/build && \
	meson install --no-rebuild || { \
		echo "Failed to install spice-gtk" >&2; \
		exit 1; \
	}

# Manual build target that can be used if jhbuild fails
manual-build: venv
	@echo "=== Building spice-gtk manually ==="
	@echo "Activating pyenv virtual environment and setting up environment..."
	@echo "Current directory: $(CURDIR)"
	@echo "Python path: $(shell which python)"

	# Set up environment variables and run build in a single shell
	cd $(CURDIR) && \
	export PATH="$(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin:$$PATH" && \
	export CFLAGS="-arch arm64 -I/opt/homebrew/include" && \
	export CXXFLAGS="-arch arm64 -I/opt/homebrew/include" && \
	export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib -L/opt/homebrew/lib -arch arm64" && \
	export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/opt/openssl@3/lib/pkgconfig" && \
	export PKG_CONFIG="/opt/homebrew/bin/pkg-config" && \
	export MACOSX_DEPLOYMENT_TARGET="12.0" && \
	export PYTHONPATH="" && \
	

	# Clone spice-gtk if needed
	if [ ! -d "checkout/spice-gtk-0.42" ]; then \
		echo "=== Cloning spice-gtk... ===" && \
		mkdir -p checkout && \
		cd checkout && \
		git clone https://gitlab.freedesktop.org/spice/spice-gtk.git spice-gtk-0.42 && \
		cd spice-gtk-0.42 && \
		git checkout v0.42 || { \
			echo "Failed to checkout v0.42"; \
			exit 1; \
		} && \
		cd ../..; \
	fi && \
	echo "=== Configuring build with meson ===" && \
	cd $(CURDIR)/checkout/spice-gtk-0.42 && \
	meson setup build \
		--prefix=$(CURDIR)/install \
		--libdir=lib \
		--buildtype=debugoptimized \
		-Dgtk=disabled \
		-Dvapi=disabled \
		-Dsmartcard=disabled \
		-Dpolkit=disabled \
		-Dusbredir=disabled \
		-Dwebdav=disabled \
		-Dcoroutine=ucontext \
		-Dintrospection=disabled \
		-Dvapi=disabled \
		-Dpolkit=no \
		-Dpulse=disabled \
		-Dlz4=disabled \
		-Dopus=disabled \
		-Dgstreamer_1=disabled \
		-Dpixman=disabled \
		-Djpeg=disabled \
		-Dzlib=disabled \
		-Dsasl=disabled \
		-Dlz4=disabled \
		-Dphodav=disabled \
		-Dusb-ids-path=/usr/share/hwdata/usb.ids || { \
			echo "Meson configuration failed"; \
			exit 1; \
	}

	# Build and install
	echo "=== Building and installing ===" && \
	cd $(CURDIR)/checkout/spice-gtk-0.42/build && \
	ninja || { \
		echo "Build failed"; \
		exit 1; \
	} && \
	ninja install || { \
		echo "Installation failed"; \
		exit 1; \
	} && \
	echo "\n=== Build completed successfully ===" && \
	echo "Files installed to: $(CURDIR)/install"

clean:
	@echo "=== Cleaning build artifacts ==="
	rm -rf \
		$(CURDIR)/jhbuildrc \
		$(CURDIR)/checkout \
		$(CURDIR)/tarballs \
		$(CURDIR)/build \
		$(CURDIR)/install \
		$(CURDIR)/*.log \
		$(CURDIR)/*.ini

	@if [ -d "$(CURDIR)/checkout/spice-gtk-0.42" ]; then \
		cd $(CURDIR)/checkout/spice-gtk-0.42 && \
		rm -rf build meson-private meson-logs compile_commands.json; \
	fi

	@echo "=== Clean complete ==="
	@echo "To clean the virtual environment, run: make clean-venv"
	@echo "To remove all build artifacts including the virtual environment, run: make distclean"

distclean: clean clean-venv
	@echo "=== Removed all build artifacts and virtual environment ==="

.PHONY: all clean distclean venv build install check-pyenv manual-build
