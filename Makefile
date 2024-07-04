-include config.mk
-include installdeps.mk

CC       = gcc
CXX      = g++
AR 		 = ar
CPPFLAGS += -I slow5lib/include/ -I slow5lib/src
CFLAGS   += -g -rdynamic -Wall -O2
LANGFLAG 	 = -x c++ -std=c++11
LDFLAGS  += $(LIBS) -lpthread -lz
BUILD_DIR = build

ifeq ($(zstd),1)
LDFLAGS		+= -lzstd
endif

ifeq ($(disable_hdf5),1)
CPPFLAGS += -DDISABLE_HDF5
endif

BINARY = slow5tools
OBJ_BIN = $(BUILD_DIR)/main.o \
      $(BUILD_DIR)/f2s.o \
      $(BUILD_DIR)/s2f.o \
      $(BUILD_DIR)/index.o \
      $(BUILD_DIR)/view.o \
	  $(BUILD_DIR)/get.o \
	  $(BUILD_DIR)/thread.o \
	  $(BUILD_DIR)/read_fast5.o \
	  $(BUILD_DIR)/merge.o \
	  $(BUILD_DIR)/split.o \
	  $(BUILD_DIR)/stats.o \
	  $(BUILD_DIR)/cat.o \
	  $(BUILD_DIR)/quickcheck.o \
	  $(BUILD_DIR)/skim.o \
	  $(BUILD_DIR)/misc.o \
	  $(BUILD_DIR)/demux.o \


PREFIX = /usr/local
VERSION = `git describe --tags`

.PHONY: clean distclean format test install uninstall slow5lib

$(BINARY): src/config.h $(HDF5_LIB) $(OBJ_BIN) slow5lib/lib/libslow5.a
	$(CXX) $(CFLAGS) $(OBJ_BIN) slow5lib/lib/libslow5.a  $(LDFLAGS) -o $@

$(BUILD_DIR)/main.o: src/main.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/f2s.o: src/f2s.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/s2f.o: src/s2f.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/index.o: src/index.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/get.o: src/get.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/view.o: src/view.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/thread.o: src/thread.c
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/read_fast5.o: src/read_fast5.c
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/merge.o: src/merge.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/split.o: src/split.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/stats.o: src/stats.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/cat.o: src/cat.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/quickcheck.o: src/quickcheck.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/skim.o: src/skim.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/misc.o: src/misc.c src/error.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

$(BUILD_DIR)/demux.o: src/demux.c $(BUILD_DIR)/thread.o src/demux.h src/error.h src/khash.h src/kvec.h src/misc.h
	$(CXX) $(LANGFLAG) $(CFLAGS) $(CPPFLAGS) $< -c -o $@

slow5lib/lib/libslow5.a:
	$(MAKE) -C slow5lib zstd=$(zstd) no_simd=$(no_simd) zstd_local=$(zstd_local) lib/libslow5.a

src/config.h:
	echo "/* Default config.h generated by Makefile */" >> $@
	echo "#define HAVE_HDF5_H 1" >> $@

$(BUILD_DIR)/lib/libhdf5.a:
	if command -v curl; then \
		curl -o $(BUILD_DIR)/hdf5.tar.bz2 https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(HDF5_MAJOR_MINOR)/hdf5-$(HDF5_VERSION)/src/hdf5-$(HDF5_VERSION).tar.bz2; \
	else \
		wget -O $(BUILD_DIR)/hdf5.tar.bz2 https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(HDF5_MAJOR_MINOR)/hdf5-$(HDF5_VERSION)/src/hdf5-$(HDF5_VERSION).tar.bz2; \
	fi
	tar -xf $(BUILD_DIR)/hdf5.tar.bz2 -C $(BUILD_DIR)
	mv $(BUILD_DIR)/hdf5-$(HDF5_VERSION) $(BUILD_DIR)/hdf5
	rm -f $(BUILD_DIR)/hdf5.tar.bz2
	cd $(BUILD_DIR)/hdf5 && \
	./configure --prefix=`pwd`/../ && \
	make -j8 && \
	make install

clean:
	rm -rf $(BINARY) $(BUILD_DIR)/*.o
	make -C slow5lib clean

# Delete all gitignored files (but not directories)
distclean: clean
	make clean
	git clean -f -X
	rm -rf $(BUILD_DIR)/* autom4te.cache

release: distclean
# make the release
	mkdir -p slow5tools-$(VERSION)
	mkdir -p slow5tools-$(VERSION)/scripts slow5tools-$(VERSION)/docs slow5tools-$(VERSION)/slow5lib
	autoreconf
	cp -r README.md LICENSE Makefile configure.ac config.mk.in \
		installdeps.mk configure build src slow5tools-$(VERSION)
	cp scripts/install-hdf5.sh scripts/install-vbz.sh scripts/install-zstd.sh slow5tools-$(VERSION)/scripts
	cp -r docs/commands.md slow5tools-$(VERSION)/docs/
	cp -r slow5lib/lib slow5lib/include slow5lib/src  slow5lib/Makefile slow5lib/LICENSE slow5lib/thirdparty/ slow5tools-$(VERSION)/slow5lib
	tar -zcf slow5tools-$(VERSION)-release.tar.gz slow5tools-$(VERSION)
	rm -rf slow5tools-$(VERSION)
# make the binaries
	scripts/install-hdf5.sh
	scripts/install-zstd.sh
	./configure --enable-localhdf5 --enable-localzstd
	make -j8
	mkdir -p slow5tools-$(VERSION)
	mkdir slow5tools-$(VERSION)/docs slow5tools-$(VERSION)/scripts
	mv slow5tools slow5tools-$(VERSION)/
	cp -r README.md LICENSE slow5tools-$(VERSION)/
	cp -r docs/commands.md slow5tools-$(VERSION)/docs/
	cp -r scripts/install-vbz.sh slow5tools-$(VERSION)/scripts/
	tar -zcf slow5tools-$(VERSION)-x86_64-linux-binaries.tar.gz slow5tools-$(VERSION)
	rm -rf slow5tools-$(VERSION)
	tar xf slow5tools-$(VERSION)-x86_64-linux-binaries.tar.gz
	mv slow5tools-$(VERSION)/slow5tools slow5tools
	zstd=1 test/test.sh

install: $(BINARY)
	mkdir -p $(DESTDIR)$(PREFIX)/bin
#mkdir -p $(DESTDIR)$(PREFIX)/share/man/man1
	cp -f $(BINARY) $(DESTDIR)$(PREFIX)/bin
#gzip < docs/slow5tools.1 > $(DESTDIR)$(PREFIX)/share/man/man1/slow5tools.1.gz

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(BINARY)
#rm -f $(DESTDIR)$(PREFIX)/share/man/man1/slow5tools.1.gz

test: $(BINARY)
	./test/test.sh

pyslow5:
	make clean
	rm -rf *.so python/pyslow5.cpp build/lib.* build/temp.*
	python3 setup.py build
	cp build/lib.*/*.so  ./
	python3 < python/example.py

test-prep: $(BINARY)
	gcc test/make_blow5.c -Isrc src/slow5.c src/slow5_press.c -lz src/slow5_idx.c src/slow5_misc.c -o test/bin/make_blow5 -g
	./test/bin/make_blow5

valgrind: $(BINARY)
	./test/test.sh mem
