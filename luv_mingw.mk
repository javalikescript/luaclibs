CC ?= gcc

LIB_UV = ..\libuv\libuv.a

LUA_PATH = lua
LUA_LIB = lua53

ifndef CLIBS_DEBUG
	LIB_OPTION += -O
endif

LIB_OPTION += -shared \
	-static-libgcc \
	-Wl,-s \
	-L..\$(LUA_PATH)\src -l$(LUA_LIB) \
	$(LIB_UV) \
	-lws2_32 -lpsapi -liphlpapi -lshell32 -luserenv -luser32

##-lws2_32 -lpsapi -liphlpapi -luserenv

# -L..\libuv -luv \
# -Wl,--output-def,luv.def,--out-implib,luv.a

# WARN= -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic

ifdef CLIBS_DEBUG
	CFLAGS += -g
else
	CFLAGS += -O
endif

ifdef CLIBS_NDEBUG
	CFLAGS += -DNDEBUG
endif

CFLAGS += -Wall \
	-Wextra \
	-Wno-unused-parameter \
	-Wstrict-prototypes \
	-fpic \
	-Isrc \
	-I../$(LUA_PATH)/src \
	-I../libuv/include \
	-D_WIN32_WINNT=0x0600 \
	-DLUA_USE_DLOPEN \
	-DBUILDING_UV_SHARED \
	-DLUA_BUILD_AS_DLL \
	-DLUA_LIB \
	-Dluv_EXPORTS

INCLUDES = src/lhandle.h \
	src/lreq.h \
	src/lthreadpool.h \
	src/luv.h \
	src/util.h

OBJS = src/luv.o

lib: luv.dll

luv.dll: $(OBJS) $(LIB_UV)
	$(CC) $(OBJS) $(LIB_OPTION) -o luv.dll

clean:
	-$(RM) $(OBJS) luv.dll

$(OBJS): %.o : %.c $(INCLUDES)
	$(CC) $(CFLAGS) -c -o $@ $<

