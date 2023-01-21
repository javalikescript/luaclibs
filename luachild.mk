CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBEXT ?= dll
LIBNAME = luachild
TARGET = $(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L../$(LUA_PATH)\src -l$(LUA_LIB)

CFLAGS_dll = -O2 -std=gnu99 -fPIC -g -Wall -Wextra \
  -Wno-missing-field-initializers -Wno-override-init -Wno-unused \
  -D_REENTRANT -D_THREAD_SAFE -D_GNU_SOURCE \
  -DUSE_WINDOWS \
  -I../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -lrt -lm \
  -Wl,-s \
  -L..\$(LUA_PATH)\src

CFLAGS_so = -O2 -std=gnu99 -fPIC -g -Wall -Wextra \
  -Wno-missing-field-initializers -Wno-override-init -Wno-unused \
  -D_REENTRANT -D_THREAD_SAFE -D_GNU_SOURCE \
  -DUSE_POSIX \
  -I../$(LUA_PATH)/src

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

HDRS = luachild.h

SRCS = luachild_common.c luachild_posix.c luachild_windows.c

ifeq ($(LUA_LIB),lua51)
  SRCS += luachild_lua_5_1.c
else
  SRCS += luachild_lua_5_3.c
endif

OBJS = ${SRCS:.c=.o}

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SRCS) $(HDRS)
	$(CC) $(CFLAGS) -c -o $@ $<

