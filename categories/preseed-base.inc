
### Localization
d-i debian-installer/locale string en_CA.UTF-8

# Keyboard selection.
d-i console-setup/layoutcode string us
d-i	keyboard-configuration/layout select English (US)
d-i	keyboard-configuration/variant select English (US)
# Prevent 'toggling between national and Latin mode'
d-i keyboard-configuration/toggle select No toggling
# Prevent 'Detect keyboard layout?'
d-i	console-setup/ask_detect boolean false

# d-i	console-setup/detected note


### Network configuration
# netcfg will choose an interface that has link if possible
d-i netcfg/choose_interface select auto

# dhcp assigned hostname/domain names take precedence
d-i netcfg/get_hostname string unassigned
d-i netcfg/get_domain string unassigned

# Disable that annoying WEP key dialog.
d-i netcfg/wireless_wep string


### Hardware
d-i hw-detect/load_firmware boolean true


### Mirror settings
d-i mirror/country string ca
# TODO: Idk which of these disabled the proxy prompt while installing, but one it was certainly one of these
d-i mirror/http/proxy string
choose-mirror-bin mirror/ftp/proxy string
choose-mirror-bin mirror/http/proxy string


### Account setup
d-i user-setup/allow-password-weak boolean true
# TODO: Consider enabling this...
d-i user-setup/encrypt-home boolean false

# root
d-i passwd/root-login boolean true

# user
d-i passwd/user-fullname string William Villeneuve
d-i passwd/username string william


### Clock and time zone setup
d-i clock-setup/utc boolean true
d-i time/zone string Canada/Eastern
d-i clock-setup/ntp boolean true


# Policy for applying updates. (Could want none instead)
d-i pkgsel/update-policy select unattended-upgrades

# Update system's locate database (after packages installed...)
d-i pkgsel/updatedb boolean true


### Apt setup
d-i apt-setup/use_mirror boolean true

d-i apt-setup/restricted boolean true
d-i apt-setup/universe boolean true
d-i apt-setup/multiverse boolean true
d-i apt-setup/partner boolean true
d-i apt-setup/backports boolean true


### Package selection

# Individual additional packages to install (for ALL configurations)
d-i pkgsel/include string 

# Whether to upgrade packages after debootstrap.
# TODO: Maybe change... This might have been part of the issue (well I mean, might be able to help fix it) with that one time I installed and has to update the kernel right away
# TODO: Change to full-upgrade... Probably...
d-i pkgsel/upgrade select safe-upgrade

# I believe this defaults to standard, if I want most of the software from that then maybe switch to that (or server for servers), but probably not...
tasksel tasksel/first multiselect none

# Kernel
d-i base-installer/kernel/image string linux-generic


### Finishing up the installation
# Avoid that last message about the install being complete.
d-i finish-install/reboot_in_progress note


### Running custom commands during the installation
d-i preseed/late_command string log-output sh /cdrom/scripts/late.sh
d-i preseed/early_command string log-output sh /cdrom/scripts/early.sh

### Includes
d-i preseed/include string generated-preseed-base.inc
