CC ?= gcc

LIB_UV_PATH = deps/libuv
LIB_UV_LIB = $(LIB_UV_PATH)/libuv.a

LUA_PATH = lua
LUA_LIB = lua53

ifndef CLIBS_DEBUG
	LIB_OPTION += -O
endif

LIB_OPTION += -shared \
	-static-libgcc \
	-Wl,-s \
	-L..\$(LUA_PATH)\src -l$(LUA_LIB) \
	$(LIB_UV_LIB) \
	-lws2_32 -lpsapi -liphlpapi -lshell32 -luserenv -luser32 -ldbghelp -lole32 -luuid

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
	-I$(LIB_UV_PATH)/include \
	-Ideps/lua-compat-5.3/c-api \
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

HDRS = src/lhandle.h \
	src/lreq.h \
	src/lthreadpool.h \
	src/luv.h \
	src/private.h \
	src/util.h

SRCS = src/async.c \
	src/check.c \
	src/constants.c \
	src/dns.c \
	src/fs.c \
	src/fs_event.c \
	src/fs_poll.c \
	src/handle.c \
	src/idle.c \
	src/lhandle.c \
	src/loop.c \
	src/lreq.c \
	src/metrics.c \
	src/misc.c \
	src/pipe.c \
	src/poll.c \
	src/prepare.c \
	src/process.c \
	src/req.c \
	src/schema.c \
	src/signal.c \
	src/stream.c \
	src/tcp.c \
	src/thread.c \
	src/timer.c \
	src/tty.c \
	src/udp.c \
	src/util.c \
	src/work.c

lib: luv.dll

luv.dll: $(OBJS) $(LIB_UV_LIB)
	$(CC) $(OBJS) $(LIB_OPTION) -o luv.dll

clean:
	-$(RM) $(OBJS) luv.dll

$(OBJS): %.o : %.c $(INCLUDES) $(HDRS) $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<

