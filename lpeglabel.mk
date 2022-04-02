LIBNAME = lpeglabel
LUADIR = ../lua/

ifdef CLIBS_DEBUG
	COPT = -g
else
	COPT = -O2
endif

ifdef CLIBS_NDEBUG
	COPT += -DNDEBUG
endif

CWARNS = -Wall -Wextra -pedantic \
	-Waggregate-return \
	-Wcast-align \
	-Wcast-qual \
	-Wdisabled-optimization \
	-Wpointer-arith \
	-Wshadow \
	-Wsign-compare \
	-Wundef \
	-Wwrite-strings \
	-Wbad-function-cast \
	-Wdeclaration-after-statement \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wstrict-prototypes \
# -Wunreachable-code \


CFLAGS = $(CWARNS) $(COPT) -std=c99 -I$(LUADIR) -fPIC
CC = gcc

FILES = lplvm.o lplcap.o lpltree.o lplcode.o lplprint.o

# For Linux
linux:
	$(MAKE) lpeg.so "DLLFLAGS = -shared -fPIC"

# For Mac OS
macosx:
	$(MAKE) lpeg.so "DLLFLAGS = -bundle -undefined dynamic_lookup"

$(LIBNAME).so: $(FILES)
	env $(CC) $(DLLFLAGS) $(FILES) -o $(LIBNAME).so

# For Windows
$(LIBNAME).dll: $(FILES)
	$(CC) $(DLLFLAGS) $(FILES) -o $(LIBNAME).dll

$(FILES): makefile

clean:
	rm -f $(FILES) $(LIBNAME).so


lplcap.o: lplcap.c lplcap.h lpltypes.h
lplcode.o: lplcode.c lpltypes.h lplcode.h lpltree.h lplvm.h lplcap.h
lplprint.o: lplprint.c lpltypes.h lplprint.h lpltree.h lplvm.h lplcap.h
lpltree.o: lpltree.c lpltypes.h lplcap.h lplcode.h lpltree.h lplvm.h lplprint.h
lplvm.o: lplvm.c lplcap.h lpltypes.h lplvm.h lplprint.h lpltree.h
