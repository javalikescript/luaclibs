
UNAME_S := $(shell uname -s)

MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))

ARCH = x86_64

ifeq ($(UNAME_S),Linux)
	PLAT ?= linux
else
	PLAT ?= windows
	MK_PATH := $(subst /c/,C:/,$(MK_PATH))
endif

MAIN_TARGET = core

LUA_PATH := lua
LUA_LIB := lua54

MK_DIR := $(dir $(MK_PATH))
LUA_DIST := dist-$(PLAT)
LUA_CDIST = $(LUA_DIST)
LUA_EDIST = $(LUA_CDIST)
LUAJLS := luajls
JLSDOC_DIR := dist-doc
LDOC_DIR := ../$(JLSDOC_DIR)

SO_windows=dll
EXE_windows=.exe
MK_windows=main_mingw.mk
ZIP_windows=.zip

SO_linux=so
EXE_linux=
MK_linux=main_linux.mk
ZIP_linux=.tar.gz

SO := $(SO_$(PLAT))
EXE := $(EXE_$(PLAT))
MAIN_MK := $(MK_$(PLAT))
ZIP := $(ZIP_$(PLAT))

GCC_NAME ?= $(shell $(CROSS_PREFIX)gcc -dumpmachine)
LUA_APP = $(LUA_PATH)/src/lua$(EXE)
LUA_DATE = $(shell $(LUA_APP) -e "print(os.date('%Y%m%d'))")
LUA_VERSION = $(shell $(LUA_APP) -e "print(string.sub(_VERSION, 5))")
DIST_SUFFIX ?= -$(LUA_VERSION)-$(GCC_NAME).$(LUA_DATE)

WEBVIEW_ARCH = x64
ifeq (,$(findstring x86_64,$(GCC_NAME)))
  WEBVIEW_ARCH = x86
	ARCH = x86
endif

# in case of cross compilation, we need to use host lua for doc generation and disable lua for tests

ifdef HOST
	CROSS_PREFIX ?= $(HOST)-
	LUA_DATE = $(shell date '+%Y%m%d')
	LUA_VERSION = $(shell echo $(LUA_LIB) | sed 's/^[^0-9]*\([0-9]\)/\1./')
	ifneq (,$(findstring arm,$(HOST)))
		ARCH = arm
	else ifneq (,$(findstring aarch64,$(HOST)))
		ARCH = aarch64
	endif
endif

ifneq ($(LUA_OPENSSL_LINKING),dynamic)
	LUA_OPENSSL_LINKING = static
endif

LUAJLS_TESTS := $(patsubst $(LUAJLS)/%.lua,%.lua,$(wildcard $(LUAJLS)/tests/*/*.lua))
LUAJLS_CMD := LUA_PATH=$(MK_DIR)$(LUA_DIST)/?.lua LUA_CPATH=$(MK_DIR)$(LUA_DIST)/?.$(SO) LD_LIBRARY_PATH=$(MK_DIR)$(LUA_DIST) $(MK_DIR)$(LUA_DIST)/lua$(EXE)
LUADOC_CMD := LUA_PATH="$(MK_DIR)LDoc/?.lua;$(MK_DIR)Penlight/lua/?.lua;$(MK_DIR)$(LUA_DIST)/?.lua" LUA_CPATH=$(MK_DIR)$(LUA_DIST)/?.$(SO) $(MK_DIR)$(LUA_DIST)/lua$(EXE) $(MK_DIR)LDoc/ldoc.lua
MD_CMD := LUA_PATH=$(MK_DIR)$(LUA_DIST)/?.lua $(MK_DIR)$(LUA_DIST)/lua$(EXE) $(MK_DIR)LDoc/ldoc/markdown.lua

main: main-$(PLAT)

all: full

core quick full extras show-main configure configure-libjpeg configure-libexif configure-openssl:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg luaserial luabt lua-zlib lua-openssl lua-jpeg lua-exif lua-webview winapi lua-win32 lua-llthreads2 lua-linux luachild lpeglabel:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

help:
	@echo Main targets \(MAIN_TARGET\): full core quick extras
	@echo Other targets: arm linux windows configure clean clean-all dist help
	@echo Available platforms \(PLAT\): linux windows
	@echo Available architecture \(ARCH\): x86_64 arm aarch64

show:
	@echo Make command goals: $(MAKECMDGOALS)
	@echo TARGET: $@
	@echo ARCH: $(ARCH)
	@echo HOST: $(HOST)
	@echo PLAT: $(PLAT)
	@echo GCC_NAME: $(GCC_NAME)
	@echo LUA_LIB: $(LUA_LIB)
	@echo LUA_PATH: $(LUA_PATH)
	@echo LUA_VERSION: $(LUA_VERSION)
	@echo Library extension: $(SO)
	@echo CC: $(CC)
	@echo AR: $(AR)
	@echo RANLIB: $(RANLIB)
	@echo LD: $(LD)
	@echo MK_DIR: $(MK_DIR)

dist-versions:
	@$(LUAJLS_CMD) -v -e "print(_VERSION, tostring(string.len(string.pack('T', 0)) * 8)..' bits')" \
		-e "print(require('socket')._VERSION); print('lua-cjson', require('cjson')._VERSION); print(require('zlib')._VERSION)" \
		-e "print('luv', require('luv').version_string()); print('lua-openssl', require('openssl').version())" \
		-e "print('lpeg', require('lpeg').version()); print('luaunit', require('luaunit')._VERSION)" \
		-e "print('lua-exif', require('exif')._VERSION); print('lua-jpeg', require('jpeg')._VERSION); print(require('lpeglabel').version)"

versions: dist-versions
	@echo " cc:"
	@$(CROSS_PREFIX)gcc -dumpversion
	@echo " os:"
	-@uname -s -r

arm linux-arm:
	@$(MAKE) main ARCH=arm HOST=arm-linux-gnueabihf PLAT=linux MAIN_TARGET=$(MAIN_TARGET)

aarch64 linux-aarch64:
	@$(MAKE) main ARCH=aarch64 HOST=aarch64-linux-gnu PLAT=linux MAIN_TARGET=$(MAIN_TARGET)

win32 windows linux mingw: main

MAIN_VARS = PLAT=$(PLAT) \
		LUA_LIB=$(LUA_LIB) \
		LUA_PATH=$(LUA_PATH) \
		SO=$(SO) \
		ARCH=$(ARCH) \
		HOST=$(HOST)

main-linux:
	@$(MAKE) -f $(MAIN_MK) \
		$(MAIN_VARS) \
		CC=$(CROSS_PREFIX)gcc \
		AR=$(CROSS_PREFIX)ar \
		RANLIB=$(CROSS_PREFIX)ranlib \
		LD=$(CROSS_PREFIX)gcc \
		$(MAIN_TARGET)

main-windows:
	@$(MAKE) -f $(MAIN_MK) \
		$(MAIN_VARS) \
		$(MAIN_TARGET)


test: $(LUAJLS_TESTS)
	@echo $(words $(LUAJLS_TESTS)) test files passed

$(LUAJLS_TESTS):
	@echo Testing $@
	-@cd $(LUAJLS) && $(LUAJLS_CMD) $@


clean-lua:
	-$(RM) ./$(LUA_PATH)/src/*.o
	-$(RM) ./$(LUA_PATH)/src/*.a ./lua/src/*.$(SO)
	-$(RM) ./$(LUA_PATH)/src/lua$(EXE) ./lua/src/luac$(EXE)

clean-luv:
	-$(RM) ./luv/*.$(SO)
	-$(RM) ./luv/src/*.o

clean-lua-libs: clean-luv
	-$(RM) ./lua-cjson/*.o
	-$(RM) ./lua-cjson/*.$(SO)
	-$(RM) ./lua-buffer/*.o
	-$(RM) ./lua-buffer/*.$(SO)
	-$(RM) ./luafilesystem/src/*.o
	-$(RM) ./luafilesystem/*.$(SO)
	-$(RM) ./luasocket/src/*.o
	-$(RM) ./luasocket/src/*.$(SO)
	-$(RM) ./lpeg/*.o
	-$(RM) ./lpeg/*.$(SO)
	-$(RM) ./lpeglabel/*.o
	-$(RM) ./lpeglabel/*.$(SO)
	-$(RM) ./luaserial/*.o
	-$(RM) ./luaserial/*.$(SO)
	-$(RM) ./luabt/*.o
	-$(RM) ./luabt/*.$(SO)
	-$(RM) ./lua-zlib/*.o
	-$(RM) ./lua-zlib/*.$(SO)
	-$(RM) ./lua-openssl/src/*.o
	-$(RM) ./lua-openssl/*.$(SO)
	-$(RM) ./lua-jpeg/*.o
	-$(RM) ./lua-jpeg/*.$(SO)
	-$(RM) ./lua-exif/*.o
	-$(RM) ./lua-exif/*.$(SO)
	-$(RM) ./lua-webview/*.o
	-$(RM) ./lua-webview/*.$(SO)
	-$(RM) ./winapi/*.o
	-$(RM) ./winapi/*.$(SO)
	-$(RM) ./lua-llthreads2/src/*.o
	-$(RM) ./lua-llthreads2/src/*.$(SO)
	-$(RM) ./lua-win32/*.o
	-$(RM) ./lua-win32/*.$(SO)
	-$(RM) ./luachild/*.o
	-$(RM) ./luachild/*.$(SO)

clean-libuv:
	-$(RM) ./luv/deps/libuv/*.a
	-$(RM) ./luv/deps/libuv/src/*.o
	-$(RM) ./luv/deps/libuv/src/unix/*.o
	-$(RM) ./luv/deps/libuv/src/win/*.o

clean-libs: clean-libuv
	-$(MAKE) -C openssl clean
	-$(RM) ./openssl/*/*.$(SO)
	-$(RM) ./zlib/*.o
	-$(RM) ./zlib/*.lo
	-$(RM) ./zlib/*.a ./zlib/*.$(SO)*
	-$(MAKE) -C lua-jpeg/libjpeg clean
	-$(MAKE) -C lua-exif/libexif clean

clean-linux:

clean-windows:
	-$(RM) ./$(LUA_PATH)/src/wlua.exe ./lua/src/wlua.res

clean: clean-lua clean-lua-libs clean-$(PLAT)

clean-all: clean-lua clean-libs clean-lua-libs


dist-clean:
	rm -rf $(LUA_DIST)

dist-prepare:
	-mkdir $(LUA_DIST)
	mkdir $(LUA_CDIST)/mime
	mkdir $(LUA_DIST)/socket
	-mkdir $(LUA_CDIST)/socket
	mkdir $(LUA_DIST)/sha1
	mkdir $(LUA_DIST)/luacov


dist-copy-openssl-dynamic-linux:
	-cp -uP openssl/libcrypto.$(SO)* $(LUA_CDIST)/
	-cp -uP openssl/libssl.$(SO)* $(LUA_CDIST)/

dist-copy-openssl-dynamic-windows:
	-cp -u openssl/libcrypto*.$(SO) $(LUA_CDIST)/
	-cp -u openssl/libssl*.$(SO) $(LUA_CDIST)/

dist-copy-openssl-static-linux dist-copy-openssl-static-windows:

dist-copy-linux:
	-cp -u lua-linux/linux.$(SO) $(LUA_CDIST)/

dist-copy-windows:
	-cp -u $(LUA_PATH)/src/lua*.$(SO) $(LUA_CDIST)/
	-cp -u $(LUA_PATH)/src/wlua$(EXE) $(LUA_CDIST)/
	-cp -u winapi/winapi.$(SO) $(LUA_CDIST)/
	-cp -u lua-win32/win32.$(SO) $(LUA_CDIST)/
	-cp -u lua-webview/webview-c/ms.webview2/$(WEBVIEW_ARCH)/WebView2Loader.dll $(LUA_CDIST)/

dist-copy: dist-copy-$(PLAT)  dist-copy-openssl-$(LUA_OPENSSL_LINKING)-$(PLAT)
	cp -u $(LUA_PATH)/src/lua$(EXE) $(LUA_EDIST)/
	cp -u $(LUA_PATH)/src/luac$(EXE) $(LUA_EDIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_CDIST)/
	cp -u lua-buffer/buffer.$(SO) $(LUA_CDIST)/
	cp -u luafilesystem/lfs.$(SO) $(LUA_CDIST)/
	-cp -u luv/luv.$(SO) $(LUA_CDIST)/
	cp -u lpeg/lpeg.$(SO) $(LUA_CDIST)/
	cp -u lua-zlib/zlib.$(SO) $(LUA_CDIST)/
	cp -u luaunit/luaunit.lua $(LUA_DIST)/
	cp -u dkjson/dkjson.lua $(LUA_DIST)/
	-cp -u luachild/luachild.$(SO) $(LUA_CDIST)/
	-cp -u lpeglabel/lpeglabel.$(SO) $(LUA_CDIST)/
	-cp -u luaserial/serial.$(SO) $(LUA_CDIST)/
	-cp -u luabt/bt.$(SO) $(LUA_CDIST)/
	-cp -u lua-openssl/openssl.$(SO) $(LUA_CDIST)/
	-cp -u lua-jpeg/jpeg.$(SO) $(LUA_CDIST)/
	-cp -u lua-exif/exif.$(SO) $(LUA_CDIST)/
	-cp -u lua-webview/webview.$(SO) $(LUA_CDIST)/
	-cp -u lua-webview/webview-launcher.lua $(LUA_CDIST)/
	-cp -u lua-llthreads2/src/llthreads.$(SO) $(LUA_CDIST)/
	cp -u luasocket/src/mime-1.0.3.$(SO) $(LUA_CDIST)/mime/core.$(SO)
	cp -u luasocket/src/socket-3.0-rc1.$(SO) $(LUA_CDIST)/socket/core.$(SO)
	cp -u luasocket/src/ltn12.lua $(LUA_DIST)/
	cp -u luasocket/src/mime.lua $(LUA_DIST)/
	cp -u luasocket/src/socket.lua $(LUA_DIST)/
	cp -u luasocket/src/ftp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/headers.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/http.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/smtp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/tp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/url.lua $(LUA_DIST)/socket/
	cp -u sha1/src/sha1/*.lua $(LUA_DIST)/sha1/
	cp -u luacov/src/luacov.lua $(LUA_DIST)/
	cp -u luacov/src/luacov/*.lua $(LUA_DIST)/luacov/
	cp -u xml2lua/XmlParser.lua $(LUA_DIST)/
	cp -u lua-cbor/cbor.lua $(LUA_DIST)/
	printf "return require('sha1.init')" > $(LUA_DIST)/sha1.lua

dist: dist-clean dist-prepare dist-copy

ldoc:
	cd $(LUAJLS) && $(LUADOC_CMD) -i -d $(LDOC_DIR) .

ldoc-dev-content:
	grep -E "^##* .*$$" ../$(LUAJLS)/doc_topics/manual.md
	grep -E "^## .*$$" ../$(LUAJLS)/doc_topics/manual.md | sed -E 's/^##*  *//g' | sed 's/[^A-Za-z][^A-Za-z]*/_/g' | sed 's/_$$//g' | sed -E 's/^(.*)$$/@{manual.md.\1|\1}/g'

ldoc-dev:
	cd ../$(LUAJLS) && $(LUADOC_CMD) -i -d doc .

md-ldoc:
	$(MD_CMD) LDoc/doc/doc.md
	mv LDoc/doc/doc.html $(JLSDOC_DIR)/ldoc.html
	-$(MD_CMD) luaunit/doc/index.md
	-mv luaunit/doc/index.html $(JLSDOC_DIR)/luaunit.html

ldoc-clean:
	rm -rf $(JLSDOC_DIR)

ldoc-all: ldoc-clean ldoc md-ldoc
	mkdir $(JLSDOC_DIR)/lua
	cp -ur $(LUA_PATH)/doc/* $(JLSDOC_DIR)/lua/
	mkdir $(JLSDOC_DIR)/luacov
	cp -ur luacov/docs/* $(JLSDOC_DIR)/luacov/

ldoc.zip: ldoc-all
	rm -f $(LUA_DIST)/docs.zip
	cd $(JLSDOC_DIR) && zip -r ../$(LUA_DIST)/docs.zip *

dist-jls: dist
	cp -ur $(LUAJLS)/jls $(LUA_DIST)/
	test -f $(LUA_DIST)/jls/net/URL.lua || printf "return require('jls.net.Url')" > $(LUA_DIST)/jls/net/URL.lua
	cp -ur $(LUAJLS)/examples $(LUA_DIST)/

dist-jls-full: dist-jls ldoc.zip
	-@$(MAKE) --quiet versions >$(LUA_DIST)/versions.txt


luajls.tar.gz:
	cd $(LUA_DIST) && tar --group=jls --owner=jls -zcvf luajls$(DIST_SUFFIX).tar.gz *

luajls.zip:
	cd $(LUA_DIST) && zip -r luajls$(DIST_SUFFIX).zip *

luajls-archive: luajls$(ZIP)

dist-archive: luajls-archive

release-cross: dist-jls luajls-archive

release: dist-jls-full test luajls-archive

.PHONY: dist release clean linux mingw windows win32 arm test ldoc full quick extras \
	lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg lpeglabel zlib lua-zlib openssl lua-openssl \
	luaserial luabt libjpeg lua-jpeg libexif lua-exif lua-webview winapi lua-win32 lua-llthreads2 lua-linux luachild

