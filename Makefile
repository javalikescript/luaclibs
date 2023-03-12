
GCC_NAME ?= $(shell $(CROSS_PREFIX)gcc -dumpmachine)

ifdef HOST
	CROSS_PREFIX ?= $(HOST)-
	CROSS_SUFFIX = -cross
	ifneq (,$(findstring x86_64,$(HOST)))
		ARCH = x86_64
	else ifneq (,$(findstring x86,$(HOST)))
		ARCH = x86
	else ifneq (,$(findstring arm,$(HOST)))
		ARCH = arm
	else ifneq (,$(findstring aarch64,$(HOST)))
		ARCH = aarch64
	else
		$(error Unknown host $(HOST))
	endif
else
	ifneq (,$(findstring x86_64,$(GCC_NAME)))
		ARCH = x86_64
	else ifneq (,$(findstring x86,$(GCC_NAME)))
		ARCH = x86
	else ifneq (,$(findstring arm,$(GCC_NAME)))
		ARCH = arm
	else ifneq (,$(findstring aarch64,$(GCC_NAME)))
		ARCH = aarch64
	else
		$(error Unknown compiler target $(GCC_NAME))
	endif
endif

ifeq ($(ARCH),x86_64)
	WEBVIEW_ARCH ?= x64
else
	WEBVIEW_ARCH ?= $(ARCH)
endif

UNAME_S := $(shell uname -s)
MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
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
LUA_DIST := dist
LUA_CDIST = $(LUA_DIST)
LUA_EDIST = $(LUA_CDIST)
LUAJLS := luajls
JLSDOC_DIR := $(LUA_DIST)-doc
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

DIST_TARGET=$(subst w64-mingw32,windows,$(GCC_NAME))$(RELEASE_SUFFIX)
LUA_APP = $(LUA_PATH)/src/lua$(EXE)
RELEASE_DATE = $(shell date '+%Y%m%d')
LUA_VERSION = $(shell $(LUA_APP) -e "print(string.sub(_VERSION, 5))")
RELEASE_NAME ?= -$(LUA_VERSION)-$(DIST_TARGET).$(RELEASE_DATE)
STATIC_NAME = $(LUA_LIB)jls

# in case of cross compilation, we need to use host lua for doc generation and disable lua for tests

ifdef HOST
	LUA_VERSION = $(shell echo $(LUA_LIB) | sed 's/^[^0-9]*\([0-9]\)/\1./')
endif

ifneq ($(LUA_OPENSSL_LINKING),dynamic)
	LUA_OPENSSL_LINKING = static
endif

LUAJLS_TESTS := $(patsubst $(LUAJLS)/%.lua,%.lua,$(wildcard $(LUAJLS)/tests/*/*.lua))
LUAJLS_CMD := LUA_PATH=$(MK_DIR)$(LUA_DIST)/?.lua LUA_CPATH=$(MK_DIR)$(LUA_DIST)/?.$(SO) LD_LIBRARY_PATH=$(MK_DIR)$(LUA_DIST) $(MK_DIR)$(LUA_DIST)/lua$(EXE)
LUATEST_CMD := LUA_PATH="$(MK_DIR)/luaunit/?.lua;$(MK_DIR)$(LUA_DIST)/?.lua" LUA_CPATH=$(MK_DIR)$(LUA_DIST)/?.$(SO) LD_LIBRARY_PATH=$(MK_DIR)$(LUA_DIST) $(MK_DIR)$(LUA_DIST)/lua$(EXE)
LUADOC_CMD := LUA_PATH="$(MK_DIR)LDoc/?.lua;$(MK_DIR)Penlight/lua/?.lua;$(MK_DIR)$(LUA_DIST)/?.lua" LUA_CPATH=$(MK_DIR)/luafilesystem/?.$(SO) $(MK_DIR)$(LUA_DIST)/lua$(EXE) $(MK_DIR)LDoc/ldoc.lua
MD_CMD := LUA_PATH=$(MK_DIR)$(LUA_DIST)/?.lua $(MK_DIR)$(LUA_DIST)/lua$(EXE) $(MK_DIR)LDoc/ldoc/markdown.lua

main: main-$(PLAT)

all: full

core quick full extras show-main configure configure-libjpeg configure-libexif configure-openssl:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg luaserial luabt lua-zlib openssl lua-openssl lua-jpeg lua-exif lua-webview winapi lua-win32 lua-llthreads2 lua-linux luachild lua-struct lpeglabel:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

help:
	@echo Main targets \(MAIN_TARGET\): full core quick extras
	@echo Other targets: arm linux windows configure clean clean-all dist help
	@echo Available platforms \(PLAT\): linux windows
	@echo Available architecture \(ARCH\): x86_64 arm aarch64

echo show:
	@echo Make command goals: $(MAKECMDGOALS)
	@echo TARGET: $@
	@echo ARCH: $(ARCH)
	@echo HOST: $(HOST)
	@echo PLAT: $(PLAT)
	@echo DIST_TARGET: $(DIST_TARGET)
	@echo GCC_NAME: $(GCC_NAME)
	@echo LUA_LIB: $(LUA_LIB)
	@echo LUA_PATH: $(LUA_PATH)
	@echo LUA_VERSION: $(LUA_VERSION)
	@echo RELEASE_DATE: $(RELEASE_DATE)
	@echo RELEASE_NAME: $(RELEASE_NAME)
	@echo Library extension: $(SO)
	@echo CC: $(CC)
	@echo AR: $(AR)
	@echo RANLIB: $(RANLIB)
	@echo LD: $(LD)
	@echo MK_DIR: $(MK_DIR)

versions-dist:
	@$(LUAJLS_CMD) -v versions.lua

versions-cross:
	@printf "cc\t"
	@$(CROSS_PREFIX)gcc -dumpversion
	@printf "platform\t"
	@echo $(PLAT)
	@printf "target\t"
	@echo $(DIST_TARGET)
	@printf "gcc-target\t"
	@echo $(GCC_NAME)
	@printf "os\t"
	-@uname -s -r

versions: versions-dist versions-cross

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
	-@cd $(LUAJLS) && $(LUATEST_CMD) $@

test-cross:


static: static-$(PLAT)

static-windows:
	LUA_PATH="$(LUAJLS)/?.lua;$(LUA_DIST)/?.lua" LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) \
		$(LUAJLS)/examples/package.lua -d $(LUAJLS)/jls -a preload -strip true -pretty false -o -f $(STATIC_NAME).lua
	cat bootstrap.lua >> $(STATIC_NAME).lua
	$(LUA_APP) luastatic\luastatic.lua $(STATIC_NAME).lua $(LUA_PATH)\src\liblua.a -Ilua\src \
		luv\src\luv.o luv\deps\libuv\libuv.a \
		lua-cjson\lua_cjson.o lua-cjson\fpconv.o lua-cjson\strbuf.o \
		zlib\libz.a lua-zlib\lua_zlib.o \
		lua-webview\webview.o \
		-lws2_32 -lpsapi -liphlpapi -lshell32 -luserenv -luser32 -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32
	rm $(STATIC_NAME).lua
	rm $(STATIC_NAME).luastatic.c

#	mv $(STATIC_NAME)$(EXE) $(LUA_DIST)/

static-linux:
	LUA_PATH="$(LUAJLS)/?.lua;$(LUA_DIST)/?.lua" LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) \
		$(LUAJLS)/examples/package.lua -d $(LUAJLS)/jls -a preload -strip true -pretty false -o -f $(STATIC_NAME).lua
	cat bootstrap.lua >> $(STATIC_NAME).lua
	$(LUA_APP) luastatic/luastatic.lua $(STATIC_NAME).lua $(LUA_PATH)/src/liblua.a -Ilua/src \
		luv/src/luv.o luv/deps/libuv/libuv.a \
		lua-cjson/lua_cjson.o lua-cjson/fpconv.o lua-cjson/strbuf.o \
		zlib/libz.a lua-zlib/lua_zlib.o \
		lua-webview/webview.o \
		-lrt -pthread -lpthread \
		$(shell pkg-config --libs gtk+-3.0 webkit2gtk-4.0)
	rm $(STATIC_NAME).lua
	rm $(STATIC_NAME).luastatic.c


clean-lua:
	-$(RM) ./$(LUA_PATH)/src/*.o ./$(LUA_PATH)/src/*.a
	-$(RM) ./lua/src/*.$(SO) ./$(LUA_PATH)/src/lua$(EXE) ./lua/src/luac$(EXE)

clean-luv:
	-$(RM) ./luv/src/*.o ./luv/*.$(SO)

clean-lua-openssl:
	-$(RM) ./lua-openssl/src/*.o ./lua-openssl/*.$(SO)

clean-lua-libs: clean-luv clean-lua-openssl
	-$(RM) ./lua-cjson/*.o ./lua-cjson/*.$(SO)
	-$(RM) ./lua-buffer/*.o ./lua-buffer/*.$(SO)
	-$(RM) ./luafilesystem/src/*.o ./luafilesystem/*.$(SO)
	-$(RM) ./luasocket/src/*.o ./luasocket/src/*.$(SO)
	-$(RM) ./lpeg/*.o ./lpeg/*.$(SO)
	-$(RM) ./lpeglabel/*.o ./lpeglabel/*.$(SO)
	-$(RM) ./luaserial/*.o ./luaserial/*.$(SO)
	-$(RM) ./luabt/*.o ./luabt/*.$(SO)
	-$(RM) ./lua-zlib/*.o ./lua-zlib/*.$(SO)
	-$(RM) ./lua-jpeg/*.o ./lua-jpeg/*.$(SO)
	-$(RM) ./lua-exif/*.o ./lua-exif/*.$(SO)
	-$(RM) ./lua-webview/*.o ./lua-webview/*.$(SO)
	-$(RM) ./winapi/*.o ./winapi/*.$(SO)
	-$(RM) ./lua-llthreads2/src/*.o ./lua-llthreads2/src/*.$(SO)
	-$(RM) ./lua-win32/*.o ./lua-win32/*.$(SO)
	-$(RM) ./luachild/*.o ./luachild/*.$(SO)
	-$(RM) ./lua-struct/*.o ./lua-struct/*.$(SO)

clean-libuv:
	-$(RM) ./luv/deps/libuv/*.a ./luv/deps/libuv/src/*.o
	-$(RM) ./luv/deps/libuv/src/unix/*.o ./luv/deps/libuv/src/win/*.o

clean-libs: clean-libuv
	-$(MAKE) -C openssl clean
	-$(RM) ./openssl/*/*.$(SO)
	-$(RM) ./zlib/*.o ./zlib/*.lo ./zlib/*.a ./zlib/*.$(SO)*
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

dist-dup-copy:
	cp -u luafilesystem/lfs.$(SO) $(LUA_CDIST)/
	cp -u dkjson/dkjson.lua $(LUA_DIST)/
	cp -u luachild/luachild.$(SO) $(LUA_CDIST)/
	cp -u lua-llthreads2/src/llthreads.$(SO) $(LUA_CDIST)/
	mkdir $(LUA_CDIST)/mime
	mkdir $(LUA_DIST)/socket
	-mkdir $(LUA_CDIST)/socket
	cp -u luasocket/src/mime-1.0.3.$(SO) $(LUA_CDIST)/mime/core.$(SO)
	cp -u luasocket/src/socket-3.0.0.$(SO) $(LUA_CDIST)/socket/core.$(SO)
	cp -u luasocket/src/ltn12.lua luasocket/src/mime.lua luasocket/src/socket.lua $(LUA_DIST)/
	cp -u luasocket/src/ftp.lua luasocket/src/headers.lua luasocket/src/http.lua \
		luasocket/src/smtp.lua luasocket/src/tp.lua luasocket/src/url.lua $(LUA_DIST)/socket/
	mkdir $(LUA_DIST)/sha1
	cp -u sha1/src/sha1/*.lua $(LUA_DIST)/sha1/
	printf "return require('sha1.init')" > $(LUA_DIST)/sha1.lua

dist-ext-copy:
	cp -u luaunit/luaunit.lua $(LUA_DIST)/
	-cp -u lua-struct/struct.$(SO) $(LUA_CDIST)/
	mkdir $(LUA_DIST)/bitop
	-cp -u bitop-lua/src/bitop/funcs.lua $(LUA_DIST)/bitop/
	mkdir $(LUA_DIST)/luacov
	-cp -u luacov/src/luacov.lua $(LUA_DIST)/
	-cp -u luacov/src/luacov/*.lua $(LUA_DIST)/luacov/
	-cp -u lua-cbor/cbor.lua $(LUA_DIST)/
	-cp -u lpeglabel/lpeglabel.$(SO) $(LUA_CDIST)/

dist-copy: dist-copy-$(PLAT) dist-copy-openssl-$(LUA_OPENSSL_LINKING)-$(PLAT)
	cp -u $(LUA_PATH)/src/lua$(EXE) $(LUA_PATH)/src/luac$(EXE) $(LUA_EDIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_CDIST)/
	cp -u luv/luv.$(SO) $(LUA_CDIST)/
	cp -u lua-zlib/zlib.$(SO) $(LUA_CDIST)/
	cp -u xml2lua/XmlParser.lua $(LUA_DIST)/
	cp -u DumbLuaParser/dumbParser.lua $(LUA_DIST)/
	-cp -u lpeg/lpeg.$(SO) $(LUA_CDIST)/
	-cp -u lpeg/re.lua $(LUA_DIST)/
	-cp -u luaserial/serial.$(SO) $(LUA_CDIST)/
	-cp -u lua-openssl/openssl.$(SO) $(LUA_CDIST)/
	-cp -u lua-webview/webview.$(SO) lua-webview/webview-launcher.lua $(LUA_CDIST)/
	-cp -u lua-jpeg/jpeg.$(SO) $(LUA_CDIST)/
	-cp -u lua-exif/exif.$(SO) $(LUA_CDIST)/
	-cp -u lua-buffer/buffer.$(SO) $(LUA_CDIST)/
	-cp -u luabt/bt.$(SO) $(LUA_CDIST)/

dist: dist-clean dist-prepare dist-copy

dist-all: dist-clean dist-prepare dist-copy dist-dup-copy dist-ext-copy


ldoc:
	cd $(LUAJLS) && $(LUADOC_CMD) -i --date "" -d $(LDOC_DIR) .

ldoc-dev-content:
	grep -E "^##* .*$$" ../$(LUAJLS)/doc_topics/manual.md
	grep -E "^## .*$$" ../$(LUAJLS)/doc_topics/manual.md | sed -E 's/^##*  *//g' | sed 's/[^A-Za-z][^A-Za-z]*/_/g' | sed 's/_$$//g' | sed -E 's/^(.*)$$/@{manual.md.\1|\1}/g'

ldoc-dev:
	cd ../$(LUAJLS) && $(LUADOC_CMD) -i --date "" -d doc .

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

dist-doc: ldoc-all
	rm -f $(LUA_DIST)/docs.zip
	cd $(JLSDOC_DIR) && zip -r ../$(LUA_DIST)/docs.zip *

dist-doc-cross:

dist-jls-lua51:
	LUA_PATH="$(LUAJLS)/?.lua;$(LUA_DIST)/?.lua" LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) \
		$(LUAJLS)/examples/package.lua -d $(LUAJLS)/jls -a copy -strip true -t 5.1 -outdir $(LUA_DIST)

dist-jls-lua54:
	cp -ur $(LUAJLS)/jls $(LUA_DIST)/

dist-jls-do: dist-jls-$(LUA_LIB)
	test -f $(LUA_DIST)/jls/net/URL.lua || printf "return require('jls.net.Url')" > $(LUA_DIST)/jls/net/URL.lua
	cp -ur $(LUAJLS)/examples $(LUA_DIST)/

dist-jls: dist dist-jls-do

dist-versions:
	-@$(MAKE) --quiet versions$(CROSS_SUFFIX) >$(LUA_DIST)/versions.txt


luajls.tar.gz:
	cd $(LUA_DIST) && tar --group=jls --owner=jls -zcvf luajls$(RELEASE_NAME).tar.gz *

luajls.zip:
	cd $(LUA_DIST) && zip -r luajls$(RELEASE_NAME).zip *

luajls-archive: luajls$(ZIP)

dist-archive: luajls-archive


release-do: dist-versions dist-doc$(CROSS_SUFFIX) test$(CROSS_SUFFIX) luajls-archive

release-all: dist-all dist-jls-do release-do

release: dist-jls release-do


.PHONY: dist release clean linux mingw windows win32 arm test ldoc full quick extras \
	lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg lpeglabel zlib lua-zlib \
	openssl lua-openssl luaserial luabt libjpeg lua-jpeg libexif lua-exif lua-webview \
	winapi lua-win32 lua-llthreads2 lua-linux luachild lua-struct

