CC ?= gcc

LIBEXT ?= dll
LIBNAME=webview
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\lua\src -llua53 \
  -static-libgcc \
  -lole32 -lcomctl32 -loleaut32 -luuid -mwindows

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -DWEBVIEW_WINAPI=1

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\lua\src \
  $(shell pkg-config --libs gtk+-3.0 webkit2gtk-4.0)

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src \
  -DWEBVIEW_GTK=1 \
  $(shell pkg-config --cflags gtk+-3.0 webkit2gtk-4.0)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = webview.c

OBJS = webview.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
