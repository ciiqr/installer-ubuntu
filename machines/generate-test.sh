#!/usr/bin/env bash

# usage:
# ./generate-test.sh --private-config ~/.private-config --default-machine server-data --build d

# TODO: At some point I should see if I can have it auto create the vm... Can I use vagrant in a non-headless fashion?
VBoxManage startvm ubuntis 2> /dev/null
./generate.sh "$@" && VBoxManage controlvm ubuntis reset
