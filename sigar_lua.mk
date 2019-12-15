
PLAT=windows
#PLAT=linux

LUA_PATH = lua
LUA_LIB = lua53

SIGAR_HOME = ../..

LIBNAME = sigar

SIGAR_LIB = $(SIGAR_HOME)/lib$(LIBNAME).a
#SIGAR_LIB = -L$(SIGAR_HOME) -l$(LIBNAME)

## Commands
# SET PATH=%PATH%;dist-win32
# lua -e "for k, v in pairs(require('sigar')) do print(k, v) end"
# lua sigar\bindings\lua\sigar-test.lua

TARGET=$(LIBNAME).$(LIBEXT_$(PLAT))

## Includes

INCS = -I$(SIGAR_HOME)/../$(LUA_PATH)/src -I$(SIGAR_HOME)/include

## Sources

SRCS = sigar-cpu.c \
	sigar-disk.c \
	sigar-fs.c \
	sigar-mem.c \
	sigar-netif.c \
	sigar-proc.c \
	sigar-swap.c \
	sigar-sysinfo.c \
	sigar-version.c \
	sigar-who.c \
	sigar.c

## Headers

HDRS = lua-sigar.h

## Build Objects

OBJS = sigar-cpu.o \
	sigar-disk.o \
	sigar-fs.o \
	sigar-mem.o \
	sigar-netif.o \
	sigar-proc.o \
	sigar-swap.o \
	sigar-sysinfo.o \
	sigar-version.o \
	sigar-who.o \
	sigar.o

## Libraries

LIBS_windows = -L$(SIGAR_HOME)/../$(LUA_PATH)/src -l$(LUA_LIB) -lws2_32 -lnetapi32 -lversion
LIBS_linux = -L$(SIGAR_HOME)/../$(LUA_PATH)/src
LIBS += $(LIBS_$(PLAT))

WARN = -pedantic
#WARN = -Wall -pedantic

LIBEXT_windows = dll
LIBEXT_linux = so

## Defines

DEFS_windows = -DHAVE_MIB_IPADDRROW_WTYPE=1
DEFS_linux = 
DEFS += $(DEFS_$(PLAT))

## Compile Flags

CFLAGS_base = -O2 -fPIC $(WARN)
CFLAGS_windows = $(CFLAGS_base)
CFLAGS_linux = $(CFLAGS_base)
CFLAGS += $(CFLAGS_$(PLAT))

## Link Flags

LDFLAGS_base = -O -shared -static-libgcc -fPIC -Wl,-s
LDFLAGS_linux = $(LDFLAGS_base)
LDFLAGS_windows = $(LDFLAGS_base)
LDFLAGS = $(LDFLAGS_$(PLAT))

CC = gcc
LD = gcc

.PHONY: all clean none

lib: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

.c.o: $(HDRS) $(SIGAR_LIB)
	$(CC) -c $(CFLAGS) $(DEFS) $(INCS) -o $@ $<

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) $(SIGAR_LIB) $(LIBS) -o $@
