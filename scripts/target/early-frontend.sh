#!/usr/bin/env bash

. /scripts/inc/apt.sh

passwd_username="$2"

# Drivers
install ubuntu-drivers-common
# - Install the recommended driver packages (ie. nvidia, intel-microcode)
install `ubuntu-drivers list`


# For Network Manager access
usermod -a -G "netdev" "$passwd_username"
