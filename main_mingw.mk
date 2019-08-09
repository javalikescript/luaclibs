
PLAT ?= windows
SO ?= so
CC ?= gcc

all: full

core: lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg lua-zlib

quick: core luasigar lmprof luaserial luabt lua-jpeg lua-exif

full: quick lua-openssl

lua:
	$(MAKE) -C lua/src mingw

lua-buffer: lua
	$(MAKE) -C lua-buffer -f ../lua-buffer.mk CC=$(CC) LIBEXT=$(SO)

lua-cjson: lua
	$(MAKE) -C lua-cjson TARGET=cjson.$(SO) \
		CJSON_CFLAGS=-DDISABLE_INVALID_NUMBERS \
		"CJSON_LDFLAGS=-O -shared -Wl,-s -static-libgcc -L../lua/src -llua53" \
		LUA_BIN_SUFFIX=.lua \
		LUA_INCLUDE_DIR=../lua/src CC=$(CC)

luafilesystem: lua
	$(MAKE) -C luafilesystem -f ../luafilesystem.mk CC=$(CC) LIBEXT=$(SO)

luasocket: lua
	$(MAKE) -C luasocket mingw LUAINC_mingw=../../lua/src \
	  DEF_mingw="-DLUASOCKET_NODEBUG -DWINVER=0x0501" \
		LUALIB_mingw="-L../../lua/src -llua53"

lpeg: lua
	$(MAKE) -C lpeg -f ../lpeg.mk lpeg.$(SO) LUADIR=../lua/src/ DLLFLAGS="-O -shared -fPIC -Wl,-s -static-libgcc -L../lua/src -llua53"

libuv:
	$(MAKE) -C libuv -f ../libuv_mingw.mk CC=$(CC)

luv: lua libuv
	$(MAKE) -C luv -f ../luv_mingw.mk

luaserial: lua
	$(MAKE) -C luaserial -f ../luaserial.mk CC=$(CC) LIBEXT=$(SO)

luabt: lua
	$(MAKE) -C luabt -f ../luabt.mk CC=$(CC) LIBEXT=$(SO)

sigar:
	$(MAKE) -C sigar -f ../sigar.mk CC=$(CC) PLAT=$(PLAT)

luasigar: sigar
	$(MAKE) -C sigar/bindings/lua -f ../../../sigar_lua.mk CC=$(CC) PLAT=$(PLAT)

lmprof: lua
	$(MAKE) -C lmprof -f ../lmprof.mk CC=$(CC) LIBEXT=$(SO)

zlib:
	$(MAKE) -C zlib -f ../zlib.mk

lua-zlib: lua zlib
	$(MAKE) -C lua-zlib -f ../lua-zlib.mk PLAT=$(PLAT)

## perl Configure no-threads mingw
## perl Configure no-threads mingw64
openssl:
	$(MAKE) -C openssl

lua-openssl: openssl
	$(MAKE) -C lua-openssl -f ../lua-openssl.mk PLAT=$(PLAT)

## sh configure CFLAGS='-O2 -fPIC'
libjpeg:
	$(MAKE) -C libjpeg

lua-jpeg: lua libjpeg
	$(MAKE) -C lua-jpeg -f ../lua-jpeg.mk CC=$(CC) LIBEXT=$(SO)

libexif:
	$(MAKE) -C libexif

lua-exif: lua libexif
	$(MAKE) -C lua-exif -f ../lua-exif.mk CC=$(CC) LIBEXT=$(SO)

.PHONY: full quick lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg luaserial luabt sigar luasigar \
	lmprof zlib lua-zlib openssl lua-openssl libjpeg lua-jpeg libexif lua-exif
