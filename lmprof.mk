CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

LIBEXT=dll
#LIBEXT=so
LIBNAME=lmprof
TARGET=$(LIBNAME).$(LIBEXT)

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
  -L../$(LUA_PATH)/src \
  $(LIBS)
	
CFLAGS_so = -Wall -pedantic -fPIC -shared \
  -I../lua/src

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = src/lmprof.c src/lmprof_hash.c src/lmprof_hash.h src/lmprof_lstrace.c src/lmprof_lstrace.h src/lmprof_stack.c src/lmprof_stack.h

OBJS = src/lmprof.o src/lmprof_hash.o src/lmprof_lstrace.o src/lmprof_stack.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
