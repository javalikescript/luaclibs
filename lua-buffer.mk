CC ?= gcc

LIBEXT ?= dll
LIBNAME = buffer
TARGET = $(LIBNAME).$(LIBEXT)
LUA_PATH = lua
LUA_LIB = lua54

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  -lkernel32

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
	-pthread \
	-lpthread \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src

CFLAGS_so = -pedantic  \
  -fPIC \
  -pthread \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT = $(LIBOPT_$(LIBEXT))

ifdef CLIBS_DEBUG
	CFLAGS += -g
else
	CFLAGS += -O
endif

ifdef CLIBS_NDEBUG
	CFLAGS += -DNDEBUG
endif

#-DNO_MUTEX=1
#-DUSE_SOFT_MUTEX=1
CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = buffer.c

OBJS = buffer.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
