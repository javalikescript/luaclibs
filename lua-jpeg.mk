CC ?= gcc

LIBJPEG_HOME = ../libjpeg
LIBJPEG = $(LIBJPEG_HOME)/.libs/libjpeg.a

LIBEXT=dll
#LIBEXT=so
LIBNAME=jpeg
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\lua\src -llua53 \
  $(LIBJPEG)

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -I$(LIBJPEG_HOME)

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\lua\src \
  $(LIBJPEG)

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -I$(LIBJPEG_HOME)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = jpeg.c luamod.h

OBJS = jpeg.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
