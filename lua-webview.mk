CC ?= gcc

LIBEXT ?= dll
LIBNAME = webview
TARGET = $(LIBNAME).$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua53

WEBVIEW_C = webview-c
MS_WEBVIEW2 = $(WEBVIEW_C)/ms.webview2
MEMMODULE = MemoryModule

GCC_NAME ?= $(shell $(CC) -dumpmachine)

WEBVIEW_ARCH = x64
ifeq (,$(findstring x86_64,$(GCC_NAME)))
  WEBVIEW_ARCH = x86
endif

WOPTS = -w
#WOPTS = -Wall -Wextra -Wno-unused-parameter -Wstrict-prototypes

LIBOPT_dll = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L../$(LUA_PATH)/src -l$(LUA_LIB) \
  -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32

CFLAGS_dll = $(WOPTS) \
  -I$(WEBVIEW_C) \
  -I$(MEMMODULE) \
  -I$(MS_WEBVIEW2)/include \
  -I../$(LUA_PATH)/src \
  -DWEBVIEW2_MEMORY_MODULE=1 \
  -DWEBVIEW_WINAPI=1

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L../$(LUA_PATH)/src \
  $(shell pkg-config --libs gtk+-3.0 webkit2gtk-4.0)

CFLAGS_so = -pedantic \
  -fPIC \
  $(WOPTS) \
  -I$(WEBVIEW_C) \
  -I../$(LUA_PATH)/src \
  -DWEBVIEW_GTK=1 \
  $(shell pkg-config --cflags gtk+-3.0 webkit2gtk-4.0)

SOURCES_dll=$(MEMMODULE)/MemoryModule.c
SOURCES_so=

OBJS_dll=$(MEMMODULE)/MemoryModule.o
OBJS_so=

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = webview.c $(SOURCES_$(LIBEXT))

OBJS = webview.o $(OBJS_$(LIBEXT))

SRCS = $(WEBVIEW_C)/webview.h \
  $(WEBVIEW_C)/webview-cocoa.c \
  $(WEBVIEW_C)/webview-gtk.c \
  $(WEBVIEW_C)/webview-win32.c \
  $(WEBVIEW_C)/webview-win32-edge.c \
  $(WEBVIEW_C)/ms.webview2/include/WebView2.h \
  $(WEBVIEW_C)/ms.webview2/include/WebView2EnvironmentOptions.h

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES) $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<
