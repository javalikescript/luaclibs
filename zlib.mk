CC=gcc

ifdef CLIBS_DEBUG
	CFLAGS = -g -DZLIB_DEBUG
else
	CFLAGS = -O3 -DNDEBUG
endif


CFLAGS += -fPIC -D_LARGEFILE64_SOURCE=1

#CFLAGS=-O3 -Wall -Wwrite-strings -Wpointer-arith -Wconversion \
#           -Wstrict-prototypes -Wmissing-prototypes

SFLAGS = $(CFLAGS)
LDFLAGS=
#SLA#LDFLAGS=-O -shared -fPIC -Wl,-s
TEST_LDFLAGS=-L. libz.a
LDSHARED=$(CC) -shared
CPP=$(CC) -E

STATICLIB=libz.a
SHAREDLIB=libz.so
SHAREDLIBV=libz.so.1.2.11
SHAREDLIBM=libz.so.1
LIBS=$(STATICLIB) $(SHAREDLIBV)

AR=ar
ARFLAGS=rc
RANLIB=ranlib
LDCONFIG=ldconfig
#LDSHAREDLIBC=-lc
LDSHAREDLIBC=-static-libgcc
TAR=tar
SHELL=/bin/sh
EXE=

prefix =/usr/local
exec_prefix =${prefix}
libdir =${exec_prefix}/lib
sharedlibdir =${libdir}
includedir =${prefix}/include
mandir =${prefix}/share/man
man3dir = ${mandir}/man3
pkgconfigdir = ${libdir}/pkgconfig
SRCDIR=
ZINC=
ZINCOUT=-I.

OBJZ = adler32.o crc32.o deflate.o infback.o inffast.o inflate.o inftrees.o trees.o zutil.o
OBJG = compress.o uncompr.o gzclose.o gzlib.o gzread.o gzwrite.o
OBJC = $(OBJZ) $(OBJG)

PIC_OBJZ = adler32.lo crc32.lo deflate.lo infback.lo inffast.lo inflate.lo inftrees.lo trees.lo zutil.lo
PIC_OBJG = compress.lo uncompr.lo gzclose.lo gzlib.lo gzread.lo gzwrite.lo
PIC_OBJC = $(PIC_OBJZ) $(PIC_OBJG)

# to use the asm code: make OBJA=match.o, PIC_OBJA=match.lo
OBJA =
PIC_OBJA =

OBJS = $(OBJC) $(OBJA)

PIC_OBJS = $(PIC_OBJC) $(PIC_OBJA)

#all: static shared all64
all: $(SHAREDLIB)

static: example$(EXE) minigzip$(EXE)

shared: examplesh$(EXE) minigzipsh$(EXE)

all64: example64$(EXE) minigzip64$(EXE)

check: test

test: all teststatic testshared test64

teststatic: static
	@TMPST=tmpst_$$; \
	if echo hello world | ./minigzip | ./minigzip -d && ./example $$TMPST ; then \
	  echo '		*** zlib test OK ***'; \
	else \
	  echo '		*** zlib test FAILED ***'; false; \
	fi; \
	rm -f $$TMPST

testshared: shared
	@LD_LIBRARY_PATH=`pwd`:$(LD_LIBRARY_PATH) ; export LD_LIBRARY_PATH; \
	LD_LIBRARYN32_PATH=`pwd`:$(LD_LIBRARYN32_PATH) ; export LD_LIBRARYN32_PATH; \
	DYLD_LIBRARY_PATH=`pwd`:$(DYLD_LIBRARY_PATH) ; export DYLD_LIBRARY_PATH; \
	SHLIB_PATH=`pwd`:$(SHLIB_PATH) ; export SHLIB_PATH; \
	TMPSH=tmpsh_$$; \
	if echo hello world | ./minigzipsh | ./minigzipsh -d && ./examplesh $$TMPSH; then \
	  echo '		*** zlib shared test OK ***'; \
	else \
	  echo '		*** zlib shared test FAILED ***'; false; \
	fi; \
	rm -f $$TMPSH

test64: all64
	@TMP64=tmp64_$$; \
	if echo hello world | ./minigzip64 | ./minigzip64 -d && ./example64 $$TMP64; then \
	  echo '		*** zlib 64-bit test OK ***'; \
	else \
	  echo '		*** zlib 64-bit test FAILED ***'; false; \
	fi; \
	rm -f $$TMP64

infcover.o: $(SRCDIR)test/infcover.c $(SRCDIR)zlib.h zconf.h
	$(CC) $(CFLAGS) $(ZINCOUT) -c -o $@ $(SRCDIR)test/infcover.c

infcover: infcover.o libz.a
	$(CC) $(CFLAGS) -o $@ infcover.o libz.a

cover: infcover
	rm -f *.gcda
	./infcover
	gcov inf*.c

libz.a: $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)
	-@ ($(RANLIB) $@ || true) >/dev/null 2>&1

match.o: match.S
	$(CPP) match.S > _match.s
	$(CC) -c _match.s
	mv _match.o match.o
	rm -f _match.s

match.lo: match.S
	$(CPP) match.S > _match.s
	$(CC) -c -fPIC _match.s
	mv _match.o match.lo
	rm -f _match.s

example.o: $(SRCDIR)test/example.c $(SRCDIR)zlib.h zconf.h
	$(CC) $(CFLAGS) $(ZINCOUT) -c -o $@ $(SRCDIR)test/example.c

minigzip.o: $(SRCDIR)test/minigzip.c $(SRCDIR)zlib.h zconf.h
	$(CC) $(CFLAGS) $(ZINCOUT) -c -o $@ $(SRCDIR)test/minigzip.c

example64.o: $(SRCDIR)test/example.c $(SRCDIR)zlib.h zconf.h
	$(CC) $(CFLAGS) $(ZINCOUT) -D_FILE_OFFSET_BITS=64 -c -o $@ $(SRCDIR)test/example.c

minigzip64.o: $(SRCDIR)test/minigzip.c $(SRCDIR)zlib.h zconf.h
	$(CC) $(CFLAGS) $(ZINCOUT) -D_FILE_OFFSET_BITS=64 -c -o $@ $(SRCDIR)test/minigzip.c


adler32.o: $(SRCDIR)adler32.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)adler32.c

crc32.o: $(SRCDIR)crc32.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)crc32.c

deflate.o: $(SRCDIR)deflate.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)deflate.c

infback.o: $(SRCDIR)infback.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)infback.c

inffast.o: $(SRCDIR)inffast.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)inffast.c

inflate.o: $(SRCDIR)inflate.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)inflate.c

inftrees.o: $(SRCDIR)inftrees.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)inftrees.c

trees.o: $(SRCDIR)trees.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)trees.c

zutil.o: $(SRCDIR)zutil.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)zutil.c

compress.o: $(SRCDIR)compress.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)compress.c

uncompr.o: $(SRCDIR)uncompr.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)uncompr.c

gzclose.o: $(SRCDIR)gzclose.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)gzclose.c

gzlib.o: $(SRCDIR)gzlib.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)gzlib.c

gzread.o: $(SRCDIR)gzread.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)gzread.c

gzwrite.o: $(SRCDIR)gzwrite.c
	$(CC) $(CFLAGS) $(ZINC) -c -o $@ $(SRCDIR)gzwrite.c


adler32.lo: $(SRCDIR)adler32.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o adler32.lo $(SRCDIR)adler32.c

crc32.lo: $(SRCDIR)crc32.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o crc32.lo $(SRCDIR)crc32.c

deflate.lo: $(SRCDIR)deflate.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o deflate.lo $(SRCDIR)deflate.c

infback.lo: $(SRCDIR)infback.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o infback.lo $(SRCDIR)infback.c

inffast.lo: $(SRCDIR)inffast.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o inffast.lo $(SRCDIR)inffast.c

inflate.lo: $(SRCDIR)inflate.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o inflate.lo $(SRCDIR)inflate.c

inftrees.lo: $(SRCDIR)inftrees.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o inftrees.lo $(SRCDIR)inftrees.c

trees.lo: $(SRCDIR)trees.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o trees.lo $(SRCDIR)trees.c

zutil.lo: $(SRCDIR)zutil.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o zutil.lo $(SRCDIR)zutil.c

compress.lo: $(SRCDIR)compress.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o compress.lo $(SRCDIR)compress.c

uncompr.lo: $(SRCDIR)uncompr.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o uncompr.lo $(SRCDIR)uncompr.c

gzclose.lo: $(SRCDIR)gzclose.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o gzclose.lo $(SRCDIR)gzclose.c

gzlib.lo: $(SRCDIR)gzlib.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o gzlib.lo $(SRCDIR)gzlib.c

gzread.lo: $(SRCDIR)gzread.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o gzread.lo $(SRCDIR)gzread.c

gzwrite.lo: $(SRCDIR)gzwrite.c
	$(CC) $(SFLAGS) $(ZINC) -DPIC -c -o gzwrite.lo $(SRCDIR)gzwrite.c

placebo $(SHAREDLIB): $(PIC_OBJS) libz.a
	$(LDSHARED) $(SFLAGS) -o $@ $(PIC_OBJS) $(LDSHAREDLIBC) $(LDFLAGS)

#placebo $(SHAREDLIBV): $(PIC_OBJS) libz.a
#	$(LDSHARED) $(SFLAGS) -o $@ $(PIC_OBJS) $(LDSHAREDLIBC) $(LDFLAGS)
#	rm -f $(SHAREDLIB) $(SHAREDLIBM)
#	ln -s $@ $(SHAREDLIB)
#	ln -s $@ $(SHAREDLIBM)
#	-@rmdir objs

example$(EXE): example.o $(STATICLIB)
	$(CC) $(CFLAGS) -o $@ example.o $(TEST_LDFLAGS)

minigzip$(EXE): minigzip.o $(STATICLIB)
	$(CC) $(CFLAGS) -o $@ minigzip.o $(TEST_LDFLAGS)

examplesh$(EXE): example.o $(SHAREDLIBV)
	$(CC) $(CFLAGS) -o $@ example.o -L. $(SHAREDLIBV)

minigzipsh$(EXE): minigzip.o $(SHAREDLIBV)
	$(CC) $(CFLAGS) -o $@ minigzip.o -L. $(SHAREDLIBV)

example64$(EXE): example64.o $(STATICLIB)
	$(CC) $(CFLAGS) -o $@ example64.o $(TEST_LDFLAGS)

minigzip64$(EXE): minigzip64.o $(STATICLIB)
	$(CC) $(CFLAGS) -o $@ minigzip64.o $(TEST_LDFLAGS)

install-libs: $(LIBS)
	-@if [ ! -d $(DESTDIR)$(exec_prefix)  ]; then mkdir -p $(DESTDIR)$(exec_prefix); fi
	-@if [ ! -d $(DESTDIR)$(libdir)       ]; then mkdir -p $(DESTDIR)$(libdir); fi
	-@if [ ! -d $(DESTDIR)$(sharedlibdir) ]; then mkdir -p $(DESTDIR)$(sharedlibdir); fi
	-@if [ ! -d $(DESTDIR)$(man3dir)      ]; then mkdir -p $(DESTDIR)$(man3dir); fi
	-@if [ ! -d $(DESTDIR)$(pkgconfigdir) ]; then mkdir -p $(DESTDIR)$(pkgconfigdir); fi
	rm -f $(DESTDIR)$(libdir)/$(STATICLIB)
	cp $(STATICLIB) $(DESTDIR)$(libdir)
	chmod 644 $(DESTDIR)$(libdir)/$(STATICLIB)
	-@($(RANLIB) $(DESTDIR)$(libdir)/libz.a || true) >/dev/null 2>&1
	-@if test -n "$(SHAREDLIBV)"; then \
	  rm -f $(DESTDIR)$(sharedlibdir)/$(SHAREDLIBV); \
	  cp $(SHAREDLIBV) $(DESTDIR)$(sharedlibdir); \
	  echo "cp $(SHAREDLIBV) $(DESTDIR)$(sharedlibdir)"; \
	  chmod 755 $(DESTDIR)$(sharedlibdir)/$(SHAREDLIBV); \
	  echo "chmod 755 $(DESTDIR)$(sharedlibdir)/$(SHAREDLIBV)"; \
	  rm -f $(DESTDIR)$(sharedlibdir)/$(SHAREDLIB) $(DESTDIR)$(sharedlibdir)/$(SHAREDLIBM); \
	  ln -s $(SHAREDLIBV) $(DESTDIR)$(sharedlibdir)/$(SHAREDLIB); \
	  ln -s $(SHAREDLIBV) $(DESTDIR)$(sharedlibdir)/$(SHAREDLIBM); \
	  ($(LDCONFIG) || true)  >/dev/null 2>&1; \
	fi
	rm -f $(DESTDIR)$(man3dir)/zlib.3
	cp $(SRCDIR)zlib.3 $(DESTDIR)$(man3dir)
	chmod 644 $(DESTDIR)$(man3dir)/zlib.3
	rm -f $(DESTDIR)$(pkgconfigdir)/zlib.pc
	cp zlib.pc $(DESTDIR)$(pkgconfigdir)
	chmod 644 $(DESTDIR)$(pkgconfigdir)/zlib.pc
# The ranlib in install is needed on NeXTSTEP which checks file times
# ldconfig is for Linux

install: install-libs
	-@if [ ! -d $(DESTDIR)$(includedir)   ]; then mkdir -p $(DESTDIR)$(includedir); fi
	rm -f $(DESTDIR)$(includedir)/zlib.h $(DESTDIR)$(includedir)/zconf.h
	cp $(SRCDIR)zlib.h zconf.h $(DESTDIR)$(includedir)
	chmod 644 $(DESTDIR)$(includedir)/zlib.h $(DESTDIR)$(includedir)/zconf.h

uninstall:
	cd $(DESTDIR)$(includedir) && rm -f zlib.h zconf.h
	cd $(DESTDIR)$(libdir) && rm -f libz.a; \
	if test -n "$(SHAREDLIBV)" -a -f $(SHAREDLIBV); then \
	  rm -f $(SHAREDLIBV) $(SHAREDLIB) $(SHAREDLIBM); \
	fi
	cd $(DESTDIR)$(man3dir) && rm -f zlib.3
	cd $(DESTDIR)$(pkgconfigdir) && rm -f zlib.pc

docs: zlib.3.pdf

zlib.3.pdf: $(SRCDIR)zlib.3
	groff -mandoc -f H -T ps $(SRCDIR)zlib.3 | ps2pdf - $@

zconf.h.cmakein: $(SRCDIR)zconf.h.in
	-@ TEMPFILE=zconfh_$$; \
	echo "/#define ZCONF_H/ a\\\\\n#cmakedefine Z_PREFIX\\\\\n#cmakedefine Z_HAVE_UNISTD_H\n" >> $$TEMPFILE &&\
	sed -f $$TEMPFILE $(SRCDIR)zconf.h.in > $@ &&\
	touch -r $(SRCDIR)zconf.h.in $@ &&\
	rm $$TEMPFILE

zconf: $(SRCDIR)zconf.h.in
	cp -p $(SRCDIR)zconf.h.in zconf.h

mostlyclean: clean
clean:
	rm -f *.o *.lo *~ \
	   example$(EXE) minigzip$(EXE) examplesh$(EXE) minigzipsh$(EXE) \
	   example64$(EXE) minigzip64$(EXE) \
	   infcover \
	   libz.* foo.gz so_locations \
	   _match.s maketree contrib/infback9/*.o
	rm -rf objs
	rm -f *.gcda *.gcno *.gcov
	rm -f contrib/infback9/*.gcda contrib/infback9/*.gcno contrib/infback9/*.gcov

maintainer-clean: distclean
distclean: clean zconf zconf.h.cmakein docs
	rm -f Makefile zlib.pc configure.log
	-@rm -f .DS_Store
	@if [ -f Makefile.in ]; then \
	printf 'all:\n\t-@echo "Please use ./configure first.  Thank you."\n' > Makefile ; \
	printf '\ndistclean:\n\tmake -f Makefile.in distclean\n' >> Makefile ; \
	touch -r $(SRCDIR)Makefile.in Makefile ; fi
	@if [ ! -f zconf.h.in ]; then rm -f zconf.h zconf.h.cmakein ; fi
	@if [ ! -f zlib.3 ]; then rm -f zlib.3.pdf ; fi

tags:
	etags $(SRCDIR)*.[ch]

adler32.o zutil.o: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h
gzclose.o gzlib.o gzread.o gzwrite.o: $(SRCDIR)zlib.h zconf.h $(SRCDIR)gzguts.h
compress.o example.o minigzip.o uncompr.o: $(SRCDIR)zlib.h zconf.h
crc32.o: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)crc32.h
deflate.o: $(SRCDIR)deflate.h $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h
infback.o inflate.o: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h $(SRCDIR)inflate.h $(SRCDIR)inffast.h $(SRCDIR)inffixed.h
inffast.o: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h $(SRCDIR)inflate.h $(SRCDIR)inffast.h
inftrees.o: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h
trees.o: $(SRCDIR)deflate.h $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)trees.h

adler32.lo zutil.lo: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h
gzclose.lo gzlib.lo gzread.lo gzwrite.lo: $(SRCDIR)zlib.h zconf.h $(SRCDIR)gzguts.h
compress.lo example.lo minigzip.lo uncompr.lo: $(SRCDIR)zlib.h zconf.h
crc32.lo: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)crc32.h
deflate.lo: $(SRCDIR)deflate.h $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h
infback.lo inflate.lo: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h $(SRCDIR)inflate.h $(SRCDIR)inffast.h $(SRCDIR)inffixed.h
inffast.lo: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h $(SRCDIR)inflate.h $(SRCDIR)inffast.h
inftrees.lo: $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)inftrees.h
trees.lo: $(SRCDIR)deflate.h $(SRCDIR)zutil.h $(SRCDIR)zlib.h zconf.h $(SRCDIR)trees.h
