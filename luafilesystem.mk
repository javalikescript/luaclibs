CC ?= gcc

LIBEXT=dll
#LIBEXT=so
LIBNAME=lfs
TARGET=$(LIBNAME).$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua53

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB)

CFLAGS_dll = -Wall -Wextra -Wno-unused-parameter -Wstrict-prototypes \
  -I../$(LUA_PATH)/src

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L../$(LUA_PATH)/src \
  $(LIBS)
	
CFLAGS_so = -O2 -pedantic -fPIC -shared \
  -Wall -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings \
  -I../$(LUA_PATH)/src

##gcc -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic -I../$(LUA_PATH)/src   -c -o src/lfs.o src/lfs.c
##gcc -shared  -o src/lfs.so src/lfs.o

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = src/lfs.c src/lfs.h

OBJS = src/lfs.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
