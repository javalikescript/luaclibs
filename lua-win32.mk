CC ?= gcc

LIBEXT ?= dll
LIBNAME = win32
SRCNAME = $(LIBNAME)
TARGET = $(LIBNAME).$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua54

LIBOPT = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  -lcomdlg32

# -lkernel32 -luser32 -lpsapi -ladvapi32 -lshell32 -lgdi32 -lcomctl32 -lcomdlg32 -luxtheme -lpowrprof -lMpr

CFLAGS += -Wall \
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
