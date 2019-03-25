
PLAT?=win32
PLATS=arm arm-linux linux mingw win32
#LUA_DIST=dist-$(PLAT)
LUA_DIST=dist
SO=$(SO_$(PLAT))
EXE=$(EXE_$(PLAT))
CROSS=$(CROSS_$(PLAT))

LUAJLS=luajls

SO_mingw=dll
EXE_mingw=.exe
MAKE_mingw=main_mingw.mk

SO_win32=dll
EXE_win32=.exe
MAKE_win32=main_mingw.mk

SO_linux=so
EXE_linux=
MAKE_linux=main_linux.mk

SO_arm=so
EXE_arm=
CROSS_arm=arm-linux-gnueabihf-
MAKE_arm=main_linux.mk

MAIN_TARGET=all
#MAIN_TARGET=quick

all: $(PLAT)

quick:
	$(MAKE) PLAT=$(PLAT) MAIN_TARGET=quick

arm:
	$(MAKE) linux PLAT=arm MAIN_TARGET=$(MAIN_TARGET)

win32: mingw

linux:
	$(MAKE) -f main_linux.mk $(MAIN_TARGET) \
		PLAT=$(PLAT) \
		CC=$(CROSS)gcc \
		AR=$(CROSS)ar \
		RANLIB=$(CROSS)ranlib \
		LD=$(CROSS)gcc

mingw:
	$(MAKE) -f main_mingw.mk $(MAIN_TARGET)

.PHONY: dist clean $(PLATS)

#find . -name "*.o" -o -name "*.a" -o -name "*.exe" -o -name "*.dll" -o -name "*.so" | sed -e 's/\/[^^\/]*\(\.[^^.]*\)$/\/*\1/' | sort -u

cleanLua:
	-$(RM) ./lua/src/*.o
	-$(RM) ./lua/src/*.a ./lua/src/*.$(SO)
	-$(RM) ./lua/src/lua$(EXE) ./lua/src/luac$(EXE)

cleanLuaLibs:
	-$(RM) ./lua-cjson/*.o
	-$(RM) ./lua-cjson/*.$(SO)
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

clean: cleanLua cleanLibs cleanLuaLibs

#	-cp -u openssl/libcrypto.$(SO).* $(LUA_DIST)/
#	-cp -u openssl/libssl.$(SO).* $(LUA_DIST)/

distClean:
	rm -rf $(LUA_DIST)

distPrepare:
	mkdir $(LUA_DIST)
	mkdir $(LUA_DIST)/lmprof
	mkdir $(LUA_DIST)/mime
	mkdir $(LUA_DIST)/socket

distCopy:
	cp -u lua/src/lua$(EXE) $(LUA_DIST)/
	-cp -u lua/src/lua53.$(SO) $(LUA_DIST)/
	cp -u lua/src/luac$(EXE) $(LUA_DIST)/
	cp -u lua-cjson/cjson.$(SO) $(LUA_DIST)/
	cp -u luafilesystem/lfs.$(SO) $(LUA_DIST)/
	cp -u luv/luv.$(SO) $(LUA_DIST)/
	cp -u lpeg/lpeg.$(SO) $(LUA_DIST)/
	cp -u luaserial/serial.$(SO) $(LUA_DIST)/
	-cp -u luabt/bt.$(SO) $(LUA_DIST)/
	-cp -u sigar/bindings/lua/*.$(SO) $(LUA_DIST)/
	cp -u lmprof/lmprof.$(SO) $(LUA_DIST)/
	cp -u lmprof/src/reduce/*.lua $(LUA_DIST)/lmprof/
	cp -u lua-zlib/zlib.$(SO) $(LUA_DIST)/
	-cp -u openssl/libcrypto*.$(SO) $(LUA_DIST)/
	-cp -u openssl/libssl*.$(SO) $(LUA_DIST)/
	cp -u lua-openssl/openssl.$(SO) $(LUA_DIST)/
	cp -u luaunit/luaunit.lua $(LUA_DIST)/
	cp -u dkjson/dkjson.lua $(LUA_DIST)/
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
	cp -u -r $(LUAJLS)/jls $(LUA_DIST)/

dist: distClean distPrepare distCopy

luajls.zip: dist
	cd $(LUA_DIST) && zip -r luajls.zip *
