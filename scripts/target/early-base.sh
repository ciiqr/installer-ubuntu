#!/usr/bin/env bash

. /scripts/inc/apt.sh

passwd_username="$2"
user_home="`eval echo "~$passwd_username"`"

# TODO: https://help.ubuntu.com/community/Repositories/CommandLine#Adding_Repositories
# Add: universe multiverse partner

# Explicitly install kernel because I had a problem once right after re-installation where it was installed but seemingly the wrong version
# TODO: Maybe we just need to make the packages installed though d-i pull from the internet? (either remove local (to cd) repo entirely, or set some preseed option, idk...)
# NOTE: It seems the generic/server kernels are no longer different http://askubuntu.com/a/177643
install linux-generic

# Misc
install acl
install libcap2-bin
install man
install info
install wget
install nfs-common
install woof
install htop
install whois
install sshfs
install nano
install p7zip
install rsync
install mlocate
install incron
install lsof
install nmap
install screen
install units
install unrar
install zip unzip
install traceroute
install fdupes
install ntp
install jq

# Hardware info
install lshw
install hwinfo

# Sensors
install lm-sensors

# Services
install haveged
install smartmontools

# Apt thugs
install apt-file
install aptitude
install software-properties-common
install debconf-utils

# Zsh
install zsh zsh-syntax-highlighting


# Update apt-file
# TODO: Either fix or delay...
# sudo apt-file update

# TODO: Need to confirm that this works being run at this point...
sensors-detect --auto

# Switch to zsh
sudo chsh -s /bin/zsh "$passwd_username"

# Make sure zsh works properly... sigh ubuntu
echo "emulate sh -c 'source /etc/profile'" > /etc/zsh/zprofile

# Password less sudo
tee "/etc/sudoers.d/$passwd_username" > /dev/null <<EOF

$passwd_username ALL=(ALL:ALL) NOPASSWD:ALL

EOF

# Override sudo defaults
tee /etc/sudoers.d/defaults > /dev/null <<EOF

# Don't keep HOME (that's super obnoxious)
Defaults env_keep -= "HOME"
# But do keep PATH so we can run our commands as root
Defaults exempt_group = $passwd_username

EOF

# Ensure the correct permissions
chmod 0440 /etc/sudoers.d/*

# TODO: I should really change dotfiles to be handled like private-config so that I don't have to install git on all machines
	# This would also help because it would be one less thing dependent on the internet for the initial install (making or more likely we'll be able to pre-load all our packages to the iso when we generate it and install on machines without worrying about internet access for the initial install, though we'll probably still want to do an update in the firstboot script...)
	# TODO: Also do this thing for awesome...
install git

# Updatedb
ADDITIONAL_PRUNE_PATHS="$user_home/.cache $user_home/.config/google-chrome $user_home/.mozilla /etc/mono/certstore/certs /etc/ssl/certs"
# TODO: Replace with replace_or_append (need to make sure I can use replacements... well I can at least grab the data I want first then find/replace)
sed -i 's@[# ]*PRUNEPATHS="\(.*\)"@PRUNEPATHS="\1 '"$ADDITIONAL_PRUNE_PATHS"'"@;s@[# ]*PRUNENAMES="\(.*\)"@PRUNENAMES="\1"@' /etc/updatedb.conf

# Enable services
systemctl enable haveged smartd
