CC ?= gcc

LIBEXIF_HOME = ../libexif
LIBEXIF = $(LIBEXIF_HOME)/libexif/.libs/libexif.a

LIBEXT=dll
#LIBEXT=so
LIBNAME=exif
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\lua\src -llua53 \
  $(LIBEXIF)

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -I$(LIBEXIF_HOME)

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\lua\src \
  $(LIBEXIF)

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -I$(LIBEXIF_HOME)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = exif.c luamod.h

OBJS = exif.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
