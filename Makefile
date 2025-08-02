.PHONY: all clean deps
.PHONY: help all build


CURDIR := $(shell pwd)


JHBUILD_DIR = $(CURDIR)/jhbuild-src
JHBUILD = $(JHBUILD_DIR)/jhbuild

# Ensure Python 3.11 for jhbuild
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
	export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$(HOME)/.local/bin:$(CURDIR)/bin:$(CURDIR)/venv/bin:$(JHBUILD_DIR)/bin:$(PATH) ; \
	export CFLAGS="$(CFLAGS)" ; \
	export PREFIX=$(CURDIR) ; \
	export JHBUILD_MODULES=$(CURDIR)/modules ; \
	export PYTHONPATH=$(JHBUILD_DIR) ; \
	export PERL5LIB=$(HOME)/perl5/lib/perl5:$(PERL5LIB)

bootstrap: deps
	@echo "Bootstrapping the project..."
	$(JHBUILD_ENV) && jhbuild bootstrap --skip=pkgconf

install:
	$(JHBUILD_ENV) && $(PYTHON3) $(JHBUILD) install

venv:
	@echo "Creating virtual environment..."
	rm -rf venv
	python3.11 -m venv venv
	. venv/bin/activate ; \
		python3.11 -m pip install --upgrade pip
	. venv/bin/activate ; \
		python3.11 -m pip install wheel setuptools meson

jhbuild: venv
	. venv/bin/activate ; \
		cd /Users/kalou/spice/jhbuild-src && ./autogen.sh && make && make install

doc:

deps:
	defaults write org.macosforge.xquartz.X11 enable_iglx -bool true
	brew install mesa mesa-glu gettext gobject-introspection libx11 libxext libxfixes libxdamage libxcomposite libxrandr pkg-config iso-codes libgdata libgee gtk-doc glib gst-plugins-base gst-plugins-good gst-plugins-bad libxml2 expat cpanm gtk+3 cairo pango atk gdk-pixbuf libepoxy


SHELL := /bin/bash

export SHELL



clean:

help: ## Show this help message
	@grep -hP '^[\w \-]+:.*##.*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
