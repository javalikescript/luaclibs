LUA_PATH = lua
LUA_LIB = lua53

INCDIR ?= -I../$(LUA_PATH)/src -I../zlib
LIBDIR ?= -L../$(LUA_PATH)/src

PLAT = windows

LIBNAME = zlib

TARGET=$(LIBNAME).$(LIBEXT_$(PLAT))

SRCS = lua_zlib.c
OBJS = lua_zlib.o

LIBS = ../zlib/libz.a
WARN = -Wall -pedantic

LIBEXT_linux = so
CFLAGS_linux  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
LDFLAGS_linux = -O -shared -fPIC -Wl,-s

LIBEXT_windows = dll
CFLAGS_windows  = -O2 -fPIC $(WARN) $(INCDIR) $(DEFS)
LDFLAGS_windows = -O -shared -fPIC -Wl,-s -l$(LUA_LIB)

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
