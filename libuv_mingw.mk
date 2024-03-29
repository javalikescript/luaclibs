
CC ?= gcc

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
	-Iinclude \
	-Isrc \
	-Isrc/win \
	-DWIN32_LEAN_AND_MEAN \
	-D_WIN32_WINNT=0x0602

INCLUDES = include/uv.h \
	include/uv/errno.h \
	include/uv/threadpool.h \
	include/uv/version.h

INCLUDES += include/uv/win.h \
	include/uv/tree.h

INCLUDES += src/heap-inl.h \
	src/idna.h \
	src/queue.h \
	src/strscpy.h \
	src/strtok.h \
	src/uv-common.h \
	src/win/atomicops-inl.h \
	src/win/handle-inl.h \
	src/win/internal.h \
	src/win/req-inl.h \
	src/win/stream-inl.h \
	src/win/winapi.h \
	src/win/winsock.h

OBJS = src/fs-poll.o \
	src/idna.o \
	src/inet.o \
	src/random.o \
	src/strscpy.o \
	src/strtok.o \
	src/thread-common.o \
	src/threadpool.o \
	src/timer.o \
	src/uv-data-getter-setters.o \
	src/uv-common.o \
	src/version.o

OBJS += src/win/async.o \
	src/win/core.o \
	src/win/detect-wakeup.o \
	src/win/dl.o \
	src/win/error.o \
	src/win/fs-event.o \
	src/win/fs.o \
	src/win/getaddrinfo.o \
	src/win/getnameinfo.o \
	src/win/handle.o \
	src/win/loop-watcher.o \
	src/win/pipe.o \
	src/win/poll.o \
	src/win/process-stdio.o \
	src/win/process.o \
	src/win/signal.o \
	src/win/stream.o \
	src/win/tcp.o \
	src/win/thread.o \
	src/win/tty.o \
	src/win/udp.o \
	src/win/util.o \
	src/win/winapi.o \
	src/win/winsock.o

all: libuv.a

clean:
	-$(RM) $(OBJS) libuv.a

libuv.a: $(OBJS)
	$(AR) crs $@ $^

$(OBJS): %.o : %.c $(INCLUDES)
	$(CC) $(CFLAGS) -c -o $@ $<
