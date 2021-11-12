
## Overview

luaclibs provides the dependent modules used by [luajls](https://github.com/javalikescript/luajls).

This repository contains [Lua](http://www.lua.org/) 5.4, selected Lua modules and associated makefiles.
The targeted operating systems are Linux and Windows. The targeted architectures are x86, x86-64 and ARM.

You could find information and download binaries on the [luajls](http://javalikescript.free.fr/lua/) page.

## How to setup?

This repository mainly contains submodule and so needs to be initialized before it can be used

```bash
git submodule update --init --recursive
```

The OpenSSL, JPEG and EXIF libraries need to be configured prior the build.

## How to build?

Prerequisites

You need make and gcc tools

Build core modules
```bash
make
```

Configure then make all modules
```bash
make configure
make all
```

Create a distribution folder containing the binaries
```bash
make dist
```

Clean the build files
```bash
make clean-all
```


### How to build on Windows (MinGW)?
<!--- Tested on Windows 10 with msys packages available in March 2019 -->
Prerequisites

Install [msys2](https://www.msys2.org/)

Install make and mingw gcc
```bash
pacman -S make mingw-w64-x86_64-gcc
```

Install additional stuff for OpenSSL and webview
```bash
pacman -S perl libtool texinfo zip pkg-config
```

Set mingw64 and msys in the beginning of your path using:
```
SET PATH=...\msys64\mingw64\bin;...\msys64\usr\bin;%PATH%
```

### How to build on Linux?

Prerequisites

Install the Bluetooth library and gtk-webkit2

```bash
sudo apt-get install libbluetooth-dev libgtk-3-dev libwebkit2gtk-4.0-dev
```

### How to build for Raspberry Pi (ARM)?

Prerequisites

You need to install a specific gcc for cross compile

Install the [tools](https://github.com/raspberrypi/tools) on a Linux OS

Get the Bluetooth library from your Raspberry Pi and export the following variables

```bash
export PATH=$HOME/raspberry/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin:$PATH
export HOST=arm-linux-gnueabihf
export CC=${HOST}-gcc
export LIBBT=../../libluetooth
```
