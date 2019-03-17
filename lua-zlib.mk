# This Makefile is based on LuaSec's Makefile. Thanks to the LuaSec developers.
# Inform the location to intall the modules
INCDIR   ?= -I../lua/src -I../zlib
LIBDIR   ?= -L../lua/src

PLAT=windows
#PLAT=linux

LIBNAME = zlib

TARGET=$(LIBNAME).$(LIBEXT_$(PLAT))

SRCS = lua_zlib.c
OBJS = lua_zlib.o

LIBS = ../zlib/libz.a
WARN = -Wall -pedantic

LIBEXT_windows = dll
LIBEXT_linux = so

CFLAGS_linux  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
LDFLAGS_linux = -O -shared -fPIC -Wl,-s

CFLAGS_windows  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
LDFLAGS_windows = -O -shared -fPIC -Wl,-s -llua53

CC = gcc
LD = gcc
CFLAGS += $(CFLAGS_$(PLAT))
LDFLAGS = $(LDFLAGS_$(PLAT))

.PHONY: all clean none linux windows

lib: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

.c.o:
	$(CC) -c $(CFLAGS) $(DEFS) $(INCDIR) -o $@ $<

$(TARGET): $(OBJS)
	$(LD) $(LDFLAGS) $(LIBDIR) $(OBJS) $(LIBS) -o $@
