#!/usr/bin/env bash

# usage:
# ./generate.sh --default-machine server-data --build d

set_cli_args_default()
{
    BUILD_MODE=''
    IMAGE_DEFAULT_MACHINE="server-data"
    private_config_dir=''
    configDir="/config"
    privateConfigDir="/config-private"
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
            --private-config)
                private_config_dir="$(readlink -f "$2")"
                shift
            ;;
            --default-machine)
                IMAGE_DEFAULT_MACHINE="$2"
                shift
            ;;
            --build)
                local input_build_mode="${2,,}"

                for mode in debug release; do
                    case "$mode" in
                        $input_build_mode*)
                            BUILD_MODE="$mode"
                            break
                        ;;
                    esac
                done

                if [[ -z "$BUILD_MODE" || -z "$input_build_mode" ]]; then
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

set_cli_args_default
parse_cli_args "$@" || exit $?

BUILD_ISO_DOWLOAD_URL="http://releases.ubuntu.com/16.04/ubuntu-16.04.4-server-amd64.iso"
# BUILD_ISO_DOWLOAD_URL="http://releases.ubuntu.com/17.10/ubuntu-17.10.1-server-amd64.iso"
BUILD_ISO_PATH="original.iso"
BUILD_ISO_MOUNT_DIR="iso-temp"

BUILD_IMAGE_DIR="image"

IMAGE_ISOLINUX_MENU_CONFIG="$BUILD_IMAGE_DIR/isolinux/txt.cfg"
IMAGE_ISOLINUX_MAIN_CONFIG="$BUILD_IMAGE_DIR/isolinux/isolinux.cfg"

if [[ "$BUILD_MODE" == "debug" ]]; then
    IMAGE_ADDITIONAL_KERNEL_OPTIONS="DEBCONF_DEBUG=5 debconf/priority=critical"
    cdrom_auto_eject="false"
else # release
    IMAGE_ADDITIONAL_KERNEL_OPTIONS="splash"
    cdrom_auto_eject="true"
fi

ISO_LABEL="WAV Custom Install CD"
ISO_PATH="../custom.iso"

# Make and go to build dir
[[ -d build ]] || mkdir build
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
# keeps trying until it unmounts successfully... Which happens often cause the dir is still transfering
until sudo umount "$BUILD_ISO_MOUNT_DIR" 2> /dev/null; do
    echo "Failed unmounting, trying again"
    sleep 0.1
done

rmdir "$BUILD_ISO_MOUNT_DIR"


# Transfer categories to image
sudo cp -r "../categories" "$BUILD_IMAGE_DIR/categories"
sudo cp -r "../scripts" "$BUILD_IMAGE_DIR/scripts"
sudo cp -r "../data" "$BUILD_IMAGE_DIR/data"

if [[ -d "$configDir" ]]; then
    sudo rsync -ra --delete "$configDir/" "$BUILD_IMAGE_DIR/data/config"
fi

if [[ -d "$privateConfigDir" ]]; then
    sudo rsync -ra --delete "$privateConfigDir/" "$BUILD_IMAGE_DIR/data/config-private"
fi

# Generate categories
sudo tee "$BUILD_IMAGE_DIR/categories/generated-preseed-base.inc" > /dev/null <<EOF

### Debug only options
d-i cdrom-detect/eject boolean $cdrom_auto_eject

EOF


# Change bootloader options

# TODO: This is a temporary solution, I need to reconfigure grub properly...
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

EOF


# TODO: Consider simply overridding the menu options entirely... (Refactor if I'm going to keep this...)
sudo tee "$IMAGE_ISOLINUX_MENU_CONFIG" > /dev/null <<EOF
default TO_BE_REPLACED
EOF

# Append all categories to the menu
# TODO: Consider whether we need the following:
#   - ramdisk_size root=/dev/ram auto=true debconf/priority=critical
# TODO: debconf/priority=critical is an issue for my laptop because I have to manually connect to wifi
# Docs: http://www.syslinux.org/doc/syslinux.txt
for category_path in ../categories/preseed-*.cfg; do
    file="`basename $category_path`"
    # Remove prefix and suffix on the filename
    label="${file#preseed-}"
    label="${label%.cfg}"

    menu_label="Install ${label^}"
    kernel_args="file=/cdrom/categories/$file initrd=/install/initrd.gz noprompt auto=true quiet $IMAGE_ADDITIONAL_KERNEL_OPTIONS"

    # Append to (legacy) bootloader menu
    sudo tee -a "$IMAGE_ISOLINUX_MENU_CONFIG" > /dev/null <<EOF

label $label
    menu label ^$menu_label
    kernel /install/vmlinuz
    append  $kernel_args ---

EOF

    # Append to (efi) bootloader menu
    sudo tee -a "$BUILD_IMAGE_DIR/boot/grub/grub.cfg" > /dev/null <<EOF

menuentry "$menu_label" {
    set gfxpayload=keep
    linux   /install/vmlinuz  $kernel_args ---
    initrd  /install/initrd.gz
}

EOF

done

# Set default boot option
if [[ ! -z "$IMAGE_DEFAULT_MACHINE" ]]; then
    # TODO: Replace with replace_or_append if applicable...
    sudo sed 's/default .*/default '"$IMAGE_DEFAULT_MACHINE"'/' -i "$IMAGE_ISOLINUX_MENU_CONFIG"
fi

# Comment out default ... (if it's something like vesamenu.c32 then it just gets in the way..)
sudo sed 's/^\(default .*\)/# \1/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"

# Always prompt for boot option
sudo sed 's/prompt 0/prompt 1/' -i "$IMAGE_ISOLINUX_MAIN_CONFIG"

# Change default timeout
if [[ "$BUILD_MODE" == "debug" ]]; then
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
sudo xorriso -as mkisofs -r -V "$ISO_LABEL" \
    -isohybrid-mbr image/isolinux/isolinux.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 \
    -boot-info-table -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
    -isohybrid-gpt-basdat -o "$ISO_PATH" "$BUILD_IMAGE_DIR"
