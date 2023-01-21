CC ?= gcc

LIBEXT ?= dll
LIBNAME = struct
TARGET = $(LIBNAME).$(LIBEXT)
LUA_PATH = lua
LUA_LIB = lua54

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB)

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = struct.c

OBJS = struct.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
