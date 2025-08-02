.PHONY: all m4 autoconf libtool clean
.PHONY: help all build venv

# Ensure Python 3.12 is used
PYTHON3 = python3.12

build: venv
	@echo "Building the project..."

	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/jhbuild-install/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(PATH) ; \
	export CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error" ; \
	export PREFIX=$(CURDIR) ; \
	export JHBUILD_MODULES=$(CURDIR)/modules ; \
	$(PYTHON3) $(JHBUILD) bootstrap

	. venv/bin/activate ; \
	export PYENV_VERSION=$(pyenv version-name) ; \
	export PATH=$(HOME)/.local/bin:$(CURDIR)/autoconf-2.69/bin:$(CURDIR)/autoconf-install/bin:$(CURDIR)/automake-1.16.1/bin:$(CURDIR)/jhbuild-install/bin:$(CURDIR)/libtool-install/bin:$(CURDIR)/m4-install/bin:$(CURDIR)/venv/bin:$(PATH) ; \
	export CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error" ; \
	export PREFIX=$(CURDIR) ; \
	export JHBUILD_MODULES=$(CURDIR)/modules ; \
	$(PYTHON3) $(JHBUILD) build --no-interact CFLAGS="-Wno-int-conversion -Wno-incompatible-function-pointer-types -Wno-pointer-sign -Wno-error"

venv:
	@echo "Creating virtual environment..."
	python3.12 -m venv $@
	. $@/bin/activate ; \
	python3.12 -m pip install --upgrade pip setuptools

JHBUILD = $(CURDIR)/jhbuild-install/bin/jhbui
