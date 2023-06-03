CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBJPEG_HOME = libjpeg
LIBJPEG = $(LIBJPEG_HOME)/.libs/libjpeg.a

LIBEXT=dll
#LIBEXT=so
LIBNAME=jpeg
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  $(LIBJPEG)

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src \
  -I$(LIBJPEG_HOME)

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src \
  $(LIBJPEG)

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src \
  -I$(LIBJPEG_HOME)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = jpeg.c lua-compat/luamod.h lua-compat/compat.h

OBJS = jpeg.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
