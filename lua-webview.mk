CC ?= gcc

LIBEXT ?= dll
LIBNAME = webview
TARGET = $(LIBNAME).$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua53

WEBVIEW_C = webview-c
MS_WEBVIEW2 = $(WEBVIEW_C)/ms.webview2.0.9.538

GCC_NAME ?= $(shell $(CC) -dumpmachine)

WEBVIEW_ARCH = x64
ifeq (,$(findstring x86_64,$(GCC_NAME)))
  WEBVIEW_ARCH = x86
endif

LIBOPT_dll = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I$(WEBVIEW_C) \
  -I$(MS_WEBVIEW2)/include \
  -I../$(LUA_PATH)/src \
  -DWEBVIEW_WINAPI=1

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\$(LUA_PATH)\src \
  $(shell pkg-config --libs gtk+-3.0 webkit2gtk-4.0)

CFLAGS_so = -pedantic \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I$(WEBVIEW_C) \
  -I../$(LUA_PATH)/src \
  -DWEBVIEW_GTK=1 \
  $(shell pkg-config --cflags gtk+-3.0 webkit2gtk-4.0)

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = webview.c

OBJS = webview.o

SRCS = $(WEBVIEW_C)/webview.h \
  $(WEBVIEW_C)/webview-cocoa.c \
  $(WEBVIEW_C)/webview-gtk.c \
  $(WEBVIEW_C)/webview-win32.c \
  $(WEBVIEW_C)/webview-win32-edge.c

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES) $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<
