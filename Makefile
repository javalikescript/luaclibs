
UNAME_S := $(shell uname -s)

MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MK_DIR := $(dir $(MK_PATH))

ARCH = x86_64

ifeq ($(UNAME_S),Linux)
	PLAT ?= linux
else
	PLAT ?= windows
endif

MAIN_TARGET = core

LUA_PATH := lua
LUA_LIB := lua53

LUA_DIST := dist-$(PLAT)
LUAJLS = luajls

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

ifdef HOST
	CROSS_PREFIX ?= $(HOST)-
	LUA_DATE = $(shell date '+%Y%m%d')
	LUA_VERSION = $(shell echo $(LUA_LIB) | sed 's/^[^0-9]*\([0-9]\)/\1./')
	ifneq (,$(findstring arm,$(HOST)))
		ARCH = arm
	endif
endif

TESTS_LUA := $(patsubst luajls/%.lua,%.lua,$(wildcard luajls/tests/*.lua))
LUAJLS_CMD := LUA_PATH=$(MK_DIR)/$(LUA_DIST)/?.lua LUA_CPATH=$(MK_DIR)/$(LUA_DIST)/?.$(SO) LD_LIBRARY_PATH=$(MK_DIR)/$(LUA_DIST) $(MK_DIR)/$(LUA_DIST)/lua$(EXE)

main: main-$(PLAT)

all: full

core quick full show-main configure configure-libjpeg configure-libexif configure-openssl:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg luaserial luabt lua-zlib lua-openssl lua-jpeg lua-exif lua-webview winapi:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

help:
	@echo Main targets \(MAIN_TARGET\): full quick core
	@echo Other targets: arm linux windows clean dist help
	@echo Available platforms \(PLAT\): linux windows
	@echo Available architecture \(ARCH\): x86_64 arm

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

versions:
	@$(LUA_APP) -e "print(_VERSION)"
	-@LUA_CPATH=luasocket/src/socket-3.0-rc1.$(SO) $(LUA_APP) -e "print('socket', require('socket_core')._VERSION)"
	-@LUA_CPATH=luv/?.$(SO) $(LUA_APP) -e "print('luv', require('luv').version_string())"
	-@LUA_CPATH=lua-cjson/?.$(SO) $(LUA_APP) -e "print('cjson', require('cjson')._VERSION)"
	-@LUA_CPATH=lua-zlib/?.$(SO) $(LUA_APP) -e "print('zlib', require('zlib')._VERSION)"
	-@LUA_CPATH=lua-openssl/?.$(SO) $(LUA_APP) -e "print('openssl', require('openssl').version())"

dist-versions:
	@$(LUAJLS_CMD) -e "print(_VERSION)"
	-@$(LUAJLS_CMD) -e "print('socket', require('socket')._VERSION)"
	-@$(LUAJLS_CMD) -e "print('cjson', require('cjson')._VERSION)"
	-@$(LUAJLS_CMD) -e "print('zlib', require('zlib')._VERSION)"
	-@$(LUAJLS_CMD) -e "print('luv', require('luv').version_string())"
	-@$(LUAJLS_CMD) -e "print('openssl', require('openssl').version())"

arm linux-arm:
	@$(MAKE) main ARCH=arm HOST=arm-linux-gnueabihf PLAT=linux MAIN_TARGET=$(MAIN_TARGET)

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


test: $(TESTS_LUA)
	@echo $(words $(TESTS_LUA)) test files passed

$(TESTS_LUA):
	@echo Testing $@
	-@cd luajls && $(LUAJLS_CMD) $@


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
	-$(RM) ./luaserial/*.o
	-$(RM) ./luaserial/*.$(SO)
	-$(RM) ./luabt/*.o
	-$(RM) ./luabt/*.$(SO)
	-$(RM) ./sigar/bindings/lua/*.o
	-$(RM) ./sigar/bindings/lua/*.$(SO)
	-$(RM) ./lmprof/src/*.o
	-$(RM) ./lmprof/*.$(SO)
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

clean-libuv:
	-$(RM) ./libuv/*.a
	-$(RM) ./libuv/src/*.o
	-$(RM) ./libuv/src/unix/*.o
	-$(RM) ./libuv/src/win/*.o

clean-libs: clean-libuv
	-$(MAKE) -C openssl clean
	-$(RM) ./openssl/*/*.$(SO)
	-$(RM) ./zlib/*.o
	-$(RM) ./zlib/*.lo
	-$(RM) ./zlib/*.a ./zlib/*.$(SO)*
	-$(RM) ./sigar/*.a
	-$(RM) ./sigar/src/*.o
	-$(RM) ./sigar/src/os/*/*.o
	-$(MAKE) -C libjpeg clean
	-$(MAKE) -C libexif clean

clean: clean-lua clean-lua-libs

clean-all: clean-lua clean-libs clean-lua-libs


dist-clean:
	rm -rf $(LUA_DIST)

dist-prepare:
	mkdir $(LUA_DIST)
	mkdir $(LUA_DIST)/lmprof
	mkdir $(LUA_DIST)/mime
	mkdir $(LUA_DIST)/socket

dist-copy-linux:
	-cp -uP openssl/libcrypto.$(SO)* $(LUA_DIST)/
	-cp -uP openssl/libssl.$(SO)* $(LUA_DIST)/

dist-copy-windows:
	-cp -u $(LUA_PATH)/src/lua*.$(SO) $(LUA_DIST)/
	-cp -u openssl/libcrypto*.$(SO) $(LUA_DIST)/
	-cp -u openssl/libssl*.$(SO) $(LUA_DIST)/
	-cp -u winapi/winapi.$(SO) $(LUA_DIST)/

dist-copy: dist-copy-$(PLAT)
	cp -u $(LUA_PATH)/src/lua$(EXE) $(LUA_DIST)/
	cp -u $(LUA_PATH)/src/luac$(EXE) $(LUA_DIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_DIST)/
	cp -u lua-buffer/buffer.$(SO) $(LUA_DIST)/
	cp -u luafilesystem/lfs.$(SO) $(LUA_DIST)/
	-cp -u luv/luv.$(SO) $(LUA_DIST)/
	cp -u lpeg/lpeg.$(SO) $(LUA_DIST)/
	cp -u lua-zlib/zlib.$(SO) $(LUA_DIST)/
	cp -u luaunit/luaunit.lua $(LUA_DIST)/
	cp -u dkjson/dkjson.lua $(LUA_DIST)/
	-cp -u luaserial/serial.$(SO) $(LUA_DIST)/
	-cp -u luabt/bt.$(SO) $(LUA_DIST)/
	-cp -u sigar/bindings/lua/*.$(SO) $(LUA_DIST)/
	-cp -u lmprof/lmprof.$(SO) $(LUA_DIST)/
	-cp -u lmprof/src/reduce/*.lua $(LUA_DIST)/lmprof/
	-cp -u lua-openssl/openssl.$(SO) $(LUA_DIST)/
	-cp -u lua-jpeg/jpeg.$(SO) $(LUA_DIST)/
	-cp -u lua-exif/exif.$(SO) $(LUA_DIST)/
	-cp -u lua-webview/webview.$(SO) $(LUA_DIST)/
	cp -u luasocket/src/mime-1.0.3.$(SO) $(LUA_DIST)/mime/core.$(SO)
	cp -u luasocket/src/socket-3.0-rc1.$(SO) $(LUA_DIST)/socket/core.$(SO)
	cp -u luasocket/src/ltn12.lua $(LUA_DIST)/
	cp -u luasocket/src/mime.lua $(LUA_DIST)/
	cp -u luasocket/src/socket.lua $(LUA_DIST)/
	cp -u luasocket/src/ftp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/headers.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/http.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/smtp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/tp.lua $(LUA_DIST)/socket/
	cp -u luasocket/src/url.lua $(LUA_DIST)/socket/

dist: dist-clean dist-prepare dist-copy

dist-jls: dist
	cp -ur $(LUAJLS)/jls $(LUA_DIST)/


luajls.tar.gz:
	cd $(LUA_DIST) && tar --group=jls --owner=jls -zcvf luajls$(DIST_SUFFIX).tar.gz *

luajls.zip:
	cd $(LUA_DIST) && zip -r luajls$(DIST_SUFFIX).zip *

luajls-archive: luajls$(ZIP)

dist-archive: luajls-archive

.PHONY: dist clean linux mingw windows win32 arm test \
	full quick lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg luaserial luabt sigar luasigar \
	lmprof zlib lua-zlib openssl lua-openssl libjpeg lua-jpeg libexif lua-exif lua-webview winapi
