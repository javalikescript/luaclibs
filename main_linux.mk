
PLAT ?= linux
SO ?= so
CC ?= gcc

LUA_PATH = lua

LUA_VARS = LUA_PATH=$(LUA_PATH)

ifeq ($(ARCH),arm)
	ARCH_SUFFIX ?= arm
else ifeq ($(ARCH),aarch64)
	ARCH_SUFFIX ?= aarch64
else
	ARCH_SUFFIX ?= default
endif

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

core: lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg lua-zlib lua-llthreads2 luachild lpeglabel lua-struct

quick: core luaserial lua-jpeg lua-exif

full: quick lua-openssl lua-linux full-$(ARCH_SUFFIX)

full-default: lua-webview

full-arm full-aarch64:

extras: luabt

any: full

configure: configure-$(ARCH_SUFFIX)

configure-default: configure-libjpeg configure-libexif configure-openssl

configure-arm: configure-libjpeg-arm configure-libexif-arm configure-openssl-arm

configure-aarch64: configure-libjpeg-aarch64 configure-libexif-aarch64 configure-openssl-aarch64

show:
	@echo Make command goals: $(MAKECMDGOALS)
	@echo TARGET: $@
	@echo ARCH: $(ARCH)
	@echo HOST: $(HOST)
	@echo PLAT: $(PLAT)
	@echo SO: $(SO)
	@echo CC: $(CC)
	@echo AR: $(AR)
	@echo RANLIB: $(RANLIB)
	@echo LD: $(LD)

lua: $(LUA_LIB)

lua51:
	$(MAKE) -C $(LUA_PATH)/src all \
		CC="$(CC) -std=gnu99" \
		AR="$(AR) rcu" \
		RANLIB=$(RANLIB) \
		MYCFLAGS="-DLUA_USE_LINUX $(LUA_MYCFLAGS)" \
		MYLIBS="-Wl,-E -ldl -lreadline -lhistory -lncurses" \
		SYSLIBS="-Wl,-E -ldl"

lua54:
	$(MAKE) -C $(LUA_PATH)/src all \
		CC="$(CC) -std=gnu99" \
		AR="$(AR) rcu" \
		RANLIB=$(RANLIB) \
		SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN" \
		MYCFLAGS="$(LUA_MYCFLAGS)" \
		SYSLIBS="-Wl,-E -ldl"

lua-cjson: lua
	$(MAKE) -C lua-cjson LUA_INCLUDE_DIR=../$(LUA_PATH)/src CC=$(CC)

luasocket: lua
	$(MAKE) -C luasocket linux LUAINC_linux=../../$(LUA_PATH)/src \
		LUALIB_linux=../../$(LUA_PATH)/src/liblua.a \
		CC_linux=$(CC) \
		LD_linux=$(LD) \
		LDFLAGS_linux="-O -fpic -shared -o"

lpeg: lua
	$(MAKE) -C lpeg lpeg.$(SO) LUADIR=../$(LUA_PATH)/src/ DLLFLAGS="-shared -fPIC"

lpeglabel: lua
	$(MAKE) -C lpeglabel lpeglabel.$(SO) LUADIR=../$(LUA_PATH)/src/ DLLFLAGS="-shared -fPIC"

libuv:
	$(MAKE) -C luv/deps/libuv -f ../../../libuv_linux.mk CC=$(CC)

luv: lua libuv
	$(MAKE) -C luv -f ../luv_linux.mk CC=$(CC) $(LUA_VARS)

luafilesystem lua-buffer luaserial lua-webview lua-linux luachild lua-struct: lua
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

luabt: lua
	$(MAKE) -C luabt -f ../luabt.mk CC=$(CC) LIBEXT=$(SO) EXTRA_CFLAGS=-I$(LIBBT) EXTRA_LIBOPT=-L$(LIBBT) $(LUA_VARS)

lua-llthreads2: lua
	$(MAKE) -C $@/src -f ../../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

zlib:
	$(MAKE) -C zlib -f ../zlib.mk CC=$(CC)

lua-zlib: lua zlib
	$(MAKE) -C lua-zlib -f ../lua-zlib.mk PLAT=$(PLAT) CC=$(CC) LD=$(LD) AR=$(AR) RANLIB=$(RANLIB) $(LUA_VARS)

## perl Configure --cross-compile-prefix=arm-linux-gnueabihf- no-threads linux-armv4 -Wl,-rpath=.
## perl Configure no-threads linux-x86_64 -Wl,-rpath=.
## perl Configure no-threads linux-x86 -Wl,-rpath=.
configure-openssl:
	cd openssl && perl Configure no-threads linux-$(ARCH) -Wl,-rpath=.

configure-openssl-arm:
	cd openssl && perl Configure --cross-compile-prefix=$(HOST)- no-threads linux-armv4 -Wl,-rpath=.

configure-openssl-aarch64:
	cd openssl && perl Configure --cross-compile-prefix=$(HOST)- no-threads linux-aarch64 -Wl,-rpath=.

openssl:
	$(MAKE) -C openssl CC=$(CC) LD=$(LD) AR="$(AR)"

lua-openssl: openssl
	$(MAKE) -C lua-openssl -f ../lua-openssl.mk PLAT=$(PLAT) OPENSSLDIR=../openssl CC=$(CC) LD=$(LD) AR=$(AR) $(LUA_OPENSSL_VARS) $(LUA_VARS)

configure-libjpeg:
	cd lua-jpeg/libjpeg && sh configure CFLAGS='-O2 -fPIC'

configure-libjpeg-arm configure-libjpeg-aarch64:
	cd lua-jpeg/libjpeg && sh configure --host=$(HOST) CC=$(HOST)-gcc LD=$(HOST)-gcc CFLAGS='-O2 -fPIC'

libjpeg:
	$(MAKE) -C lua-jpeg/libjpeg libjpeg.la

lua-jpeg: lua libjpeg
	$(MAKE) -C lua-jpeg -f ../lua-jpeg.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

configure-libexif:
	cd lua-exif/libexif && sh configure CFLAGS='-O2 -fPIC'

configure-libexif-arm configure-libexif-aarch64:
	cd lua-exif/libexif && sh configure --host=$(HOST) CC=$(HOST)-gcc LD=$(HOST)-gcc CFLAGS='-O2 -fPIC'

libexif:
	$(MAKE) -C lua-exif/libexif

lua-exif: lua libexif
	$(MAKE) -C lua-exif -f ../lua-exif.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)


.PHONY: full quick extras lua lua-buffer lua-cjson luafilesystem luasocket libuv luv lpeg luaserial luabt \
	zlib lua-zlib openssl lua-openssl libjpeg lua-jpeg libexif lua-exif lua-webview lua-llthreads2 lua-linux luachild lpeglabel

