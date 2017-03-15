#!/usr/bin/env bash

. /scripts/inc/common.sh
. /scripts/inc/apt.sh

categories="$1"


# General
install build-essential
install git
install cloc
install vagrant virtualbox
install pkg-config

# Python
install bpython bpython3

# Coffeescript
# install coffeescript

# Sass
# install sassc

# lmdb
# install liblmdb0 lmdb-doc lmdb-utils

# Scala
# install scala

# Nim
install nim

# Mono
install mono-complete nuget

# Mono - Libraries
install libgtk3.0-cil libwebkit1.1-cil libdbus2.0-cil libdbus-glib2.0-cil

# C++
install clang clang-format libclang-dev llvm lldb ninja-build

# Valgrind
install valgrind

# Strace
install strace

# Packer
install packer

# Custom Ubuntu install things
install debconf-utils genisoimage

# Frontend only
if contains_option frontend "$categories"; then
	install meld
	install virtualbox-qt
	install qtcreator
	install monodevelop
	install kcachegrind
	install xserver-xephyr
fi
