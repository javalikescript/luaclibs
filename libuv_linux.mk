
CC ?= gcc
AR ?= ar
ARFLAGS ?= rc
#ARFLAGS ?= crs
RANLIB ?= ranlib

ifdef CLIBS_DEBUG
	CFLAGS += -g
else
	CFLAGS += -O2
endif

ifdef CLIBS_NDEBUG
	CFLAGS += -DNDEBUG
endif

CFLAGS += -fPIC \
	-pedantic \
	-Iinclude \
	-Isrc \
	-Isrc/unix \
	-std=gnu89 \
	-Wall \
	-Wextra \
	-Wno-unused-parameter \
	-Wstrict-prototypes \
	-pthread

#-static-libgcc

##LIBS = -lrt -lpthread -lnsl -ldl

#CFLAGS += -pthreads
#LDFLAGS = -no-undefined -version-info 1:0:0

INCLUDES = include/uv.h \
	include/uv/errno.h \
	include/uv/threadpool.h \
	include/uv/version.h

INCLUDES += include/uv/unix.h \
	include/uv/linux.h

INCLUDES += src/heap-inl.h \
	src/idna.h \
	src/queue.h \
	src/strscpy.h \
	src/uv-common.h \
	src/unix/atomic-ops.h \
	src/unix/internal.h \
	src/unix/spinlock.h \
	src/unix/linux-syscalls.h

OBJS = src/fs-poll.o \
	src/idna.o \
	src/inet.o \
	src/random.o \
	src/strscpy.o \
	src/threadpool.o \
	src/timer.o \
	src/uv-data-getter-setters.o \
	src/uv-common.o \
	src/version.o

OBJS += src/unix/async.o \
	src/unix/core.o \
	src/unix/dl.o \
	src/unix/fs.o \
	src/unix/getaddrinfo.o \
	src/unix/getnameinfo.o \
	src/unix/loop-watcher.o \
	src/unix/loop.o \
	src/unix/pipe.o \
	src/unix/poll.o \
	src/unix/process.o \
	src/unix/random-devurandom.o \
	src/unix/signal.o \
	src/unix/stream.o \
	src/unix/tcp.o \
	src/unix/thread.o \
	src/unix/tty.o \
	src/unix/udp.o

OBJS += src/unix/linux-core.o \
	src/unix/linux-inotify.o \
	src/unix/linux-syscalls.o \
	src/unix/procfs-exepath.o \
	src/unix/proctitle.o \
	src/unix/random-getrandom.o \
	src/unix/random-sysctl-linux.o \
	src/unix/epoll.o

all: libuv.a

clean:
	-$(RM) $(OBJS) libuv.a libuv.so

libuv.a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

#$(RANLIB) $@
#-@ ($(RANLIB) $@ || true) >/dev/null 2>&1
#$(AR) crs $@ $^

libuv.so: $(OBJS)
	$(CC) -shared $^ -o $@

# ar qc libuv.a $(OBJS)
# ranlib libuv.a

$(OBJS): %.o : %.c
	$(CC) $(CFLAGS) -c -o $@ $<
