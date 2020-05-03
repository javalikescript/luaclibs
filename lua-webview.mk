CC ?= gcc

LIBEXT ?= dll
LIBNAME=webview
TARGET=$(LIBNAME).$(LIBEXT)

TARGETS=$(TARGET) WebView2Win32.$(LIBEXT)

LUA_PATH = lua
LUA_LIB = lua53

WEBVIEW_C=webview-c
MS_WEBVIEW2=$(WEBVIEW_C)/ms.webview2.0.8.355

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\$(LUA_PATH)\src -l$(LUA_LIB) \
  -static-libgcc \
  -lole32 -lcomctl32 -loleaut32 -luuid -lgdi32

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I$(WEBVIEW_C) \
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

lib: $(TARGETS)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

WebView2Win32.so:

WebView2Win32.dll:
	$(CC) $(WEBVIEW_C)/WebView2Win32.c \
    -shared \
    -static-libgcc \
    -Wl,-s \
    -I$(WEBVIEW_C) -I$(MS_WEBVIEW2)/include \
    -L$(MS_WEBVIEW2)/x64 -lWebView2Loader \
    -o WebView2Win32.dll

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
