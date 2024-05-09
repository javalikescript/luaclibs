#!/bin/sh

# Naive pkg-config helper for cross compilation
# This script extracts the configurations, headers and libraries from the target then simulates pkg-config on the compile host.

# On the target, the following command creates a zip, 'pkg-config.zip', containing the config, headers and libraries for all the listed packages
#  pkg-config.sh --config --archive <package ...>

# On the compile host, unzip 'pkg-config.zip' to a 'pkg' folder
#  then export the environment variable 'PKG_HOME' with the full path of the 'pkg' folder
#  then create a link 'pkg-config' on the path to 'pkg-config.sh'

PKG_HOME="${PKG_HOME:-}"

ZIP_NAME="${ZIP_NAME:-pkg-config.zip}"
CFG_NAME="${CFG_NAME:-pkg-config.txt}"
if test -n "$PKG_HOME"
then
  ZIP_PATH="$PKG_HOME/$ZIP_NAME"
  CFG_PATH="$PKG_HOME/$CFG_NAME"
fi

# Collect options and packages from arguments
OPTS=""
PKGS=""
for ARG in "$@"
do
  case "$ARG" in
  --help)
    echo "$0 [--cflags|--libs|--config|--archive] [package ...]" 1>&2
    exit 0
    ;;
  --*)
    OPTS="$OPTS $ARG"
    ;;
  *)
    PKGS="$PKGS $ARG"
    ;;
  esac
done

# When there is no option, indicates if the packages are availables
if test ! -n "$OPTS"
then
  for PKG in $PKGS
  do
    if ! grep -q "pkg-$PKG--" $CFG_PATH
    then
      exit 1
    fi
  done
  exit 0
fi

CFG_OUT=""

# Process the options
for OPT in $OPTS
do
  case "$OPT" in
  --cflags|--libs)
    # root is $CC -print-sysroot
    if test "$OPT" = "--libs" -a -n "$PKG_HOME"
    then
      GCC_ARCH=`$CC -dumpmachine`
      CFG_OUT="$CFG_OUT -L$PKG_HOME/usr/lib/$GCC_ARCH"
    fi
    for PKG in $PKGS
    do
      if grep -q "pkg-$PKG--" $CFG_PATH
      then
        CFG=`grep "pkg-$PKG$OPT=" $CFG_PATH | sed 's/^[^=]*=//'`
        CFG_OUT="$CFG_OUT $CFG"
      else
        echo "Package not found '$PKG'" 1>&2
        exit 1
      fi
    done
    ;;
  --config|--txt)
    for PKG in $PKGS
    do
      if ! pkg-config $PKG
      then
        echo "Package not found '$PKG'" 1>&2
        exit 1
      fi
    done
    for PKG in $PKGS
    do
      printf "pkg-$PKG--cflags="
      pkg-config --cflags $PKG
      printf "pkg-$PKG--libs="
      pkg-config --libs $PKG
    done > $CFG_PATH
    ;;
  --archive|--zip|--list)
    CFG=`pkg-config --cflags --libs $PKGS`
    FILES=`echo $CFG | tr ' ' '\n' | grep "^-I" | sed 's/^-I//' | xargs`
    LIBS=`echo $CFG | tr ' ' '\n' | grep "^-l" | sed 's/^-l//' | xargs`
    LIB_DIRS=`echo $CFG | tr ' ' '\n' | grep "^-L" | sed 's/^-L//' | xargs`
    GCC_ARCH=`gcc -print-multiarch`
    LIB_DIRS="$LIB_DIRS /usr/lib/$GCC_ARCH /usr/lib /lib"
    for LIB in $LIBS
    do
      LIBNAME="lib$LIB.so"
      for LIB_DIR in $LIB_DIRS
      do
        if test -e "$LIB_DIR/$LIBNAME"
        then
          FILES="$FILES $LIB_DIR/$LIBNAME"
          break
        fi
      done
    done
    if test -f "$CFG_PATH"
    then
      FILES="$FILES $CFG_PATH"
    fi
    if test "$OPT" = "--list"
    then
      echo $FILES
      exit 0
    fi
    zip -r $ZIP_PATH $FILES
    ;;
  *)
    echo "Unknown option '$OPT'" 1>&2
    exit 1
    ;;
  esac
done

if test -n "$CFG_OUT"
then
  if test -n "$PKG_HOME"
  then
    echo "$CFG_OUT" | sed "s: -I: -I$PKG_HOME:g"
  else
    echo "$CFG_OUT"
  fi
fi
