CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua54

LIBFANN_HOME = ../fann
LIBFANN = $(LIBFANN_HOME)/src/doublefann.o

LIBEXT=dll
LIBNAME=fann
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_COMMON = -O \
  -shared \
  -Wl,-s \
  C:\bin\msys64\mingw64\lib\libgomp.a \
  -L..\$(LUA_PATH)\src \
  $(LIBFANN)

CFLAGS_COMMON = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -fopenmp \
  -I../$(LUA_PATH)/src \
  -I$(LIBFANN_HOME)/src/include

LIBOPT_dll = $(LIBOPT_COMMON) \
  -l$(LUA_LIB) \

CFLAGS_dll = $(CFLAGS_COMMON)

LIBOPT_so = $(LIBOPT_COMMON) \
  -static-libgcc

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  $(CFLAGS_COMMON)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = src/fann.c src/fann.h

OBJS = src/fann.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
