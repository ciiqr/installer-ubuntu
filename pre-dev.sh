#!/usr/bin/env bash

# Mount iso
# sudo mount -o ro -o loop custom.iso custom

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
