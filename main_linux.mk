
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

ifeq ($(RELEASE_SUFFIX),-wd)
	LIB_UV_TAG := v1.44.2
	LIB_UV_TARGET := tag
else
	LIB_UV_TARGET := dep
endif

EXPAT=expat-2.5.0
LSQLITE=lsqlite3_v096

ifeq ($(LIBBT),)
	BT_OPTS = 
else
	INCBT ?= $(LIBBT)/../../include
	BT_OPTS = EXTRA_CFLAGS=-I$(INCBT) EXTRA_LIBOPT=-L$(LIBBT)
endif


ifeq ($(OS),Windows_NT)
	NULL := NUL
else
	NULL := /dev/null
endif

OPT_BLUETOOTH = $(shell env echo -e "\x23include <bluetooth/bluetooth.h>"| $(CC) -E - >$(NULL) 2>&1 || echo -NA-)
OPT_LINUX_GPIO = $(shell env echo -e "\x23include <linux/gpio.h>" | $(CC) -E - >$(NULL) 2>&1 && test -d lua-periphery || echo -NA-)
OPT_WEBKIT2GTK = $(shell pkg-config gtk+-3.0 webkit2gtk-4.0 >$(NULL) 2>&1 || echo -NA-)

all any: full

core: lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg lua-zlib lua-llthreads2 luachild lpeglabel lua-struct

quick: core luaserial lua-jpeg lua-exif luaexpat

extras: lua-linux lua-periphery$(OPT_LINUX_GPIO) lua-webview$(OPT_WEBKIT2GTK) luabt$(OPT_BLUETOOTH)

full: quick lua-openssl extras

%-NA-:
	@echo Ignoring $@

configure: configure-$(ARCH_SUFFIX)

configure-default: configure-libjpeg configure-libexif configure-openssl configure-libexpat-default

configure-arm: configure-libjpeg-arm configure-libexif-arm configure-openssl-arm configure-libexpat-arm

configure-aarch64: configure-libjpeg-aarch64 configure-libexif-aarch64 configure-openssl-aarch64 configure-libexpat-aarch64

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
		MYCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN $(LUA_MYCFLAGS)" \
		MYLIBS="-Wl,-E -ldl" \
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

libuv-$(LIB_UV_TAG):
	git clone --depth 1 --branch $(LIB_UV_TAG) https://github.com/libuv/libuv libuv-$(LIB_UV_TAG)

libuv-tag: libuv-$(LIB_UV_TAG)
	$(MAKE) -C libuv-$(LIB_UV_TAG) -f ../libuv-$(LIB_UV_TAG)_linux.mk CC=$(CC)

libuv-dep:
	$(MAKE) -C luv/deps/libuv -f ../../../libuv_linux.mk CC=$(CC)

libuv: libuv-$(LIB_UV_TARGET)

luv-tag:
	$(MAKE) -C luv -f ../luv_linux.mk CC=$(CC) LIB_UV_PATH=../libuv-$(LIB_UV_TAG) $(LUA_VARS)

luv-dep:
	$(MAKE) -C luv -f ../luv_linux.mk CC=$(CC) $(LUA_VARS)

luv: lua libuv luv-$(LIB_UV_TARGET)

luafilesystem lua-buffer luaserial lua-webview lua-linux luachild lua-struct: lua
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

lsqlite3: lua
	$(MAKE) -C $(LSQLITE) -f ../$@.mk CC=$(CC) LIBEXT=$(SO) $(LUA_VARS)

luabt: lua
	$(MAKE) -C luabt -f ../luabt.mk CC=$(CC) LIBEXT=$(SO) $(BT_OPTS) $(LUA_VARS)

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

configure-libexpat-default:
	cd $(EXPAT) && sh configure

configure-libexpat-arm configure-libexpat-aarch64:
	cd $(EXPAT) && sh configure --host=$(HOST) CC=$(HOST)-gcc LD=$(HOST)-gcc

configure-libexpat: configure-libexpat-$(ARCH_SUFFIX)

libexpat:
	$(MAKE) -C $(EXPAT)/lib

luaexpat: lua libexpat
	$(MAKE) -C $@ -f ../$@.mk CC=$(CC) LIBEXT=$(SO) EXPAT=../$(EXPAT) $(LUA_VARS)

lua-periphery:
	CROSS_COMPILE=$(HOST) $(MAKE) -C $@ LUA_INCDIR=../lua/src $(LUA_VARS)

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


.PHONY: full quick extras lua lua-buffer lua-cjson luafilesystem luasocket libuv luv lpeg luaexpat luaserial luabt \
	zlib lua-zlib openssl lua-openssl libjpeg lua-jpeg libexif lua-exif lua-webview lua-llthreads2 lua-linux luachild lpeglabel lua-periphery lsqlite3

