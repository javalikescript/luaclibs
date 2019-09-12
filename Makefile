
UNAME_S := $(shell uname -s)

ARCH = x86_64

ifeq ($(UNAME_S),Linux)
	PLAT ?= linux
else
	PLAT ?= windows
endif

ifdef HOST
	CROSS_PREFIX ?= $(HOST)-
endif

MAIN_TARGET = core

LUA_DIST = dist-$(PLAT)
LUAJLS = luajls

SO = $(SO_$(PLAT))
EXE = $(EXE_$(PLAT))
MAIN_MK = $(MK_$(PLAT))
ZIP = $(ZIP_$(PLAT))

SO_windows=dll
EXE_windows=.exe
MK_windows=main_mingw.mk
ZIP_windows=.zip

SO_linux=so
EXE_linux=
MK_linux=main_linux.mk
ZIP_linux=.tar.gz

GCC_NAME ?= $(shell $(CROSS_PREFIX)gcc -dumpmachine)
LUA_DATE ?= $(shell lua/src/lua$(EXE) -e "print(os.date('%Y%m%d'))")
DIST_SUFFIX ?= -$(GCC_NAME).$(LUA_DATE)

def: main

all: full

core quick full:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

lua lua-buffer luasocket luafilesystem lua-cjson luv lpeg luaserial luabt lua-zlib lua-openssl lua-jpeg lua-exif winapi:
	@$(MAKE) PLAT=$(PLAT) MAIN_TARGET=$@ main

help:
	@echo Main targets \(MAIN_TARGET\): full quick core
	@echo Other targets: arm linux windows clean dist help
	@echo Available platforms \(PLAT\): linux windows

show:
	@echo Make command goals: $(MAKECMDGOALS)
	@echo TARGET: $@
	@echo ARCH: $(ARCH)
	@echo HOST: $(HOST)
	@echo PLAT: $(PLAT)
	@echo GCC_NAME: $(GCC_NAME)
	@echo Library extension: $(SO)

arm linux-arm:
	@$(MAKE) main ARCH=arm HOST=arm-linux-gnueabihf PLAT=linux MAIN_TARGET=$(MAIN_TARGET)

win32 windows linux mingw: main

main:
	@$(MAKE) -f $(MAIN_MK) \
		PLAT=$(PLAT) \
		SO=$(SO) \
		ARCH=$(ARCH) \
		HOST=$(HOST) \
		CC=$(CROSS_PREFIX)gcc \
		AR=$(CROSS_PREFIX)ar \
		RANLIB=$(CROSS_PREFIX)ranlib \
		LD=$(CROSS_PREFIX)gcc \
		$(MAIN_TARGET)

#find . -name "*.o" -o -name "*.a" -o -name "*.exe" -o -name "*.dll" -o -name "*.so" | sed -e 's/\/[^^\/]*\(\.[^^.]*\)$/\/*\1/' | sort -u

cleanLua:
	-$(RM) ./lua/src/*.o
	-$(RM) ./lua/src/*.a ./lua/src/*.$(SO)
	-$(RM) ./lua/src/lua$(EXE) ./lua/src/luac$(EXE)

cleanLuaLibs:
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
	-$(RM) ./luv/*.$(SO)
	-$(RM) ./luv/src/*.o
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
	-$(RM) ./winapi/*.o
	-$(RM) ./winapi/*.$(SO)

cleanLibs:
	-$(RM) ./libuv/*.a
	-$(RM) ./libuv/src/*.o
	-$(RM) ./libuv/src/unix/*.o
	-$(RM) ./libuv/src/win/*.o
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

clean: cleanLua cleanLibs cleanLuaLibs

distClean:
	rm -rf $(LUA_DIST)

distPrepare:
	mkdir $(LUA_DIST)
	mkdir $(LUA_DIST)/lmprof
	mkdir $(LUA_DIST)/mime
	mkdir $(LUA_DIST)/socket

distCopy-linux:
	-cp -uP openssl/libcrypto.so* $(LUA_DIST)/
	-cp -uP openssl/libssl.so* $(LUA_DIST)/

distCopy-windows:
	-cp -u lua/src/lua*.$(SO) $(LUA_DIST)/
	-cp -u openssl/libcrypto*.dll $(LUA_DIST)/
	-cp -u openssl/libssl*.dll $(LUA_DIST)/

distCopy: distCopy-$(PLAT)
	cp -u lua/src/lua$(EXE) $(LUA_DIST)/
	cp -u lua/src/luac$(EXE) $(LUA_DIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_DIST)/
	cp -u lua-buffer/buffer.$(SO) $(LUA_DIST)/
	cp -u luafilesystem/lfs.$(SO) $(LUA_DIST)/
	cp -u luv/luv.$(SO) $(LUA_DIST)/
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
	-cp -u winapi/winapi.$(SO) $(LUA_DIST)/
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

dist: distClean distPrepare distCopy

dist-jls: dist
	cp -ur $(LUAJLS)/jls $(LUA_DIST)/

dist-jls.tar.gz: dist-jls
	cd $(LUA_DIST) && tar --group=jls --owner=jls -zcvf luajls-$(PLAT).tar.gz *

dist-jls.zip: dist-jls
	cd $(LUA_DIST) && zip -r luajls-$(PLAT).zip *

dist-jls-archive: dist-jls$(ZIP)

luajls.tar.gz: dist-jls
	cd $(LUA_DIST) && tar --group=jls --owner=jls -zcvf luajls$(DIST_SUFFIX).tar.gz *

luajls.zip: dist-jls
	cd $(LUA_DIST) && zip -r luajls$(DIST_SUFFIX).zip *

luajls-archive: luajls$(ZIP)

.PHONY: dist clean linux mingw windows win32 arm \
	full quick lua lua-buffer luasocket luafilesystem lua-cjson libuv luv lpeg luaserial luabt sigar luasigar \
	lmprof zlib lua-zlib openssl lua-openssl libjpeg lua-jpeg libexif lua-exif winapi
