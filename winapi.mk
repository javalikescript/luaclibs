CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBEXT=dll
LIBNAME=winapi
TARGET=$(LIBNAME).$(LIBEXT)

# test
# lua -e "print(require('winapi').show_message('Message', 'stuff\nand nonsense', 'yes-no', 'warning'))"
# lua -e "print(require('winapi').show_message('Message', 'arguments\n'..table.concat(arg, ' ')))"

LIBOPT = -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  -static-libgcc \
  -lkernel32 -luser32 -lpsapi -ladvapi32 -lshell32 -lMpr

## -lmsvcr80

CFLAGS = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -DPSAPI_VERSION=1 \
  -I../$(LUA_PATH)/src

## -g -O1 -DWIN32=1

SOURCES = winapi.c wutils.c wutils.h

OBJS = winapi.o wutils.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
