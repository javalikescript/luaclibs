CC ?= gcc

LIB_UV = ../libuv/libuv.a
#LIB_UV = ../libuv/libuv.so

LIB_OPTION= -O \
	-shared \
	-lrt \
	-lpthread \
	-static-libgcc \
	-L../lua/src \
	-fPIC -Wl,-s

LIB_OPTION += -pthread

#-Wl,-s \
#-Wl,--whole-archive $(LIB_UV) -Wl,--no-whole-archive
# "-S" omits debugger symbol information (but not all symbols) from the output file,
# while "-s" omits all symbol information from the output file.

#gcc -O -shared -fPIC -Wl,-s -L../lua/src -L../lua/src lua_zlib.o ../zlib/libz.a -o zlib.so

# -L..\libuv -Wl,-uv,$(LIB_UV) -o $(LIB_UV)
# -L..\libuv -luv \
# -Wl,--output-def,luv.def,--out-implib,luv.a

# WARN= -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic

#cc  -DBUILDING_UV_SHARED -DLUA_USE_DLOPEN -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGEFILE_SOURCE -Dluv_EXPORTS -Ideps/libuv/src -Ideps/libuv/include -Ideps/libuv/src/unix -Ideps/lua  -fPIC   -o CMakeFiles/luv.dir/src/luv.c.o   -c src/luv.c
#cc  -fPIC   -shared  -o luv.so CMakeFiles/luv.dir/src/luv.c.o libuv.a -lrt -lpthread 


CFLAGS += -fPIC \
	-Isrc \
	-I../lua/src \
	-I../libuv/include \
	-DBUILDING_UV_SHARED \
	-D_FILE_OFFSET_BITS=64  \
	-D_GNU_SOURCE  \
	-D_LARGEFILE_SOURCE \
	-DLUA_USE_DLOPEN  \
	-DLUA_LIB \
	-Dluv_EXPORTS

CFLAGS += -pthread

INCLUDES = src/lhandle.h \
	src/lreq.h \
	src/lthreadpool.h \
	src/luv.h \
	src/util.h

OBJS = src/luv.o

TARGET = luv.so

lib: $(TARGET)

#$(TARGET): $(OBJS)
#	$(CC) $(LIB_OPTION) $(OBJS) -o $@

$(TARGET): $(OBJS) $(LIB_UV)
	$(LD) $(LIB_OPTION) $(OBJS) $(LIB_UV) -o $@

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(INCLUDES)
	$(CC) $(CFLAGS) -c -o $@ $<

