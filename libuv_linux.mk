
CC ?= gcc
AR ?= ar
ARFLAGS ?= rc
#ARFLAGS ?= crs
RANLIB ?= ranlib

CFLAGS += -g \
	-O2 \
	-fPIC \
	-pedantic \
	-g \
	-Iinclude \
	-Isrc \
	-Isrc/unix \
	-std=gnu89 \
	-Wall \
	-Wextra \
	-Wno-unused-parameter \
	-Wstrict-prototypes

CFLAGS += -pthread

#-static-libgcc

##LIBS = -lrt -lpthread -lnsl -ldl

#CFLAGS += -pthreads
#LDFLAGS = -no-undefined -version-info 1:0:0

INCLUDES = include/uv.h \
	include/uv/errno.h \
	include/uv/threadpool.h \
	include/uv/version.h

INCLUDES += include/uv/unix.h

INCLUDES += src/heap-inl.h \
	src/queue.h \
	src/unix/spinlock.h \
	src/uv-common.h \
	src/unix/atomic-ops.h \
	src/unix/internal.h \
	src/unix/linux-syscalls.h

SOURCES = src/fs-poll.c \
	src/inet.c \
	src/threadpool.c \
	src/uv-data-getter-setters.c \
	src/uv-common.c \
	src/version.c

SOURCES += src/unix/async.c \
	src/unix/core.c \
	src/unix/dl.c \
	src/unix/fs.c \
	src/unix/getaddrinfo.c \
	src/unix/getnameinfo.c \
	src/unix/loop-watcher.c \
	src/unix/loop.c \
	src/unix/pipe.c \
	src/unix/poll.c \
	src/unix/process.c \
	src/unix/signal.c \
	src/unix/stream.c \
	src/unix/tcp.c \
	src/unix/thread.c \
	src/unix/tty.c \
	src/unix/udp.c

SOURCES += src/unix/linux-core.c \
	src/unix/linux-inotify.c \
	src/unix/linux-syscalls.c \
	src/unix/procfs-exepath.c \
	src/unix/proctitle.c \
	src/unix/sysinfo-loadavg.c \
	src/unix/sysinfo-memory.c

OBJS = src/fs-poll.o \
	src/idna.o \
	src/inet.o \
	src/strscpy.o \
	src/timer.o \
	src/threadpool.o \
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
	src/unix/sysinfo-loadavg.o \
	src/unix/sysinfo-memory.o

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
