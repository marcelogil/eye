# Eye: menu bar toggle for the desktop icons.
#
#   make            build build/Eye.app
#   make run        build, then launch it from the build folder
#   make install    build, copy to /Applications and launch (INSTALL_DIR=... overrides the folder)
#   make uninstall  quit the app and remove the installed copy
#   make clean      remove the build folder

APP_NAME    := Eye
BUNDLE_ID   := com.gil.Eye
BUILD_DIR   := build
APP         := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS    := $(APP)/Contents
BINARY      := $(CONTENTS)/MacOS/$(APP_NAME)
PLIST       := $(CONTENTS)/Info.plist
ICON        := $(CONTENTS)/Resources/AppIcon.icns
SOURCES     := $(wildcard Sources/*.swift)
INSTALL_DIR ?= /Applications

ARCH        := $(shell uname -m)
SDK         := $(shell xcrun --show-sdk-path)
MIN_OS      := 14.0
SWIFTFLAGS  := -O -swift-version 5 -target $(ARCH)-apple-macos$(MIN_OS) -sdk $(SDK)

.PHONY: all build run install uninstall clean

all: build

build: $(BINARY) $(PLIST) $(ICON)
	codesign --force --sign - --identifier $(BUNDLE_ID) $(APP)

$(BINARY): $(SOURCES)
	mkdir -p $(dir $@)
	swiftc $(SWIFTFLAGS) $(SOURCES) -o $@

$(PLIST): Resources/Info.plist
	mkdir -p $(dir $@)
	cp $< $@

$(ICON): Tools/make-icon.swift
	mkdir -p $(dir $@)
	swiftc -O -swift-version 5 -sdk $(SDK) Tools/make-icon.swift -o $(BUILD_DIR)/make-icon
	$(BUILD_DIR)/make-icon $@

run: build
	pkill -x $(APP_NAME) || true
	open $(APP)

install: build
	pkill -x $(APP_NAME) || true
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	cp -R $(APP) "$(INSTALL_DIR)/"
	open "$(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	pkill -x $(APP_NAME) || true
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"

clean:
	rm -rf $(BUILD_DIR)
