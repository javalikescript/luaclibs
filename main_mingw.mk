
PLAT = windows
SO = so
CC = gcc

LUA_PATH = lua
LUA_LIB = lua54

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

EXPAT=expat-2.5.0

all: full

core: lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg lua-zlib lua-llthreads2 luachild lpeglabel lua-struct

quick: core luaserial lua-jpeg lua-exif luaexpat

full: quick lua-openssl lua-webview winapi lua-win32

extras: luabt

any: full

configure: configure-libjpeg configure-libexif configure-openssl configure-libexpat

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

wlua.res: wlua.rc
	windres wlua.rc -O coff -o $(LUA_PATH)/src/wlua.res

lua: wlua.res
	$(MAKE) -C $(LUA_PATH)/src "LUA_A=$(LUA_LIB).dll" "LUA_T=lua.exe" \
		"AR=$(CC) -static-libgcc -shared -o" "RANLIB=strip --strip-unneeded" \
		"SYSCFLAGS=-DLUA_BUILD_AS_DLL" "SYSLIBS=" "SYSLDFLAGS=-s" lua.exe
	$(MAKE) -C $(LUA_PATH)/src "LUAC_T=luac.exe" luac.exe
	$(MAKE) -C $(LUA_PATH)/src MYCFLAGS="$(LUA_MYCFLAGS)" "LUA_A=$(LUA_LIB).dll" "LUA_T=wlua.exe" "LIBS=wlua.res" \
		"SYSCFLAGS=-DLUA_BUILD_AS_DLL" "SYSLIBS=" "SYSLDFLAGS=-s -mwindows" wlua.exe

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

lpeglabel: lua
	$(MAKE) -C lpeglabel -f ../lpeglabel.mk lpeglabel.$(SO) \
		LUADIR=../$(LUA_PATH)/src/ \
		DLLFLAGS="-O -shared -fPIC -Wl,-s -static-libgcc -L../$(LUA_PATH)/src -l$(LUA_LIB)"

libuv:
	$(MAKE) -C luv/deps/libuv -f ../../../libuv_mingw.mk CC=$(CC)

luv: lua libuv
	$(MAKE) -C luv -f ../luv_mingw.mk $(LUA_VARS)

luafilesystem lua-webview lua-buffer lua-win32 luaserial luabt winapi luachild lua-struct: lua
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

lua-llthreads2: lua
	$(MAKE) -C $@/src -f ../../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

fann:
	$(MAKE) -C fann -f ../fann.mk

lua-fann: fann
	$(MAKE) -C lua-fann -f ../lua-fann.mk

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

configure-libexpat:
	cd $(EXPAT) && sh configure

libexpat:
	$(MAKE) -C $(EXPAT)

luaexpat: lua libexpat
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) EXPAT=../$(EXPAT) $(LUA_VARS)

configure-libjpeg:
	cd lua-jpeg/libjpeg && sh configure CFLAGS='-O2 -fPIC'

libjpeg:
	$(MAKE) -C lua-jpeg/libjpeg

lua-jpeg: lua libjpeg
	$(MAKE) -C lua-jpeg -f ../lua-jpeg.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

configure-libexif:
	cd lua-exif/libexif && sh configure CFLAGS='-O2 -fPIC'

libexif:
	$(MAKE) -C lua-exif/libexif

lua-exif: lua libexif
	$(MAKE) -C lua-exif -f ../lua-exif.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

.PHONY: full quick extras lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg \
	luaexpat luaserial luabt zlib lua-zlib openssl lua-openssl libjpeg \
	lua-jpeg libexif lua-exif lua-webview winapi lua-win32 lua-llthreads2 luachild lpeglabel \
	fann lua-fann
