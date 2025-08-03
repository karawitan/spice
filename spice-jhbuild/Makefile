.PHONY: all m4 autoconf libtool clean
.PHONY: help all build venv

# Python and virtual environment settings
PYTHON_VERSION = 3.11.9
VENV_NAME = spice-build-env
PYTHON = $(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin/python
PIP = $(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin/pip
PYTHON_BIN_DIR = $(PYENV_ROOT)/versions/$(PYTHON_VERSION)/envs/$(VENV_NAME)/bin

build: venv
	@echo "Building the project..."

	eval "$$(pyenv init -)" && \
	export PATH=$(PYTHON_BIN_DIR):$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(PATH) && \
	export CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error" && \
	export PREFIX=$(HOME)/spice && \
	export JHBUILD_MODULES=$(CURDIR)/modules && \
	$(PYTHON) $(JHBUILD) bootstrap

	eval "$$(pyenv init -)" && \
	export PATH=$(PYTHON_BIN_DIR):$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(PATH) && \
	export CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error" && \
	export PREFIX=$(HOME)/spice && \
	export JHBUILD_MODULES=$(CURDIR)/modules && \
	$(PYTHON) $(JHBUILD) -f $(CURDIR)/jhbuildrc build

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

JHBUILD = $(CURDIR)/../bin/jhbuild

install: build
	@echo "Installing spice-gtk..."
	eval "$$(pyenv init -)" && \
	export PATH=$(PYTHON_BIN_DIR):$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(PATH) && \
	cd ~/.cache/jhbuild/build/spice-gtk-0.42 && \
	meson install --no-rebuild --destdir=$(HOME)/spice-install
	@echo "Installation complete. Files are in $(HOME)/spice-install"
