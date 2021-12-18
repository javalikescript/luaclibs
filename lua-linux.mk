CC ?= gcc

LIBEXT ?= so
LIBNAME = linux
SRCNAME = $(LIBNAME)
TARGET = $(LIBNAME).$(LIBEXT)

LUA_PATH = lua

LIBOPT = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src

CFLAGS +=  -pedantic \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

OBJS = $(SRCNAME).o

SRCS = $(SRCNAME).c

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<
