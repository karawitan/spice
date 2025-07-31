.PHONY: all m4 autoconf libtool clean

M4_DIR = m4-1.4.20
AUTOCONF_DIR = autoconf-2.69
LIBTOOL_DIR = libtool-2.4.6
M4_INSTALL_DIR = $(CURDIR)/m4-install
AUTOCONF_INSTALL_DIR = $(CURDIR)/autoconf-install
LIBTOOL_INSTALL_DIR = $(CURDIR)/libtool-install

all: libtool

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