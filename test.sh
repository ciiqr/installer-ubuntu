#!/usr/bin/env bash

# set -x

forrealz(){ realpath "$@" 2>/dev/null || readlink -f "$@" 2>/dev/null || perl -e 'use File::Basename; use Cwd "abs_path"; print abs_path(@ARGV[0]);' -- "$@"; }
srcDir="$(dirname "$(forrealz "${BASH_SOURCE[0]}")")"

#
vm='installer-ubuntu'
isoPath="$srcDir/build/$vm.iso"

# Create a 32GB “dynamic” disk.
VBoxManage createhd --filename "$vm.vdi" --size 32768 >/dev/null 2>&1

# Create vm
VBoxManage createvm --name "$vm" --ostype "Ubuntu_64" --register >/dev/null 2>&1

# Add a SATA controller with the dynamic disk attached.
VBoxManage storagectl "$vm" --name "SATA Controller" --add sata \
	--controller IntelAHCI 2>/dev/null
VBoxManage storageattach "$vm" --storagectl "SATA Controller" --port 0 \
	--device 0 --type hdd --medium "$vm.vdi" 2>/dev/null

# Add an IDE controller with a DVD drive attached, and the install ISO inserted into the drive:
VBoxManage storagectl "$vm" --name "IDE Controller" --add ide 2>/dev/null
VBoxManage storageattach "$vm" --storagectl "IDE Controller" --port 0 \
	--device 0 --type dvddrive --medium "$isoPath" 2>/dev/null

# Misc system settings.
VBoxManage modifyvm "$vm" --ioapic on
VBoxManage modifyvm "$vm" --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm "$vm" --memory 1024 --vram 128
dpi="$(xrdb -query | grep dpi | cut -d':' -f 2)"
VBoxManage setextradata "$vm" GUI/ScaleFactor "$((dpi / 96))"

echo "==> vm created"

# Configuration is all done, boot it up!
VBoxManage startvm "$vm" >/dev/null 2>&1

echo "==> vm started"

# Pause
trap ' ' INT
echo "Press Ctrl-C to continue"
cat

# Shutdown
VBoxManage controlvm "$vm" poweroff >/dev/null 2>&1

echo "==> vm shutting down"

# Destroy
# TODO: I'd like a way of checking if it's locked... haven't found anything that works yet
until VBoxManage unregistervm "$vm" --delete >/dev/null 2>&1; do
	sleep 1
done

echo "==> vm destroyed"
