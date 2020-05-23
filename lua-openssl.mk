CC ?= gcc

LUA_PATH = lua
LUA_LIB = lua53

PLAT ?= windows

OPENSSLDIR = ../openssl
LUADIR = ../$(LUA_PATH)/src

LIBNAME = openssl

AUXDIR = deps/auxiliar

LIBOPT_OPENSSL_SHARED = -L$(OPENSSLDIR) -lssl -lcrypto
LIBOPT_OPENSSL_STATIC = $(OPENSSLDIR)/libssl.a $(OPENSSLDIR)/libcrypto.a

ifeq ($(PLAT),linux)
  LIBOPT_OPENSSL_SHARED = -L$(OPENSSLDIR) -lssl -lcrypto -ldl
endif

ifeq ($(PLAT),windows)
  LIBOPT_OPENSSL_STATIC = $(OPENSSLDIR)/libssl.a $(OPENSSLDIR)/libcrypto.a -lws2_32 -lgdi32 -lcrypt32
endif

ifdef OPENSSL_STATIC
	LIBOPT_OPENSSL ?= $(LIBOPT_OPENSSL_STATIC)
else
	LIBOPT_OPENSSL ?= $(LIBOPT_OPENSSL_SHARED)
endif

# pkg-config openssl --static --libs

LIBEXT_windows = dll
LIBOPT_windows = -O \
  -shared \
  -Wl,-s \
  $(LIBOPT_OPENSSL) \
  -L$(LUADIR) -l$(LUA_LIB)
CFLAGS_windows = -Wall \
  -Wextra \
  -Wno-unused-parameter \
  -Wstrict-prototypes \
  -I$(OPENSSLDIR)/include \
  -I$(AUXDIR) \
  -I$(LUADIR)

LIBEXT_linux = so
#  -m32 -Wa,--noexecstack -Wall -fomit-frame-pointer
LIBOPT_linux = -O3 \
  -shared \
  -fPIC \
  -static-libgcc \
  -Wl,-s \
  $(LIBOPT_OPENSSL)
CFLAGS_linux = -pedantic  \
  -fPIC \
  -Wall \
  -Wextra \
  -std=gnu99 \
  -DLUA_USE_DLOPEN  \
  -DLUA_LIB \
  -I$(OPENSSLDIR)/include \
  -I$(AUXDIR) \
  -I$(LUADIR)

#  -Wno-unused-parameter \
#  -Wstrict-prototypes \

TARGET = $(LIBNAME).$(LIBEXT_$(PLAT))
LIBOPT = $(LIBOPT_$(PLAT))
CFLAGS += $(CFLAGS_$(PLAT))
LIBS=$(LIBS_$(PLAT))

OBJS=$(AUXDIR)/auxiliar.o $(AUXDIR)/subsidiar.o src/asn1.o src/bio.o src/cipher.o src/cms.o src/compat.o src/crl.o src/csr.o src/dh.o src/digest.o src/dsa.o src/ec.o \
	src/engine.o src/hmac.o src/lbn.o src/lhash.o src/misc.o src/ocsp.o src/openssl.o src/ots.o src/pkcs12.o src/pkcs7.o src/pkey.o \
	src/rsa.o src/srp.o src/ssl.o src/th-lock.o src/util.o src/x509.o src/xattrs.o src/xexts.o src/xname.o src/xstore.o src/xalgor.o src/callback.o 

SRCS=$(AUXDIR)/auxiliar.c $(AUXDIR)/subsidiar.c src/asn1.c src/bio.c src/cipher.c src/cms.c src/compat.c src/crl.c src/csr.c src/dh.c src/digest.c src/dsa.c src/ec.c \
	src/engine.c src/hmac.c src/lbn.c src/lhash.c src/misc.c src/ocsp.c src/openssl.c src/ots.c src/pkcs12.c src/pkcs7.c src/pkey.c \
	src/rsa.c src/srp.c src/ssl.c src/th-lock.c src/util.c src/x509.c src/xattrs.c src/xexts.c src/xname.c src/xstore.c src/xalgor.c src/callback.c 

lib: $(TARGET)

#lib$(LIBNAME).a: $(OBJS)
#	$(AR) rcs lib$(LIBNAME).a $(OBJS)

#$(TARGET)NO: lib$(LIBNAME).a
#	$(CC) -o $(TARGET) src/$(LIBNAME).o -L. -l$(LIBNAME) -L$(LUADIR) -llua
#	-L$(OPENSSLDIR) -lssl -lcrypto -Wl,--no-undefined -fpic -lrt -ldl -lm -shared -ldl -pthread

$(TARGET): $(OBJS)
	$(CC) $(OBJS) $(LIBOPT) -o $(TARGET)

clean:
	-$(RM) $(OBJS) $(TARGET)

$(OBJS): %.o : %.c $(SRCS)
	$(CC) $(CFLAGS) -c -o $@ $<


