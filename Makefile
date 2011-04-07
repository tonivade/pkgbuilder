DEST_DIR=
PREFIX=/usr/local
sysconfdir=$(PREFIX)/etc

all:

install-bin: 
	mkdir -p $(DEST_DIR)$(PREFIX)/bin
	install -m755 pkg_fakebuild.sh $(DEST_DIR)$(PREFIX)/bin 
	install -m755 pkg_query.sh $(DEST_DIR)$(PREFIX)/bin

install-sbin:
	mkdir -p $(DEST_DIR)$(PREFIX)/sbin
	install -m755 pkg_build.sh $(DEST_DIR)$(PREFIX)/sbin
	install -m755 pkg_install.sh $(DEST_DIR)$(PREFIX)/sbin
	install -m755 pkg_createdb.sh $(DEST_DIR)$(PREFIX)/sbin
	install -m755 pkg_upgrade.sh $(DEST_DIR)$(PREFIX)/sbin 
	install -m755 pkg_sync.sh $(DEST_DIR)$(PREFIX)/sbin 

install-lib:
	mkdir -p $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/functions.sh $(DEST_DIR)$(PREFIX)/lib/pkgbuilder 
	install -m644 lib/pkgfunctions.sh $(DEST_DIR)$(PREFIX)/lib/pkgbuilder
	install -m644 lib/common/base.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/common/configscript.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/common/main.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/common/makeonly.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/common/meta.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common
	install -m644 lib/common/multi.build $(DEST_DIR)$(PREFIX)/lib/pkgbuilder/common

install-conf:
	mkdir -p $(DEST_DIR)$(sysconfdir)/pkg
	install -m644 build.rc-sample $(DEST_DIR)$(sysconfdir)/pkg/build.rc

install: install-bin install-conf install-lib install-sbin

