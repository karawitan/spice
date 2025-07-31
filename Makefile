.PHONY: all m4 autoconf libtool clean
.PHONY: help all build

CURDIR := $(shell pwd)

M4_DIR = m4-1.4.20
AUTOCONF_DIR = autoconf-2.69
LIBTOOL_DIR = libtool-2.4.6
M4_INSTALL_DIR = $(CURDIR)/m4-install
AUTOCONF_INSTALL_DIR = $(CURDIR)/autoconf-install
LIBTOOL_INSTALL_DIR = $(CURDIR)/libtool-install
JHBUILD=jhbuild-install/bin/jhbuild


build:
	@echo "Building the project..."

	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/jhbuild-install/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(PATH) ; \
	$(JHBUILD) bootstrap

	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/jhbuild-install/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(PATH) ; \
	$(JHBUILD) build

venv:
	python3 -m venv $@
	. venv/bin/activate ; pip3 install --upgrade pip
	. venv/bin/activate ; pip3 install pplx-cli pip setuptools

doc:

deps: cogl
	defaults write org.macosforge.xquartz.X11 enable_iglx -bool true
	brew install mesa mesa-glu
	brew install libx11 libxext libxfixes libxdamage libxcomposite libxrandr
	brew install pkg-config iso-codes libgdata webkitgtk libgee gtk-doc glib
	cd cogl ; ./autogen.sh

cogl:
	git clone https://gitlab.gnome.org/Archive/cogl.git --single-branch
	cd cogl ; ./autogen.sh
	cd cogl ; make clean ; \
	./configure \
	  --disable-wayland-egl-platform \
	  --disable-wayland-egl-server \
	  --enable-gl \
	  --enable-cogl-gst \
	  CPPFLAGS="-I/opt/X11/include" \
	  LDFLAGS="-L/opt/X11/lib"


m4:
	@echo "Configuring m4..."
	cd $(M4_DIR) && ./configure --prefix=$(M4_INSTALL_DIR)
	@echo "Patching m4 obstack.c..."
	sed -i '' 's/__attribute_noreturn__ void (*obstack_alloc_failed_handler) (void)/void (*obstack_alloc_failed_handler) (void)/g' $(M4_DIR)/lib/obstack.c
	@echo "Patching m4 obstack.h..."
	sed -i '' 's/extern __attribute_noreturn__ void (*obstack_alloc_failed_handler) (void);/extern void (*obstack_alloc_failed_handler) (void);/g' $(M4_DIR)/lib/obstack.h
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

