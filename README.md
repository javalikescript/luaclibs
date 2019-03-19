
## Overview

This repository contains [lua](http://www.lua.org/) 5.3, selected lua modules and the associated makefiles.
The targeted operating systems are Linux and Windows. The targeted architectures are x86, x86-64, ARM.

## How to build?

Prerequisites
You need make and gcc

Build all modules
```bash
make
```

Create a dist-win32 folder containing the binaries
```bash
make dist
```

Clean the build files
```bash
make clean
```


### How to build on Windows?
Tested on Windows 10 with msys packages available in March 2019

Prerequisites
Install [msys2](https://www.msys2.org/)
Install make and mingw32 gcc
```bash
pacman -S make mingw-w64-i686-gcc
```

Add mingw32 and msys in your path using:
```
SET PATH=...\msys64\mingw32\bin;...\msys64\usr\bin;%PATH%
```

