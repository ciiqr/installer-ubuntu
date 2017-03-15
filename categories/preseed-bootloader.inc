
# TODO: Go through everything below this...
### Boot loader installation
# Grub is the default boot loader (for x86). If you want lilo installed
# instead, uncomment this:
#d-i grub-installer/skip boolean true
# To also skip installing lilo, and install no bootloader, uncomment this
# too:
#d-i lilo-installer/skip boolean true


# This is fairly safe to set, it makes grub install automatically to the MBR
# if no other operating system is detected on the machine.
d-i grub-installer/only_debian boolean true

# # This one makes grub-installer install to the MBR if it also finds some other
# # OS, which is less safe as it might not be able to boot that other OS.
# d-i grub-installer/with_other_os boolean true

# Due notably to potential USB sticks, the location of the MBR can not be
# determined safely in general, so this needs to be specified:
#d-i grub-installer/bootdev  string /dev/sda
# To install to the first device (assuming it is not a USB stick):
# TODO: Will only work consistently with default if there is only 1 device, so I should just leave it out or script the choosing of it...
# d-i grub-installer/bootdev  string default
# d-i grub-installer/bootdev string /dev/sda

# Alternatively, if you want to install to a location other than the mbr,
# uncomment and edit these lines:
#d-i grub-installer/only_debian boolean false
#d-i grub-installer/with_other_os boolean false
#d-i grub-installer/bootdev  string (hd0,1)
# To install grub to multiple disks:
#d-i grub-installer/bootdev  string (hd0,1) (hd1,1) (hd2,1)

# Use the following option to add additional boot parameters for the
# installed system (if supported by the bootloader installer).
# Note: options passed to the installer will be added automatically.
#d-i debian-installer/add-kernel-opts string nousb

# TODO: Haven't tested this
d-i grub-installer/timeout string 1
