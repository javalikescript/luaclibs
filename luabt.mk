CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBEXT ?= dll
LIBNAME = bt
TARGET = $(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) -lBthprops -lws2_32

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src \
  -lbluetooth

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT = $(EXTRA_LIBOPT) $(LIBOPT_$(LIBEXT))

CFLAGS = $(EXTRA_CFLAGS) $(CFLAGS_$(LIBEXT))

SOURCES = luabt.c luabt_windows.c luabt_linux.c

OBJS = luabt.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
  