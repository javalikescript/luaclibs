
PLAT = windows

MK_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))

LIBNAME = fann

TARGET=$(LIBNAME).a

INCDIR ?= -Isrc/include

SRCS = src/doublefann.c
OBJS = src/doublefann.o

WARN = -Wall -pedantic

CFLAGS_linux  = -D_REENTRANT -fopenmp -O3 -DNDEBUG -MD $(WARN) $(INCDIR)
ARFLAGS_linux =

CFLAGS_windows  = -D_REENTRANT -fopenmp -O3 -DNDEBUG -MD $(WARN) $(INCDIR)
ARFLAGS_windows = -fopenmp -shared -o "RANLIB=strip --strip-unneeded"

CC = cc
AR = $(CC)
CFLAGS += $(CFLAGS_$(PLAT))
ARFLAGS = $(ARFLAGS_$(PLAT))

lib: $(TARGET)

clean:
	rm -f $(OBJS) $(TARGET)

.c.o:
	$(CC) -c $(CFLAGS) $(DEFS) $(INCDIR) -o $@ $<

$(TARGET): $(OBJS) $(MK_PATH)
	$(AR) $(ARFLAGS) $(OBJS) -o $@
