CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBEXT ?= dll
LIBNAME = llthreads
TARGET = $(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L../../$(LUA_PATH)\src -l$(LUA_LIB)

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
	-pthread \
	-lpthread \
  -static-libgcc \
  -Wl,-s \
  -L../../$(LUA_PATH)\src \
  $(LIBS)

CFLAGS_so = -pedantic  \
  -fPIC \
  -pthread \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../../$(LUA_PATH)/src

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = l52util.c llthread.c

OBJS = l52util.o llthread.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
