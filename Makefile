HASH := $(shell git rev-parse --short=10 HEAD)
OS := $(shell uname)
ARCH := $(shell uname -m)
ifeq ($(OS), Linux)
J := $(shell nproc --all)
endif

ifeq ($(OS), Darwin)
J := 12
#J := $(shell system_profiler | awk '/Number of CPUs/ {print $$4}{next;}')
endif

ifeq ($(OS), MINGW64_NT-10.0-17763)
J := 4
endif

$(info building with $(J) threads)
SHELL := /bin/bash


BASE.DIR=$(PWD)
DOWNLOADS.DIR=$(BASE.DIR)/downloads
INSTALLED.HOST.DIR=$(BASE.DIR)/installed.host
INSTALLED.TARGET.DIR=$(BASE.DIR)/installed.target
CMAKE.VERSION=3.14.5
CMAKE.URL=https://github.com/Kitware/CMake/archive/v$(CMAKE.VERSION).tar.gz
CMAKE.DIR=$(DOWNLOADS.DIR)/CMake-$(CMAKE.VERSION)
CMAKE.ARCHIVE=v$(CMAKE.VERSION).tar.gz
ifeq ($(OS), MINGW64_NT-10.0-17763)
CMAKE.BIN=cmake
else
CMAKE.BIN=$(INSTALLED.HOST.DIR)/bin/cmake
endif

SOURCE.DIR=$(BASE.DIR)/source
PROJECT.VS2019.BUILD=$(BASE.DIR)/build.vs2019
MSBUILD.EXE="\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe" 
MSBUILD.PROJ=ALL_BUILD.vcxproj
BUILD.DIR=$(BASE.DIR)/build.signalrclientcpp


ifeq ($(OS), MINGW64_NT-10.0-17763)
SHELL :=/bin/bash
#export PATH := /c/tools/msys64/usr/bin:$(PATH)
ci: bootstrap.windows
else
ci: bootstrap
endif

submodule: .FORCE
	git submodule init
	git submodule update

bootstrap: submodule cmake

cmake.fetch: .FORCE
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget $(CMAKE.URL) && cd $(DOWNLOADS.DIR) &&  tar xf $(CMAKE.ARCHIVE)

cmake: cmake.clean cmake.fetch
	cd $(CMAKE.DIR) && ./configure --prefix=$(INSTALLED.HOST.DIR) --no-system-zlib --parallel=8  && make -j4 install

cmake.clean: .FORCE
	rm -f $(DOWNLOADS.DIR)/$(CMAKE.ARCHIVE)
	rm -rf $(CMAKE.DIR)

clean: cmake.clean
	rm -rf $(INSTALLED.HOST.DIR)
	rm -rf $(DOWNLOADS.DIR)

.FORCE:


