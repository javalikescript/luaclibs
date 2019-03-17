
PLAT=windows
#PLAT=linux

LIBNAME = sigar

TARGET=lib$(LIBNAME).a

## Commands
# del /s sigar\*.o sigar\*.a sigar\*.dll

## Includes

INCS_base = -Iinclude

INCS_windows = $(INCS_base) \
	-Isrc/os/win32

INCS_linux = $(INCS_base) \
	-Isrc/os/linux

INCS = $(INCS_$(PLAT))

## Sources

SRCS_base = src/sigar.c \
	src/sigar_cache.c \
	src/sigar_fileinfo.c \
	src/sigar_format.c \
	src/sigar_getline.c \
	src/sigar_ptql.c \
	src/sigar_signal.c \
	src/sigar_util.c \
	src/sigar_version.c

SRCS_windows = $(SRCS_base) \
	src/os/win32/peb.c \
	src/os/win32/win32_sigar.c

SRCS_linux = $(SRCS_base)

SRCS = $(SRCS_$(PLAT))

## Headers

HDRS_base = include/sigar.h \
	include/sigar_fileinfo.h \
	include/sigar_format.h \
	include/sigar_getline.h \
	include/sigar_log.h \
	include/sigar_private.h \
	include/sigar_ptql.h \
	include/sigar_util.h

HDRS_windows = $(HDRS_base) \
	src/os/win32/sigar_os.h \
	src/os/win32/sigar_pdh.h

HDRS_linux = $(HDRS_base) \
	src/os/linux/sigar_os.h

HDRS = $(HDRS_$(PLAT))

## Build Objects

OBJS_base = src/sigar.o \
	src/sigar_cache.o \
	src/sigar_fileinfo.o \
	src/sigar_format.o \
	src/sigar_getline.o \
	src/sigar_ptql.o \
	src/sigar_signal.o \
	src/sigar_util.o \
	src/sigar_version.o

OBJS_windows = $(OBJS_base) \
	src/os/win32/peb.o \
	src/os/win32/win32_sigar.o

OBJS_linux = $(OBJS_base) \
	src/os/linux/linux_sigar.o

OBJS = $(OBJS_$(PLAT))

## Libraries

#LIBS_windows = -lws2_32 -lnetapi32 -lversion
#LIBS_linux = 
#LIBS += $(LIBS_$(PLAT))

#WARN =
WARN = -pedantic
#WARN = -Wall -pedantic

#LIBEXT_windows = dll
#LIBEXT_linux = so

## Defines

DEFS_windows = -DHAVE_MIB_IPADDRROW_WTYPE=1
DEFS_linux = 
DEFS += $(DEFS_$(PLAT))

## Compile Flags

CFLAGS_base = -O2 -fPIC $(WARN)
CFLAGS_windows = $(CFLAGS_base)
CFLAGS_linux = $(CFLAGS_base) --std=gnu89 -fgnu89-inline
CFLAGS += $(CFLAGS_$(PLAT))

## Link Flags

#LDFLAGS_base = -O -shared -fPIC -Wl,-s
LDFLAGS_base =
LDFLAGS_linux = $(LDFLAGS_base)
LDFLAGS_windows = $(LDFLAGS_base)
LDFLAGS = $(LDFLAGS_$(PLAT))

CC = gcc
LD = gcc
AR ?= ar
#ARFLAGS = rc
ARFLAGS = crs

.PHONY: all clean none

lib: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

.c.o: $(HDRS)
	$(CC) -c $(CFLAGS) $(DEFS) $(INCS) -o $@ $<

#$(TARGET): $(OBJS)
#	$(LD) $(LDFLAGS) $(LIBDIR) $(OBJS) $(LIBS) -o $@

$(TARGET): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^
