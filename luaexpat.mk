CC ?= gcc

LIBEXT ?= dll
LIBNAME = lxp
TARGET = $(LIBNAME).$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua54

EXPAT=expat-2.5.0

LIBOPT_dll = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  $(EXPAT)/lib/.libs/libexpat.a

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src \
  -I$(EXPAT) \
  -I$(EXPAT)/lib

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src \
  ../$(EXPAT)/lib/libexpat.la

CFLAGS_so = -pedantic \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src \
  -I$(EXPAT) \
  -I$(EXPAT)/lib

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = src/lxplib.c

OBJS = src/lxplib.o

SRCS = src/lxplib.c src/lxplib.h

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<
