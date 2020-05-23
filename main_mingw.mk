
PLAT = windows
SO = so
CC = gcc

LUA_PATH = lua
LUA_LIB = lua53

LUA_VARS = LUA_LIB=$(LUA_LIB) LUA_PATH=$(LUA_PATH)

ifdef CLIBS_DEBUG
	LUA_MYCFLAGS = -g -DLUA_USE_APICHECK
endif

ifdef CLIBS_NDEBUG
	LUA_MYCFLAGS += -DNDEBUG
endif

ifeq ($(LUA_OPENSSL_LINKING),dynamic)
	LUA_OPENSSL_VARS =
else
	LUA_OPENSSL_VARS = OPENSSL_STATIC=1
endif

all: full

core: lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg lua-zlib

quick: core luasigar lmprof luaserial lua-jpeg lua-exif

full: quick luabt lua-webview lua-openssl winapi lua-win32

any: full

configure: configure-libjpeg configure-libexif configure-openssl

show show-main:
	@echo Make command goals: $(MAKECMDGOALS)
	@echo TARGET: $@
	@echo ARCH: $(ARCH)
	@echo HOST: $(HOST)
	@echo PLAT: $(PLAT)
	@echo LUA_LIB: $(LUA_LIB)
	@echo LUA_PATH: $(LUA_PATH)
	@echo SO: $(SO)
	@echo CC: $(CC)
	@echo AR: $(AR)
	@echo RANLIB: $(RANLIB)
	@echo LD: $(LD)

lua:
	$(MAKE) -C $(LUA_PATH)/src mingw \
		MYCFLAGS="$(LUA_MYCFLAGS)"

lua-cjson: lua
	$(MAKE) -C lua-cjson TARGET=cjson.$(SO) \
		CJSON_CFLAGS=-DDISABLE_INVALID_NUMBERS \
		"CJSON_LDFLAGS=-O -shared -Wl,-s -static-libgcc -L../$(LUA_PATH)/src -l$(LUA_LIB)" \
		LUA_BIN_SUFFIX=.lua \
		LUA_INCLUDE_DIR=../$(LUA_PATH)/src CC=$(CC)

luasocket: lua
	$(MAKE) -C luasocket mingw LUAINC_mingw=../../$(LUA_PATH)/src \
	  DEF_mingw="-DLUASOCKET_NODEBUG -DWINVER=0x0501" \
		LUALIB_mingw="-L../../$(LUA_PATH)/src -l$(LUA_LIB)"

lpeg: lua
	$(MAKE) -C lpeg -f ../lpeg.mk lpeg.$(SO) \
		LUADIR=../$(LUA_PATH)/src/ \
		DLLFLAGS="-O -shared -fPIC -Wl,-s -static-libgcc -L../$(LUA_PATH)/src -l$(LUA_LIB)"

libuv:
	$(MAKE) -C luv/deps/libuv -f ../../../libuv_mingw.mk CC=$(CC)

luv: lua libuv
	$(MAKE) -C luv -f ../luv_mingw.mk $(LUA_VARS)

luafilesystem lua-webview lua-buffer lua-win32 luaserial luabt winapi lmprof: lua
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

sigar:
	$(MAKE) -C sigar -f ../sigar.mk CC=$(CC) PLAT=$(PLAT)

luasigar: lua sigar
	$(MAKE) -C sigar/bindings/lua -f ../../../sigar_lua.mk CC=$(CC) PLAT=$(PLAT) $(LUA_VARS)

zlib:
	$(MAKE) -C zlib -f ../zlib.mk

lua-zlib: lua zlib
	$(MAKE) -C lua-zlib -f ../lua-zlib.mk PLAT=$(PLAT) $(LUA_VARS)

configure-openssl- configure-openssl-i686:
	cd openssl && perl Configure no-threads mingw

configure-openssl-x86_64:
	cd openssl && perl Configure no-threads mingw64

configure-openssl: configure-openssl-$(ARCH)

openssl:
	$(MAKE) -C openssl LD=$(LD)

lua-openssl: lua openssl
	$(MAKE) -C lua-openssl -f ../lua-openssl.mk $(LUA_OPENSSL_VARS) PLAT=$(PLAT) $(LUA_VARS)

configure-libjpeg:
	cd libjpeg && sh configure CFLAGS='-O2 -fPIC'

libjpeg:
	$(MAKE) -C libjpeg

lua-jpeg: lua libjpeg
	$(MAKE) -C lua-jpeg -f ../lua-jpeg.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

configure-libexif:
	cd libexif && sh configure CFLAGS='-O2 -fPIC'

libexif:
	$(MAKE) -C libexif

lua-exif: lua libexif
	$(MAKE) -C lua-exif -f ../lua-exif.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

.PHONY: full quick lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg \
	luaserial luabt sigar luasigar lmprof zlib lua-zlib openssl lua-openssl libjpeg \
	lua-jpeg libexif lua-exif lua-webview winapi lua-win32
