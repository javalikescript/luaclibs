
## Overview

This repository contains [lua](http://www.lua.org/) 5.3, selected lua modules and the associated makefiles.
The targeted operating systems are Linux and Windows. The targeted architectures are x86, x86-64, ARM.

You could find informations and releases [here](javalikescript.free.fr/lua/)

[![Build Status](https://travis-ci.org/javalikescript/luaclibs.svg?branch=master)](https://travis-ci.org/javalikescript/luaclibs)

## How to setup?

This repository mainly contains submodule and so needs to be initialized before it can be used

```bash
git submodule init
git submodule update
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
make clean
```

You could specify the target OS using `PLAT=linux` available OSes are linux and windows.

You could specify the target architecture using `ARCH=arm` available architectures are arm and x86_64.

You could specify a single module to built using `MAIN_TARGET=lua-openssl`


### How to build on Windows (MinGW)?
Tested on Windows 10 with msys packages available in March 2019

Prerequisites

Install [msys2](https://www.msys2.org/)

Install make and mingw32 gcc
```bash
pacman -S make mingw-w64-i686-gcc
```

Install additional stuff for OpenSSL
```bash
pacman -S perl libtool texinfo
```

Add mingw32 and msys in your path using:
```
SET PATH=...\msys64\mingw32\bin;...\msys64\usr\bin;%PATH%
```

### How to build on Linux?

Install the Bluetooth library

```bash
sudo apt-get install libbluetooth-dev
```

### How to build for Raspberry Pi (ARM)?

Prerequisites

You need to install a specific gcc for cross compile

Install the [tools](https://github.com/raspberrypi/tools) on a Linux OS

Get the Bluetooth library from your Raspberry Pi

```bash
export PATH=$HOME/raspberry/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin:$PATH
export HOST=arm-linux-gnueabihf
export CC=${HOST}-gcc
export LIBBT=../../libluetooth
```
