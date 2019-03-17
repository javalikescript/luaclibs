
all: full

quick: lua luasocket luafilesystem lua-zlib luacjson luv lpeg luasigar lmprof luaserial luabt

full: quick

lua:
	$(MAKE) -C lua/src mingw

luacjson: lua
	$(MAKE) -C lua-cjson TARGET=cjson.dll \
		CJSON_CFLAGS=-DDISABLE_INVALID_NUMBERS \
		"CJSON_LDFLAGS=-O -shared -Wl,-s -static-libgcc -L../lua/src -llua53" \
		LUA_BIN_SUFFIX=.lua \
		LUA_INCLUDE_DIR=../lua/src CC=gcc

luafilesystem: lua
	$(MAKE) -C luafilesystem -f ../luafilesystem.mk CC=gcc LIBEXT=dll

luasocket: lua
	$(MAKE) -C luasocket mingw LUAINC_mingw=../../lua/src \
		LUALIB_mingw="-L../../lua/src -llua53"

lpeg: lua
	$(MAKE) -C lpeg -f ../lpeg.mk lpeg.dll LUADIR=../lua/src/ DLLFLAGS="-O -shared -fPIC -Wl,-s -static-libgcc -L../lua/src -llua53"

libuv:
	$(MAKE) -C libuv -f ../libuv_mingw.mk CC=gcc

luv: lua libuv
	$(MAKE) -C luv -f ../luv_mingw.mk

luaserial: lua
	$(MAKE) -C luaserial CC=gcc LIBEXT=dll

luabt: lua
	$(MAKE) -C luabt CC=gcc LIBEXT=dll

sigar:
	$(MAKE) -C sigar -f ../sigar.mk CC=gcc PLAT=windows

luasigar: sigar
	$(MAKE) -C sigar/bindings/lua -f ../../../sigar_lua.mk CC=gcc PLAT=windows

lmprof: lua
	$(MAKE) -C lmprof -f ../lmprof.mk CC=gcc LIBEXT=dll

zlib:
	$(MAKE) -C zlib -f ../zlib.mk

lua-zlib: lua zlib
	$(MAKE) -C lua-zlib -f ../lua-zlib.mk PLAT=windows

## perl Configure no-threads mingw
## perl Configure no-threads mingw64
openssl:
	$(MAKE) -C openssl

lua-openssl: openssl
	$(MAKE) -C lua-openssl -f ../lua-openssl.mk PLAT=windows

.PHONY: full quick lua luasocket luafilesystem luacjson libuv luv lpeg luaserial luabt sigar luasigar lmprof zlib lua-zlib openssl lua-openssl
