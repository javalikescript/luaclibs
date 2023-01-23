CC ?= gcc

LIB_UV_PATH = deps/libuv
LIB_UV_LIB = $(LIB_UV_PATH)/libuv.a

LUA_PATH = lua

ifndef CLIBS_DEBUG
	LIB_OPTION += -O2
endif

LIB_OPTION += -shared \
	-lrt \
	-pthread \
	-lpthread \
	-static-libgcc \
	-L../$(LUA_PATH)/src \
	-fPIC -Wl,-s

ifdef CLIBS_DEBUG
	CFLAGS += -g
else
	CFLAGS += -O2
endif

ifdef CLIBS_NDEBUG
	CFLAGS += -DNDEBUG
endif

CFLAGS += -fPIC \
	-Isrc \
	-I../$(LUA_PATH)/src \
	-I$(LIB_UV_PATH)/include \
	-Ideps/lua-compat-5.3/c-api \
	-std=gnu99 \
	-DBUILDING_UV_SHARED \
	-D_FILE_OFFSET_BITS=64  \
	-D_GNU_SOURCE  \
	-D_LARGEFILE_SOURCE \
	-DLUA_USE_DLOPEN  \
	-DLUA_LIB \
	-Dluv_EXPORTS \
	-pthread

INCLUDES = src/lhandle.h \
	src/lreq.h \
	src/lthreadpool.h \
	src/luv.h \
	src/util.h

OBJS = src/luv.o

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
	src/signal.c \
	src/stream.c \
	src/tcp.c \
	src/thread.c \
	src/timer.c \
	src/tty.c \
	src/udp.c \
	src/util.c \
	src/work.c

TARGET = luv.so

lib: $(TARGET)

$(TARGET): $(OBJS) $(LIB_UV_LIB)
	$(LD) $(LIB_OPTION) $(OBJS) $(LIB_UV_LIB) -o $@

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(INCLUDES) $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<

