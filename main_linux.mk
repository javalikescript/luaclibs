
PLAT=linux

all: full

quick: lua luasocket luafilesystem lua-zlib luacjson luv lpeg luasigar lmprof luaserial luabt

full: quick lua-openssl

lua:
	$(MAKE) -C lua/src all \
		CC="$(CC) -std=gnu99" \
		AR="$(AR) rcu" \
		RANLIB=$(RANLIB) \
		SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
		SYSLIBS="-Wl,-E -ldl"

luacjson: lua
	$(MAKE) -C lua-cjson LUA_INCLUDE_DIR=../lua/src CC=$(CC)

luafilesystem: lua
	$(MAKE) -C luafilesystem -f ../luafilesystem.mk CC=$(CC) LIBEXT=so

luasocket: lua
	$(MAKE) -C luasocket linux LUAINC_linux=../../lua/src \
		LUALIB_linux=../../lua/src/liblua.a \
		CC_linux=$(CC) \
		LD_linux=$(LD) \
		LDFLAGS_linux="-O -fpic -shared -o"

lpeg: lua
	$(MAKE) -C lpeg lpeg.so LUADIR=../lua/src/ DLLFLAGS="-shared -fPIC"

libuv:
	$(MAKE) -C libuv -f ../libuv_linux.mk CC=$(CC)

luv: lua libuv
	$(MAKE) -C luv -f ../luv_linux.mk CC=$(CC)

luaserial: lua
	$(MAKE) -C luaserial CC=$(CC) LIBEXT=so

luabt: lua
	$(MAKE) -C luabt CC=$(CC) LIBEXT=so EXTRA_CFLAGS=-I$(LIBBT) EXTRA_LIBOPT=-L$(LIBBT)

sigar:
	$(MAKE) -C sigar -f ../sigar.mk CC=$(CC) LD=$(LD) AR=$(AR) PLAT=linux

luasigar: sigar
	$(MAKE) -C sigar/bindings/lua -f ../../../sigar_lua.mk CC=$(CC) LD=$(LD) AR=$(AR) PLAT=linux

lmprof: lua
	$(MAKE) -C lmprof -f ../lmprof.mk CC=$(CC) LIBEXT=so

zlib:
	$(MAKE) -C zlib -f ../zlib.mk CC=$(CC)

lua-zlib: lua zlib
	$(MAKE) -C lua-zlib -f ../lua-zlib.mk PLAT=linux CC=$(CC) LD=$(LD) AR=$(AR) RANLIB=$(RANLIB)

## perl Configure --cross-compile-prefix=arm-linux-gnueabihf- no-threads linux-armv4 -Wl,-rpath=.
## perl Configure no-threads linux-x86_64 -Wl,-rpath=.
openssl:
	$(MAKE) -C openssl CC=$(CC) LD=$(LD) AR="$(AR) rcu"

lua-openssl: openssl
	$(MAKE) -C lua-openssl -f ../lua-openssl.mk PLAT=linux OPENSSLDIR=../openssl CC=$(CC) LD=$(LD) AR=$(AR)


.PHONY: full quick lua luacjson luafilesystem luasocket libuv luv lpeg luaserial luabt sigar luasigar lmprof zlib lua-zlib openssl lua-openssl

