.PHONY: all m4 autoconf libtool clean
.PHONY: help all build

# for jhbuild we must use python3.11

CURDIR := $(shell pwd)

M4_DIR = m4-1.4.20
AUTOCONF_DIR = autoconf-2.69
LIBTOOL_DIR = libtool-2.4.6
M4_INSTALL_DIR = $(CURDIR)/m4-install
AUTOCONF_INSTALL_DIR = $(CURDIR)/autoconf-install
LIBTOOL_INSTALL_DIR = $(CURDIR)/libtool-install
JHBUILD_DIR = $(CURDIR)/jhbuild-src
JHBUILD = $(JHBUILD_DIR)/jhbuild

# Ensure Python 3.12 is used
PYTHON3 = python3.11

# Required library versions
GLIB_VERSION = 2.84.3
GSTREAMER_VERSION = 1.26.4
COGL_VERSION = 1.26.4

# Build flags
CFLAGS = -Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error

# Environment setup
JHBUILD_ENV = \
	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(JHBUILD_DIR)/bin:$(PATH) ; \
	export CFLAGS="$(CFLAGS)" ; \
	export PREFIX=$(CURDIR) ; \
	export JHBUILD_MODULES=$(CURDIR)/modules ; \
	export PYTHONPATH=$(JHBUILD_DIR)

bootstrap:
	@echo "Bootstrapping the project..."
	$(JHBUILD_ENV) && jhbuild bootstrap 
	$(JHBUILD_ENV) && jhbuild build CFLAGS="$(CFLAGS)"

install:
	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(PATH) ; \
	export CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error" ; \
	export PREFIX=$(CURDIR) ; \
	export JHBUILD_MODULES=$(CURDIR)/modules ; \
	$(PYTHON3) $(JHBUILD) install CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error"

venv:
	@echo "Creating virtual environment..."
	rm -rf venv
	python3.12 -m venv venv
	. venv/bin/activate ; \
		python3.12 -m pip install --upgrade pip
	. venv/bin/activate ; \
		python3.12 -m pip install wheel setuptools meson
	. venv/bin/activate ; \
		cd /Users/kalou/spice/jhbuild-src && ./autogen.sh && make && make install

doc:

deps: cogl
	defaults write org.macosforge.xquartz.X11 enable_iglx -bool true
	brew install mesa mesa-glu gettext
	brew install libx11 libxext libxfixes libxdamage libxcomposite libxrandr
	brew install pkg-config iso-codes libgdata libgee gtk-doc glib
	brew install gst-plugins-base gst-plugins-good gst-plugins-bad
	brew install gobject-introspection gettext
	# sudo cpan XML::Parser
	brew install libxml2 expat
	brew install cpanm
	# Instead of webkitgtk, try webkit2gtk or just skip web components
	brew install gtk+3 glib cairo pango atk gdk-pixbuf
	# For graphics/display, use macOS equivalents
	brew install libepoxy mesa
	cpanm XML::Parser
	# brew install perl-xml-parser
	cd cogl ; ./autogen.sh

cogl:
	git clone https://gitlab.gnome.org/Archive/cogl.git --single-branch
	cd cogl && git checkout tags/1.26.4

cogl.build: cogl
	cd cogl && ./autogen.sh
	cd cogl && ./configure \
	  --prefix=$(CURDIR)/cogl-install \
	  --disable-wayland-egl-platform \
	  --disable-wayland-egl-server \
	  --enable-gl \
	  --enable-cogl-gst \
	  CPPFLAGS="-I/opt/X11/include" \
	  LDFLAGS="-L/opt/X11/lib" \
	  PKG_CONFIG_PATH=/opt/X11/lib/pkgconfig:/usr/local/lib/pkgconfig
	cd cogl && make
	cd cogl && make install


m4:
	@echo "Configuring m4..."
	cd $(M4_DIR) && ./configure --prefix=$(M4_INSTALL_DIR)
	@echo "Compiling m4..."
	cd $(M4_DIR) && make
	@echo "Installing m4..."
	cd $(M4_DIR) && make install

autoconf: m4
	@echo "Configuring autoconf..."
	cd $(AUTOCONF_DIR) && ./configure --prefix=$(AUTOCONF_INSTALL_DIR) M4=$(M4_INSTALL_DIR)/bin/m4
	@echo "Compiling autoconf..."
	cd $(AUTOCONF_DIR) && make
	@echo "Installing autoconf..."
	cd $(AUTOCONF_DIR) && make install

libtool: autoconf
	@echo "Configuring libtool..."
	cd $(LIBTOOL_DIR) && ./configure --prefix=$(LIBTOOL_INSTALL_DIR) M4=$(M4_INSTALL_DIR)/bin/m4
	@echo "Compiling libtool..."
	cd $(LIBTOOL_DIR) && make
	@echo "Installing libtool..."
	cd $(LIBTOOL_DIR) && make install

clean:
	@echo "Cleaning m4..."
	cd $(M4_DIR) && make clean || true
	rm -rf $(M4_INSTALL_DIR)
	@echo "Cleaning autoconf..."
	cd $(AUTOCONF_DIR) && make clean || true
	rm -rf $(AUTOCONF_INSTALL_DIR)
	@echo "Cleaning libtool..."
	cd $(LIBTOOL_DIR) && make clean || true
	rm -rf $(LIBTOOL_INSTALL_DIR)

help: ## Show this help message
	@grep -hP '^[\w \-]+:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
