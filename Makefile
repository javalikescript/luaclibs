
GCC_NAME ?= $(shell $(CROSS_PREFIX)gcc -dumpmachine)

ifdef HOST
	CROSS_PREFIX ?= $(HOST)-
	CROSS_SUFFIX = -cross
	ARCH_NAME := $(HOST)
else
	ARCH_NAME := $(GCC_NAME)
endif

ifneq (,$(findstring x86_64,$(ARCH_NAME)))
	ARCH = x86_64
else ifneq (,$(findstring x86,$(ARCH_NAME)))
	ARCH = x86
else ifneq (,$(findstring arm,$(ARCH_NAME)))
	ARCH = arm
else ifneq (,$(findstring aarch64,$(ARCH_NAME)))
	ARCH = aarch64
else
	$(error Unknown architecture name $(ARCH_NAME))
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

DIST_TARGET = $(subst w64-mingw32,windows,$(GCC_NAME))$(RELEASE_SUFFIX)
LUA_APP = $(LUA_PATH)/src/lua$(EXE)
RELEASE_DATE = $(shell date '+%Y%m%d')
LUA_VERSION = $(shell $(LUA_APP) -e "print(string.sub(_VERSION, 5))")
RELEASE_NAME ?= -$(LUA_VERSION)-$(DIST_TARGET).$(RELEASE_DATE)
TAR_OPTIONS := --group=jls --owner=jls

EXPAT=expat-2.5.0


STATIC_NAME := luajls
SHARED_NAME := c$(STATIC_NAME)

STATIC_CORE_LIBNAMES := zlib luv cjson
STATIC_CORE_LIBS := $(LUA_PATH)/src/liblua.a \
		lua-zlib/lua_zlib.o zlib/libz.a \
		luv/src/luv.o luv/deps/libuv/libuv.a \
		lua-cjson/lua_cjson.o lua-cjson/fpconv.o lua-cjson/strbuf.o

STATIC_RESOURCES_windows=lua-webview/webview-c/ms.webview2/$(WEBVIEW_ARCH)/WebView2Loader.dll
STATIC_LIBS_windows=lua-webview/MemoryModule/MemoryModule.o

STATIC_LUAS := $(LUAJLS)/jls DumbLuaParser/dumbParser.lua
STATIC_LIBNAMES := $(STATIC_CORE_LIBNAMES) lxp serial webview
STATIC_LIBS := $(STATIC_CORE_LIBS) \
		luaexpat/src/lxplib.o $(EXPAT)/lib/.libs/libexpat.a \
		luaserial/luaserial.o \
		lua-webview/webview.o $(STATIC_LIBS_$(PLAT))

OPENSSL_LIBNAMES := openssl
OPENSSL_LIBS := lua-openssl/libopenssl.a openssl/libssl.a openssl/libcrypto.a

LUV_DEP_LIBS_linux=-lrt -pthread -lpthread
LUV_DEP_LIBS_windows=-lws2_32 -lpsapi -liphlpapi -lshell32 -luserenv -luser32 -ldbghelp -lole32 -luuid
LUAW32_DEP_LIBS=-lcomdlg32
WINAPI_DEP_LIBS=-lkernel32 -luser32 -lpsapi -ladvapi32 -lshell32 -lMpr
WEBVIEW_DEP_LIBS_linux=$(shell pkg-config --libs gtk+-3.0 webkit2gtk-4.0)
WEBVIEW_DEP_LIBS_windows=-lole32 -lcomctl32 -loleaut32 -luuid -lgdi32

STATIC_DEP_CORE_LIBS_linux=-ldl $(LUV_DEP_LIBS_linux)
STATIC_DEP_CORE_LIBS_windows=$(LUV_DEP_LIBS_windows) $(LUAW32_DEP_LIBS) $(WINAPI_DEP_LIBS)
STATIC_DEP_CORE_LIBS=$(STATIC_DEP_LIBS_$(PLAT))

STATIC_DEP_LIBS_linux=$(STATIC_DEP_CORE_LIBS_linux) $(WEBVIEW_DEP_LIBS_linux)
STATIC_DEP_LIBS_windows=$(STATIC_DEP_CORE_LIBS_windows) $(WEBVIEW_DEP_LIBS_windows)
STATIC_DEP_LIBS=$(STATIC_DEP_LIBS_$(PLAT))

STATIC_OS_LIBNAMES_linux=linux
STATIC_OS_LIBNAMES_windows=win32 winapi
STATIC_OS_LIBNAMES=$(STATIC_OS_LIBNAMES_$(PLAT))

STATIC_OS_LIBS_linux=lua-linux/linux.o
STATIC_OS_LIBS_windows=lua-win32\win32.o winapi\winapi.o winapi\wutils.o
STATIC_OS_LIBS=$(STATIC_OS_LIBS_$(PLAT))

STATIC_SHARED_LIBS_linux=$(LUA_PATH)/src/liblua.a -ldl
STATIC_SHARED_LIBS_windows=-L$(LUA_PATH)\src -l$(LUA_LIB)
STATIC_SHARED_LIBS=$(STATIC_SHARED_LIBS_$(PLAT)) -lm


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

core quick full extras show-main configure configure-libjpeg configure-libexif configure-openssl configure-libexpat:
	@$(MAKE) $(EXPAT)
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg luaserial luabt lua-zlib openssl lua-openssl lua-jpeg lua-exif lua-webview winapi lua-win32 lua-llthreads2 lua-linux luachild lua-struct lpeglabel luaexpat:
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


expat-2.5.0:
	wget -q --no-check-certificate https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz
	tar -xf expat-2.5.0.tar.gz
	rm expat-2.5.0.tar.gz


test: $(LUAJLS_TESTS)
	@echo $(words $(LUAJLS_TESTS)) test files passed

$(LUAJLS_TESTS):
	@echo Testing $@
	-@cd $(LUAJLS) && $(LUATEST_CMD) $@

test-cross:


static: static-full static-test
	rm addlibs.o addlibs-custom.c addlibs-main.c

static-test:
	$(MAKE) LUATEST_CMD="LUA_PATH=$(MK_DIR)/luaunit/?.lua LUA_CPATH=./?.no $(MK_DIR)$(LUA_DIST)/$(STATIC_NAME)$(EXE)" test

static-full:
	LUA_PATH=$(LUA_DIST)/?.lua LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) addlibs.lua -pp -l $(STATIC_LUAS) -p addwebview.lua -r $(STATIC_RESOURCES_$(PLAT)) $(STATIC_RESOURCES) \
		-c $(STATIC_LIBNAMES) $(STATIC_OS_LIBNAMES) $(OPENSSL_LIBNAMES)
	$(LUA_APP) changemain.lua $(LUA_PATH)/src/lua.c "$(STATIC_EXECUTE)" > addlibs-main.c
	$(CC) -c -Os addlibs.c -I$(LUA_PATH)/src -Izlib -o addlibs.o
	$(CC) -std=gnu99 -static-libgcc -o $(LUA_DIST)/$(STATIC_NAME)$(EXE) -s $(STATIC_FLAGS) addlibs.o \
		addlibs-main.c $(STATIC_LIBS) $(OPENSSL_LIBS) \
		$(STATIC_OS_LIBS) -lm -Ilua/src $(STATIC_DEP_LIBS)

static-example:
	@echo "print('You could rename this executable to, or create a link with, the name of an example to run it.')" > $(MK_DIR)/example.lua
	@echo "print('Examples: $(patsubst $(LUAJLS)/examples/%.lua,%,$(wildcard $(LUAJLS)/examples/*.lua))')" >> $(MK_DIR)/example.lua
	LUA_PATH=$(LUA_DIST)/?.lua LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) addlibs.lua -l $(LUAJLS)/jls xml2lua/XmlParser.lua -L $(LUAJLS)/examples -l example.lua -c $(STATIC_CORE_LIBNAMES)
	$(RM) example.lua
	$(LUA_APP) changemain.lua $(LUA_PATH)/src/lua.c "require((function() for i=-1,-99,-1 do if not arg[i] then return (string.gsub(string.gsub(arg[i+1], '^.*[/\\\\]', ''), '%.exe$$', '')); end; end; end)())" > addlibs-main.c
	$(CC) -c -Os addlibs.c -I$(LUA_PATH)/src -Izlib -o addlibs.o
	$(CC) -std=gnu99 -static-libgcc -o $(LUA_DIST)/example$(EXE) -s $(STATIC_FLAGS) addlibs.o \
		addlibs-main.c $(STATIC_CORE_LIBS) -lm -Ilua/src $(STATIC_DEP_CORE_LIBS)


shared: shared-$(PLAT) shared-test
	rm addlibs.o addlibs-custom.c addlibs-main.c

shared-test:
	$(MAKE) LUATEST_CMD="LUA_PATH=$(MK_DIR)/luaunit/?.lua LUA_CPATH=$(MK_DIR)$(LUA_DIST)/?.$(SO) $(MK_DIR)$(LUA_DIST)/$(SHARED_NAME)$(EXE)" test

shared-windows:
	@$(MAKE) static-shared STATIC_FLAGS="$(LUA_PATH)/src/wlua.res"
	@$(MAKE) static-shared STATIC_FLAGS="$(LUA_PATH)/src/wlua.res -mwindows" SHARED_NAME=w$(STATIC_NAME)

shared-linux: static-shared

static-shared:
	LUA_PATH=$(LUA_DIST)/?.lua LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) addlibs.lua -pp -l $(STATIC_LUAS) -r $(STATIC_RESOURCES)
	$(LUA_APP) changemain.lua $(LUA_PATH)/src/lua.c "$(STATIC_EXECUTE)" > addlibs-main.c
	$(CC) -c -Os addlibs.c -I$(LUA_PATH)/src -Izlib -o addlibs.o
	$(CC) -std=gnu99 -static-libgcc -o $(LUA_DIST)/$(SHARED_NAME)$(EXE) -s $(STATIC_FLAGS) addlibs.o \
		addlibs-main.c zlib/libz.a -Ilua/src $(STATIC_SHARED_LIBS)


clean-lua:
	-$(RM) ./$(LUA_PATH)/src/*.o ./$(LUA_PATH)/src/*.a
	-$(RM) ./lua/src/*.$(SO) ./$(LUA_PATH)/src/lua$(EXE) ./lua/src/luac$(EXE)

clean-luv:
	-$(RM) ./luv/src/*.o ./luv/*.$(SO)

clean-lua-openssl:
	-$(RM) ./lua-openssl/src/*.o ./lua-openssl/deps/auxiliar/*.o ./lua-openssl/*.$(SO)

clean-lua-libs: clean-luv clean-lua-openssl
	-$(RM) ./lua-cjson/*.o ./lua-cjson/*.$(SO)
	-$(RM) ./lua-buffer/*.o ./lua-buffer/*.$(SO)
	-$(RM) ./luafilesystem/src/*.o ./luafilesystem/*.$(SO)
	-$(RM) ./luasocket/src/*.o ./luasocket/src/*.$(SO)
	-$(RM) ./lua-zlib/*.o ./lua-zlib/*.$(SO)
	-$(RM) ./luaexpat/src/*.o ./luaexpat/*.$(SO)
	-$(RM) ./lpeg/*.o ./lpeg/*.$(SO)
	-$(RM) ./lpeglabel/*.o ./lpeglabel/*.$(SO)
	-$(RM) ./luaserial/*.o ./luaserial/*.$(SO)
	-$(RM) ./luabt/*.o ./luabt/*.$(SO)
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
	-$(RM) ./lua-webview/*.o ./lua-webview/MemoryModule/*.o
	-$(MAKE) -C $(EXPAT) clean
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

dist-ext-copy:
	-cp -u lua-struct/struct.$(SO) $(LUA_CDIST)/
	mkdir $(LUA_DIST)/bitop
	-cp -u bitop-lua/src/bitop/funcs.lua $(LUA_DIST)/bitop/
	mkdir $(LUA_DIST)/luacov
	-cp -u luacov/src/luacov.lua $(LUA_DIST)/
	-cp -u luacov/src/luacov/*.lua $(LUA_DIST)/luacov/
	-cp -u lua-cbor/cbor.lua $(LUA_DIST)/
	-cp -u lpeglabel/lpeglabel.$(SO) $(LUA_CDIST)/

dist-copy: dist-copy-$(PLAT) dist-copy-openssl-$(LUA_OPENSSL_LINKING)-$(PLAT)
	cp -u licenses.txt $(LUA_DIST)/
	cp -u $(LUA_PATH)/src/lua$(EXE) $(LUA_PATH)/src/luac$(EXE) $(LUA_EDIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_CDIST)/
	cp -u luv/luv.$(SO) $(LUA_CDIST)/
	cp -u lua-zlib/zlib.$(SO) $(LUA_CDIST)/
	cp -u luaexpat/lxp.$(SO) $(LUA_CDIST)/
	cp -u xml2lua/xml2lua.lua $(LUA_DIST)/
	cp -u xml2lua/XmlParser.lua $(LUA_DIST)/
	cp -u DumbLuaParser/dumbParser.lua $(LUA_DIST)/
	cp -u luaunit/luaunit.lua $(LUA_DIST)/
	-cp -u lpeg/lpeg.$(SO) $(LUA_CDIST)/
	-cp -u lpeg/re.lua $(LUA_DIST)/
	-cp -u luaserial/serial.$(SO) $(LUA_CDIST)/
	-cp -u lua-openssl/openssl.$(SO) $(LUA_CDIST)/
	-cp -u lua-webview/webview.$(SO) lua-webview/webview-launcher.lua $(LUA_CDIST)/
	-cp -u lua-jpeg/jpeg.$(SO) $(LUA_CDIST)/
	-cp -u lua-exif/exif.$(SO) $(LUA_CDIST)/
	-cp -u lua-buffer/buffer.$(SO) $(LUA_CDIST)/
	-cp -u luabt/bt.$(SO) $(LUA_CDIST)/

dist-min: dist-clean dist-prepare dist-copy

dist-all: dist-clean dist-prepare dist-copy dist-dup-copy dist-ext-copy


ldoc:
	mkdir $(JLSDOC_DIR)
	-cd $(LUAJLS) && $(LUADOC_CMD) -i --date "" -d $(LDOC_DIR) .

ldoc-dev-content:
	grep -E "^##* .*$$" ../$(LUAJLS)/doc_topics/manual.md
	grep -E "^## .*$$" ../$(LUAJLS)/doc_topics/manual.md | sed -E 's/^##*  *//g' | \
		sed 's/[^A-Za-z][^A-Za-z]*/_/g' | sed 's/_$$//g' | sed -E 's/^(.*)$$/@{manual.md.\1|\1}/g'

ldoc-dev:
	rm -rf ../$(LUAJLS)/doc
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
	mv $(LUA_DIST)/luaunit.lua $(LUA_DIST)/luaunit-.lua
	cp -u luaunit-patch.lua $(LUA_DIST)/luaunit.lua
	mkdir $(LUA_DIST)/luvit
	printf "return require('uv')" > $(LUA_DIST)/luvit/luv.lua
	LUA_PATH="$(LUAJLS)/?.lua;$(LUA_DIST)/?.lua" LUA_CPATH=$(LUA_DIST)/?.$(SO) $(LUA_APP) \
		compat.lua -pretty "-t=$(LUA_DIST)" $(LUAJLS)/jls
	echo "export LUA_PATH=\"$(MK_DIR)$(LUA_DIST)/luvit/?.lua;$(MK_DIR)$(LUA_DIST)/?.lua\""

dist-jls-lua54:
	cp -ur $(LUAJLS)/jls $(LUA_DIST)/

dist-jls-do: dist-jls-$(LUA_LIB)
	cp -ur $(LUAJLS)/examples $(LUA_DIST)/

dist-jls: dist-min dist-jls-do

dist-versions:
	-@$(MAKE) --quiet versions$(CROSS_SUFFIX) >$(LUA_DIST)/versions.txt

dist: dist-all dist-jls-do dist-versions


luajls.tar.gz:
	cd $(LUA_DIST) && tar $(TAR_OPTIONS) -zcvf luajls$(RELEASE_NAME).tar.gz *

luajls.zip:
	cd $(LUA_DIST) && zip -r luajls$(RELEASE_NAME).zip *

luajls-archive: luajls$(ZIP)

dist-archive: luajls-archive


release-do: dist-versions dist-doc$(CROSS_SUFFIX) test$(CROSS_SUFFIX) luajls-archive

release-all: dist-all dist-jls-do release-do

release-min: dist-jls release-do

release: release-all


STATIC_FILES := docs.zip examples licenses.txt versions.txt

static.tar.gz:
	cd $(LUA_DIST) && tar $(TAR_OPTIONS) -zcvf luajls-static$(RELEASE_NAME).tar.gz lua$(EXE) $(STATIC_FILES) && \
		tar $(TAR_OPTIONS) -zcvf luajls-shared$(RELEASE_NAME).tar.gz c$(STATIC_NAME)$(EXE)

static.zip:
	cd $(LUA_DIST) && zip -r luajls-static$(RELEASE_NAME).zip lua$(EXE) $(STATIC_FILES) && \
		zip -r luajls-shared$(RELEASE_NAME).zip c$(STATIC_NAME)$(EXE) w$(STATIC_NAME)$(EXE)

static-pre:
	mv $(LUA_DIST)/lua$(EXE) $(LUA_DIST)/lua-pre$(EXE)
	mv $(LUA_DIST)/$(STATIC_NAME)$(EXE) $(LUA_DIST)/lua$(EXE)

static-post:
	mv $(LUA_DIST)/lua$(EXE) $(LUA_DIST)/$(STATIC_NAME)$(EXE)
	mv $(LUA_DIST)/lua-pre$(EXE) $(LUA_DIST)/lua$(EXE)

static-release: static shared static-pre static$(ZIP) static-post

static-release-cross:


releases: release static-release$(CROSS_SUFFIX)


lua-5.1.5:
	wget -q --no-check-certificate https://www.lua.org/ftp/lua-5.1.5.tar.gz
	tar -xf lua-5.1.5.tar.gz
	rm lua-5.1.5.tar.gz

release-5.1: lua-5.1.5 clean
	$(MAKE) LUA_PATH=lua-5.1.5 LUA_LIB=lua51 LUA_DIST=dist-5.1 LUAJLS=$(LUAJLS) all release clean

sync-git:
	git fetch
	git rebase
	git submodule update --init --recursive

sync-5.1: sync-git
	$(MAKE) release-5.1 all releases

sync: sync-git
	$(MAKE) all releases


.PHONY: dist release clean linux mingw windows win32 arm test ldoc full quick extras \
	lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg lpeglabel zlib lua-zlib \
	openssl lua-openssl luaserial luabt libjpeg lua-jpeg libexif lua-exif lua-webview \
	winapi lua-win32 lua-llthreads2 lua-linux luachild lua-struct luaexpat

