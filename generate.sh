#!/usr/bin/env bash

# usage:
# ./generate.sh --build d

set_cli_args_default()
{
    configDir="/config"
    privateConfigDir="/config-private"
    runTest=''
    buildMode=''
}

parse_cli_args()
{
    while [[ $# -gt 0 ]]; do
        local arg="$1"

        case $arg in
            --configDir)
                configDir="${2%/}"
                shift
            ;;
            --privateConfigDir)
                privateConfigDir="${2%/}"
                shift
            ;;
            --test)
                runTest="true"
            ;;
            --build)
                local input_build_mode="${2,,}"

                for mode in debug release; do
                    case "$mode" in
                        $input_build_mode*)
                            buildMode="$mode"
                            break
                        ;;
                    esac
                done

                if [[ -z "$buildMode" ]]; then
                    echo $0: Unrecognized build mode \"$2\"
                    return 1
                fi

                shift
            ;;
            *)
                echo $0: Unrecognized option \"$1\"
                return 1
            ;;
        esac
        shift # next
    done
}

quiet()
{
    declare out="$(mktemp)"
    declare ret=0

    if ! "$@" </dev/null >"$out" 2>&1; then
        ret=1
        cat "$out" >&2
    fi

    rm -f "$out"
    return "$ret"
}

forrealz(){ realpath "$@" 2>/dev/null || readlink -f "$@" 2>/dev/null || perl -e 'use File::Basename; use Cwd "abs_path"; print abs_path(@ARGV[0]);' -- "$@"; }
srcDir="$(dirname "$(forrealz "${BASH_SOURCE[0]}")")"
# TODO: use srcDir so we don't have to be so dumb anymore

set_cli_args_default
parse_cli_args "$@" || exit $?

# BUILD_ISO_DOWLOAD_URL="http://releases.ubuntu.com/16.04/ubuntu-16.04.4-server-amd64.iso"
# BUILD_ISO_DOWLOAD_URL="http://releases.ubuntu.com/18.04/ubuntu-18.04-live-server-amd64.iso" # subiquity
BUILD_ISO_DOWLOAD_URL="http://cdimage.ubuntu.com/ubuntu/releases/18.04/release/ubuntu-18.04-server-amd64.iso" # di
BUILD_ISO_PATH="original/${BUILD_ISO_DOWLOAD_URL##*/}"
BUILD_ISO_MOUNT_DIR="iso-temp"
BUILD_IMAGE_DIR="image"
IMAGE_ISOLINUX_MAIN_CONFIG="$BUILD_IMAGE_DIR/isolinux/isolinux.cfg"
ISO_LABEL="installer-ubuntu"
ISO_PATH="$ISO_LABEL.iso"

if [[ "$buildMode" == "debug" ]]; then
    IMAGE_ADDITIONAL_KERNEL_OPTIONS="DEBCONF_DEBUG=5 debconf/priority=critical"
    cdrom_auto_eject="false"
else # release
    IMAGE_ADDITIONAL_KERNEL_OPTIONS="splash"
    cdrom_auto_eject="true"
fi

# Remove anything from a previous build
sudo rm -rf custom.iso build/image

# Make sure build directories exist
[[ -d build/original ]] || mkdir -p build/{original,image}

# Go to build directory
cd build

# Download iso if we don't have it...
if [[ ! -f "$BUILD_ISO_PATH" ]]; then
    wget "$BUILD_ISO_DOWLOAD_URL" -O "$BUILD_ISO_PATH"
fi


# Mount iso
mkdir -p "$BUILD_ISO_MOUNT_DIR"
sudo mount -o loop,ro "$BUILD_ISO_PATH" "$BUILD_ISO_MOUNT_DIR"

# Copy files from iso
sudo rsync -ra --delete "$BUILD_ISO_MOUNT_DIR/" "$BUILD_IMAGE_DIR"

# Unmount iso
# keeps trying until it unmounts successfully... Which happens often cause the dir is still transferring
until sudo umount "$BUILD_ISO_MOUNT_DIR" 2> /dev/null; do
    echo "Failed unmounting, trying again"
    sleep 0.1
done

rmdir "$BUILD_ISO_MOUNT_DIR"


# Transfer preseed to image
sudo rsync -ra "../preseed/" "$BUILD_IMAGE_DIR/preseed"
sudo rsync -ra "../scripts/" "$BUILD_IMAGE_DIR/scripts"
sudo mkdir -p "$BUILD_IMAGE_DIR/data"

if [[ -d "$configDir" ]]; then
    sudo rsync -ra --delete "$configDir/" "$BUILD_IMAGE_DIR/data/config"
fi

if [[ -d "$privateConfigDir" ]]; then
    sudo rsync -ra --delete "$privateConfigDir/" "$BUILD_IMAGE_DIR/data/config-private"
fi

# Generate preseed
sudo tee "$BUILD_IMAGE_DIR/preseed/generated-preseed.inc" > /dev/null <<EOF

### Debug only options
d-i cdrom-detect/eject boolean $cdrom_auto_eject

EOF


# Change bootloader options

# Add preseed to the menu
# Docs: http://www.syslinux.org/doc/syslinux.txt
label="ubuntu"
menu_label="Install ${label^}"
initrd="/install/initrd.gz"
vmlinuz="/install/vmlinuz"
kernel_args="file=/cdrom/preseed/preseed-main.cfg initrd=$initrd noprompt auto=true quiet $IMAGE_ADDITIONAL_KERNEL_OPTIONS"

# Configure (legacy) bootloader menu
sudo tee "$BUILD_IMAGE_DIR/isolinux/txt.cfg" > /dev/null <<EOF
default $label
label $label
    menu label ^$menu_label
    kernel $vmlinuz
    append  $kernel_args ---
EOF

# Configure (efi) bootloader menu
sudo tee "$BUILD_IMAGE_DIR/boot/grub/grub.cfg" > /dev/null <<EOF
if loadfont /boot/grub/font.pf2 ; then
    set gfxmode=auto
    insmod efi_gop
    insmod efi_uga
    insmod gfxterm
    terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

menuentry "$menu_label" {
    set gfxpayload=keep
    linux   $vmlinuz  $kernel_args ---
    initrd  $initrd
}
EOF

# Comment out default ... (if it's something like vesamenu.c32 then it just gets in the way..)
sudo sed 's/^\(default .*\)/# \1/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"

# Always prompt for boot option
sudo sed 's/prompt 0/prompt 1/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"

# Change default timeout
if [[ "$buildMode" == "debug" ]]; then
    # Basically instant timeout
    sudo sed 's/^timeout .*/timeout 1/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"
else # release
    # If not debugging then we don't want to auto boot...
    sudo sed 's/^timeout .*/timeout 0/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"
fi

# Select english as the default language (for the bootloader...)
# NOTE: Unfortunately this doesn't stop the lang prompt from appearing
echo en | sudo tee "$BUILD_IMAGE_DIR/isolinux/lang" > /dev/null


# Generate iso
quiet sudo xorriso -as mkisofs -r -V "$ISO_LABEL" \
    -isohybrid-mbr image/isolinux/isolinux.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 \
    -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -o "$ISO_PATH" "$BUILD_IMAGE_DIR"

if [[ "$runTest" == "true" ]]; then
    "$srcDir/test.sh"
fi
