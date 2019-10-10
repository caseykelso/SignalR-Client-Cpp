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
CPPRESTSDK.VERSION=2.10.14
CPPRESTSDK.ARCHIVE=v$(CPPRESTSDK.VERSION).tar.gz
CPPRESTSDK.URL=https://github.com/microsoft/cpprestsdk/archive/$(CPPRESTSDK.ARCHIVE)
CPPRESTSDK.DIR=$(DOWNLOADS.DIR)/cpprestsdk-$(CPPRESTSDK.VERSION)
CPPRESTSDK.BUILD=$(DOWNLOADS.DIR)/build.cpprestsdk
WEBSOCKETCPP.VERSION=0.8.1
WEBSOCKETCPP.ARCHIVE=$(WEBSOCKETCPP.VERSION).tar.gz
WEBSOCKETCPP.URL=https://github.com/zaphoyd/websocketpp/archive/$(WEBSOCKETCPP.ARCHIVE)
WEBSOCKETCPP.BUILD=$(DOWNLOADS.DIR)/build.websocketcpp
WEBSOCKETCPP.DIR=$(DOWNLOADS.DIR)/websocketpp-$(WEBSOCKETCPP.VERSION)
BOOST.DIR=$(DOWNLOADS.DIR)/boost
BOOST.ARCHIVE=$(DOWNLOADS.DIR)/boost_1_65_1.tar.bz2
BOOST.URL="https://s3.amazonaws.com/buildroot-sources/boost_1_65_1.tar.bz2"
GTEST.VERSION=1.8.1
GTEST.ARCHIVE=release-$(GTEST.VERSION).tar.gz
GTEST.URL=https://github.com/google/googletest/archive/$(GTEST.ARCHIVE)
GTEST.DIR=$(DOWNLOADS.DIR)/googletest-release-1.8.1
GTEST.BUILD=$(DOWNLOADS.DIR)/build.googletest

ifeq ($(OS), MINGW64_NT-10.0-17763)
SHELL :=/bin/bash
#export PATH := /c/tools/msys64/usr/bin:$(PATH)
ci: bootstrap.windows
else
ci: bootstrap signalr
endif

websocketcpp.fetch: .FORCE
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget $(WEBSOCKETCPP.URL) && tar xf $(WEBSOCKETCPP.ARCHIVE)

websocketcpp: websocketcpp.fetch
	rm -rf $(WEBSOCKETCPP.BUILD)
	mkdir -p $(WEBSOCKETCPP.BUILD) && cd $(WEBSOCKETCPP.BUILD) && $(CMAKE.BIN) -DCMAKE_INSTALL_PREFIX=$(INSTALLED.HOST.DIR) $(WEBSOCKETCPP.DIR) && make -j$(J) install

websocketcpp.clean: .FORCE
	rm -rf $(WEBSOCKETCPP.BUILD)
	rm -rf $(DOWNLOADS.DIR)/$(WEBSOCKETCPP.ARCHIVE)

cpprestsdk.fetch: .FORCE
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget $(CPPRESTSDK.URL) && tar xf $(CPPRESTSDK.ARCHIVE)

cpprestsdk: cpprestsdk.fetch
	rm -rf $(CPPRESTSDK.BUILD)
	mkdir -p $(CPPRESTSDK.BUILD) && cd $(CPPRESTSDK.BUILD) && $(CMAKE.BIN) -DCMAKE_INSTALL_PREFIX=$(INSTALLED.HOST.DIR) $(CPPRESTSDK.DIR) && make -j$(J) install

cpprestsdk.clean: .FORCE
	rm -rf $(CPPRESTSDK.BUILD)
	rm -rf $(DOWNLOADS.DIR)/$(CPPRESTSDK.ARCHIVE)

signalr: .FORCE
	rm -rf $(BUILD.DIR)
	mkdir -p $(BUILD.DIR)
	cd $(BUILD.DIR) && $(CMAKE.BIN) -DCMAKE_PREFIX_PATH=$(INSTALLED.HOST.DIR) -DCMAKE_INSTALL_PREFIX=$(INSTALLED.HOST.DIR) $(BASE.DIR) && make -j$(J) install

submodule: .FORCE
	git submodule init
	git submodule update

bootstrap: submodule cmake gtest boost websocketcpp cpprestsdk

cmake.fetch: .FORCE
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget $(CMAKE.URL) && cd $(DOWNLOADS.DIR) &&  tar xf $(CMAKE.ARCHIVE)

cmake: cmake.clean cmake.fetch
	cd $(CMAKE.DIR) && ./configure --prefix=$(INSTALLED.HOST.DIR) --no-system-zlib --parallel=8  && make -j4 install

cmake.clean: .FORCE
	rm -f $(DOWNLOADS.DIR)/$(CMAKE.ARCHIVE)
	rm -rf $(CMAKE.DIR)

boost: .FORCE
	rm -rf $(BOOST.DIR)
	rm -f $(BOOST.ARCHIVE)
	mkdir -p $(BOOST.DIR)
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget $(BOOST.URL)	
	cd $(BOOST.DIR) && tar xvf $(BOOST.ARCHIVE) && cd boost_1_65_1 && ./bootstrap.sh --prefix=$(INSTALLED.HOST.DIR) && ./b2 stage threading=multi link=shared && ./b2 install threading=multi link=shared

gtest.fetch: .FORCE
	mkdir -p $(DOWNLOADS.DIR)
	cd $(DOWNLOADS.DIR) && wget -q $(GTEST.URL) && tar xf $(GTEST.ARCHIVE)

gtest: gtest.fetch
	rm -rf $(GTEST.BUILD)
	mkdir -p $(GTEST.BUILD) && cd $(GTEST.BUILD) && $(CMAKE.BIN) -DCMAKE_INSTALL_PREFIX=$(INSTALLED.HOST.DIR) $(GTEST.DIR) && make -j$(J) install

gtest.clean: .FORCE
	rm -rf $(GTEST.BUILD)
	rm -rf $(DOWNLOADS.DIR)/$(GTEST.ARCHIVE)



clean: cmake.clean
	rm -rf $(INSTALLED.HOST.DIR)
	rm -rf $(DOWNLOADS.DIR)

.FORCE:


