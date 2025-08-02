.PHONY: clean deps python-setup jhbuild
.PHONY: doc all build

CURDIR := $(shell pwd)

JHBUILD_DIR = $(CURDIR)/jhbuild-src
JHBUILD = $(JHBUILD_DIR)/jhbuild

# Required library versions
GLIB_VERSION = 2.84.3
GSTREAMER_VERSION = 1.26.4
COGL_VERSION = 1.26.4

# Build flags
CFLAGS = -Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error

# Environment setup
JHBUILD_ENV = \
	export ACLOCAL_PATH=$(HOME)/jhbuild/install/share/aclocal:/opt/homebrew/share/aclocal:$(ACLOCAL_PATH) ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$(HOME)/.local/bin:$(CURDIR)/bin:$(JHBUILD_DIR)/bin:$(PATH) ; \
	export CFLAGS="$(CFLAGS)" ; \
	export PREFIX=$(CURDIR) ; \
	export PYTHONPATH=$(JHBUILD_DIR) ; \
	export PERL5LIB=$(HOME)/perl5/lib/perl5:$(PERL5LIB)

build: deps venv
	@echo "Building the project..."
	$(JHBUILD_ENV) && jhbuild -f $(CURDIR)/spice-jhbuild/jhbuildrc build spice-gtk

bootstrap: deps
	@echo "Bootstrapping the project..."
	$(JHBUILD_ENV) && jhbuild -f $(CURDIR)/spice-jhbuild/jhbuildrc bootstrap --skip=pkgconf

install:
	$(JHBUILD_ENV) && python $(JHBUILD) install

python-setup:
	pyenv install -s 3.11.9

venv: python-setup
	@echo "Creating pyenv virtual environment..."
	pyenv virtualenv 3.11.9 spice-env || true

	pyenv local spice-env ;\
		pip install --upgrade pip ;\

	pyenv local spice-env ;\
		pip install wheel setuptools meson PyGObject dbus-python

jhbuild: venv
	cd /Users/kalou/spice/jhbuild-src && ./autogen.sh && make && make install

doc:

deps:
	defaults write org.macosforge.xquartz.X11 enable_iglx -bool true
	brew install mesa mesa-glu gettext gobject-introspection libx11 libxext libxfixes libxdamage libxcomposite libxrandr pkg-config iso-codes libgdata libgee gtk-doc glib gst-plugins-base gst-plugins-good gst-plugins-bad libxml2 expat cpanm gtk+3 cairo pango atk gdk-pixbuf libepoxy
	cpanm --local-lib=~/perl5 local::lib
	cpanm XML::Parser

export SHELL

clean:

doc: ## Show this help message
	@grep -hP '^[\w \-]+:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
