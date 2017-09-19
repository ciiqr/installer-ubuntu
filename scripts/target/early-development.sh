#!/usr/bin/env bash

. /scripts/inc/common.sh
. /scripts/inc/apt.sh

categories="$1"


# General
install build-essential
install git
install cloc
install pkg-config

# Vagrant (w/nfs support)
install vagrant virtualbox
	# TODO: Test out installing from deb, something like this
	# version="1.9.0"
	# wget -O vagrant-"$version".deb https://releases.hashicorp.com/vagrant/"$version"/vagrant_"$version"_x86_64.deb
	# sudo dpkg -i vagrant-"$version".deb
	# sudo apt-get install -f
install nfs-common nfs-kernel-server

# For Swift perfect framework
install openssl libssl-dev uuid-dev

# Python
install bpython bpython3
install python-virtualenv python3-virtualenv virtualenv

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

# Custom Ubuntu install things
install debconf-utils genisoimage xorriso
# TODO: Maybe also syslinux syslinux-common

# Hashicorp suite
declare -A hashi_packages=(
	[terraform]="0.10.2"
	[packer]="1.0.4"
)

for hashi_package in "${!hashi_packages[@]}"; do
	declare version="${hashi_packages[$hashi_package]}"

	# Download
	wget "https://releases.hashicorp.com/${hashi_package}/${version}/${hashi_package}_${version}_linux_amd64.zip" -O "$hashi_package.zip"

	# Install
	sudo mkdir -p "/opt/$hashi_package"
	sudo unzip -o "$hashi_package.zip" -d "/opt/$hashi_package"

	# Delete zip
	rm "$hashi_package.zip"

	# Add to PATH
	tee "/etc/profile.d/$hashi_package.sh" > /dev/null <<EOF

	export PATH="/opt/$hashi_package:\$PATH"

EOF

done

# TODO: Install swift via deb

# Frontend only
if contains_option frontend "$categories"; then
	install meld
	install virtualbox-qt
	install qtcreator
	install monodevelop
	install kcachegrind
	install xserver-xephyr
fi
