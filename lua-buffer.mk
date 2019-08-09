CC ?= gcc

LIBEXT ?= dll
LIBNAME=buffer
TARGET=$(LIBNAME).$(LIBEXT)

LIBOPT_dll = -O \
  -shared \
  -Wl,-s \
  -L..\lua\src -llua53

CFLAGS_dll = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src

LIBOPT_so = -O \
  -shared \
  -static-libgcc \
  -Wl,-s \
  -L..\lua\src

CFLAGS_so = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I../lua/src

LIBOPT = $(LIBOPT_$(LIBEXT))

CFLAGS += $(CFLAGS_$(LIBEXT))

SOURCES = buffer.c

OBJS = buffer.o

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SOURCES)
	$(CC) $(CFLAGS) -c -o $@ $<
