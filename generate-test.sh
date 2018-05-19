#!/usr/bin/env bash

# usage:
# ./generate-test.sh --build d

# TODO: change to create vm on demand: https://www.perkin.org.uk/posts/create-virtualbox-vm-from-the-command-line.html

# stop vm
VBoxManage controlvm ubuntis poweroff

# destroy vm
[[ -d ~/vms/ubuntis ]] && sudo umount ~/vms/ubuntis

# pre-dev
mount_dir="$HOME/vms/ubuntis"
existing_vm_dir="$HOME/vms/ubuntis.data"
if [[ ! -d "$existing_vm_dir" && -d "$mount_dir" ]]; then
	mv "$mount_dir" "$existing_vm_dir"
	mkdir "$mount_dir"
fi
# Mount ramdisk
mkdir -p "$mount_dir"
sudo mount -t ramfs -o size=7g ramfs "$mount_dir"
# Copy existing vm to ramdisk
sudo rsync -rav "$existing_vm_dir/" "$mount_dir"


# Generate iso
./generate.sh "$@" || exit 1


# Start/reset machine
VBoxManage startvm ubuntis 2> /dev/null
VBoxManage controlvm ubuntis reset
